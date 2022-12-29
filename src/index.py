import os
import json
import logging
import autoscaling

import boto3
from datetime import datetime,timedelta

# Environment variables
min_capacity       = int(os.environ.get("min_capacity"))
max_capacity       = int(os.environ.get("max_capacity"))
cluster_identifier = os.environ.get("cluster_identifier")
scaleup_alarm_name = os.environ.get("scaleup_alarm_name")

# Scaling policies
metric_name        = os.environ.get("metric_name")
target             = int(os.environ.get("target"))
scaledown_target   = int(os.environ.get("scaledown_target"))
statistic          = os.environ.get("statistic")
period             = int(os.environ.get("period"))

def scaleup(event, context):
  logging.info("Scaleup initiated...")
  
  if min_capacity > max_capacity:
    logging.critical("The 'min_capacity' cannot be greater than 'max_capacity'.")
    return None

  docdb = autoscaling.DocumentDB(cluster_identifier, min_capacity, max_capacity)
  replicas_count = docdb.get_replicas_count()

  if min_capacity == replicas_count:
    logging.warning("The 'replicas_count' is identical to 'min_capacity', no action taken.")
    return None

  # Add more replica instances to meet the minimum capacity
  if min_capacity > replicas_count:
    logging.warning("Adding more replica instances to meet the minimum capacity...")
    missing_replicas = min_capacity - replicas_count

    while missing_replicas > 0:
      logging.warning("Adding replica...")
      docdb.add_replica(ignore_status=True)
      logging.critical("Would add Replica...")
      missing_replicas -= 1
 
    # Ignore the alarm state
    return None

  # The alarm_name determines whether to scale up or down.
  sns_message = json.loads(event.get('Records')[0].get('Sns').get('Message'))
  alarm_name = sns_message.get('AlarmName')

  if "scaleup" in alarm_name:
    logging.warning("Adding replica...")
    docdb.add_replica()
  elif "scaledown" in alarm_name:
    logging.warning("Removing replica...")
    docdb.remove_replica()
  else:
    # This condition should never be true and indicates that something unintended
    # happened.
    logging.critical("The alarm name contained neither 'scaleup' nor 'scaledown'")
    return None

def scaledown(event, context):
  logging.info("Scaledown initiated...")
  
  docdb = autoscaling.DocumentDB(cluster_identifier, min_capacity, max_capacity)
  replicas_count = docdb.get_replicas_count()

  logging.info("There are " + str(replicas_count) + " " + cluster_identifier + " replicas.")

  if min_capacity == replicas_count:
    logging.warning("The 'replicas_count' is identical to 'min_capacity', no action taken.")
    return None
  elif min_capacity > replicas_count:
    logging.critical("The 'replicas_count' is less than 'min_capacity', check if the scaleup handler works properly...")
    return None
  elif min_capacity < replicas_count:
    logging.warning("The 'replicas_count' is greater than 'min_capacity', checking if scaledown is required...")

    client = boto3.client('cloudwatch')

    alarm_response = client.describe_alarms(AlarmNames=[scaleup_alarm_name])

    # Only scale down, if the scaleup alarm is not active
    if "OK" in response['MetricAlarms'][0]['StateValue']:
      metric_response = client.get_metric_statistics(
        Namespace="AWS/DocDB",
        MetricName=metric_name,
        Dimensions=[
          {
            "Name": "DBClusterIdentifier",
            "Value": cluster_identifier
          },
        ],
        StartTime=datetime.utcnow() - timedelta(seconds = period),
        EndTime=datetime.utcnow(),
        Period=period,
        Statistics=[
          statistic,
        ]
      )

      # If there are multiple datapoints, calculate average (usually there is only one, but this way it's more robust)
      average = 0.0

      for datapoint in metric_response['Datapoints']:
        average += float(datapoint[statistic])
      
      average /= len(metric_response['Datapoints'])

      if average < scaledown_target:
        logging.warning("The " + statistic + " " + metric_name + " has been below " + str(scaledown_target) + " for " + str(period) + "seconds, scaling down...")
        docdb.remove_replica()
      else:
        logging.warning("The " + statistic + " " + metric_name + " has been above " + str(scaledown_target) + " for " + str(period) + "seconds, no action taken...")
        return None
    else:
      logging.warning("The alarm " + alarm_name + " is active, no action taken...")
  else:
    logging.critical("Something went wrong determining the replicas_count, aborting...")
    return None

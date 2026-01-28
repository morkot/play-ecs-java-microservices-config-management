import json
import os
import logging
import re
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize ECS client
ecs_client = boto3.client('ecs')


def extract_service_name_from_s3(s3_key):
    """
    Extract service name from S3 object key.
    E.g., service-1.env -> service-1
    """
    if not s3_key:
        return None

    # Pattern: {service-name}.env
    match = re.match(r'^(service-\d+)\.env$', s3_key)
    if match:
        return match.group(1)
    return None


def restart_ecs_service(cluster_name, service_name, project_name):
    """
    Restart ECS service by forcing a new deployment.
    This will gracefully stop old tasks and start new ones with fresh configuration.
    """
    ecs_service_name = f"{project_name}-{service_name}"

    logger.info(f"Restarting ECS service: {ecs_service_name} in cluster: {cluster_name}")

    try:
        # Force new deployment - ECS will gracefully replace tasks
        response = ecs_client.update_service(
            cluster=cluster_name,
            service=ecs_service_name,
            forceNewDeployment=True
        )

        logger.info(f"Successfully triggered restart for {ecs_service_name}")
        logger.info(f"Service status: {response['service']['status']}")
        logger.info(f"Desired count: {response['service']['desiredCount']}")

        return {
            'success': True,
            'service': ecs_service_name,
            'status': response['service']['status'],
            'deployments': len(response['service']['deployments'])
        }

    except ecs_client.exceptions.ServiceNotFoundException:
        logger.error(f"ECS service not found: {ecs_service_name}")
        raise Exception(f"ECS service '{ecs_service_name}' not found in cluster '{cluster_name}'")

    except ecs_client.exceptions.ClusterNotFoundException:
        logger.error(f"ECS cluster not found: {cluster_name}")
        raise Exception(f"ECS cluster '{cluster_name}' not found")

    except Exception as e:
        logger.error(f"Error restarting ECS service: {str(e)}")
        raise


def handler(event, context):
    """
    Lambda handler that restarts ECS service (forces new deployment)
    when S3 env files are updated (via EventBridge).

    EventBridge S3 event format:
    {
        "source": "aws.s3",
        "detail-type": "Object Created" | "Object Deleted",
        "detail": {
            "bucket": {"name": "bucket-name"},
            "object": {"key": "service-1.env"}
        }
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")

    cluster_name = os.environ.get('ECS_CLUSTER_NAME')
    project_name = os.environ.get('PROJECT_NAME', 'ecs-config-demo')

    if not cluster_name:
        logger.error("ECS_CLUSTER_NAME environment variable not set")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'ECS_CLUSTER_NAME not configured'})
        }

    try:
        # EventBridge S3 event
        source = event.get('source', '')
        detail_type = event.get('detail-type', '')
        detail = event.get('detail', {})

        if source != 'aws.s3':
            logger.warning(f"Unexpected event source: {source}")
            return {
                'statusCode': 400,
                'body': json.dumps({'error': f'Unexpected event source: {source}'})
            }

        bucket_name = detail.get('bucket', {}).get('name')
        object_key = detail.get('object', {}).get('key')

        logger.info(f"S3 event: {detail_type} on s3://{bucket_name}/{object_key}")

        service_name = extract_service_name_from_s3(object_key)

        if not service_name:
            logger.warning(f"Could not extract service name from S3 key: {object_key}")
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Could not determine service from S3 key',
                    's3_key': object_key
                })
            }

        result = restart_ecs_service(cluster_name, service_name, project_name)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'ECS service restart triggered for {service_name}',
                'service': service_name,
                'event_type': detail_type,
                's3_key': object_key,
                'restart_result': result
            })
        }

    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Failed to process event',
                'details': str(e)
            })
        }

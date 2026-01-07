import json
import os
import logging
import re
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize ECS client
ecs_client = boto3.client('ecs')


def extract_service_name(parameter_name):
    """
    Extract service name from SSM parameter path.
    E.g., /ecs-config-demo/dev/service-1/app/feature/flag -> service-1
    """
    if not parameter_name:
        return None

    # Pattern: /ecs-config-demo/{env}/{service-name}/...
    match = re.match(r'^/ecs-config-demo/\w+/(service-\d+)/', parameter_name)
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
    when SSM parameters are updated.
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

    # Extract SSM parameter details from event
    parameter_name = None
    operation = None
    if 'detail' in event:
        parameter_name = event.get('detail', {}).get('name')
        operation = event.get('detail', {}).get('operation')
        logger.info(f"SSM Parameter changed: {parameter_name}, Operation: {operation}")

    # Determine which service to restart based on parameter path
    service_name = extract_service_name(parameter_name)

    if not service_name:
        logger.warning(f"Could not extract service name from parameter: {parameter_name}")
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Could not determine service from parameter path',
                'parameter': parameter_name
            })
        }

    try:
        result = restart_ecs_service(cluster_name, service_name, project_name)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'ECS service restart triggered for {service_name}',
                'service': service_name,
                'parameter_changed': parameter_name,
                'operation': operation,
                'restart_result': result
            })
        }

    except Exception as e:
        logger.error(f"Error restarting service: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Failed to restart ECS service',
                'service': service_name,
                'details': str(e)
            })
        }

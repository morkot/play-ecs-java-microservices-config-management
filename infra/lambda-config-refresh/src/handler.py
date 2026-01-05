import json
import os
import urllib.request
import urllib.error
import logging
import re

logger = logging.getLogger()
logger.setLevel(logging.INFO)


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


def call_refresh_endpoint(alb_endpoint, service_name):
    """Call the refresh endpoint for a specific service."""
    refresh_url = f"{alb_endpoint}/{service_name}/api/config/refresh"
    logger.info(f"Calling refresh endpoint: {refresh_url}")

    request = urllib.request.Request(
        refresh_url,
        method='POST',
        headers={'Content-Type': 'application/json'}
    )

    with urllib.request.urlopen(request, timeout=30) as response:
        response_body = response.read().decode('utf-8')
        status_code = response.getcode()
        logger.info(f"Refresh response for {service_name}: status={status_code}, body={response_body}")
        return status_code, response_body


def handler(event, context):
    """
    Lambda handler that triggers config refresh on ECS service
    when SSM parameters are updated.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    alb_endpoint = os.environ.get('ALB_ENDPOINT')
    if not alb_endpoint:
        logger.error("ALB_ENDPOINT environment variable not set")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'ALB_ENDPOINT not configured'})
        }

    # Extract SSM parameter details from event
    parameter_name = None
    operation = None
    if 'detail' in event:
        parameter_name = event.get('detail', {}).get('name')
        operation = event.get('detail', {}).get('operation')
        logger.info(f"SSM Parameter changed: {parameter_name}, Operation: {operation}")

    # Determine which service to refresh based on parameter path
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
        status_code, response_body = call_refresh_endpoint(alb_endpoint, service_name)

        return {
            'statusCode': status_code,
            'body': json.dumps({
                'message': f'Config refresh triggered for {service_name}',
                'service': service_name,
                'parameter_changed': parameter_name,
                'refresh_response': json.loads(response_body) if response_body else None
            })
        }

    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8') if e.fp else str(e)
        logger.error(f"HTTP error calling refresh endpoint: {e.code} - {error_body}")
        return {
            'statusCode': e.code,
            'body': json.dumps({
                'error': 'Failed to refresh config',
                'service': service_name,
                'details': error_body
            })
        }

    except urllib.error.URLError as e:
        logger.error(f"URL error calling refresh endpoint: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Failed to connect to refresh endpoint',
                'service': service_name,
                'details': str(e.reason)
            })
        }

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Unexpected error',
                'service': service_name,
                'details': str(e)
            })
        }

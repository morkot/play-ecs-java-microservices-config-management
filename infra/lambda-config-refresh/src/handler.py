import json
import os
import urllib.request
import urllib.error
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

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

    refresh_url = f"{alb_endpoint}/api/config/refresh"

    # Extract SSM parameter details from event if available
    parameter_name = None
    if 'detail' in event:
        parameter_name = event.get('detail', {}).get('name')
        operation = event.get('detail', {}).get('operation')
        logger.info(f"SSM Parameter changed: {parameter_name}, Operation: {operation}")

    try:
        logger.info(f"Calling refresh endpoint: {refresh_url}")

        request = urllib.request.Request(
            refresh_url,
            method='POST',
            headers={'Content-Type': 'application/json'}
        )

        with urllib.request.urlopen(request, timeout=30) as response:
            response_body = response.read().decode('utf-8')
            status_code = response.getcode()

            logger.info(f"Refresh response: status={status_code}, body={response_body}")

            return {
                'statusCode': status_code,
                'body': json.dumps({
                    'message': 'Config refresh triggered successfully',
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
                'details': error_body
            })
        }

    except urllib.error.URLError as e:
        logger.error(f"URL error calling refresh endpoint: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Failed to connect to refresh endpoint',
                'details': str(e.reason)
            })
        }

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Unexpected error',
                'details': str(e)
            })
        }

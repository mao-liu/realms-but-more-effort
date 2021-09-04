locals {
    gaia_name = "realms-gaia"
}

resource "aws_lambda_function" "gaia" {
  function_name    = local.gaia_name
  description      = "Minimalistic lambda function to check status and start realms"
  handler          = "app.lambda_handler"
  runtime          = "python3.8"

  filename         = "${local.gaia_name}.zip"
  source_code_hash = data.archive_file.gaia.output_base64sha256
  role             = aws_iam_role.realm.arn

  environment {
    variables = {
        SSM_ASG_NAME = "ssm://realms/outputs/server_asg_name"
    }
  }

}

data "archive_file" "gaia" {
  type        = "zip"
  output_path = "${local.gaia_name}.zip"

  source {
    filename = "app.py"
    content  = <<-PYTHON
    """Very minimalistic function queries and modifies ASG"""
    import boto3
    import os
    import json
    import time
    import logging

    ASG = boto3.client('autoscaling')
    SSM = boto3.client('ssm')

    logging.basicConfig(level=logging.INFO)

    def _get_asg_name():
        ssm_path = os.environ['SSM_ASG_NAME'].replace('ssm:/', '')
        logging.info(f'SSM get_parameter {ssm_path}')
        response = SSM.get_parameter(Name=ssm_path, WithDecryption=True)
        logging.info(response)
        return response['Parameter']['Value']

    def _apigw_response(data: dict):
        response = {
            "isBase64Encoded": False,
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(data, default=str)
        }
        logging.info('response')
        logging.info(response)
        return response

    def get_status(debug=False):
        asg_name = _get_asg_name()

        logging.info(f'ASG describe_auto_scaling_groups {asg_name}')
        asg_info = ASG.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        logging.info(asg_info)

        n_instances = len(asg_info['AutoScalingGroups'][0]['Instances'])
        n_desired = asg_info['AutoScalingGroups'][0]['DesiredCapacity']

        if n_instances == 0 and n_desired == 0:
            status = "stopped"
        elif n_instances == 1 and n_desired == 0:
            status = "stopping"
        elif n_instances == 1 and n_desired == 1:
            status = "running"
        elif n_instances == 0 and n_desired == 1:
            status = "pending"
        else:
            status = "error"

        response = {
            "status": status
        }
        debug = {
            "asg_info": asg_info
        }
        if debug or status == "error":
            response['debug'] = debug
        return response

    def start_realms():
        asg_name = _get_asg_name()

        logging.info(f'ASG update_auto_scaling_group {asg_name}')
        response = ASG.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            MinSize=1,
            MaxSize=1,
            DesiredCapacity=1
        )
        logging.info(response)

        return response

    def lambda_handler(event, contest):
        handlers = {
            "GET /realms/info": lambda: get_status(),
            "GET /realms/debug": lambda: get_status(debug=True),
            "POST /realms/start": lambda: start_realms()
        }

        op = f'{event["httpMethod"]} {event["path"}'
        logging.info('Handling {op}')

        response = handlers[op]()

        return _apigw_response(response)
    PYTHON
  }
}

resource "aws_cloudwatch_log_group" "gaia" {
  name              = "/aws/lambda/${local.gaia_name}"
  retention_in_days = 30
}

resource "null_resource" "gaia_archiver_cleanup" {
  # clean up the zip file after lambda deployment
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "rm -f ${local.gaia_name}.zip"
  }
  depends_on = [aws_lambda_function.gaia]
}

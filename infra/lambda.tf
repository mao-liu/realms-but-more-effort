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
    }
  }

}

data "archive_file" "gaia" {
  type        = "zip"
  output_path = "${local.gaia_name}.zip"

  source {
    filename = "app.py"
    content  = <<-PYTHON
    """Very minimalistic function that passes SQS messages to SNS"""
    import boto3
    import os

    SNS = boto3.client('sns')
    TOPIC_NAME = os.environ['ERROR_SNS_TOPIC_ARN']

    def lambda_handler(event, contest):
        # handles SQS events, event schema is here:
        # https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html

        for record in event['Records']:
            # pass the body through to SNS without modification
            body = record['body']

            # add the eventSourceARN to the message attributes
            msg_attributes = {
              key: fix_sqs_msg_attribute(value)
              for key, value in record['messageAttributes'].items()
            }
            msg_attributes['eventSourceArn'] = {
                'DataType': 'String',
                'StringValue': record['eventSourceARN']
            }

            SNS.publish(TargetArn=TOPIC_NAME, Message=body, MessageAttributes=msg_attributes)

    def fix_sqs_msg_attribute(inp):
        # the sqs input message attributes is not fully compatible with sns message attributes
        # - turn camelCase to CamelCase for dict keys
        # - dont include any keys that arent supported by sns (stringListValues, binaryListValues)
        _key_mapping = {
          'dataType': 'DataType',
          'stringValue': 'StringValue',
          'binaryValue': 'BinaryValue'
        }
        return {
            _key_mapping[k]: v
            for k, v in inp.items()
            if k in _key_mapping
        }
    PYTHON
  }
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

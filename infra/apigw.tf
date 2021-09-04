locals {
}


resource "aws_apigatewayv2_api" "realms" {
    name = "realms-api"
    protocol_type = "HTTP"
}


resource "aws_apigatewayv2_route" "realms-get-info" {
    api_id = aws_apigatewayv2_api.realms.id
    route_key = "GET /realms/info"

    target = "integrations/${aws_api_gatewayv2_integration.gaia.id}"
}

resource "aws_apigatewayv2_integration" "gaia" {
    api_id                    = aws_apigatewayv2_api.realms.id
    integration_type          = "AWS_PROXY"

    connection_type           = "INTERNET"
    integration_method        = "POST"
    integration_uri           = aws_lambda_function.gaia.invoke_arn
    payload_format_version    = "1.0"
}

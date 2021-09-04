resource "aws_apigatewayv2_api" "realms" {
    name = "realms-api"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "realms" {
    api_id      = aws_apigatewayv2_api.realms.id
    name        = "realms"
    auto_deploy = true
}

resource "aws_apigatewayv2_api_mapping" "realms" {
    api_id      = aws_apigatewayv2_api.realms.id
    domain_name = aws_apigatewayv2_domain_name.api-realms.id
    stage       = aws_apigatewayv2_stage.realms.id
    api_mapping_key = "realms"
}

resource "aws_apigatewayv2_route" "realms" {
    for_each = toset([
        "GET /info",
        "GET /debug",
        "POST /start"
    ])
    api_id = aws_apigatewayv2_api.realms.id
    route_key = each.key

    target = "integrations/${aws_apigatewayv2_integration.gaia.id}"
}

resource "aws_apigatewayv2_integration" "gaia" {
    api_id                    = aws_apigatewayv2_api.realms.id
    integration_type          = "AWS_PROXY"

    connection_type           = "INTERNET"
    integration_method        = "POST"
    integration_uri           = aws_lambda_function.gaia.invoke_arn
    payload_format_version    = "1.0"
}

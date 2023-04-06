provider "aws" {
  region                  = var.region
  shared_credentials_file  = "~/.aws/credentials"
  profile                  = "claim_admin_ss"
}

data "aws_caller_identity" "current" {}

# Root API Gateway
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "${var.project}-api-gateway"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  depends_on = [
    "aws_api_gateway_method.lambda_method", "aws_api_gateway_integration.lambda_integration"
  ]

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api_gateway.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  variables = {
    deployed_at = "timestampher"
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  stage_name    = "stage"
}

# lambda resource endpoint
resource "aws_api_gateway_resource" "lambda_resource" {
  path_part   = "${var.endpoint_path}"
  parent_id   = aws_api_gateway_resource.lambda_resource_sub.id
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  
}

resource "aws_api_gateway_resource" "lambda_resource_sub" {
  path_part   = "sub"
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
}

# lambda resource Method
resource "aws_api_gateway_method" "lambda_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = var.http_method
  authorization = "NONE"
  api_key_required = true
}

# Method Integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.lambda_resource.id
  http_method             = aws_api_gateway_method.lambda_method.http_method
  integration_http_method = var.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:621752543894:function:Test-function/invocations"
  
  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}

# CORS OPTIONS Method for the lambda Endpoint
resource "aws_api_gateway_method" "cors_method_lambda" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# CORS Integration for the lambda Endpoint
resource "aws_api_gateway_integration" "cors_integration_lambda" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.cors_method_lambda.http_method
  type                    = "MOCK"
  request_templates = {
    "application/json" = <<EOF
{ "statusCode": 200 }
EOF
  }
}

# CORS Method Response for the lambda Endpoint
resource "aws_api_gateway_method_response" "cors_method_response_lambda" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.cors_method_lambda.http_method

  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# CORS Integration Response for the lambda Endpoint
resource "aws_api_gateway_integration_response" "cors_integration_response_lambda" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_method.cors_method_lambda.resource_id
  http_method = aws_api_gateway_method.cors_method_lambda.http_method

  status_code = aws_api_gateway_method_response.cors_method_response_lambda.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# API Gateway usage plan
resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "${var.project}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gateway.id
    stage  = aws_api_gateway_stage.example.stage_name
  }
}

# creates API Gateway key
resource "aws_api_gateway_api_key" "auth_key" {
  name = "${var.project}-auth-key"
}

# API Gateway key usage plan
resource "aws_api_gateway_usage_plan_key" "auth_key_usage_plan" {
  key_id        = aws_api_gateway_api_key.auth_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}

# Permission to allow execution from api gateway to invoke the lambda function
resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "Test-function"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api_gateway.id}/*/${aws_api_gateway_method.lambda_method.http_method}${aws_api_gateway_resource.lambda_resource.path}"
}


################################################

# lambda resource endpoint
resource "aws_api_gateway_resource" "lambda_resource2" {
  path_part   = "${var.endpoint_path}-2"
  parent_id   = aws_api_gateway_resource.lambda_resource_sub.id
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  
}

# lambda resource Method
resource "aws_api_gateway_method" "lambda_method2" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.lambda_resource2.id
  http_method   = var.http_method
  authorization = "NONE"
  api_key_required = true
}

# Method Integration
resource "aws_api_gateway_integration" "lambda_integration2" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.lambda_resource2.id
  http_method             = aws_api_gateway_method.lambda_method2.http_method
  integration_http_method = var.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:621752543894:function:test2/invocations"
  
  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}

# CORS OPTIONS Method for the lambda Endpoint
resource "aws_api_gateway_method" "cors_method_lambda2" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.lambda_resource2.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# CORS Integration for the lambda Endpoint
resource "aws_api_gateway_integration" "cors_integration_lambda2" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.lambda_resource2.id
  http_method = aws_api_gateway_method.cors_method_lambda2.http_method
  type                    = "MOCK"
  request_templates = {
    "application/json" = <<EOF
{ "statusCode": 200 }
EOF
  }
}

# CORS Method Response for the lambda Endpoint
resource "aws_api_gateway_method_response" "cors_method_response_lambda2" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.lambda_resource2.id
  http_method = aws_api_gateway_method.cors_method_lambda2.http_method

  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# CORS Integration Response for the lambda Endpoint
resource "aws_api_gateway_integration_response" "cors_integration_response_lambda2" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_method.cors_method_lambda2.resource_id
  http_method = aws_api_gateway_method.cors_method_lambda2.http_method

  status_code = aws_api_gateway_method_response.cors_method_response_lambda2.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}





# Permission to allow execution from api gateway to invoke the lambda function
resource "aws_lambda_permission" "lambda_permission2" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "test2"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api_gateway.id}/*/${aws_api_gateway_method.lambda_method2.http_method}${aws_api_gateway_resource.lambda_resource2.path}"
}

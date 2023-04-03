variable region {
  description = "AWS region"
  default = "us-east-1"
}


variable "project" {
  description = "Project Name"
  default = "intercom"
}

variable "function_name" {
  description = "Name of the Lambda Function"
  default = "sportsman-lambda-function"
}

variable "description" {
  description = "Description of the Lambda Function"
  default = "lambda function interacting with api gateway"
}

variable "handler" {
  description = "lambda handler entrypoint"
  default = "hello-world.lambda_handler"
}

variable "runtime" {
  description = "lambda runtime version"
  default = "python3.7"
}

variable "memory" {
  description = "lambda allocated memory in MB"
  default = 128
}

variable "timeout" {
  description = "lambda timeout in seconds"
  default = 300
}

variable "stage" {
  description = "api gateway stage name"
  default = "production"
}

variable "endpoint_path" {
  description = "api gateway endpoint"
  default = "endpoint"
}

variable "http_method" {
  description = "api gateway endpoint rest method"
  default = "POST"
}
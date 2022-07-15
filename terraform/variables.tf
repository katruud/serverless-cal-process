variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "calorimeter"
}

variable "handler_name" {
  description = "Lambda handler name"
  type        = string
  default     = "app"
}

variable "deployment_zip" {
  description = "Lambda deployment local file"
  type        = string
  default     = "lambda.zip"
}

variable "lambda_function_s3" {
  description = "Lambda deployment S3 key"
  type        = string
  default     = "lambda_deployment_s3.zip"
}

variable "source_bucket" {
  description = "Source bucket"
  type        = string
  default     = "source-34sds3"
}

variable "destination_bucket" {
  description = "Destination bucket"
  type        = string
  default     = "destination-324fde"
}

variable "table_name" {
  description = "DDB Table name"
  type        = string
  default     = "Calorimeter"
}
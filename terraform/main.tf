provider "aws" {
  region = var.aws_region
}

# Creating Lambda IAM resource (role)
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
# Cloudwatch policy
# To do: limit access
resource "aws_iam_role_policy" "lambda_logging" {
  name = "lambda_logging"
  role = aws_iam_role.iam_for_lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# S3 bucket policy
# To do: limit access
resource "aws_iam_role_policy" "s3_policy" {
  name = "s3_access"
  role = aws_iam_role.iam_for_lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# DynamoDB Policy
# To do: limit access
resource "aws_iam_role_policy" "ddb_policy" {
  name = "dynamo_policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = <<EOF
{  
  "Version": "2012-10-17",
  "Statement":[{
    "Effect": "Allow",
    "Action": [
     "dynamodb:BatchGetItem",
     "dynamodb:GetItem",
     "dynamodb:Query",
     "dynamodb:Scan",
     "dynamodb:BatchWriteItem",
     "dynamodb:PutItem",
     "dynamodb:UpdateItem"
    ],
    "Resource": "arn:aws:dynamodb:us-east-1:987456321456:table/myDB"
   }
  ]
}
EOF
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy above.
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}


# Source bucker trigger
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calorimeter.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source_bucket.id
}

# Lambda deployment
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.destination_bucket.id
  key    = var.lambda_function_s3
  source = var.deployment_zip

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  # etag = filemd5("path/to/file")
}

# Creating Lambda resource
resource "aws_lambda_function" "calorimeter" {
  function_name = var.function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "${var.handler_name}.lambda_handler"
  s3_bucket     = aws_s3_bucket.destination_bucket.id
  s3_key        = var.lambda_function_s3
  runtime       = "python3.9"
  environment {
    variables = {
      deriv_size       = 8
      processed_bucket = var.destination_bucket
      table            = var.table_name
      volume           = 30000
      participant      = "test_participant"
    }
  }
}

# Creating s3 source bucket
resource "aws_s3_bucket" "source_bucket" {
  bucket = var.source_bucket
}

# Creating s3 destination bucket
resource "aws_s3_bucket" "destination_bucket" {
  bucket = var.destination_bucket
}

# Adding S3 bucket as trigger to my lambda and giving the permissions
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.source_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.calorimeter.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]

  }
}
resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calorimeter.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.source_bucket.id}"
}

# DDB Table
resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"

  attribute {
    name = "uuid"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}
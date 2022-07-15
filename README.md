# Serverless Calorimeter Data Processing Concept
This is a SAM template for deploying an AWS Lambda function which reads data from an S3 bucket, 
processes it in Lambda, then writes results to a second S3 bucket and DynamoDB database

Data may also be added and read via the API gateway

## Build
Building requires SAM and Docker to be installed 

To build, from the sam folder, initalize SAM with the template file, then build and deploy
```
SAM build
SAM deploy --guided
```
Guided mode will automatically prompt for the S3 buckets and table name. S3 bucket names must be globally unique.

Alternatively, use the CFN template  or Terraform template and pre-built zip file in the /build folder. 
## Run
To run the function, place a CalRQ data file in the source bucket. An example file is provided in the /sample directory.
A results .csv file will be created in the processed bucket, and data will be added to the DynamoDB table.

## Notes and References
- Equations are derived from literature, primarily Brown et al, doi: 10.1007/BF02442102
- [Amazon API Gateway REST API to Amazon DynamoDB](https://github.com/aws-samples/serverless-patterns/tree/main/apigw-rest-api-dynamodb)
- [Lambda and S3Events DEMO](https://github.com/acantril/learn-cantrill-io-labs/tree/master/00-aws-simple-demos/aws-lambda-s3-events)
- [Implementing bulk CSV ingestion to Amazon DynamoDB](https://github.com/aws-samples/csv-to-dynamodb)

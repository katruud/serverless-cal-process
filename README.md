# Serverless Calorimeter Data Processing POC
This is a SAM template for deploying an AWS Lambda function which reads data from an S3 bucket, 
processes it in Lambda, then writes results to a second S3 bucket and DynamoDB database

## Build
Building requires SAM and Docker to be installed 

To build, initalize SAM with the template file, then build and deploy
```
SAM build
SAM deploy --guided
```
Guided mode will automatically prompt for the S3 buckets and table name. S3 bucket names must be globally unique.

Alternatively, use the CFN template and pre-built zip file in the /build folder. 
## Run
To run the function, place a CalRQ data file in the source bucket. An example file is provided in the /sample directory.
A results .csv file will be created in the processed bucket, and data will be added to the DynamoDB table.

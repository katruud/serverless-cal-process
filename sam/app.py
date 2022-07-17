import json, boto3, os
from dynamo_pandas import put_df
from calorimeter import cal_process

s3_client = boto3.client('s3')
s3 = boto3.resource('s3')
# using client for now, matching example

dynamodb = boto3.resource('dynamodb')

# bucketname for report files
processed_bucket=os.environ['processed_bucket']

# bucket = os.environ['bucket']
# key = os.environ['key']
tableName = os.environ['table']

# Variables
volume = int(os.environ['volume'])
deriv_size = int(os.environ['deriv_size'])
participant = str(os.environ['participant'])

def lambda_handler(event, context):
	print(event)
	
	# get bucket and object key from event object
	source_bucket = event['Records'][0]['s3']['bucket']['name']
	key = event['Records'][0]['s3']['object']['key']
	print(source_bucket,key)

	# try:
	# 	obj = s3.Object(source_bucket, key).get()['Body']
	# except Exception as error:
	# 	print(error)
	# 	print("S3 Object could not be opened. Check environment variable. ")
	try:
		table = dynamodb.Table(tableName)
	except Exception as error:
		print(error)
		print("Error loading DynamoDB table. Check if table was created correctly and environment variable.")

	# Generate a temp name, and set location for our original file
	# object_key = str(uuid.uuid4()) + '-' + key
	object_key = 'temp' + '-' + key
	csv_download_path = '/tmp/{}'.format(object_key)
	
	# Download the source csv from S3 to temp location within execution environment
	with open(csv_download_path,'wb') as csv_file:
		s3_client.download_fileobj(source_bucket, key, csv_file)

	# Perform post-processing
	[resultdf, result_file] = cal_process(csv_download_path, volume, deriv_size, participant)

	# Upload processed report csv
	s3_client.upload_file(result_file, processed_bucket,'processed-{}'.format(key))

	# Add data to database
	put_df(resultdf, table=tableName)

	return {
		'statusCode': 200,
		'body': json.dumps('Processed, uploaded to DynamoDB table and S3')
	}
import os
import subprocess
import boto3
import botocore.config
from datetime import date
from botocore.exceptions import ClientError


def create_backup(event, context):
    """
    Create a backup of an RDS MySQL database and store it on S3.

    """
    host = os.environ['MYSQL_HOST']
    port = os.environ['MYSQL_PORT']
    user = os.environ['MYSQL_USER']
    password = os.environ['MYSQL_PASS']
    database = os.environ['MYSQL_DB']
    s3 = os.environ['S3_BUCKET']

    # Set the path to the executable script in the AWS Lambda environment
    # Source: https://aws.amazon.com/blogs/compute/running-executables-in-aws-lambda/
    os.environ['PATH'] = os.environ['PATH'] + \
        ':' + os.environ['LAMBDA_TASK_ROOT']
    THIS_FOLDER = os.path.dirname(os.path.abspath(__file__))
    backup_file = os.path.join(THIS_FOLDER, 'backup.sh')
    subprocess.check_call(
        [backup_file, host, port, user, password, database, s3])

    # By default, S3 resolves buckets using the internet.
    # To use the VPC endpoint instead, use the 'path' addressing style config.
    # Source: https://stackoverflow.com/a/44478894
    client = boto3.client('s3', 'us-east-1', config=botocore.config.Config(
        s3={'addressing_style': 'path'}, connect_timeout=5, retries={'max_attempts': 0}))

    file_name = str(date.today()) + '.sql'
    file_path = '/tmp/' + file_name

    try:
        response = client.upload_file(file_path, 'rdsvc-db-backups', file_name)
    except ClientError as e:
        logging.error(e)
        return False
    return True

import os
import subprocess


def create_backup(event, context):
    """
    Create a backup of an RDS MySQL database and store it on S3.

    """

    # Set the path to the executable script in the AWS Lambda environment
    # Source: https://aws.amazon.com/blogs/compute/running-executables-in-aws-lambda/
    os.environ['PATH'] = os.environ['PATH'] + ':' + os.environ['LAMBDA_TASK_ROOT']
    subprocess.check_call(["cp ./backup.sh /tmp/backup.sh && chmod 755 /tmp/backup.sh"], shell=True)
    subprocess.check_call(["./backup.sh", os.environ['MYSQL_HOST'], os.environ['MYSQL_PORT'], os.environ['MYSQL_USER'], os.environ['MYSQL_PASS'], os.environ['MYSQL_DB'], os.environ['S3_BUCKET']])

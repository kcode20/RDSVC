# Create Role for Lambda Function 
resource "aws_iam_role" "lambda-role" {
  name               = "rdsvc-lambda-role"
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

  tags = {
    Name = "rdsvc-lambda-role"
  }
}

# Create IAM Policy
resource "aws_iam_policy" "rdsvc-lambda-policy" {
  name        = "rdsvc-lambda-policy"
  description = "A policy for the rdsvc lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*", 
        "rds:*",
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda-role-policy-attachment" {
  policy_arn = aws_iam_policy.rdsvc-lambda-policy.arn
  role       = aws_iam_role.lambda-role.name
}

# Create Lambda Function
resource "aws_lambda_function" "rdsvc-lambda-function" {
  function_name = "rdsvc-lambda-function"
  filename      = "rdsvc-lambda-package.zip"
  handler       = "rdsvc-lambda-package.lambda.create_backup"
  role          = aws_iam_role.lambda-role.arn
  runtime       = "python3.7"
  timeout       = 100

  environment {
    variables = {
      MYSQL_DB   = aws_db_instance.mysql-db.name
      MYSQL_HOST = aws_db_instance.mysql-db.address
      MYSQL_PORT = aws_db_instance.mysql-db.port
      MYSQL_USER = aws_db_instance.mysql-db.username
      MYSQL_PASS = var.db_password
      S3_BUCKET  = aws_s3_bucket.rdsvc-db-backups.id
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.sg-web.id]
    subnet_ids         = [aws_subnet.public-subnet.id]
  }

  tags = {
    Name = "rdsvc-lambda-function"
  }
}

# Create VPC Endpoint
resource "aws_vpc_endpoint" "rdsvc-vpc-endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.web-public-rt.id]
}

# Create Cloudwatch Event Rule
resource "aws_cloudwatch_event_rule" "lambda-function-schedule-rule" {
  name                = "rdsvc-backup-lambda-rule"
  description         = "Execute the Lambda Function Daily at 7am"
  schedule_expression = "cron(0 7 * * ? *)"
  is_enabled          = true

  tags = {
    Name = "rdsvc-backup-lambda-rule"
  }
}

# Provide Cloudwatch event target resource
resource "aws_cloudwatch_event_target" "lambda-function-schedule-target" {
  arn  = aws_lambda_function.rdsvc-lambda-function.arn
  rule = aws_cloudwatch_event_rule.lambda-function-schedule-rule.name
}

# Give Cloudwatch permission to access lambda
resource "aws_lambda_permission" "lambda-function-schedule-permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rdsvc-lambda-function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda-function-schedule-rule.arn
}

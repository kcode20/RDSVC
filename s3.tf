/*
This file creates an S3 resource.
It defines an S3 bucket.
*/

# Create an S3 bucket
resource "aws_s3_bucket" "rdsvc-db-backups" {
  bucket = "rdsvc-db-backups"
  acl    = "private"

  tags = {
    Name = "Database Backups"
  }
}

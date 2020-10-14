# Create an S3 bucket
resource "aws_s3_bucket" "rdsvc-db-backups" {
  bucket = "rdsvc-db-backups"
  acl    = "private"

  tags = {
    Name = "Database Backups"
  }
}

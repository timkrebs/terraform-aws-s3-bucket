provider "aws" {
  region = var.aws_region
}

module "s3_bucket" {
  source = "../../"

  bucket_name = "${var.prefix}-basic-bucket"
  environment = "dev"

  versioning_enabled = true
  
  # Server-side encryption
  sse_algorithm = "AES256"

  # Lifecycle rules
  lifecycle_rules = [
    {
      id     = "archive-old-objects"
      status = "Enabled"
      
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      
      expiration = {
        days = 365
      }
    }
  ]

  tags = {
    Project = "example"
  }
}
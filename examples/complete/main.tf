provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS key for bucket encryption
resource "aws_kms_key" "bucket" {
  description             = "${var.prefix}-s3-bucket-key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
  }
}

resource "aws_kms_alias" "bucket" {
  name          = "alias/${var.prefix}-s3-bucket"
  target_key_id = aws_kms_key.bucket.key_id
}

# Logging bucket
module "log_bucket" {
  source = "../../"

  bucket_name = "${var.prefix}-logs"
  environment = var.environment

  versioning_enabled = true
  
  lifecycle_rules = [
    {
      id     = "expire-logs"
      status = "Enabled"
      
      expiration = {
        days = 90
      }
      
      noncurrent_version_expiration = {
        days = 30
      }
    }
  ]

  # Grant log delivery permissions
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.prefix}-logs/*"
      }
    ]
  })

  tags = {
    Purpose = "logging"
  }
}

# Main bucket with complete configuration
module "s3_bucket" {
  source = "../../"

  bucket_name = "${var.prefix}-complete"
  environment = var.environment

  force_destroy = var.environment != "prod"

  # Versioning and MFA delete
  versioning_enabled = true
  mfa_delete         = var.environment == "prod"

  # Encryption with KMS
  sse_algorithm      = "aws:kms"
  kms_key_id         = aws_kms_key.bucket.arn
  bucket_key_enabled = true

  # Access logging
  logging_config = {
    target_bucket = module.log_bucket.bucket_id
    target_prefix = "s3-access-logs/"
  }

  # Lifecycle rules
  lifecycle_rules = [
    {
      id     = "transition-and-expire"
      status = "Enabled"
      
      filter = {
        prefix = "archive/"
      }
      
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 180
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      
      expiration = {
        days = 730
      }
      
      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
      
      noncurrent_version_expiration = {
        days = 90
      }
    },
    {
      id     = "abort-multipart"
      status = "Enabled"
      
      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ]

  # CORS configuration
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST"]
      allowed_origins = ["https://example.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  # Bucket metrics
  bucket_metrics = {
    entire-bucket = {
      # No filter means metrics for entire bucket
    }
    documents = {
      filter = {
        prefix = "documents/"
      }
    }
  }

  # Bucket inventory
  bucket_inventory = {
    entire-bucket = {
      frequency = "Weekly"
      destination = {
        format     = "CSV"
        bucket_arn = module.log_bucket.bucket_arn
        prefix     = "inventory/"
      }
      optional_fields = [
        "Size",
        "LastModifiedDate",
        "StorageClass",
        "ETag",
        "IsMultipartUploaded",
        "ReplicationStatus",
        "EncryptionStatus"
      ]
    }
  }

  # Bucket policy
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.prefix}-complete/*",
          "arn:aws:s3:::${var.prefix}-complete"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "EnforceEncryptionInTransit"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.prefix}-complete/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })

  tags = {
    Project     = "example"
    Purpose     = "complete-example"
    CostCenter  = "engineering"
  }
}

# CloudWatch alarm for bucket size
resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  alarm_name          = "${var.prefix}-bucket-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = var.bucket_size_alarm_threshold
  alarm_description   = "This metric monitors bucket size"
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = module.s3_bucket.bucket_id
    StorageType = "StandardStorage"
  }

  tags = {
    Environment = var.environment
  }
}
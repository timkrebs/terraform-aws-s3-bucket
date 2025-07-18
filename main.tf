locals {
  bucket_name = var.use_prefix ? null : var.bucket_name
  bucket_prefix = var.use_prefix ? var.bucket_name : null
  
  common_tags = merge(
    var.tags,
    {
      Module      = "terraform-aws-s3-bucket"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  )

  lifecycle_rules = concat(
    var.lifecycle_rules,
    var.enable_intelligent_tiering ? [{
      id     = "intelligent-tiering"
      status = "Enabled"
      
      transition = [{
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }]
      
      noncurrent_version_transition = [{
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }]
    }] : []
  )
}

resource "aws_s3_bucket" "this" {
  count = var.create_bucket ? 1 : 0

  bucket        = local.bucket_name
  bucket_prefix = local.bucket_prefix
  force_destroy = var.force_destroy

  tags = merge(
    local.common_tags,
    {
      Name = var.bucket_name
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_acl" "this" {
  count = var.create_bucket && var.acl != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  acl    = var.acl

  depends_on = [
    aws_s3_bucket_ownership_controls.this
  ]
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}

resource "aws_s3_bucket_logging" "this" {
  count = var.create_bucket && var.logging_config != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  target_bucket = var.logging_config.target_bucket
  target_prefix = var.logging_config.target_prefix
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.create_bucket && length(local.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  dynamic "rule" {
    for_each = local.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "filter" {
        for_each = lookup(rule.value, "filter", null) != null ? [rule.value.filter] : []
        content {
          prefix = lookup(filter.value, "prefix", null)

          dynamic "tag" {
            for_each = lookup(filter.value, "tags", {})
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transition", [])
        content {
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transition", [])
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", null) != null ? [rule.value.expiration] : []
        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expiration", null) != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = lookup(rule.value, "abort_incomplete_multipart_upload", null) != null ? [rule.value.abort_incomplete_multipart_upload] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "this" {
  count = var.create_bucket && length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      id              = lookup(cors_rule.value, "id", null)
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "this" {
  count = var.create_bucket && var.replication_configuration != null ? 1 : 0

  role   = var.replication_configuration.role
  bucket = aws_s3_bucket.this[0].id

  dynamic "rule" {
    for_each = var.replication_configuration.rules
    content {
      id       = rule.value.id
      priority = lookup(rule.value, "priority", null)
      status   = rule.value.status

      dynamic "filter" {
        for_each = lookup(rule.value, "filter", null) != null ? [rule.value.filter] : []
        content {
          prefix = lookup(filter.value, "prefix", null)

          dynamic "tag" {
            for_each = lookup(filter.value, "tags", {})
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      destination {
        bucket        = rule.value.destination.bucket
        storage_class = lookup(rule.value.destination, "storage_class", "STANDARD")

        dynamic "encryption_configuration" {
          for_each = lookup(rule.value.destination, "replica_kms_key_id", null) != null ? [1] : []
          content {
            replica_kms_key_id = rule.value.destination.replica_kms_key_id
          }
        }

        dynamic "replication_time" {
          for_each = lookup(rule.value.destination, "replication_time", null) != null ? [rule.value.destination.replication_time] : []
          content {
            status = replication_time.value.status
            time {
              minutes = replication_time.value.minutes
            }
          }
        }

        dynamic "metrics" {
          for_each = lookup(rule.value.destination, "metrics", null) != null ? [rule.value.destination.metrics] : []
          content {
            status = metrics.value.status
            event_threshold {
              minutes = metrics.value.minutes
            }
          }
        }
      }

      dynamic "delete_marker_replication" {
        for_each = lookup(rule.value, "delete_marker_replication", null) != null ? [rule.value.delete_marker_replication] : []
        content {
          status = delete_marker_replication.value.status
        }
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.this
  ]
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = var.create_bucket && var.object_lock_configuration != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  object_lock_enabled = "Enabled"

  dynamic "rule" {
    for_each = var.object_lock_configuration.rule != null ? [var.object_lock_configuration.rule] : []
    content {
      default_retention {
        mode  = rule.value.default_retention.mode
        days  = lookup(rule.value.default_retention, "days", null)
        years = lookup(rule.value.default_retention, "years", null)
      }
    }
  }
}

resource "aws_s3_bucket_notification" "this" {
  count = var.create_bucket && var.bucket_notification != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  dynamic "topic" {
    for_each = lookup(var.bucket_notification, "topic", [])
    content {
      id            = topic.value.id
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = lookup(topic.value, "filter_prefix", null)
      filter_suffix = lookup(topic.value, "filter_suffix", null)
    }
  }

  dynamic "queue" {
    for_each = lookup(var.bucket_notification, "queue", [])
    content {
      id            = queue.value.id
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = lookup(queue.value, "filter_prefix", null)
      filter_suffix = lookup(queue.value, "filter_suffix", null)
    }
  }

  dynamic "lambda_function" {
    for_each = lookup(var.bucket_notification, "lambda_function", [])
    content {
      id                  = lambda_function.value.id
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lookup(lambda_function.value, "filter_prefix", null)
      filter_suffix       = lookup(lambda_function.value, "filter_suffix", null)
    }
  }
}

resource "aws_s3_bucket_metric" "this" {
  for_each = var.create_bucket ? var.bucket_metrics : {}

  bucket = aws_s3_bucket.this[0].id
  name   = each.key

  dynamic "filter" {
    for_each = lookup(each.value, "filter", null) != null ? [each.value.filter] : []
    content {
      prefix = lookup(filter.value, "prefix", null)
    }
  }
}

resource "aws_s3_bucket_inventory" "this" {
  for_each = var.create_bucket ? var.bucket_inventory : {}

  bucket = aws_s3_bucket.this[0].id
  name   = each.key

  included_object_versions = lookup(each.value, "included_object_versions", "All")

  schedule {
    frequency = each.value.frequency
  }

  destination {
    bucket {
      format     = each.value.destination.format
      bucket_arn = each.value.destination.bucket_arn
      prefix     = lookup(each.value.destination, "prefix", null)

      dynamic "encryption" {
        for_each = lookup(each.value.destination, "encryption", null) != null ? [each.value.destination.encryption] : []
        content {
          dynamic "sse_kms" {
            for_each = lookup(encryption.value, "sse_kms", null) != null ? [encryption.value.sse_kms] : []
            content {
              key_id = sse_kms.value.key_id
            }
          }

          dynamic "sse_s3" {
            for_each = lookup(encryption.value, "sse_s3", null) != null ? [encryption.value.sse_s3] : []
            content {}
          }
        }
      }
    }
  }

  optional_fields = lookup(each.value, "optional_fields", null)

  dynamic "filter" {
    for_each = lookup(each.value, "filter", null) != null ? [each.value.filter] : []
    content {
      prefix = filter.value.prefix
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.create_bucket && var.bucket_policy != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = var.bucket_policy

  depends_on = [
    aws_s3_bucket_public_access_block.this
  ]
}
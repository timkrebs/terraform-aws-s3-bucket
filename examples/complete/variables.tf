variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "us-east-1"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "example"
}

variable "bucket_size_alarm_threshold" {
  description = "The threshold for the bucket size alarm"
  type        = number
  default     = 1000000000
}

variable "create_bucket" {
  description = "Whether to create the S3 bucket"
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "The name of the bucket. If omitted, Terraform will assign a random, unique name"
  type        = string
  default     = null
}

variable "use_prefix" {
  description = "Whether to use bucket_name as a prefix instead of an explicit name"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"
  type        = bool
  default     = false
}

variable "object_ownership" {
  description = "Object ownership. Valid values: BucketOwnerPreferred, ObjectWriter or BucketOwnerEnforced"
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "acl" {
  description = "The canned ACL to apply. Valid values are private, public-read, public-read-write, aws-exec-read, authenticated-read, and log-delivery-write"
  type        = string
  default     = null
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "versioning_enabled" {
  description = "Whether versioning is enabled"
  type        = bool
  default     = true
}

variable "mfa_delete" {
  description = "Whether MFA delete is enabled"
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "The AWS KMS key ID used for the SSE-KMS encryption"
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Whether to use Amazon S3 Bucket Keys for SSE-KMS"
  type        = bool
  default     = true
}

variable "logging_config" {
  description = "Logging configuration for the bucket"
  type = object({
    target_bucket = string
    target_prefix = string
  })
  default = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules to configure"
  type        = list(any)
  default     = []
}

variable "enable_intelligent_tiering" {
  description = "Whether to automatically enable Intelligent-Tiering for all objects"
  type        = bool
  default     = false
}

variable "cors_rules" {
  description = "List of CORS rules"
  type = list(object({
    id              = optional(string)
    allowed_headers = optional(list(string))
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  default = []
}

variable "replication_configuration" {
  description = "Replication configuration"
  type = object({
    role = string
    rules = list(object({
      id       = string
      status   = string
      priority = optional(number)
      filter   = optional(any)
      destination = object({
        bucket             = string
        storage_class      = optional(string)
        replica_kms_key_id = optional(string)
        replication_time   = optional(any)
        metrics            = optional(any)
      })
      delete_marker_replication = optional(any)
    }))
  })
  default = null
}

variable "object_lock_configuration" {
  description = "Object Lock configuration"
  type = object({
    rule = optional(object({
      default_retention = object({
        mode  = string
        days  = optional(number)
        years = optional(number)
      })
    }))
  })
  default = null
}

variable "bucket_notification" {
  description = "S3 bucket notification configuration"
  type        = any
  default     = null
}

variable "bucket_metrics" {
  description = "Map of bucket metrics configurations"
  type        = map(any)
  default     = {}
}

variable "bucket_inventory" {
  description = "Map of bucket inventory configurations"
  type        = map(any)
  default     = {}
}

variable "bucket_policy" {
  description = "The bucket policy as a JSON document"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the bucket"
  type        = map(string)
  default     = {}
}
# AWS S3 Bucket Terraform Module

This module creates AWS S3 buckets with comprehensive security, lifecycle, and management features following AWS best practices.

## Features

- Server-side encryption (SSE-S3 or SSE-KMS)
- Versioning with optional MFA delete
- Object Lock configuration
- Lifecycle policies with Intelligent-Tiering support
- Cross-Region Replication
- Access logging
- CORS configuration
- Event notifications
- Bucket metrics and inventory
- CloudWatch alarms
- Public access blocking (default enabled)
- Comprehensive tagging

## Usage

### Basic Example

```hcl
module "s3_bucket" {
  source  = "app.terraform.io/YOUR-ORG/s3-bucket/aws"
  version = "1.0.0"

  bucket_name = "my-app-bucket"
  environment = "dev"
  
  versioning_enabled = true
  
  tags = {
    Project = "my-project"
  }
}
```

### Complete Example

See the [complete example](./examples/complete) for a full working example including KMS encryption, lifecycle rules, replication, and monitoring.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `bucket_name` | The name of the bucket | `string` | `null` | no |
| `create_bucket` | Whether to create the S3 bucket | `bool` | `true` | no |
| `environment` | Environment name | `string` | `"dev"` | no |
| `versioning_enabled` | Whether versioning is enabled | `bool` | `true` | no |
| `sse_algorithm` | The server-side encryption algorithm | `string` | `"AES256"` | no |
| `kms_key_id` | The AWS KMS key ID used for SSE-KMS encryption | `string` | `null` | no |
| `lifecycle_rules` | List of lifecycle rules to configure | `list(any)` | `[]` | no |
| `cors_rules` | List of CORS rules | `list(object)` | `[]` | no |
| `logging_config` | Logging configuration for the bucket | `object` | `null` | no |
| `tags` | A map of tags to assign to the bucket | `map(string)` | `{}` | no |

> **Note**: See [variables.tf](./variables.tf) for the complete list of available inputs.

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | The name of the bucket |
| `bucket_arn` | The ARN of the bucket |
| `bucket_domain_name` | The bucket domain name |
| `bucket_regional_domain_name` | The bucket region-specific domain name |
| `bucket_hosted_zone_id` | The Route 53 Hosted Zone ID for this bucket's region |
| `bucket_region` | The AWS region this bucket resides in |

> **Note**: See [outputs.tf](./outputs.tf) for the complete list of available outputs.

## Security Best Practices

1. **Encryption**: All buckets are encrypted by default using SSE-S3. Use SSE-KMS for additional security.
2. **Public Access**: Public access is blocked by default on all buckets.
3. **Versioning**: Enabled by default to protect against accidental deletion.
4. **SSL/TLS**: Example policies enforce encrypted transport.
5. **Logging**: Enable access logging for audit trails.
6. **Lifecycle**: Configure lifecycle rules to manage costs and compliance.

## Cost Optimization

- Use Intelligent-Tiering for automatic cost optimization
- Configure lifecycle policies to transition objects to cheaper storage classes
- Set up expiration rules for temporary data
- Enable bucket metrics to monitor usage

## Advanced Configuration Examples

### With KMS Encryption

```hcl
module "s3_bucket" {
  source  = "app.terraform.io/YOUR-ORG/s3-bucket/aws"
  version = "1.0.0"

  bucket_name        = "my-encrypted-bucket"
  sse_algorithm      = "aws:kms"
  kms_key_id         = aws_kms_key.bucket.arn
  bucket_key_enabled = true
}
```

### With Lifecycle Rules

```hcl
module "s3_bucket" {
  source  = "app.terraform.io/YOUR-ORG/s3-bucket/aws"
  version = "1.0.0"

  bucket_name = "my-lifecycle-bucket"
  
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
}
```

### With CORS Configuration

```hcl
module "s3_bucket" {
  source  = "app.terraform.io/YOUR-ORG/s3-bucket/aws"
  version = "1.0.0"

  bucket_name = "my-cors-bucket"
  
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST"]
      allowed_origins = ["https://example.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
}
```

## Module Development

### Running Tests

```bash
cd test/
go test -v -timeout 30m
```

### Pre-commit Hooks

This module uses pre-commit hooks to ensure code quality:

```bash
pre-commit install
pre-commit run --all-files
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Apache 2.0 Licensed. See [LICENSE](./LICENSE) for full details.
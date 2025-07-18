output "bucket_id" {
  description = "The name of the bucket"
  value       = try(aws_s3_bucket.this[0].id, "")
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = try(aws_s3_bucket.this[0].arn, "")
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = try(aws_s3_bucket.this[0].bucket_domain_name, "")
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = try(aws_s3_bucket.this[0].bucket_regional_domain_name, "")
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = try(aws_s3_bucket.this[0].hosted_zone_id, "")
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = try(aws_s3_bucket.this[0].region, "")
}

output "bucket_website_endpoint" {
  description = "The website endpoint, if the bucket is configured with a website"
  value       = try(aws_s3_bucket.this[0].website_endpoint, "")
}

output "bucket_website_domain" {
  description = "The domain of the website endpoint, if the bucket is configured with a website"
  value       = try(aws_s3_bucket.this[0].website_domain, "")
}
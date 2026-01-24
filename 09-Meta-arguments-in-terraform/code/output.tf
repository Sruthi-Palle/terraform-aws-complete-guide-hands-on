# =============================================================================
# Output Variables - Demonstrating different output patterns with count and for_each
# =============================================================================

# -----------------------------------------------------------------------------
# Outputs for COUNT-based resources
# -----------------------------------------------------------------------------

# Using splat expression to get all bucket names
output "s3_bucket_names_count" {
  description = "Names of S3 buckets created with count (using splat expression)"
  value       = aws_s3_bucket.example_count[*].id
}

# Using splat expression to get all bucket ARNs
output "s3_bucket_arns_count" {
  description = "ARNs of S3 buckets created with count"
  value       = aws_s3_bucket.example_count[*].arn
}

# -----------------------------------------------------------------------------
# Outputs for FOR_EACH-based resources
# -----------------------------------------------------------------------------

# Using for loop to get bucket names from for_each
output "s3_bucket_names_foreach" {
  description = "Names of S3 buckets created with for_each (using for loop)"
  value       = [for bucket in aws_s3_bucket.example_foreach : bucket.id]
}

# Creating a map output with bucket names and ARNs
output "s3_bucket_details_foreach" {
  description = "Map of bucket names to ARNs from for_each"
  value = {
    for key, bucket in aws_s3_bucket.example_foreach :
    key => {
      id  = bucket.id
      arn = bucket.arn
    }
  }
}

# -----------------------------------------------------------------------------
# Outputs for meta-argument examples
# -----------------------------------------------------------------------------

# depends_on example outputs
output "primary_bucket_id" {
  description = "Primary bucket ID (for depends_on example)"
  value       = aws_s3_bucket.primary.id
}

output "dependent_bucket_id" {
  description = "Dependent bucket ID (created after primary)"
  value       = aws_s3_bucket.dependent.id
}

# lifecycle example output
output "lifecycle_bucket_id" {
  description = "Lifecycle example bucket ID"
  value       = aws_s3_bucket.lifecycle_example.id
}

# -----------------------------------------------------------------------------
# Count total resources created
# -----------------------------------------------------------------------------

output "total_s3_buckets_created" {
  description = "Total number of S3 buckets created"
  value       = length(var.s3_bucket_names) + length(var.s3_bucket_set) + 3 # +3 for primary, dependent, lifecycle
}


# -----------------------------------------------------------------------------
# Advanced: Conditional outputs and transformations
# -----------------------------------------------------------------------------

# All bucket names combined
output "all_bucket_names" {
  description = "All S3 bucket names created (count + for_each)"
  value = concat(
    aws_s3_bucket.example_count[*].id,
    [for bucket in aws_s3_bucket.example_foreach : bucket.id]
  )
}


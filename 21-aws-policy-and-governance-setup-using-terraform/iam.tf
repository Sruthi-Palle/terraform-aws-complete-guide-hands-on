# ------------------------------------------------------------------------------
# 1. IAM Policy Examples
# ------------------------------------------------------------------------------

# Create a custom IAM policy that enforces MFA for deleting S3 objects
resource "aws_iam_policy" "mfa_delete_policy" {
 /*
  When this policy is attached to an IAM user (as it is to aws_iam_user.demo_user in this project), any attempt by that user to perform s3:DeleteObject
  will be checked against this policy. If the user did not authenticate with MFA for their current session, the condition "aws:MultiFactorAuthPresent":
  "false" evaluates to true, and the Deny effect blocks the deletion. If the user did authenticate with MFA, the condition is not met, and this
  particular Deny policy does not block the action (though other policies might still apply).
  */

  name        = "${var.project_name}-mfa-delete-policy"
  description = "Policy that requires MFA to delete S3 objects"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyDeleteWithoutMFA"
        Effect   = "Deny"
        Action   = "s3:DeleteObject"
        Resource = "*" #This policy applies to s3:DeleteObject actions on any S3 object across all buckets in the account.
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    
    ]
  })
  /* 
  `BoolIfExists`: This operator is important because it ensures that if aws:MultiFactorAuthPresent is not present (e.g., for certain
         programmatic access without MFA context, like an EC2 instance role accessing S3 without specifically assuming a role with MFA), the condition
         simply isn't evaluated as a true match for denial, allowing those operations to proceed without being unnecessarily blocked. However, for a
         user session, if they haven't used MFA, aws:MultiFactorAuthPresent will be false.
  */
}

# IAM Policy: Enforce encryption in transit for S3
resource "aws_iam_policy" "enforce_s3_encryption_transit" {
  name        = "${var.project_name}-s3-encryption-transit"
  description = "Deny S3 actions without encryption in transit"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyUnencryptedObjectUploads"
        Effect   = "Deny"
        Action   = "s3:PutObject"
        Resource = "*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# IAM Policy: Require tagging for resource creation
resource "aws_iam_policy" "require_tags_policy" {
  name        = "${var.project_name}-require-tags"
  description = "Require specific tags when creating resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RequireTagsOnEC2"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotLike = {
            "aws:RequestTag/Environment" = ["dev", "staging", "prod"]
          }
        }
      },
      {
        Sid    = "RequireOwnerTag"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          "Null" = {
            "aws:RequestTag/Owner" = "true"
          }
        }
      }
    ]
  })
}

# IAM User for demonstration
resource "aws_iam_user" "demo_user" {
  name = "${var.project_name}-demo-user"
  path = "/governance/"

  tags = {
    Environment = "demo"
    Purpose     = "governance-training"
  }
}

# Attach MFA delete policy to demo user
resource "aws_iam_user_policy_attachment" "demo_user_mfa" {
  user       = aws_iam_user.demo_user.name
  policy_arn = aws_iam_policy.mfa_delete_policy.arn
}

# ------------------------------------------------------------------------------
# 2. IAM Role for AWS Config Service
# ------------------------------------------------------------------------------

# IAM Role for AWS Config Service
resource "aws_iam_role" "config_role" {
   #Trust Relationship: It establishes a trust relationship that allows the AWS Config service to assume this role.
  name = "${var.project_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Attach managed policy to Config Role
resource "aws_iam_role_policy_attachment" "config_policy_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Additional policy for Config to write to S3
resource "aws_iam_role_policy" "config_s3_policy" {
  name = "${var.project_name}-config-s3-policy"
  role = aws_iam_role.config_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.config_bucket.arn,
          "${aws_s3_bucket.config_bucket.arn}/*"
        ]
      }
    ]
  })
}

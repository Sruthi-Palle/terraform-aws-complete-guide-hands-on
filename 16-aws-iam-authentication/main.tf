# Get AWS Account ID
data "aws_caller_identity" "current" {} #This retrieves information about the AWS account executing the Terraform code, specifically to get the AWS Account ID.

# Output the account ID
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# Read users from CSV
locals {
  users = csvdecode(file("users.csv"))
  #Parses the CSV content into a list of maps. Each map represents a user, with keys corresponding to the CSV headers (first_name, last_name, department, job_title).
  # This locals block makes this structured user data available for use throughout the Terraform configuration.
}

# Output user names
output "user_names" {
  value = [for user in local.users : "${user.first_name} ${user.last_name}"]
}

# Create IAM users
resource "aws_iam_user" "users" {
  #This is a for_each loop that iterates over each user entry parsed from users.csv. 
  #This allows Terraform to create multiple aws_iam_user resources based on the dynamic data.
  for_each = { for user in local.users : user.first_name => user }

  name = lower("${substr(each.value.first_name, 0, 1)}${each.value.last_name}")
  path = "/users/"

  tags = {
    "DisplayName" = "${each.value.first_name} ${each.value.last_name}"
    "Department"  = each.value.department
    "JobTitle"    = each.value.job_title
  }
}

# Create IAM user login profile (password)
resource "aws_iam_user_login_profile" "users" {
  for_each = aws_iam_user.users

  user                    = each.value.name
  password_reset_required = true

  lifecycle {
    ignore_changes = [
      password_length,
      password_reset_required,
    ]
  }
}

output "user_passwords" {
  value = {
    for user, profile in aws_iam_user_login_profile.users :
    user => "Password created - user must reset on first login"
  }
  sensitive = true
}

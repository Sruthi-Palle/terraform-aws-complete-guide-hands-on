# Terraform Variable Precedence and Usage Guide

Terraform loads variables in a specific order, with later sources taking precedence over earlier ones. This means the value found in a higher precedence source will override any values set in lower precedence sources.

Here's the order from lowest precedence (least specific) to highest precedence (most specific):

---

## 1. Default Values (in variable declarations)

**Source:** Defined directly within the variable block in your `.tf` files (e.g., `variables.tf`).

**Example:**

```hcl
variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro" # Lowest precedence
}
```

**Explanation:**
This is the baseline value. If no other method provides a value for the variable, Terraform will use this default. If a variable is declared without a default value, it becomes a required variable, and Terraform will prompt for a value if none is provided by a higher-precedence source.

---

## 2. Environment Variables (`TF_VAR_` prefix)

**Source:** Environment variables on the system where Terraform is executed, prefixed with `TF_VAR_` followed by the variable name.

**Example:**

```bash
export TF_VAR_instance_type="t2.small"
```

**Explanation:**
These provide values that persist across your current terminal session or are set in CI/CD environments. They override default values.

**Good Practice:**
Useful for sensitive values (like API keys or passwords, though secret management tools are better for production) or for setting common values in a CI/CD pipeline without modifying files.

---

## 3. `terraform.tfvars` file (and `terraform.tfvars.json`)

**Source:** A file named exactly `terraform.tfvars` (or `terraform.tfvars.json`) in the root of your Terraform configuration directory. This file is automatically loaded by Terraform.

**Example (`terraform.tfvars`):**

```hcl
instance_type = "t2.medium"
```

**Explanation:**
This is a common place to set project-specific default values that are usually committed to version control. Values in this file override environment variables and default values.

---

## 4. `*.auto.tfvars` files (and `*.auto.tfvars.json`)

**Source:** Any files in the root of your Terraform configuration directory ending with `.auto.tfvars` (e.g., `dev.auto.tfvars`, `prod.auto.tfvars`) or `.auto.tfvars.json`. These files are also automatically loaded by Terraform in lexical (alphabetical) order of their filenames.

**Example (`prod.auto.tfvars`):**

```hcl
instance_type = "t2.large"
```

**Explanation:**
These are very useful for separating environment-specific configurations. For instance, `dev.auto.tfvars` might contain values for your development environment, and `prod.auto.tfvars` for production.

Because they are loaded alphabetically, if you have `a.auto.tfvars` and `b.auto.tfvars` and both define the same variable, `b.auto.tfvars` will take precedence.

They override `terraform.tfvars`, environment variables, and default values.

---

## 5. Command-Line Options (`-var-file` and `-var`)

### Highest Precedence – Explicit Control

Values provided directly on the terraform command line hold the absolute highest precedence in variable resolution. They will override any value set for the same variable in default declarations, environment variables, `terraform.tfvars`, or `*.auto.tfvars` files.

This makes them ideal for:

- Temporary Overrides: Quickly testing a different value without modifying configuration files.
- Ad-Hoc Deployments: Supplying unique values for one-off tasks.
- CI/CD Pipeline Integration: Passing dynamic or sensitive values that are generated or retrieved at runtime (e.g., from a secret manager).

Terraform offers two primary ways to provide variables via the command line:

---

### 5.1 Loading Entire Variable Files: `-var-file=<PATH>`

This option allows you to explicitly load one or more `.tfvars` files that are not automatically loaded by Terraform (like terraform.tfvars or \*.auto.tfvars).

**Purpose:**
To bring in a set of variable values from a specific file, especially when you have multiple sets of variables (e.g., `dev.tfvars`, `prod.tfvars`) and you want to choose which one to apply.

**Behaviour:**
Terraform will process these files in the exact order they are specified on the command line. If the same variable is defined in multiple files specified this way, the value from the last-specified file will take precedence.

**Example:**

```hcl
# common.tfvars
region = "us-east-1"
instance_type = "t2.micro"
```

```hcl
# override.tfvars
instance_type = "t2.medium"
```

```bash
terraform apply -var-file="common.tfvars" -var-file="override.tfvars"
```

In this case:

- `region` will be `"us-east-1"`
- `instance_type` will be `"t2.medium"`
  because override.tfvars (which comes last) overrides the value from common.tfvars.

**When to Use:**
When you have predefined environment-specific .tfvars files (e.g., staging.tfvars, production.tfvars) that you want to explicitly select for a deployment.

---

### 5.2. Setting Individual Variables: -var="KEY=VALUE"

This option allows you to set the value for a single variable directly on the command line.

## Purpose

Ideal for overriding just one or two specific variables, or for passing values that might be generated dynamically (e.g., a build number, a unique ID).

## Behavior

If you specify the same variable multiple times using -var, Terraform will use the value from the last -var flag encountered on the command line.

## Examples

### Simple Override

```bash
terraform apply -var="instance_type=t2.xlarge"
```

Here, instance_type will be t2.xlarge, regardless of any other definitions.

### Overriding Multiple Variables

```bash
terraform apply -var="instance_type=t2.large" -var="environment=production"
```

### Complex Types (Lists, Maps, Objects)

When providing complex values, you need to use proper JSON-like syntax and ensure the string is correctly quoted and escaped for your shell. Using single quotes around the entire -var argument is generally safer.

#### For a list

```bash
terraform apply -var='security_group_ids=["sg-0abc123def", "sg-456ghi789jkl"]'
```

#### For a map (or object)

```bash
terraform apply -var='tags_map={"Project"="TerraformDemo", "Owner"="DevOpsTeam"}'
```

## When to Use

For quick tests, single-parameter changes, or pushing dynamic values from shell scripts or CI/CD environments.

## Key Takeaway

Command-line variables offer the most granular and immediate control over your Terraform variables, always taking precedence over values defined in your configuration files or environment.

If you use both in the same command, their order on the command line determines precedence.

If you run:

```bash
terraform apply -var="type=t2.nano" -var-file="prod.tfvars"
```

And prod.tfvars contains:

```hcl
type = "t2.large"
```

The last argument (the file) wins.

---

## Summary Table (Lowest to Highest Precedence)

| Precedence | Source Type              | How it's Set/Used                                    | Notes                                                                                       |
| ---------- | ------------------------ | ---------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Lowest     | Default value            | default = "value" in variable block                  | Used if no other value is provided.                                                         |
| 2          | Environment variables    | export TF_VAR_variable_name="value"                  | Overrides defaults. Useful for CI/CD or sensitive data (though secret managers are better). |
| 3          | terraform.tfvars         | File terraform.tfvars (or .json) auto-loaded         | Common for project-wide default values.                                                     |
| 4          | \*.auto.tfvars           | Files ending in .auto.tfvars (or .json) auto-loaded. | Loaded alphabetically. Good for environment-specific configs. Overrides terraform.tfvars.   |
| Highest    | Command-line (-var-file) | terraform ... -var-file="path/to/file.tfvars"        | Explicitly loaded files. Order matters if multiple are specified.                           |
| Highest    | Command-line (-var)      | terraform ... -var="variable=value"                  | Direct override for individual variables. Last specified -var takes precedence.             |

---

## Practical Implications and Best Practices

- **Readability:** Use variables.tf to declare all variables and their types, descriptions, and sensible defaults.
- **Layering:** Leverage the precedence order to layer your configurations:
  - variables.tf: Global defaults that rarely change.
  - terraform.tfvars: Project-specific defaults that are stable.
  - \*.auto.tfvars: Environment-specific overrides (e.g., dev.auto.tfvars, prod.auto.tfvars).
  - Command Line: Temporary, ad-hoc, or pipeline-driven overrides.

- **Sensitive Data:** Avoid hardcoding sensitive values in any .tfvars file that might be committed to version control. Use environment variables (carefully), or preferably, a dedicated secret management solution (like AWS Secrets Manager, HashiCorp Vault, Azure Key Vault, GCP Secret Manager).
- **Transparency:** Always run terraform plan to review the execution plan and see the resolved variable values before applying changes, especially when variables are sourced from multiple places.

---

## Scenario : Parameterizing EC2 Instance with Variables

### Objective

To introduce reusability and flexibility by using input variables to define the EC2 instance's attributes.

---

## Steps & Code

### Modify main.tf

(You can continue in the same directory or create a new one for this scenario.)

```hcl
# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region # Use a variable for region
}

# Define an AWS EC2 instance resource
resource "aws_instance" "my_parameterized_ec2" {
  ami           = var.instance_ami_id
  instance_type = var.instance_type

  tags = {
    Name        = "ParameterizedEC2-${var.environment}"
    Environment = var.environment
  }
}

# Output the public IP of the EC2 instance
output "ec2_public_ip_parameterized" {
  value       = aws_instance.my_parameterized_ec2.public_ip
  description = "The public IP address of the parameterized EC2 instance."
}
```

---

### Create variables.tf

(It's a good practice to separate variable declarations into a dedicated file.)

```hcl
# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "instance_ami_id" {
  description = "The AMI ID for the EC2 instance."
  type        = string
  default     = "ami-053b0d53c27927904" # Default for us-east-1 Amazon Linux 2
}

variable "instance_type" {
  description = "The instance type for the EC2 instance."
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "The environment tag for the resources."
  type        = string
  default     = "Development"
}
```

---

### Create terraform.tfvars

(This file provides default or specific values for variables without command-line input.)

```hcl
# terraform.tfvars

aws_region      = "us-east-1"
instance_type   = "t2.micro"
instance_ami_id = "ami-053b0d53c27927904" # Ensure this is valid for us-east-1
environment     = "Dev"
```

---

## Demonstrate Variable Usage

### terraform init

(If it's a new directory or you moved files, re-initialize.)

### terraform plan

Run terraform plan. It should use the values from terraform.tfvars.

### terraform apply

Apply the configuration.

### Verify

Check AWS Console for ParameterizedEC2-Dev.

---

## Changing Variables and Updating Infrastructure

### Option 1: Modify terraform.tfvars

- Change instance_type = "t2.small" and environment = "Staging".
- Run terraform plan. Observe that Terraform detects a change to instance_type (requiring replacement) and tags (in-place update).
- Run terraform apply.
- Verify: In AWS Console, observe the instance type change and tags update. Note that instance type changes often require replacing the instance.

### Option 2: Pass variables via command line

```bash
terraform plan -var="instance_type=t2.nano" -var="environment=Test"
```

command-line variables override terraform.tfvars.

**Good Practice:** command-line variables are useful for quick, one-off changes, but tfvars files are better for persistent, shared configurations.

---

## Clean up

```bash
terraform destroy
```

to remove the provisioned resources.

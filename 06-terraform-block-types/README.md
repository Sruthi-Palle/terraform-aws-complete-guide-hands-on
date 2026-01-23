# Terraform Block Types

HCL is a declarative language designed for configuration, not a general-purpose programming language.

### **Basic Syntax:**

- **Blocks:** Containers for configuration (e.g., `provider`, `resource`, `variable`).
  ```bash
  block_type "block_label" "block_name" {
    # Arguments go here
  }
  ```
- **Arguments:** Key-value pairs within a block that define specific settings.
  ```bash
  argument_name = "argument_value"
  ```
- **Attributes:** Output values exposed by a resource after it's provisioned. Accessed using dot notation (e.g., `aws_instance.my_ec2.public_ip`).

### `provider` block:

- **Purpose:** Configures the cloud provider or service Terraform will interact with.
- **Example:**
  ```bash
  provider "aws" {
    region = "us-east-1" # Specifies the AWS region
    # access_key = "..." # Not recommended, use aws configure or roles
    # secret_key = "..."
  }
  ```
- **Explanation:** Terraform uses this block to understand which API endpoints to target and how to authenticate.

### `resource` block:

- **Purpose:** Defines a piece of infrastructure that Terraform will manage.
- **Structure:** `resource "<PROVIDER>_<TYPE>" "<NAME>" { ... }`
  - `<PROVIDER>_<TYPE>`: The resource type (e.g., `aws_instance` for an EC2 instance, `aws_s3_bucket` for an S3 bucket).
  - `<NAME>`: A logical name used within your Terraform configuration to refer to this specific resource.
- **Example:**
  ```bash
  resource "aws_instance" "my_ec2_instance" {
    ami           = "ami-0abcdef1234567890" # Example AMI ID
    instance_type = "t2.micro"
    tags = {
      Name = "MyWebAppServer"
    }
  }
  ```
- **Explanation:** Terraform translates this block into API calls to the specified provider to create, update, or destroy the defined resource.

### `data` block:

- **Purpose:** `data` blocks allow Terraform to read information about resources that _already exist_ and are _not managed_ by your current Terraform configuration.
- **Syntax:** `data "provider_type" "local_name"`
- **Use Cases:**
  - **Referencing existing VPCs:** If your application needs to deploy into a pre-existing VPC, you can fetch its ID.
  - **Finding the latest AMI:** Dynamically get the latest Amazon Machine Image ID for a specific OS.
  - **Discovering Subnets, Security Groups:** Get details about networking components that are managed elsewhere.
- **Example:**
  ```bash
  # 1. Find the VPC
  data "aws_vpc" "selected" {
    filter {
      name   = "tag:Name"
      values = ["my-production-vpc"]
    }
  }

  # 2. Find a Subnet inside that VPC
  data "aws_subnet" "target_subnet" {
    filter {
      name   = "vpc-id"
      values = [data.aws_vpc.selected.id]
    }
    filter {
      name   = "tag:Tier"
      values = ["Public"] # Helps pick the right subnet if there are many
    }
  }

  # 3. Use the Subnet ID for the Instance
  resource "aws_instance" "web_server" {
    ami           = "ami-0abcdef1234567890"
    instance_type = "t2.micro"

    # Reference the SUBNET, not the VPC
    subnet_id     = data.aws_subnet.target_subnet.id

    tags = {
      Name = "WebServer"
    }
  }
  ```
- **Benefit:** Promotes reusability and allows you to integrate your Terraform deployments into existing infrastructure without having to hardcode IDs.

### `variable` block:

- **Purpose:** Declares input variables for your Terraform configurations, making them reusable and flexible.
- **Structure:**

```bash
variable "instance_count" {
  description = "Number of EC2 instances to deploy"
  type        = number
  default     = 2
}

resource "aws_instance" "server" {
  count         = var.instance_count
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

- **Accessing Variables:** `var.variable_name`
- **Explanation:** Allows users to provide different values without modifying the main configuration file.
- **Use Variable Validation:** Modern Terraform allows you to add custom error messages to variables to ensure inputs meet specific criteria.
  Terraform
  ```bash
  variable "instance_type" {
    type = string
    validation {
      condition     = can(regex("^t[2-3].", var.instance_type))
      error_message = "Only T2 or T3 instances are allowed for this project."
    }
  }
  ```

### `output` block:

- **Purpose:** Output variables are like **return values**. Defines output values that Terraform will display after applying the configuration. Useful for sharing information about the provisioned infrastructure. To display data on the CLI or to pass data from a child module to a parent module.
  - **Best Practice:** Use the `sensitive = true` argument for outputs containing passwords or private keys to prevent them from being printed in the console.
- **Structure:**
  ```bash
  output "output_name" {
    value       = resource_name.attribute_name # Value to be displayed
    description = "A description of the output"
  }
  ```
- **Example:**
  ```bash
  output "ec2_public_ip" {
    value       = aws_instance.my_ec2_instance.public_ip
    description = "The public IP address of the EC2 instance."
  }
  ```
- **Explanation:** Provides easily accessible information about the deployed resources, often used in subsequent automation.

### `locals` block:

- **Purpose:** Locals are like **temporary constants**. They allow you to assign a name to an expression, preventing you from repeating the same logic multiple times.
- **Definition:** Declared within a `locals` block.
- **Usage:** Accessed via `local.<NAME>`.
- **Best Practice:** Use locals to keep your code DRY (Don't Repeat Yourself), especially for complex string manipulations or tag combinations.

Terraform

```bash
locals {
  service_name = "billing-api"
  owner        = "finance-team"
  common_tags = {
    Service = local.service_name
    Owner   = local.owner
  }
}

resource "aws_instance" "example" {
  # ... other config ...
  tags = local.common_tags
}
```

### Scenario 1 : Provisioning a Simple AWS EC2 Instance

**Objective:** To provision a single AWS EC2 instance using a basic Terraform configuration and understand the core Terraform workflow.

**Steps & Code:**

1. **Create a Configuration directory:** `mkdir terraform-ec2-scenario1 && cd terraform-ec2-scenario1`
2. ### Leveraging Terraform Documentation

   Use the official Terraform documentation as a primary reference. The process involves:
   1. Searching the documentation for the desired resource (e.g., "AWS S3").
   2. Identifying the correct resource type (`aws_s3_bucket`).
   3. Reviewing the "Example Usage" section to get a template for the configuration block.
   4. Consulting the "Argument Reference" to understand which fields are mandatory and which are optional.

3. **Create** `main.tf`:

   ```bash
   # main.tf

   # Configure the AWS Provider
   provider "aws" {
     region = "us-east-1" # Or your preferred AWS region
   }

   # Define an AWS EC2 instance resource
   resource "aws_instance" "my_first_ec2" {
     ami           = "ami-053b0d53c27927904" # Example AMI for Amazon Linux 2 (us-east-1). Find latest via AWS Console or data source.
     instance_type = "t2.micro"

     tags = {
       Name = "MyFirstTerraformEC2"
       Environment = "Dev"
     }
   }

   # Output the public IP of the EC2 instance
   output "ec2_public_ip" {
     value       = aws_instance.my_first_ec2.public_ip
     description = "The public IP address of the first EC2 instance."
   }
   ```

   - **Self-Correction/Good Practice:** find the latest AMI ID for their region (e.g., AWS Console -&gt; EC2 -&gt; AMIs -&gt; Public Images, or use `aws ec2 describe-images` CLI command)

4. **Terraform Workflow:**
   - `terraform init`:
     - **Purpose:** Initialises a Terraform working directory. Downloads necessary provider plugins (e.g., `aws` provider).
     - **Execution:** Run `terraform init` in the directory containing `main.tf`.
     - **Expected Output:** Messages indicating successful initialisation and provider installation.
     - **Explanation:** This command is crucial for setting up the backend and downloading the correct provider versions. Run it once per new configuration directory or when you add/change providers.
   - `terraform plan`:
     - **Purpose:** Generates an execution plan, showing what actions Terraform will take (create, update, destroy) without actually performing them.
     - **Execution:** Run `terraform plan`.
     - **Expected Output:** A detailed list of resources to be added, changed, or destroyed. It will show a `+` for creation.
     - **Explanation:** This is a dry run and a critical step for reviewing changes before applying them, preventing unintended modifications.
   - `terraform apply`:
     - **Purpose:** Executes the actions proposed in the plan (or a new plan if run directly). Provisions the infrastructure.
     - **Execution:** Run `terraform apply`. You will be prompted to confirm by typing `yes`.
     - **Expected Output:** Messages indicating resource creation progress. Finally, it will display the `Output` values defined (e.g., the EC2 public IP).
     - **Explanation:** This is the command that makes changes to your cloud environment.
   - **Verification in AWS Console:**
     - Navigate to the EC2 dashboard in the specified region.
     - Verify that an EC2 instance named `MyFirstTerraformEC2` is running and has a public IP address.
   - `terraform destroy`:
     - **Purpose:** Destroys all resources managed by the current Terraform configuration.
     - **Execution:** Run `terraform destroy`. You will be prompted to confirm by typing `yes`.
     - **Expected Output:** Messages indicating resource deletion progress.
     - **Explanation:** Used to tear down environments, saving costs and ensuring clean-up.
   - **Verification in AWS Console:**
     - Refresh the EC2 dashboard.
     - Verify that the `MyFirstTerraformEC2` instance is terminating or has been terminated.

> **Command-Line Flags:** The `-auto-approve` flag can be used with both `terraform apply` and `terraform destroy` to bypass the interactive confirmation prompt, which is useful for automation scripts.

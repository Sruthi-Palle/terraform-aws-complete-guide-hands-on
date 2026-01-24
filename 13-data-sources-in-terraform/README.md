# Data Sources in Terraform

## The Role and Necessity of Data Sources

In traditional Terraform workflows, provisioning a resource such as an EC2 instance requires specific identifiers, such as an AMI ID. These IDs often change based on regional releases or operating system updates (Ubuntu, Amazon Linux, CentOS).

### Challenges of Manual Identification

- **Hardcoding Risks:** Copying and pasting IDs from the AWS Console is prone to human error and leads to fragile code that requires constant manual updates.
- **Manual Intervention:** Automated environments cannot function if a human must manually look up an AMI release page to update a script.
- **Scope:** AMIs are often stored in open-source repositories outside a specific AWS environment, necessitating a standardized way to pull them into a local project.

### The Data Source Solution

A data source acts as a read-only request to the AWS API. Instead of creating a new resource, it queries existing data. For example, a developer can instruct Terraform to "fetch the latest Amazon Linux 2 image" rather than providing a specific, static ID.

---

## Enterprise Use Case: Shared Infrastructure

In enterprise settings, infrastructure is rarely built from scratch for every project. A common architecture involves a **Shared VPC** used by multiple departments, such as DevOps, Development, and QA teams.

### Operational Requirements

When provisioning new EC2 instances in such an environment, the following constraints usually apply:

1. **Reuse Existing Network:** The VPC and subnets already exist; no new networking should be created.
2. **Reference by Metadata:** Instead of hardcoding subnet IDs, resources must reference existing subnets by their names or tags.
3. **Dynamic AMI Selection:** Each instance must automatically pull the latest pre-existing Linux image.

---

## Technical Implementation and Filtering

#### **Critical Professional Considerations**

> \[!IMPORTANT\] **Tag Case Sensitivity:** AWS tags are strictly case-sensitive. If your AWS Console has a tag `Name = "production-vpc"` but your Terraform code filters for `"Production-VPC"`, the data source will fail with a "no matching resources found" error. Always verify the casing in the console before writing your filters.

> \[!TIP\] **Using Account IDs for Owners:** While `owners = ["amazon"]` is valid, using the specific AWS Account ID (e.g., `137112412989` for Amazon Linux 2) is a best practice. This prevents the accidental retrieval of "community" images that might mimic official naming conventions.

**Filtering Mechanisms**

To identify specific resources within a large AWS account, Terraform utilizes filter blocks. This is particularly useful for VPCs and subnets.

| Target Resource | Filter Attribute  | Description                                                                                                 |
| --------------- | ----------------- | ----------------------------------------------------------------------------------------------------------- |
| **AWS VPC**     | `tag:Name`        | Identifies the VPC by its assigned name (e.g., "default").                                                  |
| **AWS Subnet**  | `tag:Name`        | Targets a specific subnet (e.g., "subnet A") within a VPC.                                                  |
| **AWS AMI**     | `name` / `owners` | Uses wildcards (e.g., `*`) to find specific versions and restricts results to trusted owners like "Amazon." |

---

### Case Study:

1\. Fetch the latest Amazon Linux 2 AMI

2\. Reference an existing Shared VPC by its "Name" tag

3\. Reference an existing Subnet within that VPC

```yaml
# 1. Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true #Guarantees the newest release is selected.
  # Using the specific Amazon Account ID for enhanced security
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"] #Uses a wildcard to match the naming convention of the OS.
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] #Restricts the search to Hardware Virtual Machine images.
  }
}

# 2. Reference an existing Shared VPC by its "Name" tag
data "aws_vpc" "shared_vpc" {
  filter {
    name   = "tag:Name"
# Note: This must exactly match the casing used in the AWS Console
    values = ["Production-VPC"]
  }
}

# 3. Reference an existing Subnet within that VPC
data "aws_subnet" "selected_subnet" {
  filter {
    name   = "tag:Name"
    values = ["Public-Subnet-A"]
  }

  # Optional: Ensure the subnet belongs to the VPC found above
  vpc_id = data.aws_vpc.shared_vpc.id
}

# 4. Provision the EC2 Instance using the retrieved Data
resource "aws_instance" "web_server" {
  # Dynamically uses the ID from the AMI data source
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  # Dynamically uses the ID from the Subnet data source
  subnet_id     = data.aws_subnet.selected_subnet.id

  tags = {
    Name = "App-Server-Dynamic"
  }
}

# Output the IDs to verify what Terraform found
output "resolved_ami_id" {
  value = data.aws_ami.amazon_linux_2.id
}

output "resolved_subnet_id" {
  value = data.aws_subnet.selected_subnet.id
}
```

---

## Workflow: From Data Retrieval to Resource Provisioning

The process of using a data source follows a logical progression within the Terraform lifecycle:

1. **Tagging:** Existing AWS resources (like a VPC or Subnet) must be tagged appropriately in the AWS Console (e.g., `Name = subnet A`) to be discoverable by Terraform.
2. **Data Declaration:** The `data` block is defined in the `.tf` files.
3. **Resource Referencing:** The resource block (e.g., `aws_instance`) references the data source output using the syntax: `data.<RESOURCE_TYPE>.<LOCAL_NAME>.<ATTRIBUTE>`.
   - _Example:_ `subnet_id = data.aws_subnet.shared.id`

4. **Verification:** Running `terraform plan` allows the user to see exactly which IDs Terraform has fetched. For instance, a successful plan might resolve a filtered name to a specific ID like `80B4A9AF`.
5. **Execution:** `terraform apply` provisions the instance using the dynamically retrieved IDs.

---

## Best Practices and Conclusions

- **Consistency:** Always use data sources for components managed by other teams or shared across the organization.
- **Cleanup while you are doing practice for your learning:** Even when using data sources to reference existing infrastructure, any new resources created (like the EC2 instances themselves) must be destroyed (`terraform destroy`) after use to prevent unnecessary costs.
- `terraform destroy` will **not** delete the resources referenced by the data source (like the Shared VPC), only the resources _managed_ by your specific state file (like the EC2 instance).
- **Automation Integrity:** By utilizing `most_recent = true` and wildcards in filters, infrastructure remains up-to-date with the latest security patches and OS versions without requiring manual code changes.

---

## Summary

Terraform data sources serve as a critical mechanism for infrastructure automation by allowing configurations to dynamically fetch information from existing AWS environments or external repositories. The primary takeaways include:

- **Automation over Hardcoding:** Data sources eliminate the need for manual intervention by fetching real-time metadata (such as AMI IDs), which is essential for CI/CD pipelines and enterprise-scale environments.
- **Infrastructure Interoperability:** They allow teams to provision new resources within existing shared infrastructure (e.g., a shared VPC) without the risk of duplicating or mismanaging core network components.
- **Dynamic Filtering:** Through the use of filters and parameters like `most_recent`, Terraform ensures that the most current and secure versions of resources are utilized during provisioning.

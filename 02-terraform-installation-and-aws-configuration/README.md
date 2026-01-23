# Terraform Installation and Configuring AWS CLI

This guide provides step-by-step instructions for setting up your local development environment for infrastructure management using Terraform and AWS.

### 1\. Installing Terraform CLI:

It is best practice to install Terraform using the official package manager for your specific operating system to ensure easy updates.

- **Official Installation Guide:** [HashiCorp Install Instruct](https://developer.hashicorp.com/terraform/install)[ions](https://developer.hashicorp.com/terraform/install)
- **Verification:** After installation, verify the setup by running the following command in your terminal:

Bash

```bash
terraform --version
```

### 2\. Setting up AWS CLI and Configuring AWS Credentials:

- [**Good Practice:** Emphasise the princ](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)iple of least privilege for IAM users/roles. Avoid using root credentials.
- **Install AWS CLI:** Follow official AWS documentation [https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
- **Configure AWS Credentials:**
  - **Method 1: AWS Access Key and Secret Key (recommended only for development or learning):**
    You can get the keys for IAM user from AWS account.

    ```bash
    aws configure
    AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
    AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
    Default region name [None]: us-east-1
    Default output format [None]: json
    ```

    - **Security Note:** Storing keys directly is less secure for production.
    - > it’s worth noting that `aws configure` saves credentials to a plain-text file at `~/.aws/credentials`.
      >
      > **Tip:** Never commit `~/.aws/credentials` to Version Control (Git).

  - **Method 2: IAM Roles (for production/CI/CD):**
    **Good Practice:** Emphasise the principle of least privilege for IAM users/roles. **Strongly recommend IAM Roles for all non-human, automated processes (like Terraform in CI/CD or on EC2 instances) in production environments.** Avoid using root account credentials for any task.

### 3\. VS Code Extensions for Terraform:

- **HashiCorp Terraform:** Provides syntax highlighting, autocompletion, formatting, and intellisense for HCL. Essential for productivity.
- **HashiCorp HCL:** (Often bundled with the above or a good supplementary.) Enhances HCL editing experience.

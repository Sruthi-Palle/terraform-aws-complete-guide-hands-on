# Lambda function image processor

# Simple Image Processor - Backend Only

A simplified serverless image processing pipeline that automatically processes images uploaded to S3.

## 🎯 Architecture

```
┌─────────────────┐
│  Upload Image   │  You upload image via AWS CLI or SDK
│   to S3 Bucket  │
└────────┬────────┘
         │ s3:ObjectCreated:* event
         ↓
┌─────────────────┐
│ Lambda Function │  Automatically triggered
│ Image Processor │  - Compresses JPEG (quality 85)
└────────┬────────┘  - Low quality JPEG (quality 60)
         │            - WebP format
         │            - PNG format
         │            - Thumbnail (200x200)
         ↓
┌─────────────────┐
│ Processed S3    │  5 variants saved automatically
│    Bucket       │
└─────────────────┘
```

## 📦 Components

- **Upload S3 Bucket**: Source bucket for original images
- **Processed S3 Bucket**: Destination bucket for processed variants
- **Lambda Function**: Image processor with Pillow library
- **Lambda Layer**: Pillow 10.4.0 for image manipulation
- **S3 Event Trigger**: Automatically invokes Lambda on upload

## Explanation of deploy.sh script:

The deploy.sh script automates the end-to-end deployment of an image processing Lambda application using Terraform. Here's a detailed breakdown:

1. `set -e`: This command ensures that the script will exit immediately if any command fails, preventing further execution with potential errors.
2. Echo Deployment Start: It prints a "🚀 Deploying Image Processor Application..." message to the console, signaling the start of the process.
3. Directory Setup:
   - SCRIPT_DIR: Dynamically determines the absolute path of the directory where deploy.sh itself is located.
   - PROJECT_DIR: Determines the absolute path of the project's root directory, one level up from the scripts directory.

4. Prerequisite Checks: The script verifies the presence of essential command-line tools:
   - AWS CLI: Checks if aws command is available. If not, it prints an error message and exits.
   - Terraform CLI: Checks if terraform command is available. If not, it prints an error message and exits.

5. Build Lambda Layer:
   - It informs the user that the Lambda layer is being built using Docker.
   - chmod +x "$SCRIPT_DIR/build_layer_docker.sh": Makes the build_layer_docker.sh script executable.
   - bash "$SCRIPT_DIR/build_layer_docker.sh": Executes the build_layer_docker.sh script. This script is responsible for creating a Lambda layer, typically containing Python dependencies like Pillow for image processing, packaged within a Docker container to ensure consistent build environments across different operating systems.

6. Initialize Terraform:
   - cd "$PROJECT_DIR/terraform": Changes the current working directory to the terraform subdirectory where the infrastructure configuration files (.tf files) reside.
   - terraform init: Initializes the Terraform working directory. This command downloads the necessary AWS provider plugins and modules defined in the .tf files, preparing Terraform for deployment.

7. Plan Terraform Deployment:
   - terraform plan -out=tfplan: Generates an execution plan. Terraform compares the desired state (defined in .tf files) with the current state of AWS resources and outputs what actions (create, modify, destroy) it will take. The -out=tfplan option saves this plan to a file named tfplan, which can then be used for the apply command to ensure the exact planned changes are executed.

8. Apply Terraform Deployment:
   - terraform apply tfplan: Executes the actions specified in the tfplan file. This is where AWS resources like S3 buckets, the Lambda function, IAM roles, etc., are provisioned or updated according to the Terraform configuration.

9. Retrieve Terraform Outputs: After a successful deployment, the script fetches important information (outputs) defined in outputs.tf:
   - UPLOAD_BUCKET: The name of the S3 bucket designated for image uploads.
   - PROCESSED_BUCKET: The name of the S3 bucket where processed images will be stored.
   - LAMBDA_FUNCTION: The name of the deployed AWS Lambda function.
   - REGION: The AWS region where the resources are deployed.

10. Display Deployment Summary and Usage:
    - Finally, it prints a success message and summarizes the deployed resources (S3 buckets, Lambda function, region).
    - It provides clear usage instructions, demonstrating how a user can upload an image to the UPLOAD_BUCKET using the aws s3 cp command and explains that the Lambda function will automatically process it, saving the results to the PROCESSED_BUCKET.

In essence, deploy.sh is a wrapper script that orchestrates the entire deployment workflow, from environment checks and dependency building to infrastructure provisioning and post-deployment information display.

## 🚀 Deployment

```bash
# Deploy infrastructure
./scripts/deploy.sh

# The script will output your bucket names
```

## 📸 Usage

### Upload an Image

```bash
# Upload via AWS CLI
aws s3 cp my-photo.jpg s3://YOUR-UPLOAD-BUCKET/

# Or use the output from deployment
aws s3 cp my-photo.jpg $(terraform output -raw upload_command_example | awk '{print $NF}')
```

### View Processed Images

```bash
# List all processed variants
aws s3 ls s3://YOUR-PROCESSED-BUCKET/ --recursive

# Download a specific variant
aws s3 cp s3://YOUR-PROCESSED-BUCKET/my-photo_compressed.jpg ./
```

## 🎨 Generated Variants

For each uploaded image, the Lambda function creates:

1. **Compressed JPEG** (85% quality) - Best balance of quality/size
2. **Low Quality JPEG** (60% quality) - Smallest file size
3. **WebP Format** (85% quality) - Modern format, better compression
4. **PNG Format** - Lossless, largest file size
5. **Thumbnail** (200x200) - Small preview image

### Example Output

```
Original: photo.jpg (500 KB)
├── photo_compressed_abc123.jpg (120 KB)
├── photo_low_abc123.jpg (80 KB)
├── photo_webp_abc123.webp (95 KB)
├── photo_png_abc123.png (450 KB)
└── photo_thumbnail_abc123.jpg (15 KB)
```

## 🔧 Configuration

### Environment Variables (Lambda)

- `PROCESSED_BUCKET`: Destination S3 bucket name (auto-configured)
- `LOG_LEVEL`: Logging level (default: INFO)

### Supported Formats

**Input**: JPG, JPEG, PNG, WebP, GIF, BMP
**Output**: JPEG, PNG, WebP

## 📊 Monitoring

```bash
# View Lambda logs
aws logs tail /aws/lambda/YOUR-LAMBDA-FUNCTION --follow

# Check Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=YOUR-LAMBDA-FUNCTION \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## 🧹 Cleanup

```bash
# Destroy all resources
./scripts/destroy.sh
```

## 💰 Cost Estimation

**Monthly costs** (approximate):

- **S3 Storage**: $0.023 per GB (first 50 TB)
- **Lambda**: First 1M requests free, then $0.20 per 1M
- **Lambda Duration**: First 400,000 GB-seconds free
- **S3 Requests**: $0.0004 per 1,000 PUT requests

**Example**: Processing 1,000 images/month ≈ **$0.50 - $2.00**

## 🔐 Security Features

- ✅ All buckets are private (no public access)
- ✅ Server-side encryption (AES256)
- ✅ Bucket versioning enabled
- ✅ IAM least privilege (Lambda only has access to specific buckets)
- ✅ VPC isolation (optional, not configured by default)

## 🎯 Performance

- **Cold Start**: ~470ms (includes Pillow layer loading)
- **Warm Execution**: ~300-600ms per image
- **Memory**: 113 MB average (1024 MB allocated)
- **Processing**: ~100ms per variant

## 🛠️ Customization

### Modify Image Quality

Edit `lambda/lambda_function.py`:

```python
# Change compression levels
COMPRESSION_LEVELS = {
    'compressed': 85,  # Change this
    'low': 60,         # Or this
    'webp': 85,        # WebP quality
}
```

### Change Thumbnail Size

```python
THUMBNAIL_SIZE = (200, 200)  # Change dimensions
```

### Add New Variants

```python
# Add in create_variants() function
variants['your_variant'] = img.copy()
variants['your_variant'].save(buffer, format='JPEG', quality=75)
```

## 📝 Notes

- Lambda timeout: 60 seconds (adjustable in `terraform/main.tf`)
- Max image size: Limited by Lambda memory (1024 MB)
- Supported regions: All AWS regions
- No frontend required - pure backend automation

## Explanation of build_layer_docker.sh script:

The build_layer_docker.sh script automates the creation of an AWS Lambda layer containing the Pillow Python library. It uses Docker to ensure the layer is built in a Linux environment (linux/amd64 architecture), making it compatible with AWS Lambda's execution environment, regardless of the developer's local operating system.

Here's a detailed breakdown of its functionality:

1. `set -e`: This command ensures that the script will exit immediately if any command fails. This is a best practice for shell scripts to prevent silent failures and ensure reliability.
2. Informative Echo Statements: The script starts and proceeds with echo commands to provide clear feedback to the user about the current stage of the layer build process (e.g., "🚀 Building Lambda Layer with Pillow using Docker...", "📦 Building layer in Linux container (Python 3.12)...").
3. Directory Setup:
   - SCRIPT_DIR: This variable stores the absolute path of the directory where the build_layer_docker.sh script itself resides.
   - PROJECT_DIR: This variable is set to the absolute path of the parent directory of SCRIPT_DIR, effectively pointing to the root of the entire project.
   - TERRAFORM_DIR: This variable constructs the path to the terraform subdirectory within the project. This is the designated location where the final pillow_layer.zip file will be saved.

4. Docker Prerequisite Checks: Before attempting to use Docker, the script performs two crucial checks:
   - Docker Installation: It checks if the docker command is installed and available in the system's PATH. If not, it prints an error message, provides a helpful link to Docker installation instructions, and then exits.
   - Docker Daemon Status: It verifies if the Docker daemon (the background service that runs Docker containers) is running. It does this by attempting to execute docker info. If Docker is not running, it prints an error message and exits.

5. Docker Container Execution for Layer Build: This is the core of the script, where the actual layer is built inside a Docker container:

```yaml
# Build the layer using Docker with Python 3.12 on Linux AMD64
docker run --rm \
--platform linux/amd64 \
-v "$TERRAFORM_DIR":/output \
python:3.12-slim \
bash -c "
echo '📦 Installing Pillow for Linux AMD64...' && \
pip install --quiet Pillow==10.4.0 -t /tmp/python/lib/python3.12/site-packages/ && \
cd /tmp && \
echo '📦 Creating layer zip file...' && \
apt-get update -qq && apt-get install -y -qq zip > /dev/null 2>&1 && \
zip -q -r pillow_layer.zip python/ && \
cp pillow_layer.zip /output/ && \
echo '✅ Layer built successfully for Linux (Lambda-compatible)!'
"
```

1. `docker run`: Command to run a new Docker container.
2. `--rm`: This flag ensures that the container and its file system are automatically removed once the container exits. This keeps the developer's system clean.
3. `--platform linux/amd64`: This is critical for AWS Lambda compatibility. It specifies that the Docker image should be pulled and run for the linux/amd64 architecture. AWS Lambda functions typically run on Amazon Linux (which is x86_64 or AMD64), so building dependencies for this specific platform ensures that any compiled code within Pillow (or other libraries) is binary-compatible with the Lambda runtime.
4. `-v "$TERRAFORM_DIR":/output`: This performs a volume mount. It mounts the $TERRAFORM_DIR (the terraform directory on the host machine) into the Docker container at the path /output. This allows files created inside the container (specifically, the pillow_layer.zip) to be directly written to the host's terraform directory.
5. `python:3.12-slim`: This specifies the Docker image to use. python:3.12-slim provides a lightweight Python 3.12 environment, which is suitable for installing Python packages.
6. `bash -c "..."`: This executes a series of shell commands inside the newly created Docker container:

- `echo '📦 Installing Pillow for Linux AMD64...'`: An informative message displayed within the container's output.
- `pip install --quiet Pillow==10.4.0 -t /tmp/python/lib/python3.12/site-packages/:` This command installs the Pillow library (specifically version 10.4.0) into a structured directory within the container (/tmp/python/lib/python3.12/site-packages/). This specific path structure is a requirement for AWS Lambda layers to correctly find the installed packages. The --quiet flag reduces the verbosity of the pip install output.
- `cd /tmp:` Changes the current directory inside the container to /tmp.
- `echo` '📦 Creating layer zip file...': Another informative message.
- `apt-get update -qq && apt-get install -y -qq zip > /dev/null 2>&1`: This updates the package lists within the Debian-based python:3.12-slim image and then installs the zip utility. The -qq and &gt; /dev/null 2&gt;&1 flags are used to suppress most of the output from these commands, keeping the console clean. The zip utility is needed to create the layer archive.
- `zip -q -r pillow_layer.zip python/`: This command creates a ZIP archive named pillow_layer.zip. It recursively (-r) includes all contents of the python/ directory (where Pillow was installed). The -q flag keeps the output quiet.
- `cp pillow_layer.zip /output/`: This copies the newly created pillow_layer.zip file from /tmp inside the container to the /output directory, which, due to the volume mount, means it's copied to the host's $TERRAFORM_DIR.

7\. Output Location and Final Confirmation:

- After the Docker command completes, the script prints the exact path (📍 Location: $TERRAFORM_DIR/pillow_layer.zip) where the generated layer zip file can be found on the host system. It concludes with a final success message, reiterating that the layer is now compatible with AWS Lambda.

In summary, the build_layer_docker.sh script provides a robust and portable way to create AWS Lambda layers, ensuring that all dependencies are correctly built for the target Lambda execution environment using Docker as a consistent build platform.

## How the aws_cloudwatch_log_group is associated with the aws_lambda_function

When there isn't an explicit log_group_name argument directly within the aws_lambda_function resource block in Terraform.

The association happens implicitly through a combination of two key factors in AWS:

1. AWS Lambda's Default Logging Behavior and Naming Convention:
   - AWS Lambda functions are designed to automatically send their logs to CloudWatch Logs.
   - When a Lambda function starts executing and needs to log something, it looks for a CloudWatch Log Group with a specific name format: /aws/lambda/.
   - In your [main.tf](http://main.tf), you have:
   - ```yaml
       # Lambda function
       resource "aws_lambda_function" "image_processor" {
            function_name    = local.lambda_function_name
        # ...
        }

       # CloudWatch Log Group for Lambda
       resource "aws_cloudwatch_log_group" "lambda_processor" {
             name              = "/aws/lambda/${local.lambda_function_name}"
             retention_in_days = 7
        }
     ```

\* Notice that the name argument of your aws_cloudwatch_log_group resource is explicitly constructed to exactly match this default naming convention, using the same local.lambda_function_name that is assigned to the function_name of your Lambda. Because the log group exists with the expected name, the Lambda function automatically discovers and uses it for logging.

2. IAM Permissions for the Lambda Execution Role:
   - For a Lambda function to successfully write logs to CloudWatch, its execution role (the IAM role assigned to the Lambda function) must have the necessary permissions.
   - In your [main.tf](http://main.tf), the aws_iam_role_policy for aws_iam_role.lambda_role includes statements like these:
   - ```yaml
       resource "aws_iam_role_policy" "lambda_policy" {
         name = "${local.lambda_function_name}-policy"
         role = aws_iam_role.lambda_role.id
         policy = jsonencode({
           Version = "2012-10-17"
           Statement = [
             {
               Effect = "Allow"
                  Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                  ]
                  Resource = "arn:aws:logs:${var.aws_region}:*:*" # Grants permission to any log group in the region
                },
                # ... other permissions
              ]
            })
          }
     ```

\* The `logs:CreateLogGroup, logs:CreateLogStream`, and `logs:PutLogEvents` actions allow the Lambda's role to create log groups (if one doesn't exist), create log streams within a log group, and send log events to those streams. The Resource = "arn:aws:logs:${[var.aws](http://var.aws)\_region}:_:_" part makes these permissions apply broadly across all log groups in the specified region.

## Why we are using docker run command for building the layer?

### 1\. Cross-Compilation for Linux

AWS Lambda functions run on a Linux-based OS. Many Python libraries, like **Pillow**, contain C-extensions that must be compiled for the specific architecture and OS they run on.

- **Without Docker:** You might download a `.whl` file meant for macOS (ARM64) or Windows.
- **With Docker:** By using `--platform linux/amd64` and a `python:3.12-slim` image, you are effectively "tricking" the installation process into thinking it’s already inside a Lambda-like environment. It pulls the correct Linux binaries.

### 2\. Dependency Isolation

Docker creates a "clean room" for your build.

- It ensures that no local Python versions, environment variables, or cached packages on your laptop interfere with the layer.
- It ensures the folder structure inside the `.zip` file is exactly what Lambda expects (e.g., `python/lib/python3.12/site-packages/`).

### 3\. Portable Build Environment

You don't need to install `zip` or specific Python versions on your host machine.

- The script installs `zip` _inside_ the container (`apt-get install -y zip`).
- This makes your script "write once, run anywhere." Any developer on your team can run this script as long as they have Docker, regardless of whether they have Python 3.12 installed locally.

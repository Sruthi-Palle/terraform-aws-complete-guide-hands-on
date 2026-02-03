# Application Version 1.0 (Blue Environment - Production)

# * Purpose: This resource uploads your application's source code to an S3 bucket.
#   * `bucket`: It references the S3 bucket created in main.tf (aws_s3_bucket.app_versions). This is where all application versions will be stored.
#   * `key`: This is the filename that the uploaded object will have in the S3 bucket (i.e., app-v1.zip).
#   * `source`: This specifies the local path to the file that needs to be uploaded. The package-apps.sh script must be run first to create this app-v1.zip
#     file.
#   * `etag`: This is a checksum of the zip file. If the file's content changes, the checksum changes, which tells Terraform that the file needs to be
#     re-uploaded.
resource "aws_s3_object" "app_v1" {
  bucket = aws_s3_bucket.app_versions.id
  key    = "app-v1.zip"
  source = "${path.module}/app-v1/app-v1.zip"
  etag   = filemd5("${path.module}/app-v1/app-v1.zip")

  tags = var.tags
}

#* Purpose: This resource registers the uploaded zip file as a specific, deployable "version" within your parent Elastic Beanstalk application.
#   * `application`: It links this version to the main application defined in main.tf (aws_elastic_beanstalk_application.app).
#   * `bucket` & `key`: These attributes point directly to the S3 object that was just uploaded in the previous step.
resource "aws_elastic_beanstalk_application_version" "v1" {
  name        = "${var.app_name}-v1"
  application = aws_elastic_beanstalk_application.app.name
  description = "Application Version 1.0 - Initial Release"
  bucket      = aws_s3_bucket.app_versions.id
  key         = aws_s3_object.app_v1.id

  tags = var.tags
}

# Important: Environment
# An Elastic Beanstalk environment is a collection of AWS resources running together including an Amazon EC2 instance. 
# When you create an environment, Elastic Beanstalk provisions the necessary resources into your AWS account.

#This is the main resource block that creates the actual, running environment.
#
#   * Purpose: To launch and configure a complete, load-balanced environment running a specific application version.
#   * `name`: Gives the environment a unique name (e.g., my-app-blue).
#   * `application`: Connects this environment to the parent application from main.tf.
#   * `solution_stack_name`: Defines the underlying platform and runtime (e.g., "64bit Amazon Linux 2 v5.5.0 running Node.js 14"). This is defined as a variable
#     in variables.tf.
#   * `version_label`: This is the crucial link. It tells Elastic Beanstalk to deploy the application version v1 that was defined just above.
#   * `setting` Blocks: The numerous setting blocks are used to configure every detail of the environment, including:
#       * IAM Roles: Assigning permissions for the EC2 instances and the Elastic Beanstalk service itself.
#       * Instance Type: Setting the EC2 instance size (e.g., t2.micro).
#       * Load Balancer: Configuring it as an Application Load Balancer.
#       * Auto Scaling: Setting the minimum and maximum number of instances.
#       * Health Checks & Port: Telling the load balancer how to check if the application is healthy (by hitting the / path on port 8080).
#       * Environment Variables: Passing variables like ENVIRONMENT=blue and VERSION=1.0 to the running Node.js application.

# Blue Environment (Production)
resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "${var.app_name}-blue"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = var.solution_stack_name
  tier                = "WebServer"
  version_label       = aws_elastic_beanstalk_application_version.v1.name

  # IAM Settings
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    #IamInstanceProfile: This gives your EC2 instances permission to talk to other AWS services (like S3 to download your code or CloudWatch to upload logs).
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    #ServiceRole: This gives Elastic Beanstalk itself permission to monitor your resources and create the Load Balancer/Auto Scaling group on your behalf.
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.name
  }

  # Instance Settings
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  # Environment Type (Load Balanced)
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  # Auto Scaling Settings
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "2"
  }

  # Health Reporting
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    #HealthReporting (enhanced): Provides deep metrics (CPU, latency, error rates) instead of just a simple "is the server on/off" check.
    name      = "SystemType"
    value     = "enhanced"
  }

  # Platform Settings
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "8080"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  # Environment Variables
  #These are your Environment Variables. Your code (Node.js, Python, Java, etc.) reads these at runtime to know it's in the "blue" environment or what version it's running.
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENVIRONMENT"
    value     = "blue"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "VERSION"
    value     = "1.0"
  }

  # Deployment Policy
  setting {
    namespace = "aws:elasticbeanstalk:command"
    #DeploymentPolicy (Rolling): This is crucial. It ensures that when you update your code, 
    #Beanstalk doesn't take all servers down at once. It does them one by one so your website stays online.
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Percentage"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "50"
  }

  # Managed Updates
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "false"
  }

  tags = merge(
    var.tags,
    {
      Environment = "blue"
      Role        = "production"
    }
  )
}

# In summary, this file takes the v1 application code, uploads it, versions it, and then launches a fully configured, production-ready environment to run that
#  specific version. The green-environment.tf file does the exact same thing, but for v2.

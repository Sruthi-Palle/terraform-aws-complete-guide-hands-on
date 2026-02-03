#!/bin/bash

# Script to perform the Blue-Green swap

#* Syntax: Initializes variables for AWS region and environment names. Uses a while loop with case statement to parse command-line arguments.
# * Functionality: Allows the user to override default values or dynamically retrieved environment names by passing --region, --blue, and --green flags
#                  when running the script (e.g., ./swap-environments.sh --region eu-west-1 --blue myapp-blue --green myapp-green).

# Default values
REGION="us-east-1"
BLUE_ENV=""
GREEN_ENV=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --region)
            REGION="$2"
            shift 2
            ;;
        --blue)
            BLUE_ENV="$2"
            shift 2
            ;;
        --green)
            GREEN_ENV="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--region REGION] [--blue BLUE_ENV] [--green GREEN_ENV]"
            exit 1
            ;;
    esac
done

echo "====================================="
echo "Blue-Green Environment Swap"
echo "====================================="
echo ""

# Get environment names from Terraform output if not provided
# Syntax: An if statement checks if BLUE_ENV or GREEN_ENV are empty (meaning they weren't provided via command-line arguments). It then checks for the
#         presence of terraform and jq commands. jq is a command-line JSON processor. terraform output -json is executed, and its JSON output is piped to jq to
#         extract the environment names.
#Functionality: This is crucial for automation. If the environment names aren't explicitly provided, the script intelligently fetches them from the
#         terraform output. This ensures it always uses the correct, dynamically provisioned environment names. Error handling is included for when Terraform or
#         jq are not found, or if Terraform output fails.

if [ -z "$BLUE_ENV" ] || [ -z "$GREEN_ENV" ]; then
    echo "Getting environment names from Terraform..."
    
    if ! command -v terraform &> /dev/null; then
        echo "[ERROR] Terraform is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "[ERROR] jq is not installed. Please install jq to parse JSON output."
        echo "On Ubuntu/Debian: sudo apt-get install jq"
        echo "On macOS: brew install jq"
        exit 1
    fi
    
    TF_OUTPUT=$(terraform output -json 2>&1)
    if [ $? -ne 0 ]; then
        echo "[ERROR] Could not read Terraform outputs."
        echo "   Please run 'terraform apply' first or provide environment names manually."
        exit 1
    fi
    
    BLUE_ENV=$(echo "$TF_OUTPUT" | jq -r '.blue_environment_name.value')
    GREEN_ENV=$(echo "$TF_OUTPUT" | jq -r '.green_environment_name.value')
    
    echo "[SUCCESS] Found environments:"
    echo "   Blue (Production): $BLUE_ENV"
    echo "   Green (Staging): $GREEN_ENV"
fi

echo ""
echo "[WARNING] This will swap the CNAMEs of both environments!"
echo "   Production traffic will be redirected to the staging environment."
echo ""
echo "Press any key to continue or Ctrl+C to cancel..."
read -n 1 -s

echo ""
echo "Swapping environment CNAMEs..."

# Perform the swap
if ! command -v aws &> /dev/null; then
    echo "[ERROR] AWS CLI is not installed or not in PATH"
    exit 1
fi

if aws elasticbeanstalk swap-environment-cnames \
    --source-environment-name "$BLUE_ENV" \
    --destination-environment-name "$GREEN_ENV" \
    --region "$REGION" 2>&1; then
    
    echo ""
    echo "====================================="
    echo "[SUCCESS] Swap initiated successfully!"
    echo "====================================="
    echo ""
    echo "[INFO] The swap typically takes 1-2 minutes to complete."
    echo ""
    echo "You can verify the swap by:"
    echo "1. Checking the Elastic Beanstalk console"
    echo "2. Visiting the environment URLs (wait a few minutes)"
    echo "3. Running: terraform output instructions"
else
    echo ""
    echo "[ERROR] Error performing swap"
    echo ""
    echo "Troubleshooting:"
    echo "1. Ensure AWS CLI is configured correctly"
    echo "2. Verify both environments are healthy"
    echo "3. Check that no other operation is in progress"
    exit 1
fi

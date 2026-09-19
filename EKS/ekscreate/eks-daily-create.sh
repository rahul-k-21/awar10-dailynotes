#!/bin/bash
# ------------------------------------------------------------------
# Creates the "ekswithrahul" EKS cluster.
# Intended to run from cron, Mon-Fri at 19:15 IST.
#
# Setup:
#   chmod +x "eks-daily-create.sh"
#   (see README-cron-setup.md in this folder)
# ------------------------------------------------------------------

# Cron runs with a minimal environment - it does NOT load your shell
# profile. So we set PATH and AWS configuration explicitly here.
export PATH="/home/rahul/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:/mnt/c/Program Files/Amazon/AWSCLIV2:/mnt/c/Users/user/AppData/Local/Microsoft/WinGet/Packages/eksctl.eksctl_Microsoft.Winget.Source_8wekyb3d8bbwe"
export HOME="/home/rahul"
export AWS_PROFILE="default"
export AWS_CONFIG_FILE="$HOME/.aws/config"
export AWS_SHARED_CREDENTIALS_FILE="$HOME/.aws/credentials"

echo "=================================================="
echo "START: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "=================================================="

# --- Preflight: is eksctl actually reachable from cron's PATH? ---
EKSCTL_BIN=""
if command -v eksctl >/dev/null 2>&1; then
    EKSCTL_BIN="eksctl"
elif command -v eksctl.exe >/dev/null 2>&1; then
    EKSCTL_BIN="eksctl.exe"
else
    echo "ERROR: eksctl not found on PATH."
    echo "PATH is: $PATH"
    echo "Run 'which eksctl' in your terminal and add that directory above."
    echo "END (failed preflight): $(date '+%Y-%m-%d %H:%M:%S %Z')"
    exit 1
fi
echo "Using eksctl at: $(command -v "$EKSCTL_BIN")"

# --- Preflight: are AWS credentials working? ---
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "ERROR: AWS credentials not working for profile '$AWS_PROFILE'."
    echo "Test with: aws sts get-caller-identity"
    echo "END (failed preflight): $(date '+%Y-%m-%d %H:%M:%S %Z')"
    exit 1
fi
echo "AWS identity: $(aws sts get-caller-identity --query Arn --output text)"

# --- Warn if the cluster already exists ---
# eksctl will fail on a duplicate name. This makes the reason obvious
# in the log instead of leaving you to decode a stack error.
if "$EKSCTL_BIN" get cluster --name ekswithrahul --region ap-south-1 >/dev/null 2>&1; then
    echo "WARNING: cluster 'ekswithrahul' already exists in ap-south-1."
    echo "The create below will fail. Delete it first with:"
    echo "  $EKSCTL_BIN delete cluster --name ekswithrahul --region ap-south-1"
fi

# --- The command, exactly as specified ---
echo "--------------------------------------------------"
echo "Running eksctl create cluster..."
echo "--------------------------------------------------"

"$EKSCTL_BIN" create cluster --name ekswithrahul --version 1.35 --region ap-south-1 --zones=ap-south-1a,ap-south-1b --nodegroup-name mycustomng --nodes 2 --node-type c7i-flex.large --node-ami-family=AmazonLinux2023 --managed

EXIT_CODE=$?

echo "=================================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: cluster created."
else
    echo "FAILED: eksctl exited with code $EXIT_CODE"
fi
echo "END: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "=================================================="
echo ""

exit $EXIT_CODE

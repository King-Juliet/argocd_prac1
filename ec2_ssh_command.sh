#!/bin/bash

SECRET_NAME="argocd-ec2-keypair"
REGION="eu-north-1"
EC2_USER="ubuntu"
EC2_IP="13.61.189.90" # Replace with your EC2 instance's public IP or DNS

aws secretsmanager get-secret-value \
  --region $REGION \
  --secret-id $SECRET_NAME \
  --query SecretString \
  --output text > argocd-ec2-key.pem

chmod 400 argocd-ec2-key.pem

ssh -i argocd-ec2-key.pem $EC2_USER@$EC2_IP



# -- since the key pair was created in terraform and pushed to aws secret manager,
# to access the instance, you will need to retrieve the key pair from AWS Secret Manager.
# Run the following command to retrieve the key pair:

# aws secretsmanager get-secret-value \
#   --secret-id argocd-ec2-keypair \
#   --query SecretString \
#   --output text > argocd-ec2-key.pem
# chmod 400 argocd-ec2-key.pem  #This is necessary because SSH will refuse to use keys that are publicly accessible.

# Make sure your IAM user or role has permission to access the secret.
# This command:
# Fetches the private key (PEM format) from Secrets Manager.
# Writes it to a local file called argocd-ec2-key.pem.

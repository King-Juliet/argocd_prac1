# PERMISSIONS

# SECURITY GROUP
resource "aws_security_group" "argocd_sg" {
  name        = "argocd-ec2-sg"
  description = "Allow SSH, HTTP, HTTPS, and Kubernetes service access"
  vpc_id      = module.argocd_vpc.vpc_id

  tags = {
    Name = "airbyte-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_access" {
  security_group_id = aws_security_group.argocd_sg.id
  cidr_ipv4         = "0.0.0.0/0" # Allow SSH from anywhere
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "http_access" {
  security_group_id = aws_security_group.argocd_sg.id
  cidr_ipv4         = "0.0.0.0/0"# Allow http from anywhere
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "https_access" {
  security_group_id = aws_security_group.argocd_sg.id
  cidr_ipv4         = "0.0.0.0/0" # Allow https from anywhere
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

## NodePort range for K8s services
resource "aws_vpc_security_group_ingress_rule" "nodeport_range_access" {
  security_group_id = aws_security_group.argocd_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 30000
  ip_protocol       = "tcp"
  to_port           = 32767
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.argocd_sg.id
  cidr_ipv4         = "0.0.0.0/0" # Allow all outbound traffic
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#SSH KEYPAIR FOR THE INSTANCE
# Generate SSH key pair
module "argocd_ec2_keypair" {
  source       = "./modules/keypair"
  ssh_key_name = "argocd-keypair"  # Give a name to the EC2 keypair
}

# Store the private key in Secrets Manager
module "argocd_ec2_keypair_store" {
  source        = "./modules/secrets_manager"
  secrets_name  = "argocd-ec2-keypair"                     # Secret name in AWS Secrets Manager
  description   = "SSH Key Pair for ArgoCD EC2 Instance"   # Description
  secret_string = module.argocd_ec2_keypair.private_key_pem  # Store the actual private key PEM
}

#EBS VOLUME
module "argocd_ec2_ebs" {
  source = "./modules/ebs"
  availability_zone = module.argocd_subnet.az
  ebs_volume_size  = 1  # 1 GB
  ebs_volume_name= "argocd-ebs"
}

# INSTANCE
module "argocd_ec2" {
  source = "./modules/ec2"
  instance_type = "t3.xlarge" # Change this to your desired instance type
  subnet_id = module.argocd_subnet.subnet_id
  ssh_key_name = module.argocd_ec2_keypair.ssh_key_name
  vpc_security_group_id = aws_security_group.argocd_sg.id
  instance_name = "argocd-instance"

}

# Attach EBS volume to the EC2 instance
resource "aws_volume_attachment" "argocd_data_volume_attachment" {
  device_name = "/dev/xvdf"                         # The device name inside the EC2
  volume_id   = module.argocd_ec2_ebs.ebs_volume_id
  instance_id = module.argocd_ec2.instance_id                # The ID of the EC2 instance to attach to
  force_detach = true                               # Force detachment on destroy
}
# add depends on keypair, rds, vpc

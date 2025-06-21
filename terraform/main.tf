terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  
  backend "s3" {
    bucket = "k8s-demo-state-sourav"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC and Networking
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# Security Groups
resource "aws_security_group" "k3s_master" {
  name_prefix = "${var.cluster_name}-master-"
  vpc_id      = module.vpc.vpc_id

  # SSH access (for debugging)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Kubernetes API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # etcd cluster communication
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # ArgoCD Server (if exposed externally)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ArgoCD Server (HTTPS)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus metrics
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana dashboard
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node Exporter metrics
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # k3s metrics
  ingress {
    from_port   = 10255
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Calico networking (if using)
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Flannel networking (if using)
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Health check endpoints
  ingress {
    from_port   = 10248
    to_port     = 10248
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # kube-proxy health check
  ingress {
    from_port   = 10256
    to_port     = 10256
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # ArgoCD metrics
  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ArgoCD repo server
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # ArgoCD application controller
  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow Load Balancer health checks
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    security_groups = [aws_security_group.k3s_api_lb.id]
  }

  # GitHub Actions IP ranges (optional - for direct access if needed)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [
      "192.30.252.0/22",  # GitHub Actions
      "185.199.108.0/22", # GitHub Actions
      "140.82.112.0/20",  # GitHub Actions
      "143.55.64.0/20"    # GitHub Actions
    ]
  }

  # GitHub Actions IPv6 ranges (separate rule for IPv6)
  ingress {
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    ipv6_cidr_blocks = [
      "2a0a:a440::/29", # GitHub Actions IPv6
      "2606:50c0::/32"  # GitHub Actions IPv6
    ]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-master-sg"
  }
}

resource "aws_security_group" "k3s_worker" {
  name_prefix = "${var.cluster_name}-worker-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-worker-sg"
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "k3s_role" {
  name = "${var.cluster_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "k3s_policy" {
  role       = aws_iam_role.k3s_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Additional IAM policy for GitHub Actions access
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "${var.cluster_name}-github-actions-policy"
  role = aws_iam_role.k3s_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstanceInformation",
          "ssm:StartSession",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:DescribeInstanceProperties",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "k3s_profile" {
  name = "${var.cluster_name}-profile"
  role = aws_iam_role.k3s_role.name
}

# Key Pair
resource "aws_key_pair" "k3s_key" {
  key_name   = "${var.cluster_name}-key"
  public_key = var.ssh_public_key
}

# Launch Template for k3s nodes (commented out for single-node setup)
# resource "aws_launch_template" "k3s_lt" {
#   name_prefix   = "${var.cluster_name}-lt"
#   image_id      = "ami-05f9478b4deb8d173"
#   instance_type = var.instance_type

#   key_name = aws_key_pair.k3s_key.key_name

#   vpc_security_group_ids = [aws_security_group.k3s_worker.id]

#   iam_instance_profile {
#     name = aws_iam_instance_profile.k3s_profile.name
#   }

#   user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
#     cluster_name      = var.cluster_name
#     node_type         = "worker"
#     enable_argocd     = var.enable_argocd
#     enable_monitoring = var.enable_monitoring
#   }))

#   block_device_mappings {
#     device_name = "/dev/sda1"
#     ebs {
#       volume_size = 20
#       volume_type = "gp3"
#       encrypted   = true
#     }
#   }

#   metadata_options {
#     http_tokens = "required"
#   }

#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "${var.cluster_name}-node"
#     }
#   }
# }

# Auto Scaling Group for k3s workers (commented out for single-node setup)
# resource "aws_autoscaling_group" "k3s_workers" {
#   name                = "${var.cluster_name}-workers"
#   desired_capacity    = var.worker_count
#   max_size           = var.worker_max_count
#   min_size           = var.worker_min_count
#   target_group_arns  = [aws_lb_target_group.k3s_tg.arn]
#   vpc_zone_identifier = module.vpc.private_subnets

#   launch_template {
#     id      = aws_launch_template.k3s_lt.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "kubernetes.io/cluster/${var.cluster_name}"
#     value              = "owned"
#     propagate_at_launch = true
#   }

#   tag {
#     key                 = "Name"
#     value              = "${var.cluster_name}-worker"
#     propagate_at_launch = true
#   }
# }

# Application Load Balancer for app traffic
resource "aws_lb" "k3s_alb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.cluster_name}-alb"
  }
}

# Load Balancer for Kubernetes API Server
resource "aws_lb" "k3s_api_lb" {
  name               = "${var.cluster_name}-api-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.cluster_name}-api-lb"
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

# Security Group for Kubernetes API Load Balancer
resource "aws_security_group" "k3s_api_lb" {
  name_prefix = "${var.cluster_name}-api-lb-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-api-lb-sg"
  }
}

resource "aws_lb_target_group" "k3s_tg" {
  name     = "${var.cluster_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

# Target Group for Kubernetes API Server
resource "aws_lb_target_group" "k3s_api_tg" {
  name     = "${var.cluster_name}-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "k3s_listener" {
  load_balancer_arn = aws_lb.k3s_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_tg.arn
  }
}

# Listener for Kubernetes API Load Balancer
resource "aws_lb_listener" "k3s_api_listener" {
  load_balancer_arn = aws_lb.k3s_api_lb.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_api_tg.arn
  }
}

# Master node (single instance for demo)
resource "aws_instance" "k3s_master" {
  ami                    = "ami-05f9478b4deb8d173"
  instance_type          = var.instance_type
  key_name              = aws_key_pair.k3s_key.key_name
  vpc_security_group_ids = [aws_security_group.k3s_master.id]
  subnet_id             = module.vpc.private_subnets[0]
  iam_instance_profile  = aws_iam_instance_profile.k3s_profile.name

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    cluster_name      = var.cluster_name
    node_type         = "master"
    enable_argocd     = var.enable_argocd
    enable_monitoring = var.enable_monitoring
  }))

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.cluster_name}-master"
  }

  depends_on = [module.vpc]
}

# Attach master node to API Load Balancer
resource "aws_lb_target_group_attachment" "k3s_api" {
  target_group_arn = aws_lb_target_group.k3s_api_tg.arn
  target_id        = aws_instance.k3s_master.id
  port             = 6443
} 
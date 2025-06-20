variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k3s-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "cluster_name" {
  description = "Name of the k3s cluster"
  type        = string
  default     = "k3s-demo-cluster"
}

variable "instance_type" {
  description = "EC2 instance type for k3s nodes"
  type        = string
  default     = "t3.micro"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     =   1
}

variable "worker_min_count" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "worker_max_count" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instances"
  type        = string
  default     = ""
}

variable "k3s_version" {
  description = "k3s version to install"
  type        = string
  default     = "v1.28.5+k3s1"
}

variable "k3s_token" {
  description = "k3s cluster token (auto-generated if empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "SSL certificate ARN for HTTPS"
  type        = string
  default     = ""
} 
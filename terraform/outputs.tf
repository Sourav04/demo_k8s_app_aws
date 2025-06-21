output "cluster_name" {
  description = "Name of the k3s cluster"
  value       = var.cluster_name
}

output "master_node_ip" {
  description = "Private IP of the master node"
  value       = aws_instance.k3s_master.private_ip
}

output "master_instance_id" {
  description = "Instance ID of the master node"
  value       = aws_instance.k3s_master.id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.k3s_alb.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.k3s_alb.zone_id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.k3s_alb.arn
}

output "kubernetes_api_lb_dns" {
  description = "DNS name of the Kubernetes API Load Balancer"
  value       = aws_lb.k3s_api_lb.dns_name
}

output "kubernetes_api_lb_arn" {
  description = "ARN of the Kubernetes API Load Balancer"
  value       = aws_lb.k3s_api_lb.arn
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig from master node"
  value       = "ssh -i ${var.ssh_public_key != "" ? "~/.ssh/id_rsa" : "your-key.pem"} ubuntu@${aws_instance.k3s_master.private_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml'"
}

output "argocd_admin_password" {
  description = "ArgoCD admin password (run this command on master node)"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}

output "connect_to_master" {
  description = "SSH command to connect to master node"
  value       = "ssh -i ${var.ssh_public_key != "" ? "~/.ssh/id_rsa" : "your-key.pem"} ubuntu@${aws_instance.k3s_master.private_ip}"
}

output "cluster_info" {
  description = "Cluster information"
  value = {
    name           = var.cluster_name
    region         = var.aws_region
    instance_type  = var.instance_type
    worker_count   = var.worker_count
    master_ip      = aws_instance.k3s_master.private_ip
    lb_dns         = aws_lb.k3s_alb.dns_name
    vpc_id         = module.vpc.vpc_id
  }
} 
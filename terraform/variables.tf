variable "aws_region" {
  description = "Region for every resource (the course default is Mumbai)."
  type        = string
  default     = "ap-south-1"
}

variable "owner" {
  description = "Tag value that shows who created the resources."
  type        = string
}

variable "name" {
  description = "Prefix for every resource."
  type        = string
  default     = "readcycle"
}

variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "azs" {
  description = "Availability-zone suffixes to spread the subnets over."
  type        = list(string)
  default     = ["a", "b"]
}

variable "cluster_version" {
  description = "Kubernetes version of the EKS control plane; must be in standard support (see eks.tf)."
  type        = string
  default     = "1.34"
}

variable "node_instance_types" {
  # The AWS Free plan only allows Free Tier eligible types (t3.micro, t3.small, t4g.*,
  # c7i-flex.large, m7i-flex.large); m7i-flex.large (2 vCPU, 8 GiB) fits the app, Argo CD
  # and monitoring on one node.
  description = "EC2 instance types for the worker nodes."
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "node_scaling" {
  description = "Worker node count; one node keeps the cost lowest."
  type        = object({ min = number, desired = number, max = number })
  default = {
    min     = 1
    desired = 1
    max     = 2
  }
}

variable "node_disk_size" {
  description = "Root volume size of each worker node, in GiB."
  type        = number
  default     = 20
}

variable "api_allowed_cidrs" {
  description = "Who may reach the public EKS API endpoint; set your own IP as x.x.x.x/32."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "EKS control-plane logs sent to CloudWatch (billed per GB); off by default."
  type        = list(string)
  default     = []
}

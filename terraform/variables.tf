variable "instance_names" {
  description = "Create EC2 instances with these names"
  type        = list(string)
  default     = ["main", "worker1", "worker2"]
}
variable "ssh_user" {
  description = "SSH user for the nodes"
  type        = string
}

variable "ssh_ip" {
  description = "SSH IP address of the node"
  type        = string
}

variable "rke2_id" {
  description = "RKE2 node identifier"
  type        = string
}

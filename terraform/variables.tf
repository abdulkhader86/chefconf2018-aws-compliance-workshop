variable "automate_admin_password" {}
variable "automate_channel" {}
variable "automate_license" {}
variable "aws_tag_x_contact" {}
variable "chef_admin_username" {}
variable "chef_admin_password" {}
variable "lab_prefix" {}
variable "ssh_public_key" {}
variable "ssh_private_key_path" {}
variable "workstation_username" {}
variable "workstation_password" {}

variable "participants" {
  type = "list"
}

variable "aws_profile" {
  default = "default"
}

variable "aws_region" {
  default = "us-east-1"
}

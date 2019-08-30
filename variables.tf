variable "region" {}

variable "vpc_id" {
  type = "string"
}

variable "private_subnet_ids" {
  type = "list"
}

variable "dns_zone_id" {
  type = "string"
}

variable "custom_tags" {
  type = "map"
}

variable "project" {
  type    = "string"
  default = "name-prod"
}

variable "launch_template_id_for_asg" {
  type = "string"
}

variable "asg_default_cooldown" {
  default = 60
}

variable "asg_health_check_grace_period" {
  default = 60
}

variable "asg_max_size" {
  default = 6
}

variable "asg_min_size" {
  default = 2
}

variable "asg_desired_capacity" {
  default = 2
}

variable "health_check_matcher" {
  default = "200-299"
}

variable "health_check_path" {
  default = "/"
}

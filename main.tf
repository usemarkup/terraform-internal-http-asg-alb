provider "aws" {
  region = "${var.region}"
}

data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

resource "aws_route53_record" "nlb_record" {
  zone_id = "${var.dns_zone_id}"

  name = "${var.project}-alb"
  type = "A"

  alias {
    name                   = "${module.alb.dns_name}"
    zone_id                = "${module.alb.load_balancer_zone_id}"
    evaluate_target_health = true
  }
}

locals {
  alb_sg_tags = {
    MarkupTerraformReference = "${var.project}-alb-sg"
    Name                     = "${var.project}-alb-sg"
  }

  alb_tags = {
    MarkupTerraformReference = "${var.project}-alb"
    Name                     = "${var.project}-alb"
  }
}

resource "aws_security_group" "alb_sg" {
  name = "${var.project}-alb-sg"
  tags = "${merge(local.alb_sg_tags, var.custom_tags)}"

  vpc_id = "${var.vpc_id}"

  lifecycle {
    create_before_destroy = true
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  # WE CANNOT USE v4 UNTIL TF 0.12
  version = "~> 3.0"

  security_groups = [
    "${aws_security_group.alb_sg.id}",
  ]

  subnets = "${var.private_subnet_ids}"
  vpc_id  = "${var.vpc_id}"

  # Optional Values
  logging_enabled          = "false"
  http_tcp_listeners_count = 1
  https_listeners_count    = 0

  http_tcp_listeners = [
    {
      port            = 80
      protocol = "HTTP"

    },
  ]

  enable_cross_zone_load_balancing = true

  load_balancer_is_internal = "true"
  load_balancer_name        = "${var.project}-alb-lb"

  target_groups = [
    {
      backend_port     = "80"
      backend_protocol = "HTTP"
      name             = "${var.project}-asg-tg"
    },
  ]

  tags = "${merge(local.alb_tags, var.custom_tags)}"

  target_groups_count = 1

  target_groups_defaults = {
    cookie_duration                  = 86400
    deregistration_delay             = 30
    health_check_interval            = 6
    health_check_healthy_threshold   = 5
    health_check_path                = "${var.health_check_path}"
    health_check_port                = "traffic-port"
    health_check_timeout             = 5
    health_check_unhealthy_threshold = 2
    health_check_matcher             = "${var.health_check_matcher}"
    stickiness_enabled               = false
    target_type                      = "instance"
    slow_start                       = 30
  }
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity    = "${var.asg_desired_capacity}"
  max_size            = "${var.asg_max_size}"
  min_size            = "${var.asg_min_size}"
  default_cooldown    = "${var.asg_default_cooldown}"
  vpc_zone_identifier = ["${var.private_subnet_ids}"]
  name                = "${var.project}-asg"
  
  health_check_type   = "ELB"

  termination_policies = [
    "OldestLaunchTemplate",
    "OldestInstance",
  ]

  health_check_grace_period = "${var.asg_health_check_grace_period}"

  target_group_arns = ["${module.alb.target_group_arns}"]

  launch_template {
    id      = "${var.launch_template_id_for_asg}"
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "${var.project}-asg"
    propagate_at_launch = false
  }

  tag {
    key = "MarkupTerraformReference"
    value = "${var.project}-asg"
    propagate_at_launch = false
  }
}

resource "aws_sns_topic" "topic" {
  name = "${var.project}-asg-sns"
}

resource "aws_autoscaling_notification" "notifications" {
  group_names = [
    "${aws_autoscaling_group.asg.name}",
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = "${aws_sns_topic.topic.arn}"
}

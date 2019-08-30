# Terraform Internal ASG ALB

Simple & opinionated module to create an ALB with an ASG for Nginx

- Creates simple Application Load Balancer listening on 80
- Creates Security Group to handle traffic and allow communication with the Auto Scaling Instances
- Creates a DNS record for the LB
- Creates a SNS topic for notifications

## Prerequisites

- Private Subnet
- Launch Template
- Security Group for use with the ASG
- DNS Zone

### Note

Public, Not Open Source. No support comes with this Module.

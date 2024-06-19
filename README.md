# nginx-test for 15gifts


# Terraform AWS Infrastructure

This repository contains Terraform configuration files to set up the following AWS resources:
- A Load Balancer with TLS
- Two EC2 instances served by the Load Balancer
- A MySQL database

## Prerequisites

- Terraform installed on your machine
- AWS CLI configured with appropriate credentials

## Usage

Locally (Please export your AWS credentials): 

1. Clone the repository:
git clone https://github.com/your-repo/terraform-aws-infrastructure.git

cd terraform-aws-infrastructure


2. Initialize Terraform:
terraform init

3. verify and plan the terraform code: 
terraform verify && terraform plan

4. Apply the Terraform configuration:
Terraform apply


5. After the apply is complete, you will see the DNS name of the Load Balancer. You can open this URL in your browser to see the web server response.


## Clean Up

To remove all resources created by this configuration, run:
terraform destroy

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.54.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | 9.9.0 |
| <a name="module_asg"></a> [asg](#module\_asg) | terraform-aws-modules/autoscaling/aws | 7.6.0 |
| <a name="module_db"></a> [db](#module\_db) | terraform-aws-modules/rds/aws | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.8.1 |

## Resources

| Name | Type |
|------|------|
| [aws_security_group.asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_asg"></a> [asg](#output\_asg) | n/a |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | n/a |

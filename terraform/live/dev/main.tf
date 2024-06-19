locals {
  region           = "eu-west-1"
  environment_name = "dev"
}

######################################################################################
#-----------------------------VPC-----------------------------------------------------
######################################################################################
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${local.environment_name}-15gifts"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", ]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", ]
  public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", ]

  enable_nat_gateway = true
}

######################################################################################
#-----------------------------ALB-----------------------------------------------------
######################################################################################
# https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name                       = "my-alb"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "nginx"
      }
    }
  }

  target_groups = {
    nginx = {
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "instance"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      # There's nothing to attach here in this definition.
      # The attachment happens in the ASG module above
      create_attachment = false
    }
  }
}

######################################################################################
#-----------------------------ASG-----------------------------------------------------
######################################################################################
# https://registry.terraform.io/modules/terraform-aws-modules/autoscaling/aws/latest
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.6.0"

  # Autoscaling group
  name = "example-asg"

  min_size            = 1
  max_size            = 2
  desired_capacity    = 2
  security_groups     = [aws_security_group.asg.id]
  health_check_type   = "EC2"
  vpc_zone_identifier = module.vpc.private_subnets

  user_data = base64encode(file("user_data.sh"))

  create_traffic_source_attachment = true
  traffic_source_identifier        = module.alb.target_groups["nginx"].arn
  traffic_source_type              = "elbv2"

  initial_lifecycle_hooks = [
    {
      name                 = "ExampleStartupLifeCycleHook"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 60
      lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
      # This could be a rendered data resource
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                 = "ExampleTerminationLifeCycleHook"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 180
      lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
      # This could be a rendered data resource
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]
  # Launch template
  launch_template_name        = "example-asg"
  launch_template_description = "Launch template example"
  update_default_version      = true

  image_id          = data.aws_ami.ubuntu.image_id
  instance_type     = "t3.micro"
  ebs_optimized     = true
  enable_monitoring = true

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "example-asg"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role example"

  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp2"
      }
    },
  ]

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  placement = {
    availability_zone = "us-west-1b"
  }


  tags = {}
}

resource "aws_security_group" "asg" {
  name   = "asg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id] # Allow traffic from ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


###########################################################################
#-----------------------DB-------------------------------------------------
###########################################################################

#https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "nginxdb"

  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "nginxdb"
  username = "user"
  port     = "3306"

  iam_database_authentication_enabled = true

  #vpc_security_group_ids = module.vpc.private_subnets

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring 
  monitoring_interval    = "30"
  monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = true

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection - setting it to false for this test only
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}




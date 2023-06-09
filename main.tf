terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "dkorobenko"

    workspaces {
      name = "learning-terraform"
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.1.0"
    }
  }
}

resource "aws_ecr_repository" "app_ecr_repo" {
  name = "app-repo"
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "app-cluster"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-first-task"
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add VPN network mode as this is required for Fargate
  memory                   = 512         # specify the memory that container requires
  cpu                      = 256         # specify the CPU that container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}" # grant required permissions to make AWS API calls
  container_definitions    = <<DEFINITION
  [
    {
      "name": "app-first-task",
      "image": "${aws_ecr_repository.app_ecr_repo.repository_url}",
      "essential": true,
      "memory": 512,
      "cpu": 256,
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 5000
        }
      ]
    }
  ]
  DEFINITION
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "eu-central-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "eu-central-1b"
}

resource "aws_alb" "application_load_balancer" {
  name               = "load-balancer-dev"
  load_balancer_type = "application"
  subnets = [
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allow traffic in from all sources
  }

  egress {  # allow all egress rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}" # default VPC
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}" # load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # target group
  }
}

resource "aws_ecs_service" "app_service" {
  name            = "app-first-service" # name the service
  cluster         = "${aws_ecs_cluster.my_cluster.id}" # reference the created cluster
  task_definition = "${aws_ecs_task_definition.app_task.arn}" # reference the task that the service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # set up the number of containers to 3

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # reference the target group
    container_name   = "${aws_ecs_task_definition.app_task.family}"
    container_port   = 5000 # specify the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}"]
    assign_public_ip = true # provide the containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"] # det up the security group
  }
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # allow traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress { # allow all egress rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "app_url" {
  value = aws_alb.application_load_balancer.dns_name # log the load balancer app URL
}
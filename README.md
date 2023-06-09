# SRE Internship - First App
  - [Prerequisites](#prerequisites)
  - [Project Description](#project-description)
  - [Create Website](#create-website)
  - [Containerize Application](#containerize-application)
  - [Deploy Using Terraform](#deploy-using-terraform)
    + [Initial Setup](#initial-setup)
    + [Create an ECR on AWS ECS and Push the Docker Image](#create-an-ecr-on-aws-ecs-and-push-the-docker-image)
    + [Create an ECS Cluster and Configure AWS ECS Task Definitions](#create-an-ecs-cluster-and-configure-aws-ecs-task-definitions)
    + [Launch the Container](#launch-the-container)
    + [Test the Infrastructure](#test-the-infrastructure)
  - [Automate with GitHub Actions](#automate-with-github-actions)
  - [Useful Links](#useful-links)

## Prerequisites

Create accounts, install neccessary tools and extensions to the [code editor](https://www.hostinger.com/tutorials/best-code-editors):
- [Github](https://github.com/pricing)/[Git](https://git-scm.com/downloads)
- [AWS](https://aws.amazon.com/free)/[AWS CLI](https://formulae.brew.sh/formula/awscli)
- [Docker](https://www.docker.com)
- [Terraform CLI](https://www.terraform.io)

The list of recommended documentation/tutorials/cheetsheets/courses/etc is mentioned at the end of this file.

## Project Description

- Find a basic Flask site and personalize it
- Dockerize the Flask application
- Deploy AWS infrastructure using Terraform and manually push the Docker image to AWS ECR repository
- Automate the workflow with GitHub Actions

## Create Website

At first, I found [a basic website](https://github.com/gurkirat63/Flask-PersonalSite) on Github built with Flask and personalized it by modifying [index.html file](https://github.com/dkorobenko-mwb/website/blob/6f085106ec51ef8131d12b30999b10373081f627/templates/index.html):

![Personalized website](/images/website.png)

## Containerize Application

Now I will try to containerize my application with Docker.

1. Created [Dockerfile](https://github.com/dkorobenko-mwb/website/blob/6f085106ec51ef8131d12b30999b10373081f627/Dockerfile) to containerize the application by following [documentation](https://www.freecodecamp.org/news/how-to-dockerize-a-flask-app/):

```dockerfile
# use an official dockerhub node runtime as a parent image
FROM node:12.7.0-alpine

# set the working directory
WORKDIR /app

# install app dependencies
COPY requirements.txt requirements.txt
RUN apk add py3-pip
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt

# copy all code to the working directory
COPY . .

# set flask env variables
ENV FLASK_APP=main.py
ENV FLASK_ENV=development

# make port 5000 available to the world (outside of the container)
EXPOSE 5000

# run flask app
CMD [ "flask", "run", "--host", "0.0.0.0" ]
```

2. Built the container and run it:

```sh
docker build -t website:latest . # build image with tag ('-t')
docker run -p 5000:5000 website:latest # run image with exposed port ('-p')
```

Verified through terminal that the application was successfully built:

![Docker build](/images/docker_build.png)

3. Verified that the application is working inside the container:

![Website inside container](/images/container_website.png)

Verified that the application is working outside of the container by going to http://localhost:5000/:

![Proof of working website](/images/docker_website.png)

Docker Desktop could also be used to check the current state of the containers/images:

![Docker Desktop](/images/docker_desktop.png)

4. Followed the [handbook](https://linuxhandbook.com/essential-docker-commands/) to check what containers are currently running, stop and remove them:
```sh
docker ps # check running containers
docker stop container-name-or-id # stop the container
docker rm container_or_image_name_or_id # remove image/container
```

## Deploy Using Terraform

Next step would be to deploy Docker container to AWS ECS using Terraform (with the help of [this tutorial](https://earthly.dev/blog/deploy-dockcontainers-to-awsecs-using-terraform/)).

### Initial Setup

1. [Created an IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) in my AWS account with administrator access and programmatic access key:

![IAM user](/images/iam_user.png)

2. Copied the credentials and configured them to AWS CLI by running:
```sh
aws configure
```

Provided AWS IAM user details:

+ AWS Access Key ID
+ AWS Secret Access Key
+ Default region name
+ Default output format 

3. Logged in to Terraform Cloud from CLI by following [this tutorial](https://developer.hashicorp.com/terraform/tutorials/0-13/cloud-login), generated a token and copied it to the CLI:

```sh
terraform login
```

![Terraform token](/images/terraform_token.png)

4. Created a new workspace with CLI-driven workflow:

![Terraform workspace](/images/terraform_workspace.png)

5. Added AWS configuration credentials as environmental variables to allow Terraform to connect to AWS:

![Terraform variables](/images/terraform_envs.png)

### Create an ECR on AWS ECS and Push the Docker Image

ECR is an AWS service for sharing and deploying container applications. This service offers a fully managed container registry that makes the process of storing, managing, sharing, and deploying your containers easier and faster. First, I will need to set up ECR to deploy my application to ECS.

1. Created [main.tf file](https://github.com/dkorobenko-mwb/website/blob/c682dd2f4372fbca8d1f07d3d15a31f9bc9db992/main.tf) and added [remote backend configuration](https://developer.hashicorp.com/terraform/language/settings/backends/remote) to store state snapshots and execute operations in Terraform Cloud:

```tf
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "dkorobenko"

    workspaces {
      name = "learning-terraform"
    }
  }
}
```

2. Added [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest) to [main.tf file](https://github.com/dkorobenko-mwb/website/blob/25bc5bbb769ea44bc039ca9631cef6d6fb5da873/main.tf) to allow Terraform to connect to AWS:

```tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.1.0"
    }
  }
}
```

3. Created an [Elastic Container Registry (ECR)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) in [main.tf file](https://github.com/dkorobenko-mwb/website/blob/25bc5bbb769ea44bc039ca9631cef6d6fb5da873/main.tf):

```tf
resource "aws_ecr_repository" "app_ecr_repo" {
  name = "app-repo"
}
```

4. Applied the created Terraform configuration ([cheatsheet](https://acloudguru.com/blog/engineering/the-ultimate-terraform-cheatsheet)):

```sh
terraform init  # initialize directory, pull down providers
terraform plan  # preview changes required by the current configuration
terraform apply # provision the displayed configuration infrastructure on AWS
```

5. Verified via AWS Console that an ECR repository was created:

![ECR repository](/images/ecr_repo.png)

6. Navigated to ECR repository and clicked the `View push commands` button, as shown below:

![ECR repository v2](/images/ecr_repo_v2.png)

A pop-up was launched with the push commands for this repository:

![ECR push commands](/images/push_repo.png)

7. Executed the following command in the CLI to run a token that authenticates and connects Docker client to ECR repository:

```sh
aws ecr get-login-password --region REGION | docker login \     #REGION = your AWS region
--username AWS --password-stdin ID.dkr.ecr.REGION.amazonaws.com #ID     = your AWS account id
```

8. Built the Docker image, tagged it and pushed to ECR repository:

```sh
docker build -t app-repo .
docker tag app-repo:latest ID.dkr.ecr.REGION.amazonaws.com/app-repo:latest #ID     = your AWS account id
docker push ID.dkr.ecr.REGION.amazonaws.com/app-repo:latest                #REGION = your AWS region
```

9. Verified via AWS Console that the image was successfully pushed to ECR repository:

![ECR image](/images/ecr_image.png)

10. To avoid additional AWS costs `terraform destroy` command should be applied. But once Terraform section will come to an end, to verify that the setup is actually working the docker image has to be created again.

### Create an ECS Cluster and Configure AWS ECS Task Definitions

I have created a repository and deployed the image, but to launch it I will need a target. A cluster acts as the container target. It takes a task into the cluster configuration and runs that task within the cluster. The ECS agent communicates with the ECS cluster and receives requests to launch the container. 

I added the following configurations to [main.tf file](https://github.com/dkorobenko-mwb/website/blob/25bc5bbb769ea44bc039ca9631cef6d6fb5da873/main.tf) to create a cluster where I will run a task:

```tf
resource "aws_ecs_cluster" "my_cluster" {
  name = "app-cluster"
}
```

The image is now hosted in the ECR, but to run the image, I need to launch it onto an ECS container. To deploy the image to ECS, I first need to create a task. A task tells ECS how I want to spin up Docker container. It describes the container’s critical specifications which include:

+ Port mappings
+ Application image
+ CPU and RAM resources
+ Container launch types such as EC2 or Fargate

Fargate (that I am going to use) is an AWS orchestration tool which runs container as serverless, so I do not have to provision container using a virtual machine on AWS. Using Task definition JSON format, I provided the container specifications in [main.tf file](https://github.com/dkorobenko-mwb/website/blob/25bc5bbb769ea44bc039ca9631cef6d6fb5da873/main.tf) by following [Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) and [AWS]() documentation:

```tf
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
```

Creating a task definition requires ecsTaskExecutionRole to be added to IAM, so I created a resource to execute this role by following [Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) and [AWS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html) documentation:

```tf
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
```

### Launch the Container

At this point, I need to create VPC and subnets to launch the cluster into. The load balancer must use a VPC with two public subnets in different Availability Zones. VPC and subnets allow to connect to the internet, communicate with ECS, and expose the application to available zones.

1. Created a default VPC by following [the documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_vpc):

```tf
resource "aws_default_vpc" "default_vpc" {
}
```

2. Created default subnets by following [the documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_subnet):

```tf
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "eu-central-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "eu-central-1b"
}
```

3. Implemented an application load balancer by following [the documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb):

```tf
resource "aws_alb" "application_load_balancer" {
  name               = "load-balancer-dev"
  load_balancer_type = "application"
  subnets = [
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}
```

4. Created a security group for the load balancer by following [the documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group):

```tf
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
```

5. Target group directs traffic to Amazon ECS application's task set. Listener is used by load balancer to direct traffic to target group. Both are required to configure the load balancer with the VPC networking I created earlier, and were defined by following [the documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener):

```tf
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
```

6. The last step is to create an ECS Service to maintain task definition in ECS cluster. The service should run the cluster, task, and Fargate behind the created load balancer to distribute traffic across the containers that are associated with the service. ECS Service was configured by following [the documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service):

```tf
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
```

7. To access ECS service over HTTP while ensuring the VPC is more secure, I created a security group that will only allow the traffic from the created load balancer:

```tf
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
```

8. Additionally, added an output config that will extract the load balancer URL value from the state file and log it onto the terminal:

```tf
output "app_url" {
  value = aws_alb.application_load_balancer.dns_name # log the load balancer app URL
}
```

### Test the Infrastructure

Now it is time to test the infrastrucure that was created with Terraform.

1. Applied the created Terraform configuration ([cheatsheet](https://acloudguru.com/blog/engineering/the-ultimate-terraform-cheatsheet)):

```sh
terraform init  # initialize directory, pull down providers
terraform plan  # preview changes required by the current configuration
terraform apply # provision the displayed configuration infrastructure on AWS
```

The output should end with an application's URL:

![Terraform output](/images/app_url.png)

2. After copying URL to the browser, I was able to access my AWS ECS provisioned application:

![Terraform website](/images/terraform_website.png)

>**Note!** If you ran terraform destroy earlier, you need to push the Docker image manually to the ECR repository again and refresh the web page.

3. Finally, I verified via AWS Console that all the services like Load Balancer, VPC/Subnets, ECS Cluster, etc were created according to the Terraform configuration. For instance, Load Balancer:

![Load Balancer](/images/load_balancer.png)

4. Last but not least, I ran `terraform destroy` to avoid any additional AWS expenses.

## Automate with GitHub Actions

## Useful Links

All learning materials recommended here are free, except for books (more in-depth knowledge).

- GitHub
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()

- AWS
  + [Documentation](https://docs.aws.amazon.com/)
  + [Skill Builder](https://skillbuilder.aws/)
  + [Documentation]()
  + [Documentation]()

- Docker
  + [Documentation](https://docs.docker.com)
  + [Cheat Sheet](https://docs.docker.com/get-started/docker_cheatsheet.pdf)
  + [Course](https://learn.cantrill.io/p/docker-fundamentals)
  + [Other]()

- Terraform
  + [Documentation](https://developer.hashicorp.com/terraform/docs)
  + [Registry](https://registry.terraform.io/)
  + [Best Practices](https://www.terraform-best-practices.com)
  + [Youtube Course](https://youtu.be/SLB_c_ayRMo)
  + [Hands-on Book](https://www.amazon.co.uk/Terraform-Running-Writing-Infrastructure-Code-dp-1098116747/dp/1098116747/ref=dp_ob_title_bk)

- GitHub Actions
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()
<br> </br> 
  >**Note**: I've built this project from many resources which were mentioned throughout the file. *Useful Links* section is purely a source of information for you about where to get the basic knowledge required to complete this project.
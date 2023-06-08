# SRE Internship - First App
  - [Prerequisites](#prerequisites)
  - [Create Website](#create-website)
  - [Containerize Application](#containerize-application)
  - [Deploy Using Terraform](#deploy-using-terraform)
    + [Initial Setup](#initial-setup)
    + [Create an ECR on AWS ECS](#create-an-ecr-on-aws-ecs)
    + [Create an ECS Cluster](#create-an-ecs-cluster)
    + [Configure AWS ECS Task Definitions](#configure-aws-ecs-task-definitions)
    + [Launch the Container](#launch-the-container)
    + [Test the Infrastructure](#test-the-infrastructure)
  - [Automate with GitHub Actions](#automate-with-github-actions)

## Prerequisites

Created accounts, installed neccessary tools and extensions to my [code editor](https://www.hostinger.com/tutorials/best-code-editors):
- [Github](https://github.com/pricing)/[Git](https://formulae.brew.sh/formula/git)
- [AWS](https://aws.amazon.com/free)/[AWS CLI](https://formulae.brew.sh/formula/awscli)
- [Docker](https://www.docker.com)
- [Terraform](https://www.terraform.io)

## Create Website

Found [a basic website](https://github.com/gurkirat63/Flask-PersonalSite) on Github built with Flask and personalized it by modifying [index.html file](https://github.com/dkorobenko-mwb/website/blob/6f085106ec51ef8131d12b30999b10373081f627/templates/index.html):

![Personalized website](/images/website.png)

## Containerize Application

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

Deployed Docker container to AWS ECS using Terraform with the help of [this tutorial](https://earthly.dev/blog/deploy-dockcontainers-to-awsecs-using-terraform/).

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

### Create an ECR on AWS ECS

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

2. Added [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest) to `main.tf` to allow Terraform to connect to AWS:

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

3. Created an [Elastic Container Registry (ECR)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) in `main.tf`:

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

6. Navigated to ECR repository and clicked the View push commands button, as shown below:



7. Executed the following command to run a token that authenticates and connects Docker client to ECR repository:

```sh
aws ecr get-login-password --region REGION | docker login \     #REGION = your AWS region
--username AWS --password-stdin ID.dkr.ecr.REGION.amazonaws.com #ID     = your AWS account id
```

8. Built the container and pushed the image to ECR repository:

```sh
docker build -t website:latest .
docker push website:latest
```

9. Verified via AWS Console that the image was successfully pushed to ECR repository:

![ECR repository v2](/images/ecr_repo_v2.png)

### Create an ECS Cluster

### Configure AWS ECS Task Definitions

### Launch the Container

### Test the Infrastructure

## Automate with GitHub Actions

## Useful Links

- GitHub
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()

- AWS
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()

- Docker
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()

- Terraform
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()

- GitHub Actions
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()
  + [Documentation]()
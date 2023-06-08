# SRE Internship - First App
  - [Prerequisites](#prerequisites)
  - [Create Website](#create-website)
  - [Containerize Application](#containerize-application)
  - [Deploy Using Terraform](#deploy-using-terraform)
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
# use an official node runtime as a parent image
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

Followed the [handbook](https://linuxhandbook.com/essential-docker-commands/) to check what containers are currently running, stop and remove them:
```sh
docker ps # check running containers
docker stop container-name-or-id # stop the container
docker rm container_or_image_name_or_id # remove image/container
```

## Deploy Using Terraform

## Automate with GitHub Actions
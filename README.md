# SRE Internship - First App
  - [Prerequisites](#prerequisites)
  - [Create Website](#create-website)
  - [Containerize Application](#containerize-application)
  - [Deploy Using Terraform](#deploy-using-terraform)
  - [Automate with GitHub Actions](#automate-with-github-actions)

## Prerequisites

Create accounts, install neccessary tools and extensions to your [code editor](https://www.hostinger.com/tutorials/best-code-editors):
- [Github](https://github.com/pricing)/[Git](https://formulae.brew.sh/formula/git)
- [AWS](https://aws.amazon.com/free)/[AWS CLI](https://formulae.brew.sh/formula/awscli)
- [Docker](https://www.docker.com)
- [Terraform](https://www.terraform.io)

## Create Website

Find [a basic website](https://github.com/gurkirat63/Flask-PersonalSite) on Github built with Flask and personalize it:

![Personalized website](/images/website.png)

## Containerize Application

Create Dockerfile to containerize the application by following [documentation](https://www.freecodecamp.org/news/how-to-dockerize-a-flask-app/):

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

## Deploy Using Terraform

## Automate with GitHub Actions
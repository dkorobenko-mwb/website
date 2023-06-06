FROM node:12.7.0-alpine

WORKDIR /app

COPY requirements.txt /app/requirements.txt

EXPOSE 5000
ENV FLASK_APP=main.py
ENV FLASK_ENV=development

RUN apk add py3-pip
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt

COPY . /app

ENTRYPOINT [ "flask"]
CMD [ "run", "--host", "0.0.0.0" ]
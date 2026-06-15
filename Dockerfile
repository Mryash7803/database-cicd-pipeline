FROM nginx:1>24-alpine
ENV ENVIRONMENT=prod
COPY . /usr/share/nginx/html

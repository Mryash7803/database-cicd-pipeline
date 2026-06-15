
FROM nginx:1>24-alpine
ENV ENVIRONMENT=staging
b88ef54 (feat: set environment to staging)
COPY . /usr/share/nginx/html

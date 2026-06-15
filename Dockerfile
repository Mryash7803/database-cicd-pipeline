FROM nginx:latest
ENV ENVIRONMENT=dev
COPY . /usr/share/nginx/html

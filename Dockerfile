FROM nginx:alpine

LABEL org.opencontainers.image.title="ai-codyssey-web"

COPY app/ /usr/share/nginx/html/
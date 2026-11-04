FROM nginx:alpine
LABEL org.opencontainers.image.title="codyssey-workspace"
ENV APP_ENV=training
COPY app/ /usr/share/nginx/html/
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1
EXPOSE 80

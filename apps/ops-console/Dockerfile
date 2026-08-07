FROM node:22-alpine AS build
WORKDIR /src
COPY src ./dist

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY startup.sh /usr/local/bin/startup.sh
COPY --from=build /src/dist /usr/share/nginx/html
RUN chmod +x /usr/local/bin/startup.sh \
    && chown -R nginx:nginx /usr/share/nginx/html
USER nginx
EXPOSE 8080
ENV API_BASE=http://localhost:8080
ENTRYPOINT ["/usr/local/bin/startup.sh"]
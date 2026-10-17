FROM node:22-alpine
WORKDIR /app
COPY ["server.js", "Web Task.html", "./"]
# config.json is mounted at /config, accounts/notes/files live in the /data volume
ENV DASH_CONFIG=/config/config.json DASH_DATA=/data HOST=0.0.0.0 PORT=8787 NODE_ENV=production
RUN mkdir -p /data /config && chown node:node /data /config
USER node
EXPOSE 8787
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8787/ || exit 1
CMD ["node", "server.js"]

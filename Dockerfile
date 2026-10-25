# Хороший образ: фиксированная версия, кеш npm, multi-stage и непривилегированный пользователь.
FROM node:22.23.3-alpine3.24 AS dependencies
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund && npm cache clean --force

FROM node:18.0.0-bullseye
ENV NODE_ENV=production
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY --chown=node:node index.js notifier.js modules.js ./
COPY --chown=node:node functions ./functions
COPY --chown=node:node modules ./modules
RUN mkdir -p modules/logger/logs && chown -R node:node modules/logger/logs
USER node
EXPOSE 3000 3001
HEALTHCHECK --interval=20s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:${API_PORT:-3000}/api/ping || exit 1
CMD ["node", "index.js"]

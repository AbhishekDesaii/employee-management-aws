FROM node:22-alpine AS builder

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev && npm cache clean --force

FROM node:22-alpine

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .

RUN chown -R app:app /app

USER app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

CMD ["node", "server.js"]
# Base stage
FROM node:20-slim AS base
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

# Dependencies stage
FROM base AS builder
COPY package.json package-lock.json ./
RUN npm install --frozen-lockfile
COPY . .
RUN npm run build

# Production stage
FROM node:20-slim AS production
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nextjs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/package_prod.json ./package.json
RUN npm install
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.ts ./next.config.ts
COPY --from=builder /app/tsconfig.json ./tsconfig.json

RUN mkdir -p .next/cache/images && chown -R nextjs:nextjs .next/cache/images

USER nextjs
CMD ["npm", "run", "start"]

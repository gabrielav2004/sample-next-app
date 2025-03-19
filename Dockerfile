# Base stage
FROM node:20-slim AS base
WORKDIR /app
ARG PORT=3001
ENV PORT=${PORT}
ENV NEXT_TELEMETRY_DISABLED=1

# Dependencies stage
FROM base AS dependencies
COPY package.json package-lock.json ./
RUN npm install --frozen-lockfile

# Build stage
FROM dependencies AS builder
COPY . .  
COPY --from=dependencies /app/node_modules ./node_modules
RUN npm run build

# Production stage
FROM node:20-slim AS production
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nextjs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/package.json ./package.json
RUN npm install --omit=dev
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.ts ./next.config.ts
COPY --from=builder /app/tsconfig.json ./tsconfig.json
COPY --from=builder /app/postcss.config.mjs ./postcss.config.mjs  # SCSS/PostCSS support
USER nextjs
CMD ["npm", "run", "start"]

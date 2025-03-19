# Base stage
FROM node:22-slim AS base
WORKDIR /app
ARG PORT=3001
ENV PORT=${PORT}
ENV NEXT_TELEMETRY_DISABLED=1

# Dependencies stage
FROM base AS dependencies
COPY package.json package-lock.json ./
RUN npm install --frozen-lockfile

# Build stage
FROM dependencies AS build
COPY . .
COPY --from=dependencies /app/node_modules ./node_modules
RUN npm run build

# Production stage
FROM base AS production
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nextjs
RUN adduser --system --uid 1001 nextjs
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/next.config.js ./next.config.js
COPY --from=build /app/.env ./.env

USER nextjs
CMD ["npm", "run", "start"]

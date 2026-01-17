# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Enable Corepack for Yarn
RUN corepack enable && corepack prepare yarn@stable --activate

# Install dependencies
COPY package.json yarn.lock* ./
RUN yarn install --frozen-lockfile

# Copy source code
COPY tsconfig.json ./
COPY src/ ./src/

# Build the application
RUN yarn build

# Production stage
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Enable Corepack for Yarn
RUN corepack enable && corepack prepare yarn@stable --activate

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 hono

# Copy only production dependencies and built files
COPY package.json yarn.lock* ./
RUN yarn install --frozen-lockfile --production && yarn cache clean

COPY --from=builder /app/dist ./dist

# Change ownership to non-root user
RUN chown -R hono:nodejs /app

USER hono

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

CMD ["node", "dist/server.js"]

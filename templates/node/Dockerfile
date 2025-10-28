# Node.js Project Template for YADS
FROM node:18-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    bash

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy project files
COPY . .

# Build application
RUN npm run build

# Create user
RUN adduser -D -s /bin/bash appuser && \
    chown -R appuser:appuser /app

# Switch to app user
USER appuser

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"]

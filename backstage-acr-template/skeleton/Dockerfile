{%- if values.language == "nodejs" %}
# Node.js Dockerfile
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Build the application
FROM base AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=deps --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json

USER nextjs

EXPOSE ${{ values.container_port }}

CMD ["npm", "start"]

{%- elif values.language == "java" %}
# Java Dockerfile
FROM maven:3.9-openjdk-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM openjdk:17-jre-slim AS runtime
WORKDIR /app

RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app

COPY --from=build --chown=appuser:appuser /app/target/*.jar app.jar

USER appuser

EXPOSE ${{ values.container_port }}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${{ values.container_port }}/health || exit 1

CMD ["java", "-jar", "app.jar"]

{%- elif values.language == "python" %}
# Python Dockerfile
FROM python:3.11-slim AS base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=appuser:appuser . .

USER appuser

EXPOSE ${{ values.container_port }}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${{ values.container_port }}/health || exit 1

{%- if values.framework == "fastapi" %}
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "${{ values.container_port }}"]
{%- elif values.framework == "flask" %}
CMD ["python", "app.py"]
{%- else %}
CMD ["python", "main.py"]
{%- endif %}

{%- elif values.language == "dotnet" %}
# .NET Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE ${{ values.container_port }}

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["${{ values.name }}.csproj", "."]
RUN dotnet restore "${{ values.name }}.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "${{ values.name }}.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "${{ values.name }}.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app

COPY --from=publish --chown=appuser:appuser /app/publish .

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${{ values.container_port }}/health || exit 1

ENTRYPOINT ["dotnet", "${{ values.name }}.dll"]

{%- elif values.language == "go" %}
# Go Dockerfile
FROM golang:1.21-alpine AS builder

# Install git for private modules (if needed)
RUN apk add --no-cache git

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest AS runtime

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates curl

WORKDIR /root/

# Create non-root user
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Copy the binary from builder stage
COPY --from=builder --chown=appuser:appuser /app/main .

USER appuser

EXPOSE ${{ values.container_port }}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${{ values.container_port }}/health || exit 1

CMD ["./main"]

{%- else %}
# Generic Dockerfile
FROM alpine:latest

WORKDIR /app

# Create non-root user
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Copy application files
COPY --chown=appuser:appuser . .

USER appuser

EXPOSE ${{ values.container_port }}

CMD ["echo", "Please customize this Dockerfile for your application"]
{%- endif %}
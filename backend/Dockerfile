# Backend Dockerfile - Spring Boot Application
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copy pom.xml first for better caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage - Use Debian instead of Alpine for better compatibility with Piper TTS
FROM eclipse-temurin:17-jre

# Install wget and other dependencies for Piper TTS
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download and install Piper TTS Linux binary
RUN wget -q https://github.com/rhasspy/piper/releases/download/v1.2.0/piper_amd64.tar.gz && \
    tar -xzf piper_amd64.tar.gz && \
    (test -f piper/piper && mv piper/piper /usr/local/bin/piper || mv piper /usr/local/bin/piper) && \
    (test -d piper && mv piper/*.so* /usr/local/lib/ 2>/dev/null || true) && \
    (test -d piper && mv piper/espeak-ng-data /usr/local/lib/ 2>/dev/null || true) && \
    chmod +x /usr/local/bin/piper && \
    ldconfig && \
    rm -rf piper_amd64.tar.gz piper* && \
    mkdir -p /piper

# Copy the built JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Copy entrypoint script and fix line endings (Windows CRLF -> Linux LF)
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN sed -i 's/\r$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh

# Expose port
EXPOSE 8082

# Health check (simple port check)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8082/api/words || exit 1

# Run the application with Docker profile using entrypoint script
ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]


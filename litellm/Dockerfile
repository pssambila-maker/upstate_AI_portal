FROM ghcr.io/berriai/litellm:main-latest

# Set working directory
WORKDIR /app

# Copy configuration file
COPY config.yaml /app/config.yaml

# Create non-root user for security (HIPAA best practice)
RUN groupadd -r litellm && useradd -r -g litellm litellm

# Set ownership
RUN chown -R litellm:litellm /app

# Switch to non-root user
USER litellm

# Expose port
EXPOSE 4000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4000/health || exit 1

# Run LiteLLM with configuration
# Environment variables will be injected by Azure Container Apps
CMD ["--config", "/app/config.yaml", "--port", "4000", "--num_workers", "4"]

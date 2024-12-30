FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    aws-cli \
    rclone \
    tzdata

# Create necessary directories
RUN mkdir -p /app /app/data /var/log && \
    touch /var/log/cron.log

# Copy our scripts
COPY scripts/backup.sh /app/
COPY scripts/entrypoint.sh /app/

# Make scripts executable
RUN chmod +x /app/*.sh

# Set up working directory
WORKDIR /app

# Make entrypoint executable and run it
ENTRYPOINT ["/app/entrypoint.sh"]

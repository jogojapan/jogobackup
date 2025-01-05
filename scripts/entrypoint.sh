#!/bin/sh

# Validate required environment variables
if [ -z "$JOGOBACKUP_SOURCE" ] || [ -z "$JOGOBACKUP_DEST_BUCKET" ] || \
   [ -z "$JOGOBACKUP_AWS_KEY" ] || [ -z "$JOGOBACKUP_AWS_SECRET" ] || \
   [ -z "$JOGOBACKUP_AWS_STORAGECLASS" ] || \
   [ -z "$JOGOBACKUP_AWS_REGION" ] || \
   [ -z "$JOGOBACKUP_CRON_SCHEDULE" ]; then
    echo "Error: Required environment variables are not set"
    exit 1
fi

echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Container is starting."

# Ensure log file exists and has proper permissions
touch /var/log/cron.log
chmod 0644 /var/log/cron.log

# Remove old pipe if it exists
rm -f /tmp/logpipe

# Create logging pipe
mkfifo /tmp/logpipe
chmod 666 /tmp/logpipe

# Start logging process in background
(tail -F /tmp/logpipe | tee -a /var/log/cron.log) &

# Create cron job - redirect to our named pipe
echo "$JOGOBACKUP_CRON_SCHEDULE /app/backup.sh > /tmp/logpipe 2>&1" > /etc/crontabs/root

# Log startup message
echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Container started, cron schedule: $JOGOBACKUP_CRON_SCHEDULE" > /tmp/logpipe

# Start crond in foreground
exec crond -f -l 8

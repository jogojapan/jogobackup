#!/bin/sh

# Validate required environment variables
if [ -z "$JOGOBACKUP_SOURCE" ] || [ -z "$JOGOBACKUP_DEST_BUCKET" ] || \
   [ -z "$JOGOBACKUP_AWS_KEY" ] || [ -z "$JOGOBACKUP_AWS_SECRET" ] || \
   [ -z "$JOGOBACKUP_AWS_STORAGECLASS" ] || \
   [ -z "$JOGOBACKUP_AWS_REGION" ] || \
   [ -z "$JOGOBACKUP_HOURS" ]; then
    echo "Error: Required environment variables are not set"
    exit 1
fi

# Create logging pipe
mkfifo /tmp/logpipe
chmod 666 /tmp/logpipe

# Start logging process in background
(tail -f /tmp/logpipe | tee -a /var/log/cron.log) &

# Create cron schedule based on JOGOBACKUP_HOURS
CRON_SCHEDULE="0 */$JOGOBACKUP_HOURS * * *"

# Create cron job - redirect to our named pipe
echo "$CRON_SCHEDULE /app/backup.sh > /tmp/logpipe 2>&1" > /etc/crontabs/root

# Start crond in foreground
exec crond -f -l 8

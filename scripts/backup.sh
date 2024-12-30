#!/bin/sh

# Add timestamp to log messages
log() {
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] $*"
}

# Configuration file for storing the last backup date
DATE_FILE="/app/data/last_backup_date"

log "Starting backup process"

# Export rclone environment variables
export RCLONE_CONFIG_AWS_TYPE=s3
export RCLONE_CONFIG_AWS_PROVIDER=AWS
export RCLONE_CONFIG_AWS_ENV_AUTH=false
export RCLONE_CONFIG_AWS_ACCESS_KEY_ID=$JOGOBACKUP_AWS_KEY
export RCLONE_CONFIG_AWS_SECRET_ACCESS_KEY=$JOGOBACKUP_AWS_SECRET
export RCLONE_CONFIG_AWS_REGION=$JOGOBACKUP_AWS_REGION
export RCLONE_CONFIG_AWS_STORAGE_CLASS=$JOGOBACKUP_AWS_STORAGECLASS

# Get current UTC time
current_date=$(date -u "+%Y-%m-%d-%H-%M")
current_ts=$(date -u +%s)

# If date file exists, calculate difference
if [ -f "$DATE_FILE" ]; then
    stored_date=$(cat "$DATE_FILE")
    # Convert stored date to timestamp using BusyBox date
    stored_ts=$(date -u -D "%Y-%m-%d-%H-%M" -d "$stored_date" +%s)

    # Calculate difference in minutes and round up
    diff_minutes=$(( (current_ts - stored_ts + 59) / 60 ))
    log "Last backup was $diff_minutes minutes ago"
else
    # If no date file exists, use a large number (1 year in minutes)
    diff_minutes=$((525600))
    log "No previous backup found, setting max age to $diff_minutes minutes"
fi

# Run rclone with calculated max-age
log "Starting rclone copy with max-age ${diff_minutes}m"
if rclone copy \
    --max-age "${diff_minutes}m" \
    --s3-storage-class "$JOGOBACKUP_STORAGECLASS" \
    --progress \
    --stats 30s \
    "$JOGOBACKUP_SOURCE" \
    "aws:$JOGOBACKUP_DEST_BUCKET" 2>&1; then

    # If successful, update the date file
    echo "$current_date" > "$DATE_FILE"
    log "Backup completed successfully"
else
    log "Backup failed with error code $?"
    exit 1
fi

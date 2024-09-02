#!/bin/bash

# Configuration
BACKUP_DIR="/var/lib/vz/dump"
LOG_DIR="/var/log"
KEEP_COUNT=4  # Number of backups to keep

# Cleanup Google Drive Trash
cleanup_google_drive_trash() {
    RCLONE_REMOTE=$1
    LOG_FILE=$2

    echo "Cleaning up Google Drive Trash for remote ${RCLONE_REMOTE}..." >> "$LOG_FILE"
    rclone cleanup "${RCLONE_REMOTE}:" --drive-trashed-only >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo "Google Drive Trash cleaned up successfully for ${RCLONE_REMOTE} at $(date)" >> "$LOG_FILE"
    else
        echo "Failed to clean up Google Drive Trash for ${RCLONE_REMOTE} at $(date)" >> "$LOG_FILE"
    fi
}

# Backup VMs or LXC Containers
backup_and_upload() {
    VM_ID=$1
    RCLONE_REMOTE=$2
    VM_TYPE=$3
    LOG_FILE="${LOG_DIR}/vzdump_${VM_TYPE}_${VM_ID}_$(date +'%Y_%m_%d_%H_%M_%S').log"
    NOTES_FILE="${BACKUP_DIR}/vzdump-${VM_TYPE}-${VM_ID}-$(date +'%Y_%m_%d_%H_%M_%S').tar.zst.notes"

    # Cleanup Google Drive Trash before starting backup
    cleanup_google_drive_trash "$RCLONE_REMOTE" "$LOG_FILE"

    # Start Backup
    echo "Starting backup for ${VM_TYPE} ID ${VM_ID} at $(date)" >> "$LOG_FILE"
    vzdump $VM_ID --storage local --mode snapshot --compress zstd >> "$LOG_FILE" 2>&1

    # Check if the backup was successful
    if [ $? -eq 0 ]; then
        echo "Backup completed successfully for ${VM_TYPE} ID ${VM_ID} at $(date)" >> "$LOG_FILE"
        BACKUP_FILE=$(ls -t ${BACKUP_DIR}/vzdump-${VM_TYPE}-${VM_ID}-*.tar.zst | head -1)

        # Create a .notes file with backup details
        echo "Backup ID: $VM_ID" > "$NOTES_FILE"
        echo "Backup Date: $(date)" >> "$NOTES_FILE"
        echo "Backup Log: $LOG_FILE" >> "$NOTES_FILE"
        echo "Compression: zstd" >> "$NOTES_FILE"

        # Upload to Google Drive via Rclone
        echo "Uploading backup for ${VM_TYPE} ID ${VM_ID} to Google Drive remote ${RCLONE_REMOTE}..." >> "$LOG_FILE"
        rclone copy "$BACKUP_FILE" "$RCLONE_REMOTE:/" >> "$LOG_FILE" 2>&1

        if [ $? -eq 0 ]; then
            echo "Upload completed successfully for ${VM_TYPE} ID ${VM_ID} at $(date)" >> "$LOG_FILE"

            # Delete old backups locally, keeping only the last $KEEP_COUNT backups
            BACKUPS_LOCAL=$(ls -t ${BACKUP_DIR}/vzdump-${VM_TYPE}-${VM_ID}-*.tar.zst | tail -n +$(($KEEP_COUNT + 1)))
            for BACKUP in $BACKUPS_LOCAL; do
                rm -f "$BACKUP"
                echo "Deleted old local backup: $BACKUP" >> "$LOG_FILE"
            done

            # Delete old backups from Google Drive, keeping only the last $KEEP_COUNT backups
            BACKUPS_DRIVE=$(rclone ls "$RCLONE_REMOTE:/" | grep "vzdump-${VM_TYPE}-${VM_ID}-" | sort -r | tail -n +$(($KEEP_COUNT + 1)) | awk '{print $2}')
            for BACKUP in $BACKUPS_DRIVE; do
                rclone delete "$RCLONE_REMOTE:/$BACKUP"
                echo "Deleted old Google Drive backup: $BACKUP" >> "$LOG_FILE"
            done
        else
            echo "Upload failed for ${VM_TYPE} ID ${VM_ID} at $(date)" >> "$LOG_FILE"
        fi
    else
        echo "Backup failed for ${VM_TYPE} ID ${VM_ID} at $(date)" >> "$LOG_FILE"
    fi
}

# VM IDs and corresponding Rclone remotes
declare -A VM_RCLONE_MAP=(
    [100]="citplvmbackup1"
    [101]="citplvmbackup2"
    [102]="citplvmbackup3"
)

# Iterate over each VM in the map
for VM_ID in "${!VM_RCLONE_MAP[@]}"; do
    RCLONE_REMOTE="${VM_RCLONE_MAP[$VM_ID]}"

    # Determine if it's a VM or LXC Container
    VM_TYPE="qemu"
    if pct status $VM_ID &>/dev/null; then
        VM_TYPE="lxc"
    fi

    # Perform backup and upload
    backup_and_upload $VM_ID $RCLONE_REMOTE $VM_TYPE
done

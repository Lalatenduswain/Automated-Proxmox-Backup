# Automated Proxmox VM / LXC Container Backup and Google Drive Upload Script

This repository contains a bash script to automate the backup of VMs and LXC containers on Proxmox VE7 / VE8. The script performs weekly backups, uploads them to separate Google Drive accounts using Rclone, and manages old backups by automatically deleting them after a specified period.

## Repository Information

- **GitHub Username:** [Lalatendu Swain](https://github.com/Lalatenduswain)
- **Repository URL:** [https://github.com/Lalatenduswain/Automated-Proxmox-Backup](https://github.com/Lalatenduswain/Automated-Proxmox-Backup)
- **Script Name:** `Automated-Proxmox-Backup.sh`

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation and Configuration](#installation-and-configuration)
- [Usage](#usage)
- [Scheduling Backups](#scheduling-backups)
- [Disclaimer | Running the Script](#disclaimer--running-the-script)
- [Donations](#donations)
- [Support or Contact](#support-or-contact)

## Prerequisites

Before running this script, ensure you have the following installed and configured on your Proxmox VE 7 server:

1. **Proxmox VE 7**: Ensure that your system is running Proxmox VE 7.
2. **Rclone**: Install Rclone to manage Google Drive connections.
   - Installation:
     ```bash
     sudo apt update
     sudo apt install rclone
     ```
   - Configure Rclone for each of your Google Drive accounts. Example:
     ```bash
     rclone config
     ```
     - Follow the prompts to configure each Google Drive remote (e.g., `citplvmbackup1`, `citplvmbackup2`, `citplvmbackup3`).

3. **Bash Shell**: The script is written in bash, so ensure you have a bash shell available.

4. **Proxmox Permissions**: You need root or equivalent sudo permissions to run the backup command (`vzdump`) and manage system files.
   - Ensure you can run the script with root privileges:
     ```bash
     sudo bash Automated-Proxmox-Backup.sh
     ```

## Installation and Configuration

1. **Clone the Repository**: Begin by cloning the repository to your Proxmox server.
   ```bash
   git clone https://github.com/Lalatenduswain/Automated-Proxmox-Backup.git
   cd Automated-Proxmox-Backup
   ```

2. **Script Configuration**: The script is pre-configured to work with specific VMs or LXC containers. You can modify the `VM_RCLONE_MAP` section to adjust the VM IDs and corresponding Rclone remotes if needed.

3. **Set Execute Permissions**: Ensure the script has execute permissions.
   ```bash
   chmod +x Automated-Proxmox-Backup.sh
   ```

## Usage

### Running the Script Manually

To run the backup and upload script manually, execute the following command:
```bash
sudo ./Automated-Proxmox-Backup.sh
```

The script will:
- Backup the specified VMs and LXC containers.
- Compress the backup files using `zstd`.
- Upload the backup files to the corresponding Google Drive accounts via Rclone.
- Automatically delete old backup files based on the retention period (default: 7 days).

### Script Details

The script iterates through the VM IDs and performs the following actions:

1. **Backup**: It uses the `vzdump` command to create a backup with Zstd compression.
2. **Upload**: The backup file is uploaded to the appropriate Google Drive account using Rclone.
3. **Cleanup**: Old backups are deleted from the local directory based on the retention period.

## Scheduling Backups

To automate the backup process, you can schedule the script using `cron`.

1. **Edit Crontab**: Open the crontab file.
   ```bash
   crontab -e
   ```
2. **Add Cron Job**: Add the following line to schedule the script to run every Sunday at 2 AM:
   ```bash
   0 2 * * 0 /path/to/Automated-Proxmox-Backup.sh
   ```
   Replace `/path/to/Automated-Proxmox-Backup.sh` with the actual path to the script.

## Disclaimer | Running the Script

**Author:** Lalatendu Swain | [GitHub](https://github.com/Lalatenduswain) | [Website](https://blog.lalatendu.info/)

This script is provided as-is and may require modifications or updates based on your specific environment and requirements. Use it at your own risk. The authors of the script are not liable for any damages or issues caused by its usage.

## Donations

If you find this script useful and want to show your appreciation, you can donate via [Buy Me a Coffee](https://www.buymeacoffee.com/lalatendu.swain).

## Support or Contact

Encountering issues? Don't hesitate to submit an issue on our [GitHub page](https://github.com/Lalatenduswain/Automated-Proxmox-Backup/issues).

# Bash Backup Automation Script

A shell script that automates file and directory backups, deletions, and secure 
cloud transfers. It can be run manually or via a scheduler like cron.

---

## What It Does

- **Backup** — copies files or directories to a structured destination with timestamps
- **Delete** — interactively lists and removes files from the backup location
- **Secure Copy** — transfers backups to a remote cloud server via SCP

---

## Usage

### Scheduled (e.g. via cron)
```bash
./backup.sh scheduled <selection> <file_source> <backup_dst> <runner> <backup_type> <log_dir> <log_file>
```

### Manual (interactive)
```bash
./backup.sh notscheduled
```
Then follow the prompts to select an option and enter the required inputs.

---

## Selection Options

| Option | Description |
|---|---|
| 1 | File or directory backup |
| 2 | File or directory delete |
| 3 | Secure backup to a cloud server |

---

## Built With

- Bash / Shell scripting
- SSH & SCP for remote transfers
- Cron-compatible for scheduled runs

---

## Logs

All backup activity is written to a log file specified at runtime,
tracking each step including directory creation, file copy, and exit statuses.
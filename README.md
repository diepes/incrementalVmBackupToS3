# incrementalVmBackupToS3

 * Bash script, that makes daily tar backups to s3
 * full backup on first of month and then incremental, only files that changed.


 * Uses aws cli tools, tar.
 * The backup, avoids making a local backup file, it streams the tar backup directly to s3.

## How to setup
 * Linux server, create dir to place script / checkout git repo e.g. /root/backupscript
 * Update cron to run the shell script every day # crontab -e
 * Create a aws s3 backup user, and place the credentials in /root/.aws/credentials, to be used by the aws cli tool.
 * Install the aws cli tool
 * copy backupS3.config.Sample to backupS3.config  and update with bucket name, and any other information
 * copy tarexclude.txt.Sample to tarexclude.txt and update with dir's not to be included in backup.

### When ran
 * Script will create, local files
   * tarIncrementalFullFileName.txt << Saved last full backup name
   * tarIncrementalLevelCounter.txt << Counter for day of month for Incremental backups.
   * history-backup.txt
 * S3 bucket, will get files with prefix  /backupsFull/ , and next day /backupsInc/



## Why use tar and s3 bucket + aws cli ? 
 * This approach has numerous advantages as a backup strategy.
   1. By using tar and compression, standard tools can open the backup and extract single files.
   2. The .aws/credentials used on the server can be setup to only have IAM upload capability to s3 bucket
      * Limiting harm that can be done if server and credentials compromised, previous backups can not be harmed.
   3. AWS S3 offers simple retention policies and cheap options by moving backups to Glacier for longterm archive.
   4. Reduced temporary diskspace for backups, as the backup is streamed to s3, not creating a local copy in the process.
   5. Tar offers incremental changed file backup, allowing for monthly full backup, and then daily incremental files that changed.


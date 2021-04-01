# incrementalVmBackupToS3

 * Bash script, that makes daily backups to s3
 * full backup on first of month and then incremental, only files that changed.


 * Uses aws cli tools, tar.
 * The backup, avoids making a local backup file, it streams the tar backup directly to s3.

 By using tar the backup can be downloaded from s3, opened and any file extracted, without needing any other external tools.


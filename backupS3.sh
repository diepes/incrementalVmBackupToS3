#!/bin/bash
#(c) 2017 P.E.Smit GPL 3a
# 2018-10-22 backup meta info to */info/* subfolder namespace
# 2018-10-20 add -a to tee log output
# 2017-08-19 all echo to >> $histfile 
# 2017-07-09 fix logic so if tarIncrementalLevelCounter.txt removed a full backup will be made.
# 2017-07-09 PES provide tar dirs as relative  and use -C / to start from root
# 2017-07-09 PES move from s3cmd to aws-cli s3
# 2017-01-23 PES no backblaze backup disk full. add .inc. to incremental name.
# 2016-08-24 PES re-use full.snar tar "tarIncrementalInfo" for each incremental
# 2016-05-02 PES backup script to s3(AWS) once a month.   (And b2 backblaze)
# http://paulwhippconsulting.com/blog/using-tar-for-full-and-incremental-backups/
#

set -e ; source ./backupS3.config
#
d="`date +%F-%Hh%M`"
day="`date +%d`"  ##Always full backup when day=1
trap times EXIT
# Read level $l from file and update file, max 7 incremental
# Note: To force full backup set val in tarIncrementalLevelCounter.txt > 32
l="$(( `cat tarIncrementalLevelCounter.txt 2>/dev/null || echo "-1"`   + 1 ))"  #Level default to 0 Counter file missing
#echo "l=$l"
if [ "$l" -gt  "31" ]; then l=0; fi #Max 31 incremental backups
if [ "$day" -eq "1" ]; then l=0; fi #Begining of month level=0 full backup
echo "$l" > tarIncrementalLevelCounter.txt
if [ "$l" -gt "0" ]; 
then 
    level=1; #Only level=1 incremental files.
    #Retrieve full name backupVigor-2016-08-24-09h47
    fullName="`cat $configdir/tarIncrementalFullFileName.txt`" ##Read name of last full backup
    f="$fullName-to-$d-level${level}_${l}.inc.tar.xz"
    #Always use last full full.snar as incremental guide.
    rm "$tarIncrementalInfo.inc.snar"
    cp "$tarIncrementalInfo.full.snar"  "$tarIncrementalInfo.inc.snar"
    tarIncrementalInfo="$tarIncrementalInfo.inc.snar"
    echo "" >> $histfile
else 
    level=0;  #Full backup
    fullName="${basefilename}-$d" ##Create new baseName+date
    f="${fullName}-FULL.tar.xz"   ##New full archive file name
    echo "${fullName}" > $configdir/tarIncrementalFullFileName.txt
    echo "" > $tarIncrementalInfo ## Start fresh no incremental history
    #remove incremental files
    rm "$tarIncrementalInfo.inc.snar"
    rm "$tarIncrementalInfo.full.snar"
    tarIncrementalInfo="$tarIncrementalInfo.full.snar"
    #backup backup script.
    #s3cmd put backupS3.sh s3://${s3bucket}/backupS3.sh.${d}.sh
    #s3cmd put $configdir/tarexclude.txt s3://${s3bucket}/tarexclude.txt.${d}.txt
    aws s3 cp $configdir/backupS3.sh    s3://${s3bucket}/info/${fullName}-backupS3.sh
    aws s3 cp $configdir/tarexclude.txt s3://${s3bucket}/info/${fullName}-tarexclude.txt

fi  #Max level1
echo "starting backup to s3, Incremental=$l, level=$level, to $f  ..." >> $histfile
## --files-from=$tarinclude
## --level=$l --listed-incremental=$tarIncrementalInfo 
cd /
nice -n18 tar --create -f -                  \
    --sparse --recursion                     \
    --exclude-from "${tarexclude}"           \
    --level=$l                               \
    --listed-incremental=$tarIncrementalInfo \
    -C /  ${tardirectories}                  |
nice -n19 xz --compress -6 --memlimit=200MiB  --check=crc64 - |
pv -t -r -b                                  |
aws s3 cp --expected-size $((1024*1024*1024*30)) - s3://${s3bucket}/$f

## --expected-size Max size, critical if bigger thann 5G
## max_concurrent_requests=1 default 10, set in .aws/config
if [ $? -eq 0 ]
  then
    err=1 
  else
    echo "Error exit code $?  from aws s3  ? " | tee -a $histfile
    err=0
fi
cd $configdir
echo "Backup done, Incremental=$l , level=$level , to $f ..." >> $histfile
echo "$d , s3://${s3bucket}/$f , `ls -lh $tarIncrementalInfo`" >> $histfile ##Add small log
#ls -lh $f*
ls -lh $tarIncrementalInfo
##Notes
# No /var/lib/mongodb  ?? journal only ?
# cat - > /root/backupscript/tar-test.tar.xz
# cat - > /root/backupscript/${basefilename}-$d-level$l.tar.xz 

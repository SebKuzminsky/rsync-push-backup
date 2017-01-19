#!/bin/bash
set -e
set -x

rm -rf backups
rm -f .backup/test/lock
../../bin/backup -c .backup

# verify that the correct backup dirs & symlinks were created
[ -d backups/test/hourly.0 ]
[ -L backups/test/daily.0 ]  && [ $(readlink backups/test/daily.0) == hourly.10 ]
[ -L backups/test/weekly.0 ] && [ $(readlink backups/test/weekly.0) == daily.5 ]
[ -L backups/test/monthly.0 ] && [ $(readlink backups/test/monthly.0 ) == weekly.2 ]

# verify that the backup happened
diff --recursive --brief dir-to-backup backups/test/hourly.0/dir-to-backup

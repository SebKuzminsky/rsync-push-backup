#!/bin/bash
set -e
#set -x

F=dir-to-backup/versioned-file
VERSION_NUMBER=0


function update_version {
    echo "version ${VERSION_NUMBER}" >| ${F}
    VERSION_NUMBER=$((VERSION_NUMBER+1))
}


function verify_contents {
    SNAPSHOT="$1"
    EXPECTED="$2"
    RESULT=$(cat backups/test/${SNAPSHOT}/${F})
    if [ "${EXPECTED}" != "${RESULT}" ]; then
        echo "error in snapshot ${SNAPSHOT}"
        echo "expected '${EXPECTED}'"
        echo "got '${RESULT}'"
        exit 1
    fi
}


rm -rf backups
rm -f .backup/test/lock

# make the first version of the file to back up
update_version

# make the first snapshot
../../bin/backup -c .backup

# verify that the correct backup dirs & symlinks were created
[ -d backups/test/hourly.0 ]
[ -L backups/test/daily.0 ]  && [ $(readlink backups/test/daily.0) == hourly.2 ]
[ -L backups/test/weekly.0 ] && [ $(readlink backups/test/weekly.0) == daily.3 ]
[ -L backups/test/monthly.0 ] && [ $(readlink backups/test/monthly.0 ) == weekly.4 ]

# verify that the backup happened
diff --recursive --brief dir-to-backup backups/test/hourly.0/dir-to-backup


# make new backups while changing the versioned file
for ((MONTH=0; ${MONTH} < 5; MONTH++)); do
    for ((WEEK=0; ${WEEK} < 4; WEEK++)); do
        for ((DAY=0; ${DAY} < 3; DAY++)); do
            for ((HOUR=0; ${HOUR} < 2; HOUR++)); do
                echo
                echo "***"
                printf "H%d D%d W%d M%d\n" $HOUR $DAY $WEEK $MONTH
                echo "***"
                update_version
                ../../bin/backup -c .backup
            done
            touch --no-dereference --date='25 hours ago' backups/test/daily.0
        done
        touch --no-dereference --date='8 days ago' backups/test/weekly.0
    done
    touch --no-dereference --date='32 days ago' backups/test/monthly.0
done

# and one final backup to make the last monthly snapshot
update_version
../../bin/backup -c .backup

# These are maybe not the ideal contents, but it's what we currently have.
verify_contents hourly.0 'version 121'
verify_contents hourly.1 'version 121'
verify_contents hourly.2 'version 120'

verify_contents daily.0 'version 120'
verify_contents daily.1 'version 120'
verify_contents daily.2 'version 118'
verify_contents daily.3 'version 116'

verify_contents weekly.0 'version 116'
verify_contents weekly.1 'version 116'
verify_contents weekly.2 'version 110'
verify_contents weekly.3 'version 104'
verify_contents weekly.4 'version 98'

verify_contents monthly.0 'version 98'
verify_contents monthly.1 'version 98'
verify_contents monthly.2 'version 74'
verify_contents monthly.3 'version 50'
verify_contents monthly.4 'version 26'
verify_contents monthly.5 'version 2'

(cd backups/test; /bin/ls -1) > actual-snapshots
diff -u expected-snapshots actual-snapshots
for S in $(cat expected-snapshots); do
    echo "verifying contents of snapshot $S"
    (cd backups/test/$S/dir-to-backup; /bin/ls -1) >| actual-files
    diff -u expected-files actual-files
done

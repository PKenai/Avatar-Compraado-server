#!/bin/bash

# Config
databasename="avatar"
databasepassword="41qtXY752Z0L"

# Allow core dumps
ulimit -c unlimited
ulimit -n 65000

# Main loop
while true;
do
    date=`date "+%d-%m-%y-%H-%M-%S"`
    filename="${databasename}-${date}"
    databasefile="${filename}.sql"
    logfile="console-${date}.log"

    echo "Waiting 5 seconds... If you want to close your server, do it now. (Ctrl+C)"
    sleep 5

    echo "Taking database backup..."
    mysqldump -uroot -p$databasepassword --add-drop-table --add-locks --allow-keywords --extended-insert --quick --compress $databasename > databases/$databasefile
    gzip databases/$databasefile

    echo "Opening server by python code with gdb"
    gdb -x openserver.py
done;

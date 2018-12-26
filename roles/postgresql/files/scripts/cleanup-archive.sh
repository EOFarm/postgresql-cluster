#!/bin/bash

this_script=$(realpath $0)
env_file="$(dirname ${this_script})/cluster-environment"

. ${env_file}

archive_dir=${ARCHIVE_DIR}

if [[ ! -d "${archive_dir}" ]]; then
   echo "The archive directory is not a directory (is ARCHIVE_DIR set?)!"
   exit 1
fi

accessed_before_days=$1

help="Usage: ${0} <accessed-before-days>"

if [[ "${accessed_before_days}" -lt "1" ]]; then
    echo "Error: The access time must be >= 1 (days)"
    echo ${help}
    exit 1;
fi

# Find old archive files: not being accessed for more than given interval (in days)
old_archive_files=$(find ${archive_dir} -type f -atime +"${accessed_before_days}") 
test -z "${old_archive_files}" && exit 0

oldest_kept_archive_file=$(stat -c '%X %n' ${old_archive_files} | sort -n -r | head -n 1 | basename $(awk '{print $2}'))

# Fixme (-n is a dry run!)
sudo -u postgres pg_archivecleanup -n ${archive_dir} ${oldest_kept_archive_file}


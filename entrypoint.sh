#!/bin/bash

echo "Starting Anki - setting secrets"
for user_file in $(env | grep -E 'SYNC_USER[0-9]+_FILE')
do
  echo "Reading secret [$user_file]"
  user="$(basename "${user_file%_FILE}")"
  user="${user%=*}"
  file=${user_file#*=}
  echo "Setting [$user] to the contents of [$file]"
  if [[ -n "$(env | grep "^$user=")" ]]
  then
    echo "both $user and $user_file are set - choose only one"
    exit 1
  fi

  export ${user}="$(cat $file)"
  unset ${user}_FILE
done

echo

exec $@

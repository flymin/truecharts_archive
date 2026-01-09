#!/bin/bash
# create backup folder
folder="/mnt/<YOUR-POOL>/migration/backup_pg"
mkdir -p "$folder"

# get namespaces with postgres database pod
namespaces=$(k3s kubectl get pods -A | grep postgres | awk '{print $1}')

for ns in $namespaces; do
  # extract application name
  app=$(echo "$ns" | sed 's/^ix-//')

  echo "Creating database backup for $app."

  file="$app.sql"

  # Scale down deployment to avoid inconsistencies in DB
  k3s kubectl scale deploy "$app" -n "$ns" --replicas=0
  while true; do k3s kubectl get pods -n "$ns" | grep -i -q terminating || break; done;

  k3s kubectl exec -n "$ns" -c "$app"-postgresql "$app"-postgresql-0 -- bash -c 'PGPASSWORD=$POSTGRES_PASSWORD pg_dump -Fc -U $POSTGRES_USER -d $POSTGRES_DB -f /tmp/'$file
  k3s kubectl cp -n "$ns" -c "$app"-postgresql "$app-postgresql-0:tmp/$file" $folder$file

  # Scale deployment back up
  k3s kubectl scale deploy "$app" -n "$ns" --replicas=1

  if [ ! -f "$folder$file" ]; then
    >&2 echo "$folder$file does not exist."
    exit 1
  fi

  echo "File $file created."

done

exit 0

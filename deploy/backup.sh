#!/bin/sh
# Run from deploy/ during a maintenance window; requires Docker Compose.
set -eu
umask 077
: "${BACKUP_DIR:?Choose a private absolute backup directory}"
case "$BACKUP_DIR" in /*) ;; *) echo 'BACKUP_DIR must be absolute' >&2; exit 1 ;; esac
mkdir -p "$BACKUP_DIR"
name="homeharbor-$(date -u +%Y%m%dT%H%M%SZ)"
# Keep the database and photo archive consistent by pausing writes.
docker compose stop web notifications
trap 'docker compose start web notifications' EXIT HUP INT TERM
docker compose exec -T db pg_dump -U homeharbor -d homeharbor_production -Fc --no-owner --no-acl > "$BACKUP_DIR/$name.dump"
docker compose run --rm --no-deps --user root --entrypoint tar web -C /rails/storage -czf - . > "$BACKUP_DIR/$name-storage.tar.gz"
sha256sum "$BACKUP_DIR/$name.dump" "$BACKUP_DIR/$name-storage.tar.gz" > "$BACKUP_DIR/$name.sha256"
echo "Backup completed: $name. Copy the encrypted backup off this server."

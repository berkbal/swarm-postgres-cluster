#!/bin/bash
set -e

# Master hazir olana kadar bekle
until pg_isready -h postgres-master -p 5432; do
  echo "Waiting for master..."
  sleep 10
done

# pg_basebackup ile master'dan klon almadan once dizini temizlemek gerekiyor
rm -rf /var/lib/postgresql/data/*

# Master'dan db2 slotunu kullanarak backup olusturuluyor.
PGPASSWORD=123 pg_basebackup \
  -h postgres-master \
  -D /var/lib/postgresql/data \
  -U replication \
  -v -P -R -S db2

# Dosya izinleri
chown -R postgres:postgres /var/lib/postgresql/data

# postgres'i postgres kullanicisi ile baslat
exec /usr/local/bin/docker-entrypoint.sh postgres

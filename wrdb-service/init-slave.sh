#!/bin/bash
set -e

# 等待主資料庫啟動
until PGPASSWORD=$POSTGRES_PASSWORD psql -h postgres-master -U $POSTGRES_USER -d $POSTGRES_DB -c '\q'; do
  echo "等待主資料庫啟動..."
  sleep 1
done

# 配置從資料庫
cat >> /var/lib/postgresql/data/postgresql.conf <<EOF
hot_standby = on
EOF

# 創建複製配置
cat > /var/lib/postgresql/data/recovery.conf <<EOF
standby_mode = 'on'
primary_conninfo = 'host=postgres-master port=5432 user=replicator password=replicator'
trigger_file = '/tmp/trigger_file'
EOF 
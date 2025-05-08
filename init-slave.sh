#!/bin/bash
set -e

echo "開始從庫初始化流程..."

# 等待主資料庫就緒
until PGPASSWORD="$REPLICATOR_PASSWORD" psql -h "$PRIMARY_HOST" -p "$PRIMARY_PORT" -U replicator -d "$POSTGRES_DB" -c '\q'; do
    echo "等待主資料庫就緒..."
    sleep 5
done

echo "主資料庫已就緒，檢查複製槽狀態..."

# 檢查複製槽是否存在
SLOT_EXISTS=$(PGPASSWORD="$REPLICATOR_PASSWORD" psql -h "$PRIMARY_HOST" -p "$PRIMARY_PORT" -U replicator -d "$POSTGRES_DB" -tAc "SELECT COUNT(*) FROM pg_replication_slots WHERE slot_name = 'replica_slot'")

if [ "$SLOT_EXISTS" -eq "0" ]; then
    echo "錯誤：在主庫上找不到複製槽 'replica_slot'"
    exit 1
fi

echo "複製槽檢查完成，開始配置從庫..."

# 停止 PostgreSQL 服務
pg_ctl -D "$PGDATA" -m fast -w stop || true

# 清空資料目錄
rm -rf "${PGDATA:?}"/*

# 從主資料庫執行基礎備份
echo "開始從主庫執行基礎備份..."
PGPASSWORD="$REPLICATOR_PASSWORD" pg_basebackup \
    -h "$PRIMARY_HOST" \
    -p "$PRIMARY_PORT" \
    -U replicator \
    -D "$PGDATA" \
    -X stream \
    -P \
    -v \
    -R \
    -S replica_slot

if [ $? -ne 0 ]; then
    echo "錯誤：基礎備份失敗"
    exit 1
fi

echo "基礎備份完成，開始配置從庫參數..."

# 配置從資料庫
cat > "$PGDATA/postgresql.conf" <<EOF
# 基本設置
listen_addresses = '*'
max_connections = 100
shared_buffers = 128MB

# 複製設置
hot_standby = on
wal_level = replica
max_wal_senders = 10
hot_standby_feedback = on

# 主庫連接設置
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=replicator password=$REPLICATOR_PASSWORD application_name=slave1 keepalives=1 keepalives_idle=60 keepalives_interval=10 keepalives_count=10 sslmode=prefer'
primary_slot_name = 'replica_slot'
recovery_target_timeline = 'latest'

# 連接設置
tcp_keepalives_idle = 60
tcp_keepalives_interval = 10
tcp_keepalives_count = 10
EOF

# 配置認證
cat > "$PGDATA/pg_hba.conf" <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all            all                                     trust
host    all            all             0.0.0.0/0              md5
EOF

# 創建 standby.signal 文件
touch "$PGDATA/standby.signal"

# 確保正確的權限
chown -R postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"

echo "從庫配置完成，正在啟動服務..."

# 啟動 PostgreSQL 服務
pg_ctl -D "$PGDATA" -w start 
#!/bin/bash
set -e

# 創建複製用戶
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD '$REPLICATOR_PASSWORD';
EOSQL

# 配置主從複製
cat > /var/lib/postgresql/data/postgresql.conf <<EOF
# 基本設置
listen_addresses = '*'
max_connections = 100
shared_buffers = 128MB

# 複製設置
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
wal_keep_size = 1GB
synchronous_commit = on
synchronous_standby_names = 'ANY 1 (slave1)'

# 歸檔設置
archive_mode = on
archive_command = '/bin/true'

# 連接設置
tcp_keepalives_idle = 60
tcp_keepalives_interval = 10
tcp_keepalives_count = 10
EOF

# 配置認證
cat > /var/lib/postgresql/data/pg_hba.conf <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all            all                                     trust
host    all            all             0.0.0.0/0              md5
host    replication    replicator      0.0.0.0/0              md5
host    replication    all             0.0.0.0/0              md5
EOF

# 等待 PostgreSQL 完全啟動
until pg_isready -U postgres; do
    echo "等待 PostgreSQL 就緒..."
    sleep 1
done

echo "PostgreSQL 已就緒，開始創建複製槽..."

# 創建複製槽
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_replication_slots WHERE slot_name = 'replica_slot'
    ) THEN
        PERFORM pg_create_physical_replication_slot('replica_slot', true);
        RAISE NOTICE 'Created replication slot: replica_slot';
    ELSE
        RAISE NOTICE 'Replication slot already exists: replica_slot';
    END IF;
END \$\$;
EOSQL

echo "複製槽創建完成，開始創建資料表..."

# 創建用戶表和觸發器
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
    -- 創建用戶表
    CREATE TABLE IF NOT EXISTS users (
        id BIGSERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- 創建更新時間觸發器
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS \$\$
    BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    \$\$ language 'plpgsql';

    -- 檢查觸發器是否存在
    DO \$\$
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'update_users_updated_at'
        ) THEN
            CREATE TRIGGER update_users_updated_at
            BEFORE UPDATE ON users
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
        END IF;
    END \$\$;
EOSQL 
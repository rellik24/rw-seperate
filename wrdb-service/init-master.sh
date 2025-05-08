#!/bin/bash
set -e

echo "開始主庫初始化流程..."

# 創建複製用戶
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD '$REPLICATOR_PASSWORD';
EOSQL

# 配置主從複製
cat >> /var/lib/postgresql/data/postgresql.conf <<EOF
listen_addresses = '*'
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
wal_keep_size = 1024
synchronous_commit = on
max_connections = 100
shared_buffers = 128MB
tcp_keepalives_idle = 60
tcp_keepalives_interval = 10
tcp_keepalives_count = 10
EOF

# 配置認證
cat >> /var/lib/postgresql/data/pg_hba.conf <<EOF
host    replication     replicator      all                 md5
host    all            all             all                 md5
EOF

# 創建用戶表
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
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

    CREATE TRIGGER IF NOT EXISTS update_users_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();

    -- 檢查並創建複製槽
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'replica_slot') THEN
            PERFORM pg_create_physical_replication_slot('replica_slot');
            RAISE NOTICE 'Created replication slot: replica_slot';
        ELSE
            RAISE NOTICE 'Replication slot already exists: replica_slot';
        END IF;
    END \$\$;
EOSQL

echo "主庫初始化完成！" 
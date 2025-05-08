#!/bin/bash
set -e

# 等待主資料庫就緒
until PGPASSWORD=postgres psql -h postgres-master -U postgres -d demo -c '\q' 2>/dev/null; do
    echo "等待主資料庫就緒..."
    sleep 2
done

echo "主資料庫已就緒，開始創建複製槽..."

# 檢查並創建複製槽
PGPASSWORD=postgres psql -h postgres-master -U postgres -d demo <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'replica_slot') THEN
        PERFORM pg_create_physical_replication_slot('replica_slot');
        RAISE NOTICE 'Created replication slot: replica_slot';
    ELSE
        RAISE NOTICE 'Replication slot already exists: replica_slot';
    END IF;
END \$\$;
EOF

echo "複製槽創建完成" 
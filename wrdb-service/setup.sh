#!/bin/bash

# 確保腳本有執行權限
chmod +x init-master.sh
chmod +x init-slave.sh

# 啟動服務
docker-compose up -d

# 等待服務啟動
echo "等待服務啟動..."
sleep 10

# 檢查服務狀態
echo "檢查服務狀態..."
docker-compose ps

# 測試連接
echo "測試主資料庫連接..."
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d demo -c "SELECT 1"

echo "測試從資料庫連接..."
PGPASSWORD=postgres psql -h localhost -p 5433 -U postgres -d demo -c "SELECT 1"

echo "測試 Pgpool 連接..."
PGPASSWORD=postgres psql -h localhost -p 9999 -U postgres -d demo -c "SELECT 1"

echo "環境設置完成！" 
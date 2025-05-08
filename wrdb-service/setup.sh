#!/bin/bash

# 顯示腳本執行步驟
echo "開始設置 PostgreSQL 主從複製環境..."

# 確保腳本有執行權限
chmod +x init-master.sh
chmod +x init-slave.sh

# 停止並移除現有容器和卷（如果存在）
echo "清理現有環境..."
docker-compose down -v

# 創建必要的目錄
echo "創建配置目錄..."
mkdir -p pgpool

# 啟動服務
echo "啟動 Docker 服務..."
docker-compose up -d

# 等待服務啟動
echo "等待服務啟動..."
sleep 20

# 檢查服務狀態
echo "檢查服務狀態..."
docker-compose ps

# 測試連接
echo "測試資料庫連接..."

# 測試 Pgpool 連接
echo "測試 Pgpool 連接..."
max_retries=5
retry_count=0
while [ $retry_count -lt $max_retries ]; do
    if PGPASSWORD=postgres psql -h localhost -p 9999 -U postgres -d demo -c "SELECT version();" > /dev/null 2>&1; then
        echo "Pgpool 連接成功！"
        break
    else
        echo "等待 Pgpool 就緒... (${retry_count}/${max_retries})"
        retry_count=$((retry_count + 1))
        sleep 5
    fi
done

if [ $retry_count -eq $max_retries ]; then
    echo "錯誤：無法連接到 Pgpool"
    exit 1
fi

# 檢查主從複製狀態
echo "檢查主從複製狀態..."
PGPASSWORD=postgres psql -h localhost -p 9999 -U postgres -d demo -c "show pool_nodes;"

echo "環境設置完成！"
echo "
連接資訊：
- Pgpool 連接埠：9999
- 使用者名稱：postgres
- 密碼：postgres
- 資料庫名稱：demo

您可以使用以下指令連接到資料庫：
PGPASSWORD=postgres psql -h localhost -p 9999 -U postgres -d demo

Spring Boot 配置已更新為使用 Pgpool。
" 
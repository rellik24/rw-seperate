# 讀寫分離環境設置說明

## 環境需求
- Docker
- Docker Compose
- PostgreSQL 客戶端工具（psql）

## 目錄結構
```
wrdb-service/
├── docker-compose.yml    # Docker 服務配置
├── init-master.sh       # 主資料庫初始化腳本
├── init-slave.sh        # 從資料庫初始化腳本
├── setup.sh            # 環境設置腳本
└── README.md           # 說明文件
```

## Docker Compose 使用說明

### 1. 基本操作
```bash
# 啟動所有服務
docker-compose up -d

# 查看服務狀態
docker-compose ps

# 查看服務日誌
docker-compose logs

# 查看特定服務的日誌
docker-compose logs postgres-master
docker-compose logs postgres-slave
docker-compose logs pgpool

# 停止所有服務
docker-compose down

# 停止服務並刪除數據卷
docker-compose down -v
```

### 2. 服務管理
```bash
# 重啟特定服務
docker-compose restart postgres-master
docker-compose restart postgres-slave
docker-compose restart pgpool

# 重新構建並啟動服務
docker-compose up -d --build

# 查看服務資源使用情況
docker-compose top
```

### 3. 進入容器
```bash
# 進入主資料庫容器
docker-compose exec postgres-master bash

# 進入從資料庫容器
docker-compose exec postgres-slave bash

# 進入 Pgpool 容器
docker-compose exec pgpool bash
```

### 4. 數據庫操作
```bash
# 在主資料庫執行 SQL
docker-compose exec postgres-master psql -U postgres -d demo

# 在從資料庫執行 SQL
docker-compose exec postgres-slave psql -U postgres -d demo

# 通過 Pgpool 執行 SQL
docker-compose exec pgpool psql -U postgres -d demo
```

### 5. 故障排除
```bash
# 檢查容器網絡
docker-compose network ls
docker-compose network inspect postgres-network

# 檢查容器配置
docker-compose config

# 檢查容器日誌
docker-compose logs -f

# 重啟所有服務
docker-compose restart
```

### 6. 環境變數
可以在 `.env` 文件中設置環境變數：
```bash
# 創建 .env 文件
cat > .env <<EOF
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=demo
PGPOOL_USERNAME=postgres
PGPOOL_PASSWORD=postgres
EOF
```

### 7. 數據持久化
- 主資料庫數據存儲在 `postgres-master-data` 卷中
- 從資料庫數據存儲在 `postgres-slave-data` 卷中
- 可以通過以下命令管理數據卷：
```bash
# 查看所有數據卷
docker volume ls

# 刪除特定數據卷
docker volume rm postgres-master-data
docker volume rm postgres-slave-data

# 備份數據卷
docker run --rm -v postgres-master-data:/source -v $(pwd):/backup alpine tar -czf /backup/master-data.tar.gz -C /source .
```

### 8. 網絡配置
- 所有服務都在 `postgres-network` 網絡中
- 服務間可以通過服務名稱互相訪問
- 可以通過以下命令查看網絡配置：
```bash
# 查看網絡列表
docker network ls

# 查看網絡詳情
docker network inspect postgres-network
```

## 快速開始

### 1. 啟動環境
```bash
./setup.sh
```

### 2. 驗證環境
```bash
# 檢查主從複製狀態
psql -h localhost -p 5432 -U postgres -d demo -c "SELECT * FROM pg_stat_replication;"

# 檢查 Pgpool 狀態
psql -h localhost -p 9999 -U postgres -d demo -c "show pool_nodes;"
```

### 3. 測試讀寫分離
```bash
# 寫入測試（會路由到主庫）
psql -h localhost -p 9999 -U postgres -d demo -c "INSERT INTO users (name, email, password) VALUES ('測試用戶', 'test@example.com', 'password');"

# 讀取測試（會路由到從庫）
psql -h localhost -p 9999 -U postgres -d demo -c "SELECT * FROM users;"
```

## Spring Boot 配置

在 `application.properties` 中配置：

```properties
# 主資料庫配置
spring.datasource.master.url=jdbc:postgresql://localhost:5432/demo
spring.datasource.master.username=postgres
spring.datasource.master.password=postgres
spring.datasource.master.driver-class-name=org.postgresql.Driver

# 從資料庫配置
spring.datasource.slave.url=jdbc:postgresql://localhost:5433/demo
spring.datasource.slave.username=postgres
spring.datasource.slave.password=postgres
spring.datasource.slave.driver-class-name=org.postgresql.Driver
```

## 故障排除

### 1. 主從複製問題
```bash
# 檢查主庫日誌
docker logs postgres-master

# 檢查從庫日誌
docker logs postgres-slave
```

### 2. Pgpool 問題
```bash
# 檢查 Pgpool 日誌
docker logs pgpool

# 檢查 Pgpool 狀態
psql -h localhost -p 9999 -U postgres -d demo -c "show pool_status;"
```

### 3. 常見問題解決
1. 如果主從複製中斷：
   ```bash
   # 在從庫上重新同步
   docker exec -it postgres-slave bash
   pg_ctl promote
   ```

2. 如果 Pgpool 連接失敗：
   ```bash
   # 重啟 Pgpool
   docker-compose restart pgpool
   ```

## 清理環境
```bash
# 停止並移除所有容器
docker-compose down

# 移除所有數據卷
docker-compose down -v
```

## 注意事項
1. 確保端口 5432、5433、9999 未被佔用
2. 主從複製可能需要一些時間同步
3. 首次啟動時，從庫會自動從主庫同步數據
4. 建議在生產環境中修改預設密碼

# PostgreSQL 讀寫分離環境

## 快速啟動
```bash
# 啟動所有服務
./setup.sh
```

## 展示指令

### 1. 資料庫操作指令

#### 查看主資料庫數據
```bash
docker exec -it postgres-master psql -U postgres -d demo -c "SELECT * FROM users;"
```

#### 查看從資料庫數據
```bash
docker exec -it postgres-slave psql -U postgres -d demo -c "SELECT * FROM users;"
```

#### 在主資料庫插入測試數據
```bash
docker exec -it postgres-master psql -U postgres -d demo -c "INSERT INTO users (name, email, password) VALUES ('測試用戶1', 'test1@example.com', 'password1');"
```

#### 檢查主從複製狀態
```bash
docker exec -it postgres-master psql -U postgres -d demo -c "SELECT * FROM pg_stat_replication;"
```

### 2. REST API 測試指令

#### 創建用戶
```bash
# 使用 curl
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "測試用戶", "email": "test@example.com", "password": "password123"}'

# 使用 httpie（更易讀）
http POST :8080/api/users name="測試用戶" email="test@example.com" password="password123"
```

#### 查詢用戶
```bash
# 通過 ID 查詢
curl http://localhost:8080/api/users/1

# 通過 Email 查詢
curl http://localhost:8080/api/users/email/test@example.com
```

### 3. 連接資訊

#### 主資料庫
- Host: localhost
- Port: 5432
- Database: demo
- Username: postgres
- Password: postgres

#### 從資料庫
- Host: localhost
- Port: 5433
- Database: demo
- Username: postgres
- Password: postgres

#### Pgpool 連接（推薦）
- Host: localhost
- Port: 9999
- Database: demo
- Username: postgres
- Password: postgres

## 驗證讀寫分離

1. 插入數據到主庫：
```bash
docker exec -it postgres-master psql -U postgres -d demo -c "INSERT INTO users (name, email, password) VALUES ('展示用戶', 'demo@example.com', 'password');"
```

2. 立即在主庫查看：
```bash
docker exec -it postgres-master psql -U postgres -d demo -c "SELECT * FROM users WHERE email='demo@example.com';"
```

3. 在從庫查看（驗證複製）：
```bash
docker exec -it postgres-slave psql -U postgres -d demo -c "SELECT * FROM users WHERE email='demo@example.com';"
```

## 常用操作指令

### 環境管理
```bash
# 停止所有服務
docker-compose down

# 停止並清除所有數據
docker-compose down -v

# 查看服務狀態
docker-compose ps

# 查看服務日誌
docker-compose logs -f
```

### 數據庫管理
```bash
# 連接到主庫 psql
docker exec -it postgres-master psql -U postgres -d demo

# 連接到從庫 psql
docker exec -it postgres-slave psql -U postgres -d demo

# 查看表結構
\d users

# 退出 psql
\q
```

# PostgreSQL 主從複製示範

本專案設置了一個基於 Docker 的 PostgreSQL 主從複製架構，包含以下組件：

- 主資料庫 (Master)
- 從資料庫 (Slave/Replica)
- PgPool-II 連接池和負載平衡器

## 快速啟動

### 1. 啟動服務

```bash
# 如果之前啟動過，先停止並移除舊容器
docker-compose down

# 啟動所有服務
docker-compose up -d
```

### 2. 驗證主從狀態

執行測試腳本驗證主從複製狀態：

```bash
./test-replication-docker.sh
```

### 3. 主要操作示範

#### 查看複製槽狀態

```bash
docker exec postgres-master psql -U postgres -d demo -c "SELECT slot_name, slot_type, active FROM pg_replication_slots;"
```

#### 檢查複製連接

```bash
docker exec postgres-master psql -U postgres -d demo -c "SELECT pid, application_name, client_addr, state, sync_state FROM pg_stat_replication;"
```

#### 確認從庫恢復模式

```bash
docker exec postgres-slave psql -U postgres -d demo -c "SELECT pg_is_in_recovery();"
```

#### 寫入測試

在主庫寫入資料：

```bash
docker exec postgres-master psql -U postgres -d demo -c "INSERT INTO users (name, email, password) VALUES ('會議演示', 'demo@example.com', 'password123') RETURNING id;"
```

在從庫查詢資料 (確認同步)：

```bash
docker exec postgres-slave psql -U postgres -d demo -c "SELECT * FROM users WHERE email='demo@example.com';"
```

#### 通過連接池訪問

```bash
docker exec pgpool psql -h localhost -p 5432 -U postgres -d demo -c "SELECT * FROM users;"
```

## 架構說明

### 主庫 (Master)

- 接受讀寫操作
- 維護複製槽 (replica_slot)
- 將 WAL 日誌傳送至從庫

### 從庫 (Slave)

- 唯讀操作
- 透過複製槽接收 WAL 日誌
- 自動從主庫同步資料

### 連接池 (PgPool)

- 負載平衡
- 讀寫分離 (寫操作導向主庫，讀操作可分配到從庫)
- 高可用性管理

## 重要檔案

- `init-master.sh`: 主庫初始化腳本
- `init-slave.sh`: 從庫初始化腳本
- `test-replication-docker.sh`: 測試主從複製狀態的腳本
- `docker-compose.yml`: 容器配置檔案
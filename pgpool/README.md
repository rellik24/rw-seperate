# Pgpool-II 配置說明

## 簡介
Pgpool-II 是一個 PostgreSQL 的中間件，提供以下主要功能：
1. 連接池
2. 負載平衡
3. 自動故障轉移
4. 並行查詢
5. 在線恢復

## 安裝步驟

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install pgpool2
```

### CentOS/RHEL
```bash
sudo yum install pgpool-II
```

## 配置說明

### 主要配置文件 (pgpool.conf)
- `listen_addresses`: 監聽的 IP 地址
- `port`: Pgpool-II 的監聽端口
- `backend_hostname0/1`: 主從資料庫的主機名
- `backend_port0/1`: 主從資料庫的端口
- `load_balance_mode`: 是否啟用負載平衡
- `master_slave_mode`: 是否啟用主從模式
- `health_check_period`: 健康檢查間隔（秒）

### 認證配置 (pool_hba.conf)
用於配置客戶端連接的認證規則，格式類似於 PostgreSQL 的 pg_hba.conf。

## 啟動與停止

### 啟動
```bash
sudo systemctl start pgpool
```

### 停止
```bash
sudo systemctl stop pgpool
```

### 重啟
```bash
sudo systemctl restart pgpool
```

## 監控與管理

### 查看狀態
```bash
psql -h localhost -p 9999 -U postgres -c "show pool_nodes;"
```

### 查看連接池狀態
```bash
psql -h localhost -p 9999 -U postgres -c "show pool_status;"
```

## 故障排除

### 查看日誌
```bash
tail -f /var/log/pgpool/pgpool.log
```

### 常見問題
1. 連接被拒絕：檢查 pool_hba.conf 的認證配置
2. 負載平衡不工作：檢查 load_balance_mode 和 white_function_list
3. 主從切換失敗：檢查 failover_command 和健康檢查配置

## 安全建議
1. 修改預設的 postgres 用戶密碼
2. 限制可連接的 IP 範圍
3. 定期備份配置文件
4. 監控系統日誌
5. 使用 SSL 加密連接

## 效能調優
1. 根據系統資源調整 num_init_children
2. 適當設置 connection_life_time
3. 根據負載情況調整 max_pool
4. 監控並調整健康檢查間隔

## 參考資料
- [官方文檔](https://www.pgpool.net/docs/latest/en/html/index.html)
- [配置參數說明](https://www.pgpool.net/docs/latest/en/html/runtime-config.html)
- [故障排除指南](https://www.pgpool.net/docs/latest/en/html/tutorial.html) 
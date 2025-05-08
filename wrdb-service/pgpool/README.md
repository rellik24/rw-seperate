# Pgpool-II 配置目錄

此目錄包含 Pgpool-II 的相關配置檔案，用於實現 PostgreSQL 的讀寫分離、負載平衡和高可用性。

## 檔案說明

### pgpool.conf

主要配置檔案，包含了 Pgpool-II 的所有設定參數，包括：

- 連接設定（監聽地址、連接埠等）
- 主從複製模式設定
- 負載平衡設定
- 健康檢查設定
- 資料庫後端設定
- 日誌設定

### pool_hba.conf

Pgpool-II 的主機訪問控制配置檔案，用於設定客戶端連接認證規則，類似於 PostgreSQL 的 pg_hba.conf。

## 常用設定

### 負載平衡

在 pgpool.conf 中配置：

```
load_balance_mode = on
```

### 主從複製

在 pgpool.conf 中配置：

```
master_slave_mode = on
master_slave_sub_mode = 'stream'
```

### 連接設定

在 pgpool.conf 中配置：

```
listen_addresses = '*'
port = 9999
```

## 更多資訊

關於 Pgpool-II 的詳細配置和使用方法，請參考：

- [Pgpool-II 官方文檔](https://www.pgpool.net/docs/latest/en/html/index.html)
- [wrdb-service 目錄下的 README.md](../README.md) 
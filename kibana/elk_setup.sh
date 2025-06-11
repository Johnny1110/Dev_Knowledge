#!/bin/bash

# 創建 ELK Stack 設置腳本
echo "開始設置 ELK Stack..."

# 創建目錄結構
mkdir -p elk-stack/logstash/config
mkdir -p elk-stack/logstash/pipeline

cd elk-stack

# 檢查 Docker 和 Docker Compose
if ! command -v docker &> /dev/null; then
    echo "錯誤: Docker 未安裝"
    exit 1
fi

# if ! command -v docker-compose &> /dev/null; then
#     echo "錯誤: Docker Compose 未安裝"
#     exit 1
# fi

# 設置系統參數 (需要 root 權限)
echo "設置系統參數..."
sudo sysctl -w vm.max_map_count=262144
# echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf

# 創建 Logstash 配置文件
cat > logstash/config/logstash.yml << 'EOF'
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: [ "http://elasticsearch:9200" ]
xpack.monitoring.enabled: false
EOF

# 創建 Logstash pipeline 配置
cat > logstash/pipeline/logstash.conf << 'EOF'
input {
  file {
    path => "/app/logs/app_*.log"
    start_position => "beginning"
    sincedb_path => "/dev/null"
    codec => "plain"
    tags => ["app_logs"]
  }
}

filter {
  if [path] {
    grok {
      match => { 
        "path" => "/app/logs/app_%{DATE:log_date}\.log" 
      }
    }
  }

  grok {
    match => { 
      "message" => "(?<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[%{LOGLEVEL:level}\] %{GREEDYDATA:log_message}"
    }
    tag_on_failure => ["_grokparsefailure"]
  }

  if [timestamp] {
    date {
      match => [ "timestamp", "yyyy-MM-dd HH:mm:ss" ]
      target => "@timestamp"
    }
  }

  mutate {
    add_field => { 
      "source_host" => "%{host}"
      "log_file" => "%{path}"
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "app-logs-%{+YYYY.MM.dd}"
  }
  
  stdout { 
    codec => rubydebug 
  }
}
EOF

echo "配置文件已創建完成"

# 啟動服務
echo "啟動 ELK Stack..."
docker compose up -d

echo "等待服務啟動..."
sleep 30

# 檢查服務狀態
echo "檢查服務狀態..."
echo "Elasticsearch: http://localhost:9200"
curl -s http://localhost:9200/_cluster/health?pretty

echo -e "\nKibana: http://localhost:5601"
echo "請等待 1-2 分鐘讓所有服務完全啟動"

echo -e "\n設置完成!"
echo "您可以在瀏覽器中訪問 http://localhost:5601 來使用 Kibana"
echo "日誌索引名稱: app-logs-*"
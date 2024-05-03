# 塞滿導致 OOM
java -Xms1m -Xmx5m -jar .\demo-oom.jar oom

# 塞不滿 導致接近 OOM
java -Xms1m -Xmx20m -jar .\demo-oom.jar noom


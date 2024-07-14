# Dev_Knowledge

<br>
<br>

this's my blog to share my dev knowledge like java essence, sql optimize, system design inspiration etc.

since 2024 April.

"stay hungry stay humble."

<br>

---

<br>
<br>

# Catogory:

<br>

## Dev Philosophy

* [淺談 SOLID (物件導向設計基本原則)](dev_philosophy/solid/README.md)


<br>
<br>

## Java Eccence

 * [multi-thread](java/multi-thread)

 * [JVM Optimization](java/jvm)

<br>
<br>

## SQL

* [MySQL query optimization](sql/query-optimization/README.md)


<br>
<br>

## Redis

* [demo]

<br>
<br>

## System Desgin

* [order payment timeout](system/design/order-payment-timeout/README.md)

<br>
<br>

## TODO List(挖坑)

1. 設計資料及應用
    * https://github.com/Johnny1110/ddia

2. MongoDB 基礎以及應用，底層設計

3. K8s 研究:
    * https://ithelp.ithome.com.tw/m/articles/10288389

4. Web3 以太訪 ABI 互動 (用 golang 寫一個 web)

5. Web3 合約編寫部署
    * https://vocus.cc/article/62899a13fd89780001d43679

6. 史丹佛密碼學課程:
    * https://crypto.stanford.edu/~dabo/courses/OnlineCrypto/

7. Spring Boot 2 Actuator + Prometheus + Grafana 監控視覺化簡介(客製化 Metrics) :
    * https://www.tpisoftware.com/tpu/articleDetails/2446
    * https://medium.com/simform-engineering/revolutionize-monitoring-empowering-spring-boot-applications-with-prometheus-and-grafana-e99c5c7248cf
  
8. 實作一次模擬 MySQL 分庫分表，Partition 研究：
   * https://developer.aliyun.com/article/1253020 (阿里雲短介紹)
   * https://ke.qq.com/course/457506/4046378884332322#term_id=100547500 (騰訊課程影片)
   * https://github.com/GoodBoy2333/sharding-jdbc-demo (分庫分表)
   * https://blog.csdn.net/qq_26664043/article/details/138452285 (分區 CSDN)
  
9. Frizo Side Project:
   基本: 仿 line 做一個聊天通訊軟體。並支持使用者匯入 Web 3.0 錢包。
   進階: 串接 line pay 做 C2C ETH 交易 -> 敲定交易價格後，買方把錢轉到第三方 line pay 帳號中，賣家透過鏈上交易，產生 txHash 並交由後端去 web3 驗證，確定都沒問題後，line pay 第三方帳號匯款給賣家。如果賣方沒有去鏈上轉帳 (沒有 txHASH) 則 line pay 第三方帳號會在 1 hr 後將錢退還給買方。
   最終: 做成開公司 ?
   

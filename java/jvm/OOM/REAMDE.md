# JVM 優化系列(四) 由 OOM ( out of memory )  引出的 JVM 排查與優化方法

<br>

---

<br>

__問 : 如果 Java 應用程式運行過程出現 OOM 該怎麼辦 ?__

<br>

面對這個問題，OOM 問題的導致原因要先歸類可能的幾個原因:

<br>


1. __應用一次申請太多物件__

    例如一次性向 DB 申請了千萬筆資料放到 List 中。對應解法就是不要這樣做，請改用分頁查詢。

    <br>

2. __使用不當建立物件__

    例如高併發情況下，頻繁建立 Thread 或頻繁建立 JDBC Connection，且未妥善處理釋放資源就會導致 OOM。對應方法就是改用 Pool 來管理 Thread 或 Connection。

    <br>

3. __JVM 本身分配的資源就不夠__

    使用 `jmap -heap` 查看 heap 的狀況。透過一系列 JVM 啟動參數優化來調整。



<br>
<br>
<br>
<br>

---

<br>

本篇筆記需要搭配我寫的一個 JAR 檔做示範

JAR: [demo-oom.jar]()

<br>

---

<br>
<br>

## 1, 2 類問題排查

<br>
<br>

先說一下針對 __應用一次申請太多物件__ 或 ___使用不當建立物件__ 類型問題處理方式。

首先這兩類問題是由程式碼設計不良造成的，所以要定位的點，當然就是到底是哪一行程式碼在搞事情。

要定位 OOM 問題點有要分不同情境:

* 情境 1. 系統已經 GG

* 情境 2. 系統還在運行，但是記憶體快撐爆，或者 CPU 占用過高。

<br>
<br>

## 情境 1. 系統已經 GG

<br>

在 JVM 啟動時，需要設定一個 dump 參數。

```bash
java -Xms1m -Xmx5m -jar demo-oom.jar oom
```


<br>
<br>
<br>
<br>

---

<br>
<br>

## 3 類問題排查

<br>

針對啟動要被排查的 Java 應用後，透過 `jps` 查詢應用 PID :

```bash
> jps
10088 shoppingCartBase-1.0-SNAPSHOT.jar
17420 Jps
```

<br>

我使用的是 jdk 13，其提供的 jmap 需樣像下面這樣使用

```bash
jhsdb jmap --heap --pid 10088
```

<br>

可以看到 console 結果:

```bash
>jhsdb jmap --heap --pid 10088

Attaching to process ID 10088, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 13.0.1+9

using thread-local object allocation.
Garbage-First (G1) GC with 8 thread(s)

Heap Configuration: # 堆配置
   MinHeapFreeRatio         = 40 # 最小堆空閒比率
   MaxHeapFreeRatio         = 70 # 最大堆空閒比率
   MaxHeapSize              = 5337251840 (5090.0MB) # 堆最大容量
   NewSize                  = 1363144 (1.2999954223632812MB) # 新生代大小
   MaxNewSize               = 3202351104 (3054.0MB) # 新生代最大容量
   OldSize                  = 5452592 (5.1999969482421875MB) # 老年代大小
   NewRatio                 = 2 # 新生代與老年代的大小比率
   SurvivorRatio            = 8 # Survivor 空間與 Eden 空間的大小比率
   MetaspaceSize            = 21807104 (20.796875MB) # 元空間大小
   CompressedClassSpaceSize = 1073741824 (1024.0MB) # 壓縮類空間大小
   MaxMetaspaceSize         = 17592186044415 MB # 元空間最大容量
   G1HeapRegionSize         = 1048576 (1.0MB) # G1 Heap Region 大小

Heap Usage: # 堆使用情況
G1 Heap:
   regions  = 5090 # G1 堆區域數量
   capacity = 5337251840 (5090.0MB) # G1 堆總容量
   used     = 51934624 (49.528717041015625MB) # G1 堆已使用容量
   free     = 5285317216 (5040.471282958984MB) # G1 堆空閒容量
   0.9730592738902873% used # G1 堆已使用比例
G1 Young Generation:
Eden Space:
   regions  = 24 # Eden 空間區域數量
   capacity = 56623104 (54.0MB) # Eden 空間總容量
   used     = 25165824 (24.0MB) # Eden 空間已使用容量
   free     = 31457280 (30.0MB) # Eden 空間空閒容量
   44.44444444444444% used # Eden 空間已使用比例
Survivor Space:
   regions  = 11 # Survivor 空間區域數量
   capacity = 12582912 (12.0MB) # Survivor 空間總容量
   used     = 12265376 (11.697174072265625MB) # Survivor 空間已使用容量
   free     = 317536 (0.302825927734375MB) # Survivor 空間空閒容量
   97.47645060221355% used # Survivor 空間已使用比例
G1 Old Generation:
   regions  = 16 # 老年代區域數量
   capacity = 39845888 (38.0MB) # 老年代總容量
   used     = 14503424 (13.83154296875MB) # 老年代已使用容量
   free     = 25342464 (24.16845703125MB) # 老年代空閒容量
   36.39879728618421% used # 老年代已使用比例
```

其中詳細資料已經都列出註解說明其意義了，如果有看前面講到 [JVM 優化系列(二) 運行時內存 (新生代，老年代，永久代)](https://github.com/Johnny1110/Dev_Knowledge/blob/main/java/jvm/runtime/REAMDE.md) 應該或多或少都看得懂。

<br>
<br>



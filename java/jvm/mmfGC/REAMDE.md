# JVM 優化系列(六) Minor GC， Major GC， Full GC 觸發時機

<br>

---

<br>

本篇筆記會談到以下幾點:

1. 簡單介紹 Java 1.8 Memory Model。

2. 甚麼是 Minor GC， Major GC， Full GC。

3. GC 觸發條件。

<br>

---

<br>
<br>
<br>
<br>

## 簡單介紹 Java Memory Model

<br>

JVM Heap 在 1.8 版本前後，做出了一些調整，簡單說就是 1.8 以前的永久代 (PermGen) 移除了。1.8 版本之後的 class metadata 資料都存放在 METASPACE (Native Memory) 裡面。METASPACE 與 Heap 不相連，但是他們其實共享物理快取記憶體。

<br>

Java Memory Model (Pre 1.8 vs 1.8):

![heap](imgs/Java8-heap.jpg)

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

## 甚麼是 Minor GC， Major GC， Full GC

<br>

### Minor GC

__指發生在新生代 (NewGen) 的資源回收行為。__

__Minor GC 執行時會 STW (STOP-THE-WORLD) 所有人動作暫停__，等他 GC 完成再繼續動作。這個停頓時間可以作為參數被設定為 JVM 啟動選項 (可接最大受停頓時間)。

Minor GC 會在清理物件後，對清不掉的物件進行年齡 +1，當物件年齡超過 15 歲就會認定長大成人 (系統預設 15，可自行設定)，移去老年代存放。

<br>
<br>

### Major GC

__指發生在老生代 (OldGen) 的資源回收行為。__

<br>
<br>

### Full GC

__指針對所有區域，包括新生代，老年代，Metaspace 的全局資源回收。__ 

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

## GC 觸發條件

<br>

### Minor GC 

當新生代的 Eden 區無法再為新的物件分配記憶體空間時，便會觸發一次 Minor GC。應用如果會頻繁建立生命週期短的物件，就會頻繁觸發 Minor GC。

<br>
<br>

### Full GC 

Full GC 觸發時機有以下三點:

1. 老年代空間不足

2. Metaspace 空間不足

3. __Minor GC 引發 Full GC__ (重點)

<br>

Minor GC 引發 Full GC 原因:

__主要原因是年輕代經歷 Minor GC 一次過後，年紀到成年的物件會要移居到老年代。__

<br>

在 Minor GC 發生之前，JVM 會檢查老年代空間夠不夠所有目前年輕代的物件搬過來住 (畢竟極端情況就是大家都滿 15 歲了)。

上述檢查會發生 3 種情況:

* 情況 1 : __老年代空間 > 新生代物件總大小 > 歷次新生代物件搬家時的平均大小。__

* 情況 2 : __新生代物件總大小 > 老年代空間 > 歷次新生代物件搬家時的平均大小。__

* 情況 3 : __新生代物件總大小 > 歷次新生代物件搬家時的平均大小 > 老年代空間。__

<br>
<br>

情況 1 非常好。直接進行 Minor GC。

<br>
<br>

情況 2 不樂觀。但是可以報有 Minor GC 過後，新生代還活著的物件變小的希望。所以先跑一次 Minor GC，然後根據不同結果做不一樣的對策。

>1. Minor GC 過後，剩餘的存活物件的大小 < Survivor 區空間，那麼此時存活物件進入Survivor 區即可。

>2. Minor GC 過後，剩餘的存活物件的大小 > Survivor 區空間，但是是小於老年代可用空間，此時就直接進入老年代即可。

>3. 很不幸，Minor GC 過後，剩餘的存活物件的大小 > Survivor區空間，也大於了老年代可用空間。此時老年代都放不下這些存活物件了，就會發生「Handle Promotion Failure」的情況，這個時候就會觸發一次 Full GC。如果 Full GC 仍空間不夠就會 OOM。


<br>
<br>

情況 3 非常不樂觀。這種情況下就不做 Minor GC 了，直接進行一次 Full GC。如果 Full GC 仍空間不夠就會 OOM。



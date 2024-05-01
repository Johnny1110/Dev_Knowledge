# 淺談 SOLID (物件導向設計基本原則)

<br>

---

<br>

這一篇筆記並不是要一一解釋 SOLID 原則個代表甚麼意義，而是記錄一下我對 SOLID 開發哲學思想的個人看法:


<br>

* 單一職責原則(Single responsibility principle, SRP)

* 開放封閉原則(Open-Close principle, OCP)

* 里氏替換原則(Liskov substitution principle, LSP)

* 接口隔離原則(Interface segregation principle, ISP)

* 依賴反轉原則(Dependency inversion principle, DIP)

<br>

以上列出 SOLID 五大原則，下面針對這五大原則說明一下我的理解。


<br>
<br>
<br>
<br>

---

<br>

## 單一職責原則 (Single responsibility principle, SRP)

<br>

這個其實沒什麼好講的，就是簡單的一個物件就指該負責他本分的事，用現實生活舉例就是一個後端工程師就好好把後端寫好，不要去搞前端，不要去搞UI，不要去弄部屬。

換作是一個 class 來看，如果這個 class 定義了一個方法，叫做產出，裡面的 code 具體到從系統分析，時程規劃， UI 設計，套版串 API，寫 API，寫邏輯，做持久化處理，CI/CD 更版，設定網路防火牆等等。以下會遇到幾個問題:

1. 工程師 A 與 工程師 B 同時要調整這個大類別的不同功能，不用想，大概率會 Merge 衝突。

2. 免不了很多工序會串在一起，到時候改不動，不好維運。

3. 一個 class 出問題，搞不好全掛 (公司裡那個全能大神病倒住院了，公司業務怎麼辦)。

<br>

工作中不免還是會看到很多工程師把一坨業務擠在一起。然後東西寫好了也無法做單元測試。只能推版上去 run 一遍 API，看整個流程是不是好的... 

我自己的開發方式會是，把需求整理成 flow，然後寫成一個 Template 像這樣:


```java
class WorkTemplate{

    public Object doWork(Object params){
        // TODO 1. A 招呼客人
        ClassA a = new ClassA();
        a.do();

        // TODO 2. B 泡茶
        ClassB b = new ClassB();
        b.do();

        // TODO 3. C 做菜
        ClassC c = new ClassC();
        c.do();

        // TODO 4. D 結帳
        ClassD d = new ClassD();
        d.do();

        // save data.
        save();
    ...
    }
}
```

然後根據 A B C D 業務的不同，也許我會分別建立 4 各類別分別負責相應的工作。這樣一來職責分離開，我們可以針對它們分別編寫單元測試，而 doWork() 可以留給整合測試階段測。

如果大家在各自崗位各司其職，顧好自己本份。在 work flow 中把大家工作成果彙整交付，這樣不是很棒嗎。


<br>
<br>
<br>
<br>

---

<br>

##  開放封閉原則(Open-Close principle, OCP)

<br>

開放原則旨在對一個物件進行開發的過程中，不要去 __修改__ 他已有的方法，而是 __新增__

開放你新增，禁止你修改。

<br>

先舉例好了，大家不免都使用過框架，基於框架或套件開發業務。如果套件框架開發團隊進行更版，把你原本串接好的方法整個砍掉，或者直接修改邏輯，導致該方法提供的功能跟你原本預期的完全不一樣。然後更糟糕的是，你的 code 又大量依賴了該方法，那結果就是加班到死唄...

<br>

我們可以看到優秀的套件或框架開發者，很少會像上述那樣去做，而是會針對功能進行新增。讓我們可以自由選擇要不要換新 or 繼續用舊的。

另一個層面，來到我們日常開發中。開閉原則的 __開__ 告訴我們一個道理，對類別添加新行為時:

>依賴注入 > 實作介面 > 繼承物件

<br>

受先，類別繼承是十分寶貴的資源，畢竟只能繼承一個父類別，其次是實作，類別確實可以實作多個，然後定義其行為進行實作。但是也不見得該介面每個方法都必需要實作，最後是依賴注入:

```java

public class ClassA{

    private final ClassB b;

    public ClassA(ClassB b){
        this.b = b;
    }

    public void do(){
        // do something...
        b.dosomething();
    }

}

```

對物件添加新行為，開閉原則的建議是這樣，但實務上我覺得 __真沒必要過度糾結這個開閉原則的開部分__，根據實際狀況合理的新增功能就好了，到是這個閉原則真的很重要。


<br>
<br>
<br>
<br>

--------------------------------

<br>

## 里氏替換原則 (Liskov substitution principle, LSP)

<br>

"你不僅要做到你爸能做到的，豪要要比你爸更出色！" － some toxic ppl.

<br>

* 子類要求不應該比父類別多

* 子類回饋不應該比父類別少

<br>

里氏替換原則就是在說這一句話，子類別要在符合大眾對他的預期(以父類別為標準)的基礎上，做到比父類更多的事，還不能要求更多。

這個準則其實就是規範了我們，使用繼承時要注意的點。子類的設計必須遵照這樣的準則，不然就不要使用繼承。如果無法遵守這一個準則，那就實作介面。

<br>


>PS: 
我平時使用到繼承的時機大概有兩個，一個是使用 Template 設計模式時會使用，另一個狀況就是有一系列物件都屬於相同的分類 (例如 5 種支付方式的實作)，這些類別需要用到同樣的方法 (e.g. 調用訂單金和核對方法)，我會把這些方法提取出來整理到一個父類別供大家繼承使用，這些共用方法我會訂為 `protected`。

>話說基於開閉原則，應該優先使用依賴注入的方式來做可能會比較好，不過在實際開發中，我還是覺得這樣使用繼承會比依賴注入更方便。



<br>
<br>
<br>
<br>

---

<br>

## 接口隔離原則 (Interface segregation principle, ISP)

<br>

"針對不同需求的用戶，開放其對應需求的介面，提拱使用。可避免不相關的需求介面異動，造成被強迫一同面對異動的情況。"

<br>

關於接口隔離原則，簡單講就是把行為拆分的更細緻，最後類別透過實作想要的行為來定義他本身的能力職責。

例如現在有幾個介面:

1. 炒菜
2. 備料
3. 洗碗
4. 排餐

一個類別可以選擇他要實做哪些他要的介面，來定義出它本身具備的功能。你可以選擇只要炒菜 + 備料，也可以都選。簡單講就是把類別的粒度切小。

這些介面如果彙整到一個大介面上，也許可以叫做 "內場師傅介面"，但是如果合併起來，遇到的問題就是，當類別根本不需要有 "洗碗" 的能力，勢必會出現空實作，該類別無法提供該方法，但卻具備此方法可以給使用者使用，這就很奇怪。

<br>

> PS: 實務上我不會過度糾結這個 ISP 原則，要切的細緻前提是拿到的需求能一開始就很明確呀，而且有足夠的時間愜意的慢慢規劃，慢慢去切分職責... 這太過於理想了。基本上我就是直接 "內場師傅介面" 給他開下去，空實作就給他空。畢竟很難有資源來實現理想化的 ISP。



<br>
<br>
<br>
<br>

---

<br>

## 依賴反轉原則 (Dependency inversion principle, DIP)

<br>

依賴反轉，最終 solution 就是 DI，IOC。

<br>

他的核心精神在於，當 A 類別需要使用 B 類別的方法，不要直接在 A 類別裡建立 B 類別。因為如果這樣做了就會形成依賴，使模組耦合。

<br>


```java
public class ClassA {

    public void doSomething(){
        ClassB b = new ClassB(); // 依賴 B 類別
        b.doSomething(); 
    }

}
```

<br>

好的做法是透過 Interface + DI + IOC 的方式來做，例如:


```java

public class ClassA {

    private final InterfaceB b; // 依賴 Class 改為依賴 Interface

    public ClassA(InterfaceB b){// DI 依賴注入
        this.b = b;
    }

    public void doSomething(){
        b.do()
    }

}

public class IoC { // IoC 控制反轉，將物件之間的依賴關係，交給外部來定義。

    public void initApp(){
        InterfaceB b = new ClassB();
        ClassA a = new ClassA(b); // 注入 b 給 a
    }

}
```

這樣做的好處是，當今天我們的系統中，有 100 個地方使用到 InterfaceB，而我們需要抽換 ClassB 實作，換成其他。只需要修改 IoC 的配置就可以實現了。這就是解偶的好處。

<br>

> PS: Spring 框架核心理念就是 DI IoC。基於這套框架，使我們的程式開發默認就遵照 DIP。但是實務上我只會在真的有必要的地方使用 DIP，全部物件之間都沒有依賴性是理想化的，但是沒那個必要。專案中大量使用 Apache common-utils 之類的小工具如果都要一一實現 DIP... 那個 code 可能也不忍直視。

<br>

---

<br>
<br>
<br>
<br>

SOLID 是一套理想的開發哲學，但並不是開發設計的唯一準則。理解其中想要表達的設計思想後，根據實際情況去應用就好，我認為沒必要再開發實過度去 "SOLID 化"，那可能會逼瘋你的同事。我認為吸收理解成他並轉化為每個工程師自己的設計理念才是 SOLID 真正被設計出來的意義。
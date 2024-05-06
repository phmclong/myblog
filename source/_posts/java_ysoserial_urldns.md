---
title: Java Security 2 - Phân tích  URLDNS chain (ysoserial)
date: 2023-7-20 20:18:07
tags: [Java Security, Security, Java Insecure Deserialization]
categories:
  - Java 
---

# Lời nói đầu

Như đã nói, sang bài này tôi sẽ phân tích chain **URLDNS** trong công cụ **ysoserial**.

# Kiến thức nền

Để hiểu được các khái niệm nói trong bài này, bạn cần có kiến thức về cơ chế **Serialization/Deserialization** và **Reflection API**. Tôi có viết về các cơ chế này trong series Java Learning, cụ thể là 2 bài sau:  
[https://sheon.hashnode.dev/java-learning-5-serialization-deserialization](https://sio.hashnode.dev/java-learning-5-serialization-deserialization)  
[https://phmclong.github.io/myblog/2023/07/19/java_reflection/](https://phmclong.github.io/myblog/2023/07/19/java_reflection/)

Ngoài ra có 1 khái niệm mà tôi sẽ dùng trong bài là **Source** và **Sink**.

* **Source** và **Sink** được sử dụng trong **phân tích luồng dữ liệu (data flow analysis)**.
    
* **Source** là nơi data đến, **Sink** là nơi data kết thúc.
    
* **Source** và **Sink** thường được sử dụng để **taint analysist** (phân tích sự nhiễm độc - tôi ko thích cách dịch này lắm). Đọc thêm về **taint analysist**: [https://owasp.org/www-community/controls/Static\_Code\_Analysis#Taint\_Analysis](https://owasp.org/www-community/controls/Static_Code_Analysis#Taint_Analysis)
    
* Data bị **"nhiễm độc (tainted)"** nếu data đến từ một nguồn không an toàn, chẳng hạn như file, network hoặc user input. Data nào chạm vào data cũng bị **tainted**. Nếu **tainted data** được chuyển đến một phần nhạy cảm, thì khi **phân tích tĩnh (static analysist)** sẽ thông báo sự cố.
    

# Setup môi trường

Repository của ysoserial: [https://github.com/frohoff/ysoserial](https://github.com/frohoff/ysoserial)

Download toàn bộ project về để tiến hành phân tích source code.

IDE tôi dùng trong bài là **IntelliJ IDEA**.

Sau khi download xong ta sẽ thấy toàn bộ project như sau:

{% asset_img 1.png %}

Để phân tích chain **URLDNS** thì phiên bản **Java** tôi dùng là **Java 8u202.**

Bạn có thể setup **JDK** của project như sau:

* Bước 1: Ấn chuột phải vào thư mục chứa project
{% asset_img 2.png %}

* Bước 2: Sau đó bảng sau hiện ra, click chọn **Open Module Settings**
    
{% asset_img 3.png %}


* Bước 3: Lúc đó bảng **Project Structure** sẽ hiện ra, vào phần **Project Settings &gt; Project** để chọn JDK.
    
{% asset_img 4.png %}


Quay trở lại project, ta thấy file **pom.xml**. Vậy nên đây là 1 project maven.
{% asset_img 5.png %}


Trước tiên ấn vào **ô số 1**, lúc đó cái bảng ở góc phải sẽ hiện ra. Ấn tiếp vào **ô số 2** để reload project. Sau đó, ấn tiếp vào **ô số 3** và tìm đến dòng **Download Sources and Document** để tải toàn bộ **Dependencies** còn thiếu về.

# Tổng quan về chain URLDNS

* Chain **URLDNS** chỉ có thể kích hoạt DNS request chứ không thể thực thi code.
    
* Để chạy chain **URLDNS** thì không cần thêm class của third-party mà chỉ cần một số class và method **có sẵn (built-in)** trong JDK. Do vậy nó rất thích hợp để xác định rằng target có cho phép **Deserialize** hay không.
    
* Chain **URLDNS** là có thể nói là chain đơn giản trong ysoserial.
    

# Phân tích chain URLDNS

Mở file **ysoserial/src/main/java/ysoserial/payloads/URLDNS.java** để tiến hành phân tích.

{% asset_img 6.png %}


Cùng nhìn vào phần quan trọng trong source code của **URLDNS chain**.

```java
public class URLDNS implements ObjectPayload<Object> {
    public Object getObject(final String url) throws Exception {
        URLStreamHandler handler = new ysoserial.payloads.URLDNS.SilentURLStreamHandler();
        HashMap ht = new HashMap();
        URL u = new URL(null, url, handler);
        ht.put(u, url);
        Reflections.setFieldValue(u, "hashCode", -1);
        return ht;
    }

    public static void main(final String[] args) throws Exception {
        PayloadRunner.run(ysoserial.payloads.URLDNS.class, args);
    }
    static class SilentURLStreamHandler extends URLStreamHandler {
        protected URLConnection openConnection(URL u) throws IOException {
            return null;
        }
        protected synchronized InetAddress getHostAddress(URL u) {
            return null;
        }
    }
}
```

Tóm tắt ngắn gọn về đoạn code trên:

* `getObject()` là method được ysoserial gọi khi thực hiện tạo payload. Đây chính là quá trình `Serialization`.
    
* Khi chạy method `main()` sẽ gọi method `PayloadRunner.run(ysoserial.payloads.URLDNS.class, args);` và đây sẽ là method thực hiện việc gọi method `getObject()` và đưa **serialized data** từ `getObject()` vào quá trình `Deserialization`.
    

Ta có thể phân tích source code **URLDNS.java** bằng cách debug trực tiếp method `main()`.

Tuy nhiên ta cần thêm vào tham số mà method `main()` này cần trước khi tiến hành debug.

* Ta thực hiện chuột phải vào method `main()` và ấn **Modify Run Configuration**.
    
{% asset_img 7.png %}


* Thêm vào tham số ở phần khoanh đỏ, ở đây chính là URL mà ta muốn thực hiện DNS request tới.
    
* Ở đây URL tôi dùng được tạo ra từ **Burp Collaborator**, các bạn có thể sử dụng tùy ý các tool khác để tạo server lắng nghe DNS request. Tôi thấy có bạn dùng: [https://requestrepo.com/](https://requestrepo.com/)
    
{% asset_img 8.png %}


* Vì hàm tôi muốn debug là hàm `main()`, ngay bên trong hàm `main()` là `PayloadRunner.run(URLDNS.class, args);` -&gt; tôi sẽ đặt break point ngay tại dòng này để theo dõi cách chương trình hoạt động.
    
    {% asset_img 9.png %}

    
* Chuột phải vào method `main()` và ấn **Debug 'URLDNS.main()'** để tiến hành debug.
    
{% asset_img 10.png %}


> Lưu ý: Khi run hoặc debug file này, Windows defender sẽ nhận định vài file là virus nên sẽ không cho thực thi. Vậy nên hãy cấp quyền cho phép các file này chạy.

Sau khi đặt breakpoint và bật debug, hãy ấn **F7** và đọc thử cách chương trình hoạt động.

## Phân tích quá trình serialization

Sau một hồi đọc và ấn **F7**, bạn sẽ đi đến dòng `ht.put(u, url)` (của tôi là dòng 57 trong file **ysoserial/src/main/java/ysoserial/payloads/URLDNS.java**).

{% asset_img 11.png %}


Ấn tổ hợp **Ctrl + B** hoặc ấn **Ctrl + chuột trái** vào hàm `put()` ở dòng 57 để đi tới nơi hàm này được khai báo.

Hàm `put()` nằm trong class `HashMap`, class `HashMap` được nằm trong file **rt.jar** (file **rt.jar** này chứa tất cả các file Class đã được biên dịch cho môi trường Java Runtime).

Hàm `put()` gọi đến `putVal()` hay có thể viết là `HashMap.putVal()`.

{% asset_img 12.png %}


Trong file **URLDNS.java** ta thấy 1 đoạn comment mô tả Gadget Chain như sau:

{% asset_img 13.png %}


Có thể thấy `HashMap.putVal()` là 1 method call nằm trong gadget chain. Ta thấy bên trong `HashMap.putVal()` gọi tới method `HashMap.hash()` (`HashMap.hash()` chính là method call tiếp theo trong gadget chain), tiếp tục đi tới nơi `HashMap.hash()` được khai báo.

{% asset_img 14.png %}


Tại dòng 339, do giá trị của `key != null` nên `HashMap.hash()` đã gọi `key.hashCode()`.

{% asset_img 15.png %}


Ở đây `key` chính là 1 instance của class `URL`. Do đó nếu viết trực quan ra thì `key.hashCode()` chính là gọi tới `URL.hashCode()` (`URL.hashCode()` chính là method call tiếp theo trong gadget chain).

* Cách để tìm nhanh class `URL` là bạn ấn chuột phải vào **key** trong bảng này, lúc đó ấn tiếp **Jump to Type Source**.
    
{% asset_img 16.png %}


Tiếp tục đi tới nơi `URL.hashCode()` được khai báo.

{% asset_img 17.png %}


Ta thấy `hashCode = -1` nên giá trị của `hashCode` giờ được chuyển thành `handler.hashCode()`.

{% asset_img 18.png %}


`handler` là 1 instance của class `SilentURLStreamHandler`. Mà class `SilentURLStreamHandler` là class con của class `URLStreamHandler`.

{% asset_img 19.png %}


Vậy nên khi gọi `handler.hashCode()` ta có thể viết thành `URLStreamHandler.hashCode()`. Đi tới nơi `URLStreamHandler.hashCode()` khai báo.

{% asset_img 20.png %}


Khi đặt breakpoint tới dòng 354, ta thấy biến `u` là 1 instance của class `URL`.

{% asset_img 21.png %}


Khi gọi `u.getProtocol()` tương tự với gọi `URL.getProtocol()`. Đọc docs ta thấy method này dùng để lấy ra tên protocol của `URL` mà ta truyền vào. Link docs: [https://docs.oracle.com/javase/8/docs/api/java/net/URL.html#getProtocol--](https://docs.oracle.com/javase/8/docs/api/java/net/URL.html#getProtocol--)

{% asset_img 22.png %}


Ta thấy `protocol` có giá trị là `"http"` .

Tiếp tục kiểm tra dòng 359, nơi method `getHostAddress(u)` được gọi. Method `getHostAddress()` sẽ trả về chuỗi địa chỉ IP dưới dạng văn bản. Link docs: [https://docs.oracle.com/javase/8/docs/api/java/net/InetAddress.html#getHostAddress--](https://docs.oracle.com/javase/8/docs/api/java/net/InetAddress.html#getHostAddress--)

{% asset_img 23.png %}


Đi đến nơi `getHostAddress()` được khai báo.

{% asset_img 24.png %}


Ta thấy ở dòng 442 gọi `InetAddress.getByName(host)`. Hàm này sẽ xác định địa chỉ IP của host được cung cấp, do vậy sẽ thực hiện 1 request DNS -&gt; Đây mới chính là **Sink** của gadget chain này. Link docs: [https://docs.oracle.com/javase/8/docs/api/java/net/InetAddress.html#getByName-java.lang.String-](https://docs.oracle.com/javase/8/docs/api/java/net/InetAddress.html#getByName-java.lang.String-)

{% asset_img 25.png %}


Ở trên tôi vừa phân tích xong quá trình serialization, giờ tôi sẽ phân tích tiếp quá trình deserialization để xem toàn bộ quá trình thực hiện của gadget chain.

## Phân tích quá trình deserialization

> Lưu ý: Nhớ tắt debug và xóa các break point ở phần trước để bắt đầu lại.

Khởi đầu trong chain này chính là method `HashMap.readObject()` , ta sẽ bắt đầu từ nó.

Ấn **Ctrl + N** sẽ hiện ra 1 cái bảng, gõ **HashMap** để tìm class `HashMap`

{% asset_img 26.png %}


Sau khi tìm thấy class `HashMap`, ấn **Enter** để vào file khai báo class `HashMap` .

{% asset_img 27.png %}


Method ta cần tìm là `readObject()`. Ấn **Ctrl + F12** sẽ hiện ra 1 bảng chứa toàn bộ các method được khai báo trong class `HashMap` .

{% asset_img 28.png %}


Tiếp tục trên cái bảng đó, gõ **readObject** thì sẽ hiện ra method `readObject()`. Ấn **Enter** để đi tới nơi khai báo method `readObject()` .

{% asset_img 29.png %}


Trong body của method `HashMap.readObject()`thì `putVal()` được gọi. Đặt break point tại đây (dòng 1413) và tiến hành debug.

{% asset_img 30.png %}


Method `putVal()` gọi tới method `hash()` với tham số là `key` với `key` là URL cần gọi tới.

Đi vào nơi khai báo method `hash()`. Tiếp tục đặt break point vào dòng 339 tại nơi khai báo method `hash()`.

{% asset_img 31.png %}


Đoạn này bên trên tôi phân tích rồi nên đi tiếp luôn nhé.

Tiếp tục đi vào nơi khai báo `URL.hashCode()`.

Vừa nãy tôi có phân tích là đoạn này sẽ nhảy đến dòng 885 và gọi `handler.hashCode()`.

Tuy nhiên nếu bạn để ý thì ở khối if đã kiểm tra giá trị của `hashCode` và nếu `hashCode != -1` thì hàm sẽ trả về giá trị `hashCode` ngay lập tức và không thực thi các gadget đằng sau.

{% asset_img 32.png %}


Không phải tự nhiên `hashCode` có giá trị `=-1`. Điều này có được nhờ **Reflection API**. Đây là lí do cần có kiến thức về **Reflection API** để hiểu gadget chain này.

Để ý trong file **ysoserial/src/main/java/ysoserial/payloads/URLDNS.java**, dòng 59 đã dùng `Reflections.setFieldValue(u, "hashCode", -1)`.

{% asset_img 33.png %}


`Reflections.setFieldValue()` là method được **ysoserial** tự định nghĩa. Cùng xem cách `Reflections.setFieldValue()` hoạt động khi truyền 3 tham số `(u, "hashCode", -1)`.

* Code triển khai `Reflections.setFieldValue()`:
    
{% asset_img 34.png %}


`getField()` lại là 1 method được **ysoserial** tự định nghĩa.

* Code triển khai của `Reflections.getField()`:
    
{% asset_img 35.png %}

Quá trình khi truyền 3 tham số `(u, "hashCode", -1)` vào `Reflections.setFieldValue()` có thể mô tả như sau:

* Dòng 44 của `Reflections.setFieldValue()` gọi tới `Reflections.getField()` với tham số là `u` và `"hashCode"`.
    
{% asset_img 36.png %}


* Dòng 33 của `Reflections.getField()` thực hiện lấy ra field `hashCode` của object `u`.
    
{% asset_img 37.png %}


* Dòng 34 của `Reflections.getField()` cấp quyền truy cập vào field `hashCode` (do ban đầu field này có access modifier là **private**.
    
{% asset_img 38.png %}

{% asset_img 39.png %}


* Sau khi lấy được field `hashCode` hay trực quan hơn là `u.hashCode` thì dòng 45 của `Reflections.setFieldValue()` thực hiện gán giá trị cho `hashCode` với giá trị là tham số `-1`. Cuối cùng `hashCode = -1` .
    
{% asset_img 40.png %}


Bởi vì `hashCode = -1` nên method `URL.hashCode()` sẽ đi tiếp đến dòng 885 và theo đó thực hiện chạy các gadget giống hệt như tôi đã phân tích ở quá trình **Serialization**.

{% asset_img 41.png %}


Khi chạy đến cuối gadget thì thì server của tôi đã nhận được các DNS request.

{% asset_img 42.png %}


Có thể nói việc phân tích quá trình **Deserialization** đã kết thúc tại đây.

## Mở rộng

Có 1 đoạn code mà tôi chưa nói đến ở trong chain này.

```java
static class SilentURLStreamHandler extends URLStreamHandler {
    protected URLConnection openConnection(URL u) throws IOException {
        return null;
    }

    protected synchronized InetAddress getHostAddress(URL u) {
        return null;
    }
}
```

Trong chain **URLDNS**, dòng 53 trong hàm `getObject()` sử dụng kĩ cơ chế **Upcasting**.

Khi biến tham chiếu của class cha tham chiếu tới object của class con, thì đó là **Upcasting**. Đọc thêm về **Upcasting**: [https://gpcoder.com/2406-co-che-upcasting-va-downcasting-trong-java/](https://gpcoder.com/2406-co-che-upcasting-va-downcasting-trong-java/)

{% asset_img 43.png %}


Vậy vì sao lại phải `URLStreamHandler handler = new SilentURLStreamHandler();` ?

* Như đã phân tích tại quá trình **Serialization** thì khi code bên trong method `handler.getHostAddress()` được thực thi thì sẽ thực hiện 1 DNS request.
    
{% asset_img 44.png %}


* Trong quá trình **Serialization**, ta thực hiện ghi đè method `handler.getHostAddress()` trở thành `return null`. Lúc này dù có call method `handler.getHostAddress()` cũng sẽ không thực hiện 1 DNS request.
    
* Dòng 83-&gt;85 đã thực hiện ghi đè `handler.getHostAddress()`
    
{% asset_img 45.png %}


* Khi upcasting như này thì ghi gọi `handler.getHostAddress()` sẽ thực hiện đoạn `handler.getHostAddress()` mà ta đã ghi đè ở lớp con hay trực quan hơn là lớp `SilentURLStreamHandler`. Vậy nên DNS request không thực hiện trong quá trình **Serialization.**
    
{% asset_img 46.png %}


* Có lẽ việc tác giả đặt tên class con là `SlientURLStreamHandler` để mang ý là: thực hiện xử lý URLStream trong **im lặng (slient)** mà không thực hiện request DNS (Cái này tôi đoán vậy thôi 😂).
    

## Kết bài

Vậy là việc phân tích chain **URLDNS** của tôi kết thúc tại đây.

Chain này đúng ra phải viết lại như sau:

1. `HashMap.readObject()`
    
2. `HashMap.hash()`
    
3. `URL.hashCode()`
    
4. `URLStreamHandler.hashCode()`
    
5. `URLStreamHandler.getHostAddress()`
    
6. `InetAddress.getByName()`
    

Sau khi phân tích chain này tôi học được rất nhiều, dù đây mới chỉ là chain đơn giản nhất trong **ysoserial**. Sang các bài sau có lẽ tôi sẽ phân tích 7 gadget chain trong bộ **CommonsCollections**.

Cảm ơn các bạn đã đọc tới đây, chào tạm biệt và hẹn gặp lại ở bài sau!
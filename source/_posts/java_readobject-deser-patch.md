---
title: Java Sec - Phân tích method readObject và lý do vì sao patch thường thực hiện tại resolveClass
date: 2026-07-23 11:57:00
tags: [Java Sec, Java Deser]
categories:
  - Java
---

# I. Tổng quan

Xem sơ đồ luồng thực thi của `readObject` bên dưới. Đây là sơ đồ mô tả quá trình thực thi **Deserialization** trong WebLogic.

{% asset_img image-4.png %}

Có thể tạm thời bỏ qua lần gọi `readObject` đầu tiên; phần này sẽ được giải thích chi tiết trong bài viết tiếp theo về WebLogic.

Tạo 2 class để debug quá trình deserialization

Class `User`:
```java
package org.example;

import java.io.Serializable;

public class User implements Serializable {
    private String name;
    private int age;

    @Override
    public String toString() {
        return "User{" +
                "name='" + name + '\'' +
                ", age=" + age +
                '}';
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public User() {
    }

    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }
}
```

Class `ReadObjectAnalysis`:
```java
package org.example;

import java.io.*;

public class ReadObjectAnalysis {
    public static void main(String[] args) throws IOException, ClassNotFoundException {
        User user = new User();
        user.setName("sheon");
        user.setAge(26);
        ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("1.txt"));
        oos.writeObject(user);
        ObjectInputStream ois = new ObjectInputStream(new FileInputStream("1.txt"));
        Object o = ois.readObject();
    }
}
```

# II. Phân tích method `readObject`
Sau khi chuẩn bị. Ta đi đến quá trình phân tích.

Đặt breakpoint tại method `ObjectInputStream.readObject()`, rồi chạy class `ReadObjectAnalysis` để debug.
{% asset_img image-1.png %}
Tại đây có một đoạn kiểm tra biến `enableOverride`. Nếu giá trị của nó không phải `false`, chương trình sẽ trả về kết quả từ method `readObjectOverride`. Trong constructor, giá trị này đã được định nghĩa là `false`.
{% asset_img image-3.png %}
Tiếp theo chương trình sẽ gọi method `readObject0`
{% asset_img image-5.png %}
Ta tiếp tục follow vào bên trong phương thức `readObject0` để xem cách implement.
{% asset_img image-6.png %}
Ở đây, chương trình sẽ lấy byte đầu tiên trong dữ liệu serialized. Nếu byte này là `TC_RESET` thì sẽ gọi:

```java
bin.readByte();
handleReset();
```
Kiểm tra giá trị của `TC_RESET.
{% asset_img image-7.png %}

Sau khi chuyển sang kiểu `Byte`, giá trị này là `121`. Trong khi đó, byte đầu tiên trong dữ liệu serialized của chúng ta là `115`, nên đoạn xử lý này sẽ bị bỏ qua.
{% asset_img image-8.png %}

Tiếp theo, trong code có một câu lệnh `switch` để kiểm tra loại dữ liệu. Giá trị của `TC_OBJECT` sau khi chuyển đổi vừa đúng bằng `115`, vì vậy chương trình sẽ đi vào nhánh này.
{% asset_img image-9.png %}
Trong nhánh này, nó sẽ gọi phương thức `readOrdinaryObject`. Tiếp tục follow vào trong.
{% asset_img image-10.png %}
Trong phương thức này, chương trình tiếp tục gọi `readClassDesc`. Tiếp tục follow.
{% asset_img image-11.png %}
Đến đây khá thú vị: chương trình lấy byte thứ hai trong dữ liệu serialized, sau đó lại thực hiện một câu lệnh switch. Lần này luồng thực thi đi vào phương thức `readNonProxyDesc`. Tiếp tục follow.
{% asset_img image-12.png %}
{% asset_img image-13.png %}
Trong phương thức này, nó lại gọi `resolveClass` và truyền vào tham số `readDesc`. Tiếp tục follow vào phương thức này.
{% asset_img image-14.png %}

Tại đây, phương thức trả về:
```java
Class.forName(name, false, latestUserDefinedLoader());
```
Phương thức `latestUserDefinedLoader()` trả về `sun.misc.VM.latestUserDefinedLoader()`. Điều này cho thấy class loader được chỉ định tại đây.
{% asset_img image-15.png %}
Sau đó quay lại phương thức `readOrdinaryObject` để tiếp tục phân tích.
{% asset_img image-16.png %}
Đây là nơi thực hiện thao tác deserialization. Đi vào hàm `readSerialData` để phân tích.

{% asset_img image-17.png %}
Phương thức `slotDesc.hasReadObjectMethod()` sẽ lấy thuộc tính `readObjectMethod`.

Nếu class đang được deserialization không override `readObject()`, thì thuộc tính `readObjectMethod` sẽ là `null`.

Nếu class này có override `readObject()`, chương trình sẽ đi vào nhánh `if` bên trong và gọi `slotDesc.invokeReadObject(obj, this);`

{% asset_img image-18.png %}
Nói cách khác, nếu phương thức `readObject()` bị override thì luồng xử lý sẽ đi đến được điều kiện else này trong `readSerialData`.
{% asset_img image-19.png %}

# III. Vì sao trong các bản patch thường thực hiện tại method `resolveClass`

Phương thức `resolveClass` có nhiệm vụ chuyển đổi **serialization descriptor** của một class thành đối tượng `Class` tương ứng.

{% asset_img image-4.png %}

Có thể sử dụng sơ đồ trên để minh họa quá trình gọi hàm bên trong phương thức `readObject` nguyên bản (dù có 1 vài bước liên quan tới quá trình `readObject` Weblogic nhưng ko cần để tâm).

Bên trong hàm `resolveClass`, chương trình lấy **fully qualified class name** từ phần mô tả của class. Sau đó, nó sử dụng **Reflection** để tìm và trả về đối tượng `Class` tương ứng với tên đầy đủ đó.

{% asset_img image-14.png %}

Vì vậy, khi **override** phương thức `resolveClass`, chúng ta có thể thêm một **blacklist** chứa tên các class không được phép sử dụng. Nếu phát hiện class đang được xử lý nằm trong blacklist, chương trình sẽ ném ra một **exception**.

Bằng cách này, chúng ta có thể ngăn chặn các cuộc tấn công **Deserialization Attack** ở một mức độ nhất định.

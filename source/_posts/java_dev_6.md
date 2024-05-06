---
title: Java Dev 6 - Reflection API
date: 2023-7-19 17:18:07
tags: [Java Development, Development]
categories:
  - Java
---

# Lời nói đầu

Hôm nay tôi sẽ giới thiệu ngắn gọn về Reflection API trong Java. Việc hiểu được cơ chế của Reflection API sẽ là tiền đề quan trọng cho việc nghiên cứu lỗ hổng bảo mật Deserialization trong Java.

# Kiến thức nền

Trước khi tìm hiểu Reflection, trước tiên bạn nên hiểu 2 khái niệm: **giai đoạn biên dịch (compile time)** và **giai đoạn chạy (run time)**.

## Compile time

- Là giai đoạn mà source code được **compiler** biên dịch thành **code mà máy tính có thể thực thi (executable code)**.
- Trong Java, đó là quá trình biên dịch file `.java` thành file `.class`.
- Trong **compile time**, chỉ một số chức năng biên dịch được thực hiện và code không được đưa vào bộ nhớ để chạy mà chỉ hoạt động dưới dạng văn bản, chẳng hạn như kiểm tra **lỗi (errors)**.

## Run time

- Là giai đoạn mà **executable code** bắt đầu chạy cho đến khi kết thúc chương trình.
- Là giai đoạn mà code trên **đĩa (disk)** được đưa vào bộ nhớ và **thực thi (execute)**.

# Tổng quan Reflection API

Java là một ngôn ngữ hướng đối tượng (Object-oriented), thông thường bạn cần tạo ra một đối tượng và bạn có thể truy cập vào các trường (field), hoặc gọi phương thức (method) của đối tượng này thông qua dot-operator `.`

**Reflection API** giới thiệu một cách tiếp cận khác, bạn có thể truy cập vào một trường của một đối tượng nếu bạn biết tên của trường đó. Hoặc bạn có thể gọi một phương thức của đối tượng nếu bạn biết tên phương thức, các kiểu tham số của phương thức, và các giá trị tham số để truyền vào.

**Reflection API** cho phép bạn truy cập, sửa đổi cấu trúc và hành vi của một đối tượng tại thời gian chạy (runtime) của chương trình. Đồng thời nó cho phép bạn truy cập vào các thành viên private (private member) tại mọi nơi trong ứng dụng, điều này không được phép với cách tiếp cận truyền thống.

# Kiến trúc của Reflection API

Các class được dùng trong **Reflection** được nằm trong package `java.lang.reflect`

{% asset_img 1.png %}

## Object

Class **Object** là class gốc trong hệ thống phân lớp các class.

Mọi class đều là con của class **Object**, hay có thể nói class **Object** là class cha của toàn bộ các class.

## Class

{% asset_img 2.png %}

**Class** là class được cung cấp bởi package `java.lang.Class`.

Một instance của class **Class** đại diện cho toàn bộ các kiểu dữ liệu trong Java, bao gồm: các kiểu dữ liệu cơ bản (boolean, byte, char, short, int, long), void, array, class, interface, enumeration, annotation.

**Class** không có **public constructor**. Thay vào đó object của **Class** được tạo ra tự động bởi JVM trong quả trình tải class.

# Cách sử dụng Reflection API

Do các thao tác của Reflection API đều nằm trên object của class **Class** nên trước tiên ta cần lấy ra được object **Class** trước.

## Các cách lấy ra object **Class**

### Cách 1:

- Cú pháp: `Class.forName("<full class name>")`
- Ví dụ: `Class cls = Class.forName("Domain.Person")`
- Cách này thường được sử dụng khi chỉ biên dịch được tên lớp lúc thực thi (runtime)
- Nếu như không tìm thấy class trong class path, method này sẽ trả về exception **ClassNotFoundException**.

### Cách 2:

- Cú pháp: `<Tên class>.class`
- Ví dụ: `Class cls = Person.class;`

### Cách 3:

- Cú pháp: `<Đối tượng>.getClass()`
- Ví dụ: `Person p = new Person(); Class cls = p.getClass();`
- method `getClass()` được định nghĩa trong class **Object**

## Cách lấy ra Field

### Cách 1:

- Cú pháp: `Field[] getFields()`
- trả về tất cả các field mà có modifier là public

### Cách 2:

- Cú pháp: `Field getField(String name)`
- trả về field có modifier là public, tham số truyền vào là tên cụ thể của field đó.

### Cách 3:

- Cú pháp: `Field[] getDeclaredFields()`
- trả về tất cả các field, không quan tâm field đó có modifier là gì.

### Cách 4:

- Cú pháp: `Field getDeclaredField(String name)`
- trả về field mà không quan tâm field đó có modifier là gì, tham số truyền vào là tên cụ thể của field đó.

### Cách cho phép truy cập vào Field bất kể Access Modifier

Cú pháp: `<Field lấy được>.setAccessible(boolean flag)`

### Cách lấy giá trị của Field

Cú pháp: `<Field lấy được>.get(Object obj)`

### Cách sửa giá trị của Field

Cú pháp: `<Field lấy được>.set(Object obj, Object value)`

## Cách lấy ra Method

### Cách 1:

- Cú pháp: `Method[] getMethods()`
- trả về tất cả các method mà có modifier là public

### Cách 2:

- Cú pháp: `Method getMethod(String name, class<?>... parameterTypes)`
- trả về field có modifier là public, tham số truyền vào là tên cụ thể của field đó.

### Cách 3:

- Cú pháp: `Method[] getDeclaredMethods()`
- trả về tất cả các method, không quan tâm method đó có modifier là gì.

### Cách 4:

- Cú pháp: `Method getDeclaredMethod(String name, class<?>... parameterTypes)`
- trả về method mà không quan tâm method đó có modifier là gì (ngoại trừ modifier là protected), tham số truyền vào là tên cụ thể của method đó.

### Cách thực thi một method

- Cú pháp: `Method.invoke(Object obj, Object[] args)`

## Cách lấy ra Constructor

### Cách 1:

- Cú pháp: `Constructor<?>[] getConstructors()`

### Cách 2:

- Cú pháp: `Constructor getConstructor(class<?>... parameterTypes)`

### Cách 3:

- Cú pháp: `Constructor getDeclaredConstructor(class<?>... parameterTypes)`

### Cách 4:

- Cú pháp: `Constructor<?>[] getDeclaredConstructors()`

> Thật ra còn rất nhiều các phương thức khác, các bạn có thể tham khảo ở phần cuối bài

# Ví dụ minh họa:

- Cấu trúc project:

{% asset_img 3.png %}

- Code của class **Person:**

```java
package Domain;

public class Person {
    private String name  ;
    private int age;
    public String a ;


    public Person() {
    }

    public void eat(){
        System.out.println("eat");
    }
    public void eat(String food){
        System.out.println("eat "+food);
    }

    @Override
    public String toString() {
        return "Person{" +
                "name='" + name + '\'' +
                ", age=" + age +
                ", a='" + a + '\'' +
                '}';
    }

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }
}
```

- Code của class **Main**:

```java
package Domain;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Constructor;

public class Main {

    public static void main(String[] args) throws Exception {
        // Sử dụng Class.forName() để lấy ra object Class
        Class cls = Class.forName("Domain.Person");
        // Sử dụng getField() để lấy field cụ thể (có modifier public)
        Field a = cls.getField("a");
        System.out.println("(+) Demo getField(): ");
        System.out.println(a + "\n"); // "a" ko public nên sẽ trả về null

        Person person = new Person();
        Object o = a.get(person);
        System.out.println("(+) Demo <Field lấy được>.get():");
        System.out.println(o + "\n");

        a.set(person, "abc");
        System.out.println("(+) Demo <Field lấy được>.set():");
        System.out.println(person + "\n");

        // Sử dụng getDeclaredFields() để lấy toàn bộ Field
        System.out.println("(+) Demo getDeclaredFields():");
        Field[] declaredFields = cls.getDeclaredFields();
        for (Field declaredField : declaredFields) {
            System.out.println(declaredField);
        }
        System.out.println("\n");

        // Sử dụng setAccessible() để truy cập vào field bất kể access modifier,
        // ở đây a là 1 field private
        a.setAccessible(true);
        Object o1 = a.get(person);
        System.out.println("(+) Demo <Field lấy được>.setAccessible(): ");
        System.out.println(o1 + "\n");

        // Sử dụng getMethods() để lấy ra toàn bộ Method
        System.out.println("(+) Demo getMethods(): ");
        Method[] methods = cls.getMethods();
        for (Method method : methods) {
            System.out.println(method);
        }
        System.out.println("\n");

        // Lấy ra tên class
        System.out.println("(+) Demo getName(): ");
        String name = cls.getName();
        System.out.println(name + "\n");


        Constructor constructor = cls.getConstructor(String.class,int.class);
        System.out.println("(+) Demo getConstructor(): ");
        System.out.println(constructor + "\n");

        // Construct có param
        System.out.println("(+) Demo <Constructor lấy được>.getConstructor() khi có param: ");
        Object o2 = constructor.newInstance("123", 18);
        System.out.println(o);

        // Construct không có param
        System.out.println("(+) Demo <Constructor lấy được>.getConstructor() khi không có param: ");
        Object o3 = constructor.newInstance();
        System.out.println(o3);

    }
}
```

Kết quả khi chạy hàm `main()`:

```plaintext
(+) Demo getField():
public java.lang.String Domain.Person.a

(+) Demo <Field lấy được>.get():
null

(+) Demo <Field lấy được>.set():
Person{name='null', age=0, a='abc'}

(+) Demo getDeclaredFields():
private java.lang.String Domain.Person.name
private int Domain.Person.age
public java.lang.String Domain.Person.a

(+) Demo <Field lấy được>.setAccessible():
abc

(+) Demo getMethods():
public java.lang.String Domain.Person.toString()
public void Domain.Person.eat(java.lang.String)
public void Domain.Person.eat()
public final void java.lang.Object.wait() throws java.lang.InterruptedException
public final void java.lang.Object.wait(long,int) throws java.lang.InterruptedException
public final native void java.lang.Object.wait(long) throws java.lang.InterruptedException
public boolean java.lang.Object.equals(java.lang.Object)
public native int java.lang.Object.hashCode()
public final native java.lang.Class java.lang.Object.getClass()
public final native void java.lang.Object.notify()
public final native void java.lang.Object.notifyAll()

(+) Demo getName():
Domain.Person

(+) Demo getConstructor():
public Domain.Person(java.lang.String,int)

(+) Demo <Constructor lấy được>.getConstructor() khi có param:
null
(+) Demo <Constructor lấy được>.getConstructor() khi không có param:
Exception in thread "main" java.lang.IllegalArgumentException: wrong number of arguments
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at Domain.Main.main(Main.java:64)
```

# Kết bài

Lại là 1 bài mà tôi mất khá nhiều thời gian để viết. Các bài sau có thể tôi sẽ tiếp tục với series Java Learning này hoặc chuyển qua viết series Java Security, chắc có lẽ tùy hứng :&gt; Cảm ơn các bạn đã đọc tới đây.

Happy learning. Good bye!

# Tham khảo

- [https://docs.oracle.com/javase/8/docs/api/java/lang/reflect/Field.html](https://docs.oracle.com/javase/8/docs/api/java/lang/reflect/Field.html)
- [https://docs.oracle.com/javase/8/docs/api/java/lang/Object.html](https://docs.oracle.com/javase/8/docs/api/java/lang/Object.html)
- [https://docs.oracle.com/javase/8/docs/api/java/lang/Class.html](https://docs.oracle.com/javase/8/docs/api/java/lang/Class.html)

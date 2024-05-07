---
title: Java Dev 8 - Java Bytecode (ASM Framework)
date: 2023-11-02 17:18:07
tags: [Java Development, Development]
categories:
  - Java
---

# Type descriptor

| **Kiểu trong Java** | **Type descriptor** |
| --- | --- |
| `boolean` | `Z` |
| `char` | `C` |
| `byte` | `B` |
| `short` | `S` |
| `int` | `I` |
| `float` | `F` |
| `long` | `J` |
| `double` | `D` |
| `Object` | `Ljava/lang/Object;` |
| `int[]` | `[I` |
| `Object[][]` | `[[Ljava/lang/Object;` |

# Method descriptor

| Method ví dụ | **Method descriptor tương ứng** |
| --- | --- |
| `void m(int i, float f)` | `(IF)V` |
| `int m(Object o)` | `(Ljava/lang/Object;)I` |
| `int[] m(int i, String s)` | `(ILjava/lang/String;)[I` |
| `Object m(int[] i)` | `([I)Ljava/lang/Object;` |
| `Object m(String str)` | `(Ljava/lang/String;)Ljava/lang/Object;` |
| `public Test(){…}` | Method descriptor là `()V`, tên method là: `<init>` ( điều này tượng trưng cho việc đây là constructor) |
| `static int m = 1;` | Tên method là: `<clinit>` |

# `ClassReader`

`ClassReader` là trình phân tích cú pháp (**parser**), nó tạo ra một `ClassVisitor` để truy cập cấu trúc `ClassFile`, `ClassFile` được định nghĩa trong Java Virtual Machine Specification - JVMS.

Xem thêm JVMS: [https://docs.oracle.com/javase/specs/jvms/se9/html/jvms-4.html](https://docs.oracle.com/javase/specs/jvms/se9/html/jvms-4.html)

`ClassReader` sẽ parse nội dung `ClassFile` và gọi các method truy cập thích hợp của một `ClassVisitor` nhất định cho từng field, method và bytecode mà nó gặp phải.

# `ClassVisitor`

`ClassVisitor` là một trình truy cập (**visitor**) sẽ truy cập qua các class Java. Các method của class này phải được gọi theo thứ tự sau: `visit [ visitSource ] [ visitModule ][ visitNestHost ][ visitOuterClass ] ( visitAnnotation | visitTypeAnnotation | visitAttribute )* ( visitNestMember | [ * visitPermittedSubclass ] | visitInnerClass | visitRecordComponent | visitField | visitMethod )* visitEnd`.
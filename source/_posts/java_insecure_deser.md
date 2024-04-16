---
title: Java Security 1 - Lỗ hổng Insecure Deserialization & công cụ ysoserial
date: 2023-7-20 17:18:07
tags: [Java Security, Security, Java Insecure Deserialization]
categories:
  - Java 
---

# Lời nói đầu

Mở đầu cho series Java Security, tôi sẽ viết về lỗ hổng **Insecure Deserialization**.

# Kiến thức nền

Trước khi đến với chủ đề này, bạn nên có hiểu biết về cơ chế **Serialization/Deserialization** trong Java. Tôi có viết về cơ chế này trong series Java Learning, cụ thể là bài này: [https://sio.hashnode.dev/java-learning-5-serialization-deserialization](https://sio.hashnode.dev/java-learning-5-serialization-deserialization)

# Insecure Deserialization là gì ?

Khi data được **deserialize** là data do người dùng có thể kiểm soát (user-controllable data hay untrusted data) thì đó là **Insecure Deserialization**.

# Lý do lỗ hổng Insecure Deserialization phát sinh ?

* Do sự thiếu hiểu biết về hậu quả khi để cho user-controllable data đi vào quá trình deserialiazation.
    
* Do developer nghĩ rằng user-controllable data xuất hiện ở dạng binary thì sẽ khó để thao túng hơn, dẫu nó có thể khó hơn, attacker vẫn có thể thao túng nó.
    
* Developer có thể đã triển khai 1 vài form kiểm tra đối với dữ liệu được deserialize. Tuy nhiên việc kiểm tra này thường được thực hiện sau khi quá trình deserialization kết thúc, mà việc khai thác lỗ hổng có thể đạt được mục đích ngay cả trước khi quá trình deserialization kết thúc.
    
* Do developer sử dụng dependencies không an toàn, mỗi dependencies sẽ có các class và method khác nhau dẫn đến việc khó kiểm soát các class và method này 1 cách hiệu quả và an toàn.
    

# Hậu quả của Insecure Deserialization

* Lỗ hổng này đến từ việc can thiệp vào các properties, methods của object nên attacker có thể thay đổi luồng hoạt động của chương trình tùy theo ý muốn. Do vậy kĩ thuật này còn được gọi với cái tên **Object Injection**.
    
* Chính vì thay đổi được luồng hoạt động của chương trình nên rủi ro bảo mật có thể nói là thiên biến vạn hóa, có thể kể đến như: bypass authentication, privilege escalation, arbitrary file access, denial-of-service, remote code execution,...
    

# Gadget chain là gì?

* Khi ta lắp các mảnh nhỏ của khẩu súng thành 1 khẩu súng hoàn chỉnh thì từng mảnh nhỏ đó là **gadget** và khẩu súng hoàn chỉnh là **gadget chain**.
    
* Trong việc khai thác lỗ hổng **Insecure Deserialization**, khi attacker tìm cách lợi dụng các method call, chỉnh sửa field thì từng method call, từng field bị chỉnh sửa chính là từng **gadget**; từ các **gadget** đó attacker có thể điều khiển luồng hoạt động của chương trình theo ý attacker muốn thì đó là quá trình xây dựng **gadget chain**.
    

# Giới thiệu về Ysoserial

* là công cụ được công bố trong bài trình bày **Marshalling Pickles** bởi **Chris Frohoff** và **Gabe Lawrence** tại hội thảo AppSecCali 2015.
    
* Video bài trình bày **Marshalling Pickles**: \[https://www.youtube.com/watch?v=KSA7vUkXGSg\]
    
* Slide của bài trình bày **Marshalling Pickles**: \[https://www.slideshare.net/frohoff1/appseccali-2015-marshalling-pickles\]
    
* là 1 tool mã nguồn mở trên github, đây là link github của nó: [https://github.com/frohoff/ysoserial](https://github.com/frohoff/ysoserial).
    
* là một tập hợp các **gadget chain** được phát hiện trong các thư viện Java nổi tiếng, trong điều kiện thích hợp nó có thể dùng để khai thác các ứng dụng Java thực hiện deserialize không an toàn.
    

# Kết bài

Bài này chỉ là giới thiệu cơ bản, ở các bài viết trong tương lai thì tôi sẽ tiến hành phân tích source code của bộ tool **ysoserial**. Cụ thể hơn là phân tích cách mà các **gadget chain** này được xây dựng.

# Tham khảo

* [https://portswigger.net/web-security/deserialization](https://portswigger.net/web-security/deserialization)
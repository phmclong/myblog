---
title: CBJS Challenge - JS SECURITY (Write up)
date: 2022-05-29 02:21:02
tags: [JS Security, CTF, JS Type Coercion]
categories:
  - JS
---

> Sau bao nhiêu thử thách PHP của CBJS, mình cũng đã được làm 1 thử thách về JavaScript - ngôn ngữ mình quen thuộc.

Khi mà PHP có vấn nạn mang tên **Type Juggling**, thì JavaScript cũng tồn tại 1 vấn nạn mang tên **Type Coercion**. Thử thách lần này chính là về **Type Coercion** trong JavaScript.

# Challenge 1

## Goal: RCE

Link thử thách 1:
http://javascript-workshop.cyberjutsu-lab.tech:8000/

Vừa vào ta thấy trang cho ta chức năng tính toán các phép như cộng, trừ, nhân, chia cơ bản.
{% asset_img 1.png %}

Thử một phép tính cơ bản: "một cộng hai bằng mấy ?"
{% asset_img 2.png %}

"Một cộng hai bằng ba". "Ba...hai...một... tay đâu tay đâu 🤘🤘🤘"

Quẩy đến đây thôi, làm tiếp đã :)

### Đọc source code tại client

{% asset_img 3.png %}

Sau khi ấn nút Submit thì đây là đoạn script sẽ được chạy ở client.

Chức năng của hàm **tinh()** là gửi 1 POST request tới server, gói tin này có data là object **data** ở dòng 5, nhờ **JSON.stringify()** mà **javascript object** được chuyển sang dạng **JSON**.

### Đọc source code tại server

Cấu trúc thường thấy của 1 server viết bằng NodeJS + Express Framework:

File **app.js** sẽ là nơi khởi động server.

Folder **views** chứa các file html để cho người dùng tương tác.

Folder **routes** sẽ chứa các hàm để xử lý các request đến từ user.

{% asset_img 4.png %}

Đọc file **app.js**.
{% asset_img 5.png %}

Dòng 10, ta thấy việc xử lý các gói tin đến "/" được thực hiện bởi module **indexRouter** nằm trong đường dẫn tới thư mục **routes**.

Ta đi đến module **indexRouter**
{% asset_img 6.png %}

Dòng 24->44 chính là hàm xử lý gói tin POST mà ban nãy client gửi.

Dòng 39 là nơi 1 **unsafe method** mang tên **eval()** xuất hiện.

Dòng 26 là nơi các **untrusted data** xuất hiện, các data này chính là 3 tham số mà client gửi tới.

Để **untrusted data** đến được **unsafe method** thì phải qua được khối **if** từ dòng 29->36.

{% asset_img 7.png %}

Dòng 29, khối **if** sử dụng 2 lần toán tử OR, điều đó có nghĩa 3 toán hạng kia chỉ cần 1 toán hạng trả về **true** thì sẽ thực hiện khối **if**.

Để qua được khối **if** thì cả 3 toán hạng kia đều phải trả về **false**, vậy làm sao để 3 toán hạng đều trả về **false**.

Ta thấy trước các hàm **kiemTra()** đều có dấu **!**, vậy thì kết quả trả về của hàm **kiemTra()** phải trả về **true**.

{% asset_img 8.png %}

Dòng 9->16 của hàm **kiemTra()**, khối **if** của hàm này sẽ kiểm tra xem nếu tham số **input** có phải dạng **string** không ? Nếu **input** là **string** mà chứa các ký tự ko hợp lệ, ko nằm trong tham số **whitelist** thì lập tức hàm **kiemTra()** sẽ trả về **false**.

Nhưng nếu ở đây **input** không phải là **string**, mà lại là **array** thì sao ? Vậy thì có phải ta đã bypass được khối **if** trong hàm **kiemTra()**, do đó hàm **kiemTra()** sẽ luôn trả về **true**.

## The Bug

Có thể bạn đã biết, với POST Request ta có thể chuyển thông tin tới server thông qua JSON, và JSON còn cho phép ta truyền cả dữ liệu dạng **array**.

{% asset_img 9.png %}
Một gói tin bình thường với thamSo1, thamSo2, phepTinh đều được truyền dưới dạng **string** -> hợp lệ. Kết quả = 4.

{% asset_img 10.png %}
Một gói tin khác thường, thamSo1 lúc này được truyền dưới dạng **array** -> hợp lệ. Kết quả vẫn = 4.

Lý do vì sao **["2"] + 2 = 4** thì bạn tự thử nhé. Đó là vì cơ chế **Type Coercion** của JavaScript.

["2"] sẽ được hàm toString() convert thành **2** và **2+2=4**. Không tin bạn có thể thử.
{% asset_img 11.png %}

## Exploitation

Quay trở về với hàm xử lý POST Request.
{% asset_img 12.png %}

Lúc này ta đã kiểm chứng rằng có thể gửi **array** để bypass hàm **kiemTra()**. Vậy thì payload lúc này của mình sẽ như sau.

Với **thamSo2** mình sẽ để bằng **1**, giá trị nằm trong whitelist **0123456789**.

Với **phepTinh**, mình sẽ để bằng **+**, giá trị nằm trong whitelist **+-\*/**.

Với **thamSo1**, mình sẽ để bằng **["require('child_process').execSync('ls -la)"]**.

Ta biết **thamSo1** sau khi được toString() sẽ trở thành **require('child_process').execSync('ls -la')**.

Tóm lại, biến **bieuthuc** ở dòng 38 sẽ có dạng: **require('child_process').execSync('ls -la') + 1**

### Kết quả khi gửi payload trên

{% asset_img 13.png %}

Để ý thấy số 1 ở đoạn cuối phần response, chỗ **views\n1** không. Đó chính là 1 đến từ **thamSo2** đó.

Ở đây ta thấy có 1 file mang tên **secret.txt**. Ta thử dùng 'cat secret.txt' để đọc nội dung file này xem.
{% asset_img 14.png %}

> Flag thử thách 1: CBJS{dc6a2318ff561b711c08fa41ae95e752}

### Giải thích payload (TL;DR)

<details>
  <summary>Ấn để xem</summary>

Trong NodeJS, module **child_process** là một module có sẵn khi ta cài đặt NodeJS, nó cung cấp cho ta chức năng tạo 1 tiến trình con (child process).
<br>
<br>
Cái này kiến thức về hệ điều hành, 1 phần mềm khi chạy sẽ được tính là 1 tiến trình (1 process), cái process này sẽ gọi nhiều process khác và các process khác này là các process con.  
<br>
Giả sử, khi khởi động trò chơi League Of Legends, file thực thi để chạy game LoL sẽ là process cha.
<br>
<br>
Sau đó việc hiển thị champ sẽ dùng 1 process (tạm gọi là process hiển thị), tính toán sát thương sẽ sử dụng 1 process (tạm gọi là process tính toán). Process hiển thị và process tính toán sẽ là con của process cha.
<br>
<br>
Ta có 2 phương thức có thể sử dụng từ module này để RCE đó là **exec()** và **execSync()**. 2 phương thức này đều có tác dụng sinh ra 1 tiến trình để thực thi các câu lệnh được truyền vào bên trong nó.
<br>
<br>
Tuy nhiên do NodeJS chạy theo kiến trúc bất đồng bộ (Asynchronous). Nghĩa là NodeJS sẽ ưu tiên thực hiện các process khác nhẹ hơn rồi mới thực hiện các process nặng.
<br>
<br>
Do đó nếu ta truyền payload dạng **require('child_process').exec('ls -la')** thì process sinh ra sẽ nặng hơn và được thực thi sau. Việc này đồng nghĩa NodeJS sẽ tạm thời không thực thi nó và coi payload này chỉ là 1 object thông thường.
<br>
<br>
Vậy nên kết quả khi truyền payload **require('child_process').exec('ls -la')** sẽ là: "[object Object]1".
<br>
<br>
Để khắc phục, ta dùng **execSync()**. Lúc này 1 cờ synchronous được sinh ra để báo hiệu rằng NodeJS phải thực thi process này trước, sau khi thực thi xong mới tiếp tục đến các process khác.
<br>
<br>
Do đó khi dùng **require('child_process').execSync('ls -la')** thì process này sẽ được thực thi trước và với **ls -la** thì nó sẽ in ra các directory và file ở thư mục hiện tại. Sau đó mới thực thi đến đoạn **+ 1** phía sau.
<br>
<br>

- Đọc thêm về kiến trúc của NodeJS:
https://www.codehub.com.vn/NodeJS-%E2%80%93-Hieu-Asynchronous-Event-Driven-Nonblocking-I-O
</details>

# Challenge 2

## Goal: RCE

Link thử thách 2:
http://javascript-workshop.cyberjutsu-lab.tech:8001/

Về cơ bản thử thách 2 giống với thử thách 1, nhưng có 1 vài phần thay đổi

### Source code tại client

{% asset_img 15.png %}

Dòng 11, đổi route từ "/" sang "/calc".

Dòng 12, hàm **tinh()** đã đổi giao thức gửi dữ liệu từ POST sang GET.
{% asset_img 16.png %}

3 dữ liệu thamSo1, thamSo2, phepTinh được gửi qua GET Param.

### Source code tại server

{% asset_img 17.png %}

Tại file **app.js**, có thêm dòng 11 và 14 để khai báo module xử lý các request tới "/calc"

{% asset_img 18.png %}

Ta thấy module **calcRouter** không thay đổi gì nhiều.

Tại dòng 21 thay vì nhận dữ liệu từ **req.body** như thử thách 1 thì nay nhận dữ liệu từ **req.query**.

Đến đây thì ta không thể sử dụng cách gửi dữ liệu dưới dạng **array** thông qua body của POST Request được. Vì đây là GET Request mà.

## The Bug

Tuy nhiên thì ta có 1 điểm chung giữa PHP và NodeJS. Cái tuy nhiên này rất là ...

Đó là vì 1 lý do nào đó mà các dev NodeJS cũng cho phép ta có thể truyền array thông qua GET param.

{% asset_img 19.png %}

Giả sử nếu ở url bạn truyền **?thamSo1=1** thì kết quả nhận về qua dòng trên sẽ là:

```javascript
const thamSo1 = 1;
```

**thamSo1** được lưu dưới dạng là **number**

Tuy nhiên nếu bạn truyền **?thamSo1=1&thamSo1=3** thì kết quả nhận về sẽ là:

```javascript
const thamSo1 = [1, 3];
```

**thamSo1** được lưu dưới dạng là **array**

Việc truyền **thamSo1** khiến nó trở thành **array** là 1 dạng attack được gọi dưới cái tên **HTTP Parameter Pollution**.

- Về HTTP Paramater Pollution: https://www.youtube.com/watch?v=QVZBl8yxVX0

## Exploitation

Vậy thì mình sẽ truyền payload qua GET Param như sau: **/calc?thamSo1=1&thamSo1=require('child_process').execSync('ls+-la')&phepTinh=%2B&thamSo2=1**

Do truyền qua GET Param nên phải encode các ký tự khi truyền. Khoảng trắng giữa 'ls -la' phải thay bằng dấu **+**, dấu **+** ở phepTinh sẽ thay bằng **%2B**.

Tóm lại, biến **bieuthuc** sẽ có dạng: **1,require('child_process').execSync('ls -la') + 1**

### Kết quả khi gửi payload trên

{% asset_img 20.png %}

Ở đây ta thấy có 1 file mang tên **secret.txt**. Ta thử dùng 'cat secret.txt' để đọc nội dung file này.
{% asset_img 21.png %}

> Flag thử thách 2: CBJS{130e35d9d4b850aa8d720e5896975cc5}

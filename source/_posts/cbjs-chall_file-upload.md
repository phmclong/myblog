---
title: CBJS Challenge - FILE UPLOAD WORKSHOP 📁 (Write up)
date: 2022-05-14 02:21:02
tags: [PHP Security, Security, CTF, File Upload Vulnerability]
categories:
  - PHP 
---

Thử thách lần này là về lỗ hổng File Upload, được xây dựng bởi team CyberJutsu, nó bao gồm tất cả 9 levels mà theo mình thấy thì được sắp xếp từ dễ cho đến khó, ban đầu thì đơn giản nhưng càng về sau thì bạn càng phải xâu chuỗi những kiến thức mà bạn có được thì mới giải được nó.

Để nắm được sơ qua khái niệm về lỗ hổng File Upload thì team CyberJutsu đã làm 2 video giới thiệu về lỗ hổng này:

* Video 1: https://www.youtube.com/watch?v=ttj7\_uL4xPA
    
* Video 2: https://www.youtube.com/watch?v=OLp10F6DLR4
    

Không lan man nữa, ta đi đến link của thử thách: http://file-workshop.cyberjutsu-lab.tech:6001/

**RCE** hay còn gọi là Remote Code/Command Excution, từ ngay cái tên của nó đã cho chúng ta cơ bản về khái niệm RCE là gì, đó là "Thực thi code/command từ xa". Vậy thì chúng ta phải tìm mọi cách để có thể thực thi mã từ xa.

# Thử thách 1 (Đề bài: RCE)

Vừa vào, ta thấy trang cung cấp cho chức năng upload file. Mình sẽ thử upload 1 file mang tên **test.txt**, bên trong mình soạn 2 dòng "hello world" để xem sao.

{% asset_img 1.png %}

Ok vậy theo như dòng trên thì mình được biết là mình upload file thành công. Mình ấn thử vào đường link màu xanh thì thấy:

{% asset_img 2.png %}

Ồ, nó hiện ra dòng chữ "hello world" này.

Debug source:

{% asset_img 3.png %}

Ta thấy 2 dòng này không có đoạn filter nào. Do vậy chúng ta có thể upload 1 file **.php** có chứa mã để **RCE**.

Soạn và gửi 1 file mang tên **hack.php** với nội dung sau:

{% asset_img 4.png %}

Đi tới đường link chứa file **.hack.php** ta thấy:

{% asset_img 5.png %}

Ok vậy là chạy được hàm **phpinfo()** thành công, phiên bản **php** trên server là 7.3.30.

Ta nên test thử có **RCE** bằng hàm **phpinfo()** thay vì các **hàm nguy hiểm** như **system()**. Bởi rất có server chứa firewall, antivirus sẽ chặn không cho chạy các **hàm nhạy cảm** như vậy.

Mình spoil trước luôn là toàn bộ các thử thách lần này đều có thể chạy hàm **system()** mà ko bị chặn :V

Soạn và gửi file **hack.php** với nội dung sau để xem toàn bộ file và directory nằm ở thư mục root:

{% asset_img 6.png %}

Ồ, ta thấy chạy được **system()** và nó trả về toàn bộ file và directory nằm ở thư mục root này.

{% asset_img 7.png %}

Flag nằm trong file **71c99ec9c94-secret.txt**.

Dùng lệnh **cat** để đọc nội dung 1 file chỉ định:

{% asset_img 8.png %}

> Flag thử thách 1: CBJS{why-php-run-what?}

# Thử thách 2 (Đề bài: RCE)

Có thể thấy thử thách 2 đã filter tên file

{% asset_img 9.png %}

Dòng 2, hàm **explode()** đã giúp tách tên của file thành các phần khác nhau, các phần ngăn cách nhau bằng dấu "."

Kết quả trả về của hàm **explode()** là 1 array.

Nếu tên file là **hack.php** thì nó sẽ tách thành 1 array như sau array\["hack", "php"\], trong đó array\[0\] mang giá trị "hack", array\[1\] mang giá trị "php".

Dòng 3, Kiểm tra xem array\[1\] có trùng giá trị với "php" không, nếu trùng thì **Hack detected**

Cách bypass của mình là mình sẽ để tên file là **hack.abc.php**.

Dòng 2, đi qua hàm **explode()** thì nó sẽ thành array\["hack","abc","php"\] và array\[1\] có giá trị "abc" !== "php". Vậy ta bypass thành công.

Soạn nội dung file **hack.abc.php** như sau:

{% asset_img 10.png %}

Tiếp tục làm như thử thách 1 mình làm, kết quả trả về:

{% asset_img 11.png %}

Flag nằm trong file **1ad7e7cd851-secret.txt**

> Flag thử thách 2: CBJS{wr0nGlY\_ImplEm3nt}

Thử thách 2 cũng có thể giải giống thử thách 3 (cách giải bên dưới).

# Thử thách 3 (Đề bài: RCE)

Có thể thấy thử thách 3 đã thay đổi đoạn filter đuôi file bằng đoạn này:

{% asset_img 12.png %}

Lần này có thêm hàm **end()** bọc bên ngoài **explode()** nên lúc này thì cái giá trị mà biến **$extension** trả về sẽ luôn là giá trị cuối của cái array mà mình phân tích phía trên.

Nghĩa là bạn đặt tên file là **hack.abc.xyz.php** thì cái **$extension** sẽ luôn trả về là **php** và bị phát hiện là hack.

Tuy nhiên mình biết được 1 file **php** không nhất thiết phải là **.php** mà có thể là các đuôi khác như **.php2, .php3, .php4, .php5, .php6, .php7, .phps, .phps, .pht, .phtm, .phtml, .pgif, .shtml, .htaccess, .phar, .inc**.

Đoạn này thử vài đuôi tệp thì mình thấy có 2 đuôi hợp lệ là **.phar** và **.phtml** (thật ra bạn không muốn thử nhiều thì ấn sang debug ở thử thách 4 cũng có gợi ý đó :v)

Soạn file **hack.phar** với nội dung:

{% asset_img 13.png %}

Tiến hành làm như các bài trước, ta thấy:

{% asset_img 14.png %}

Flag nằm trong file **1ad7e7cd851-secret.txt**

> Flag thử thách 3: CBJS{bl4ck\_list?}

# Thử thách 4 (Đề bài: RCE)

Có thể thấy thử thách 4 đã thay đổi cách filter:

{% asset_img 15.png %}

Dòng 4, filter nốt 2 đuôi **.phar** và **.phtml** bằng cách sử dụng hàm **in\_array()**.

Hàm **in\_array()** nhận 2 tham số (tham số 1 là giá trị của một phần tử, tham số 2 là một mảng), hàm này sẽ duyệt xem giá trị của phần tử kia có nằm trong mảng kia ko.

Vậy thì nếu **$extension** có giá trị nằm trong 3 đuôi \["php", "phtml", "phar"\] thì đều bị chặn.

Nhưng bài này lại cho ta đọc được cấu hình của Apache.

Vậy trong cấu hình Apache có một đoạn khá "hay ho", đó chính là đoạn này:

{% asset_img 16.png %}

Thoạt nhìn qua trông file này giống mấy file XML/HTML phải không ?

Dòng 1, Khai báo tag Directory kèm attribute **/var/www** là đường dẫn tới directory.

Nằm bên trong tag Directory là các đoạn cấu hình mà mình tạm gọi là các **luật lệ** mà directory đó phải thực hiện, các **luật lệ** đó là: Options Indexes FollowSymLinks, AllowOverride All, Require all granted

Chú ý đến đoạn **AllowOverride All**, đoạn này có nghĩa là ta có thể sử dụng file **.htaccess** nằm trong thư mục **/var/www** để ghi đè cấu hình của Apache.

* Về **Directory**: https://httpd.apache.org/docs/2.4/en/mod/core.html#directory
    
* Về **.htaccess**: https://httpd.apache.org/docs/2.2/en/howto/htaccess.html
    
* Về **AllowOverride**: https://httpd.apache.org/docs/2.4/fr/mod/core.html#allowoverride
    

Bạn có nhớ tại video 2 của CBJS thì để thực thi được các file **.php** mỗi khi có request tới thì apache phải sử dụng module **libapache2-mod-php**.

Để lấy ra module **libapache2-mod-php** và bảo nó thực thi file có đuôi **.php** thì tại file **apache2.conf** nằm ở đường dẫn **/etc/apache2/apache2.conf** thường sẽ có 2 dòng sau:

{% asset_img 17.png %}

**LoadModule** cho phép bạn thêm module **libapache2-mod-php**. **AddType** cho phép các file có đuôi **.php** ánh xạ với 1 loại MIMETYPE - MIMETYPE này chính là **application/x-httpd-php**.

Có nghĩa là bạn có thể cho phép 1 đuôi bất kì như **.abc** được ánh xạ như 1 file **php** bình thường.

* Về **LoadModule**: https://httpd.apache.org/docs/2.4/fr/mod/mod\_so.html#loadmodule
    
* Về **AddType**: https://httpd.apache.org/docs/2.4/fr/mod/mod\_mime.html#addtype
    

Ta biết: **.htaccess** cho phép ghi đè apache config, **AddType** chỉ định apache sẽ thực thi các file **.php**.

Vậy thì xâu chuỗi 2 thứ đó lại, ta có được 1 cách bypass, đó chính là sử dụng **.htaccess** để ghi đè cấu hình **AddType** của apache.

Mình sẽ gửi file **.htaccess** với nội dung sau để cho phép các file có đuôi **.abc** cũng được ánh xạ như 1 file **php** bình thường, do đó có thể thực thi được file đuôi **.abc** như 1 file **.php**:

{% asset_img 18.png %}

Mình sử dụng phần mềm Burp Suite để hỗ trợ gửi file **.htaccess**:

Đây là 1 gói tin khi mà mình gửi file **hack.php** với nội dung

{% asset_img 19.png %}

{% asset_img 20.png %}

Còn đây là 1 gói tin mà mình gửi file **.htaccess** với nội dung

{% asset_img 21.png %}

{% asset_img 22.png %}

Khi gửi gói tin chứa file **.htaccess** thì mình đã sửa 3 phần:

Dòng 16, sửa trường **filename** thành **.htaccess**

Dòng 17, sửa **Content-Type** thành **text/plain**

Dòng 19, mình đổi nội dung file

Sau khi gửi gói tin chứa file **.htaccess** thì response nhận được là:

{% asset_img 23.png %}

Vậy là mình đã thành công gửi file **.htaccess**. Vậy thì giờ để kiểm chứng, mình sẽ soạn 1 file **hack.abc** với nội dung bên dưới để gửi lên server

{% asset_img 24.png %}

Response nhận được là:

{% asset_img 25.png %}

Thành công gửi file **hack.abc**, mình truy cập theo đường dẫn tới file **hack.abc** và thấy:

{% asset_img 26.png %}

Flag nằm trong file **fead248f338-secret.txt**:

> Flag thử thách 4: CBJS{so\_magic\_I\_wondeR\_what\_about\_other\_system?}

# Thử thách 5 (Đề bài: RCE)

Tiếp tục thay đổi cách filter:

{% asset_img 27.png %}

Bài 5 ko cho ta xem file cấu hình apache nữa, nếu như bài 4 ta có thể bypass bằng cách lợi dụng tệp **.htaccess** để gửi lên 1 file tuy có đuôi khác nhưng MIMETYPE của nó vẫn có thể được thực thi như 1 file php.

Ở bài này lọc luôn MIMETYPE bằng hàm **in\_array()**, lúc này nếu như MIMETYPE không nằm trong 3 giá trị \["image/jpeg", "image/png", "image/gif"\] thì sẽ bị phát hiện hack.

Mình thấy bài này bypass còn dễ hơn bài trước, mình vẫn sẽ gửi 1 file **hack.php** nhưng mình sẽ đổi MIMETYPE của nó thành 1 trong 3 giá trị bên trên. Trông request nó sẽ như này:

{% asset_img 28.png %}

Dòng 17 mình sửa **Content-Type** thành **image/png**. Ấn gửi request và response trả về là:

{% asset_img 29.png %}

Đơn giản phải không? Truy cập theo đường dẫn ta thấy:

{% asset_img 30.png %}

Flag nằm trong file **fead248f338-secret.txt**:

> Flag thử thách 5: CBJS{why\_you\_check\_with\_useR\_input}

# Thử thách 6 (Đề bài: RCE)

Lúc vào thử thách 6, bạn có thể thấy dòng chữ *I checked the wrong way, I've just fixed it, hope I dont have bug anymore* không?

Liệu bài này đã check đúng cách chưa, cùng xem đoạn code đã được thay đổi:

{% asset_img 31.png %}

Dòng 1, hàm **finfo\_open()** với tham số **FILEINFO\_MIME\_TYPE** để lấy ra **magic\_database**.

> MIME hay Multi-purpose Internet Mail Extensions. MIMETYPE tạo thành một cách tiêu chuẩn để phân loại các loại tệp trên Internet. Các chương trình Internet như máy chủ Web và trình duyệt đều có danh sách các MIMETYPE để chúng có thể chuyển các tệp cùng loại theo cùng một cách, bất kể chúng đang làm việc trong hệ điều hành nào.

Dòng 2, hàm **finfo\_file()** được dùng để kiểm tra **MIMETYPE** của file vừa được upload. Việc kiểm tra này được thực hiện bằng cách so sánh **file signature (hay còn gọi là chữ ký đầu tệp** của file vừa được upload với **file signature** nằm trong **magic\_database**.

Dòng 3 và 4, ta thấy chỉ có 3 dạng MIMETYPE được chấp nhận là "image/jpeg", "image/png", "image/gif".

Hàm **finfo\_file()** chỉ check MIMETYPE bằng các ký tự đầu tệp, cho nên các ký tự phía sau sẽ không được check. Từ đó ta có thể thêm code của mình đằng sau để bypass cơ chế check này.

Mình dùng tool **Exiftool** để tạo ra 1 file có ký tự đầu tệp giống các file **.jpg** nhưng các ký tự sau chứa code của mình.

{% asset_img 32.png %}

Mình tạo 1 file **hack.php** với nội dung bằng câu lệnh:

{% asset_img 33.png %}

Tiến hành gửi file **hack.php**

{% asset_img 34.png %}

Gửi thành công, đi tới đường dẫn chứa file ta thấy:

{% asset_img 35.png %}

Flag nằm trong file **414ed63690-secret.txt**:

{% asset_img 36.png %}

> Flag thử thách 6: CBJS{ch3ck\_mag1c\_bite\_iz\_tragic}

# Thử thách 7 (Đề bài: RCE)

Truy cập vào thư thách 7, ta thấy dòng chữ *CHANGELOG: From this challenge onwards, we have configured apache securely, you can read the config if you like:*. Có vẻ như bài này cấu hình apache đã an toàn.

## Đoạn này mình giải thích vì sao cấu hình apache ở bài này an toàn. Bạn nào ko thích đọc thì kéo thẳng xuống đoạn hack

Đọc thử file cấu hình apache trước.

Ta thấy có 2 đoạn config đáng chủ ý, đó là:

```plaintext
<Directory /var/www/>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>
```

và

```plaintext
<Directory "/usr/upload/">
        AllowOverride None
        Require all granted
        <FilesMatch ".*">
                SetHandler None
        </FilesMatch>
        Header set Content-Type application/octet-stream
        <FilesMatch ".+\.jpg$">
                Header set Content-Type image/jpeg
        </FilesMatch>
        <FilesMatch ".+\.png$">
                Header set Content-Type image/png
        </FilesMatch>
        <FilesMatch ".+\.(html|txt|php)">
                Header set Content-Type text/plain
        </FilesMatch>
</Directory>
```

Dòng **AllowOverride** đã trở về **None**, vậy ta loại trừ đi khả năng có thể sử dụng cách ghi đè cấu hình bằng **.htaccess**.

Bên trái là source code thử thách 6, bên phải là thử thách 7

{% asset_img 37.png %}

Đoạn mã PHP đã được thay đổi

{% asset_img 38.png %}

Đoạn mã HTML đã được thay đổi

Trước tiên nói đến phần mã PHP đã được thay đổi, có các phần đáng chú ý như đoạn code khai báo thêm 2 biến là **$cmd** và **$debug** tại dòng 13 và dòng 16, đoạn kiểm tra nằm trong khối **try..catch** cũng đã được thay đổi.

Tạm gọi đây là đoạn code mang tên "thư mục upload file 1"

```php
 if (!isset($_SESSION['dir'])) {
      $_SESSION['dir'] = '/usr/upload/' . session_id();
 }
$dir = $_SESSION['dir'];
$newFile = $dir . "/" . $_FILES["file"]["name"];
move_uploaded_file($_FILES["file"]["tmp_name"], $newFile);
```

Đoạn "thư mục upload file 1" ra ngay trên mô tả cách mà file mới được lưu, lúc này nó sẽ được lưu vào thư mục **/usr/upload/tên\_session\_id/tên\_file**.

Tạm gọi đây là đoạn code mang tên "thư mục upload file 2"

```php
$user_dir = substr($dir, 5);
$success = 'Successfully uploaded and unzip files into ' . $user_dir . '/' . $_FILES["file"]["name"];
```

Đoạn "thư mục upload file 2" này nhằm mục đích in ra cho người dùng thông báo về nơi lưu trữ file đã được upload. Bạn thấy như mình giải thích thì file được upload sẽ được lưu vào **/usr/upload/tên\_session\_id/tên\_file**, tuy nhiên trong file **000-default.conf** có ghi:

```plaintext
# CHANGELOG: if request to /upload/* then serve /usr/upload/*
Alias "/upload/" "/usr/upload/"
```

nghĩa là toàn bộ các request tới **/upload** sẽ lấy ra các file trong thư mục **/usr/upload** để đưa lên cho bạn xem.

Vậy nên thông dòng thông báo ở "thư mục upload file 2" sử dụng hàm **substr()** nhằm cắt phần **/usr/** đi và in ra thông báo nơi chứa thư mục là bắt nguồn từ **/upload/tên\_session\_id/tên\_file**.

Tuy nhiên file thật vẫn năm trong **/usr/upload/tên\_session\_id/tên\_file**.

Chỗ mình giải thích kia chỉ là phần mở rộng để bạn hiểu thêm về code đang làm gì.

Vì đa phần các bạn sẽ nghĩ theo hướng vẫn có thể upload file **.php** chứa mã cho phép RCE như thử thách 1.

Nhưng hãy nhìn lại đoạn cấu hình apache đã được thêm như sau:

```plaintext
<Directory "/usr/upload/">
        AllowOverride None
        Require all granted
        <FilesMatch ".*">
                SetHandler None
        </FilesMatch>
        Header set Content-Type application/octet-stream
        <FilesMatch ".+\.jpg$">
                Header set Content-Type image/jpeg
        </FilesMatch>
        <FilesMatch ".+\.png$">
                Header set Content-Type image/png
        </FilesMatch>
        <FilesMatch ".+\.(html|txt|php)">
                Header set Content-Type text/plain
        </FilesMatch>
</Directory>
```

Riêng dòng này cho ta thấy, mọi request tới file đều sẽ không được thực thi:

```plaintext
<FilesMatch ".*">
       SetHandler None
</FilesMatch>
```

Muốn tải lên file **.htaccess** để ghi đè thì đã có dòng này chặn:

```plaintext
AllowOverride None
```

## Hack

{% asset_img 39.png %}

Dòng 26 là nơi mà một **unsafe method** là hàm **shell\_exec()** được gọi.

Tham số mà hàm **shell\_exec()** nhận lại đến từ một **untrusted data** là biến **$cmd**. Truy về nguồn gốc tạo nên biến **$cmd** ta thấy nó tạo từ biến **$newFile** ở dòng 21, tại đây biến **$\_FILES\["file"\]\["name"\]** chính là **user input** hay một **unstrusted data**

Mình sẽ truyền giá trị **;sleep 5;** cho biến **$\_FILES\["file"\]\["name"\]** để test 5 giây sau server có trả về response không.

{% asset_img 40.png %}

Kết quả là sau 5 giây server mới trả về response, thành công **RCE** .Vậy mình sẽ tạo payload như sau:

{% asset_img 41.png %}

Nói qua 1 một chút về đoạn payload thì mình sử dụng dấu **;** để tạo thành nhiều command nối liên tục trong linux.

Vì thư mục mà mình gửi request tới là **/var/www/html** nên mình sử dụng lệnh **cd ..** 3 lần để trở về thư mục root, sau đó dùng lệnh **ls - la** để hiển thị các file và directory.

Dòng 26, kết quả chạy của hàm **shell\_exec()** được lưu vào biến **$debug**.

Dòng 81, **echo** cho phép in ra kết quả của biến **$debug**.

Ta thấy response trả về là toàn bộ file và directory của thư mục root (cảm ơn biến **$debug**):

{% asset_img 42.png %}

Đổi payload thành **;cd ..;cd ..;cd ..;cat cf2f5cab2-secret.txt;** để đọc nội dung file **cf2f5cab2-secret.txt**, ta được:

{% asset_img 43.png %}

> Flag thử thách 7: CBJS{w0w\_s0\_buggy\_filename}

# Thử thách 8 (Đề bài: đọc file /etc/passwd)

Debug source:

{% asset_img 44.png %}

Dòng 6, biến **$game** có giá trị là biến **$GET\['game'\]**, như vậy **$game** là 1 **untrusted data**.

Dòng 27, chứa biểu thức **include** cho phép evaluates một file được chỉ định, như vậy **include** là 1 **unsafe method**.

Kết hợp 2 thứ này lại cho phép ta evaluates một file bất kì trên hệ thống.

Đề bài bảo ta cần đọc file **/etc/passwd**. Ta kết hợp 1 loại attack mang tên **Path Traversal** - loại tấn công cho phép ta di chuyển qua lại giữa các thư mục trên hệ thống.

Thư mục của file hiện tại nằm ở **/var/www/html/views**, vậy để tới được **/etc/passwd** thì ta dùng payload sau: **/../../../../etc/passwd**

Thành công evaluates được file **/etc/passwd**

{% asset_img 45.png %}

Việc đọc được file vừa xong được gọi là **Local File Inclusion** - 1 loại attack mà hacker đánh lừa ứng dụng web để có thể đọc và thực thi một file bất kì trên hệ thống.

> Flag thử thách 8: CBJS{baby\_LFI}

# Thử thách 9 (Đề bài: RCE)

Vẫn là một cái game như bài 8, nhưng có thêm phần Hall Of Fame (ghi danh) và Profile (upload avatar).

Trong phần **/game.php** vẫn dính lỗi LFI tương tự thử thách 8, vậy payload của mình như sau: **/game.php?game=/../../../../etc/passwd**

{% asset_img 46.png %}

> Flag thử thách 9: CBJS{LFI+FileUpload=Bomb}

Vì đề bài là RCE nên đọc được file **/etc/passwd** chưa phải kết thúc, tác giả còn để lại 1 đường link để tham khảo thêm về lỗ hổng này **Please read more on this: https://book.hacktricks.xyz/pentesting-web/file-inclusion**

Từ cái flag ta có thể thấy tác giả đã gợi ý về việc kết hợp **LFI** và **File Upload**.

Ở đây ý tưởng của mình là upload file chứa mã để RCE nhờ chức năng upload avatar ở phần **Profile**. Sau đó sử dụng **LFI** để evaluates file này.

Đầu tiên, soạn và upload file với nội dung:

{% asset_img 47.png %}

Đoạn code này cho ta biết file của chúng ta luôn được lưu tại **/usr/upload/tên\_session/** và với cái tên cố định là **avatar.jpg**. Giả sử **tên\_session** của mình là **sheon** thì nó luôn được lưu tại **/usr/upload/sheon/avatar.jpg**

{% asset_img 48.png %}

Sau đó, sử dụng **LFI** để evaluates file vừa upload lên. Sử dụng payload sau: **/game.php?game=/../../../../usr/upload/sheon/avatar.jpg**

Thành công evaluates file **usr/upload/sheon/avatar.jpg**

{% asset_img 49.png %}

Response cho thấy **RCE** thành công. Kết thúc chuỗi thử thách.

Mình cũng chưa ngồi nghịch thử phần để đưa tên lên Hall of fame nhưng chắc lúc nào có thời gian mình sẽ thử.

Bài cũng dài rồi, mình sẽ kết thúc tại đây. Lời cuối mình muốn gửi là cảm ơn team CyberJutsu đã tạo ra 1 chuỗi thử thách rất hay. Mình từ một người chưa biết tý gì về lỗ hổng File Upload mà sau chuỗi thử thách đã học được rất nhiều khía cạnh về lỗ hổng này. Cảm ơn các thành viên trong team đã lắng nghe phản hồi của mình về 1 phần out-of-scope ở thử thách 7 (dù đã khá muộn, gần 12h đêm).

Update một chút về cái Hall of fame, các bạn có thể thấy tên **sheon** là của mình. Thật ra cái tài khoản tên **testasasas** cũng là mình nốt @@. Làm như nào thì ko bật mí nha :v

{% asset_img 50.png %}

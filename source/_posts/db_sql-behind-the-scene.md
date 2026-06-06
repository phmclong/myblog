---
title: Phân tích Database - SQL thật sự lưu dữ liệu như thế nào ?
date: 2025-05-23 16:00:00
tags: [Database, Technology Curiousity]
categories:
  - Database
  - SQL
---

# I. Lời nói đầu

Đợt này mình rảnh rảnh đọc sách System Design Interview của anh Alex Xu. Ngay chapter 1 đã giới thiệu về rất nhiều loại Database, từ **relational database** cho tới **non-relational database**. Mình cũng từng dùng được 1 vài database nhưng thật sự ko hiểu nổi cơ chế đằng sau như thế nào.
Cụ thể thì mình luôn tự hỏi: "Thật sự lưu dữ liệu dạng **bảng (table)** trong SQL nó là cái quái gì ? Dữ liệu được lưu vào đâu, máy tính sẽ đọc như thế nào để có thể lưu và truy vấn nó ra sao ?"
Cũng nhờ thời này AI rất mạnh, mình đã có thể hiểu được bản chất của các cơ chế này. Mình tính viết thành 1 series tìm hiểu và phân tích về cách hoạt động của các dạng database. Trước tiên thì trong bài này, mình sẽ ghi lại những gì mình tìm hiểu được về **Relational Database**, hay còn gọi là **SQL**.

# II. Cơ chế đằng sau Relational Database

Bản chất là: database không “lưu bảng” giống như file Excel, mà nó lưu dữ liệu thành các page/block nhị phân trên disk. “Bảng”, “dòng”, “cột” chỉ là mô hình logic để người dùng nhìn và query bằng SQL.

Ta có thể phân tách thành 3 layer

## 2.1. Layer logic: table, row, column

Khi ta tạo bảng:

```sql
CREATE TABLE users (
  id INT,
  name VARCHAR(100),
  age INT
);
```

Ta nhìn thấy dữ liệu dạng:
| id | name | age |
| -: | ---- | --: |
| 1 | Long | 25 |
| 2 | Nam | 30 |

Đây là cách database trình bày dữ liệu cho con người. Nhưng trên ổ đĩa, nó không lưu y nguyên thành bảng đẹp như vậy.

# 1. Table không phải là một “file bảng” đơn giản

Khi bạn tạo bảng:

```sql
CREATE TABLE users (
  id INT,
  name VARCHAR(100),
  age INT
);
```

Bạn nhìn thấy:

|  id | name | age |
| --: | ---- | --: |
|   1 | Long |  25 |
|   2 | Nam  |  30 |

Nhưng database engine không lưu kiểu:

```text
id,name,age
1,Long,25
2,Nam,30
```

Trừ khi đó là file CSV. Còn database như MySQL InnoDB, Oracle, PostgreSQL… thường lưu theo cấu trúc nhị phân có tổ chức.

Có thể hình dung:

```text
Table users
  ↓
Datafile / tablespace file
  ↓
Page / block
  ↓
Record / row
  ↓
Column values dưới dạng bytes
```

---

# 2. Datafile là gì?

Database cần một nơi vật lý để lưu dữ liệu trên ổ cứng/SSD.

Với MySQL InnoDB, nếu dùng `innodb_file_per_table`, mỗi bảng có thể có file riêng:

```text
users.ibd
orders.ibd
products.ibd
```

Với Oracle, dữ liệu nằm trong các datafile:

```text
users01.dbf
system01.dbf
app_data01.dbf
```

Nhưng datafile này **không phải text file**. Bạn mở bằng Notepad sẽ không đọc được bình thường, vì bên trong là dữ liệu nhị phân.

Ví dụ tưởng tượng file `users.ibd`:

```text
users.ibd
+------------------------------------------------+
| Page 0 | Page 1 | Page 2 | Page 3 | Page 4 ... |
+------------------------------------------------+
```

Database không xử lý từng byte rời rạc một cách tùy tiện. Nó chia file thành các đơn vị lớn hơn gọi là **page** hoặc **block**.

---

# 3. Page/block là gì?

**Page/block là đơn vị đọc/ghi cơ bản của database.**

Ví dụ MySQL InnoDB thường dùng page 16 KB.

Nghĩa là khi cần đọc một dòng dữ liệu, database thường không chỉ đọc đúng vài chục byte của dòng đó. Nó đọc cả page chứa dòng đó vào memory.

Ví dụ:

```text
Page size = 16 KB

Page 100
+------------------------------------------------+
| Page header                                    |
| Record 1                                      |
| Record 2                                      |
| Record 3                                      |
| Free space                                    |
| Page directory / slot info                    |
| Page trailer                                  |
+------------------------------------------------+
```

Một page không chỉ chứa data row. Nó còn chứa metadata để database quản lý page đó.

Một page có thể gồm:

```text
Page
 ├── Header: thông tin quản lý page
 ├── Records: các row thật
 ├── Free space: vùng trống để insert/update thêm
 ├── Directory/slot: vị trí các record trong page
 └── Trailer/checksum: kiểm tra lỗi, tính toàn vẹn
```

Nói dễ hiểu: **page giống như một trang trong cuốn sổ**, mỗi trang chứa nhiều dòng ghi chép, nhưng trên trang đó còn có số trang, đánh dấu, phần trống, thông tin kiểm tra.

---

# 4. Vì sao phải chia thành page/block?

Vì ổ đĩa và memory hoạt động hiệu quả hơn khi đọc/ghi theo block lớn.

Nếu mỗi lần query database phải đọc từng byte nhỏ lẻ thì rất chậm.

Thay vào đó:

```text
Disk → đọc một page 16 KB → đưa vào RAM → xử lý nhiều record trong page đó
```

Ví dụ bạn query:

```sql
SELECT * FROM users WHERE id = 2;
```

Nếu dòng `id = 2` nằm trong Page 100, database sẽ đọc Page 100 vào memory.

```text
Disk
 └── Page 100
      ├── id=1
      ├── id=2
      └── id=3
```

Dù bạn chỉ cần `id=2`, database vẫn thường đọc cả page chứa nó.

Đây là lý do database rất quan tâm đến:

```text
Page size
Buffer pool/cache
Index
Data locality
Fragmentation
```

---

# 5. Record/row nằm trong page như thế nào?

Giả sử page có 16 KB.

Một record nhỏ có thể chỉ vài chục bytes.

Ví dụ bảng:

```sql
CREATE TABLE users (
  id INT,
  name VARCHAR(100),
  age INT
);
```

Dòng:

```text
id = 1
name = 'Long'
age = 25
```

Có thể được lưu đại khái như sau:

```text
Record
+----------------+------------+----------------+-------------+------------+
| Record Header  | id bytes   | name length    | name bytes  | age bytes  |
+----------------+------------+----------------+-------------+------------+
```

Tức là:

```text
[header][id][name_length][name_data][age]
```

Trong đó:

```text
header      → metadata của record
id          → giá trị id đã encode thành bytes
name_length → độ dài chuỗi name
name_data   → nội dung chữ Long
age         → giá trị age đã encode thành bytes
```

---

# 6. Record header chứa gì?

Record header là phần database dùng để quản lý row.

Nó có thể chứa các thông tin kiểu như:

```text
- Record này còn sống hay đã bị đánh dấu xóa?
- Record này dài bao nhiêu?
- Có NULL column không?
- Có field nào là variable-length không?
- Version/transaction information
- Con trỏ/liên kết tới record khác
```

Ví dụ rất đơn giản:

```text
Record header
 ├── delete flag
 ├── record length
 ├── null bitmap
 ├── variable column offset
 └── transaction metadata
```

Bạn có thể hiểu: **row không chỉ gồm dữ liệu bạn nhập, mà còn có dữ liệu phụ để database quản lý giao dịch, xóa, update, rollback, concurrency.**

Ví dụ bạn thấy:

```text
id=1, name=Long, age=25
```

Nhưng database có thể lưu thêm:

```text
row này được tạo bởi transaction nào
row này đã bị xóa logic chưa
row này có version cũ không
field nào đang NULL
```

## 2.2. Physic layer: file, page/block, record

Database lưu dữ liệu trong các **file dữ liệu**.

Ví dụ:

MySQL InnoDB thường có:

```text
.ibd file
```

Oracle có:

```text
.dbf datafile
```

Bên trong các file này, dữ liệu được chia thành nhiều **page** hoặc **block**.

Ví dụ đơn giản:

```text
Data file
 ├── Page 1
 ├── Page 2
 ├── Page 3
 └── Page 4
```

Mỗi page/block có kích thước cố định.

Ví dụ phổ biến:

```text
MySQL InnoDB page: 16 KB
Oracle block: thường 8 KB, có thể cấu hình
```

Trong mỗi page/block sẽ chứa nhiều **record**, tức là nhiều dòng dữ liệu.

Ví dụ:

```text
Page 1
 ├── Record: id=1, name=Long, age=25
 ├── Record: id=2, name=Nam, age=30
 └── Record: id=3, name=Hoa, age=22
```

Nói ngắn gọn:

```text
Table
 → nhiều page/block
 → mỗi page/block chứa nhiều row/record
 → mỗi row chứa nhiều column value
```

---

## 3. Một dòng dữ liệu được lưu như thế nào?

Giả sử có dòng:

```text
id = 1
name = 'Long'
age = 25
```

Database sẽ encode nó thành dạng nhị phân.

Ví dụ rất đơn giản hóa:

```text
[header][id][name_length][name_data][age]
```

Có thể hình dung:

```text
Row record:
 ├── Header metadata
 ├── id: 00000001
 ├── name length: 4
 ├── name: L o n g
 └── age: 00011001
```

Các kiểu dữ liệu khác nhau sẽ được lưu khác nhau:

```text
INT       → số nhị phân cố định, ví dụ 4 bytes
BIGINT    → 8 bytes
CHAR      → chuỗi độ dài cố định
VARCHAR   → độ dài + nội dung chuỗi
DATE      → dạng số/nhị phân biểu diễn ngày
DECIMAL   → dạng số chính xác, không giống FLOAT
BLOB/CLOB → dữ liệu lớn, có thể lưu riêng ngoài row
```

Ví dụ:

```sql
INT
```

không lưu thành ký tự `"123"` như text, mà lưu thành số nhị phân.

Còn:

```sql
VARCHAR('Long')
```

thường lưu kiểu:

```text
độ dài = 4
dữ liệu = Long
```

---

# Ví dụ trực quan

Bạn có bảng:

```text
users
```

Bên ngoài bạn nhìn thấy:

```text
+----+------+-----+
| id | name | age |
+----+------+-----+
| 1  | Long | 25  |
| 2  | Nam  | 30  |
+----+------+-----+
```

Nhưng bên trong disk có thể giống thế này:

```text
File: users.ibd

Page 100
 ├── Page header
 ├── Record header + id=1 + name='Long' + age=25
 ├── Record header + id=2 + name='Nam'  + age=30
 ├── Free space
 └── Page trailer
```

Database engine sẽ biết:

```text
Bảng users nằm ở những page nào
Record trong page nằm ở offset nào
Column id bắt đầu ở đâu
Column name dài bao nhiêu byte
Column age nằm ở đâu
```

---

# Vậy index thì sao?

Nếu không có index, muốn tìm:

```sql
SELECT * FROM users WHERE id = 2;
```

Database có thể phải đọc nhiều page, nhiều record để tìm.

Index sinh ra để tránh việc này.

Trong MySQL InnoDB, index thường dùng cấu trúc **B+Tree**.

Có thể hiểu như mục lục sách:

```text
Index on id

        [10, 20, 30]
       /     |      \
   page A  page B  page C
```

Khi tìm `id = 2`, database không cần đọc toàn bộ bảng, mà đi qua cây index để tìm đúng page chứa record.

Với InnoDB, nếu bảng có **primary key**, dữ liệu của bảng được lưu theo **clustered index**. Nghĩa là:

```text
Primary key index chứa luôn dữ liệu row
```

Nói cách khác, trong InnoDB:

```text
Table data được tổ chức theo B+Tree của primary key
```

Không phải bảng nằm riêng, index nằm riêng hoàn toàn như nhiều người tưởng.

---

# MySQL và Oracle có giống nhau không?

Về bản chất thì giống:

```text
SQL table
 → row/column logic
 → datafile trên disk
 → page/block
 → record nhị phân
 → index để tìm nhanh
```

Nhưng cách triển khai khác nhau.

## MySQL InnoDB

Thường có:

```text
Tablespace
Data page 16 KB
Clustered index theo primary key
Undo log
Redo log
Buffer pool
```

Dữ liệu table trong InnoDB thường nằm trong B+Tree của primary key.

Ví dụ:

```text
users.ibd
 └── B+Tree primary key
      ├── leaf page chứa row thật
      └── internal page dẫn đường
```

## Oracle Database

Oracle tổ chức theo:

```text
Tablespace
Datafile
Segment
Extent
Block
Row
```

Có thể hình dung:

```text
Tablespace
 └── Datafile
      └── Segment của bảng USERS
           └── Extent
                └── Block
                     └── Row
```

Một bảng trong Oracle là một **segment**, segment gồm nhiều **extent**, extent gồm nhiều **block**, block chứa các row.

---

# Khi INSERT thì chuyện gì xảy ra?

Ví dụ:

```sql
INSERT INTO users VALUES (1, 'Long', 25);
```

Database sẽ làm đại khái:

```text
1. Parse SQL
2. Kiểm tra metadata bảng users
3. Tìm page/block còn trống
4. Encode row thành binary record
5. Ghi record vào page trong memory
6. Ghi log để đảm bảo crash recovery
7. Sau đó dữ liệu mới được flush xuống disk
```

Điểm quan trọng: database thường **không ghi thẳng từng row xuống disk ngay lập tức**.

Nó ghi vào memory trước, ví dụ:

```text
MySQL: Buffer Pool
Oracle: Database Buffer Cache
```

Sau đó mới flush xuống datafile.

Nhưng để đảm bảo mất điện không mất dữ liệu, database ghi log trước:

```text
MySQL InnoDB: redo log, undo log, binlog
Oracle: redo log, undo segment
```

---

# Một row có nằm liền nhau không?

Thường một row nhỏ sẽ nằm trong một page/block.

Nhưng nếu row quá lớn, ví dụ có:

```sql
TEXT
BLOB
CLOB
VARCHAR rất dài
```

thì database có thể lưu một phần ở ngoài page chính, còn trong row chỉ giữ con trỏ/tham chiếu.

Ví dụ:

```text
Record chính:
 ├── id = 1
 ├── name = Long
 └── avatar_blob_pointer → chỗ khác
```

Dữ liệu lớn:

```text
LOB page / external storage
 └── binary content của ảnh/file
```

---

# Tóm tắt cực ngắn

Database lưu bảng như sau:

```text
Table logic
  ↓
Rows và columns
  ↓
Encode thành binary records
  ↓
Đặt vào page/block
  ↓
Page/block nằm trong datafile
  ↓
Index giúp tìm page/row nhanh
  ↓
Log đảm bảo khôi phục khi lỗi
```

Nên bản chất không phải là:

```text
database lưu file Excel
```

mà là:

```text
database lưu các page nhị phân có cấu trúc,
trong đó chứa record, metadata, offset, free space, index và log.
```

Một câu dễ nhớ:

**Table là cách con người nhìn dữ liệu; page/block và record nhị phân mới là cách database thật sự lưu dữ liệu.**

Đúng rồi, đoạn này là **phần cốt lõi nhất** để hiểu database lưu dữ liệu thật sự như thế nào. Mình phân tích kỹ hơn theo hướng “từ bảng logic xuống bytes trên disk”.

---

---

# 7. INT được lưu như thế nào?

Khi bạn lưu:

```sql
id INT
```

và insert:

```sql
INSERT INTO users VALUES (1, 'Long', 25);
```

Giá trị `1` không được lưu thành ký tự `'1'`.

Nếu lưu dạng text, ký tự `'1'` có thể là:

```text
ASCII '1' = 0x31
```

Nhưng INT thường lưu dưới dạng binary number.

Ví dụ `1` trong 4 bytes:

```text
00000000 00000000 00000000 00000001
```

Hay dạng hex:

```text
00 00 00 01
```

Giá trị `25`:

```text
00000000 00000000 00000000 00011001
```

Dạng hex:

```text
00 00 00 19
```

Vậy dòng:

```text
id = 1
age = 25
```

không phải lưu kiểu:

```text
"1" và "25"
```

mà là số nhị phân để máy tính xử lý nhanh hơn.

---

# 8. VARCHAR được lưu như thế nào?

Với:

```sql
name VARCHAR(100)
```

và giá trị:

```text
Long
```

Database cần biết chuỗi này dài bao nhiêu, vì `VARCHAR` là độ dài biến đổi.

Nên nó thường lưu kiểu:

```text
[length][data]
```

Ví dụ:

```text
name = 'Long'
length = 4
data = L o n g
```

Có thể hình dung:

```text
04 4C 6F 6E 67
```

Trong đó:

```text
04          → độ dài chuỗi là 4 bytes
4C 6F 6E 67 → ký tự L o n g theo encoding
```

Nếu encoding là UTF-8:

```text
L = 4C
o = 6F
n = 6E
g = 67
```

Nhưng nếu chuỗi có tiếng Việt như:

```text
Long Phạm
```

thì không thể đơn giản tính “số ký tự = số byte”.

Ví dụ chữ:

```text
ạ
```

trong UTF-8 có thể chiếm nhiều hơn 1 byte.

Vì vậy `VARCHAR(100)` thường nghĩa là giới hạn theo số ký tự hoặc byte tùy database/charset/cấu hình, nhưng khi lưu xuống disk thì cuối cùng vẫn là **bytes**.

---

# 9. CHAR khác VARCHAR thế nào khi lưu?

Giả sử:

```sql
code CHAR(10)
name VARCHAR(10)
```

Nếu lưu:

```text
code = 'ABC'
name = 'ABC'
```

`CHAR(10)` có xu hướng lưu cố định độ dài, có thể padding thêm khoảng trắng:

```text
'A' 'B' 'C' ' ' ' ' ' ' ' ' ' ' ' ' ' '
```

Còn `VARCHAR(10)` lưu linh hoạt:

```text
length = 3
data = 'A' 'B' 'C'
```

So sánh dễ hiểu:

```text
CHAR(10)     → luôn dành chỗ cố định gần 10 ký tự
VARCHAR(10)  → dùng bao nhiêu lưu bấy nhiêu, kèm thông tin độ dài
```

Vì vậy `CHAR` hợp với dữ liệu có độ dài cố định, ví dụ:

```text
country_code CHAR(2) → VN, US, JP
status_code CHAR(1) → A, I, D
```

Còn `VARCHAR` hợp với tên, email, địa chỉ, mô tả ngắn.

---

# 10. NULL được lưu thế nào?

Giả sử bảng:

```sql
CREATE TABLE users (
  id INT,
  name VARCHAR(100),
  age INT
);
```

Nếu row:

```text
id = 1
name = NULL
age = 25
```

Database cần biết `name` không có giá trị.

Nó không nhất thiết lưu chữ `"NULL"`.

Thường nó dùng một vùng gọi là **NULL bitmap**.

Ví dụ:

```text
NULL bitmap:
id   = 0 → không null
name = 1 → null
age  = 0 → không null
```

Tức là:

```text
[header][null_bitmap][id][age]
```

Cột `name` có thể không cần lưu data thật vì nó đang NULL.

Điểm quan trọng:

```text
NULL không giống chuỗi rỗng ''
NULL không giống số 0
NULL nghĩa là không có giá trị / unknown
```

---

# 11. Fixed-length và variable-length columns

Các kiểu như:

```text
INT
BIGINT
DATE
FLOAT
DOUBLE
```

thường có độ dài khá cố định.

Ví dụ:

```text
INT    → 4 bytes
BIGINT → 8 bytes
```

Các kiểu như:

```text
VARCHAR
TEXT
BLOB
CLOB
```

có độ dài biến đổi.

Một record có cả 2 loại:

```text
Record:
 ├── Fixed-length area
 │    ├── id INT
 │    └── age INT
 └── Variable-length area
      └── name VARCHAR
```

Nhưng database thực tế có thể tổ chức phức tạp hơn, ví dụ dùng offset array để biết field biến đổi bắt đầu/kết thúc ở đâu.

Ví dụ:

```text
Record
 ├── Header
 ├── Null bitmap
 ├── Offset của field biến đổi
 ├── Fixed values
 └── Variable values
```

Với variable field, database cần biết:

```text
name bắt đầu ở byte nào?
name dài bao nhiêu?
field tiếp theo bắt đầu ở đâu?
```

---

# 12. Một page chứa nhiều record bằng cách nào?

Giả sử page 16 KB.

```text
Page 100, size 16 KB
+------------------------------------------------+
| Page header                                    |
| Record 1: id=1, name=Long, age=25              |
| Record 2: id=2, name=Nam, age=30               |
| Record 3: id=3, name=Hoa, age=22               |
| Free space                                     |
| Slot directory                                 |
+------------------------------------------------+
```

Database không chỉ “xếp dòng từ trên xuống” đơn giản. Nó thường có cơ chế quản lý vị trí record trong page.

Một mô hình phổ biến là:

```text
Page đầu: chứa record data
Page cuối: chứa slot directory / offset
Giữa page: free space
```

Hình dung:

```text
+------------------------------------------------+
| Page header                                    |
| Record A                                      |
| Record B                                      |
| Record C                                      |
|                Free space                      |
|                         Slot C offset          |
|                         Slot B offset          |
|                         Slot A offset          |
+------------------------------------------------+
```

Slot directory giúp database biết record nằm ở offset nào trong page.

Ví dụ:

```text
Slot 1 → record bắt đầu tại byte 120
Slot 2 → record bắt đầu tại byte 168
Slot 3 → record bắt đầu tại byte 220
```

Nhờ vậy khi record bị update, di chuyển, hoặc page bị reorganize, database vẫn quản lý được vị trí của từng row.

---

# 13. Khi UPDATE làm row dài hơn thì sao?

Ví dụ ban đầu:

```text
name = 'Long'
```

sau đó update:

```sql
UPDATE users SET name = 'Long Pham Nguyen Van A' WHERE id = 1;
```

Chuỗi mới dài hơn rất nhiều.

Nếu trong page còn đủ free space, database có thể mở rộng record trong cùng page.

Nếu không đủ, tùy engine, có thể:

```text
- chuyển record sang vị trí khác trong page
- split page
- lưu một phần ở overflow page
- tạo version row mới
- đánh dấu record cũ và ghi record mới
```

Với MVCC như InnoDB/Oracle, update không đơn giản là “đè trực tiếp giá trị cũ”. Database còn phải giữ thông tin để transaction khác có thể đọc version cũ nếu cần.

Ví dụ:

```text
Transaction A đang đọc name='Long'
Transaction B update name='Long Pham'
```

Database phải đảm bảo Transaction A vẫn có thể thấy dữ liệu cũ theo isolation level.

Vì vậy update thường liên quan đến:

```text
data page
undo/rollback information
redo log
row version
transaction id
```

---

# 14. BLOB/CLOB/TEXT lưu thế nào?

Với dữ liệu lớn như:

```text
ảnh
file PDF
nội dung text rất dài
video nhỏ
JSON lớn
```

Database thường không nhét toàn bộ vào row chính nếu quá lớn.

Thay vào đó:

```text
Row chính
 ├── id
 ├── name
 └── pointer/reference tới vùng lưu dữ liệu lớn
```

Ví dụ:

```text
Record trong page chính:
[id=1][name='Long'][avatar_pointer=LOB_PAGE_500]
```

Dữ liệu ảnh nằm ở nơi khác:

```text
LOB Page 500
 ├── binary chunk 1
 ├── binary chunk 2
 └── binary chunk 3
```

Vì nếu nhét BLOB lớn vào page chính, một row có thể chiếm hết cả page, làm giảm hiệu năng scan/index.

---

# 15. Metadata giúp database hiểu bytes đó là gì

Một câu hỏi hay là: nếu trên disk chỉ là bytes, làm sao database biết đoạn nào là `id`, đoạn nào là `name`, đoạn nào là `age`?

Câu trả lời là nhờ **data dictionary / system catalog / metadata**.

Khi bạn tạo table:

```sql
CREATE TABLE users (
  id INT,
  name VARCHAR(100),
  age INT
);
```

Database lưu metadata kiểu:

```text
Table users:
 ├── column 1: id, type INT, nullable?, length 4
 ├── column 2: name, type VARCHAR, max length 100
 ├── column 3: age, type INT, nullable?, length 4
 ├── primary key là gì
 ├── index nào đang tồn tại
 └── table nằm ở segment/tablespace nào
```

Khi đọc record bytes, database dựa vào metadata này để decode lại thành row logic.

Ví dụ bytes trong record:

```text
[header][00 00 00 01][04][4C 6F 6E 67][00 00 00 19]
```

Database biết:

```text
column 1 là INT 4 bytes → đọc ra id = 1
column 2 là VARCHAR → đọc length = 4, sau đó đọc 4 bytes → name = Long
column 3 là INT 4 bytes → đọc ra age = 25
```

---

# 16. Ví dụ gom lại một row hoàn chỉnh

Giả sử row:

```text
id = 1
name = 'Long'
age = 25
```

Một record đơn giản hóa có thể như này:

```text
+----------------+----------------+----------------+----------------+----------------+
| Record header  | Null bitmap    | id             | name length    | name data      | age |
+----------------+----------------+----------------+----------------+----------------+
```

Dạng minh họa:

```text
[HDR][000][00 00 00 01][04][4C 6F 6E 67][00 00 00 19]
```

Trong đó:

```text
HDR             → metadata record
000             → không cột nào NULL
00 00 00 01     → id = 1
04              → name dài 4 bytes
4C 6F 6E 67     → Long
00 00 00 19     → age = 25
```

Đây là minh họa đơn giản hóa, không phải layout chính xác tuyệt đối của MySQL hay Oracle, nhưng đúng về bản chất.

---

# 17. Page chứa row đó như thế nào?

Row trên sẽ nằm trong một page:

```text
Page 100
+------------------------------------------------+
| Page header                                    |
|                                                |
| Record 1: [HDR][id=1][name=Long][age=25]       |
| Record 2: [HDR][id=2][name=Nam][age=30]        |
| Record 3: [HDR][id=3][name=Hoa][age=22]        |
|                                                |
| Free space                                     |
|                                                |
| Slot directory                                 |
| Page trailer                                   |
+------------------------------------------------+
```

Khi query:

```sql
SELECT name FROM users WHERE id = 1;
```

Database sẽ:

```text
1. Dựa vào index hoặc scan để tìm page chứa id=1
2. Đọc page đó vào memory
3. Tìm record tương ứng trong page
4. Decode record theo metadata của bảng
5. Trả về column name = Long
```

---

# 18. Tóm lại bản chất đoạn này

Có thể nhớ theo chuỗi sau:

```text
Bảng users không được lưu như Excel.

Nó được lưu trong datafile.
Datafile được chia thành page/block.
Page/block chứa nhiều record.
Record chứa header + giá trị các column.
Column value được encode thành bytes theo kiểu dữ liệu.
Database dùng metadata để hiểu bytes đó là INT, VARCHAR, DATE...
```

Câu quan trọng nhất:

**Database lưu dữ liệu dạng bảng ở tầng logic, nhưng ở tầng vật lý nó lưu thành các record nhị phân nằm trong page/block của datafile.**

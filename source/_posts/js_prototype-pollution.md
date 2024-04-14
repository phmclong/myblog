---
title: JavaScript Security - Prototype Pollution Attack
date: 2022-02-13 17:18:07
tags: [Javascript Security, Security, Javascript Prototype Pollution]
categories:
  - Javascript 
---

# Lời nói đầu

**Prototype Pollution** không phải kĩ thuật dễ nhai dành cho người mới học.

Để hiểu kĩ thuật này cũng không quá khó, tuy nhiên bạn cần có 1 chút kiến thức sau: **JavaScript** ở mức trung, **OOP (Object-oriented Programming)** ở mức cơ bản, **Data Structure & Algorihm** ở mức cơ bản.

Bài này mình thấy sẽ hợp hơn với người đọc đã có các kiến thức mình nêu trên, nên nếu bạn chưa đủ những kiến thức đó có thể cảm thấy khó hiểu. Dẫu vậy mình sẽ cố gắng viết sao cho dễ hiểu nhất.

# Object-Oriented Programming

Ai nào từng học qua môn **Object-Oriented Programming** - **OOP** (hay ở Việt Nam còn gọi là Lập trình hướng đối tượng) thì chắc hẳn sẽ nghe đến khái niệm lớp **class** và **object**.

> Tạm hiểu **class** chính là khung, còn **object** là vật thể được tạo dựa vào cái khung đó. Hay còn có thể hiểu **object** kế thừa những gì mà **class** để lại cho nó, những gì nó kế thừa bao gồm **property** và **method**.

# Object-Oriented Programming trong JavaScript

Trong JavaScript, mình có thể khai báo **object** tên **car** như sau (cú pháp khai báo **object** như này được gọi là **Object literal**):

```javascript
const car = {
  color: "red",
  running: function () {
    console.log("Car is running");
  },
};
```

Nếu bạn là người từng học lập trình các ngôn ngữ như là **Java**, **C#** sẽ cảm thấy rất **lạ**.

Đúng, nó **lạ** bởi vì **object** này được khai báo mà không cần xác định **class** của nó. Nó vẫn có **property** là **color** và **method** là **running()** như mọi **object** bạn từng được học ở các ngôn ngữ khác.

Vậy đã bao giờ bạn thử:

```javascript
console.log(car.toString()); //return '[object Object]'
```

**car** thật sự có **method** tên là `toString()`. Vậy cái `toString()` này lấy từ đâu ?

Câu trả lời là do nó đã kế thừa **method** này từ `Object.prototype`.

> Trong **JavaScript**, ngoại trừ **undefined** thì toàn bộ các kiểu dữ liệu khác đều là **object**, điều đó có nghĩa là chúng đều có **property** và **method**. Có thể bạn không tin, nhưng các kiểu dữ liệu như **number**, **boolean** (các dữ liệu kiểu **primitive**) cũng có **property** và **method**.

> Nguyên nhân các **object kì lạ** như **number**, **boolean** có **property** và **method** là do chúng được kế thừa thông qua **Prototype**.

> **Prototype** trong **JavaScript** đóng vai trò giống như **class** ở các ngôn ngữ lập trình hướng đối tượng khác, nó cũng đóng vai trò như một cái **khung**. Các **object** nói chung và cả các **object kì lạ** như trên nói riêng đều được kế thừa các **property** và **method** từ cái gọi là **Prototype**.

Sau đây là sơ đồ minh họa cách mà **Prototype** trong **JavaScript** hoạt động:

{% asset_img 1.png %}
Mình sẽ giải thích qua về sơ đồ này:

`username` là dữ liệu dạng **string** và do đó nó được kế thừa từ `String.prototype`, `itemsInCart` là dữ liệu dạng **array** nên được kế thừa từ `Array.prototype`, `remainingStock` là dữ liệu dạng **number** nên được kế thừa từ `Number.prototype`.

Tiếp đến thì `String.prototype`, `Array.prototype` và `Number.prototype` đều được kế thừa từ `Object.prototype`.

> Có thể nói nôm na `username` là con của `String.prototype`, `String.prototype` lại là con của `Object.prototype`. Tuy nhiên `Object.prototype` thì không là con của thằng nào hết.

> Một điều lưu ý nữa: Khi một **object** được tạo ra bởi cú pháp **Object literal** thì **object** này được kế thừa từ `Object.prototype`, nghĩa là nó được kế thừa trực tiếp từ `Object.prototype`. Trong khi ở sơ đồ bên trên một **object** có dạng **array** sẽ phải kế thừa `Object.prototype` gián tiếp qua `Array.prototype`.

# Prototype là gì ?

Qua các ví dụ mình nói ở trên, bạn có thể hiểu sơ qua về **Prototype**. Nôm na ý mình muốn truyền tải ở các phần bên trên là:

> **Prototype** cho phép các **object** kế thừa **property** và **method** từ nó.

Giờ thì mình sẽ đi đến chi tiết hơn về **Prototype**. Nếu như đoạn trước đã hack não thì đoạn này còn hack não hơn =\]\]

Đi sâu hơn về cái sơ đồ ban nãy:

{% asset_img 1.png %}

> Lưu ý: Sơ đồ này chỉ dùng để biểu trưng và mới chỉ để cập đến 3 kiểu dữ liệu là **array**, **string**, **number**. Trong khi đó còn rất nhiều kiểu dữ liệu khác. Phần này mình nghĩ người đọc nên tự tìm hiểu thêm để hiểu hơn về JavaScript.

`String.prototype` là gì ? `Array.prototype` là gì ? Chắc hẳn bạn sẽ có những câu hỏi như vậy khi xem cái sơ đồ vừa rồi, đây là phần mà ban nãy mình chưa nói rõ.

Bạn có thể thấy `String.prototype` có một dấu `.` ngăn cách giữa chữ `String` và chữ `prototype`. Đây còn gọi là toán tử `.` hay (**dot operator**), có thể bạn cũng biết đây là cách ta sử dụng để truy cập (**access**) vào **property** của một **object** trong **JavaScript**.

Tiện đây thì mình sẽ nói qua về cách **access** vào **property** trong **JavaScript**. Ta có 3 cách như sau, mình sẽ tiếp tục sử dụng ví dụ ban nãy để minh họa:

```javascript
const car = {
  color: "red",
  running: function () {
    console.log("Car is running");
  },
};

console.log(car.color); //trả về red
console.log(car["color"]); //trả về red
var x = "color";
console.log(car[x]); //trả về red
```

Chi tiết hơn về **Property Accessors** có thể xem ở đây: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Property\_Accessors

Khi ta nhìn thấy `String.prototype` thì ta có thể biết `String` là **object** và `prototype` là **property**.

> Vậy bản chất `prototype` chỉ là **property** của một **object**. Cơ mà cái `prototype` chính bản thân nó cũng là **object** (hack não chưa =\]\] )

Khi bạn vào thử giao diện **Console** của trình duyệt và gõ `String.prototype` thì bạn có thể thấy ngay vì sao `prototype` chính bản thân nó cũng là **object** :

{% asset_img 2.png %}

> `String` là **object**, nhưng `String.prototype` vẫn là **object**. Điều này áp dụng tương tự cho `Number.prototype`,`Array.prototype`, `Object.prototype` và các kiểu dữ liệu khác. Đoạn này mình nghĩ các bạn nên vào giao diện **Console** của trình duyệt và gõ các lệch này để tự kiểm chứng.

# Quy ước về các thuật ngữ được dùng trong bài

Do chữ 2 chữ`String-string` có thể sẽ gây nhầm lẫn nên mình sẽ nói `String` này là `StringBase`, còn `string` này để nói về kiểu dữ liệu dạng **string**. Điều này áp dụng tương tự với `Array-array`,`Number-number`, `Object-object` và các kiểu dữ liệu khác.

# Prototype Pollution là gì ?

Sang phần này lại phải dùng đến cái sơ đồ này để nói tiếp:

{% asset_img 1.png %}

Qua các phần mà mình trình bày ở trên, các bạn đã phần nào nắm được rõ **Prototype** là gì.

Bạn nào nhìn vào cái tên **Prototype Pollution** thì cũng có thể đặt ra ý tưởng về cách khai thác lỗi này. Đó chính là việc ta **làm ngập prototype**, cụ thể hơn là làm ngập `Object.prototype`.

Vì sao lại là làm ngập `Object.prototype`?

> Bởi vì mọi **object** đều được kế thừa các **property** và **method** từ `Object.prototype`. Một khi kiểm soát được `Object.prototype` thì attacker có thể thao túng luồng chức năng của chương trình và mở ra rất nhiều hướng tấn công khác.

Một ví dụ rất đơn giản và dễ hiểu, giả sử chương trình của mình có phân ra 2 quyền là **normal user** và **admin**. Mình có 1 đoạn code sau để kiểm tra quyền của người dùng:

```javascript
if (user.isAdmin == true) {
  // chỉ có admin mới được thực hiện các thao tác này
}
```

Nếu như lúc này attacker có thể thao túng `Object.prototype` và gán thêm 1 thuộc tính `isAdmin = true` thì lúc này `user.isAdmin` sẽ luôn có giá trị `true`. Lúc này attacker đã có thể thực hiện các thao tác mà chỉ quyền **admin** mới có thể làm.

# Cách truy cập và sửa đổi Prototype

## Sử dụng **property** `constructor`

`constructor` là 1 property đặc biệt cho phép 1 **object** trỏ về hàm (**function**) đã tạo ra nó. Và thông qua việc trỏ về được **function** cha, nó có thể truy cập vào **property** `prototype` để tiến hành sửa đổi `prototype`.

Ví dụ minh họa:

```javascript
const car = {
  color: "red",
  running: function () {
    console.log("Car is running");
  },
};

console.log(car.constructor); //dòng trên sẽ trả về `ObjectBase` (đoạn này mình dùng kí hiệu như đã nói ở trên)
console.log(car.constructor.prototype); //dòng trên trả về `Object.prototype`
car.constructor.prototype.isFast = "yes";
console.log(car.isFast); //trả về "yes"
```

## Sử dụng **magic property** `__proto__`

Kể từ ECMAScript 6, ta có thêm một **magic property** mang tên `__proto__` (các **method** hay **property** có cú pháp `2 dấu gạch dưới + tên + 2 dấu gạch dưới` được gọi dưới cái tên **magic method** hay **magic property**, thật ra có lý do khiến người ta gọi là **magic method** hay **magic property** nhưng mình sẽ không trình bày ở đây).

`__proto__` cho phép một **object** truy cập thẳng vào **property** `prototype` của cha nó.

Ví dụ minh họa:

```javascript
const car = {
  color: "red",
  running: function () {
    console.log("Car is running");
  },
};

console.log(car.__proto__); //dòng trên trả về `Object.prototype`
car.__proto__.isFast = "yes";
console.log(car.isFast); //trả về "yes"
```

## Điều thú vị về **property** `constructor`

Ở bên trên mình đã giới thiệu về cách khai báo một **object** bằng **Object literal**. Và trong **JavaScript** còn vài cách khai báo **object** nữa.

Ở đây mình sẽ nói về **Constructor Function** (nếu bạn nắm kha khá về **JavaScript** thì chắc cũng biết cái này)

Cú pháp khi dùng **Constructor Function** sẽ như sau (cú pháp này sẽ quen thuộc với ai từng học **Java**, **C#** hơn):

```javascript
function Car(color, speed) {
  this.color = color;
  this.speed = function () {
    return `This car is running in: ${speed} km/h`;
  };
}

const car = new Car("red", 11);
console.log(car.color); //trả về "red"
console.log(car.speed()); //trả về "This car is running in: 11 km/h"
```

Okay vậy thì điều đặc biệt về **property** `constructor` là gì ?

Nếu bạn không biết, `function Car` được kế thừa từ `global constructor function`.

```javascript
function Car(color, speed) {
  this.color = color;
  this.speed = function () {
    return `This car is running in: ${speed} km/h`;
  };
}

console.log(Car.constructor); //trả về global constructor function
```

{% asset_img 3.png %}

Và khi khai báo bằng **Object literal**

```javascript
const car = {
  color: "red",
  running: function () {
    console.log("Car is running");
  },
};

console.log(car.constructor); //trả về ObjectBase
console.log(car.constructor.constructor); //trả về global constructor function
car.constructor.constructor("return Ford");
car.constructor.constructor("return Ford")(); //trả về Ford
```

> Ở đây có nghĩa là `constructor` của `constructor` là `global constructor function` (hack não thật =\]\])

# Prototype Pollution xảy ra khi nào ?

Prototype pollution xảy ra khi lập trình viên không biết về mối nguy hiểm khi vô tình cho phép attacker thêm/sửa/xóa `Object.prototype`.

Có rất nhiều thư viện dính phải lỗi này. Trong bài viết này mình chỉ phân tích một vài case tiêu biểu:

## Case 1: Hàm `merge()`

Giả sử ta muốn hợp nhất 2 object a và b như sau:

```javascript
let a = { a: 1, b: 2 };
let b = { b: 3, c: 4 };
```

Điều ta mong muốn là tạo ra 1 object c có dạng:

```javascript
c = { a: 1, b: 3, c: 4 };
```

Để giải quyết việc này, trong 1 vài thư viện thì các developer đã xây dựng ra hàm `mere()`

```javascript
let c = merge(a, b); //Lúc này c sẽ có dạng { a: 1, b: 3, c: 4} như ta mong muốn
```

Hàm `merge()` này có cách hoạt động như sau:

```javascript
function merge(a, b) {
  for (var att in b) {
    if (typeof a[att] === "object" && typeof b[att] === "object") {
      merge(a[att], b[att]);
    } else {
      a[att] = b[att];
    }
  }
  return a;
}
```

Hàm `merge()` sẽ duyệt qua các thuộc tính của **b**, nếu như thuộc tính này ở cả object **a** và **b** đều là object thì `merge()` sẽ đệ quy tiếp, nếu không thỏa mãn điều kiện này thì `merge()` sẽ gán thuộc tính của **b** vào **a**. Lý do tại sao thuộc tính `b = 3` chứ không phải `b = 2` thì chính là do khối code ở **else** thực hiện.

Vậy nếu như `b` không phải một **object** đơn thuần như trên thì sao. Giả sử nó có dạng kì lạ sau:

```javascript
let b = JSON.parse('{"__proto__":{"polluted": 1}}');
```

Vì sao nó kì lạ, đây là câu trả lời:

> In JSON, "**proto**" is a normal property key. In an object literal, it sets the object's prototype.

Ý của câu này là khi gọi `__proto__` ở trong JSON thì nó giống như trỏ đến một **property** bình thường. Còn khi khi gọi `__proto__` ở trong **Object literal** thì nó sẽ trỏ đến `Object.prototype`

Nguồn của câu trên: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Object\_initializer#object\_literal\_syntax\_vs.\_json

Nếu như bạn gán cho một **object** được khai báo bằng **Object literal** như này

```javascript
var b = { __proto__: { " polluted": 1 } };
```

Lúc này thì `__proto__` sẽ trỏ đến `Object.prototype` và sửa đổi `Object.prototype` thành `{ " polluted": 1 }`. Hàm `merge()` sẽ không chạy như ta mong muốn.

Vì sao nó không được như ta mong muốn thì bạn hãy xem cách hàm `merge()` thực thi bên dưới.

```javascript
function merge(a, b) {
  for (var att in b) {
    if (typeof a[att] === "object" && typeof b[att] === "object") {
      merge(a[att], b[att]);
    } else {
      a[att] = b[att];
    }
  }
  return a;
}
var a = { a: 1, b: 1 };
var b = JSON.parse('{"__proto__":{"polluted": 1}}');
var c = merge(a, b); //hàm merge được gọi
var d = {};
console.log(d.polluted); //trả về 1
```

**_Bước 1_**: Vòng for sẽ duyệt qua tất cả thuộc tính của `b`, `b` chính là **object** được tạo bởi `JSON.parse` và có thuộc tính `__proto__`.

> Vì sao khi dùng `var b = { __proto__: { " polluted": 1 } };` thì không được ? Vì vòng `for` này sẽ không thấy được thuộc tính `__proto__`, bởi `for (var att in b)` không cho phép tìm các **magic property**. Nên đây không phải luồng mà ta muốn chạy.

**_Bước 2_**: Đi đến khối `if`, lúc này khối `if` sẽ kiểm tra `a["__proto__"]` và `b["__proto__"]` có phải là dạng **object** không? `a[__proto__]` chính là `Object.prototype` và `Object.prototype` như mình đã phân tích thì nó là một **object**, còn `b[__proto__]` là `{"polluted": 1 }` thì đương nhiên `{ "polluted": 1 }` cũng là **object**.

**_Bước 3_**: Sau khi thấy cả `a[__proto__]` và `b[__proto__]` cùng là **object** thì sẽ tiến hành đệ quy. Nhớ rằng ở đây `a[__proto__] === Object.prototype`, `b[__proto__] === {"polluted": 1}`

**_Bước 4_**: Hàm `merge()` nhận 2 tham số là `Object.prototype` và `{"polluted": 1}`. Ở đây mình quy ước `a2 === Object.prototype` và `b2 === {"polluted": 1}`

**_Bước 5_**: Vòng for sẽ duyệt qua thuộc tính của `b2`, và `b2` có thuộc tính `polluted`. Tiếp đến khối `if` sẽ kiểm tra `a2["polluted"]` và `b2["polluted"]` có phải là dạng **object** không? Ở đây `a2["polluted"] = undefined`, còn `b2["polluted"] = 1`. Vậy ở đây cả 2 điều kiện đều không thỏa mãn, dừng đệ quy và đi đến khối else.

**_Bước 6_**: Khối else sẽ thực hiện `a2["polluted"] = b2["polluted"]`. Viết trực quan ra thì nó sẽ là `Object.prototype.polluted = 1`. Vậy ta đã có thể làm cho `Object.prototype` có thêm thuộc tính là `polluted`. Khi đó toàn bộ các object nào kế thừa từ `Object.prototype` sẽ đều có thuộc tính `polluted` với giá trị `1`.

## Case 2: Hàm `clone()`

Bản chất hàm này cũng được tạo nên từ hàm`merge()`.

Code triển khai của hàm `clone()`

```javascript
function clone(a) {
  return merge({}, a);
}
```

## Case 3: Path Assignment Operation

Code minh hoạ:

```javascript
var obj = { b: { test: 321 } };
setValue(obj, "b.test", 123);
obj.b.test; //trả về 123
```

Các thư viện sử dụng đoạn code trên cho phép gán giá trị theo đường `b.test` và đặt giá trị là `123`.

Ở đây ta có thể khai thác bằng cách sử dụng giống như việc thay đổi `Object.prototype` bằng **magic property** `__proto__`.

Đoạn code với exploit payload:

```javascript
var obj = {};
setValue(obj, "__proto__.polluted", 1);
var d = {};
d.polluted; //trả về 1
```

## Case n: Tổng quát về cách khai thác

Bản chất cách khai thác của lỗi này đến từ việc cho phép **access** vào `Object.prototype`. Vậy nên các pattern cho phép **access** vào `Object.prototype` đều có thể dẫn đến lỗi.

Nếu như thông qua một **Object Literal** thì chỉ cần thông qua một lần trỏ đến `__proto__` là có thể **access** vào `Object.prototype`.

Nếu thông qua một **object** được kế thừa qua **n** `prototype` khác thì tương ứng với **n** lần trỏ đến `__proto__`.

# Prototype Pollution Mitigation

## Cách 1: Sử dụng `Object.freeze()`

Khi một **object** bị hàm `freeze()` gọi, hàm`freeze()` sẽ **đóng băng** và không cho sửa đổi gì trên **object** đó. Và do `ObjectBase` là **object** nên ta hoàn toàn có thể **đóng băng** `ObjectBase` và nhờ đó không cho sửa đổi gì vào `Object.prototype`.

Dẫu vậy thì mình nghĩ đây không phải cách **mitigate** hay, bởi đôi khi ta vẫn cần thêm **property** hay **method** vào `Object.prototype`.

Code minh họa:

```javascript
Object.freeze(Object.prototype);
Object.freeze(Object);
({}).__proto__.test = 123({}).test; // trả về undefined
```

## Cách 2: Sử dụng `Object.create(null)`

Hàm `create()` với tham số **null** sẽ tạo ra một **object** không có khả năng kế thừa từ `Object.prototype`. Do vậy đây cũng là 1 cách **mitigate**, tuy nhiên mình cũng không đánh giá cao, bởi việc dùng `Object.create(null)` sẽ khiến ta phải lặp lại code rất nhiều khi lập trình. Bởi mỗi lần tạo một **object** lại phải dùng lại hàm này và khai báo lại toàn bộ **property** và **method** của **object** đó.

Code minh họa:

```javascript
function merge(a, b) {
  for (var att in b) {
    if (typeof a[att] === "object" && typeof b[att] === "object") {
      merge(a[att], b[att]);
    } else {
      a[att] = b[att];
    }
  }
  return a;
}
var a = { a: 1, b: 1 };
var b = JSON.parse('{"__proto__":{"polluted": 1}}');
var c = merge(a, b); //hàm merge được gọi

o = Object.create(null);
console.log(o.polluted); // trả về undefined
```

## Cách 3: Sử dụng `MapBase`

Cấu trúc dữ liệu kiểu **map** sẽ lưu giá trị theo dạng **key-value**, vậy nên có thể lưu **property** vào đây. Tuy nhiên lại không thế lưu **method** nên cách này cũng gây nhiều hạn chế.

Code minh họa:

```javascript
var map = new Map();
map.set("1", "string 1");
map.set(1, "number 1");
map.set(true, "boolean true");

console.log(map.get("1")); //trả về string 1
console.log(map.get(1)); //trả về number 1
console.log(map.get(true)); //trả về boolean true
```

## Cách 4: Validate các trường dữ liệu JSON đầu vào

Rất nhiều thư viện **NPM** cho phép validate các trường dữ liệu **JSON** đầu vào, có thể kể đến như thư viện **avi**. Lúc này **JSON đầu vào** chỉ được phép viết ở dạng thích hợp mà ta đặt ra, không xử lý các **JSON** có dạng **kì lạ** như trên.

Đây là cách **mitigate** mình thấy hay nhất, vì vừa đảm bảo tính linh hoạt khi muốn thao tác vào `Object.prototype`, vừa giảm thiểu việc lặp code khi lập trình.

---
title: ImaginaryCTF 2022 - Web Category - Login Please (Write up)
date: 2022-09-18 02:21:02
tags: [Javascript Security, Security, CTF, Javascript Prototype Pollution]
categories:
  - Javascript
---

# Introduction

- Category: Web
- Description: Login as admin to get flag, so easy right?
- Language: NodeJS

# TL;DR

- Idea: You can send a JSON with `__proto__` to bypass the `username=admin` check, and crack md5 by using online rainbow table to get flag. It works because `req.body` has a null prototype while the `{}` in `Object.assign()` doesn't.
- Payload: `curl http://puzzler7.imaginaryctf.org:5001/login -H 'Content-Type: application/json' --data '{"password":"admin","__proto__":{"username":"admin"}}'`

# Analyze

At the first glance, we see a login form like the below image.

{% asset_img 1.png %}

Whenever I see a challenge like this I usually press `Ctrl+U` to see the source code.

{% asset_img 2.png %}

Line 13 tells us some hints, this might be the source code at the URI `/source`. I come into `/source` and saw the source code down below:

```javascript
const express = require("express");
const crypto = require("crypto");

function md5(text) {
  return crypto.createHash("md5").update(text).digest("hex");
}

const app = express();

const users = {
  guest: "084e0343a0486ff05530df6c705c8bb4",
  admin: "21232f297a57a5a743894a0e4a801fc3",
  "1337hacker": "2ab96390c7dbe3439de74d0c9b0b1767",
};
const localIPs = ["127.0.0.1", "::1", "::ffff:127.0.0.1"];

app.use(express.urlencoded({ extended: false }));
app.use(express.json());
app.get("/", (req, res) => {
  res.send(`
<form action="/login" method="POST">
    <div>
        <label for="username">Username: </label>
        <input name="username" type="text" id="username">
    </div>
    <div>
        <label for="password">Password: </label>
        <input name="password" type="password" id="password">
    </div>
    <button type="submit">Login</button>
</form>
<!-- /source -->
`);
});

app.post("/login", (req, res) => {
  if (req.body.username === "admin" && !localIPs.includes(req.ip)) {
    return res.end("Admin is only allowed from localhost");
  }
  const auth = Object.assign({}, req.body);
  if (users[auth.username] === md5(auth.password)) {
    if (auth.username === "admin") {
      res.end(`Welcome admin! The flag is ${process.env.FLAG}`);
    } else {
      res.end(`Welcome ${auth.username}!`);
    }
  } else {
    res.end("Invalid username or password");
  }
});

app.get("/source", (req, res) => {
  res.sendFile(__filename);
});

app.get("/package.json", (req, res) => {
  res.sendFile("package.json", { root: __dirname });
});

const port = 5001 || process.env.PORT;
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
```

Combine the source code when I press `Ctrl+U` and travel to `/source`, I can confirm that the middleware `app.post('/login)` will trigger whenever I fill in the login form and press the`Login` button.

`users` constance has a table of key-value and if you try to hash those keys with the same `md5` algorithm, you will see the value after hashed `admin` and `guest` have the same value in the table.

At this stage, you might see how to get the flag by sending the payload `username=admin&password=admin`.

But things don't go easy like this, an if statement `if (req.body.username === 'admin' && !localIPs.includes(req.ip)) { return res.end('Admin is only allowed from localhost') }` not allow you to get the flag.

Sometimes they implement a server using Nginx, we can bypass the if statement above by sending `X-Forwarded-For` header. But this time it won't work.

No more beating around the bush, i will straightforwardly talk about the bug at the middleware `app.post('/login)`. The bug is spotted when they use `Object.assign()` to clone the new instance of `req.body`.

> The `Object.assign()` method copies all enumerable own properties from one or more source objects to a target object. It returns the modified target object.

One thing to note that `req.body` also has a null prototype. So we can pollute the `req.body` object and leverage `Object.assign()` to create a new object with the polluted prototype.

By default, when we press the `Login` button, the client will send `Content-Type: application/x-www-form-urlencoded` header.

So we have to change into `Content-Type: application/json` and send the payload `{"password":"admin","__proto__":{"username":"admin"}}`,

The `if (req.body.username === 'admin' && !localIPs.includes(req.ip)) { return res.end('Admin is only allowed from localhost') }` check the `username` properties of the `req.body` object but it doesn't check`req.body.__proto__.username` which have the same result when we access by `auth.username`.

PoC:
{% asset_img 3.png %}

> Flag: ictf{omg_js_why_are_you_doing_this_to_me}

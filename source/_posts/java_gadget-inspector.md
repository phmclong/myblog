---
title: Java Security 3 - công cụ Gadget Inspector (not done)
date: 2023-11-02 7:18:07
tags: [Java Security, Security, Java Insecure Deserialization, Static Analysis]
categories:
  - Java 
---

# Kiến thức nền

Về thuật ngữ **source** và **sink**:

- [https://sheon.hashnode.dev/java-security-2-phan-tich-urldns-chain-ysoserial](https://sheon.hashnode.dev/java-security-2-phan-tich-urldns-chain-ysoserial)

Về Java bytecode và framework ASM:

- [https://sheon.hashnode.dev/java-learning-7-java-bytecode](https://sheon.hashnode.dev/java-learning-7-java-bytecode-not-done)
- [https://sheon.hashnode.dev/java-learning-8-java-bytecode-asm-framework](https://sheon.hashnode.dev/java-learning-8-java-bytecode-asm-framework)

# Tổng quan về Gadget Inspector

- được công bố trong bài trình bày **Automated Discovery of Deserialization Gadget Chains** bởi **Ian Haken** tại hội thảo DEFCON26 năm 2018
- Slide của bài trình bày **Automated Discovery of Deserialization Gadget Chains**: [https://i.blackhat.com/us-18/Thu-August-9/us-18-Haken-Automated-Discovery-of-Deserialization-Gadget-Chains.pdf](https://i.blackhat.com/us-18/Thu-August-9/us-18-Haken-Automated-Discovery-of-Deserialization-Gadget-Chains.pdf)
- Paper của bài trình bày **Automated Discovery of Deserialization Gadget Chains**: [https://i.blackhat.com/us-18/Thu-August-9/us-18-Haken-Automated-Discovery-of-Deserialization-Gadget-Chains-wp.pdf](https://i.blackhat.com/us-18/Thu-August-9/us-18-Haken-Automated-Discovery-of-Deserialization-Gadget-Chains-wp.pdf)
- Video bài trình bày **Automated Discovery of Deserialization Gadget Chains**: [https://www.youtube.com/watch?v=KSA7vUkXGSg](https://www.youtube.com/watch?v=KSA7vUkXGSg)
- là công cụ phân tích tĩnh (static analysis) mã nguồn, nó kiểm tra trong các thư viện nằm trên Classpath và các thư viện tích hợp sẵn của ứng dụng, từ đó tự động tìm ra các gadget chain có thể sử dụng để khai thác trong ứng dụng.

# Các thư viện thực hiện Serialization & Deserialization trong Java

Trong thực tế có nhiều thư viện hỗ trợ việc **serialization** & **deserialization** khác nhau:

- JDK (Object Input Stream)
- Jackson (XML, JSON)
- Xstream (XML, JSON)
- Genson (JSON)
- JSON-IO (JSON)
- FlexSON (JSON)
- Fastjson (JSON)

Hành vi khi thực hiện **deserialization** của các thư viện này cũng khác nhau. Theo đó **magic method** khác nhau sẽ được gọi tự động và các **magic method** này có thể được sử dụng làm **entry point** (hay còn gọi là **source**) của quá trình **deserialization**. Nếu các này gọi các sub-method khác thì một sub-method trong **call chain** cũng có thể được sử dụng làm **source**, tương đương với việc biết phần trước của **call chain**, bắt đầu từ một sub-method để tìm các nhánh khác. Một số phương thức nguy hiểm (**dangerous method**) hay còn gọi là **sink** có thể bị chạm tới thông qua nhiều layer các method call.

- **ObjectInputStream**:
  - Cho ví dụ: một class implement interface `Serializable` thì `ObjectInputStream.readobject()` sẽ tự động tìm và gọi method `readObject()`, `readResolve()` và một số methods của class khi thực hiện quá trình deserialization.
  - Cho ví dụ: một class implement interface `Externalizable` thì `ObjectInputStream.readObject()` sẽ tự động tìm và gọi method `readExternal()` và 1 số methods của class khi thực hiện quá trình deserialization.
- **Jackson**:
  - Khi `ObjectMapper.readValue()` thực hiện deserialization một class, nó sẽ tự động tìm hàm constructor không có argument (**no-argument constructor)** của class cần deserialization, constructor có chứa base parameter, **setter** của property, **getter** của property,...

# Phân tích

Điểm khởi đầu của tool chính là hàm `main()` trong file **src\\main\\java\\gadgetinspector\\GadgetInspector.java**. Cùng đi phân tích lần lượt những gì có trong hàm này.

```java
if (args.length == 0) {
    printUsage();
    System.exit(1);
}
```

Mở đầu của hàm, đoạn này xác định xem tham số khởi động liệu có bị trống hay không ? Nếu có, chương trình sẽ thoát ngay lập tức.

```java
configureLogging();
boolean resume = false;
GIConfig config = ConfigRepository.getConfig("jserial");
```

Tiếp tục, `configureLogging()` dùng để cấu hình log. Biến `resume` sẽ được mô tả chi tiết phần sau.

Ta thấy dòng `GIConfig config = ConfigRepository.getConfig("jserial");` khởi tạo biến `config` có kiểu dữ liệu `GIConfig`. Thực tế `GIConfig` là 1 interface. Bước này dùng để thống nhất việc quản lý output và thống nhất cấu hình kiểu serialization. Cùng xem qua `GIConfig` tại **src\\main\\java\\gadgetinspector\\config\\GIConfig.java**

```java
public interface GIConfig {
    String getName();
    SerializableDecider getSerializableDecider(Map<MethodReference.Handle, MethodReference> methodMap, InheritanceMap inheritanceMap);
    ImplementationFinder getImplementationFinder(Map<MethodReference.Handle, MethodReference> methodMap,
                                                 Map<MethodReference.Handle, Set<MethodReference.Handle>> methodImplMap,
                                                 InheritanceMap inheritanceMap);
    SourceDiscovery getSourceDiscovery();

}
```

Do có kiểu **serialization** khác nhau nên ta cần triển khai (implement) các `SerializableDecider`, `ImplementationFinder` và `SourceDiscovery` dành riêng cho từng kiểu serialization.

Trong 3 thư mục: **src\\main\\java\\gadgetinspector\\jackson**, **src\\main\\java\\gadgetinspector\\javaserial**, **src\\main\\java\\gadgetinspector\\xstream** tác giả đã implement các `SerializableDecider`, `ImplementationFinder` và `SourceDiscovery` dành riêng cho từng hình thức serialization.

{% asset_img 1.jpeg %}

Sử dụng Jackson làm ví dụ để phân tích. Xem file **src\\main\\java\\gadgetinspector\\jackson\\JacksonSerializableDecider.java** để thấy `SerializableDecider` dành cho kiểu serialization trong thư viện Jackson.

```java
public class JacksonSerializableDecider implements SerializableDecider {
    private final Map<ClassReference.Handle, Boolean> cache = new HashMap<>();
    private final Map<ClassReference.Handle, Set<MethodReference.Handle>> methodsByClassMap;

    public JacksonSerializableDecider(Map<MethodReference.Handle, MethodReference> methodMap) {
        this.methodsByClassMap = new HashMap<>();
        for (MethodReference.Handle method : methodMap.keySet()) {
            Set<MethodReference.Handle> classMethods = methodsByClassMap.get(method.getClassReference());
            if (classMethods == null) {
                classMethods = new HashSet<>();
                methodsByClassMap.put(method.getClassReference(), classMethods);
            }
            classMethods.add(method);
        }
    }

    @Override
    public Boolean apply(ClassReference.Handle handle) {
        Boolean cached = cache.get(handle);
        if (cached != null) {
            return cached;
        }

        Set<MethodReference.Handle> classMethods = methodsByClassMap.get(handle);
        if (classMethods != null) {
            for (MethodReference.Handle method : classMethods) {
                if (method.getName().equals("<init>") && method.getDesc().equals("()V")) {
                    cache.put(handle, Boolean.TRUE);
                    return Boolean.TRUE;
                }
            }
        }

        cache.put(handle, Boolean.FALSE);
        return Boolean.FALSE;
    }
}
```

Trong phần này ta chỉ cần chú ý đến method `apply()`, đây là 1 method có return type là boolean. Có thể thấy rằng miễn là có một hàm constructor không có tham số (**no-argument constructor**) thì có nghĩa là nó có thể serialize được. Bởi vì trong Jackson, nếu không có implement cụ thể gì bên trong 1 no-argument constructor và lúc đó lại implement bên trong 1 constructor có argument thì lúc này Jackson sẽ deserialize dữ liệu JSON.

Mọi instance đều được khởi tạo (**instantiated**) thông qua no-argument constructor. Do đó nếu 1 class không có no-argument constructor thì nó không thể được deserialize bởi Jackson.

```java
if (classMethods != null) {
    for (MethodReference.Handle method : classMethods) {
        if (method.getName().equals("<init>") && method.getDesc().equals("()V")) {
            cache.put(handle, Boolean.TRUE);
            return Boolean.TRUE;
        }
    }
}
```

Ta thấy khối `if (method.getName().equals("<init>") && method.getDesc().equals("()V"))` dùng để kiểm tra xem class đang kiểm tra có no-argument constructor hay không? Nếu không có thì nó không thể deserialize được -&gt; không deserialize được thì ta không thể kiểm soát được data flow -&gt; không kiểm soát được data flow thì gadget chain tìm được sẽ không hợp lệ.

Tiếp tục, xem file **src\\main\\java\\gadgetinspector\\jackson\\ JacksonImplementationFinder**

```java
package gadgetinspector.jackson;

import gadgetinspector.ImplementationFinder;
import gadgetinspector.SerializableDecider;
import gadgetinspector.data.MethodReference;

import java.util.HashSet;
import java.util.Set;

public class JacksonImplementationFinder implements ImplementationFinder {

    private final SerializableDecider serializableDecider;

    public JacksonImplementationFinder(SerializableDecider serializableDecider) {
        this.serializableDecider = serializableDecider;
    }

    @Override
    public Set<MethodReference.Handle> getImplementations(MethodReference.Handle target) {
        Set<MethodReference.Handle> allImpls = new HashSet<>();

        // Đối với jackson, ta ko cần chỉ định class; nó sử dụng Reflection API để khởi tạo class của chính nó.
        // Do đó chỉ cần thêm target method nếu target class có thể tự serialize được.
        if (Boolean.TRUE.equals(serializableDecider.apply(target.getClassReference()))) {
            allImpls.add(target);
        }

        return allImpls;
    }
}
```

Để ý tới method `JacksonImplementationFinder.getImplementations()`, bởi vì Java là ngôn ngữ đa hình nên ta chỉ có thể biết được một class đã implement gì từ một interface trong run time. Trong khi đó **gadget inspector** không phải công cụ tìm gadget chain trong run time. Do đó, khi gặp một số lời gọi đến một số phương thức của interface, ta cần tìm tất cả các class đã implement các method của interface và tạo thành một chain trong số chúng và từ đó tạo thành một chuỗi method call và cuối cùng thực hiện Taint Analysis.

Method `getImplementations()` này được đánh giá bằng cách gọi method `apply()` của class JacksonSerializableDecider, bởi vì chúng ta có thể kiểm soát việc triển khai interface hoặc subclass, nhưng việc JSON có thể deserialize được hay không thì đòi hỏi `JacksonSerializableDecider` phải xác định xem liệu có no-argument constructor hay không ?

Tiếp tục, xem file **src\\main\\java\\gadgetinspector\\jackson\\JacksonSourceDiscovery.java** để thấy `SourceDiscovery` dành cho kiểu serialization trong thư viện Jackson.

```java
package gadgetinspector.jackson;

import gadgetinspector.SourceDiscovery;
import gadgetinspector.data.ClassReference;
import gadgetinspector.data.InheritanceMap;
import gadgetinspector.data.MethodReference;
import gadgetinspector.data.Source;

import java.util.Map;

public class JacksonSourceDiscovery extends SourceDiscovery {

    @Override
    public void discover(Map<ClassReference.Handle, ClassReference> classMap,
                         Map<MethodReference.Handle, MethodReference> methodMap,
                         InheritanceMap inheritanceMap) {

        final JacksonSerializableDecider serializableDecider = new JacksonSerializableDecider(methodMap);

        for (MethodReference.Handle method : methodMap.keySet()) {
            if (serializableDecider.apply(method.getClassReference())) {
                if (method.getName().equals("<init>") && method.getDesc().equals("()V")) {
                    addDiscoveredSource(new Source(method, 0));
                }
                if (method.getName().startsWith("get") && method.getDesc().startsWith("()")) {
                    addDiscoveredSource(new Source(method, 0));
                }
                if (method.getName().startsWith("set") && method.getDesc().matches("\\(L[^;]*;\\)V")) {
                    addDiscoveredSource(new Source(method, 0));
                }
            }
        }
    }
}
```

Class này chỉ có một method là `discover()`. Tuy nhiên, nó là method quan trọng nhất để tìm gadget chain , bởi vì đối với chuỗi thực thi method của gadget chain, chúng ta phải có một entry có thể được kích hoạt và vai trò của `JacksonSourceDiscovery` là tìm các entry method. Khi Jackson deserialize dữ liệu JSON, nó sẽ thực thi hàm constructor không có đối số cũng như các method `setter()` và `getter()`. Nếu chúng ta có các trường dữ liệu có thể kiểm soát được thì các method được thực thi này sẽ kích hoạt, nếu có gadget chain, nó có thể kích hoạt việc thực thi toàn bộ source-sink chain.

Quay trở lại hàm `GadgetInspector.main()`. Xem xét tiếp đoạn code sau:

```java
int argIndex = 0;
while (argIndex < args.length) {
    String arg = args[argIndex];
    if (!arg.startsWith("--")) {
        break;
    }
    if (arg.equals("--resume")) {
        resume = true;
    } else if (arg.equals("--config")) {
        config = ConfigRepository.getConfig(args[++argIndex]);
        if (config == null) {
            throw new IllegalArgumentException("Invalid config name: " + args[argIndex]);
        }
    } else {
        throw new IllegalArgumentException("Unexpected argument: " + arg);
    }

    argIndex += 1;
}
```

Đoạn code chỉ đơn giản kiểm tra các tham số ta truyền vào khi khởi động chương trình. Không cần để ý nhiều. Lúc đầu tôi có nhắc tới biến `resume` sẽ được nói tới sau, khối `if (arg.equals("--resume"))` kiểm tra xem nếu như ta có chuyển tham số `--resume` vào khi khởi động chương trình hay ko ? Nếu ko truyền thì giá trị `resume = false`, ở phần sau ta sẽ thấy nếu như `resume = false` thì sẽ xóa toàn bộ file **.dat**

Tiếp tục phần sau của `GadgetInspector.main()`:

```java
final ClassLoader classLoader;
if (args.length == argIndex+1 && args[argIndex].toLowerCase().endsWith(".war")) {
    Path path = Paths.get(args[argIndex]);
    LOGGER.info("Using WAR classpath: " + path);
    classLoader = Util.getWarClassLoader(path);
} else {
    final Path[] jarPaths = new Path[args.length - argIndex];
    for (int i = 0; i < args.length - argIndex; i++) {
        Path path = Paths.get(args[argIndex + i]).toAbsolutePath();
        if (!Files.exists(path)) {
            throw new IllegalArgumentException("Invalid jar path: " + path);
        }
        jarPaths[i] = path;
    }
    LOGGER.info("Using classpath: " + Arrays.toString(jarPaths));
    classLoader = Util.getJarClassLoader(jarPaths);
}
final ClassResourceEnumerator classResourceEnumerator = new ClassResourceEnumerator(classLoader);
```

Phần code trên **parse** phần "--parameter" cuối cùng khi khởi động chương trình. Phần này có thể chỉ định một **package** WAR hoặc nhiều **package** JAR và đặt vào trong `ClassResourceEnumerator`. `ClassResourceEnumerator` sẽ đọc tất cả các class trong WAR và JAR đã tải hoặc đọc tất cả các class trong `rt.jar` của jre.

Tiếp tục phần sau `GadgetInspector.main()`:

```java
if (!resume) {
    // nếu có tham số --resume thì ko xóa file .dat
    LOGGER.info("Deleting stale data...");
    for (String datFile : Arrays.asList("classes.dat", "methods.dat", "inheritanceMap.dat",
            "passthrough.dat", "callgraph.dat", "sources.dat", "methodimpl.dat")) {
        final Path path = Paths.get(datFile);
        if (Files.exists(path)) {
            Files.delete(path);
        }
    }
}
```

Đoạn này rất đơn giản. Như đã phân tích ở phía trên, nếu như không truyền tham số `--resume` thì xóa toàn bộ file **.dat**.

Tiếp tục, đây là phần cuối cũng như core xử lý của method `GadgetInspector.main()`:

```java
if (!Files.exists(Paths.get("classes.dat")) || !Files.exists(Paths.get("methods.dat"))
        || !Files.exists(Paths.get("inheritanceMap.dat"))) {
    LOGGER.info("Running method discovery...");
    MethodDiscovery methodDiscovery = new MethodDiscovery();
    methodDiscovery.discover(classResourceEnumerator);
    methodDiscovery.save();
}

if (!Files.exists(Paths.get("passthrough.dat"))) {
    LOGGER.info("Analyzing methods for passthrough dataflow...");
    PassthroughDiscovery passthroughDiscovery = new PassthroughDiscovery();
    passthroughDiscovery.discover(classResourceEnumerator, config);
    passthroughDiscovery.save();
}

if (!Files.exists(Paths.get("callgraph.dat"))) {
    LOGGER.info("Analyzing methods in order to build a call graph...");
    CallGraphDiscovery callGraphDiscovery = new CallGraphDiscovery();
    callGraphDiscovery.discover(classResourceEnumerator, config);
    callGraphDiscovery.save();
}

if (!Files.exists(Paths.get("sources.dat"))) {
    LOGGER.info("Discovering gadget chain source methods...");
    SourceDiscovery sourceDiscovery = config.getSourceDiscovery();
    sourceDiscovery.discover();
    sourceDiscovery.save();
}

{
    LOGGER.info("Searching call graph for gadget chains...");
    GadgetChainDiscovery gadgetChainDiscovery = new GadgetChainDiscovery(config);
    gadgetChainDiscovery.discover();
}

LOGGER.info("Analysis complete!");
```

5 khối code tương đương với 5 bước thực hiện của công cụ mà tác giả đã nói trong slide:

- Bước 1: Enumerate class/method hierarchy.
- Bước 2: Discover Passthrough Dataflow.
- Bước 3: Enumerate Passthrough Callgraph.
- Bước 4: Enumerate Sources Using Know Tricks.
- Bước 5: BFS on Call Graph for Chains.

## Bước 1: Enumerate class/method hierarchy

Bước này chủ yếu thu thập dữ liệu class, dữ liệu method và dữ liệu mối quan hệ kế thừa của các class.

```java
if (!Files.exists(Paths.get("classes.dat")) || !Files.exists(Paths.get("methods.dat"))
        || !Files.exists(Paths.get("inheritanceMap.dat"))) {
    LOGGER.info("Running method discovery...");
    MethodDiscovery methodDiscovery = new MethodDiscovery();
    methodDiscovery.discover(classResourceEnumerator);
    methodDiscovery.save();
}
```

Có thể thấy ở trên, khối `if` kiểm tra xem liệu 3 file **classes.dat**, **methods.dat**, **inheritanceMap.dat** có tồn tại không ? Nếu không tồn tại thì tạo ra 1 instance `MethodDiscovery` ở và gọi tới method `discover()` của instance này.

Tới **src\\main\\java\\gadgetinspector\\MethodDiscovery.java** để xem cách method `MethodDiscovery.discover()` được triển khai.

```java
public void discover(final ClassResourceEnumerator classResourceEnumerator) throws Exception {
    for (ClassResourceEnumerator.ClassResource classResource : classResourceEnumerator.getAllClasses()) {
        try (InputStream in = classResource.getInputStream()) {
            ClassReader cr = new ClassReader(in);
            try {
                cr.accept(new MethodDiscoveryClassVisitor(), ClassReader.EXPAND_FRAMES);
            } catch (Exception e) {
                LOGGER.error("Exception analyzing: " + classResource.getName(), e);
            }
        }
    }
}
```

Bên trong `MethodDiscovery.discover()` , method `classResourceEnumerator.getAllClasses()` sẽ lấy ra toàn bộ class từ trong `rt.jar`, package war và jar được cấu hình với tham số khởi động chương trình. Vòng `for` sẽ duyệt qua từng class. Bên trong vòng `for`, dòng `ClassReader cr = new ClassReader(in);` khởi tạo một instance của `ClassReader` trong ASM framework.

Quay trở lại ta với đoạn code bên trên:

```java
ClassReader cr = new ClassReader(in);
try {
    cr.accept(new MethodDiscoveryClassVisitor(), ClassReader.EXPAND_FRAMES);
} catch (Exception e) {
    LOGGER.error("Exception analyzing: " + classResource.getName(), e);
}
```

Ở sử dụng method `ClassReader.accept()` để quan sát từng class với `ClassVisitor` được truyền vào, ở đây `ClassVisitor` được truyền vào chính là `MethodDiscoveryClassVisitor`.

Code được triển khai của class `MethodDiscoveryClassVisitor` cũng nằm trong class `MethodDiscovery`:

```java
private class MethodDiscoveryClassVisitor extends ClassVisitor {

    private String name;
    private String superName;
    private String[] interfaces;
    boolean isInterface;
    private List<ClassReference.Member> members;
    private ClassReference.Handle classHandle;

    private MethodDiscoveryClassVisitor() throws SQLException {
        super(Opcodes.ASM6);
    }

    @Override
    public void visit ( int version, int access, String name, String signature, String superName, String[]interfaces)
    {
        this.name = name;
        this.superName = superName;
        this.interfaces = interfaces;
        this.isInterface = (access & Opcodes.ACC_INTERFACE) != 0;
        this.members = new ArrayList<>();
        this.classHandle = new ClassReference.Handle(name);

        super.visit(version, access, name, signature, superName, interfaces);
    }

    public FieldVisitor visitField(int access, String name, String desc,
                                    String signature, Object value) {
        if ((access & Opcodes.ACC_STATIC) == 0) {
            Type type = Type.getType(desc);
            String typeName;
            if (type.getSort() == Type.OBJECT || type.getSort() == Type.ARRAY) {
                typeName = type.getInternalName();
            } else {
                typeName = type.getDescriptor();
            }
            members.add(new ClassReference.Member(name, access, new ClassReference.Handle(typeName)));
        }
        return super.visitField(access, name, desc, signature, value);
    }

    @Override
    public MethodVisitor visitMethod(int access, String name, String desc, String signature, String[] exceptions) {
        boolean isStatic = (access & Opcodes.ACC_STATIC) != 0;
        discoveredMethods.add(new MethodReference(
                classHandle,
                name,
                desc,
                isStatic));
        return super.visitMethod(access, name, desc, signature, exceptions);
    }

    @Override
    public void visitEnd() {
        ClassReference classReference = new ClassReference(
                name,
                superName,
                interfaces,
                isInterface,
                members.toArray(new ClassReference.Member[members.size()]));
        discoveredClasses.add(classReference);

        super.visitEnd();
    }
}
```

Thứ tự các method mà `ClassVisitor` sẽ truy cập sẽ là: `visit()`\-&gt;`visitField()`\-&gt;`visitMethod()`\-&gt;`visitEnd()`.

Ta phân tích `MethodDiscoveryClassVisitor.visit()`, đây là method được thực thi đầu tiên khi class hiện tại được quan sát bởi `ClassReader`. Xem lại triển khai của `MethodDiscoveryClassVisitor.visit()`:

```java
@Override
public void visit ( int version, int access, String name, String signature, String superName, String[]interfaces)
{
    this.name = name;
    this.superName = superName;
    this.interfaces = interfaces;
    this.isInterface = (access & Opcodes.ACC_INTERFACE) != 0;
    this.members = new ArrayList<>();
    this.classHandle = new ClassReference.Handle(name); // tên class

    super.visit(version, access, name, signature, superName, interfaces);
}
```

Ta thấy khi `MethodDiscoveryClassVisitor.visit()` được thực thi thì nó sẽ lưu lại 1 số thông tin của class đang được quan sát như sau:

1. `this.name`: tên class hiện tại
2. `this.superName`: tên của class cha đã kế thừa
3. `this.interfaces`: tên các inteface đã implement
4. `this.isInterface`: liệu class hiện tại có phải là interface ko
5. `this.members`: tập hợp các field của class hiện tại
6. `this.classHandle`: đóng gói của các tên class bên trong gadget inspector

Tiếp theo ta phân tích `MethodDiscoveryClassVisitor.visitField()`, đây là method được thực thi ngay sau `MethodDiscoveryClassVisitor.visit()`. Xem lại triển khai của `MethodDiscoveryClassVisitor.visitField()`:

```java
public FieldVisitor visitField(int access, String name, String desc,
                                String signature, Object value) {
    if ((access & Opcodes.ACC_STATIC) == 0) {
        Type type = Type.getType(desc);
        String typeName;
        if (type.getSort() == Type.OBJECT || type.getSort() == Type.ARRAY) {
            typeName = type.getInternalName();
        } else {
            typeName = type.getDescriptor();
        }
        members.add(new ClassReference.Member(name, access, new ClassReference.Handle(typeName)));
    }
    return super.visitField(access, name, desc, signature, value);
}
```

Ta thấy return type của method `MethodDiscoveryClassVisitor.visitField()` là `FieldVisitor`. `FieldVisitor` được dùng để truy cập các field của class hiện tại được quan sát. Class hiện tại được quan sát có bao nhiêu field thì method `MethodDiscoveryClassVisitor.visitField()` sẽ được gọi bấy nhiêu lần.

Ta thấy mỗi lần `MethodDiscoveryClassVisitor.visitField()` được gọi thì nó đều tạo ra 1 biến `typeName`, khối `if (type.getSort() == Type.OBJECT || type.getSort() == Type.ARRAY)` sẽ đánh giá kiểu của field, cuối cùng ở dòng `members.add()` thêm `typeName` vào bên trong biến `this.members` mà ta biết `this.members` được khởi tạo từ method `MethodDiscoveryClassVisitor.visit()`.

Tiếp theo ta phân tích `MethodDiscoveryClassVisitor.visitMethod()`, đây là method được thực thi ngay sau `MethodDiscoveryClassVisitor.visitField()`. Xem lại triển khai của `MethodDiscoveryClassVisitor.visitMethod()`:

```java
@Override
public MethodVisitor visitMethod(int access, String name, String desc, String signature, String[] exceptions) {
    boolean isStatic = (access & Opcodes.ACC_STATIC) != 0;
    // thêm thông tin method vào this.discoveredMethods
    discoveredMethods.add(new MethodReference(
            classHandle, // Tên class
            name,
            desc,
            isStatic));
    return super.visitMethod(access, name, desc, signature, exceptions);
}
```

Gần giống với `MethodDiscoveryClassVisitor.visitField()`, `MethodDiscoveryClassVisitor.visitMethod()` có return type là `MethodVisitor`, nó dùng để truy cập các method của class hiện tại. Class hiện tại được quan sát có bao nhiêu method thì method `MethodDiscoveryClassVisitor.visitMethod()`sẽ được gọi bấy nhiêu lần. Mỗi lần `MethodDiscoveryClassVisitor.visitMethod()` được gọi thì nó sẽ lưu lại thông tin của method vào trong biến `this.discoveredMethods` (biến này có dạng ArrayList).

Cuối cùng xem xét `MethodDiscoveryClassVisitor.visitEnd()`, đây cũng là method được thực thi sau cùng, sau khi thực thi toàn bộ các method `visit()` ở phía trước.

```java
@Override
public void visitEnd() {
    ClassReference classReference = new ClassReference(
            name,
            superName,
            interfaces,
            isInterface,
            members.toArray(new ClassReference.Member[members.size()]));
    // thêm thông tin class vào this.discoveredClasses
    discoveredClasses.add(classReference);

    super.visitEnd();
}
```

Trong `MethodDiscoveryClassVisitor.visitEnd()`, toàn bộ thông tin về class đang được quan sát sẽ được lưu vào `this.discoveredClass`. Các thông tin được lưu vào `this.discoveredClass` có cả thông tin các field thu thập được của class đang được quan sát (điều này có được thông qua biến `members`, mà `members` được tạo ra từ khi thực thi `visitField()`).

Tại thời điểm này, sự thực thi của `MethodDiscover.discover()` đã hoàn thành. Bước tiếp theo sẽ là sự thực thi của `MethodDiscover.save()`, cùng xem triển khai của `MethodDiscover.save()`:

```java
public void save() throws IOException {
    // Việc lưu và đọc được triển khai bởi việc dùng Factory

    /**
     * (-) Định dạng một entry bên trong classes.dat:
     * (+) "Tên class" "Các parent class" "Interface A, Interface B, Interface C"
     * "liệu có phải là interface ko?" "Field 1! Field 1 access! Field 1 type! Field 2! Field 2 access! Field 1 type"
     */
    DataLoader.saveData(Paths.get("classes.dat"), new ClassReference.Factory(), discoveredClasses);
    /**
     * (-) Định dạng một entry bên trong methods.dat:
     * (+) "Tên class" "Tên method" "Method descriptor" "Liệu có phải là static method ko?"
     */
    DataLoader.saveData(Paths.get("methods.dat"), new MethodReference.Factory(), discoveredMethods);

    // Tạo mối quan hệ ánh xạ của tên class
    Map<ClassReference.Handle, ClassReference> classMap = new HashMap<>();
    // Mỗi entry của classMap có dạng {"tên class"="thông tin class"}
    for (ClassReference clazz : discoveredClasses) {
        classMap.put(clazz.getHandle(), clazz);
    }
    /**
     * Khi lưu classes.dat và methods.dat, bên trong Inheritance.derive()
     * dùng đệ quy để tạo thành một InheritanceMap với mỗi entry có dạng { "tên parent class" = ["tên subclass 1, tên subclass 2"] }
     * class is the subclass parent class, super class or implemented interface class, saved to inheritanceMap.dat
    */
    InheritanceDeriver.derive(classMap).save();
}
```

Thông tin class và thông tin method từ trong `this.discoveredClasses` và `this.discoveredMethods` được lưu lại nhờ method `DataLoader.saveData()`. Định dạng thông tin được lưu trữ được triển khai thông qua `ClassReference.Factory()` và `MethodReference.Factory()` (lưu ý Factory là inner class có trong cả class `ClassReference` và class `MethodReference`)

Triển khai của `DataLoader.saveData()`:

```java
public static <T> void saveData(Path filePath, DataFactory<T> factory, Collection<T> values) throws IOException {
    try (BufferedWriter writer = Files.newWriter(filePath.toFile(), StandardCharsets.UTF_8)) {
        for (T value : values) {
            final String[] fields = factory.serialize(value);
            if (fields == null) {
                continue;
            }

            StringBuilder sb = new StringBuilder();
            for (String field : fields) {
                if (field == null) {
                    sb.append("\t");
                } else {
                    sb.append("\t").append(field);
                }
            }
            writer.write(sb.substring(1));
            writer.write("\n");
        }
    }
}
```

Ta thấy tại dòng `final String[] fields = factory.serialize(value);`, dữ liệu sẽ được serialize (lưu ý serialize này không phải serialize trong suốt bài viết mà chỉ là 1 kiểu serialize dữ liệu khác) bằng việc gọi method `serialize()` trên instance của `Factory`. Các đoạn code về sau của method này được dùng để in ra dữ liệu ra thành từng dòng một.

Xem qua method `serialize()` của `ClassReference.Factory`:

```java
public static class Factory implements DataFactory<ClassReference> {
    ...
    @Override
    public String[] serialize(ClassReference obj) {
        String interfaces;
        if (obj.interfaces.length > 0) {
            StringBuilder interfacesSb = new StringBuilder();
            for (String iface : obj.interfaces) {
                interfacesSb.append(",").append(iface);
            }
            interfaces = interfacesSb.substring(1);
        } else {
            interfaces = "";
        }

        StringBuilder members = new StringBuilder();
        for (Member member : obj.members) {
            members.append("!").append(member.getName())
                    .append("!").append(Integer.toString(member.getModifiers()))
                    .append("!").append(member.getType().getName());
        }

        return new String[]{
                obj.name,
                obj.superClass,
                interfaces,
                Boolean.toString(obj.isInterface),
                members.length() == 0 ? null : members.substring(1)
        };
    }
}
```

Cuối cùng, một entry trong file **classes.dat** có dạng: `"Tên class" "Các parent class" "Interface A, Interface B, Interface C" "Liệu có phải là interface ko?" "Field 1! Field 1 access! Field 1 type! Field 2! Field 2 access! Field 1 type"`.

Ví dụ một entry trong file **classes.dat**: `com/oracle/net/Sdp$1   java/lang/Object     java/security/PrivilegedAction   false     val$o!4112!java/lang/reflect/AccessibleObject`

Trong đó:

- `com/oracle/net/Sdp$1`: là tên class
- `java/lang/Object`: là tên các parent class
- `java/security/PrivilegedAction`: là tên interface
- `false`: class này không phải interface
- `val$o!4112!java/lang/reflect/AccessibleObject` :
  - các giá trị được ngăn cách bởi dấu “!”
  - `val$o`: là Field 1
  - `4412`: là Field 1 access
  - `java/lang/reflect/AccessibleObject`: là Field 1 type

Xem qua một chút method `MethodReference.Factory.serialize()`:

```java
public static class Factory implements DataFactory<MethodReference> {
    ...
    @Override
    public String[] serialize(MethodReference obj) {
        return new String[] {
                obj.classReference.getName(),
                obj.name,
                obj.desc,
                Boolean.toString(obj.isStatic),
        };
    }
}
```

Cuối cùng, một entry trong file **methods.dat** có dạng: `"Tên class" "Tên method" "Method descriptor" "Liệu có phải là static method ko?"`

Ví dụ một entry trong file **methods.dat**: `com/oracle/net/Sdp$1 <init>     (Ljava/lang/reflect/AccessibleObject;)V     false`

Trong đó:

- `com/oracle/net/Sdp$1`: là tên class
- `<init>`: là tên method
- `(Ljava/lang/reflect/AccessibleObject;)V`: là method descriptor
- `false` : method này không phải static method

Quay trở lại với `MethodDiscover.save()` thì sau khi thông tin class và method được lưu, thông tin class thu được sẽ được tiếp tục sử dụng để tiến hành phân tích tổng hợp các mối quan hệ triển khai (**implementation**) và kế thừa (**inheritance**) của class.

```java
// Tạo mối quan hệ ánh xạ của tên class
Map<ClassReference.Handle, ClassReference> classMap = new HashMap<>();
// Mỗi entry của classMap có dạng {"tên class"="thông tin class"}
for (ClassReference clazz : discoveredClasses) {
    classMap.put(clazz.getHandle(), clazz);
}
// Khi lưu classes.dat và methods.dat, bên trong Inheritance.derive() dùng đệ quy
// để tạo thành một inheritanceMap với mỗi entry có dạng { "tên parent class" = ["tên subclass 1, tên subclass 2"] } sau đó lưu vào inheritanceMap.dat
InheritanceDeriver.derive(classMap).save();
```

Phần triển khai chính nằm ở method `InheritanceDeriver.derive()` (tại dòng`InheritanceDeriver.derive(classMap).save();`). Cùng xem triển khai của method `InheritanceDeriver.derive()`:

```java
public static InheritanceMap derive(Map<ClassReference.Handle, ClassReference> classMap) {
    LOGGER.debug("Calculating inheritance for " + (classMap.size()) + " classes...");
    // Mỗi entry của implicitInheritance có dạng { "tên class" = ["tên parent class, tên super class, tên interface của class đang làm key"] }
    Map<ClassReference.Handle, Set<ClassReference.Handle>> implicitInheritance = new HashMap<>();
    // Duyệt qua tất cả các class
    for (ClassReference classReference : classMap.values()) {
        // Nếu tên của classReference đã nằm trong key của implicitInheritance thì dừng
        if (implicitInheritance.containsKey(classReference.getHandle())) {
            throw new IllegalStateException("Already derived implicit classes for " + classReference.getName());
        }
        /*
        Tại sao trong classMap đã chứa toàn bộ thông tin như parent class, super class, inteface của class key mà ta vẫn phải
        dùng đến implicitInheritance để lưu thông tin { "tên class" = ["parent class, super class, interface của class đang làm key"] } ?
        */
        Set<ClassReference.Handle> allParents = new HashSet<>();
        // Lấy toàn bộ parent class, super classes, và interface của classReference
        getAllParents(classReference, classMap, allParents);
        // Thêm vào cache (thông qua implicitInheritance)
        implicitInheritance.put(classReference.getHandle(), allParents);
    }
    // một entry của InheritanceMap có dạng { "tên parent class" = ["tên subclass 1, tên subclass 2"] }
    return new InheritanceMap(implicitInheritance);
}
```

Ta thấy đoạn sau gọi tới `InheritanceDeriver.getAllParents()`:

```java
 // Lấy toàn bộ parent class, super classes, và interface của classReference
getAllParents(classReference, classMap, allParents);
```

Cùng xem triển khai của method `InheritanceDeriver.getAllParents()`:

```java
public class InheritanceDeriver {
    ...
    /**
    * Lấy ra toàn bộ parent class, super class, và interface của class đang theo dõi ( chính là classReference)
    * @param classReference chứa thông tin class đang theo dõi
    * @param classMap có dạng { "tên class" = "thông tin class" }
    * @param allParents
    */
    private static void getAllParents(ClassReference classReference, Map<ClassReference.Handle, ClassReference> classMap, Set<ClassReference.Handle> allParents) {
        // Biến parents dùng để chứa "tên" parent class của class hiện tại đang kiểm tra (chính là classReference)
        Set<ClassReference.Handle> parents = new HashSet<>();
        // Thêm "tên" super class vào biến parents nếu class hiện tại đang kiểm tra có super class
        if (classReference.getSuperClass() != null) {
            parents.add(new ClassReference.Handle(classReference.getSuperClass()));
        }
        // Thêm toàn bộ "tên" interface mà class hiện triển khai vào biến parents
        for (String iface : classReference.getInterfaces()) {
            parents.add(new ClassReference.Handle(iface));
        }
        // Từ toàn bộ tập hợp dữ liệu class, duyệt để tìm ra parent class và interface của classReference
        for (ClassReference.Handle immediateParent : parents) {
            // Lấy ra thông tin của immediateParent (lưu ý immediateParent chỉ là "tên của class") từ trong classMap
            ClassReference parentClassReference = classMap.get(immediateParent);
            if (parentClassReference == null) {
                LOGGER.debug("No class id for " + immediateParent.getName());
                continue;
            }
            // Tiếp tục thêm tên của class vừa lấy được từ trong classMap vào biến allParents
            allParents.add(parentClassReference.getHandle());
            // Tiếp tục đệ quy cho tới khi toàn bộ parent class, super class và interface của classReference được thêm vào biến allParents
            getAllParents(parentClassReference, classMap, allParents);
        }
    }
    ...
}
```

Cuối cùng của method `InheritanceDeriver.derive()` sẽ tạo ra 1 instance của `InheritanceMap` với tham số là `implicitInheritance`, một entry trong `implicitInheritance` có dạng `"Tên parent class" "Tên subclass 1” “Tên subclass 2” …`

Đi tiếp tới constructor method `InheritanceMap`:

```java
public class InheritanceMap {
    // Một entry trong inheritanceMap thể hiện quan hệ con-cha
    private final Map<ClassReference.Handle, Set<ClassReference.Handle>> inheritanceMap;
    // Một entry trong subClassMap thể hiện quan hệ cha-con
    private final Map<ClassReference.Handle, Set<ClassReference.Handle>> subClassMap;

    public InheritanceMap(Map<ClassReference.Handle, Set<ClassReference.Handle>> inheritanceMap) {
        // mỗi entry của implicitMap có dạng { "tên class" = ["tên parent class, tên super class, tên interface của class đang làm key"] }
        this.inheritanceMap = inheritanceMap;
        // mỗi entry của subClassMap có dạng { "tên class cha" = ["tên class con 1, tên class con 2"] }
        subClassMap = new HashMap<>();
        for (Map.Entry<ClassReference.Handle, Set<ClassReference.Handle>> entry : inheritanceMap.entrySet()) {
            ClassReference.Handle child = entry.getKey();
            for (ClassReference.Handle parent : entry.getValue()) {
                subClassMap.computeIfAbsent(parent, k -> new HashSet<>()).add(child);
            }
        }
    }
    ...
}
```

Quay trở lại với `MethodDiscovery.save()`:

```java
public class MethodDiscovery {
    ...
    public void save() throws IOException {
        ...
        /**
         * Khi lưu classes.dat và methods.dat, bên trong Inheritance.derive()
         * dùng đệ quy để tạo thành một InheritanceMap với mỗi entry có dạng { "tên parent class" = ["tên subclass 1, tên subclass 2"] }
         * class is the subclass parent class, super class or implemented interface class, saved to inheritanceMap.dat
        */
        InheritanceDeriver.derive(classMap).save();
    }
    ...
}
```

Sau khi gọi `InheritanceDeriver.derive()`, ta có được dữ liệu thể hiện mối quan hệ triển khai và kế thừa là 1 instance của `InheritanceMap`, do đó dữ liệu được lưu bằng cách gọi phương thức `InheritanceMap.save()`

Cùng xem triển khai của `InheritanceMap.save()`:

```java
public class InheritanceMap {
    ...
    public void save() throws IOException {
        DataLoader.saveData(Paths.get("inheritanceMap.dat"), new InheritanceMapFactory(), inheritanceMap.entrySet());
    }
    ...
}
```

Bên trong `InheritanceMap.save()`) tiếp tục gọi `DataLoader.saveData()` và dữ liệu sẽ được serialize bằng việc gọi method `serialize()` trên instance của `InheritanceMapFactory`. `InheritanceMapFactory` là inner class của `InheritanceMap`.

Xem qua method `InheritanceMapFactory.serialize()`:

```java
public class InheritanceMap {
    ...
    private static class InheritanceMapFactory implements DataFactory<Map.Entry<ClassReference.Handle, Set<ClassReference.Handle>>> {
        ...
        @Override
        public String[] serialize(Map.Entry<ClassReference.Handle, Set<ClassReference.Handle>> obj) {
            final String[] fields = new String[obj.getValue().size()+1];
            fields[0] = obj.getKey().getName();
            int i = 1;
            for (ClassReference.Handle handle : obj.getValue()) {
                fields[i++] = handle.getName();
            }
            return fields;
        }
    }
}
```

Cuối cùng, một entry trong file **inheritanceMap.dat** sẽ có dạng: `"Tên class" "Parent class hoặc Super class hoặc Interface thứ 1" "Parent class hoặc Super class hoặc Interface thứ 2" … "Parent class hoặc Super class hoặc Interface thứ n"`

Ví dụ một entry trong file **inheritanceMap.dat**: `sun/management/ManagementFactoryHelper$LoggingMXBean  java/lang/Object     java/lang/management/PlatformLoggingMXBean  java/util/logging/LoggingMXBean     java/lang/management/PlatformManagedObject`

Trong đó:

- `sun/management/ManagementFactoryHelper$LoggingMXBean`: là tên class
- `java/lang/Object` : là tên parent class của class `sun/management/ManagementFactoryHelper$LoggingMXBean`
- `java/lang/management/PlatformLoggingMXBean` : là tên interface mà `sun/management/ManagementFactoryHelper$LoggingMXBean` đã extend
- `java/util/logging/LoggingMXBean` : là tên interface mà `sun/management/ManagementFactoryHelper$LoggingMXBean` triển khai
- `java/lang/management/PlatformManagedObject` : là tên interface mà `java/lang/management/PlatformLoggingMXBean` đã extend

## Bước 2: Discover Passthrough Dataflow

Tiếp tục sang bước 2, đây là đoạn code được thực hiện bên trong method `GadgetInspector.main()`:

```java
public class GadgetInspector {
    ...
    if (!Files.exists(Paths.get("passthrough.dat"))) {
        LOGGER.info("Analyzing methods for passthrough dataflow...");
        PassthroughDiscovery passthroughDiscovery = new PassthroughDiscovery();
        passthroughDiscovery.discover(classResourceEnumerator, config);
        passthroughDiscovery.save();
    }
    ...
}
```

Trong phần này, tôi chủ yếu giải thích cách hoạt động của `PassthroughDiscovery`, đây cũng là phần core của toàn bộ công cụ gadget inspector.

Trước khi nói tiếp về cách thức hoạt động của `PassthroughDiscovery`, tôi muốn đưa ra ví dụ sau:

```java
public void main(String args) throws IOException {
    String cmd = new A().method(args);
    Runtime.getRuntime().exec(cmd);
}

class A {
  public String method(String param) {
    return param;
  }
}
```

Từ đoạn code trên, ta có thể thấy class `A` và method tên `method()`. Sau khi method `A.method()` được truyền parameter `param` vào, nó return giá trị của parameter `para` vừa được truyền, sau đó giá trị được return này được gán cho biến `cmd` tại dòng `String cmd = new A().method(args);` trong method `main()` và cuối cùng method `Runtime.getRuntime().exec()` sẽ thực thi lệnh bên trong biến `cmd` (trong Java, đây là method nguy hiểm có thể dẫn tới hậu quả là RCE).

Ta có thể thấy, miễn là ta có thể kiểm soát các tham số đầu vào của method, ta có thể kiểm soát giá trị trả về của phương thức của nó và kiểm soát luồng dữ liệu đến `Runtime.exec()`. Việc này giống như taint analysis và trong giai đoạn xử lý của class `PassthroughDiscovery` thì điều quan trọng nhất là thực hiện được một việc như vậy. Việc này được thực hiện bằng cách liên tục **analyze** tất cả các method, xem liệu chúng có bị ảnh hưởng bởi các parameter đầu vào hay không?

Ngoài ra, việc luồng dữ liệu (**data flow**) được truyền thông qua method không chỉ một hoặc hai layer mà có thể liên quan đến nhiều method trong toàn bộ gadget chain. Sau đó, để tiến hành **taint analysis** của tất cả các **data flow** của method, thứ tự analysis sẽ là điều kiện tiên quyết để có thể thành công. Để giải thích, ta tiếp tục với một ví dụ:

```java
public void main(String args) throws IOException {
    String cmd = new A().method1(args);
    new B().method2(cmd);
}
class A {
  public String method1(String param) {
    return param;
  }
}
class B {
  public void method2(String param) throws IOException {
    new C().method3(param);
  }
}
class C {
  public void method3(String param) throws IOException {
    Runtime.getRuntime().exec(param);
  }
}
```

Trong đoạn code trên, có thể thấy quy trình cụ thể giữa **source** và **sink**. Sau quá trình **taint analysis** các **data flow**, chúng ta có thể nhận được kết quả (cách thể hiện kết quả như vậy giống cách tác giả Ian Haken thể hiện trong paper):

> A.method1()-&gt;1
>
> B.method2()-&gt;1
>
> C.method3()-&gt;1

Con số **1** đứng sau **A.method1()-&gt;** biểu thị cho việc **parameter 1** kiểm soát **return value** của **A.method1()**.

Việc đánh số cho **parameter** có quy tắc như sau:

- biến `this` của class sẽ được tính là **parameter 0**.
- các tham số được truyền vào hàm sẽ được tính tăng dần từ 1. Ví dụ: nếu `public String method1(String param)` thì `param` tính là **parameter 1**, còn nếu `public String method1(String param, Int age)` thì `param` tính là **parameter 1** còn `age` tính là **parameter 2**.

Từ việc phân tích code, vì chúng ta có thể kiểm soát các **parameter** của `A.method1()` và **return value** của nó cũng được điều khiển gián tiếp bởi các **parameter**.

- **Return value** của `A.method1()` sau đó được gán cho biến `cmd` tại dòng `String cmd = new A().method1(args);`, điều đó có nghĩa là ta cũng có thể kiểm soát biến `cmd`.
- Sau đó dòng `new B().method2(cmd);` lại gọi `B.method2()`, biến `cmd` được sử dụng làm **parameter** cho `B.method2()` và nó lại tiếp tục được làm **parameter** của `C.method3()` và cuối cùng nó chạm tới `Runtime.getRuntime().exec(param)`. Điều này có nghĩa là miễn là chúng ta có thể kiểm soát `A.method1()` thì tới cuối cùng chúng ta có thể sử dụng dữ liệu này để tác động đến toàn bộ source-&gt;sink và cuối cùng thực hiện RCE.

Từ luồng code trên, miễn là ta biết tham số nào có thể bị ô nhiêm (**tainted)** bởi method `A.method1()`, method `B.method2()` và method `C.method3()` thì ta có thể xác định việc lây lan sự ô nhiễm (**tainted transfer**) từ **sink** đến **source**. Tuy nhiên, có một vấn đề ở đây đó là: trước khi nhận được kết quả là các **parameter** của `B.method2()` đã bị **tainted**, trước tiên ta phải nhận được kết quả là các **parameter** của `C.method3()` đã bị **tainted**. Cụ thể thực hiện việc này như thế nào? Trong Gadget Inspector, DTS được sử dụng. Đây là một phương pháp sắp xếp đảo ngược topology (**inverse topological sorting**).

Về **inverse topological sorting**, đầu tiên chúng ta nhận được một `Set` chứa các method được sắp xếp theo thứ tự ngược lại của chuỗi method call. Sau đó, thực hiện quá trình **taint analysis** từ tham số ở cuối và thực hiện đảo ngược. Tức là, trước tiên ta xác nhận các tham số của `C.method3()` bị tainted và lưu đây lại xác nhận này. Khi analyze `B.method2()`, chúng ta có thể tiếp tục phân tích dựa trên xác nhận thu được trước đó là `C.method3()` bị tainted và cuối cùng thu được xác nhận rằng `B.method2()` cũng bị tainted. Vậy tool thực hiện **inverse topological sorting** như thế nào, ta xem tiếp code triển khai của `PassthroughDiscovery.discover()`:

```java
public class PassthroughDiscovery {
    ...
    private Map<MethodReference.Handle, Set<Integer>> passthroughDataflow;

    public void discover(final ClassResourceEnumerator classResourceEnumerator, final GIConfig config) throws IOException {
        // Tải toàn bộ thông tin các method được lưu trong file
        Map<MethodReference.Handle, MethodReference> methodMap = DataLoader.loadMethods();
        // Tải toàn bộ thông tin các class được lưu trong file
        Map<ClassReference.Handle, ClassReference> classMap = DataLoader.loadClasses();
        // Tải toàn bộ thông tin liên quan đến kế thừa và triển khai của class được lưu trong file
        InheritanceMap inheritanceMap = InheritanceMap.load();

        // Tìm kiếm mối quan hệ gọi - được gọi giữa các method, lưu nó vào methodCalls, methodCalls có dạng {"tên class"="tài nguyên class"}
        Map<String, ClassResourceEnumerator.ClassResource> classResourceByName = discoverMethodCalls(classResourceEnumerator);
        List<MethodReference.Handle> sortedMethods = topologicallySortMethodCalls();
        passthroughDataflow = calculatePassthroughDataflow(classResourceByName, classMap, inheritanceMap, sortedMethods,
                config.getSerializableDecider(methodMap, inheritanceMap));
    }
    ...
}
```

Có thể thấy rằng ba thao tác đầu tiên `PassthroughDiscovery.discover()` làm là tải các class, method và thông tin triển khai & kế thừa từ file.

Tiếp theo, dòng `Map<String, ClassResourceEnumerator.ClassResource> classResourceByName = discoverMethodCalls(classResourceEnumerator);` gọi method `PassthroughDiscovery.discoverMethodCalls()` để sắp xếp tập hợp ánh xạ giữa tất cả các method, method của **caller method** và method của **callee method**.

Cùng xem `PassthroughDiscovery.discoverMethodCalls()`:

```java
public class PassthroughDiscovery {
    ...
    private Map<String, ClassResourceEnumerator.ClassResource> discoverMethodCalls(final ClassResourceEnumerator classResourceEnumerator) throws IOException {
        Map<String, ClassResourceEnumerator.ClassResource> classResourcesByName = new HashMap<>();
        for (ClassResourceEnumerator.ClassResource classResource : classResourceEnumerator.getAllClasses()) {
            try (InputStream in = classResource.getInputStream()) {
                ClassReader cr = new ClassReader(in);
                try {
                    MethodCallDiscoveryClassVisitor visitor = new MethodCallDiscoveryClassVisitor(Opcodes.ASM6);
                    cr.accept(visitor, ClassReader.EXPAND_FRAMES);
                    classResourcesByName.put(visitor.getName(), classResource);
                } catch (Exception e) {
                    LOGGER.error("Error analyzing: " + classResource.getName(), e);
                }
            }
        }
        return classResourcesByName;
    }
    ...
}
```

Dòng `MethodCallDiscoveryClassVisitor visitor = new MethodCallDiscoveryClassVisitor(Opcodes.ASM6);` sử dụng `MethodCallDiscoveryClassVisitor`(được extend từ `ClassVisitor`) mục đích để thu thập các method call.

Cùng xem `MethodCallDiscoveryClassVisitor`:

```java
public class PassthroughDiscovery {
    ...
    private class MethodCallDiscoveryClassVisitor extends ClassVisitor {
        public MethodCallDiscoveryClassVisitor(int api) {
            super(api);
        }

        private String name = null;

        @Override
        public void visit(int version, int access, String name, String signature,
                          String superName, String[] interfaces) {
            super.visit(version, access, name, signature, superName, interfaces);
            if (this.name != null) {
                throw new IllegalStateException("ClassVisitor already visited a class!");
            }
            this.name = name;
        }

        public String getName() {
            return name;
        }

        @Override
        public MethodVisitor visitMethod(int access, String name, String desc,
                                         String signature, String[] exceptions) {
            MethodVisitor mv = super.visitMethod(access, name, desc, signature, exceptions);
            // Mỗi khi visit 1 method, ta tạo 1 MethodVisitor để theo dõi method đó.
            // MethodCallDiscoveryMethodVisitor là class được extends từ MethodVisitor
            MethodCallDiscoveryMethodVisitor modelGeneratorMethodVisitor = new MethodCallDiscoveryMethodVisitor(
                    api, mv, this.name, name, desc);

            return new JSRInlinerAdapter(modelGeneratorMethodVisitor, access, name, desc, signature, exceptions);
        }

        @Override
        public void visitEnd() {
            super.visitEnd();
        }
    }
    ...
}
```

Trình tự thực thi của method bên trong `MethodCallDiscoveryClassVisitor` là: `visit()` -&gt; `visitMethod()` -&gt; `visitEnd()`. Cụ thể:

- `visit()`: Trong method này, tên class hiện đang được quan sát được gán cho `this.name`
- `visitMethod()`: Trong method này ở dòng `MethodCallDiscoveryMethodVisitor modelGeneratorMethodVisitor = new MethodCallDiscoveryMethodVisitor(api, mv, this.name, name, desc);`, nó tiếp tục quan sát thêm chi tiết từng method của class đang được quan sát thông qua `MethodCallDiscoveryMethodVisitor` (được extend từ `MethodVisitor`)

Mỗi khi method đang được theo dõi bên trong `visitMethod()` gọi một method khác thì `MethodCallDiscoveryMethodVisitor.visitMethodInsn()` sẽ được thực thi. Ta cùng xem triển khai của `MethodCallDiscoveryMethodVisitor`:

```java
public class PassthroughDiscovery {
    ...
    private class MethodCallDiscoveryMethodVisitor extends MethodVisitor {
        private final Set<MethodReference.Handle> calledMethods;

        public MethodCallDiscoveryMethodVisitor(final int api, final MethodVisitor mv,
                                           final String owner, String name, String desc) {
            super(api, mv);

            this.calledMethods = new HashSet<>();
            methodCalls.put(new MethodReference.Handle(new ClassReference.Handle(owner), name, desc), calledMethods);
        }

        @Override
        public void visitMethodInsn(int opcode, String owner, String name, String desc, boolean itf) {
            calledMethods.add(new MethodReference.Handle(new ClassReference.Handle(owner), name, desc));
            super.visitMethodInsn(opcode, owner, name, desc, itf);
        }
    }
    ...
}
```

Tôi đã comment khá chi tiết tại đây. Khi constructor method của class `MethodCallDiscoveryMethodVisitor` được thực thi thì `this.calledMethods` ở dòng `private final Set<MethodReference.Handle> calledMethods;` sẽ được khởi tạo. `this.calledMethods` có scope là private nằm bên trong `MethodCallDiscoveryMethodVisitor`. Ta biết mỗi khi method đang được quan sát từ bước `MethodCallDiscoveryClassVisitor.visitMethod()` gọi tới 1 method nào đó thì `MethodCallDiscoveryMethodVisitor.visitMethodInsn()` sẽ được gọi. Lúc đó nhiệm vụ của `this.calledMethods` là lưu thông tin method được gọi.

Sau cùng, các thông tin của method đang được theo dõi sẽ được lưu vào `methodCalls` (lí do bởi là biến `methodCalls` có scope nằm tại class `PassthroughDiscovery` nên sẽ thuận tiện cho các method khác cùng nằm trong class `PassthroughDiscovery` truy cập), `methodCalls` được lưu theo dạng: `{“tên class của method đang được theo dõi, tên của method đang được theo dõi, method descriptor của method đang được theo dõi” = “tên class của method được method đang theo dõi gọi, tên của method được gọi, method descriptor của method được gọi”}`

Quay trở lại với `PassthroughDiscovery.discover()`, sau khi thực thi xong `Map<String, ClassResourceEnumerator.ClassResource> classResourceByName = discoverMethodCalls(classResourceEnumerator);` thì sau đó thực hiện `List<MethodReference.Handle> sortedMethods = topologicallySortMethodCalls();`, ta thấy ở đây gọi đến method `topologicallySortMethodCalls()`:

Cùng xem triển khai của `topologicallySortMethodCalls()`:

```java
public class PassthroughDiscovery {
    ...
    private List<MethodReference.Handle> topologicallySortMethodCalls() {
        Map<MethodReference.Handle, Set<MethodReference.Handle>> outgoingReferences = new HashMap<>();
        for (Map.Entry<MethodReference.Handle, Set<MethodReference.Handle>> entry : methodCalls.entrySet()) {
            MethodReference.Handle method = entry.getKey();
            outgoingReferences.put(method, new HashSet<>(entry.getValue()));
        }

        // Inverse topological sorting
        LOGGER.debug("Performing topological sort...");
        Set<MethodReference.Handle> dfsStack = new HashSet<>();
        Set<MethodReference.Handle> visitedNodes = new HashSet<>();
        List<MethodReference.Handle> sortedMethods = new ArrayList<>(outgoingReferences.size());
        for (MethodReference.Handle root : outgoingReferences.keySet()) {
            dfsTsort(outgoingReferences, sortedMethods, visitedNodes, dfsStack, root);
        }
        LOGGER.debug(String.format("Outgoing references %d, sortedMethods %d", outgoingReferences.size(), sortedMethods.size()));

        return sortedMethods;
    }
    ...
}
```

Đoạn dưới được sử dụng để chuyển cấu trúc dữ liệu của `methodCalls` sang dạng `Map<MethodReference.Handle, Set<MethodReference.Handle>>` và lưu vào `outgoingReferences`

```java
Map<MethodReference.Handle, Set<MethodReference.Handle>> outgoingReferences = new HashMap<>();
for (Map.Entry<MethodReference.Handle, Set<MethodReference.Handle>> entry : methodCalls.entrySet()) {
    MethodReference.Handle method = entry.getKey();
    outgoingReferences.put(method, new HashSet<>(entry.getValue()));
}
```

Tiếp tục, đoạn dưới gọi tới method `dfsTsort()` để thực hiện **inverse topological sorting**.

```java
for (MethodReference.Handle root : outgoingReferences.keySet()) {
    dfsTsort(outgoingReferences, sortedMethods, visitedNodes, dfsStack, root);
}
```

Trước khi nói tiếp về **inverse topology sorting** thì tôi sẽ nói qua 1 chút về topology sorting: việc sắp xếp theo cấu trúc liên kết (**topology sorting**) chỉ khả dụng cho các biểu đồ theo chu kỳ có hướng (directed acyclic graphs - DAG), các biểu đồ không phải DAG không có khả năng sử dụng topology sorting.

DAG phải thỏa mãn các điều kiện sau:

- Mỗi đỉnh xuất hiện và chỉ xuất hiện một lần
- Nếu A đứng trước B trong dãy thì không có đường đi từ B đến A như trên hình.

{% asset_img 2.jpeg %}

Đồ thị như vậy là đồ thị topo có thứ tự. Cấu trúc tree thực sự có thể được chuyển thành phân loại topo, trong khi phân loại topo không nhất thiết phải chuyển thành cây.

Lấy sơ đồ sắp xếp topo ở trên làm ví dụ, sử dụng dictionary (trong python) để biểu diễn cấu trúc biểu đồ:

```python
graph = {
     "a": ["b","d"],
     "b": ["c"],
     "d": ["e","c"],
     "e": ["c"],
     "c": [],
 }
```

Code triển khai:

```python
graph = {
    "a": ["b","d"],
    "b": ["c"],
    "d": ["e","c"],
    "e": ["c"],
    "c": [],
}
def TopologicalSort(graph):
  degrees = dict((u, 0) for u in graph)
  for u in graph:
      for v in graph[u]:
          degrees[v] += 1
  #Insert queue with zero degree of entry
  queue = [u for u in graph if degrees[u] == 0]
  res = []
  while queue:
      u = queue.pop()
      res.append(u)
      for v in graph[u]:
          # Remove the edge, the intrinsic degree of the current element related element -1
          degrees[v] -= 1
          if degrees[v] == 0:
              queue.append(v)
  return res

print(TopologicalSort(graph)) # ['a', 'd', 'e', 'b', 'c']
```

Nhưng trong method call, chúng ta hy vọng kết quả cuối cùng là `['c', 'b', 'e', 'd', 'a']`,ngược lại với `['a', 'd', 'e', 'b', 'c']`. Bước này yêu cầu ta phải sử dụng **inverse topological sorting**, sắp xếp thuận dùng BFS thì kết quả ngược lại mới có thể sử dụng DFS. Tại sao chúng ta cần sử dụng **inverse topological sorting** trong method call, điều này có liên quan đến việc tạo luồng dữ liệu **Passthrough**. Hãy xem ví dụ sau:

```java
...
    public String parentMethod(String arg){
        String vul = Obj.childMethod(arg);
        return vul;
    }
...
```

Vậy có mối quan hệ nào giữa `arg` và **return type** không? Giả sử `Obj.childMethod` là:

```java
...
    public String childMethod(String carg){
        return carg.toString();
    }
...
```

Vì **return value** của `childMethod()` có liên quan đến param `carg` nên có thể xác định rằng **return value** của `parentMethod` có liên quan đến param `arg`. Vì vậy, nếu có một lệnh gọi **sub-method** và truyền param của **parent-method** cho **sub-method** đó, trước tiên cần xác định mối quan hệ giữa **giá trị trả về** của **sub-method** và đối số của **sub-method**. Do đó, việc đánh giá **sub-method** cần phải được thực hiện trước, đó là lý do tại sao việc **inverse topological sorting** được thực hiện.

Như bạn có thể thấy trong hình bên dưới, cấu trúc dữ liệu của `outgoingReferences`trong method `topologicallySortMethodCalls()` là:

{% asset_img 3.jpeg %}

Nhưng ở trên đã nói rằng topology không thể tạo thành một vòng khi sắp xếp mà phải có một vòng trong chuỗi method call.

Cùng xem triển khai của `dfsTsort()` để thấy tác giả tránh được bằng cách nào.

```java
public class PassthroughDiscovery {
    ...
    private static void dfsTsort(Map<MethodReference.Handle, Set<MethodReference.Handle>> outgoingReferences,
                                    List<MethodReference.Handle> sortedMethods, Set<MethodReference.Handle> visitedNodes,
                                    Set<MethodReference.Handle> stack, MethodReference.Handle node) {
        // Ngăn chặn việc truy cập vào vòng lặp trong chuỗi method call của dfs
        if (stack.contains(node)) {
            return;
        }
        // Ngăn chặn việc sắp xếp lại một method và sub-method
        if (visitedNodes.contains(node)) {
            return;
        }
        // Theo start method, lấy ra 1 set các method đc gọi
        Set<MethodReference.Handle> outgoingRefs = outgoingReferences.get(node);
        if (outgoingRefs == null) {
            return;
        }
        // Đẩy lên trên stack để phép đệ quy không gây ra sự tích hợp vòng lặp vô hạn như tham chiếu vòng (circular).
        stack.add(node);
        for (MethodReference.Handle child : outgoingRefs) {
            dfsTsort(outgoingReferences, sortedMethods, visitedNodes, stack, child);
        }
        stack.remove(node);
        // Ghi lại các method đã được visit để có thể bỏ qua chúng khi gặp các method trùng lặp trong các layer phía trên.
        visitedNodes.add(node);
        // Sau khi việc thăm dò hoàn tất theo cách đệ quy, node sẽ được thêm vào sortedMethods
        sortedMethods.add(node);
    }
    ...
}
```

- biến `dfsStack` đảm bảo rằng các vòng lặp không được hình thành khi thực hiện **inverse topological sorting**.
- biến `visitedNodes` tránh việc sắp xếp lặp lại khi chuỗi method call bị chồng chéo.
- biến `sortedMethods` là kết quả cuối cùng sau khi thực hiện **inverse topological sorting**.

Sử dụng biểu đồ call graph sau để minh họa quy trình xử lý bên trong method `dfsTsort()` :

## Bước 3: Enumerate Passthrough Callgraph

## Bước 4: Enumerate Sources Using Know Tricks

## Bước 5: BFS on Call Graph for Chains

# Tham khảo

- [https://testanull.com/the-art-of-deserialization-gadget-hunting-part-3-how-i-found-cve-2020-2555-by-known-tools-67819b29cb63](https://testanull.com/the-art-of-deserialization-gadget-hunting-part-3-how-i-found-cve-2020-2555-by-known-tools-67819b29cb63)
- [https://paper.seebug.org/1046/](https://paper.seebug.org/1046/)
- [https://xz.aliyun.com/t/7058](https://xz.aliyun.com/t/7058)

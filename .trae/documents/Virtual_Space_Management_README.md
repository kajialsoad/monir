# 🌐 DWH Crush APK - Virtual Space Management

## 🎯 ওভারভিউ

Virtual Space Management হলো DWH Crush APK এর একটি মূল কম্পোনেন্ট যা প্রতিটি ক্লোনড অ্যাপের জন্য আলাদা ভার্চুয়াল এনভায়রনমেন্ট তৈরি করে। এই সিস্টেম নিশ্চিত করে যে প্রতিটি অ্যাপ ইনস্ট্যান্স সম্পূর্ণ আলাদা স্পেসে চলে এবং একে অপরের সাথে interference না করে।

## 🏗️ আর্কিটেকচার

### Core Components
- **Virtual Environment Engine**: ভার্চুয়াল এনভায়রনমেন্ট তৈরি ও পরিচালনা
- **Sandbox Manager**: স্যান্ডবক্স আইসোলেশন সিস্টেম
- **Resource Virtualizer**: সিস্টেম রিসোর্স ভার্চুয়ালাইজেশন
- **Context Switcher**: ভার্চুয়াল কনটেক্সট স্যুইচিং

### File Structure
```
smali_classes2/com/lody/virtual/
├── client/
│   ├── env/
│   │   ├── VirtualRuntime.smali
│   │   └── SpecialComponentList.smali
│   ├── stub/
│   │   ├── StubManifest.smali
│   │   └── ShadowContext.smali
│   └── fixer/
│       ├── ComponentFixer.smali
│       └── ContextFixer.smali
├── server/
│   ├── interfaces/
│   │   ├── IVirtualLocationManager.smali
│   │   └── IVirtualStorageManager.smali
│   └── bit64/
│       └── VirtualMachine64.smali
└── helper/
    ├── compat/
    │   ├── BuildCompat.smali
    │   └── BundleCompat.smali
    └── utils/
        ├── VLog.smali
        └── Reflect.smali
```

## ⚙️ সেটআপ এবং কনফিগারেশন

### 1. Virtual Runtime ইনিশিয়ালাইজেশন

```smali
# VirtualRuntime.smali
.method public static startup(Landroid/content/Context;)V
    .locals 3
    
    # Virtual environment context তৈরি করা
    invoke-static {p0}, Lcom/lody/virtual/client/env/VirtualRuntime;->createVirtualContext(Landroid/content/Context;)Landroid/content/Context;
    move-result-object v0
    
    # Runtime environment setup
    sput-object v0, Lcom/lody/virtual/client/env/VirtualRuntime;->sVirtualContext:Landroid/content/Context;
    
    # Component list initialize করা
    invoke-static {}, Lcom/lody/virtual/client/env/SpecialComponentList;->initializeComponents()V
    
    # Virtual machine start করা
    invoke-static {v0}, Lcom/lody/virtual/client/env/VirtualRuntime;->startVirtualMachine(Landroid/content/Context;)V
    
    return-void
.end method
```

### 2. Sandbox Environment Creation

```smali
# ShadowContext.smali
.method public createSandboxEnvironment(Ljava/lang/String;I)Landroid/content/Context;
    .locals 5
    
    # Sandbox directory তৈরি করা
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    
    const-string v1, "/data/data/virtual_sandbox_"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v2, "/"
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v3
    
    # Sandbox context তৈরি করা
    invoke-direct {p0, v3}, Lcom/lody/virtual/client/stub/ShadowContext;->createIsolatedContext(Ljava/lang/String;)Landroid/content/Context;
    move-result-object v4
    
    # Security permissions apply করা
    invoke-direct {p0, v4, p1}, Lcom/lody/virtual/client/stub/ShadowContext;->applySandboxSecurity(Landroid/content/Context;Ljava/lang/String;)V
    
    return-object v4
.end method
```

## 🔧 প্রধান ফিচারসমূহ

### 1. Virtual Storage Management

#### Storage Isolation
```smali
# IVirtualStorageManager.smali
.method public createVirtualStorage(Ljava/lang/String;I)Ljava/lang/String;
    .locals 4
    
    # Virtual storage path generate করা
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    
    const-string v1, "/storage/emulated/virtual_"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v2, "/"
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v3
    
    # Directory তৈরি করা
    new-instance v4, Ljava/io/File;
    invoke-direct {v4, v3}, Ljava/io/File;-><init>(Ljava/lang/String;)V
    invoke-virtual {v4}, Ljava/io/File;->mkdirs()Z
    
    # Permissions set করা
    const/16 v5, 0x1c0  # 0700 permissions
    invoke-virtual {v4, v5}, Ljava/io/File;->setReadable(ZZ)Z
    invoke-virtual {v4, v5}, Ljava/io/File;->setWritable(ZZ)Z
    invoke-virtual {v4, v5}, Ljava/io/File;->setExecutable(ZZ)Z
    
    return-object v3
.end method
```

#### File System Redirection
```smali
# ComponentFixer.smali
.method public redirectFileAccess(Ljava/lang/String;I)Ljava/lang/String;
    .locals 6
    
    # Original path check করা
    const-string v0, "/data/data/"
    invoke-virtual {p1, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v1
    if-eqz v1, :cond_redirect
    
    # Virtual path এ redirect করা
    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V
    
    const-string v3, "/data/data/virtual_"
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    
    # Original path এর package name extract করা
    const/16 v4, 0xb  # "/data/data/" length
    invoke-virtual {p1, v4}, Ljava/lang/String;->substring(I)Ljava/lang/String;
    move-result-object v5
    invoke-virtual {v2, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v6
    return-object v6
    
    :cond_redirect
    return-object p1
.end method
```

### 2. Virtual Location Management

#### GPS Spoofing
```smali
# IVirtualLocationManager.smali
.method public setVirtualLocation(IDDI)V
    .locals 8
    
    # Virtual location data structure তৈরি করা
    new-instance v0, Lcom/lody/virtual/server/interfaces/VirtualLocation;
    invoke-direct {v0}, Lcom/lody/virtual/server/interfaces/VirtualLocation;-><init>()V
    
    # Instance ID set করা
    iput p1, v0, Lcom/lody/virtual/server/interfaces/VirtualLocation;->instanceId:I
    
    # Latitude এবং Longitude set করা
    iput-wide p2, v0, Lcom/lody/virtual/server/interfaces/VirtualLocation;->latitude:D
    iput-wide p4, v0, Lcom/lody/virtual/server/interfaces/VirtualLocation;->longitude:D
    
    # Accuracy set করা
    iput p6, v0, Lcom/lody/virtual/server/interfaces/VirtualLocation;->accuracy:I
    
    # Location cache এ store করা
    iget-object v1, p0, Lcom/lody/virtual/server/interfaces/IVirtualLocationManager;->locationCache:Ljava/util/Map;
    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v2
    invoke-interface {v1, v2, v0}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
    
    return-void
.end method
```

### 3. Context Switching

#### Virtual Context Management
```smali
# ContextFixer.smali
.method public switchVirtualContext(Landroid/content/Context;I)Landroid/content/Context;
    .locals 5
    
    # Current context backup করা
    iget-object v0, p0, Lcom/lody/virtual/client/fixer/ContextFixer;->contextStack:Ljava/util/Stack;
    invoke-virtual {v0, p1}, Ljava/util/Stack;->push(Ljava/lang/Object;)Ljava/lang/Object;
    
    # Virtual context retrieve করা
    iget-object v1, p0, Lcom/lody/virtual/client/fixer/ContextFixer;->virtualContexts:Ljava/util/Map;
    invoke-static {p2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v2
    invoke-interface {v1, v2}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;
    move-result-object v3
    check-cast v3, Landroid/content/Context;
    
    if-nez v3, :cond_create
    # নতুন virtual context তৈরি করা
    invoke-direct {p0, p1, p2}, Lcom/lody/virtual/client/fixer/ContextFixer;->createVirtualContext(Landroid/content/Context;I)Landroid/content/Context;
    move-result-object v3
    invoke-interface {v1, v2, v3}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
    
    :cond_create
    # Context switch করা
    invoke-direct {p0, v3}, Lcom/lody/virtual/client/fixer/ContextFixer;->activateContext(Landroid/content/Context;)V
    
    return-object v3
.end method
```

## 🛠️ কাস্টমাইজেশন

### Virtual Space Configuration

`virtualSpaceConfig.json` ফাইল এডিট করুন:

```json
{
  "virtualSpaces": {
    "maxSpaces": 10,
    "isolationLevel": "strict",
    "resourceLimits": {
      "memory": "512MB",
      "storage": "2GB",
      "cpu": "50%"
    },
    "networking": {
      "isolated": true,
      "vpnSupport": true,
      "proxySettings": {
        "enabled": false,
        "host": "",
        "port": 0
      }
    },
    "location": {
      "spoofing": true,
      "defaultLocation": {
        "latitude": 0.0,
        "longitude": 0.0
      }
    }
  },
  "security": {
    "encryption": true,
    "accessControl": "strict",
    "auditLogging": true
  },
  "performance": {
    "lazyLoading": true,
    "caching": true,
    "compression": true
  }
}
```

### Custom Virtual Environment

```smali
# CustomVirtualEnvironment.smali
.method public createCustomEnvironment(Ljava/lang/String;Ljava/util/Map;)Landroid/content/Context;
    .locals 6
    
    # Base virtual context তৈরি করা
    invoke-static {}, Lcom/lody/virtual/client/env/VirtualRuntime;->getVirtualContext()Landroid/content/Context;
    move-result-object v0
    
    # Custom properties apply করা
    invoke-interface {p2}, Ljava/util/Map;->entrySet()Ljava/util/Set;
    move-result-object v1
    invoke-interface {v1}, Ljava/util/Set;->iterator()Ljava/util/Iterator;
    move-result-object v2
    
    :goto_loop
    invoke-interface {v2}, Ljava/util/Iterator;->hasNext()Z
    move-result v3
    if-eqz v3, :cond_end
    
    invoke-interface {v2}, Ljava/util/Iterator;->next()Ljava/lang/Object;
    move-result-object v4
    check-cast v4, Ljava/util/Map$Entry;
    
    # Property apply করা
    invoke-interface {v4}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;
    move-result-object v5
    check-cast v5, Ljava/lang/String;
    invoke-interface {v4}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;
    move-result-object v6
    
    invoke-direct {p0, v0, v5, v6}, Lcom/lody/virtual/client/env/CustomVirtualEnvironment;->applyProperty(Landroid/content/Context;Ljava/lang/String;Ljava/lang/Object;)V
    
    goto :goto_loop
    
    :cond_end
    return-object v0
.end method
```

## 🔍 ডিবাগিং এবং ট্রাবলশুটিং

### Common Issues

#### 1. Virtual Space Creation Failed
```bash
# Virtual space logs check করুন
adb logcat | grep "VirtualRuntime"

# Expected output:
I/VirtualRuntime: Creating virtual space for package: com.example.app
I/VirtualRuntime: Virtual context initialized successfully
I/VirtualRuntime: Sandbox environment created
```

#### 2. Context Switching Problems
```smali
# Debug method add করুন ContextFixer.smali এ
.method private debugContextSwitch(Landroid/content/Context;I)V
    .locals 4
    
    const-string v0, "VirtualSpace"
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    const-string v2, "Switching to virtual context for instance: "
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v3, " Context: "
    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {p1}, Ljava/lang/Object;->toString()Ljava/lang/String;
    move-result-object v4
    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v5
    invoke-static {v0, v5}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    
    return-void
.end method
```

### Performance Monitoring

#### Resource Usage Tracking
```smali
# ResourceMonitor.smali
.method public monitorVirtualSpaceUsage(I)Lcom/lody/virtual/server/interfaces/ResourceUsage;
    .locals 5
    
    new-instance v0, Lcom/lody/virtual/server/interfaces/ResourceUsage;
    invoke-direct {v0}, Lcom/lody/virtual/server/interfaces/ResourceUsage;-><init>()V
    
    # Memory usage calculate করা
    invoke-direct {p0, p1}, Lcom/lody/virtual/server/interfaces/ResourceMonitor;->calculateMemoryUsage(I)J
    move-result-wide v1
    iput-wide v1, v0, Lcom/lody/virtual/server/interfaces/ResourceUsage;->memoryUsage:J
    
    # Storage usage calculate করা
    invoke-direct {p0, p1}, Lcom/lody/virtual/server/interfaces/ResourceMonitor;->calculateStorageUsage(I)J
    move-result-wide v3
    iput-wide v3, v0, Lcom/lody/virtual/server/interfaces/ResourceUsage;->storageUsage:J
    
    # CPU usage calculate করা
    invoke-direct {p0, p1}, Lcom/lody/virtual/server/interfaces/ResourceMonitor;->calculateCpuUsage(I)F
    move-result v4
    iput v4, v0, Lcom/lody/virtual/server/interfaces/ResourceUsage;->cpuUsage:F
    
    return-object v0
.end method
```

## 🚀 Advanced Features

### 1. Virtual Network Management
```smali
# VirtualNetworkManager.smali
.method public createVirtualNetwork(I)Lcom/lody/virtual/server/interfaces/VirtualNetwork;
    .locals 4
    
    new-instance v0, Lcom/lody/virtual/server/interfaces/VirtualNetwork;
    invoke-direct {v0, p1}, Lcom/lody/virtual/server/interfaces/VirtualNetwork;-><init>(I)V
    
    # Virtual IP range assign করা
    const-string v1, "192.168.100."
    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    add-int/lit8 v3, p1, 0x1
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v4
    
    invoke-virtual {v0, v4}, Lcom/lody/virtual/server/interfaces/VirtualNetwork;->setVirtualIP(Ljava/lang/String;)V
    
    # Network isolation enable করা
    const/4 v5, 0x1
    invoke-virtual {v0, v5}, Lcom/lody/virtual/server/interfaces/VirtualNetwork;->setIsolated(Z)V
    
    return-object v0
.end method
```

### 2. Virtual Device Information
```smali
# VirtualDeviceManager.smali
.method public generateVirtualDeviceInfo(I)Lcom/lody/virtual/server/interfaces/VirtualDeviceInfo;
    .locals 6
    
    new-instance v0, Lcom/lody/virtual/server/interfaces/VirtualDeviceInfo;
    invoke-direct {v0}, Lcom/lody/virtual/server/interfaces/VirtualDeviceInfo;-><init>()V
    
    # Virtual IMEI generate করা
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    const-string v2, "86"
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    
    # Random digits add করা
    const/4 v3, 0x0
    :goto_loop
    const/16 v4, 0xd
    if-ge v3, v4, :cond_end
    
    invoke-static {}, Ljava/lang/Math;->random()D
    move-result-wide v5
    const-wide/high16 v7, 0x4024000000000000L  # 10.0
    mul-double v5, v5, v7
    double-to-int v8, v5
    invoke-virtual {v1, v8}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    
    add-int/lit8 v3, v3, 0x1
    goto :goto_loop
    
    :cond_end
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v9
    invoke-virtual {v0, v9}, Lcom/lody/virtual/server/interfaces/VirtualDeviceInfo;->setIMEI(Ljava/lang/String;)V
    
    # Virtual Android ID generate করা
    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;
    move-result-object v10
    invoke-virtual {v10}, Ljava/util/UUID;->toString()Ljava/lang/String;
    move-result-object v11
    const-string v12, "-"
    const-string v13, ""
    invoke-virtual {v11, v12, v13}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;
    move-result-object v14
    invoke-virtual {v0, v14}, Lcom/lody/virtual/server/interfaces/VirtualDeviceInfo;->setAndroidId(Ljava/lang/String;)V
    
    return-object v0
.end method
```

## 📊 মনিটরিং এবং অ্যানালিটিক্স

### Virtual Space Statistics
```smali
# VirtualSpaceStats.smali
.method public getVirtualSpaceStatistics()Lcom/lody/virtual/server/interfaces/VSpaceStats;
    .locals 6
    
    new-instance v0, Lcom/lody/virtual/server/interfaces/VSpaceStats;
    invoke-direct {v0}, Lcom/lody/virtual/server/interfaces/VSpaceStats;-><init>()V
    
    # Active virtual spaces count
    iget-object v1, p0, Lcom/lody/virtual/server/interfaces/VirtualSpaceStats;->activeSpaces:Ljava/util/Set;
    invoke-interface {v1}, Ljava/util/Set;->size()I
    move-result v2
    iput v2, v0, Lcom/lody/virtual/server/interfaces/VSpaceStats;->activeSpaceCount:I
    
    # Total memory usage
    invoke-direct {p0}, Lcom/lody/virtual/server/interfaces/VirtualSpaceStats;->calculateTotalMemoryUsage()J
    move-result-wide v3
    iput-wide v3, v0, Lcom/lody/virtual/server/interfaces/VSpaceStats;->totalMemoryUsage:J
    
    # Average response time
    invoke-direct {p0}, Lcom/lody/virtual/server/interfaces/VirtualSpaceStats;->calculateAverageResponseTime()F
    move-result v5
    iput v5, v0, Lcom/lody/virtual/server/interfaces/VSpaceStats;->averageResponseTime:F
    
    return-object v0
.end method
```

## 📝 Best Practices

### 1. Virtual Space Design
- প্রতিটি virtual space এর জন্য আলাদা resource allocation করুন
- Memory leaks এড়াতে proper cleanup implement করুন
- Context switching optimize করুন

### 2. Security Considerations
- Virtual spaces এর মধ্যে data leakage prevent করুন
- Sandbox isolation strictly maintain করুন
- Virtual device information properly randomize করুন

### 3. Performance Tips
- Lazy loading ব্যবহার করে startup time কমান
- Resource sharing minimize করুন
- Context caching implement করুন

## 🔗 Related Components

- [App Cloning Feature](./App_Cloning_Feature_README.md)
- [Security & Hooking System](./Security_Hooking_System_README.md)
- [Native Libraries Management](./Native_Libraries_Management_README.md)

## 📞 Support

যদি কোনো সমস্যার সম্মুখীন হন, তাহলে:
1. Virtual space logs check করুন
2. Resource usage monitor করুন
3. Context switching verify করুন
4. Sandbox isolation test করুন

---

**Note**: এই ডকুমেন্টেশন DWH Crush APK v1.1.3 এর জন্য তৈরি। নতুন version এ changes থাকতে পারে।
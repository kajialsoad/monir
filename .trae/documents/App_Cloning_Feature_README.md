# 📱 DWH Crush APK - App Cloning Feature Management

## 🎯 ওভারভিউ

DWH Crush APK এর App Cloning Feature হলো একটি উন্নত সিস্টেম যা একই ডিভাইসে একাধিক অ্যাপ ইনস্ট্যান্স চালানোর সুবিধা প্রদান করে। এই ফিচারটি ভার্চুয়াল এনভায়রনমেন্ট ব্যবহার করে প্রতিটি ক্লোনড অ্যাপকে আলাদা স্পেসে রান করায়।

## 🏗️ আর্কিটেকচার

### Core Components
- **Clone Engine**: মূল ক্লোনিং লজিক
- **Instance Manager**: মাল্টিপল ইনস্ট্যান্স ম্যানেজমেন্ট
- **Data Isolation**: ডেটা আইসোলেশন সিস্টেম
- **Resource Allocator**: রিসোর্স বরাদ্দকরণ

### File Structure
```
smali_classes2/com/lody/virtual/
├── client/
│   ├── core/
│   │   ├── VirtualCore.smali
│   │   └── InstallStrategy.smali
│   ├── ipc/
│   └── hook/
├── server/
│   ├── am/
│   │   ├── VActivityManagerService.smali
│   │   └── TaskRecord.smali
│   └── pm/
│       └── VPackageManagerService.smali
└── remote/
    ├── InstalledAppInfo.smali
    └── AppTaskInfo.smali
```

## ⚙️ সেটআপ এবং কনফিগারেশন

### 1. Virtual Core ইনিশিয়ালাইজেশন

```smali
# VirtualCore.smali এ startup method
.method public static startup(Landroid/content/Context;)V
    .locals 2
    
    # Virtual environment initialize করা
    invoke-static {p0}, Lcom/lody/virtual/client/core/VirtualCore;->get(Landroid/content/Context;)Lcom/lody/virtual/client/core/VirtualCore;
    move-result-object v0
    
    # App cloning service start করা
    invoke-virtual {v0}, Lcom/lody/virtual/client/core/VirtualCore;->initialize()V
    
    return-void
.end method
```

### 2. App Installation Process

```smali
# InstallStrategy.smali
.method public installPackage(Ljava/lang/String;I)Lcom/lody/virtual/remote/InstallResult;
    .locals 4
    
    # APK path validate করা
    invoke-static {p1}, Landroid/text/TextUtils;->isEmpty(Ljava/lang/CharSequence;)Z
    move-result v0
    if-eqz v0, :cond_install
    
    # Error return করা
    new-instance v1, Lcom/lody/virtual/remote/InstallResult;
    const/4 v2, -0x1
    invoke-direct {v1, v2}, Lcom/lody/virtual/remote/InstallResult;-><init>(I)V
    return-object v1
    
    :cond_install
    # Virtual space এ install করা
    invoke-direct {p0, p1, p2}, Lcom/lody/virtual/client/core/InstallStrategy;->installInVirtualSpace(Ljava/lang/String;I)Lcom/lody/virtual/remote/InstallResult;
    move-result-object v1
    return-object v1
.end method
```

## 🔧 প্রধান ফিচারসমূহ

### 1. Multi-Instance Management

#### Instance Creation
```smali
# VActivityManagerService.smali
.method public startActivity(Landroid/content/Intent;I)I
    .locals 3
    
    # নতুন instance তৈরি করা
    new-instance v0, Lcom/lody/virtual/server/am/TaskRecord;
    invoke-direct {v0, p1, p2}, Lcom/lody/virtual/server/am/TaskRecord;-><init>(Landroid/content/Intent;I)V
    
    # Instance list এ add করা
    iget-object v1, p0, Lcom/lody/virtual/server/am/VActivityManagerService;->mTaskRecords:Ljava/util/List;
    invoke-interface {v1, v0}, Ljava/util/List;->add(Ljava/lang/Object;)Z
    
    # Activity start করা
    invoke-virtual {v0}, Lcom/lody/virtual/server/am/TaskRecord;->startActivity()I
    move-result v2
    return v2
.end method
```

#### Instance Switching
```smali
# TaskRecord.smali
.method public switchToInstance(I)V
    .locals 2
    
    # Current instance pause করা
    invoke-virtual {p0}, Lcom/lody/virtual/server/am/TaskRecord;->pauseCurrentInstance()V
    
    # Target instance resume করা
    iput p1, p0, Lcom/lody/virtual/server/am/TaskRecord;->currentInstanceId:I
    invoke-virtual {p0}, Lcom/lody/virtual/server/am/TaskRecord;->resumeInstance()V
    
    return-void
.end method
```

### 2. Data Isolation System

#### Isolated Storage
```smali
# VPackageManagerService.smali
.method public getApplicationInfo(Ljava/lang/String;II)Landroid/content/pm/ApplicationInfo;
    .locals 4
    
    # Virtual path তৈরি করা
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    
    const-string v1, "/data/data/virtual_"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v2, "/"
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v3
    
    # ApplicationInfo modify করা
    invoke-direct {p0, p1, p2, v3}, Lcom/lody/virtual/server/pm/VPackageManagerService;->modifyApplicationInfo(Ljava/lang/String;ILjava/lang/String;)Landroid/content/pm/ApplicationInfo;
    move-result-object v4
    return-object v4
.end method
```

## 🛠️ কাস্টমাইজেশন

### Clone Settings Configuration

`cloneSettings.json` ফাইল এডিট করুন:

```json
{
  "maxInstances": 5,
  "isolationLevel": "high",
  "dataEncryption": true,
  "resourceSharing": false,
  "autoBackup": true,
  "cloneNaming": {
    "prefix": "Clone_",
    "useNumbers": true,
    "customNames": []
  },
  "permissions": {
    "inheritOriginal": true,
    "restrictNetwork": false,
    "restrictStorage": false
  }
}
```

### Custom Clone Icon

```smali
# IconManager.smali
.method public generateCloneIcon(Landroid/graphics/drawable/Drawable;I)Landroid/graphics/drawable/Drawable;
    .locals 5
    
    # Original icon load করা
    move-object v0, p1
    
    # Clone badge তৈরি করা
    new-instance v1, Landroid/graphics/drawable/LayerDrawable;
    const/4 v2, 0x2
    new-array v3, v2, [Landroid/graphics/drawable/Drawable;
    
    # Original icon set করা
    const/4 v4, 0x0
    aput-object v0, v3, v4
    
    # Clone badge add করা
    invoke-direct {p0, p2}, Lcom/lody/virtual/client/core/IconManager;->createCloneBadge(I)Landroid/graphics/drawable/Drawable;
    move-result-object v5
    const/4 v6, 0x1
    aput-object v5, v3, v6
    
    invoke-direct {v1, v3}, Landroid/graphics/drawable/LayerDrawable;-><init>([Landroid/graphics/drawable/Drawable;)V
    
    return-object v1
.end method
```

## 🔍 ডিবাগিং এবং ট্রাবলশুটিং

### Common Issues

#### 1. Clone Creation Failed
```bash
# Log check করুন
adb logcat | grep "VirtualCore"

# Expected output:
I/VirtualCore: Creating new instance for package: com.example.app
I/VirtualCore: Instance created successfully with ID: 1
```

#### 2. Data Isolation Problems
```smali
# Debug method add করুন VPackageManagerService.smali এ
.method private debugDataPath(Ljava/lang/String;I)V
    .locals 3
    
    const-string v0, "VirtualCore"
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    const-string v2, "Data path for "
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v2, " instance "
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v3
    invoke-static {v0, v3}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    
    return-void
.end method
```

### Performance Optimization

#### Memory Management
```smali
# MemoryManager.smali
.method public optimizeMemoryUsage()V
    .locals 2
    
    # Unused instances clear করা
    invoke-direct {p0}, Lcom/lody/virtual/client/core/MemoryManager;->clearUnusedInstances()V
    
    # Cache cleanup
    invoke-static {}, Ljava/lang/System;->gc()V
    
    # Memory stats log করা
    invoke-direct {p0}, Lcom/lody/virtual/client/core/MemoryManager;->logMemoryStats()V
    
    return-void
.end method
```

## 📊 মনিটরিং এবং অ্যানালিটিক্স

### Instance Statistics
```smali
# StatsManager.smali
.method public getInstanceStats()Lcom/lody/virtual/remote/InstanceStats;
    .locals 4
    
    new-instance v0, Lcom/lody/virtual/remote/InstanceStats;
    invoke-direct {v0}, Lcom/lody/virtual/remote/InstanceStats;-><init>()V
    
    # Active instances count
    iget-object v1, p0, Lcom/lody/virtual/client/core/StatsManager;->activeInstances:Ljava/util/List;
    invoke-interface {v1}, Ljava/util/List;->size()I
    move-result v2
    iput v2, v0, Lcom/lody/virtual/remote/InstanceStats;->activeCount:I
    
    # Memory usage
    invoke-direct {p0}, Lcom/lody/virtual/client/core/StatsManager;->calculateMemoryUsage()J
    move-result-wide v3
    iput-wide v3, v0, Lcom/lody/virtual/remote/InstanceStats;->memoryUsage:J
    
    return-object v0
.end method
```

## 🚀 Advanced Features

### 1. Auto Clone Detection
```smali
# AutoCloneDetector.smali
.method public detectCloneableApps()Ljava/util/List;
    .locals 5
    
    new-instance v0, Ljava/util/ArrayList;
    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V
    
    # Installed apps scan করা
    invoke-virtual {p0}, Lcom/lody/virtual/client/core/AutoCloneDetector;->getInstalledApps()Ljava/util/List;
    move-result-object v1
    
    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;
    move-result-object v2
    
    :goto_loop
    invoke-interface {v2}, Ljava/util/Iterator;->hasNext()Z
    move-result v3
    if-eqz v3, :cond_end
    
    invoke-interface {v2}, Ljava/util/Iterator;->next()Ljava/lang/Object;
    move-result-object v4
    check-cast v4, Landroid/content/pm/ApplicationInfo;
    
    # Clone compatibility check
    invoke-direct {p0, v4}, Lcom/lody/virtual/client/core/AutoCloneDetector;->isCloneable(Landroid/content/pm/ApplicationInfo;)Z
    move-result v5
    if-eqz v5, :goto_loop
    
    invoke-interface {v0, v4}, Ljava/util/List;->add(Ljava/lang/Object;)Z
    goto :goto_loop
    
    :cond_end
    return-object v0
.end method
```

### 2. Clone Synchronization
```smali
# SyncManager.smali
.method public syncInstanceData(II)Z
    .locals 4
    
    # Source instance data path
    invoke-direct {p0, p1}, Lcom/lody/virtual/client/core/SyncManager;->getInstanceDataPath(I)Ljava/lang/String;
    move-result-object v0
    
    # Target instance data path
    invoke-direct {p0, p2}, Lcom/lody/virtual/client/core/SyncManager;->getInstanceDataPath(I)Ljava/lang/String;
    move-result-object v1
    
    # Data copy করা
    invoke-static {v0, v1}, Lcom/lody/virtual/helper/utils/FileUtils;->copyDirectory(Ljava/lang/String;Ljava/lang/String;)Z
    move-result v2
    
    if-eqz v2, :cond_success
    # Sync metadata update করা
    invoke-direct {p0, p1, p2}, Lcom/lody/virtual/client/core/SyncManager;->updateSyncMetadata(II)V
    const/4 v3, 0x1
    return v3
    
    :cond_success
    const/4 v3, 0x0
    return v3
.end method
```

## 📝 Best Practices

### 1. Resource Management
- প্রতিটি clone এর জন্য আলাদা data directory ব্যবহার করুন
- Memory leaks এড়াতে unused instances cleanup করুন
- Background processes limit করুন

### 2. Security Considerations
- Clone instances এর মধ্যে data sharing restrict করুন
- Sensitive data encryption ব্যবহার করুন
- Permission isolation maintain করুন

### 3. Performance Tips
- Clone creation এর সময় lazy loading ব্যবহার করুন
- Resource sharing optimize করুন
- Background sync minimize করুন

## 🔗 Related Components

- [Virtual Space Management](./Virtual_Space_Management_README.md)
- [Security & Hooking System](./Security_Hooking_System_README.md)
- [Resource Management](./Resource_Management_README.md)

## 📞 Support

যদি কোনো সমস্যার সম্মুখীন হন, তাহলে:
1. Log files check করুন
2. Debug mode enable করুন
3. Memory usage monitor করুন
4. Instance limits verify করুন

---

**Note**: এই ডকুমেন্টেশন DWH Crush APK v1.1.3 এর জন্য তৈরি। নতুন version এ changes থাকতে পারে।
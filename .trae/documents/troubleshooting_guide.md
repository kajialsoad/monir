# Multi-Space App Cloner - Troubleshooting Guide

## 1. Common Installation Issues

### 1.1 APK Installation Failed

**Problem:** APK installation fails with "App not installed" error

**Possible Causes:**
- Insufficient storage space
- Corrupted APK file
- Conflicting package signatures
- Unknown sources disabled

**Solutions:**
```bash
# Check available storage
adb shell df /data

# Clear package installer cache
adb shell pm clear com.google.android.packageinstaller

# Enable unknown sources
adb shell settings put secure install_non_market_apps 1

# Force install with replace
adb install -r -d app-release.apk

# Install with downgrade permission
adb install -r -d --force-queryable app-release.apk
```

**Verification:**
```bash
# Check if app is installed
adb shell pm list packages | grep com.multispace.cloner

# Check app info
adb shell dumpsys package com.multispace.cloner
```

### 1.2 Permission Denied Errors

**Problem:** App crashes with permission denied errors

**Root Cause Analysis:**
```bash
# Check app permissions
adb shell dumpsys package com.multispace.cloner | grep permission

# Check SELinux denials
adb shell dmesg | grep denied

# Check logcat for permission errors
adb logcat | grep -i "permission denied"
```

**Solutions:**
```bash
# Grant all permissions
adb shell pm grant com.multispace.cloner android.permission.WRITE_EXTERNAL_STORAGE
adb shell pm grant com.multispace.cloner android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant com.multispace.cloner android.permission.CAMERA
adb shell pm grant com.multispace.cloner android.permission.ACCESS_FINE_LOCATION

# Reset app permissions
adb shell pm reset-permissions com.multispace.cloner
```

## 2. App Cloning Issues

### 2.1 Clone Creation Fails

**Problem:** App cloning process fails or hangs

**Diagnostic Steps:**
```bash
# Check available memory
adb shell cat /proc/meminfo | grep MemAvailable

# Monitor CPU usage during cloning
adb shell top -p $(adb shell pidof com.multispace.cloner)

# Check for file system errors
adb shell fsck /data
```

**Debug Logging:**
```java
// Enable verbose logging in VirtualCore
public class DebugConfig {
    public static final boolean DEBUG_CLONE_CREATION = true;
    public static final boolean DEBUG_FILE_OPERATIONS = true;
    public static final boolean DEBUG_PERMISSION_HOOKS = true;
    
    public static void enableDebugLogging() {
        if (DEBUG_CLONE_CREATION) {
            Log.d("VirtualCore", "Clone creation debugging enabled");
        }
    }
}
```

**Common Fixes:**
```java
// Fix 1: Clear temporary files
public void clearTempFiles() {
    File tempDir = new File(getFilesDir(), "temp");
    if (tempDir.exists()) {
        deleteRecursively(tempDir);
    }
}

// Fix 2: Reset VirtualCore state
public void resetVirtualCore() {
    VirtualCore.get().killAllApps();
    VirtualCore.get().clearPackageCache();
}

// Fix 3: Increase memory allocation
public void optimizeMemory() {
    System.gc();
    Runtime.getRuntime().runFinalization();
}
```

### 2.2 Cloned App Won't Start

**Problem:** Cloned app fails to launch or crashes immediately

**Error Analysis:**
```bash
# Get crash logs
adb logcat -b crash | grep com.multispace.cloner

# Check for native crashes
adb shell ls /data/tombstones/

# Monitor app startup
adb logcat | grep -E "(START|ActivityManager)"
```

**Solutions:**
```java
// Solution 1: Fix hooking conflicts
public class HookingFix {
    public static void resolveHookConflicts() {
        // Disable conflicting hooks
        SandHook.disableHook("problematic_method");
        
        // Re-initialize hooking system
        HookingEngine.getInstance().reinitialize();
    }
}

// Solution 2: Handle library loading issues
public class LibraryLoader {
    public static void loadRequiredLibraries() {
        try {
            System.loadLibrary("virtualcore");
            System.loadLibrary("sandhook");
        } catch (UnsatisfiedLinkError e) {
            Log.e("LibraryLoader", "Failed to load native libraries", e);
            // Fallback to alternative loading method
            loadLibrariesFromAssets();
        }
    }
}
```

## 3. Performance Issues

### 3.1 High Memory Usage

**Problem:** App consumes excessive memory

**Memory Analysis:**
```bash
# Check memory usage
adb shell dumpsys meminfo com.multispace.cloner

# Monitor memory over time
adb shell "while true; do dumpsys meminfo com.multispace.cloner | grep TOTAL; sleep 5; done"

# Check for memory leaks
adb shell am dumpheap com.multispace.cloner /data/local/tmp/heap.hprof
```

**Memory Optimization:**
```java
public class MemoryOptimizer {
    private static final int MAX_CLONE_INSTANCES = 5;
    private LruCache<String, CloneInstance> cloneCache;
    
    public MemoryOptimizer() {
        int maxMemory = (int) (Runtime.getRuntime().maxMemory() / 1024);
        int cacheSize = maxMemory / 8; // Use 1/8th of available memory
        
        cloneCache = new LruCache<String, CloneInstance>(cacheSize) {
            @Override
            protected int sizeOf(String key, CloneInstance clone) {
                return clone.getMemorySize() / 1024; // Size in KB
            }
            
            @Override
            protected void entryRemoved(boolean evicted, String key, 
                                     CloneInstance oldValue, CloneInstance newValue) {
                if (evicted) {
                    oldValue.cleanup();
                }
            }
        };
    }
    
    public void optimizeMemory() {
        // Force garbage collection
        System.gc();
        
        // Clear unused clones
        cloneCache.evictAll();
        
        // Trim memory usage
        onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW);
    }
}
```

### 3.2 Slow App Performance

**Problem:** App responds slowly or lags

**Performance Profiling:**
```bash
# Profile CPU usage
adb shell simpleperf record -p $(adb shell pidof com.multispace.cloner) -o /data/local/tmp/perf.data

# Analyze frame rendering
adb shell dumpsys gfxinfo com.multispace.cloner

# Check for ANRs
adb shell ls /data/anr/
```

**Performance Fixes:**
```java
public class PerformanceOptimizer {
    // Fix 1: Optimize database operations
    public void optimizeDatabase() {
        SQLiteDatabase db = getWritableDatabase();
        
        // Enable WAL mode for better concurrency
        db.enableWriteAheadLogging();
        
        // Optimize database settings
        db.execSQL("PRAGMA synchronous = NORMAL");
        db.execSQL("PRAGMA cache_size = 10000");
        db.execSQL("PRAGMA temp_store = MEMORY");
    }
    
    // Fix 2: Implement background processing
    public void moveToBackground(Runnable task) {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        executor.execute(() -> {
            try {
                task.run();
            } catch (Exception e) {
                Log.e("PerformanceOptimizer", "Background task failed", e);
            }
        });
    }
    
    // Fix 3: Optimize UI rendering
    public void optimizeUI() {
        // Reduce overdraw
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        );
        
        // Enable view recycling
        RecyclerView recyclerView = findViewById(R.id.clone_list);
        recyclerView.setRecycledViewPool(new RecyclerView.RecycledViewPool());
        recyclerView.setItemViewCacheSize(20);
    }
}
```

## 4. Security & Privacy Issues

### 4.1 Root Detection False Positives

**Problem:** App incorrectly detects rooted device

**Debug Root Detection:**
```java
public class RootDetectionDebug {
    public static void debugRootDetection() {
        Log.d("RootDetection", "Checking root indicators...");
        
        // Check each root indicator
        for (String path : ROOT_PATHS) {
            boolean exists = new File(path).exists();
            Log.d("RootDetection", "Path " + path + ": " + exists);
        }
        
        // Check su command
        try {
            Process process = Runtime.getRuntime().exec("su");
            Log.d("RootDetection", "Su command available: true");
        } catch (Exception e) {
            Log.d("RootDetection", "Su command available: false");
        }
    }
}
```

**Whitelist Trusted Root Apps:**
```java
public class RootWhitelist {
    private static final Set<String> TRUSTED_ROOT_APPS = Set.of(
        "com.topjohnwu.magisk",
        "eu.chainfire.supersu",
        "com.noshufou.android.su"
    );
    
    public static boolean isTrustedRootEnvironment() {
        PackageManager pm = context.getPackageManager();
        
        for (String packageName : TRUSTED_ROOT_APPS) {
            try {
                PackageInfo info = pm.getPackageInfo(packageName, 0);
                if (info != null) {
                    return true; // Trusted root manager found
                }
            } catch (PackageManager.NameNotFoundException e) {
                // Package not found, continue
            }
        }
        
        return false;
    }
}
```

### 4.2 Encryption/Decryption Errors

**Problem:** Data encryption or decryption fails

**Encryption Debugging:**
```java
public class EncryptionDebug {
    public static void testEncryption() {
        String testData = "Hello, World!";
        String key = "test_encryption_key_32_bytes_long";
        
        try {
            // Test encryption
            String encrypted = AESUtil.encrypt(testData, key);
            Log.d("Encryption", "Encrypted: " + encrypted);
            
            // Test decryption
            String decrypted = AESUtil.decrypt(encrypted, key);
            Log.d("Encryption", "Decrypted: " + decrypted);
            
            // Verify data integrity
            if (testData.equals(decrypted)) {
                Log.d("Encryption", "Encryption test passed");
            } else {
                Log.e("Encryption", "Encryption test failed");
            }
        } catch (Exception e) {
            Log.e("Encryption", "Encryption error", e);
        }
    }
}
```

**Key Management Fixes:**
```java
public class KeyManagement {
    public static void regenerateKeys() {
        try {
            // Clear old keys
            KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
            keyStore.load(null);
            keyStore.deleteEntry("multispace_key");
            
            // Generate new key
            KeyGenerator keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
            
            KeyGenParameterSpec keyGenParameterSpec = new KeyGenParameterSpec.Builder(
                "multispace_key",
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build();
            
            keyGenerator.init(keyGenParameterSpec);
            keyGenerator.generateKey();
            
            Log.d("KeyManagement", "New encryption key generated");
        } catch (Exception e) {
            Log.e("KeyManagement", "Key generation failed", e);
        }
    }
}
```

## 5. Network & Connectivity Issues

### 5.1 Network Access Blocked

**Problem:** Cloned apps cannot access network

**Network Debugging:**
```bash
# Check network connectivity
adb shell ping -c 3 8.8.8.8

# Check DNS resolution
adb shell nslookup google.com

# Monitor network traffic
adb shell tcpdump -i any -w /data/local/tmp/network.pcap
```

**Network Permission Fixes:**
```java
public class NetworkFix {
    public static void fixNetworkAccess(String cloneId) {
        // Grant network permission to clone
        PermissionController controller = SecurityManager.getPermissionController();
        controller.grantPermission(cloneId, "android.permission.INTERNET");
        controller.grantPermission(cloneId, "android.permission.ACCESS_NETWORK_STATE");
        
        // Clear network restrictions
        NetworkPolicy policy = SecurityManager.getNetworkPolicy(cloneId);
        policy.setNetworkAllowed(true);
        policy.clearRestrictions();
    }
}
```

### 5.2 SSL/TLS Certificate Issues

**Problem:** HTTPS connections fail with certificate errors

**Certificate Debugging:**
```java
public class CertificateDebug {
    public static void debugCertificates(String hostname) {
        try {
            URL url = new URL("https://" + hostname);
            HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
            
            connection.connect();
            Certificate[] certificates = connection.getServerCertificates();
            
            for (Certificate cert : certificates) {
                if (cert instanceof X509Certificate) {
                    X509Certificate x509 = (X509Certificate) cert;
                    Log.d("Certificate", "Subject: " + x509.getSubjectDN());
                    Log.d("Certificate", "Issuer: " + x509.getIssuerDN());
                    Log.d("Certificate", "Valid from: " + x509.getNotBefore());
                    Log.d("Certificate", "Valid to: " + x509.getNotAfter());
                }
            }
        } catch (Exception e) {
            Log.e("Certificate", "Certificate check failed", e);
        }
    }
}
```

## 6. Database Issues

### 6.1 Database Corruption

**Problem:** SQLite database becomes corrupted

**Database Recovery:**
```java
public class DatabaseRecovery {
    public static boolean repairDatabase(String dbPath) {
        try {
            // Check database integrity
            SQLiteDatabase db = SQLiteDatabase.openDatabase(
                dbPath, null, SQLiteDatabase.OPEN_READONLY);
            
            Cursor cursor = db.rawQuery("PRAGMA integrity_check", null);
            boolean isCorrupted = false;
            
            if (cursor.moveToFirst()) {
                String result = cursor.getString(0);
                isCorrupted = !"ok".equals(result);
            }
            cursor.close();
            db.close();
            
            if (isCorrupted) {
                // Attempt repair
                return repairCorruptedDatabase(dbPath);
            }
            
            return true;
        } catch (Exception e) {
            Log.e("DatabaseRecovery", "Database repair failed", e);
            return false;
        }
    }
    
    private static boolean repairCorruptedDatabase(String dbPath) {
        try {
            // Create backup
            File originalDb = new File(dbPath);
            File backupDb = new File(dbPath + ".backup");
            copyFile(originalDb, backupDb);
            
            // Try to recover data
            SQLiteDatabase corruptedDb = SQLiteDatabase.openDatabase(
                dbPath, null, SQLiteDatabase.OPEN_READONLY);
            
            // Create new database
            String newDbPath = dbPath + ".new";
            SQLiteDatabase newDb = SQLiteDatabase.openOrCreateDatabase(
                newDbPath, null);
            
            // Recreate schema
            DatabaseHelper.createTables(newDb);
            
            // Copy recoverable data
            copyRecoverableData(corruptedDb, newDb);
            
            corruptedDb.close();
            newDb.close();
            
            // Replace corrupted database
            originalDb.delete();
            new File(newDbPath).renameTo(originalDb);
            
            return true;
        } catch (Exception e) {
            Log.e("DatabaseRecovery", "Database repair failed", e);
            return false;
        }
    }
}
```

### 6.2 Database Lock Issues

**Problem:** Database operations hang due to locks

**Lock Resolution:**
```java
public class DatabaseLockResolver {
    private static final int LOCK_TIMEOUT = 30000; // 30 seconds
    
    public static SQLiteDatabase openDatabaseSafely(String dbPath) {
        try {
            SQLiteDatabase db = SQLiteDatabase.openDatabase(
                dbPath, null, SQLiteDatabase.OPEN_READWRITE);
            
            // Set busy timeout
            db.execSQL("PRAGMA busy_timeout = " + LOCK_TIMEOUT);
            
            // Enable WAL mode to reduce locking
            db.enableWriteAheadLogging();
            
            return db;
        } catch (SQLiteDatabaseLockedException e) {
            Log.w("DatabaseLock", "Database locked, attempting recovery");
            return recoverFromLock(dbPath);
        }
    }
    
    private static SQLiteDatabase recoverFromLock(String dbPath) {
        try {
            // Force close all connections
            SQLiteDatabase.releaseMemory();
            
            // Wait and retry
            Thread.sleep(1000);
            
            return SQLiteDatabase.openDatabase(
                dbPath, null, SQLiteDatabase.OPEN_READWRITE);
        } catch (Exception e) {
            Log.e("DatabaseLock", "Lock recovery failed", e);
            throw new RuntimeException("Cannot open database", e);
        }
    }
}
```

## 7. Device Compatibility Issues

### 7.1 Android Version Compatibility

**Problem:** App doesn't work on specific Android versions

**Version-Specific Fixes:**
```java
public class CompatibilityFixes {
    public static void applyAndroidVersionFixes() {
        int sdkVersion = Build.VERSION.SDK_INT;
        
        if (sdkVersion >= Build.VERSION_CODES.Q) {
            // Android 10+ scoped storage fixes
            applyScopedStorageFixes();
        }
        
        if (sdkVersion >= Build.VERSION_CODES.R) {
            // Android 11+ package visibility fixes
            applyPackageVisibilityFixes();
        }
        
        if (sdkVersion >= Build.VERSION_CODES.S) {
            // Android 12+ material you fixes
            applyMaterialYouFixes();
        }
    }
    
    private static void applyScopedStorageFixes() {
        // Request legacy external storage
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Add to AndroidManifest.xml:
            // android:requestLegacyExternalStorage="true"
        }
    }
    
    private static void applyPackageVisibilityFixes() {
        // Add queries to AndroidManifest.xml for package visibility
        // <queries>
        //     <intent>
        //         <action android:name="android.intent.action.MAIN" />
        //     </intent>
        // </queries>
    }
}
```

### 7.2 OEM-Specific Issues

**Problem:** App behaves differently on specific device brands

**OEM Compatibility:**
```java
public class OEMCompatibility {
    public static void applyOEMFixes() {
        String manufacturer = Build.MANUFACTURER.toLowerCase();
        
        switch (manufacturer) {
            case "xiaomi":
                applyXiaomiFixes();
                break;
            case "huawei":
                applyHuaweiFixes();
                break;
            case "samsung":
                applySamsungFixes();
                break;
            case "oppo":
            case "oneplus":
                applyOppoFixes();
                break;
        }
    }
    
    private static void applyXiaomiFixes() {
        // MIUI-specific fixes
        // Request autostart permission
        requestAutostartPermission();
        
        // Handle MIUI's aggressive battery optimization
        requestBatteryOptimizationWhitelist();
    }
    
    private static void applyHuaweiFixes() {
        // EMUI-specific fixes
        // Handle Huawei's protected apps
        requestProtectedAppStatus();
    }
    
    private static void applySamsungFixes() {
        // Samsung-specific fixes
        // Handle Samsung's device care optimization
        requestDeviceCareWhitelist();
    }
}
```

## 8. Emergency Recovery Procedures

### 8.1 Complete App Reset

**When to Use:** App is completely broken and won't start

**Reset Procedure:**
```bash
#!/bin/bash
# emergency_reset.sh

echo "Starting emergency app reset..."

# Stop the app
adb shell am force-stop com.multispace.cloner

# Clear app data
adb shell pm clear com.multispace.cloner

# Clear app cache
adb shell rm -rf /data/data/com.multispace.cloner/cache/*

# Reset permissions
adb shell pm reset-permissions com.multispace.cloner

# Restart the app
adb shell am start -n com.multispace.cloner/.MainActivity

echo "Emergency reset completed!"
```

### 8.2 Data Recovery

**Backup Recovery:**
```java
public class EmergencyRecovery {
    public static boolean recoverFromBackup() {
        try {
            File backupDir = new File(getExternalFilesDir(null), "emergency_backup");
            if (!backupDir.exists()) {
                Log.e("Recovery", "No backup found");
                return false;
            }
            
            // Restore database
            File dbBackup = new File(backupDir, "database_backup.db");
            if (dbBackup.exists()) {
                File currentDb = getDatabasePath("app_database.db");
                copyFile(dbBackup, currentDb);
            }
            
            // Restore preferences
            File prefsBackup = new File(backupDir, "preferences_backup.json");
            if (prefsBackup.exists()) {
                restorePreferences(prefsBackup);
            }
            
            // Restore clone data
            File cloneBackup = new File(backupDir, "clone_data");
            if (cloneBackup.exists()) {
                File cloneDir = new File(getFilesDir(), "virtual_spaces");
                copyDirectory(cloneBackup, cloneDir);
            }
            
            return true;
        } catch (Exception e) {
            Log.e("Recovery", "Recovery failed", e);
            return false;
        }
    }
}
```

## 9. Diagnostic Tools

### 9.1 Built-in Diagnostics

**Diagnostic Activity:**
```java
public class DiagnosticActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_diagnostic);
        
        runDiagnostics();
    }
    
    private void runDiagnostics() {
        StringBuilder report = new StringBuilder();
        
        // System information
        report.append("=== SYSTEM INFO ===\n");
        report.append("Android Version: ").append(Build.VERSION.RELEASE).append("\n");
        report.append("API Level: ").append(Build.VERSION.SDK_INT).append("\n");
        report.append("Device: ").append(Build.MANUFACTURER).append(" ").append(Build.MODEL).append("\n");
        report.append("Architecture: ").append(Build.SUPPORTED_ABIS[0]).append("\n\n");
        
        // Memory information
        report.append("=== MEMORY INFO ===\n");
        ActivityManager.MemoryInfo memInfo = new ActivityManager.MemoryInfo();
        ActivityManager am = (ActivityManager) getSystemService(ACTIVITY_SERVICE);
        am.getMemoryInfo(memInfo);
        report.append("Available Memory: ").append(memInfo.availMem / 1024 / 1024).append(" MB\n");
        report.append("Total Memory: ").append(memInfo.totalMem / 1024 / 1024).append(" MB\n\n");
        
        // Storage information
        report.append("=== STORAGE INFO ===\n");
        StatFs stat = new StatFs(getFilesDir().getPath());
        long availableBytes = stat.getAvailableBytes();
        long totalBytes = stat.getTotalBytes();
        report.append("Available Storage: ").append(availableBytes / 1024 / 1024).append(" MB\n");
        report.append("Total Storage: ").append(totalBytes / 1024 / 1024).append(" MB\n\n");
        
        // App-specific diagnostics
        report.append("=== APP DIAGNOSTICS ===\n");
        report.append("VirtualCore Status: ").append(checkVirtualCoreStatus()).append("\n");
        report.append("Hooking System: ").append(checkHookingSystem()).append("\n");
        report.append("Database Status: ").append(checkDatabaseStatus()).append("\n");
        report.append("Clone Count: ").append(getCloneCount()).append("\n");
        
        // Display report
        TextView reportView = findViewById(R.id.diagnostic_report);
        reportView.setText(report.toString());
    }
}
```

### 9.2 Log Collection

**Automated Log Collection:**
```java
public class LogCollector {
    public static File collectLogs() {
        try {
            File logDir = new File(getExternalFilesDir(null), "logs");
            if (!logDir.exists()) {
                logDir.mkdirs();
            }
            
            String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
                .format(new Date());
            File logFile = new File(logDir, "diagnostic_log_" + timestamp + ".txt");
            
            FileWriter writer = new FileWriter(logFile);
            
            // Collect system logs
            Process logcatProcess = Runtime.getRuntime().exec("logcat -d");
            BufferedReader reader = new BufferedReader(
                new InputStreamReader(logcatProcess.getInputStream()));
            
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.contains("com.multispace.cloner") || 
                    line.contains("VirtualCore") || 
                    line.contains("SandHook")) {
                    writer.write(line + "\n");
                }
            }
            
            writer.close();
            reader.close();
            
            return logFile;
        } catch (Exception e) {
            Log.e("LogCollector", "Failed to collect logs", e);
            return null;
        }
    }
}
```

এই troubleshooting guide ব্যবহার করে আপনি multi-space app cloner এর সাধারণ সমস্যাগুলো দ্রুত identify এবং resolve করতে পারবেন।
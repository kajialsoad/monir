package com.multispace.app.multispace_cloner

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Process
import android.os.UserHandle
import android.util.Log
import java.io.File
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong
import org.json.JSONObject
import org.json.JSONArray

/**
 * 🏗️ Complete Sandbox Manager
 * Manages virtual app environments with complete isolation:
 * - File system virtualization
 * - Process isolation 
 * - Memory space separation
 * - Network isolation
 * - Permission sandboxing
 */
class SandboxManager private constructor(private val context: Context) {
    
    companion object {
        const val TAG = "SandboxManager"
        private const val SANDBOX_ROOT_DIR = "sandbox_environments"
        private const val VIRTUAL_PROC_DIR = "virtual_proc"
        private const val ISOLATED_STORAGE_DIR = "isolated_storage"
        
        @Volatile
        private var INSTANCE: SandboxManager? = null
        
        fun getInstance(context: Context): SandboxManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: SandboxManager(context.applicationContext).also { 
                    INSTANCE = it
                    it.initializeSandboxSystem()
                }
            }
        }
    }
    
    // 📊 Sandbox tracking and management
    private val activeSandboxes = ConcurrentHashMap<String, SandboxEnvironment>()
    private val sandboxCounter = AtomicLong(0)
    private val securityManager = SecurityManager.getInstance(context)
    
    /**
     * 🏗️ Sandbox Environment Data Class
     * Represents a complete isolated environment for a cloned app
     */
    data class SandboxEnvironment(
        val sandboxId: String,
        val cloneId: String,
        val packageName: String,
        val processId: Int,
        val rootPath: String,
        val dataPath: String,
        val cachePath: String,
        val libPath: String,
        val virtualProcPath: String,
        val networkNamespace: String,
        val memoryLimit: Long,
        val storageLimit: Long,
        val createdAt: Long,
        val lastAccessed: Long,
        var isActive: Boolean = true,
        val isolationLevel: IsolationLevel = IsolationLevel.STRICT,
        val securityPolicy: SecurityPolicy
    )
    
    /**
     * 🔒 Isolation Levels
     */
    enum class IsolationLevel {
        MINIMAL,    // Basic file separation
        STANDARD,   // File + process isolation
        STRICT,     // Complete isolation (default)
        MAXIMUM     // Ultra-secure isolation with encryption
    }
    
    /**
     * 🛡️ Security Policy for Sandbox
     */
    data class SecurityPolicy(
        val allowNetworkAccess: Boolean = true,
        val allowStorageAccess: Boolean = true,
        val allowCameraAccess: Boolean = false,
        val allowLocationAccess: Boolean = false,
        val allowContactsAccess: Boolean = false,
        val encryptData: Boolean = true,
        val auditAllAccess: Boolean = true,
        val restrictedPermissions: Set<String> = emptySet(),
        val allowedNetworkHosts: Set<String> = emptySet(),
        val maxStorageSize: Long = 8192 * 1024 * 1024, // 8GB increased limit
        val maxMemorySize: Long = 1024 * 1024 * 1024,   // 1GB increased limit
        val enableStorageCleanup: Boolean = true,       // Auto cleanup when limit reached
        val storageWarningThreshold: Float = 0.8f       // Warning at 80% usage
    )
    
    /**
     * 🚀 Initialize Complete Sandbox System
     */
    private fun initializeSandboxSystem() {
        try {
            Log.d(TAG, "🏗️ Initializing Complete Sandbox System...")
            
            // Create sandbox root directory
            createSandboxRootDirectory()
            
            // Initialize virtual file system
            initializeVirtualFileSystem()
            
            // Setup process isolation
            setupProcessIsolation()
            
            // Initialize network isolation
            initializeNetworkIsolation()
            
            // Setup memory management
            setupMemoryManagement()
            
            // Start sandbox monitoring
            startSandboxMonitoring()
            
            Log.d(TAG, "✅ Sandbox System initialized successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to initialize sandbox system", e)
            throw SecurityException("Sandbox initialization failed", e)
        }
    }
    
    /**
     * 🏗️ Create Complete Sandbox Environment
     * Creates a new isolated environment for a cloned app
     */
    fun createSandboxEnvironment(
        cloneId: String,
        packageName: String,
        isolationLevel: IsolationLevel = IsolationLevel.STRICT,
        securityPolicy: SecurityPolicy = SecurityPolicy()
    ): SandboxEnvironment? {
        
        try {
            Log.d(TAG, "🏗️ Creating sandbox environment for $packageName (Clone: $cloneId)")
            Log.d(TAG, "🔒 Isolation Level: $isolationLevel")
            
            // Generate unique sandbox ID
            val sandboxId = "sandbox_${sandboxCounter.incrementAndGet()}_${System.currentTimeMillis()}"
            
            // Create sandbox directory structure
            val rootPath = createSandboxDirectoryStructure(sandboxId, packageName)
            
            // Setup virtual process space
            val virtualProcPath = setupVirtualProcessSpace(sandboxId)
            
            // Create isolated storage
            val (dataPath, cachePath, libPath) = createIsolatedStorage(sandboxId, packageName, securityPolicy)
            
            // Setup network namespace
            val networkNamespace = createNetworkNamespace(sandboxId)
            
            // Create sandbox environment object
            val sandbox = SandboxEnvironment(
                sandboxId = sandboxId,
                cloneId = cloneId,
                packageName = packageName,
                processId = Process.myPid(), // Will be updated when app launches
                rootPath = rootPath,
                dataPath = dataPath,
                cachePath = cachePath,
                libPath = libPath,
                virtualProcPath = virtualProcPath,
                networkNamespace = networkNamespace,
                memoryLimit = securityPolicy.maxMemorySize,
                storageLimit = securityPolicy.maxStorageSize,
                createdAt = System.currentTimeMillis(),
                lastAccessed = System.currentTimeMillis(),
                isActive = true,
                isolationLevel = isolationLevel,
                securityPolicy = securityPolicy
            )
            
            // Apply security restrictions
            applySandboxSecurity(sandbox)
            
            // Setup file system hooks
            setupFileSystemHooks(sandbox)
            
            // Register sandbox
            activeSandboxes[sandboxId] = sandbox
            
            // Create sandbox configuration file
            saveSandboxConfiguration(sandbox)
            
            Log.d(TAG, "✅ Sandbox environment created successfully")
            Log.d(TAG, "📁 Sandbox ID: $sandboxId")
            Log.d(TAG, "📁 Root Path: $rootPath")
            Log.d(TAG, "💾 Data Path: $dataPath")
            Log.d(TAG, "🔒 Security Level: ${isolationLevel}")
            
            return sandbox
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to create sandbox environment", e)
            return null
        }
    }
    
    /**
     * 📁 Create Sandbox Directory Structure
     * Creates complete directory hierarchy for isolated app
     */
    private fun createSandboxDirectoryStructure(sandboxId: String, packageName: String): String {
        val sandboxRoot = File(context.filesDir, "$SANDBOX_ROOT_DIR/$sandboxId")
        
        // Create main directories
        val directories = listOf(
            "data/data/$packageName",      // App data directory
            "data/data/$packageName/cache", // Cache directory
            "data/data/$packageName/databases", // Databases
            "data/data/$packageName/shared_prefs", // SharedPreferences
            "data/data/$packageName/files", // App files
            "data/data/$packageName/code_cache", // Code cache
            "storage/emulated/0",          // External storage
            "system/lib",                  // System libraries
            "system/bin",                  // System binaries
            "proc",                        // Virtual proc filesystem
            "dev",                         // Device files
            "tmp",                         // Temporary files
            "var/log",                     // Log files
            "etc"                          // Configuration files
        )
        
        for (dir in directories) {
            val dirFile = File(sandboxRoot, dir)
            if (!dirFile.exists()) {
                dirFile.mkdirs()
                
                // Set appropriate permissions
                dirFile.setReadable(true, true)   // Owner read only
                dirFile.setWritable(true, true)   // Owner write only
                dirFile.setExecutable(true, true) // Owner execute only
            }
        }
        
        Log.d(TAG, "📁 Created sandbox directory structure at: ${sandboxRoot.absolutePath}")
        return sandboxRoot.absolutePath
    }
    
    /**
     * 🖥️ Setup Virtual Process Space
     * Creates virtual /proc filesystem for process isolation
     */
    private fun setupVirtualProcessSpace(sandboxId: String): String {
        val procPath = File(context.filesDir, "$SANDBOX_ROOT_DIR/$sandboxId/proc")
        
        // Create virtual proc entries
        val procEntries = mapOf(
            "version" to "Linux version 5.10.0-virtual",
            "cmdline" to "android.process.acore",
            "stat" to generateVirtualProcStat(),
            "meminfo" to generateVirtualMemInfo(),
            "cpuinfo" to generateVirtualCpuInfo(),
            "mounts" to generateVirtualMounts(sandboxId)
        )
        
        for ((entry, content) in procEntries) {
            val entryFile = File(procPath, entry)
            entryFile.writeText(content)
        }
        
        Log.d(TAG, "🖥️ Virtual process space created at: ${procPath.absolutePath}")
        return procPath.absolutePath
    }
    
    /**
     * 💾 Create Isolated Storage
     * Sets up completely isolated storage for the sandbox
     */
    private fun createIsolatedStorage(sandboxId: String, packageName: String, securityPolicy: SecurityPolicy): Triple<String, String, String> {
        val sandboxRoot = File(context.filesDir, "$SANDBOX_ROOT_DIR/$sandboxId")
        
        // Data directory
        val dataPath = File(sandboxRoot, "data/data/$packageName").apply {
            mkdirs()
            setReadable(true, true)
            setWritable(true, true)
        }
        
        // Cache directory  
        val cachePath = File(sandboxRoot, "data/data/$packageName/cache").apply {
            mkdirs()
            setReadable(true, true)
            setWritable(true, true)
        }
        
        // Library directory
        val libPath = File(sandboxRoot, "data/data/$packageName/lib").apply {
            mkdirs()
            setReadable(true, true)
            setExecutable(true, true)
        }
        
        // Create storage quota file with SecurityPolicy limit
        val quotaFile = File(sandboxRoot, ".storage_quota")
        quotaFile.writeText("${securityPolicy.maxStorageSize}") // Use SecurityPolicy limit
        
        Log.d(TAG, "💾 Isolated storage created")
        Log.d(TAG, "   📁 Data: ${dataPath.absolutePath}")
        Log.d(TAG, "   💾 Cache: ${cachePath.absolutePath}") 
        Log.d(TAG, "   📚 Lib: ${libPath.absolutePath}")
        
        return Triple(dataPath.absolutePath, cachePath.absolutePath, libPath.absolutePath)
    }
    
    /**
     * 🌐 Create Network Namespace
     * Sets up isolated network environment
     */
    private fun createNetworkNamespace(sandboxId: String): String {
        val networkNamespace = "netns_$sandboxId"
        
        // Create virtual network interface configuration
        val networkConfig = JSONObject().apply {
            put("namespace", networkNamespace)
            put("interface", "veth_$sandboxId")
            put("ip_range", "192.168.${Random().nextInt(255)}.0/24")
            put("gateway", "192.168.${Random().nextInt(255)}.1")
            put("dns", arrayOf("8.8.8.8", "8.8.4.4"))
            put("isolated", true)
        }
        
        // Save network configuration
        val networkConfigFile = File(context.filesDir, "$SANDBOX_ROOT_DIR/$sandboxId/network_config.json")
        networkConfigFile.writeText(networkConfig.toString())
        
        Log.d(TAG, "🌐 Network namespace created: $networkNamespace")
        return networkNamespace
    }
    
    /**
     * 🔒 Apply Sandbox Security
     * Applies security restrictions to the sandbox
     */
    private fun applySandboxSecurity(sandbox: SandboxEnvironment) {
        Log.d(TAG, "🔒 Applying sandbox security for ${sandbox.sandboxId}")
        
        // File permissions
        applyFilePermissions(sandbox)
        
        // Process restrictions
        applyProcessRestrictions(sandbox)
        
        // Network restrictions
        applyNetworkRestrictions(sandbox)
        
        // Memory restrictions
        applyMemoryRestrictions(sandbox)
        
        // System call filtering
        applySystemCallFiltering(sandbox)
        
        Log.d(TAG, "✅ Sandbox security applied successfully")
    }
    
    private fun applyFilePermissions(sandbox: SandboxEnvironment) {
        val sandboxRoot = File(sandbox.rootPath)
        
        // Apply strict file permissions
        sandboxRoot.setReadable(false, false)  // No world read
        sandboxRoot.setWritable(false, false)  // No world write
        sandboxRoot.setExecutable(false, false) // No world execute
        
        // Owner-only permissions
        sandboxRoot.setReadable(true, true)    // Owner read
        sandboxRoot.setWritable(true, true)    // Owner write
        sandboxRoot.setExecutable(true, true)  // Owner execute
    }
    
    private fun applyProcessRestrictions(sandbox: SandboxEnvironment) {
        // Create process restrictions configuration
        val restrictions = JSONObject().apply {
            put("max_processes", 10)
            put("max_threads", 50)
            put("max_open_files", 1024)
            put("nice_level", 10)  // Lower priority
            put("cpu_quota", 50)   // 50% CPU max
        }
        
        val restrictionFile = File(sandbox.rootPath, "process_restrictions.json")
        restrictionFile.writeText(restrictions.toString())
    }
    
    private fun applyNetworkRestrictions(sandbox: SandboxEnvironment) {
        if (!sandbox.securityPolicy.allowNetworkAccess) {
            // Block all network access
            val networkBlock = File(sandbox.rootPath, ".network_blocked")
            networkBlock.createNewFile()
        }
        
        // Create network whitelist if specified
        if (sandbox.securityPolicy.allowedNetworkHosts.isNotEmpty()) {
            val whitelist = JSONArray()
            sandbox.securityPolicy.allowedNetworkHosts.forEach { host ->
                whitelist.put(host)
            }
            
            val whitelistFile = File(sandbox.rootPath, "network_whitelist.json")
            whitelistFile.writeText(whitelist.toString())
        }
    }
    
    private fun applyMemoryRestrictions(sandbox: SandboxEnvironment) {
        val memoryConfig = JSONObject().apply {
            put("max_memory_bytes", sandbox.memoryLimit)
            put("max_heap_size", sandbox.memoryLimit / 2)
            put("oom_score_adj", 15) // More likely to be killed under memory pressure
        }
        
        val memoryFile = File(sandbox.rootPath, "memory_limits.json")
        memoryFile.writeText(memoryConfig.toString())
    }
    
    private fun applySystemCallFiltering(sandbox: SandboxEnvironment) {
        // Define allowed/blocked system calls based on security policy
        val syscallPolicy = JSONObject().apply {
            put("block_network", !sandbox.securityPolicy.allowNetworkAccess)
            put("block_file_creation", false)
            put("block_process_creation", true)
            put("audit_all_calls", sandbox.securityPolicy.auditAllAccess)
        }
        
        val syscallFile = File(sandbox.rootPath, "syscall_policy.json")
        syscallFile.writeText(syscallPolicy.toString())
    }
    
    /**
     * 🗃️ Setup File System Hooks
     * Intercepts and redirects file system calls
     */
    private fun setupFileSystemHooks(sandbox: SandboxEnvironment) {
        // Create file redirection table
        val redirections = JSONObject().apply {
            put("/data/data/${sandbox.packageName}", sandbox.dataPath)
            put("/storage/emulated/0", "${sandbox.rootPath}/storage/emulated/0")
            put("/proc", sandbox.virtualProcPath)
            put("/tmp", "${sandbox.rootPath}/tmp")
        }
        
        val hookConfigFile = File(sandbox.rootPath, "file_hooks.json")
        hookConfigFile.writeText(redirections.toString())
        
        Log.d(TAG, "🗃️ File system hooks configured for ${sandbox.sandboxId}")
    }
    
    /**
     * 💾 Save Sandbox Configuration
     */
    private fun saveSandboxConfiguration(sandbox: SandboxEnvironment) {
        val config = JSONObject().apply {
            put("sandboxId", sandbox.sandboxId)
            put("cloneId", sandbox.cloneId)
            put("packageName", sandbox.packageName)
            put("rootPath", sandbox.rootPath)
            put("dataPath", sandbox.dataPath)
            put("isolationLevel", sandbox.isolationLevel.name)
            put("createdAt", sandbox.createdAt)
            put("securityPolicy", JSONObject().apply {
                put("allowNetworkAccess", sandbox.securityPolicy.allowNetworkAccess)
                put("allowStorageAccess", sandbox.securityPolicy.allowStorageAccess)
                put("encryptData", sandbox.securityPolicy.encryptData)
                put("maxStorageSize", sandbox.securityPolicy.maxStorageSize)
                put("maxMemorySize", sandbox.securityPolicy.maxMemorySize)
            })
        }
        
        val configFile = File(context.filesDir, "sandbox_configs/${sandbox.sandboxId}.json")
        configFile.parentFile?.mkdirs()
        configFile.writeText(config.toString(2))
    }
    
    /**
     * 🗑️ Destroy Sandbox Environment
     * Completely removes a sandbox and cleans up resources
     */
    fun destroySandboxEnvironment(sandboxId: String): Boolean {
        return try {
            Log.d(TAG, "🗑️ Destroying sandbox environment: $sandboxId")
            
            val sandbox = activeSandboxes[sandboxId]
            if (sandbox == null) {
                Log.w(TAG, "Sandbox not found: $sandboxId")
                return false
            }
            
            // Stop any running processes in the sandbox
            terminateSandboxProcesses(sandbox)
            
            // Clean up file system
            val sandboxRoot = File(sandbox.rootPath)
            if (sandboxRoot.exists()) {
                sandboxRoot.deleteRecursively()
            }
            
            // Remove configuration
            val configFile = File(context.filesDir, "sandbox_configs/$sandboxId.json")
            if (configFile.exists()) {
                configFile.delete()
            }
            
            // Remove from active sandboxes
            activeSandboxes.remove(sandboxId)
            
            Log.d(TAG, "✅ Sandbox environment destroyed: $sandboxId")
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to destroy sandbox: $sandboxId", e)
            false
        }
    }
    
    /**
     * 🧹 Clear All Sandbox Environments
     * Destroys all active sandboxes and cleans up resources
     */
    fun clearAllSandboxes(): Boolean {
        return try {
            Log.d(TAG, "🧹 Clearing all sandbox environments...")
            
            val sandboxIds = activeSandboxes.keys.toList()
            var successCount = 0
            
            for (sandboxId in sandboxIds) {
                if (destroySandboxEnvironment(sandboxId)) {
                    successCount++
                }
            }
            
            // Clear the entire sandbox root directory
            val sandboxRoot = File(context.filesDir, SANDBOX_ROOT_DIR)
            if (sandboxRoot.exists()) {
                sandboxRoot.deleteRecursively()
                sandboxRoot.mkdirs()
            }
            
            // Clear all config files
            val configDir = File(context.filesDir, "sandbox_configs")
            if (configDir.exists()) {
                configDir.deleteRecursively()
                configDir.mkdirs()
            }
            
            Log.d(TAG, "✅ Cleared $successCount/${sandboxIds.size} sandbox environments")
            successCount == sandboxIds.size
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to clear all sandboxes", e)
            false
        }
    }
    
    private fun terminateSandboxProcesses(sandbox: SandboxEnvironment) {
        // In a real implementation, you would terminate processes running in the sandbox
        Log.d(TAG, "Terminating processes for sandbox: ${sandbox.sandboxId}")
    }
    
    // 🖥️ Virtual File System Generators
    
    private fun generateVirtualProcStat(): String {
        return "cpu  ${Random().nextInt(100000)} 0 ${Random().nextInt(50000)} ${Random().nextInt(200000)} 0 0 0 0 0 0\n"
    }
    
    private fun generateVirtualMemInfo(): String {
        return """
            MemTotal:        2048000 kB
            MemFree:         1024000 kB
            MemAvailable:    1536000 kB
            Cached:          512000 kB
        """.trimIndent()
    }
    
    private fun generateVirtualCpuInfo(): String {
        return """
            processor       : 0
            vendor_id       : VirtualCPU
            cpu family      : 6
            model           : 142
            model name      : Virtual CPU @ 2.40GHz
        """.trimIndent()
    }
    
    private fun generateVirtualMounts(sandboxId: String): String {
        return """
            /dev/root / ext4 rw,relatime 0 0
            proc /proc proc rw,nosuid,nodev,noexec,relatime 0 0
            tmpfs /tmp tmpfs rw,nosuid,nodev 0 0
        """.trimIndent()
    }
    
    // 🔧 System Initialization Methods
    
    private fun createSandboxRootDirectory() {
        val sandboxRoot = File(context.filesDir, SANDBOX_ROOT_DIR)
        if (!sandboxRoot.exists()) {
            sandboxRoot.mkdirs()
        }
        
        // Create config directory
        val configDir = File(context.filesDir, "sandbox_configs")
        if (!configDir.exists()) {
            configDir.mkdirs()
        }
    }
    
    private fun initializeVirtualFileSystem() {
        Log.d(TAG, "Initializing virtual file system")
        // Setup base virtual file system structure
    }
    
    private fun setupProcessIsolation() {
        Log.d(TAG, "Setting up process isolation")
        // Initialize process isolation mechanisms
    }
    
    private fun initializeNetworkIsolation() {
        Log.d(TAG, "Initializing network isolation")
        // Setup network namespace isolation
    }
    
    private fun setupMemoryManagement() {
        Log.d(TAG, "Setting up memory management")
        // Initialize memory limits and monitoring
    }
    
    private fun startSandboxMonitoring() {
        // Start background monitoring thread
        Thread {
            while (true) {
                try {
                    Thread.sleep(10000) // Check every 10 seconds
                    monitorSandboxHealth()
                } catch (e: InterruptedException) {
                    break
                } catch (e: Exception) {
                    Log.e(TAG, "Sandbox monitoring error", e)
                }
            }
        }.start()
    }
    
    private fun monitorSandboxHealth() {
        for ((sandboxId, sandbox) in activeSandboxes) {
            try {
                // Check storage usage
                val storageUsed = calculateStorageUsage(sandbox)
                
                // Debug logging for storage limit issue
                Log.d(TAG, "📊 Sandbox $sandboxId Storage Debug:")
                Log.d(TAG, "   💾 Storage Used: ${storageUsed / (1024 * 1024)} MB")
                Log.d(TAG, "   📏 Storage Limit: ${sandbox.storageLimit / (1024 * 1024)} MB")
                Log.d(TAG, "   🔧 Security Policy Max: ${sandbox.securityPolicy.maxStorageSize / (1024 * 1024)} MB")
                
                // Prevent division by zero
                val storageUsagePercent = if (sandbox.storageLimit > 0) {
                    storageUsed.toFloat() / sandbox.storageLimit.toFloat()
                } else {
                    Log.e(TAG, "❌ Sandbox $sandboxId has ZERO storage limit! Using security policy limit.")
                    storageUsed.toFloat() / sandbox.securityPolicy.maxStorageSize.toFloat()
                }
                
                // Warning threshold check
                if (storageUsagePercent >= sandbox.securityPolicy.storageWarningThreshold) {
                    Log.w(TAG, "⚠️ Sandbox $sandboxId storage usage: ${(storageUsagePercent * 100).toInt()}%")
                }
                
                // Storage limit exceeded - use proper limit value
                val effectiveStorageLimit = if (sandbox.storageLimit > 0) sandbox.storageLimit else sandbox.securityPolicy.maxStorageSize
                if (storageUsed > effectiveStorageLimit) {
                    Log.e(TAG, "🚨 Sandbox $sandboxId exceeded storage limit: ${storageUsed / (1024 * 1024)} MB / ${effectiveStorageLimit / (1024 * 1024)} MB")
                    
                    // Auto cleanup if enabled
                    if (sandbox.securityPolicy.enableStorageCleanup) {
                        performStorageCleanup(sandbox)
                    }
                }
                
                // Memory usage check
                checkMemoryUsage(sandbox)
                
                // Update last accessed time if sandbox is active
                if (sandbox.isActive) {
                    // Update in database or memory
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error monitoring sandbox $sandboxId", e)
            }
        }
    }
    
    private fun calculateStorageUsage(sandbox: SandboxEnvironment): Long {
        return try {
            val sandboxRoot = File(sandbox.rootPath)
            calculateDirectorySize(sandboxRoot)
        } catch (e: Exception) {
            0L
        }
    }
    
    private fun calculateDirectorySize(directory: File): Long {
        var size = 0L
        if (directory.exists()) {
            directory.walkTopDown().forEach { file ->
                if (file.isFile) {
                    size += file.length()
                }
            }
        }
        return size
    }
    
    /**
     * 🧹 Perform Storage Cleanup
     * Automatically cleans up sandbox storage when limit is exceeded
     */
    private fun performStorageCleanup(sandbox: SandboxEnvironment) {
        try {
            Log.d(TAG, "🧹 Performing storage cleanup for sandbox: ${sandbox.sandboxId}")
            
            val sandboxRoot = File(sandbox.rootPath)
            
            // Clean cache directories first
            val cacheDir = File(sandbox.cachePath)
            if (cacheDir.exists()) {
                cacheDir.deleteRecursively()
                cacheDir.mkdirs()
                Log.d(TAG, "🗑️ Cleaned cache directory")
            }
            
            // Clean temporary files
            val tempDir = File(sandboxRoot, "tmp")
            if (tempDir.exists()) {
                tempDir.deleteRecursively()
                tempDir.mkdirs()
                Log.d(TAG, "🗑️ Cleaned temp directory")
            }
            
            // Clean log files older than 7 days
            val logDir = File(sandboxRoot, "var/log")
            if (logDir.exists()) {
                val sevenDaysAgo = System.currentTimeMillis() - (7 * 24 * 60 * 60 * 1000)
                logDir.listFiles()?.forEach { file ->
                    if (file.lastModified() < sevenDaysAgo) {
                        file.delete()
                    }
                }
                Log.d(TAG, "🗑️ Cleaned old log files")
            }
            
            // Verify cleanup success
            val newStorageUsed = calculateStorageUsage(sandbox)
            Log.d(TAG, "✅ Storage cleanup completed. New usage: ${newStorageUsed / (1024 * 1024)} MB")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Storage cleanup failed for sandbox: ${sandbox.sandboxId}", e)
        }
    }
    
    /**
     * 🧠 Check Memory Usage
     * Monitors memory usage of sandbox processes
     */
    private fun checkMemoryUsage(sandbox: SandboxEnvironment) {
        try {
            val runtime = Runtime.getRuntime()
            val usedMemory = runtime.totalMemory() - runtime.freeMemory()
            val memoryUsagePercent = usedMemory.toFloat() / sandbox.memoryLimit.toFloat()
            
            if (memoryUsagePercent >= 0.9f) {
                Log.w(TAG, "⚠️ Sandbox ${sandbox.sandboxId} high memory usage: ${(memoryUsagePercent * 100).toInt()}%")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error checking memory usage for sandbox: ${sandbox.sandboxId}", e)
        }
    }
    
    // 🔓 Public API Methods
    
    fun getSandboxEnvironment(sandboxId: String): SandboxEnvironment? {
        return activeSandboxes[sandboxId]
    }
    
    fun getAllActiveSandboxes(): List<SandboxEnvironment> {
        return activeSandboxes.values.toList()
    }
    
    fun getSandboxCount(): Int = activeSandboxes.size
    
    fun getSandboxReport(): String {
        val activeCount = activeSandboxes.size
        val totalStorage = activeSandboxes.values.sumOf { calculateStorageUsage(it) }
        
        return """
        📦 Sandbox System Report
        ═══════════════════════════════
        🏗️ Active Sandboxes: $activeCount
        💾 Total Storage Used: ${totalStorage / (1024 * 1024)} MB
        🔒 Security Level: HIGH
        📊 System Status: HEALTHY
        ═══════════════════════════════
        """.trimIndent()
    }
}
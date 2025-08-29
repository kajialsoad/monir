package com.multispace.app.multispace_cloner

import android.content.Context
import android.content.SharedPreferences
import android.os.Environment
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream
import org.json.JSONObject
import org.json.JSONArray

/**
 * Data Isolation Manager - Handles data separation and storage management for cloned apps
 * This class ensures that each cloned app has its own isolated data environment
 */
class DataIsolationManager(private val context: Context) {
    
    private val prefs: SharedPreferences = context.getSharedPreferences("data_isolation", Context.MODE_PRIVATE)
    
    companion object {
        private const val ISOLATION_ROOT = "isolated_data"
        private const val BACKUP_EXTENSION = ".backup"
        private const val MAX_BACKUP_SIZE = 100 * 1024 * 1024 // 100MB
    }
    
    /**
     * Creates isolated storage for a cloned app
     * @param packageName The package name of the app
     * @param virtualSpaceId The virtual space ID
     * @return true if successful, false otherwise
     */
    fun createIsolatedStorage(packageName: String, virtualSpaceId: String): Boolean {
        try {
            val isolatedDir = getIsolatedDirectory(packageName, virtualSpaceId)
            if (isolatedDir == null) {
                return false
            }
            
            // Create directory structure for isolated storage
            val directories = arrayOf(
                "app_data",
                "app_cache", 
                "app_files",
                "app_databases",
                "shared_prefs",
                "external_files",
                "external_cache"
            )
            
            for (dir in directories) {
                val directory = File(isolatedDir, dir)
                if (!directory.exists()) {
                    directory.mkdirs()
                }
            }
            
            // Create isolation configuration
            val config = JSONObject().apply {
                put("packageName", packageName)
                put("virtualSpaceId", virtualSpaceId)
                put("createdAt", System.currentTimeMillis())
                put("dataPath", isolatedDir.absolutePath)
                put("storageUsed", 0)
                put("isActive", true)
            }
            
            // Save isolation configuration
            saveIsolationConfig(packageName, virtualSpaceId, config)
            
            // Setup file system redirection
            setupFileSystemRedirection(packageName, virtualSpaceId, isolatedDir)
            
            return true
            
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Clears isolated storage for a cloned app
     * @param packageName The package name of the app
     * @param virtualSpaceId The virtual space ID
     * @return true if successful, false otherwise
     */
    fun clearIsolatedStorage(packageName: String, virtualSpaceId: String): Boolean {
        try {
            val isolatedDir = getIsolatedDirectory(packageName, virtualSpaceId)
            if (isolatedDir != null && isolatedDir.exists()) {
                // Create backup before clearing (optional)
                createBackup(packageName, virtualSpaceId)
                
                // Clear all data
                isolatedDir.deleteRecursively()
            }
            
            // Remove isolation configuration
            removeIsolationConfig(packageName, virtualSpaceId)
            
            return true
            
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Gets the isolated directory for a specific app and virtual space
     * @param packageName The package name of the app
     * @param virtualSpaceId The virtual space ID
     * @return File object representing the isolated directory
     */
    fun getIsolatedDirectory(packageName: String, virtualSpaceId: String): File? {
        try {
            val isolationRoot = File(context.filesDir, ISOLATION_ROOT)
            if (!isolationRoot.exists()) {
                isolationRoot.mkdirs()
            }
            
            val appIsolationDir = File(isolationRoot, "${packageName}_${virtualSpaceId}")
            return appIsolationDir
            
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }
    
    /**
     * Calculates storage usage for isolated app data
     * @param packageName The package name of the app
     * @param virtualSpaceId The virtual space ID
     * @return Storage usage in bytes
     */
    fun calculateStorageUsage(packageName: String, virtualSpaceId: String): Long {
        try {
            val isolatedDir = getIsolatedDirectory(packageName, virtualSpaceId)
            if (isolatedDir != null && isolatedDir.exists()) {
                return calculateDirectorySize(isolatedDir)
            }
            return 0
        } catch (e: Exception) {
            e.printStackTrace()
            return 0
        }
    }
    
    /**
     * Creates a backup of isolated app data
     * @param packageName The package name of the app
     * @param virtualSpaceId The virtual space ID
     * @return true if successful, false otherwise
     */
    fun createBackup(packageName: String, virtualSpaceId: String): Boolean {
        try {
            val isolatedDir = getIsolatedDirectory(packageName, virtualSpaceId)
            if (isolatedDir == null || !isolatedDir.exists()) {
                return false
            }
            
            // Check if backup size would exceed limit
            val dataSize = calculateDirectorySize(isolatedDir)
            if (dataSize > MAX_BACKUP_SIZE) {
                return false // Data too large to backup
            }
            
            val backupDir = File(context.filesDir, "backups")
            if (!backupDir.exists()) {
                backupDir.mkdirs()
            }
            
            val backupFile = File(backupDir, "${packageName}_${virtualSpaceId}_${System.currentTimeMillis()}$BACKUP_EXTENSION")
            
            // Create ZIP backup
            return createZipBackup(isolatedDir, backupFile)
            
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Restores app data from backup
     * @param packageName The package name of the app
     * @param virtualSpaceId The virtual space ID
     * @param backupFile The backup file to restore from
     * @return true if successful, false otherwise
     */
    fun restoreFromBackup(packageName: String, virtualSpaceId: String, backupFile: File): Boolean {
        try {
            if (!backupFile.exists()) {
                return false
            }
            
            val isolatedDir = getIsolatedDirectory(packageName, virtualSpaceId)
            if (isolatedDir == null) {
                return false
            }
            
            // Clear existing data
            if (isolatedDir.exists()) {
                isolatedDir.deleteRecursively()
            }
            isolatedDir.mkdirs()
            
            // Extract backup
            return extractZipBackup(backupFile, isolatedDir)
            
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Gets isolated SharedPreferences for a cloned app
     * @param packageName The package name of the app
     * @param virtualSpaceId The virtual space ID
     * @param prefName The preference file name
     * @return SharedPreferences instance
     */
    fun getIsolatedSharedPreferences(packageName: String, virtualSpaceId: String, prefName: String): SharedPreferences? {
        try {
            val isolatedDir = getIsolatedDirectory(packageName, virtualSpaceId)
            if (isolatedDir != null) {
                val prefsDir = File(isolatedDir, "shared_prefs")
                if (!prefsDir.exists()) {
                    prefsDir.mkdirs()
                }
                
                // Create isolated preferences file path
                val prefsFile = File(prefsDir, "${prefName}.xml")
                
                // Return custom SharedPreferences implementation
                return IsolatedSharedPreferences(prefsFile)
            }
            return null
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }
    
    /**
     * Gets app usage statistics for a cloned app
     * @param packageName The package name of the app
     * @param virtualSpaceId The virtual space ID
     * @return Map containing usage statistics
     */
    fun getAppUsageStats(packageName: String, virtualSpaceId: String): Map<String, Any> {
        val usageStats = mutableMapOf<String, Any>()
        
        try {
            val isolatedDir = getIsolatedDirectory(packageName, virtualSpaceId)
            if (isolatedDir != null && isolatedDir.exists()) {
                // Calculate storage usage
                val storageUsage = calculateDirectorySize(isolatedDir)
                usageStats["storageUsage"] = storageUsage
                
                // Get last access time
                val lastAccessFile = File(isolatedDir, ".last_access")
                val lastAccessTime = if (lastAccessFile.exists()) {
                    lastAccessFile.lastModified()
                } else {
                    0L
                }
                usageStats["lastAccessTime"] = lastAccessTime
                
                // Get app launch count
                val launchCountFile = File(isolatedDir, ".launch_count")
                val launchCount = if (launchCountFile.exists()) {
                    try {
                        launchCountFile.readText().toIntOrNull() ?: 0
                    } catch (e: Exception) {
                        0
                    }
                } else {
                    0
                }
                usageStats["launchCount"] = launchCount
                
                // Get total runtime
                val runtimeFile = File(isolatedDir, ".total_runtime")
                val totalRuntime = if (runtimeFile.exists()) {
                    try {
                        runtimeFile.readText().toLongOrNull() ?: 0L
                    } catch (e: Exception) {
                        0L
                    }
                } else {
                    0L
                }
                usageStats["totalRuntime"] = totalRuntime
                
                // Update last access time
                lastAccessFile.writeText(System.currentTimeMillis().toString())
            }
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return usageStats
    }
    
    // Private helper methods
    
    private fun setupFileSystemRedirection(packageName: String, virtualSpaceId: String, isolatedDir: File) {
        try {
            // Create file system redirection configuration
            val redirectionConfig = JSONObject().apply {
                put("packageName", packageName)
                put("virtualSpaceId", virtualSpaceId)
                put("isolatedPath", isolatedDir.absolutePath)
                put("redirections", JSONObject().apply {
                    put("/data/data/$packageName", "${isolatedDir.absolutePath}/app_data")
                    put("/data/data/$packageName/cache", "${isolatedDir.absolutePath}/app_cache")
                    put("/data/data/$packageName/files", "${isolatedDir.absolutePath}/app_files")
                    put("/data/data/$packageName/databases", "${isolatedDir.absolutePath}/app_databases")
                    put("/data/data/$packageName/shared_prefs", "${isolatedDir.absolutePath}/shared_prefs")
                })
            }
            
            // Save redirection configuration
            val editor = prefs.edit()
            editor.putString("redirection_${packageName}_${virtualSpaceId}", redirectionConfig.toString())
            editor.apply()
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun saveIsolationConfig(packageName: String, virtualSpaceId: String, config: JSONObject) {
        val editor = prefs.edit()
        editor.putString("isolation_${packageName}_${virtualSpaceId}", config.toString())
        editor.apply()
    }
    
    private fun removeIsolationConfig(packageName: String, virtualSpaceId: String) {
        val editor = prefs.edit()
        editor.remove("isolation_${packageName}_${virtualSpaceId}")
        editor.remove("redirection_${packageName}_${virtualSpaceId}")
        editor.apply()
    }
    
    private fun calculateDirectorySize(directory: File): Long {
        var size = 0L
        try {
            if (directory.isDirectory) {
                val files = directory.listFiles()
                if (files != null) {
                    for (file in files) {
                        size += if (file.isDirectory) {
                            calculateDirectorySize(file)
                        } else {
                            file.length()
                        }
                    }
                }
            } else {
                size = directory.length()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return size
    }
    
    // Virtual Storage Management
    fun createVirtualFileSystem(virtualSpaceId: String, packageName: String): Boolean {
        return try {
            val virtualRoot = File(getVirtualSpaceDirectory(virtualSpaceId), "filesystem")
            val appDataDir = File(virtualRoot, "data/data/$packageName")
            val appExternalDir = File(virtualRoot, "sdcard/Android/data/$packageName")
            val appCacheDir = File(virtualRoot, "cache/$packageName")
            val appFilesDir = File(virtualRoot, "files/$packageName")
            
            // Create directory structure
            listOf(appDataDir, appExternalDir, appCacheDir, appFilesDir).forEach { dir ->
                if (!dir.exists()) {
                    dir.mkdirs()
                }
            }
            
            // Create symbolic links for system directories
            createSystemDirectoryLinks(virtualRoot)
            
            // Setup file system redirection rules
            setupVirtualFileSystemRedirection(virtualSpaceId, packageName)
            
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    private fun getVirtualSpaceDirectory(virtualSpaceId: String): File {
        val virtualSpacesRoot = File(context.filesDir, "virtual_spaces")
        if (!virtualSpacesRoot.exists()) {
            virtualSpacesRoot.mkdirs()
        }
        return File(virtualSpacesRoot, virtualSpaceId)
    }
    
    private fun createSystemDirectoryLinks(virtualRoot: File) {
        val systemDirs = mapOf(
            "system" to "/system",
            "vendor" to "/vendor",
            "proc" to "/proc",
            "dev" to "/dev"
        )
        
        systemDirs.forEach { (virtualPath, realPath) ->
            val virtualDir = File(virtualRoot, virtualPath)
            if (!virtualDir.exists()) {
                try {
                    // Create symbolic link (requires root or special permissions)
                    Runtime.getRuntime().exec("ln -s $realPath ${virtualDir.absolutePath}")
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
    
    private fun setupVirtualFileSystemRedirection(virtualSpaceId: String, packageName: String) {
        val redirectionRules = mutableMapOf<String, String>()
        val virtualRoot = File(getVirtualSpaceDirectory(virtualSpaceId), "filesystem")
        
        // App data redirection
        redirectionRules["/data/data/$packageName"] = File(virtualRoot, "data/data/$packageName").absolutePath
        redirectionRules["/sdcard/Android/data/$packageName"] = File(virtualRoot, "sdcard/Android/data/$packageName").absolutePath
        
        // Cache redirection
        redirectionRules["/data/data/$packageName/cache"] = File(virtualRoot, "cache/$packageName").absolutePath
        
        // Files redirection
        redirectionRules["/data/data/$packageName/files"] = File(virtualRoot, "files/$packageName").absolutePath
        
        // Save redirection rules
        saveVirtualRedirectionRules(virtualSpaceId, packageName, redirectionRules)
    }
    
    private fun saveVirtualRedirectionRules(virtualSpaceId: String, packageName: String, rules: Map<String, String>) {
        val rulesFile = File(getVirtualSpaceDirectory(virtualSpaceId), "redirection_$packageName.json")
        try {
            val jsonRules = JSONObject()
            rules.forEach { (source, target) ->
                jsonRules.put(source, target)
            }
            rulesFile.writeText(jsonRules.toString())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    fun getVirtualRedirectionRules(virtualSpaceId: String, packageName: String): Map<String, String> {
        val rulesFile = File(getVirtualSpaceDirectory(virtualSpaceId), "redirection_$packageName.json")
        return try {
            if (rulesFile.exists()) {
                val jsonRules = JSONObject(rulesFile.readText())
                val rules = mutableMapOf<String, String>()
                jsonRules.keys().forEach { key ->
                    rules[key] = jsonRules.getString(key)
                }
                rules
            } else {
                emptyMap()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            emptyMap()
        }
    }
    
    // File System Redirection
    fun redirectPath(virtualSpaceId: String, packageName: String, originalPath: String): String {
        val rules = getVirtualRedirectionRules(virtualSpaceId, packageName)
        
        // Find matching redirection rule
        for ((sourcePath, targetPath) in rules) {
            if (originalPath.startsWith(sourcePath)) {
                return originalPath.replace(sourcePath, targetPath)
            }
        }
        
        // If no specific rule found, check for general app data paths
        return when {
            originalPath.contains("/data/data/$packageName") -> {
                val virtualRoot = File(getVirtualSpaceDirectory(virtualSpaceId), "filesystem")
                originalPath.replace("/data/data/$packageName", File(virtualRoot, "data/data/$packageName").absolutePath)
            }
            originalPath.contains("/sdcard/Android/data/$packageName") -> {
                val virtualRoot = File(getVirtualSpaceDirectory(virtualSpaceId), "filesystem")
                originalPath.replace("/sdcard/Android/data/$packageName", File(virtualRoot, "sdcard/Android/data/$packageName").absolutePath)
            }
            else -> originalPath
        }
    }
    
    // Virtual Storage Operations
    fun copyFileToVirtualSpace(virtualSpaceId: String, packageName: String, sourcePath: String, targetPath: String): Boolean {
        return try {
            val redirectedTarget = redirectPath(virtualSpaceId, packageName, targetPath)
            val sourceFile = File(sourcePath)
            val targetFile = File(redirectedTarget)
            
            // Ensure target directory exists
            targetFile.parentFile?.mkdirs()
            
            // Copy file
            sourceFile.copyTo(targetFile, overwrite = true)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    fun readFileFromVirtualSpace(virtualSpaceId: String, packageName: String, filePath: String): ByteArray? {
        return try {
            val redirectedPath = redirectPath(virtualSpaceId, packageName, filePath)
            val file = File(redirectedPath)
            if (file.exists() && file.isFile) {
                file.readBytes()
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    fun writeFileToVirtualSpace(virtualSpaceId: String, packageName: String, filePath: String, data: ByteArray): Boolean {
        return try {
            val redirectedPath = redirectPath(virtualSpaceId, packageName, filePath)
            val file = File(redirectedPath)
            
            // Ensure parent directory exists
            file.parentFile?.mkdirs()
            
            file.writeBytes(data)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    fun deleteFileFromVirtualSpace(virtualSpaceId: String, packageName: String, filePath: String): Boolean {
        return try {
            val redirectedPath = redirectPath(virtualSpaceId, packageName, filePath)
            val file = File(redirectedPath)
            if (file.exists()) {
                if (file.isDirectory) {
                    file.deleteRecursively()
                } else {
                    file.delete()
                }
            } else {
                true // File doesn't exist, consider it deleted
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    fun listVirtualSpaceFiles(virtualSpaceId: String, packageName: String, directoryPath: String): List<Map<String, Any>> {
        return try {
            val redirectedPath = redirectPath(virtualSpaceId, packageName, directoryPath)
            val directory = File(redirectedPath)
            
            if (directory.exists() && directory.isDirectory) {
                directory.listFiles()?.map { file ->
                    mapOf(
                        "name" to file.name,
                        "path" to file.absolutePath,
                        "isDirectory" to file.isDirectory,
                        "size" to if (file.isFile) file.length() else 0L,
                        "lastModified" to file.lastModified()
                    )
                } ?: emptyList()
            } else {
                emptyList()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            emptyList()
        }
    }
    
    // Virtual Storage Statistics
    fun getVirtualStorageStats(virtualSpaceId: String, packageName: String): Map<String, Any> {
        return try {
            val virtualRoot = File(getVirtualSpaceDirectory(virtualSpaceId), "filesystem")
            val appDataDir = File(virtualRoot, "data/data/$packageName")
            val appExternalDir = File(virtualRoot, "sdcard/Android/data/$packageName")
            val appCacheDir = File(virtualRoot, "cache/$packageName")
            val appFilesDir = File(virtualRoot, "files/$packageName")
            
            val dataSize = calculateDirectorySize(appDataDir)
            val externalSize = calculateDirectorySize(appExternalDir)
            val cacheSize = calculateDirectorySize(appCacheDir)
            val filesSize = calculateDirectorySize(appFilesDir)
            val totalSize = dataSize + externalSize + cacheSize + filesSize
            
            mapOf(
                "totalSize" to totalSize,
                "dataSize" to dataSize,
                "externalSize" to externalSize,
                "cacheSize" to cacheSize,
                "filesSize" to filesSize,
                "fileCount" to countFilesInDirectory(virtualRoot),
                "directoryCount" to countDirectoriesInDirectory(virtualRoot)
            )
        } catch (e: Exception) {
            e.printStackTrace()
            mapOf(
                "totalSize" to 0L,
                "dataSize" to 0L,
                "externalSize" to 0L,
                "cacheSize" to 0L,
                "filesSize" to 0L,
                "fileCount" to 0,
                "directoryCount" to 0
            )
        }
    }
    
    private fun countFilesInDirectory(directory: File): Int {
        if (!directory.exists() || !directory.isDirectory) return 0
        
        var count = 0
        directory.walkTopDown().forEach { file ->
            if (file.isFile) count++
        }
        return count
    }
    
    private fun countDirectoriesInDirectory(directory: File): Int {
        if (!directory.exists() || !directory.isDirectory) return 0
        
        var count = 0
        directory.walkTopDown().forEach { file ->
            if (file.isDirectory && file != directory) count++
        }
        return count
    }
    
    // Cleanup virtual storage
    fun cleanupVirtualStorage(virtualSpaceId: String, packageName: String): Boolean {
        return try {
            val virtualRoot = File(getVirtualSpaceDirectory(virtualSpaceId), "filesystem")
            val appCacheDir = File(virtualRoot, "cache/$packageName")
            
            // Clear cache directory
            if (appCacheDir.exists()) {
                appCacheDir.deleteRecursively()
                appCacheDir.mkdirs()
            }
            
            // Clear temporary files
            val tempDir = File(virtualRoot, "tmp/$packageName")
            if (tempDir.exists()) {
                tempDir.deleteRecursively()
            }
            
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    private fun createZipBackup(sourceDir: File, backupFile: File): Boolean {
        try {
            ZipOutputStream(FileOutputStream(backupFile)).use { zipOut ->
                zipDirectory(sourceDir, sourceDir.name, zipOut)
            }
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    private fun zipDirectory(folder: File, parentFolder: String, zipOut: ZipOutputStream) {
        val files = folder.listFiles()
        if (files != null) {
            for (file in files) {
                if (file.isDirectory) {
                    zipDirectory(file, "$parentFolder/${file.name}", zipOut)
                } else {
                    FileInputStream(file).use { fis ->
                        val zipEntry = ZipEntry("$parentFolder/${file.name}")
                        zipOut.putNextEntry(zipEntry)
                        
                        val buffer = ByteArray(1024)
                        var length: Int
                        while (fis.read(buffer).also { length = it } > 0) {
                            zipOut.write(buffer, 0, length)
                        }
                        zipOut.closeEntry()
                    }
                }
            }
        }
    }
    
    private fun extractZipBackup(backupFile: File, targetDir: File): Boolean {
        try {
            ZipInputStream(FileInputStream(backupFile)).use { zipIn ->
                var entry: ZipEntry? = zipIn.nextEntry
                while (entry != null) {
                    val file = File(targetDir, entry.name)
                    if (entry.isDirectory) {
                        file.mkdirs()
                    } else {
                        file.parentFile?.mkdirs()
                        FileOutputStream(file).use { fos ->
                            val buffer = ByteArray(1024)
                            var length: Int
                            while (zipIn.read(buffer).also { length = it } > 0) {
                                fos.write(buffer, 0, length)
                            }
                        }
                    }
                    zipIn.closeEntry()
                    entry = zipIn.nextEntry
                }
            }
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
}

/**
 * Custom SharedPreferences implementation for isolated storage
 */
class IsolatedSharedPreferences(private val prefsFile: File) : SharedPreferences {
    
    private val data = mutableMapOf<String, Any?>()
    
    init {
        loadPreferences()
    }
    
    override fun getAll(): MutableMap<String, *> = data.toMutableMap()
    
    override fun getString(key: String?, defValue: String?): String? {
        return data[key] as? String ?: defValue
    }
    
    override fun getStringSet(key: String?, defValues: MutableSet<String>?): MutableSet<String>? {
        @Suppress("UNCHECKED_CAST")
        return data[key] as? MutableSet<String> ?: defValues
    }
    
    override fun getInt(key: String?, defValue: Int): Int {
        return data[key] as? Int ?: defValue
    }
    
    override fun getLong(key: String?, defValue: Long): Long {
        return data[key] as? Long ?: defValue
    }
    
    override fun getFloat(key: String?, defValue: Float): Float {
        return data[key] as? Float ?: defValue
    }
    
    override fun getBoolean(key: String?, defValue: Boolean): Boolean {
        return data[key] as? Boolean ?: defValue
    }
    
    override fun contains(key: String?): Boolean {
        return data.containsKey(key)
    }
    
    override fun edit(): SharedPreferences.Editor {
        return IsolatedEditor()
    }
    
    override fun registerOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener?) {
        // Not implemented for isolated preferences
    }
    
    override fun unregisterOnSharedPreferenceChangeListener(listener: SharedPreferences.OnSharedPreferenceChangeListener?) {
        // Not implemented for isolated preferences
    }
    
    private fun loadPreferences() {
        try {
            if (prefsFile.exists()) {
                // Simple key-value loading (in real implementation, use XML parsing)
                val content = prefsFile.readText()
                // Parse and load preferences data
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun savePreferences() {
        try {
            prefsFile.parentFile?.mkdirs()
            // Simple key-value saving (in real implementation, use XML format)
            val content = data.toString()
            prefsFile.writeText(content)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    inner class IsolatedEditor : SharedPreferences.Editor {
        private val changes = mutableMapOf<String, Any?>()
        
        override fun putString(key: String?, value: String?): SharedPreferences.Editor {
            if (key != null) changes[key] = value
            return this
        }
        
        override fun putStringSet(key: String?, values: MutableSet<String>?): SharedPreferences.Editor {
            if (key != null) changes[key] = values
            return this
        }
        
        override fun putInt(key: String?, value: Int): SharedPreferences.Editor {
            if (key != null) changes[key] = value
            return this
        }
        
        override fun putLong(key: String?, value: Long): SharedPreferences.Editor {
            if (key != null) changes[key] = value
            return this
        }
        
        override fun putFloat(key: String?, value: Float): SharedPreferences.Editor {
            if (key != null) changes[key] = value
            return this
        }
        
        override fun putBoolean(key: String?, value: Boolean): SharedPreferences.Editor {
            if (key != null) changes[key] = value
            return this
        }
        
        override fun remove(key: String?): SharedPreferences.Editor {
            if (key != null) changes[key] = null
            return this
        }
        
        override fun clear(): SharedPreferences.Editor {
            data.clear()
            return this
        }
        
        override fun commit(): Boolean {
            return try {
                apply()
                true
            } catch (e: Exception) {
                false
            }
        }
        
        override fun apply() {
            for ((key, value) in changes) {
                if (value == null) {
                    data.remove(key)
                } else {
                    data[key] = value
                }
            }
            savePreferences()
            changes.clear()
        }
    }
}
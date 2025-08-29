package com.multispace.app.multispace_cloner

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import android.util.Log
import java.io.File
import java.util.concurrent.ConcurrentHashMap

/**
 * Memory optimization manager for virtual spaces
 * Handles memory monitoring, cleanup, and optimization
 */
class MemoryOptimizer(private val context: Context) {
    
    companion object {
        private const val TAG = "MemoryOptimizer"
        private const val LOW_MEMORY_THRESHOLD = 100 * 1024 * 1024 // 100MB
        private const val CRITICAL_MEMORY_THRESHOLD = 50 * 1024 * 1024 // 50MB
        private const val MAX_CACHE_SIZE = 50 * 1024 * 1024 // 50MB
    }
    
    private val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    private val memoryCache = ConcurrentHashMap<String, ByteArray>()
    private var currentCacheSize = 0L
    
    /**
     * Gets current memory usage information
     */
    fun getMemoryInfo(): Map<String, Any> {
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        val debugMemoryInfo = Debug.MemoryInfo()
        Debug.getMemoryInfo(debugMemoryInfo)
        
        return mapOf(
            "availableMemory" to memoryInfo.availMem,
            "totalMemory" to memoryInfo.totalMem,
            "lowMemory" to memoryInfo.lowMemory,
            "threshold" to memoryInfo.threshold,
            "usedMemory" to (memoryInfo.totalMem - memoryInfo.availMem),
            "dalvikPss" to debugMemoryInfo.dalvikPss * 1024,
            "nativePss" to debugMemoryInfo.nativePss * 1024,
            "otherPss" to debugMemoryInfo.otherPss * 1024,
            "totalPss" to debugMemoryInfo.totalPss * 1024,
            "cacheSize" to currentCacheSize
        )
    }
    
    /**
     * Checks if system is in low memory state
     */
    fun isLowMemory(): Boolean {
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        return memoryInfo.lowMemory || memoryInfo.availMem < LOW_MEMORY_THRESHOLD
    }
    
    /**
     * Checks if system is in critical memory state
     */
    fun isCriticalMemory(): Boolean {
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        return memoryInfo.availMem < CRITICAL_MEMORY_THRESHOLD
    }
    
    /**
     * Performs memory cleanup for a virtual space
     */
    fun cleanupVirtualSpace(virtualSpaceId: String): Boolean {
        return try {
            Log.d(TAG, "Starting memory cleanup for virtual space: $virtualSpaceId")
            
            // Clear temporary files
            clearTempFiles(virtualSpaceId)
            
            // Clear cache files
            clearCacheFiles(virtualSpaceId)
            
            // Clear memory cache for this virtual space
            clearMemoryCache(virtualSpaceId)
            
            // Force garbage collection
            System.gc()
            
            Log.d(TAG, "Memory cleanup completed for virtual space: $virtualSpaceId")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cleanup virtual space: ${e.message}")
            false
        }
    }
    
    /**
     * Performs global memory cleanup
     */
    fun performGlobalCleanup(): Boolean {
        return try {
            Log.d(TAG, "Starting global memory cleanup")
            
            // Clear all memory cache
            memoryCache.clear()
            currentCacheSize = 0L
            
            // Clear system cache if possible
            clearSystemCache()
            
            // Force garbage collection
            System.gc()
            
            Log.d(TAG, "Global memory cleanup completed")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to perform global cleanup: ${e.message}")
            false
        }
    }
    
    /**
     * Optimizes memory usage for virtual spaces
     */
    fun optimizeMemoryUsage(): Map<String, Any> {
        val beforeMemory = getMemoryInfo()
        val optimizationResults = mutableMapOf<String, Any>()
        
        try {
            // Check if optimization is needed
            if (isLowMemory()) {
                Log.d(TAG, "Low memory detected, starting optimization")
                
                // Clear unused virtual spaces
                val clearedSpaces = clearUnusedVirtualSpaces()
                optimizationResults["clearedSpaces"] = clearedSpaces
                
                // Compress memory cache
                val compressedSize = compressMemoryCache()
                optimizationResults["compressedCacheSize"] = compressedSize
                
                // Clear temporary files
                val clearedTempFiles = clearAllTempFiles()
                optimizationResults["clearedTempFiles"] = clearedTempFiles
                
                // Force garbage collection
                System.gc()
            }
            
            val afterMemory = getMemoryInfo()
            optimizationResults["beforeMemory"] = beforeMemory
            optimizationResults["afterMemory"] = afterMemory
            optimizationResults["memoryFreed"] = (beforeMemory["usedMemory"] as Long) - (afterMemory["usedMemory"] as Long)
            optimizationResults["success"] = true
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to optimize memory: ${e.message}")
            optimizationResults["success"] = false
            optimizationResults["error"] = e.message ?: "Unknown error"
        }
        
        return optimizationResults
    }
    
    /**
     * Adds data to memory cache
     */
    fun addToCache(key: String, data: ByteArray): Boolean {
        return try {
            if (currentCacheSize + data.size > MAX_CACHE_SIZE) {
                // Remove oldest entries to make space
                compressMemoryCache()
            }
            
            memoryCache[key] = data
            currentCacheSize += data.size
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add to cache: ${e.message}")
            false
        }
    }
    
    /**
     * Gets data from memory cache
     */
    fun getFromCache(key: String): ByteArray? {
        return memoryCache[key]
    }
    
    /**
     * Removes data from memory cache
     */
    fun removeFromCache(key: String): Boolean {
        val data = memoryCache.remove(key)
        if (data != null) {
            currentCacheSize -= data.size
            return true
        }
        return false
    }
    
    // Private helper methods
    
    private fun clearTempFiles(virtualSpaceId: String): Int {
        var clearedCount = 0
        try {
            val tempDir = File(context.filesDir, "virtual_spaces/$virtualSpaceId/temp")
            if (tempDir.exists()) {
                tempDir.listFiles()?.forEach { file ->
                    if (file.delete()) {
                        clearedCount++
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear temp files: ${e.message}")
        }
        return clearedCount
    }
    
    private fun clearCacheFiles(virtualSpaceId: String): Int {
        var clearedCount = 0
        try {
            val cacheDir = File(context.filesDir, "virtual_spaces/$virtualSpaceId/cache")
            if (cacheDir.exists()) {
                cacheDir.listFiles()?.forEach { file ->
                    if (file.delete()) {
                        clearedCount++
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear cache files: ${e.message}")
        }
        return clearedCount
    }
    
    private fun clearMemoryCache(virtualSpaceId: String): Int {
        var clearedCount = 0
        val keysToRemove = memoryCache.keys.filter { it.startsWith(virtualSpaceId) }
        keysToRemove.forEach { key ->
            if (removeFromCache(key)) {
                clearedCount++
            }
        }
        return clearedCount
    }
    
    private fun clearSystemCache() {
        try {
            // Clear app cache
            context.cacheDir.listFiles()?.forEach { file ->
                file.deleteRecursively()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear system cache: ${e.message}")
        }
    }
    
    private fun clearUnusedVirtualSpaces(): Int {
        var clearedCount = 0
        try {
            val virtualSpacesDir = File(context.filesDir, "virtual_spaces")
            if (virtualSpacesDir.exists()) {
                virtualSpacesDir.listFiles()?.forEach { spaceDir ->
                    if (spaceDir.isDirectory) {
                        val lastAccessFile = File(spaceDir, ".last_access")
                        if (lastAccessFile.exists()) {
                            val lastAccess = lastAccessFile.lastModified()
                            val daysSinceAccess = (System.currentTimeMillis() - lastAccess) / (1000 * 60 * 60 * 24)
                            
                            // Clear spaces not accessed for more than 7 days
                            if (daysSinceAccess > 7) {
                                if (spaceDir.deleteRecursively()) {
                                    clearedCount++
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear unused virtual spaces: ${e.message}")
        }
        return clearedCount
    }
    
    private fun compressMemoryCache(): Long {
        var compressedSize = 0L
        try {
            if (currentCacheSize > MAX_CACHE_SIZE) {
                val entriesToRemove = (currentCacheSize - MAX_CACHE_SIZE * 0.8).toLong()
                var removedSize = 0L
                
                val iterator = memoryCache.entries.iterator()
                while (iterator.hasNext() && removedSize < entriesToRemove) {
                    val entry = iterator.next()
                    removedSize += entry.value.size
                    iterator.remove()
                }
                
                currentCacheSize -= removedSize
                compressedSize = removedSize
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to compress memory cache: ${e.message}")
        }
        return compressedSize
    }
    
    private fun clearAllTempFiles(): Int {
        var clearedCount = 0
        try {
            val virtualSpacesDir = File(context.filesDir, "virtual_spaces")
            if (virtualSpacesDir.exists()) {
                virtualSpacesDir.listFiles()?.forEach { spaceDir ->
                    if (spaceDir.isDirectory) {
                        clearedCount += clearTempFiles(spaceDir.name)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear all temp files: ${e.message}")
        }
        return clearedCount
    }
}
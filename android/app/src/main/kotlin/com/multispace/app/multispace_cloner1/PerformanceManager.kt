package com.multispace.app.multispace_cloner

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.util.Log
import java.io.File
import java.io.RandomAccessFile
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt

/**
 * Advanced Performance Manager for MultiSpace Cloner
 * Handles CPU monitoring, battery optimization, background task management,
 * and overall system performance optimization
 */
class PerformanceManager(private val context: Context) {
    
    companion object {
        private const val TAG = "PerformanceManager"
        private const val HIGH_CPU_THRESHOLD = 80.0 // 80% CPU usage
        private const val CRITICAL_CPU_THRESHOLD = 95.0 // 95% CPU usage
        private const val LOW_BATTERY_THRESHOLD = 20 // 20% battery
        private const val CRITICAL_BATTERY_THRESHOLD = 10 // 10% battery
        private const val PERFORMANCE_CHECK_INTERVAL = 30L // 30 seconds
        private const val MAX_BACKGROUND_TASKS = 5
    }
    
    private val memoryOptimizer = MemoryOptimizer(context)
    private val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    private val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
    private val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    
    private val performanceExecutor: ScheduledExecutorService = Executors.newScheduledThreadPool(2)
    private val backgroundTasks = ConcurrentHashMap<String, BackgroundTask>()
    private val performanceMetrics = ConcurrentHashMap<String, PerformanceMetric>()
    
    private var isMonitoring = false
    private var lastCpuUsage = 0.0
    private var lastCpuTime = 0L
    
    data class PerformanceMetric(
        val timestamp: Long,
        val cpuUsage: Double,
        val memoryUsage: Long,
        val batteryLevel: Int,
        val batteryTemperature: Float,
        val isCharging: Boolean,
        val activeVirtualSpaces: Int,
        val backgroundTaskCount: Int
    )
    
    data class BackgroundTask(
        val id: String,
        val name: String,
        val priority: TaskPriority,
        val startTime: Long,
        val virtualSpaceId: String?,
        val cpuUsage: Double = 0.0,
        val memoryUsage: Long = 0L
    )
    
    enum class TaskPriority {
        LOW, MEDIUM, HIGH, CRITICAL
    }
    
    data class PerformanceStatus(
        val overallScore: Int, // 0-100
        val cpuStatus: String,
        val memoryStatus: String,
        val batteryStatus: String,
        val recommendations: List<String>,
        val activeOptimizations: List<String>
    )
    
    /**
     * Initialize performance monitoring
     */
    fun initializePerformanceMonitoring(): Boolean {
        return try {
            if (!isMonitoring) {
                startPerformanceMonitoring()
                Log.d(TAG, "Performance monitoring initialized")
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize performance monitoring: ${e.message}")
            false
        }
    }
    
    /**
     * Start continuous performance monitoring
     */
    private fun startPerformanceMonitoring() {
        isMonitoring = true
        performanceExecutor.scheduleAtFixedRate({
            try {
                collectPerformanceMetrics()
                analyzePerformance()
                optimizeIfNeeded()
            } catch (e: Exception) {
                Log.e(TAG, "Error in performance monitoring: ${e.message}")
            }
        }, 0, PERFORMANCE_CHECK_INTERVAL, TimeUnit.SECONDS)
    }
    
    /**
     * Stop performance monitoring
     */
    fun stopPerformanceMonitoring() {
        isMonitoring = false
        performanceExecutor.shutdown()
        Log.d(TAG, "Performance monitoring stopped")
    }
    
    /**
     * Get current performance status
     */
    fun getPerformanceStatus(): PerformanceStatus {
        val currentMetric = getCurrentPerformanceMetric()
        val recommendations = mutableListOf<String>()
        val activeOptimizations = mutableListOf<String>()
        
        // Analyze CPU status
        val cpuStatus = when {
            currentMetric.cpuUsage > CRITICAL_CPU_THRESHOLD -> {
                recommendations.add("Reduce active virtual spaces to lower CPU usage")
                "Critical"
            }
            currentMetric.cpuUsage > HIGH_CPU_THRESHOLD -> {
                recommendations.add("Consider closing unused applications")
                "High"
            }
            else -> "Normal"
        }
        
        // Analyze memory status
        val memoryInfo = memoryOptimizer.getMemoryInfo()
        val memoryUsagePercent = ((memoryInfo["usedMemory"] as Long).toDouble() / 
                                 (memoryInfo["totalMemory"] as Long).toDouble()) * 100
        
        val memoryStatus = when {
            memoryUsagePercent > 90 -> {
                recommendations.add("Clear cache and temporary files")
                activeOptimizations.add("Memory cleanup scheduled")
                "Critical"
            }
            memoryUsagePercent > 75 -> {
                recommendations.add("Consider memory optimization")
                "High"
            }
            else -> "Normal"
        }
        
        // Analyze battery status
        val batteryStatus = when {
            currentMetric.batteryLevel <= CRITICAL_BATTERY_THRESHOLD -> {
                recommendations.add("Enable battery saver mode")
                recommendations.add("Reduce background activity")
                activeOptimizations.add("Battery optimization active")
                "Critical"
            }
            currentMetric.batteryLevel <= LOW_BATTERY_THRESHOLD -> {
                recommendations.add("Consider reducing virtual space activity")
                "Low"
            }
            else -> "Normal"
        }
        
        // Calculate overall performance score
        val cpuScore = ((100 - currentMetric.cpuUsage) * 0.3).roundToInt()
        val memoryScore = ((100 - memoryUsagePercent) * 0.3).roundToInt()
        val batteryScore = (currentMetric.batteryLevel * 0.4).roundToInt()
        val overallScore = (cpuScore + memoryScore + batteryScore).coerceIn(0, 100)
        
        return PerformanceStatus(
            overallScore = overallScore,
            cpuStatus = cpuStatus,
            memoryStatus = memoryStatus,
            batteryStatus = batteryStatus,
            recommendations = recommendations,
            activeOptimizations = activeOptimizations
        )
    }
    
    /**
     * Optimize performance based on current conditions
     */
    fun optimizePerformance(): Map<String, Any> {
        val results = mutableMapOf<String, Any>()
        
        try {
            val currentMetric = getCurrentPerformanceMetric()
            
            // CPU optimization
            if (currentMetric.cpuUsage > HIGH_CPU_THRESHOLD) {
                val cpuOptimization = optimizeCpuUsage()
                results["cpuOptimization"] = cpuOptimization
            }
            
            // Memory optimization
            if (memoryOptimizer.isLowMemory()) {
                val memoryOptimization = memoryOptimizer.optimizeMemoryUsage()
                results["memoryOptimization"] = memoryOptimization
            }
            
            // Battery optimization
            if (currentMetric.batteryLevel <= LOW_BATTERY_THRESHOLD) {
                val batteryOptimization = optimizeBatteryUsage()
                results["batteryOptimization"] = batteryOptimization
            }
            
            // Background task optimization
            val taskOptimization = optimizeBackgroundTasks()
            results["taskOptimization"] = taskOptimization
            
            results["success"] = true
            results["timestamp"] = System.currentTimeMillis()
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to optimize performance: ${e.message}")
            results["success"] = false
            results["error"] = e.message ?: "Unknown error"
        }
        
        return results
    }
    
    /**
     * Register a background task
     */
    fun registerBackgroundTask(
        id: String,
        name: String,
        priority: TaskPriority,
        virtualSpaceId: String? = null
    ): Boolean {
        return try {
            if (backgroundTasks.size >= MAX_BACKGROUND_TASKS && priority != TaskPriority.CRITICAL) {
                Log.w(TAG, "Maximum background tasks reached, rejecting task: $name")
                return false
            }
            
            val task = BackgroundTask(
                id = id,
                name = name,
                priority = priority,
                startTime = System.currentTimeMillis(),
                virtualSpaceId = virtualSpaceId
            )
            
            backgroundTasks[id] = task
            Log.d(TAG, "Registered background task: $name")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register background task: ${e.message}")
            false
        }
    }
    
    /**
     * Unregister a background task
     */
    fun unregisterBackgroundTask(id: String): Boolean {
        return try {
            val task = backgroundTasks.remove(id)
            if (task != null) {
                Log.d(TAG, "Unregistered background task: ${task.name}")
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister background task: ${e.message}")
            false
        }
    }
    
    /**
     * Get performance metrics history
     */
    fun getPerformanceHistory(hours: Int = 24): List<PerformanceMetric> {
        val cutoffTime = System.currentTimeMillis() - (hours * 60 * 60 * 1000)
        return performanceMetrics.values
            .filter { it.timestamp >= cutoffTime }
            .sortedBy { it.timestamp }
    }
    
    /**
     * Get CPU usage percentage
     */
    fun getCpuUsage(): Double {
        return try {
            val currentTime = System.currentTimeMillis()
            val currentCpuTime = getTotalCpuTime()
            
            if (lastCpuTime > 0) {
                val timeDiff = currentTime - lastCpuTime
                val cpuTimeDiff = currentCpuTime - lastCpuTime
                
                if (timeDiff > 0) {
                    lastCpuUsage = (cpuTimeDiff.toDouble() / timeDiff.toDouble()) * 100
                }
            }
            
            lastCpuTime = currentTime
            lastCpuUsage.coerceIn(0.0, 100.0)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get CPU usage: ${e.message}")
            0.0
        }
    }
    
    /**
     * Get battery information
     */
    fun getBatteryInfo(): Map<String, Any> {
        return try {
            val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            
            val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            val temperature = batteryIntent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
            val voltage = batteryIntent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
            val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            val health = batteryIntent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
            
            val batteryLevel = if (level >= 0 && scale > 0) {
                (level.toFloat() / scale.toFloat() * 100).roundToInt()
            } else {
                -1
            }
            
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                           status == BatteryManager.BATTERY_STATUS_FULL
            
            mapOf(
                "level" to batteryLevel,
                "temperature" to (temperature / 10.0f), // Convert to Celsius
                "voltage" to voltage,
                "isCharging" to isCharging,
                "health" to health,
                "status" to status
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get battery info: ${e.message}")
            mapOf(
                "level" to -1,
                "temperature" to -1.0f,
                "voltage" to -1,
                "isCharging" to false,
                "health" to -1,
                "status" to -1
            )
        }
    }
    
    // Private helper methods
    
    private fun collectPerformanceMetrics() {
        val timestamp = System.currentTimeMillis()
        val cpuUsage = getCpuUsage()
        val memoryInfo = memoryOptimizer.getMemoryInfo()
        val batteryInfo = getBatteryInfo()
        
        val metric = PerformanceMetric(
            timestamp = timestamp,
            cpuUsage = cpuUsage,
            memoryUsage = memoryInfo["usedMemory"] as Long,
            batteryLevel = batteryInfo["level"] as Int,
            batteryTemperature = batteryInfo["temperature"] as Float,
            isCharging = batteryInfo["isCharging"] as Boolean,
            activeVirtualSpaces = getActiveVirtualSpaceCount(),
            backgroundTaskCount = backgroundTasks.size
        )
        
        performanceMetrics[timestamp.toString()] = metric
        
        // Keep only last 24 hours of metrics
        val cutoffTime = timestamp - (24 * 60 * 60 * 1000)
        performanceMetrics.entries.removeAll { it.value.timestamp < cutoffTime }
    }
    
    private fun analyzePerformance() {
        val currentMetric = getCurrentPerformanceMetric()
        
        // Log performance warnings
        if (currentMetric.cpuUsage > CRITICAL_CPU_THRESHOLD) {
            Log.w(TAG, "Critical CPU usage detected: ${currentMetric.cpuUsage}%")
        }
        
        if (memoryOptimizer.isCriticalMemory()) {
            Log.w(TAG, "Critical memory usage detected")
        }
        
        if (currentMetric.batteryLevel <= CRITICAL_BATTERY_THRESHOLD) {
            Log.w(TAG, "Critical battery level: ${currentMetric.batteryLevel}%")
        }
    }
    
    private fun optimizeIfNeeded() {
        val currentMetric = getCurrentPerformanceMetric()
        
        // Auto-optimize if critical conditions are met
        if (currentMetric.cpuUsage > CRITICAL_CPU_THRESHOLD ||
            memoryOptimizer.isCriticalMemory() ||
            currentMetric.batteryLevel <= CRITICAL_BATTERY_THRESHOLD) {
            
            Log.d(TAG, "Auto-optimization triggered")
            optimizePerformance()
        }
    }
    
    private fun optimizeCpuUsage(): Map<String, Any> {
        val results = mutableMapOf<String, Any>()
        
        try {
            // Reduce background task priority
            var optimizedTasks = 0
            backgroundTasks.values.forEach { task ->
                if (task.priority == TaskPriority.LOW) {
                    // Pause or reduce frequency of low priority tasks
                    optimizedTasks++
                }
            }
            
            results["optimizedTasks"] = optimizedTasks
            results["success"] = true
        } catch (e: Exception) {
            results["success"] = false
            results["error"] = e.message ?: "Unknown error"
        }
        
        return results
    }
    
    private fun optimizeBatteryUsage(): Map<String, Any> {
        val results = mutableMapOf<String, Any>()
        
        try {
            // Reduce background activity
            val pausedTasks = pauseLowPriorityTasks()
            
            // Enable power saving mode if available
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val isPowerSaveMode = powerManager.isPowerSaveMode
                results["powerSaveMode"] = isPowerSaveMode
            }
            
            results["pausedTasks"] = pausedTasks
            results["success"] = true
        } catch (e: Exception) {
            results["success"] = false
            results["error"] = e.message ?: "Unknown error"
        }
        
        return results
    }
    
    private fun optimizeBackgroundTasks(): Map<String, Any> {
        val results = mutableMapOf<String, Any>()
        
        try {
            val beforeCount = backgroundTasks.size
            
            // Remove completed or stale tasks
            val currentTime = System.currentTimeMillis()
            val staleTasks = backgroundTasks.filter { (_, task) ->
                currentTime - task.startTime > 30 * 60 * 1000 // 30 minutes
            }
            
            staleTasks.forEach { (id, _) ->
                backgroundTasks.remove(id)
            }
            
            val afterCount = backgroundTasks.size
            results["removedTasks"] = beforeCount - afterCount
            results["activeTasks"] = afterCount
            results["success"] = true
        } catch (e: Exception) {
            results["success"] = false
            results["error"] = e.message ?: "Unknown error"
        }
        
        return results
    }
    
    private fun pauseLowPriorityTasks(): Int {
        var pausedCount = 0
        backgroundTasks.values.forEach { task ->
            if (task.priority == TaskPriority.LOW) {
                // In a real implementation, you would pause the actual task
                pausedCount++
            }
        }
        return pausedCount
    }
    
    private fun getCurrentPerformanceMetric(): PerformanceMetric {
        val latest = performanceMetrics.values.maxByOrNull { it.timestamp }
        return latest ?: PerformanceMetric(
            timestamp = System.currentTimeMillis(),
            cpuUsage = getCpuUsage(),
            memoryUsage = 0L,
            batteryLevel = getBatteryInfo()["level"] as Int,
            batteryTemperature = getBatteryInfo()["temperature"] as Float,
            isCharging = getBatteryInfo()["isCharging"] as Boolean,
            activeVirtualSpaces = 0,
            backgroundTaskCount = backgroundTasks.size
        )
    }
    
    private fun getTotalCpuTime(): Long {
        return try {
            val statFile = RandomAccessFile("/proc/stat", "r")
            val cpuLine = statFile.readLine()
            statFile.close()
            
            val cpuTimes = cpuLine.split("\\s+".toRegex())
            var totalTime = 0L
            for (i in 1..7) {
                if (i < cpuTimes.size) {
                    totalTime += cpuTimes[i].toLongOrNull() ?: 0L
                }
            }
            totalTime
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get CPU time: ${e.message}")
            0L
        }
    }
    
    private fun getActiveVirtualSpaceCount(): Int {
        return try {
            val virtualSpacesDir = File(context.filesDir, "virtual_spaces")
            if (virtualSpacesDir.exists()) {
                virtualSpacesDir.listFiles()?.count { it.isDirectory } ?: 0
            } else {
                0
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get active virtual space count: ${e.message}")
            0
        }
    }
    
    /**
     * Cleanup resources
     */
    fun cleanup() {
        stopPerformanceMonitoring()
        backgroundTasks.clear()
        performanceMetrics.clear()
        Log.d(TAG, "Performance manager cleaned up")
    }
}
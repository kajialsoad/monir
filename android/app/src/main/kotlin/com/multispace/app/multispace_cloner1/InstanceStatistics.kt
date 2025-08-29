package com.multispace.app.multispace_cloner

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ConcurrentHashMap

/**
 * Instance statistics manager for tracking cloned app usage
 * Provides detailed analytics and usage patterns
 */
class InstanceStatistics(private val context: Context) {
    
    companion object {
        private const val TAG = "InstanceStatistics"
        private const val PREFS_NAME = "instance_statistics"
        private const val STATS_FILE = "statistics.json"
    }
    
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val activeInstances = ConcurrentHashMap<String, InstanceInfo>()
    
    data class InstanceInfo(
        val virtualSpaceId: String,
        val packageName: String,
        val startTime: Long,
        var lastActivityTime: Long,
        var totalRuntime: Long = 0L,
        var launchCount: Int = 0,
        var memoryUsage: Long = 0L,
        var storageUsage: Long = 0L
    )
    
    data class UsagePattern(
        val hourlyUsage: Map<Int, Long>, // Hour -> Total runtime
        val dailyUsage: Map<String, Long>, // Date -> Total runtime
        val weeklyUsage: Map<Int, Long>, // Day of week -> Total runtime
        val monthlyUsage: Map<String, Long> // Month -> Total runtime
    )
    
    /**
     * Records app launch event
     */
    fun recordAppLaunch(virtualSpaceId: String, packageName: String): Boolean {
        return try {
            val instanceKey = "${virtualSpaceId}_${packageName}"
            val currentTime = System.currentTimeMillis()
            
            // Update launch count
            val launchCount = prefs.getInt("${instanceKey}_launch_count", 0) + 1
            prefs.edit().putInt("${instanceKey}_launch_count", launchCount).apply()
            
            // Record launch time
            prefs.edit().putLong("${instanceKey}_last_launch", currentTime).apply()
            
            // Add to active instances
            activeInstances[instanceKey] = InstanceInfo(
                virtualSpaceId = virtualSpaceId,
                packageName = packageName,
                startTime = currentTime,
                lastActivityTime = currentTime,
                launchCount = launchCount
            )
            
            // Record daily launch
            recordDailyLaunch(packageName, currentTime)
            
            Log.d(TAG, "Recorded app launch: $packageName in virtual space: $virtualSpaceId")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record app launch: ${e.message}")
            false
        }
    }
    
    /**
     * Records app close event
     */
    fun recordAppClose(virtualSpaceId: String, packageName: String): Boolean {
        return try {
            val instanceKey = "${virtualSpaceId}_${packageName}"
            val currentTime = System.currentTimeMillis()
            
            val activeInstance = activeInstances[instanceKey]
            if (activeInstance != null) {
                val sessionRuntime = currentTime - activeInstance.startTime
                val totalRuntime = prefs.getLong("${instanceKey}_total_runtime", 0L) + sessionRuntime
                
                // Update total runtime
                prefs.edit().putLong("${instanceKey}_total_runtime", totalRuntime).apply()
                
                // Record session data
                recordSessionData(packageName, sessionRuntime, currentTime)
                
                // Remove from active instances
                activeInstances.remove(instanceKey)
                
                Log.d(TAG, "Recorded app close: $packageName, session runtime: ${sessionRuntime}ms")
            }
            
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record app close: ${e.message}")
            false
        }
    }
    
    /**
     * Updates memory usage for an instance
     */
    fun updateMemoryUsage(virtualSpaceId: String, packageName: String, memoryUsage: Long) {
        try {
            val instanceKey = "${virtualSpaceId}_${packageName}"
            prefs.edit().putLong("${instanceKey}_memory_usage", memoryUsage).apply()
            
            activeInstances[instanceKey]?.memoryUsage = memoryUsage
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update memory usage: ${e.message}")
        }
    }
    
    /**
     * Updates storage usage for an instance
     */
    fun updateStorageUsage(virtualSpaceId: String, packageName: String, storageUsage: Long) {
        try {
            val instanceKey = "${virtualSpaceId}_${packageName}"
            prefs.edit().putLong("${instanceKey}_storage_usage", storageUsage).apply()
            
            activeInstances[instanceKey]?.storageUsage = storageUsage
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update storage usage: ${e.message}")
        }
    }
    
    /**
     * Gets statistics for a specific app
     */
    fun getAppStatistics(virtualSpaceId: String, packageName: String): Map<String, Any> {
        val instanceKey = "${virtualSpaceId}_${packageName}"
        val stats = mutableMapOf<String, Any>()
        
        try {
            stats["packageName"] = packageName
            stats["virtualSpaceId"] = virtualSpaceId
            stats["launchCount"] = prefs.getInt("${instanceKey}_launch_count", 0)
            stats["totalRuntime"] = prefs.getLong("${instanceKey}_total_runtime", 0L)
            stats["lastLaunch"] = prefs.getLong("${instanceKey}_last_launch", 0L)
            stats["memoryUsage"] = prefs.getLong("${instanceKey}_memory_usage", 0L)
            stats["storageUsage"] = prefs.getLong("${instanceKey}_storage_usage", 0L)
            stats["isActive"] = activeInstances.containsKey(instanceKey)
            
            // Calculate average session time
            val launchCount = stats["launchCount"] as Int
            val totalRuntime = stats["totalRuntime"] as Long
            stats["averageSessionTime"] = if (launchCount > 0) totalRuntime / launchCount else 0L
            
            // Get usage patterns
            stats["usagePatterns"] = getUsagePatterns(packageName)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get app statistics: ${e.message}")
        }
        
        return stats
    }
    
    /**
     * Gets global statistics for all cloned apps
     */
    fun getGlobalStatistics(): Map<String, Any> {
        val stats = mutableMapOf<String, Any>()
        
        try {
            val allKeys = prefs.all.keys
            val packageNames = mutableSetOf<String>()
            var totalLaunches = 0
            var totalRuntime = 0L
            var totalMemoryUsage = 0L
            var totalStorageUsage = 0L
            
            allKeys.forEach { key ->
                when {
                    key.endsWith("_launch_count") -> {
                        totalLaunches += prefs.getInt(key, 0)
                        val packageName = extractPackageName(key)
                        if (packageName.isNotEmpty()) {
                            packageNames.add(packageName)
                        }
                    }
                    key.endsWith("_total_runtime") -> {
                        totalRuntime += prefs.getLong(key, 0L)
                    }
                    key.endsWith("_memory_usage") -> {
                        totalMemoryUsage += prefs.getLong(key, 0L)
                    }
                    key.endsWith("_storage_usage") -> {
                        totalStorageUsage += prefs.getLong(key, 0L)
                    }
                }
            }
            
            stats["totalClonedApps"] = packageNames.size
            stats["totalLaunches"] = totalLaunches
            stats["totalRuntime"] = totalRuntime
            stats["totalMemoryUsage"] = totalMemoryUsage
            stats["totalStorageUsage"] = totalStorageUsage
            stats["activeInstances"] = activeInstances.size
            stats["averageSessionTime"] = if (totalLaunches > 0) totalRuntime / totalLaunches else 0L
            
            // Get most used apps
            stats["mostUsedApps"] = getMostUsedApps(5)
            
            // Get usage trends
            stats["usageTrends"] = getUsageTrends()
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get global statistics: ${e.message}")
        }
        
        return stats
    }
    
    /**
     * Gets usage patterns for a specific app
     */
    fun getUsagePatterns(packageName: String): UsagePattern {
        val hourlyUsage = mutableMapOf<Int, Long>()
        val dailyUsage = mutableMapOf<String, Long>()
        val weeklyUsage = mutableMapOf<Int, Long>()
        val monthlyUsage = mutableMapOf<String, Long>()
        
        try {
            val statsFile = File(context.filesDir, "statistics/${packageName}_sessions.json")
            if (statsFile.exists()) {
                val jsonContent = statsFile.readText()
                val sessionsArray = JSONArray(jsonContent)
                
                for (i in 0 until sessionsArray.length()) {
                    val session = sessionsArray.getJSONObject(i)
                    val startTime = session.getLong("startTime")
                    val runtime = session.getLong("runtime")
                    
                    val calendar = Calendar.getInstance()
                    calendar.timeInMillis = startTime
                    
                    // Hourly usage
                    val hour = calendar.get(Calendar.HOUR_OF_DAY)
                    hourlyUsage[hour] = hourlyUsage.getOrDefault(hour, 0L) + runtime
                    
                    // Daily usage
                    val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                    val date = dateFormat.format(Date(startTime))
                    dailyUsage[date] = dailyUsage.getOrDefault(date, 0L) + runtime
                    
                    // Weekly usage
                    val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
                    weeklyUsage[dayOfWeek] = weeklyUsage.getOrDefault(dayOfWeek, 0L) + runtime
                    
                    // Monthly usage
                    val monthFormat = SimpleDateFormat("yyyy-MM", Locale.getDefault())
                    val month = monthFormat.format(Date(startTime))
                    monthlyUsage[month] = monthlyUsage.getOrDefault(month, 0L) + runtime
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get usage patterns: ${e.message}")
        }
        
        return UsagePattern(hourlyUsage, dailyUsage, weeklyUsage, monthlyUsage)
    }
    
    /**
     * Exports statistics to JSON file
     */
    fun exportStatistics(): File? {
        return try {
            val exportDir = File(context.getExternalFilesDir(null), "exports")
            if (!exportDir.exists()) {
                exportDir.mkdirs()
            }
            
            val exportFile = File(exportDir, "statistics_${System.currentTimeMillis()}.json")
            val globalStats = getGlobalStatistics()
            
            val jsonObject = JSONObject()
            jsonObject.put("exportTime", System.currentTimeMillis())
            jsonObject.put("globalStatistics", JSONObject(globalStats))
            
            // Add individual app statistics
            val appsArray = JSONArray()
            val allKeys = prefs.all.keys
            val packageNames = mutableSetOf<String>()
            
            allKeys.forEach { key ->
                if (key.endsWith("_launch_count")) {
                    val packageName = extractPackageName(key)
                    if (packageName.isNotEmpty()) {
                        packageNames.add(packageName)
                    }
                }
            }
            
            packageNames.forEach { packageName ->
                // Find all virtual spaces for this package
                val virtualSpaces = findVirtualSpacesForPackage(packageName)
                virtualSpaces.forEach { virtualSpaceId ->
                    val appStats = getAppStatistics(virtualSpaceId, packageName)
                    appsArray.put(JSONObject(appStats))
                }
            }
            
            jsonObject.put("appStatistics", appsArray)
            
            exportFile.writeText(jsonObject.toString(2))
            exportFile
        } catch (e: Exception) {
            Log.e(TAG, "Failed to export statistics: ${e.message}")
            null
        }
    }
    
    /**
     * Clears all statistics data
     */
    fun clearAllStatistics(): Boolean {
        return try {
            prefs.edit().clear().apply()
            activeInstances.clear()
            
            // Clear statistics files
            val statsDir = File(context.filesDir, "statistics")
            if (statsDir.exists()) {
                statsDir.deleteRecursively()
            }
            
            Log.d(TAG, "All statistics cleared")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear statistics: ${e.message}")
            false
        }
    }
    
    // Private helper methods
    
    private fun recordDailyLaunch(packageName: String, timestamp: Long) {
        try {
            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val date = dateFormat.format(Date(timestamp))
            val key = "daily_launches_${date}_${packageName}"
            val count = prefs.getInt(key, 0) + 1
            prefs.edit().putInt(key, count).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record daily launch: ${e.message}")
        }
    }
    
    private fun recordSessionData(packageName: String, runtime: Long, endTime: Long) {
        try {
            val statsDir = File(context.filesDir, "statistics")
            if (!statsDir.exists()) {
                statsDir.mkdirs()
            }
            
            val sessionFile = File(statsDir, "${packageName}_sessions.json")
            val sessionsArray = if (sessionFile.exists()) {
                JSONArray(sessionFile.readText())
            } else {
                JSONArray()
            }
            
            val sessionObject = JSONObject()
            sessionObject.put("startTime", endTime - runtime)
            sessionObject.put("endTime", endTime)
            sessionObject.put("runtime", runtime)
            
            sessionsArray.put(sessionObject)
            sessionFile.writeText(sessionsArray.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record session data: ${e.message}")
        }
    }
    
    private fun extractPackageName(key: String): String {
        return try {
            val parts = key.split("_")
            if (parts.size >= 3) {
                parts.dropLast(2).joinToString("_").substringAfter("_")
            } else {
                ""
            }
        } catch (e: Exception) {
            ""
        }
    }
    
    private fun findVirtualSpacesForPackage(packageName: String): List<String> {
        val virtualSpaces = mutableListOf<String>()
        try {
            prefs.all.keys.forEach { key ->
                if (key.contains(packageName) && key.endsWith("_launch_count")) {
                    val virtualSpaceId = key.substringBefore("_${packageName}")
                    if (virtualSpaceId.isNotEmpty()) {
                        virtualSpaces.add(virtualSpaceId)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to find virtual spaces: ${e.message}")
        }
        return virtualSpaces
    }
    
    private fun getMostUsedApps(limit: Int): List<Map<String, Any>> {
        val appUsage = mutableMapOf<String, Long>()
        
        try {
            prefs.all.keys.forEach { key ->
                if (key.endsWith("_total_runtime")) {
                    val packageName = extractPackageName(key)
                    if (packageName.isNotEmpty()) {
                        val runtime = prefs.getLong(key, 0L)
                        appUsage[packageName] = appUsage.getOrDefault(packageName, 0L) + runtime
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get most used apps: ${e.message}")
        }
        
        return appUsage.toList()
            .sortedByDescending { it.second }
            .take(limit)
            .map { (packageName, runtime) ->
                mapOf(
                    "packageName" to packageName,
                    "totalRuntime" to runtime
                )
            }
    }
    
    private fun getUsageTrends(): Map<String, Any> {
        val trends = mutableMapOf<String, Any>()
        
        try {
            val calendar = Calendar.getInstance()
            val currentTime = calendar.timeInMillis
            
            // Last 7 days usage
            val last7Days = mutableMapOf<String, Long>()
            for (i in 0..6) {
                calendar.timeInMillis = currentTime - (i * 24 * 60 * 60 * 1000)
                val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                val date = dateFormat.format(calendar.time)
                
                var dayUsage = 0L
                prefs.all.keys.forEach { key ->
                    if (key.startsWith("daily_launches_${date}_")) {
                        dayUsage += prefs.getInt(key, 0)
                    }
                }
                last7Days[date] = dayUsage
            }
            
            trends["last7Days"] = last7Days
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get usage trends: ${e.message}")
        }
        
        return trends
    }
}
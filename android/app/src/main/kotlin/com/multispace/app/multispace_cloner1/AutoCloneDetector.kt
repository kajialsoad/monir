package com.multispace.app.multispace_cloner

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.*

/**
 * Auto clone detector for identifying apps suitable for cloning
 * Analyzes app characteristics and suggests cloning opportunities
 */
class AutoCloneDetector(private val context: Context) {
    
    companion object {
        private const val TAG = "AutoCloneDetector"
        private const val CLONE_SUGGESTIONS_FILE = "clone_suggestions.json"
        
        // Categories of apps that are commonly cloned
        private val SOCIAL_MEDIA_PACKAGES = setOf(
            "com.whatsapp", "com.facebook.katana", "com.instagram.android",
            "com.twitter.android", "com.snapchat.android", "com.tencent.mm",
            "com.viber.voip", "com.skype.raider", "com.telegram.messenger",
            "com.discord", "com.zhiliaoapp.musically", "com.ss.android.ugc.trill"
        )
        
        private val MESSAGING_PACKAGES = setOf(
            "com.whatsapp", "com.viber.voip", "com.telegram.messenger",
            "com.tencent.mm", "com.facebook.orca", "com.google.android.apps.messaging",
            "com.samsung.android.messaging", "com.android.mms"
        )
        
        private val GAMING_PACKAGES = setOf(
            "com.supercell.clashofclans", "com.king.candycrushsaga",
            "com.mojang.minecraftpe", "com.roblox.client", "com.ea.game.pvz2_row",
            "com.outfit7.mytalkingtomfriends", "com.supercell.clashroyale"
        )
        
        private val PRODUCTIVITY_PACKAGES = setOf(
            "com.google.android.gm", "com.microsoft.office.outlook",
            "com.slack", "com.microsoft.teams", "com.zoom.us",
            "us.zoom.videomeetings", "com.dropbox.android", "com.google.android.apps.docs"
        )
    }
    
    data class CloneSuggestion(
        val packageName: String,
        val appName: String,
        val category: String,
        val priority: Int, // 1-5, 5 being highest
        val reason: String,
        val confidence: Float, // 0.0-1.0
        val estimatedBenefit: String
    )
    
    data class CloneAnalysis(
        val isCloneable: Boolean,
        val difficulty: String, // "Easy", "Medium", "Hard", "Very Hard"
        val risks: List<String>,
        val benefits: List<String>,
        val requirements: List<String>
    )
    
    /**
     * Analyzes all installed apps and suggests cloning candidates
     */
    fun analyzeInstalledApps(): List<CloneSuggestion> {
        val suggestions = mutableListOf<CloneSuggestion>()
        
        try {
            val packageManager = context.packageManager
            val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
            
            installedApps.forEach { appInfo ->
                if (shouldAnalyzeApp(appInfo)) {
                    val suggestion = analyzeAppForCloning(appInfo, packageManager)
                    if (suggestion != null) {
                        suggestions.add(suggestion)
                    }
                }
            }
            
            // Sort by priority and confidence
            suggestions.sortWith(compareByDescending<CloneSuggestion> { it.priority }
                .thenByDescending { it.confidence })
            
            // Save suggestions
            saveSuggestions(suggestions)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to analyze installed apps: ${e.message}")
        }
        
        return suggestions
    }
    
    /**
     * Analyzes a specific app for cloning suitability
     */
    fun analyzeSpecificApp(packageName: String): CloneAnalysis? {
        return try {
            val packageManager = context.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            
            val isCloneable = isAppCloneable(appInfo)
            val difficulty = assessCloningDifficulty(appInfo)
            val risks = identifyRisks(appInfo)
            val benefits = identifyBenefits(appInfo)
            val requirements = identifyRequirements(appInfo)
            
            CloneAnalysis(isCloneable, difficulty, risks, benefits, requirements)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to analyze app: ${e.message}")
            null
        }
    }
    
    /**
     * Gets saved clone suggestions
     */
    fun getSavedSuggestions(): List<CloneSuggestion> {
        val suggestions = mutableListOf<CloneSuggestion>()
        
        try {
            val suggestionsFile = File(context.filesDir, CLONE_SUGGESTIONS_FILE)
            if (suggestionsFile.exists()) {
                val jsonContent = suggestionsFile.readText()
                val jsonArray = JSONArray(jsonContent)
                
                for (i in 0 until jsonArray.length()) {
                    val jsonObject = jsonArray.getJSONObject(i)
                    val suggestion = CloneSuggestion(
                        packageName = jsonObject.getString("packageName"),
                        appName = jsonObject.getString("appName"),
                        category = jsonObject.getString("category"),
                        priority = jsonObject.getInt("priority"),
                        reason = jsonObject.getString("reason"),
                        confidence = jsonObject.getDouble("confidence").toFloat(),
                        estimatedBenefit = jsonObject.getString("estimatedBenefit")
                    )
                    suggestions.add(suggestion)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get saved suggestions: ${e.message}")
        }
        
        return suggestions
    }
    
    /**
     * Updates suggestion priority based on user feedback
     */
    fun updateSuggestionPriority(packageName: String, newPriority: Int): Boolean {
        return try {
            val suggestions = getSavedSuggestions().toMutableList()
            val index = suggestions.indexOfFirst { it.packageName == packageName }
            
            if (index != -1) {
                suggestions[index] = suggestions[index].copy(priority = newPriority)
                saveSuggestions(suggestions)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update suggestion priority: ${e.message}")
            false
        }
    }
    
    /**
     * Marks a suggestion as dismissed
     */
    fun dismissSuggestion(packageName: String): Boolean {
        return try {
            val suggestions = getSavedSuggestions().toMutableList()
            suggestions.removeAll { it.packageName == packageName }
            saveSuggestions(suggestions)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to dismiss suggestion: ${e.message}")
            false
        }
    }
    
    /**
     * Gets apps that are frequently used together (for batch cloning)
     */
    fun getRelatedApps(packageName: String): List<String> {
        val relatedApps = mutableListOf<String>()
        
        try {
            // Define app relationships
            val appRelationships = mapOf(
                "com.whatsapp" to listOf("com.whatsapp.w4b", "com.telegram.messenger", "com.viber.voip"),
                "com.facebook.katana" to listOf("com.instagram.android", "com.facebook.orca", "com.twitter.android"),
                "com.instagram.android" to listOf("com.facebook.katana", "com.snapchat.android", "com.twitter.android"),
                "com.google.android.gm" to listOf("com.microsoft.office.outlook", "com.google.android.apps.docs"),
                "com.supercell.clashofclans" to listOf("com.supercell.clashroyale", "com.supercell.boombeach")
            )
            
            appRelationships[packageName]?.let { related ->
                val packageManager = context.packageManager
                related.forEach { relatedPackage ->
                    try {
                        packageManager.getApplicationInfo(relatedPackage, 0)
                        relatedApps.add(relatedPackage)
                    } catch (e: PackageManager.NameNotFoundException) {
                        // App not installed
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get related apps: ${e.message}")
        }
        
        return relatedApps
    }
    
    /**
     * Detects apps that might benefit from multiple accounts
     */
    fun detectMultiAccountApps(): List<CloneSuggestion> {
        val multiAccountApps = mutableListOf<CloneSuggestion>()
        
        try {
            val packageManager = context.packageManager
            val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
            
            installedApps.forEach { appInfo ->
                if (isMultiAccountCandidate(appInfo)) {
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val suggestion = CloneSuggestion(
                        packageName = appInfo.packageName,
                        appName = appName,
                        category = "Multi-Account",
                        priority = 4,
                        reason = "This app commonly benefits from multiple accounts",
                        confidence = 0.8f,
                        estimatedBenefit = "Separate personal and work accounts"
                    )
                    multiAccountApps.add(suggestion)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to detect multi-account apps: ${e.message}")
        }
        
        return multiAccountApps
    }
    
    // Private helper methods
    
    private fun shouldAnalyzeApp(appInfo: ApplicationInfo): Boolean {
        // Skip system apps and our own app
        return !isSystemApp(appInfo) && 
               appInfo.packageName != context.packageName &&
               appInfo.enabled
    }
    
    private fun analyzeAppForCloning(appInfo: ApplicationInfo, packageManager: PackageManager): CloneSuggestion? {
        return try {
            val packageName = appInfo.packageName
            val appName = packageManager.getApplicationLabel(appInfo).toString()
            
            val category = categorizeApp(packageName)
            val priority = calculatePriority(packageName, category)
            val confidence = calculateConfidence(appInfo)
            
            if (priority > 0 && confidence > 0.3f) {
                CloneSuggestion(
                    packageName = packageName,
                    appName = appName,
                    category = category,
                    priority = priority,
                    reason = generateReason(packageName, category),
                    confidence = confidence,
                    estimatedBenefit = generateBenefit(category)
                )
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to analyze app for cloning: ${e.message}")
            null
        }
    }
    
    private fun isAppCloneable(appInfo: ApplicationInfo): Boolean {
        // Check various factors that affect cloneability
        return !isSystemApp(appInfo) &&
               !hasAntiCloneProtection(appInfo) &&
               !requiresSpecialPermissions(appInfo)
    }
    
    private fun assessCloningDifficulty(appInfo: ApplicationInfo): String {
        var difficultyScore = 0
        
        // Check for various complexity factors
        if (hasNativeLibraries(appInfo)) difficultyScore += 1
        if (hasComplexPermissions(appInfo)) difficultyScore += 1
        if (hasAntiCloneProtection(appInfo)) difficultyScore += 2
        if (isSystemApp(appInfo)) difficultyScore += 2
        
        return when (difficultyScore) {
            0, 1 -> "Easy"
            2 -> "Medium"
            3 -> "Hard"
            else -> "Very Hard"
        }
    }
    
    private fun identifyRisks(appInfo: ApplicationInfo): List<String> {
        val risks = mutableListOf<String>()
        
        if (hasAntiCloneProtection(appInfo)) {
            risks.add("App may have anti-clone protection")
        }
        
        if (hasComplexPermissions(appInfo)) {
            risks.add("App requires sensitive permissions")
        }
        
        if (hasNativeLibraries(appInfo)) {
            risks.add("App uses native libraries that may not work in virtual environment")
        }
        
        return risks
    }
    
    private fun identifyBenefits(appInfo: ApplicationInfo): List<String> {
        val benefits = mutableListOf<String>()
        val packageName = appInfo.packageName
        
        when {
            SOCIAL_MEDIA_PACKAGES.contains(packageName) -> {
                benefits.add("Separate personal and professional social media accounts")
                benefits.add("Manage multiple social media profiles")
            }
            MESSAGING_PACKAGES.contains(packageName) -> {
                benefits.add("Use multiple phone numbers or accounts")
                benefits.add("Separate work and personal communications")
            }
            GAMING_PACKAGES.contains(packageName) -> {
                benefits.add("Play with multiple game accounts")
                benefits.add("Test different game strategies")
            }
            PRODUCTIVITY_PACKAGES.contains(packageName) -> {
                benefits.add("Separate work and personal data")
                benefits.add("Use multiple accounts simultaneously")
            }
        }
        
        return benefits
    }
    
    private fun identifyRequirements(appInfo: ApplicationInfo): List<String> {
        val requirements = mutableListOf<String>()
        
        requirements.add("Sufficient storage space")
        requirements.add("Adequate RAM for running multiple instances")
        
        if (hasComplexPermissions(appInfo)) {
            requirements.add("Grant all required permissions")
        }
        
        if (hasNativeLibraries(appInfo)) {
            requirements.add("Compatible device architecture")
        }
        
        return requirements
    }
    
    private fun categorizeApp(packageName: String): String {
        return when {
            SOCIAL_MEDIA_PACKAGES.contains(packageName) -> "Social Media"
            MESSAGING_PACKAGES.contains(packageName) -> "Messaging"
            GAMING_PACKAGES.contains(packageName) -> "Gaming"
            PRODUCTIVITY_PACKAGES.contains(packageName) -> "Productivity"
            else -> "Other"
        }
    }
    
    private fun calculatePriority(packageName: String, category: String): Int {
        return when {
            SOCIAL_MEDIA_PACKAGES.contains(packageName) -> 5
            MESSAGING_PACKAGES.contains(packageName) -> 5
            GAMING_PACKAGES.contains(packageName) -> 4
            PRODUCTIVITY_PACKAGES.contains(packageName) -> 3
            category == "Other" -> 2
            else -> 1
        }
    }
    
    private fun calculateConfidence(appInfo: ApplicationInfo): Float {
        var confidence = 0.5f
        
        // Increase confidence for known cloneable apps
        if (SOCIAL_MEDIA_PACKAGES.contains(appInfo.packageName) ||
            MESSAGING_PACKAGES.contains(appInfo.packageName)) {
            confidence += 0.3f
        }
        
        // Decrease confidence for system apps
        if (isSystemApp(appInfo)) {
            confidence -= 0.4f
        }
        
        // Decrease confidence for apps with anti-clone protection
        if (hasAntiCloneProtection(appInfo)) {
            confidence -= 0.3f
        }
        
        return confidence.coerceIn(0.0f, 1.0f)
    }
    
    private fun generateReason(packageName: String, category: String): String {
        return when (category) {
            "Social Media" -> "Popular social media app that benefits from multiple accounts"
            "Messaging" -> "Messaging app commonly used with multiple phone numbers"
            "Gaming" -> "Game that allows multiple player accounts"
            "Productivity" -> "Productivity app that benefits from work/personal separation"
            else -> "App that may benefit from cloning for multiple accounts"
        }
    }
    
    private fun generateBenefit(category: String): String {
        return when (category) {
            "Social Media" -> "Manage multiple social profiles separately"
            "Messaging" -> "Use different phone numbers or accounts"
            "Gaming" -> "Play with multiple game accounts"
            "Productivity" -> "Separate work and personal data"
            else -> "Use multiple accounts simultaneously"
        }
    }
    
    private fun isSystemApp(appInfo: ApplicationInfo): Boolean {
        return (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
    }
    
    private fun hasAntiCloneProtection(appInfo: ApplicationInfo): Boolean {
        // Simple heuristic - apps with certain characteristics may have protection
        val packageName = appInfo.packageName
        return packageName.contains("bank") ||
               packageName.contains("payment") ||
               packageName.contains("wallet") ||
               packageName.contains("security")
    }
    
    private fun requiresSpecialPermissions(appInfo: ApplicationInfo): Boolean {
        // Check if app requires device admin or other special permissions
        return false // Simplified for now
    }
    
    private fun hasNativeLibraries(appInfo: ApplicationInfo): Boolean {
        return try {
            val nativeLibraryDir = File(appInfo.nativeLibraryDir)
            nativeLibraryDir.exists() && nativeLibraryDir.listFiles()?.isNotEmpty() == true
        } catch (e: Exception) {
            false
        }
    }
    
    private fun hasComplexPermissions(appInfo: ApplicationInfo): Boolean {
        // Simplified check - in real implementation, would check actual permissions
        return false
    }
    
    private fun isMultiAccountCandidate(appInfo: ApplicationInfo): Boolean {
        val packageName = appInfo.packageName
        return SOCIAL_MEDIA_PACKAGES.contains(packageName) ||
               MESSAGING_PACKAGES.contains(packageName) ||
               PRODUCTIVITY_PACKAGES.contains(packageName)
    }
    
    private fun saveSuggestions(suggestions: List<CloneSuggestion>) {
        try {
            val jsonArray = JSONArray()
            suggestions.forEach { suggestion ->
                val jsonObject = JSONObject()
                jsonObject.put("packageName", suggestion.packageName)
                jsonObject.put("appName", suggestion.appName)
                jsonObject.put("category", suggestion.category)
                jsonObject.put("priority", suggestion.priority)
                jsonObject.put("reason", suggestion.reason)
                jsonObject.put("confidence", suggestion.confidence)
                jsonObject.put("estimatedBenefit", suggestion.estimatedBenefit)
                jsonArray.put(jsonObject)
            }
            
            val suggestionsFile = File(context.filesDir, CLONE_SUGGESTIONS_FILE)
            suggestionsFile.writeText(jsonArray.toString(2))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save suggestions: ${e.message}")
        }
    }
}
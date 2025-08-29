package com.multispace.app.multispace_cloner

import android.content.Context
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import android.util.Log
import android.net.wifi.WifiManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.bluetooth.BluetoothAdapter
import java.io.File
import java.security.SecureRandom
import java.util.*
import org.json.JSONObject
import org.json.JSONArray
import kotlin.random.Random

/**
 * DeviceSpoofingManager - Manages device information spoofing for app cloning
 * This class handles randomization of device identifiers, hardware info, and network details
 * to ensure each cloned app sees a different device fingerprint
 */
class DeviceSpoofingManager private constructor(private val context: Context) {
    
    companion object {
        const val TAG = "DeviceSpoofingManager"
        
        @Volatile
        private var INSTANCE: DeviceSpoofingManager? = null
        
        fun getInstance(context: Context): DeviceSpoofingManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: DeviceSpoofingManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }
    
    private val secureRandom = SecureRandom()
    private val deviceBrands = listOf(
        "Samsung", "Google", "OnePlus", "Xiaomi", "Huawei", "Oppo", "Vivo",
        "Realme", "Nokia", "Motorola", "Sony", "LG", "HTC", "Honor"
    )
    
    private val deviceModels = mapOf(
        "Samsung" to listOf("Galaxy S21", "Galaxy S22", "Galaxy Note 20", "Galaxy A52", "Galaxy M52"),
        "Google" to listOf("Pixel 6", "Pixel 6 Pro", "Pixel 5", "Pixel 4a", "Pixel 7"),
        "OnePlus" to listOf("OnePlus 9", "OnePlus 9 Pro", "OnePlus 8T", "OnePlus Nord", "OnePlus 10"),
        "Xiaomi" to listOf("Mi 11", "Redmi Note 10", "Poco X3", "Mi 11 Ultra", "Redmi 9A"),
        "Huawei" to listOf("P40 Pro", "Mate 40", "Nova 8", "P30 Lite", "Y9s")
    )
    
    private val androidVersions = listOf(
        "10", "11", "12", "13", "14"
    )
    
    private val carriers = listOf(
        "Verizon", "AT&T", "T-Mobile", "Sprint", "Vodafone", "Orange",
        "Airtel", "Jio", "BSNL", "Idea", "O2", "EE", "Three"
    )
    
    /**
     * Generate spoofed device information for a cloned app
     */
    fun generateSpoofedDeviceInfo(cloneId: String): SpoofedDeviceInfo {
        try {
            Log.d(TAG, "Generating spoofed device info for clone: $cloneId")
            
            val brand = deviceBrands.random()
            val model = deviceModels[brand]?.random() ?: "Unknown"
            val androidVersion = androidVersions.random()
            val carrier = carriers.random()
            
            val spoofedInfo = SpoofedDeviceInfo(
                cloneId = cloneId,
                deviceId = generateRandomDeviceId(),
                androidId = generateRandomAndroidId(),
                imei = generateRandomIMEI(),
                serialNumber = generateRandomSerialNumber(),
                macAddress = generateRandomMacAddress(),
                bluetoothAddress = generateRandomBluetoothAddress(),
                brand = brand,
                model = model,
                manufacturer = brand,
                product = "${brand.lowercase()}_${model.replace(" ", "_").lowercase()}",
                device = model.replace(" ", "").lowercase(),
                board = generateRandomBoard(),
                hardware = generateRandomHardware(),
                androidVersion = androidVersion,
                apiLevel = getApiLevelForVersion(androidVersion),
                buildId = generateRandomBuildId(),
                fingerprint = generateDeviceFingerprint(brand, model, androidVersion),
                carrier = carrier,
                countryCode = generateRandomCountryCode(),
                timeZone = generateRandomTimeZone(),
                locale = generateRandomLocale(),
                screenDensity = generateRandomScreenDensity(),
                screenResolution = generateRandomScreenResolution(),
                cpuAbi = generateRandomCpuAbi(),
                totalRam = generateRandomRam(),
                totalStorage = generateRandomStorage(),
                batteryLevel = generateRandomBatteryLevel(),
                isRooted = false, // Always report as non-rooted for security
                hasVpn = Random.nextBoolean(),
                createdAt = System.currentTimeMillis()
            )
            
            // Save spoofed info to file
            saveSpoofedDeviceInfo(cloneId, spoofedInfo)
            
            Log.d(TAG, "Spoofed device info generated successfully for clone: $cloneId")
            Log.d(TAG, "Device: $brand $model, Android: $androidVersion, IMEI: ${spoofedInfo.imei}")
            
            return spoofedInfo
            
        } catch (e: Exception) {
            Log.e(TAG, "Error generating spoofed device info", e)
            throw e
        }
    }
    
    /**
     * Get saved spoofed device info for a clone
     */
    fun getSpoofedDeviceInfo(cloneId: String): SpoofedDeviceInfo? {
        return try {
            val spoofFile = File(context.filesDir, "spoofed_devices/$cloneId.json")
            if (spoofFile.exists()) {
                val jsonData = spoofFile.readText()
                SpoofedDeviceInfo.fromJson(jsonData)
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading spoofed device info", e)
            null
        }
    }
    
    /**
     * Apply device spoofing for a specific clone
     */
    fun applySpoofing(cloneId: String, packageName: String): Boolean {
        return try {
            val spoofedInfo = getSpoofedDeviceInfo(cloneId) ?: generateSpoofedDeviceInfo(cloneId)
            
            Log.d(TAG, "Applying device spoofing for clone: $cloneId, package: $packageName")
            
            // Create spoofing configuration
            val spoofingConfig = JSONObject().apply {
                put("clone_id", cloneId)
                put("package_name", packageName)
                put("spoofed_device_info", spoofedInfo.toJson())
                put("spoofing_enabled", true)
                put("applied_at", System.currentTimeMillis())
            }
            
            // Save spoofing configuration
            val configFile = File(context.filesDir, "spoofing_configs/$cloneId.json")
            configFile.parentFile?.mkdirs()
            configFile.writeText(spoofingConfig.toString())
            
            // Apply system property spoofing
            applySystemPropertySpoofing(spoofedInfo)
            
            // Apply build info spoofing
            applyBuildInfoSpoofing(spoofedInfo)
            
            // Apply telephony spoofing
            applyTelephonySpoofing(spoofedInfo)
            
            // Apply network spoofing
            applyNetworkSpoofing(spoofedInfo)
            
            Log.d(TAG, "Device spoofing applied successfully for clone: $cloneId")
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error applying device spoofing", e)
            false
        }
    }
    
    /**
     * Remove spoofing for a clone
     */
    fun removeSpoofing(cloneId: String): Boolean {
        return try {
            Log.d(TAG, "Removing device spoofing for clone: $cloneId")
            
            // Remove spoofed device info
            val spoofFile = File(context.filesDir, "spoofed_devices/$cloneId.json")
            if (spoofFile.exists()) {
                spoofFile.delete()
            }
            
            // Remove spoofing configuration
            val configFile = File(context.filesDir, "spoofing_configs/$cloneId.json")
            if (configFile.exists()) {
                configFile.delete()
            }
            
            Log.d(TAG, "Device spoofing removed for clone: $cloneId")
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error removing device spoofing", e)
            false
        }
    }
    
    // Private helper methods for generating random device information
    
    private fun generateRandomDeviceId(): String {
        val chars = "0123456789ABCDEF"
        return (1..16).map { chars.random() }.joinToString("")
    }
    
    private fun generateRandomAndroidId(): String {
        val chars = "0123456789abcdef"
        return (1..16).map { chars.random() }.joinToString("")
    }
    
    private fun generateRandomIMEI(): String {
        // Generate valid IMEI using Luhn algorithm
        val tac = (100000..999999).random()
        val serial = (100000..999999).random()
        val imeiWithoutCheck = "$tac$serial"
        val checkDigit = calculateLuhnCheckDigit(imeiWithoutCheck)
        return "$imeiWithoutCheck$checkDigit"
    }
    
    private fun generateRandomSerialNumber(): String {
        val chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return (1..10).map { chars.random() }.joinToString("")
    }
    
    private fun generateRandomMacAddress(): String {
        val bytes = ByteArray(6)
        secureRandom.nextBytes(bytes)
        bytes[0] = (bytes[0].toInt() and 0xFE).toByte() // Clear multicast bit
        bytes[0] = (bytes[0].toInt() or 0x02).toByte()  // Set local bit
        return bytes.joinToString(":") { "%02X".format(it) }
    }
    
    private fun generateRandomBluetoothAddress(): String {
        val bytes = ByteArray(6)
        secureRandom.nextBytes(bytes)
        return bytes.joinToString(":") { "%02X".format(it) }
    }
    
    private fun generateRandomBoard(): String {
        val boards = listOf("msm8996", "sdm845", "sm8150", "exynos9820", "kirin990")
        return boards.random()
    }
    
    private fun generateRandomHardware(): String {
        val hardware = listOf("qcom", "exynos", "kirin", "mediatek", "snapdragon")
        return hardware.random()
    }
    
    private fun getApiLevelForVersion(version: String): Int {
        return when (version) {
            "10" -> 29
            "11" -> 30
            "12" -> 31
            "13" -> 33
            "14" -> 34
            else -> 30
        }
    }
    
    private fun generateRandomBuildId(): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return (1..8).map { chars.random() }.joinToString("")
    }
    
    private fun generateDeviceFingerprint(brand: String, model: String, version: String): String {
        val buildId = generateRandomBuildId()
        return "$brand/$model/$model:$version/$buildId/${System.currentTimeMillis()}:user/release-keys"
    }
    
    private fun generateRandomCountryCode(): String {
        val countryCodes = listOf("US", "GB", "DE", "FR", "IN", "JP", "KR", "CN", "CA", "AU")
        return countryCodes.random()
    }
    
    private fun generateRandomTimeZone(): String {
        val timeZones = listOf(
            "America/New_York", "Europe/London", "Asia/Tokyo", "Asia/Shanghai",
            "Europe/Berlin", "America/Los_Angeles", "Asia/Kolkata", "Australia/Sydney"
        )
        return timeZones.random()
    }
    
    private fun generateRandomLocale(): String {
        val locales = listOf("en_US", "en_GB", "de_DE", "fr_FR", "ja_JP", "ko_KR", "zh_CN", "hi_IN")
        return locales.random()
    }
    
    private fun generateRandomScreenDensity(): Int {
        val densities = listOf(320, 420, 480, 560, 640)
        return densities.random()
    }
    
    private fun generateRandomScreenResolution(): String {
        val resolutions = listOf(
            "1080x1920", "1440x2560", "1080x2340", "1440x3040", "1080x2400"
        )
        return resolutions.random()
    }
    
    private fun generateRandomCpuAbi(): String {
        val abis = listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
        return abis.random()
    }
    
    private fun generateRandomRam(): Long {
        val ramOptions = listOf(4L, 6L, 8L, 12L, 16L) // GB
        return ramOptions.random() * 1024 * 1024 * 1024 // Convert to bytes
    }
    
    private fun generateRandomStorage(): Long {
        val storageOptions = listOf(64L, 128L, 256L, 512L, 1024L) // GB
        return storageOptions.random() * 1024 * 1024 * 1024 // Convert to bytes
    }
    
    private fun generateRandomBatteryLevel(): Int {
        return (20..100).random()
    }
    
    private fun calculateLuhnCheckDigit(number: String): Int {
        var sum = 0
        var alternate = false
        
        for (i in number.length - 1 downTo 0) {
            var digit = number[i].toString().toInt()
            if (alternate) {
                digit *= 2
                if (digit > 9) digit = (digit % 10) + 1
            }
            sum += digit
            alternate = !alternate
        }
        
        return (10 - (sum % 10)) % 10
    }
    
    // Spoofing application methods
    
    private fun applySystemPropertySpoofing(spoofedInfo: SpoofedDeviceInfo) {
        try {
            Log.d(TAG, "Applying system property spoofing")
            
            // Create system property override configuration
            val systemPropsConfig = JSONObject().apply {
                put("ro.build.brand", spoofedInfo.brand)
                put("ro.build.model", spoofedInfo.model)
                put("ro.build.manufacturer", spoofedInfo.manufacturer)
                put("ro.build.product", spoofedInfo.product)
                put("ro.build.device", spoofedInfo.device)
                put("ro.build.board", spoofedInfo.board)
                put("ro.build.hardware", spoofedInfo.hardware)
                put("ro.build.version.release", spoofedInfo.androidVersion)
                put("ro.build.version.sdk", spoofedInfo.apiLevel)
                put("ro.build.id", spoofedInfo.buildId)
                put("ro.build.fingerprint", spoofedInfo.fingerprint)
                put("ro.serialno", spoofedInfo.serialNumber)
            }
            
            // Save system properties configuration
            val propsFile = File(context.filesDir, "system_props/${spoofedInfo.cloneId}.json")
            propsFile.parentFile?.mkdirs()
            propsFile.writeText(systemPropsConfig.toString())
            
            Log.d(TAG, "System property spoofing configuration saved")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error applying system property spoofing", e)
        }
    }
    
    private fun applyBuildInfoSpoofing(spoofedInfo: SpoofedDeviceInfo) {
        try {
            Log.d(TAG, "Applying build info spoofing")
            
            // Create build info override configuration
            val buildConfig = JSONObject().apply {
                put("BRAND", spoofedInfo.brand)
                put("MODEL", spoofedInfo.model)
                put("MANUFACTURER", spoofedInfo.manufacturer)
                put("PRODUCT", spoofedInfo.product)
                put("DEVICE", spoofedInfo.device)
                put("BOARD", spoofedInfo.board)
                put("HARDWARE", spoofedInfo.hardware)
                put("SERIAL", spoofedInfo.serialNumber)
                put("ID", spoofedInfo.buildId)
                put("FINGERPRINT", spoofedInfo.fingerprint)
                put("CPU_ABI", spoofedInfo.cpuAbi)
                put("CPU_ABI2", "")
                put("SUPPORTED_ABIS", JSONArray().apply { put(spoofedInfo.cpuAbi) })
            }
            
            // Save build info configuration
            val buildFile = File(context.filesDir, "build_info/${spoofedInfo.cloneId}.json")
            buildFile.parentFile?.mkdirs()
            buildFile.writeText(buildConfig.toString())
            
            Log.d(TAG, "Build info spoofing configuration saved")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error applying build info spoofing", e)
        }
    }
    
    private fun applyTelephonySpoofing(spoofedInfo: SpoofedDeviceInfo) {
        try {
            Log.d(TAG, "Applying telephony spoofing")
            
            // Create telephony override configuration
            val telephonyConfig = JSONObject().apply {
                put("imei", spoofedInfo.imei)
                put("device_id", spoofedInfo.deviceId)
                put("subscriber_id", generateRandomSubscriberId())
                put("sim_serial_number", generateRandomSimSerial())
                put("network_operator_name", spoofedInfo.carrier)
                put("network_country_iso", spoofedInfo.countryCode.lowercase())
                put("sim_country_iso", spoofedInfo.countryCode.lowercase())
                put("phone_type", 1) // GSM
                put("network_type", 13) // LTE
            }
            
            // Save telephony configuration
            val telephonyFile = File(context.filesDir, "telephony/${spoofedInfo.cloneId}.json")
            telephonyFile.parentFile?.mkdirs()
            telephonyFile.writeText(telephonyConfig.toString())
            
            Log.d(TAG, "Telephony spoofing configuration saved")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error applying telephony spoofing", e)
        }
    }
    
    private fun applyNetworkSpoofing(spoofedInfo: SpoofedDeviceInfo) {
        try {
            Log.d(TAG, "Applying network spoofing")
            
            // Create network override configuration
            val networkConfig = JSONObject().apply {
                put("mac_address", spoofedInfo.macAddress)
                put("bluetooth_address", spoofedInfo.bluetoothAddress)
                put("wifi_enabled", true)
                put("bluetooth_enabled", Random.nextBoolean())
                put("mobile_data_enabled", true)
                put("network_available", true)
                put("connection_type", "WIFI")
            }
            
            // Save network configuration
            val networkFile = File(context.filesDir, "network/${spoofedInfo.cloneId}.json")
            networkFile.parentFile?.mkdirs()
            networkFile.writeText(networkConfig.toString())
            
            Log.d(TAG, "Network spoofing configuration saved")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error applying network spoofing", e)
        }
    }
    
    private fun saveSpoofedDeviceInfo(cloneId: String, spoofedInfo: SpoofedDeviceInfo) {
        try {
            val spoofFile = File(context.filesDir, "spoofed_devices/$cloneId.json")
            spoofFile.parentFile?.mkdirs()
            spoofFile.writeText(spoofedInfo.toJson().toString())
            Log.d(TAG, "Spoofed device info saved for clone: $cloneId")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving spoofed device info", e)
        }
    }
    
    private fun generateRandomSubscriberId(): String {
        val digits = "0123456789"
        return (1..15).map { digits.random() }.joinToString("")
    }
    
    private fun generateRandomSimSerial(): String {
        val digits = "0123456789"
        return (1..20).map { digits.random() }.joinToString("")
    }
    
    /**
     * Get spoofing status for a clone
     */
    fun getSpoofingStatus(cloneId: String): JSONObject {
        return try {
            val configFile = File(context.filesDir, "spoofing_configs/$cloneId.json")
            if (configFile.exists()) {
                JSONObject(configFile.readText())
            } else {
                JSONObject().apply {
                    put("spoofing_enabled", false)
                    put("error", "No spoofing configuration found")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting spoofing status", e)
            JSONObject().apply {
                put("spoofing_enabled", false)
                put("error", e.message)
            }
        }
    }
    
    /**
     * Update spoofed device info for a clone
     */
    fun updateSpoofedDeviceInfo(cloneId: String, updates: Map<String, Any>): Boolean {
        return try {
            val currentInfo = getSpoofedDeviceInfo(cloneId)
            if (currentInfo != null) {
                val updatedInfo = currentInfo.copy(
                    brand = updates["brand"] as? String ?: currentInfo.brand,
                    model = updates["model"] as? String ?: currentInfo.model,
                    androidVersion = updates["androidVersion"] as? String ?: currentInfo.androidVersion,
                    imei = updates["imei"] as? String ?: currentInfo.imei,
                    carrier = updates["carrier"] as? String ?: currentInfo.carrier
                )
                saveSpoofedDeviceInfo(cloneId, updatedInfo)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating spoofed device info", e)
            false
        }
    }
}

/**
 * Data class representing spoofed device information
 */
data class SpoofedDeviceInfo(
    val cloneId: String,
    val deviceId: String,
    val androidId: String,
    val imei: String,
    val serialNumber: String,
    val macAddress: String,
    val bluetoothAddress: String,
    val brand: String,
    val model: String,
    val manufacturer: String,
    val product: String,
    val device: String,
    val board: String,
    val hardware: String,
    val androidVersion: String,
    val apiLevel: Int,
    val buildId: String,
    val fingerprint: String,
    val carrier: String,
    val countryCode: String,
    val timeZone: String,
    val locale: String,
    val screenDensity: Int,
    val screenResolution: String,
    val cpuAbi: String,
    val totalRam: Long,
    val totalStorage: Long,
    val batteryLevel: Int,
    val isRooted: Boolean,
    val hasVpn: Boolean,
    val createdAt: Long
) {
    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("clone_id", cloneId)
            put("device_id", deviceId)
            put("android_id", androidId)
            put("imei", imei)
            put("serial_number", serialNumber)
            put("mac_address", macAddress)
            put("bluetooth_address", bluetoothAddress)
            put("brand", brand)
            put("model", model)
            put("manufacturer", manufacturer)
            put("product", product)
            put("device", device)
            put("board", board)
            put("hardware", hardware)
            put("android_version", androidVersion)
            put("api_level", apiLevel)
            put("build_id", buildId)
            put("fingerprint", fingerprint)
            put("carrier", carrier)
            put("country_code", countryCode)
            put("time_zone", timeZone)
            put("locale", locale)
            put("screen_density", screenDensity)
            put("screen_resolution", screenResolution)
            put("cpu_abi", cpuAbi)
            put("total_ram", totalRam)
            put("total_storage", totalStorage)
            put("battery_level", batteryLevel)
            put("is_rooted", isRooted)
            put("has_vpn", hasVpn)
            put("created_at", createdAt)
        }
    }
    
    companion object {
        fun fromJson(jsonString: String): SpoofedDeviceInfo {
            val json = JSONObject(jsonString)
            return SpoofedDeviceInfo(
                cloneId = json.getString("clone_id"),
                deviceId = json.getString("device_id"),
                androidId = json.getString("android_id"),
                imei = json.getString("imei"),
                serialNumber = json.getString("serial_number"),
                macAddress = json.getString("mac_address"),
                bluetoothAddress = json.getString("bluetooth_address"),
                brand = json.getString("brand"),
                model = json.getString("model"),
                manufacturer = json.getString("manufacturer"),
                product = json.getString("product"),
                device = json.getString("device"),
                board = json.getString("board"),
                hardware = json.getString("hardware"),
                androidVersion = json.getString("android_version"),
                apiLevel = json.getInt("api_level"),
                buildId = json.getString("build_id"),
                fingerprint = json.getString("fingerprint"),
                carrier = json.getString("carrier"),
                countryCode = json.getString("country_code"),
                timeZone = json.getString("time_zone"),
                locale = json.getString("locale"),
                screenDensity = json.getInt("screen_density"),
                screenResolution = json.getString("screen_resolution"),
                cpuAbi = json.getString("cpu_abi"),
                totalRam = json.getLong("total_ram"),
                totalStorage = json.getLong("total_storage"),
                batteryLevel = json.getInt("battery_level"),
                isRooted = json.getBoolean("is_rooted"),
                hasVpn = json.getBoolean("has_vpn"),
                createdAt = json.getLong("created_at")
            )
        }
    }
}
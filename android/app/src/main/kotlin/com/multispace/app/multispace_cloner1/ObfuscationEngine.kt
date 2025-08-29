package com.multispace.app.multispace_cloner

import android.util.Base64
import android.util.Log
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec
import kotlin.random.Random

/**
 * Advanced Obfuscation Engine for MultiSpace Cloner
 * Provides string obfuscation, control flow obfuscation, and anti-analysis techniques
 */
object ObfuscationEngine {
    
    private const val TAG = "ObfuscationEngine"
    internal val secureRandom = SecureRandom()
    
    // Obfuscation keys - these should be different in production
    private val obfuscationKeys = arrayOf(
        "msc_key_1_2024",
        "cloner_secure_key",
        "multispace_obf_key",
        "android_protection_key"
    )
    
    /**
     * String Obfuscation
     */
    
    /**
     * Obfuscate a string using XOR with dynamic key
     */
    fun obfuscateString(input: String, keyIndex: Int = 0): String {
        return try {
            val key = obfuscationKeys[keyIndex % obfuscationKeys.size]
            val inputBytes = input.toByteArray(StandardCharsets.UTF_8)
            val keyBytes = key.toByteArray(StandardCharsets.UTF_8)
            
            val obfuscated = ByteArray(inputBytes.size)
            for (i in inputBytes.indices) {
                obfuscated[i] = (inputBytes[i].toInt() xor keyBytes[i % keyBytes.size].toInt()).toByte()
            }
            
            Base64.encodeToString(obfuscated, Base64.DEFAULT).trim()
        } catch (e: Exception) {
            Log.e(TAG, "String obfuscation failed", e)
            input // Return original if obfuscation fails
        }
    }
    
    /**
     * Deobfuscate a string using XOR with dynamic key
     */
    fun deobfuscateString(obfuscated: String, keyIndex: Int = 0): String {
        return try {
            val key = obfuscationKeys[keyIndex % obfuscationKeys.size]
            val obfuscatedBytes = Base64.decode(obfuscated, Base64.DEFAULT)
            val keyBytes = key.toByteArray(StandardCharsets.UTF_8)
            
            val deobfuscated = ByteArray(obfuscatedBytes.size)
            for (i in obfuscatedBytes.indices) {
                deobfuscated[i] = (obfuscatedBytes[i].toInt() xor keyBytes[i % keyBytes.size].toInt()).toByte()
            }
            
            String(deobfuscated, StandardCharsets.UTF_8)
        } catch (e: Exception) {
            Log.e(TAG, "String deobfuscation failed", e)
            obfuscated // Return original if deobfuscation fails
        }
    }
    
    /**
     * Advanced string obfuscation with multiple layers
     */
    fun obfuscateStringAdvanced(input: String): ObfuscatedString {
        return try {
            // Layer 1: XOR obfuscation
            val keyIndex = secureRandom.nextInt(obfuscationKeys.size)
            val xorObfuscated = obfuscateString(input, keyIndex)
            
            // Layer 2: Base64 encoding with padding
            val paddingLength = secureRandom.nextInt(16) + 1
            val padding = generateRandomString(paddingLength)
            val paddedString = "$padding$xorObfuscated$padding"
            val base64Encoded = Base64.encodeToString(
                paddedString.toByteArray(StandardCharsets.UTF_8),
                Base64.DEFAULT
            ).trim()
            
            // Layer 3: Character substitution
            val substituted = applyCharacterSubstitution(base64Encoded)
            
            ObfuscatedString(
                data = substituted,
                keyIndex = keyIndex,
                paddingLength = paddingLength,
                checksum = calculateChecksum(input)
            )
        } catch (e: Exception) {
            Log.e(TAG, "Advanced string obfuscation failed", e)
            ObfuscatedString(input, 0, 0, "")
        }
    }
    
    /**
     * Deobfuscate advanced obfuscated string
     */
    fun deobfuscateStringAdvanced(obfuscated: ObfuscatedString): String {
        return try {
            // Layer 3: Reverse character substitution
            val unsubstituted = reverseCharacterSubstitution(obfuscated.data)
            
            // Layer 2: Base64 decoding and padding removal
            val base64Decoded = String(
                Base64.decode(unsubstituted, Base64.DEFAULT),
                StandardCharsets.UTF_8
            )
            val unpaddedString = base64Decoded.substring(
                obfuscated.paddingLength,
                base64Decoded.length - obfuscated.paddingLength
            )
            
            // Layer 1: XOR deobfuscation
            val result = deobfuscateString(unpaddedString, obfuscated.keyIndex)
            
            // Verify integrity
            if (calculateChecksum(result) != obfuscated.checksum) {
                Log.w(TAG, "Checksum mismatch during deobfuscation")
            }
            
            result
        } catch (e: Exception) {
            Log.e(TAG, "Advanced string deobfuscation failed", e)
            obfuscated.data
        }
    }
    
    /**
     * Control Flow Obfuscation
     */
    
    /**
     * Execute code with dummy operations to confuse static analysis
     */
    fun <T> obfuscatedExecution(block: () -> T): T {
        // Add dummy operations
        val dummy1 = System.currentTimeMillis()
        val dummy2 = secureRandom.nextInt(1000)
        val dummy3 = "dummy_string_${dummy1}_${dummy2}".hashCode()
        
        // Execute actual block
        val result = block()
        
        // More dummy operations
        val dummy4 = result.hashCode()
        val dummy5 = (dummy3 xor dummy4).toString()
        
        return result
    }
    
    /**
     * Add fake conditional branches
     */
    fun addFakeBranches(condition: Boolean, trueBlock: () -> Unit, falseBlock: () -> Unit) {
        val fakeCondition1 = System.currentTimeMillis() % 2 == 0L
        val fakeCondition2 = secureRandom.nextBoolean()
        
        when {
            fakeCondition1 && !fakeCondition2 -> {
                // Fake branch 1
                val dummy = "fake_branch_1".hashCode()
            }
            !fakeCondition1 && fakeCondition2 -> {
                // Fake branch 2
                val dummy = "fake_branch_2".hashCode()
            }
            condition -> trueBlock()
            else -> falseBlock()
        }
    }
    
    /**
     * Anti-Analysis Techniques
     */
    
    /**
     * Generate misleading function calls
     */
    fun generateMisleadingCalls() {
        // Fake API calls that do nothing but confuse analysis
        try {
            val fakeData = "fake_api_call_${System.currentTimeMillis()}"
            val fakeHash = MessageDigest.getInstance("SHA-256").digest(fakeData.toByteArray())
            val fakeResult = Base64.encodeToString(fakeHash, Base64.DEFAULT)
            
            // Fake network-like delay
            Thread.sleep(Random.nextLong(1, 10))
            
            // Fake processing
            for (i in 0 until Random.nextInt(5, 15)) {
                val temp = fakeResult.hashCode() xor i
            }
        } catch (e: Exception) {
            // Intentionally ignore
        }
    }
    
    /**
     * Create fake sensitive operations
     */
    fun createFakeSensitiveOperations() {
        try {
            // Fake encryption operation
            val fakeKey = "fake_encryption_key_${secureRandom.nextInt()}"
            val fakeData = "sensitive_fake_data_${System.currentTimeMillis()}"
            val cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
            val keySpec = SecretKeySpec(fakeKey.take(16).padEnd(16, '0').toByteArray(), "AES")
            cipher.init(Cipher.ENCRYPT_MODE, keySpec)
            val fakeEncrypted = cipher.doFinal(fakeData.toByteArray())
            
            // Fake decryption
            cipher.init(Cipher.DECRYPT_MODE, keySpec)
            val fakeDecrypted = cipher.doFinal(fakeEncrypted)
            
            // Fake validation
            val isValid = String(fakeDecrypted) == fakeData
        } catch (e: Exception) {
            // Intentionally ignore
        }
    }
    
    /**
     * Dynamic Code Generation
     */
    
    /**
     * Generate dynamic method names
     */
    fun generateDynamicMethodName(base: String): String {
        val timestamp = System.currentTimeMillis().toString().takeLast(6)
        val random = secureRandom.nextInt(1000).toString().padStart(3, '0')
        return "${base}_${timestamp}_${random}"
    }
    
    /**
     * Generate dynamic class names
     */
    fun generateDynamicClassName(base: String): String {
        val hash = base.hashCode().toString().replace("-", "N")
        val random = secureRandom.nextInt(10000).toString().padStart(4, '0')
        return "${base}${hash}${random}"
    }
    
    /**
     * Utility Functions
     */
    
    private fun applyCharacterSubstitution(input: String): String {
        val substitutionMap = mapOf(
            'A' to 'Z', 'B' to 'Y', 'C' to 'X', 'D' to 'W', 'E' to 'V',
            'F' to 'U', 'G' to 'T', 'H' to 'S', 'I' to 'R', 'J' to 'Q',
            'K' to 'P', 'L' to 'O', 'M' to 'N', 'N' to 'M', 'O' to 'L',
            'P' to 'K', 'Q' to 'J', 'R' to 'I', 'S' to 'H', 'T' to 'G',
            'U' to 'F', 'V' to 'E', 'W' to 'D', 'X' to 'C', 'Y' to 'B',
            'Z' to 'A'
        )
        
        return input.map { char ->
            substitutionMap[char.uppercaseChar()]?.let { substituted ->
                if (char.isLowerCase()) substituted.lowercaseChar() else substituted
            } ?: char
        }.joinToString("")
    }
    
    private fun reverseCharacterSubstitution(input: String): String {
        // Reverse of applyCharacterSubstitution
        return applyCharacterSubstitution(input) // Since it's symmetric
    }
    
    private fun generateRandomString(length: Int): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return (1..length)
            .map { chars[secureRandom.nextInt(chars.length)] }
            .joinToString("")
    }
    
    private fun calculateChecksum(input: String): String {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(input.toByteArray(StandardCharsets.UTF_8))
            Base64.encodeToString(hash, Base64.DEFAULT).trim().take(16)
        } catch (e: Exception) {
            input.hashCode().toString()
        }
    }
    
    /**
     * Runtime String Deobfuscation
     */
    
    /**
     * Deobfuscate strings at runtime to avoid static analysis
     */
    fun runtimeDeobfuscate(obfuscatedStrings: Map<String, String>): Map<String, String> {
        return obfuscatedStrings.mapValues { (_, obfuscated) ->
            deobfuscateString(obfuscated)
        }
    }
    
    /**
     * Get obfuscated constant strings
     */
    fun getObfuscatedConstants(): Map<String, String> {
        return mapOf(
            "API_ENDPOINT" to obfuscateString("https://api.multispace.com"),
            "SECRET_KEY" to obfuscateString("multispace_secret_2024"),
            "DATABASE_NAME" to obfuscateString("multispace_cloner.db"),
            "SHARED_PREFS" to obfuscateString("multispace_preferences"),
            "ENCRYPTION_ALGORITHM" to obfuscateString("AES/GCM/NoPadding"),
            "KEYSTORE_ALIAS" to obfuscateString("multispace_master_key")
        )
    }
    
    /**
     * Anti-Debugging Helpers
     */
    
    /**
     * Add timing checks to detect debugging
     */
    fun addTimingChecks(block: () -> Unit) {
        val startTime = System.nanoTime()
        block()
        val endTime = System.nanoTime()
        
        val executionTime = endTime - startTime
        // If execution took too long, it might indicate debugging
        if (executionTime > 1_000_000_000) { // 1 second
            Log.w(TAG, "Suspicious execution time detected")
            // Could trigger additional security measures
        }
    }
    
    /**
     * Add stack trace checks
     */
    fun checkStackTrace(): Boolean {
        val stackTrace = Thread.currentThread().stackTrace
        val suspiciousClasses = listOf(
            "dalvik.system.VMDebug",
            "android.os.Debug",
            "java.lang.management",
            "com.android.tools"
        )
        
        return stackTrace.any { element ->
            suspiciousClasses.any { suspicious ->
                element.className.contains(suspicious, ignoreCase = true)
            }
        }
    }
}

/**
 * Data class for advanced obfuscated strings
 */
data class ObfuscatedString(
    val data: String,
    val keyIndex: Int,
    val paddingLength: Int,
    val checksum: String
)
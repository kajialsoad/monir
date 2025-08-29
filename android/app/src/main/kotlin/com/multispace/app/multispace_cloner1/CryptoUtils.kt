package com.multispace.app.multispace_cloner

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import java.nio.charset.StandardCharsets
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import java.security.spec.AlgorithmParameterSpec
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.Mac
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec
import javax.crypto.SecretKeyFactory
import kotlin.random.Random

/**
 * Advanced Cryptographic Utilities for MultiSpace Cloner
 * Provides various encryption, hashing, and key management functions
 */
object CryptoUtils {
    
    private const val TAG = "CryptoUtils"
    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val AES_TRANSFORMATION = "AES/GCM/NoPadding"
    private const val RSA_TRANSFORMATION = "RSA/ECB/OAEPWithSHA-256AndMGF1Padding"
    private const val GCM_IV_LENGTH = 12
    private const val GCM_TAG_LENGTH = 16
    private const val PBKDF2_ITERATIONS = 100000
    private const val SALT_LENGTH = 32
    
    private val secureRandom = SecureRandom()
    
    /**
     * AES Encryption/Decryption
     */
    
    /**
     * Generate AES key with specified key size
     */
    fun generateAESKey(keySize: Int = 256): SecretKey {
        val keyGenerator = KeyGenerator.getInstance("AES")
        keyGenerator.init(keySize)
        return keyGenerator.generateKey()
    }
    
    /**
     * Encrypt data using AES-GCM
     */
    fun encryptAES(data: ByteArray, key: SecretKey, associatedData: ByteArray? = null): EncryptionResult? {
        return try {
            val cipher = Cipher.getInstance(AES_TRANSFORMATION)
            val iv = ByteArray(GCM_IV_LENGTH)
            secureRandom.nextBytes(iv)
            
            val gcmSpec = GCMParameterSpec(GCM_TAG_LENGTH * 8, iv)
            cipher.init(Cipher.ENCRYPT_MODE, key, gcmSpec)
            
            // Add associated data if provided
            associatedData?.let { cipher.updateAAD(it) }
            
            val encryptedData = cipher.doFinal(data)
            
            EncryptionResult(encryptedData, iv, associatedData)
        } catch (e: Exception) {
            Log.e(TAG, "AES encryption failed", e)
            null
        }
    }
    
    /**
     * Decrypt data using AES-GCM
     */
    fun decryptAES(encryptionResult: EncryptionResult, key: SecretKey): ByteArray? {
        return try {
            val cipher = Cipher.getInstance(AES_TRANSFORMATION)
            val gcmSpec = GCMParameterSpec(GCM_TAG_LENGTH * 8, encryptionResult.iv)
            cipher.init(Cipher.DECRYPT_MODE, key, gcmSpec)
            
            // Add associated data if provided
            encryptionResult.associatedData?.let { cipher.updateAAD(it) }
            
            cipher.doFinal(encryptionResult.encryptedData)
        } catch (e: Exception) {
            Log.e(TAG, "AES decryption failed", e)
            null
        }
    }
    
    /**
     * RSA Encryption/Decryption
     */
    
    /**
     * Generate RSA key pair in Android Keystore
     */
    fun generateRSAKeyPair(alias: String, keySize: Int = 2048): Boolean {
        return try {
            val keyPairGenerator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_RSA,
                ANDROID_KEYSTORE
            )
            
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setKeySize(keySize)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
                .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
                .build()
            
            keyPairGenerator.initialize(keyGenParameterSpec)
            keyPairGenerator.generateKeyPair()
            
            true
        } catch (e: Exception) {
            Log.e(TAG, "RSA key pair generation failed", e)
            false
        }
    }
    
    /**
     * Encrypt data using RSA-OAEP
     */
    fun encryptRSA(data: ByteArray, keyAlias: String): ByteArray? {
        return try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
            keyStore.load(null)
            
            val publicKey = keyStore.getCertificate(keyAlias)?.publicKey
                ?: return null
            
            val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
            cipher.init(Cipher.ENCRYPT_MODE, publicKey)
            
            cipher.doFinal(data)
        } catch (e: Exception) {
            Log.e(TAG, "RSA encryption failed", e)
            null
        }
    }
    
    /**
     * Decrypt data using RSA-OAEP
     */
    fun decryptRSA(encryptedData: ByteArray, keyAlias: String): ByteArray? {
        return try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
            keyStore.load(null)
            
            val privateKey = keyStore.getKey(keyAlias, null)
                ?: return null
            
            val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
            cipher.init(Cipher.DECRYPT_MODE, privateKey)
            
            cipher.doFinal(encryptedData)
        } catch (e: Exception) {
            Log.e(TAG, "RSA decryption failed", e)
            null
        }
    }
    
    /**
     * Password-Based Encryption
     */
    
    /**
     * Derive key from password using PBKDF2
     */
    fun deriveKeyFromPassword(
        password: String,
        salt: ByteArray,
        iterations: Int = PBKDF2_ITERATIONS,
        keyLength: Int = 256
    ): SecretKey? {
        return try {
            val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            val spec = PBEKeySpec(password.toCharArray(), salt, iterations, keyLength)
            val key = factory.generateSecret(spec)
            SecretKeySpec(key.encoded, "AES")
        } catch (e: Exception) {
            Log.e(TAG, "Key derivation failed", e)
            null
        }
    }
    
    /**
     * Generate random salt
     */
    fun generateSalt(length: Int = SALT_LENGTH): ByteArray {
        val salt = ByteArray(length)
        secureRandom.nextBytes(salt)
        return salt
    }
    
    /**
     * Encrypt data with password
     */
    fun encryptWithPassword(data: ByteArray, password: String): PasswordEncryptionResult? {
        return try {
            val salt = generateSalt()
            val key = deriveKeyFromPassword(password, salt) ?: return null
            
            val encryptionResult = encryptAES(data, key) ?: return null
            
            PasswordEncryptionResult(
                encryptedData = encryptionResult.encryptedData,
                iv = encryptionResult.iv,
                salt = salt,
                associatedData = encryptionResult.associatedData
            )
        } catch (e: Exception) {
            Log.e(TAG, "Password encryption failed", e)
            null
        }
    }
    
    /**
     * Decrypt data with password
     */
    fun decryptWithPassword(result: PasswordEncryptionResult, password: String): ByteArray? {
        return try {
            val key = deriveKeyFromPassword(password, result.salt) ?: return null
            
            val encryptionResult = EncryptionResult(
                encryptedData = result.encryptedData,
                iv = result.iv,
                associatedData = result.associatedData
            )
            
            decryptAES(encryptionResult, key)
        } catch (e: Exception) {
            Log.e(TAG, "Password decryption failed", e)
            null
        }
    }
    
    /**
     * Hashing Functions
     */
    
    /**
     * Calculate SHA-256 hash
     */
    fun sha256(data: ByteArray): ByteArray {
        val digest = MessageDigest.getInstance("SHA-256")
        return digest.digest(data)
    }
    
    /**
     * Calculate SHA-512 hash
     */
    fun sha512(data: ByteArray): ByteArray {
        val digest = MessageDigest.getInstance("SHA-512")
        return digest.digest(data)
    }
    
    /**
     * Calculate HMAC-SHA256
     */
    fun hmacSha256(data: ByteArray, key: SecretKey): ByteArray? {
        return try {
            val mac = Mac.getInstance("HmacSHA256")
            mac.init(key)
            mac.doFinal(data)
        } catch (e: Exception) {
            Log.e(TAG, "HMAC-SHA256 failed", e)
            null
        }
    }
    
    /**
     * Calculate HMAC-SHA512
     */
    fun hmacSha512(data: ByteArray, key: SecretKey): ByteArray? {
        return try {
            val mac = Mac.getInstance("HmacSHA512")
            mac.init(key)
            mac.doFinal(data)
        } catch (e: Exception) {
            Log.e(TAG, "HMAC-SHA512 failed", e)
            null
        }
    }
    
    /**
     * Secure Random Generation
     */
    
    /**
     * Generate secure random bytes
     */
    fun generateSecureRandomBytes(length: Int): ByteArray {
        val bytes = ByteArray(length)
        secureRandom.nextBytes(bytes)
        return bytes
    }
    
    /**
     * Generate secure random string
     */
    fun generateSecureRandomString(length: Int): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return (1..length)
            .map { chars[secureRandom.nextInt(chars.length)] }
            .joinToString("")
    }
    
    /**
     * Key Management
     */
    
    /**
     * Store key in Android Keystore
     */
    fun storeKeyInKeystore(alias: String, key: SecretKey): Boolean {
        return try {
            val keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                ANDROID_KEYSTORE
            )
            
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build()
            
            keyGenerator.init(keyGenParameterSpec)
            keyGenerator.generateKey()
            
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to store key in keystore", e)
            false
        }
    }
    
    /**
     * Retrieve key from Android Keystore
     */
    fun getKeyFromKeystore(alias: String): SecretKey? {
        return try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
            keyStore.load(null)
            
            keyStore.getKey(alias, null) as? SecretKey
        } catch (e: Exception) {
            Log.e(TAG, "Failed to retrieve key from keystore", e)
            null
        }
    }
    
    /**
     * Delete key from Android Keystore
     */
    fun deleteKeyFromKeystore(alias: String): Boolean {
        return try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
            keyStore.load(null)
            keyStore.deleteEntry(alias)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete key from keystore", e)
            false
        }
    }
    
    /**
     * Utility Functions
     */
    
    /**
     * Convert bytes to hex string
     */
    fun bytesToHex(bytes: ByteArray): String {
        return bytes.joinToString("") { "%02x".format(it) }
    }
    
    /**
     * Convert hex string to bytes
     */
    fun hexToBytes(hex: String): ByteArray {
        return hex.chunked(2)
            .map { it.toInt(16).toByte() }
            .toByteArray()
    }
    
    /**
     * Encode bytes to Base64
     */
    fun encodeBase64(bytes: ByteArray): String {
        return Base64.encodeToString(bytes, Base64.DEFAULT)
    }
    
    /**
     * Decode Base64 to bytes
     */
    fun decodeBase64(base64: String): ByteArray {
        return Base64.decode(base64, Base64.DEFAULT)
    }
    
    /**
     * Secure string comparison
     */
    fun secureEquals(a: ByteArray, b: ByteArray): Boolean {
        if (a.size != b.size) {
            return false
        }
        
        var result = 0
        for (i in a.indices) {
            result = result or (a[i].toInt() xor b[i].toInt())
        }
        
        return result == 0
    }
    
    /**
     * Secure string comparison
     */
    fun secureEquals(a: String, b: String): Boolean {
        return secureEquals(
            a.toByteArray(StandardCharsets.UTF_8),
            b.toByteArray(StandardCharsets.UTF_8)
        )
    }
    
    /**
     * Advanced Security Validation
     */
    
    /**
     * Validate data integrity using HMAC
     */
    fun validateIntegrity(data: ByteArray, hmac: ByteArray, key: SecretKey): Boolean {
        val calculatedHmac = hmacSha256(data, key) ?: return false
        return secureEquals(hmac, calculatedHmac)
    }
    
    /**
     * Create secure checksum for data
     */
    fun createSecureChecksum(data: ByteArray, key: SecretKey): ByteArray? {
        return hmacSha256(data, key)
    }
    
    /**
     * Wipe sensitive data from memory
     */
    fun wipeSensitiveData(data: ByteArray) {
        for (i in data.indices) {
            data[i] = 0
        }
    }
    
    /**
     * Wipe sensitive data from char array
     */
    fun wipeSensitiveData(data: CharArray) {
        for (i in data.indices) {
            data[i] = '\u0000'
        }
    }
}

/**
 * Data classes for encryption results
 */
data class EncryptionResult(
    val encryptedData: ByteArray,
    val iv: ByteArray,
    val associatedData: ByteArray? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        
        other as EncryptionResult
        
        if (!encryptedData.contentEquals(other.encryptedData)) return false
        if (!iv.contentEquals(other.iv)) return false
        if (associatedData != null) {
            if (other.associatedData == null) return false
            if (!associatedData.contentEquals(other.associatedData)) return false
        } else if (other.associatedData != null) return false
        
        return true
    }
    
    override fun hashCode(): Int {
        var result = encryptedData.contentHashCode()
        result = 31 * result + iv.contentHashCode()
        result = 31 * result + (associatedData?.contentHashCode() ?: 0)
        return result
    }
}

data class PasswordEncryptionResult(
    val encryptedData: ByteArray,
    val iv: ByteArray,
    val salt: ByteArray,
    val associatedData: ByteArray? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        
        other as PasswordEncryptionResult
        
        if (!encryptedData.contentEquals(other.encryptedData)) return false
        if (!iv.contentEquals(other.iv)) return false
        if (!salt.contentEquals(other.salt)) return false
        if (associatedData != null) {
            if (other.associatedData == null) return false
            if (!associatedData.contentEquals(other.associatedData)) return false
        } else if (other.associatedData != null) return false
        
        return true
    }
    
    override fun hashCode(): Int {
        var result = encryptedData.contentHashCode()
        result = 31 * result + iv.contentHashCode()
        result = 31 * result + salt.contentHashCode()
        result = 31 * result + (associatedData?.contentHashCode() ?: 0)
        return result
    }
}
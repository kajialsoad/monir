package com.multispace.app.multispace_cloner

import android.content.Context
import android.content.ContextWrapper
import android.content.SharedPreferences
import android.database.sqlite.SQLiteDatabase
import android.database.DatabaseErrorHandler
import android.os.Environment
import java.io.File
import android.util.Log
import org.json.JSONObject

/**
 * 🔒 Isolated Context Wrapper for Storage Isolation
 * 
 * This class wraps the original context to redirect all storage operations
 * to clone-specific directories, ensuring complete data isolation between
 * the original app and its clones.
 */
class IsolatedContextWrapper(
    base: Context,
    private val cloneId: String,
    private val packageName: String
) : ContextWrapper(base) {
    
    companion object {
        private const val TAG = "IsolatedContextWrapper"
        private const val ISOLATED_ROOT = "isolated_data"
    }
    
    private val dataIsolationManager = DataIsolationManager(baseContext)
    private val isolatedDirectory: File by lazy {
        getOrCreateIsolatedDirectory()
    }
    
    /**
     * 📁 Override getFilesDir() to return clone-specific files directory
     */
    override fun getFilesDir(): File {
        val filesDir = File(isolatedDirectory, "app_files")
        if (!filesDir.exists()) {
            filesDir.mkdirs()
            Log.d(TAG, "Created isolated files directory: ${filesDir.absolutePath}")
        }
        return filesDir
    }
    
    /**
     * 📁 Override getCacheDir() to return clone-specific cache directory
     */
    override fun getCacheDir(): File {
        val cacheDir = File(isolatedDirectory, "app_cache")
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
            Log.d(TAG, "Created isolated cache directory: ${cacheDir.absolutePath}")
        }
        return cacheDir
    }
    
    /**
     * 📁 Override getExternalFilesDir() to return clone-specific external files directory
     */
    override fun getExternalFilesDir(type: String?): File? {
        val externalDir = File(isolatedDirectory, "external_files")
        if (!externalDir.exists()) {
            externalDir.mkdirs()
        }
        
        return if (type != null) {
            val typeDir = File(externalDir, type)
            if (!typeDir.exists()) {
                typeDir.mkdirs()
            }
            typeDir
        } else {
            externalDir
        }
    }
    
    /**
     * 🗄️ Override getDatabasePath() to return clone-specific database path
     */
    override fun getDatabasePath(name: String): File {
        val databasesDir = File(isolatedDirectory, "app_databases")
        if (!databasesDir.exists()) {
            databasesDir.mkdirs()
            Log.d(TAG, "Created isolated databases directory: ${databasesDir.absolutePath}")
        }
        
        val dbFile = File(databasesDir, name)
        Log.d(TAG, "Database path for clone $cloneId: ${dbFile.absolutePath}")
        return dbFile
    }
    
    /**
     * 🔧 Override getSharedPreferences() to return clone-specific SharedPreferences
     */
    override fun getSharedPreferences(name: String, mode: Int): SharedPreferences {
        val prefsDir = File(isolatedDirectory, "shared_prefs")
        if (!prefsDir.exists()) {
            prefsDir.mkdirs()
            Log.d(TAG, "Created isolated shared_prefs directory: ${prefsDir.absolutePath}")
        }
        
        val prefsFile = File(prefsDir, "$name.xml")
        Log.d(TAG, "SharedPreferences for clone $cloneId: ${prefsFile.absolutePath}")
        
        // Return isolated SharedPreferences implementation
        return dataIsolationManager.getIsolatedSharedPreferences(packageName, cloneId, name)
            ?: super.getSharedPreferences(name, mode)
    }
    
    /**
     * 🗄️ Override openOrCreateDatabase() to use isolated database path
     */
    override fun openOrCreateDatabase(
        name: String,
        mode: Int,
        factory: SQLiteDatabase.CursorFactory?
    ): SQLiteDatabase {
        val dbPath = getDatabasePath(name)
        Log.d(TAG, "Opening isolated database: ${dbPath.absolutePath}")
        
        return SQLiteDatabase.openOrCreateDatabase(dbPath.absolutePath, factory)
    }
    
    /**
     * 🗄️ Override openOrCreateDatabase() with error handler
     */
    override fun openOrCreateDatabase(
        name: String,
        mode: Int,
        factory: SQLiteDatabase.CursorFactory?,
        errorHandler: android.database.DatabaseErrorHandler?
    ): SQLiteDatabase {
        val dbPath = getDatabasePath(name)
        Log.d(TAG, "Opening isolated database with error handler: ${dbPath.absolutePath}")
        
        return SQLiteDatabase.openOrCreateDatabase(dbPath.absolutePath, factory, errorHandler)
    }
    
    /**
     * 📁 Override getDir() to return clone-specific custom directories
     */
    override fun getDir(name: String, mode: Int): File {
        val customDir = File(isolatedDirectory, "custom_dirs/$name")
        if (!customDir.exists()) {
            customDir.mkdirs()
            Log.d(TAG, "Created isolated custom directory: ${customDir.absolutePath}")
        }
        return customDir
    }
    
    /**
     * 🔧 Get or create the isolated directory for this clone
     */
    private fun getOrCreateIsolatedDirectory(): File {
        val isolationRoot = File(baseContext.filesDir, ISOLATED_ROOT)
        if (!isolationRoot.exists()) {
            isolationRoot.mkdirs()
        }
        
        val cloneDir = File(isolationRoot, "${packageName}_${cloneId}")
        if (!cloneDir.exists()) {
            cloneDir.mkdirs()
            Log.d(TAG, "Created isolated directory for clone $cloneId: ${cloneDir.absolutePath}")
            
            // Create subdirectories
            createSubDirectories(cloneDir)
        }
        
        return cloneDir
    }
    
    /**
     * 📁 Create necessary subdirectories in the isolated directory
     */
    private fun createSubDirectories(cloneDir: File) {
        val subDirs = listOf(
            "app_files",
            "app_cache", 
            "app_databases",
            "shared_prefs",
            "external_files",
            "custom_dirs"
        )
        
        subDirs.forEach { dirName ->
            val subDir = File(cloneDir, dirName)
            if (!subDir.exists()) {
                subDir.mkdirs()
                Log.d(TAG, "Created subdirectory: ${subDir.absolutePath}")
            }
        }
    }
    
    /**
     * 🧹 Clear all isolated data for this clone
     */
    fun clearIsolatedData(): Boolean {
        return try {
            if (isolatedDirectory.exists()) {
                isolatedDirectory.deleteRecursively()
                Log.d(TAG, "Cleared isolated data for clone: $cloneId")
                true
            } else {
                Log.w(TAG, "No isolated data found for clone: $cloneId")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing isolated data for clone: $cloneId", e)
            false
        }
    }
    
    /**
     * 📊 Get storage usage for this clone
     */
    fun getStorageUsage(): Long {
        return try {
            if (isolatedDirectory.exists()) {
                calculateDirectorySize(isolatedDirectory)
            } else {
                0L
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating storage usage for clone: $cloneId", e)
            0L
        }
    }
    
    /**
     * 📏 Calculate directory size recursively
     */
    private fun calculateDirectorySize(directory: File): Long {
        var size = 0L
        
        if (directory.isDirectory) {
            directory.listFiles()?.forEach { file ->
                size += if (file.isDirectory) {
                    calculateDirectorySize(file)
                } else {
                    file.length()
                }
            }
        } else {
            size = directory.length()
        }
        
        return size
    }
    
    /**
     * 🔍 Get isolated directory path
     */
    fun getIsolatedDirectoryPath(): String {
        return isolatedDirectory.absolutePath
    }
    
    /**
     * ✅ Check if isolated directory exists
     */
    fun isIsolatedDirectoryCreated(): Boolean {
        return isolatedDirectory.exists()
    }
}
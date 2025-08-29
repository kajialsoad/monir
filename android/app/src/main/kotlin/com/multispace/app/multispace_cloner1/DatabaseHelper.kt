package com.multispace.app.multispace_cloner

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

/**
 * SQLite Database Helper class
 * Cloned apps এর সব data manage করে
 */
class DatabaseHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "multispace_cloner.db"
        private const val DATABASE_VERSION = 1
        private const val TAG = "DatabaseHelper"
        
        @Volatile
        private var INSTANCE: DatabaseHelper? = null
        
        fun getInstance(context: Context): DatabaseHelper {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: DatabaseHelper(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    override fun onCreate(db: SQLiteDatabase) {
        try {
            // Create cloned_apps table
            val createClonedAppsTable = """
                CREATE TABLE ${ClonedApp.TABLE_NAME} (
                    ${ClonedApp.COLUMN_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
                    ${ClonedApp.COLUMN_ORIGINAL_PACKAGE} TEXT NOT NULL,
                    ${ClonedApp.COLUMN_CLONED_PACKAGE} TEXT NOT NULL UNIQUE,
                    ${ClonedApp.COLUMN_APP_NAME} TEXT NOT NULL,
                    ${ClonedApp.COLUMN_CLONED_APP_NAME} TEXT NOT NULL,
                    ${ClonedApp.COLUMN_ICON_PATH} TEXT,
                    ${ClonedApp.COLUMN_IS_ACTIVE} INTEGER DEFAULT 1,
                    ${ClonedApp.COLUMN_CREATED_AT} INTEGER NOT NULL,
                    ${ClonedApp.COLUMN_LAST_USED} INTEGER NOT NULL,
                    ${ClonedApp.COLUMN_DATA_PATH} TEXT NOT NULL,
                    ${ClonedApp.COLUMN_USER_ID} INTEGER DEFAULT 0,
                    ${ClonedApp.COLUMN_ACCOUNT_INFO} TEXT
                )
            """.trimIndent()
            
            // Create app_usage_stats table
            val createUsageStatsTable = """
                CREATE TABLE ${AppUsageStats.TABLE_NAME} (
                    ${AppUsageStats.COLUMN_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
                    ${AppUsageStats.COLUMN_CLONED_APP_ID} INTEGER NOT NULL,
                    ${AppUsageStats.COLUMN_SESSION_START} INTEGER NOT NULL,
                    ${AppUsageStats.COLUMN_SESSION_END} INTEGER,
                    ${AppUsageStats.COLUMN_SESSION_DURATION} INTEGER DEFAULT 0,
                    ${AppUsageStats.COLUMN_MEMORY_USAGE} INTEGER DEFAULT 0,
                    ${AppUsageStats.COLUMN_CPU_USAGE} REAL DEFAULT 0,
                    ${AppUsageStats.COLUMN_NETWORK_USAGE} INTEGER DEFAULT 0,
                    FOREIGN KEY (${AppUsageStats.COLUMN_CLONED_APP_ID}) REFERENCES ${ClonedApp.TABLE_NAME}(${ClonedApp.COLUMN_ID}) ON DELETE CASCADE
                )
            """.trimIndent()
            
            // Create user_accounts table
            val createUserAccountsTable = """
                CREATE TABLE ${UserAccount.TABLE_NAME} (
                    ${UserAccount.COLUMN_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
                    ${UserAccount.COLUMN_CLONED_APP_ID} INTEGER NOT NULL,
                    ${UserAccount.COLUMN_ACCOUNT_NAME} TEXT NOT NULL,
                    ${UserAccount.COLUMN_ACCOUNT_TYPE} TEXT NOT NULL,
                    ${UserAccount.COLUMN_LOGIN_DATA} TEXT,
                    ${UserAccount.COLUMN_IS_ACTIVE} INTEGER DEFAULT 1,
                    ${UserAccount.COLUMN_CREATED_AT} INTEGER NOT NULL,
                    ${UserAccount.COLUMN_LAST_LOGIN} INTEGER NOT NULL,
                    FOREIGN KEY (${UserAccount.COLUMN_CLONED_APP_ID}) REFERENCES ${ClonedApp.TABLE_NAME}(${ClonedApp.COLUMN_ID}) ON DELETE CASCADE
                )
            """.trimIndent()
            
            db.execSQL(createClonedAppsTable)
            db.execSQL(createUsageStatsTable)
            db.execSQL(createUserAccountsTable)
            
            // Create indexes for better performance
            db.execSQL("CREATE INDEX idx_cloned_package ON ${ClonedApp.TABLE_NAME}(${ClonedApp.COLUMN_CLONED_PACKAGE})")
            db.execSQL("CREATE INDEX idx_original_package ON ${ClonedApp.TABLE_NAME}(${ClonedApp.COLUMN_ORIGINAL_PACKAGE})")
            db.execSQL("CREATE INDEX idx_usage_app_id ON ${AppUsageStats.TABLE_NAME}(${AppUsageStats.COLUMN_CLONED_APP_ID})")
            db.execSQL("CREATE INDEX idx_account_app_id ON ${UserAccount.TABLE_NAME}(${UserAccount.COLUMN_CLONED_APP_ID})")
            
            Log.d(TAG, "Database tables created successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error creating database tables", e)
        }
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        try {
            // Handle database upgrades here
            when (oldVersion) {
                // Add migration logic for future versions
            }
            Log.d(TAG, "Database upgraded from version $oldVersion to $newVersion")
        } catch (e: Exception) {
            Log.e(TAG, "Error upgrading database", e)
            // If upgrade fails, recreate tables
            db.execSQL("DROP TABLE IF EXISTS ${ClonedApp.TABLE_NAME}")
            db.execSQL("DROP TABLE IF EXISTS ${AppUsageStats.TABLE_NAME}")
            db.execSQL("DROP TABLE IF EXISTS ${UserAccount.TABLE_NAME}")
            onCreate(db)
        }
    }

    override fun onConfigure(db: SQLiteDatabase) {
        super.onConfigure(db)
        db.setForeignKeyConstraintsEnabled(true)
    }

    /**
     * Insert a new cloned app record
     */
    fun insertClonedApp(clonedApp: ClonedApp): Long {
        val db = writableDatabase
        return try {
            val values = ContentValues().apply {
                put(ClonedApp.COLUMN_ORIGINAL_PACKAGE, clonedApp.originalPackageName)
                put(ClonedApp.COLUMN_CLONED_PACKAGE, clonedApp.clonedPackageName)
                put(ClonedApp.COLUMN_APP_NAME, clonedApp.appName)
                put(ClonedApp.COLUMN_CLONED_APP_NAME, clonedApp.clonedAppName)
                put(ClonedApp.COLUMN_ICON_PATH, clonedApp.iconPath)
                put(ClonedApp.COLUMN_IS_ACTIVE, if (clonedApp.isActive) 1 else 0)
                put(ClonedApp.COLUMN_CREATED_AT, clonedApp.createdAt)
                put(ClonedApp.COLUMN_LAST_USED, clonedApp.lastUsed)
                put(ClonedApp.COLUMN_DATA_PATH, clonedApp.dataPath)
                put(ClonedApp.COLUMN_USER_ID, clonedApp.userId)
                put(ClonedApp.COLUMN_ACCOUNT_INFO, clonedApp.accountInfo)
            }
            val result = db.insert(ClonedApp.TABLE_NAME, null, values)
            Log.d(TAG, "Cloned app inserted with ID: $result")
            result
        } catch (e: Exception) {
            Log.e(TAG, "Error inserting cloned app", e)
            -1L
        }
    }

    /**
     * Get all cloned apps
     */
    fun getAllClonedApps(): List<ClonedApp> {
        val clonedApps = mutableListOf<ClonedApp>()
        val db = readableDatabase
        
        Log.d("DatabaseHelper", "getAllClonedApps: Querying database for active cloned apps")
        
        try {
            val cursor = db.query(
                ClonedApp.TABLE_NAME,
                null,
                "${ClonedApp.COLUMN_IS_ACTIVE} = ?",
                arrayOf("1"),
                null,
                null,
                "${ClonedApp.COLUMN_LAST_USED} DESC"
            )
            
            cursor.use {
                Log.d("DatabaseHelper", "getAllClonedApps: Cursor count = ${it.count}")
                while (it.moveToNext()) {
                    val clonedApp = ClonedApp(
                        id = it.getLong(it.getColumnIndexOrThrow(ClonedApp.COLUMN_ID)),
                        originalPackageName = it.getString(it.getColumnIndexOrThrow(ClonedApp.COLUMN_ORIGINAL_PACKAGE)),
                        clonedPackageName = it.getString(it.getColumnIndexOrThrow(ClonedApp.COLUMN_CLONED_PACKAGE)),
                        appName = it.getString(it.getColumnIndexOrThrow(ClonedApp.COLUMN_APP_NAME)),
                        clonedAppName = it.getString(it.getColumnIndexOrThrow(ClonedApp.COLUMN_CLONED_APP_NAME)),
                        iconPath = it.getString(it.getColumnIndexOrThrow(ClonedApp.COLUMN_ICON_PATH)),
                        isActive = it.getInt(it.getColumnIndexOrThrow(ClonedApp.COLUMN_IS_ACTIVE)) == 1,
                        createdAt = it.getLong(it.getColumnIndexOrThrow(ClonedApp.COLUMN_CREATED_AT)),
                        lastUsed = it.getLong(it.getColumnIndexOrThrow(ClonedApp.COLUMN_LAST_USED)),
                        dataPath = it.getString(it.getColumnIndexOrThrow(ClonedApp.COLUMN_DATA_PATH)),
                        userId = it.getInt(it.getColumnIndexOrThrow(ClonedApp.COLUMN_USER_ID)),
                        accountInfo = it.getString(it.getColumnIndexOrThrow(ClonedApp.COLUMN_ACCOUNT_INFO))
                    )
                    clonedApps.add(clonedApp)
                    Log.d("DatabaseHelper", "getAllClonedApps: Added app ${clonedApp.clonedAppName} (${clonedApp.originalPackageName})")
                }
            }
        } catch (e: Exception) {
            Log.e("DatabaseHelper", "Error getting cloned apps", e)
        }
        
        Log.d("DatabaseHelper", "getAllClonedApps: Returning ${clonedApps.size} cloned apps")
        return clonedApps
    }

    /**
     * Get a cloned app by ID
     */
    fun getClonedAppById(clonedAppId: Long): ClonedApp? {
        val db = readableDatabase
        var clonedApp: ClonedApp? = null
        
        try {
            val cursor = db.query(
                ClonedApp.TABLE_NAME,
                null,
                "${ClonedApp.COLUMN_ID} = ?",
                arrayOf(clonedAppId.toString()),
                null,
                null,
                null
            )
            
            if (cursor.moveToFirst()) {
                clonedApp = ClonedApp(
                    id = cursor.getLong(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_ID)),
                    originalPackageName = cursor.getString(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_ORIGINAL_PACKAGE)),
                    clonedPackageName = cursor.getString(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_CLONED_PACKAGE)),
                    appName = cursor.getString(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_APP_NAME)),
                    clonedAppName = cursor.getString(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_CLONED_APP_NAME)),
                    iconPath = cursor.getString(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_ICON_PATH)),
                    isActive = cursor.getInt(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_IS_ACTIVE)) == 1,
                    createdAt = cursor.getLong(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_CREATED_AT)),
                    lastUsed = cursor.getLong(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_LAST_USED)),
                    dataPath = cursor.getString(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_DATA_PATH)),
                    userId = cursor.getInt(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_USER_ID)),
                    accountInfo = cursor.getString(cursor.getColumnIndexOrThrow(ClonedApp.COLUMN_ACCOUNT_INFO))
                )
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting cloned app by ID: $clonedAppId", e)
        }
        
        return clonedApp
    }

    /**
     * Update last used time for a cloned app
     */
    fun updateLastUsed(clonedAppId: Long) {
        val db = writableDatabase
        try {
            val values = ContentValues().apply {
                put(ClonedApp.COLUMN_LAST_USED, System.currentTimeMillis())
            }
            db.update(
                ClonedApp.TABLE_NAME,
                values,
                "${ClonedApp.COLUMN_ID} = ?",
                arrayOf(clonedAppId.toString())
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error updating last used time", e)
        }
    }

    /**
     * Delete a cloned app
     */
    fun deleteClonedApp(clonedAppId: Long): Boolean {
        val db = writableDatabase
        return try {
            val result = db.delete(
                ClonedApp.TABLE_NAME,
                "${ClonedApp.COLUMN_ID} = ?",
                arrayOf(clonedAppId.toString())
            )
            result > 0
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting cloned app", e)
            false
        }
    }

    /**
     * Insert usage statistics
     */
    fun insertUsageStats(stats: AppUsageStats): Long {
        val db = writableDatabase
        return try {
            val values = ContentValues().apply {
                put(AppUsageStats.COLUMN_CLONED_APP_ID, stats.clonedAppId)
                put(AppUsageStats.COLUMN_SESSION_START, stats.sessionStart)
                put(AppUsageStats.COLUMN_SESSION_END, stats.sessionEnd)
                put(AppUsageStats.COLUMN_SESSION_DURATION, stats.sessionDuration)
                put(AppUsageStats.COLUMN_MEMORY_USAGE, stats.memoryUsage)
                put(AppUsageStats.COLUMN_CPU_USAGE, stats.cpuUsage)
                put(AppUsageStats.COLUMN_NETWORK_USAGE, stats.networkUsage)
            }
            db.insert(AppUsageStats.TABLE_NAME, null, values)
        } catch (e: Exception) {
            Log.e(TAG, "Error inserting usage stats", e)
            -1L
        }
    }

    /**
     * Insert user account
     */
    fun insertUserAccount(account: UserAccount): Long {
        val db = writableDatabase
        return try {
            val values = ContentValues().apply {
                put(UserAccount.COLUMN_CLONED_APP_ID, account.clonedAppId)
                put(UserAccount.COLUMN_ACCOUNT_NAME, account.accountName)
                put(UserAccount.COLUMN_ACCOUNT_TYPE, account.accountType)
                put(UserAccount.COLUMN_LOGIN_DATA, account.loginData)
                put(UserAccount.COLUMN_IS_ACTIVE, if (account.isActive) 1 else 0)
                put(UserAccount.COLUMN_CREATED_AT, account.createdAt)
                put(UserAccount.COLUMN_LAST_LOGIN, account.lastLogin)
            }
            db.insert(UserAccount.TABLE_NAME, null, values)
        } catch (e: Exception) {
            Log.e(TAG, "Error inserting user account", e)
            -1L
        }
    }

    /**
     * Get user accounts for a cloned app
     */
    fun getUserAccounts(clonedAppId: Long): List<UserAccount> {
        val accounts = mutableListOf<UserAccount>()
        val db = readableDatabase
        
        try {
            val cursor = db.query(
                UserAccount.TABLE_NAME,
                null,
                "${UserAccount.COLUMN_CLONED_APP_ID} = ? AND ${UserAccount.COLUMN_IS_ACTIVE} = ?",
                arrayOf(clonedAppId.toString(), "1"),
                null,
                null,
                "${UserAccount.COLUMN_LAST_LOGIN} DESC"
            )
            
            cursor.use {
                while (it.moveToNext()) {
                    accounts.add(
                        UserAccount(
                            id = it.getLong(it.getColumnIndexOrThrow(UserAccount.COLUMN_ID)),
                            clonedAppId = it.getLong(it.getColumnIndexOrThrow(UserAccount.COLUMN_CLONED_APP_ID)),
                            accountName = it.getString(it.getColumnIndexOrThrow(UserAccount.COLUMN_ACCOUNT_NAME)),
                            accountType = it.getString(it.getColumnIndexOrThrow(UserAccount.COLUMN_ACCOUNT_TYPE)),
                            loginData = it.getString(it.getColumnIndexOrThrow(UserAccount.COLUMN_LOGIN_DATA)),
                            isActive = it.getInt(it.getColumnIndexOrThrow(UserAccount.COLUMN_IS_ACTIVE)) == 1,
                            createdAt = it.getLong(it.getColumnIndexOrThrow(UserAccount.COLUMN_CREATED_AT)),
                            lastLogin = it.getLong(it.getColumnIndexOrThrow(UserAccount.COLUMN_LAST_LOGIN))
                        )
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting user accounts", e)
        }
        
        return accounts
    }
}
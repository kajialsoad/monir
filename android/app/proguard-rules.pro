# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart/Flutter generated classes
-keep class **.Dart** { *; }
-keep class **.*Dart { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*

# Keep generic signatures
-keepattributes Signature

# Keep inner classes
-keepattributes InnerClasses

# Keep exception information
-keepattributes Exceptions

# Android specific
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Material Design
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# App specific classes (adjust package name as needed)
-keep class com.multispace.app.multispace_cloner.** { *; }

# Method channels
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }

# Shared Preferences
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$Editor { *; }

# SQLite
-keep class android.database.** { *; }
-keep class android.database.sqlite.** { *; }

# Crypto
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# Google Play Core (handle missing classes)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Google Error Prone annotations (handle missing classes)
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# Google Crypto Tink
-dontwarn com.google.crypto.tink.**
-keep class com.google.crypto.tink.** { *; }

# Performance optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Remove debug code
-assumenosideeffects class java.lang.System {
    public static void out.println(...);
    public static void err.println(...);
}

# Aggressive optimization for release
-repackageclasses ''
-allowaccessmodification
-mergeinterfacesaggressively

# Keep crash reporting
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# End of ProGuard rules
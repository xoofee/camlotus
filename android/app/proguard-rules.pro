# this is to solve the problem of FileProvider when install apk from app

# 12-19 16:08:45.880 17645 17645 E AndroidRuntime: java.lang.IncompatibleClassChangeError: Class 'android.content.res.XmlBlock$Parser' does not implement interface 'd5.a' in call to 'int d5.a.next ()' (declaration of 'androidx.core.content.FileProvider' appears in /data/app/~~E15_DfUG7a8HXT7D9butmg==/com.example.camlotus-w7mh6NmOhdf_xpFBH6xFog==/base.apk) 12-19 16:08:45.881 1539 1660 W ActivityTaskManager: Force finishing activity com.example.camlotus/.MainActivity

# E AndroidRuntime: java.lang.IncompatibleClassChangeError: Class 'android.content.res.XmlBlock$Parser' does not implement interface 'n4.a' in call to 'int n4.a.next()' (declaration of 'androidx.core.content.FileProvider' appears in /data/app/~~Ig6X1M9f4pJHV1qk6wF77g==/com.example.camlotus-QmP3iTbmjVNpmZanPYo_QA==/base.apk)
# 12-19 17:43:03.812 1539 2090 W ActivityTaskManager: Force finishing activity com.example.camlotus/.MainActivity

# Keep FileProvider and all its classes - prevent all obfuscation
-keep class androidx.core.content.FileProvider { *; }
-keep class androidx.core.content.FileProvider$* { *; }
-keepclassmembers class androidx.core.content.FileProvider { *; }

# Keep XML resource parser classes used by FileProvider
-keep class android.content.res.XmlBlock { *; }
-keep class android.content.res.XmlBlock$Parser { *; }
-keep interface android.content.res.XmlBlock$** { *; }
-keepclassmembers class android.content.res.XmlBlock { *; }
-keepclassmembers class android.content.res.XmlBlock$Parser { *; }

# Prevent obfuscation of interfaces that FileProvider uses
# R8 was obfuscating interfaces to 'n4.a' - prevent this
# Keep all interfaces (FileProvider uses reflection on interfaces)
-keep interface * { *; }
-keepnames interface *
# Keep names of classes that might implement these interfaces
-keepnames class android.content.res.**
-keepnames class androidx.core.content.**

# Keep FileProvider paths configuration
-keep class * extends androidx.core.content.FileProvider

# Keep AndroidX Core classes that FileProvider depends on - prevent obfuscation
-keep class androidx.core.** { *; }
-keepclassmembers class androidx.core.** { *; }
-keepnames class androidx.core.**

# Keep all classes that implement interfaces used by FileProvider
-keep class * implements android.content.res.XmlBlock$** { *; }

# Keep ProfileInstaller classes (may help with SIGBUS during profile installation)
-keep class androidx.profileinstaller.** { *; }
-keepclassmembers class androidx.profileinstaller.** { *; }

# Keep native method bindings
-keepclasseswithmembernames class * {
    native <methods>;
}


# Keep Flutter Local Notifications reflection classes and model types
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Java reflection / serialization models
-keepclassmembers class * implements java.io.Serializable { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }

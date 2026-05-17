# Keep rules for flutter_local_notifications.
# The plugin uses reflection + Gson to schedule notifications; minified
# builds drop the referenced classes without these rules.
-keep class com.dexterous.** { *; }

# Gson reflection (used by flutter_local_notifications scheduled payloads).
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keep class * extends com.google.gson.reflect.TypeToken

# Drift / sqlite3_flutter_libs ship a native library and don't need ProGuard
# rules of their own. Defensive: keep the Drift platform interface so that
# any future reflective access from the Dart side via the platform channel
# resolves cleanly.
-keep class io.flutter.plugin.platform.** { *; }

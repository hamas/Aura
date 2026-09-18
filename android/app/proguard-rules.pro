# ============================================================================
# Aura Media Center — Production ProGuard & R8 Optimization Rules
# ============================================================================

# 1. Flutter Engine & Plugin Core
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.FlutterInjector { *; }

# Preserve native JNI methods for Flutter engine
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# 2. MediaKit & Native libmpv Bindings
-keep class com.alexmercerind.media_kit.** { *; }
-keep class com.alexmercerind.media_kit_video.** { *; }
-keep class com.alexmercerind.mediakit.** { *; }
-keep class com.alexmercerind.mediakit_video.** { *; }
-keep class * implements com.alexmercerind.mediakit.** { *; }
-keepclassmembers class com.alexmercerind.mediakit.** {
    native <methods>;
}
-dontwarn com.alexmercerind.media_kit.**
-dontwarn com.alexmercerind.media_kit_video.**
-dontwarn com.alexmercerind.mediakit.**
-dontwarn com.alexmercerind.mediakit_video.**

# 3. Firebase Auth & Google Sign-In
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# 4. JSON Serialization Models & Data Transfer Objects
-keepattributes Signature, InnerClasses, EnclosingMethod, *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Preserve Aura domain entities & models from reflection stripping
-keep class com.aura.app.aura.models.** { *; }
-keepclassmembers class * implements java.io.Serializable { *; }

# 5. General Optimization & Warning Suppression
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**

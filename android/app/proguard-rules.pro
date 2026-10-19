# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Fonts
-keep class com.google.fonts.** { *; }

# Preserve Model Classes / Enums
-keepclassmembers enum * { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Local Auth Biometrics
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Flutter Deferred Components / Play Core
-dontwarn com.google.android.play.core.**

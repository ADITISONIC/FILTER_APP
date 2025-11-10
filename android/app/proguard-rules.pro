# Ignore all warnings about missing classes
-dontwarn **

# Keep Razorpay completely
-keep class com.razorpay.** { *; }

# Keep Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep your app
-keep class com.example.filter_app.** { *; }

# Basic annotations
-keepattributes *Annotation*
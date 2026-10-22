# Flutter embedding — dibutuhkan R8 saat minifyEnabled true.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter embedding mereferensikan Play Core (deferred components) yang tidak
# dipakai aplikasi ini. Tanpa aturan ini R8 gagal: "Missing classes detected".
-dontwarn com.google.android.play.core.**

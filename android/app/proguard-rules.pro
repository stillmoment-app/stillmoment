# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in $ANDROID_HOME/tools/proguard/proguard-android.txt

# Keep Hilt classes
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }
-keep class * extends dagger.hilt.android.HiltAndroidApp { *; }

# Keep Compose classes
-keep class androidx.compose.** { *; }

# Keep data classes for serialization
-keepclassmembers class com.stillmoment.domain.models.** {
    <init>(...);
    <fields>;
}

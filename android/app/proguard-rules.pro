# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in $ANDROID_HOME/tools/proguard/proguard-android.txt

# Hilt, Compose and kotlinx.serialization ship their own consumer R8 rules.
# Do not add blanket -keep rules for them: they disable shrinking, optimization
# and obfuscation for most of the DEX code (Play Console "DEX code optimization").

# Keep data classes for serialization
-keepclassmembers class com.stillmoment.domain.models.** {
    <init>(...);
    <fields>;
}

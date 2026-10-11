# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in $ANDROID_HOME/tools/proguard/proguard-android.txt

# Hilt, Compose and kotlinx.serialization ship their own consumer R8 rules.
# Do not add blanket -keep rules for them: they disable shrinking, optimization
# and obfuscation for most of the DEX code (Play Console "DEX code optimization").

# AGP 9 R8 defaults are active (android-090):
# - strict full mode: "-keep class X" no longer keeps X's default constructor.
#   Write "-keep class X { <init>(); }" if a class is instantiated reflectively.
# - optimized resource shrinking: resources only referenced from dead code are removed.
#   Resources loaded by name (getIdentifier) would need res/raw/keep.xml (tools:keep);
#   the app has none - raw sounds are resolved via R.raw in AudioService.

# Keep data classes for serialization
-keepclassmembers class com.stillmoment.domain.models.** {
    <init>(...);
    <fields>;
}

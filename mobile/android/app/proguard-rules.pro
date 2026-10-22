# Regels voor de winkelversie (R8 verkleint en hernoemt code).
# flutter_local_notifications slaat geplande meldingen op met Gson; zonder
# deze regels gaan de typegegevens verloren en mislukt het inplannen.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*

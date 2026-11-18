# Regras para o build de release (R8 encolhe e renomeia o código).

# flutter_local_notifications: guarda as notificações agendadas com o Gson,
# que precisa dos nomes e dos tipos genéricos das classes do plugin.
-keep class com.dexterous.** { *; }

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# home_widget (widget "Palavra do dia")
-keep class es.antonborri.home_widget.** { *; }

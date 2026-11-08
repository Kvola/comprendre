# ML Kit : seule l'écriture latine est embarquée ; les autres (chinois, japonais…)
# sont facultatives et référencées par le plugin sans être présentes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Le scanner de documents et l'OCR passent par réflexion (services Google Play) :
# R8 ne doit ni renommer ni retirer leurs classes (sinon NullPointerException au démarrage du scanner).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-keep class com.google.android.gms.common.internal.** { *; }
-keep class com.google_mlkit_document_scanner.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

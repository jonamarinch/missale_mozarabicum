/// Versión de la app, elegida al construirla: `--dart-define=VARIANTE=mozarabic` para la web
/// https://mozarabic.web.app. Vacía en la app principal.
///
/// Las versiones leen los mismos datos de Firestore. Los textos llevan `ocultar_en` (versiones que no los
/// muestran en la ICAE) y `sustituir_en` (español e inglés que muestran en su lugar); el latín no cambia.
const String kVariante = String.fromEnvironment('VARIANTE');

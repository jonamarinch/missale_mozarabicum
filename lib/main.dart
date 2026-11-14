// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:missale_mozarabicum/models/app_settings.dart';
import 'package:missale_mozarabicum/services/estilos_factory.dart';
import 'package:missale_mozarabicum/screens/home_screen.dart';
import 'package:missale_mozarabicum/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de Firebase para Android, iOS y web (lib/firebase_options.dart, generado y fuera de Git)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  // Inicializar formatos de fecha para todos los idiomas que usas
  await Future.wait([
    initializeDateFormatting('es_ES'),
    initializeDateFormatting('en_US'),
    initializeDateFormatting('es'),
    initializeDateFormatting('en'),
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

// Método auxiliar para aplicar fuente según configuración (fuera de la clase)
TextStyle? _getTextStyle(TextStyle? baseStyle, {required bool useSystemFont}) {
  if (baseStyle == null) return null;
  return useSystemFont ? baseStyle : GoogleFonts.cardo(textStyle: baseStyle);
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value ?? const AppSettings();

    return MaterialApp(
      title: 'Missale Mozarabicum',
      locale: settings.locale,
      themeMode: settings.themeMode,

      // Tema claro
      theme: _buildTheme(
        brightness: Brightness.light,
        useSystemFont: settings.useSystemFont,
      ),

      // Tema oscuro
      darkTheme: _buildTheme(
        brightness: Brightness.dark,
        useSystemFont: settings.useSystemFont,
      ),

      home: HomeScreen(),
    );
  }

  ThemeData _buildTheme({
    required Brightness brightness,
    required bool useSystemFont,
  }) {
    final isDark = brightness == Brightness.dark;

    // Colores base
    final primaryColor = const Color(0xFFB8AAA1);
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFFFFBF7);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurfaceColor = isDark ? Colors.white : Colors.black87;

    // Esquema de colores
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      surface: surfaceColor,
      onSurface: onSurfaceColor,
    );

    // TextTheme base
    TextTheme textTheme;
    if (useSystemFont) {
      textTheme = brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme;
    } else {
      final baseTheme = brightness == Brightness.dark
          ? ThemeData.dark()
          : ThemeData.light();
      textTheme = GoogleFonts.cardoTextTheme(baseTheme.textTheme);
    }

    // Aplicar colores al textTheme
    textTheme = textTheme.apply(
      bodyColor: onSurfaceColor,
      displayColor: onSurfaceColor,
    );

    final theme = ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: textTheme,
      scaffoldBackgroundColor: backgroundColor,

      // AppBar personalizado
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: onSurfaceColor,
        elevation: 0,
        titleTextStyle: _getTextStyle(
          textTheme.titleLarge,
          useSystemFont: useSystemFont,
        )?.copyWith(
          color: onSurfaceColor,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: _getTextStyle(
            textTheme.labelLarge,
            useSystemFont: useSystemFont,
          ),
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: _getTextStyle(
            textTheme.labelLarge,
            useSystemFont: useSystemFont,
          ),
        ),
      ),

      // Diálogos
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        titleTextStyle: _getTextStyle(
          textTheme.headlineSmall,
          useSystemFont: useSystemFont,
        )?.copyWith(color: onSurfaceColor),
        contentTextStyle: _getTextStyle(
          textTheme.bodyMedium,
          useSystemFont: useSystemFont,
        )?.copyWith(color: onSurfaceColor),
      ),

      // Input decorations
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: onSurfaceColor.withOpacity(0.3)),
        ),
      ),
    );

    // Añadir los estilos personalizados de la app
    return theme.copyWith(
      extensions: [
        buildAppTextStyles(textTheme, isDarkMode: isDark),
      ],
    );
  }
}
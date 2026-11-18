import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'providers/teacher_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'presentation/screens/splash/animated_splash_screen.dart';

void main() async {
  // Inicializa bindings antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las variables de entorno desde el archivo .env
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        // Registramos el UserProvider y cargamos los datos guardados
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        // Registramos el ThemeProvider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Registramos el TeacherProvider y cargamos sus datos
        ChangeNotifierProvider(
            create: (_) => TeacherProvider()..loadTeacherData()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos únicamente el estado del modo oscuro
    final themeProv = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'ChemIA',
      debugShowCheckedModeBanner: false,
      theme: themeProv.isDarkMode
          ? AppTheme.getDarkTheme()
          : AppTheme.getLightTheme(),
      // AnimatedSplashScreen redirige automáticamente a Onboarding o Home
      home: const AnimatedSplashScreen(),
    );
  }
}
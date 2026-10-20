import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Importante para inicializar bindings antes de runApp
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado del modo oscuro
    final themeProv = Provider.of<ThemeProvider>(context);
    // Escuchamos si el usuario ya existe
    final userProv = Provider.of<UserProvider>(context);

    return MaterialApp(
      title: 'ChemIA',
      debugShowCheckedModeBanner: false,
      theme: themeProv.isDarkMode ? AppTheme.getDarkTheme() : AppTheme.getLightTheme(),
      // Si el usuario es null, va a Onboarding, si no, va al Home
      home: userProv.user == null ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
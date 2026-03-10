import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/supabase/supabase_config.dart';
import 'ui/pages/cuotapp_login_page.dart';

Future<void> main() async {
  // Asegurar bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Iniciar la app con un loader
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await dotenv.load(fileName: ".env");
     
      // Inicializar Supabase
      await SupabaseConfig.initialize();
  
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar pantalla de carga mientras inicializa
    if (!_isInitialized && _errorMessage == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Inicializando aplicación...'),
              ],
            ),
          ),
        ),
      );
    }

    // Mostrar error si ocurrió
    if (_errorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error de inicialización',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isInitialized = false;
                        _errorMessage = null;
                      });
                      _initialize();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // App principal
    return CuotApp();
  }
}

class CuotApp extends StatelessWidget {
  const CuotApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color kPrimaryGreen = Color(0xFF00C853);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CuotApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryGreen),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CuotAppLoginPage(),
    );
  }
}
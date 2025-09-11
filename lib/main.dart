import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rua11store_catalog_app/screens/auth/changePasswordScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'controllers/categoriesController.dart';
import 'controllers/productsController.dart';
import 'widgets/layout/appbar.dart';
import 'catalog_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Handler de mensagens em background (Mobile)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Mensagem recebida em background: ${message.notification?.title}');
}

String? fcmWebToken;

// Inicialização segura do FCM Web
Future<void> initFirebaseSafe() async {
  // Desabilita completamente o Firebase para web
  if (kIsWeb) {
    debugPrint("ℹ️ Firebase desabilitado para web - Não essencial para o app");
    return;
  }

  // Mantém apenas para mobile
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Firebase inicializado para mobile");
    }
  } catch (e) {
    debugPrint("❌ Erro ao inicializar Firebase mobile: $e");
  }
}

Future<void> initFCMSafe() async {
  // Desabilita FCM para web
  if (kIsWeb) {
    debugPrint("ℹ️ FCM desabilitado para web");
    return;
  }

  // Mantém apenas para mobile
  try {
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint("✅ Token FCM Mobile: $token");
  } catch (e) {
    debugPrint("⚠️ FCM Mobile não inicializado: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // login Firebase ou FCM
    } catch (e) {
      debugPrint("⚠️ Firebase/FCM Mobile falhou: $e");
    }
  } else {
    debugPrint("ℹ️ Firebase desabilitado no Web");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Categoriescontroller()),
        ChangeNotifierProvider(create: (_) => ProductsController()),
      ],
      child: const MyApp(), // MyApp deve conter o CatalogPage
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rua11Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          primary: Color.fromARGB(255, 76, 0, 255),
          secondary: Color(0xFF5E4B6E),
          surface: Color(0xFFF5F5F5),
          error: Colors.deepPurpleAccent,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.black,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: TextTheme(displaySmall: GoogleFonts.hahmlet(fontSize: 14)),
      ),
      home: const MyHomePage(title: 'Rua11Store'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    debugPrint("📱 Construindo MyHomePage...");
    return Scaffold(appBar: const AppBarExample(), body: CatalogPage());
  }
}

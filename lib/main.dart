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
  print('Mensagem recebida em background: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.web : null,
  );

  // Inicializa Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  if (!kIsWeb) {
    Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await _initializeFCMWeb();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Categoriescontroller()),
        ChangeNotifierProvider(create: (_) => ProductsController()),
      ],
      child: const MyApp(),
    ),
  );
}

String? fcmWebToken;

Future<void> _initializeFCMWeb() async {
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      fcmWebToken = await FirebaseMessaging.instance.getToken(
        vapidKey:
            "BIVzCDEvp452x1vdxzCEmkyS22jiTYymoOwJr-BjtTQiKeLCLGpCKlMquHg-gsooSXFfKZh4d4y47Ll0ywkjdxE",
      );
      print("Token do dispositivo Web: $fcmWebToken");
    }
  } catch (e) {
    print("erro ao solicitar permissão FCM Web: $e");
  }
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
    return Scaffold(appBar: const AppBarExample(), body: CatalogPage());
  }
}

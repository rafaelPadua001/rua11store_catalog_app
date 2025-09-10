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

// Handler de mensagens em background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    print('Mensagem recebida em background: ${message.notification?.title}');
  } catch (e) {
    print('Erro no background handler: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, s) {
    print("Erro na inicialização: $e\n$s");
  }

  // Background handler (apenas Mobile)
  //  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Permissão de notificações no Web
  if (kIsWeb) {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      print('Permissão FCM Web falhou: $e');
    }
  }

  await dotenv.load(fileName: ".env");
  final uri = Uri.base;

  String? accessToken;
  String? type;

  // Primeiro tenta ler os parâmetros do fragmento (após #)
  if (uri.fragment.isNotEmpty) {
    final params = Uri.splitQueryString(uri.fragment);
    accessToken = params['access_token'];
    type = params['type'];
  }

  // Se não encontrou no fragmento, tenta pegar nos queryParameters (após ?)
  if (accessToken == null) {
    accessToken =
        uri.queryParameters['access_token'] ?? uri.queryParameters['code'];
    type = uri.queryParameters['type'] ?? 'recovery';
  }

  Widget initialScreen = const MyHomePage(title: 'Rua11Store');

  if (type == 'recovery' && accessToken != null && accessToken.isNotEmpty) {
    initialScreen = ChangePasswordScreen(accessToken: accessToken);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Categoriescontroller()),
        ChangeNotifierProvider(create: (context) => ProductsController()),
      ],
      child: MyApp(initialScreen: initialScreen),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({
    super.key,
    this.initialScreen = const MyHomePage(title: 'Rua11Store'),
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rua11Store',
      theme: ThemeData(
        colorScheme: ColorScheme(
          primary: const Color.fromARGB(255, 76, 0, 255),
          secondary: const Color(0xFF5E4B6E),
          surface: const Color(0xFFF5F5F5),
          error: Colors.deepPurpleAccent,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.black,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: TextTheme(displaySmall: GoogleFonts.hahmlet(fontSize: 14)),
      ),
      initialRoute: '/',
      home: initialScreen,
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

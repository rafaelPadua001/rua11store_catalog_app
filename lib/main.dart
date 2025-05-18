import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'controllers/categoriesController.dart';
import 'controllers/productsController.dart';
import 'widgets/layout/appbar.dart';
import 'catalog_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Categoriescontroller()),
        ChangeNotifierProvider(create: (context) => ProductsController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rua11Store',
      theme: ThemeData(
        colorScheme: ColorScheme(
          // seedColor: Colors.white,
          primary: Color.fromARGB(255, 2, 0, 3),
          secondary: Color(0xFF5E4B6E),
          surface: Color(0xFFF5F5F5),
          error: Colors.deepPurpleAccent,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.black,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: TextTheme(
          // displayLarge: const TextStyle(
          //   fontSize: 16,
          //   fontWeight: FontWeight.bold,
          // ),
          // titleLarge: GoogleFonts.lobster(
          //   fontSize: 20,
          //   fontStyle: FontStyle.normal,
          // ),
          // bodyMedium: GoogleFonts.lobster(
          //   fontSize: 18,
          //   // fontWeight: FontWeight.bold
          // ),
          displaySmall: GoogleFonts.hahmlet(fontSize: 14),
        ),
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
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _showAgeDialog(); // chama o alerta ao iniciar o app
  }

  void _showAgeDialog() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirmação de Idade'),
              content: const Text('Você tem 18 anos ou mais?'),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red, // Cor do texto
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o diálogo
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Acesso Negado'),
                            content: const Text(
                              'Você precisa ter 18 anos ou mais para acessar este conteúdo.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // Navigator.of(context).pop();
                                  // Opcional: Fechar o app
                                  // SystemNavigator.pop(); // Para Android
                                },
                                child: const Text('Fechar'),
                              ),
                            ],
                          ),
                    );
                  },
                  child: const Text('Não'),
                ),

                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green, // Cor do texto
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o diálogo
                  },
                  child: const Text('Sim'),
                ),
              ],
            ),
      );
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarExample(),
      // appBar: AppBar(

      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,

      //   title: Text(widget.title),
      // ),
      body: CatalogPage(),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

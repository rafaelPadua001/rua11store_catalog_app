import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/main.dart';
import 'package:rua11store_catalog_app/screens/auth/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register.dart';
import 'recoveryPassword.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

//import '../../services/.register_device_token.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _StateLogin createState() => _StateLogin();
}

class _StateLogin extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) throw Exception("Usuário não encontrado após o login");

      // Obtém token apenas no mobile
      //  String? deviceToken;
      //  if (!kIsWeb) {
      //    try {
      //      deviceToken = await FirebaseMessaging.instance.getToken();
      //    } catch (e) {
      //      debugPrint("⚠️ Erro ao obter token FCM Mobile: $e");
      //    }
      //  }
      //
      //  if (deviceToken != null) {
      //    fcmWebToken = deviceToken; // Salva o token globalmente
      //    await Supabase.instance.client.from('user_devices').upsert({
      //      'user_id': user.id,
      //      'device_token': deviceToken,
      //    });
      //  }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login bem-sucedido!')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Dashboard()),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro de login: ${e.message}')));
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: EdgeInsets.all(16.0),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Demo Store',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite seu e-mail';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'E-mail inválido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite sua senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecoveryPassword(),
                        ),
                      );
                    },
                    child: Text(
                      'Recuperar senha',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Register()),
                      );
                    },
                    child: Text(
                      'Registrar-se',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _login,
                    icon: Icon(Icons.login, color: Colors.white),
                    label: Text('Login', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

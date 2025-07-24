import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/supabase_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordScreen extends StatefulWidget {
  final String accessToken;
  const ChangePasswordScreen({required this.accessToken, Key? key})
    : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _loading = true;
  bool _loadingSubmit = false;
  bool _sessionRestored = false; // controla se a sessão foi restaurada
  String? _errorMessage;

  final TextEditingController _passwordController = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _passwordController.dispose(); // evita vazamento de memória
    super.dispose();
  }

  Future<void> _restoreSession() async {
    setState(() => _loading = true);

    final code = Uri.base.queryParameters['code'];
    if (code == null) {
      setState(() {
        _errorMessage = 'Código de recuperação não encontrado';
        _loading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client.auth
          .exchangeCodeForSession(code);
      final session = response.session;

      if (session != null) {
        // Agora o SDK já tem o accessToken válido
        setState(() {
          _sessionRestored = true;
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Sessão inválida';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao restaurar sessão: $e';
        _loading = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'A senha deve ter ao menos 6 caracteres');
      return;
    }

    setState(() {
      _loadingSubmit = true;
      _errorMessage = null;
    });

    try {
      // Atualiza a senha usando o SDK, que usa o token da sessão atual
      final updateResponse = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (updateResponse.user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha atualizada com sucesso')),
        );
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() => _errorMessage = 'Erro ao atualizar senha');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro: ${e.toString()}');
    } finally {
      setState(() => _loadingSubmit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Senha')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Digite sua nova senha', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadingSubmit ? null : () => _updatePassword(),
              child:
                  _loadingSubmit
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Atualizar senha'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';

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
  bool _passwordChanged = false;
  String? _errorMessage;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    setState(() => _loading = true);
    try {
      final response =
          await Supabase.instance.client.auth.recoverSession(widget.accessToken);

      setState(() {
        _loading = false;
      });

      if (response.session == null) {
        // Sessão inválida, talvez redirecionar ou mostrar erro
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Erro ao restaurar sessão';
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
      final response =
          await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword));

      if (response.user != null) {
        if (!mounted) return;

        setState(() {
          _passwordChanged = true;
          _loadingSubmit = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha atualizada com sucesso')),
        );

        // No Web, se quiser limpar a URL, pode usar:
        if (kIsWeb) {
          // O navegador vai permanecer na mesma rota, sem recarregar
        }
      } else {
        setState(() {
          _errorMessage = 'Erro ao atualizar senha';
          _loadingSubmit = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro: ${e.toString()}';
        _loadingSubmit = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Senha')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
              onPressed: _loadingSubmit || _passwordChanged ? null : _updatePassword,
              child: _loadingSubmit
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Atualizar senha'),
            ),
            if (_passwordChanged) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MyHomePage(title: 'Rua11Store')),
                    (route) => false,
                  );
                },
                child: const Text('Voltar à página inicial'),
              ),
            ],
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

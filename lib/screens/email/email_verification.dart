import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/data/user_profile/user_profile_repository.dart';
import 'package:rua11store_catalog_app/main.dart';
import 'package:rua11store_catalog_app/screens/auth/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      // await Supabase.instance.client.auth.resendOtp(
      //   email: widget.email,
      //   type: OtpType.signup,
      // );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail de verificação reenviado!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reenviar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null && session.user.emailConfirmedAt != null) {
          timer.cancel();
          await _completeRegistration(session.user.id);
          if (mounted) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => MyApp()));
          }
        }
      } catch (e) {
        debugPrint('Erro na verificação: $e');
      }
    });
  }

  Future<void> _completeRegistration(String userId) async {
    try {
      final profileRepo = UserProfileRepository();
      // await profileRepo.createProfile(
      //   UserModel(
      //     id: Uuid().v4(), // Removido `const`
      //     userId: userId,
      //     name: '',
      //     email: widget.email,
      //     age: 0,
      //     avatarUrl: '',
      //     createdAt: DateTime.now(),
      //     updatedAt: DateTime.now(),
      //   ),
      // );
    } catch (e) {
      debugPrint('Erro ao completar registro: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifique seu e-mail')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                'Verificação de e-mail necessária',
                style: Theme.of(context).textTheme.titleLarge, // Atualizado
              ),
              const SizedBox(height: 20),
              const Text('Enviamos um link de confirmação para:'),
              Text(
                widget.email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _resendVerificationEmail,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.email),
                label: const Text('Reenviar e-mail de verificação'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  Navigator.of(
                    context,
                  ).pushReplacement(MaterialPageRoute(builder: (_) => Login()));
                },
                child: const Text('Voltar para login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rua11store_catalog_app/main.dart';
import 'package:rua11store_catalog_app/screens/email/email_verification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/user_profile/user_profile_repository.dart';
import '../../models/user.dart';
import 'login.dart';

class Register extends StatefulWidget {
  @override
  _StateRegister createState() => _StateRegister();
}

class _StateRegister extends State<Register> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = Uuid();

  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // final isWeb = kIsWeb; // Import 'package:flutter/foundation.dart'

    try {
      // 1. Validar idade
      final birthDate = DateFormat('dd/MM/yyyy').parse(_dateController.text);
      if (_calculateAge(birthDate) < 18) {
        throw Exception('Você precisa ter mais de 18 anos');
      }

      // 2. Registrar no Auth
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {'name': _nameController.text, 'age': _calculateAge(birthDate)},
      );

      // 3. Verificar se o e-mail precisa de confirmação
      if (authResponse.user?.confirmedAt == null) {
        // 4. Mostrar tela de confirmação em vez de tentar login
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Enviamos um link de confirmação para ${_emailController.text}',
            ),
            duration: Duration(seconds: 5),
          ),
        );

        // 5. Redirecionar para tela de verificação
        navigator.pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => EmailVerificationScreen(email: _emailController.text),
          ),
        );
        return;
      }

      // 6. Se o e-mail já estiver confirmado (configuração local)
      await _completeRegistration(authResponse.user!.id);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString().replaceAll('Exception:', '')}'),
          duration: Duration(seconds: 5),
        ),
      );
      debugPrint('ERRO DETALHADO: $e');
    }
  }

  Future<void> _completeRegistration(String userId) async {
    // 1. Criar perfil automaticamente via trigger (recomendado)
    // Ou usar função Edge se estiver usando Supabase Edge Functions
    final profileRepo = UserProfileRepository();

    // 2. Se não usar trigger, criar perfil manualmente
    // await profileRepo.createProfile(
    //   UserModel(
    //     id: _uuid.v4(),
    //     userId: userId,
    //     name: _nameController.text,
    //     email: _emailController.text,
    //     age: _calculateAge(DateFormat('dd/MM/yyyy').parse(_dateController.text)),
    //     avatarUrl: '',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //   ),
    // );

    // 3. Redirecionar para home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rua11Store',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nome Completo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite seu nome completo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Data de Nascimento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecione sua data de nascimento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme sua senha';
                        }
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _register,
                      icon: Icon(Icons.person_add, color: Colors.white),
                      label: Text(
                        'Registrar',
                        style: TextStyle(color: Colors.white),
                      ),
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
      ),
    );
  }
}

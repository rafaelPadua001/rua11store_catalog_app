import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rua11store_catalog_app/main.dart';
import 'package:rua11store_catalog_app/screens/email/email_verification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Register extends StatefulWidget {
  const Register({super.key});

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

    try {
      // 1. Validate birth date
      final birthDate = DateFormat('dd/MM/yyyy').parse(_dateController.text);
      final age = _calculateAge(birthDate);
      if (age < 18) {
        throw Exception('Você precisa ter mais de 18 anos');
      }

      // 2. Register in Auth
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {
          'display_name': _nameController.text, // Correct column name
          'birth_date': birthDate.toIso8601String(),
        },
      );

      // 3. Check if email needs confirmation
      if (authResponse.user?.confirmedAt == null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Enviamos um link de confirmação para ${_emailController.text}',
            ),
            duration: Duration(seconds: 5),
          ),
        );

        navigator.pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => EmailVerificationScreen(email: _emailController.text),
          ),
        );
        return;
      }

      // 4. If email is already confirmed
      await _completeRegistration(authResponse.user!, birthDate: birthDate);
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

  Future<void> _completeRegistration(
    User user, {
    required DateTime birthDate,
  }) async {
    final supabase = Supabase.instance.client;
    print(user);
    // 1. Criar perfil na tabela profile_users
    final profileResponse = await supabase.from('profile_users').insert({
      'user_id': user.id,
      'full_name':
          user.userMetadata?['display_name'] ??
          _nameController.text, // Usando fullname
      'email':
          user.email ?? user.userMetadata?['email'] ?? _emailController.text,
      'birth_date':
          user.userMetadata?['birth_date'] ?? birthDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'profile_complete': false,
      'avatar_url': null,
    });

    if (profileResponse.error != null) {
      throw Exception(
        'Falha ao criar perfil: ${profileResponse.error!.message}',
      );
    }

    // 2. Navegar para a tela inicial
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => MyApp()));
    }
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

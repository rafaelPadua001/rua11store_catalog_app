import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: AgeCheckDialog()));
}

class AgeCheckDialog extends StatelessWidget {
  const AgeCheckDialog({super.key});

  void _showAgeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // impede fechar clicando fora
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmação de Idade'),
          content: const Text('Você tem 18 anos ou mais?'),
          actions: [
            TextButton(
              onPressed: () {
                // Usuário menor de idade: bloquear acesso
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Acesso Negado'),
                        content: const Text(
                          'Você deve ter 18 anos ou mais para continuar.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Opcional: Fechar o app ou navegar para outra tela
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                );
              },
              child: const Text('Não'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Redirecionar para a página principal/autorizada
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAgeDialog(context);
    });

    return Scaffold(
      body: Center(
        child: Text(
          'Verificando idade...',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página Liberada')),
      body: const Center(child: Text('Bem-vindo(a)!')),
    );
  }
}

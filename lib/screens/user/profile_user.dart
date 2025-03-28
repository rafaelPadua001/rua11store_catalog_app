import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/user_profile/user_profile_repository.dart';
import '../../models/user.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class ProfileUserWidget extends StatefulWidget {
  final UserModel user;
  final double imageSize;
  final Color borderColor;
  final double borderWidth;

  const ProfileUserWidget({
    Key? key,
    required this.user,
    this.imageSize = 120.0,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
  }) : super(key: key);

  @override
  State<ProfileUserWidget> createState() => _ProfileUserWidgetState();
}

class _ProfileUserWidgetState extends State<ProfileUserWidget> {
  late UserModel _currentUser;
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _dateController = TextEditingController();

  DateTime? _selectedDate;

 

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadProfile();
  }

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

  Future<void> _loadProfile() async {
    
    try {
      final profile = await _profileRepo.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentUser = profile;
           print(_currentUser);
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _updateProfile(UserModel updatedUser) async {
    try {
      final result = await _profileRepo.updateProfile(updatedUser);
      if (mounted) {
        setState(() {
          _currentUser = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enviando imagem...')));

      final imageUrl = await _profileRepo.uploadAvatar(File(image.path));
      await _updateProfile(_currentUser.copyWith(avatarUrl: imageUrl));

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto atualizada com sucesso!')),
      );
    } on StorageException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de armazenamento: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: ${e.toString()}')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Alterar foto de perfil"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.camera,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text("Tirar foto"),
                  onTap: () {
                    Navigator.pop(context);
                    _handleImageSelection(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text("Escolher da galeria"),
                  onTap: () {
                    Navigator.pop(context);
                    _handleImageSelection(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _currentUser.full_name,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Nome'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    final updatedUser = _currentUser.copyWith(full_name: newName);
                    await _updateProfile(updatedUser);
                    if (!mounted) return;
                    Navigator.pop(context);
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  void _showEditEmailDialog() {
    final emailController = TextEditingController(text: _currentUser.email);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Email'),
            content: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newEmail = emailController.text.trim();
                  if (newEmail.isNotEmpty && newEmail.contains('@')) {
                    try {
                      final updatedUser = _currentUser.copyWith(
                        email: newEmail,
                      );
                      await _updateProfile(updatedUser);
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Email atualizado - verifique sua caixa de entrada para confirmar',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao atualizar email: ${e.toString()}',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

 void _showEditAgeDialog() {
  showDialog(
    context: context,
    builder: (context) {
      // Local controller to handle empty state
      final textController = TextEditingController(text: _dateController.text);
      
      return AlertDialog(
        title: const Text('Editar Data de Nascimento'),
        content: TextFormField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'Data de Nascimento',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
            hintText: 'DD/MM/AAAA',
          ),
          readOnly: true,
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            
            if (selectedDate != null) {
              textController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, selecione uma data válida'),
                  ),
                );
                return;
              }

              try {
                final birthDate = DateFormat('dd/MM/yyyy').parse(textController.text);
                
                // Verify age is at least 13 years
                final age = DateTime.now().difference(birthDate).inDays ~/ 365;
                if (age < 18) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Você deve ter pelo menos 83 anos'),
                    ),
                  );
                  return;
                }

                final updatedUser = _currentUser.copyWith(
                  birthDate: birthDate,
                );
print('MEeeerda');
                await _updateProfile(updatedUser);
                
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data de nascimento atualizada com sucesso'),
                  ),
                );
              } on FormatException {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formato de data inválido. Use DD/MM/AAAA'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao atualizar: ${e.toString()}'),
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProfileImage(context),
                const SizedBox(height: 24),
                _buildUserInfo(),
                // const SizedBox(height: 32),
                // _buildEditButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: widget.imageSize,
          height: widget.imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.borderColor,
              width: widget.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child:
                (_currentUser.avatarUrl?.isNotEmpty ?? false)
                    ? CachedNetworkImage(
                      imageUrl: _currentUser.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => _buildDefaultAvatar(),
                    )
                    : _buildDefaultAvatar(),
          ),
        ),
        _buildUploadButton(),
      ],
    );
  }

  Widget _buildUploadButton() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
            ],
          ),
          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.person,
          size: widget.imageSize * 0.6,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
  // Obtém o usuário autenticado do Supabase
  final authUser = Supabase.instance.client.auth.currentUser;
  
  // Define o nome a ser exibido
  final displayName = authUser?.userMetadata?['display_name']?.toString() ?? 
                    // _currentUser.display_name ?? 
                    _currentUser.full_name;

  // Define o email a ser exibido
  final email = authUser?.email ?? _currentUser.email;

  return Column(
    children: [
      // Linha com nome e ícone de edição
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayName, // Usa o nome definido acima
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showEditNameDialog(),
            child: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      // Linha com email e ícone de edição
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            email, // Usa o email definido acima
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showEditEmailDialog(),
            child: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _buildAgeUser(context),
    ],
  );
}

  Widget _buildAgeUser(BuildContext context) {
  // Função para calcular a idade a partir da data de nascimento
  int? calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  final age = calculateAge(_currentUser.birthDate);
  final ageText = age != null ? '$age anos' : '18+';

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        ageText,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => _showEditAgeDialog(),
        child: const Icon(
          Icons.edit_outlined,
          size: 16,
          color: Colors.blue,
        ),
      ),
    ],
  );
}

  // Widget _buildEditButton(BuildContext context) {
  //   return ElevatedButton(
  //     onPressed: () {
  //       // Implementar navegação para tela de edição
  //     },
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: Theme.of(context).primaryColor,
  //       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //     ),
  //     child: const Text('Editar Perfil', style: TextStyle(fontSize: 16, color: Colors.white)),
  //   );
  // }
}

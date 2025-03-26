import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user.dart';

class ProfileUserWidget extends StatelessWidget {
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

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Alterar foto de perfil"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera),
                  title: Text("Tirar foto"),
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar captura de foto
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text("Escolher da galeria"),
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar seleção da galeria
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile user')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Widget de imagem com tratamento de erro
            _buildProfileImage(context),
            const SizedBox(height: 20),
            // Informações do usuário
            _buildUserInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Container da imagem de perfil
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: ClipOval(
            child:
                user.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: user.imageUrl,
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

        // Botão de upload
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              _showImageSourceDialog(context);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.0),
              ),
              child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Icon(Icons.person, size: imageSize * 0.6, color: Colors.grey[400]),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          user.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          user.email,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text('${user.age} anos', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

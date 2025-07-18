import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/controllers/commentsController.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentBottomSheet extends StatefulWidget {
  final String userName;
  final String avatarUrl;
  final int productId;
  const CommentBottomSheet({
    Key? key,
    required this.userName,
    required this.avatarUrl,
    required this.productId,
  }) : super(key: key);

  @override
  _CommentBottomSheetState createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final supabase = Supabase.instance.client;

  String? userName;
  String? avatarUrl;
  User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _onSave() async {
    String comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    final controller = Commentscontroller();
    final success = await controller.saveComment(
      comment: comment,
      userId: Supabase.instance.client.auth.currentUser!.id,
      userName: userName ?? 'Sem Nome',
      avatarUrl: avatarUrl ?? '',
      productId: widget.productId.toString(),
    );

    if (success) {
      Navigator.pop(context, {
        'id': 0, // se você tiver o id real, coloque aqui
        'comment': comment,
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'user_name': userName ?? 'Sem Nome',
        'avatar_url': avatarUrl ?? '',
        'product_id': widget.productId,
        'status': 'pendente',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      // trate erro de salvar comentário aqui, se quiser
    }
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      //user not logged
      setState(() {
        currentUser = null;
        userName = 'Usuário desconhecido';
        avatarUrl = '';
        isLoading = false;
      });
      return;
    }

    try {
      final response =
          await supabase
              .from('user_profiles')
              .select('full_name, avatar_url')
              .eq('user_id', user.id)
              .single();

      setState(() {
        currentUser = user;
        userName = response['full_name'] ?? 'Sem Nome';
        avatarUrl = response['avatar_url'] ?? '';
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        currentUser = user;
        userName = 'Unknown';
        avatarUrl = '';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Carregando usuário...'),
            ],
          ),
        ),
      );
    }

    if (currentUser == null) {
      return Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Wrap(
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'You have logged to comment.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            _buildAvatarUser(),
            const SizedBox(width: 16),
            _buildTextField(),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarUser() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage:
              avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
          child:
              (avatarUrl == null || avatarUrl!.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
        ),
        _buildUserName(),
      ],
    );
  }

  Widget _buildUserName() {
    return Expanded(
      child: Text(
        userName ?? 'unknown',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _commentController,
      maxLines: 5,
      minLines: 3,
      decoration: const InputDecoration(
        hintText: "Write your comment...",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: _onCancel, child: const Text('Cancel')),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }
}

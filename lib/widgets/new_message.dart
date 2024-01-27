import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() {
    return _NewMessageState();
  }
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    if (enteredMessage.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    _messageController.clear();

    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // print(userData.data());

    FirebaseFirestore.instance.collection('chat').add({
      'text': enteredMessage,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'userName': userData.data()!['username'],
      'userImage': userData.data()!['image_url'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 10, bottom: 14),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: Theme.of(context).colorScheme.background),
            autocorrect: true,
            enableSuggestions: true,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Message...',
              contentPadding: const EdgeInsetsDirectional.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(24),
                  ),
                  borderSide: BorderSide.none),
              fillColor:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              filled: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.all(12),
          ),
          onPressed: _submitMessage,
          icon: const Icon(Icons.send),
        )
      ]),
    );
  }
}

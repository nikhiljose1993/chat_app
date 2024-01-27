// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredUsername = '';
  var _enteredPassword = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || !_isLogin && _selectedImage == null) {
      // show error
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        final userLoginCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        final userSignupCredentials =
            await _firebase.createUserWithEmailAndPassword(
                email: _enteredEmail, password: _enteredPassword);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userSignupCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userSignupCredentials.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _isAuthenticating = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Autheticaton failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(10),
      ),
      borderSide: BorderSide(
        width: 1,
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              margin: const EdgeInsets.only(
                top: 30,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              child: Image.asset(
                'assets/images/chat.png',
                width: 250,
                height: 250,
              ),
            ),

            // Form card

            Card(
              margin: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    // autovalidateMode: AutovalidateMode.onUserInteraction,
                    key: _form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (!_isLogin)
                        UserImagePicker(
                          onPickImage: (pickedImage) {
                            _selectedImage = pickedImage;
                          },
                        ),
                      // Email input

                      TextFormField(
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            border: inputBorder,
                            isDense: true,
                            labelText: 'Email Address'),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          const pattern =
                              r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$";
                          final regex = RegExp(pattern);

                          return value == null ||
                                  value.trim().isEmpty ||
                                  !regex.hasMatch(value)
                              ? 'Enter a valid email address'
                              : null;
                        },
                        onSaved: (newValue) {
                          _enteredEmail = newValue!;
                        },
                      ),

                      const SizedBox(height: 12),
                      // Username input
                      if (!_isLogin)
                        TextFormField(
                          decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              border: inputBorder,
                              isDense: true,
                              labelText: 'User Name'),
                          enableSuggestions: false,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length < 4) {
                              return 'Please enter at least 4 characters.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredUsername = value!;
                          },
                        ),

                      if (!_isLogin) const SizedBox(height: 12),

                      // Password input

                      TextFormField(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          labelText: 'Password',
                          border: inputBorder,
                          isDense: true,
                        ),
                        obscureText: true,
                        validator: (value) {
                          return value == null || value.trim().length < 6
                              ? 'Password must be at least 6 characters long'
                              : null;
                        },
                        onSaved: (newValue) {
                          _enteredPassword = newValue!;
                        },
                      ),

                      const SizedBox(height: 12),
                      // Buttons
                      if (_isAuthenticating) const CircularProgressIndicator(),
                      if (!_isAuthenticating)
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer),
                          child: Text(_isLogin ? 'Login' : 'Signup'),
                        ),
                      if (!_isAuthenticating)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                            _form.currentState!.reset();
                            FocusScope.of(context).unfocus();
                          },
                          child: Text(_isLogin
                              ? 'Create an account'
                              : 'I already have an account'),
                        )
                    ]),
                  ),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}

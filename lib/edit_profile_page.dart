import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _farmNameCtrl = TextEditingController();
  File? _selectedImage;
  String? _imageUrl;
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  Future<void> _loadUserData() async {
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = userDoc.data() ?? {};
    final farmQuery =
        await FirebaseFirestore.instance
            .collection('farms')
            .where('sellerId', isEqualTo: user.uid)
            .limit(1)
            .get();
    final farmName =
        farmQuery.docs.isNotEmpty ? farmQuery.docs.first['farmName'] : '';
    setState(() {
      _usernameCtrl.text = data['username'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _localityCtrl.text = data['locality'] ?? '';
      _farmNameCtrl.text = farmName ?? '';
      _imageUrl = data['profileImage'];
    });
  }

  Future<void> _pickImage() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img != null) setState(() => _selectedImage = File(img.path));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorPickingImage(e.toString()))),
      );
    }
  }

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? imageUrl = _imageUrl;
    if (_selectedImage != null) {
      try {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_images/${user.uid}_profile_image.jpg',
        );
        final task = await ref.putFile(_selectedImage!);
        imageUrl = await task.ref.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorUploadingProfileImage(e.toString()))),
        );
        return;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'username': _usernameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'locality': _localityCtrl.text.trim(),
            'profileImage': imageUrl,
          });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.profileUpdatedSuccess)));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorSavingProfile(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF48F8F),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF48F8F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              icon: const Icon(Icons.language, color: Colors.white),
              value: localeProv.locale,
              items:
                  AppLocalizations.supportedLocales
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(
                            l.languageCode.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (locale) {
                if (locale != null) {
                  localeProv.setLocale(locale);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _animatedFadeSlide(
                0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_imageUrl != null
                                      ? NetworkImage(_imageUrl!)
                                      : null)
                                  as ImageProvider?,
                      child:
                          _selectedImage == null && _imageUrl == null
                              ? const Icon(
                                Icons.account_circle,
                                size: 80,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _animatedFadeSlide(
                1,
                child: _buildField(
                  loc.usernameLabel,
                  _usernameCtrl,
                  loc.errorEmptyField,
                ),
              ),
              _animatedFadeSlide(
                2,
                child: _buildField(
                  loc.emailLabel,
                  _emailCtrl,
                  loc.errorEmptyField,
                ),
              ),
              _animatedFadeSlide(
                3,
                child: _buildField(
                  loc.phoneLabel,
                  _phoneCtrl,
                  loc.errorEmptyField,
                ),
              ),
              _animatedFadeSlide(
                4,
                child: _buildField(
                  loc.localityLabel,
                  _localityCtrl,
                  loc.errorEmptyField,
                ),
              ),
              _animatedFadeSlide(
                5,
                child: _buildField(
                  loc.farmNameLabel,
                  _farmNameCtrl,
                  loc.errorEmptyField,
                ),
              ),
              const SizedBox(height: 20),
              _animatedFadeSlide(
                6,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(loc.saveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String errorMsg,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 16)),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.edit, color: Colors.black),
          ),
          validator: (v) => v == null || v.isEmpty ? errorMsg : null,
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _animatedFadeSlide(int index, {required Widget child}) {
    return AnimatedSlide(
      offset: _animate ? Offset.zero : const Offset(0, 0.3),
      duration: Duration(milliseconds: 300 + index * 100),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _animate ? 1 : 0,
        duration: Duration(milliseconds: 300 + index * 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: child,
        ),
      ),
    );
  }
}

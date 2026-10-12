import 'dart:io';
import 'package:bloggers/Components/round_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Postscreen extends StatefulWidget {
  final Map<String, dynamic>? existingPost;
  const Postscreen({super.key, this.existingPost});

  @override
  State<Postscreen> createState() => _PostscreenState();
}

class _PostscreenState extends State<Postscreen> {
  File? _image;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  final supabase = Supabase.instance.client;

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  bool isUploading = false;
  bool _isPrivate = false;

  bool get isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      titleController.text = widget.existingPost!['title'] ?? '';
      descriptionController.text = widget.existingPost!['description'] ?? '';
      _isPrivate = widget.existingPost!['is_private'] ?? false;
      _existingImageUrl = widget.existingPost!['image_url'];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _savePost() async {
    if (_image == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      String imageUrl = _existingImageUrl ?? '';

      if (_image != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('Blogimages').upload(fileName, _image!);
        imageUrl = supabase.storage.from('Blogimages').getPublicUrl(fileName);
      }

      if (isEditing) {
        await supabase.from('posts').update({
          'title': titleController.text,
          'description': descriptionController.text,
          'image_url': imageUrl,
          'is_private': _isPrivate,
        }).eq('id', widget.existingPost!['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new post
        await supabase.from('posts').insert({
          'title': titleController.text,
          'description': descriptionController.text,
          'image_url': imageUrl,
          'is_private': _isPrivate,
          'user_id': supabase.auth.currentUser?.id,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post uploaded successfully!')),
          );
          setState(() {
            _image = null;
            titleController.clear();
            descriptionController.clear();
            _isPrivate = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: SizedBox(
            height: 120,
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                  child: const ListTile(
                    leading: Icon(Icons.camera),
                    title: Text('Camera'),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                  child: const ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Gallery'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEB740C),
        title: Text(
          isEditing ? 'Edit Blog' : 'Upload Blogs',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceDialog(context),
                  child: Container(
                    height: MediaQuery.of(context).size.height * .2,
                    width: MediaQuery.of(context).size.width * 1,
                    child: _image != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _image!.absolute,
                        height: MediaQuery.of(context).size.height * .2,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                        : (_existingImageUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _existingImageUrl!,
                        height: MediaQuery.of(context).size.height * .2,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 100,
                      height: 100,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.blue,
                      ),
                    )),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      keyboardType: TextInputType.text,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter Post Title',
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                        labelStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: descriptionController,
                      keyboardType: TextInputType.text,
                      minLines: 1,
                      maxLines: 100,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter Post Description',
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                        labelStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: _isPrivate,
                      onChanged: (value) {
                        setState(() {
                          _isPrivate = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFEB740C),
                      title: const Text('Make this post private'),
                      subtitle: const Text(
                        'Only you will be able to see this post',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    isUploading
                        ? const CircularProgressIndicator(color: Color(0xFFEB740C))
                        : RoundButton(
                      title: isEditing ? 'Update' : 'Upload',
                      onPress: _savePost,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
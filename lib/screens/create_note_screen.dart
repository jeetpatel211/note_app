import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notes_app/core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final titleController = TextEditingController();
  final QuillController quillController = QuillController.basic();
  final FocusNode editorFocuseNode = FocusNode();
  String selectedCategory = "Personal";

  bool isLoading = false;

  Future<void> createNote() async {
    final content = jsonEncode(quillController.document.toDelta().toJson());

    final plainText = quillController.document.toPlainText();

    if (titleController.text.trim().isEmpty ||
        quillController.document.isEmpty()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields")));

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/notes"),

        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },

        body: jsonEncode({
          "title": titleController.text.trim(),
          "content": content,
          "category": selectedCategory,
        }),
      );

      print(response.statusCode);
      print(response.body);
      // print("TOKEN => $token");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));

      print("Create Note Error: $e");
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.black),
        ),

        title: Text(
          "Create Note",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: isLoading ? null : createNote,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.blue.shade800,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.check, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),

      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.blue.shade800,
      //   foregroundColor: Colors.white,

      //   onPressed: isLoading ? null : createNote,

      //   child: isLoading
      //       ? CircularProgressIndicator(color: Colors.white)
      //       : Icon(Icons.check),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,

                decoration: InputDecoration(
                  hintText: "Title",
                  border: InputBorder.none,

                  hintStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 20),

              DropdownButtonFormField(
                value: selectedCategory,

                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),

                items: ["Work", "Personal", "Ideas", "Travel"].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),

              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,

                    children: [
                      QuillSimpleToolbar(
                        controller: quillController,
                        config: QuillSimpleToolbarConfig(
                          showUndo: true,
                          showRedo: true,
                        ),
                      ),
                      // Icon(Icons.format_bold),
                      // Icon(Icons.format_italic),
                      // Icon(Icons.format_list_bulleted),
                      // Icon(Icons.image_outlined),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(editorFocuseNode);
                },
                child: Container(
                  height: 400,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      Expanded(
                        child: QuillEditor.basic(
                          controller: quillController,
                          focusNode: editorFocuseNode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

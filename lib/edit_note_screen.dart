import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:notes_app/core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditNoteScreen extends StatefulWidget {
  final dynamic note;

  const EditNoteScreen({super.key, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController titleController;
  late QuillController quillController;

  String selectedCategory = "Personal";

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.note["title"]);

    selectedCategory = widget.note["category"];

    final content = jsonDecode(widget.note["content"]);

    quillController = QuillController(
      document: Document.fromJson(content),
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> updateNote() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Retrieve token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No token found");
      }

      // Prepare request
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/notes/${widget.note["_id"]}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": titleController.text.trim(),
          "content": jsonEncode(quillController.document.toDelta().toJson()),
          "category": selectedCategory,
        }),
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Updated Failed")));

        print("Update failed: ${response.statusCode} → ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      print("Error updating note: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF5F7FB),
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
          "Edit Note",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(8),
            child: GestureDetector(
              onTap: isLoading ? null : updateNote,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.check, color: Colors.white),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: "Title",
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            DropdownButtonFormField(
              value: selectedCategory,

              items: ["Work", "Personal", "Ideas", "Travel"].map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
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
            // Expanded(
            //   child: Container(
            //     padding: EdgeInsets.all(12),

            //     decoration: BoxDecoration(
            //       color: Colors.white,

            //       borderRadius: BorderRadius.circular(20),
            //     ),

            //     child: Column(
            //       children: [
            //         QuillSimpleToolbar(controller: quillController),

            //         Expanded(
            //           child: QuillEditor.basic(controller: quillController),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            Expanded(child: QuillEditor.basic(controller: quillController)),
          ],
        ),
      ),
    );
  }
}

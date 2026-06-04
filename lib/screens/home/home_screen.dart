import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:notes_app/core/network/api_service.dart';
import 'package:notes_app/edit_note_screen.dart';
import 'package:notes_app/providers/auth_provider.dart';
import 'package:notes_app/screens/create_note_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List notes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotes();
    // loadUser();
  }

  String selectedCategory = "All Notes";

  // Fetch Notes

  Future<void> fetchNotes() async {
    try {
      setState(() {
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      print("TOKEN => $token");

      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/notes"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("STATUS => ${response.statusCode}");
      print("BODY => ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          notes = data["notes"];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });

        print("Failed => ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      print("Fetch Notes Error => $e");
    }
  }

  // DELETE NOTE

  Future<void> deleteNote(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString("token");

    await http.delete(
      Uri.parse("${ApiService.baseUrl}/notes/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    fetchNotes();
  }

  String getPlainText(String content) {
    try {
      final decoded = jsonDecode(content);
      String text = "";

      for (var item in decoded) {
        if (item["insert"] != null) {
          text += item["insert"];
        }
      }
      return text.trim();
    } catch (e) {
      return content;
    }
  }

  String? photoUrl;

  final user = FirebaseAuth.instance.currentUser;

  // Future<void> loadUser() async {
  //   final prefs = await SharedPreferences.getInstance();

  //   final userData = prefs.getString("user");

  //   if (userData != null) {
  //     final user = jsonDecode(userData);

  //     setState(() {
  //       photoUrl = user["photoUrl"];
  //     });
  //   }
  // }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List filteredNotes = selectedCategory == "All Notes"
        ? notes
        : notes.where((note) {
            return note["category"] == selectedCategory;
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Material Notes",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.black),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null ? const Icon(Icons.person) : null,
            ),
          ),
          IconButton(
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, "/login");
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 2, 86, 155),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateNoteScreen()),
          );

          if (result == true) {
            fetchNotes();
          }
        },
        child: const Icon(Icons.add),
        // label: const Text(""),
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // SEARCH BAR
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search notes...",
                  icon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = "All Notes";
                      });
                    },
                    child: categoryChip(
                      "All Notes",
                      selectedCategory == "All Notes",
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = "Work";
                      });
                    },
                    child: categoryChip("Work", selectedCategory == "Work"),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = "Personal";
                      });
                    },
                    child: categoryChip(
                      "Personal",
                      selectedCategory == "Personal",
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = "Ideas";
                      });
                    },
                    child: categoryChip("Ideas", selectedCategory == "Ideas"),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = "Travel";
                      });
                    },
                    child: categoryChip("Travel", selectedCategory == "Travel"),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredNotes.isEmpty
                  ? const Center(child: Text("No Notes Found"))
                  : MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return noteCard(note);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget categoryChip(String title, bool active) {
    return Padding(
      padding: EdgeInsets.only(right: 10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Color.fromARGB(255, 2, 86, 155) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget noteCard(dynamic note) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,

          MaterialPageRoute(builder: (_) => EditNoteScreen(note: note)),
        );

        if (result == true) {
          fetchNotes();
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note["title"] ?? "",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () {
                        deleteNote(note["_id"]);
                      },
                      child: Text("Delete"),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),

            Text(
              getPlainText(note["content"] ?? ""),
              style: TextStyle(color: Colors.grey.shade500, height: 1.5),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    note["category"] ?? "",

                    style: TextStyle(
                      color: Colors.blue.shade200,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.push_pin_outlined, size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

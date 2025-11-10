import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileSetupPage extends StatefulWidget {
  final String uid;
  const ProfileSetupPage({super.key, required this.uid});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final aboutController = TextEditingController();

  String username = "";
  String selectedEmoji = "🙂"; // ✅ Default emoji
  bool loading = false;
final List<String> emojis = [
  "😀", "😁", "😂", "🤣", "😃", "😄",
  "😅", "😆", "😉", "😊", "😇", "🙂",
  "🙃", "😍", "🥰", "😘", "😗", "😚",
  "😙", "😋", "😛", "😜", "🤪", "😝",
  "🤑", "🤗", "🤭", "🤫", "🤔", "🤨",
  "😐", "😑", "😶", "😏", "😒", "🙄",
  "😬", "😮‍💨", "🤥", "😌", "😔", "😪",
  "🤤", "😴", "😷", "🤒", "🤕", "🤧",
  "🥵", "🥶", "🥴", "😵", "🤯", "🤠",
  "😎", "🤓", "🧐", "😕", "😟", "🙁",
  "😮", "😯", "😲", "😳", "🥺", "😢",
  "😭", "😤", "😠", "😡", "🤬", "😈",
  "👿", "🥳"
];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// ✅ Load existing username
  Future<void> loadUserData() async {
    var snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .get();

    setState(() {
      username = snap["name"] ?? "";
    });
  }

  /// ✅ Emoji Selection Popup
  void selectEmoji() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 220,
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: emojis.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() => selectedEmoji = emojis[index]);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    emojis[index],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// ✅ Save profile (emoji + details)
  Future<void> updateProfile() async {
    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.uid)
          .update({
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "about": aboutController.text.trim(),
        "profileEmoji": selectedEmoji,
      });

      /// ✅ Navigate to Role Select Page
      Navigator.pushNamed(
        context,
        '/role_select',
        arguments: {
          "uid": widget.uid,
          "name": username,
          "phone": phoneController.text.trim(),
          "address": addressController.text.trim(),
          "profileEmoji": selectedEmoji,
        },
      );
    } catch (e) {
      print("ERROR: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// ✅ Emoji Profile Avatar
            GestureDetector(
              onTap: selectEmoji,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade100,
                child: Text(
                  selectedEmoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                  labelText: "Phone Number", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                  labelText: "Address", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: aboutController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: "About You", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: loading ? null : updateProfile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save & Continue"),
            ),
          ],
        ),
      ),
    );
  }
}

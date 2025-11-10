import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileViewPage extends StatelessWidget {
  final String uid;
  const ProfileViewPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          String getValue(String key) =>
              (data[key] ?? "").toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ✅ Profile Photo
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: getValue("profileImage").isNotEmpty
                      ? NetworkImage(getValue("profileImage"))
                      : null,
                  child: getValue("profileImage").isEmpty
                      ? Icon(Icons.person, size: 60, color: Colors.grey.shade700)
                      : null,
                ),

                const SizedBox(height: 20),

                Text(
                  getValue("name"),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  getValue("email"),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Profile data card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      profileRow("Phone", getValue("phone")),
                      divider(),
                      profileRow("Address", getValue("address")),
                      divider(),
                      profileRow("About", getValue("about")),
                      divider(),
                      profileRow("Donor ID", getValue("did")),
                      divider(),
                      profileRow("Receiver ID", getValue("rid")),
                      divider(),
                      profileRow("Volunteer ID", getValue("vid")),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget profileRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "-",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget divider() {
    return Divider(
      color: Colors.grey.shade300,
      thickness: 1,
    );
  }
}

import 'package:flutter/material.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  LinearGradient getRoleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'donor':
        return const LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF28A745)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'volunteer':
        return const LinearGradient(
          colors: [Color(0xFFFF6F3C), Color(0xFFFF3D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'receiver':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(colors: [Colors.grey, Colors.grey]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Receive arguments
    final data =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};

    String uid = data["uid"] ?? "";
    String name = data["name"] ?? "";
    String phone = data["phone"] ?? "";
    String address = data["address"] ?? "";

    // ✅ Auto-generate IDs
    String did = "DONOR-$uid";
    String vid = "VOLUNTEER-$uid";
    String rid = "RECEIVER-$uid";

    final roles = [
      {
        "name": "Donor",
        "quote": "Give a little, change a lot",
        "asset": "assets/images/donor_placeholder.png",
      },
      {
        "name": "Volunteer",
        "quote": "Hands that help, hearts that shine.",
        "asset": "assets/images/volunteer_placeholder.png",
      },
      {
        "name": "Receiver",
        "quote": "Hope comes to those who reach out.",
        "asset": "assets/images/receiver_placeholder.png",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
  automaticallyImplyLeading: false,  // ✅ Removes default back arrow

  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  elevation: 0,
  
  leading: IconButton(
    icon: const Icon(Icons.person),   // ✅ Profile icon on left
    onPressed: () {
      Navigator.pushNamed(
        context,
        '/profile_view',
        arguments: uid,
      );
    },
  ),

  actions: [
    IconButton(
      icon: const Icon(Icons.exit_to_app),
      onPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      },
    ),
  ],
),


      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Choose your role",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: "Poppins",
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  final gradient = getRoleGradient(role["name"]!);

                  return GestureDetector(
                    onTap: () {
                      if (role["name"] == "Donor") {
                        Navigator.pushNamed(
                          context,
                          '/donor',
                          arguments: {
                            "did": did,
                            "name": name,
                            "phone": phone,
                            "address": address,
                          },
                        );
                      } else if (role["name"] == "Volunteer") {
                        Navigator.pushNamed(
                          context,
                          '/volunteer',
                          arguments: {
                            "vid": vid,
                            "name": name,
                            "phone": phone,
                            "address": address,
                          },
                        );
                      } else if (role["name"] == "Receiver") {
                        Navigator.pushNamed(
                          context,
                          '/receiver',
                          arguments: {
                            "receiverId": rid,
                            "receiverName": name,
                            "receiverPhone": phone,
                            "receiverAddress": address,
                          },
                        );
                      }
                    },
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      padding:
                          const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              role["asset"]!,
                              width: 70,
                              height: 70,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            role["name"]!,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            role["quote"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

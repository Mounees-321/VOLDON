import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final emailController = TextEditingController();

  bool loading = false;

  Future<void> createAccount() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();
    final cpass = confirmPasswordController.text.trim();

    if (pass != cpass) {
      showMessage("Passwords do not match!", color: Colors.red);
      return;
    }

    setState(() => loading = true);

    try {
      String uid = DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set({
        "uid": uid,
        "name": username,
        "email": email,
        "password": pass,
        "phone": "",
        "address": "",
        "about": "",
        "profileImage": "",
        "did": "DONOR-$uid",
        "rid": "RECEIVER-$uid",
        "vid": "VOLUNTEER-$uid",
        "createdAt": DateTime.now(),
      });

      showMessage("Account Created Successfully!", color: Colors.green);

      Navigator.pushNamed(
        context,
        '/profile_setup',
        arguments: uid,
      );

    } catch (e) {
      showMessage("Account creation failed: $e", color: Colors.red);
    } finally {
      setState(() => loading = false);
    }
  }

  void showMessage(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create your account",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Re-type Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : createAccount,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create Account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//////////////////////////////////////////////////////////////////////
// ✅ DONOR PAGE MAIN WRAPPER WITH 4 TABS
//////////////////////////////////////////////////////////////////////

class DonorPage extends StatelessWidget {
  const DonorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;

    final String name = args["name"];
    final String phone = args["phone"];
    final String did = args["did"];

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Donor Dashboard",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.home), text: "HOME"),
              Tab(icon: Icon(Icons.add), text: "CREATE"),
              Tab(icon: Icon(Icons.pending), text: "PENDING"),
              Tab(icon: Icon(Icons.done_all), text: "COMPLETED"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const DonorHomeScreen(),
            AddScreen(donorName: name, donorPhone: phone, did: did),
            PendingScreen(donorId: did),
            DonorCompletedPage(donorId: did),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////
// ✅ HOME SCREEN
//////////////////////////////////////////////////////////////////////

class DonorHomeScreen extends StatelessWidget {
  const DonorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Donation Categories",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        buildCategory("Food Donations", "assets/images/food.png"),
        buildCategory("Clothes Donations", "assets/images/cloth.png"),
        buildCategory("Books Donations", "assets/images/books.png"),
        buildCategory("Electronics Donations", "assets/images/electricals.jpg"),
        buildCategory("Furniture Donations", "assets/images/furniture.jpg"),
      ],
    );
  }

  Widget buildCategory(String title, String img) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(img,
              height: 180, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}

//////////////////////////////////////////////////////////////////////
// ✅ ADD DONATION PAGE
//////////////////////////////////////////////////////////////////////

class AddScreen extends StatefulWidget {
  final String donorName;
  final String donorPhone;
  final String did;

  const AddScreen(
      {super.key,
      required this.donorName,
      required this.donorPhone,
      required this.did});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();
  String? selectedCategory;
  bool saving = false;

  Future<void> createDonation() async {
    if (titleCtrl.text.isEmpty ||
        descCtrl.text.isEmpty ||
        quantityCtrl.text.isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => saving = true);

    await FirebaseFirestore.instance.collection("donations").add({
      "donorId": widget.did,
      "donorName": widget.donorName,
      "donorPhone": widget.donorPhone,
      "title": titleCtrl.text.trim(),
      "description": descCtrl.text.trim(),
      "quantity": quantityCtrl.text.trim(),
      "category": selectedCategory,
      "status": "pending",
      "receiverId": null,
      "volunteerId": null,
      "createdAt": FieldValue.serverTimestamp(),
    });

    titleCtrl.clear();
    descCtrl.clear();
    quantityCtrl.clear();
    selectedCategory = null;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Donation Added ✅")));
    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Create Donation",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
              labelText: "Title", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: descCtrl,
          decoration: const InputDecoration(
              labelText: "Description", border: OutlineInputBorder()),
          maxLines: 3,
        ),
        const SizedBox(height: 15),
        TextField(
          controller: quantityCtrl,
          decoration: const InputDecoration(
              labelText: "Quantity", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 15),
        DropdownButtonFormField(
          decoration: const InputDecoration(
              labelText: "Category", border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: "Food", child: Text("Food")),
            DropdownMenuItem(value: "Clothes", child: Text("Clothes")),
            DropdownMenuItem(value: "Books", child: Text("Books")),
            DropdownMenuItem(value: "Electronics", child: Text("Electronics")),
            DropdownMenuItem(value: "Furniture", child: Text("Furniture")),
          ],
          onChanged: (v) => selectedCategory = v,
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: saving ? null : createDonation,
          child: saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Create Donation"),
        ),
      ],
    );
  }
}

//////////////////////////////////////////////////////////////////////
// ✅ PENDING DONATIONS
//////////////////////////////////////////////////////////////////////

class PendingScreen extends StatelessWidget {
  final String donorId;

  const PendingScreen({super.key, required this.donorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("donorId", isEqualTo: donorId)
          .where("status", whereIn: [
        "pending",
        "accepted_no_volunteer",
        "accepted_need_volunteer",
        "volunteer_accepted",
        "picked",
        "delivered"
      ]).orderBy("createdAt", descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No Pending Donations"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                title: Text(data["title"]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Status: ${data['status']}"),
                    if (data["receiverName"] != null)
                      Text("Receiver: ${data['receiverName']}"),
                    if (data["volunteerName"] != null)
                      Text("Volunteer: ${data['volunteerName']}"),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DonorPendingDetailsPage(data: data),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////////////
// ✅ COMPLETED DONATIONS
//////////////////////////////////////////////////////////////////////

class DonorCompletedPage extends StatelessWidget {
  final String donorId;

  const DonorCompletedPage({super.key, required this.donorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("donorId", isEqualTo: donorId)
          .where("status", isEqualTo: "completed")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No Completed Donations"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                title: Text(data["title"]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Receiver: ${data['receiverName']}"),
                    Text("Volunteer: ${data['volunteerName']}"),
                    const Text("✅ Completed Delivery",
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DonorCompletedDetailsPage(data: data),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////////////
// ✅ FULL DETAILS → PENDING DONATION
//////////////////////////////////////////////////////////////////////

class DonorPendingDetailsPage extends StatelessWidget {
  final Map data;

  const DonorPendingDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data["title"]),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("ITEM DETAILS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Title: ${data['title']}"),
          Text("Category: ${data['category']}"),
          Text("Quantity: ${data['quantity']}"),
          Text("Description: ${data['description']}"),
          const SizedBox(height: 20),
          const Text("RECEIVER DETAILS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Name: ${data['receiverName'] ?? 'Not Assigned'}"),
          Text("Phone: ${data['receiverPhone'] ?? 'N/A'}"),
          Text("Address: ${data['receiverAddress'] ?? 'N/A'}"),
          const SizedBox(height: 20),
          const Text("VOLUNTEER DETAILS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Name: ${data['volunteerName'] ?? 'Not Assigned'}"),
          Text("Phone: ${data['volunteerPhone'] ?? 'N/A'}"),
          const SizedBox(height: 20),
          const Text("STATUS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(data['status']),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////
// ✅ FULL DETAILS → COMPLETED DONATION
//////////////////////////////////////////////////////////////////////

class DonorCompletedDetailsPage extends StatelessWidget {
  final Map data;

  const DonorCompletedDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data["title"]),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("ITEM DETAILS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Title: ${data['title']}"),
          Text("Category: ${data['category']}"),
          Text("Quantity: ${data['quantity']}"),
          Text("Description: ${data['description']}"),
          const SizedBox(height: 20),
          const Text("RECEIVER DETAILS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Name: ${data['receiverName']}"),
          Text("Phone: ${data['receiverPhone']}"),
          Text("Address: ${data['receiverAddress']}"),
          const SizedBox(height: 20),
          const Text("VOLUNTEER DETAILS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Name: ${data['volunteerName']}"),
          Text("Phone: ${data['volunteerPhone']}"),
          const SizedBox(height: 20),
          const Text("STATUS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("✅ Completed",
              style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

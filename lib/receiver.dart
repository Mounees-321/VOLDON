import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

class AppColors {
  static const primary = Colors.green;
  static const background = Colors.white;
  static const textSecondary = Colors.grey;
}

class AppStrings {
  static const receiverDashboard = "Receiver Dashboard";
  static const available = "Available";
  static const myRequests = "My Requests";
  static const noDonations = "No donations available";
  static const noRequests = "No requests available";
  static const donorInfo = "Donor Info";
  static const acceptNoVolunteer = "ACCEPT (I GET BY MYSELF)";
  static const needVolunteer = "NEED VOLUNTEER";
}

// ============================================================================
// MODELS
// ============================================================================

class ReceiverInfo {
  final String id;
  final String name;
  final String phone;
  final String address;

  const ReceiverInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });
}

class DonationData {
  final String title;
  final String category;
  final String quantity;
  final String description;
  final String donorName;
  final String donorPhone;
  final String donorAddress;
  final String status;

  DonationData({
    required this.title,
    required this.category,
    required this.quantity,
    required this.description,
    required this.donorName,
    required this.donorPhone,
    required this.donorAddress,
    required this.status,
  });

  factory DonationData.fromMap(Map<String, dynamic> map) {
    return DonationData(
      title: map['title'] ?? 'Untitled',
      category: map['category'] ?? 'N/A',
      quantity: map['quantity'] ?? 'N/A',
      description: map['description'] ?? 'No description',
      donorName: map['donorName'] ?? 'Unknown',
      donorPhone: map['donorPhone'] ?? 'N/A',
      donorAddress: map['donorAddress'] ?? 'Not available',
      status: map['status'] ?? 'pending',
    );
  }
}

// ============================================================================
// MAIN RECEIVER PAGE
// ============================================================================

class ReceiverPage extends StatelessWidget {
  final ReceiverInfo receiverInfo;

  const ReceiverPage({
    super.key,
    required this.receiverInfo,
  });

  // Legacy constructor for backward compatibility
  factory ReceiverPage.fromParams({
    required String receiverId,
    required String receiverName,
    required String receiverPhone,
    required String receiverAddress,
  }) {
    return ReceiverPage(
      receiverInfo: ReceiverInfo(
        id: receiverId,
        name: receiverName,
        phone: receiverPhone,
        address: receiverAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildTabBarView(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        AppStrings.receiverDashboard,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      bottom: const TabBar(
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: [
          Tab(text: AppStrings.available),
          Tab(text: AppStrings.myRequests),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      children: [
        AvailableDonationsTab(receiverInfo: receiverInfo),
        MyRequestsTab(receiverId: receiverInfo.id),
      ],
    );
  }
}

// ============================================================================
// AVAILABLE DONATIONS TAB
// ============================================================================

class AvailableDonationsTab extends StatelessWidget {
  final ReceiverInfo receiverInfo;

  const AvailableDonationsTab({
    super.key,
    required this.receiverInfo,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getDonationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(AppStrings.noDonations);
        }

        return _buildDonationsList(context, snapshot.data!.docs);
      },
    );
  }

  Stream<QuerySnapshot> _getDonationsStream() {
    return FirebaseFirestore.instance
        .collection("donations")
        .where("status", isEqualTo: "pending")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Widget _buildDonationsList(BuildContext context, List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = DonationData.fromMap(doc.data() as Map<String, dynamic>);
        return DonationCard(
          donationId: doc.id,
          data: data,
          receiverInfo: receiverInfo,
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Text(
        'Error: $error',
        style: const TextStyle(fontSize: 16, color: Colors.red),
      ),
    );
  }
}

// ============================================================================
// DONATION CARD WIDGET
// ============================================================================

class DonationCard extends StatelessWidget {
  final String donationId;
  final DonationData data;
  final ReceiverInfo receiverInfo;

  const DonationCard({
    super.key,
    required this.donationId,
    required this.data,
    required this.receiverInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildContent()),
              const Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.person, 'Donor: ${data.donorName}'),
        _buildInfoRow(Icons.inventory, 'Quantity: ${data.quantity}'),
        _buildInfoRow(Icons.location_on, 'Address: ${data.donorAddress}'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DonationDetailsPage(
          donationId: donationId,
          data: data,
          receiverInfo: receiverInfo,
        ),
      ),
    );
  }
}

// ============================================================================
// DONATION DETAILS PAGE
// ============================================================================

class DonationDetailsPage extends StatefulWidget {
  final String donationId;
  final DonationData data;
  final ReceiverInfo receiverInfo;

  const DonationDetailsPage({
    super.key,
    required this.donationId,
    required this.data,
    required this.receiverInfo,
  });

  @override
  State<DonationDetailsPage> createState() => _DonationDetailsPageState();
}

class _DonationDetailsPageState extends State<DonationDetailsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.data.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          _buildContent(),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Donation Details', [
            _buildDetailRow('Category', widget.data.category),
            _buildDetailRow('Quantity', widget.data.quantity),
            _buildDetailRow('Description', widget.data.description),
          ]),
          const SizedBox(height: 24),
          _buildSection(AppStrings.donorInfo, [
            _buildDetailRow('Name', widget.data.donorName),
            _buildDetailRow('Phone', widget.data.donorPhone),
            _buildDetailRow('Address', widget.data.donorAddress),
          ]),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isLoading ? null : () => _acceptDonation(true),
          child: const Text(
            AppStrings.needVolunteer,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary, width: 2),
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isLoading ? null : () => _acceptDonation(false),
          child: const Text(
            AppStrings.acceptNoVolunteer,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _acceptDonation(bool needVolunteer) async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection("donations")
          .doc(widget.donationId)
          .update({
        "status": needVolunteer ? "accepted_need_volunteer" : "accepted_no_volunteer",
        "receiverId": widget.receiverInfo.id,
        "receiverName": widget.receiverInfo.name,
        "receiverPhone": widget.receiverInfo.phone,
        "receiverAddress": widget.receiverInfo.address,
        "acceptedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation accepted successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
// ============================================================================
// ✅ MY REQUESTS TAB
// ============================================================================

class MyRequestsTab extends StatelessWidget {
  final String receiverId;

  const MyRequestsTab({super.key, required this.receiverId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("receiverId", isEqualTo: receiverId)
          .orderBy("acceptedAt", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text("No Requests Available"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            final doc = snap.data!.docs[i];
            final data = doc.data() as Map<String, dynamic>;

            return RequestCard(data: data, docId: doc.id);
          },
        );
      },
    );
  }
}
// ============================================================================
// ✅ REQUEST CARD — ABSTRACT VIEW
// ============================================================================

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const RequestCard({
    super.key,
    required this.data,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final donor = data["donorName"] ?? "Unknown";
    final donorPhone = data["donorPhone"] ?? "N/A";

    final volunteerAssigned =
        data["volunteerName"] != null && data["volunteerName"].toString().isNotEmpty;

    final volunteer = volunteerAssigned ? data["volunteerName"] : "Not Assigned";
    final volunteerPhone = volunteerAssigned ? data["volunteerPhone"] : "N/A";

    final status = data["status"] ?? "pending";

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RequestFullDetailsPage(data: data, docId: docId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Text(
                data["title"] ?? "Item",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text("Donor: $donor"),
              Text("Donor Phone: $donorPhone"),

              const SizedBox(height: 6),

              Text("Volunteer: $volunteer"),
              Text("Volunteer Phone: $volunteerPhone"),

              const SizedBox(height: 10),

              Text("Status: ${_format(status)}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 12),

              _buildButtons(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(String status) {
    switch (status) {
      case "accepted_no_volunteer":
        return ElevatedButton(
          onPressed: () {
            FirebaseFirestore.instance
                .collection("donations")
                .doc(docId)
                .update({"status": "completed"});
          },
          child: const Text("COLLECTED ✅"),
        );

      case "accepted_need_volunteer":
        return const Text("Waiting for volunteer…",
            style: TextStyle(color: Colors.orange));

      case "volunteer_accepted":
        return const Text("Volunteer Accepted ✅",
            style: TextStyle(color: Colors.blue));

      case "picked":
        return const Text("Volunteer Picked Up ✅",
            style: TextStyle(color: Colors.green));

      case "completed":
        return const Text("Completed ✅",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));

      default:
        return const SizedBox();
    }
  }

  String _format(String s) {
    return s.replaceAll("_", " ").split(" ").map(
      (e) => e[0].toUpperCase() + e.substring(1),
    ).join(" ");
  }
}
// ============================================================================
// ✅ FULL DETAILS PAGE
// ============================================================================

class RequestFullDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const RequestFullDetailsPage({
    super.key,
    required this.data,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final volunteer = data["volunteerName"] ?? "Not Assigned";
    final volunteerPhone = data["volunteerPhone"] ?? "N/A";

    return Scaffold(
      appBar: AppBar(
        title: Text(data["title"] ?? "Details"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text("ITEM: ${data['title']}"),
            Text("QUANTITY: ${data['quantity']}"),
            Text("DESCRIPTION: ${data['description']}"),

            const SizedBox(height: 20),

            const Text("DONOR DETAILS",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Name: ${data['donorName']}"),
            Text("Phone: ${data['donorPhone']}"),
            Text("Address: ${data['donorAddress']}"),

            const SizedBox(height: 20),

            const Text("VOLUNTEER DETAILS",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Name: $volunteer"),
            Text("Phone: $volunteerPhone"),

            const SizedBox(height: 20),

            Text("STATUS: ${data['status']}"),
          ],
        ),
      ),
    );
  }
}

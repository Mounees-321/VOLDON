import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
 

class MockMapPage extends StatefulWidget {
  const MockMapPage({super.key});

  @override
  State<MockMapPage> createState() => _MockMapPageState();
}

class _MockMapPageState extends State<MockMapPage> {
  LatLng volunteerLocation = const LatLng(12.9516, 80.1403);

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  Map<String, LatLng> donorPositions = {};
  Map<String, LatLng> receiverPositions = {};

  @override
  void initState() {
    super.initState();
    generateMockMarkers();
  }

  // ✅ Generate Random Nearby Coordinates
  LatLng randomNearby(LatLng base, double radius) {
    final r = Random();
    return LatLng(
      base.latitude + (r.nextDouble() - 0.5) * radius,
      base.longitude + (r.nextDouble() - 0.5) * radius,
    );
  }

  // ✅ Create 5 donor + 5 receiver markers
  void generateMockMarkers() {
    Set<Marker> temp = {};

    // ✅ Volunteer marker (Green)
    temp.add(
      Marker(
        markerId: const MarkerId("volunteer"),
        position: volunteerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: "You (Volunteer)"),
      ),
    );

    // ✅ Add donors (Red)
    for (int i = 0; i < 5; i++) {
      LatLng pos = randomNearby(volunteerLocation, 0.01);
      donorPositions["donor_$i"] = pos;

      temp.add(
        Marker(
          markerId: MarkerId("donor_$i"),
          position: pos,
          onTap: () => drawRouteForIndex(i),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: "Donor #$i (Tap to Navigate)"),
        ),
      );
    }

    // ✅ Add receivers (Blue)
    for (int i = 0; i < 5; i++) {
      LatLng pos = randomNearby(volunteerLocation, 0.01);
      receiverPositions["receiver_$i"] = pos;

      temp.add(
        Marker(
          markerId: MarkerId("receiver_$i"),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: "Receiver #$i"),
        ),
      );
    }

    setState(() => markers = temp);
  }

  // ✅ Create a straight line between donor_i → receiver_i
  void drawRouteForIndex(int i) {
    LatLng? donor = donorPositions["donor_$i"];
    LatLng? receiver = receiverPositions["receiver_$i"];

    if (donor == null || receiver == null) return;

    Set<Polyline> temp = {};

    temp.add(
      Polyline(
        polylineId: PolylineId("route_$i"),
        color: Colors.purple,
        width: 5,
        points: [
          donor,
          receiver,
        ],
      ),
    );

    setState(() {
      polylines = temp; // ✅ Replace old route
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Donors & Receivers"),
        backgroundColor: Colors.green,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: volunteerLocation,
          zoom: 14,
        ),
        markers: markers,
        polylines: polylines,
      ),
    );
  }
}


///////////////////////////////////////////////////////////////////////////////
// ✅ MAIN VOLUNTEER PAGE WITH 3 TABS
///////////////////////////////////////////////////////////////////////////////

class VolunteerPage extends StatelessWidget {
  const VolunteerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;

    final String vid = args["vid"];
    final String vname = args["name"];
    final String vphone = args["phone"];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text(
            "Volunteer Dashboard",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.volunteer_activism), text: "Available"),
              Tab(icon: Icon(Icons.delivery_dining), text: "My Pickups"),
              Tab(icon: Icon(Icons.done_all), text: "Completed"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          child: const Icon(Icons.map),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MockMapPage()),
            );
          },
        ),
        body: TabBarView(
          children: [
            VolunteerAvailablePage(vid: vid, vname: vname, vphone: vphone),
            VolunteerMyPickupsPage(vid: vid),
            VolunteerCompletedPage(vid: vid),
          ],
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////
// ✅ PAGE 1: AVAILABLE DONATIONS (NEED VOLUNTEER)
///////////////////////////////////////////////////////////////////////////////

class VolunteerAvailablePage extends StatelessWidget {
  final String vid;
  final String vname;
  final String vphone;

  const VolunteerAvailablePage({
    super.key,
    required this.vid,
    required this.vname,
    required this.vphone,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("status", isEqualTo: "accepted_need_volunteer")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text("No Requests Needing Volunteers"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  data["title"],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text("Receiver: ${data['receiverName']}"),
                    Text("Receiver Address: ${data['receiverAddress']}"),
                    const SizedBox(height: 4),
                    Text("Donor: ${data['donorName']}"),
                    Text("Donor Address: ${data['donorAddress']}"),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection("donations")
                        .doc(doc.id)
                        .update({
                      "status": "volunteer_accepted",
                      "volunteerId": vid,
                      "volunteerName": vname,
                      "volunteerPhone": vphone,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You accepted this request ✅")),
                    );
                  },
                  child: const Text("Accept"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

///////////////////////////////////////////////////////////////////////////////
// ✅ PAGE 2: MY PICKUPS
///////////////////////////////////////////////////////////////////////////////

class VolunteerMyPickupsPage extends StatelessWidget {
  final String vid;

  const VolunteerMyPickupsPage({super.key, required this.vid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("volunteerId", isEqualTo: vid)
          .where("status", whereIn: ["volunteer_accepted", "picked"])
          .snapshots(),

      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text("No Pickups Assigned"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final status = data["status"];

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data["title"],
                        style:
                            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 8),
                    Text("Receiver: ${data['receiverName']}"),
                    Text("Receiver Phone: ${data['receiverPhone']}"),
                    Text("Receiver Address: ${data['receiverAddress']}"),

                    const SizedBox(height: 8),
                    Text("Donor: ${data['donorName']}"),
                    Text("Donor Phone: ${data['donorPhone']}"),
                    Text("Donor Address: ${data['donorAddress']}"),

                    const SizedBox(height: 14),

                    if (status == "volunteer_accepted")
                      ElevatedButton(
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection("donations")
                              .doc(doc.id)
                              .update({"status": "picked"});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Item Picked ✅")),
                          );
                        },
                        child: const Text("MARK AS PICKED"),
                      ),

                    if (status == "picked")
                      ElevatedButton(
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection("donations")
                              .doc(doc.id)
                              .update({"status": "completed"});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Delivered ✅")),
                          );
                        },
                        child: const Text("MARK AS DELIVERED"),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

///////////////////////////////////////////////////////////////////////////////
// ✅ PAGE 3: COMPLETED DELIVERIES
///////////////////////////////////////////////////////////////////////////////

class VolunteerCompletedPage extends StatelessWidget {
  final String vid;

  const VolunteerCompletedPage({super.key, required this.vid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("volunteerId", isEqualTo: vid)
          .where("status", isEqualTo: "completed")
          .orderBy("createdAt", descending: true)
          .snapshots(),

      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text("No Completed Deliveries Yet"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data["title"],
                        style:
                            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 6),
                    Text("Donor: ${data['donorName']}"),
                    Text("Donor Address: ${data['donorAddress']}"),

                    const SizedBox(height: 6),
                    Text("Receiver: ${data['receiverName']}"),
                    Text("Receiver Address: ${data['receiverAddress']}"),

                    const SizedBox(height: 10),
                    const Text(
                      "✅ Completed Delivery",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

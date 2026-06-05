import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LocationFilterPage extends StatefulWidget {
  @override
  _LocationFilterPageState createState() => _LocationFilterPageState();
}

class _LocationFilterPageState extends State<LocationFilterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedState;
  String? selectedCity;

  final List<String> states = ["Assam", "Gujarat", "Maharashtra"];
  final Map<String, List<String>> cities = {
    "Assam": ["Guwahati", "Silchar", "Dibrugarh"],
    "Gujarat": ["Ahmedabad", "Surat", "Gandhinagar"],
    "Maharashtra": ["Nagpur", "Pune", "Sangli"],
  };

  Stream<QuerySnapshot> getFilteredWorkers() {
    Query query = _firestore.collection("workers");
    if (selectedState != null) {
      query = query.where('state', isEqualTo: selectedState);
    }
    if (selectedCity != null) {
      query = query.where('city', isEqualTo: selectedCity);
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.teal),
              onPressed: () => Navigator.pop(context),
              iconSize: 24,
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Filter by Location',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: Text("Select State", style: TextStyle(color: Colors.black)),
              value: selectedState,
              items:
                  states.map((state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state, style: TextStyle(color: Colors.black)),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedState = value;
                  selectedCity = null;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: Text("Select City", style: TextStyle(color: Colors.black)),
              value: selectedCity,
              items:
                  selectedState == null
                      ? []
                      : cities[selectedState!]!.map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(
                            city,
                            style: TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getFilteredWorkers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var workers = snapshot.data!.docs;
                  if (workers.isEmpty) {
                    return Center(child: Text("No workers found"));
                  }
                  return ListView.builder(
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      var worker =
                          workers[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(worker['name']),
                          subtitle: Text(
                            "${worker['city']}, ${worker['state']}",
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Apply Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

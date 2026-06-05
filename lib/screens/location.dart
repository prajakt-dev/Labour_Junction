import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class LocationSelectionPage extends StatefulWidget {
  @override
  _LocationSelectionPageState createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>(); // Form validation key

  String? selectedCity;
  String? selectedState;

  final List<String> states = ["Assam", "Gujarat", "Maharashtra"];
  final Map<String, List<String>> cities = {
    "Assam": ["Guwahati", "Silchar", "Dibrugarh"],
    "Gujarat": ["Ahmedabad", "Surat", "Gandhinagar"],
    "Maharashtra": ["Nagpur", "Pune", "Sangli"],
  };

  void saveLocation() async {
    if (_formKey.currentState!.validate()) {
      User? user = _auth.currentUser;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).update({
          'city': selectedCity,
          'state': selectedState,
        });

        // Navigate to Home Page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false, // Remove all previous pages from stack
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // Wrapping inside Form for validation
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Select your state and city.',
                  style: TextStyle(color: Colors.grey),
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
                      borderSide: BorderSide(
                        color: Colors.teal,
                        width: 2,
                      ), // Change focus color to Teal
                    ),
                    filled: true,
                    fillColor: Colors.white, // Background color of dropdown
                  ),
                  hint: Text("State"),
                  value: selectedState,
                  items:
                      states.map((state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedState = value;
                      selectedCity = null; // Reset city when state changes
                    });
                  },
                  validator:
                      (value) => value == null ? 'Please select a state' : null,
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
                      borderSide: BorderSide(
                        color: Colors.teal,
                        width: 2,
                      ), // Change focus color to Teal
                    ),
                    filled: true,
                    fillColor: Colors.white, // Background color of dropdown
                  ),
                  hint: Text("City"),
                  value: selectedCity,
                  items:
                      selectedState == null
                          ? [] // Empty list when no state is selected
                          : cities[selectedState!]!.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value;
                    });
                  },
                  validator: (value) {
                    if (selectedState == null) {
                      return 'Please select a state first';
                    }
                    if (value == null) {
                      return 'Please select a city';
                    }
                    return null;
                  },
                  disabledHint: Text(
                    "Select State first",
                  ), // Hint when disabled
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saveLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Confirm Location',
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
        ),
      ),
    );
  }
}

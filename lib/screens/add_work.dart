import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class WorkDetailsPage extends StatefulWidget {
  @override
  _WorkDetailsPageState createState() => _WorkDetailsPageState();
}

class _WorkDetailsPageState extends State<WorkDetailsPage> {
  bool _isSubmitting = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid uuid = Uuid();

  final TextEditingController _budgetController = TextEditingController(
    text: " Rs",
  );
  final TextEditingController _endingTimeController = TextEditingController(
    text: "00:00",
  );
  final TextEditingController _messageController = TextEditingController();

  String _selectedCategory = "Plumber";

  Future<void> saveJobToFirestore() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      String jobId = uuid.v4();

      await _firestore.collection('jobs').doc(jobId).set({
        "id": jobId,
        "category": _selectedCategory,
        "budget": _budgetController.text,
        "bids": 0,
        "time": _endingTimeController.text,
        "description": _messageController.text,
        "status": "Open",
        "postedBy": FirebaseAuth.instance.currentUser!.uid,
        "bookedBy": "",
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("✅ Job Added Successfully!");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Job Posted Successfully!")));

      Navigator.pushReplacementNamed(context, "/home");
    } catch (error) {
      print("❌ Error saving job: $error");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to post job.")));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  InputDecoration tealInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.teal),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.teal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.teal, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Work Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.teal[600]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Work Details Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedCategory / Urgent',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),

                  // Budget Input
                  buildDetailRow(
                    'Budget:',
                    TextField(
                      controller: _budgetController,
                      textAlign: TextAlign.right,
                      cursorColor: Colors.teal,
                      decoration: tealInputDecoration(),
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // Ending Time Input
                  buildDetailRow(
                    'Ending in:',
                    TextField(
                      controller: _endingTimeController,
                      textAlign: TextAlign.right,
                      cursorColor: Colors.teal,
                      decoration: tealInputDecoration(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _endingTimeController.text = pickedTime.format(
                              context,
                            );
                          });
                        }
                      },
                    ),
                  ),

                  SizedBox(height: 10),

                  // Category Dropdown
                  buildDetailRow(
                    'Category:',
                    DropdownButton<String>(
                      value: _selectedCategory,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                      items:
                          ['Caters', 'Plumber', 'Electrician', 'Labour'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Message Box
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    cursorColor: Colors.teal,
                    decoration: tealInputDecoration(
                      hintText: 'Your Message Here',
                    ),
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Worker Suggestion (Static Example)
            Text(
              'Worker Suggestion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Karan More',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Bid Amount: 250 Rs'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[600]),
                      SizedBox(width: 4),
                      Text('7.5(10)'),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : saveJobToFirestore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isSubmitting
                        ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDetailRow(String label, Widget child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), SizedBox(width: 12), Expanded(child: child)],
    );
  }
}

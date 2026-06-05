import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class ViewWorkPage extends StatefulWidget {
  final Map<String, dynamic> jobData;

  ViewWorkPage({required this.jobData});

  @override
  _ViewWorkPageState createState() => _ViewWorkPageState();
}

class _ViewWorkPageState extends State<ViewWorkPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.teal[600]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.jobData['category'] ?? "Job Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  "Category: ${widget.jobData['category']}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 8),
                _buildDetailRow("Budget", "${widget.jobData['budget']} Rs"),
                _buildDetailRow("Time", widget.jobData['time']),
                _buildDetailRow("Bids", widget.jobData['bids'].toString()),
                SizedBox(height: 12),
                Text(
                  "Description:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  widget.jobData['description'] ?? "No description provided.",
                ),
                SizedBox(height: 224),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _applyForJob(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                              "Book Work",
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

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$title: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _applyForJob(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      String jobPosterId = widget.jobData['postedBy'];
      String jobId = widget.jobData['id'];

      // Get user details
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
      if (!userDoc.exists) throw Exception("User data not found.");

      String firstName = userDoc["firstName"] ?? "";
      String lastName = userDoc["lastName"] ?? "";
      String phone = userDoc["phone"] ?? "";

      // Check if already booked
      QuerySnapshot existingApplications =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where("jobId", isEqualTo: jobId)
              .where("applicantId", isEqualTo: currentUserId)
              .get();

      if (existingApplications.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You have already applied for this job.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();

      // Add booking request
      DocumentReference bookingRef = firestore.collection('bookings').doc();
      batch.set(bookingRef, {
        'applicantId': currentUserId,
        'jobId': jobId,
        'jobPosterId': jobPosterId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update job details (increment bids)
      DocumentReference jobRef = firestore.collection('jobs').doc(jobId);
      batch.update(jobRef, {
        "bids": FieldValue.increment(1),
        "latestApplicant": "$firstName $lastName",
        "latestApplicantPhone": phone,
      });

      // Notify job poster
      DocumentReference notificationRef =
          firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        "receiverId": jobPosterId,
        "senderId": currentUserId,
        "message": "$firstName has applied for your job!",
        "jobId": jobId,
        "timestamp": FieldValue.serverTimestamp(),
        "read": false,
      });

      await batch.commit();

      // Fetch job poster's device token
      DocumentSnapshot jobPosterDoc =
          await firestore.collection('users').doc(jobPosterId).get();
      String? deviceToken = jobPosterDoc["deviceToken"];

      if (deviceToken != null && deviceToken.isNotEmpty) {
        await _sendNotificationToJobPoster(deviceToken, jobId, firstName);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Booking Request Sent")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to book work. Please try again.")),
      );
      print("Error booking job: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendNotificationToJobPoster(
    String deviceToken,
    String jobId,
    String senderName,
  ) async {
    final String projectId =
        "YOUR_PROJECT_ID"; // Replace with Firebase Project ID
    final String apiUrl =
        "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

    try {
      final String serviceAccountString = await rootBundle.loadString(
        'assets/service-account.json',
      );
      final serviceAccountJson = jsonDecode(serviceAccountString);

      final auth.ServiceAccountCredentials credentials = auth
          .ServiceAccountCredentials.fromJson(serviceAccountJson);
      final http.Client httpClient = http.Client();
      final auth.AutoRefreshingAuthClient authClient = await auth
          .clientViaServiceAccount(credentials, [
            'https://www.googleapis.com/auth/firebase.messaging',
          ]);

      final Map<String, dynamic> notificationData = {
        "message": {
          "token": deviceToken,
          "notification": {
            "title": "New Job Application",
            "body": "$senderName has applied for your job!",
          },
          "data": {"jobId": jobId},
        },
      };

      final response = await authClient.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(notificationData),
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent successfully.");
      } else {
        print("❌ FCM Error: ${response.statusCode} - ${response.body}");
      }

      authClient.close();
    } catch (e) {
      print("❌ Error sending notification: $e");
    }
  }
}

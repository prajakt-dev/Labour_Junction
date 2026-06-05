import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Slidebar extends StatefulWidget {
  @override
  _SlidebarState createState() => _SlidebarState();
}

class _SlidebarState extends State<Slidebar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String userName = 'User Name';
  String userLocation = 'Location';

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    if (_user == null) return;

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          String firstName = userDoc['firstName'] ?? 'User';
          String lastName = userDoc['lastName'] ?? 'Name';
          userName = '$firstName $lastName'; // Combine first & last name

          String city = userDoc['city'] ?? 'City';
          String state = userDoc['state'] ?? 'State';
          userLocation = '$city, $state';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey[100],
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 49, height: 70),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userLocation,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: Colors.black54),
            SizedBox(height: 24),

            /// Menu Items with Navigation and Logout Confirmation
            _buildMenuItem(context, Icons.person, 'Profile', '/profile'),
            _buildMenuItem(context, Icons.location_on, 'Location', '/filter'),
            _buildMenuItem(context, Icons.history, 'History', '/history'),
            _buildMenuItem(context, Icons.mail, 'Messages', '/messages'),
            _buildMenuItem(context, Icons.settings, 'Settings', '/setting'),
            _buildMenuItem(
              context,
              Icons.logout,
              'Log Out',
              '',
              isLogout: true,
            ),

            SizedBox(height: 24),
            Divider(color: Colors.black54),
            Center(
              child: Column(
                children: [
                  Text(
                    'Private Policy',
                    style: TextStyle(color: Colors.black54),
                  ),
                  Text(
                    'Copyrights @2025',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to create a menu item with navigation and logout confirmation
  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String text,
    String route, {
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isLogout) {
          _showLogoutDialog(context);
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isLogout ? Colors.red : Colors.black, size: 24),
              SizedBox(width: 16),
              Text(
                text,
                style: TextStyle(
                  color: isLogout ? Colors.red : Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout", style: TextStyle(color: Colors.black)),
          content: Text("Are you sure you want to log out?"),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text("Cancel", style: TextStyle(color: Colors.teal)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacementNamed(
                  context,
                  '/login',
                ); // Redirect to login
              },
              child: Text("Log Out", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

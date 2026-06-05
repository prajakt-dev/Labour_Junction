import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:labours/screens/history.dart';
import 'package:labours/screens/setting.dart';
import 'package:labours/screens/view_work.dart';

import '../widgets/slidebar.dart';
import 'add_work.dart';
import 'notifications.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _city = '';
  String _state = '';
  String _searchQuery = '';
  String _selectedCategory = ''; // ✅ NEW

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _fetchUserLocation();
    }
  }

  Future<void> _fetchUserLocation() async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          _city = userDoc['city'] ?? 'Unknown';
          _state = userDoc['state'] ?? 'Unknown';
        });
      }
    } catch (e) {
      print("Error fetching user location: $e");
    }
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      resizeToAvoidBottomInset: false,
      drawer: Slidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text(
              'Location',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            Text(
              '$_city, $_state',
              style: TextStyle(
                fontSize: 17,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.email, color: Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 Search Box
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.teal),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                cursorColor: Colors.teal,
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.teal),
                  hintText: 'Search',
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 16.0),

            // 📂 Categories Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = '';
                    });
                  },
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(color: Colors.teal[600]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryButton(
                    label: 'Labours',
                    isSelected: _selectedCategory == 'Labours',
                    onTap:
                        () => setState(() {
                          _selectedCategory = 'Labours';
                        }),
                  ),
                  CategoryButton(
                    label: 'Electrician',
                    isSelected: _selectedCategory == 'Electrician',
                    onTap:
                        () => setState(() {
                          _selectedCategory = 'Electrician';
                        }),
                  ),
                  CategoryButton(
                    label: 'Plumber',
                    isSelected: _selectedCategory == 'Plumber',
                    onTap:
                        () => setState(() {
                          _selectedCategory = 'Plumber';
                        }),
                  ),
                  CategoryButton(
                    label: 'Caterers',
                    isSelected: _selectedCategory == 'Caterers',
                    onTap:
                        () => setState(() {
                          _selectedCategory = 'Caterers';
                        }),
                  ),
                  CategoryButton(
                    label: 'Accountant',
                    isSelected: _selectedCategory == 'Accountant',
                    onTap:
                        () => setState(() {
                          _selectedCategory = 'Accountant';
                        }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('jobs')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("❌ Error loading jobs."));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No Jobs Available"));
                  }

                  var jobs =
                      snapshot.data!.docs.where((doc) {
                        var job = doc.data() as Map<String, dynamic>? ?? {};
                        final jobCategory =
                            job['category']?.toString().toLowerCase() ?? '';
                        final matchesSearch = jobCategory.contains(
                          _searchQuery,
                        );
                        final matchesCategory =
                            _selectedCategory.isEmpty ||
                            job['category'] == _selectedCategory;
                        return matchesSearch && matchesCategory;
                      }).toList();

                  return ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      var job = jobs[index].data() as Map<String, dynamic>;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        color: Colors.white,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12),
                          title: Text(
                            job['category'] ?? 'Unknown Category',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text("Budget: ${job['budget']} Rs"),
                              if (job['bids'] != null)
                                Text("Bids: ${job['bids']}"),
                              if (job['time'] != null)
                                Text("Time: ${job['time']}"),
                              if (job['description'] != null)
                                Text(
                                  "Description: ${job['description'].toString().length > 50 ? job['description'].toString().substring(0, 50) + '...' : job['description']}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.teal,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ViewWorkPage(jobData: job),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WorkDetailsPage()),
          );
        },
        backgroundColor: Colors.teal[600],
        child: Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: Colors.grey[500]),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.search, color: Colors.grey[500]),
                onPressed: () {},
              ),
              SizedBox(width: 48.0),
              IconButton(
                icon: Icon(Icons.swap_horiz, color: Colors.grey[500]),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => History()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.menu, color: Colors.grey[500]),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryButton({
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.grey : Colors.teal,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: Text(label),
      ),
    );
  }
}

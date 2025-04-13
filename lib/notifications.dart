import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  final String userId;
  const NotificationPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> markAllAsRead() async {
    final query = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  @override
  void initState() {
    super.initState();
    markAllAsRead(); // Mark as read on opening
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final isRead = data['isRead'] ?? false;

              return ListTile(
                leading: Icon(Icons.notifications, color: isRead ? Colors.grey : Colors.blue),
                title: Text(data['message'] ?? ''),
                subtitle: timestamp != null
                    ? Text('${timestamp.toLocal()}'.split('.')[0])
                    : null,
                tileColor: isRead ? Colors.white : Colors.blue.shade50,
              );
            },
          );
        },
      ),
    );
  }
}

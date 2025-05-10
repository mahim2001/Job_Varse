import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'job_details.dart'; // Make sure this import points to your JobDetailsPage file

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
      await doc.reference.update({'isRead': true});
    }
  }

  @override
  void initState() {
    super.initState();
    markAllAsRead();
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final String? jobId = data['jobId'];

    if (jobId != null && jobId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailsPage(jobId: jobId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications"), centerTitle: true),
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
            return const Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final isRead = data['isRead'] ?? false;
              final message = data['message'] ?? 'You have a new notification.';

              return GestureDetector(
                onTap: () => _handleNotificationTap(data),
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: isRead ? Colors.grey : Colors.green,
                    ),
                    title: Text(
                      message,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: timestamp != null
                        ? Text('${timestamp.toLocal()}'.split('.')[0])
                        : null,
                    tileColor: isRead ? Colors.white : Colors.green.shade50,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

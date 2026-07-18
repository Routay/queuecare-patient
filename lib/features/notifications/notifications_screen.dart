import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:intl/intl.dart';
import 'package:queuecare_patient/core/widgets/shimmer_loading.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifs = await LocalDatabase.instance.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifs.reversed.toList(); // Newest first
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.slateDark),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF0A0F1E)]
                : [const Color(0xFFF0FDFA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadNotifications,
            color: AppTheme.primaryTeal,
            child: _isLoading
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: List.generate(4, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShimmerLoading(width: double.infinity, height: 80, isDark: isDark, borderRadius: 16),
                    )),
                  )
                : _notifications.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Icon(Icons.notifications_none, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 16),
                          const Center(child: Text('Aucune notification pour le moment.', style: TextStyle(fontSize: 16, color: Colors.grey))),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          return _buildNotificationCard(notif, isDark);
                        },
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications, color: AppTheme.primaryTeal, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif['title'] ?? 'Notification',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Text(
                      _formatDate(notif['timestamp'] ?? ''),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notif['body'] ?? '',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

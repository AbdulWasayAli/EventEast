import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

import '../../widgets/premium_ui.dart';

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<AdminProvider>(context, listen: false).fetchFlaggedContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumScreenAppBar(
        eyebrow: 'Flagged Reports',
        title: 'Moderation Queue',
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final flaggedItems = adminProvider.flaggedGalleryItems;

          if (adminProvider.isLoading && flaggedItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (flaggedItems.isEmpty) {
            return RefreshIndicator(
              onRefresh: adminProvider.fetchFlaggedContent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 80, color: Colors.blueGrey.shade200),
                          SizedBox(height: 16),
                          Text(
                            'No Flagged Content',
                            style: TextStyle(
                              color: Colors.blueGrey.shade400,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All user content is currently clean.',
                            style: TextStyle(
                                color: Colors.blueGrey.shade300, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: adminProvider.fetchFlaggedContent,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: flaggedItems.length,
              itemBuilder: (context, index) {
                final doc = flaggedItems[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildFlaggedItem(context, adminProvider, doc.id, data);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlaggedItem(
    BuildContext context,
    AdminProvider adminProvider,
    String docId,
    Map<String, dynamic> data,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryText = isDark ? const Color(0xFFCBD5E1) : Colors.blueGrey.shade700;
    final secondaryText = isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400;
    final String imageUrl = (data['imageUrl'] ?? '').toString();
    final String caption = (data['caption'] ?? '').toString();
    final String eventId = (data['eventId'] ?? '').toString();
    final String flagReason =
        (data['flagReason'] ?? 'Reported by a user').toString();
    final String uploadedBy = (data['uploadedBy'] ?? 'Unknown').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF7F1D1D) : Colors.red.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade900.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF450A0A) : Colors.red.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red.shade700, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flagReason,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (imageUrl.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption.trim().isNotEmpty) ...[
                  Text(
                    caption,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                Text(
                  'Event ID: $eventId  •  Uploaded by: $uploadedBy',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          adminProvider.ignoreModerationItem(docId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Flag Dismissed'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey.shade600,
                          side:
                              BorderSide(color: Colors.blueGrey.shade200),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Ignore',
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final bool confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  title: Text('Delete Content?'),
                                  content: Text(
                                      'This will permanently delete this image. This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                          dialogContext, false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                          dialogContext, true),
                                      child: Text('Delete',
                                          style: TextStyle(
                                              color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          if (!confirm) return;

                          await adminProvider
                              .deleteModerationItem(docId);
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Content Deleted'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('Delete Content',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

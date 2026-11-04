import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/premium_ui.dart';


class OrganizerFeedbackScreen extends StatefulWidget {
  final String? eventId;

  const OrganizerFeedbackScreen({
    super.key,
    this.eventId,
  });

  @override
  State<OrganizerFeedbackScreen> createState() => _OrganizerFeedbackScreenState();
}

class _OrganizerFeedbackScreenState extends State<OrganizerFeedbackScreen> {
  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('feedbacks');
    if (widget.eventId != null && widget.eventId!.trim().isNotEmpty) {
      query = query.where('eventId', isEqualTo: widget.eventId);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SettingsStyleAppBar(
        title: 'Feedback & Ratings',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots() as Stream<QuerySnapshot>,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Firestore Error:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallCard(0.0, 0, [0.0, 0.0, 0.0, 0.0, 0.0]),
                  SizedBox(height: 32),
                  Text(
                    'Recent Reviews',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 40),
                  Center(
                    child: Text(
                      'No feedback received yet for this event.',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final feedbacks = snapshot.data!.docs;

          int totalReviews = feedbacks.length;
          double totalScore = 0;
          Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

          for (var doc in feedbacks) {
            final data = doc.data() as Map<String, dynamic>;
            int rating = (data['rating'] ?? 5).toInt();
            totalScore += rating;
            if (starCounts.containsKey(rating)) {
              starCounts[rating] = starCounts[rating]! + 1;
            }
          }

          double averageRating =
          totalReviews > 0 ? totalScore / totalReviews : 0.0;

          List<double> percentages = [
            totalReviews > 0 ? starCounts[5]! / totalReviews : 0.0,
            totalReviews > 0 ? starCounts[4]! / totalReviews : 0.0,
            totalReviews > 0 ? starCounts[3]! / totalReviews : 0.0,
            totalReviews > 0 ? starCounts[2]! / totalReviews : 0.0,
            totalReviews > 0 ? starCounts[1]! / totalReviews : 0.0,
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallCard(averageRating, totalReviews, percentages),
                SizedBox(height: 32),
                Text(
                  'Recent Reviews',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final feedbackData =
                    feedbacks[index].data() as Map<String, dynamic>;

                    final eventTitle =
                        feedbackData['eventTitle'] ?? 'Event';
                    final rating = (feedbackData['rating'] ?? 0).toInt();
                    final comment =
                        feedbackData['comment'] ?? 'No comment provided.';
                    final name =
                        feedbackData['userName'] ?? feedbackData['name'] ?? feedbackData['userEmail'] ?? 'Attendee';

                    return _buildReviewCard(name, eventTitle, rating, comment);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallCard(
      double averageRating, int totalReviews, List<double> percentages) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                      (index) => Icon(
                    index < averageRating.floor()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '$totalReviews Reviews',
                style: TextStyle(
                  color: Colors.blueGrey.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildRatingBar(5, percentages[0]),
                SizedBox(height: 4),
                _buildRatingBar(4, percentages[1]),
                SizedBox(height: 4),
                _buildRatingBar(3, percentages[2]),
                SizedBox(height: 4),
                _buildRatingBar(2, percentages[3]),
                SizedBox(height: 4),
                _buildRatingBar(1, percentages[4]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Row(
      children: [
        Text(
          '$stars',
          style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
      String name, String eventTitle, int rating, String comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007E7B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  eventTitle,
                  style: TextStyle(
                    color: Color(0xFF007E7B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
                  (index) => Icon(
                index < rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            comment,
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/premium_ui.dart';

class FeedbackScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const FeedbackScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  bool _isSubmitting = false;
  bool _isCheckingExisting = true;
  bool _alreadySubmitted = false;

  final TextEditingController _feedbackController = TextEditingController();

  final List<String> _quickTags = [
    'Great Venue',
    'Well Organized',
    'Amazing Speakers',
    'Good Food',
    'Needs Improvement',
    'Too Crowded',
  ];

  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _checkExistingFeedback();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
  Future<void> _checkExistingFeedback() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _isCheckingExisting = false);
      return;
    }

    try {
      final existing = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('eventId', isEqualTo: widget.eventId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (!mounted) return;

      if (existing.docs.isNotEmpty) {
        final data = existing.docs.first.data();
        setState(() {
          _alreadySubmitted = true;
          _rating = (data['rating'] is int) ? data['rating'] as int : 0;
          _feedbackController.text = (data['comment'] ?? '').toString();
          final tags = data['tags'];
          if (tags is List) {
            _selectedTags
              ..clear()
              ..addAll(tags.map((t) => t.toString()));
          }
          _isCheckingExisting = false;
        });
      } else {
        setState(() => _isCheckingExisting = false);
      }
    } catch (e) {
      debugPrint('Error checking existing feedback: $e');
      if (mounted) setState(() => _isCheckingExisting = false);
    }
  }

  Future<String> _getUserNameFromFirestore(User? user) async {
    if (user == null) {
      return 'Anonymous';
    }

    try {
      final userIdQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('UserId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userIdQuery.docs.isNotEmpty) {
        final data = userIdQuery.docs.first.data();
        final dynamic nameValue = data['Name'] ?? data['name'];
        if (nameValue != null && nameValue.toString().trim().isNotEmpty) {
          return nameValue.toString().trim();
        }
      }

      if (user.email != null) {
        final emailQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (emailQuery.docs.isNotEmpty) {
          final data = emailQuery.docs.first.data();
          final dynamic nameValue = data['Name'] ?? data['name'];
          if (nameValue != null && nameValue.toString().trim().isNotEmpty) {
            return nameValue.toString().trim();
          }
        }
      }

      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        return user.displayName!.trim();
      }

      if (user.email != null && user.email!.contains('@')) {
        return user.email!.split('@').first;
      }
    } catch (e) {
      debugPrint('Error getting user name: $e');
    }

    return 'Attendee User';
  }

  Future<void> _submitFeedback() async {
    if (_alreadySubmitted) return;

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a star rating first! ⭐'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final existing = await FirebaseFirestore.instance
            .collection('feedbacks')
            .where('eventId', isEqualTo: widget.eventId)
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _alreadySubmitted = true;
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have already submitted feedback for this event.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      final String actualUserName = await _getUserNameFromFirestore(user);

      await FirebaseFirestore.instance.collection('feedbacks').add({
        'eventId': widget.eventId,
        'eventTitle': widget.eventTitle,
        'userId': user?.uid ?? 'anonymous',
        'userName': actualUserName,
        'userEmail': user?.email ?? 'No Email',
        'rating': _rating,
        'tags': List<String>.from(_selectedTags),
        'comment': _feedbackController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your feedback! 🎉'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error submitting feedback: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit feedback: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _ratingText() {
    switch (_rating) {
      case 5:
        return 'Outstanding! 🌟';
      case 4:
        return 'Great! 😊';
      case 3:
        return 'Good 👍';
      case 2:
        return 'Fair 😐';
      case 1:
        return 'Poor 😞';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = Theme.of(context).cardColor;
    final Color textPrimary = Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87;
    final Color textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final Color dividerColor = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const PremiumScreenAppBar(
        eyebrow: 'Event review',
        title: 'Leave feedback',
      ),
      body: _isCheckingExisting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF007E7B)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Event info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _alreadySubmitted ? Icons.check_circle_rounded : Icons.event_rounded,
                    size: 40,
                    color: const Color(0xFF007E7B),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.eventTitle,
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _alreadySubmitted ? 'You already reviewed this event' : 'How was your experience?',
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),

            if (_alreadySubmitted) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007E7B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF007E7B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Feedback can only be submitted once per event. Here\'s what you sent:',
                        style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            Text(
              'Rate this event',
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
            ),

            const SizedBox(height: 16),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final int starNumber = index + 1;
                final bool selected = starNumber <= _rating;
                return GestureDetector(
                  onTap: _alreadySubmitted ? null : () => setState(() => _rating = starNumber),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      selected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: selected ? const Color(0xFFFFC107) : dividerColor,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),

            if (_rating > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _ratingText(),
                  style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),

            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Tags',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTags.map((String tag) {
                final bool isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: _alreadySubmitted ? null : () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF007E7B) : cardBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF007E7B) : dividerColor,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Additional Comments',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 5,
                readOnly: _alreadySubmitted,
                cursorColor: const Color(0xFF007E7B),
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF007E7B), width: 1.2),
                  ),
                  hintText: 'Share your experience...',
                  hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),

            const SizedBox(height: 32),
            if (!_alreadySubmitted)
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A896), Color(0xFF028090)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF028090).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Submit Feedback',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(color: textSecondary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

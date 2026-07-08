import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/review_provider.dart';
import '../../../models/review_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReviewsScreen extends ConsumerWidget {
  final String productId;
  const ReviewsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ratings & Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Ratings Overview
            reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No reviews yet. Be the first to review!',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ),
                  );
                }

                // Calculate average rating
                double avgRating = 0;
                final counts = [0, 0, 0, 0, 0];
                for (var r in reviews) {
                  avgRating += r.rating;
                  if (r.rating >= 1 && r.rating <= 5) {
                    counts[r.rating - 1]++;
                  }
                }
                avgRating /= reviews.length;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      color: context.colors.surface,
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: context.colors.primary,
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < avgRating.floor() 
                                      ? Icons.star_rounded 
                                      : (i < avgRating ? Icons.star_half_rounded : Icons.star_border_rounded),
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Based on ${reviews.length} reviews',
                                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(width: 32),
                          // Progress bars
                          Expanded(
                            child: Column(
                              children: [
                                _RatingBarRow(star: 5, percent: counts[4] / reviews.length),
                                _RatingBarRow(star: 4, percent: counts[3] / reviews.length),
                                _RatingBarRow(star: 3, percent: counts[2] / reviews.length),
                                _RatingBarRow(star: 2, percent: counts[1] / reviews.length),
                                _RatingBarRow(star: 1, percent: counts[0] / reviews.length),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Filters
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: context.colors.surface,
                      child: Row(
                        children: [
                          _FilterButton(label: 'Most Recent', isSelected: true),
                          const SizedBox(width: 8),
                          _FilterButton(label: 'Highest Rated', isSelected: false),
                          const Spacer(),
                          Icon(Icons.tune_rounded, color: context.colors.primary, size: 20),
                        ],
                      ),
                    ),

                    // Review List
                    Container(
                      color: context.colors.surface,
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: reviews.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return _ReviewCard(review: reviews[index]);
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('Error loading reviews: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.colors.primary,
        onPressed: () => context.push('/catalog/product/$productId/rate'),
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Write a Review',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _RatingBarRow extends StatelessWidget {
  final int star;
  final double percent;

  const _RatingBarRow({required this.star, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$star stars',
              style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
          SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: context.colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterButton({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? context.colors.primary : context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? context.colors.primary : context.colors.border,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? context.colors.surface : context.colors.textPrimary,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: context.colors.surface),
          ]
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.colors.primaryLight,
                child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber, 
                              size: 12
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(timeago.format(review.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: context.colors.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.text,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          // Thumbs up
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 14, color: context.colors.textHint),
              SizedBox(width: 6),
              Text('Helpful (12)',
                  style: TextStyle(fontSize: 12, color: context.colors.textHint)),
            ],
          ),
        ],
      ),
    );
  }
}







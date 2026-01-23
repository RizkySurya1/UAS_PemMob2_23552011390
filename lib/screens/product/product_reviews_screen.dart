import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductReviewsScreen extends StatelessWidget {
  final String productId;
  final String productName;

  const ProductReviewsScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Produk'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Product name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Text(
              productName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Reviews list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('productIds', arrayContains: productId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada review',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jadilah yang pertama memberikan review!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort reviews by date (newest first)
                final reviews = snapshot.data!.docs;
                reviews.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTimestamp = aData['createdAt'] as Timestamp?;
                  final bTimestamp = bData['createdAt'] as Timestamp?;
                  
                  if (aTimestamp == null) return 1;
                  if (bTimestamp == null) return -1;
                  
                  return bTimestamp.compareTo(aTimestamp);
                });

                // Calculate rating statistics
                double totalRating = 0;
                Map<int, int> ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
                
                for (var doc in reviews) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rating = (data['rating'] as num?)?.toDouble() ?? 0;
                  totalRating += rating;
                  ratingCounts[rating.round()] = (ratingCounts[rating.round()] ?? 0) + 1;
                }
                
                final averageRating = totalRating / reviews.length;

                return ListView(
                  children: [
                    // Rating summary
                    _buildRatingSummary(averageRating, reviews.length, ratingCounts),
                    const Divider(height: 1, thickness: 8),
                    
                    // Reviews
                    ...reviews.map((doc) {
                      final review = doc.data() as Map<String, dynamic>;
                      return _buildReviewCard(review);
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(
    double averageRating,
    int totalReviews,
    Map<int, int> ratingCounts,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Average rating
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalReviews review',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Rating distribution
          Expanded(
            flex: 3,
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = ratingCounts[star] ?? 0;
                final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final userName = review['userName'] ?? 'User';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final reviewText = review['review'] ?? '';
    final createdAt = review['createdAt'] as Timestamp?;
    
    String formattedDate = '';
    if (createdAt != null) {
      formattedDate = DateFormat('dd MMM yyyy').format(createdAt.toDate());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  userName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        if (formattedDate.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reviewText,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

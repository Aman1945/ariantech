import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              // Top tab section
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Other tabs
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Other tabs
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Other tabs
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Other tabs
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Other tabs
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Other tabs
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Other tabs
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Other tabs
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

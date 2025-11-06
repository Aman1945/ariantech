import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonCallanalysis extends StatelessWidget {
  const SkeletonCallanalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsetsGeometry.all(10),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 200,
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
              const SizedBox(height: 10),
              Container(
                height: 200,
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
              const SizedBox(height: 10),
              Container(
                height: 200,
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

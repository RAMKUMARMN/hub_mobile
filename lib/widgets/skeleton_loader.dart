import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final int itemCount;
  final bool isProfile;

  const SkeletonLoader({super.key, this.itemCount = 5, this.isProfile = false});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isProfile) {
      return _buildProfileSkeleton();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: _animation,
          child: Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              title: Container(
                width: double.infinity,
                height: 16,
                color: Colors.grey.shade300,
              ),
              subtitle: Container(
                width: 100,
                height: 12,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.only(top: 8, right: 100),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _animation,
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 32),
            Container(height: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Container(height: 56, color: Colors.grey.shade300),
            const SizedBox(height: 32),
            Container(height: 48, width: double.infinity, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

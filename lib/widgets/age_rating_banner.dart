import 'dart:async';
import 'package:flutter/material.dart';

class AgeRatingBanner extends StatefulWidget {
  const AgeRatingBanner({super.key});

  @override
  State<AgeRatingBanner> createState() => _AgeRatingBannerState();
}

class _AgeRatingBannerState extends State<AgeRatingBanner> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    // 3초 뒤에 사라지도록 타이머
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: _visible ? 1.0 : 0.0,
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 18, right: 18),
          child: Image.asset(
            'assets/images/rating_all.png',
            width: 80,
            height: 80,
          ),
        ),
      ),
    );
  }
}

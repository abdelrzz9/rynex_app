import 'package:flutter/material.dart';

import '../../domain/entities/local_user.dart';

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({required this.user, this.radius = 20, super.key});

  final LocalUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = user.avatarMaterialColor;
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        user.initials,
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(backgroundColor) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

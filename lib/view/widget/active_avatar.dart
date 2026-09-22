import 'package:flutter/material.dart';


class ActiveAvatar extends StatelessWidget {
  final String name;
  const ActiveAvatar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '';
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(initials),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
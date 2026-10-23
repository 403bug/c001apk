import 'package:flutter/material.dart';

Widget messageThirdCard(
  BuildContext context,
  IconData icon,
  String title,
  int? badge,
  Function() onTap,
) {
  return ListTile(
    onTap: onTap,
    leading: Icon(icon),
    title: Text(title),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      if (badge != null && badge > 0) ...[
        Badge.count(count: badge),
        const SizedBox(width: 12),
      ],
      const Icon(Icons.chevron_right),
    ]),
  );
}

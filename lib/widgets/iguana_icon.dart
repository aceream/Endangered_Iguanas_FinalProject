import 'package:flutter/material.dart';

class IguanaIcon extends StatelessWidget {
  final int classId;
  final double size;

  const IguanaIcon({
    super.key,
    required this.classId,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData();
    final colors = _getColors();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }

  IconData _getIconData() {
    const List<IconData> icons = [
      Icons.pets,
      Icons.water,
      Icons.wb_sunny,
      Icons.favorite,
      Icons.home,
      Icons.beach_access,
      Icons.terrain,
      Icons.location_on,
      Icons.cloud,
      Icons.star,
    ];
    return classId < icons.length ? icons[classId] : Icons.pets;
  }

  List<Color> _getColors() {
    switch (classId) {
      case 0:
        return [Colors.grey.shade700, Colors.black87];
      case 1:
        return [Colors.blue.shade600, Colors.cyan.shade500];
      case 2:
        return [Colors.pink.shade400, Colors.orange.shade400];
      case 3:
        return [Colors.teal.shade500, Colors.green.shade600];
      case 4:
        return [Colors.amber.shade600, Colors.brown.shade500];
      case 5:
        return [Colors.blue.shade500, Colors.teal.shade600];
      case 6:
        return [Colors.indigo.shade600, Colors.purple.shade700];
      case 7:
        return [Colors.green.shade700, Colors.teal.shade600];
      case 8:
        return [Colors.green.shade500, Colors.lime.shade600];
      case 9:
        return [Colors.purple.shade600, Colors.red.shade600];
      default:
        return [Colors.grey.shade500, Colors.grey.shade700];
    }
  }
}

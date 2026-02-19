import 'package:flutter/material.dart';
import 'package:shopping_list/models/grocery_item.dart';

class Item extends StatelessWidget {
  const Item({
    Key? key,
    required this.name,
    required this.color,
    required this.quantity,
  }) : super(key: key);

  final String name;
  final Color color;
  final int quantity;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ColoredBox(
          color: color,
          child: SizedBox(
            width: 15,
            height: 15,
          ),
        ),
        const SizedBox(
          width: 15,
        ),
        Text(name),
        const Spacer(),
        Text(quantity.toString()),
        const SizedBox(width: 15),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/widgets/item.dart';

class ItemList extends StatefulWidget {
  const ItemList({super.key});

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          for (final item in groceryItems)
            Column(
              children: [
                Item(
                  name: item.name,
                  color: item.category.color,
                  quantity: item.quantity,
                ),
                SizedBox(
                  height: 15,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

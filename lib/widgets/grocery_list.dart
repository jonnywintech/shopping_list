import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];

  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  late Box _box;

  void _loadItems() {
    try {
      _box = Hive.box('grocery_items');
      final List<GroceryItem> loadedItems = [];
      for (int i = 0; i < _box.length; i++) {
        final item = Map<String, dynamic>.from(_box.getAt(i));
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item['category'],
            )
            .value;
        loadedItems.add(
          GroceryItem(
            id: item['id'],
            name: item['name'],
            quantity: item['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load items. Please try again later.';
        _isLoading = false;
      });
    }
  }

  void _saveItems() {
    _box.clear();
    for (final item in _groceryItems) {
      _box.add({
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'category': item.category.title,
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => NewItem()));
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
    _saveItems();
  }

  void _removeItem(GroceryItem item) {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    _saveItems();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    const duration = Duration(seconds: 2);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item deleted'),
        duration: duration,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _undoRemoveItem(item, index);
          },
        ),
      ),
    );

    Timer(duration, () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  void _undoRemoveItem(GroceryItem item, int index) {
    setState(() {
      _groceryItems.insert(index, item);
    });
    _saveItems();
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  @override
  Widget build(BuildContext context) {
    Widget _content = ListView.builder(
      itemCount: _groceryItems.length,
      itemBuilder: (ctx, index) {
        return Dismissible(
          key: ValueKey(_groceryItems[index].id),
          background: Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.error.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: Theme.of(context).cardTheme.margin,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
                Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          onDismissed: (DismissDirection direction) {
            if (direction == DismissDirection.endToStart ||
                direction == DismissDirection.startToEnd) {
              _removeItem(_groceryItems[index]);
            }
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        );
      },
    );

    if (_groceryItems.isEmpty) {
      _content = const Center(
        child: Text('No items added yet.'),
      );
    }

    if (_isLoading) {
      _content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      _content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: Icon(Icons.add))],
      ),
      body: Center(
        child: _content,
      ),
    );
  }
}

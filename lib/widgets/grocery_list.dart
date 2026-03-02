import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

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

  void _loadItems() async {
    final url = Uri.https(
      'flutter-prep-56665-default-rtdb.europe-west1.firebasedatabase.app',
      'shopping-list.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to load items. Please try again later.';
          _isLoading = false;
        });
        return;
      }

      // depending of backend it gives different response when there is no data, so we need to check if it is null or not before parsing it
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(
        response.body,
      );
      final List<GroceryItem> _loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;
        _loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = _loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load items. Please try again later.';
        _isLoading = false;
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
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      'flutter-prep-56665-default-rtdb.europe-west1.firebasedatabase.app',
      'shopping-list/${item.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete item. Please try again later.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item deleted'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _undoRemoveItem(item, index);
          },
        ),
      ),
    );
  }

  void _undoRemoveItem(GroceryItem item, int index) async {
    setState(() {
      _groceryItems.insert(index, item);
    });

    final url = Uri.https(
      'flutter-prep-56665-default-rtdb.europe-west1.firebasedatabase.app',
      'shopping-list/${item.id}.json',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': item.name,
        'quantity': item.quantity,
        'category': item.category.title,
      }),
    );

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.remove(item);
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to restore item.'),
        ),
      );
    }
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/bill_dao.dart';
import '../../core/database/daos/menu_item_dao.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_text_field.dart';
import '../menu/menu_repository.dart';

class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  Map<int, int> _cartItems = {}; // itemId -> quantity
  String _discountType = 'percent'; // percent or fixed
  double _discountValue = 0;
  String _searchQuery = '';
  
  double get _subtotal {
    double total = 0;
    _cartItems.forEach((itemId, quantity) {
      final item = _cachedItems[itemId];
      if (item != null) {
        total += item.price * quantity;
      }
    });
    return total;
  }
  
  double get _discountAmount {
    if (_discountType == 'percent') {
      return _subtotal * (_discountValue / 100);
    }
    return _discountValue;
  }
  
  double get _total => _subtotal - _discountAmount;
  
  List<MenuItemsCompanion> _cachedItems = [];
  List<MenuItemsCompanion> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }
  
  Future<void> _loadItems() async {
    final dao = ref.read(menuDaoProvider);
    _cachedItems = await dao.getAll();
    _filterItems();
    setState(() {});
  }
  
  void _filterItems() {
    if (_searchQuery.isEmpty) {
      _filteredItems = _cachedItems;
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredItems = _cachedItems.where((item) {
        return item.name.toLowerCase().contains(query);
      }).toList();
    }
  }
  
  void _addToCart(int itemId) {
    setState(() {
      _cartItems[itemId] = (_cartItems[itemId] ?? 0) + 1;
    });
  }
  
  void _removeFromCart(int itemId) {
    setState(() {
      if (_cartItems.containsKey(itemId)) {
        _cartItems[itemId] = _cartItems[itemId]! - 1;
        if (_cartItems[itemId]! <= 0) {
          _cartItems.remove(itemId);
        }
      }
    });
  }
  
  void _updateQuantity(int itemId, int delta) {
    setState(() {
      final current = _cartItems[itemId] ?? 0;
      final newValue = current + delta;
      if (newValue > 0) {
        _cartItems[itemId] = newValue;
      } else {
        _cartItems.remove(itemId);
      }
    });
  }
  
  Future<void> _generateBill() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the bill')),
      );
      return;
    }
    
    final items = <BillItemData>[];
    for (var entry in _cartItems.entries) {
      final menuItem = _cachedItems.firstWhere((i) => i.id == entry.key);
      items.add(BillItemData(
        name: menuItem.name,
        quantity: entry.value,
        price: menuItem.price,
        subtotal: menuItem.price * entry.value,
      ));
    }
    
    final billData = BillData(
      customerName: _customerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      items: items,
      subtotal: _subtotal,
      discountType: _discountType,
      discountValue: _discountValue,
      total: _total,
      createdAt: DateTime.now(),
    );
    
    // Navigate to template selection
    context.go('/billing/select-template', extra: billData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _cartItems.isEmpty ? null : () => _showCartSummary(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Menu items
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppTextField(
                    controller: TextEditingController(),
                    hintText: 'Search items...',
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterItems();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? const Center(child: Text('No items found'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final inCart = _cartItems[item.id] ?? 0;
                            return AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          child: item.imagePath.isNotEmpty
                                              ? Image.file(
                                                  File(item.imagePath),
                                                  width: double.infinity,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.restaurant, size: 48),
                                                ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.isVeg ? Colors.green : Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              item.isVeg ? Icons.check_circle : Icons.remove_circle,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${item.price}',
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (inCart > 0)
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () => _updateQuantity(item.id!, -1),
                                                size: 20,
                                              ),
                                              Text('$inCart'),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () => _updateQuantity(item.id!, 1),
                                                size: 20,
                                              ),
                                            ],
                                          )
                                        else
                                          AppButton(
                                            text: 'Add',
                                            onPressed: () => _addToCart(item.id!),
                                            fullWidth: true,
                                            small: true,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Right side - Cart summary
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _cartItems.isEmpty
                      ? const Center(child: Text('No items added'))
                      : ListView.builder(
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final entry = _cartItems.entries.elementAt(index);
                            final item = _cachedItems.firstWhere((i) => i.id == entry.key);
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text('₹${item.price} x ${entry.value}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _updateQuantity(entry.key, -1),
                                    size: 20,
                                  ),
                                  Text('${entry.value}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _updateQuantity(entry.key, 1),
                                    size: 20,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _customerNameController,
                        hintText: 'Customer Name (optional)',
                        small: true,
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _phoneController,
                        hintText: 'Phone Number (optional)',
                        keyboardType: TextInputType.phone,
                        small: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _discountType,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'percent', child: Text('%')),
                                DropdownMenuItem(value: 'fixed', child: Text('₹')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _discountType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppTextField(
                              controller: TextEditingController(text: _discountValue.toString()),
                              hintText: 'Discount',
                              keyboardType: TextInputType.number,
                              small: true,
                              onChanged: (value) {
                                setState(() {
                                  _discountValue = double.tryParse(value) ?? 0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildSummaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
                      _buildSummaryRow('Discount', '-₹${_discountAmount.toStringAsFixed(2)}'),
                      _buildSummaryRow(
                        'Total',
                        '₹${_total.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Generate Bill',
                        onPressed: _cartItems.isEmpty ? null : _generateBill,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCartSummary() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cart Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._cartItems.entries.map((entry) {
              final item = _cachedItems.firstWhere((i) => i.id == entry.key);
              return ListTile(
                title: Text(item.name),
                trailing: Text('x${entry.value}'),
              );
            }),
          ],
        ),
      ),
    );
  }
}

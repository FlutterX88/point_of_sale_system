import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../backend/billing/bill_service.dart';
import '../../backend/order/OrderApiService.dart';
import '../orders/modifyOrder.dart';

class BillPage extends StatefulWidget {
  final propertyid;
  final outletname;
  const BillPage(
      {super.key, required this.propertyid, required this.outletname});
  @override
  _BillPageState createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  BillingApiService billApiService = BillingApiService();
  OrderApiService orderApiService = OrderApiService();
  List<Map<String, String>> _bills = [];
  final List<Map<String, String>> _billsdata = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> orderItems = [];
  var selectedOrderId;
  bool isLoadingOrders = true;
  bool isLoadingItems = false;
  Map<String, Map<String, dynamic>> itemMap = {};
  String ordernumber = "";

  Map<String, dynamic>? _selectedBill;
  late Future<List<Map<String, String>>> _billingFuture;

  @override
  void initState() {
    _billingFuture = getbillByStatusnew('UnPaid');
    super.initState();
  }

  Future<List<Map<String, String>>> getbillByStatusnew(String status) async {
    try {
      // Await the result from the API call
      List<Map<String, dynamic>> billJson = await billApiService
          .getbillByStatus(status: status); // Await the Future

      // Map the API response to the structure of _bills
      _bills = billJson.map((bill) {
        return {
          'bill_id': bill['id']?.toString() ?? '',
          'bill_number': bill['bill_number']?.toString() ?? '',
          'tax_value': bill['tax_value']?.toString() ?? '0',
          'discount_value': bill['discount_value']?.toString() ?? '0',
          'outlet_name': bill['outlet_name']?.toString() ?? '',
          'status': bill['status']?.toString() ?? '',
          'bill_generated_at': bill['bill_generated_at']?.toString() ?? '',
          'guest_name': bill['guestname']?.toString() ?? '',
          'grand_total': bill['grand_total']?.toString() ?? '0',
          'discount_percentage': bill['discount_percentage']?.toString() ?? '0',
          'service_charge_percentage':
              bill['service_charge_percentage']?.toString() ?? '0',
          'service_charge_value':
              bill['service_charge_value']?.toString() ?? '0',
          'delivery_charge_percentage':
              bill['delivery_charge_percentage']?.toString() ?? '0',
          'packing_charge_percentage':
              bill['packing_charge_percentage']?.toString() ?? '0',
          'delivery_charge_value': bill['delivery_charge']?.toString() ?? '0',
          'packing_charge_value': bill['packing_charge']?.toString() ?? '0',
          'total_amount': bill['total_amount']?.toString() ?? '0',
          'country': 'India'
        };
      }).toList();

      return _bills;
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  // Future<List<Map<String, String>>> getbillBybillno(String billno) async {
  //   try {
  //     // Await the result from the API call
  //     List<Map<String, dynamic>> billJson = await billApiService
  //         .getbillByStatus(billno: billno); // Await the Future

  //     // Map the API response to the structure of _bills
  //     _billsdata = billJson.map((bill) {
  //       return {
  //         'bill_id': bill['id']
  //             .toString(), // Adjust based on the field name in your API response
  //         'bill_number': bill['bill_number'].toString(),
  //         'amount': bill['grand_total']
  //             .toString(), // Adjust based on the field name in your API response
  //         'total_amount': bill['grand_total'].toString(),
  //         'tax_value': bill['tax_value'].toString(),
  //         'discount_value': bill['discount_value'].toString(),
  //         'outlet_name': bill['outlet_name'].toString(),
  //         'status': bill['status'].toString(),
  //         'bill_generated_at': bill['bill_generated_at'].toString(),
  //         'guest_name': bill['guestname'].toString(),
  //         'country': 'India'
  //       };
  //     }).toList();

  //     return _billsdata;
  //   } catch (e) {
  //     throw Exception('Error fetching orders: $e');
  //   }
  // }

  Future<void> _fetchOrders(billid) async {
    setState(() {
      isLoadingOrders = true;
    });

    try {
      // Fetch orders by table and status (assuming this fetches the 10 orders)
      orders = await orderApiService.getOrdersBybillid(billid);

      // Check if there are orders, then extract their IDs
      if (orders.isNotEmpty) {
        // Extract all order IDs from the fetched orders
        List<String> orderIds =
            orders.map((order) => order['order_id'].toString()).toList();

        // Fetch items for all selected orders
        await _fetchOrderItems(orderIds);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching orders: $e')),
      );
    } finally {
      setState(() {
        isLoadingOrders = false;
      });
    }
  }

  Future<void> _fetchOrderItems(List<String> orderIds) async {
    setState(() {
      isLoadingItems = true;
    });

    try {
      // Fetch items for all selected orders
      final fetchedItems = await orderApiService.getOrderItemsByIds(orderIds);
      itemMap.clear();
      orderItems.clear();
      // Process fetched items
      for (var item in [...orderItems, ...fetchedItems]) {
        final key = item['item_name'];

        // Safely parse item quantity, rate, and tax
        int itemQuantity = 0;
        if (item['item_quantity'] != null) {
          if (item['item_quantity'] is String) {
            itemQuantity = int.tryParse(item['item_quantity']) ?? 0;
          } else if (item['item_quantity'] is int) {
            itemQuantity = item['item_quantity'] as int;
          }
        }

        double itemRate = 0.0;
        if (item['item_rate'] != null) {
          if (item['item_rate'] is String) {
            itemRate = double.tryParse(item['item_rate']) ?? 0.0;
          } else if (item['item_rate'] is double) {
            itemRate = item['item_rate'] as double;
          }
        }

        int taxRate = 0;
        if (item['taxrate'] != null && item['taxrate'] is int) {
          taxRate = item['taxrate'];
        }

        if (itemMap.containsKey(key)) {
          itemMap[key]!['quantity'] += itemQuantity;
          itemMap[key]!['total'] = itemMap[key]!['quantity'] * itemRate;
        } else {
          itemMap[key] = {
            'sno': itemMap.length + 1,
            'item_name': item['item_name'],
            'quantity': itemQuantity,
            'price': itemRate,
            'tax': taxRate,
            'total': itemQuantity * itemRate,
            'order_id': item['order_id'],
            'discountable': item['discountable']
          };
        }
      }

      setState(() {
        orderItems = itemMap.values.toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching order items: ${e.toString()}')),
      );
      print("Error: $e");
    } finally {
      setState(() {
        isLoadingItems = false;
      });
    }
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final parsedDate =
            DateTime.parse(date).toLocal(); // Convert to local timezone
        return "${_twoDigits(parsedDate.day)}-${_twoDigits(parsedDate.month)}-${parsedDate.year} : ${_twoDigits(parsedDate.hour)}:${_twoDigits(parsedDate.minute)}";
      } else if (date is DateTime) {
        final localDate = date.toLocal(); // Ensure it's in the local timezone
        return "${_twoDigits(localDate.day)}-${_twoDigits(localDate.month)}-${localDate.year} : ${_twoDigits(localDate.hour)}:${_twoDigits(localDate.minute)}";
      }
    } catch (e) {
      print("Error formatting date: $e");
    }
    return "Invalid Date";
  }

// Helper function to ensure two digits for day, month, hour, and minute
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // Replace null or "null" values with defaults
  Map<String, dynamic> sanitizeBill(Map<String, dynamic> bill) {
    final sanitized = <String, dynamic>{};
    bill.forEach((key, value) {
      if (value == null || value.toString().toLowerCase() == 'null') {
        sanitized[key] =
            double.tryParse(value?.toString() ?? '') == null ? '' : '0';
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Billing System'),
        ),
        body: FutureBuilder<List<Map<String, String>>>(
            future: _billingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a loading indicator while waiting for data
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                // Handle error
                return Center(
                    child: Text('Error loading menu items: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                return Row(children: [
                  // Left Side: Bills List
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[200],
                      child: ListView.builder(
                        itemCount: _bills.length,
                        itemBuilder: (context, index) {
                          final bill = _bills[index];
                          bool isSelected = _selectedBill == bill;
                          return Card(
                            color: isSelected ? Colors.blue[100] : Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                                title: Text('Bill ID: ${bill['bill_number']}'),
                                subtitle:
                                    Text('Amount: ${bill['grand_total']}'),
                                onTap: () async {
                                  await _fetchOrders(
                                      bill['bill_id'].toString());
                                  _selectBill(bill);
                                }),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _selectedBill == null
                        ? const Center(
                            child: Text('Select a bill to view details'))
                        : Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Bill Details
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1, color: Colors.grey),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bill Number: ${_selectedBill!['bill_number']}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Guest Name: ${_selectedBill?['guest_name'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Date & Time: ${_formatDate(_selectedBill!['bill_generated_at'])}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Status: ${_selectedBill!['status']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Items List
                                Expanded(
                                  child: isLoadingItems
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : orderItems.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No items available',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount: orderItems.length,
                                              itemBuilder: (context, index) {
                                                final item = orderItems[index];
                                                return Card(
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: ListTile(
                                                    title: Text(
                                                        '${item['item_name']}'),
                                                    subtitle: Text(
                                                      'Qty: ${item['quantity']} | Price: ₹${item['price'].toStringAsFixed(2)}',
                                                    ),
                                                    trailing: Text(
                                                      'Total: ₹${item['total'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                ),

                                // Footer: Charges
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          width: 1, color: Colors.grey),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Total:'),
                                          Text(
                                            '₹${_selectedBill?['total_amount'] ?? '0.00'}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              'Discount: ${_selectedBill?['discount_percentage'] ?? '0'}% '),
                                          Text(
                                            '₹${_selectedBill?['discount_value'] ?? '0.00'}',
                                          ),
                                        ],
                                      ),

                                      // Tax Details
                                      // if (_selectedBill?['country'] ==
                                      //     'India') ...[

                                      // Row(
                                      //   mainAxisAlignment:
                                      //       MainAxisAlignment.spaceBetween,
                                      //   children: [
                                      //     Text(
                                      //         'CGST: ${_selectedBill?['cgst_percentage'] ?? '0'}% '),
                                      //     Text(
                                      //       '₹${_selectedBill?['cgst_value'] ?? '0.00'}',
                                      //     ),
                                      //   ],
                                      // ),
                                      // const SizedBox(height: 8),
                                      // Row(
                                      //   mainAxisAlignment:
                                      //       MainAxisAlignment.spaceBetween,
                                      //   children: [
                                      //     Text(
                                      //         'SGST: ${_selectedBill?['sgst_percentage'] ?? '0'}%'),
                                      //     Text(
                                      //       '₹${_selectedBill?['sgst_value'] ?? '0.00'}',
                                      //     ),
                                      //   ],
                                      // ),
                                      // ] else ...[
                                      //   Row(
                                      //     mainAxisAlignment:
                                      //         MainAxisAlignment.spaceBetween,
                                      //     children: [
                                      //       Text(
                                      //           'Tax: ${_selectedBill?['tax_percentage'] ?? '0'}%'),
                                      //       Text(
                                      //         '₹${_selectedBill?['tax_value'] ?? '0.00'}',
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ],
                                      const SizedBox(height: 8),

                                      // Discount
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Subtotal: '),
                                          Text(
                                            '₹${double.parse(_selectedBill?['total_amount']) - double.parse(_selectedBill?['discount_value']) ?? '0.00'}',
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Tax:'),
                                          Text(
                                            '₹${_selectedBill?['tax_value'] ?? '0.00'}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Service Charge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              'Service Charge: ${_selectedBill?['service_charge_percentage'] ?? '0'}% '),
                                          Text(
                                            '₹${_selectedBill?['service_charge_value'] ?? '0.00'}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Packing Charge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              'Packing Charge: ${_selectedBill?['packing_charge_percentage'] ?? '0'}%'),
                                          Text(
                                            '₹${_selectedBill?['packing_charge_value'] ?? '0.00'}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Delivery Charge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              'Delivery Charge: ${_selectedBill?['delivery_charge_percentage'] ?? '0'}%'),
                                          Text(
                                            '₹${_selectedBill?['delivery_charge_value'] ?? '0.00'}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Grand Total
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Grand Total:',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '₹${_selectedBill?['grand_total'] ?? '0.00'}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Action Buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              await _generateReprintPDF(); // Call the PDF generator
                                            },
                                            child: const Text('Reprint'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _modifyBillDialog(),
                                            child: const Text('Modify'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => _modifyBill(orders,
                                                _selectedBill?['bill_id']),
                                            child: const Text('Edit'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => _cancelBill(),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              _saveModifiedBill(
                                                  _selectedBill?[
                                                          'guest_name'] ??
                                                      '',
                                                  double.parse(_selectedBill?[
                                                      'discount_percentage']),
                                                  double.parse(_selectedBill?[
                                                      'service_charge_percentage']),
                                                  double.parse(_selectedBill?[
                                                      'packing_charge_percentage']),
                                                  double.parse(_selectedBill?[
                                                      'delivery_charge_percentage']));
                                            },
                                            child: const Text('Final Save'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ]);
              }
              return const CircularProgressIndicator();
            }));
  }

  void _modifyBillDialog() {
    // Controllers for text fields
    final guestNameController = TextEditingController();
    final discountController = TextEditingController();
    final serviceChargeController = TextEditingController();
    final packingChargeController = TextEditingController();
    final deliveryChargeController = TextEditingController();

    // Pre-fill the fields with current percentage values
    guestNameController.text = _selectedBill?['guest_name'] ?? '';
    discountController.text = _selectedBill?['discount_percentage'] ?? '0';
    serviceChargeController.text =
        _selectedBill?['service_charge_percentage'] ?? '0';
    packingChargeController.text =
        _selectedBill?['packing_charge_percentage'] ?? '0';
    deliveryChargeController.text =
        _selectedBill?['delivery_charge_percentage'] ?? '0';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modify Bill'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: guestNameController,
                decoration: const InputDecoration(labelText: 'Guest Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Discount %'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: serviceChargeController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Service Charge %'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: packingChargeController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Packing Charge %'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deliveryChargeController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Delivery Charge %'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _saveModifiedBill(
                guestNameController.text,
                double.tryParse(discountController.text) ?? 0.0,
                double.tryParse(serviceChargeController.text) ?? 0.0,
                double.tryParse(packingChargeController.text) ?? 0.0,
                double.tryParse(deliveryChargeController.text) ?? 0.0,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveModifiedBill(
    String guestName,
    double discountPercent,
    double serviceChargePercent,
    double packingChargePercent,
    double deliveryChargePercent,
  ) async {
    // 1) Update basic fields (percentages)
    setState(() {
      _selectedBill?['guest_name'] = guestName;
      _selectedBill?['discount_percentage'] =
          discountPercent.toStringAsFixed(2);
      _selectedBill?['service_charge_percentage'] =
          serviceChargePercent.toStringAsFixed(2);
      _selectedBill?['packing_charge_percentage'] =
          packingChargePercent.toStringAsFixed(2);
      _selectedBill?['delivery_charge_percentage'] =
          deliveryChargePercent.toStringAsFixed(2);
    });

    // 2) Rebuild items with discount (using percent) and tax
    List<Map<String, dynamic>> updatedItems = [];
    for (var item in orderItems) {
      final qty = (item['quantity'] is num)
          ? (item['quantity'] as num).toDouble()
          : double.tryParse(item['quantity'].toString()) ?? 0.0;
      final price = (item['price'] is num)
          ? (item['price'] as num).toDouble()
          : double.tryParse(item['price'].toString()) ?? 0.0;
      final taxRate = (item['tax'] is num)
          ? (item['tax'] as num).toInt()
          : int.tryParse(item['tax'].toString()) ?? 0;
      final discountable = (item['discountable'] is bool)
          ? item['discountable'] as bool
          : item['discountable'].toString().toLowerCase() == 'true';

      final itemTotal = qty * price;
      final itemDiscount =
          discountable ? (itemTotal * discountPercent) / 100 : 0.0;
      final itemSubtotal = itemTotal - itemDiscount;
      final itemTax = (itemSubtotal * taxRate) / 100;

      updatedItems.add({
        'sno': updatedItems.length + 1,
        'item_name': item['item_name'],
        'quantity': qty,
        'price': price,
        'tax': itemTax,
        'total': itemTotal,
        'subtotal': itemSubtotal,
        'grandtotal': itemSubtotal + itemTax,
        'discountable': discountable,
        'discount_percentage': discountable ? discountPercent : 0.0,
        'dis_amt': itemDiscount,
        'order_id': item['order_id'],
      });
    }

    // 3) Totals & subtotal
    final totalAmount = updatedItems.fold<double>(0, (s, i) => s + i['total']);
    final totalDiscount =
        updatedItems.fold<double>(0, (s, i) => s + i['dis_amt']);
    final taxValue = updatedItems.fold<double>(0, (s, i) => s + i['tax']);
    final subtotal = totalAmount - totalDiscount;

    // 4) Convert percentages → absolute charges
    final serviceChargeValue = subtotal * serviceChargePercent / 100;
    final packingChargeValue = subtotal * packingChargePercent / 100;
    final deliveryChargeValue = subtotal * deliveryChargePercent / 100;

    // 5) Grand total
    final grandTotal = subtotal +
        taxValue +
        serviceChargeValue +
        packingChargeValue +
        deliveryChargeValue;

    // 6) Update bill with calculated values
    setState(() {
      _selectedBill?['total_amount'] = totalAmount.toStringAsFixed(2);
      _selectedBill?['tax_value'] = taxValue.toStringAsFixed(2);
      _selectedBill?['subtotal'] = subtotal.toStringAsFixed(2);
      _selectedBill?['service_charge_value'] =
          serviceChargeValue.toStringAsFixed(2);
      _selectedBill?['packing_charge_value'] =
          packingChargeValue.toStringAsFixed(2);
      _selectedBill?['delivery_charge_value'] =
          deliveryChargeValue.toStringAsFixed(2);
      _selectedBill?['grand_total'] = grandTotal.toStringAsFixed(2);
    });

    // 7) Persist to backend
    try {
      final billData = sanitizeBill(_selectedBill!);
      billData['items'] = updatedItems;
      // also persist both % and absolute values if your API supports them:
      billData['service_charge_percentage'] = serviceChargePercent;
      billData['packing_charge_percentage'] = packingChargePercent;
      billData['delivery_charge_percentage'] = deliveryChargePercent;
      billData['service_charge_value'] = serviceChargeValue;
      billData['packing_charge_value'] = packingChargeValue;
      billData['delivery_charge_value'] = deliveryChargeValue;

      await billApiService.editBill(
        _selectedBill!['bill_id'].toString(),
        billData,
      );
      //  _billingFuture = getbillByStatusnew('UnPaid');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save bill: $e')),
      );
    }
  }

  // Method to select a bill
  void _selectBill(Map<String, dynamic> bill) {
    setState(() {
      _selectedBill = bill;
    });
  }

  // Method to handle Edit
  void _editBill() {
    print('Editing bill: ${_selectedBill!['bill_number']}');
  }

  // Method to handle Cancel
  void _cancelBill() {
    print('Cancelling bill: ${_selectedBill!['bill_number']}');
    // Add your cancel functionality here
  }

  // Recalculate totals and persist the bill
  // Future<void> _finalSaveBill() async {
  //   if (_selectedBill == null) return;

  //   // Existing charges
  //   double discount =
  //       double.tryParse(_selectedBill?['discount_value'] ?? '0') ?? 0;
  //   double serviceCharge = double.tryParse(_selectedBill?['service_charge'] ??
  //           _selectedBill?['service_charge_value'] ??
  //           '0') ??
  //       0;
  //   double packingCharge =
  //       double.tryParse(_selectedBill?['packing_charge'] ?? '0') ?? 0;
  //   double deliveryCharge =
  //       double.tryParse(_selectedBill?['delivery_charge'] ?? '0') ?? 0;

  //   // Totals from order items
  //   double totalAmount = orderItems.fold<double>(0, (sum, item) {
  //     final dynamic total = item['total'];
  //     if (total is num) {
  //       return sum + total.toDouble();
  //     }
  //     final qty = item['quantity'] is num
  //         ? (item['quantity'] as num).toDouble()
  //         : double.tryParse(item['quantity'].toString()) ?? 0;
  //     final price = item['price'] is num
  //         ? (item['price'] as num).toDouble()
  //         : double.tryParse(item['price'].toString()) ?? 0;
  //     return sum + (qty * price);
  //   });

  //   double taxValue = orderItems.fold<double>(0, (sum, item) {
  //     final dynamic total = item['total'];
  //     double baseTotal;
  //     if (total is num) {
  //       baseTotal = total.toDouble();
  //     } else {
  //       final qty = item['quantity'] is num
  //           ? (item['quantity'] as num).toDouble()
  //           : double.tryParse(item['quantity'].toString()) ?? 0;
  //       final price = item['price'] is num
  //           ? (item['price'] as num).toDouble()
  //           : double.tryParse(item['price'].toString()) ?? 0;
  //       baseTotal = qty * price;
  //     }
  //     final rate = item['tax'] is num
  //         ? (item['tax'] as num).toDouble()
  //         : double.tryParse(item['tax'].toString()) ?? 0;
  //     return sum + (baseTotal * rate / 100);
  //   });

  //   double subtotal = totalAmount - discount;
  //   double grandTotal =
  //       subtotal + taxValue + serviceCharge + packingCharge + deliveryCharge;

  //   setState(() {
  //     _selectedBill?['total_amount'] = totalAmount.toStringAsFixed(2);
  //     _selectedBill?['tax_value'] = taxValue.toStringAsFixed(2);
  //     _selectedBill?['subtotal'] = subtotal.toStringAsFixed(2);
  //     _selectedBill?['grand_total'] = grandTotal.toStringAsFixed(2);
  //   });

  //   try {
  //     await billApiService.editBill(
  //         _selectedBill!['bill_id'].toString(), sanitizeBill(_selectedBill!));
  //     final updatedBill =
  //         await billApiService.getBill(_selectedBill!['bill_id'].toString());
  //     setState(() {
  //       _selectedBill = Map<String, dynamic>.from(updatedBill);
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Bill saved successfully')));
  //   } catch (e) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('Failed to save bill: $e')));
  //   }
  // }

  // Method to handle Modify
  void _modifyBill(orders, billid) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ModifyOrderList(
                outletname: widget.outletname,
                propertyid: widget.propertyid,
                orders: orders,
                billid: billid)));
  }

  Future<void> _generateReprintPDF() async {
    if (_selectedBill == null || orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bill or items to print')),
      );
      return;
    }

    final bill = _selectedBill!;
    final now = DateTime.now();
    final pdf = pw.Document();

    double totalAmount = double.tryParse(bill['total_amount'] ?? '0') ?? 0;
    if (totalAmount == 0 && orderItems.isNotEmpty) {
      totalAmount = orderItems.fold<double>(0, (sum, item) {
        final dynamic total = item['total'];
        if (total is num) {
          return sum + total.toDouble();
        }
        final qty = item['quantity'] is num ? item['quantity'] as num : 0;
        final price = item['price'] is num ? item['price'] as num : 0;
        return sum + (qty * price);
      });
    }
    double tax = double.tryParse(bill['tax_value'] ?? '0') ?? 0;
    double discount = double.tryParse(bill['discount_value'] ?? '0') ?? 0;
    double serviceCharge =
        double.tryParse(bill['service_charge_value'] ?? '0') ?? 0;
    double packingCharge = double.tryParse(bill['packing_charge'] ?? '0') ?? 0;
    double deliveryCharge =
        double.tryParse(bill['delivery_charge'] ?? '0') ?? 0;
    double grandTotal = double.tryParse(bill['grand_total'] ?? '0') ?? 0;

    double discountPer = totalAmount == 0 ? 0 : (discount / totalAmount) * 100;
    double subtotal = totalAmount - discount;
    double totalCharges = serviceCharge + packingCharge + deliveryCharge;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Text('My Business Name',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(
              child: pw.Text('123 Business Street, City, Country',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ),
            pw.Center(
              child: pw.Text('Phone: +123456789 | contact@business.com',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.8),

            // Meta Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Table: ${bill['table_no']}',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.Text('PAX: ${bill['pax']}',
                    style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Bill No: ${bill['bill_number']}',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Order #: ${bill['order_no'] ?? '1'}',
                    style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date: ${DateFormat('dd-MMM-yyyy').format(now)}',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Time: ${DateFormat('hh:mm a').format(now)}',
                    style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 6),

            // Guest
            pw.Text('Bill To:',
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Customer Name: ${bill['guest_name'] ?? 'Walk-In'}',
                style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.5),

            // Item Table
            pw.Text('Itemized Bill:',
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              cellAlignment: pw.Alignment.center,
              headerStyle:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
              headers: ['Item', 'Qty', 'Price', 'Tax%', 'Total'],
              data: orderItems.map((item) {
                final qty = item['quantity'];
                final rate = item['price'];
                final total = item['total'];
                return [
                  item['item_name'],
                  '$qty',
                  rate.toStringAsFixed(2),
                  '${item['tax']}%',
                  total.toStringAsFixed(2),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),

            // Totals Summary
            _summaryRow('Total Amount:', totalAmount),
            if (discount > 0)
              _summaryRow(
                  'Discount (${discountPer.toStringAsFixed(1)}%):', -discount),
            _summaryRow('Subtotal:', subtotal),
            _summaryRow('Tax (5%):', tax),
            _summaryRow('Service Charge (10%):', totalCharges),

            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.8),

            // Net Payable
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Net Payable:',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(grandTotal.toStringAsFixed(2),
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 6),

            // Footer
            pw.Center(
              child: pw.Text('Thank you for your purchase!',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.green)),
            ),
            pw.Center(
              child: pw.Text('Visit Again!',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ),
          ],
        );
      },
    ));

    final directory = Directory('C:\\Users\\Public\\Documents');
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    final safeBillNo =
        bill['bill_number'].toString().replaceAll(RegExp(r'[^\w\-]'), '_');
    final filePath = p.join(directory.path, '$safeBillNo.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved at: $filePath')),
    );

    if (Platform.isWindows) {
      await Process.run('explorer', [filePath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [filePath]);
    }
  }

  pw.Widget _summaryRow(String label, double value) {
    final isNegative = value < 0;
    final formatted = isNegative
        ? '- ${value.abs().toStringAsFixed(2)}'
        : value.toStringAsFixed(2);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(formatted, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}

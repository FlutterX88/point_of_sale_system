import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:point_of_sale_system/backend/OrderApiService.dart';
import 'package:point_of_sale_system/backend/bill_service.dart';

class BillingFormScreen extends StatefulWidget {
  final tableno;
  final propertyid;
  final outlet;
  const BillingFormScreen(
      {Key? key,
      required this.propertyid,
      required this.outlet,
      required this.tableno})
      : super(key: key);

  @override
  _BillingFormScreenState createState() => _BillingFormScreenState();
}

class _BillingFormScreenState extends State<BillingFormScreen> {
  BillingApiService billingApiService =
      BillingApiService(baseUrl: 'http://localhost:3000/api');
  OrderApiService orderApiService =
      OrderApiService(baseUrl: 'http://localhost:3000/api');
  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _orderNoController =
      TextEditingController(text: 'ORD67890');
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _tableNoController = TextEditingController();
  final TextEditingController _guestIdController = TextEditingController();
  final TextEditingController _guestSearchController = TextEditingController();
  final TextEditingController _paxController = TextEditingController(text: '1');
  final TextEditingController _flatDiscountController = TextEditingController();
  final TextEditingController _percentDiscountController =
      TextEditingController();
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> orderItems = [];
  var selectedOrderId;
  bool isLoadingOrders = true;
  bool isLoadingItems = false;

  bool _isInitialized = false;
  String _discountType = 'Percentage'; // Default to Percentage Discount

  // Mock data for items
  // final List<Map<String, dynamic>> _items = List.generate(10, (index) {
  //   return {
  //     'sno': index + 1,
  //     'name': 'Item ${index + 1}',
  //     'qty': 1,
  //     'rate': 100.0,
  //     'amount': 100.0,
  //     'tax': 5.0,
  //     'discount_amount': 10.0,
  //     'happy_hour_discount': 5.0,
  //     'scheme': 'None',
  //     'category': 'Category ${index % 3}',
  //   };
  // });
  Map<String, Map<String, dynamic>> itemMap = {};

  @override
  void initState() {
    _billNoController.text = generateBillId();
    _tableNoController.text = widget.tableno;
    _fetchOrders();
    super.initState();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      isLoadingOrders = true;
    });

    try {
      // Fetch orders by table and status (assuming this fetches the 10 orders)
      orders = await orderApiService.getOrdersByTableAndStatus(
          widget.tableno, 'Pending');

      // Check if there are orders, then extract their IDs
      if (orders.isNotEmpty) {
        // Extract all order IDs from the fetched orders
        List<String> orderIds =
            orders.map((order) => order['order_id'].toString()).toList();

        // Fetch items for all selected orders
        _fetchOrderItems(orderIds);
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

  String generateBillId() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMddHHmm');
    final formattedDate = formatter.format(now);
    return 'BILL-$formattedDate';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _dateController.text = DateTime.now().toString().split(' ')[0];
      _timeController.text = TimeOfDay.now().format(context);
      _isInitialized = true;
    }
  }

  void _searchGuest() {
    setState(() {
      _guestIdController.text = 'GUEST001';
    });
  }

  Future<void> _saveBill() async {
    try {
      // Prepare bill data
      Map<String, dynamic> billData = {
        "table_no": widget.tableno,
        "tax_value": 5.0,
        "discount_percentage": 10.0,
        "service_charge_percentage": 5.0,
        "packing_charge_percentage": 2.0,
        "delivery_charge_percentage": 3.0,
        "other_charge": 50.0,
        "property_id": widget.propertyid,
        "outletname": widget.outlet
      };
      await billingApiService.generateBill(billData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill saved successfully!')),
      );
      _clearControllers(); // Clear the input fields
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  void _clearControllers() {
    _billNoController.clear();
    _orderNoController.clear();
    _tableNoController.text = '5'; // Default value
    _guestIdController.clear();
    _guestSearchController.clear();
    _paxController.text = '1'; // Default value
    _flatDiscountController.clear();
    _percentDiscountController.clear();
    setState(() {
      _isInitialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Billing Form'),
      ),
      body: Center(
        child: Container(
          width: 600, // Adjust as needed for the form width
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 4,
                blurRadius: 10,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bill No:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                              controller: _billNoController,
                              enabled: false,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order No:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                              controller: _orderNoController,
                              enabled: false,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                              controller: _dateController,
                              enabled: false,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                              controller: _timeController,
                              enabled: false,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Table No:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                              controller: _tableNoController,
                              enabled: false,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guest ID:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                              controller: _guestIdController,
                              enabled: false,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _guestSearchController,
                  decoration: InputDecoration(
                    labelText: 'Search Guest',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: _searchGuest,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Pax Field
                TextFormField(
                  controller: _paxController,
                  decoration: InputDecoration(
                    labelText: 'Pax (Number of People)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),

                // Discount Field with Radio Buttons for Discount Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Discount Type:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Radio<String>(
                      value: 'Percentage',
                      groupValue: _discountType,
                      onChanged: (value) {
                        setState(() {
                          _discountType = value!;
                        });
                      },
                    ),
                    Text('Percentage'),
                    Radio<String>(
                      value: 'Flat',
                      groupValue: _discountType,
                      onChanged: (value) {
                        setState(() {
                          _discountType = value!;
                        });
                      },
                    ),
                    Text('Flat Amount'),
                  ],
                ),
                if (_discountType == 'Percentage')
                  TextFormField(
                    controller: _percentDiscountController,
                    decoration:
                        InputDecoration(labelText: 'Discount Percentage'),
                    keyboardType: TextInputType.number,
                  ),
                if (_discountType == 'Flat')
                  TextFormField(
                    controller: _flatDiscountController,
                    decoration: InputDecoration(labelText: 'Discount Amount'),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 10),

                // Scrollable Items List
                Container(
                  height:
                      250, // Increased height to allow vertical scroll as well
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical, // Allow vertical scrolling
                    child: SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal, // Allow horizontal scrolling
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('S.No')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Rate')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Tax')),
                          // DataColumn(label: Text('Discount Amount')),
                          // DataColumn(label: Text('Happy Hour Discount')),
                          // DataColumn(label: Text('Scheme')),
                          // DataColumn(label: Text('Category')),
                        ],
                        rows: itemMap.entries.map((entry) {
                          var item =
                              entry.value; // Accessing the value of the entry
                          return DataRow(cells: [
                            DataCell(Text(item['sno'].toString())),
                            DataCell(Text(item['item_name'])),
                            DataCell(Text(item['quantity'].toString())),
                            DataCell(Text('₹${item['price']}')),
                            DataCell(Text('₹${item['total']}')),
                            DataCell(Text('${item['tax']}%')),
                            // DataCell(Text('₹${item['discount_amount']}')),
                            // DataCell(Text('₹${item['happy_hour_discount']}')),
                            // DataCell(Text(item['scheme'])),
                            // DataCell(Text(item['category'])),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // Summary Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount:'),
                        Text('₹1000.00'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discount:'),
                        Text('₹50.00'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal:'),
                        Text('₹950.00'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('CGST (2.5%):'),
                        Text('₹23.75'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SGST (2.5%):'),
                        Text('₹23.75'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Service Charge:'),
                        Text('₹10.00'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Net Receivable Amount:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹1007.50',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _saveBill();
                      },
                      child: Text('Save'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Print Bill'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

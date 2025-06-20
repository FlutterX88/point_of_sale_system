import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../backend/settings/deliveryApiService.dart';
import '../../backend/api_config.dart';

class DeliveryChargeConfigForm extends StatefulWidget {
  const DeliveryChargeConfigForm({super.key});

  @override
  _DeliveryChargeConfigFormState createState() =>
      _DeliveryChargeConfigFormState();
}

class _DeliveryChargeConfigFormState extends State<DeliveryChargeConfigForm> {
  DeliveryApiService deliveryApiService =
      DeliveryApiService(baseUrl: apiBaseUrl);
  final _formKey = GlobalKey<FormState>();
  final _chargePercentageController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  final _taxController = TextEditingController();
  String _applyOn = 'all bills';
  String _status = 'active';
  String? _selectedOutlet; // Default selected outlet

  // List of available outlets (for example purposes, replace with actual data)
  List<String> outlets = [];

  // Map to store Delivery Charge by outlet
  Map<String, List<Map<String, dynamic>>> outletdeliveryCharge = {};

  List<dynamic> properties = [];
  List<dynamic> outletConfigurations = [];
  DateTime? startDate;

  @override
  void initState() {
    super.initState();
    _loadDataFromHive();
  }

  // Load data from Hive
  Future<void> _loadDataFromHive() async {
    var box = await Hive.openBox('appData');

    // Retrieve the data
    var properties = box.get('properties');
    var outletConfigurations = box.get('outletConfigurations');

    // Check if outletConfigurations is not null
    if (outletConfigurations != null) {
      // Extract the outlet names into the outlets list
      List<String> outletslist = [];
      for (var outlet in outletConfigurations) {
        if (outlet['outlet_name'] != null) {
          outletslist.add(outlet['outlet_name'].toString());
        }
      }

      setState(() {
        this.properties = properties ?? [];
        this.outletConfigurations = outletConfigurations ?? [];
        outlets = outletslist; // Set the outlets list
      });
    }
    _fetchdeliveryCharge();
  }

  Future<void> _fetchdeliveryCharge() async {
    try {
      List<Map<String, dynamic>> deliveryCharge =
          await deliveryApiService.getDeliveryCharges();

      // Organize Delivery Charge by outlet
      Map<String, List<Map<String, dynamic>>> organizedCharges = {};
      for (var charge in deliveryCharge) {
        String outletName = charge['outlet_name'] ?? 'Unknown Outlet';
        if (!organizedCharges.containsKey(outletName)) {
          organizedCharges[outletName] = [];
        }
        organizedCharges[outletName]!.add(charge);
      }
      setState(() {
        outletdeliveryCharge = organizedCharges;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetchingDelivery Charge: $e')));
    }
  }

  // Save  Delivery Charge configuration
  void _saveDeliveryChargeConfig() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, dynamic> newDeliveryCharge = {
        'property_id': properties.first['property_id'],
        'delivery_charge': double.parse(_chargePercentageController.text),
        'min_amount': double.parse(_minAmountController.text),
        'max_amount': double.parse(_maxAmountController.text),
        'apply_on': _applyOn,
        'status': _status,
        'start_date': startDate?.toIso8601String(),
        'outlet_name': _selectedOutlet.toString(),
        'tax': double.parse(_taxController.text),
      };

      // Check if the combination of property_id and outlet_name already exists
      String propertyId = newDeliveryCharge['property_id'].toString();
      String outletName = newDeliveryCharge['outlet_name'];

      bool exists = outletdeliveryCharge.containsKey(outletName) &&
          outletdeliveryCharge[outletName]!.any(
            (charge) =>
                charge['property_id'].toString() == propertyId.toString(),
          );

      try {
        if (exists) {
          // Update the existing Delivery Charge configuration
          String configId = outletdeliveryCharge[outletName]!
              .firstWhere((charge) =>
                  charge['property_id'].toString() ==
                  propertyId.toString())['id']
              .toString();

          await deliveryApiService.updateDeliveryCharge(
            configId,
            newDeliveryCharge,
          );

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Service charge updated successfully')));
        } else {
          // Create a new Delivery Charge configuration
          await deliveryApiService.createDeliveryCharge(newDeliveryCharge);

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Service charge created successfully')));
        }

        _fetchdeliveryCharge(); // Refresh the UI
        _clearFormFields();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving Delivery Charge: $e')));
      }
    }
  }

  void _editDeliveryCharge(
      String configId, Map<String, dynamic> updatedData) async {
    try {
      await deliveryApiService.updateDeliveryCharge(configId, updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service charge updated successfully')));
      _fetchdeliveryCharge(); // Refresh the UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating Delivery Charge: $e')));
    }
  }

  void _deleteDeliveryCharge(String configId, String outlet, int index) async {
    try {
      await deliveryApiService.deleteDeliveryCharge(configId);

      setState(() {
        outletdeliveryCharge[outlet]!.removeWhere(
            (charge) => charge['id'].toString() == configId.toString());
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service charge deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting Delivery Charge: $e')));
    }
  }

  void _clearFormFields() {
    setState(() {
      _chargePercentageController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _taxController.clear();
      _applyOn = 'all bills';
      _status = 'active';
      _selectedOutlet = null;
      startDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Charge Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form to input Delivery Charge details
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outlet Selection Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedOutlet,
                    onChanged: (value) {
                      setState(() {
                        _selectedOutlet = value!;
                      });
                    },
                    items: outlets.map((outlet) {
                      return DropdownMenuItem<String>(
                        value: outlet,
                        child: Text(outlet),
                      );
                    }).toList(),
                    decoration:
                        const InputDecoration(labelText: 'Select Outlet'),
                  ),

                  const SizedBox(height: 16),
                  // Charge Percentage Input
                  TextFormField(
                    maxLength: 3,
                    controller: _chargePercentageController,
                    decoration: const InputDecoration(
                      labelText: 'Charge Percentage',
                      prefixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Restricts input to digits only
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a charge percentage';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    maxLength: 3,
                    controller: _taxController,
                    decoration: const InputDecoration(
                      labelText: 'Tax',
                      prefixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Restricts input to digits only
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a charge percentage';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Min Amount Input
                  TextFormField(
                    maxLength: 8,
                    controller: _minAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Min Amount',
                      prefixText: '₹',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Restricts input to digits only
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a minimum amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Max Amount Input
                  TextFormField(
                    maxLength: 8,
                    controller: _maxAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Max Amount',
                      prefixText: '₹',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Restricts input to digits only
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a maximum amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Start Date
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Start Date (yyyy-MM-dd)'),
                    keyboardType: TextInputType.datetime,
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (selectedDate != null && selectedDate != startDate) {
                        setState(() {
                          startDate = selectedDate;
                        });
                      }
                    },
                    controller: TextEditingController(
                        text: startDate != null
                            ? "${startDate!.toLocal()}".split(' ')[0]
                            : ''),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a start date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Apply On Dropdown
                  DropdownButtonFormField<String>(
                    value: _applyOn,
                    onChanged: (value) {
                      setState(() {
                        _applyOn = value!;
                      });
                    },
                    items: ['all bills', 'specific outlets'].map((applyOn) {
                      return DropdownMenuItem<String>(
                        value: applyOn,
                        child: Text(applyOn),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Apply On'),
                  ),
                  const SizedBox(height: 16),
                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: _status,
                    onChanged: (value) {
                      setState(() {
                        _status = value!;
                      });
                    },
                    items: ['active', 'inactive'].map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveDeliveryChargeConfig,
                    child: const Text('Save  Delivery Charge Configuration'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Display saved Delivery Charge configurations outlet-wise
            Expanded(
              child: ListView.builder(
                itemCount: outletdeliveryCharge.keys.length,
                itemBuilder: (context, index) {
                  String outlet = outletdeliveryCharge.keys.elementAt(index);
                  List<Map<String, dynamic>> deliveryCharge =
                      outletdeliveryCharge[outlet]!;

                  return ExpansionTile(
                    title: Text(outlet),
                    leading: const Icon(Icons.store),
                    children: deliveryCharge.map((DeliveryCharge) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.attach_money,
                              color: Colors.green),
                          title: Text(
                              'Charge: ${DeliveryCharge['delivery_charge']}%'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Min: ₹${DeliveryCharge['min_amount']}'),
                              Text('Max: ₹${DeliveryCharge['max_amount']}'),
                              Text('Apply On: ${DeliveryCharge['apply_on']}'),
                              Text('Status: ${DeliveryCharge['status']}'),
                              Text(
                                  'Start Date: ${Getdateormat.formatDate(DeliveryCharge['start_date'])}'),
                              Text(
                                  'Outlet Name: ${DeliveryCharge['outlet_name']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteDeliveryCharge(
                                DeliveryCharge['id'].toString(),
                                DeliveryCharge['outlet_name'],
                                index),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Getdateormat {
  static String formatDate(dynamic date) {
    try {
      if (date is String) {
        final parsedDate =
            DateTime.parse(date).toLocal(); // Convert to local timezone
        return "${parsedDate.day}-${parsedDate.month}-${parsedDate.year}";
      } else if (date is DateTime) {
        return "${date.toLocal().day}-${date.toLocal().month}-${date.toLocal().year}";
      }
    } catch (e) {
      print("Error formatting date: $e");
    }
    return "Invalid Date";
  }
}

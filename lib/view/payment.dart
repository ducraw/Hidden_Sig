import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvoiceInfoWidget extends StatelessWidget {
  final Map<String, dynamic> invoiceInfo;

  const InvoiceInfoWidget({
    Key? key,
    required this.invoiceInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice ID: ${invoiceInfo['id']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Order Info: ${invoiceInfo['orderInfo']}'),
            SizedBox(height: 8),
            Text('Amount: ${invoiceInfo['amount']}'),
            SizedBox(height: 8),
            Text('Bank Code: ${invoiceInfo['bankCode']}'),
          ],
        ),
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late User? _user;
  List<Map<String, dynamic>> _invoiceInfoList = [];
  // Variable to store invoice info list

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadInvoice(); // Check if the user has an invoice
  }

  Future<void> _loadInvoice() async {
    try {
      final invoices = await _getInvoice(_user!.uid);
      setState(() {
        _invoiceInfoList = invoices
            .map<Map<String, dynamic>>((invoice) => {
                  'id': invoice['id'],
                  'orderInfo': invoice['orderInfo'],
                  'amount': invoice['amount'],
                  'bankCode': invoice['bankCode'],
                })
            .toList();
      });
    } catch (error) {
      print('Error loading invoice: $error');
    }
  }

  Future<List<dynamic>> _getInvoice(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/get_invoice/$userId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load invoice information');
      }
    } catch (error) {
      throw Exception('Failed to load invoice information: $error');
    }
  }

  final TextEditingController _amountController = TextEditingController();
  String _selectedBankCode = 'VNBANK'; // Default value
  String _vnpUrl = ''; // Variable to store the payment URL

  Future<void> _createPayment() async {
    String amount = _amountController.text;
    String bankCode = _selectedBankCode;
    String language = "vn"; // Customize language based on your requirements
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/create_payment_url'),
        body: jsonEncode({
          'amount': amount,
          'bankCode': bankCode,
          'userId': _user!.uid,
          'language': language,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 302) {
        // Extract redirection URL from the response headers
        String paymentUrl = response.headers['location'] ?? '';
        setState(() {
          _vnpUrl = paymentUrl;
        });
        _launchURL(paymentUrl);
      } else {
        // Handle other status codes
        print('Failed to create payment URL');
      }
    } catch (e) {
      // Handle network error
      print('Network error: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Info'),
      ),
      body: _invoiceInfoList.isNotEmpty
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _invoiceInfoList.length,
                    itemBuilder: (context, index) {
                      return InvoiceInfoWidget(
                        invoiceInfo: _invoiceInfoList[index],
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Thank you for purchasing!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField(
                    value: _selectedBankCode,
                    items: const [
                      DropdownMenuItem(
                        value: 'VNBANK',
                        child: Text('VNBANK'),
                      ),
                      DropdownMenuItem(
                        value: 'INTCARD',
                        child: Text('INTCARD'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedBankCode = value.toString();
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Select Bank Code'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createPayment,
                    child: const Text('Create Payment'),
                  ),
                ],
              ),
            ),
    );
  }
}

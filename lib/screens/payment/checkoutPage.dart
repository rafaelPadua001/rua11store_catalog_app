import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:rua11store_catalog_app/controllers/couponsController.dart';
import 'package:rua11store_catalog_app/models/adress.dart';
import 'package:rua11store_catalog_app/models/cardbrand.dart';
import 'package:rua11store_catalog_app/screens/payment/payment_result.dart';
import '../../controllers/PaymentController.dart';
import '../../controllers/addressController.dart';
import '../../models/payment.dart';
import '../../models/coupon.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class CheckoutPage extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final String zipCode;
  final List<Map> products;
  final Map delivery;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.userEmail,
    this.userName = '',
    required this.products,
    required this.delivery,
    required this.zipCode,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPayment = 'credit'; // valor padrão
  String? _selectedPaymentMethodId;
  double _subtotal = 0.0;
  double _shipping = 0.0;
  double _total = 0.0;
  final int _quantity = 1;
  double _discount = 0.0;
  bool _isLoading = false;
  late TextEditingController _numberCardController;
  late TextEditingController _nameCardController;
  late TextEditingController _cardExpiryController;
  late TextEditingController _cardCVVController;
  late TextEditingController _couponController;

  final List<String> estados = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];
  String? _estadoSelecionado;

  Coupon? _appliedCoupon;

  final List<CardBrand> cardBrands = [
    CardBrand(
      name: 'Mastercard',
      paymentMethodId: 'master',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/0/04/Mastercard-logo.png',
    ),
    CardBrand(
      name: 'Visa',
      paymentMethodId: 'visa',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/5/5e/Visa_Inc._logo.svg',
    ),
    CardBrand(
      name: 'Elo',
      paymentMethodId: 'elo',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/5/5e/Elo_logo.png',
    ),
  ];

  int? _selectedInstallment;
  CardBrand? selectedBrand;
  final TextEditingController _cpfController = MaskedTextController(
    mask: '000.000.000-00',
  );
  final docType = 'CPF';
  late TextEditingController _installmentsController = TextEditingController();
  TextEditingController _recipientNameController = TextEditingController();

  TextEditingController _streetController = TextEditingController();
  TextEditingController _numberController = TextEditingController();
  TextEditingController _complementController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _stateController = TextEditingController();
  late TextEditingController _zipCodeController = TextEditingController();
  TextEditingController _countryController = TextEditingController();
  late TextEditingController _bairroController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  late Future<List<Address>> _addressesFuture;

  final _addressController = AddressController();
  Map<String, dynamic>? _selectedAddress;

  @override
  void initState() {
    super.initState();

    _numberCardController = TextEditingController();
    _nameCardController = TextEditingController();
    _cardExpiryController = TextEditingController();
    _cardCVVController = TextEditingController();
    _installmentsController = TextEditingController();

    _zipCodeController = MaskedTextController(
      mask: '00000-000',
      text: widget.zipCode,
    );

    _bairroController = TextEditingController();

    _recipientNameController = TextEditingController();
    _streetController = TextEditingController();
    _numberController = TextEditingController();
    _complementController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController();
    _phoneController = MaskedTextController(mask: '(00) 00000-0000');
    _couponController = TextEditingController();

    _subtotal = widget.products.fold<double>(0.0, (sum, item) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final quantity = int.tryParse(item['quantity'].toString()) ?? 1;
      return sum + (price * quantity);
    });

    _shipping = double.tryParse(widget.delivery['price'].toString()) ?? 0.0;
    int installments = int.tryParse(_installmentsController.text) ?? 1;
    _total = (_subtotal + _shipping) / installments;

    // 1) busca os endereços e depois seta o primeiro endereço como selecionado
    _addressesFuture = _addressController.getUserAddresses(widget.userId);

    _addressesFuture.then((addresses) {
      if (addresses.isNotEmpty) {
        setState(() {
          _selectedAddress = addresses.first.toMap();

          _recipientNameController.text =
              _selectedAddress?['recipient_name'] ?? widget.userName ?? '';
          _streetController.text = _selectedAddress?['street'] ?? '';
          _numberController.text = _selectedAddress?['number'] ?? '';
          _complementController.text = _selectedAddress?['complement'] ?? '';
          _bairroController.text = _selectedAddress?['bairro'] ?? '';
          _cityController.text = _selectedAddress?['city'] ?? '';
          _stateController.text = _selectedAddress?['state'] ?? '';
          _zipCodeController.text = _selectedAddress?['zip_code'] ?? '';
          _countryController.text = _selectedAddress?['country'] ?? '';
          _phoneController.text = _selectedAddress?['phone'] ?? '';
        });
      }
    });

    _findAddress(widget.zipCode);

    _cardExpiryController.addListener(() {
      String text = _cardExpiryController.text;

      text = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.length > 4) {
        text = text.substring(0, 4);
      }

      if (text.length >= 2) {
        text = '${text.substring(0, 2)}/${text.substring(2)}';
      }

      if (text != _cardExpiryController.text) {
        _cardExpiryController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _numberCardController.dispose();
    _nameCardController.dispose();
    _cardExpiryController.dispose();
    _cardCVVController.dispose();
    _installmentsController.dispose();
    _zipCodeController.dispose();
    _bairroController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    final convertedProducts =
        widget.products.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> newItem = Map<String, dynamic>.from(item);
          if (newItem.containsKey('product_id')) {
            newItem['id'] = newItem['product_id'];
            //newItem.remove('product_id');
          }

          final price = newItem['price'];
          if (price is String) {
            newItem['price'] = double.tryParse(price) ?? 0.0;
          } else if (price is int) {
            newItem['price'] = price.toDouble();
          } else if (price is! double) {
            newItem['price'] = 0.0;
          }

          return newItem;
        }).toList();

    final paymentController = PaymentController();

    // Determinar qual endereço usar
    Map<String, dynamic> address = {}; // Inicializa como um mapa vazio

    if (_selectedAddress != null) {
      // Se _selectedAddress está disponível, formata o endereço
      address = {
        "recipient_name": _selectedAddress!["recipient_name"] ?? "",
        "user_name": widget.userName,
        "street": _selectedAddress!["street"] ?? "",
        "number": _selectedAddress!["number"] ?? "",
        "complement": _selectedAddress!["complement"] ?? "",
        "bairro": _selectedAddress!["bairro"] ?? "",
        "city": _selectedAddress!["city"] ?? "",
        "state": _selectedAddress!["state"] ?? "",
        "country": _selectedAddress!["country"] ?? "",
        "zip_code": _selectedAddress!["zip_code"] ?? "",
        "phone": _selectedAddress!["phone"] ?? "",
        "total_value": widget.delivery['price'] ?? "0.00",
        "delivery_id": widget.delivery['id'],
        "products": convertedProducts,
      };
    } else if (_numberController.text.isNotEmpty) {
      // Se o usuário inseriu um endereço no formulário, usamos ele
      address = {
        "recipient_name": _recipientNameController.text,
        "user_name": widget.userName,
        "street": _streetController.text,
        "number": _numberController.text,
        "complement": _complementController.text,
        "bairro": _bairroController.text,
        "city": _cityController.text,
        "state": _stateController.text,
        "country": _countryController.text,
        "zip_code": _zipCodeController.text,
        "phone": _phoneController.text,
        "total_value": widget.delivery['price'] ?? "0.00",
        "delivery_id": widget.delivery['id'],
        "products": convertedProducts,
      };
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Você deve inserir um endereço de entrega válido',
          ),
        ),
      );

      _isLoading = false;
    }

    String? token;
    String cleanedCardNumber = _numberCardController.text.replaceAll(
      RegExp(r'[\s\-.]'),
      '',
    );
    if (_selectedPayment == 'credit' || _selectedPayment == 'debit') {
      // print('Cupom aplicado: ${_appliedCoupon?.id}');
      // print('Desconto calculado: $_discount');
      final tempPayment = Payment(
        zipCode: widget.zipCode,
        userId: widget.userId,
        userEmail: widget.userEmail,
        userName: widget.userName,
        cpf: _cpfController.text,
        address: address, // Usando o endereço correto
        paymentType: _selectedPayment,
        subtotal: _subtotal,
        shipping: _shipping,
        total: _total,
        products: convertedProducts,
        numberCard: _selectedPayment != 'Pix' ? cleanedCardNumber : null,
        nameCard:
            _selectedPayment != 'Pix'
                ? _nameCardController.text.toLowerCase()
                : null,
        expiry: _selectedPayment != 'Pix' ? _cardExpiryController.text : null,
        cvv: _selectedPayment != 'Pix' ? _cardCVVController.text : null,
        installments: int.tryParse(_installmentsController.text) ?? 1,
        paymentMethodId: _selectedPaymentMethodId,
        couponAmount: _discount,
        couponCode: _appliedCoupon?.code,
      );

      final expiryParts = (tempPayment.expiry ?? '').split('/');
      final expirationMonth = int.tryParse(expiryParts[0]) ?? 0;
      final expirationYear = int.tryParse('20${expiryParts[1]}') ?? 0;

      token = await paymentController.generateCardToken(
        cardNumber: tempPayment.numberCard ?? '',
        expirationMonth: expirationMonth ?? 0,
        expirationYear: expirationYear,
        securityCode: tempPayment.cvv ?? '',
        cardholderName: tempPayment.nameCard ?? '',
        docType: docType,
        docNumber: _cpfController.text,
      );
    }

    // Criar o pagamento com o token obtido
    final payment = Payment(
      cardToken: token,
      zipCode: widget.zipCode ?? "default_value",
      userEmail: widget.userEmail,
      userId: widget.userId,
      userName: widget.userName,
      cpf: _cpfController.text,
      address: address,
      paymentType: _selectedPayment,
      subtotal: _subtotal,
      shipping: _shipping,
      total: _total,
      products: convertedProducts,
      numberCard: _selectedPayment != 'Pix' ? _numberCardController.text : null,
      nameCard: _selectedPayment != 'Pix' ? _nameCardController.text : null,
      expiry: _selectedPayment != 'Pix' ? _cardExpiryController.text : null,
      cvv: _selectedPayment != 'Pix' ? _cardCVVController.text : null,
      installments: int.tryParse(_installmentsController.text) ?? 1,
      paymentMethodId: _selectedPaymentMethodId,
      couponAmount: _discount,
      couponCode: _appliedCoupon?.code,
    );

    // Enviar o pagamento
    final controller = PaymentController();
    final response = await controller.sendPayment(payment);

    // print('Success ${response['status']}');
    if (_selectedPayment.toLowerCase() == 'pix' &&
        response.containsKey('qr_code') &&
        response.containsKey('qr_code_base64')) {
      // Exibe o QR code e código copia-e-cola na mesma tela
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pagamento via Pix'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.memory(
                    base64Decode(response['qr_code_base64']),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SelectableText(
                        response['qr_code'],
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copiar código Pix',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: response['qr_code']),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Código Pix copiado para a área de transferência',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 5),
                const Text(
                  "Escaneie o QR Code ou copie o código acima para pagar.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Fechar"),
              ),
            ],
          );
        },
      );
    } else if (response['status'] == "approved") {
      // Pagamento comum (cartão aprovado)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento aprovado com sucesso!')),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (_appliedCoupon != null) {
        await CouponsController.deleteCoupon(
          couponId: _appliedCoupon!.id,
          userId: widget.userId,
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResult(response: response),
        ),
      );
    } else if (response['status'] == 'in_process') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pagamento pendente!')));
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResult(response: response),
        ),
      );
    } else {
      // Falha no pagamento
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao enviar pagamento')));
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResult(response: response),
        ),
      );
    }
  }

  Future<void> _findAddress(String cep) async {
    final cleanedCep = cep.replaceAll(RegExp(r'\D'), '');
    if (cleanedCep.length == 8) {
      final response = await http.get(
        Uri.parse('http://viacep.com.br/ws/$cleanedCep/json'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null && !data.containsKey('error')) {
          setState(() {
            _streetController.text = data['logradouro'] ?? '';
            _cityController.text = data['localidade'] ?? '';
            _stateController.text = data['uf'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
          });
        } else {
          // Se houver erro na resposta, você pode tratar isso aqui
          print('Erro na resposta do endereço: ${data['error']}');
        }
      } else {
        print('Falha na requisição: ${response.statusCode}');
      }
    }
  }

  Future<void> _handleCouponSubmit(String couponCode) async {
    final controller = CouponsController();

    final coupon = await controller.validateCoupon(
      couponCode: couponCode,
      userId: widget.userId,
    );

    if (coupon != null) {
      setState(() {
        final discountRate = coupon.discount / 100;
        final rawDiscount = _subtotal * discountRate;

        _discount = double.parse(rawDiscount.toStringAsFixed(2));
        _appliedCoupon = coupon;

        final rawTotal = (_subtotal + _shipping) - _discount;
        _total = double.parse(rawTotal.toStringAsFixed(2));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cupom inválido."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductsList(), // Certifique-se que aqui não tem ListView com scroll
                    FutureBuilder<List<Address>>(
                      future: _addressesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            'Erro ao carregar endereço: ${snapshot.error}',
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nenhum endereço encontrado.'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final result = await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return _buildAddressFormDialog(context);
                                    },
                                  );

                                  if (result == true) {
                                    // Se o usuário adicionou um novo endereço, recarregue a lista
                                    setState(() {
                                      _addressesFuture = _addressController
                                          .getUserAddresses(widget.userId);
                                    });
                                  }
                                },
                                child: const Text('Adicionar Endereço'),
                              ),
                            ],
                          );
                        } else {
                          Address address =
                              snapshot
                                  .data!
                                  .first; // ou o selecionado, se for o caso
                          return _buildAddressCard(context, address);
                        }
                      },
                    ),
                    _buildCouponCard(context),
                    _buildPaymentCard(context),
                    _buildTotalCard(context),
                    const SizedBox(height: 16),
                    _buildElevatedButton(), // Botão azul grande
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    final apiUrl = dotenv.env['API_URL'] ?? '';
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.products.length,
      itemBuilder: (context, index) {
        final p = widget.products[index];
        // print(p);
        final imageUrl = p['image'] ?? p['image_url'] ?? '';
        final name =
            p['name'] ?? p['product_name'] ?? p['productName'] ?? 'Sem nome';
        final price = double.tryParse(p['price'].toString()) ?? 0.0;
        final quantity = int.tryParse(p['quantity'].toString()) ?? 0;
        final total = price * quantity;

        return Card(
          margin: const EdgeInsets.all(12.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      imageUrl.isNotEmpty
                          ? Image.network(
                            imageUrl,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 80),
                          )
                          : const Icon(Icons.image_not_supported, size: 80),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'R\$ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Quantidade: $quantity',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    print('Remover $name');
                    // lógica de remoção aqui
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery to Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Atualizado para acessar corretamente os dados de _selectedAddress
                    Text(
                      _selectedAddress != null
                          ? _selectedAddress!['recipient_name'] ??
                              'Nome não informado'
                          : address.recipientName,
                    ),
                    Text(
                      _selectedAddress != null
                          ? '${_selectedAddress!['street']}, ${_selectedAddress!['number']}, ${_selectedAddress!['complement']} ,${_selectedAddress!['bairro']}'
                          : '${address.street}, ${address.number}, ${address.complement} ,${address.bairro}',
                    ),
                    Text(
                      _selectedAddress != null
                          ? '${_selectedAddress!['city']}, ${_selectedAddress!['state']}, ${_selectedAddress!['zip_code']}'
                          : '${address.city}, ${address.state} ,  ${address.zipCode}',
                    ),
                    SizedBox(height: 6),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildAddressFormDialog(context);
                    },
                  );
                },
                child: const Text('Change'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final existingAddress = await _addressController
                        .getUserAddresses(widget.userId);

                    final id = existingAddress.first.id;

                    if (id != null) {
                      await _addressController.deleteAddress(id);
                      Navigator.of(context).pop(); // Fecha o diálogo
                      Navigator.of(
                        context,
                      ).pop(true); // Retorna true para indicar sucesso
                    } else {
                      print('ID do endereço não encontrado');
                    }
                  } catch (e) {
                    print('Erro ao remover endereço: $e');
                    Navigator.of(
                      context,
                    ).pop(); // Fecha o diálogo mesmo com erro
                  }
                },
                child: const Text('remove'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressFormDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Address'),
      content: SingleChildScrollView(
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 48,
                child: TextField(
                  controller: _recipientNameController,
                  decoration: InputDecoration(
                    labelText: 'Recipient name ex(${widget.userName})',
                    hintText: widget.userName.isNotEmpty ? widget.userName : '',
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 48,
                child: TextField(
                  controller: _zipCodeController,
                  decoration: const InputDecoration(labelText: 'CEP'),
                  keyboardType: TextInputType.number,
                  onSubmitted: _findAddress,
                ),
              ),

              Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 32,
                    child: TextField(
                      controller: _streetController,
                      decoration: const InputDecoration(labelText: 'Street'),
                      onChanged: (value) {
                        setState(() {
                          _selectedAddress?['street'] = value;
                        });
                      },
                    ),
                  ),

                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 32,
                    child: TextField(
                      controller: _numberController,
                      decoration: const InputDecoration(labelText: 'Number'),
                      onChanged: (value) {
                        setState(() {
                          _selectedAddress?['recipient_name'] = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 48,
                child: TextField(
                  controller: _complementController,
                  decoration: const InputDecoration(labelText: 'Complement'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 32,
                    child: TextField(
                      controller: _bairroController,
                      decoration: const InputDecoration(labelText: 'Bairro'),
                    ),
                  ),

                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 32,
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width:
                        MediaQuery.of(context).size.width / 2 -
                        32, // defina a largura desejada
                    child: DropdownButtonFormField<String>(
                      value: _estadoSelecionado,
                      decoration: InputDecoration(
                        labelText: _stateController.text ?? 'state',
                      ),
                      items:
                          estados.map((String estado) {
                            return DropdownMenuItem<String>(
                              value: estado,
                              child: Text(estado),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _estadoSelecionado = newValue;
                          _stateController.text = newValue ?? '';
                        });
                      },
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Campo obrigatório'
                                  : null,
                    ),
                  ),

                  //  SizedBox(
                  //    width: 100,
                  //    child: TextField(
                  //      controller: _stateController,
                  //      decoration: const InputDecoration(labelText: 'State'),
                  //    ),
                  //  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 32,
                    child: TextField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Country'),
                    ),
                  ),
                ],
              ),

              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 48,
                child: TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
              ),
              onPressed: () async {
                if (_recipientNameController.text.trim().isEmpty ||
                    _complementController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Preencha os campos obrigatórios: Nome do destinatário e Complemento.',
                      ),
                    ),
                  );
                  return;
                }

                final addressData = {
                  "user_id": widget.userId,
                  "recipient_name": _recipientNameController.text,
                  "street": _streetController.text,
                  "number": _numberController.text,
                  "complement": _complementController.text,
                  "city": _cityController.text,
                  "state": _stateController.text,
                  "zip_code": _zipCodeController.text,
                  "country": _countryController.text,
                  "bairro": _bairroController.text,
                  "phone": _phoneController.text,
                };

                final existingAddress = await _addressController
                    .getUserAddresses(widget.userId);

                if (existingAddress.isNotEmpty) {
                  final addressId = existingAddress.first.id;
                  final updateSuccess = await _addressController.updateAddress(
                    addressId!,
                    addressData,
                  );

                  if (updateSuccess) {
                    List<Address> updatedAddresses = await _addressController
                        .getUserAddresses(widget.userId);

                    if (updatedAddresses.isNotEmpty) {
                      Map<String, dynamic> updatedAddressMap =
                          updatedAddresses.first.toJson();

                      setState(() {
                        _selectedAddress = updatedAddressMap;
                      });
                    }

                    Navigator.of(context).pop(true);
                  } else {
                    print('Erro ao atualizar endereço');
                  }
                } else {
                  final insertedAddress = await _addressController
                      .insertAddress(addressData);

                  if (insertedAddress != null) {
                    setState(() {
                      _addressController.getUserAddresses(widget.userId);
                    });
                    Navigator.of(context).pop(true);
                  } else {
                    print('Erro ao salvar endereço');
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCouponCard(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Discount Coupon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: const InputDecoration(
                        hintText: 'Enter coupon code',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _handleCouponSubmit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _handleCouponSubmit(_couponController.text);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Cartão de Crédito'),
                value: 'credit',
                groupValue: _selectedPayment,
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Cartão de Débito'),
                value: 'debit',
                groupValue: _selectedPayment,
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Pix'),
                value: 'pix',
                groupValue: _selectedPayment,
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              if (_selectedPayment == 'credit' || _selectedPayment == 'debit')
                _buildCardPaymentForm()
              else if (_selectedPayment == 'pix')
                _buildPixInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _cpfController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'CPF'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedPayment == 'credit') ...[
              // Número de Parcelas
              SizedBox(
                height: 60,
                child: DropdownButtonFormField<int>(
                  value: _selectedInstallment,
                  decoration: InputDecoration(
                    labelText: 'Número de Parcelas',
                    isDense: true,
                  ),
                  items:
                      List.generate(4, (index) => index + 1)
                          .map(
                            (number) => DropdownMenuItem<int>(
                              value: number,
                              child: Text('$number'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInstallment = value!;
                      _installmentsController.text = value.toString();
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor, selecione o número de parcelas';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),
              // Cartões de Crédito
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Forma de Pagamento',
                  border: OutlineInputBorder(),
                ),
                value: _selectedPaymentMethodId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPaymentMethodId = newValue;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'visa', child: Text('Visa')),
                  DropdownMenuItem(value: 'master', child: Text('Mastercard')),
                  DropdownMenuItem(
                    value: 'amex',
                    child: Text('American Express'),
                  ),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione um método de pagamento';
                  }
                  return null;
                },
              ),
            ] else if (_selectedPayment == 'debit') ...[
              // Cartão de Débito
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Forma de Pagamento (Débito)',
                  border: OutlineInputBorder(),
                ),
                value: _selectedPaymentMethodId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPaymentMethodId = newValue;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'visa', child: Text('Visa')),
                  DropdownMenuItem(value: 'master', child: Text('Mastercard')),
                  DropdownMenuItem(value: 'elo', child: Text('Elo')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione um método de pagamento';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),

        TextField(
          controller: _numberCardController,
          decoration: InputDecoration(labelText: 'Número do Cartão'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),

        TextField(
          controller: _nameCardController,
          decoration: InputDecoration(labelText: 'Nome no Cartão'),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardExpiryController,
                decoration: InputDecoration(labelText: 'Validade MM/AA'),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              child: TextField(
                controller: _cardCVVController,
                decoration: InputDecoration(labelText: '*CVV'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3), // Limita a 3 caracteres
                  FilteringTextInputFormatter
                      .digitsOnly, // Permite apenas números
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPixInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Você selecionou pagamento via pix"),
        Text('A chave pix será exibida após o pedido'),
      ],
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    int installments = int.tryParse(_installmentsController.text) ?? 1;

    // Verifica se há cupom aplicado e calcula desconto
    double discountPercent = _appliedCoupon?.discount ?? 0.0;
    double discountAmount = _subtotal * (discountPercent / 100);
    double discountedSubtotal = _subtotal - discountAmount;

    double finalTotal = discountedSubtotal + _shipping;
    double totalInstallments = finalTotal / installments;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('Subtotal: R\$ ${_subtotal.toStringAsFixed(2)}'),
              Text('Shipping: R\$ ${_shipping.toStringAsFixed(2)}'),
              if (_appliedCoupon != null)
                Text(
                  'Discount (${_appliedCoupon!.code}): -R\$ ${discountAmount.toStringAsFixed(2)}',
                ),
              const SizedBox(height: 8),
              Text('Discount: R\$ ${_discount.toStringAsFixed(2)}'),
              Text(
                _selectedInstallment == null
                    ? 'Total: R\$ ${_total.toStringAsFixed(2)}'
                    : 'Total: R\$ ${((_total) / _selectedInstallment!).toStringAsFixed(2)} '
                        'x $_selectedInstallment = R\$ ${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _isLoading ? null : _handlePayment,
        child:
            _isLoading
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                : const Text(
                  'Place Order Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }
}

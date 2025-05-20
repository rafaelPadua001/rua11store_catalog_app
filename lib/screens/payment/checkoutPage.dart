import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:rua11store_catalog_app/models/adress.dart';
import 'package:rua11store_catalog_app/models/cardbrand.dart';
import 'package:rua11store_catalog_app/screens/payment/payment_result.dart';
import '../../controllers/PaymentController.dart';
import '../../controllers/addressController.dart';
import '../../models/payment.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class CheckoutPage extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String zipCode;
  final List<Map> products;
  final Map delivery;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.products,
    required this.delivery,
    required this.zipCode,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPayment = 'Crédito'; // valor padrão
  String? _selectedPaymentMethodId;
  double _subtotal = 0.0;
  double _shipping = 0.0;
  double _total = 0.0;
  int _quantity = 1;
  bool _isLoading = false;
  late TextEditingController _numberCardController;
  late TextEditingController _nameCardController;
  late TextEditingController _cardExpiryController;
  late TextEditingController _cardCVVController;

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
  ];

  int? _selectedInstallment;
  CardBrand? selectedBrand;
  final TextEditingController _cpfController = MaskedTextController(
    mask: '000.000.000-00',
  );
  final docType = 'CPF';
  late TextEditingController _installmentsController = TextEditingController();
  final TextEditingController _recipientNameController = TextEditingController(
    text: "João da Silva",
  );
  final TextEditingController _streetController = TextEditingController(
    text: "Rua das Laranjeiras",
  );
  final TextEditingController _numberController = TextEditingController(
    text: "456",
  );
  final TextEditingController _complementController = TextEditingController(
    text: "Casa dos fundos",
  );
  final TextEditingController _cityController = TextEditingController(
    text: "Rio de Janeiro",
  );
  final TextEditingController _stateController = TextEditingController(
    text: "RJ",
  );
  late TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(
    text: "Brasil",
  );
  late TextEditingController _bairroController = TextEditingController(
    text: 'Bairro ...',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "(21) 99999-9999",
  );
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
    _zipCodeController = TextEditingController(text: widget.zipCode);
    _bairroController = TextEditingController();

    _subtotal = widget.products.fold<double>(0.0, (sum, item) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      _quantity = int.tryParse(item['quantity'].toString()) ?? 1;
      return sum + (price * _quantity);
    });

    _shipping = double.tryParse(widget.delivery['price'].toString()) ?? 0.0;
    int installments = int.tryParse(_installmentsController.text) ?? 1;
    _total = (_subtotal + _shipping) / installments;

    _findAddress(widget.zipCode);
    _addressesFuture = _addressController.getUserAddresses(widget.userId);

    _cardExpiryController.addListener(() {
      String text = _cardExpiryController.text;

      // Remove qualquer caractere não numérico e barra
      text = text.replaceAll(RegExp(r'[^0-9]'), '');

      if (text.length >= 2) {
        // Adiciona a barra após os dois primeiros dígitos
        text = '${text.substring(0, 2)}/${text.substring(2)}';
      }

      // Evita loop de atualização
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
    super.dispose();
  }

  void _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    final convertedProducts =
        widget.products.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> newItem = Map<String, dynamic>.from(item);
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
    } else if (_streetController.text.isNotEmpty) {
      // Se o usuário inseriu um endereço no formulário, usamos ele
      address = {
        "recipient_name": _recipientNameController.text,
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
    }

    String? token;
    String cleanedCardNumber = _numberCardController.text.replaceAll(
      RegExp(r'[\s\-.]'),
      '',
    );
    if (_selectedPayment == 'credit' || _selectedPayment == 'debit') {
      final tempPayment = Payment(
        zipCode: widget.zipCode,
        userId: widget.userId,
        userEmail: widget.userEmail,
        cpf: _cpfController.text,
        address: address, // Usando o endereço correto
        paymentType: _selectedPayment,
        subtotal: _subtotal,
        shipping: _shipping,
        total: _total,
        products: convertedProducts,
        numberCard: _selectedPayment != 'Pix' ? cleanedCardNumber : null,
        nameCard: _selectedPayment != 'Pix' ? _nameCardController.text : null,
        expiry: _selectedPayment != 'Pix' ? _cardExpiryController.text : null,
        cvv: _selectedPayment != 'Pix' ? _cardCVVController.text : null,
        installments: int.tryParse(_installmentsController.text) ?? 1,
        paymentMethodId: _selectedPaymentMethodId,
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
      paymentMethodId: _selectedPaymentMethodId, // <-- aqui
    );

    // Enviar o pagamento
    final controller = PaymentController();
    final response = await controller.sendPayment(payment);

    print('Success ${response['status']}');
    if (response['status'] == "approved") {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento enviado com sucesso!')),
      );
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResult(response: response),
        ), // substitua HomePage pela sua home real
      );
    } else {
      _isLoading = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao enviar pagamento')));

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResult(response: response),
        ), // substitua HomePage pela sua home real
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
        print(p);
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
                            apiUrl + imageUrl,
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
                          ? '${_selectedAddress!['street']}, ${_selectedAddress!['number']}'
                          : '${address.street}, ${address.number}, ${address.complement} ,${address.bairro}',
                    ),
                    Text(
                      _selectedAddress != null
                          ? '${_selectedAddress!['city']}, ${_selectedAddress!['state']} ${_selectedAddress!['zip_code']}'
                          : '${address.city}, ${address.state} ,  ${address.zipCode}',
                    ),
                    // Text(
                    //   _selectedAddress != null
                    //       ? _selectedAddress!['bairro'] ??
                    //           'Bairro não informado'
                    //       : address.bairro,
                    // ),
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _zipCodeController,
            decoration: const InputDecoration(labelText: 'CEP'),
            keyboardType: TextInputType.number,
            onSubmitted: _findAddress,
          ),
          TextField(
            controller: _recipientNameController,
            decoration: const InputDecoration(labelText: 'Recipient Name'),
          ),
          TextField(
            controller: _streetController,
            decoration: const InputDecoration(labelText: 'Street'),
            onChanged: (value) {
              setState(() {
                _selectedAddress?['street'] = value;
              });
            },
          ),
          TextField(
            controller: _numberController,
            decoration: const InputDecoration(labelText: 'Number'),
          ),
          TextField(
            controller: _complementController,
            decoration: const InputDecoration(labelText: 'Complement'),
          ),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City'),
          ),
          TextField(
            controller: _stateController,
            decoration: const InputDecoration(labelText: 'State'),
          ),
          TextField(
            controller: _bairroController,
            decoration: const InputDecoration(labelText: 'bairro'),
          ),
          TextField(
            controller: _countryController,
            decoration: const InputDecoration(labelText: 'Country'),
          ),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Fecha o dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Coleta os dados dos controladores
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

            // Verifica se já existe um endereço para este usuário
            final existingAddress = await _addressController.getUserAddresses(
              widget.userId,
            );

            if (existingAddress.isNotEmpty) {
              // Se existir, chama o update
              final addressId = existingAddress.first.id;
              final updateSuccess = await _addressController.updateAddress(
                addressId!,
                addressData,
              );

              if (updateSuccess) {
                // Recupera os endereços atualizados (apenas o primeiro, no caso de um único endereço)
                List<Address> updatedAddresses = await _addressController
                    .getUserAddresses(widget.userId);

                if (updatedAddresses.isNotEmpty) {
                  // Pega o primeiro endereço da lista e converte para Map<String, dynamic>
                  Map<String, dynamic> updatedAddressMap =
                      updatedAddresses.first.toJson();

                  setState(() {
                    _selectedAddress =
                        updatedAddressMap; // Atualiza o único endereço
                  });
                }

                Navigator.of(context).pop(true); // Fecha a tela
              } else {
                // Exibe erro de atualização
                print('Erro ao atualizar endereço');
              }
            } else {
              // Se não existir, chama o insert
              final insertedAddress = await _addressController.insertAddress(
                addressData,
              );

              // Verifica se a inserção foi bem-sucedida (verifica se o valor não é nulo)
              if (insertedAddress != null) {
                setState(() {
                  // Se a inserção foi bem-sucedida, atualize a UI com o novo endereço
                  _addressController.getUserAddresses(
                    widget.userId,
                  ); // Opcional, dependendo de como você usa os dados
                });
                Navigator.of(context).pop(true); // Fecha a tela
              } else {
                // Exibe erro de inserção
                print('Erro ao salvar endereço');
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
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
        _selectedPayment == 'credit'
            ? SizedBox(
              height: 60, // Tamanho fixo ou mínimo
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
            )
            : SizedBox.shrink(),
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
          items: [
            DropdownMenuItem(value: 'visa', child: Text('Visa')),
            DropdownMenuItem(value: 'master', child: Text('Mastercard')),
            DropdownMenuItem(value: 'amex', child: Text('American Express')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Selecione um método de pagamento';
            }
            return null;
          },
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
                decoration: InputDecoration(labelText: 'CVV'),
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
    int installments =
        int.tryParse(_installmentsController.text) ??
        1; // Valor padrão de 1 se não for válido
    double totalInstallments = (_subtotal + _shipping) / installments;
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
              Text('Shipping: R\$ $_shipping'),
              const SizedBox(height: 8),

              Text(
                _selectedInstallment == null
                    ? 'Total: R\$ ${_total.toStringAsFixed(2)}'
                    : 'Total: R\$ ${(totalInstallments * _selectedInstallment!).toStringAsFixed(2)} '
                        'x $_selectedInstallment = R\$ ${totalInstallments.toStringAsFixed(2)}',
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

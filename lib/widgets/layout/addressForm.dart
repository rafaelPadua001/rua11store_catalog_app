import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/addressController.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class AddressForm extends StatefulWidget {
  const AddressForm({super.key});

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final addressController = AddressController();
  int? _addressId;

  // Controladores para os campos
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = MaskedTextController(
    mask: '00000-000',
  );
  final TextEditingController _countryController = TextEditingController();

  // Novo controlador para o telefone
  final TextEditingController _phoneController = MaskedTextController(
    mask: '(00) 00000-0000',
  );
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

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      final response =
          await supabase
              .from('user_profiles')
              .select('*, addresses(*)')
              .eq('user_id', user.id)
              .maybeSingle();

      if (response != null) {
        setState(() {
          final addressList = response['addresses'];
          final address =
              (addressList != null &&
                      addressList is List &&
                      addressList.isNotEmpty)
                  ? addressList.first
                  : null;

          _addressId =
              address != null && address['id'] != null
                  ? int.tryParse(address['id'].toString())
                  : null;

          final fullName = response['full_name'] ?? '';

          final recipientName =
              fullName.isNotEmpty ? fullName : address?['recipient_name'] ?? '';

          _recipientNameController.text = recipientName;

          _streetController.text =
              address != null
                  ? address['street'] ?? ''
                  : response['street'] ?? '';
          _numberController.text =
              address != null
                  ? address['number'] ?? ''
                  : response['number'] ?? '';
          _complementController.text =
              address != null
                  ? address['complement'] ?? ''
                  : response['complement'] ?? '';
          _bairroController.text =
              address != null
                  ? address['bairro'] ?? ''
                  : response['bairro'] ?? '';
          _cityController.text =
              address != null ? address['city'] ?? '' : response['city'] ?? '';
          _stateController.text =
              address != null
                  ? address['state'] ?? ''
                  : response['state'] ?? '';
          _zipCodeController.text =
              address != null
                  ? address['zip_code'] ?? ''
                  : response['zip_code'] ?? '';
          _countryController.text =
              address != null
                  ? address['country'] ?? ''
                  : response['country'] ?? '';
          _phoneController.text =
              address != null
                  ? address['phone'] ?? ''
                  : response['phone'] ?? '';
        });
      }
    }

    setState(() {
      _loading = false;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('Usuário não autenticado');
        return;
      }

      final address = {
        'recipient_name': _recipientNameController.text,
        'street': _streetController.text,
        'number': _numberController.text,
        'complement': _complementController.text,
        'bairro': _bairroController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zip_code': _zipCodeController.text,
        'country': _countryController.text,
        'phone': _phoneController.text, // campo telefone enviado
        'user_id': user.id,
      };

      print(_addressId);

      if (_addressId == null) {
        // Inserir novo endereço
        final result = await addressController.insertAddress(address);
        if (result != null) {
          print('Endereço inserido: $result');
          setState(() {
            _addressId = int.tryParse(
              result['id'].toString(),
            ); // armazena id após inserção
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('endereço cadastrado com sucesso')),
          );
        }
      } else {
        // Atualizar endereço existente
        final result = await addressController.updateAddress(
          _addressId!,
          address,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('endereço atualizado com sucesso')),
        );
      }
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _bairroController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose(); // dispose do controlador novo
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _recipientNameController,
            decoration: const InputDecoration(
              labelText: 'Nome do destinatário',
            ),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
          ),
          TextFormField(
            controller: _streetController,
            decoration: const InputDecoration(labelText: 'Rua'),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
          ),
          TextFormField(
            controller: _numberController,
            decoration: const InputDecoration(labelText: 'Número'),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
          ),
          TextFormField(
            controller: _complementController,
            decoration: const InputDecoration(labelText: 'Complemento'),
          ),
          TextFormField(
            controller: _bairroController,
            decoration: const InputDecoration(labelText: 'Bairro'),
          ),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'Cidade'),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
          ),
          DropdownButtonFormField<String>(
            value: _estadoSelecionado,

            decoration: InputDecoration(
              labelText: _stateController.text ?? 'Estado',
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
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
          ),
          TextFormField(
            controller: _zipCodeController,
            decoration: const InputDecoration(labelText: 'CEP'),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
          ),
          TextFormField(
            controller: _countryController,
            decoration: const InputDecoration(labelText: 'País'),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
          ),
          // Campo telefone novo obrigatório
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Telefone'),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Salvar Endereço'),
          ),
        ],
      ),
    );
  }
}

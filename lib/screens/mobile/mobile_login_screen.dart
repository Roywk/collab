import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/user_account_repository.dart';
import '../../models/user_profile.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({required this.repository, super.key});

  final UserAccountRepository repository;

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactRelationshipController =
      TextEditingController();

  late Future<List<BankChoice>> _banksFuture;
  final Set<String> _selectedBankIds = <String>{};

  bool _registering = false;
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _banksFuture = widget.repository.getAvailableBanks();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    try {
      if (_registering) {
        final response = await widget.repository.signUp(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phoneNumber: _phoneController.text,
          nationality: _nationalityController.text,
          bankIds: _selectedBankIds.toList(growable: false),
          emergencyContactName: _contactNameController.text,
          emergencyContactPhone: _contactPhoneController.text,
          emergencyContactRelationship: _contactRelationshipController.text,
        );
        if (response.session == null && mounted) {
          setState(() {
            _registering = false;
            _message =
                'Account created. Check your email to confirm the '
                'account, then sign in.';
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        }
      } else {
        await widget.repository.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AuthException ? error.message : error.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    try {
      await widget.repository.sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _message = 'Password reset instructions were sent to $email.';
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AuthException ? error.message : error.toString();
      });
    }
  }

  Future<void> _openAdminLogin() async {
    await Navigator.of(context).pushNamed('/admin');
  }

  void _switchMode() {
    setState(() {
      _registering = !_registering;
      _error = null;
      _message = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x241E40AF),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Visit 1MY',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _registering
                        ? 'Create your secure tourist account'
                        : 'Sign in to continue your safer journey',
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _registering ? 'Create Account' : 'Welcome Back',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _registering
                                ? 'Enter your details to register.'
                                : 'Enter your account details to sign in.',
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_registering) ...[
                            TextFormField(
                              controller: _fullNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 11),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (!RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(email)) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          if (_registering) ...[
                            const SizedBox(height: 11),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                                hintText: '+60123456789',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 11),
                            TextFormField(
                              controller: _nationalityController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nationality',
                                prefixIcon: Icon(Icons.public_outlined),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 11),
                            FutureBuilder<List<BankChoice>>(
                              future: _banksFuture,
                              builder: (context, snapshot) {
                                final banks =
                                    snapshot.data ?? const <BankChoice>[];
                                return _BankMultiSelectField(
                                  banks: banks,
                                  selectedIds: _selectedBankIds,
                                  loading:
                                      snapshot.connectionState ==
                                      ConnectionState.waiting,
                                  loadError: snapshot.hasError
                                      ? 'Banks could not be loaded.'
                                      : null,
                                  onChanged: (ids) {
                                    setState(() {
                                      _selectedBankIds
                                        ..clear()
                                        ..addAll(ids);
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 17),
                            const Text(
                              'PRIMARY EMERGENCY CONTACT',
                              style: TextStyle(
                                color: AppColors.slate,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _contactNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Contact name',
                                prefixIcon: Icon(
                                  Icons.contact_emergency_outlined,
                                ),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 11),
                            TextFormField(
                              controller: _contactPhoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Contact phone (international)',
                                hintText: '+60123456789',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: _validateE164Phone,
                            ),
                            const SizedBox(height: 11),
                            TextFormField(
                              controller: _contactRelationshipController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Relationship',
                                prefixIcon: Icon(Icons.people_outline),
                              ),
                              validator: _required,
                            ),
                          ],
                          const SizedBox(height: 11),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _hidePassword,
                            textInputAction: _registering
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_registering) _submit();
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').length < 8) {
                                return 'Password must contain at least 8 characters.';
                              }
                              return null;
                            },
                          ),
                          if (_registering) ...[
                            const SizedBox(height: 11),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _hidePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? 'Passwords do not match.'
                                  : null,
                            ),
                          ],
                          if (!_registering)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _forgotPassword,
                                child: const Text('Forgot password?'),
                              ),
                            )
                          else
                            const SizedBox(height: 16),
                          if (_error != null) _LoginMessage.error(_error!),
                          if (_message != null)
                            _LoginMessage.success(_message!),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _registering
                                          ? 'Create Account'
                                          : 'Sign In',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _loading ? null : _switchMode,
                            child: Text(
                              _registering
                                  ? 'Already have an account? Sign In'
                                  : 'New to Visit 1MY? Create Account',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _loading ? null : _openAdminLogin,
                    icon: const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 17,
                    ),
                    label: const Text('Administrator Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return (value ?? '').trim().isEmpty ? 'This field is required.' : null;
  }

  String? _validateE164Phone(String? value) {
    final phone = value?.trim() ?? '';
    if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone)) {
      return 'Use international format, e.g. +60123456789.';
    }
    return null;
  }
}

class _BankMultiSelectField extends FormField<Set<String>> {
  _BankMultiSelectField({
    required List<BankChoice> banks,
    required Set<String> selectedIds,
    required bool loading,
    required ValueChanged<Set<String>> onChanged,
    String? loadError,
  }) : super(
         initialValue: Set<String>.of(selectedIds),
         validator: (value) => (value == null || value.isEmpty)
             ? 'Select at least one bank.'
             : null,
         builder: (field) {
           final selected = field.value ?? <String>{};
           final banksById = {for (final bank in banks) bank.id: bank};
           final selectedBanks = <BankChoice>[
             for (final id in selected)
               if (banksById.containsKey(id)) banksById[id]!,
           ];

           Future<void> chooseBanks() async {
             if (loading || banks.isEmpty) return;
             final result = await showModalBottomSheet<Set<String>>(
               context: field.context,
               isScrollControlled: true,
               showDragHandle: true,
               builder: (context) => _BankSelectionSheet(
                 banks: banks,
                 initialSelection: selected,
               ),
             );
             if (result == null) return;
             field.didChange(result);
             onChanged(result);
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               InkWell(
                 onTap: chooseBanks,
                 borderRadius: BorderRadius.circular(12),
                 child: InputDecorator(
                   decoration: InputDecoration(
                     errorText: field.errorText ?? loadError,
                     prefixIcon: const Icon(Icons.account_balance_outlined),
                     suffixIcon: loading
                         ? const Padding(
                             padding: EdgeInsets.all(13),
                             child: SizedBox(
                               width: 16,
                               height: 16,
                               child: CircularProgressIndicator(strokeWidth: 2),
                             ),
                           )
                         : const Icon(Icons.keyboard_arrow_down_rounded),
                   ),
                   child: Text(
                     selectedBanks.isEmpty
                         ? 'Select your bank'
                         : selectedBanks.first.name,
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                     style: TextStyle(
                       color: selectedBanks.isEmpty
                           ? AppColors.muted
                           : AppColors.navy,
                       fontSize: 13,
                     ),
                   ),
                 ),
               ),
               const SizedBox(height: 2),
               Row(
                 children: [
                   TextButton.icon(
                     onPressed: loading || banks.isEmpty ? null : chooseBanks,
                     style: TextButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 4),
                       minimumSize: const Size(0, 34),
                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                     ),
                     icon: const Icon(Icons.add_rounded, size: 17),
                     label: Text(
                       selectedBanks.isEmpty
                           ? 'Select banks'
                           : 'Select more banks',
                     ),
                   ),
                   const Spacer(),
                   if (selectedBanks.isNotEmpty)
                     Text(
                       selectedBanks.length == 1
                           ? 'Primary bank'
                           : '${selectedBanks.length} banks selected',
                       style: const TextStyle(
                         color: AppColors.slate,
                         fontSize: 10,
                       ),
                     ),
                 ],
               ),
             ],
           );
         },
       );
}

class _BankSelectionSheet extends StatefulWidget {
  const _BankSelectionSheet({
    required this.banks,
    required this.initialSelection,
  });

  final List<BankChoice> banks;
  final Set<String> initialSelection;

  @override
  State<_BankSelectionSheet> createState() => _BankSelectionSheetState();
}

class _BankSelectionSheetState extends State<_BankSelectionSheet> {
  late final Set<String> _selection = Set<String>.of(widget.initialSelection);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select your banks',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select every bank you use. The first selected bank is primary.',
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.banks.length,
                itemBuilder: (context, index) {
                  final bank = widget.banks[index];
                  final checked = _selection.contains(bank.id);
                  return CheckboxListTile(
                    value: checked,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(bank.name),
                    subtitle:
                        _selection.isNotEmpty && _selection.first == bank.id
                        ? const Text('Primary bank')
                        : null,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selection.add(bank.id);
                        } else {
                          _selection.remove(bank.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _selection.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selection),
              child: Text('Use ${_selection.length} selected bank(s)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginMessage extends StatelessWidget {
  const _LoginMessage._({required this.message, required this.error});

  factory _LoginMessage.error(String message) {
    return _LoginMessage._(message: message, error: true);
  }

  factory _LoginMessage.success(String message) {
    return _LoginMessage._(message: message, error: false);
  }

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: error ? AppColors.redSoft : AppColors.greenSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: error ? AppColors.red : AppColors.green,
          fontSize: 10,
          height: 1.3,
        ),
      ),
    );
  }
}

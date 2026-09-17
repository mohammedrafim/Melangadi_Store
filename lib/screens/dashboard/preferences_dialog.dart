import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';

class PreferencesDialog extends StatefulWidget {
  const PreferencesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const PreferencesDialog(),
    );
  }

  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cashierController;
  late TextEditingController _storeNameController;
  late TextEditingController _storePhoneController;
  bool _isLoggedIn = true;

  @override
  void initState() {
    super.initState();
    final prefs = PreferencesService.instance;
    _cashierController = TextEditingController(text: prefs.cashierName);
    _storeNameController = TextEditingController(text: prefs.storeName);
    _storePhoneController = TextEditingController(text: prefs.storePhone);
    _isLoggedIn = prefs.isLoggedIn;
  }

  @override
  void dispose() {
    _cashierController.dispose();
    _storeNameController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = PreferencesService.instance;
    await prefs.setCashierName(_cashierController.text);
    await prefs.setStoreName(_storeNameController.text);
    await prefs.setStorePhone(_storePhoneController.text);
    await prefs.setLoggedIn(_isLoggedIn);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings_outlined, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Store & User Settings',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Operator / Cashier Name
                TextFormField(
                  controller: _cashierController,
                  decoration: const InputDecoration(
                    labelText: 'Active Operator / Cashier Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter operator name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Store Name
                TextFormField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Store Display Name',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter store name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Store Phone
                TextFormField(
                  controller: _storePhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Store Phone / Contact (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Login Status switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Store Session Active / Logged In', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Keeps user session persistent locally', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _isLoggedIn,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isLoggedIn = val;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Save button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _savePreferences,
                  child: const Text('Save Settings', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

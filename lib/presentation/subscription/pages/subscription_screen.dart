import 'package:flutter/material.dart';
import 'package:study_blocker/presentation/shared/widgets/custom_button.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String _selectedPlan = 'monthly';

  Future<void> _purchaseSubscription() async {
    setState(() => _isLoading = true);

    // Simulación de pasarela de pago
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Felicidades! Eres usuario PRO.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Planes Pro')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildPlanCard(
              context,
              title: 'Mensual',
              price: '\$4.99',
              id: 'monthly',
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              title: 'Anual',
              price: '\$39.99',
              id: 'yearly',
              badge: 'AHORRA 30%',
            ),
            const Spacer(),
            CustomButton(
              text: _isLoading
                  ? 'Procesando...'
                  : 'Obtener Plan ${_selectedPlan.toUpperCase()}',
              isLoading: _isLoading,
              onPressed: _purchaseSubscription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String id,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedPlan == id;

    return InkWell(
      onTap: () => setState(() => _selectedPlan = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

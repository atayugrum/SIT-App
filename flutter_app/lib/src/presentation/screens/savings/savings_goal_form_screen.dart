// File: lib/src/presentation/screens/savings/savings_goal_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../providers/savings_providers.dart';

class SavingsGoalFormScreen extends ConsumerStatefulWidget {
  final SavingsGoalModel? goalToEdit;

  const SavingsGoalFormScreen({super.key, this.goalToEdit});

  @override
  ConsumerState<SavingsGoalFormScreen> createState() => _SavingsGoalFormScreenState();
}

class _SavingsGoalFormScreenState extends ConsumerState<SavingsGoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetAmountController;
  DateTime? _selectedTargetDate;

  bool get _isEditMode => widget.goalToEdit != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goalToEdit;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _targetAmountController = TextEditingController(text: goal != null ? goal.targetAmount.toStringAsFixed(0) : '');
    _selectedTargetDate = goal?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedTargetDate = pickedDate;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final targetAmount = double.tryParse(_targetAmountController.text.trim());

    if (_selectedTargetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir hedef tarihi seçin.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      if (_isEditMode) {
        // TODO: Update metodu servise ve provider'a eklenecek.
        print("Update logic not implemented yet.");
      } else {
        await ref.read(savingsGoalNotifierProvider.notifier).createGoal(
          title: title,
          targetAmount: targetAmount!,
          targetDate: _selectedTargetDate!,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Hedef başarıyla kaydedildi!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(savingsGoalNotifierProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Hedefi Düzenle' : 'Yeni Tasarruf Hedefi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Hedef Adı (örn: Tatil Fonu)'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Lütfen bir başlık girin.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(labelText: 'Hedef Tutar', prefixText: '₺ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Lütfen bir tutar girin.';
                  if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Lütfen geçerli pozitif bir tutar girin.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Hedef Tarihi'),
                subtitle: Text(_selectedTargetDate == null
                    ? 'Tarih Seçilmedi'
                    : DateFormat.yMMMd('tr_TR').format(_selectedTargetDate!)),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDate,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white,) 
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
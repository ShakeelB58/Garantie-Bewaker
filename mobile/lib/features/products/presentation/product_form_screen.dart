import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_view.dart';
import '../application/product_providers.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/product_input.dart';
import 'widgets/date_field.dart';

/// Product toevoegen (zonder [productId]) of bewerken (met [productId]).
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({this.productId, super.key});

  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = productId;
    if (id == null) return const _ProductForm(initial: null);

    final product = ref.watch(productByIdProvider(id));
    return product.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Product bewerken')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Product bewerken')),
        body: ErrorView(error: error),
      ),
      data: (product) => product == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Product bewerken')),
              body: const Center(child: Text('Dit product bestaat niet meer.')),
            )
          : _ProductForm(key: ValueKey(product.id), initial: product),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({required this.initial, super.key});

  final Product? initial;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _merchant;
  late final TextEditingController _price;
  late ProductCategory _category;
  late String _currency;
  DateTime? _purchaseDate;
  DateTime? _warrantyEndDate;
  late bool _reminderEnabled;
  DateTime? _reminderDate;

  Map<ProductField, String> _errors = const {};
  bool _saving = false;
  bool _dirty = false;

  /// Zet terugnavigatie vrij nadat de gebruiker wijzigingen heeft weggegooid.
  bool _allowPop = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final input = initial == null
        ? ProductInput(
            purchaseDate: Dates.dateOnly(ref.read(clockProvider)()),
          )
        : ProductInput.fromProduct(initial);

    _name = TextEditingController(text: input.name);
    _brand = TextEditingController(text: input.brand);
    _merchant = TextEditingController(text: input.merchant);
    _price = TextEditingController(text: input.priceText);
    _category = input.category;
    _currency = input.currency;
    _purchaseDate = input.purchaseDate;
    _warrantyEndDate = input.warrantyEndDate;
    _reminderEnabled = input.reminderEnabled;
    _reminderDate = input.reminderDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _merchant.dispose();
    _price.dispose();
    super.dispose();
  }

  ProductInput get _input => ProductInput(
    name: _name.text,
    brand: _brand.text,
    merchant: _merchant.text,
    category: _category,
    purchaseDate: _purchaseDate,
    priceText: _price.text,
    currency: _currency,
    warrantyEndDate: _warrantyEndDate,
    reminderEnabled: _reminderEnabled,
    reminderDate: _reminderDate,
  );

  void _changed(ProductField? field, VoidCallback update) {
    setState(() {
      update();
      _dirty = true;
      if (field != null && _errors.containsKey(field)) {
        _errors = Map.of(_errors)..remove(field);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    final now = ref.read(clockProvider)();
    final input = _input;
    final errors = ProductValidator.validate(input, today: now);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) {
      _showMessage('Controleer de gemarkeerde velden.');
      return;
    }

    final initial = widget.initial;
    final product = input.toProduct(
      id: initial?.id ?? ref.read(idGeneratorProvider)(),
      createdAt: initial?.createdAt ?? now,
      now: now,
    );

    setState(() => _saving = true);
    try {
      await ref.read(productsProvider.notifier).save(product);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(userMessageFor(error));
      return;
    }
    if (!mounted) return;

    // Tijdens het opslaan staat _saving op true, waardoor PopScope de
    // navigatie hieronder niet tegenhoudt.
    final messenger = ScaffoldMessenger.of(context);
    if (_isEdit) {
      context.pop();
    } else {
      context.pushReplacement(AppRoutes.productDetail(product.id));
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Product opgeslagen.')));
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wijzigingen weggooien?'),
        content: const Text('Je wijzigingen worden niet opgeslagen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Verder bewerken'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Weggooien'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      // Pas na de volgende opbouw is PopScope vrijgegeven.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = Dates.dateOnly(ref.read(clockProvider)());
    final firstDate = DateTime(1990);
    final lastFutureDate = DateTime(today.year + 30, 12, 31);

    return PopScope<Object?>(
      canPop: !_dirty || _saving || _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Product bewerken' : 'Product toevoegen'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _SectionTitle('Product'),
            TextField(
              key: const Key('productForm.name'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: ProductValidator.maxNameLength,
              decoration: InputDecoration(
                labelText: 'Productnaam *',
                hintText: 'bijv. Wasmachine',
                errorText: _errors[ProductField.name],
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (_) => _changed(ProductField.name, () {}),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('productForm.brand'),
              controller: _brand,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Merk (optioneel)',
                errorText: _errors[ProductField.brand],
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _changed(ProductField.brand, () {}),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ProductCategory>(
              key: const Key('productForm.category'),
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categorie',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in ProductCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) _changed(null, () => _category = value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionTitle('Aankoop'),
            TextField(
              key: const Key('productForm.merchant'),
              controller: _merchant,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Winkel of verkoper (optioneel)',
                errorText: _errors[ProductField.merchant],
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _changed(ProductField.merchant, () {}),
            ),
            const SizedBox(height: AppSpacing.md),
            DateField(
              key: const Key('productForm.purchaseDate'),
              label: 'Aankoopdatum *',
              value: _purchaseDate,
              firstDate: firstDate,
              lastDate: today,
              errorText: _errors[ProductField.purchaseDate],
              onChanged: (value) =>
                  _changed(ProductField.purchaseDate, () => _purchaseDate = value),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    key: const Key('productForm.price'),
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Aankoopprijs (optioneel)',
                      hintText: 'bijv. 1.299,00',
                      errorText: _errors[ProductField.price],
                      errorMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _changed(ProductField.price, () {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    key: const Key('productForm.currency'),
                    initialValue: _currency,
                    decoration: InputDecoration(
                      labelText: 'Valuta',
                      errorText: _errors[ProductField.currency],
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final code in Money.supportedCurrencies)
                        DropdownMenuItem(value: code, child: Text(code)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _changed(ProductField.currency, () => _currency = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionTitle('Garantie en herinnering'),
            DateField(
              key: const Key('productForm.warrantyEndDate'),
              label: 'Garantie-einddatum (optioneel)',
              helperText:
                  'Vul zelf in tot wanneer je garantie hebt. '
                  'De app berekent dit niet.',
              value: _warrantyEndDate,
              firstDate: firstDate,
              lastDate: lastFutureDate,
              allowClear: true,
              errorText: _errors[ProductField.warrantyEndDate],
              onChanged: (value) => _changed(
                ProductField.warrantyEndDate,
                () => _warrantyEndDate = value,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              key: const Key('productForm.reminderEnabled'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Herinnering instellen'),
              subtitle: const Text(
                'De datum wordt bewaard. Meldingen op je telefoon volgen in '
                'een volgende versie.',
              ),
              value: _reminderEnabled,
              onChanged: (value) => _changed(ProductField.reminderDate, () {
                _reminderEnabled = value;
                if (value && _reminderDate == null) {
                  final base = _warrantyEndDate;
                  _reminderDate = base != null && base.isAfter(today)
                      ? base.subtract(const Duration(days: 30))
                      : null;
                  if (_reminderDate != null && _reminderDate!.isBefore(today)) {
                    _reminderDate = today;
                  }
                }
              }),
            ),
            if (_reminderEnabled)
              DateField(
                key: const Key('productForm.reminderDate'),
                label: 'Herinneringsdatum',
                value: _reminderDate,
                firstDate: firstDate,
                lastDate: lastFutureDate,
                errorText: _errors[ProductField.reminderDate],
                onChanged: (value) => _changed(
                  ProductField.reminderDate,
                  () => _reminderDate = value,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '* verplicht',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: FilledButton.icon(
              key: const Key('productForm.save'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Bezig met opslaan…' : 'Opslaan'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

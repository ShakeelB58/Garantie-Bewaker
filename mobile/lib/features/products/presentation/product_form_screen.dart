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
import '../../documents/application/document_service.dart';
import '../../documents/domain/document.dart';
import '../../documents/presentation/document_capture.dart';
import '../../documents/presentation/document_widgets.dart';
import '../application/product_providers.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/product_input.dart';
import 'widgets/date_field.dart';

/// Product toevoegen (zonder [productId]) of bewerken (met [productId]).
///
/// Bij toevoegen kunnen [initialDocuments] al gescand of geïmporteerd zijn;
/// die worden bij het opslaan aan het nieuwe product gekoppeld.
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({
    this.productId,
    this.initialDocuments = const [],
    super.key,
  });

  final String? productId;
  final List<StagedDocument> initialDocuments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = productId;
    if (id == null) {
      return _ProductForm(initial: null, initialDocuments: initialDocuments);
    }

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
  const _ProductForm({
    required this.initial,
    this.initialDocuments = const [],
    super.key,
  });

  final Product? initial;
  final List<StagedDocument> initialDocuments;

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

  /// Documenten die al veilig zijn opgeslagen, maar nog niet gekoppeld.
  late List<StagedDocument> _staged;

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
    _staged = [...widget.initialDocuments];
    // Een al gescand document telt als niet-opgeslagen wijziging.
    _dirty = _staged.isNotEmpty;
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

    final documentService = ref.read(documentServiceProvider);
    final container = ProviderScope.containerOf(context);

    setState(() => _saving = true);
    try {
      await ref.read(productsProvider.notifier).save(product);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(userMessageFor(error));
      return;
    }

    // Documenten koppelen. Mislukt dat, dan blijft het product bewaard en
    // wordt het losse bestand opgeruimd.
    var documentFailed = false;
    for (final staged in _staged) {
      try {
        await documentService.attach(staged, product.id);
      } catch (_) {
        documentFailed = true;
        await documentService.discard(staged);
      }
    }
    _staged = [];
    container.invalidate(documentsForProductProvider(product.id));
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
      ..showSnackBar(
        SnackBar(
          content: Text(
            documentFailed
                ? 'Product opgeslagen, maar een document kon niet worden '
                      'toegevoegd. Probeer het opnieuw via het productscherm.'
                : 'Product opgeslagen.',
          ),
        ),
      );
  }

  Future<void> _addDocument() async {
    final service = ref.read(documentServiceProvider);
    final source = await showDocumentSourceSheet(context);
    if (source == null || !mounted) return;
    final staged = await acquireDocument(context, ref, source);
    if (staged == null) return;
    if (!mounted) {
      // Formulier is intussen gesloten: bestand niet laten slingeren.
      await service.discard(staged);
      return;
    }
    _changed(null, () => _staged = [..._staged, staged]);
  }

  void _removeStaged(StagedDocument staged) {
    ref.read(documentServiceProvider).discard(staged);
    _changed(null, () => _staged = [..._staged]..remove(staged));
  }

  void _handleBack() {
    if (_dirty && !_saving && !_allowPop) {
      _confirmDiscard();
    } else {
      context.pop();
    }
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
      final service = ref.read(documentServiceProvider);
      for (final staged in _staged) {
        service.discard(staged);
      }
      _staged = [];
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
          // Eigen terugknop: zo vraagt de app altijd om bevestiging bij
          // niet-opgeslagen wijzigingen, ongeacht hoe de router het
          // terugnavigeren afhandelt. PopScope hierboven vangt de
          // systeem-terugknop (Android) en veeggebaren (iOS) af.
          leading: BackButton(onPressed: _handleBack),
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
            if (!_isEdit) ...[
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Aankoopbewijzen'),
              for (final staged in _staged)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Card(
                    child: DocumentTile(
                      title: staged.type.label,
                      subtitle: staged.originalFilename ?? 'Nieuw document',
                      format: staged.format,
                      trailing: IconButton(
                        tooltip: 'Document weghalen',
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeStaged(staged),
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('productForm.addDocument'),
                  onPressed: _addDocument,
                  icon: const Icon(Icons.add),
                  label: const Text('Document toevoegen'),
                ),
              ),
            ],
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

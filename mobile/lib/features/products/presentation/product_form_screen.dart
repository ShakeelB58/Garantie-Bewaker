import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/imei.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_view.dart';
import '../../documents/application/document_service.dart';
import '../../documents/domain/document.dart';
import '../../documents/presentation/document_capture.dart';
import '../../documents/presentation/document_widgets.dart';
import '../../recognition/domain/parsed_receipt.dart';
import '../../reminders/application/reminder_service.dart';
import '../../settings/application/settings_providers.dart';
import '../application/product_providers.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/product_input.dart';
import 'widgets/date_field.dart';
import '../../../l10n/app_strings.dart';

/// Product toevoegen (zonder [productId]) of bewerken (met [productId]).
///
/// Bij toevoegen kunnen [initialDocuments] al gescand of geïmporteerd zijn;
/// die worden bij het opslaan aan het nieuwe product gekoppeld. Met
/// [recognition] worden herkende gegevens als voorstel ingevuld.
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({
    this.productId,
    this.initialDocuments = const [],
    this.recognition,
    super.key,
  });

  final String? productId;
  final List<StagedDocument> initialDocuments;
  final ParsedReceipt? recognition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = productId;
    if (id == null) {
      return _ProductForm(
        initial: null,
        initialDocuments: initialDocuments,
        recognition: recognition,
      );
    }

    final product = ref.watch(productByIdProvider(id));
    return product.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(S.current.editProduct)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(S.current.editProduct)),
        body: ErrorView(error: error),
      ),
      data: (product) => product == null
          ? Scaffold(
              appBar: AppBar(title: Text(S.current.editProduct)),
              body: Center(child: Text(S.current.productGone)),
            )
          : _ProductForm(key: ValueKey(product.id), initial: product),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({
    required this.initial,
    this.initialDocuments = const [],
    this.recognition,
    super.key,
  });

  final Product? initial;
  final List<StagedDocument> initialDocuments;
  final ParsedReceipt? recognition;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _serial;
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

  /// Velden die uit het document zijn overgenomen, met hun zekerheid.
  /// Zodra de gebruiker een veld aanpast, telt het als eigen invoer.
  final Map<ProductField, RecognitionConfidence> _recognized = {};

  /// Gekozen productregel als er meerdere op het document staan.
  ParsedLineItem? _chosenItem;

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
        ? ProductInput(purchaseDate: Dates.dateOnly(ref.read(clockProvider)()))
        : ProductInput.fromProduct(initial);

    _name = TextEditingController(text: input.name);
    _brand = TextEditingController(text: input.brand);
    _serial = TextEditingController(text: input.serialNumber);
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

    final recognition = widget.recognition;
    if (initial == null && recognition != null) _applyRecognition(recognition);
  }

  /// Vult herkende waarden in als voorstel. Niets wordt opgeslagen voordat
  /// de gebruiker op "Opslaan" drukt.
  void _applyRecognition(ParsedReceipt r) {
    final name = r.productName;
    if (name.value != null) {
      _name.text = name.value!;
      _recognized[ProductField.name] = name.confidence;
    }
    final merchant = r.merchant;
    if (merchant.value != null) {
      _merchant.text = merchant.value!;
      _recognized[ProductField.merchant] = merchant.confidence;
    }
    // Valuta van de bon (bijv. pond of dollar), als de app die kent.
    if (r.totalMinor.isFound &&
        Money.supportedCurrencies.contains(r.currency)) {
      _currency = r.currency;
    }
    final serial = r.serialNumber;
    if (serial.value != null) {
      _serial.text = serial.value!;
      _recognized[ProductField.serialNumber] = serial.confidence;
    }
    final date = r.purchaseDate;
    if (date.value != null) {
      _purchaseDate = date.value;
      _recognized[ProductField.purchaseDate] = date.confidence;
    }
    // Prijs: alleen bij één product op het document. Bij meerdere producten
    // wordt het totaalbedrag bewust NIET aan één product gekoppeld.
    final candidates = r.productCandidates;
    if (candidates.length == 1) {
      _price.text = Money.formatForInput(candidates.single.amountMinor);
      _recognized[ProductField.price] = name.confidence;
      _chosenItem = candidates.single;
    } else if (candidates.isEmpty && r.totalMinor.value != null) {
      _price.text = Money.formatForInput(r.totalMinor.value!);
      _recognized[ProductField.price] = r.totalMinor.confidence;
    }
  }

  void _chooseItem(ParsedLineItem item) {
    setState(() {
      _chosenItem = item;
      _name.text = item.description;
      _price.text = Money.formatForInput(item.amountMinor);
      _recognized[ProductField.name] = RecognitionConfidence.medium;
      _recognized[ProductField.price] = RecognitionConfidence.medium;
      _errors = Map.of(_errors)
        ..remove(ProductField.name)
        ..remove(ProductField.price);
      _dirty = true;
    });
  }

  /// Hulptekst onder een veld dat uit het document is overgenomen.
  String? _recognitionHint(ProductField field) {
    final confidence = _recognized[field];
    if (confidence == null) return null;
    return switch (confidence) {
      RecognitionConfidence.high ||
      RecognitionConfidence.medium => S.current.recognizedHint,
      _ => S.current.uncertainHint,
    };
  }

  TextStyle? _hintStyle(ProductField field) {
    final confidence = _recognized[field];
    if (confidence == null) return null;
    final theme = Theme.of(context);
    final uncertain =
        confidence == RecognitionConfidence.low ||
        confidence == RecognitionConfidence.unknown;
    return theme.textTheme.bodySmall?.copyWith(
      color: uncertain ? AppColors.warning : theme.colorScheme.primary,
      fontWeight: uncertain ? FontWeight.w600 : null,
    );
  }

  Widget? _recognitionIcon(ProductField field) {
    final confidence = _recognized[field];
    if (confidence == null) return null;
    final uncertain =
        confidence == RecognitionConfidence.low ||
        confidence == RecognitionConfidence.unknown;
    return Icon(
      uncertain ? Icons.warning_amber_rounded : Icons.auto_awesome_outlined,
      color: uncertain
          ? AppColors.warning
          : Theme.of(context).colorScheme.primary,
    );
  }

  /// Uitleg of waarschuwing onder het serienummerveld.
  String _serialHelper() {
    final recognized = _recognitionHint(ProductField.serialNumber);
    if (recognized != null) return recognized;
    if (_serialLooksLikeWrongImei) {
      return S.current.imeiChecksumWarning;
    }
    return _category == ProductCategory.phoneTablet
        ? S.current.imeiHint
        : S.current.serialHint;
  }

  bool get _serialLooksLikeWrongImei =>
      Imei.looksLikeImei(_serial.text) && !Imei.isValid(_serial.text);

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _serial.dispose();
    _merchant.dispose();
    _price.dispose();
    super.dispose();
  }

  ProductInput get _input => ProductInput(
    name: _name.text,
    brand: _brand.text,
    serialNumber: _serial.text,
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
      if (field != null) _recognized.remove(field);
      if (field != null && _errors.containsKey(field)) {
        _errors = Map.of(_errors)..remove(field);
      }
    });
  }

  /// Vraagt toestemming voor meldingen op het moment dat de gebruiker een
  /// herinnering aanzet. Zonder toestemming blijft de herinnering bewaard en
  /// zichtbaar in de app, maar komt er geen melding.
  Future<void> _askNotificationPermission() async {
    bool granted;
    try {
      granted = await ref
          .read(reminderNotificationsProvider)
          .requestPermission();
    } catch (error) {
      debugPrint('Toestemming voor meldingen mislukt (${error.runtimeType})');
      granted = false;
    }
    if (!granted && mounted) {
      _showMessage(S.current.notificationsOffReminderSaved);
    }
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
      _showMessage(S.current.checkMarkedFields);
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
    container
      ..invalidate(documentsForProductProvider(product.id))
      ..invalidate(allDocumentsProvider);
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
                ? S.current.productSavedDocumentFailed
                : S.current.productSaved,
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
        // Bij grote tekst kan het hele venster scrollen.
        scrollable: true,
        title: Text(S.current.discardChangesQuestion),
        content: Text(S.current.changesNotSaved),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.current.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.current.discard),
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
    // Alvast laden, zodat de standaardherinnering klaarstaat.
    ref.watch(reminderLeadProvider);
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
          title: Text(
            _isEdit
                ? S.current.editProduct
                : widget.recognition?.hasAnything ?? false
                ? S.current.checkDetails
                : S.current.addProduct,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (!_isEdit && widget.recognition != null) ...[
              _RecognitionBanner(recognition: widget.recognition!),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!_isEdit &&
                (widget.recognition?.productCandidates.length ?? 0) > 1) ...[
              _ProductChoice(
                recognition: widget.recognition!,
                chosen: _chosenItem,
                onChoose: _chooseItem,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _SectionTitle(S.current.product),
            TextField(
              key: const Key('productForm.name'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: ProductValidator.maxNameLength,
              decoration: InputDecoration(
                labelText: S.current.productNameRequired,
                hintText: S.current.productNameHint,
                errorText: _errors[ProductField.name],
                helperText: _recognitionHint(ProductField.name),
                helperStyle: _hintStyle(ProductField.name),
                suffixIcon: _recognitionIcon(ProductField.name),
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
                labelText: S.current.brandOptional,
                errorText: _errors[ProductField.brand],
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _changed(ProductField.brand, () {}),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ProductCategory>(
              isExpanded: true,
              key: const Key('productForm.category'),
              initialValue: _category,
              decoration: InputDecoration(
                labelText: S.current.category,
                border: const OutlineInputBorder(),
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
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('productForm.serialNumber'),
              controller: _serial,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              maxLength: ProductValidator.maxSerialLength,
              decoration: InputDecoration(
                labelText: S.current.serialOptional,
                errorText: _errors[ProductField.serialNumber],
                helperText: _serialHelper(),
                helperMaxLines: 3,
                helperStyle:
                    _hintStyle(ProductField.serialNumber) ??
                    (_serialLooksLikeWrongImei
                        ? theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          )
                        : null),
                suffixIcon: _recognitionIcon(ProductField.serialNumber),
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (_) => _changed(ProductField.serialNumber, () {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(S.current.purchase),
            TextField(
              key: const Key('productForm.merchant'),
              controller: _merchant,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: S.current.merchantOptional,
                errorText: _errors[ProductField.merchant],
                helperText: _recognitionHint(ProductField.merchant),
                helperStyle: _hintStyle(ProductField.merchant),
                suffixIcon: _recognitionIcon(ProductField.merchant),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _changed(ProductField.merchant, () {}),
            ),
            const SizedBox(height: AppSpacing.md),
            DateField(
              key: const Key('productForm.purchaseDate'),
              label: S.current.purchaseDateRequired,
              value: _purchaseDate,
              firstDate: firstDate,
              lastDate: today,
              errorText: _errors[ProductField.purchaseDate],
              helperText: _recognitionHint(ProductField.purchaseDate),
              onChanged: (value) => _changed(
                ProductField.purchaseDate,
                () => _purchaseDate = value,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldPair(
              first: TextField(
                key: const Key('productForm.price'),
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: S.current.priceOptional,
                  hintText: S.current.priceHint,
                  errorText: _errors[ProductField.price],
                  errorMaxLines: 2,
                  helperText: _recognitionHint(ProductField.price),
                  helperStyle: _hintStyle(ProductField.price),
                  helperMaxLines: 2,
                  suffixIcon: _recognitionIcon(ProductField.price),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _changed(ProductField.price, () {}),
              ),
              second: DropdownButtonFormField<String>(
                isExpanded: true,
                key: const Key('productForm.currency'),
                initialValue: _currency,
                decoration: InputDecoration(
                  labelText: S.current.currency,
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
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(S.current.warrantyAndReminder),
            DateField(
              key: const Key('productForm.warrantyEndDate'),
              label: S.current.warrantyEndOptional,
              helperText: S.current.warrantyEndHelper,
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
              title: Text(S.current.setReminder),
              subtitle: Text(S.current.setReminderHelper),
              value: _reminderEnabled,
              onChanged: (value) {
                _changed(ProductField.reminderDate, () {
                  _reminderEnabled = value;
                  if (value && _reminderDate == null) {
                    final lead =
                        ref.read(reminderLeadProvider).value ??
                        ReminderLead.standard;
                    final base = _warrantyEndDate;
                    _reminderDate = base != null && base.isAfter(today)
                        ? base.subtract(Duration(days: lead.days))
                        : null;
                    if (_reminderDate != null &&
                        _reminderDate!.isBefore(today)) {
                      _reminderDate = today;
                    }
                  }
                });
                if (value) _askNotificationPermission();
              },
            ),
            if (_reminderEnabled)
              DateField(
                key: const Key('productForm.reminderDate'),
                label: S.current.csvReminderDate,
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
              _SectionTitle(S.current.proofsOfPurchase),
              for (final staged in _staged)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Card(
                    child: DocumentTile(
                      title: staged.type.label,
                      subtitle:
                          staged.originalFilename ?? S.current.newDocument,
                      format: staged.format,
                      trailing: IconButton(
                        tooltip: S.current.removeDocument,
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
                  label: Text(S.current.addDocument),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              S.current.requiredNote,
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
              label: Text(_saving ? S.current.saving : S.current.save),
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

/// Uitleg bovenaan het formulier na automatisch herkennen.
class _RecognitionBanner extends StatelessWidget {
  const _RecognitionBanner({required this.recognition});

  final ParsedReceipt recognition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final found = recognition.hasAnything;
    final total = recognition.totalMinor.value;
    final fields = [
      recognition.merchant,
      recognition.purchaseDate,
      recognition.totalMinor,
    ];
    final good =
        fields.every((f) => f.isFound) && !fields.any((f) => f.needsAttention);
    final summary = [
      ?recognition.merchant.value,
      if (recognition.purchaseDate.value != null)
        Dates.formatShort(recognition.purchaseDate.value!),
    ].join(' · ');
    return Card(
      key: const Key('recognition.banner'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                found ? Icons.receipt_long_outlined : Icons.info_outline,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summary.isNotEmpty)
                    Text(
                      summary,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (found) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: good
                            ? theme.colorScheme.primaryContainer
                            : const Color(0xFFFFF1DC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        good
                            ? S.current.recognitionGood
                            : S.current.recognitionCheck,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: good ? AppColors.navy : AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    found
                        ? S.current.dataTakenFromDocument
                        : S.current.noDataRecognized,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    found
                        ? S.current.checkBeforeSaving
                        : S.current.fillInYourself,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (total != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      S.current.totalOnDocument(
                        Money.format(total, recognition.currency),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keuze van een productregel als er meerdere op het document staan.
/// Het totaalbedrag wordt niet automatisch aan één product gekoppeld.
class _ProductChoice extends StatelessWidget {
  const _ProductChoice({
    required this.recognition,
    required this.chosen,
    required this.onChoose,
  });

  final ParsedReceipt recognition;
  final ParsedLineItem? chosen;
  final ValueChanged<ParsedLineItem> onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = recognition.productCandidates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(S.current.whichProduct),
        Text(
          S.current.multipleProducts,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < candidates.length; i++)
                ListTile(
                  key: Key('recognition.item.$i'),
                  leading: Icon(
                    candidates[i] == chosen
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(candidates[i].description),
                  trailing: Text(
                    Money.format(
                      candidates[i].amountMinor,
                      recognition.currency,
                    ),
                  ),
                  onTap: () => onChoose(candidates[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Twee velden naast elkaar (3:2), of onder elkaar bij grote tekst of een
/// smal scherm, zodat niets wordt afgekapt.
class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;
    final narrow = MediaQuery.sizeOf(context).width < 360;
    if (largeText || narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: AppSpacing.md),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: first),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 2, child: second),
      ],
    );
  }
}

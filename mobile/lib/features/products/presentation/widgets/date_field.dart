import 'package:flutter/material.dart';

import '../../../../core/utils/dates.dart';

/// Formulierveld voor een kalenderdatum met de Nederlandse datumkiezer.
class DateField extends StatelessWidget {
  const DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.errorText,
    this.helperText,
    this.allowClear = false,
    super.key,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? errorText;
  final String? helperText;
  final bool allowClear;

  Future<void> _pick(BuildContext context) async {
    final initial = value ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate)
          ? firstDate
          : (initial.isAfter(lastDate) ? lastDate : initial),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: label,
      cancelText: 'Annuleren',
      confirmText: 'Kiezen',
    );
    if (picked != null) onChanged(Dates.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value == null ? 'Geen datum gekozen' : Dates.formatLong(value!);

    final field = InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          helperText: helperText,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
          suffixIcon: allowClear && value != null
              ? IconButton(
                  tooltip: 'Datum wissen',
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          text,
          style: value == null
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : theme.textTheme.bodyLarge,
        ),
      ),
    );
    // Zonder wisknop: label, datum en tikactie als één knop voorlezen.
    // Met wisknop blijven beide knoppen apart bereikbaar.
    if (allowClear && value != null) return field;
    return MergeSemantics(
      child: Semantics(button: true, onTapHint: 'Datum kiezen', child: field),
    );
  }
}

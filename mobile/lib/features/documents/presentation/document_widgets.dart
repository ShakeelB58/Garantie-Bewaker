import 'package:flutter/material.dart';

import '../../../core/utils/dates.dart';
import '../domain/document.dart';

extension DocumentFormatIcon on DocumentFormat {
  IconData get icon => this == DocumentFormat.pdf
      ? Icons.picture_as_pdf_outlined
      : Icons.image_outlined;
}

/// Eén regel in een lijst met documenten.
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    required this.title,
    required this.format,
    this.subtitle,
    this.onTap,
    this.trailing,
    super.key,
  });

  /// Lijst-regel voor een opgeslagen [Document].
  factory DocumentTile.forDocument(
    Document document, {
    VoidCallback? onTap,
    Widget? trailing,
    Key? key,
  }) {
    final parts = [
      if (document.originalFilename != null) document.originalFilename!,
      'Toegevoegd ${Dates.formatShort(document.createdAt.toLocal())}',
    ];
    return DocumentTile(
      key: key,
      title: document.type.label,
      subtitle: parts.join(' · '),
      format: document.format,
      onTap: onTap,
      trailing: trailing,
    );
  }

  final String title;
  final String? subtitle;
  final DocumentFormat format;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.primary,
        child: Icon(format.icon),
      ),
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Laat de gebruiker het soort document kiezen.
Future<DocumentType?> showDocumentTypeDialog(
  BuildContext context,
  DocumentType current,
) {
  return showDialog<DocumentType>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Soort document'),
      children: [
        for (final type in DocumentType.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(type),
            child: Row(
              children: [
                Icon(
                  type == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(type.label),
              ],
            ),
          ),
      ],
    ),
  );
}

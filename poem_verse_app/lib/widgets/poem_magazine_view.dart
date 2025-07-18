// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class PoemMagazineView extends StatefulWidget {
  final String title;
  final String author;
  final List<String> contentLines;
  final String? comment;
  final String? imageUrl;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;

  static const int maxPreviewLines = 8; // 最大预览行数

  const PoemMagazineView({
    super.key,
    required this.title,
    required this.author,
    required this.contentLines,
    this.comment,
    this.imageUrl,
    this.isExpanded = false,
    this.onExpandToggle,
  });

  @override
  State<PoemMagazineView> createState() => _PoemMagazineViewState();
}

class _PoemMagazineViewState extends State<PoemMagazineView> {
  @override
  Widget build(BuildContext context) {
    Widget contentWidget = ExpandableText(
      text: widget.contentLines.join('\n'),
      maxLines: PoemMagazineView.maxPreviewLines,
      expanded: widget.isExpanded,
      onExpandToggle: widget.onExpandToggle,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 6,
      color: const Color(0xFFF8F6FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Image.network(
                widget.imageUrl!.replaceAll('/public', '/list'),
                width: double.infinity,
                height: 225,
                fit: BoxFit.cover,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 0, 36, 36),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                        const SizedBox(height: 48),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '作者：${widget.author}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 24),
                      contentWidget,
                    ],
                  ),
                ),
              ),
            ),
            if (widget.comment != null && widget.comment!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment, color: Colors.purple, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.comment!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 新增：最大行数判断的可展开文本组件
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final bool expanded;
  final VoidCallback? onExpandToggle;

  const ExpandableText({
    required this.text,
    required this.maxLines,
    required this.expanded,
    this.onExpandToggle,
    super.key,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  late bool _exceedsMaxLines;

  @override
  void initState() {
    super.initState();
    _exceedsMaxLines = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExceed());
  }

  void _checkExceed() {
    final span = TextSpan(text: widget.text, style: const TextStyle(fontSize: 17, height: 1.7));
    final tp = TextPainter(
      text: span,
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 48); // 24+24 padding
    setState(() {
      _exceedsMaxLines = tp.didExceedMaxLines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: widget.expanded ? null : widget.maxLines,
          overflow: widget.expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, height: 1.7),
        ),
        if (_exceedsMaxLines)
          TextButton(
            onPressed: widget.onExpandToggle,
            child: Text(widget.expanded ? '收起' : '展开全文', style: const TextStyle(fontSize: 15)),
          ),
      ],
    );
  }
} 
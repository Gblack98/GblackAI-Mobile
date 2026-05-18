import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models.dart';
import 'severity_badge.dart';

class DetectionCard extends StatefulWidget {
  final Detection detection;
  const DetectionCard({super.key, required this.detection});

  @override
  State<DetectionCard> createState() => _DetectionCardState();
}

class _DetectionCardState extends State<DetectionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final d = widget.detection;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── Header ──────────────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _Thumbnail(url: d.croppedImageUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.className,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SeverityBadge(severity: d.severity),
                            const SizedBox(width: 8),
                            Text(
                              '${(d.confidenceScore * 100).toStringAsFixed(0)}% de confiance',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _MiniBar(value: d.confidenceScore),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 280),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: cs.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Expanded body ────────────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: _ExpandedBody(details: d.details, cs: cs),
          ),
        ],
      ),
    );
  }
}

// ─── Mini confidence bar ──────────────────────────────────────────────────────

class _MiniBar extends StatelessWidget {
  final double value;
  const _MiniBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value > 0.8
        ? Colors.red.shade400
        : value > 0.5
            ? Colors.orange.shade400
            : Colors.green.shade400;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 4,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        color: color,
      ),
    );
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final String? url;
  const _Thumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.eco_outlined,
        size: 30,
        color: cs.primary.withOpacity(0.5),
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

// ─── Expanded Body ────────────────────────────────────────────────────────────

class _ExpandedBody extends StatelessWidget {
  final DetectionDetails details;
  final ColorScheme cs;
  const _ExpandedBody({required this.details, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBlock(
            icon: Icons.info_outline_rounded,
            color: cs.primary,
            label: 'Description',
            text: details.description,
          ),
          const SizedBox(height: 12),
          _InfoBlock(
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            label: 'Impact',
            text: details.impact,
          ),
          if (!details.recommendations.isEmpty) ...[
            const SizedBox(height: 16),
            _RecommendationTabs(recs: details.recommendations),
          ],
          if (details.knowledgeBaseTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: details.knowledgeBaseTags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Info Block ───────────────────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String text;

  const _InfoBlock({
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Recommendation Tabs ──────────────────────────────────────────────────────

class _RecTab {
  final IconData icon;
  final String label;
  final Color color;
  final List<RecommendationItem> items;
  const _RecTab(this.icon, this.label, this.color, this.items);
}

class _RecommendationTabs extends StatefulWidget {
  final Recommendations recs;
  const _RecommendationTabs({required this.recs});

  @override
  State<_RecommendationTabs> createState() => _RecommendationTabsState();
}

class _RecommendationTabsState extends State<_RecommendationTabs> {
  int _sel = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final tabs = [
      if (widget.recs.biological.isNotEmpty)
        _RecTab(Icons.nature, 'Bio', Colors.green, widget.recs.biological),
      if (widget.recs.chemical.isNotEmpty)
        _RecTab(Icons.science_outlined, 'Chimique', Colors.blue,
            widget.recs.chemical),
      if (widget.recs.cultural.isNotEmpty)
        _RecTab(Icons.agriculture, 'Culturale', Colors.orange,
            widget.recs.cultural),
    ];

    if (tabs.isEmpty) return const SizedBox.shrink();

    final sel = _sel.clamp(0, tabs.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMANDATIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: cs.outline,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        // Tab buttons
        Row(
          children: tabs.asMap().entries.map((e) {
            final isSelected = e.key == sel;
            final tab = e.value;
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: e.key < tabs.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _sel = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tab.color
                          : cs.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: tab.color.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab.icon,
                          size: 13,
                          color: isSelected ? Colors.white : cs.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        // Items (animated switch)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _RecList(
            key: ValueKey(sel),
            items: tabs[sel].items,
            color: tabs[sel].color,
          ),
        ),
      ],
    );
  }
}

class _RecList extends StatelessWidget {
  final List<RecommendationItem> items;
  final Color color;

  const _RecList({super.key, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.solution,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.details,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

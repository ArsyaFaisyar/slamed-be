import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/date_format.dart';

/// Satu pilihan filter beserta jumlah datanya (opsional).
class FilterOption<T> {
  const FilterOption(this.value, this.label, {this.count});
  final T value;
  final String label;
  final int? count;
}

/// Pil filter bulat; dipakai juga untuk pil rentang tanggal (dengan tombol hapus).
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimary : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Icon(Icons.close_rounded, size: 16, color: fg),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Kolom pencarian + deretan pil filter + pil rentang tanggal.
/// [query] adalah nilai pencarian saat ini; bila diubah dari luar (mis. Reset filter),
/// teks di kolom ikut berubah.
class SearchFilterBar<T> extends StatefulWidget {
  const SearchFilterBar({
    super.key,
    required this.hint,
    required this.query,
    required this.onQuery,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.range,
    this.onPickRange,
    this.onClearRange,
  });

  final String hint, query;
  final ValueChanged<String> onQuery;
  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final DateTimeRange? range;
  final VoidCallback? onPickRange, onClearRange;

  @override
  State<SearchFilterBar<T>> createState() => _SearchFilterBarState<T>();
}

class _SearchFilterBarState<T> extends State<SearchFilterBar<T>> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(SearchFilterBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _ctrl.text) _ctrl.text = widget.query;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.range;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(children: [
        TextField(
          controller: _ctrl,
          textInputAction: TextInputAction.search,
          onChanged: (v) {
            widget.onQuery(v);
            setState(() {});
          },
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _ctrl.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _ctrl.clear();
                      widget.onQuery('');
                      setState(() {});
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final o in widget.options) ...[
              FilterPill(
                label: o.count == null ? o.label : '${o.label} ${o.count}',
                selected: o.value == widget.selected,
                onTap: () => widget.onSelected(o.value),
              ),
              const SizedBox(width: 8),
            ],
            if (widget.onPickRange != null)
              FilterPill(
                icon: Icons.date_range_rounded,
                label: r == null ? 'Tanggal' : '${formatDate(r.start)} – ${formatDate(r.end)}',
                selected: r != null,
                onTap: widget.onPickRange!,
                onClear: r == null ? null : widget.onClearRange,
              ),
          ]),
        ),
      ]),
    );
  }
}
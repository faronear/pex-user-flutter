/// 国家/地区选择列表，对应源项目 `parts/partLandTable.vue`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lands.dart';

class PartLandTable extends ConsumerStatefulWidget {
  const PartLandTable({super.key, this.landCodeNow = '', this.onPick});

  final String landCodeNow;
  final ValueChanged<LandItem>? onPick;

  @override
  ConsumerState<PartLandTable> createState() => _PartLandTableState();
}

class _PartLandTableState extends ConsumerState<PartLandTable> {
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final List<LandItem> lands = kLands.where((LandItem land) {
      if (_keyword.isEmpty) return true;
      final String k = _keyword.toLowerCase();
      return land.iso2.toLowerCase().contains(k) ||
          land.itc.contains(k) ||
          land.nameZh.contains(_keyword) ||
          land.nameEn.toLowerCase().contains(k);
    }).toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (String value) => setState(() => _keyword = value),
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                hintText: 'Search',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lands.length,
              itemBuilder: (BuildContext context, int index) {
                final LandItem land = lands[index];
                final bool selected = land.iso2 == widget.landCodeNow;
                return ListTile(
                  dense: true,
                  selected: selected,
                  selectedTileColor: const Color(0xFFF3F4F6),
                  leading: Text(land.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text('${land.iso2}  ${land.name.resolve(lang)}'),
                  trailing: Text(land.itc),
                  onTap: () => widget.onPick?.call(land),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

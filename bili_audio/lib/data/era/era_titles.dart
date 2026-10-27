import '../repositories/repositories.dart';

final _eraTitle = <DiscoverTab, RegExp>{
  DiscoverTab.y2020: RegExp('202\\d|二零二零'),
  DiscoverTab.y2010: RegExp('201\\d|(?<!\\d)10\\s*年代|一零年代'),
  DiscoverTab.y2000: RegExp('(?<!\\d)200\\d|(?<!\\d)00\\s*年代|零零年代|千禧'),
  DiscoverTab.y1990: RegExp('(?<!\\d)90\\s*年代|九十年代|(?<!\\d)199\\d'),
  DiscoverTab.y1980: RegExp('(?<!\\d)80\\s*年代|八十年代|(?<!\\d)198\\d'),
  DiscoverTab.y1970: RegExp('(?<!\\d)70\\s*年代|七十年代|(?<!\\d)197\\d'),
};

final _eraList = RegExp(
  r'(?<!\d)((?:[789]0|00)(?:\s*[、,，/]\s*(?:[789]0|00))+)(?=\s*年代)',
);

const _shortDecade = <String, DiscoverTab>{
  '70': DiscoverTab.y1970,
  '80': DiscoverTab.y1980,
  '90': DiscoverTab.y1990,
  '00': DiscoverTab.y2000,
};

/// 标题点名的年代。70、80、90 这种跨年代合集会返回多个。
Set<DiscoverTab> erasMentionedInTitle(String title) {
  final found = <DiscoverTab>{
    for (final entry in _eraTitle.entries)
      if (entry.value.hasMatch(title)) entry.key,
  };
  for (final match in _eraList.allMatches(title)) {
    final body = match.group(1);
    if (body == null) continue;
    for (final part in body.split(RegExp(r'[、,，/]'))) {
      final tab = _shortDecade[part.trim()];
      if (tab != null) found.add(tab);
    }
  }
  return found;
}

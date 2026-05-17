/// Learn more about the SFZ format here: <https://sfzformat.com/headers/>
String opcodeMapToString(Map<String, String>? opcodeMap) {
  if (opcodeMap == null) {
    return '';
  } else {
    return opcodeMap.entries.map((entry) => '${entry.key}=${entry.value}\n').join();
  }
}

class SfzRegion {
  SfzRegion({
    this.sample,
    this.key,
    this.loKey,
    this.hiKey,
    this.loVel,
    this.hiVel,
    this.loopStart,
    this.loopEnd,
    this.otherOpcodes,
  });

  String? sample;
  int? key;
  int? loKey;
  int? hiKey;
  int? loVel;
  int? hiVel;
  double? loopStart;
  double? loopEnd;
  Map<String, String>? otherOpcodes;

  String buildString() =>
      '<region>\n${sample != null ? 'sample=$sample\n' : ''}${key != null ? 'key=$key\n' : ''}\n${loKey != null ? 'loKey=$loKey\n' : ''}${hiKey != null ? 'hiKey=$hiKey\n' : ''}${loVel != null ? 'loVel=$loVel\n' : ''}${hiVel != null ? 'hiVel=$hiVel\n' : ''}${loopStart != null ? 'loop_start=$loopStart\n' : ''}${loopEnd != null ? 'loop_end=$loopEnd\n' : ''}${opcodeMapToString(otherOpcodes)}';
}

class SfzGroup {
  const SfzGroup({this.opcodes, required this.regions});

  final Map<String, String>? opcodes;
  final List<SfzRegion> regions;

  String buildString() {
    return '<group>\n${opcodeMapToString(opcodes)}${regions.map((r) => r.buildString()).join()}';
  }
}

class SfzControl {
  const SfzControl({this.opcodes});

  final Map<String, String>? opcodes;

  String buildString() {
    return '<control>\n${opcodeMapToString(opcodes)}';
  }
}

class SfzGlobal {
  const SfzGlobal({this.opcodes});

  final Map<String, String>? opcodes;

  String buildString() {
    return '<global>\n${opcodeMapToString(opcodes)}';
  }
}

class SfzEffect {
  const SfzEffect({this.opcodes});

  final Map<String, String>? opcodes;

  String buildString() {
    return '<effect>\n${opcodeMapToString(opcodes)}';
  }
}

class SfzCurve {
  const SfzCurve({this.opcodes});

  final Map<String, String>? opcodes;

  String buildString() {
    return '<curve>\n${opcodeMapToString(opcodes)}';
  }
}

/// Used to build an SFZ. Note that if loKey or hiKey are not set on a given
/// region, they will be set automatically.
class Sfz {
  const Sfz({
    required this.groups,
    this.controls = const [],
    this.effects = const [],
    this.curves = const [],
    this.global,
  });

  final List<SfzGroup> groups;
  final List<SfzControl> controls;
  final List<SfzEffect> effects;
  final List<SfzCurve> curves;
  final SfzGlobal? global;

  void _setNoteRanges() {
    final allRegions = <SfzRegion>[];

    for (final g in groups) {
      allRegions.addAll(g.regions);
    }

    allRegions.sort((a, b) => (a.key ?? 0) - (b.key ?? 0));
    allRegions.asMap().forEach((index, sd) {
      final prevSd = index > 0 ? allRegions[index - 1] : null;
      final nextSd = index < allRegions.length - 1 ? allRegions[index + 1] : null;

      if (sd.loKey == null) {
        if (prevSd == null) {
          sd.loKey = 0;
        } else {
          sd.loKey = (((sd.key ?? 0) + (prevSd.key ?? 0)) / 2).floor() + 1;
        }
      }

      if (sd.hiKey == null) {
        if (nextSd == null) {
          sd.hiKey = 127;
        } else {
          sd.hiKey = (((nextSd.key ?? 0) + (sd.key ?? 0)) / 2).floor();
        }
      }
    });
  }

  String buildString() {
    _setNoteRanges();

    return (global?.buildString() ?? '') +
        controls.map((c) => c.buildString()).join() +
        effects.map((e) => e.buildString()).join() +
        curves.map((c) => c.buildString()).join() +
        groups.map((g) => g.buildString()).join();
  }
}

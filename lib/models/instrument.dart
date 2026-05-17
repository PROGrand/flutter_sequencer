import '../constants.dart';
import 'sfz.dart';

/// The base class for Instruments.
abstract class Instrument {
  const Instrument(this.idOrPath, {required this.isAsset, this.presetIndex = kDefaultPatchNumber});

  final String idOrPath;
  final bool isAsset;
  final int presetIndex;

  String get displayName {
    return idOrPath.split(RegExp(r'[\\/]')).last;
  }
}

/// Describes an instrument in SFZ format. The SFZ will be played by
/// [sfizz](https://sfz.tools/sfizz/). path should point to an SFZ file. Paths
/// in the SFZ file should be relative to the parent directory of path. To use
/// an alternate tuning, set tuningPath to the path to a
/// [Scala](http://www.huygens-fokker.org/scala/scl_format.html) tuning file.
class SfzInstrument extends Instrument {
  const SfzInstrument({required String path, required bool isAsset, this.tuningPath})
    : super(path, isAsset: isAsset);
  final String? tuningPath;
}

/// Describes an instrument in SFZ format. The SFZ will be played by
/// [sfizz](https://sfz.tools/sfizz/). With this instrument, the SFZ file will
/// be generated dynamically from the Sfz object that's passed in. Sample paths
/// will be relative to sampleRoot. To use an alternate tuning, set tuningString
/// to a [Scala](http://www.huygens-fokker.org/scala/scl_format.html) tuning.
/// Note that if you want to change the SFZ, you'll have to recreate the
/// instrument.
class RuntimeSfzInstrument extends Instrument {
  const RuntimeSfzInstrument({
    required String id,
    required bool isAsset,
    required this.sampleRoot,
    required this.sfz,
    this.tuningString,
  }) : super(id, isAsset: isAsset);

  final String sampleRoot;
  final Sfz sfz;
  final String? tuningString;
}

/// Describes an instrument in SF2 format. Will be played by the SoundFont
/// player for the current platform.
class Sf2Instrument extends Instrument {
  const Sf2Instrument({
    required String path,
    required bool isAsset,
    int presetIndex = kDefaultPatchNumber,
  }) : super(path, isAsset: isAsset, presetIndex: presetIndex);
}

/// Describes an AudioUnit instrument (Apple platforms only.)
class AudioUnitInstrument extends Instrument {
  const AudioUnitInstrument({required String manufacturerName, required String componentName})
    : super('$manufacturerName.$componentName', isAsset: false);
}

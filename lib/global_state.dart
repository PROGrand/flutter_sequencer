import 'dart:async';

import 'package:flutter/services.dart';

import 'constants.dart';
import 'flutter_sequencer.dart';
import 'native_bridge.dart';
import 'sequence.dart';
import 'track.dart';

/// A singleton that manages the global state of the sequencer engine. It is
/// responsible for setting up, starting, and stopping the engine. It also
/// maintains the timer for "topping off" the buffers.
class GlobalState {
  factory GlobalState() {
    return _globalState;
  }

  GlobalState._internal() {
    _setupEngine();
  }

  static final GlobalState _globalState = GlobalState._internal();

  var keepEngineRunning = false;
  final sequenceIdMap = <int, Sequence>{};
  int? sampleRate;
  var isEngineReady = false;
  Timer? _topOffTimer;
  int lastTickInBuffer = 0;
  final onEngineReadyCallbacks = <void Function()>[];

  /// Calls a function when the sequencer engine is ready. Trying to play the
  /// sequence won't do anything until the engine is ready.
  void onEngineReady(void Function() callback) {
    if (isEngineReady) {
      callback();
    } else {
      onEngineReadyCallbacks.add(callback);
    }
  }

  /// Registers the sequence with the underlying engine.
  int registerSequence(Sequence sequence) {
    var nextId = 0;

    while (sequenceIdMap.containsKey(nextId)) {
      nextId++;
    }

    sequenceIdMap[nextId] = sequence;

    return nextId;
  }

  /// {@macro flutter_sequencer_library_private}
  /// Unregisters the sequence with the underlying engine.
  void unregisterSequence(Sequence sequence) {
    sequenceIdMap.remove(sequence.id);
  }

  /// {@macro flutter_sequencer_library_private}
  void playSequence(int? id) {
    if (!sequenceIdMap.containsKey(id)) return;
    final sequence = sequenceIdMap[id!]!;
    if (sequence.isPlaying || sequence.getIsOver()) return;

    final shouldPlayEngine = !_getIsPlaying();

    sequence.isPlaying = true;
    sequence.engineStartFrame =
        kLeadFrames + NativeBridge.getPosition() - sequence.beatToFrames(sequence.pauseBeat);

    _syncAllBuffers();

    if (shouldPlayEngine) {
      _playEngine();
    }
  }

  /// {@macro flutter_sequencer_library_private}
  void pauseSequence(int? id) {
    if (!sequenceIdMap.containsKey(id)) return;
    final sequence = sequenceIdMap[id!]!;
    if (!sequence.isPlaying) return;
    final shouldPauseEngine = _getIsPlaying();

    sequence.pauseBeat = sequence.getBeat();
    sequence.isPlaying = false;

    if (shouldPauseEngine) {
      // All sequences are paused, pause engine
      _pauseEngine();
    }

    sequence.getTracks().forEach((track) {
      track.clearBuffer();
    });
  }

  /// {@macro flutter_sequencer_library_private}
  int usToFrames(int us) {
    if (sampleRate == null) return 0;
    return (us * kSecondsPerUs * sampleRate!).round();
  }

  /// {@macro flutter_sequencer_library_private}
  int framesToUs(int frames) {
    if (sampleRate == null) return 0;
    return (frames / (kSecondsPerUs * sampleRate!)).round();
  }

  Future<void> _setupEngine() async {
    final _flutterSequencerPlugin = FlutterSequencer();
    String platformVersion;
    try {
      platformVersion =
          await _flutterSequencerPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } catch (_) {
      platformVersion = 'Failed to get platform version.';
    }

    print('XXX platform_version:$platformVersion');

    sampleRate = await _flutterSequencerPlugin.doSetup();
    isEngineReady = true;
    for (final callback in onEngineReadyCallbacks) {
      callback();
    }

    if (keepEngineRunning) {
      NativeBridge.play();
    }
  }

  bool _getIsPlaying() {
    return sequenceIdMap.values.any((sequence) => sequence.isPlaying);
  }

  void _playEngine() {
    // All sequences were paused, play engine
    if (!keepEngineRunning) NativeBridge.play();

    if (_topOffTimer != null) _topOffTimer!.cancel();
    _topOffTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      _topOffAllBuffers();

      for (final sequence in sequenceIdMap.values) {
        sequence.checkIsOver();
      }
    });
  }

  void _pauseEngine() {
    if (!keepEngineRunning) NativeBridge.pause();

    if (_topOffTimer != null) _topOffTimer!.cancel();
  }

  /// Gets all tracks in all sequences.
  List<Track> _getAllTracks() {
    final tracks = <Track>[];

    sequenceIdMap.forEach((_, sequence) {
      sequence.getTracks().forEach(tracks.add);
    });

    return tracks;
  }

  /// Refills the underlying sequencer engine's event buffer to full capacity.
  void _topOffAllBuffers() {
    _getAllTracks().forEach((track) {
      track.topOffBuffer();
    });
  }

  void _syncAllBuffers([int? absoluteStartFrame, int maxEventsToSync = kBufferSize]) {
    _getAllTracks().forEach((track) {
      track.syncBuffer(absoluteStartFrame, maxEventsToSync);
    });
  }
}

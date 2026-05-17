import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_sequencer/global_state.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'package:flutter_sequencer/models/sfz.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/track.dart';
import 'package:flutter_sequencer_example/components/drum_machine/drum_machine.dart';
import 'package:flutter_sequencer_example/components/position_view.dart';
import 'package:flutter_sequencer_example/components/step_count_selector.dart';
import 'package:flutter_sequencer_example/components/tempo_selector.dart';
import 'package:flutter_sequencer_example/components/track_selector.dart';
import 'package:flutter_sequencer_example/components/transport.dart';
import 'package:flutter_sequencer_example/constants.dart';
import 'package:flutter_sequencer_example/models/project_state.dart';
import 'package:flutter_sequencer_example/models/step_sequencer_state.dart';
import 'package:maplibre/maplibre.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final sequence = Sequence(tempo: kInitialTempo, endBeat: kInitialStepCount.toDouble());
  Map<int, StepSequencerState?> trackStepSequencerStates = {};
  List<Track> tracks = [];
  Map<int, double> trackVolumes = {};
  Track? selectedTrack;
  late Ticker ticker;
  double tempo = kInitialTempo;
  int stepCount = kInitialStepCount;
  double position = 0.0;
  bool isPlaying = false;
  bool isLooping = kInitialIsLooping;

  @override
  void initState() {
    super.initState();

    GlobalState().keepEngineRunning = true;

    final instruments = [
      const Sf2Instrument(path: 'assets/sf2/TR-808.sf2', isAsset: true),
      const SfzInstrument(
        path: 'assets/sfz/GMPiano.sfz',
        isAsset: true,
        tuningPath: 'assets/sfz/meanquar.scl',
      ),
      RuntimeSfzInstrument(
        id: 'Sampled Synth',
        sampleRoot: 'assets/wav',
        isAsset: true,
        sfz: Sfz(
          groups: [
            SfzGroup(
              regions: [
                SfzRegion(sample: 'D3.wav', key: 62),
                SfzRegion(sample: 'F3.wav', key: 65),
                SfzRegion(sample: 'Gsharp3.wav', key: 68),
              ],
            ),
          ],
        ),
      ),
      RuntimeSfzInstrument(
        id: 'Generated Synth',
        // This SFZ doesn't use any sample files, so just put "/" as a placeholder.
        sampleRoot: '/',
        isAsset: false,
        // Based on the Unison Oscillator example here:
        // https://sfz.tools/sfizz/quick_reference#unison-oscillator
        sfz: Sfz(
          groups: [
            SfzGroup(
              regions: [
                SfzRegion(
                  sample: '*saw',
                  otherOpcodes: {'oscillator_multi': '5', 'oscillator_detune': '50'},
                ),
              ],
            ),
          ],
        ),
      ),
    ];

    sequence.createTracks(instruments).then((tracks) {
      this.tracks = tracks;
      for (final track in tracks) {
        trackVolumes[track.id] = 0.0;
        trackStepSequencerStates[track.id] = StepSequencerState();
      }

      setState(() {
        selectedTrack = tracks[0];
      });
    });

    ticker = createTicker((Duration elapsed) {
      setState(() {
        tempo = sequence.getTempo();
        position = sequence.getBeat();
        isPlaying = sequence.getIsPlaying();

        for (final track in tracks) {
          trackVolumes[track.id] = track.getVolume();
        }
      });
    });
    ticker.start();
  }

  void handleTogglePlayPause() {
    if (isPlaying) {
      sequence.pause();
    } else {
      sequence.play();
    }
  }

  void handleStop() {
    sequence.stop();
  }

  void handleSetLoop({required bool nextIsLooping}) {
    if (nextIsLooping) {
      sequence.setLoop(0, stepCount.toDouble());
    } else {
      sequence.unsetLoop();
    }

    setState(() {
      isLooping = nextIsLooping;
    });
  }

  void handleToggleLoop() {
    final nextIsLooping = !isLooping;

    handleSetLoop(nextIsLooping: nextIsLooping);
  }

  void handleStepCountChange(int nextStepCount) {
    if (nextStepCount < 1) return;

    sequence.endBeat = nextStepCount.toDouble();

    if (isLooping) {
      final nextLoopEndBeat = nextStepCount.toDouble();

      sequence.setLoop(0, nextLoopEndBeat);
    }

    setState(() {
      stepCount = nextStepCount;
      for (final track in tracks) {
        syncTrack(track);
      }
    });
  }

  void handleTempoChange(double nextTempo) {
    if (nextTempo <= 0) return;
    sequence.setTempo(nextTempo);
  }

  void handleTrackChange(Track? nextTrack) {
    setState(() {
      selectedTrack = nextTrack;
    });
  }

  void handleVolumeChange(double nextVolume) {
    if (selectedTrack != null) {
      selectedTrack!.changeVolumeNow(volume: nextVolume);
    }
  }

  void handleVelocitiesChange(int trackId, int step, int noteNumber, double velocity) {
    final track = tracks.firstWhere((track) => track.id == trackId);

    trackStepSequencerStates[trackId]!.setVelocity(step, noteNumber, velocity);

    syncTrack(track);
  }

  void syncTrack(Track track) {
    track.clearEvents();
    trackStepSequencerStates[track.id]!.iterateEvents((step, noteNumber, velocity) {
      if (step < stepCount) {
        track.addNote(
          noteNumber: noteNumber,
          velocity: velocity,
          startBeat: step.toDouble(),
          durationBeats: 1.0,
        );
      }
    });
    track.syncBuffer();
  }

  void loadProjectState(ProjectState projectState) {
    handleStop();

    trackStepSequencerStates[tracks[0].id] = projectState.drumState;
    trackStepSequencerStates[tracks[1].id] = projectState.pianoState;
    trackStepSequencerStates[tracks[2].id] = projectState.bassState;
    trackStepSequencerStates[tracks[3].id] = projectState.synthState;

    handleStepCountChange(projectState.stepCount);
    handleTempoChange(projectState.tempo);
    handleSetLoop(nextIsLooping: projectState.isLooping);

    tracks.forEach(syncTrack);
  }

  void handleReset() {
    loadProjectState(ProjectState.empty());
  }

  void handleLoadDemo() {
    loadProjectState(ProjectState.demo());
  }

  Widget _getMainView() {
    if (selectedTrack == null) return const Text('Loading...');

    final isDrumTrackSelected = selectedTrack == tracks[0];

    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Transport(
                isPlaying: isPlaying,
                isLooping: isLooping,
                onTogglePlayPause: handleTogglePlayPause,
                onStop: handleStop,
                onToggleLoop: handleToggleLoop,
              ),
              PositionView(position: position),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StepCountSelector(stepCount: stepCount, onChange: handleStepCountChange),
              TempoSelector(selectedTempo: tempo, handleChange: handleTempoChange),
            ],
          ),
          TrackSelector(
            tracks: tracks,
            selectedTrack: selectedTrack,
            handleChange: handleTrackChange,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialButton(onPressed: handleReset, child: const Text('Reset')),
              MaterialButton(onPressed: handleLoadDemo, child: const Text('Load Demo')),
            ],
          ),
          DrumMachineWidget(
            track: selectedTrack!,
            stepCount: stepCount,
            currentStep: position.floor(),
            rowLabels: isDrumTrackSelected ? kRowLabelsDrums : kRowLabelsPiano,
            columnPitches: isDrumTrackSelected ? kRowPitchesDrums : kRowPitchesPiano,
            volume: trackVolumes[selectedTrack!.id] ?? 0.0,
            stepSequencerState: trackStepSequencerStates[selectedTrack!.id],
            handleVolumeChange: handleVolumeChange,
            handleVelocitiesChange: handleVelocitiesChange,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white),
      ),
      home: Scaffold(
        body: Column(
          children: [
            const Expanded(child: MapScreen()),
            Expanded(flex: 2, child: _getMainView()),
          ],
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  MapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapLibreMap(
        onMapCreated: (controller) {
          // Store the map controller for later use. You can use it to control
          // the map programmatically.
          _mapController = controller;
        },
        onStyleLoaded: (style) {
          // Add your sources and layers here or do any other setup after the
          // style has been loaded.
          debugPrint('Map loaded 😎');
        },
      ),
    );
  }
}

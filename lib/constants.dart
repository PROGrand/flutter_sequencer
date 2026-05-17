/// Seconds per microsecond
const kSecondsPerUs = 1 / 1000000;

/// The size of the event buffer in the native backend
const kBufferSize = 1024;

/// Interval to "top off" each track's buffer, in milliseconds
const kTopOffPeriodMs = 1000;

/// "Lead frames" account for the fact that it may take some time to build the
/// events and sync them with the native sequencer engine.
const kLeadFrames = 1024;

/// The patch number to select from a sf2 file.
const kDefaultPatchNumber = 0;

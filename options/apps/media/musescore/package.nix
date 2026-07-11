# basic-pitch-transcribe script package
#
# Transcribes an audio file to MIDI using basic-pitch (inside a steam-run FHS
# wrapper so TensorFlow's binary wheel can dynamically link on NixOS), then
# quantizes the raw MIDI timing and renders it to PDF sheet music via
# MuseScore. Caches the pip venv at ~/.cache/basic-pitch-venv so repeat runs
# skip reinstalling packages.
#---------------------------------------------------------------------------------------------------
{ writeShellScriptBin, python311, musescore }:

let
  quantizeEnv = python311.withPackages (ps: [ ps.mido ]);
in
writeShellScriptBin "basic-pitch-transcribe" ''
  set -euo pipefail

  usage() {
    echo "Usage: $(basename "$0") <audio-file> [output-dir]" >&2
    exit 1
  }

  [ $# -ge 1 ] || usage

  AUDIO_FILE=$(realpath "$1")
  OUT_DIR=$(realpath -m "''${2:-./output}")
  VENV_DIR="$HOME/.cache/basic-pitch-venv"

  [ -f "$AUDIO_FILE" ] || { echo "No such file: $AUDIO_FILE" >&2; exit 1; }
  mkdir -p "$OUT_DIR"

  # Inside steam-run's FHS sandbox, a bare "python" can resolve to a
  # system/FHS Python instead of the Nix-provided python311, silently
  # building the venv with the wrong version and breaking basic-pitch's
  # pinned dependency resolution — so python3.11 is resolved explicitly and
  # threaded through as $PY. The inner script is fed via stdin (bash -s)
  # rather than a second file; \INNER keeps it unexpanded until the inner
  # bash reads it, so $VAR refs resolve from its own environment.
  ONSET_THRESHOLD="''${ONSET_THRESHOLD:-0.65}"
  FRAME_THRESHOLD="''${FRAME_THRESHOLD:-0.4}"
  MIN_NOTE_LENGTH_MS="''${MIN_NOTE_LENGTH_MS:-150}"
  MIN_FREQUENCY_HZ="''${MIN_FREQUENCY_HZ:-27.5}"
  MAX_FREQUENCY_HZ="''${MAX_FREQUENCY_HZ:-4186}"
  export VENV_DIR OUT_DIR AUDIO_FILE ONSET_THRESHOLD FRAME_THRESHOLD MIN_NOTE_LENGTH_MS MIN_FREQUENCY_HZ MAX_FREQUENCY_HZ
  NIXPKGS_ALLOW_UNFREE=1 nix-shell -p python311 python311Packages.pip python311Packages.virtualenv ffmpeg steam-run --run '
  PY=$(command -v python3.11)
  steam-run env PY="$PY" VENV_DIR="$VENV_DIR" OUT_DIR="$OUT_DIR" AUDIO_FILE="$AUDIO_FILE" \
    ONSET_THRESHOLD="$ONSET_THRESHOLD" FRAME_THRESHOLD="$FRAME_THRESHOLD" MIN_NOTE_LENGTH_MS="$MIN_NOTE_LENGTH_MS" \
    MIN_FREQUENCY_HZ="$MIN_FREQUENCY_HZ" MAX_FREQUENCY_HZ="$MAX_FREQUENCY_HZ" \
    bash -s <<\INNER
  set -euo pipefail
  if [ ! -d "$VENV_DIR" ]; then
    "$PY" -m venv "$VENV_DIR"
  fi
  source "$VENV_DIR/bin/activate"
  if ! python -c "import basic_pitch" 2>/dev/null; then
    pip install --quiet --upgrade pip
    pip install --quiet basic-pitch
  fi
  # Thresholds are tuned conservative to cut down on the spurious/duplicate
  # notes basic-pitch tends to over-generate (octave doubling, split
  # re-triggers of one held note, short noise blips), which is what makes
  # the resulting sheet music unreadable even after quantizing timing. The
  # frequency range is clamped to a standard 88-key piano (A0-C8) to drop
  # rumble/hiss detections outside playable range.
  # Override via ONSET_THRESHOLD / FRAME_THRESHOLD / MIN_NOTE_LENGTH_MS /
  # MIN_FREQUENCY_HZ / MAX_FREQUENCY_HZ.
  basic-pitch "$OUT_DIR" "$AUDIO_FILE" \
    --onset-threshold "$ONSET_THRESHOLD" \
    --frame-threshold "$FRAME_THRESHOLD" \
    --minimum-note-length "$MIN_NOTE_LENGTH_MS" \
    --minimum-frequency "$MIN_FREQUENCY_HZ" \
    --maximum-frequency "$MAX_FREQUENCY_HZ"
  INNER
  '

  # basic-pitch names its output "<stem>_basic_pitch.mid".
  STEM=$(basename "$AUDIO_FILE")
  STEM="''${STEM%.*}"
  MIDI_FILE="$OUT_DIR/''${STEM}_basic_pitch.mid"
  PDF_FILE="$OUT_DIR/''${STEM}_basic_pitch.pdf"

  # basic-pitch reports continuous onset timing rather than musical time,
  # frequently re-triggers a single held note as several short ones, often
  # hears a note's harmonic as a phantom second note an octave away, and
  # dumps every note into one track spanning the whole piano range (which
  # makes MuseScore's layout switch clef mid-measure trying to fit it on one
  # staff). Snap timing to a grid, merge those re-triggers, drop
  # octave-duplicate phantoms, drop leftover noise blips, and split into
  # high/low tracks for stable treble/bass staff assignment.
  # Override via QUANTIZE_GRID / QUANTIZE_MIN_DURATION / QUANTIZE_OCTAVE_OVERLAP
  # / QUANTIZE_HAND_SPLIT.
  ${quantizeEnv}/bin/python3 ${./quantize.py} "$MIDI_FILE" \
    --grid "''${QUANTIZE_GRID:-8}" \
    --min-duration "''${QUANTIZE_MIN_DURATION:-1}" \
    --octave-overlap "''${QUANTIZE_OCTAVE_OVERLAP:-0.85}" \
    --hand-split "''${QUANTIZE_HAND_SPLIT:-60}"

  ${musescore}/bin/mscore -o "$PDF_FILE" "$MIDI_FILE"

  echo "Sheet music: $PDF_FILE"
''

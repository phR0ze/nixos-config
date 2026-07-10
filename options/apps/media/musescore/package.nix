# basic-pitch-transcribe script package
#
# Transcribes an audio file to MIDI using basic-pitch (inside a steam-run FHS
# wrapper so TensorFlow's binary wheel can dynamically link on NixOS), then
# renders the MIDI to PDF sheet music via MuseScore. Caches the pip venv at
# ~/.cache/basic-pitch-venv so repeat runs skip reinstalling packages.
#---------------------------------------------------------------------------------------------------
{ writeShellScriptBin }:

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
  export VENV_DIR OUT_DIR AUDIO_FILE
  NIXPKGS_ALLOW_UNFREE=1 nix-shell -p python311 python311Packages.pip python311Packages.virtualenv ffmpeg steam-run --run '
  PY=$(command -v python3.11)
  steam-run env PY="$PY" VENV_DIR="$VENV_DIR" OUT_DIR="$OUT_DIR" AUDIO_FILE="$AUDIO_FILE" bash -s <<\INNER
  set -euo pipefail
  if [ ! -d "$VENV_DIR" ]; then
    "$PY" -m venv "$VENV_DIR"
  fi
  source "$VENV_DIR/bin/activate"
  pip install --quiet --upgrade pip
  pip install --quiet basic-pitch
  basic-pitch "$OUT_DIR" "$AUDIO_FILE"
  INNER
  '

  # basic-pitch names its output "<stem>_basic_pitch.mid". MuseScore is
  # installed alongside this script via the same option, so "mscore" is
  # already on PATH here.
  STEM=$(basename "$AUDIO_FILE")
  STEM="''${STEM%.*}"
  MIDI_FILE="$OUT_DIR/''${STEM}_basic_pitch.mid"
  PDF_FILE="$OUT_DIR/''${STEM}_basic_pitch.pdf"

  mscore -o "$PDF_FILE" "$MIDI_FILE"

  echo "Sheet music: $PDF_FILE"
''

#!/usr/bin/env python3
# Snap note-on/off timing in a MIDI file to a fixed grid, in place.
#
# basic-pitch's onset detection reports continuous timing rather than
# musical time, which MuseScore imports as a mess of tied thirty-second
# notes. Rounding each event to the nearest grid line makes the
# transcribed rhythm readable.
import argparse

import mido


def quantize(path: str, subdivisions: int) -> None:
    mid = mido.MidiFile(path)
    grid = max(1, mid.ticks_per_beat * 4 // subdivisions)

    for track in mid.tracks:
        abs_time = 0
        snapped_times = []
        for msg in track:
            abs_time += msg.time
            snapped_times.append(round(abs_time / grid) * grid)

        prev = 0
        for msg, snapped in zip(track, snapped_times):
            msg.time = snapped - prev
            prev = snapped

    mid.save(path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("midi_file")
    parser.add_argument(
        "--grid", type=int, default=16,
        help="note subdivision to snap to, e.g. 8 for eighth notes, 16 for sixteenth notes (default: 16)",
    )
    args = parser.parse_args()
    quantize(args.midi_file, args.grid)

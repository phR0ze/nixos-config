#!/usr/bin/env python3
# Clean up a MIDI file transcribed by basic-pitch, in place.
#
# basic-pitch's onset/frame detection reports continuous timing rather than
# musical time, frequently re-triggers a single sustained note as several
# short adjacent notes, often hears a note's own harmonic as a second note
# exactly one or two octaves away, and dumps every note into one track
# spanning the whole piano range. Left alone, MuseScore imports this as a
# mess of tied thirty-second notes, duplicate re-articulations, phantom
# octave doublings, and constant mid-measure clef switching as its layout
# heuristic tries to fit one wide-ranging track onto a single staff. This
# script:
#   1. Snaps note start/end times to a fixed grid.
#   2. Merges adjacent same-pitch notes into one (undoes basic-pitch's
#      re-triggering of held notes).
#   3. Drops the weaker note of any near-identical-timing octave pair
#      (undoes harmonic bleed being heard as a second note).
#   4. Drops notes that round down to zero duration (detection noise).
#   5. Splits notes into separate high/low tracks by pitch, so MuseScore
#      assigns them to a stable treble/bass staff instead of one staff that
#      keeps switching clef.
import argparse

import mido


def _extract_notes(track):
    """Pull (start, end, note, velocity, channel) tuples out of a track,
    plus the other (non note_on/off) messages with their absolute times."""
    notes = []
    other = []
    open_notes = {}  # (channel, note) -> (start_time, velocity)
    abs_time = 0
    for msg in track:
        abs_time += msg.time
        if msg.type == "note_on" and msg.velocity > 0:
            open_notes[(msg.channel, msg.note)] = (abs_time, msg.velocity)
        elif msg.type == "note_off" or (msg.type == "note_on" and msg.velocity == 0):
            key = (msg.channel, msg.note)
            if key in open_notes:
                start, velocity = open_notes.pop(key)
                notes.append([start, abs_time, msg.note, velocity, msg.channel])
        else:
            other.append((abs_time, msg.copy(time=0)))
    return notes, other


def _snap(time, grid):
    return round(time / grid) * grid


def _merge_adjacent(notes):
    """Collapse same-pitch/channel notes whose quantized end meets the next
    note's quantized start, treating them as one re-triggered note."""
    notes.sort(key=lambda n: (n[4], n[2], n[0]))
    merged = []
    for note in notes:
        if merged:
            prev = merged[-1]
            if prev[4] == note[4] and prev[2] == note[2] and prev[1] >= note[0]:
                prev[1] = max(prev[1], note[1])
                continue
        merged.append(note)
    return merged


def _drop_octave_duplicates(notes, overlap_ratio):
    """Drop the quieter note of any pair one or two octaves apart whose
    time spans overlap heavily — basic-pitch hallucinating a harmonic as a
    distinct note produces near-identical start/end times, whereas an
    intentionally played octave voicing rarely lines up this exactly."""
    notes.sort(key=lambda n: (n[4], n[0]))
    dropped = set()
    for i, a in enumerate(notes):
        if id(a) in dropped:
            continue
        for b in notes[i + 1:]:
            if b[4] != a[4]:
                continue
            if b[0] > a[1]:
                break
            if id(b) in dropped:
                continue
            if abs(b[2] - a[2]) not in (12, 24):
                continue
            overlap = min(a[1], b[1]) - max(a[0], b[0])
            union = max(a[1], b[1]) - min(a[0], b[0])
            if union > 0 and overlap / union >= overlap_ratio:
                weaker = a if a[3] < b[3] else b
                dropped.add(id(weaker))
    return [n for n in notes if id(n) not in dropped]


def _build_track(notes, other, program_msgs):
    events = list(other)
    for start, end, note, velocity, channel in notes:
        events.append((start, mido.Message("note_on", note=note, velocity=velocity, channel=channel, time=0)))
        events.append((end, mido.Message("note_off", note=note, velocity=0, channel=channel, time=0)))
    events.sort(key=lambda e: (e[0], e[1].type == "note_on"))

    track = mido.MidiTrack()
    for msg in program_msgs:
        track.append(msg.copy(time=0))
    prev = 0
    for abs_time, msg in events:
        track.append(msg.copy(time=abs_time - prev))
        prev = abs_time
    return track


def quantize(path: str, subdivisions: int, min_duration: int, octave_overlap: float, hand_split: int) -> None:
    mid = mido.MidiFile(path)
    grid = max(1, mid.ticks_per_beat * 4 // subdivisions)
    min_len = grid * min_duration

    new_tracks = []
    for track in mid.tracks:
        notes, other = _extract_notes(track)

        if not notes:
            new_tracks.append(track)
            continue

        for note in notes:
            note[0] = _snap(note[0], grid)
            note[1] = _snap(note[1], grid)

        notes = _merge_adjacent(notes)
        if octave_overlap > 0:
            notes = _drop_octave_duplicates(notes, octave_overlap)
        notes = [n for n in notes if n[1] - n[0] >= min_len]

        program_msgs = [m for _, m in other if m.type == "program_change"]
        other = [(t, m) for t, m in other if m.type != "program_change"]

        if hand_split > 0:
            high = [n for n in notes if n[2] >= hand_split]
            low = [n for n in notes if n[2] < hand_split]
            new_tracks.append(_build_track(high, other, program_msgs))
            new_tracks.append(_build_track(low, [], program_msgs))
        else:
            new_tracks.append(_build_track(notes, other, program_msgs))

    mid.tracks = new_tracks
    mid.save(path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("midi_file")
    parser.add_argument(
        "--grid", type=int, default=8,
        help="note subdivision to snap to, e.g. 8 for eighth notes, 16 for sixteenth notes (default: 8)",
    )
    parser.add_argument(
        "--min-duration", type=int, default=1,
        help="drop notes shorter than this many grid units after snapping (default: 1)",
    )
    parser.add_argument(
        "--octave-overlap", type=float, default=0.85,
        help="time-overlap ratio (0-1) above which a same-timed octave pair is treated as a "
        "harmonic-detection duplicate and the quieter note dropped; 0 disables this (default: 0.85)",
    )
    parser.add_argument(
        "--hand-split", type=int, default=60,
        help="MIDI note number splitting notes into a high track (>=) and low track (<), so "
        "MuseScore assigns them to stable treble/bass staves; 0 disables splitting (default: 60, middle C)",
    )
    args = parser.parse_args()
    quantize(args.midi_file, args.grid, args.min_duration, args.octave_overlap, args.hand_split)

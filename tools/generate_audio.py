#!/usr/bin/env python3
"""Rebuild the project's original synthesized audio. No third-party samples."""
import math
from pathlib import Path
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 22050
DURATIONS = {"drill": 2.0, "reel": 1.0, "splash": 0.65, "bite": 0.45, "catch": 0.9,
             "coins": 0.45, "purchase": 0.55, "level": 1.2, "discovery": 1.4, "wind": 6.0, "music": 12.0}

def generate(destination=None):
    destination = destination or ROOT / "assets/audio"
    destination.mkdir(parents=True, exist_ok=True)
    for name, duration in DURATIONS.items():
        rng = random.Random(name)
        samples = []
        smooth_noise = 0.0
        for i in range(int(RATE * duration)):
            t = i / RATE
            noise = rng.uniform(-1, 1)
            smooth_noise = smooth_noise * 0.96 + noise * 0.04
            edge = min(1, t / 0.02, (duration - t) / 0.05)
            if name == "wind":
                value = smooth_noise * (0.5 + 0.2 * math.sin(t * math.tau / duration))
            elif name == "music":
                notes = (220, 261.63, 293.66, 349.23, 392, 349.23, 293.66, 261.63)
                phase = t % 1.5
                note = notes[int(t / 1.5) % len(notes)]
                value = (math.sin(math.tau * note * t) + 0.4 * math.sin(math.tau * note * 2 * t)) * math.exp(-phase * 2) * 0.12
            elif name == "drill":
                value = (noise * 0.12 + math.sin(math.tau * 85 * t) * 0.2) * (0.7 + 0.3 * math.sin(math.tau * 7 * t))
            elif name == "reel":
                value = noise * 0.25 * math.exp(-(t % (1 / 12)) * 100)
            elif name == "splash":
                value = (noise * 0.25 + smooth_noise) * math.exp(-t * 8)
            else:
                notes = {"bite": (880,), "catch": (523.25, 659.25, 783.99), "coins": (1174.66, 1567.98),
                         "purchase": (659.25, 880), "level": (523.25, 659.25, 783.99, 1046.5), "discovery": (440, 659.25, 880, 1318.51)}[name]
                value = 0.0
                for index, note in enumerate(notes):
                    local = t - index * duration / (len(notes) + 2)
                    if local >= 0:
                        value += math.sin(math.tau * note * local) * math.exp(-local * 9) * 0.18
            samples.append(struct.pack('<h', int(max(-1, min(1, value * edge)) * 32767)))
        with wave.open(str(destination / f"{name}.wav"), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            output.writeframes(b''.join(samples))
    print(f"Generated {len(DURATIONS)} original WAVs in {destination}")

if __name__ == "__main__":
    generate()

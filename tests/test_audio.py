"""Verify original generated audio is reproducible, playable PCM, and nonempty."""
import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("generate_audio", ROOT / "tools/generate_audio.py")
audio = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audio)


class AudioTests(unittest.TestCase):
    def test_audio_is_deterministic_and_non_silent_pcm(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            audio.generate(output)
            for name, seconds in audio.DURATIONS.items():
                file = output / f"{name}.wav"
                self.assertEqual(file.read_bytes(), (ROOT / "assets/audio" / file.name).read_bytes())
                with wave.open(str(file), "rb") as sound:
                    self.assertEqual(sound.getparams()[:3], (1, 2, 22050))
                    self.assertAlmostEqual(sound.getnframes() / sound.getframerate(), seconds, places=3)
                    samples = struct.unpack(f"<{sound.getnframes()}h", sound.readframes(sound.getnframes()))
                    self.assertGreater(max(abs(value) for value in samples), 100)
                    self.assertLess(max(abs(value) for value in samples), 32767)


if __name__ == "__main__":
    unittest.main()

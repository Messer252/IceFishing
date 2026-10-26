"""Check the exported place contains executable scripts at the expected paths."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("build_place", ROOT / "tools/build_place.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class PlaceTests(unittest.TestCase):
    def test_export_preserves_scripts_and_hierarchy(self):
        with tempfile.TemporaryDirectory() as directory:
            destination = builder.build(Path(directory) / "test.rbxlx")
            tree = ET.parse(destination)
        sources = {}

        def walk(node, path=""):
            for child in node.findall("Item"):
                name = child.find("Properties/string[@name='Name']").text
                current = f"{path}/{name}"
                source = child.find("Properties/ProtectedString[@name='Source']")
                if source is not None:
                    sources[current] = (child.attrib["class"], source.text)
                walk(child, current)

        walk(tree.getroot())
        expected = {}
        for directory, prefix in (
            ("shared", "/ReplicatedStorage/Shared"),
            ("server", "/ServerScriptService/Server"),
            ("client", "/StarterPlayer/StarterPlayerScripts/Client"),
        ):
            for file in (ROOT / "src" / directory).rglob("*.lua"):
                name = file.stem
                kind = "ModuleScript"
                if name.endswith(".server"):
                    name, kind = name[:-7], "Script"
                elif name.endswith(".client"):
                    name, kind = name[:-7], "LocalScript"
                expected[f"{prefix}/{name}"] = (kind, file.relative_to(ROOT).as_posix())
        self.assertEqual(set(sources), set(expected))
        for path, (kind, file) in expected.items():
            self.assertEqual(sources[path], (kind, (ROOT / file).read_text()))

    def test_build_is_repeatable(self):
        with tempfile.TemporaryDirectory() as directory:
            path = builder.build(Path(directory) / "test.rbxlx")
            first = path.read_bytes()
            builder.build(path)
            self.assertEqual(first, path.read_bytes())


if __name__ == "__main__":
    unittest.main()

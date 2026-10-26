#!/usr/bin/env python3
"""Build a Studio-openable place using Python's standard library only."""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def item(parent, class_name, name):
    node = ET.SubElement(parent, "Item", {"class": class_name})
    props = ET.SubElement(node, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = name
    return node


def scripts(parent, directory):
    for path in sorted(directory.iterdir()):
        if path.is_dir():
            scripts(item(parent, "Folder", path.name), path)
        elif path.suffix == ".lua":
            stem = path.stem
            class_name = "ModuleScript"
            if stem.endswith(".server"):
                stem, class_name = stem[:-7], "Script"
            elif stem.endswith(".client"):
                stem, class_name = stem[:-7], "LocalScript"
            node = item(parent, class_name, stem)
            ET.SubElement(node.find("Properties"), "ProtectedString", {"name": "Source"}).text = path.read_text()


def build(destination=None):
    root = ET.Element("roblox", {"version": "4"})
    ET.SubElement(root, "External").text = "null"
    ET.SubElement(root, "External").text = "nil"
    workspace = item(root, "Workspace", "Workspace")
    props = workspace.find("Properties")
    ET.SubElement(props, "bool", {"name": "StreamingEnabled"}).text = "true"
    ET.SubElement(props, "int", {"name": "StreamingMinRadius"}).text = "64"
    ET.SubElement(props, "int", {"name": "StreamingTargetRadius"}).text = "192"
    storage = item(root, "ReplicatedStorage", "ReplicatedStorage")
    scripts(item(storage, "Folder", "Shared"), ROOT / "src/shared")
    server = item(root, "ServerScriptService", "ServerScriptService")
    scripts(item(server, "Folder", "Server"), ROOT / "src/server")
    starter = item(root, "StarterPlayer", "StarterPlayer")
    client = item(starter, "StarterPlayerScripts", "StarterPlayerScripts")
    scripts(item(client, "Folder", "Client"), ROOT / "src/client")
    item(root, "Lighting", "Lighting")
    for index, node in enumerate(root.iter("Item"), start=1):
        node.set("referent", f"RBX{index}")
    destination = destination or ROOT / "dist/FrostbiteFishing.rbxlx"
    destination.parent.mkdir(parents=True, exist_ok=True)
    ET.indent(root)
    ET.ElementTree(root).write(destination, encoding="utf-8", xml_declaration=True)
    print(f"Built {destination}")
    return destination


if __name__ == "__main__":
    build()

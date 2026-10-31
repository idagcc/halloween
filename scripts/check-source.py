"""Verify the distributable stays self-contained and both launch paths are intact."""
from pathlib import Path
import re
import subprocess
import plistlib

root = Path(__file__).resolve().parent.parent
html = (root / 'index.html').read_text()
script = re.search(r'<script>([\s\S]*?)</script>', html).group(1)
subprocess.run(['node', '--check'], input=script, text=True, check=True)
references = re.findall(r'(?:src|href)=["\']([^"\']+)', html)
assert all(value.startswith(('#', 'data:')) for value in references), 'External HTML dependency'
assert not re.search(r'\b(fetch|XMLHttpRequest|WebSocket|sendBeacon)\s*\(', script), 'Network API in game'
assert 'aspect-ratio:16 / 9' in html, 'Missing 16:9 stage'
assert 'window.pumpkinNative.toggleFullscreen()' in script, 'Missing native fullscreen bridge'
with (root / 'mac/Info.plist').open('rb') as stream:
    info = plistlib.load(stream)
assert info['CFBundleExecutable'] == 'PumpkinPop'
assert info['LSMinimumSystemVersion'] == '13.0'
print('PASS: JavaScript syntax, offline dependencies, 16:9 stage, Mac bridge, bundle metadata')

"""Import the publisher's verse-per-line ZIP, retaining every text record."""
import hashlib
import json
from pathlib import Path
import re
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
with zipfile.ZipFile(sys.argv[1]) as archive:
    source = archive.read('mal2015_vpl.txt')
    data = {}
    for line in source.decode('utf-8-sig').splitlines():
        match = re.fullmatch(r'(\w+) (\d+):(\d+(?:-\d+)?) (.*)', line)
        if not match:
            raise ValueError(f'Unrecognized source record: {line[:100]}')
        book, chapter, verse, text = match.groups()
        data.setdefault(book, {}).setdefault(chapter, []).append({'v': verse, 't': text})
    assert len(data) == 66
    assert sum(len(book) for book in data.values()) == 1189
    (root/'assets/bible.json').write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    (root/'assets/source_about.html').write_bytes(archive.read('mal2015_about.htm'))
    print('VPL SHA-256:', hashlib.sha256(source).hexdigest())
    print('Imported verse records:', sum(len(c) for b in data.values() for c in b.values()))

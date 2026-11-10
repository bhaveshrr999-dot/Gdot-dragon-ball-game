#!/usr/bin/env python3
"""Validate archive integrity, ABI, ELF architecture and the distribution cap."""
import hashlib
import json
import struct
import sys
import zipfile
from pathlib import Path

apk = Path(sys.argv[1])
assert apk.stat().st_size < 1_500_000_000, 'APK exceeds the 1.5 GB task budget'
with zipfile.ZipFile(apk) as archive:
    assert archive.testzip() is None, 'corrupt archive member'
    names = archive.namelist()
    assert 'AndroidManifest.xml' in names, 'missing manifest'
    libs = [name for name in names if name.startswith('lib/') and name.endswith('.so')]
    assert libs, 'no native libraries'
    assert all(name.startswith('lib/arm64-v8a/') for name in libs), libs
    for name in libs:
        elf = archive.read(name)
        assert elf[:4] == b'\x7fELF' and elf[4] == 2, 'expected ELF64'
        assert struct.unpack_from('<H', elf, 18)[0] == 183, 'expected AArch64'
    assert any(name.startswith('assets/') for name in names), 'missing game resources'
print(json.dumps({'file': apk.name, 'bytes': apk.stat().st_size,
                  'abi': 'arm64-v8a', 'native_libraries': libs,
                  'sha256': hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest(),
                  'note': 'Static verification only; does not establish Android runtime compatibility.'}, indent=2))

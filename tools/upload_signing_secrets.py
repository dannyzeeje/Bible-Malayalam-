#!/usr/bin/env python3
"""Upload the private signing ZIP using a gh login with Actions secrets access."""
import argparse
import base64
import subprocess
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('signing_zip', help='Path to Bible-Permanent-Signing-Key-PRIVATE.zip')
args = parser.parse_args()
with zipfile.ZipFile(args.signing_zip) as bundle:
    properties = dict(
        line.split('=', 1)
        for line in bundle.read('key.properties').decode().splitlines()
        if '=' in line and not line.lstrip().startswith('#')
    )
    secrets = {
        'ANDROID_KEYSTORE_BASE64': base64.b64encode(bundle.read('word-release.jks')).decode(),
        'ANDROID_KEYSTORE_PASSWORD': properties['storePassword'],
        'ANDROID_KEY_PASSWORD': properties['keyPassword'],
        'ANDROID_KEY_ALIAS': properties['keyAlias'],
    }
for name, value in secrets.items():
    subprocess.run(
        ['gh', 'secret', 'set', name, '--repo', 'dannyzeeje/Bible-Malayalam-'],
        input=value, text=True, check=True,
    )
    print(f'Uploaded {name}')

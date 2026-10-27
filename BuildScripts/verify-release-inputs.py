#!/usr/bin/env python3
"""Verify the exact dependency sources and libraries used by Astralight 1.0.0."""
from pathlib import Path
import hashlib,json,subprocess
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'ThirdParty/release-inputs.json').read_text())
entries=data['sourceArchives']+data['bundledLibrariesAndPatches']+data['openSSLBuildSupport']['files']
for entry in entries:
 path=root/entry['file']
 if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=entry['sha256']:
  raise SystemExit('Checksum mismatch: '+entry['file'])
for entry in data['submodules']:
 path=root/entry['path']
 if not path.is_dir():raise SystemExit('Missing dependency: '+entry['path'])
 # Expanded source bundles intentionally omit .git directories.
 if (path/'.git').exists():
  revision=subprocess.check_output(['git','-C',str(path),'rev-parse','HEAD'],text=True).strip()
  if revision!=entry['revision']:raise SystemExit('Wrong submodule revision: '+entry['path'])
subprocess.run(['python3',str(root/'BuildScripts/generate-legal-documents.py'),'--check'],check=True)
print('PASS exact source archives, library checksums, dependency patches and submodule revisions')

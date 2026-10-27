#!/usr/bin/env python3
"""Package tracked source plus expanded, patched submodules. Never includes .git or local credentials."""
from pathlib import Path
import argparse,gzip,hashlib,io,json,subprocess,tarfile
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('output',type=Path);args=p.parse_args()
subprocess.run(['python3',str(root/'BuildScripts/verify-release-inputs.py')],check=True)
# Root edits must be committed so the archive identifies an immutable source revision.
if subprocess.check_output(['git','status','--porcelain','--ignore-submodules=all'],cwd=root):
 raise SystemExit('Commit root changes before packaging release source.')
manifest=json.loads((root/'ThirdParty/release-inputs.json').read_text())
expected={
 'moonlight-common/moonlight-common-c':'Patches/moonlight-common-initialization.patch',
 'moonlight-common/moonlight-common-c/enet':'Patches/enet-enum-flags.patch'}
for sub in manifest['submodules']:
 path=root/sub['path']
 diff=subprocess.check_output(['git','diff','HEAD','--ignore-submodules=all'],cwd=path)
 wanted=(root/expected[sub['path']]).read_bytes() if sub['path'] in expected else b''
 if diff!=wanted:raise SystemExit('Unexpected or missing dependency edits: '+sub['path'])
 if subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=path):
  raise SystemExit('Untracked dependency files: '+sub['path'])
paths=subprocess.check_output(['git','ls-files','--recurse-submodules','-z'],cwd=root).decode().split('\0')
revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
args.output.parent.mkdir(parents=True,exist_ok=True)
prefix='Astralight-1.0.0-source/'
with args.output.open('wb') as raw,gzip.GzipFile(filename='',mode='wb',fileobj=raw,mtime=0) as gz,tarfile.open(fileobj=gz,mode='w') as tar:
 for relative in sorted(filter(None,paths)):
  path=root/relative
  if not path.is_file() and not path.is_symlink():continue
  info=tar.gettarinfo(str(path),arcname=prefix+relative)
  info.uid=info.gid=info.mtime=0;info.uname=info.gname=''
  if info.isfile():
   with path.open('rb') as f:tar.addfile(info,f)
  else:tar.addfile(info)
 content=('Astralight 1.0.0 (1)\nGit revision: '+revision+'\nSubmodules expanded with the checked-in Patches applied.\n').encode()
 info=tarfile.TarInfo(prefix+'SOURCE_REVISION.txt');info.size=len(content);info.mode=0o644;tar.addfile(info,io.BytesIO(content))
checksum=hashlib.sha256(args.output.read_bytes()).hexdigest()
args.output.with_suffix(args.output.suffix+'.sha256').write_text(checksum+'  '+args.output.name+'\n')
print(str(args.output)+'\nSHA-256: '+checksum)

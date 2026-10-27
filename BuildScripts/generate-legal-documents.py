#!/usr/bin/env python3
"""Regenerate the offline notices from the actual dependency license texts."""
from pathlib import Path
import argparse
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
items=[
 ('Astralight / Moonlight iOS — GPLv3 with App Store Distribution Exception','LICENSE.txt'),
 ('moonlight-common-c — GPLv3 with App Store Distribution Exception','moonlight-common/moonlight-common-c/LICENSE.txt'),
 ('ENet — MIT','moonlight-common/moonlight-common-c/enet/LICENSE'),
 ('nanors — MIT','moonlight-common/moonlight-common-c/nanors/LICENSE'),
 ('X1Kit — MIT','X1Kit/LICENSE.md'),
 ('SWRevealViewController — MIT','ThirdParty/Licenses/SWRevealViewController-MIT.txt'),
 ('SDL 2.28.5 — zlib','ThirdParty/Licenses/SDL-zlib.txt'),
 ('Opus 1.4 — BSD-style license and patent grant','ThirdParty/Licenses/Opus-COPYING.txt'),
 ('FFmpeg N-112686-g3f890fbfd9 — LGPL 2.1 or later','ThirdParty/Licenses/FFmpeg-LGPL-2.1.txt'),
 ('OpenSSL 3.6.3 — Apache 2.0','ThirdParty/Licenses/OpenSSL-Apache-2.0.txt'),
 ('OpenSSL-Package 3.6.3000 — Apache 2.0','ThirdParty/Licenses/OpenSSL-Package-Apache-2.0.txt'),
]
intro='''Astralight — Credits & Licenses

Astralight 1.0.0 is an independent fork of Moonlight for iOS, maintained by Jordon Bibian. Thanks to the Moonlight contributors and the open source projects listed below. Astralight is not affiliated with or endorsed by Moonlight, Apollo, Sunshine, or their maintainers. Compatible host software is separate and is not bundled with this app.

Astralight changes include the iOS 27 scene lifecycle, native display resolution and fold/unfold reconnection, optional MetalFX spatial upscaling, the Astralight interface and artwork, documentation links, and release privacy improvements. Original copyright and license notices remain in the corresponding sources.

Complete corresponding source, including dependencies, changes, and build instructions:
https://github.com/JordonBibian/astralight

Release/source instructions:
https://github.com/JordonBibian/astralight/blob/master/RELEASING.md

You may modify and redistribute this software under its applicable licenses. It comes without warranty; the full terms follow. Distribution on the App Store does not remove your rights under those licenses.
'''
text=intro+'\n'+''.join('\n'+'='*60+'\n'+name+'\n'+'='*60+'\n\n'+(root/path).read_text().strip()+'\n' for name,path in items)
outputs={'Limelight/Legal/Licenses.txt':text,'Limelight/Legal/Privacy.txt':(root/'PRIVACY.md').read_text()}
for path,content in outputs.items():
 target=root/path
 if args.check:
  if not target.exists() or target.read_text()!=content:raise SystemExit('Out of date: '+path)
 else:target.write_text(content)
print('PASS bundled privacy policy and complete dependency notices' if args.check else 'Generated offline legal documents')

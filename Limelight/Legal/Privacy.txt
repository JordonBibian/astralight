Astralight Privacy Policy
Effective October 27, 2026 • Version 1.0.0

Astralight is an independent, open source game-streaming client maintained by Jordon Bibian. It is a fork of Moonlight and is not affiliated with or endorsed by the Moonlight, Apollo, or Sunshine projects.

Your stream and your computer
Astralight connects to the gaming computer you choose. Your computer sends video, audio, its name, available apps, and connection information to your device. Astralight sends pairing requests, stream settings, and your touch, keyboard, mouse, and controller input to that computer. The computer's host software controls its own permissions, logging, and retention. Astralight does not route your stream through a developer-operated server.

Information stored on your device
The app saves computer names and network addresses, host identifiers and certificates, pairing credentials (including the client certificate and private key), preferences, and cached app lists/artwork in its local app storage. These support reconnection and the library interface. Local data may be included in backups managed by your device or Apple. Astralight does not provide an account or cloud-sync service.

Network discovery and STUN
Local discovery uses Bonjour on your network. When looking up a computer's external address, Astralight may automatically send a STUN request to stun.moonlight-stream.org on UDP port 3478. This third-party service sees your public IP address and source port and returns the external address. Astralight sends no game video, audio, pairing keys, or controller input to that service. Its operator controls any server-side logging or retention; Astralight's maintainer does not operate that service and has not independently verified its retention practices. Your DNS provider and network operator also handle ordinary network traffic.

Diagnostics and tracking
Astralight includes no advertising, tracking, or analytics SDK and sends no usage analytics or diagnostic reports to a developer-operated service. Local diagnostic logs can include device capabilities, computer names or network addresses, connection errors, and performance information. App-generated logs omit pairing PINs, session keys, and raw HTTP requests/responses. Review logs before sharing them. Apple may collect crash, performance, and TestFlight feedback information under your Apple settings and Apple's policies; the developer may receive reports Apple makes available.

Permissions
Local Network access allows discovery and connections to your computer. Bluetooth is used if you enable support for a compatible Citrix X1 mouse. You can change permissions in iOS Settings. Astralight does not request your contacts, photos, location, camera, or microphone.

Your choices and deletion
You can remove a saved computer from Astralight. To revoke that client's access on the computer, also remove its paired-client entry in Apollo, Sunshine, or your host software. Deleting Astralight removes its local app container; copies in device backups are managed separately. You can change settings, stop streaming, or disable network access at any time. There is no Astralight account to delete.

Links and support
Documentation, Source Code, and public policy links open third-party websites. Those sites apply their own privacy policies. Information you choose to post in a public GitHub issue is public; do not post pairing secrets, private keys, or unreviewed logs. For privacy questions, contact the maintainer through the project's issue tracker:
https://github.com/JordonBibian/astralight/issues

The current public policy is available at:
https://github.com/JordonBibian/astralight/blob/master/PRIVACY.md

Changes
This policy describes Astralight 1.0.0. Material changes to data practices will be reflected in an updated policy and, where required, in the app's disclosures.

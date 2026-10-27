# Astralight 1.0.0 — App Store privacy worksheet

Audited October 27, 2026. This is a release worksheet, not a claim that App Store Connect answers have been published.

Public policy URL: https://github.com/JordonBibian/astralight/blob/master/PRIVACY.md

In-app location: Settings → About Astralight → Privacy Policy (available offline).

## Verified code behavior

| Topic | Audited behavior |
| --- | --- |
| Tracking / advertising | No tracking, advertising SDK, IDFA use, data broker, or targeted advertising. App manifest declares no tracking. |
| Developer backend | No developer-operated streaming, account, analytics, or crash-upload backend. |
| Stream and inputs | Sent directly between the device and the computer chosen by the user. The maintainer does not receive them. |
| Local storage | Computer names/addresses/IDs, paired-host certificate, client certificate/private key, preferences, cached app lists/artwork. Stored in the app container. |
| STUN | Discovery can contact `stun.moonlight-stream.org:3478`. Operator sees public IP/source port. No video/audio/input/keys sent. Retention has not been independently confirmed. |
| Logs | Local connection/performance logs can include computer names and network addresses. PIN/key/raw-request/raw-response logging removed. No automatic app uploader. |
| Apple diagnostics | Maintainer confirmed on October 27, 2026 that Apple-provided crash and performance reports will be used to diagnose problems. Disclose Crash Data and Performance Data for App Functionality. Review the actual report fields and identity linkage before publishing. |
| External links | Open documentation, GitHub source/support, or policy in the browser. No embedded analytics web view. |
| Accounts | No Astralight account, so no in-app account-deletion flow is necessary. Removing a computer locally does not revoke its paired-client entry on the host. |

## Required-reason API manifest

`Limelight/PrivacyInfo.xcprivacy` declares app settings with `NSPrivacyAccessedAPICategoryUserDefaults / CA92.1` and elapsed-time scheduling with `NSPrivacyAccessedAPICategorySystemBootTime / 35F9.1` (including linked SDL timers). These values are bundled at the app root. No boot-time value is sent to an analytics server.

The packaged OpenSSL framework supplies its own privacy manifest. Binary inspection finds `stat`/`fstat` imports in OpenSSL; Astralight's certificate conversion uses memory BIOs, not its file wrappers. The vendor manifest lists no accessed categories. Do not invent an approved reason just to silence validation: if Apple identifies an SDK declaration issue, resolve it with the vendor or rebuild the unused file functionality out and retest.

## Before publishing App Store Connect answers

Apple defines collection in terms of off-device data remaining accessible beyond servicing a real-time request. Local-only settings are not collection under that definition. An empty collected-data list in the app manifest does not certify a third-party server's retention.

1. Confirm the STUN operator's IP/port retention. A transient address lookup with no retained data may be excluded. If the operator retains data, disclose the applicable type and purpose based on its actual use; do not guess that it is anonymous or unlinked. Moonlight's published policy expressly covers its official clients, not this fork, and does not establish STUN retention for Astralight.
2. The maintainer confirmed use of Apple-provided crash and performance reports to diagnose problems. Draft answers: **Crash Data** and **Performance Data**, purpose **App Functionality**, **not used for tracking**. Verify whether report fields can be linked to a person/device before selecting linked/not linked; no production reports have been reviewed yet. Do not infer anonymity merely because the app has no user accounts. TestFlight feedback may include additional voluntarily supplied information; assess it separately.
3. Select no tracking. Do not publish “Data Not Collected”; the maintainer intends to use Apple-provided diagnostics. Finalize all data categories and linkage after the remaining checks above. Keep the public policy, actual behavior, manifest, and App Store answers consistent if services change.

Sources: [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/), [required-reason APIs](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype), [Moonlight privacy policy](https://moonlight-stream.org/privacy.html).

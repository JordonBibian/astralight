# Astralight interface reference

`astralight-reference.png` is a locally rendered design reference created before the iOS UI changes. It is a design mockup, not a screenshot or an AI-generated image.

Direction: a dark blue-to-purple gradient, generous safe-area margins, rounded cards, persistent app titles, clear computer status, and grouped settings. The implemented library uses the host’s real artwork when available.

The app icon uses the reference’s four-point star on a blue-to-purple gradient. `astralight-icon-preview.png` is a preview; the production images live in `Limelight/Images.xcassets/AppIcon.appiconset`. The matching `AstralightMark` image asset is used in the app header.

Regenerate both asset sets with `python3 Design/generate_app_icon.py` (requires Pillow). App icons are opaque RGB images with square corners; iOS applies its own icon mask.

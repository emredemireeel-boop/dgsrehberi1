# DGS iOS ATT review correction

Prepared version 1.1.4 (9), source commit 0601400. The rejected App Store binary 1.1.0 (5) still contains NSUserTrackingUsageDescription according to App Store Connect. The current source Info.plist has no such key or ATT dependency. Consequently the remaining Advertising Data tracking declaration cannot be published until a replacement binary is uploaded/selected; do not claim the correction is complete before then.

## Changes

- iOS banner and interstitial requests use non-personalized ads.
- Native AppDelegate disables publisher first-party ID before plugin registration using Google's documented request configuration API.
- Wait for the current UMP consent form callback before ads initialization; SDK startup failures do not propagate into study flows.
- SDK technical collection remains disclosed. Non-personalized ads do not mean no data collection.
- Public/in-app privacy copy updated; ATT is intentionally not requested for the contextual-ad path.

## Verification

22 October 2026: `flutter analyze --no-pub` clean; `flutter test --reporter expanded` 1 passed (compact timer layout). This does not verify Swift compilation, the signed IPA or physical-iPad ad behavior. These require the Codemagic build and subsequent artifact verification.

## External state

Apple App Privacy: Coarse Location, Device ID and Product Interaction tracking flags changed to No. Advertising Data flag still Yes because Apple rejects No while the currently selected old binary contains the ATT usage string. A replacement IPA is required to complete that last change and the review submission.

Codemagic personal application created: `6ada1afd2a0c2094c2015302`, repository dgsrehberi1. A repeated UI error occurs opening the first-build dialog: "Looks like something broke down" while branches/workflows load. No successful build is claimed at this point.

Official configuration reference: https://developers.google.com/admob/ios/privacy/strategies

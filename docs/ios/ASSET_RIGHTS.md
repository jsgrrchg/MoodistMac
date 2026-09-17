# Audio and app identity release gate

The catalog remains identical on Mac and iOS. `asset-rights.json` binds each bundled audio file to its SHA-256 and a place to record source, author, license and redistribution evidence. The existing README names BBC, Pixabay and CC0 only at collection level. Assigning any of those licenses to individual files without evidence would be incorrect.

**Distribution is not cleared yet.** Fill in the per-file evidence and review the intended distribution before changing each status to `verified`. Run `python3 scripts/ios/check-asset-rights.py --release`. Do not silently remove tracks from iOS to make this gate pass.

The iOS target uses the existing shared app icon asset catalog, which already contains a 1024-point iOS entry. No new logo was invented. Xcode derives platform renditions; manually inspect default/dark/tinted/clear appearances and App Store icon validation before submission. The source PNG has an alpha channel; archive validation must confirm an acceptable App Store icon.

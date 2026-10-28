# mimiTrends-iOS development guidelines

- Keep each Swift source file and top-level type at 400 lines or fewer. Split view sections, persistence, provider adapters, scanner rules, and formatting by responsibility before reaching the limit.
- Trace state ownership, data dependencies, view identity, and action paths before changing SwiftUI screens. Keep disk and network work off the main actor.
- Design for iPadOS 27 first; keep the optional macOS 27 target functional. Check current Apple Human Interface Guidelines when changing controls or layout, including Dynamic Type, contrast, focus, and Reduce Motion. For Mac-specific layout and dialogs, follow the macOS 27 HIG when a design choice is unclear. Settings content should use the available detail width at normal window sizes, with system content backgrounds and compact grouping.
- Use the compact, raised action-button appearance of MiMiNavigator's `DownToolbarButtonView` as the visual reference. Reuse `TrendsActionButton` and `TrendsActionButtonStyle` for app actions. Adapt the appearance to each platform's touch targets and system colors; do not copy MiMiNavigator's bottom bar or its macOS-only settings.
- Keep data surfaces and panels readable with system backgrounds or materials. Reserve decorative effects for controls and navigation; preserve clear hierarchy between the content and interactive elements.
- Verify changed interactions in the running `mimiTrends-iOS` app, not the Kotlin `MiMiTrends` desktop app. Build and test the iPad target and check the Mac target when shared UI code changes.
- Use English for source, comments, UI text, and documentation. Do not add AI attribution. Preserve unrelated edits.

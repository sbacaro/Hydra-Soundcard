# Graph Report - .  (2026-07-21)

## Corpus Check
- Corpus is ~6,639 words - fits in a single context window. You may not need a graph.

## Summary
- 212 nodes · 31 edges · 184 communities (145 shown, 39 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Dante Controller Subsystem (postinstall)
- DVS Subsystem (common.sh)
- Dante Controller Subsystem (conmon_post)
- Dante Controller Subsystem (installer_common.sh)
- Dante Controller Subsystem (preinstall)
- Dante Controller Subsystem (install.sh)
- Dante Controller Subsystem (install.sh)
- Dante Controller Subsystem (install.sh)
- Dante Controller Subsystem (launch_conmon.sh)
- Dante Controller Subsystem (dante_use.sh)
- Dante Controller Subsystem (delete.sh)
- Dante Controller Subsystem (relaunchDaemon.sh)
- Dante Controller Subsystem (use.sh)
- Dante Controller Subsystem (uninstall.sh)
- Dante Controller Subsystem (conmon_pre)
- Dante Controller Subsystem (postinstall)
- Dante Controller Subsystem (postinstall)
- DVS Subsystem (uninstall.sh)
- DVS Subsystem (postinstall)
- DVS Subsystem (preinstall)
- DVS Subsystem (postinstall)
- Dante Controller Subsystem (AUD MAN DanteController)
- Dante Controller Subsystem (UI Tab: hdmi_inputs)
- Dante Controller Subsystem (UI Tab: hdmi_outputs)
- Dante Controller Subsystem (UI Tab: sdi_inputs)
- Dante Controller Subsystem (UI Tab: sdi_outputs)
- Dante Controller Subsystem (UI Tab: serial_config)
- Dante Controller Subsystem (UI Tab: video_config)
- Dante Controller Subsystem (UI Tab: video_decoder)
- Dante Controller Subsystem (UI Tab: video_encoder)
- Dante Controller Subsystem (UI Tab: video_wall)
- Dante Controller Subsystem (index)
- Dante Controller Subsystem (index)
- Dante Controller Subsystem (index)
- Dante Controller Subsystem (index)
- Dante Controller Subsystem (index)
- Dante Controller Subsystem (index)
- Dante Controller Subsystem (index)
- DVS Subsystem (DanteVirtualSoundcardUserGuide)
- DVS Subsystem (ThirdPartyLicenses)

## God Nodes (most connected - your core abstractions)
1. `install.sh script` - 1 edges
2. `install.sh script` - 1 edges
3. `install.sh script` - 1 edges
4. `launch_conmon.sh script` - 1 edges
5. `dante_use.sh script` - 1 edges
6. `delete.sh script` - 1 edges
7. `relaunchDaemon.sh script` - 1 edges
8. `use.sh script` - 1 edges
9. `uninstall.sh script` - 1 edges
10. `installer_common.sh script` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (184 total, 39 thin omitted)

### Community 0 - "Dante Controller Subsystem (postinstall)"
Cohesion: 0.83
Nodes (3): postinstall script, launch_dc(), log_postinstall()

## Knowledge Gaps
- **31 isolated node(s):** `install.sh script`, `install.sh script`, `install.sh script`, `launch_conmon.sh script`, `dante_use.sh script` (+26 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **39 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `install.sh script`, `install.sh script`, `install.sh script` to the rest of the system?**
  _31 weakly-connected nodes found - possible documentation gaps or missing edges._
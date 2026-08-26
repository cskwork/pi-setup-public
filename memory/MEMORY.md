<!-- 2026-08-11 10:19:31 [7f7f91e1] migrated-from-pi-memory-db -->
#fact [[project.aidt.microservices_root]] /Users/danny/Documents/Git/AIDT

<!-- 2026-08-11 12:39:42 [bfbd9b75] migrated-from-pi-memory-db -->
#fact [[project.aidt_dev_harness.portability]] The AIDT dev harness must be fully self-contained for AIDT-specific capabilities: another user should be able to clone/install it and immediately use it for AIDT feature development and debugging without preinstalled machine-local AIDT skills. Only unavoidable external prerequisites such as OMP/model authentication, service repositories, and user-supplied DB credentials may remain external; they must be detected and explained clearly.

<!-- 2026-08-24 20:57:17 [6a1ff017] migrated-from-pi-memory-db -->
#fact [[project.pi-setup.sixpack-pack2]] Pack 2 stays lean: coder → qa, deliberately no cleaner gate, even though upstream SwarmForge two-pack runs coder → cleaner. User confirmed 2026-08-25.

<!-- 2026-08-24 21:19:31 [3df72adb] migrated-from-pi-memory-db -->
#fact [[project.casevault.ocr.tesseract_psm]] CaseVault OCR (corrected 2026-08-25): production tesseract adapter ALREADY uses --psm 11 (internal/ocr/tesseract.go:62). The real X200 recognition defects were in internal/ocr/preprocess.go: (1) alpha bug — color.GrayModel.Convert ignores alpha, so RGBA PNGs with transparent background (~87% non-opaque pixels in x200-generated.png) rendered background black and buried glyphs; fix = composite over opaque white before luminance. (2) point-sampled downscale aliased thin strokes; fix = area-average downscale + maxLongEdge 1000. With both fixes X200 confidence = 90.98 (auto-verify threshold 80). A raw-file `tesseract --psm 11` test bypasses preprocessing and is NOT representative of the production path.

<!-- 2026-08-25 12:59:18 [71f2f248] migrated-from-pi-memory-db -->
#fact [[pi-setup.skill-collision-rule]] pi dedupes skills silently when duplicate names resolve to the SAME realpath, and only warns when realpaths differ. Convention: every shared skill name across ~/.pi/agent/skills, ~/.agents/skills, ~/.pi/skills must symlink to one owner — /Users/danny/pi-setup/skills/<name>. Verify with loadSkills() from @earendil-works/pi-coding-agent/dist/core/skills.js; expect collisions=0.

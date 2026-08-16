#!/usr/bin/env python3
"""Crownfall — mark exported iOS Xcode project as Japanese-localized.

Godot 4.6.x apple_embedded template ships:
  - CFBundleDevelopmentRegion = en
  - en.lproj only
  - project.pbxproj developmentRegion/knownRegions = en

App Store "Languages" is derived from the binary (.lproj / CFBundleLocalizations),
NOT from App Store Connect primary language. Crownfall UI is Japanese-only and
does not use Godot Translation resources, so export never emits ja.lproj.

This script rewrites the exported project so App Store lists Japanese (JA).
Does not touch game scripts or in-game text.
"""

from __future__ import annotations

import argparse
import plistlib
import re
import shutil
import sys
from pathlib import Path


def _find_info_plists(root: Path) -> list[Path]:
	found: list[Path] = []
	for p in root.rglob("*-Info.plist"):
		if "xcframework" in p.parts or "framework" in p.parts:
			continue
		found.append(p)
	# Fallback name used by some export layouts
	for p in root.rglob("Info.plist"):
		if "xcframework" in p.parts or "framework" in p.parts:
			continue
		if p.name == "Info.plist" and p.parent.name.endswith(".app"):
			continue
		# Prefer app Info.plist under the binary folder only
		if p.parent.name not in ("Crownfall", "godot_apple_embedded") and not (
			p.parent / "dummy.cpp"
		).exists():
			continue
		found.append(p)
	# Unique
	uniq: list[Path] = []
	seen: set[Path] = set()
	for p in found:
		rp = p.resolve()
		if rp not in seen:
			seen.add(rp)
			uniq.append(p)
	return uniq


def _find_pbxproj(root: Path) -> Path | None:
	cands = list(root.rglob("project.pbxproj"))
	# Prefer Crownfall.xcodeproj
	for p in cands:
		if p.parent.name.endswith(".xcodeproj") and "Crownfall" in p.parent.name:
			return p
	return cands[0] if cands else None


def _patch_info_plist(path: Path) -> list[str]:
	changes: list[str] = []
	with path.open("rb") as f:
		data = plistlib.load(f)

	old_region = data.get("CFBundleDevelopmentRegion")
	if old_region != "ja":
		data["CFBundleDevelopmentRegion"] = "ja"
		changes.append(f"CFBundleDevelopmentRegion: {old_region!r} -> 'ja'")

	locs = data.get("CFBundleLocalizations")
	if not isinstance(locs, list):
		locs = []
	# Japanese primary only — do not keep en so App Store does not list EN
	new_locs = ["ja"]
	if locs != new_locs:
		data["CFBundleLocalizations"] = new_locs
		changes.append(f"CFBundleLocalizations: {locs!r} -> {new_locs!r}")

	if changes:
		with path.open("wb") as f:
			plistlib.dump(data, f, sort_keys=False)
	return changes


def _replace_en_lproj_with_ja(root: Path) -> list[str]:
	changes: list[str] = []
	# Walk app source dirs only (skip frameworks)
	for en_dir in list(root.rglob("en.lproj")):
		if "xcframework" in en_dir.parts or "framework" in en_dir.parts:
			continue
		ja_dir = en_dir.with_name("ja.lproj")
		if ja_dir.exists():
			# Prefer existing ja; drop en so App Store does not advertise English
			shutil.rmtree(en_dir)
			changes.append(f"removed {en_dir.relative_to(root)} (kept existing ja.lproj)")
			continue
		en_dir.rename(ja_dir)
		changes.append(f"renamed {en_dir.name} -> {ja_dir.name} under {en_dir.parent.relative_to(root)}")
		# Ensure InfoPlist.strings exists
		strings = ja_dir / "InfoPlist.strings"
		if not strings.exists():
			strings.write_text(
				"/* Localized versions of Info.plist keys */\n",
				encoding="utf-8",
			)
			changes.append(f"created {strings.relative_to(root)}")
	# If somehow only missing ja with no en — create minimal ja.lproj next to Info.plist
	if not any(root.rglob("ja.lproj")):
		for info in _find_info_plists(root):
			ja_dir = info.parent / "ja.lproj"
			ja_dir.mkdir(parents=True, exist_ok=True)
			(ja_dir / "InfoPlist.strings").write_text(
				"/* Localized versions of Info.plist keys */\n",
				encoding="utf-8",
			)
			changes.append(f"created {ja_dir.relative_to(root)}")
			break
	return changes


def _patch_pbxproj(path: Path) -> list[str]:
	text = path.read_text(encoding="utf-8")
	orig = text
	changes: list[str] = []

	def sub(pattern: str, repl: str, label: str) -> None:
		nonlocal text
		new_text, n = re.subn(pattern, repl, text)
		if n:
			text = new_text
			changes.append(f"{label} ({n})")

	sub(r"developmentRegion = en;", "developmentRegion = ja;", "developmentRegion en->ja")
	# knownRegions: replace leading en, with ja, (keep Base)
	sub(
		r"knownRegions = \(\s*en,\s*Base,",
		"knownRegions = (\n\t\t\t\tja,\n\t\t\t\tBase,",
		"knownRegions en->ja",
	)
	# File reference for InfoPlist.strings localization
	sub(
		r'name = en; path = en\.lproj/InfoPlist\.strings;',
		"name = ja; path = ja.lproj/InfoPlist.strings;",
		"InfoPlist.strings path en->ja",
	)
	sub(
		r"/\* en \*/ = \{isa = PBXFileReference; lastKnownFileType = text\.plist\.strings; name = ja;",
		"/* ja */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = ja;",
		"PBXFileReference comment en->ja",
	)
	# Variant group child comment
	sub(
		r"(D0BCFE4518AEBDA2004A7AAE /\*) en( \*/,)",
		r"\1 ja\2",
		"PBXVariantGroup child en->ja",
	)

	if text != orig:
		path.write_text(text, encoding="utf-8")
	elif not changes:
		# Already patched or unexpected layout — still report if ja already set
		if "developmentRegion = ja;" in text:
			changes.append("pbxproj already Japanese (no edit)")
		else:
			changes.append("WARNING: pbxproj layout unexpected; manual check needed")
	return changes


def fix_ios_root(root: Path) -> int:
	if not root.is_dir():
		print(f"ERROR: not a directory: {root}", file=sys.stderr)
		return 1

	print(f"=== fix_ios_japanese_localization: {root} ===")
	any_change = False

	plists = _find_info_plists(root)
	if not plists:
		print("WARNING: no *-Info.plist found")
	for plist in plists:
		ch = _patch_info_plist(plist)
		if ch:
			any_change = True
			print(f"Info.plist {plist.relative_to(root)}:")
			for c in ch:
				print(f"  - {c}")
		else:
			print(f"Info.plist {plist.relative_to(root)}: already ja")

	for c in _replace_en_lproj_with_ja(root):
		any_change = True
		print(f"lproj: {c}")

	pbx = _find_pbxproj(root)
	if pbx is None:
		print("WARNING: project.pbxproj not found")
	else:
		ch = _patch_pbxproj(pbx)
		if ch and ch != ["pbxproj already Japanese (no edit)"]:
			any_change = True
		print(f"pbxproj {pbx.relative_to(root)}:")
		for c in ch:
			print(f"  - {c}")

	# Verify
	ok = True
	ja_dirs = [p for p in root.rglob("ja.lproj") if "xcframework" not in p.parts]
	en_dirs = [p for p in root.rglob("en.lproj") if "xcframework" not in p.parts]
	if not ja_dirs:
		print("ERROR: ja.lproj missing after fix", file=sys.stderr)
		ok = False
	if en_dirs:
		print(f"ERROR: en.lproj still present: {en_dirs}", file=sys.stderr)
		ok = False
	for plist in plists:
		with plist.open("rb") as f:
			data = plistlib.load(f)
		if data.get("CFBundleDevelopmentRegion") != "ja":
			print(f"ERROR: {plist} CFBundleDevelopmentRegion != ja", file=sys.stderr)
			ok = False
		locs = data.get("CFBundleLocalizations")
		if locs != ["ja"]:
			print(f"ERROR: {plist} CFBundleLocalizations={locs!r}", file=sys.stderr)
			ok = False

	if ok:
		print("OK: Japanese localization markers applied" + (" (updated)" if any_change else " (idempotent)"))
		return 0
	return 2


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument(
		"root",
		nargs="?",
		default="build/ios",
		help="Exported iOS project root (default: build/ios)",
	)
	args = parser.parse_args()
	return fix_ios_root(Path(args.root).resolve())


if __name__ == "__main__":
	sys.exit(main())

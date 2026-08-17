#!/usr/bin/env python3
"""Self-test for tools/fix_ios_japanese_localization.py (no Xcode required)."""

from __future__ import annotations

import plistlib
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import fix_ios_japanese_localization as fix  # noqa: E402


FIXTURE_INFO = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>Crownfall</string>
	<key>CFBundleIdentifier</key>
	<string>com.example.crownfall</string>
	<key>CFBundleName</key>
	<string>Crownfall</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
</dict>
</plist>
"""

FIXTURE_PBX = """// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 46;
	objects = {
		D0BCFE4518AEBDA2004A7AAE /* en */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = en; path = en.lproj/InfoPlist.strings; sourceTree = "<group>"; };
		D0BCFE4418AEBDA2004A7AAE /* InfoPlist.strings */ = {
			isa = PBXVariantGroup;
			children = (
				D0BCFE4518AEBDA2004A7AAE /* en */,
			);
			name = InfoPlist.strings;
			sourceTree = "<group>";
		};
	};
	rootObject = D0BCFE2C18AEBDA2004A7AAE /* Project object */;
	/* Begin PBXProject section */
		D0BCFE2C18AEBDA2004A7AAE /* Project object */ = {
			isa = PBXProject;
			attributes = {
			};
			buildConfigurationList = D0BCFE2F18AEBDA2004A7AAE;
			compatibilityVersion = "Xcode 3.2";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = D0BCFE2B18AEBDA2004A7AAE;
		};
	/* End PBXProject section */
}
"""


def build_fixture(tmp: Path) -> Path:
	root = tmp / "ios"
	app = root / "Crownfall"
	app.mkdir(parents=True)
	(app / "Crownfall-Info.plist").write_text(FIXTURE_INFO, encoding="utf-8")
	en = app / "en.lproj"
	en.mkdir()
	(en / "InfoPlist.strings").write_text(
		"/* Localized versions of Info.plist keys */\n", encoding="utf-8"
	)
	# Touch dummy.cpp so Info.plist discovery treats this as app dir if needed
	(app / "dummy.cpp").write_text("// dummy\n", encoding="utf-8")
	xcode = root / "Crownfall.xcodeproj"
	xcode.mkdir()
	(xcode / "project.pbxproj").write_text(FIXTURE_PBX, encoding="utf-8")
	return root


def main() -> int:
	with tempfile.TemporaryDirectory(prefix="crownfall_ios_ja_") as td:
		root = build_fixture(Path(td))
		rc = fix.fix_ios_root(root)
		if rc != 0:
			print("FAIL: fix returned", rc, file=sys.stderr)
			return 1

		info = root / "Crownfall" / "Crownfall-Info.plist"
		with info.open("rb") as f:
			data = plistlib.load(f)
		assert data["CFBundleDevelopmentRegion"] == "ja", data
		assert data["CFBundleLocalizations"] == ["ja"], data
		assert (root / "Crownfall" / "ja.lproj" / "InfoPlist.strings").is_file()
		assert not (root / "Crownfall" / "en.lproj").exists()

		pbx = (root / "Crownfall.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
		assert "developmentRegion = ja;" in pbx
		assert "ja," in pbx
		assert "path = ja.lproj/InfoPlist.strings;" in pbx
		assert "name = ja;" in pbx
		assert "path = en.lproj/InfoPlist.strings;" not in pbx

		# Idempotent second run
		rc2 = fix.fix_ios_root(root)
		assert rc2 == 0

	print("PASS: fix_ios_japanese_localization self-test")
	return 0


if __name__ == "__main__":
	sys.exit(main())

#!/usr/bin/env bash
# Crownfall — iPhone テストプレイ環境セットアップ（Godot 4.6.3 + iOS export）
#
# 使い方:
#   bash tools/setup_ios_testplay.sh          # Godot + export templates を入れる
#   bash tools/setup_ios_testplay.sh --check  # インストール状況だけ確認
#
# 初回 iPhone 実機テストの流れ（このスクリプトの後）:
#   1. Xcode → Settings → Accounts で Apple ID を追加
#   2. iPhone を USB 接続 → 「このコンピュータを信頼」
#   3. Godot でプロジェクトを開く → Project → Export → iOS
#   4. Bundle Identifier / Team を設定 → Export Project
#   5. 出力された .xcodeproj を Xcode で開く → **実機 iPhone** を選んで ▶ Run
#
# 注意: 実行先に「iPhone 17 Pro」等の **Simulator** を選ぶと
#       Undefined symbol: _main で失敗する（Godot 4.6.3 の sim 用 lib が x86_64 のみのため）。
#       接続中の実機（例: "iPhone"）を選ぶこと。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_VERSION="4.6.3"
GODOT_DIR="$ROOT/tools/godot"
GODOT_APP="$GODOT_DIR/Godot.app"
GODOT_BIN="$GODOT_APP/Contents/MacOS/Godot"
TEMPLATES_DIR="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"
GODOT_ZIP_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_macos.universal.zip"
TEMPLATES_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"

MODE="${1:-install}"

red() { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }

check_xcode() {
    if ! xcode-select -p &>/dev/null; then
        red "ERROR: Xcode Command Line Tools がありません。"
        echo "  → Xcode を App Store から入れて一度起動してください。"
        return 1
    fi
    green "OK: Xcode $(xcodebuild -version | head -1)"
}

check_signing() {
    local count
    count="$(security find-identity -v -p codesigning 2>/dev/null | rg -c 'Apple Development|Developer ID' || true)"
    if [[ "$count" -eq 0 ]]; then
        yellow "WARN: コード署名証明書がまだありません。"
        echo "  → Xcode → Settings → Accounts で Apple ID を追加すると自動作成されます。"
        echo "  → 無料 Apple ID でも自分の iPhone へのテストインストールは可能です。"
    else
        green "OK: コード署名証明書 $count 件"
        security find-identity -v -p codesigning 2>/dev/null | rg 'Apple Development|Developer ID' || true
    fi
}

check_godot() {
    if [[ -x "$GODOT_BIN" ]]; then
        green "OK: Godot $($GODOT_BIN --version 2>&1 | head -1)"
        echo "     $GODOT_BIN"
    else
        red "MISSING: Godot ${GODOT_VERSION}（$GODOT_APP）"
        return 1
    fi
}

check_templates() {
    if [[ -f "$TEMPLATES_DIR/ios.zip" ]]; then
        green "OK: Export templates (${GODOT_VERSION}.stable)"
    else
        red "MISSING: Export templates"
        echo "     期待パス: $TEMPLATES_DIR/ios.zip"
        return 1
    fi
}

check_export_preset() {
    if [[ -f "$ROOT/export_presets.cfg" ]]; then
        green "OK: export_presets.cfg あり"
    else
        yellow "WARN: export_presets.cfg 未作成"
        if [[ -f "$ROOT/export_presets.example.cfg" ]]; then
            echo "  → cp export_presets.example.cfg export_presets.cfg"
            echo "  → Bundle Identifier を自分用に変更"
        fi
    fi
}

check_iphone() {
    if xcrun devicectl list devices 2>/dev/null | rg -q 'iPhone|iPad'; then
        green "OK: 接続中の iOS デバイス"
        xcrun devicectl list devices 2>/dev/null | rg 'iPhone|iPad' || true
    else
        yellow "WARN: iPhone が USB 接続されていません（後で接続してください）"
    fi
}

install_godot() {
    if [[ -x "$GODOT_BIN" ]]; then
        green "SKIP: Godot は既にインストール済み"
        return 0
    fi
    echo "=== Godot ${GODOT_VERSION} をダウンロード ==="
    mkdir -p "$GODOT_DIR"
    local tmp
    tmp="$(mktemp -d)"
    curl -L --progress-bar -o "$tmp/godot.zip" "$GODOT_ZIP_URL"
    unzip -q -o "$tmp/godot.zip" -d "$GODOT_DIR"
    rm -rf "$tmp"
    chmod +x "$GODOT_BIN"
    green "Installed: $GODOT_BIN"
}

install_templates() {
    if [[ -f "$TEMPLATES_DIR/ios.zip" ]]; then
        green "SKIP: Export templates は既にインストール済み"
        return 0
    fi
    echo "=== Export templates ${GODOT_VERSION} をダウンロード ==="
    mkdir -p "$TEMPLATES_DIR"
    local tmp tpz
    tmp="$(mktemp -d)"
    tpz="$tmp/templates.tpz"
    curl -L --progress-bar -o "$tpz" "$TEMPLATES_URL"
    unzip -q -o "$tpz" -d "$TEMPLATES_DIR"
    rm -rf "$tmp"
    # Godot 4.6 は ios.zip をバージョン直下で探す（tpz は templates/ 配下に展開される）
    if [[ -f "$TEMPLATES_DIR/templates/ios.zip" && ! -f "$TEMPLATES_DIR/ios.zip" ]]; then
        cp "$TEMPLATES_DIR/templates/ios.zip" "$TEMPLATES_DIR/ios.zip"
    fi
    green "Installed: $TEMPLATES_DIR"
}

ensure_export_preset() {
    if [[ -f "$ROOT/export_presets.cfg" ]]; then
        return 0
    fi
    if [[ ! -f "$ROOT/export_presets.example.cfg" ]]; then
        yellow "WARN: export_presets.example.cfg がありません"
        return 0
    fi
    cp "$ROOT/export_presets.example.cfg" "$ROOT/export_presets.cfg"
    yellow "Created export_presets.cfg（Bundle Identifier を確認してください）"
}

print_team_id_help() {
    cat <<EOF
Team ID の調べ方:
  Xcode → Settings → Accounts → 自分の Apple ID を選択
  → Team 名の下に表示される 10 文字（例: AB12CD34EF）

設定方法（どちらか）:
  A) export_presets.cfg の application/app_store_team_id に直接記入
  B) 環境変数: export GODOT_IOS_TEAM_ID=AB12CD34EF
     bash tools/setup_ios_testplay.sh --export

EOF
}

export_ios_project() {
    local team_id="${GODOT_IOS_TEAM_ID:-}"
    if [[ -z "$team_id" && -f "$ROOT/export_presets.cfg" ]]; then
        team_id="$(rg -o 'application/app_store_team_id="([^"]*)"' -r '$1' "$ROOT/export_presets.cfg" | head -1 || true)"
    fi
    if [[ -z "$team_id" ]]; then
        red "ERROR: App Store Team ID が未設定です。"
        print_team_id_help
        return 1
    fi
    if [[ -f "$ROOT/export_presets.cfg" ]]; then
        perl -i -pe "s/application\\/app_store_team_id=\".*\"/application\\/app_store_team_id=\"$team_id\"/" "$ROOT/export_presets.cfg"
    fi
    mkdir -p "$ROOT/build/ios"
    echo "=== iOS Xcode プロジェクトをエクスポート ==="
    "$GODOT_BIN" --path "$ROOT" --headless --export-debug "iOS" "$ROOT/build/ios/Crownfall.xcodeproj"
    green "Exported: $ROOT/build/ios/Crownfall.xcodeproj"
    echo "次: open \"$ROOT/build/ios/Crownfall.xcodeproj\""
}

print_next_steps() {
    cat <<EOF

=== 次の手順（初回のみ）===

1. Apple ID を Xcode に登録
   Xcode → Settings (⌘,) → Accounts → 「+」→ Apple ID

2. iPhone を USB 接続
   iPhone 側で「このコンピュータを信頼」をタップ

3. Team ID を設定してエクスポート
   bash tools/setup_ios_testplay.sh --team-id   # 調べ方表示
   export GODOT_IOS_TEAM_ID=あなたのTeamID
   bash tools/setup_ios_testplay.sh --export

4. Xcode で実機 Run
   open build/ios/Crownfall.xcodeproj
   上部の実行先で iPhone を選択 → ▶ Run
   初回は iPhone: 設定 → 一般 → VPNとデバイス管理 で開発者を信頼

Godot エディタ起動:
  $GODOT_BIN --path "$ROOT" --editor

EOF
}

case "$MODE" in
    --check|check)
        echo "=== Crownfall iOS テストプレイ環境チェック ==="
        check_xcode || true
        check_signing || true
        check_godot || true
        check_templates || true
        check_export_preset || true
        check_iphone || true
        ;;
    --export|export)
        check_godot
        check_templates
        export_ios_project
        ;;
    --team-id|team-id)
        print_team_id_help
        ;;
    --help|-h)
        sed -n '1,20p' "$0"
        ;;
    *)
        echo "=== Crownfall iOS テストプレイ環境セットアップ ==="
        check_xcode
        install_godot
        install_templates
        ensure_export_preset
        echo ""
        echo "=== チェック ==="
        check_godot
        check_templates
        check_signing || true
        check_export_preset || true
        print_next_steps
        ;;
esac

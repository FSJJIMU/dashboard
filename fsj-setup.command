#!/bin/bash
# Mac用 ワンライン導入・更新スクリプト（Windowsの fsj-setup.bat と同じ役割）。
#
# ★なぜターミナルに1行貼らせるのか
#   macOS 15（Sequoia）から、ブラウザで落とした未署名のスクリプトは
#   右クリック →「開く」でも実行できなくなった（Appleが抜け道を廃止）。
#   落としたファイルには com.apple.quarantine という印が付き、
#   システム設定で1つずつ許可しない限りブロックされる。
#   curl で受け取って bash に直接渡せば、そもそもファイルとして
#   保存されないので印が付かない。貼り付けは1回だけで、
#   ここで印を消しておくため、2回目以降はダブルクリックで開ける。
#
#   使い方:
#     curl -fsSL https://fsjjimu.github.io/dashboard/fsj-setup.command | bash
#
# ★パイプ経由で動くことを壊さないこと
#   このスクリプト自身が標準入力なので、read や python の input() は
#   必ず < /dev/tty を付けて端末から読む。付け忘れると、
#   入力待ちが即座に終了して設定が空のまま進む。

URL="https://fsjjimu.github.io/dashboard/fsj-second-sender.zip"
APP="$HOME/FSJセカンド自動送信"
TMPZIP="${TMPDIR:-/tmp}/fsj-second-sender.zip"

say() { printf '%s\n' "$1"; }
die() {
  say ""
  say "  [エラー] $1"
  say ""
  [ -e /dev/tty ] && read -r -p "  Enterで閉じます" _ < /dev/tty
  exit 1
}

say ""
say "  FSJ セカンド自動送信"
say "  ===================="
say "  入れる場所: $APP"
say ""

# ── 動いている最中に上書きすると壊れる ──
if pgrep -f "second_sender.py" >/dev/null 2>&1; then
  die "セカンド自動送信が動いています。
        「セカンド自動送信_常駐起動」の窓を閉じてから、
        もう一度実行してください。"
fi

# ── python3 の確認 ──
# macOS の /usr/bin/python3 は、開発ツールが未導入だと「入れますか」と
# 聞くだけの入れ物になっている。あるかどうかではなく、動くかを見る。
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then
  say "  Python が入っていないようです。"
  say "  画面に「コマンドラインデベロッパツールをインストール」と出たら"
  say "  「インストール」を押して、終わってからもう一度この1行を貼ってください。"
  die "Python 3.8 以上が必要です。
        出てこない場合は https://www.python.org から入れてください。"
fi

# ── 取ってくる ──
say "  [1/4] ダウンロードしています..."
curl -L -f -s -S -o "$TMPZIP" "$URL" || die "ダウンロードできませんでした。
        ネットワークを確認してもう一度お試しください。
        $URL"
[ -s "$TMPZIP" ] || die "ダウンロードしたファイルが空です。"

# ── 展開する ──
say "  [2/4] 展開しています..."
mkdir -p "$APP" || die "フォルダを作れませんでした: $APP"
unzip -oq "$TMPZIP" -d "$APP" || die "展開できませんでした。
        $APP を開いている窓を閉じてもう一度お試しください。"
rm -f "$TMPZIP"
[ -f "$APP/scripts/setup_wizard.py" ] || die "中身が足りません。もう一度お試しください。"

# ★ここが要点。ダウンロードの印を消し、実行できるようにしておく。
#   これをやっておくと、次回からデスクトップのフォルダを
#   ダブルクリックするだけで開ける（ターミナルはもう使わない）。
xattr -dr com.apple.quarantine "$APP" 2>/dev/null
chmod +x "$APP"/Mac/*.command 2>/dev/null

# ── 足りない部品を入れる ──
# Windowsは python-embed に同梱しているが、Macは同梱できないためここで入れる。
if ! python3 -c "import websocket" >/dev/null 2>&1; then
  say "  [3/4] 必要な部品を入れています（1分ほどかかることがあります）..."
  python3 -m pip install --user --quiet websocket-client >/dev/null 2>&1 || \
    say "      [!] 自動で入りませんでした。あとで「セットアップ診断」に従ってください。"
else
  say "  [3/4] 必要な部品は入っています。"
fi

# ── 設定へ ──
say "  [4/4] セットアップを始めます。"
say ""
cd "$APP" || die "フォルダに入れませんでした: $APP"

# ★ < /dev/tty が必須。付けないと、このスクリプト自身（パイプ）を
#   入力として読んでしまい、名前もキーも空のまま通り抜ける。
python3 -X utf8 scripts/setup_wizard.py < /dev/tty

say ""
[ -e /dev/tty ] && read -r -p "  Enterで閉じます" _ < /dev/tty

# WSL Codex / Claude VS Code 起動クラッシュ対策メモ 2026-06-11

## 症状

VS Code / Windows Terminal から WSL 下の Codex または Claude Code を起動すると、ターミナルがすぐ終了し、Windows Terminal 側で次のように表示される。

```text
[プロセスはコード 1 (0x00000001) で終了しました]
```

## 重要な発見

VS Code のユーザー設定により、Windows 側で開いているワークスペースがそのまま WSL CLI の起動ディレクトリになっていた。

```jsonc
"terminal.integrated.defaultProfile.windows": "Ubuntu (WSL)",
"terminal.integrated.cwd": "${workspaceFolder}",
"chatgpt.runCodexInWindowsSubsystemForLinux": true
```

問題発生時のワークスペースは次だった。

```text
C:\Users\yt\OneDrive\画像\Screenshots
```

WSL 側では次の DrvFs パスになる。

```text
/mnt/c/Users/yt/OneDrive/画像/Screenshots
```

Claude Code の IDE 連携ロックも Windows 側ホームに作られていた。

```text
/mnt/c/Users/yt/.claude/ide/32281.lock
```

中身は次の通りで、Screenshots ワークスペースを指していた。

```json
{"pid":39500,"workspaceFolders":["c:\\Users\\yt\\OneDrive\\画像\\Screenshots"],"ideName":"Visual Studio Code","transport":"ws","runningInWindows":true}
```

つまり、Windows VS Code 拡張、WSL CLI、Windows 側 `.claude`、WSL 側 `~/.claude` が混ざっていた。

## 直した内容

### 1. VS Code ユーザー設定

対象:

```text
C:\Users\yt\AppData\Roaming\Code\User\settings.json
```

WSL ターミナルの起動 cwd を `${workspaceFolder}` に依存させず、Ubuntu プロファイル自体を `/home/y` で起動するようにした。あわせて、Windows 側から WSL CLI を起動する時の環境変数も WSL ホームへ寄せた。

```jsonc
"terminal.integrated.defaultProfile.windows": "Ubuntu (WSL)",
"terminal.integrated.profiles.windows": {
  "Ubuntu (WSL)": {
    "path": "C:\\WINDOWS\\System32\\wsl.exe",
    "args": ["-d", "Ubuntu", "--cd", "/home/y"],
    "icon": "terminal-ubuntu"
  }
},
"terminal.integrated.env.windows": {
  "HOME": "/home/y",
  "CODEX_HOME": "/home/y/.codex"
},
"claudeCode.environmentVariables": [
  {
    "name": "HOME",
    "value": "/home/y"
  }
]
```

### 2. Claude グローバル設定

対象:

```text
/home/y/.claude/settings.json
```

壊れたモデル名を修正した。

```diff
- "model": "claude-fable-5[1m]"
+ "model": "claude-fable-5"
```

### 3. Codex npm prefix

Codex は `/home/y/.local` 配下に入っているのに、npm の global prefix が `/usr` になっていた。これにより `codex doctor` が終了コード 1 になっていた。

修正:

```bash
npm config set prefix "$HOME/.local" --location=user
```

結果:

```text
~/.npmrc: prefix=/home/y/.local
codex doctor: 17 ok, 0 fail
```

### 4. ~/.profile の重複整理

`~/.profile` に fcitx5 自動起動ブロックが 4 回重複していたため、1 つに整理した。

## 検証済み

WSL ネイティブ側:

```bash
codex doctor
# 17 ok · 1 idle · 1 notes · 0 warn · 0 fail

claude -p 'Reply exactly: OK' --output-format text
# OK

bash -l -c 'echo login-shell-ok'
# login-shell-ok

bash -i -c 'echo interactive-shell-ok'
# interactive-shell-ok
```

OneDrive/Screenshots 配下でも、HOME を WSL 側へ寄せれば正常。

```bash
cd /mnt/c/Users/yt/OneDrive/画像/Screenshots
HOME=/home/y CODEX_HOME=/home/y/.codex codex doctor --summary
# 17 ok · 0 fail

HOME=/home/y claude -p 'Reply exactly: OK' --output-format text
# OK
```

旧条件に近い `HOME=/mnt/c/Users/yt` では、Claude が `/mnt/c/Users/yt/.claude` を読みに行き、設定・プラグイン・IDE 状態が Windows 側に二重化する。

## 残る注意点

現在開いている VS Code ウィンドウは、古い設定と古い IDE ロックを保持している可能性がある。設定変更後は VS Code の該当ウィンドウを再読み込みまたは閉じ直すこと。

特に PID 39500 の VS Code は、調査時点で次のロックを保持していた。

```text
/mnt/c/Users/yt/.claude/ide/32281.lock
```

安全のため、未保存ファイルがないことを確認してから VS Code を再起動する。再起動後も古い lock が残る場合のみ、該当 lock を削除する。

## 推奨運用

Codex / Claude Code で WSL 内のファイルを触る場合、Windows ローカルの OneDrive フォルダをワークスペースにしない。

推奨ワークスペース:

```text
/home/y/PIV,PEJVO統合20260605 - コピー
```

VS Code ではできる限り `Reopen Folder in WSL` または WSL 側パスで開く。

避けるべきワークスペース:

```text
C:\Users\yt\OneDrive\画像\Screenshots
/mnt/c/Users/yt/OneDrive/画像/Screenshots
```

## 再発時の最小診断

```bash
echo "cwd=$(pwd)"
echo "HOME=$HOME"
echo "CODEX_HOME=${CODEX_HOME:-}"
which codex claude
codex doctor --summary
claude --version
find ~/.claude/ide /mnt/c/Users/yt/.claude/ide -maxdepth 1 -type f -name '*.lock' -print 2>/dev/null
```

期待値:

```text
HOME=/home/y
CODEX_HOME=/home/y/.codex
Codex doctor: 0 fail
Claude lock は原則 WSL 側または現行プロセスに対応していること
```

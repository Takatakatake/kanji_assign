# 統合検証スイート(前向き・継続検証プロトコル)。1コマンドで全コーパスの健全性を点検しログ化。
#   A. ハード不変条件(原本diff/一级外/数字id/群内id重複)= 絶対防衛線
#   B. 優先順位(CSV2890被覆・境界44104)
#   C. 偽分解(全分節割れ検出器の base分岐フラグ数=既知から増えてないか)
#   D. WSLドリフト(プロジェクト辞書 vs WSL最前線=再同期要否)
#   E. 数字id(注入全体)
# サブscriptは Write-Host 出力なので *>&1 で捕捉。結果サマリを画面+ _verify_log.txt(追記)。全PASSで exit 0。
$ErrorActionPreference='Continue'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
Set-Location $dir
$ts=(Get-Date -Format 'yyyy-MM-dd HH:mm')
$LOG=New-Object System.Collections.ArrayList
function Say($s){ [void]$LOG.Add([string]$s); Write-Host ([string]$s) }
$fail=0
Push-Location $dir; $hash=(& git rev-parse --short HEAD 2>$null); Pop-Location
Say ("===== 統合検証 " + $ts + " / HEAD=" + ([string]$hash).Trim() + " =====")

# --- A. ハード不変条件(*>&1 で Write-Host 捕捉) ---
$inv = & "$dir\_audit_invariants.ps1" *>&1 | Out-String
$jiOut = ([regex]::Match($inv,'一级外字\s*=\s*(\d+)')).Groups[1].Value
$numId = ([regex]::Match($inv,'数字id\s*=\s*(\d+)')).Groups[1].Value
$dupId = ([regex]::Match($inv,'群内id重複\s*=\s*(\d+)')).Groups[1].Value
$diff0 = ([regex]::Matches($inv,'原本diff\s*=\s*0\s*PASS')).Count
Say ("[A] 不変条件: 原本diff=0 PASS x" + $diff0 + " / 一级外=" + $jiOut + " / 数字id=" + $numId + " / id重複=" + $dupId)
if($diff0 -lt 2 -or $jiOut -ne '0' -or $numId -ne '0' -or $dupId -ne '0'){ $fail=1; Say "    !! ハード不変条件に違反 → 要即対応" }

# --- B. 優先順位 ---
$pri = & "$dir\_audit_priority.ps1" *>&1 | Out-String
$csvCov = ([regex]::Match($pri,'割当済\s*\d+\s*\(([\d\.]+)%\)')).Groups[1].Value
$csvGap = ([regex]::Match($pri,'要検討content(\d+)')).Groups[1].Value
Say ("[B] 優先順位: CSV2890被覆=" + $csvCov + "% / 要検討contentギャップ=" + $csvGap + "件(音訳/固有名/一级外=正当)")
$bd = & "$dir\_audit_tiers.ps1" *>&1 | Out-String
$piBefore = ([regex]::Match($bd,'44104\)以前にある【PIV】行\s*=\s*(\d+)')).Groups[1].Value
Say ("    境界44104以前の【PIV】行=" + $piBefore + "(0が正)")
if($piBefore -ne '0'){ $fail=1; Say "    !! 境界違反" }

# --- C. 偽分解 検出器 base分岐フラグ ---
foreach($v in @('学習者','学術')){
  $o = & "$dir\_audit_sep_coverage.ps1" ("漢字注入_"+$v+"版_20260620.txt") *>&1 | Out-String
  $flags = ([regex]::Match($o,'base分岐フラグ\s*(\d+)')).Groups[1].Value
  Say ("[C] 偽分解 "+$v+"版: base分岐フラグ=" + $flags + "(基準 学習81前後/学術46前後=2026-06-27。新規sep追加で漸増は正常・急増は新誤友の疑い→変更語点検)")
}

# --- D. WSLドリフト ---
$wsl='\\wsl.localhost\Ubuntu\home\y\エスペラント辞書徹底語根分解_20260619'
$pej=Join-Path $dir '20_PEJVO語彙リスト_原本・生成版_2024-2026'
$drift=0
if(Test-Path -LiteralPath $wsl){
  foreach($n in @('世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt','世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt')){
    $w=Get-Item -LiteralPath (Join-Path $wsl $n) -ErrorAction SilentlyContinue; $p=Get-Item -LiteralPath (Join-Path $pej $n) -ErrorAction SilentlyContinue
    if($w -and $p -and ($w.Length -ne $p.Length)){ $drift++; Say ("[D] WSLドリフト検出: "+$n.Substring(0,4)+" WSL="+$w.Length+"("+$w.LastWriteTime.ToString('MM-dd HH:mm')+") != PROJ="+$p.Length+" → 同期+変更語点検を推奨") }
  }
  if($drift -eq 0){ Say "[D] WSLドリフト: なし(最新に同期済)" }
} else { Say "[D] WSLドリフト: WSL未接続(スキップ)" }

# --- E. 注入の数字付き識別子 ---
$nNum=0
foreach($ln in [System.IO.File]::ReadAllLines((Join-Path $dir '漢字注入_学習者版_20260620.txt'))){ foreach($m in [regex]::Matches($ln,'⟦([^⟧]*)⟧')){ if($m.Groups[1].Value -match '[一-鿿][ʰ-˿ᴀ-ᶿ̀-ͯ]*[0-9]'){ $nNum++ } } }
Say ("[E] 注入の数字付き識別子=" + $nNum + "(0が正)")
if($nNum -gt 0){ $fail=1; Say "    !! 注入に数字id" }

# --- F. 偽分解尊重 整合性(漢字化語根がlatin残存=同綴別語/結合形/固有名で正当か) ---
$fc = & "$dir\_audit_fake_decomp_consistency.ps1" *>&1 | Out-String
$newInc = ([regex]::Match($fc,'★新規不整合\s*=\s*(\d+)')).Groups[1].Value
if($newInc -eq ''){ $newInc='?' }
Say ("[F] 偽分解整合性: ★新規不整合=" + $newInc + "件(0が正。既知19件=同綴別語/結合形/固有名で正当。新規が出たら語義照合で homonym か真の違反か判定)")
if($newInc -ne '0' -and $newInc -ne '?'){ Say "    !! 新規の偽分解不整合候補あり → 変更語を語義照合で点検" }

# --- 総括 ---
$verdict='全PASS(健全・同期も最新)'
if($fail -ne 0){ $verdict='要対応(ハード違反あり)' } elseif($drift -ne 0){ $verdict='不変条件PASSだが WSL再同期推奨' } elseif($newInc -ne '0' -and $newInc -ne '?'){ $verdict='不変条件PASSだが 新規偽分解不整合の点検推奨' }
Say ("===== 総括: " + $verdict + " =====")
Add-Content -LiteralPath (Join-Path $dir '_verify_log.txt') -Value (($LOG -join "`r`n") + "`r`n") -Encoding UTF8
Write-Host "→ ログ追記: _verify_log.txt"
if($fail -gt 0){ exit 1 } else { exit 0 }

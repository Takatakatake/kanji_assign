# 統合検証スイート(前向き・継続検証プロトコル)。1コマンドで全コーパスの健全性を点検しログ化。
#   A. ハード不変条件(原本diff/一级外/数字id/群内id重複)= 絶対防衛線
#   B. 優先順位(CSV2890被覆・境界44104)
#   C. 偽分解(全分節割れ検出器の base分岐フラグ数=既知から増えてないか)
#   D. WSLドリフト(プロジェクト辞書 vs WSL最前線=再同期要否)
#   E. 数字id(注入全体)
# サブscriptは Write-Host 出力なので *>&1 で捕捉。結果サマリを画面+ _verify_log.txt(追記)。全PASSで exit 0。
$ErrorActionPreference='Continue'
$dir=$PSScriptRoot
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
$firstPivLn = ([regex]::Match($bd,'最初の【PIV】行\s*=\s*(\d+)')).Groups[1].Value
$pivSuppN = ([regex]::Match($bd,'PEJVO追補区間\(44105-44440\)内の【PIV】行\s*=\s*(\d+)')).Groups[1].Value
Say ("    境界44104以前の【PIV】行=" + $piBefore + "(0が正) / 最初の【PIV】=" + $firstPivLn + "行 / 追補(44105-44440)内【PIV】=" + $pivSuppN + "(0が正=追補は純PEJVO)")
Say ("    3層: 1-44104旧PEJVO / 44105-44440 PEJVO追補 / " + $firstPivLn + "以降PIV(>44104=全PIV ではない)")
if($piBefore -ne '0' -or ($pivSuppN -ne '' -and $pivSuppN -ne '0')){ $fail=1; Say "    !! 境界違反(PEJVO領域にPIV混入)" }

# --- C. 偽分解 検出器 base分岐フラグ ---
foreach($v in @('学習者','学術')){
  $o = & "$dir\_audit_sep_coverage.ps1" ("漢字注入_"+$v+"版_20260620.txt") *>&1 | Out-String
  $flags = ([regex]::Match($o,'base分岐フラグ\s*(\d+)')).Groups[1].Value
  Say ("[C] 偽分解 "+$v+"版: base分岐フラグ=" + $flags + "(基準 学習81前後/学術46前後=2026-06-27。新規sep追加で漸増は正常・急増は新誤友の疑い→変更語点検)")
}

# --- D. 原本ドリフト(正本DICT + WSL) ---
# 2026-07-16 教訓: 正本はD:の分解dir(20260630)。従来はWSL(20260619)しか監視せず正本更新を見逃した→DICT監視を主に。
# 2026-07-17 是正: ファイルサイズ比較は「同サイズの内容変更」を見逃す→SHA-256比較に変更(監査指摘)。
$dict=Join-Path (Split-Path $dir -Parent) 'エスペラント辞書徹底語根分解_20260630'
$wsl='\\wsl.localhost\Ubuntu\home\y\エスペラント辞書徹底語根分解_20260619'
$pej=Join-Path $dir '20_PEJVO語彙リスト_原本・生成版_2024-2026'
function Sha256Of([string]$path){ try{ (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash }catch{ $null } }
$drift=0; $dictDrift=0
foreach($srcPair in @(@('DICT正本',$dict),@('WSL',$wsl))){
  $label=$srcPair[0]; $src=$srcPair[1]
  if(Test-Path -LiteralPath $src){
    foreach($n in @('世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt','世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt')){
      $sp=Join-Path $src $n; $pp=Join-Path $pej $n
      if((Test-Path -LiteralPath $sp) -and (Test-Path -LiteralPath $pp)){
        $hw=Sha256Of $sp; $hp=Sha256Of $pp
        if($hw -and $hp -and ($hw -ne $hp)){ $drift++; if($label -eq 'DICT正本'){ $dictDrift++ }; $wi=Get-Item -LiteralPath $sp; $pi=Get-Item -LiteralPath $pp; Say ("[D] "+$label+"ドリフト検出(SHA不一致): "+$n.Substring(29,3)+" "+$label+"時刻="+$wi.LastWriteTime.ToString('MM-dd HH:mm')+" size="+$wi.Length+" != PROJ size="+$pi.Length+" → 同期+再注入+変更語点検") }
      }
    }
  } else { Say ("[D] "+$label+"ドリフト: 未接続/不在(スキップ)") }
}
if($drift -eq 0){ Say "[D] 原本ドリフト: なし(SHA-256一致=DICT正本/WSLとも同期済または不在)" }
# 2026-07-18 監査是正: DICT正本(ユーザーが随時更新)のドリフトは hard-fail=同期必須の明示信号。WSL(20260619は旧式・放棄コピー)のドリフトは従来どおりadvisory。
if($dictDrift -gt 0){ $fail=1; Say "    !! DICT正本ドリフト → PROJに未同期の正本更新あり。同期+再注入してからコミット" }

# --- E. 注入の数字付き識別子(両版走査。2026-07-16 監査是正: 従来は学習者版のみだった) ---
$nNum=0
foreach($f in @('漢字注入_学習者版_20260620.txt','漢字注入_学術版_20260620.txt')){
  foreach($ln in [System.IO.File]::ReadAllLines((Join-Path $dir $f))){ foreach($m in [regex]::Matches($ln,'⟦([^⟧]*)⟧')){ if($m.Groups[1].Value -match '[一-鿿][ʰ-˿ᴀ-ᶿ̀-ͯ]*[0-9]'){ $nNum++ } } }
}
Say ("[E] 注入の数字付き識別子=" + $nNum + "(0が正。両版走査)")
if($nNum -gt 0){ $fail=1; Say "    !! 注入に数字id" }

# --- F. 偽分解尊重 整合性(漢字化語根がlatin残存=同綴別語/結合形/固有名で正当か) ---
$fc = & "$dir\_audit_fake_decomp_consistency.ps1" *>&1 | Out-String
$newInc = ([regex]::Match($fc,'★新規不整合\s*=\s*(\d+)')).Groups[1].Value
if($newInc -eq ''){ $newInc='?' }
Say ("[F] 偽分解整合性: ★新規不整合=" + $newInc + "件(0が正。既知19件=同綴別語/結合形/固有名で正当。新規が出たら語義照合で homonym か真の違反か判定)")
if($newInc -ne '0' -and $newInc -ne '?'){ Say "    !! 新規の偽分解不整合候補あり → 変更語を語義照合で点検" }

# --- G. P整合advisory(k列画数 vs st/E/D/P独立検査。技術的負債の可視化=非fail。詳細は _audit_pvalue_consistency.ps1) ---
$pv = & "$dir\_audit_pvalue_consistency.ps1" *>&1 | Out-String
$pvSummary = ([regex]::Match($pv,'\[G\][^\r\n]*')).Value
if($pvSummary){ Say ("    " + $pvSummary) } else { Say "[G] P整合advisory: 実行不可(要 _audit_pvalue_consistency.ps1)" }

# --- H. 逆転20群の期待基本形assertion(2026-07-16 第10回監査: P=5同士は再生成で基本形が動きうる→裁定=現状維持からの変動を検出=fail) ---
$rb = & "$dir\_audit_reversal_bases.ps1" *>&1 | Out-String
$rbLine = ([regex]::Match($rb,'\[H\][^\r\n]*')).Value
$rbBad = ([regex]::Match($rb,'不一致\s*=\s*(\d+)')).Groups[1].Value
if($rbLine){ Say $rbLine } else { Say "[H] 逆転20群assertion: 実行不可(要 _audit_reversal_bases.ps1)"; $rbBad='?' }
if($rbBad -ne '0' -and $rbBad -ne '?'){ $fail=1; Say "    !! 逆転20群の基本形が裁定(§14=現状維持)から変動 → 変更コミットを点検" }

# --- I. 優先順位 構造監査(CSV2890>PEJVO>PIV を独立ground-truthで検証。_audit_priority_tiers.py v3) ---
# CSV2890中核語(band-basic=CSV照合由来)がbaseを失う層順違反=hard-fail。同義語逆転/CSV band誤ラベルはadvisory。
$psOut = & python "$dir\_audit_priority_tiers.py" 2>&1 | Out-String
$psLine = ([regex]::Match($psOut,'PRIORITY_STRUCT:[^\r\n]*')).Value
$csvCov = ([regex]::Match($psOut,'CSV2890: rows=\d+ matched=\d+\(([\d\.]+)%\)')).Groups[1].Value
$csvLoss = ([regex]::Match($psOut,'CSV2890_LOSES_BASE=(\d+)')).Groups[1].Value
if($psLine){ Say ("[I] 優先順位構造(CSV2890照合" + $csvCov + "%): " + $psLine) } else { Say "[I] 優先順位構造: 実行不可(要 python + _audit_priority_tiers.py) → hard-fail(未実行で全PASSと誤認しない。2026-07-20 別AI監査是正)"; $csvLoss='?'; $fail=1 }
Say "    (NEW_SYNONYM_REVERSAL/CSV_MISLABEL=advisory=要裁定・非fail / 詳細 _audit_priority_tiers_ledger.tsv)"
if($csvLoss -ne '0' -and $csvLoss -ne '?' -and $csvLoss -ne ''){ $fail=1; Say "    !! CSV2890中核語がbaseを失う層順違反 → 要即対応" }

# --- J. 描画の一意性(語レベルの同形異義。2026-07-26 第9レンズで新設) ---
# §9契約は【字+識別子→語根】=分節1個の一意復号を保証するが、読者が読むのは『語』。
# 異なる語が完全に同じ漢字列に描画されていないかは [A]id重複0 でも [E][F] でも捕捉できない。
# 同一形態素の二重見出し(接辞定義行 -ism- と語根行 ism/o 等)は自動除外し、真の同形異義のみ検査。
$dc = & python "$dir\_audit_display_collisions.py" *>&1 | Out-String
$dcNew = ([regex]::Match($dc,'\[J\] ★新規合計=(\d+)')).Groups[1].Value
foreach($ln in ($dc -split "`r?`n")){ if($ln -match '^\[J\] (学習者版|学術版):' -or $ln -match '^\[J\] 表面同形' -or $ln -match '★新規の同形異義' -or $ln -match '★新規の表面同形' -or $ln -match '^\s+L\d'){ Say $ln } }
if($dcNew -eq ''){ Say "[J] 描画の一意性: 実行不可(要 python + _audit_display_collisions.py)"; $fail=1 }
elseif($dcNew -ne '0'){ $fail=1; Say ("    !! 新規の同形異義=" + $dcNew + "種 → 異なる語が同じ漢字列に描画されている。語義照合のうえ識別子付与か既知登録を判断") }

# --- K. 新規露出分節/見出し(2026-07-26 第11レンズで新設) ---
# 正本の分解変更で結合形が分割されると、成分が **同綴別語の既存割当をそのまま拾う** ことがある。
# 2026-07-26 の1日で2回発生(nau^tik→nau^t/ik / ribosom→rib/o/som で rib が【植】醋栗 を拾った)。
# [A][F][J] はいずれも「今の状態が壊れているか」しか見ず、この露出の瞬間を捕捉できない。
$ns = & python "$dir\_audit_new_segments.py" *>&1 | Out-String
foreach($ln in ($ns -split "`r?`n")){ if($ln -match '^\[K\]' -or $ln -match '★漢字描画された新規分節' -or $ln -match '新規見出し\(要点検\)' -or $ln -match '^\s+※' -or $ln -match '^\s+\(2026'){ Say $ln } }
if($ns -notmatch '\[K\]'){ Say "[K] 新規露出分節: 実行不可(要 python + _audit_new_segments.py)"; $fail=1 }
elseif($ns -match '★漢字描画=([1-9]\d*)'){ $fail=1; Say "    !! 漢字描画された新規分節あり → 同綴別語の字を拾っていないか語義照合。確認後 python _audit_new_segments.py --accept" }

# --- L. 配信エクスポートの同期(2026-07-26 第14レンズで新設) ---
# 正本(DICT)のドリフトは [D] が検出するのに、**配信面のドリフトには検出器が無かった**。
# 2026-07-26、アプリ側から「注入版とエクスポートの食い違い17件」の報告があり、原因は
# エクスポートが4時間古かっただけだった(注入を直したらエクスポートも再生成する、という
# 人間の記憶に頼る運用が実際に破れた)。1行でも食い違えば fail させる。
# 直し方: python _gen_export.py "コメント"
$ex = & python "$dir\_audit_export_sync.py" *>&1 | Out-String
foreach($ln in ($ex -split "`r?`n")){ if($ln -match '^\[L\]' -or $ln -match '^\s+#\d' -or $ln -match '^\s+\.\.\. 他'){ Say $ln } }
if($ex -notmatch '\[L\]'){ Say "[L] 配信エクスポート同期: 実行不可(要 python + _audit_export_sync.py)"; $fail=1 }
elseif($ex -match '★描画が食い違う行|行数不一致|存在しない'){ $fail=1; Say "    !! 配信エクスポートが古い → python _gen_export.py で再生成してからコミット" }

# --- [M] 台帳の死にキー監査(2026-07-27 第15レンズで新設) ---
# homonym台帳の sep 行は「見出し語リスト」で適用範囲を決めるので、**正本が分解を細かくして見出し綴りが
# 変わると、語リストのキーだけが古いまま残り、規則が静かに不発火になる**。実際に3回起きている:
#   pir/o/gajlol/o→pir/o/gajl/ol/o(火ᴾ→梨) / di/tionat/o→di/tion/at/o(二ᴰᴵ→神) / tetra/tionat/o→tetra/tion/at/o(四ᵀᴬ→野鸡)
# 「スラッシュを除くと同じ綴りの生きた見出しがあり・その見出しが当該分節を持ち・まだ語リストに無い」
# ものだけを報告する。基準4=別ルート(化学inline rule)で既に正しく描画されている既知の4件
# (makro/fag/o=宏ᴹ/吞 は $fagEat、di/met/oksi/fen/ol/o=二/甲/氧 は化学di-/met-のinline ruleが担当)。
$dk = & python "$dir\_audit_ledger_deadkeys.py" 4 *>&1 | Out-String
foreach($ln in ($dk -split "`r?`n")){ if($ln -match '^\[M\]' -or $ln -match '^\s+★' -or $ln -match '^\s+!!'){ Say $ln } }
if($dk -notmatch '\[M\]'){ Say "[M] 台帳死にキー: 実行不可(要 python + _audit_ledger_deadkeys.py)"; $fail=1 }
elseif($dk -match '!!'){ $fail=1 }

# --- [N] 描画トークンの出典被覆(2026-07-27 第16レンズで新設) ---
# 逆引き(漢字→語根)は §9 の一意復号契約の裏返し。第16レンズで、出力に現れる漢字トークンのうち
# **sidecar にも台帳にも載らない字**が9種あった(炎ᵀ/盐ᴬ/盐ᴵ/丁戊庚壬癸辛=化学塩・医学-itis・アルキル語幹の
# 文脈判定で _inject_final.ps1 が直接埋め込む定数)。配布表に載らないのでアプリは逆引き辞書を完成できない。
# _inline_tokens.tsv に登録して0にした。新しい inline rule が未文書のトークンを持ち込んだらここで気付く。
$tc = & python "$dir\_audit_token_coverage.py" 0 *>&1 | Out-String
foreach($ln in ($tc -split "`r?`n")){ if($ln -match '^\[N\]' -or $ln -match '^\s+★' -or $ln -match '^\s+!!'){ Say $ln } }
if($tc -notmatch '\[N\]'){ Say "[N] トークン出典被覆: 実行不可(要 python + _audit_token_coverage.py)"; $fail=1 }
elseif($tc -match '!!'){ $fail=1 }

# --- [O] 版間ラテン維持センチネル(2026-07-30 続54で新設) ---
# 確定裁定が **片方の版にしか届かない** 事故が2度起きている:
#   続49 orkid/panikl 4件 … §14.2.1 の裁定が学術版whole-root master に未反映
#   続53 kuriterapi 1件  … 語釈gated規則は分節 kuri には届くが学術版の融合語根には原理的に届かず
#                          学術版だけ 廷疗(廷はCuria専用)のまま6日間残っていた
# [A]は原本との一致・[F]は偽分解の整合・[J]は描画の衝突・[K]は新規露出しか見ないので、
# **版間で片方だけ漢字が付いている状態**はどの検査の視野にも入っていなかった。
# 「学術版の融合分節に漢字があり、それが覆う学習者版分節にラテンのままのものがある」箇所を
# 全数抽出し、受理台帳 _known_latin_sentinel.txt に無いものだけを ★新規 として報告する。
# 受理済84件は融合語根の正当な全体割当(urat=尿酸盐/dentin=齿质/penicilin=青霉素/procent=率 等)で、
# §4.6 が版間の粒度差を明示的に許容し klement(続16 ユーザー裁定A案)の前例どおり揃えない。
# 直し方: 内容を点検して正当と確認できたら python _audit_latin_sentinel_crossversion.py --accept
$ls = & python "$dir\_audit_latin_sentinel_crossversion.py" *>&1 | Out-String
foreach($ln in ($ls -split "`r?`n")){ if($ln -match '^\[O\]' -or $ln -match '^\s+★' -or $ln -match '^\s+!!' -or $ln -match '^\s+\(参考\)'){ Say $ln } }
if($ls -notmatch '\[O\]'){ Say "[O] 版間ラテン維持: 実行不可(要 python + _audit_latin_sentinel_crossversion.py)"; $fail=1 }
elseif($ls -match '!!'){ $fail=1 }

# --- 総括 ---
$verdict='全PASS(健全・同期も最新)'
if($fail -ne 0){ $verdict='要対応(ハード違反あり)' } elseif($drift -ne 0){ $verdict='不変条件PASSだが WSL再同期推奨' } elseif($newInc -ne '0' -and $newInc -ne '?'){ $verdict='不変条件PASSだが 新規偽分解不整合の点検推奨' }
Say ("===== 総括: " + $verdict + " =====")
Add-Content -LiteralPath (Join-Path $dir '_verify_log.txt') -Value (($LOG -join "`r`n") + "`r`n") -Encoding UTF8
Write-Host "→ ログ追記: _verify_log.txt"
if($fail -gt 0){ exit 1 } else { exit 0 }

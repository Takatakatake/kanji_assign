# 漢字割り当ての成果を日付スナップショットとして退避(いつでも再実行可)。
#   ① git bundle --all = 全履歴+全コミット済ファイルを1ファイルに完全保存(どこでも git clone で復元可)
#   ② 主要成果ファイルの平文コピー(git無しでも閲覧・利用可)
# 退避先 = 親フォルダ(マイドライブ=Google Drive配下なのでクラウドにも同期される)の _漢字割り当て_スナップショット\<日時>_<commit>
param([switch]$Force)   # -Force でHEAD未変化でも強制スナップショット(既定=未変化ならスキップ)
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$parent=Split-Path $dir -Parent
$keep=14   # 直近この数だけ保持(古い分は自動削除)。Google Driveクラウド+GitHubにも同期されるため局所はローテーション
$snapRoot=Join-Path $parent '_漢字割り当て_スナップショット'
$stamp=(Get-Date -Format 'yyyyMMdd_HHmm')
Push-Location $dir
$hash=(& git rev-parse --short HEAD).Trim()
$branch=(& git rev-parse --abbrev-ref HEAD).Trim()
# 未変化スキップ: 現HEADのスナップショットが既にあれば作らない(定期実行で同一bundleを量産しない)
if(-not $Force -and (Test-Path $snapRoot) -and (Get-ChildItem -LiteralPath $snapRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like ('*_'+$hash) })){
  Pop-Location
  Write-Host ("スキップ: HEAD("+$hash+")のスナップショットは既に存在(変更なし)。-Force で強制作成可。")
  exit 0
}
$dest=Join-Path $snapRoot ($stamp + "_" + $hash)
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# ① 完全バックアップ = git bundle(全履歴)
# 注: PS5.1はnative gitのstderr(進捗/verifyの'is okay')を擬似エラー化するため、git区間だけ Continue にする
$bundle=Join-Path $dest ("kanji_assign_" + $stamp + "_" + $hash + ".bundle")
$ErrorActionPreference='Continue'
& git bundle create $bundle --all 2>&1 | Out-Null
& git bundle verify $bundle 2>&1 | Out-Null
$verify=if($LASTEXITCODE -eq 0){'OK (bundle verified)'}else{'WARNING: verify exit '+$LASTEXITCODE}
$ErrorActionPreference='Stop'

# ② 主要成果ファイルの平文コピー(git無しでも使える)
$files=@(
  '漢字注入_学習者版_20260620.txt','漢字注入_学術版_20260620.txt',
  '_kanji_map_master.tsv','_p_work.csv','_identifier_sidecar.tsv','_homonym.tsv','_homonym_disp.tsv',
  '漢字化方針_v2_20260613.md','エスペラント語根_識別子付与アルゴリズム_仕様書.md',
  '_inject_final.ps1','_build_homonym.ps1','_gas_identifier.ps1','_make_sidecar.ps1','_homonym_disp.ps1',
  '通用规范汉字表_一级3500字.txt'
)
$copyDir=Join-Path $dest '主要成果ファイル'
New-Item -ItemType Directory -Path $copyDir -Force | Out-Null
$nCopied=0
foreach($f in $files){ $src=Join-Path $dir $f; if(Test-Path -LiteralPath $src){ Copy-Item -LiteralPath $src -Destination (Join-Path $copyDir $f) -Force; $nCopied++ } }
# 親フォルダにある修正記録(git管理外)も拾う
Get-ChildItem -LiteralPath $parent -Filter 'エスペラント語根漢字_修正記録_*.md' -ErrorAction SilentlyContinue | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $copyDir $_.Name) -Force; $nCopied++ }

# README(復元手順)
$readme=Join-Path $dest '_README_復元方法.txt'
$lines=@(
  "エスペラント語根→漢字割り当て スナップショット",
  ("作成: " + $stamp + " / commit " + $hash + " (branch " + $branch + ")"),
  ("bundle検証: " + $verify),
  "",
  "【完全復元(全履歴付き)】",
  ("  git clone " + (Split-Path $bundle -Leaf) + " 復元先フォルダ"),
  "  → コミット履歴ごと完全に復元されます。",
  "",
  "【中身だけ見たい】",
  "  主要成果ファイル\\ 以下に注入結果・方針書・スクリプト・修正記録の平文コピーがあります。",
  "",
  "【大本のバックアップ】",
  "  ・GitHub: git@github.com:Takatakatake/kanji_assign.git (origin/main)",
  "  ・Google Drive: 本フォルダはマイドライブ配下なのでクラウドにも自動同期されます。"
)
[System.IO.File]::WriteAllLines($readme,$lines,(New-Object System.Text.UTF8Encoding($true)))

$bSize=[math]::Round((Get-Item -LiteralPath $bundle).Length/1MB,1)
Pop-Location
# 世代管理: 直近 $keep だけ残し古いスナップショットを自動削除(名前=日時_hash で時系列ソート可)
$old=@(Get-ChildItem -LiteralPath $snapRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -Skip $keep)
$nDel=0; foreach($o in $old){ Remove-Item -LiteralPath $o.FullName -Recurse -Force -ErrorAction SilentlyContinue; $nDel++ }
Write-Host ("スナップショット作成完了: " + $dest)
Write-Host ("  ① git bundle (全履歴) " + $bSize + " MB / 検証: " + $verify)
Write-Host ("  ② 主要成果ファイル平文コピー " + $nCopied + " 件")
Write-Host ("  大本: GitHub origin/main(" + $hash + ") + Google Drive同期")
if($nDel -gt 0){ Write-Host ("  世代管理: 古いスナップショット " + $nDel + " 件を削除(直近" + $keep + "件保持)") }
exit 0

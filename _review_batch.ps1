# バッチ完了結果を点検(読み取り専用) + roots を保存 + 一级照合
# 使い方: powershell -File _review_batch.ps1 -OutPath <task .output> -Num 8
param(
  [Parameter(Mandatory=$true)][string]$OutPath,
  [Parameter(Mandatory=$true)][int]$Num
)
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
$j = (Get-Content -Raw -Encoding UTF8 $OutPath | ConvertFrom-Json).result
$j.roots | ConvertTo-Json -Depth 5 -Compress | Out-File "$dir\_wf_b$Num`_result.json" -Encoding UTF8
Write-Host "b$Num : roots $($j.roots.Count) / revise $($j.revised.Count) / batchColl $($j.batchCollisions.Count) / usedColl $($j.usedCollisions.Count)"

Write-Host "`n=== revise (root: from -> to | problem | 理由抜粋) ==="
$j.revised | ForEach-Object {
  $rs = ($_.reason -replace '\s+',' '); $rs = $rs.Substring(0,[Math]::Min(50,$rs.Length))
  "{0,-11} {1} -> {2}  [{3}] {4}" -f $_.root, $_.from, $_.to, $_.problem, $rs
}
Write-Host "`n=== 未対応 ==="
($j.roots | Where-Object { $_.final -eq '未対応' } | ForEach-Object { $_.root }) -join ', '

# confidence=low / medium も一覧化(点検補助)
Write-Host "`n=== confidence=low (要確認) ==="
($j.roots | Where-Object { $_.confidence -eq 'low' } | ForEach-Object { "$($_.root)=$($_.final)" }) -join ', '

# 一级照合
$yi = @{}
Get-Content "$dir\通用规范汉字表_一级3500字.txt" -Encoding UTF8 | ForEach-Object { $c=$_.Trim(); if($c.Length -ge 1){ $yi[$c[0]]=$true } }
$ng = $j.roots | Where-Object { $_.final -ne '未対応' -and $_.final.Length -eq 1 -and -not $yi.ContainsKey([char]$_.final) } | ForEach-Object { "$($_.root)=$($_.final)" }
Write-Host "`n=== 一级外(要検討) ==="
if($ng){ $ng -join ', ' } else { "なし(全て一级内)" }

# 多字final(2字以上=透明性目的なら可・3字超や不要な冗長のみ要確認)
$multi = $j.roots | Where-Object { $_.final -ne '未対応' -and $_.final.Length -ge 2 } | ForEach-Object { "$($_.root)=$($_.final)" }
Write-Host "`n=== 多字final(透明性目的なら可、長すぎるもののみ要確認) ==="
if($multi){ $multi -join ', ' } else { "なし" }

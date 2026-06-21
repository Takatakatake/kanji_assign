# バッチ結果(ワークフロー戻り値JSON)を master へ取り込む
# 使い方: powershell -File _ingest_batch.ps1 -ResultPath _wf_b7_result.json
param(
  [Parameter(Mandatory=$true)][string]$ResultPath,
  [string]$Type = 'content'
)
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
$masterPath = "$dir\_kanji_map_master.tsv"

$raw = Get-Content -Raw -Encoding UTF8 $ResultPath | ConvertFrom-Json
# .roots があればそれ、無ければ配列そのもの
if($raw.PSObject.Properties.Name -contains 'roots'){ $items = $raw.roots } else { $items = $raw }

# master 既存キー
$master = @{}
Get-Content $masterPath -Encoding UTF8 | ForEach-Object { $p=$_ -split "`t"; if($p.Count -ge 2){ $master[$p[1].Trim()] = $true } }

# 一级集合(二级検出用)
$yi = @{}
$yiPath = "$dir\通用规范汉字表_一级3500字.txt"
if(Test-Path $yiPath){ Get-Content $yiPath -Encoding UTF8 | ForEach-Object { $c=$_.Trim(); if($c){ $yi[$c[0]]=$true } } }
$nivelo2 = New-Object System.Collections.ArrayList
$multichar = New-Object System.Collections.ArrayList

$add = New-Object System.Collections.ArrayList
$untargeted = New-Object System.Collections.ArrayList  # 未対応/音訳
$dup = New-Object System.Collections.ArrayList
foreach($it in $items){
  $root = ([string]$it.root).Trim()
  $final = ([string]$it.final).Trim()
  if([string]::IsNullOrWhiteSpace($root)){ continue }
  if($master.ContainsKey($root)){ $null=$dup.Add($root); continue }
  if([string]::IsNullOrWhiteSpace($final) -or $final -eq '未対応'){
    $null=$untargeted.Add("$root=$final"); continue
  }
  $master[$root] = $true
  $null=$add.Add("$Type`t$root`t$final")
  # 二级検出(構成字のいずれかが一級外なら記録)
  $hasN2 = $false
  foreach($ch in $final.ToCharArray()){ if($yi.Count -gt 0 -and -not $yi.ContainsKey($ch)){ $hasN2 = $true } }
  if($hasN2){ $null=$nivelo2.Add("$Type`t$root`t$final") }
  # 多字(2字以上)記録
  if($final.Length -ge 2){ $null=$multichar.Add("$Type`t$root`t$final") }
}
if($nivelo2.Count -gt 0){ Add-Content -Path "$dir\_nivelo2.tsv" -Value $nivelo2 -Encoding UTF8 }
if($multichar.Count -gt 0){ Add-Content -Path "$dir\_multichar.tsv" -Value $multichar -Encoding UTF8 }
if($add.Count -gt 0){ Add-Content -Path $masterPath -Value $add -Encoding UTF8 }
# 未対応を台帳へ永続化(次バッチで再出題されないように)
if($untargeted.Count -gt 0){ $utRows = $untargeted | ForEach-Object { $rt=($_ -split '=')[0]; "$Type`t$rt`t未対応" }; Add-Content -Path "$dir\_untargeted.tsv" -Value $utRows -Encoding UTF8 }
Write-Host "取り込み: 追加 $($add.Count) / 重複skip $($dup.Count) / 未対応・音訳 $($untargeted.Count) / 二级 $($nivelo2.Count) / 多字 $($multichar.Count)"
if($multichar.Count -gt 0){ Write-Host ("多字: " + (($multichar | ForEach-Object { ($_ -split "`t")[1..2] -join '=' }) -join ', ')) }
if($nivelo2.Count -gt 0){ Write-Host ("二级(一级外): " + (($nivelo2 | ForEach-Object { ($_ -split "`t")[1..2] -join '=' }) -join ', ')) }
if($untargeted.Count -gt 0){ Write-Host ("未対応: " + ($untargeted -join ', ')) }
if($dup.Count -gt 0){ Write-Host ("重複: " + ($dup -join ', ')) }
$total = (Get-Content $masterPath -Encoding UTF8 | Measure-Object -Line).Lines
Write-Host "master 総行: $total"

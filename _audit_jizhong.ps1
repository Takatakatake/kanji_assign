# 字種監査: master の全割当字を 一级(3500・許容)と照合し、一级外字(二级/三级/表外=要是正)を検出
# 【2026-06-16 方針転換】字種は一级のみ。一级で表せなければ未対応(二级廃止)。
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613"
$allowed = @{}
foreach($f in @("通用规范汉字表_一级3500字_画数.tsv")){
  Get-Content "$dir\$f" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
    $p = $_ -split "`t"; if($p.Count -ge 4){ $c=$p[1].Trim(); if($c){ $allowed[$c]=$p[3].Trim() } }
  }
}
$bad = @{}
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object {
  $p = $_ -split "`t"; if($p.Count -lt 3){ return }
  $root=$p[1].Trim(); $kanji=$p[2].Trim()
  if($kanji -eq '未対応' -or -not $kanji){ return }
  foreach($ch in $kanji.ToCharArray()){
    $cs=[string]$ch; if([int][char]$ch -lt 128){ continue }
    if(-not $allowed.ContainsKey($cs)){
      if(-not $bad.ContainsKey($cs)){ $bad[$cs]=New-Object System.Collections.ArrayList }
      $null=$bad[$cs].Add($root)
    }
  }
}
Write-Host ("許容字(一级3500): {0} / master 一级外字(二级/三级/表外): {1} 種" -f $allowed.Count, $bad.Count)
if($bad.Count -gt 0){
  $bad.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object { "  {0}  ({1}件): {2}" -f $_.Key, $_.Value.Count, (($_.Value) -join ',') }
} else { Write-Host "  OK: 全割当が一级のみ(クリーン)" }
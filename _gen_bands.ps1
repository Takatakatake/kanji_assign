# 層バンド(基本語彙/PEJVO/PIV)+ F(見出し数)を機械判定し、サイドカー _band_map.tsv を生成
# master は変更しない(読み取りのみ)。v2 §8/§11 の P 数値化の基礎データ。
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613"
$dict = "$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$csv  = "$dir\30_重要語彙CSV_日中対照_2890語\2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
$master = "$dir\_kanji_map_master.tsv"

function ToHsys([string]$s){
  $s = $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^'
  return $s
}
$endingRe = '^(o|a|e|i|u|oj|aj|on|an|ojn|ajn|en|as|is|os|us|u|j|n)$'

# (1) 基本語彙ルート集合: CSV の Esperanto 列 → 末尾語尾1字除去 → h-system
$basic = @{}
$csvLines = Get-Content $csv -Encoding UTF8 | Select-Object -Skip 1
foreach($ln in $csvLines){
  $w = ($ln -split ',')[0]
  if([string]::IsNullOrWhiteSpace($w)){ continue }
  $w = $w.Trim().ToLower()
  if($w.StartsWith('-') -or $w.EndsWith('-')){ continue }   # 接辞は別タグ
  $r = $w -replace '(o|a|e|i|u)$',''                          # 文法語尾1字除去
  if($r.Length -ge 1){ $basic[(ToHsys $r)] = $true }
}

# (2) 辞書スキャン: 各 content セグメントの F(見出し数) と 非PIV見出しに出現したか
$Fmap = @{}; $seenNonPIV = @{}; $seenAny = @{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci = $line.IndexOf(':'); if($ci -lt 1){ continue }
  $head = $line.Substring(0,$ci); $gloss = $line.Substring($ci+1)
  $isPIV = $gloss.Contains('【PIV】')
  foreach($wd in ($head -split ' ')){
    foreach($s in ($wd -split '/')){
      if($s -match $endingRe){ continue }
      if($s.Length -lt 1){ continue }
      $Fmap[$s] = 1 + ($Fmap[$s]); $seenAny[$s] = $true
      if(-not $isPIV){ $seenNonPIV[$s] = $true }
    }
  }
}

# (3) master 各行を分類してサイドカー出力(master 自体は変更しない)
$struct = @{ 'func'=1;'suf'=1;'correl'=1;'prep'=1;'pref'=1;'sci'=1;'cal'=1;'elem'=1;'num'=1;'proper'=1;'rel'=1 }
$rows = New-Object System.Collections.ArrayList
$cnt = @{}
foreach($l in (Get-Content $master -Encoding UTF8)){
  $p = $l -split "`t"; if($p.Count -lt 3){ continue }
  $type=$p[0].Trim(); $root=$p[1].Trim(); $kanji=$p[2].Trim()
  $rootH = ToHsys $root
  if($struct.ContainsKey($type)){ $band = $type }
  elseif($basic.ContainsKey($rootH)){ $band = 'basic' }
  elseif($seenAny.ContainsKey($rootH) -and -not $seenNonPIV.ContainsKey($rootH)){ $band = 'piv' }
  else { $band = 'pejvo' }
  $fc = if($Fmap.ContainsKey($rootH)){ $Fmap[$rootH] } else { 0 }
  $null = $rows.Add(("{0}`t{1}`t{2}`t{3}`t{4}" -f $type,$root,$kanji,$band,$fc))
  $cnt[$band] = 1 + ($cnt[$band])
}
"type`troot`tkanji`tband`tF" | Out-File "$dir\_band_map.tsv" -Encoding UTF8
$rows | Out-File "$dir\_band_map.tsv" -Encoding UTF8 -Append
Write-Host "=== バンド分布 ==="
$cnt.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { "{0,-10} {1}" -f $_.Name, $_.Value }
Write-Host "基本語彙ルート集合(CSV由来): $($basic.Count)"
Write-Host ""
Write-Host "=== サンプル: basic 上位F ==="
$rows | Where-Object { ($_ -split "`t")[3] -eq 'basic' } | Sort-Object { [int](($_ -split "`t")[4]) } -Descending | Select-Object -First 8 | ForEach-Object { ($_ -split "`t")[1..4] -join '  ' }
Write-Host "=== サンプル: pejvo(長尾) ランダム的 ==="
$rows | Where-Object { ($_ -split "`t")[3] -eq 'pejvo' } | Select-Object -First 8 | ForEach-Object { ($_ -split "`t")[1..4] -join '  ' }
Write-Host "=== サンプル: piv(PIV専) ==="
$rows | Where-Object { ($_ -split "`t")[3] -eq 'piv' } | Select-Object -First 8 | ForEach-Object { ($_ -split "`t")[1..4] -join '  ' }
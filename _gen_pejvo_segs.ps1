# 辞書の未マップ content セグメントを頻度順に抽出し、代表見出し+語義を付す
# 出力: _pejvo_unmapped.json (頻度降順) / コンソールに上位N
param([int]$Top = 80)
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
$dict = "$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"

function ToHsys([string]$s){
  $s = $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^'
  return $s
}
# master 既知キー(値が漢字でも未対応でも = 全て既知扱いで再抽出しない。h-systemキーに変換)
$map = @{}
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object {
  $p = $_ -split "`t"
  if($p.Count -ge 2){ $k=$p[1].Trim(); if($k){ $map[(ToHsys $k)] = $true } }
}
# 未対応台帳も既知扱い(再抽出しない。h-systemキーに変換)
$unt = @{}
if(Test-Path "$dir\_untargeted.tsv"){ Get-Content "$dir\_untargeted.tsv" -Encoding UTF8 | ForEach-Object { $pp=$_ -split "`t"; if($pp.Count -ge 2){ $unt[(ToHsys $pp[1].Trim())]=$true } } }

$endingRe = '^(o|a|e|i|u|oj|aj|on|an|ojn|ajn|en|as|is|os|us|u|j|n)$'
$lines = Get-Content $dict -Encoding UTF8

$count = @{}        # seg -> 出現数
$repHead = @{}       # seg -> 代表見出し(seg が単独語根の見出し優先)
$repGloss = @{}      # seg -> 語義
$repScore = @{}      # seg -> 代表性スコア(小さいほど良い: seg=唯一語根 を最優先)

foreach($line in $lines){
  $ci = $line.IndexOf(':')
  if($ci -lt 1){ continue }
  $head = $line.Substring(0,$ci)
  $gloss = $line.Substring($ci+1)
  $gloss = $gloss -replace '^\{[^}]*\}',''            # {Ｂ} タグ除去
  foreach($w in ($head -split ' ')){
    $segs = @($w -split '/')
    # content セグメント(語尾除く)
    $contentSegs = @($segs | Where-Object { $_ -notmatch $endingRe })
    for($i=0;$i -lt $segs.Count;$i++){
      $s = $segs[$i]
      if($s -match $endingRe){ continue }
      if($map.ContainsKey($s)){ continue }
      if($unt.ContainsKey($s)){ continue }
      if($s.Length -lt 1){ continue }
      $count[$s] = 1 + ($count[$s])
      # 代表性: この見出しの content セグメント数が少ないほど(=seg が主役)良い。1なら最良。
      $sc = $contentSegs.Count
      if(-not $repScore.ContainsKey($s) -or $sc -lt $repScore[$s]){
        $repScore[$s] = $sc; $repHead[$s] = $w
        $g = $gloss.Trim(); if($g.Length -gt 60){ $g = $g.Substring(0,60) }
        $repGloss[$s] = $g
      }
    }
  }
}

$arr = foreach($k in $count.Keys){
  [pscustomobject]@{ seg=$k; n=$count[$k]; head=$repHead[$k]; gloss=$repGloss[$k] }
}
$sorted = @($arr | Sort-Object n -Descending)
$sorted | ConvertTo-Json -Depth 4 -Compress | Out-File "$dir\_pejvo_unmapped.json" -Encoding UTF8
Write-Host "未マップ content セグメント ユニーク: $($sorted.Count)"
Write-Host "=== 上位 $Top (seg / 出現数 / 代表見出し / 語義) ==="
$sorted | Select-Object -First $Top | ForEach-Object { "{0,-12} {1,4}  {2,-20} {3}" -f $_.seg, $_.n, $_.head, $_.gloss }

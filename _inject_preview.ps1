# 形態素合成の注入プレビュー生成(基底字のみ・識別子なし)
# master の root→漢字 を辞書のスラッシュ分解に合成注入し、原本diff=0 と被覆率を検証する。
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613"
$dict = "$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$preview = "$dir\世界语…学習者版_kanji_preview_20260614.txt"

# Unicode→h-system 変換(辞書のキーに合わせる)
function ToHsys([string]$s){
  $s = $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^'
  return $s
}
# master → map(h-systemキー→漢字)。未対応/空は除外
$map = @{}
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object {
  $p = $_ -split "`t"
  if($p.Count -ge 3){
    $k = $p[1].Trim(); $v = $p[2].Trim()
    if($v -and $v -ne '未対応'){ $map[(ToHsys $k)] = $v }
  }
}
Write-Host "map エントリ: $($map.Count)"

# 文法語尾(ラテン保持・被覆対象外)。on/an/en は接尾辞(分/员)・前置詞(内)と衝突するため除外し、位置で裁定。
$endingRe = '^(o|a|e|i|u|oj|aj|ojn|ajn|as|is|os|us|u|j|n)$'

$lines = Get-Content $dict -Encoding UTF8
$outLines = New-Object System.Collections.Generic.List[string]
$totLines=0; $injLines=0; $fullCov=0
$segTotal=0; $segMapped=0
$unmapped = @{}   # 未マップ content セグメント → 出現数

foreach($line in $lines){
  $totLines++
  $ci = $line.IndexOf(':')
  if($ci -lt 1){ $outLines.Add($line); continue }
  $head = $line.Substring(0,$ci)
  $rest = $line.Substring($ci)   # ":" 以降
  # 見出しを語(space)→セグメント(/)で処理
  $words = $head -split ' '
  $anyMapped = $false; $lineSegContent=0; $lineSegMapped=0
  $kwords = foreach($w in $words){
    $segs = @($w -split '/')
    $nseg = $segs.Count
    # 先頭に後続 content(非語尾)があるか(privative a-/an- 判定用)
    $laterContent = $false
    for($j=1;$j -lt $nseg;$j++){ if($segs[$j] -notmatch $endingRe){ $laterContent=$true; break } }
    $parts = New-Object System.Collections.Generic.List[string]
    $mergeNext = $false; $prevMapped = $false
    for($idx=0; $idx -lt $nseg; $idx++){
      $s = $segs[$idx]
      # 連結母音 o: 漢字複合の間(前後とも漢字)→ 省略しマージ(水o生→水生)
      if($s -eq 'o' -and $idx -gt 0 -and ($idx+1 -lt $nseg) -and $prevMapped -and $map.ContainsKey($segs[$idx+1])){
        $mergeNext = $true; continue
      }
      $tok = $null; $thisMapped = $false
      if($idx -eq 0 -and ($s -eq 'a' -or $s -eq 'an') -and $laterContent){
        $tok='无'; $thisMapped=$true; $anyMapped=$true; $lineSegContent++; $lineSegMapped++   # privative a-/an-=无
      }
      elseif($s -eq 'en'){
        if($idx -eq 0){ $tok='内'; $thisMapped=$true; $anyMapped=$true; $lineSegContent++; $lineSegMapped++ } # 前置詞/接頭 en=内
        else { $tok=$s }                                                                                     # 方向 -en は語尾
      }
      elseif($s -match $endingRe){ $tok=$s }                  # 文法語尾→ラテン
      elseif($map.ContainsKey($s)){ $tok=$map[$s]; $thisMapped=$true; $anyMapped=$true; $lineSegContent++; $lineSegMapped++ }
      else { $tok=$s; $lineSegContent++; if($s.Length -ge 1){ $unmapped[$s] = 1 + ($unmapped[$s]) } }  # 未マップ→ラテン
      if($mergeNext -and $parts.Count -gt 0){ $parts[$parts.Count-1] = $parts[$parts.Count-1] + $tok; $mergeNext=$false }
      else { $parts.Add($tok) }
      $prevMapped = $thisMapped
    }
    ($parts -join '/')
  }
  $segTotal += $lineSegContent; $segMapped += $lineSegMapped
  if($anyMapped){
    $injLines++
    if($lineSegMapped -eq $lineSegContent -and $lineSegContent -gt 0){ $fullCov++ }
    $kanjiHead = ($kwords -join ' ')
    $outLines.Add("$head⟦$kanjiHead⟧$rest")
  } else {
    $outLines.Add($line)
  }
}
[System.IO.File]::WriteAllLines($preview, $outLines, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "総行 $totLines / 注入行 $injLines / 全セグ被覆行 $fullCov"
Write-Host ("content セグ被覆: {0}/{1} = {2:P1}" -f $segMapped, $segTotal, ($segMapped/[double]$segTotal))

# 原本diff検証: ⟦…⟧ を除去して原本と一致するか
$stripped = $outLines | ForEach-Object { $_ -replace '⟦[^⟧]*⟧','' }
$diff = 0
for($i=0;$i -lt $lines.Count;$i++){ if($stripped[$i] -ne $lines[$i]){ $diff++ } }
Write-Host "原本diff: $diff $(if($diff -eq 0){'(原本不可侵 PASS)'}else{'(要調査!)'})"

# 未マップ content セグメント 上位(次フェーズ=PEJVO/PIVの主対象)
$topUnmapped = $unmapped.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 30
Write-Host "=== 未マップ content セグメント 上位30(出現数) ==="
$topUnmapped | ForEach-Object { "{0,-14} {1}" -f $_.Key, $_.Value }
# 未マップ語根の総ユニーク数
Write-Host "未マップ content セグメント ユニーク数: $($unmapped.Count)"

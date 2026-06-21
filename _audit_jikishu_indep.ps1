$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$dir = (Get-Location).Path
$lvl1 = [System.Collections.Generic.HashSet[string]]::new()
foreach ($ch in (Get-Content -LiteralPath (Join-Path $dir '通用规范汉字表_一级3500字.txt') -Encoding UTF8)) { $t = $ch.Trim(); if ($t.Length -ge 1) { [void]$lvl1.Add($t) } }
$lvl2 = [System.Collections.Generic.HashSet[string]]::new()
foreach ($ch in (Get-Content -LiteralPath (Join-Path $dir '通用规范汉字表_二级3000字.txt') -Encoding UTF8)) { $t = $ch.Trim(); if ($t.Length -ge 1) { [void]$lvl2.Add($t) } }
Write-Host ("Loaded lvl1=" + $lvl1.Count + " lvl2=" + $lvl2.Count)
$open = [char]0x27E6; $close = [char]0x27E7
$rx = [regex]::new("$open([^$open$close]*)$close")
function Test-File($path) {
  $lineNo = 0; $results = @{}
  foreach ($line in (Get-Content -LiteralPath $path -Encoding UTF8)) {
    $lineNo++
    foreach ($m in $rx.Matches($line)) {
      $inner = $m.Groups[1].Value; $si = 0
      while ($si -lt $inner.Length) {
        $cp = [System.Char]::ConvertToUtf32($inner, $si)
        $isSur = [System.Char]::IsHighSurrogate($inner[$si])
        if ($isSur) { $charStr = $inner.Substring($si,2); $si += 2 } else { $charStr = $inner.Substring($si,1); $si += 1 }
        $isCJK = ($cp -ge 0x4E00 -and $cp -le 0x9FFF) -or ($cp -ge 0x3400 -and $cp -le 0x4DBF) -or ($cp -ge 0x20000 -and $cp -le 0x2FFFF) -or ($cp -ge 0xF900 -and $cp -le 0xFAFF)
        if ($isCJK) {
          if (-not $results.ContainsKey($charStr)) {
            $results[$charStr] = [pscustomobject]@{ Char=$charStr; CP=([string]::Format("U+{0:X4}",$cp)); InLvl1=$lvl1.Contains($charStr); InLvl2=$lvl2.Contains($charStr); Count=0; FirstLine=$lineNo; FirstText=$line }
          }
          $results[$charStr].Count++
        }
      }
    }
  }
  return $results
}
foreach ($f in @('漢字注入_学習者版_20260620.txt','漢字注入_学術版_20260620.txt')) {
  $path = Join-Path $dir $f
  Write-Host ("`n========== " + $f + " ==========")
  $r = Test-File $path
  $offending = @($r.Values | Where-Object { -not $_.InLvl1 })
  Write-Host ("Distinct CJK chars in brackets: " + $r.Count)
  Write-Host ("Chars NOT in 一级: " + $offending.Count)
  foreach ($o in ($offending | Sort-Object { -$_.Count })) {
    $tag = if ($o.InLvl2) { "二级" } else { "范表外" }
    Write-Host ("  VIOLATION [" + $tag + "] char=" + $o.Char + " " + $o.CP + " count=" + $o.Count + " firstLine=" + $o.FirstLine)
    Write-Host ("    line: " + $o.FirstText)
  }
}
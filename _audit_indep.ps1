$ErrorActionPreference='Stop'
$base = 'd:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$csvDir = Join-Path $base '30_重要語彙CSV_日中対照_2890語'
$csv = (Get-ChildItem -LiteralPath $csvDir -Filter '2890 Gravaj*.csv' | Where-Object { $_.Name -notmatch 'Korea' } | Select-Object -First 1).FullName
Write-Host "CSV path: $csv"
$out  = Join-Path $base '漢字注入_学習者版_20260620.txt'

# h-system conversion: Unicode EO letters -> h-system (use code points to avoid encoding issues)
$cx=[char]0x0109; $Cx=[char]0x0108  # c-circ
$gx=[char]0x011D; $Gx=[char]0x011C  # g-circ
$hx=[char]0x0125; $Hx=[char]0x0124  # h-circ
$jx=[char]0x0135; $Jx=[char]0x0134  # j-circ
$sx=[char]0x015D; $Sx=[char]0x015C  # s-circ
$ux=[char]0x016D; $Ux=[char]0x016C  # u-breve
function ToH([string]$s){
  $s = $s.Replace($cx,'c^').Replace($Cx,'C^')
  $s = $s.Replace($gx,'g^').Replace($Gx,'G^')
  $s = $s.Replace($hx,'h^').Replace($Hx,'H^')
  $s = $s.Replace($jx,'j^').Replace($Jx,'J^')
  $s = $s.Replace($sx,'s^').Replace($Sx,'S^')
  $s = $s.Replace($ux,'u^').Replace($Ux,'U^')
  return $s
}

# --- Read CSV first column ---
$csvLines = Get-Content -LiteralPath $csv -Encoding UTF8
$csvWords = New-Object System.Collections.Generic.List[string]
for($i=1;$i -lt $csvLines.Count;$i++){  # skip header
  $line = $csvLines[$i]
  if([string]::IsNullOrWhiteSpace($line)){continue}
  $w = ($line -split ',')[0]
  $w = $w.Trim()
  # strip BOM if present
  $w = $w.TrimStart([char]0xFEFF)
  if($w -eq ''){continue}
  $csvWords.Add((ToH $w))
}
Write-Host "CSV words read (excl header): $($csvWords.Count)"

# --- Build lookup of output headwords ---
# Each output line: HEAD[⟦KANJI⟧]:gloss   OR   HEAD:gloss (no kanji)
# plain key = HEAD with '/' and '-' removed. value = whether kanji present.
$outLines = Get-Content -LiteralPath $out -Encoding UTF8
$map = @{}   # plainkey -> $true(has kanji) ; store best (any line with kanji => true)
$mapKanji = @{} # plainkey -> kanji content (first seen with kanji)
foreach($line in $outLines){
  if($line -eq ''){continue}
  $line2 = $line.TrimStart([char]0xFEFF)
  # split on first ':'
  $ci = $line2.IndexOf(':')
  if($ci -lt 0){continue}
  $headFull = $line2.Substring(0,$ci)
  $hasKanji = $false
  $kanji = ''
  $head = $headFull
  $bi = $headFull.IndexOf([char]0x301A)  # ⟦
  if($bi -ge 0){
    $ei = $headFull.IndexOf([char]0x301B) # ⟧
    $head = $headFull.Substring(0,$bi)
    if($ei -gt $bi){ $kanji = $headFull.Substring($bi+1, $ei-$bi-1) }
    $hasKanji = $true
  }
  # plain key
  $key = $head -replace '/','' -replace '-',''
  if(-not $map.ContainsKey($key)){ $map[$key] = $hasKanji; if($hasKanji){$mapKanji[$key]=$kanji} }
  else {
    if($hasKanji -and -not $map[$key]){ $map[$key]=$true }
    if($hasKanji -and -not $mapKanji.ContainsKey($key)){ $mapKanji[$key]=$kanji }
  }
}
Write-Host "Output headword keys: $($map.Count)"

# --- Match each CSV word ---
$covered = New-Object System.Collections.Generic.List[string]
$notfound = New-Object System.Collections.Generic.List[string]   # not in output at all
$nokanji  = New-Object System.Collections.Generic.List[string]   # in output but no kanji (untargeted)
foreach($w in $csvWords){
  $key = $w -replace '/','' -replace '-',''
  if($map.ContainsKey($key)){
    if($map[$key]){ $covered.Add($w) }
    else { $nokanji.Add($w) }
  } else {
    $notfound.Add($w)
  }
}

$total = $csvWords.Count
$cov = $covered.Count
Write-Host ""
Write-Host "=== COVERAGE ==="
Write-Host "Total CSV words: $total"
Write-Host "Covered (has kanji): $cov  ($([math]::Round(100.0*$cov/$total,2))%)"
Write-Host "In output but NO kanji (untargeted): $($nokanji.Count)"
Write-Host "Not found in output at all: $($notfound.Count)"

# write detail files
Set-Content -LiteralPath (Join-Path $base '_indep_nokanji.txt') -Value $nokanji -Encoding UTF8
Set-Content -LiteralPath (Join-Path $base '_indep_notfound.txt') -Value $notfound -Encoding UTF8
Write-Host "(wrote _indep_nokanji.txt, _indep_notfound.txt)"

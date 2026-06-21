$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
# locate CSV and output by glob (avoid hardcoding non-ascii literals)
$csvPath = (Get-ChildItem -Path $base -Recurse -Filter '2890 Gravaj*.csv' | Select-Object -First 1).FullName
# learner version is the LARGER of the two _20260620.txt files
$outPath = (Get-ChildItem -Path $base -Filter '*_20260620.txt' | Sort-Object Length -Descending | Select-Object -First 1).FullName
Write-Host ("CSV: " + $csvPath)
Write-Host ("OUT: " + $outPath)

# NOTE: PowerShell variable names are CASE-INSENSITIVE, so $cc and $cC would
# collide. Use lo_/up_ prefixes to keep lowercase and uppercase distinct.
$lo_c = [string][char]0x0109; $up_c = [string][char]0x0108
$lo_g = [string][char]0x011D; $up_g = [string][char]0x011C
$lo_h = [string][char]0x0125; $up_h = [string][char]0x0124
$lo_j = [string][char]0x0135; $up_j = [string][char]0x0134
$lo_s = [string][char]0x015D; $up_s = [string][char]0x015C
$lo_u = [string][char]0x016D; $up_u = [string][char]0x016C

function ToH([string]$s){
  $s = $s.Replace($lo_c,'c^').Replace($up_c,'C^')
  $s = $s.Replace($lo_g,'g^').Replace($up_g,'G^')
  $s = $s.Replace($lo_h,'h^').Replace($up_h,'H^')
  $s = $s.Replace($lo_j,'j^').Replace($up_j,'J^')
  $s = $s.Replace($lo_s,'s^').Replace($up_s,'S^')
  $s = $s.Replace($lo_u,'u^').Replace($up_u,'U^')
  return $s
}
$LB = [string][char]0x27E6
$RB = [string][char]0x27E7

$outLines = [System.IO.File]::ReadAllLines($outPath)
$outMap = @{}
$outRawMap = @{}
$outKanjiBlock = @{}
$LBc = [char]0x27E6
$RBc = [char]0x27E7
foreach($line in $outLines){
  $line = [string]$line
  if($line -eq '' -or $line[0] -eq '#'){ continue }
  $ci = [string]::new($line).IndexOf([char]':')
  if($ci -lt 0){ continue }
  $head = $line.Substring(0,$ci)
  $hasKanji = $false
  $kblock = ''
  $lb = $head.IndexOf($LBc)
  if($lb -ge 0){
    $hasKanji = $true
    $rb = $head.IndexOf($RBc)
    if($rb -gt $lb){ $kblock = $head.Substring($lb+1, $rb-$lb-1) }
    $head = $head.Substring(0,$lb)
  }
  $key = $head -replace '/','' -replace '-',''
  if(-not $outMap.ContainsKey($key)){
    $outMap[$key] = $hasKanji
    $outRawMap[$key] = $head
    $outKanjiBlock[$key] = $kblock
  } else {
    if($hasKanji -and -not $outMap[$key]){
      $outMap[$key] = $true
      $outRawMap[$key] = $head
      $outKanjiBlock[$key] = $kblock
    }
  }
}
Write-Host ("Output index size: " + $outMap.Count)

$csvLines = [System.IO.File]::ReadAllLines($csvPath)
$total = 0; $covered = 0
$notFound = New-Object System.Collections.ArrayList
$noKanji = New-Object System.Collections.ArrayList
for($i=1; $i -lt $csvLines.Count; $i++){
  $ln = $csvLines[$i]
  if($ln.Trim() -eq ''){ continue }
  $comma = $ln.IndexOf(',')
  if($comma -lt 0){ continue }
  $lemma = $ln.Substring(0,$comma).Trim()
  if($lemma -eq ''){ continue }
  $total++
  $h = ToH $lemma
  $key = $h -replace '/','' -replace '-',''
  if($outMap.ContainsKey($key)){
    if($outMap[$key]){
      $covered++
    } else {
      [void]$noKanji.Add(($lemma + "`t" + $h + "`t" + $outRawMap[$key]))
    }
  } else {
    [void]$notFound.Add(($lemma + "`t" + $h + "`t" + $key))
  }
}

Write-Host ("Total CSV entries: " + $total)
Write-Host ("Covered (has kanji): " + $covered)
$rate = [math]::Round(100.0*$covered/$total,2)
Write-Host ("Coverage rate: " + $rate + " %")
Write-Host ("Not found in output: " + $notFound.Count)
Write-Host ("Found but no kanji: " + $noKanji.Count)

$enc = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines((Join-Path $base '_verify_notfound.tsv'), $notFound, $enc)
[System.IO.File]::WriteAllLines((Join-Path $base '_verify_nokanji.tsv'), $noKanji, $enc)
Write-Host "Done."

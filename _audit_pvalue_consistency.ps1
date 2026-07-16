# P整合advisory監査(2026-07-16 第9回監査で新設): _p_work.csv の k列(漢字)と
# st/E/D/P列(画数由来の優先度計算値)が整合しているか点検。k列を変更したのに
# P列を再計算し忘れた「旧P値残存」を可視化する。
#   P=5 sentinel(隙間充填=V非計算)は対象外。一级外字を含む行(char画数不明)もスキップ。
# GASが読むのはP列(C=band_rank*1000+P)なので、旧P値は将来のk変更/再計算時に
# 基本形・識別子順を動かしうる技術的負債。ただし出力が既に安定なら即害はない。
# ★これはadvisory(表示のみ)。$fail にはしない(一括修正は基本形を動かすため個別裁定)。
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
$strokes=@{}
Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
  $p=$_ -split "`t"; if($p.Count -ge 4 -and $p[1]){ $strokes[$p[1]]=[int]$p[3] }
}
$bad=New-Object System.Collections.ArrayList
Import-Csv "$dir\_p_work.csv" -Encoding UTF8 | ForEach-Object {
  if($_.P -eq '5'){ return }                      # P=5 sentinel は V非計算ゆえ対象外
  $k=$_.k; $st=0; $ok=$true
  foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($strokes.ContainsKey($cs)){ $st+=$strokes[$cs] } else { $ok=$false } }
  if(-not $ok -or $st -le 0){ return }             # 一级外字/結合を含む行はスキップ(画数不明)
  $lat=[double]$_.lat; $F=[double]$_.F
  $E=$lat/$st
  $Pexp = -([math]::Log($F+1) + 0.3*$E - 0.1*$st)  # D=st(一级はランク0)
  $Pcur=[double]$_.P
  if([int]$_.st -ne $st -or [math]::Abs($Pcur-$Pexp) -gt 0.02){
    [void]$bad.Add(("{0}`tst_csv={1}`tst_real={2}`tP_csv={3}`tP_real={4}" -f $_.root,$_.st,$st,$_.P,("{0:F3}" -f $Pexp)))
  }
}
Write-Host ("[G] P整合advisory: k列画数とst/P不一致(P≠5) = {0}行(旧P値残存=技術的負債。基本形/IDは現状安定・一括修正は诲/毒蛇の基本形が動くため個別対応)" -f $bad.Count)
$bad | ForEach-Object { Write-Host ("    "+$_) }

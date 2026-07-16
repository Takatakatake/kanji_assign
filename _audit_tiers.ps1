$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
$out="$dir\漢字注入_学習者版_20260620.txt"
$lines=Get-Content $out -Encoding UTF8
$BOUND=44104
# tier別: 見出し行(: を含む)を content/proper/grammar に分類し、⟦注入有無
function Classify($head){
  # 大文字始まり(固有名)
  if($head -cmatch '^[A-ZĈĜĤĴŜŬ]'){ return 'proper' }
  $sp=($head -split ' ')[0] -replace '/',''
  if($sp.Length -le 2){ return 'gram' }
  return 'content'
}
$stat=@{}
foreach($t in 'PEJVO','PIV'){ foreach($c in 'content','proper','gram'){ $stat["$t/$c/tot"]=0; $stat["$t/$c/inj"]=0 } }
for($i=0;$i -lt $lines.Count;$i++){
  $ln=$lines[$i]; $ci=$ln.IndexOf(':'); if($ci -lt 1){continue}
  $tier= if(($i+1) -le $BOUND){'PEJVO'}else{'PIV'}
  $hasK = $ln -match '⟦'
  $head = if($hasK){ $ln.Substring(0,$ln.IndexOf('⟦')) } else { $ln.Substring(0,$ci) }
  $cls=Classify $head
  $stat["$tier/$cls/tot"]++
  if($hasK){ $stat["$tier/$cls/inj"]++ }
}
Write-Host "=== 行番号境界(<=44104=旧PEJVO / 44105-44440=PEJVO追補 / >=44441=PIV)での層別 見出し行被覆(粗2分割は被覆統計用) ==="
foreach($t in 'PEJVO','PIV'){
  Write-Host ("--- {0} ---" -f $t)
  foreach($c in 'content','proper','gram'){
    $tot=$stat["$t/$c/tot"]; $inj=$stat["$t/$c/inj"]
    $pct= if($tot -gt 0){ "{0:P1}" -f ($inj/[double]$tot) } else {'-'}
    Write-Host ("  {0,-8} 見出し {1,6} / 注入 {2,6} = {3}" -f $c,$tot,$inj,$pct)
  }
}
# 境界整合: 【PIV】マーカー位置 vs 行番号境界
# 2026-07-16 原本更新追従: PEJVO既存見出しへのPIV定義の合併(「... / 【史】【PIV】...」= Arg/Eol)が出現。
# PIV由来見出し=「語釈冒頭(任意個の【タグ】の直後)に【PIV】」で判定し、途中合併は境界違反にしない(参考表示)。
$pivNative='^[^:]+:(【[^】]*】)*【PIV】'
$pivBeforeBound=0; $pivMergedBefore=0; $nonpivAfterBound=0; $pivTot=0
for($i=0;$i -lt $lines.Count;$i++){
  $ln=$lines[$i]; if($ln.IndexOf(':') -lt 1){continue}
  $isPiv = $ln -match $pivNative
  if($isPiv){ $pivTot++; if(($i+1) -le $BOUND){ $pivBeforeBound++ } }
  else {
    if(($i+1) -le $BOUND -and $ln -match '【PIV】'){ $pivMergedBefore++ }
    if(($i+1) -gt $BOUND){ $nonpivAfterBound++ }
  }
}
Write-Host ""
Write-Host ("=== 境界整合チェック ===")
Write-Host ("  【PIV】由来見出し総数 {0}(語釈冒頭判定)" -f $pivTot)
Write-Host ("  境界(44104)以前にある【PIV】行 = {0}" -f $pivBeforeBound)
Write-Host ("  境界以前のPIV定義合併行(参考・違反でない) = {0}(既存PEJVO見出しに「 / 【PIV】…」追記された行=Arg/Eol型)" -f $pivMergedBefore)
Write-Host ("  境界以降にある 非【PIV】見出し行 = {0}(注: 44105-44440=PEJVO追補336行 + 44441以降の非PIV見出し。>44104=全PIV ではない)" -f $nonpivAfterBound)

# 3層構造の精査(2026-07-16 第6回監査是正: PEJVO追補区間を明示。従来の">44104=PIV"は追補分だけ不正確)
$firstPiv=-1; for($k=0;$k -lt $lines.Count;$k++){ if($lines[$k] -match $pivNative){ $firstPiv=$k+1; break } }
$pivSupp=0; for($k=44104;$k -lt 44440;$k++){ if($lines[$k] -match $pivNative){ $pivSupp++ } }
Write-Host ("  最初の【PIV】行 = {0}(=PIV層開始。44105-{1}はPEJVO 2024追補)" -f $firstPiv,($firstPiv-1))
Write-Host ("  PEJVO追補区間(44105-44440)内の【PIV】行 = {0}(0が正=追補は純PEJVO)" -f $pivSupp)

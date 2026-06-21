$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
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
Write-Host "=== 行番号境界(<=44104=PEJVO / >44104=PIV)での層別 見出し行被覆 ==="
foreach($t in 'PEJVO','PIV'){
  Write-Host ("--- {0} ---" -f $t)
  foreach($c in 'content','proper','gram'){
    $tot=$stat["$t/$c/tot"]; $inj=$stat["$t/$c/inj"]
    $pct= if($tot -gt 0){ "{0:P1}" -f ($inj/[double]$tot) } else {'-'}
    Write-Host ("  {0,-8} 見出し {1,6} / 注入 {2,6} = {3}" -f $c,$tot,$inj,$pct)
  }
}
# 境界整合: 【PIV】マーカー位置 vs 行番号境界
$pivBeforeBound=0; $nonpivAfterBound=0; $pivTot=0
for($i=0;$i -lt $lines.Count;$i++){
  $ln=$lines[$i]; if($ln.IndexOf(':') -lt 1){continue}
  $isPiv = $ln -match '【PIV】'
  if($isPiv){ $pivTot++; if(($i+1) -le $BOUND){ $pivBeforeBound++ } }
  else { if(($i+1) -gt $BOUND){ $nonpivAfterBound++ } }
}
Write-Host ""
Write-Host ("=== 境界整合チェック ===")
Write-Host ("  【PIV】総数 {0}" -f $pivTot)
Write-Host ("  境界(44104)以前にある【PIV】行 = {0}" -f $pivBeforeBound)
Write-Host ("  境界以降にある 非【PIV】見出し行 = {0}" -f $nonpivAfterBound)

# 偽分解尊重「整合性」監査。
# 「ある語で漢字が当たる語根が、別の語で(文法語尾でも固有名でもないのに)latin残存」する不整合を全注入から悉皆検出。
# 候補の大半は同綴別語(homonym)/結合形/固有名で正当 → 既知15件はホワイトリスト化し、
# それ以外の【★新規】候補のみを「要確認(真の偽分解違反の疑い)」として報告する前向き監査。
# 使い方: powershell -File _audit_fake_decomp_consistency.ps1
$ErrorActionPreference='Continue'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'

# 文法語尾・分詞接尾(latin残存が正常)
$endings=@{}
foreach($e in @('o','a','e','i','u','j','n','oj','aj','ej','on','an','en','ojn','ajn','as','is','os','us','int','ant','ont','it','at','ot')){ $endings[$e]=$true }

# 既知の正当不整合(同綴別語/結合形/固有名)= 2026-06-27 全15件を語義照合で確定。新規はこれ以外。
$known = @('aktini','al','are','gram','in','log','od','ol','om','or','oz','par','tio','tom','ul')
$knownSet=@{}; foreach($k in $known){ $knownSet[$k]=$true }

$lo=[char]0x4E00; $hi=[char]0x9FFF; $hasCJK=[regex]('['+$lo+'-'+$hi+']')
# 固有名(大文字始)= case-sensitive 必須(PowerShell -match は既定で大小無視のため [regex] を使う)
$capRe=[regex]('^[A-Z'+[char]0x108+[char]0x11C+[char]0x124+[char]0x134+[char]0x15C+[char]0x16C+']')
$L1=[char]0x27E6; $R1=[char]0x27E7   # 注入括弧 ⟦ ⟧

$totalNew=0
foreach($pair in @(@('漢字注入_学習者版_20260620.txt','学習者'),@('漢字注入_学術版_20260620.txt','学術'))){
  $f=Join-Path $dir $pair[0]
  if(-not (Test-Path -LiteralPath $f)){ continue }
  $c=Get-Content -LiteralPath $f -Encoding UTF8
  $kanjiOf=@{}; $latinAt=@{}
  foreach($line in $c){
    $ci=$line.IndexOf($L1); if($ci -lt 0){ continue }
    $cj=$line.IndexOf($R1,$ci); if($cj -lt 0){ continue }
    $head=$line.Substring(0,$ci); $kanjiPart=$line.Substring($ci+1,$cj-$ci-1)
    if($capRe.IsMatch($head)){ continue }
    $hs=@($head -split '/'); $ks=@($kanjiPart -split '/')
    if($hs.Count -ne $ks.Count){ continue }
    for($i=0;$i -lt $hs.Count;$i++){
      $hseg=[string]$hs[$i]; $kseg=[string]$ks[$i]
      if($hseg -match '\s'){ continue }
      if($hseg.Length -lt 2){ continue }
      if($endings.ContainsKey($hseg)){ continue }
      if($hasCJK.IsMatch($kseg)){ if(-not $kanjiOf.ContainsKey($hseg)){ $kanjiOf[$hseg]=$kseg } }
      elseif($kseg -eq $hseg){ if(-not $latinAt.ContainsKey($hseg)){ $latinAt[$hseg]=$head } }
    }
  }
  $incons=@(); foreach($r in $latinAt.Keys){ if($kanjiOf.ContainsKey($r)){ $incons+=$r } }
  $newOnes=@($incons | Where-Object { -not $knownSet.ContainsKey($_) } | Sort-Object)
  $totalNew += $newOnes.Count
  Write-Host ('['+$pair[1]+'版] 漢字化語根='+$kanjiOf.Count+' / 不整合候補='+$incons.Count+'(既知正当'+($incons.Count-$newOnes.Count)+' / ★新規'+$newOnes.Count+')')
  foreach($r in $newOnes){ Write-Host ('    ★新規要確認: '+$r+'  →漢字『'+$kanjiOf[$r]+'』  latin残: '+$latinAt[$r]) }
}
Write-Host ('=== 偽分解整合性: ★新規不整合 = '+$totalNew+'件(0が正。新規が出たら同綴別語か真の違反かを語義照合) ===')
exit 0

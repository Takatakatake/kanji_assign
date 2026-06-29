# 単一字割当の「孤立字」スキャン。
# 各注入トークンで「1個のCJK字(+識別子上付き)だけ」の割当を抽出し、
# その基底字 base に対応する distinct 語根(headの当該分節)を集計。
# base に語根が1つだけ=孤立単字割当(苛=drakon 型)。さらに総出現回数も付す。
# 出力: base字 / 語根数 / 総出現 / 語根例。語根数==1 を fold候補として精査する。
$ErrorActionPreference='Continue'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$f=Join-Path $dir '漢字注入_学習者版_20260620.txt'
$L1=[char]0x27E6; $R1=[char]0x27E7
$lo=[char]0x4E00; $hi=[char]0x9FFF
$cjk=[regex]('['+$lo+'-'+$hi+']')
# 上付き識別子の文字域(modifier letters / combining diacritics / superscripts)
$idChars='[ʰ-˿ᴀ-ᶿ̀-ͯ⁰-₟]'
$capRe=[regex]('^[A-Z'+[char]0x108+[char]0x11C+[char]0x124+[char]0x134+[char]0x15C+[char]0x16C+']')

$rootsOf=@{}   # base -> hashset of roots
$count=@{}      # base -> total token occurrences
foreach($line in [System.IO.File]::ReadAllLines($f)){
  $ci=$line.IndexOf($L1); if($ci -lt 0){ continue }
  $cj=$line.IndexOf($R1,$ci); if($cj -lt 0){ continue }
  $head=$line.Substring(0,$ci); $kanjiPart=$line.Substring($ci+1,$cj-$ci-1)
  if($capRe.IsMatch($head)){ continue }
  $hs=@($head -split '/'); $ks=@($kanjiPart -split '/')
  if($hs.Count -ne $ks.Count){ continue }
  for($i=0;$i -lt $ks.Count;$i++){
    $kseg=[string]$ks[$i]; $hseg=[string]$hs[$i]
    # 識別子上付きを剥がす
    $bare = ($kseg -replace $idChars,'')
    # 「ちょうど1個のCJK字」だけの割当か(2字熟語・latin混在は除外)
    if($bare.Length -eq 1 -and $cjk.IsMatch($bare)){
      $b=$bare
      if(-not $rootsOf.ContainsKey($b)){ $rootsOf[$b]=@{} }
      $rootsOf[$b][$hseg]=$true
      if(-not $count.ContainsKey($b)){ $count[$b]=0 }
      $count[$b]++
    }
  }
}
# 語根数==1(孤立単字割当)を出力。総出現の少ない順。
$rows=@()
foreach($b in $rootsOf.Keys){
  if($rootsOf[$b].Count -eq 1){
    $rt=@($rootsOf[$b].Keys)[0]
    $rows += [pscustomobject]@{ base=$b; roots=$rootsOf[$b].Count; occ=$count[$b]; root=$rt }
  }
}
$iso=@($rows | Sort-Object occ,base)
Write-Host ("単一字割当の総base字 = "+$rootsOf.Count+" / うち孤立(語根1つだけ)= "+$iso.Count)
Write-Host "=== 孤立単字割当 全件(base / 総出現occ / 語根) ==="
foreach($r in $iso){ Write-Host ("  "+$r.base+"  occ="+$r.occ+"  root="+$r.root) }
exit 0

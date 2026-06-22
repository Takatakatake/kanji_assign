# 独立・構造整合監査(既存監査が未検証の項目): 注入出力 ⟦⟧ の構造を原本見出しと照合
#  (1)語ごとのスラッシュ数一致(§11 = 見出しのスラッシュ数と一致) ※ハイフンも形態素境界
#  (2)大文字始(多字)見出し=固有名 -> 先頭語の漢字付与は違反(§7)。例外: 単一大文字+ハイフン(T-/U-/X-/H-)
#  (3)文法語尾(終端 o/a/e/i/u/oj/aj/as/is/os/us/n/j)= ⟦⟧内でラテン保持
#  (4)⟦⟧内に残ったラテン語根候補(漢字を含まず・語尾でも識別子でもない純ラテン2字以上)を抽出
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$files=@('漢字注入_学習者版_20260620.txt','漢字注入_学術版_20260620.txt')
$reBr=[regex]'^(.*?)⟦([^⟧]*)⟧'
$reKanji=[regex]'[一-鿿]'
$ending='^(o|a|e|i|u|oj|aj|ojn|ajn|on|an|en|as|is|os|us|u|j|n)$'
foreach($fn in $files){
  $path=Join-Path $dir $fn
  $lines=[System.IO.File]::ReadAllLines($path)
  $slashMis=New-Object System.Collections.ArrayList
  $properHit=New-Object System.Collections.ArrayList
  $endingMis=New-Object System.Collections.ArrayList
  $latinResid=@{}
  $injLines=0
  foreach($line in $lines){
    $m=$reBr.Match($line); if(-not $m.Success){ continue }
    $injLines++
    $head=$m.Groups[1].Value
    $block=$m.Groups[2].Value
    # (2) 固有名ガード: 先頭語が多字大文字始(X-型でない)で漢字化されていれば違反
    if(($head -cmatch '^[A-ZĈĜĤĴŜŬ]') -and ($head -notmatch '^[A-ZĈĜĤĴŜŬ]-')){
      $bw0=($block -split ' ')[0]
      if($reKanji.IsMatch($bw0)){ [void]$properHit.Add($head+'  ⟦'+$block+'⟧') }
    }
    # (1)(3)(4) 語ごとに照合
    $hwords=$head -split ' '; $bwords=$block -split ' '
    if($hwords.Count -ne $bwords.Count){ [void]$slashMis.Add("[語数不一致] "+$head+" ⟦"+$block+"⟧"); continue }
    for($wi=0;$wi -lt $hwords.Count;$wi++){
      $hw=$hwords[$wi]; $bw=$bwords[$wi]
      $hs=([regex]::Matches($hw,'/')).Count
      $bs=([regex]::Matches($bw,'/')).Count
      if($hs -ne $bs){ [void]$slashMis.Add(("[/数不一致] {0}({1}) vs {2}({3})" -f $hw,$hs,$bw,$bs)); continue }
      $hsg=$hw -split '/'; $bsg=$bw -split '/'
      # (3) 終端文法語尾: 見出し最終分節が語尾なら ⟦⟧最終分節もラテン同一
      $last=$hsg[$hsg.Count-1]
      if($last -match $ending){ if($bsg[$bsg.Count-1] -ne $last){ [void]$endingMis.Add(("{0} ⟦{1}⟧ 終端 {2}->{3}" -f $hw,$bw,$last,$bsg[$bsg.Count-1])) } }
      # (4) ⟦⟧内ラテン残存
      foreach($seg in $bsg){
        if($reKanji.IsMatch($seg)){ continue }   # 漢字含む分節は除外
        $core=$seg -replace '[^a-zA-Zĉĝĥĵŝŭ]',''   # ラテン基底字のみ(上付き識別子・ハイフン除去)
        if($core.Length -ge 2 -and ($core -notmatch $ending)){
          if(-not $latinResid.ContainsKey($core)){ $latinResid[$core]=0 }; $latinResid[$core]++
        }
      }
    }
  }
  Write-Host ("`n========== [{0}] 注入行 {1} ==========" -f $fn,$injLines)
  Write-Host ("(1) スラッシュ数/語数 不一致: {0}件 {1}" -f $slashMis.Count,$(if($slashMis.Count -eq 0){'PASS'}else{'NG'}))
  $slashMis | Select-Object -First 25 | ForEach-Object{ "    $_" }
  Write-Host ("(2) 固有名(多字大文字始)に漢字付与: {0}件 {1}" -f $properHit.Count,$(if($properHit.Count -eq 0){'PASS'}else{'NG'}))
  $properHit | Select-Object -First 25 | ForEach-Object{ "    $_" }
  Write-Host ("(3) 終端文法語尾の非ラテン化: {0}件 {1}" -f $endingMis.Count,$(if($endingMis.Count -eq 0){'PASS'}else{'NG'}))
  $endingMis | Select-Object -First 25 | ForEach-Object{ "    $_" }
  Write-Host ("(4) ⟦⟧内ラテン残存(借用/固有名/未漢字化候補) 種類: {0} / 延べ抽出上位:" -f $latinResid.Count)
  $latinResid.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 45 | ForEach-Object{ "    {0}  ({1})" -f $_.Key,$_.Value }
}

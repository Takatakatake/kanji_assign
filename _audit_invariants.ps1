# ルール遵守 不変条件 一括検証: ①原本diff=0 ②⟦⟧内 一级外字0 ③数字id0 ④特殊字(ĉĝĥĵŝŭ)漏れ0 ⑤id重複0(群内)
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
$srcDir="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026"
$pairs=@(
  @('世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt','漢字注入_学習者版_20260620.txt'),
  @('世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt','漢字注入_学術版_20260620.txt') )

# --- 一级3500字 集合 ---
$yiji=New-Object System.Collections.Generic.HashSet[string]
$yt=Get-Content "$dir\通用规范汉字表_一级3500字.txt" -Raw -Encoding UTF8
foreach($ch in $yt.ToCharArray()){ if([int][char]$ch -ge 0x4E00 -and [int][char]$ch -le 0x9FFF){ [void]$yiji.Add([string]$ch) } }
Write-Host ("一级字数: {0}" -f $yiji.Count)

# 上付き識別子・特殊記号(漢字でない)を判定から除外する集合
function IsKanji([string]$ch){ $cp=[int][char]$ch; ($cp -ge 0x4E00 -and $cp -le 0x9FFF) -or ($cp -ge 0x3400 -and $cp -le 0x4DBF) }

foreach($pair in $pairs){
  $src=Join-Path $srcDir $pair[0]; $outp=Join-Path $dir $pair[1]
  if(-not (Test-Path $outp)){ Write-Host ("skip(無): "+$pair[1]); continue }
  $orig=Get-Content $src -Encoding UTF8
  $out =Get-Content $outp -Encoding UTF8
  # ①原本diff
  $diff=0; for($i=0;$i -lt $orig.Count;$i++){ $st=$out[$i] -replace '⟦[^⟧]*⟧',''; if($st -ne $orig[$i]){ $diff++ } }
  # ②④ ⟦⟧内の漢字を走査
  $nonYiji=@{}; $special=0; $bracketLines=0; $kanjiTokens=0
  $reBr=[regex]'⟦([^⟧]*)⟧'
  foreach($line in $out){
    foreach($m in $reBr.Matches($line)){ $bracketLines++
      foreach($ch in $m.Groups[1].Value.ToCharArray()){
        $c=[string]$ch
        if($c -match '[ĉĝĥĵŝŭĈĜĤĴŜŬ]'){ $special++ }
        if(IsKanji $c){ $kanjiTokens++; if(-not $yiji.Contains($c)){ if(-not $nonYiji.ContainsKey($c)){$nonYiji[$c]=0}; $nonYiji[$c]++ } }
      }
    }
  }
  Write-Host ("`n[{0}]" -f $pair[1])
  Write-Host ("  ①原本diff      = {0} {1}" -f $diff,$(if($diff -eq 0){'PASS'}else{'FAIL!'}))
  Write-Host ("  ②一级外字       = {0}種 {1}" -f $nonYiji.Count,$(if($nonYiji.Count -eq 0){'PASS'}else{'FAIL! → '+(($nonYiji.Keys|ForEach-Object{ '{0}({1})' -f $_,$nonYiji[$_] }) -join ' ')}))
  Write-Host ("  ④特殊字漏れ     = {0} {1}" -f $special,$(if($special -eq 0){'PASS'}else{'FAIL!'}))
  Write-Host ("  (注入漢字延べ   = {0})" -f $kanjiTokens)
}

# ③数字id ⑤群内id重複(サイドカー)
Write-Host "`n=== サイドカー識別子検証 ==="
$rows=Import-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -Delimiter "`t"
$numId=@($rows | Where-Object{ $_.id_super -match '[0-9]' })
Write-Host ("  ③数字id = {0} {1}" -f $numId.Count,$(if($numId.Count -eq 0){'PASS'}else{'FAIL! → '+(($numId|ForEach-Object{$_.root+':'+$_.id_super}) -join ' ')}))
# ⑤群内 disp+id_super の重複
$grp=@{}
foreach($r in $rows){ $g=$r.groupkey; if(-not $grp.ContainsKey($g)){$grp[$g]=New-Object System.Collections.ArrayList}; [void]$grp[$g].Add($r) }
$dupTotal=0; $dupSample=New-Object System.Collections.ArrayList
foreach($g in $grp.Keys){ $mem=$grp[$g]; if($mem.Count -lt 2){continue}
  $seen=@{}
  foreach($m in $mem){ $k=$m.disp+'|'+$m.id_super; if($seen.ContainsKey($k)){ $dupTotal++; if($dupSample.Count -lt 10){[void]$dupSample.Add(("群{0}: {1}+{2} ⇔ {3}" -f $g,$m.root,$m.id_super,$seen[$k]))} } else { $seen[$k]=$m.root } }
}
Write-Host ("  ⑤群内id重複 = {0} {1}" -f $dupTotal,$(if($dupTotal -eq 0){'PASS'}else{'FAIL!'}))
$dupSample | ForEach-Object{ "    $_" }

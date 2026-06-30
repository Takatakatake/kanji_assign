# 優先順位監査: ①CSV2890の被覆(実注入出力で判定) ②基本形の優先順位逆転(サイドカー) ③band正当性
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
$out="$dir\漢字注入_学習者版_20260620.txt"
$csv="$dir\30_重要語彙CSV_日中対照_2890語\2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"

# --- 注入出力: 見出し綴り(/除去) -> 割当有無。※大小区別(Ordinal): 固有名 Mar/o と 内容語 mar/o を混同しない。割当ありを優先 ---
$spell=[System.Collections.Generic.Dictionary[string,bool]]::new([System.StringComparer]::Ordinal)
foreach($line in (Get-Content $out -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}
  $hasK = $line -match '⟦'
  $head = if($hasK){ $line.Substring(0,$line.IndexOf('⟦')) } else { $line.Substring(0,$ci) }
  foreach($w in ($head -split ' ')){ $sp=($w -replace '/',''); if($sp){ if(-not $spell.ContainsKey($sp)){ $spell[$sp]=$hasK } elseif($hasK){ $spell[$sp]=$true } } }
}

# --- CSV2890 被覆(CSVはUnicode→h-system正規化して照合) ---
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^' }
$lines=Get-Content $csv -Encoding UTF8 | Select-Object -Skip 1
$assigned=0;$untgt=0;$nomatch=0;$total=0
$untgtList=New-Object System.Collections.ArrayList; $nomatchList=New-Object System.Collections.ArrayList
foreach($l in $lines){
  $eo=($l -split ',')[0].Trim().Trim('"'); if(-not $eo){continue}
  $eo=(ToHsys $eo).Trim('-')   # h-system化 + 接辞の前後ハイフン除去
  if(-not $eo){continue}
  $total++
  if($spell.ContainsKey($eo)){ if($spell[$eo]){$assigned++}else{$untgt++; [void]$untgtList.Add($eo)} }
  else { $nomatch++; [void]$nomatchList.Add($eo) }
}
Write-Host ("=== CSV2890 被覆(実注入出力で判定) 計{0} ===" -f $total)
Write-Host ("  割当済 {0} ({1:P1}) / 未対応 {2} / 出力に綴り無し {3}" -f $assigned,($assigned/[double]$total),$untgt,$nomatch)
# 未対応を分類(固有名=大文字始 / 文法=1-2字 / 間投詞=!終 / 残=要検討content)
$pn=@();$gram=@();$intj=@();$genuine=@()
foreach($u in $untgtList){
  if($u -cmatch '^[A-Z]'){ $pn+=$u }
  elseif($u.Length -le 2 -or $u -match '^(ajn|c^i|k\.t\.p\.)$'){ $gram+=$u }
  elseif($u -match '!$'){ $intj+=$u }
  else{ $genuine+=$u }
}
Write-Host ("  [未対応内訳] 固有名{0} / 文法・小詞{1} / 間投詞{2} / 要検討content{3}" -f $pn.Count,$gram.Count,$intj.Count,$genuine.Count)
Write-Host "  --- ★要検討content(CSV2890だが未対応=ギャップ候補) 全件 ---"
$genuine | ForEach-Object{ "    $_" }
Write-Host "  --- 固有名(正常) ---"; Write-Host ("    "+($pn -join ' '))
Write-Host "  --- 綴り無し(接辞・分解形が大半=偽ギャップ。content風のみ抽出) ---"
$nomatchList | Where-Object{ $_ -cmatch '^[a-z]' -and $_.Length -ge 4 -and $_ -notmatch '^(au\^|eu\^)' } | Select-Object -First 30 | ForEach-Object{ "    $_" }

# --- 基本形 優先順位逆転(サイドカー) ---
$rank=@{ 'basic'=0;'suf'=0;'pref'=0;'prep'=0;'correl'=0;'num'=0;'func'=0;'pejvo'=1;'sci'=1;'elem'=1;'cal'=1;'rel'=1;'piv'=2;'proper'=2 }
$rows=Import-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -Delimiter "`t"
$grp=@{}
foreach($r in $rows){ $g=$r.groupkey; if(-not $grp.ContainsKey($g)){$grp[$g]=New-Object System.Collections.ArrayList}; [void]$grp[$g].Add($r) }
$inv=New-Object System.Collections.ArrayList
foreach($g in $grp.Keys){ $mem=$grp[$g]; if($mem.Count -lt 2){continue}
  $base=$mem | Where-Object{ $_.id_super -eq '' } | Select-Object -First 1
  if(-not $base){continue}
  $br=if($rank.ContainsKey($base.band)){$rank[$base.band]}else{1}
  foreach($m in $mem){ if($m.id_super -eq ''){continue}
    $mr=if($rank.ContainsKey($m.band)){$rank[$m.band]}else{1}
    if($mr -lt $br){ [void]$inv.Add(("群{0}: 基本形={1}({2}) ←逆転 {3}({4},id={5}) が高優先" -f $g,$base.root,$base.band,$m.root,$m.band,$m.id_super)) }
  }
}
Write-Host ""
Write-Host ("=== 基本形 優先順位逆転(低優先が基本形・高優先が識別子持ち): {0}件 ===" -f $inv.Count)
$inv | Select-Object -First 40 | ForEach-Object{ "  $_" }
# 3層(CSV2890=basic / PEJVO / PIV)から代表サンプルを抽出 → _audit_sample.tsv(語単位品質監査用)
# 各行: tier<TAB>root<TAB>kanji(disp)<TAB>gloss。各層を均等サンプリング(難易度/出現順で散らす)。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
# サイドカー: root→(disp,band)
$disp=@{};$band=@{}
Import-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -Delimiter "`t" | ForEach-Object{ $disp[$_.root]=$_.disp; $band[$_.root]=$_.band }
# 注入(学習者版)から各rootの基本形 gloss を採取(root/o・root/i・root/a・root/e の最初の行)
$gloss=@{}
$lines=[System.IO.File]::ReadAllLines("$dir\漢字注入_学習者版_20260620.txt")
foreach($ln in $lines){ $ci=$ln.IndexOf(':'); if($ci -lt 1){continue}; $head=$ln.Substring(0,$ci)
  $m=[regex]::Match($head,'^([a-z][a-z^]*)/(o|i|a|e|as|is|on)⟦'); if(-not $m.Success){continue}
  $r=$m.Groups[1].Value; if($gloss.ContainsKey($r)){continue}
  $g=$ln.Substring($ci+1); $g=$g -replace '##.*$',''; $g=$g.Substring(0,[Math]::Min(60,$g.Length)); $gloss[$r]=$g }
# band別 root集合(disp有=割当済のみ)
function SampleBand($bn,$n){
  $rs=@($band.Keys | Where-Object{ $band[$_] -eq $bn -and $disp.ContainsKey($_) -and $disp[$_] -and $gloss.ContainsKey($_) } | Sort-Object)
  if($rs.Count -le $n){ return $rs }
  $step=[math]::Floor($rs.Count/$n); $out=@(); for($i=0;$i -lt $rs.Count -and $out.Count -lt $n;$i+=$step){ $out+=$rs[$i] }; return $out
}
$out=New-Object System.Collections.ArrayList; [void]$out.Add("tier`troot`tkanji`tgloss")
foreach($pair in @(@('basic','CSV2890',110),@('pejvo','PEJVO',90),@('piv','PIV',90))){
  $rs=SampleBand $pair[0] $pair[2]
  foreach($r in $rs){ [void]$out.Add($pair[1]+"`t"+$r+"`t"+$disp[$r]+"`t"+$gloss[$r]) }
  Write-Host ("{0}: {1}件サンプル" -f $pair[1],$rs.Count)
}
[System.IO.File]::WriteAllLines("$dir\_audit_sample.tsv",$out,(New-Object System.Text.UTF8Encoding($false)))
Write-Host ("計 {0}件 → _audit_sample.tsv" -f ($out.Count-1))

# 第9次: ユーザー裁定(2026-06-21)。kart(カード)→卡 をR4音訳禁止の例外として割当。
#  卡(kǎ)=上+下 でカード(平たい札)を連想。CSV2890常用語(F高・L級)。卡は一级(YIJI)・未使用→衝突0→disp=卡(無印)。
#  ※通常音訳(沙发/巧克力等)は未対応のままだが、卡は完全に自然化した単字morphemeとしてユーザー承認の例外。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
function EoLen([string]$s){ $h=ToHsys $s; $n=0; for($i=0;$i -lt $h.Length;$i++){ if($i+1 -lt $h.Length -and $h[$i+1] -eq '^'){$i++}; $n++ }; $n }
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
$resc=@( ,@('kart','卡','basic') )   # 単項コンマ=単一要素入れ子配列のフラット化防止(必須)
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
$hmap=@{}; foreach($r in $resc){ $hmap[$r[0]]=(ToHsys $r[0]) }
$F=@{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci)
  $seen=@{}
  foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ foreach($r in $resc){ if($s -eq $hmap[$r[0]] -and -not $seen.ContainsKey($r[0])){ $seen[$r[0]]=$true; $F[$r[0]]=1+($F[$r[0]]) } } } }
}
$mRoots=@{}; Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 2){ $mRoots[$p[1].Trim()]=$true } }
$pwHas=@{}; Import-Csv "$dir\_p_work.csv" -Encoding UTF8|ForEach-Object{ $pwHas[$_.root]=$true }
$mAdd=New-Object System.Collections.ArrayList; $pAdd=New-Object System.Collections.ArrayList; $skip=0
foreach($r in $resc){ $root=$r[0];$k=$r[1];$band=$r[2]
  if($mRoots.ContainsKey($root) -or $pwHas.ContainsKey($root)){ Write-Host ("skip(既存): $root"); $skip++; continue }
  $f=[int]$F[$root]; if($f -lt 1){$f=1}
  $brk=$BR[$band]; $st=KStroke $k; $lat=EoLen $root; $E=[math]::Round($lat/$st,4); $D=$st
  $P=[math]::Round(-([math]::Log($f+1)+0.3*$E-0.1*$D),3)
  $null=$mAdd.Add($band+"`t"+$root+"`t"+$k)
  $null=$pAdd.Add([pscustomobject]@{root=$root;k=$k;band=$band;br=$brk;F=$f;st=$st;lat=$lat;E=$E;D=$D;P=$P})
  Write-Host ("追加: {0}→{1} band={2} F={3} P={4}" -f $root,$k,$band,$f,$P)
}
if($mAdd.Count -gt 0){ Add-Content "$dir\_kanji_map_master.tsv" -Value $mAdd -Encoding UTF8 }
if($pAdd.Count -gt 0){ $existing=Import-Csv "$dir\_p_work.csv" -Encoding UTF8; $all=@($existing)+@($pAdd); $all|Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation }
Write-Host ("master・_p_work 追記完了 ({0}件 / skip {1})" -f $mAdd.Count,$skip)

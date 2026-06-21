# 第8次救済: ユーザー裁定(2026-06-21)。CSV2890境界語2件を割当。
#  aŭtobus→车 : バス(=buso 车ᴮ と同系)。辞書は au^tobus を単一語根扱い→未対応だった。aŭt(车)は基本形のまま、aŭtobus は §9で一意id(车ᴬᴮ等)。
#  asfalt →沥青: アスファルト(=同物質 bitum 沥青ᴮ と同系)。CSV2890=basic のため §8優先順位で 沥青 の基本形になり peĉ→沥青ᴾ(優先順位通り。bitum=沥青ᴮ不変)。
# 両語とも CSV2890 語=band 'basic'。根は Unicode 格納(aŭt/aŭtomobil と統一)。F は h-system 形で辞書照合。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
function EoLen([string]$s){ $h=ToHsys $s; $n=0; for($i=0;$i -lt $h.Length;$i++){ if($i+1 -lt $h.Length -and $h[$i+1] -eq '^'){$i++}; $n++ }; $n }
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
# root, kanji, band
$resc=@( @('aŭtobus','车','basic'), @('asfalt','沥青','basic') )
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
# --- F(見出し数): 各根の h-system 形で辞書分節を完全一致照合 ---
$hmap=@{}; foreach($r in $resc){ $hmap[$r[0]]=(ToHsys $r[0]) }
$F=@{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci)
  $seen=@{}
  foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ foreach($r in $resc){ if($s -eq $hmap[$r[0]] -and -not $seen.ContainsKey($r[0])){ $seen[$r[0]]=$true; $F[$r[0]]=1+($F[$r[0]]) } } } }
}
# --- 既存重複チェック ---
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

# 第10次: 独立検証(2026-06-22)で検出した結合形/技術語ギャップを救済。ユーザー裁定「3件すべて適用」。
#  既存基底字を共有(R1同字共有 + R5同義系列を同基底字で統一):
#   aden→腺  (base gland=腺 の医学ギリシャ結合形 adeno-。aden/it腺炎・aden/o/pati腺症・limf/aden淋腺=リンパ節)
#   petr→岩  (base rok=岩 の地質同義 petro=rock。kalk/petr石灰岩・petr/ig岩化。petrol石油/petrosel パセリ/petromiz ヤツメ は別morpheme=衝突なし。Petr=ペテロ[proper・未対応]は大文字ガード)
#   trak→轨  (base rel=轨 の鉄道/空路同義 trako=track。trak/baz路盤・trak/larĝ軌間。trakt治療/管は末尾t別morpheme。trak/o=トラキア人は amb=支配義track に倒す。Trak/i/o地方は大文字ガード)
#  band: aden/petr=piv(内容は全て医学/地質PIV専)、trak=pejvo(【鉄】非PIV行に実出現)。
#  → 既存base(gland/rok/rel)は rank で保護され不変、新規のみ識別子付き(腺ᴬ/岩ᴾ/轨ᵀ 見込み)。
#  ★第1版の不具合是正: ①存在チェックを case-sensitive(Ordinal)化(大小無視Hashtableが Petr↔petr を誤認し petr を skip していた) ②F集計を ReadAllLines + -ceq で堅牢化(Get-Content経由で trak F=1 異常)。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
function EoLen([string]$s){ $h=ToHsys $s; $n=0; for($i=0;$i -lt $h.Length;$i++){ if($i+1 -lt $h.Length -and $h[$i+1] -eq '^'){$i++}; $n++ }; $n }
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
$resc=@( @('aden','腺','piv'), @('petr','岩','piv'), @('trak','轨','pejvo') )
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
$hmap=@{}; foreach($r in $resc){ $hmap[$r[0]]=(ToHsys $r[0]) }
# F = lowercase root を分節に含む見出し数(case-sensitive: 大文字始固有名 Aden/Petr/Trak を除外)
$F=@{}; foreach($r in $resc){ $F[$r[0]]=0 }
$dlines=[System.IO.File]::ReadAllLines($dict)
foreach($line in $dlines){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci)
  $seen=@{}
  foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ foreach($r in $resc){ $rt=$r[0]; if(($s -ceq $hmap[$rt]) -and (-not $seen.ContainsKey($rt))){ $seen[$rt]=$true; $F[$rt]=$F[$rt]+1 } } } }
}
# case-sensitive(Ordinal)存在チェック: Petr(固有名)↔petr(岩) を区別
$mRoots=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 2){ [void]$mRoots.Add($p[1].Trim()) } }
$pwHas=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
Import-Csv "$dir\_p_work.csv" -Encoding UTF8|ForEach-Object{ [void]$pwHas.Add($_.root) }
$mAdd=New-Object System.Collections.ArrayList; $pAdd=New-Object System.Collections.ArrayList; $skip=0
foreach($r in $resc){ $root=$r[0];$k=$r[1];$band=$r[2]
  if($mRoots.Contains($root) -or $pwHas.Contains($root)){ Write-Host ("skip(既存): $root"); $skip++; continue }
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

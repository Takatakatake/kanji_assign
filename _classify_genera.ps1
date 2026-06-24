# PIV尾部の未対応 単一形態素 生物属を §4.6(最近一级字)で分類 → _genera_classified.tsv(検証用)
# 方針: PIV語義は「G.(Genro)(名) de [カテゴリ複数形]…」と規則的。語義を左から走査し【最初に現れるカテゴリ語】の字を採用
#       (「fungoj parazitaj sur arboj」→ fungoj が先 → 菌。寄生先 arboj に化けない)。
# 解決できる限り: カテゴリ語が無い属は分類せず latin 据置(unclassified)。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$inj="$dir\漢字注入_学習者版_20260620.txt"
# カテゴリ語→一级字(正規表現, 字)。動物(具体的)を先に、植物を後に。各語は語幹一致(複数形oj/単数o/形容詞a を内包)。
# 各キーワードは【形態素語幹】。マッチは語幹+エス語尾の先読み (?=[oaeju]) を要求(下の $rx)。
# これで複合語(sufok+serpent+o=蛇・nokt+papili+o=蛾)を捕捉しつつ、「malgranda」内の alg(後続=r)等の偶然一致を排除。
# 位置最小=語義中で最初に現れるカテゴリ語の字を採用(「fungo... sur arbo」→菌が先)。
$cats=@(
  @('bird','鸟'), @('fis\^','鱼'), @('s\^ark','鱼'),
  @('serpent','蛇'), @('testud','龟'),
  @('lacert','龙'), @('reptili','龙'), @('amfibi','蛙'),
  @('simi','猴'), @('antilop','兽'), @('rong\^ul','鼠'), @('rabobest','兽'), @('mamul','兽'),
  @('krustac','虾'), @('arane','蛛'),
  @('cefalopod','贝'), @('gastropod','贝'), @('molusk','贝'),
  @('papili','虫'), @('insekt','虫'), @('verm','虫'), @('akar','虫'),
  @('alg','藻'),
  @('micet','菌'), @('fung','菌'), @('liken','菌'),
  @('musk','苔'),
  @('filik','草'), @('orkid','草'),
  @('arbed','木'), @('arbust','木'), @('arbet','木'), @('arb','木'),
  @('herb','草'), @('kresk','草'), @('plant','草'), @('flor','草'), @('vegeta','草')
)
$lines=[System.IO.File]::ReadAllLines($inj)
$out=New-Object System.Collections.ArrayList; [void]$out.Add("root`tk`tcat`tgloss")
$cnt=@{}; $unc=0; $tot=0
for($i=44104;$i -lt $lines.Count;$i++){
  $ln=$lines[$i]; $ci=$ln.IndexOf(':'); if($ci -lt 1){continue}
  $head=$ln.Substring(0,$ci); $gloss=$ln.Substring($ci+1)
  if($head.Contains('⟦')){continue}                       # 既に一部以上割当=対象外
  if($head -notmatch '^[a-z][a-z^]*/o$'){continue}        # 単一形態素 root/o のみ(小文字始)
  $mt=[regex]::Match($gloss,'【([^】]+)】')                 # 最初の【】タグ
  if(-not $mt.Success){continue}
  if(@('動','植','菌') -notcontains $mt.Groups[1].Value){continue}   # 1次義が生物(動/植/菌)の語のみ。【医】始まり等(adventic動脈外膜)の2次義汚染を除外
  $root=$head.Substring(0,$head.Length-2)                 # /o を除く
  $tot++
  # 最初に現れるカテゴリ語を採用(位置最小)
  $bestPos=[int]::MaxValue; $bestK=$null; $bestC=$null
  foreach($c in $cats){ $m=[regex]::Match($gloss,$c[0]+'(?=[oaeju])'); if($m.Success -and $m.Index -lt $bestPos){ $bestPos=$m.Index; $bestK=$c[0]; $bestC=$c[1] } }
  if($bestC){ [void]$out.Add($root+"`t"+$bestC+"`t"+$bestK+"`t"+($gloss.Substring(0,[Math]::Min(55,$gloss.Length)))); if(-not $cnt.ContainsKey($bestC)){$cnt[$bestC]=0}; $cnt[$bestC]++ }
  else { $unc++ }
}
[System.IO.File]::WriteAllLines("$dir\_genera_classified.tsv",$out,(New-Object System.Text.UTF8Encoding($false)))
Write-Host ("対象生物属(単一形態素) {0} / 分類済 {1} / 未分類(latin据置) {2}" -f $tot,($out.Count-1),$unc)
Write-Host "--- 字別内訳 ---"
$cnt.GetEnumerator()|Sort-Object Value -Descending|ForEach-Object{ "  {0} : {1}" -f $_.Key,$_.Value }
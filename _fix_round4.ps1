# 第4次検証(/goal ultracode・17次元WF敵対検証)で確証した master/_p_work 系の是正。
#  (A)元素救済漏れ23金属→金 + astaten→卤(astatine同義) (B)単字是正 bask 衣边→摆/kornic 杆→檐/raj 扁鱼→鱼/somnol 困→眠
#  (C)antiklinal→背斜 追加(sinklinal=向斜 対義ペア) (D)dio根正規化 "dio,Di"→"dio"(CSVセル内コンマ混入の識別子汚染是正)
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
function EoLen([string]$s){ $h=ToHsys $s; $n=0; for($i=0;$i -lt $h.Length;$i++){ if($i+1 -lt $h.Length -and $h[$i+1] -eq '^'){$i++}; $n++ }; $n }
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
function CalcP([string]$root,[string]$k,[int]$f){ $st=KStroke $k; $lat=EoLen $root; $E=[math]::Round($lat/$st,4); [pscustomobject]@{st=$st;E=$E;D=$st;P=[math]::Round(-([math]::Log($f+1)+0.3*$E-0.1*$st),3)} }
$dlines=[System.IO.File]::ReadAllLines($dict)
function CalcF([string]$root){ $rh=ToHsys $root; $f=0; foreach($line in $dlines){ $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci); $hit=$false; foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ if($s -ceq $rh){$hit=$true} } }; if($hit){$f++} }; if($f -lt 1){$f=1}; return $f }

# ---- (A)+(C) 追加(新規root): root,kanji,band ----
$metals=@('bari','americi','berkeli','ejns^tejni','fermi','lau^renci','mendelevi','neptuni','nobeli','protaktini','tekneci','disprozi','hafni','holmi','neodim','niob','prazeodim','prometi','reni','rodi','rubidi','terbi','tuli')
$adds=New-Object System.Collections.ArrayList
foreach($m in $metals){ [void]$adds.Add(@($m,'金','piv')) }
[void]$adds.Add(@('astaten','卤','piv'))      # astatine(=astato) 元素
[void]$adds.Add(@('antiklinal','背斜','piv'))  # 背斜(anticline)。sinklinal=向斜 と対義ペア

# ---- (B)+(D) 更新(既存root): root,newKanji(,newRoot) ----
$updates=@(
  @('bask','摆'),     # CSV典拠=下摆。1字優先(R1)・衝突歓迎(pendol=摆と共有)
  @('kornic','檐'),   # 軒蛇腹=檐口/挑檐(中心義)。杆は下位例カーテンレール由来
  @('raj','鱼'),      # エイ=軟骨魚。魚系列generic鱼に統一(扁鱼=ヒラメ系で誤分類)
  @('somnol','眠')    # 傾眠。困は日中乖離(日=困る/中=眠い)→眠(日中一致・dorm=睡系列)
)
$renameDio=@('dio,Di','dio')   # CSVセル内コンマ"dio,Dio"由来の不正root→正規化

$mp="$dir\_kanji_map_master.tsv"; $ml=Get-Content $mp -Encoding UTF8
$mExist=@{}; foreach($l in $ml){ $p=$l -split "`t"; if($p.Count -ge 2){ $mExist[$p[1]]=$true } }
$pw=Import-Csv "$dir\_p_work.csv" -Encoding UTF8
$pwExist=@{}; foreach($r in $pw){ $pwExist[$r.root]=$r }

# 追加(master): 既存skip
$mAdd=New-Object System.Collections.ArrayList; $pAdd=New-Object System.Collections.ArrayList
foreach($a in $adds){ $root=$a[0];$k=$a[1];$band=$a[2]
  if($mExist.ContainsKey($root) -or $pwExist.ContainsKey($root)){ Write-Host "skip(既存): $root"; continue }
  $f=CalcF $root; $c=CalcP $root $k $f
  [void]$mAdd.Add($band+"`t"+$root+"`t"+$k)
  [void]$pAdd.Add([pscustomobject]@{root=$root;k=$k;band=$band;br=$BR[$band];F=$f;st=$c.st;lat=(EoLen $root);E=$c.E;D=$c.D;P=$c.P})
  Write-Host ("追加: {0}→{1} band={2} F={3} P={4}" -f $root,$k,$band,$f,$c.P)
}
# 更新(master kanji + dio rename)
for($i=0;$i -lt $ml.Count;$i++){ $p=$ml[$i] -split "`t"; if($p.Count -lt 3){continue}; $type=$p[0];$root=$p[1];$k=$p[2]
  foreach($u in $updates){ if($root -ceq $u[0]){ $ml[$i]=$type+"`t"+$root+"`t"+$u[1]; Write-Host ("master更新: {0} {1}→{2}" -f $root,$k,$u[1]) } }
  if($root -ceq $renameDio[0]){ $ml[$i]=$type+"`t"+$renameDio[1]+"`t"+$k; Write-Host ("master rename: {0}→{1}" -f $renameDio[0],$renameDio[1]) }
}
if($mAdd.Count -gt 0){ $ml=@($ml)+@($mAdd) }
[System.IO.File]::WriteAllLines($mp,$ml,(New-Object System.Text.UTF8Encoding($false)))

# 更新(_p_work kanji+P + dio rename)
foreach($r in $pw){ foreach($u in $updates){ if($r.root -ceq $u[0]){ $c=CalcP $r.root $u[1] ([int]$r.F); $r.k=$u[1]; $r.st=$c.st; $r.E=$c.E; $r.D=$c.D; $r.P=$c.P; Write-Host ("_p_work更新: {0}→{1} P={2}" -f $r.root,$u[1],$c.P) } }
  if($r.root -ceq $renameDio[0]){ $r.root=$renameDio[1]; Write-Host ("_p_work rename dio") } }
$all=@($pw)+@($pAdd)
$all | Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation
Write-Host ("完了: master追加{0} / 更新{1} / _p_work {2}行" -f $mAdd.Count,$updates.Count,$all.Count)
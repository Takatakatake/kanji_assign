# 配置是正(2026-06-28・count=2深いworkflow+ユーザー承認): trimestr 季→期(move_one=季は消えずsezonに残存)。
#   trimestr(四半期/学期=3ヶ月の期間)は季節ではなく時間区分。形態的に semestr(se-mestr 6ヶ月=半期=期ˢ)の双子(tri-mestr 3ヶ月)。
#   季ᵀ(季=季節)は誤配置→期(時間区分hub: dat期/dum期ᴰᴹ/period期ᴾ/semestr期ˢ)へ移動し双子semestrと整合。§6aで期ᵀ等。
#   ※季はsezon(季節=雨季/四季/季語…多数のevocative専用字)が専有=温存(字は消えない=move_one)。
# _fold_orphan7.ps1 の機構を忠実踏襲: master の kanji列 + _p_work.csv の kanji依存列(k/st/E/D/P)を CalcP で同期更新。
# §9識別子(复ᴵᵀ等)は後段 _gas_identifier が自動付与。頭字衝突は§6aで自動解決。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
function EoLen([string]$s){ $n=0; for($i=0;$i -lt $s.Length;$i++){ if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){$i++}; $n++ }; $n }
$updates=@( ,@('trimestr','期') )   # 単一要素=単項コンマでフラット化防止
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
$allRoots=@{}; foreach($u in $updates){ $allRoots[$u[0]]=$true }
$F=@{}; $nonpiv=@{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci); $isPiv=$line -match '【PIV】'
  $seen=@{}
  foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ if($allRoots.ContainsKey($s) -and -not $seen.ContainsKey($s)){ $seen[$s]=$true; $F[$s]=1+($F[$s]); if(-not $isPiv){ $nonpiv[$s]=$true } } } }
}
function CalcP([string]$root,[string]$k){
  $f=[int]$F[$root]; if($f -lt 1){$f=1}
  $band= if($nonpiv.ContainsKey($root)){'pejvo'}else{'piv'}; $brk=$BR[$band]
  $st=KStroke $k; $lat=EoLen $root; $E=[math]::Round($lat/$st,4); $D=$st
  $P=[math]::Round(-([math]::Log($f+1)+0.3*$E-0.1*$D),3)
  return [pscustomobject]@{root=$root;k=$k;band=$band;br=$brk;F=$f;st=$st;lat=$lat;E=$E;D=$D;P=$P}
}
# ===== master の kanji列を更新(根一致で p[2]=newK) =====
$mLines=Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8
$mOut=New-Object System.Collections.ArrayList
foreach($l in $mLines){
  $p=$l -split "`t"; $changed=$false
  if($p.Count -ge 3){ foreach($u in $updates){ if($p[1].Trim() -eq $u[0]){ $p[2]=$u[1]; $changed=$true; Write-Host ("master: {0} → {1}" -f $u[0],$u[1]) } } }
  if($changed){ $null=$mOut.Add(($p -join "`t")) } else { $null=$mOut.Add($l) }
}
# ===== _p_work.csv の kanji依存列を CalcP で再計算 =====
$pw=Import-Csv "$dir\_p_work.csv" -Encoding UTF8
foreach($row in $pw){ foreach($u in $updates){ if($row.root -eq $u[0]){ $c=CalcP $u[0] $u[1]
  Write-Host ("p_work: {0}  k {1}→{2}  band {3}→{4}  P {5}→{6}" -f $u[0],$row.k,$c.k,$row.band,$c.band,$row.P,$c.P)
  $row.k=$c.k; $row.band=$c.band; $row.br=$c.br; $row.F=$c.F; $row.st=$c.st; $row.lat=$c.lat; $row.E=$c.E; $row.D=$c.D; $row.P=$c.P } } }
# 書き戻し: master は BOM無し / _p_work は Export-Csv
[System.IO.File]::WriteAllLines("$dir\_kanji_map_master.tsv",$mOut,(New-Object System.Text.UTF8Encoding($false)))
$pw | Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation
Write-Host ("完了: 是正{0}件 / master・_p_work 同期更新" -f $updates.Count)

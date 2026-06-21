# 第6次救済: 結合形フォルスフレンド是正(2026-06-21)。limf(リンパ·lymph)=淋を新規追加。limfat(lymphatic)=痰(誤·phlegm)→淋に是正(limfと統一)。
# fag(phago→吞)・tromb(thrombo→栓)は多義のため _build_homonym.ps1 の列挙sepで対応(masterのfag=树/tromb=龙卷は維持)。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
function EoLen([string]$s){ $n=0; for($i=0;$i -lt $s.Length;$i++){ if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){$i++}; $n++ }; $n }
$resc=@( ,@('limf','淋') )          # 新規追加(現在未対応)。単項コンマ=単一要素入れ子配列のフラット化防止(必須)
$updates=@( ,@('limfat','淋') )     # 既存是正: 痰→淋。同上
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
# 対象根の集合(F計算用)
$allRoots=@{}; foreach($r in $resc){ $allRoots[$r[0]]=$true }; foreach($u in $updates){ $allRoots[$u[0]]=$true }
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
# ===== (A) 既存是正: master + p_work の limfat 痰→淋 =====
$mLines=Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8
$mOut=New-Object System.Collections.ArrayList
foreach($l in $mLines){
  $p=$l -split "`t"; $changed=$false
  if($p.Count -ge 3){ foreach($u in $updates){ if($p[1].Trim() -eq $u[0]){ $p[2]=$u[1]; $changed=$true; Write-Host ("是正(master): {0} → {1}" -f $u[0],$u[1]) } } }
  if($changed){ $null=$mOut.Add(($p -join "`t")) } else { $null=$mOut.Add($l) }
}
$pw=Import-Csv "$dir\_p_work.csv" -Encoding UTF8
foreach($row in $pw){ foreach($u in $updates){ if($row.root -eq $u[0]){ $c=CalcP $u[0] $u[1]; $row.k=$c.k; $row.band=$c.band; $row.br=$c.br; $row.F=$c.F; $row.st=$c.st; $row.lat=$c.lat; $row.E=$c.E; $row.D=$c.D; $row.P=$c.P; Write-Host ("是正(p_work): {0} → {1} band={2} F={3} P={4}" -f $u[0],$u[1],$c.band,$c.F,$c.P) } } }
# ===== (B) 新規追加: limf =====
$mRoots=@{}; foreach($l in $mOut){ $p=$l -split "`t"; if($p.Count -ge 2){ $mRoots[$p[1].Trim()]=$true } }
$pwHas=@{}; foreach($row in $pw){ $pwHas[$row.root]=$true }
$pAdd=New-Object System.Collections.ArrayList; $skip=0
foreach($r in $resc){ $root=$r[0];$k=$r[1]
  if($mRoots.ContainsKey($root) -or $pwHas.ContainsKey($root)){ Write-Host ("skip(既存): $root"); $skip++; continue }
  $c=CalcP $root $k
  $null=$mOut.Add(($c.band+"`t"+$root+"`t"+$k))
  $null=$pAdd.Add([pscustomobject]@{root=$root;k=$k;band=$c.band;br=$c.br;F=$c.F;st=$c.st;lat=$c.lat;E=$c.E;D=$c.D;P=$c.P})
  Write-Host ("追加: {0}→{1} band={2} F={3} P={4}" -f $root,$k,$c.band,$c.F,$c.P)
}
# 書き戻し(UTF-8 BOM付き=PS5.1互換)
[System.IO.File]::WriteAllLines("$dir\_kanji_map_master.tsv",$mOut,(New-Object System.Text.UTF8Encoding($true)))
$allPw=@($pw)+@($pAdd); $allPw|Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation
Write-Host ("master・p_work 更新完了 (新規{0}件 / 是正{1}件 / skip {2})" -f $pAdd.Count,$updates.Count,$skip)

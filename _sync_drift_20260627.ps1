# WSL上流ドリフト吸収(2026-06-27): 上流が3見出しの分解を精緻化。
#   galvaniz/i → galvan/iz/i      (分割: 既存 galvan=电ᴳ + iz=化 で自動透明化。旧 galvaniz は未対応だった→ギャップ解消)
#   eh^/o/lokal/iz/i(/il/o) → eh^/o/lokaliz/i(/il/o)  (統合: lokaliz を1形態素化。標準 lokaliz/i と整合)
# 対応: (1)PROJ辞書を WSL とバイト一致でコピー(drift=0化)。(2)新root lokaliz→位 を master+_p_work へ追加
#   (位=位置系列 pozici位ᴾ/situ位/bit位ᴮ/apozici位ᴬ に合流。§6a で自動弁別。回/o/位=echo-locate)。
# master は BOM無し厳守(現状 first3=99 111 114)。_add_rescue6.ps1 の追加機構を踏襲。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$wsl='\\wsl.localhost\Ubuntu\home\y\エスペラント辞書徹底語根分解_20260619'
$src="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026"
$names=@('世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt','世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt')
# ===== (1) 辞書同期: WSL → PROJ (バイト一致) =====
foreach($n in $names){
  $w=Join-Path $wsl $n; $p=Join-Path $src $n
  Copy-Item -LiteralPath $w -Destination $p -Force
  $wl=(Get-Item -LiteralPath $w).Length; $pl=(Get-Item -LiteralPath $p).Length
  Write-Host ("同期: {0}  WSL={1} PROJ={2} {3}" -f $n.Substring(0,4),$wl,$pl,$(if($wl -eq $pl){'OK(一致)'}else{'不一致!'}))
}
# ===== (2) 新root lokaliz→位 を追加 =====
$dict="$src\$($names[0])"
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
function EoLen([string]$s){ $n=0; for($i=0;$i -lt $s.Length;$i++){ if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){$i++}; $n++ }; $n }
$resc=@( ,@('lokaliz','位') )   # 単項コンマ=単一要素入れ子配列フラット化防止
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
$allRoots=@{}; foreach($r in $resc){ $allRoots[$r[0]]=$true }
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
$mLines=Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8
$mOut=New-Object System.Collections.ArrayList; foreach($l in $mLines){ $null=$mOut.Add($l) }
$mRoots=@{}; foreach($l in $mOut){ $p=$l -split "`t"; if($p.Count -ge 2){ $mRoots[$p[1].Trim()]=$true } }
$pw=Import-Csv "$dir\_p_work.csv" -Encoding UTF8
$pwHas=@{}; foreach($row in $pw){ $pwHas[$row.root]=$true }
$pAdd=New-Object System.Collections.ArrayList; $skip=0
foreach($r in $resc){ $root=$r[0];$k=$r[1]
  if($mRoots.ContainsKey($root) -or $pwHas.ContainsKey($root)){ Write-Host ("skip(既存): $root"); $skip++; continue }
  $c=CalcP $root $k
  $null=$mOut.Add($c.band+"`t"+$root+"`t"+$k)
  $null=$pAdd.Add([pscustomobject]@{root=$root;k=$k;band=$c.band;br=$c.br;F=$c.F;st=$c.st;lat=$c.lat;E=$c.E;D=$c.D;P=$c.P})
  Write-Host ("追加: {0}→{1} band={2} F={3} st={4} P={5}" -f $root,$k,$c.band,$c.F,$c.st,$c.P)
}
# master は BOM無し(現状維持) / _p_work は Export-Csv
[System.IO.File]::WriteAllLines("$dir\_kanji_map_master.tsv",$mOut,(New-Object System.Text.UTF8Encoding($false)))
$allPw=@($pw)+@($pAdd); $allPw|Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation
Write-Host ("完了: 辞書同期2 + lokaliz追加{0}件(skip {1})" -f $pAdd.Count,$skip)

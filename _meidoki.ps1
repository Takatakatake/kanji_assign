# 迷いどころ抽出: 二级字使用 / 3字以上 / content2字 を、辞書グロス付きで列挙。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"

# 一级集合
$ichi=New-Object System.Collections.Generic.HashSet[string]
Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object{
  $c=($_ -split "`t")[1]; if($c){ [void]$ichi.Add($c) } }

# 辞書グロス: root(先頭/まで) -> 最初のgloss
$gl=@{}
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
Get-Content $dict -Encoding UTF8 | ForEach-Object{
  $ci=$_.IndexOf(':'); if($ci -lt 1){return}
  $head=$_.Substring(0,$ci); $g=$_.Substring($ci+1)
  $r=($head -split '/')[0]
  $rh=ToHsys $r
  if(-not $gl.ContainsKey($rh)){ $gl[$rh]=$g }
}

# master読み込み
$rows=Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object{
  $p=$_ -split "`t"; if($p.Count -lt 3){return}
  if($p[2] -eq '未対応'){return}
  [pscustomobject]@{band=$p[0];root=$p[1];kanji=$p[2]}
}

function HasErji([string]$k){
  foreach($ch in $k.ToCharArray()){
    $cs=[string]$ch
    # 識別子上付き・ラテン母音・記号はスキップ
    if($cs -match '[a-zA-Z0-9oaeiu]'){continue}
    if([int][char]$cs -lt 0x3000){continue}
    if(-not $ichi.Contains($cs)){ return $true }
  }
  return $false
}
function KanjiLen([string]$k){
  $n=0; foreach($ch in $k.ToCharArray()){ if([int][char]$ch -ge 0x4E00){$n++} }; return $n
}

Write-Host "=== [C1] 二级(非一级)字を含む割当 ==="
$c1=$rows | Where-Object{ HasErji $_.kanji }
Write-Host ("該当 {0} 件" -f $c1.Count)
$c1 | Where-Object{$_.band -eq 'content'} | Select-Object -First 60 | ForEach-Object{
  $g=$gl[$_.root]; if(-not $g){$g='(grーなし)'}
  if($g.Length -gt 42){$g=$g.Substring(0,42)}
  "{0,-16}{1,-8}{2}" -f $_.root,$_.kanji,$g
}

Write-Host ""
Write-Host "=== [C2] 漢字3字以上の割当 ==="
$c2=$rows | Where-Object{ (KanjiLen $_.kanji) -ge 3 }
Write-Host ("該当 {0} 件" -f $c2.Count)
$c2 | Select-Object -First 60 | ForEach-Object{
  $g=$gl[$_.root]; if(-not $g){$g='(grーなし)'}
  if($g.Length -gt 42){$g=$g.Substring(0,42)}
  "{0,-16}{1,-10}{2}" -f $_.root,$_.kanji,$g
}

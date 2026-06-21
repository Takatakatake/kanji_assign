# 衝突グループ(同字共有)を各語根の語義付きで出力 → 一貫性監査用
# 「同概念の散らばり(別字の同義語)」「取り違え(グループ内の異質語根)」を人/LLMが判定するための材料
param([int]$MinGroup = 3)
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
$dict = "$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){
  $s = $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^'
  return $s
}
# master(漢字割当のみ)
$assign = New-Object System.Collections.ArrayList
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object {
  $p = $_ -split "`t"
  if($p.Count -ge 3){ $t=$p[0].Trim(); $k=$p[1].Trim(); $v=$p[2].Trim()
    if($v -and $v -ne '未対応'){ $null=$assign.Add([pscustomobject]@{type=$t; root=$k; hsys=(ToHsys $k); kanji=$v; gloss=''}) } }
}
# 語義: dict から代表見出し(その語根が主役の見出し優先)
$endingRe='^(o|a|e|i|u|oj|aj|ojn|ajn|as|is|os|us|u|j|n)$'
$gl=@{}; $sc=@{}
Get-Content $dict -Encoding UTF8 | ForEach-Object {
  $ci=$_.IndexOf(':'); if($ci -lt 1){ return }
  $head=$_.Substring(0,$ci); $g=$_.Substring($ci+1) -replace '^\{[^}]*\}',''
  foreach($w in ($head -split ' ')){
    $segs=@($w -split '/'); $cs=@($segs | Where-Object { $_ -notmatch $endingRe })
    foreach($s in $segs){ if($s -match $endingRe){ continue }
      $score=$cs.Count
      if(-not $sc.ContainsKey($s) -or $score -lt $sc[$s]){ $sc[$s]=$score; $t=$g.Trim(); if($t.Length -gt 40){$t=$t.Substring(0,40)}; $gl[$s]=$t } }
  }
}
foreach($a in $assign){ if($gl.ContainsKey($a.hsys)){ $a.gloss=$gl[$a.hsys] } }
# group
$grp=@{}; foreach($a in $assign){ if(-not $grp.ContainsKey($a.kanji)){ $grp[$a.kanji]=New-Object System.Collections.ArrayList }; $null=$grp[$a.kanji].Add($a) }
$big=@($grp.GetEnumerator() | Where-Object { $_.Value.Count -ge $MinGroup } | Sort-Object { $_.Value.Count } -Descending)
# 出力
$out=New-Object System.Collections.Generic.List[string]
$out.Add("# 過剰共有 一貫性監査材料 (グループ>=$MinGroup) 2026-06-14")
$out.Add("")
foreach($e in $big){
  $out.Add("## $($e.Key)  ×$($e.Value.Count)")
  foreach($m in ($e.Value | Sort-Object root)){ $out.Add("- " + $m.root + " = " + $m.kanji + "  「" + $m.gloss + "」") }
  $out.Add("")
}
Set-Content -Path "$dir\_overload_audit_material.md" -Value $out -Encoding UTF8
Write-Host "グループ>=$MinGroup : $($big.Count) 件 / 出力 _overload_audit_material.md"
Write-Host "=== サイズ上位20(語根のみ) ==="
$big | Select-Object -First 20 | ForEach-Object { "{0} ×{1}: {2}" -f $_.Key, $_.Value.Count, (($_.Value | ForEach-Object { $_.root }) -join ',') }
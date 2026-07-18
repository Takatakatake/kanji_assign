# bare contextual alias 台帳を _inject_final.ps1 から自動抽出 → _bare_alias_ledger.tsv
# 注入層で「識別子を付さない bare 漢字」を直接出力する定義/語釈/文脈gated override を悉皆列挙する。
# これらは §9 の識別子ベース reverse復号(字→語根)の対象外(forward-only/lossy 例外)。手書き列挙は誤りを生む
# (2026-07-18 監査で「15字」過小記述が判明)ため、実装(_inject_final.ps1)を単一の正典として機械抽出する。
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
$src=Get-Content "$dir\_inject_final.ps1" -Encoding UTF8
$cjk='[一-鿿々]'
$rows=New-Object System.Collections.ArrayList
$hdr="root`ttoken`tline`tkind`tgate"
# ① $alkylStem ハッシュ(アルキル語幹→天干): 化学タグ$isSysChem+アルキル語幹隣接ゲート(line 122)
for($i=0;$i -lt $src.Count;$i++){
  if($src[$i] -match '^\$alkylStem\s*=\s*@\{'){
    foreach($m in [regex]::Matches($src[$i],"'(\w+)'\s*=\s*'($cjk)'")){
      [void]$rows.Add("$($m.Groups[1].Value)`t$($m.Groups[2].Value)`t$($i+1)`talkyl`t\$isSysChem+アルキル語幹隣接(甲乙丙基システム)")
    }
  }
}
# ② elseif(($s -eq 'ROOT') ...){ $tok='漢字'; $thisMapped=$true } の直接bare出力ルール
for($i=0;$i -lt $src.Count;$i++){
  $line=$src[$i]
  $mt=[regex]::Match($line,"\`$tok='($cjk+)'\s*;\s*\`$thisMapped=\`$true")
  if(-not $mt.Success){ continue }
  $token=$mt.Groups[1].Value
  $mr=[regex]::Match($line,"\`$s\s*-eq\s*'([^']+)'")
  if(-not $mr.Success){ continue }
  $root=$mr.Groups[1].Value
  # ゲート要約(条件部の先頭〜$tok直前を圧縮)
  $gate=''
  $gm=[regex]::Match($line,'elseif\((.*?)\)\{\s*\$tok')
  if($gm.Success){ $gate=($gm.Groups[1].Value -replace '\s+',' ') ; if($gate.Length -gt 70){$gate=$gate.Substring(0,70)+'…'} }
  [void]$rows.Add("$root`t$token`t$($i+1)`tword-scoped`t$gate")
}
$out=@($hdr)+@($rows)
[System.IO.File]::WriteAllLines("$dir\_bare_alias_ledger.tsv",$out,(New-Object System.Text.UTF8Encoding($false)))
$tok=@{}; foreach($r in $rows){ $t=($r -split "`t")[1]; $tok[$t]=$true }
Write-Host ("bare alias台帳: root→token対 "+$rows.Count+" / 異なりtoken "+$tok.Count+" → _bare_alias_ledger.tsv")
Write-Host ("tokens: "+(($tok.Keys | Sort-Object) -join ''))

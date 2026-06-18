# 最終本番注入: 辞書の各見出しに disp(漢字+§9識別子)を注入。homonym(sep見出し/amb語義)・privative=无ᴬ・en・連結母o省略。原本diff=0検証。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$outp="$dir\漢字注入_最終プレビュー_20260619.txt"
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^' }
# --- sidecar disp(主義) ---
$disp=@{}; Import-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -Delimiter "`t" | ForEach-Object { $disp[(ToHsys $_.root)]=$_.disp }
# --- homonym台帳(disp付き) ---
$hsep=@{}; $hamb=@{}
Get-Content "$dir\_homonym_disp.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
  $p=$_ -split "`t"; if($p.Count -lt 5){return}; $seg=$p[0];$type=$p[1];$disc=$p[2];$d=$p[4]
  if($type -eq 'sep'){ foreach($hw in ($disc -split ',')){ $hw=$hw.Trim(); if(-not $hw){continue}; if(-not $hsep.ContainsKey($hw)){$hsep[$hw]=@{}}; $hsep[$hw][$seg]=$d } }
  else { if(-not $hamb.ContainsKey($seg)){$hamb[$seg]=New-Object System.Collections.ArrayList}; [void]$hamb[$seg].Add(@{key=$disc;disp=$d}) }
}
$privDisp = "无$([char]0x1D2C)"   # privative a-/an- = 无ᴬ
$enDisp = if($disp.ContainsKey('en')){$disp['en']}else{'内'}
$endingRe = '^(o|a|e|i|u|oj|aj|on|an|ojn|ajn|en|as|is|os|us|u|j|n)$'

$lines = Get-Content $dict -Encoding UTF8
$out = New-Object System.Collections.Generic.List[string]
$tot=0;$inj=0;$segTot=0;$segMap=0;$hsepN=0;$hambN=0;$privN=0
foreach($line in $lines){
  $tot++
  $ci=$line.IndexOf(':'); if($ci -lt 1){ $out.Add($line); continue }
  $head=$line.Substring(0,$ci); $rest=$line.Substring($ci); $gl=$line.Substring($ci+1)
  $words=$head -split ' '; $anyMapped=$false
  $kwords = foreach($w in $words){
    $segs=@($w -split '/'); $nseg=$segs.Count
    $laterContent=$false; for($j=1;$j -lt $nseg;$j++){ if($segs[$j] -notmatch $endingRe){ $laterContent=$true; break } }
    $parts=New-Object System.Collections.Generic.List[string]; $mergeNext=$false; $prevMapped=$false
    for($idx=0;$idx -lt $nseg;$idx++){
      $s=$segs[$idx]
      if($s -eq 'o' -and $idx -gt 0 -and ($idx+1 -lt $nseg) -and $prevMapped -and $disp.ContainsKey($segs[$idx+1])){ $mergeNext=$true; continue }  # 連結母o省略
      $tok=$null; $thisMapped=$false
      if($hsep.ContainsKey($w) -and $hsep[$w].ContainsKey($s)){ $tok=$hsep[$w][$s]; $thisMapped=$true; $hsepN++ }                       # homonym sep(見出し)
      elseif($hamb.ContainsKey($s) -and (@($hamb[$s]|Where-Object{ $gl -like ("*"+$_.key+"*") }).Count -gt 0)){ $tok=(@($hamb[$s]|Where-Object{ $gl -like ("*"+$_.key+"*") })[0].disp); $thisMapped=$true; $hambN++ }  # homonym amb(語義)
      elseif($idx -eq 0 -and ($s -eq 'a' -or $s -eq 'an') -and $laterContent){ $tok=$privDisp; $thisMapped=$true; $privN++ }            # privative
      elseif($s -eq 'en'){ if($idx -eq 0){ $tok=$enDisp; $thisMapped=$true } else { $tok=$s } }                                          # en位置判定
      elseif($s -match $endingRe){ $tok=$s }                                                                                              # 文法語尾
      elseif($disp.ContainsKey($s)){ $tok=$disp[$s]; $thisMapped=$true }                                                                 # 主義disp
      else { $tok=$s }                                                                                                                    # 未マップ
      if($thisMapped){ $anyMapped=$true }
      if($s -notmatch $endingRe -and -not ($s -eq 'o' -and $mergeNext)){ $segTot++; if($thisMapped){$segMap++} }
      if($mergeNext -and $parts.Count -gt 0){ $parts[$parts.Count-1]=$parts[$parts.Count-1]+$tok; $mergeNext=$false } else { $parts.Add($tok) }
      $prevMapped=$thisMapped
    }
    ($parts -join '/')
  }
  if($anyMapped){ $inj++; $out.Add("$head⟦$($kwords -join ' ')⟧$rest") } else { $out.Add($line) }
}
[System.IO.File]::WriteAllLines($outp,$out,(New-Object System.Text.UTF8Encoding($true)))
# --- 原本diff=0検証 ---
$diff=0; for($i=0;$i -lt $lines.Count;$i++){ $st=$out[$i] -replace '⟦[^⟧]*⟧',''; if($st -ne $lines[$i]){ $diff++ } }
Write-Host ("総行{0} / 注入行{1} / contentセグ被覆 {2}/{3}={4:P1}" -f $tot,$inj,$segMap,$segTot,($segMap/[double]$segTot))
Write-Host ("homonym適用: sep {0} / amb {1} / privative {2}" -f $hsepN,$hambN,$privN)
Write-Host ("原本diff: {0} {1}" -f $diff,$(if($diff -eq 0){'(不可侵PASS)'}else{'(要調査!)'}))
Write-Host "出力: $outp"
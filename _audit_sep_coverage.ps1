# sep派生形網羅性 検出器(critic #1・2026-06-23)
# 各 sep/comb 分節について、注入の全 word で「その分節が何の漢字に化けたか」を集計。
# 同一分節が2種以上の base漢字(識別子除去)に割れていたら、sep字でない方=「base default に落ちた候補」を列挙。
# combining-form が同綴の内容語字(base)に化けた取りこぼし(oz/cit/trik型)を悉皆検出する。
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
# 上付き識別子を除去して base漢字を取り出す
$supChars=@(); 0x1D2C..0x1D6A|ForEach-Object{$supChars+=[char]$_}; $supChars+=[char]0x02E2; $supChars+=[char]0x2C7D; $supChars+=[char]0x1DBB; $supChars+=[char]0x0302; $supChars+=[char]0x0306
function BaseKanji([string]$tok){ $o=''; foreach($ch in $tok.ToCharArray()){ if($supChars -notcontains $ch){ $o+=$ch } }; return $o }
# 監視対象 = _homonym.tsv の sep/comb 分節(amb除く。ampは同綴で別処理)
$watch=@{}
Get-Content "$dir\_homonym.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object{
  $p=$_ -split "`t"; if($p.Count -lt 4){return}; $seg=$p[0];$ov=$p[1];$type=$p[2]
  if($type -eq 'sep' -or $type -eq 'comb'){ if(-not $watch.ContainsKey($seg)){$watch[$seg]=@{}}; $watch[$seg][$ov]=$true } }
# 注入を走査し、各監視分節→{base漢字: [word...]} を集計。両版(学習者+学術)を対象(版差の取りこぼしも検出)。
$injFile = if($args.Count -ge 1 -and $args[0]){ $args[0] } else { '漢字注入_学習者版_20260620.txt' }
Write-Host ("=== 走査対象: {0} ===" -f $injFile)
$segChar=@{}  # seg -> hashtable(baseKanji -> List<word>)
$inj=[System.IO.File]::ReadAllLines("$dir\$injFile")
foreach($line in $inj){
  $m=[regex]::Match($line,'^([^:]+?)⟦([^⟧]*)⟧'); if(-not $m.Success){continue}
  $hwords=$m.Groups[1].Value -split ' '; $iwords=$m.Groups[2].Value -split ' '
  for($wi=0;$wi -lt $hwords.Count -and $wi -lt $iwords.Count;$wi++){
    $segs=$hwords[$wi] -split '/'; $toks=$iwords[$wi] -split '/'
    for($si=0;$si -lt $segs.Count -and $si -lt $toks.Count;$si++){
      $s=$segs[$si]; if(-not $watch.ContainsKey($s)){continue}
      $bk=BaseKanji $toks[$si]
      if($bk -eq $s){continue}   # ラテン残存(漢字化されず)=対象外
      if(-not $segChar.ContainsKey($s)){$segChar[$s]=@{}}
      if(-not $segChar[$s].ContainsKey($bk)){$segChar[$s][$bk]=New-Object System.Collections.ArrayList}
      [void]$segChar[$s][$bk].Add($hwords[$wi])
    } } }
# 報告: 分節が sep字 以外の漢字にも化けている場合、その非sep字(=base default候補)を列挙
$flagN=0
foreach($s in ($segChar.Keys|Sort-Object)){
  $chars=@($segChar[$s].Keys)
  $sepChars=@($watch[$s].Keys)
  # sep字でない漢字に化けた word(=取りこぼし候補)
  $nonSep=@($chars|Where-Object{ $sepChars -notcontains $_ })
  if($nonSep.Count -ge 1 -and $chars.Count -ge 2){
    foreach($nc in $nonSep){
      $words=@($segChar[$s][$nc]|Select-Object -Unique)
      Write-Host ("[{0}] sep字={1} / base字に化けた『{2}』: {3}件 → {4}" -f $s,($sepChars -join ''),$nc,$words.Count,(($words|Select-Object -First 6) -join ', '))
      $flagN++
    } } }
Write-Host ("--- 監視分節 {0} / base分岐フラグ {1} ---" -f $watch.Count,$flagN)

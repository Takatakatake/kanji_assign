# 逆転群の期待基本形assertion(2026-07-16 第10回監査で新設・2026-07-17 出力活性検査を追加)。
# PEJVO→PIV実効逆転群(方針書§14・ユーザー裁定=現状維持)の基本形(無印)が sidecar 上で期待どおりか検査(churn検出=fail)。
# さらに各群が【実注入出力】に現れるかで活性判定: 原本更新で語根が消える/融合形が分解され群漢字が
# 出力に出なくなると「非活性(逆転でない)」→advisory警告(§14更新の合図)。sidecarはオーファン割当を
# 残すため(fototip/fototipi=原本が fot/o/tip 分解でオーファン化)、活性判定は出力を正とする。
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
# 群漢字 => @(基本形, partner語根...)
$groups=[ordered]@{
  '蛾'=@('mote','bombiks'); '气学家'=@('aerolog','meteolog'); '气学'=@('aerologi','meteologi')
  '气计'=@('gasmetr','aerometr','gasometr'); '高计'=@('altimetr','altometr','hipsometr'); '高测'=@('altometri','hipsometri')
  '脉炎'=@('flebit','vejnit'); '菌学'=@('mikologi','bakteriologi'); '苔植'=@('brifit','briofit')
  '胚源'=@('embrigenez','embriogenez'); '拍型'=@('fototip','fototipi'); '胃炎'=@('gastrit','stomakit')
  '乐主义'=@('hedonism','optimism'); '乐家'=@('hedonist','optimist'); '肠炎'=@('ileit','enterit')
  '色计'=@('kolormetr','kolorometr'); '神经学'=@('nervologi','neu^rologi'); '振具'=@('vibrator','oscilator')
  '渗计'=@('osmozmetr','osmozometr'); '速计'=@('takimetr','rapidometr')
}
# sidecar: groupkey別の無印基本形
$bases=@{}
Get-Content "$dir\_identifier_sidecar.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
  $p=$_ -split "`t" | ForEach-Object { $_.Trim('"') }
  if($p.Count -ge 8 -and $p[2] -eq '' -and $groups.Contains($p[7]) -and -not $bases.ContainsKey($p[7])){ $bases[$p[7]]=$p[0] }
}
# 注入出力(学術版=融合語根を保つ側)の ⟦⟧ 内 識別子除去済みセグメント集合(=実際に描画された disp)。
# 逆転群(aerolog気学家/gasmetr气计 等)は学習者版では aer/o/log と分解され群dispが出ないため、
# 融合形を保つ学術版で活性判定する(mote蛾 等の単一語根は両版で描画)。
$baseSet=New-Object 'System.Collections.Generic.HashSet[string]'      # 無印で描画された disp(=基本形side)
$partnerSet=New-Object 'System.Collections.Generic.HashSet[string]'   # 識別子付きで描画された disp基底(=partner side)
$comb=[regex]'[ʰ-˿̀-ͯᴬ-ᶿ⁰-₟]'
foreach($ln in [System.IO.File]::ReadAllLines("$dir\漢字注入_学術版_20260620.txt")){
  $lb=$ln.IndexOf([char]0x27E6); if($lb -lt 0){continue}; $rb=$ln.IndexOf([char]0x27E7,$lb); if($rb -lt 0){continue}
  foreach($seg in ($ln.Substring($lb+1,$rb-$lb-1) -split '[ /\-]')){
    if(-not $seg){continue}
    $stripped=$comb.Replace($seg,'')
    if($seg -eq $stripped){ [void]$baseSet.Add($stripped) } else { [void]$partnerSet.Add($stripped) }   # 識別子の有無で base/partner を弁別
  }
}
$bad=New-Object System.Collections.ArrayList; $warn=New-Object System.Collections.ArrayList
$activeGroups=0; $activeRoots=0
foreach($k in $groups.Keys){
  $expBase=$groups[$k][0]
  # 真の逆転群=基本形(無印)と 識別子付きpartner が【両方】描画されている(片方のみ=退化群)
  $active = ($baseSet.Contains($k) -and $partnerSet.Contains($k))
  if($active){
    $activeGroups++; $activeRoots++
    $cur=$bases[$k]
    if($cur -ne $expBase){ [void]$bad.Add(("{0}`t期待基本形={1}`t現行={2}" -f $k,$expBase,($(if($cur){$cur}else{'(基本形なし)'})))) }
  } else {
    $why = if(-not $baseSet.Contains($k)){ '基本形side未描画' } else { 'partner(識別子付き)未描画=退化群' }
    [void]$warn.Add(("{0}(基本形{1})=非活性({2})" -f $k,$expBase,$why))
  }
}
Write-Host ("[H] 逆転群assertion: 基本形不一致={0}(0が正=churn無) / 非活性群={1}(advisory) / 活性群={2}" -f $bad.Count,$warn.Count,$activeGroups)
$bad  | ForEach-Object { Write-Host ("    !!基本形変動 "+$_) }
$warn | ForEach-Object { Write-Host ("    ~非活性 "+$_+" (§14の逆転群一覧を更新)") }
if($bad.Count -gt 0){ exit 1 } else { exit 0 }

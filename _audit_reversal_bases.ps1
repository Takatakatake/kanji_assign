# 逆転20群の期待基本形assertion(2026-07-16 第10回監査で新設)。
# PEJVO→PIV実効逆転20群(方針書§14 2026-07-16 第9〜10回監査項・ユーザー裁定=現状維持)の
# 基本形(無印)が sidecar 上で期待どおりか検査。P=5同士は入力順や新規短語根で
# 再生成時に基本形が入れ替わりうるため、変動したら即検出する(_verify_all [H]で fail 化)。
# 期待値を変える時は §14 の裁定記録を先に更新すること(裁定なき変動=回帰)。
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
$expected=[ordered]@{
  '蛾'='mote'; '气学家'='aerolog'; '气学'='aerologi'; '气计'='gasmetr'; '高计'='altimetr'
  '高测'='altometri'; '脉炎'='flebit'; '菌学'='mikologi'; '苔植'='brifit'; '胚源'='embrigenez'
  '拍型'='fototip'; '胃炎'='gastrit'; '乐主义'='hedonism'; '乐家'='hedonist'; '肠炎'='ileit'
  '色计'='kolormetr'; '神经学'='nervologi'; '振具'='vibrator'; '渗计'='osmozmetr'; '速计'='takimetr'
}
$bases=@{}
Get-Content "$dir\_identifier_sidecar.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
  $p=$_ -split "`t" | ForEach-Object { $_.Trim('"') }
  if($p.Count -ge 8 -and $p[2] -eq '' -and $expected.Contains($p[7]) -and -not $bases.ContainsKey($p[7])){ $bases[$p[7]]=$p[0] }
}
$bad=New-Object System.Collections.ArrayList
foreach($k in $expected.Keys){
  $cur=$bases[$k]
  if($cur -ne $expected[$k]){ [void]$bad.Add(("{0}`t期待={1}`t現行={2}" -f $k,$expected[$k],($(if($cur){$cur}else{'(基本形なし/群消失)'})))) }
}
Write-Host ("[H] 逆転20群 期待基本形assertion: 不一致={0}(0が正。P=5同士は再生成で動きうるため裁定=現状維持を固定監視)" -f $bad.Count)
$bad | ForEach-Object { Write-Host ("    "+$_) }
if($bad.Count -gt 0){ exit 1 } else { exit 0 }

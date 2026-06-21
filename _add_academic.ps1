# 学術・科学結合形 + 派生接尾辞の curated 割当(頻度上位の確信できるもの)
# 固有名詞/国名は未対応(§91)へ。曖昧な内容語根は本スクリプトでは扱わず後の検証バッチへ。
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
$mp = "$dir\_kanji_map_master.tsv"

# type, key(Unicode), kanji, 根拠
$rows = @(
 # --- 派生接尾辞(生産的) ---
 @('suf','iz','化','-iz- 加工・変化(-ize)'),
 @('suf','oz','富','-oz- 豊富(-ous/-ose)'),
 @('suf','iv','能','-iv- 能力・傾向(-ive)'),
 @('suf','oid','似','-oid 類似(-oid)'),
 # --- 医学・科学接尾辞 ---
 @('suf','emi','血','-emia 血液状態'),
 @('suf','tomi','切','-tomy 切開'),
 @('suf','ektomi','除','-ectomy 摘出'),
 @('suf','algi','痛','-algia 痛み'),
 @('suf','estez','感','-esthesia 感覚'),
 @('suf','liz','解','-lysis 分解・溶解'),
 @('suf','nomi','学','-nomy 学問分野'),
 @('suf','pati','情','-pathy 感情・病'),
 # --- 学術結合形(語根) ---
 @('sci','graf','记','-graph 記録(homonym graf=伯爵は後送り)'),
 @('sci','grafi','志','-graphy 記述・誌'),
 @('sci','skop','镜','-scope 観察器'),
 @('sci','metri','测','-metry 計測'),
 @('sci','terapi','疗','therapy 療法'),
 @('sci','gen','生','-gen 生成・遺伝子'),
 @('sci','genez','源','genesis 起源'),
 @('sci','morf','形','morph 形態'),
 # --- 元素・化学結合形 ---
 @('sci','oksi','氧','oxygen 酸素'),
 @('sci','oksid','氧化','oxide 酸化物'),
 @('sci','klor','氯','chlorine 塩素'),
 @('sci','sulf','硫','sulfur 硫黄'),
 @('sci','nitr','氮','nitrogen 窒素'),
 # --- 接頭(学術) ---
 @('pref','hidr','水','hydro 水'),
 @('pref','tele','远','tele 遠'),
 @('pref','mikro','微','micro 微'),
 @('pref','anti','抗','anti 対抗'),
 @('pref','retro','逆','retro 逆行'),
 @('pref','poli','多','poly 多'),
 @('pref','mono','单','mono 単一'),
 @('pref','izo','等','iso 等しい'),
 @('pref','hipo','亚','hypo 下位'),
 @('pref','hiper','超','hyper 超過'),
 @('pref','epi','表','epi 表層・上'),
 @('pref','endo','内','endo 内部'),
 @('pref','pseŭdo','伪','pseudo 偽'),
 # --- 解剖・生物 ---
 @('sci','pod','足','-pod 足'),
 @('sci','pter','翅','-pter 翅'),
 @('sci','derm','皮','derm 皮膚'),
 @('sci','gastr','胃','gastro 胃'),
 @('sci','kardi','心','cardio 心臓'),
 @('sci','neŭr','神经','nerve 神経'),
 # --- その他 明確な科学・専門 ---
 @('sci','toks','毒','toxic 毒'),
 @('sci','inflam','炎','inflammation 炎症'),
 @('sci','polus','极','pole 極'),
 @('sci','polar','极','polar 極性'),
 @('sci','frekvenc','频','frequency 頻度'),
 @('sci','kondukt','导','conduction 伝導'),
 @('sci','kontinu','续','continuous 連続'),
 @('sci','sekc','切','section 切断'),
 @('sci','trab','梁','beam 梁'),
 @('sci','kanon','炮','cannon 砲'),
 @('sci','bio','生','bio 生命'),
 @('sci','fibr','纤','fiber 繊維'),
 @('sci','polu','污','pollution 汚染'),
 @('sci','edr','面','-hedron 面'),
 @('sci','ras','种','race 人種')
)
# 固有名詞/国名 → 未対応(§91)
$proper = @('ĉin','german','rus','angl','eŭrop','Petr','esperant')

# 既存キー & 一级
$existing = @{}
Get-Content $mp -Encoding UTF8 | ForEach-Object { $p=$_ -split "`t"; if($p.Count -ge 2){ $existing[$p[1].Trim()]=$true } }
$yi = @{}
Get-Content "$dir\通用规范汉字表_一级3500字.txt" -Encoding UTF8 | ForEach-Object { $c=$_.Trim(); if($c){ $yi[$c[0]]=$true } }

$add=@(); $n2=@(); $mc=@(); $skip=@()
foreach($r in $rows){
  $t=$r[0]; $k=$r[1]; $v=$r[2]
  if($existing.ContainsKey($k)){ $skip+=$k; continue }
  $existing[$k]=$true
  $add += "$t`t$k`t$v"
  foreach($ch in $v.ToCharArray()){ if(-not $yi.ContainsKey($ch)){ $n2 += "$t`t$k`t$v ($ch)"; break } }
  if($v.Length -ge 2){ $mc += "$t`t$k`t$v" }
}
if($add.Count){ Add-Content -Path $mp -Value $add -Encoding UTF8 }
if($n2.Count){ Add-Content -Path "$dir\_nivelo2.tsv" -Value $n2 -Encoding UTF8 }
if($mc.Count){ Add-Content -Path "$dir\_multichar.tsv" -Value $mc -Encoding UTF8 }

# 固有名詞 → untargeted + master(未対応 記録)
$untAdd=@(); $propAdd=@()
foreach($pn in $proper){
  if($existing.ContainsKey($pn)){ continue }
  $existing[$pn]=$true
  $untAdd += "proper`t$pn`t固有名詞・国名(§91)"
  $propAdd += "proper`t$pn`t未対応"
}
if($untAdd.Count){ Add-Content -Path "$dir\_untargeted.tsv" -Value $untAdd -Encoding UTF8 }
if($propAdd.Count){ Add-Content -Path $mp -Value $propAdd -Encoding UTF8 }

Write-Host "追加(学術): $($add.Count) / 固有名詞→未対応: $($propAdd.Count)"
if($skip.Count){ Write-Host ("既存skip: " + ($skip -join ', ')) }
if($n2.Count){ Write-Host ("★二级(一级外)検出: " + ($n2 -join ' | ')) }
if($mc.Count){ Write-Host ("多字: " + ($mc -join ' | ')) }
$total = (Get-Content $mp -Encoding UTF8 | Measure-Object -Line).Lines
Write-Host "master 総行: $total"

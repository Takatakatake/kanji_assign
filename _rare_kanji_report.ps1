# 稀少字(≤2語根)を意味カテゴリ別に分類し、可読レポート _rare_kanji_report.txt を生成。
# 「実際に1-2回しか使われない漢字」の具体像をユーザーに提示する用。語義マーカーで自動分類。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$rows = Get-Content "$dir\_rare_kanji_now.tsv" -Encoding UTF8 | Select-Object -Skip 1
# カテゴリ判定(語義の【...】タグ/キーワード)
function ClassifyGloss($gloss){
  if($gloss -match '【動】|【鳥】|【魚】|【虫】|【獣】|（属）|（の類）|（科）'){ return '1_生物(動植物・属種)' }
  if($gloss -match '【植】|【果】'){ return '1_生物(動植物・属種)' }
  if($gloss -match '【解】|【医】|【病】'){ return '2_身体・医学' }
  if($gloss -match '【化】|【理】|【鉱】|【元素】|元素|【天】'){ return '3_化学・物理・鉱物' }
  if($gloss -match '【楽】|【宗】|【法】|【建】|【海】|【軍】|【機】|【電】|【通】|【経】|【商】|【数】'){ return '4_専門分野(楽宗法建海軍機等)' }
  if($gloss -match '【地理】|【地名】|【史】'){ return '5_地理・歴史・固有' }
  return '6_一般概念(動作・性質・抽象)'
}
$buckets=@{}
foreach($r in $rows){
  $p=$r -split "`t"; if($p.Count -lt 3){continue}
  $ch=$p[0]; $n=$p[1]; $info=$p[2]
  $g=($info -split '\|')[0]   # 代表語根の語義
  $c=ClassifyGloss $g
  if(-not $buckets.ContainsKey($c)){ $buckets[$c]=New-Object System.Collections.ArrayList }
  [void]$buckets[$c].Add(("{0}(×{1})  {2}" -f $ch,$n,(($info.Substring(0,[Math]::Min(60,$info.Length)))) ))
}
$out=New-Object System.Collections.ArrayList
[void]$out.Add("==== 稀少漢字(1〜2語根しか使わない字)カテゴリ別一覧 ====")
[void]$out.Add(("生成: 最新注入 / 計 " + $rows.Count + " 字(1語根=690 + 2語根=481)"))
[void]$out.Add("【方針】大半は『その概念にしか使えない必要専用字』=evocative方針の自然な帰結で維持が正しい。")
[void]$out.Add("統合できる drakon型(同義の孤立字→確立系列)は累計17件を適用済。残りは維持。")
[void]$out.Add("")
foreach($c in ($buckets.Keys | Sort-Object)){
  [void]$out.Add(("---- " + $c + " : " + $buckets[$c].Count + "字 ----"))
  foreach($line in ($buckets[$c] | Sort-Object)){ [void]$out.Add("  " + $line) }
  [void]$out.Add("")
}
[System.IO.File]::WriteAllText("$dir\_rare_kanji_report.txt",($out -join "`r`n"),(New-Object System.Text.UTF8Encoding($true)))
# 画面にはカテゴリ別件数サマリのみ
Write-Host "=== 稀少字カテゴリ別 件数 ==="
foreach($c in ($buckets.Keys | Sort-Object)){ Write-Host ("  {0,-32} {1}字" -f $c,$buckets[$c].Count) }
Write-Host ("  合計 " + $rows.Count + "字 → 詳細は _rare_kanji_report.txt")

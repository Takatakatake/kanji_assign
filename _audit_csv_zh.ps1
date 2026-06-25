# CSV2890の中国語対訳列(Chinese_Trans)と、割当漢字(サイドカーdisp base字)を突き合わせ、
# 「割当base字が中国語対訳に1字も現れない」語を抽出(真の意味乖離=誤割当の候補)。
# 出力 _audit_csv_zh.tsv: root<TAB>disp<TAB>baseChars<TAB>chinese(60字)<TAB>japanese(40字)
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$csv="$dir\30_重要語彙CSV_日中対照_2890語\2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
# サイドカー: root→disp
$disp=@{}
Import-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -Delimiter "`t" | ForEach-Object { if(-not $disp.ContainsKey($_.root)){ $disp[$_.root]=$_.disp } }
# 語尾除去で root 候補を得る(長い語尾から)
$endings=@('antaj^o','intaj^o','ontaj^o','atajo','ado','aĵo','ant','int','ont','aj^','ado','as','is','os','us','oj','aj','ojn','ajn','on','an','en','o','a','e','i','u','j','n')
function ToRoot([string]$w){
  $w=$w.Trim().TrimStart('-').TrimEnd('-')
  if($w -eq ''){return ''}
  # スラッシュ無しの citation form。末尾語尾を1つ剥がす(最長一致)
  foreach($e in ($endings | Sort-Object { $_.Length } -Descending)){ if($w.Length -gt $e.Length -and $w.EndsWith($e)){ return $w.Substring(0,$w.Length-$e.Length) } }
  return $w
}
# CJK統合漢字のみ抽出(識別子上付き・ラテン・かなを除く)
function BaseChars([string]$s){
  $o=''
  foreach($ch in $s.ToCharArray()){ $c=[int][char]$ch; if(($c -ge 0x4E00 -and $c -le 0x9FFF) -or ($c -ge 0x3400 -and $c -le 0x4DBF)){ $o+=$ch } }
  $o
}
$rows=New-Object System.Collections.ArrayList
[void]$rows.Add("root`tdisp`tbaseChars`tchinese`tjapanese")
$nTot=0;$nAssigned=0;$nMiss=0
Import-Csv $csv -Encoding UTF8 | ForEach-Object {
  $eo=$_.Esperanto; if(-not $eo){return}
  $zh=$_.Chinese_Trans; if(-not $zh){$zh=''}
  $ja=$_.Japanese_Trans; if(-not $ja){$ja=''}
  $nTot++
  $root=ToRoot $eo
  if(-not $disp.ContainsKey($root)){ return }   # 未割当(固有名/文法/音訳=別途)
  $d=$disp[$root]; $bc=BaseChars $d
  if($bc -eq ''){ return }   # ラテンのみ(未対応)
  $nAssigned++
  # base字のいずれかが中国語対訳に含まれるか
  $hit=$false; foreach($ch in $bc.ToCharArray()){ if($zh.Contains([string]$ch)){ $hit=$true; break } }
  if(-not $hit){
    $nMiss++
    $zs=if($zh.Length -gt 60){$zh.Substring(0,60)}else{$zh}
    $js=if($ja.Length -gt 40){$ja.Substring(0,40)}else{$ja}
    [void]$rows.Add("$root`t$d`t$bc`t$zs`t$js")
  }
}
[System.IO.File]::WriteAllLines("$dir\_audit_csv_zh.tsv",$rows,(New-Object System.Text.UTF8Encoding($false)))
Write-Host ("CSV2890 計{0} / 割当照合{1} / base字が中国語対訳に不在={2}件 → _audit_csv_zh.tsv" -f $nTot,$nAssigned,$nMiss)

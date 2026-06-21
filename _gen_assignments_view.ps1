# 現時点の全割当を一覧化(識別子プレビュー付き)
# F(汎用性=辞書出現数)を算出 → 同字でグループ化 → §9識別子を【プレビュー】付与
# 出力: 漢字割当一覧_識別子付きプレビュー_20260614.tsv / .md
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
$dict = "$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"

function ToHsys([string]$s){
  $s = $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^'
  return $s
}
# Esperanto 文字分解(ĉĝĥĵŝŭ を1単位に、h-system不可・Unicode前提)
$vowels = 'a','e','i','o','u'
function IsVowel([string]$c){ return ($vowels -contains $c.ToLower()) }   # ŭ は子音扱い(リストにない)
# 上付き字体マップ(§121)。c/f/s/z は小文字モディファイア。特殊字は基底+結合分音
$sup = @{
 'a'=[char]0x1D2C; 'b'=[char]0x1D2E; 'c'=[char]0x1D9C; 'd'=[char]0x1D30; 'e'=[char]0x1D31;
 'f'=[char]0x1DA0; 'g'=[char]0x1D33; 'h'=[char]0x1D34; 'i'=[char]0x1D35; 'j'=[char]0x1D36;
 'k'=[char]0x1D37; 'l'=[char]0x1D38; 'm'=[char]0x1D39; 'n'=[char]0x1D3A; 'o'=[char]0x1D3C;
 'p'=[char]0x1D3E; 'r'=[char]0x1D3F; 's'=[char]0x02E2; 't'=[char]0x1D40; 'u'=[char]0x1D41;
 'v'=[char]0x2C7D; 'z'=[char]0x1DBB
}
$comb = @{ 'ĉ'='c'; 'ĝ'='g'; 'ĥ'='h'; 'ĵ'='j'; 'ŝ'='s'; 'ŭ'='u' }   # +結合記号
function ToSup([string]$id){
  $out = ''
  foreach($ch in $id.ToCharArray()){
    $cs = [string]$ch
    if($sup.ContainsKey($cs)){ $out += $sup[$cs] }
    elseif($comb.ContainsKey($cs)){
      $base = $comb[$cs]; $out += $sup[$base]
      if($cs -eq 'ŭ'){ $out += [char]0x0306 } else { $out += [char]0x0302 }
    }
    elseif($ch -match '[0-9]'){ $out += $ch }   # 数字フォールバック
    else { $out += $ch }
  }
  return $out
}
# 文字単位に分解(ĉĝĥĵŝŭ=1単位)
function Letters([string]$s){
  $arr = New-Object System.Collections.Generic.List[string]
  foreach($ch in $s.ToCharArray()){ $arr.Add([string]$ch) }
  return $arr
}

# --- master 読み込み(値が漢字のもののみ。未対応は別集計) ---
$assign = New-Object System.Collections.ArrayList
$untN = 0
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object {
  $p = $_ -split "`t"
  if($p.Count -ge 3){
    $t=$p[0].Trim(); $k=$p[1].Trim(); $v=$p[2].Trim()
    if($v -eq '未対応' -or $v -eq ''){ $script:untN++; return }
    $null = $assign.Add([pscustomobject]@{ type=$t; root=$k; kanji=$v; hsys=(ToHsys $k); F=0 })
  }
}

# --- F(辞書出現数) 算出: 全セグメント数を一括カウント ---
$endingRe = '^(o|a|e|i|u|oj|aj|on|an|ojn|ajn|en|as|is|os|us|u|j|n)$'
$segCount = @{}
Get-Content $dict -Encoding UTF8 | ForEach-Object {
  $ci = $_.IndexOf(':'); if($ci -lt 1){ return }
  $head = $_.Substring(0,$ci)
  foreach($w in ($head -split ' ')){
    foreach($s in ($w -split '/')){
      if($s -match $endingRe){ continue }
      if($s.Length -lt 1){ continue }
      $segCount[$s] = 1 + ($segCount[$s])
    }
  }
}
foreach($a in $assign){ if($segCount.ContainsKey($a.hsys)){ $a.F = $segCount[$a.hsys] } }

# --- 同字グループ化 ---
$groups = @{}
foreach($a in $assign){ if(-not $groups.ContainsKey($a.kanji)){ $groups[$a.kanji]=New-Object System.Collections.ArrayList }; $null=$groups[$a.kanji].Add($a) }

# --- グループ内ソート(F降順, 語根長昇順, アルファベット) + 識別子プレビュー付与 ---
$rowsOut = New-Object System.Collections.ArrayList
foreach($kj in $groups.Keys){
  $mem = @($groups[$kj] | Sort-Object @{e={$_.F};Descending=$true}, @{e={$_.root.Length}}, @{e={$_.root}})
  $used = @{}
  for($i=0;$i -lt $mem.Count;$i++){
    $m = $mem[$i]
    if($i -eq 0){ $id = '' }                       # 基本形(識別子なし)
    else {
      $L = Letters $m.root
      $cand = $L[0]
      if(-not $used.ContainsKey($cand)){ $id = $cand }
      else {
        $id = $null
        foreach($ch in $L[1..($L.Count-1)]){ if(-not (IsVowel $ch)){ $t=$cand+$ch; if(-not $used.ContainsKey($t)){ $id=$t; break } } }  # 子音優先
        if(-not $id){ foreach($ch in $L[1..($L.Count-1)]){ $t=$cand+$ch; if(-not $used.ContainsKey($t)){ $id=$t; break } } }            # 母音補完
        if(-not $id){ $kk=2; while($used.ContainsKey($cand+$kk)){ $kk++ }; $id=$cand+$kk }                                              # 数字
      }
      $used[$id]=$true
    }
    $supId = if($id){ ToSup $id } else { '' }
    $null = $rowsOut.Add([pscustomobject]@{
      kanji=$kj; final=($m.kanji+$supId); id=$id; root=$m.root; type=$m.type; F=$m.F; grp=$mem.Count; base=($(if($i -eq 0){'✓'}else{''}))
    })
  }
}

# --- 出力ソート: 衝突グループ(大→小)を上, 同点はF降順 ---
$sorted = @($rowsOut | Sort-Object @{e={$_.grp};Descending=$true}, @{e={$_.kanji}}, @{e={$_.F};Descending=$true})

# TSV
$tsv = "$dir\漢字割当一覧_識別子付きプレビュー_20260614.tsv"
$head = "最終形`t識別子`t漢字`t語根`t型`tF(汎用性)`tグループ数`t基本形"
$body = $sorted | ForEach-Object { "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}" -f $_.final,$_.id,$_.kanji,$_.root,$_.type,$_.F,$_.grp,$_.base }
Set-Content -Path $tsv -Value (@($head)+$body) -Encoding UTF8

# 統計
$nAssign = $assign.Count
$nChars = $groups.Count
$collGroups = @($groups.GetEnumerator() | Where-Object { $_.Value.Count -ge 2 })
$nColl = $collGroups.Count
$maxg = ($collGroups | ForEach-Object { $_.Value.Count } | Measure-Object -Maximum).Maximum

# MD(サマリ + 衝突グループ上位)
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# 漢字割当一覧(識別子プレビュー) 2026-06-14")
$md.Add("")
$md.Add("> 識別子は**最終全体パスのプレビュー**(§9)。Fは辞書出現数で近似。基本形=グループ内F最大(識別子なし)。")
$md.Add("")
$md.Add("## サマリ")
$md.Add("- 割当(漢字)総数: **$nAssign** / 未対応(ラテン保持): $untN")
$md.Add("- ユニーク漢字(=グループ)数: **$nChars**")
$md.Add("- 衝突グループ(2語根以上が同字): **$nColl** (最大 $maxg 語根)")
$md.Add("- 全データ: ``漢字割当一覧_識別子付きプレビュー_20260614.tsv``")
$md.Add("")
$md.Add("## 衝突グループ(同字共有→識別子で区別) ※上位40")
$topColl = @($collGroups | Sort-Object @{e={$_.Value.Count};Descending=$true} | Select-Object -First 40)
foreach($g in $topColl){
  $kj = $g.Key
  $mem = @($sorted | Where-Object { $_.kanji -eq $kj } | Sort-Object @{e={$_.F};Descending=$true})
  $disp = ($mem | ForEach-Object { "{0}={1}{2}(F{3})" -f $_.root, $_.kanji, $(if($_.id){"["+$_.id+"]"}else{""}), $_.F }) -join ' , '
  $md.Add("- **$kj** ×$($mem.Count): $disp")
}
Set-Content -Path "$dir\漢字割当一覧_識別子付きプレビュー_20260614.md" -Value $md -Encoding UTF8

Write-Host "割当 $nAssign / ユニーク字 $nChars / 衝突グループ $nColl (最大$maxg) / 未対応 $untN"
Write-Host "出力: 漢字割当一覧_識別子付きプレビュー_20260614.tsv / .md"
Write-Host ""
Write-Host "=== 衝突グループ 上位12(プレビュー) ==="
$topColl | Select-Object -First 12 | ForEach-Object {
  $kj=$_.Key
  $mem=@($sorted | Where-Object { $_.kanji -eq $kj } | Sort-Object @{e={$_.F};Descending=$true})
  $disp=($mem | ForEach-Object { "{0}{1}" -f $_.root, $(if($_.id){"→"+$_.final}else{"(基)"}) }) -join ' , '
  "{0} ×{1}: {2}" -f $kj, $mem.Count, $disp
}
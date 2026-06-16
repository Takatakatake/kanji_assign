# 語義照合QAワークフロー生成: (語根・辞書フル語義・割当漢字) を敵対的に照合し誤りを flag
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613"
$dict = "$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){
  $s = $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^'
  return $s
}
$endingRe = '^(o|a|e|i|u|oj|aj|on|an|ojn|ajn|en|as|is|os|us|u|j|n)$'
# 各セグメント → 代表フル語義(content数最小の見出しを代表に)
$repGloss=@{}; $repScore=@{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){ continue }
  $head=$line.Substring(0,$ci); $gloss=($line.Substring($ci+1) -replace '^\{[^}]*\}','').Trim()
  foreach($w in ($head -split ' ')){
    $segs=@($w -split '/'); $cn=@($segs | Where-Object { $_ -notmatch $endingRe }).Count
    foreach($s in $segs){
      if($s -match $endingRe -or $s.Length -lt 1){ continue }
      if(-not $repScore.ContainsKey($s) -or $cn -lt $repScore[$s]){
        $repScore[$s]=$cn; $g=$gloss; if($g.Length -gt 110){ $g=$g.Substring(0,110) }; $repGloss[$s]=$g
      }
    }
  }
}
# master → 検証項目(語義のあるもののみ。未対応除外)
$items = New-Object System.Collections.ArrayList
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object {
  $p=$_ -split "`t"; if($p.Count -lt 3){ return }
  $root=$p[1].Trim(); $kanji=$p[2].Trim()
  if($kanji -eq '未対応' -or -not $kanji){ return }
  $rh=ToHsys $root; if(-not $repGloss.ContainsKey($rh)){ return }
  $null=$items.Add([pscustomobject]@{ root=$root; kanji=$kanji; gloss=$repGloss[$rh] })
}
$ITEMS = ($items | ConvertTo-Json -Compress)
Write-Host "検証項目: $($items.Count)"
$tpl = @'
export const meta = { name: 'semqa', description: '全漢字割当を辞書語義と敵対的照合し誤りをflag', phases: [{title:'QA'}] }
const ITEMS = ITEMSARR
const SCH = { type:'object', additionalProperties:false, required:['flags'], properties:{ flags:{ type:'array', items:{ type:'object', additionalProperties:false, required:['root','current','verdict','suggest','reason'], properties:{ root:{type:'string'}, current:{type:'string'}, verdict:{type:'string',enum:['mismatch','doubtful']}, suggest:{type:'string'}, reason:{type:'string'} } } } } }
const CH=[]; for(let i=0;i<ITEMS.length;i+=30) CH.push(ITEMS.slice(i,i+30))
phase('QA')
const res = await parallel(CH.map((c,ci)=>()=> agent(`あなたはエスペラント語根→簡体字割当の語義照合検証者。各項目について、割当漢字が「辞書語義の中心義」を正しく表すか厳格に判定せよ。\n【flagするのは明確な誤りのみ】: 漢字の意味が辞書語義と無関係/別物/正反対、語義を取り違えている(例 poez=詩なのに生)、固有名詞なのに無関係字、など。\n【flagしない(許容)】: 同字共有(複数語根が同じ漢字)、2字/3字熟語、元素字、二级専門字、意味の近い字・標準的な意訳・結合形・偽分解由来でも中心義が合っているもの。\n中心義が辞書語義と食い違う項目だけ flags に入れよ(正しいものは入れない)。各flag: root, current(現漢字), verdict(mismatch=明確な誤り/doubtful=要確認), suggest(推奨漢字 or 空), reason(簡潔・日本語)。\n項目(JSON): ${JSON.stringify(c)}`, { label:`qa:${ci}`, phase:'QA', schema:SCH }).then(r=> (r&&r.flags)?r.flags:[]) ))
const flags = res.filter(Boolean).flat()
log(`検証 ${ITEMS.length}項目 / flag ${flags.length}`)
return { count: ITEMS.length, flags }
'@
$js = $tpl.Replace('ITEMSARR',$ITEMS)
$out = "$dir\_wf_semqa.js"
[System.IO.File]::WriteAllText($out, $js, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "生成: $out"
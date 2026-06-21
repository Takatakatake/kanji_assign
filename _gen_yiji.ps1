# 一级化リダクション: 二级字を含む割当に、一级のみの透明な代替を探すワークフローを生成
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
$dict = "$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){
  $s = $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^'
  return $s
}
$endingRe = '^(o|a|e|i|u|oj|aj|on|an|ojn|ajn|en|as|is|os|us|u|j|n)$'
# 一级/二级 集合
$yi=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object { $c=($_ -split "`t")[1]; if($c){$yi[$c.Trim()]=$true} }
$er=@{}; Get-Content "$dir\通用规范汉字表_二级3000字_画数.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object { $c=($_ -split "`t")[1]; if($c){$er[$c.Trim()]=$true} }
# 代表フル語義
$repGloss=@{}; $repScore=@{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){ continue }
  $head=$line.Substring(0,$ci); $gloss=($line.Substring($ci+1) -replace '^\{[^}]*\}','').Trim()
  foreach($w in ($head -split ' ')){
    $segs=@($w -split '/'); $cn=@($segs | Where-Object { $_ -notmatch $endingRe }).Count
    foreach($s in $segs){ if($s -match $endingRe -or $s.Length -lt 1){ continue }
      if(-not $repScore.ContainsKey($s) -or $cn -lt $repScore[$s]){ $repScore[$s]=$cn; $g=$gloss; if($g.Length -gt 110){$g=$g.Substring(0,110)}; $repGloss[$s]=$g } }
  }
}
# 二级字を含む割当を抽出
$items = New-Object System.Collections.ArrayList
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object {
  $p=$_ -split "`t"; if($p.Count -lt 3){ return }
  $root=$p[1].Trim(); $kanji=$p[2].Trim(); if($kanji -eq '未対応' -or -not $kanji){ return }
  $erChars=@(); foreach($ch in $kanji.ToCharArray()){ if([int][char]$ch -lt 128){continue}; if($er.ContainsKey([string]$ch)){ $erChars += [string]$ch } }
  if($erChars.Count -eq 0){ return }
  $rh=ToHsys $root; $g=if($repGloss.ContainsKey($rh)){$repGloss[$rh]}else{''}
  $null=$items.Add([pscustomobject]@{ root=$root; kanji=$kanji; er=($erChars -join ''); gloss=$g })
}
$ITEMS = ($items | ConvertTo-Json -Compress)
Write-Host "二级を含む割当: $($items.Count)"
$tpl = @'
export const meta = { name: 'yiji-reduce', description: '二级字を含む割当に一级のみの透明代替を探す', phases: [{title:'Reduce'}] }
const ITEMS = ITEMSARR
const SCH = { type:'object', additionalProperties:false, required:['results'], properties:{ results:{ type:'array', items:{ type:'object', additionalProperties:false, required:['root','current','action','newk','reason'], properties:{ root:{type:'string'}, current:{type:'string'}, action:{type:'string',enum:['reduce','untargeted']}, newk:{type:'string'}, reason:{type:'string'} } } } } }
const CH=[]; for(let i=0;i<ITEMS.length;i+=10) CH.push(ITEMS.slice(i,i+10))
phase('Reduce')
const res = await parallel(CH.map((c,ci)=>()=> agent(`各割当は《通用规范汉字表》二级字(er欄に明示)を含む。**最優先目標=二级字を一切使わない。一级3500字だけにする。一级で表せなければ未対応にする(二级で維持は禁止)**。\n各項目で「一级字のみ」で辞書語義の中心義に到達できる代替を探せ:\n- 一级のみで透明に表せる代替(一级単字、または一级のみの2字熟語)が在れば action=reduce, newk=その一级表現。**やや汎用的でも中心義に到達できれば一级を優先**(精度より一级優先。例 蟒→巨蛇/蝰→毒蛇/鳗→未対応[一级で表せない]/鲟→未対応)。既存一级字の再利用(R1=漢字重複歓迎)を積極活用し、**同字衝突は気にするな**(識別子で解消)。\n- **一级では中心義に到達できない場合(元素字・系統化学字・一级に語が無い特定動植物種/専門概念で、一级にすると完全な別物・誤読になる、または一级表現が存在しない)は action=untargeted(未対応)**。二级での維持(keep)は不可。\nnewk は必ず一级字のみ(二级・表外字を使うな)。reduce時のみnewk記入、untargeted時は空。各項目: root, current(現漢字), action(reduce/untargeted), newk, reason(簡潔・日本語)。\n項目(JSON, er=現在使用中の二级字): ${JSON.stringify(c)}`, { label:`reduce:${ci}`, phase:'Reduce', schema:SCH }).then(r=> (r&&r.results)?r.results:[]) ))
const all = res.filter(Boolean).flat()
const reduced = all.filter(r=>r.action==='reduce'&&r.newk)
const unt = all.filter(r=>r.action==='untargeted')
log(`対象 ${ITEMS.length} / reduce(一级) ${reduced.length} / untargeted(未対応) ${unt.length}`)
return { total: ITEMS.length, results: all, reduced, unt }
'@
$js = $tpl.Replace('ITEMSARR',$ITEMS)
$out = "$dir\_wf_yiji.js"
[System.IO.File]::WriteAllText($out, $js, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "生成: $out"
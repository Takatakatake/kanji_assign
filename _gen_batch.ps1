# 基本語彙 内容語バッチ生成器
# 使い方: powershell -File _gen_batch.ps1 -Num 7 -Size 120
param(
  [int]$Num = 7,
  [int]$Size = 120,
  [int]$Offset = 0
)
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"

# --- master 読み込み: キー集合 と 既割当漢字集合 ---
$masterLines = Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8
$master = @{}
$usedKanji = New-Object System.Collections.Generic.List[string]
$seenK = @{}
foreach($l in $masterLines){
  $p = $l -split "`t"
  if($p.Count -ge 2){ $master[$p[1].Trim()] = $true }
  if($p.Count -ge 3){
    $k = $p[2].Trim()
    # 多字(未対応/語尾付き)や注記は単字のみ拾う
    if($k.Length -eq 1 -and -not $seenK.ContainsKey($k)){ $seenK[$k]=$true; $usedKanji.Add($k) }
  }
}
$USED = ($usedKanji -join ' ')

# --- 原始小辞の明示除外集合 (master func外で内容語でないもの) ---
$skip = @{}
foreach($w in @('ĉi','je','nu','ho','ha')){ $skip[$w]=$true }

# --- 未対応台帳の語根を除外集合に (借用語等の再出題防止) ---
$untSet = @{}
$ledgerPath = "$dir\_untargeted.tsv"
if(Test-Path $ledgerPath){
  Get-Content $ledgerPath -Encoding UTF8 | ForEach-Object { $pp=$_ -split "`t"; if($pp.Count -ge 2){ $untSet[$pp[1].Trim()]=$true } }
}

# --- CSV から残り内容語を再計算 ---
$rows = Import-Csv -Path "$dir\2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv" -Encoding UTF8
$remaining = New-Object System.Collections.ArrayList
foreach($r in $rows){
  $vals = @($r.PSObject.Properties.Value)
  $esp = ([string]$vals[0]).Trim()
  $jp  = [string]$vals[1]
  $cn  = [string]$vals[2]
  $lvl = [string]$vals[3]
  if([string]::IsNullOrWhiteSpace($esp)){ continue }
  if($esp -match '[^a-zA-ZĉĝĥĵŝŭĈĜĤĴŜŬ]'){ continue }   # 記号・空白・"!"含む間投詞を除外
  if($esp.Length -le 1){ continue }
  if($esp.StartsWith('-') -or $esp.EndsWith('-')){ continue }
  if($skip.ContainsKey($esp)){ continue }
  if($master.ContainsKey($esp)){ continue }              # 全形既済(機能語等)
  # 語根導出
  $root = $esp
  if($root -match '(oj|aj)$'){ $root = $root.Substring(0,$root.Length-2) }   # 複数語尾
  if($root -match '(as|is|os|us)$'){ $root = $root.Substring(0,$root.Length-2) }
  elseif($root -match '[oaie]$'){ $root = $root.Substring(0,$root.Length-1) }
  if($root.Length -lt 2){ continue }                     # 過剰剥離(小辞)→除外
  if($master.ContainsKey($root)){ continue }             # 語根既済
  if($untSet.ContainsKey($root)){ continue }             # 未対応台帳(借用語等)既出
  # jp の先頭タグ {Ｂ}{Ｏ} を除去
  $jpc = $jp -replace '^\{[^}]*\}',''
  $null = $remaining.Add([pscustomobject]@{ root=$root; esp=$esp; level=[double]$lvl; jp=$jpc.Trim(); cn=$cn.Trim() })
}
$sorted = @($remaining | Sort-Object level, root)
# root 重複除去(同根の別品詞が複数行ある場合、最初=最低levelを採用)
$seen=@{}; $uniq=New-Object System.Collections.ArrayList
foreach($it in $sorted){ if(-not $seen.ContainsKey($it.root)){ $seen[$it.root]=$true; $null=$uniq.Add($it) } }
$sorted = @($uniq)

$sorted | ConvertTo-Json -Depth 4 -Compress | Out-File "$dir\_content_remaining.json" -Encoding UTF8
Write-Host "残り内容語(uniq root): $($sorted.Count) / 既割当ユニーク漢字: $($usedKanji.Count)"

# --- バッチslice ---
$batch = @($sorted | Select-Object -Skip $Offset -First $Size)
Write-Host "バッチ b$Num (offset $Offset): $($batch.Count) 語 (level $($batch[0].level)〜$($batch[-1].level))"
$itemsArr = $batch | ForEach-Object { [pscustomobject]@{ root=$_.root; esp=$_.esp; jp=$_.jp; cn=$_.cn } }
$ITEMS = ($itemsArr | ConvertTo-Json -Depth 4 -Compress)
if($batch.Count -eq 1){ $ITEMS = "[$ITEMS]" }   # 1件時は配列化

# --- JS 生成 ---
$tpl = @'
export const meta = { name: 'content-root-kanji-bNUM', description: '内容語語根バッチBNUMの漢字割当を提案し敵対的に検証', phases: [{title:'Propose'},{title:'Verify'}] }
const USED = 'USEDSET'
const POLICY = `
【漢字化方針(要約)】内容語(名詞・動詞・形容詞)の語根に簡体字を意味訳で割り当てる(原則1字、ただし下記の通り多字可)。
- 意味訳のみ。音訳厳禁。意味透明性が最重要。HSK基礎・簡体字・少画数優先。《通用规范汉字表》一級内が目安。
- 字数: 【原則1字】(省エネ最優先。特に汎用度の高い常用語根は必ず1字)。その1字が語根の中心義を担っていれば1字を維持せよ(例 应=must/should, 界=world, 解=understand, 头=head, 问=ask, 末=last, 良=good は全て1字で十分)。多字(2-3字)を使うのは次の2類のみ: (a)その1字の主要義が語根の意味を含まない・無関係(例 使=使う/使者→angelは天使、号=番号→trumpetは喇叭、动=動く→animalは动物); (b)稀な専門・動植物・器物で適切な1字が存在しない(例 目皮=eyelid、山毛榉=beech、孔雀=peacock)。それ以外は1字。日中で主要意味が乖離する字(走/汤/手纸/写/吃 等)は同等に透明な代替があれば回避。
- 多義語根は中心義を基準。真の借用語・音訳語(コーヒー/カード/バイオリン等、漢字が音写しかない語)は無理に当てず problem=音訳・final=未対応。ただし意味訳の熟語が定着している語(电话/千克 等)は多字で意味訳してよい。
- 旧プロジェクトの 修正傾向まとめ_20260416.md は典拠にしない(参照禁止)。
【既割当漢字(機能語+接辞+既出内容語)】衝突は最終識別子パスで完全に解消される(同字を複数語根が共有してよい。日本語漢字が複数の訓読みを持つのと同じ)。したがって常に最も意味透明な字を優先せよ。非衝突字への代替は、それが最良字と同等以上に透明な場合に限る。少しでも透明性が劣るなら衝突を厭わず最良字を採れ。いずれの場合も衝突を申告すること:
${USED}
`
const PS = { type:'object', additionalProperties:false, required:['root','recommended','rationale','divergence_risk','collision','confidence'], properties:{ root:{type:'string'}, recommended:{type:'string'}, alt:{type:'array',items:{type:'string'}}, rationale:{type:'string'}, divergence_risk:{type:'string'}, collision:{type:'string'}, confidence:{type:'string',enum:['high','medium','low']} } }
const VS = { type:'object', additionalProperties:false, required:['root','proposed','verdict','final','problem','reason'], properties:{ root:{type:'string'}, proposed:{type:'string'}, verdict:{type:'string',enum:['accept','revise']}, final:{type:'string'}, problem:{type:'string',enum:['音訳','不透明','日中乖離','専門字','冗長2字','なし']}, reason:{type:'string'} } }
const ITEMS = ITEMSARR
phase('Propose')
const results = await pipeline(ITEMS,
  (it) => agent(`${POLICY}\n対象の内容語語根に最良の簡体字漢字を提案せよ(原則1字。ただし1字で意味が立たない/不透明/難字しかない場合は透明な2-3字可)。\n語根: ${it.root}-  (語形 ${it.esp})\n日本語義: ${it.jp}\n中国語義: ${it.cn}\n\n意味訳のみ。日中双方に透明な基礎字。既割当字との衝突は識別子で解消されるので最良字優先可だが衝突を申告し同等の非衝突字は代替に。音写になる借用語は problem=音訳 相当として recommended に無理に当てず簡潔に申告。root は "${it.root}" を返せ。`, { label:`propose:${it.root}`, phase:'Propose', schema:PS }).then((p)=>({...it,propose:p})),
  (r) => { if(!r||!r.propose) return null; const it=r; return agent(`${POLICY}\nあなたは敵対的検証者。提案を却下しようと試みよ。\n語根: ${it.root}- (${it.esp})\n日:${it.jp} 中:${it.cn}\n提案:「${it.propose.recommended}」(代替 ${(it.propose.alt||[]).join('/')||'なし'}) 理由:${it.propose.rationale} 衝突:${it.propose.collision}\nチェック:(1)音訳でない(2)中心義が透明(3)日中乖離で誤読しない(4)一級外の難字を単字で使うなら、透明な2字熟語(一級字構成)に置換できないか検討(5)透明性に寄与しない無駄な冗長熟語でない(但し1字が不透明/難字なら透明な2字を優先)(6)明らかに優れた基礎字が他にないか。重要:衝突は識別子で完全解消されるため、既割当との衝突のみを理由に劣る字へ替えるな(最良の意味透明字が衝突しても維持)。代替は最良字と同等以上に透明な時のみ。問題があれば verdict=revise・final に採用字、無ければ accept(final=提案字)。借用語で適切な意味字が無ければ problem=音訳・final=未対応。root は "${it.root}" を返せ。`, { label:`verify:${it.root}`, phase:'Verify', schema:VS }).then((v)=>({root:it.root,jp:it.jp,cn:it.cn,propose:it.propose,verify:v})) }
)
const ok = results.filter(Boolean)
const usedSet = new Set(USED.split(' '))
const fO = (r)=> r.verify? r.verify.final : r.propose.recommended
const bk={}; for(const r of ok){const k=fO(r);(bk[k]=bk[k]||[]).push(r.root)}
const batchCollisions = Object.entries(bk).filter(([k,l])=>l.length>1).map(([k,l])=>({kanji:k,roots:l}))
const usedCollisions = ok.filter((r)=>usedSet.has(fO(r))).map((r)=>({root:r.root,kanji:fO(r)}))
const revised = ok.filter((r)=>r.verify&&r.verify.verdict==='revise').map((r)=>({root:r.root,from:r.propose.recommended,to:r.verify.final,problem:r.verify.problem,reason:r.verify.reason}))
log(`検証完了: ${ok.length}語 / revise ${revised.length} / バッチ内衝突 ${batchCollisions.length} / 既割当重複 ${usedCollisions.length}`)
return { roots: ok.map((r)=>({root:r.root,jp:r.jp,cn:r.cn,final:fO(r),verdict:r.verify&&r.verify.verdict,problem:r.verify&&r.verify.problem,alt:r.propose.alt,collision:r.propose.collision,confidence:r.propose.confidence})), revised, batchCollisions, usedCollisions }
'@

$js = $tpl.Replace('NUM', "$Num").Replace('USEDSET', $USED).Replace('ITEMSARR', $ITEMS)
$outPath = "$dir\_wf_content_b$Num.js"
$js | Out-File $outPath -Encoding UTF8
Write-Host "生成: $outPath"

# 3字+割当を2字(or1字)へ短縮するクリーンアップ・ワークフロー生成
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613"
$usedKanji = New-Object System.Collections.Generic.List[string]; $seenK=@{}
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object { $p=$_ -split "`t"; if($p.Count -ge 3){ $k=$p[2].Trim(); if($k.Length -eq 1 -and -not $seenK.ContainsKey($k)){ $seenK[$k]=$true; $usedKanji.Add($k) } } }
$USED = ($usedKanji -join ' ')
$arr = Get-Content -Raw -Encoding UTF8 "$dir\_threechar.json" | ConvertFrom-Json
# 月名は対象外
$cand = @($arr | Where-Object { $_.root -notin @('novembr','decembr') })
$ITEMS = ($cand | ForEach-Object { [pscustomobject]@{ root=$_.root; cur=$_.cur; gloss=$_.gloss } } | ConvertTo-Json -Depth 4 -Compress)
if($cand.Count -eq 1){ $ITEMS="[$ITEMS]" }
$tpl = @'
export const meta = { name: 'threechar-fix', description: '3字+割当を透明性を保ち2字以下へ短縮', phases: [{title:'Propose'},{title:'Verify'}] }
const USED = 'USEDSET'
const POL = `
【3字短縮タスク】現在「3字以上」の漢字が割り当てられた語根がある。日中双方に透明な意味を保ったまま、可能な限り【2字以下】のCN標準語へ短縮せよ。
- 2字(または1字)で中心義が立つなら短縮(例: 蛋白质→蛋白, 手榴弹→手雷, 黄道带→黄道, 雌雄同体→两性, 修道院长→院长, 火车头→机车, 降落伞→伞/降伞, 实验室→实验, 办公室→署/公署, 苯=benzene)。
- 真に不可分でCN標準が3字のものだけ3字維持(例: 大理石, 无花果, 染色体, 安乐死, 仙人掌, 龙舌兰, 鸡尾酒, 肉豆蔻 等は短縮で不透明化するなら維持可)。
- 音訳厳禁。CN標準形優先(日本固有語は避ける)。既割当単字との衝突は最終識別子で解消されるので最良の透明字を優先(衝突は気にしてよいが短縮を妨げない)。
`
const PS = { type:'object', additionalProperties:false, required:['root','recommended','keep3','reason'], properties:{ root:{type:'string'}, recommended:{type:'string'}, keep3:{type:'boolean'}, reason:{type:'string'} } }
const VS = { type:'object', additionalProperties:false, required:['root','final','changed','reason'], properties:{ root:{type:'string'}, final:{type:'string'}, changed:{type:'boolean'}, reason:{type:'string'} } }
const ITEMS = ITEMSARR
phase('Propose')
const results = await pipeline(ITEMS,
  (it) => agent(`${POL}\n語根 ${it.root}- 現在の割当「${it.cur}」(${it.cur.length}字) 語義: ${it.gloss}\n2字以下のCN標準の透明な漢字へ短縮を提案。無理なら keep3=true で現状維持。recommended に採用字。root は "${it.root}"。\n既割当単字(参考): ${USED}`, { label:`fix:${it.root}`, phase:'Propose', schema:PS }).then((p)=>({...it,p})),
  (r)=>{ if(!r) return null; const it=r; return agent(`${POL}\n語根 ${it.root}- 現「${it.cur}」 提案「${it.p.recommended}」 keep3=${it.p.keep3} 理由:${it.p.reason}\n検証: 短縮案が(1)2字以下(2)CN標準・透明(3)意味を損なわない なら採用(final=提案, changed=現と異なるか)。短縮で不透明化/非標準化するなら現状維持(final=現「${it.cur}」, changed=false)。root は "${it.root}"。`, { label:`vrf:${it.root}`, phase:'Verify', schema:VS }).then((v)=>({root:it.root,cur:it.cur,gloss:it.gloss,final:v.final,changed:v.changed,reason:v.reason})) }
)
const ok = results.filter(Boolean)
const changed = ok.filter((r)=>r.final && r.final!==r.cur)
log(`完了 ${ok.length} / 変更 ${changed.length}`)
return { results: ok, changed }
'@
$js = $tpl.Replace('USEDSET',$USED).Replace('ITEMSARR',$ITEMS)
$js | Out-File "$dir\_wf_threechar.js" -Encoding UTF8
Write-Host "対象: $($cand.Count) / 生成: _wf_threechar.js"

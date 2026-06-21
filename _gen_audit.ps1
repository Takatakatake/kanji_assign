# 単字内容語の透明性監査ワークフローを生成(フラットITEMS + JS側チャンク化)
param([int]$ChunkSize = 20)
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
$audit = Get-Content -Raw -Encoding UTF8 "$dir\_audit_singlechar.json" | ConvertFrom-Json
$itemsArr = $audit | ForEach-Object { [pscustomobject]@{ root=$_.root; cur=$_.cur; jp=$_.jp; cn=$_.cn } }
$ITEMS = ($itemsArr | ConvertTo-Json -Depth 4 -Compress)
Write-Host "監査対象 $($audit.Count) 語 / chunk=$ChunkSize"

$tpl = @'
export const meta = { name: 'transparency-audit', description: '単字内容語の透明性を監査し不透明な割当を多字へ格上げ提案', phases: [{title:'Audit'}] }
const POLICY = `
【透明性監査】各語根には現在「1字」の簡体字が割り当てられている。その1字を【単独で】見たとき、CN/JP話者に語根の中心義が透明に伝わるかを判定する。
- 透明(例: 爱=愛する, 大=大きい, 友=友達, 山=山, 虎=虎) → transparent=true, final=現状字。
- 不透明: その1字の単独主要義が語根の意味とずれ、意味が二字熟語内でしか立たない場合(例: 使=「使う/使者」で angel(天使)が立たない、动=「動く」で animal/zoology が立たない、理=「理屈」で physics が立たない、号=「番号」で trumpet が立たない) → transparent=false, final=透明な熟語(標準的な現代中国語語、原則2字・必要なら3字、基礎字/少画優先、音訳は避け意味訳)。
- 専門的な動植物・器物などで1字が正確かつ標準なら transparent=true。既に妥当なら無理に変えない。判断は語根の中心義基準。
`
const AS = { type:'object', additionalProperties:false, required:['results'], properties:{ results:{ type:'array', items:{ type:'object', additionalProperties:false, required:['root','transparent','final'], properties:{ root:{type:'string'}, transparent:{type:'boolean'}, final:{type:'string'}, reason:{type:'string'} } } } } }
const ITEMS = ITEMSARR
const CHUNK = CHUNKSIZE
const chunks = []
for(let i=0;i<ITEMS.length;i+=CHUNK){ chunks.push(ITEMS.slice(i,i+CHUNK)) }
phase('Audit')
const results = await pipeline(chunks,
  (chunk) => {
    const lst = chunk.map((it,i)=>`${i+1}. 語根 ${it.root}- 現字「${it.cur}」 / 日:${it.jp} / 中:${it.cn}`).join('\n')
    return agent(`${POLICY}\n次の各語根を監査し、results に root ごとに {root, transparent, final, reason} を返せ。透明なら final=現字、不透明なら final=透明な意味訳熟語。全${chunk.length}件を漏れなく返すこと。\n\n${lst}`, { label:`audit:${chunk[0].root}`, phase:'Audit', schema:AS }).then((r)=>({r}))
  }
)
const ok = results.filter(Boolean)
let all = []
for(const x of ok){ if(x.r && x.r.results){ for(const j of x.r.results){ all.push(j) } } }
const upgrades = all.filter((j)=> j.transparent===false && j.final && j.final.length>=2)
log(`監査完了: ${all.length}語 / 格上げ提案 ${upgrades.length}`)
return { judgments: all, upgrades }
'@
$js = $tpl.Replace('ITEMSARR', $ITEMS).Replace('CHUNKSIZE', "$ChunkSize")
$js | Out-File "$dir\_wf_audit.js" -Encoding UTF8
Write-Host "生成: $dir\_wf_audit.js"

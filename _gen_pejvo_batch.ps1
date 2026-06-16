# PEJVO/PIV 長尾バッチ生成器(未マップセグメント→propose→敵対的検証)
# 使い方: powershell -File _gen_pejvo_batch.ps1 -Num 1 -Size 120 -Offset 0
param([int]$Num=1, [int]$Size=120, [int]$Offset=0)
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613"

# master: USED 単字集合
$usedKanji = New-Object System.Collections.Generic.List[string]; $seenK=@{}
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8 | ForEach-Object {
  $p=$_ -split "`t"; if($p.Count -ge 3){ $k=$p[2].Trim(); if($k.Length -eq 1 -and -not $seenK.ContainsKey($k)){ $seenK[$k]=$true; $usedKanji.Add($k) } }
}
$USED = ($usedKanji -join ' ')

# 未マップ json(頻度降順) を読み、フィルタ
$arr = Get-Content -Raw -Encoding UTF8 "$dir\_pejvo_unmapped.json" | ConvertFrom-Json
$cand = @($arr | Where-Object {
  $_.seg -cmatch '^[a-zĉĝĥĵŝŭ]' -and $_.seg.Length -ge 2 -and $_.seg -notmatch '[!]' -and $_.seg -ne 'c^i'
})
$batch = @($cand | Select-Object -Skip $Offset -First $Size)
Write-Host "候補(lowercase content): $($cand.Count) / バッチ b$($Num): $($batch.Count) 語 (n $($batch[0].n)-$($batch[-1].n))"
$itemsArr = $batch | ForEach-Object { [pscustomobject]@{ seg=$_.seg; n=$_.n; head=$_.head; gloss=$_.gloss } }
$ITEMS = ($itemsArr | ConvertTo-Json -Depth 4 -Compress); if($batch.Count -eq 1){ $ITEMS="[$ITEMS]" }

$tpl = @'
export const meta = { name: 'pejvo-root-kanji-bNUM', description: 'PEJVO/PIV長尾語根バッチBNUMの漢字割当を提案し敵対的に検証', phases: [{title:'Propose'},{title:'Verify'}] }
const USED = 'USEDSET'
const POLICY = `
【漢字化方針(PEJVO/PIV長尾・要約)】辞書のスラッシュ分解セグメント(語根/結合形)に簡体字を意味訳で割り当てる。
- 【原則1字・最大2字】省エネ最優先。1字が中心義を担えば1字(应/界/解/头 等)。1字不可なら**2字で意味を立たせよ**(蛋白质→蛋白, 手榴弹→手雷, 反应堆→堆/核堆 等、2字化を最優先で試みる)。**3字以上は真に不可分な極稀な専門概念のみ**(例外)。多字化の条件は(a)その1字の主要義が語根義を含まない (b)専門・動植物・器物で適切な1字が無い。
- 意味訳のみ・音訳厳禁。意味透明性最重要。日中双方に透明な基礎字。**【字種は《通用规范汉字表》一级3500字のみ】二级・三级・表外字・日本字・繁体専用字は一切不可**。一级で中心義に到達できる代替(一级単字 or 一级のみ2字熟語。やや汎用的でも透明なら可=蟒→巨蛇/蝰→毒蛇)が無ければ**未対応**(二级で妥協しない。碲/烯/醛 等の元素・化学・専門概念は未対応)。**ただし生物種(動植物/魚鳥虫獣等)で一级専用字が無い場合は、未対応でなく《一级にある最も近い生物種字》を当てる**(汎用~近縁で可: 鳗→鱼/鲟→鱼/鼬→近い一级獣字/ブナ→木/アザミ→草/ベリー→果)。
- **稀な語根でも、意味のある内容語(特定の動植物/概念/現象/物質/器物/動作 等)には積極的に良い透明漢字を当てよ**(漢字割当の意義が大きい語根を取りこぼすな)。
- **未対応は最終手段**。専門語でも「2字程度の意味訳」が可能か必ず再考せよ(意味で2字に訳せるなら未対応にせず割り当てる。安易に音訳判定しない)。未対応にするのは: 純粋固有名詞(地名/人名/言語名/宗教固有名)・真の音訳語(意味訳が存在しないコーヒー/カード型)・本当に透明な適字が皆無の語 のみ。final=未対応・problem=音訳 か 固有名詞。
- 宗教・神話語は「意味字があれば意味訳(仏=佛/神=神)、音訳しかなければ未対応(Krist等)」。
- **【公平性・固有名一律未対応】国名・地名・民族名・言語名・住民名・人名は、中国語名が意味透明(音訳でない)でも一律 final=未対応**(日本→未対応・中国→未対応・朝鲜→未対応も同様)。透明な東アジア名だけ漢字を与えるのは漢字圏贔屓ゆえ不可。**ただし翻訳可能な文化・概念・器物の語は対象外で意味訳してよい**(武士=warrior一般概念, 浮世绘, 挂轴 等のmeaning-calque)。
- 日中で主要意味が乖離する字(走/汤/写=写す 等)は同等に透明な代替があれば回避(中国語義基準)。**多字熟語も中国語標準形を選べ**(日本固有語 死体/牡牛/混凝 等は避け、中国語標準の 尸/公牛/混凝土 等に)。
- homonym(同綴り異義: graf=记/伯爵 等)に注意。代表見出しの語義に合う中心義で判断。
- **【最重要・字種最小化R1】既割当字を積極的に再利用せよ=漢字を重複させる方がよい**。短い形(1字・既割当の共有字含む)が中国語で正しく意味するなら必ず共有せよ(衝突は最終識別子パスで解消)。**「既割当だから」を理由に新字を導入したり字を足すのは厳禁**(例: jib=帆でよい、帆がvelと共有でも可。球は6語根で共有OK)。新字導入・字追加・3字化が許されるのは、短い形が**中国語標準で『別の物』を指し学習者が誤読する真の false friend**の時のみ(例: 蓟=アザミ≠アカンサス→叶蓟、疝=ヘルニア≠疝痛→绞痛)。その場合も**可能な限り既割当字の組合せで作り、新字導入を避けよ**。木瓜=パパイア/甘菊=カミツレ のように常用義で通じるものは2字共有形でよい(過度に正確を期して番木瓜/洋甘菊と伸ばすな)。
- 旧PJの修正傾向まとめは典拠にしない。
【既割当単字(衝突は最終識別子パスで解消。同字共有可=中国語が母語的に全義を持つ限りOK)。最も意味透明な字を優先。衝突は申告】:
${USED}
`
const PS = { type:'object', additionalProperties:false, required:['root','recommended','rationale','divergence_risk','collision','confidence'], properties:{ root:{type:'string'}, recommended:{type:'string'}, alt:{type:'array',items:{type:'string'}}, rationale:{type:'string'}, divergence_risk:{type:'string'}, collision:{type:'string'}, confidence:{type:'string',enum:['high','medium','low']} } }
const VS = { type:'object', additionalProperties:false, required:['root','proposed','verdict','final','problem','reason'], properties:{ root:{type:'string'}, proposed:{type:'string'}, verdict:{type:'string',enum:['accept','revise']}, final:{type:'string'}, problem:{type:'string',enum:['音訳','不透明','日中乖離','専門字','冗長2字','固有名詞','なし']}, reason:{type:'string'} } }
const ITEMS = ITEMSARR
phase('Propose')
const results = await pipeline(ITEMS,
  (it) => agent(`${POLICY}\n対象セグメントに最良の簡体字を提案せよ(原則1字)。\nセグメント: ${it.seg}-\n代表見出し: ${it.head}\n語義: ${it.gloss}\n出現回数: ${it.n}\n\n意味訳のみ。音訳になる借用語・固有名詞は recommended を「未対応」とせよ。root は "${it.seg}" を返せ。`, { label:`propose:${it.seg}`, phase:'Propose', schema:PS }).then((p)=>({...it,propose:p})),
  (r) => { if(!r||!r.propose) return null; const it=r; return agent(`${POLICY}\nあなたは敵対的検証者。提案を却下しようと試みよ。\nセグメント: ${it.seg}- (見出し ${it.head})\n語義: ${it.gloss}\n提案:「${it.propose.recommended}」 理由:${it.propose.rationale} 衝突:${it.propose.collision}\nチェック:(1)音訳でない(2)中心義が透明(3)日中乖離で誤読しない(4)**一级3500字のみか**=二级/三级/表外字・日本字/繁体専用字(例 鮟)を使っていないか→一级で透明に表せる代替に置換、一级で無理なら final=未対応(二级で妥協禁止)(5)無駄な冗長熟語でない・既割当だからと不要に字を足していないか(R1: 短い形が正しく意味するなら既割当字を共有せよ)(6)借用語/固有名詞でないか(該当なら final=未対応)。重要:衝突は識別子で解消されるため最良の意味透明字を維持し、同字共有を恐れるな。問題あれば verdict=revise・final に採用字、無ければ accept。root は "${it.seg}" を返せ。`, { label:`verify:${it.seg}`, phase:'Verify', schema:VS }).then((v)=>({seg:it.seg,n:it.n,head:it.head,gloss:it.gloss,propose:it.propose,verify:v})) }
)
const ok = results.filter(Boolean)
const fO = (r)=> r.verify? r.verify.final : r.propose.recommended
const revised = ok.filter((r)=>r.verify&&r.verify.verdict==='revise').map((r)=>({root:r.seg,from:r.propose.recommended,to:r.verify.final,problem:r.verify.problem,reason:r.verify.reason}))
const untargeted = ok.filter((r)=>{const f=fO(r); return !f||f==='未対応'}).map((r)=>r.seg)
log(`検証完了: ${ok.length}語 / revise ${revised.length} / 未対応 ${untargeted.length}`)
return { roots: ok.map((r)=>({root:r.seg,n:r.n,gloss:r.gloss,final:fO(r),verdict:r.verify&&r.verify.verdict,problem:r.verify&&r.verify.problem,alt:r.propose.alt,collision:r.propose.collision,confidence:r.propose.confidence})), revised, untargeted }
'@
$js = $tpl.Replace('NUM',"$Num").Replace('USEDSET',$USED).Replace('ITEMSARR',$ITEMS)
$out = "$dir\_wf_pejvo_b$Num.js"
$js | Out-File $out -Encoding UTF8
Write-Host "生成: $out"

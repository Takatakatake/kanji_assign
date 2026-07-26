# 同綴異義台帳(_homonym.tsv)を網羅版に再構築。型(sep=見出し分離可 / amb=同一文字列→語義判別)を辞書行数で自動判定。
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$lines=Get-Content $dict -Encoding UTF8
# oz/on 動的分類は両版(学習者+学術)をスキャン。学術版の粗分解(fagocit/oz・aktinomicet/oz・deoksi/oz 等の whole-form)も
# 症/糖へ網羅し base 富ᴼ への取りこぼしを防ぐ(2026-06-23 sep派生形網羅)。型判定(下の $n=…$lines)は学習者版のみで不変。
$dictAcad="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt"
$ozLines=@($lines); if(Test-Path $dictAcad){ $ozLines += @(Get-Content $dictAcad -Encoding UTF8) }
# 既存10(全sep)
$existing=@(
 @('graf','伯','graf/o,graf/in/o,graf/land/o,graf/a,graf/ej/o,graf/ec/o,graf/uj/o,land/graf/o,vic/graf/o,burg/o/graf/o,kastel/graf/o','','伯爵(count/earl)→伯。-graf-(graphy記録)=记と別。爵位複合も伯: graf/ej/o領地・graf/ec/o伯爵位・graf/uj/o伯爵領・land/graf/o方伯(landgrave)・vic/graf/o子爵(viscount)・burg/o/graf/o,kastel/graf/o城伯(burgrave)(2026-06-23 sep派生形網羅)'),
 @('epi','后','epi/log/o,epi/taf/o,epi/gon/o,epi/paleo/lit/ik/o','','epi-=後(after)。epi=表(upon上)と別。epi/paleo/lit/ik/o=epipaleolithic(旧石器の後・中石器の前の文化)もepi=后(2026-06-23ユーザー裁定。lit=石は維持)'),
 # 元素救済(2026-06-20): 金属クロム/チタンは「金属→金」(§4.6元素拡張)。素字の prep krom=外・giant titan=巨 と分離。bor(ホウ素=半金属)は境界=保留($forceUnt)。
 @('ant','反','ant/onim/o','','anti-(反対against)→反。反意語antonym(ant/onim=反/名)の anti のみ。現在分詞-ant-(在。abon/ant等30語以上)は在維持(word-scoped)。反はmal/opon/kontra等と同グリフ(新字ゼロ)。2026-07-18 偽友スイープR2'),
 @('krom','金','krom/o,krom/at/o,krom/at/a','','クロム(金属元素)→金。前置詞krom=外と別。krom/at=クロム酸塩→金/盐'),
 # chromo-(色=color。ギリシャ chroma)→色。クロム金属krom=金・前置詞krom=外 とは別綴り同根の第3義(2026-06-23)。
 @('krom','色','krom/o/fotografi/o,krom/o/litografi/o,krom/o/sfer/o,krom/o/fot/o/grafi/o,krom/o/lit/o/grafi/o,kvantum/krom/o/dinamik/o','','chromo-(色=color)→色。量子色力学QCD kvantum/krom/o/dinamik(量子/色/o/力=color charge色荷)。chromosphere彩層(太陽)・chromolithography彩色石版・chromophotography彩色写真。金属クロムkrom/o=金・前置詞krom=外と別綴り同根。2026-07-18偽友スイープR2: 正本再分節(fotografi→fot/o/grafi・litografi→lit/o/grafi)で外に化けた天然色写真krom/o/fot/o/grafi・着色石版krom/o/lit/o/grafiを現行綴りで追加'),
 @('titan','金','titan/o,titan/at/o,titan/at/a','','チタン(金属元素)→金。巨人titan/a=巨と別。titan/at=チタン酸塩→金/盐(krom/borと平行)'),
 @('bor','矿','bor/o,bor/at/o,bor/at/a,bor/o/tartr/at/o,tetra/bor/at/o,fluor/bor/at/o,bor/o/tartrat/o','','ホウ素(半金属元素)→矿。bor/o/tartrat=学術版粗分解(2026-06-23)。掘削bor/i=钻と別。bor/at=ホウ酸塩→矿/盐。bor/o/tartr/at=ホウ酒石酸塩(連結o複合)も矿。tetra/bor/at=四ホウ酸塩・fluor/bor/at=フルオロホウ酸塩(WSL過細分解 Xat→X/at 同期)'),
 @('tetr','四','tetr/','','tetra-接頭辞。鳥tetr/o=琴鸡が既定'),
 @('tetra','四','tetra/,tetra/gram/o,tetra/borat/o,tetra/mer/o,tetra/tionat/o,tetra/ol/o,tetra/bor/at/o','','tetra-数詞接頭辞(4)→四。鳥tetra/o=野鸡(基本形)は除外。tetra/ol→四(2026-06-22 ol精緻化)。tetra/bor/at(WSL過細分解同期)'),
 # 化学接頭 pent-(5炭素鎖=pentose由来)→五。penta=五ᴾ・heks=六ᴴ・tetra=四ᵀ と平行(2026-06-23 最終収束WF)。
 # ※pent/ozan/o(ペントザン=五炭糖多糖)の派生語1件のみ。後悔penti/pent/o/pent/em=悔・縮小辞-et-は別morphemeでdisc不掲載=悔維持。pent/接頭辞定義見出し(pent/⟦悔⟧)もamb(支配義悔)で据置(met置/but培/et小と平行・批評裁定)。
 @('pent','五','pent/ozan/o','','化学接頭pent-(5炭素鎖)→五。pent/ozan=ペントザン(ペントース多糖)。後悔penti=悔・縮小辞-et-とは別morpheme(disc不掲載で悔維持)。penta=五ᴾ/heks=六ᴴと平行。ozanは不透明でlatin維持'),
 @('kaj','码','kaj/o,kaj/oj','','埠頭。接続詞kaj=和と別'),
 @('log','诱','log/i,log/aj^/o,al/log/i,al/log/o,al/log/a,al/log/aj^/o,de/log/i,de/log/o,el/log/i,for/log/i,mal/log/i,log/il/o,log/bird/o,log/fajf/il/o,log/ig^/i,seks/al/log/o,sens/al/log/a,tromp/log/i,seks/log/o','','誘惑(allure/lure)。-log-=学家と別。接頭al/de+log=動詞诱(allogi魅了/delogi誘惑)。seks/al/log・sens/al/log・tromp/log・seks/log(allogo=性的魅力/誘惑)も诱。※連結o付 seks/o/log/o=性科学者は学家(別語)(2026-06-23 sep派生形網羅)'),
 @('c^iel','天','c^iel/o,c^iel/a,c^iel/ark/o,c^iel/ark/a,c^iel/blu/a,c^iel/ir/o,c^iel/e/n/ir/o,c^iel/mekanik/o,c^iel/o/sfer/o,c^iel/rug^/o,c^iel/skrap/ant/o,c^iel/skrap/ul/o,c^iel/tus^/a,c^iel/ul/o,c^iel/an/o,c^iel/fajr/o,sub/c^iel/a,sub/c^iel/e','','空。相関詞c^iel=全样と別。2026-07-07 正本波で c^ielen/ir→c^iel/e/n/ir に-e/n境界正規化されたため c^iel/e/n/ir/o(昇天=c^ieliro)追加(被覆漏れ是正=全样に化けるのを防ぐ)'),
 @('c^ar','车','c^ar/o,c^ar/ist/o,c^ar/eg/o,c^ar/et/o,c^ar/um/o,c^ar/on,c^ar/far/ist/o,c^ar/lev/il/o,au^t/o/c^ar/o,antau^/c^ar/o,post/c^ar/o,bov/o/c^ar/o,c^eval/c^ar/o,bagag^/o/c^ar/o,beb/o/c^ar/et/o,infan/c^ar/et/o,ac^et/c^ar/et/o,pus^/c^ar/et/o,pus^/c^ar/o,fald/c^ar/o,fald/c^ar/et/o,fest/o/c^ar/o,furag^/o/c^ar/o,elektr/o/c^ar/o,krom/c^ar/o,lev/c^ar/o,plen/c^ar/o,s^arg^/o/c^ar/o,serv/o/c^ar/et/o,sid/c^ar/et/o,tir/c^ar/o,trole/c^ar/o','','荷車/車両(ĉaro=cart)→车。接続詞ĉar(因)はdisc不掲載で維持。荷車ĉar系32見出しを網羅(2026-06-21): aŭt/o/ĉar=バス・bov/o/ĉar=牛車・ĉeval/ĉar=馬車・krom/ĉar=側車(外/车)・各乳母車(beb/o/infan/fald)・手押車(puŝ/ĉar/um)・ショッピングカート(aĉet/puŝ)・フォークリフトlev/ĉar・山車fest/o/ĉar・リヤカーtir/ĉar 等'),
 @('nom','学','agr/o/nom/o,agr/o/nom/a,agr/o/nom,astr/o/nom/o,astr/o/nom/a,astr/o/nom,gastr/o/nom/o,gastr/o/nom/a,gastr/o/nom,erg/o/nom/o,erg/o/nom/a,erg/o/nom','','科学-nom-(agronom/astronom/gastronom/ergonom)→学。名前複合(famili/nom/dosier/nom等)は名のまま'),
 # ギリシャ結合形 同綴衝突(2026-06-21・列挙sep)。fon→声と同型だが多義のため見出し列挙。正当語(bo/fil息子・du/lit/aベッド・buter/te茶)は disc 不掲載で保護。全字一级。
 @('fil','爱','bibli/o/fil/o,bibli/o/fil/i/o,pedo/fil/i/o,gastr/o/fil/o,gips/o/fil/o,hidr/o/fil/a,nekr/o/fil/i/o,skop/o/fil/i/o,fil/antrop/o,fil/antrop/i/o,fil/o/logi/o,fil/o/logi/a,fil/o/logi/ist/o,fil/o/log/o','','-fil-(philos=愛/-phile)→爱。語頭philo-(filantrop博愛/filolog文献学=言葉への愛)も含む(2026-06-22)。filo=息子(儿)はbo/du-on/adopt-o/bapt-o/pra/sol/ge/sen-fil で維持(disc不掲載)。filogenez=phylon系統は別語源で対象外'),
 @('per','过','per/oksid/o,per/oksid/i,per/oksid/a,per/oksid/az/o,per/klor/at/o,per/sulf/at/o,per/sulf/at/oj,per/klorat/o,per/oksidaz/o,per/sulfat/oj,per/mangan/at/o','','per-(化学:過酸化/過…)→过。前置詞per=以 は別。学術版粗分解 per/klorat/per/oksidaz/per/sulfat も过・per/mangan/at=過マンガン酸塩(両版)も过(2026-06-23 sep派生形網羅)'),
 @('oks','氧','an/oks/emi/o,hipoks/emi/o,oks/oni/o','','oxy-(酸素)→氧。牛oks/o=牛 は別。2026-07-26 正本ドリフトで oksoni/o→oks/oni/o に分解され oks が牛ᴼ(雄牛)で描画される誤友が露出→disc追加で氧に是正(oni=オニウムイオンはL148の化学ルールでlatin保持)'),
 # 2026-07-26 正本ドリフト是正: hermafrodit(両性具有)が herm/afrodit へ##エス的分解され、
 #   afrodit が同綴の【動】Aphrodita(ウロコムシ属)=虫ᴬᴰ で描画される誤友が露出(两性→herm/虫ᴬᴰ の品質後退)。
 #   §3.1「同綴誤友の是正」に従い word-scoped sep で是正。従来の見た目 两性 を分解鏡像として維持する
 #   (herm=Hermes男神 + afrodit=Aphrodite女神 → 两/性 = 両性)。herm/o(【PIV】ヘルメス柱像)・Herm/o(固有名)は
 #   disc非掲載ゆえ不発火、afrodit/o(ウロコムシ)も虫ᴬᴰ を維持。
 @('herm','两','herm/afrodit/a,herm/afrodit/ec/o,herm/afrodit/o,herm/afrodit/flor/a,pseu^do/herm/afrodit/ec/o','','herm-(Hermes)→两: hermafrodit=両性具有 の分解鏡像 两/性。彫像 herm/o は disc外で latin 維持'),
 # 2026-07-26 別AI監査の指摘: aer/o/sol/o が 气/o/唯 (=「空気だけ」)と誤描画。sol は【化】ゾル(コロイド)であり
 #   同綴の sol/a=唯一(唯)とは別語。中国語 气溶胶 に合わせ 胶(既存 glu=胶)へ word-scoped sep。
 #   sol/o は【化】ゾルと「ただ一人/独奏」が同一綴りの amb ゆえ disc に載せず、唯 を維持する。
 @('sol','胶','aer/o/sol/o','','sol(【化】ゾル=コロイド)→胶: 气溶胶(aerosol)。同綴 sol/a=唯一 は唯を維持。sol/o は amb(化学ゾルと独奏が同綴)ゆえ disc非掲載'),
 @('afrodit','性','herm/afrodit/a,herm/afrodit/ec/o,herm/afrodit/o,herm/afrodit/flor/a,pseu^do/herm/afrodit/ec/o','','afrodit-(Aphrodite)→性: 上記 herm=两 と対で 两性。同綴の【動】Aphrodita(ウロコムシ属)=虫ᴬᴰ は disc外で維持'),
 @('leu^k','白','leu^k/emi/o,leu^k/oz/o','','leuko-(白)→白(白血病·白血球增多症)。leu^ko=白ᴸ は別root。2026-07-19 正本ドリフト leukoz→leu^k/oz 露出で leu^k latin残([F]不整合)→白(白/富=白血球增多)で整合'),
 # PIV航海語 jul/o(艫でひねって漕ぐ櫓=yuloh)・jul/ad/i(櫓で漕ぐ)→漕ぐhub划(=rem。パドルpagaj=划ᴾᴳと同型・新字ゼロ)。クリスマス系 jul/arb/o=圣诞/树 は別見出しで維持(2026-07-04ユーザー裁定sep分離)。※$hsepは大小無視だが Jul/o(大文字=ユール祭)は固有名ガードがhsepより先に捕捉し注釈なしで無影響=衝突せず。jul/arb/o は見出し文字列がjul/oと異なるため非該当で圣诞/树維持
 @('jul','划','jul/o,jul/ad/i','','【PIV】航海 jul/o=艫でひねる櫓(yuloh)・jul/ad/i=櫓で漕ぐ→漕ぐhub划。クリスマス系(jul/arb/o=圣诞/树・Jul/o=圣诞ユール祭)は別見出しで維持。2026-07-04ユーザー裁定sep分離'),
 # -ator両義対応(2026-07-04): 装置義(=X-ilo)=具ᴬ(既定)、人物義(-anto/-isto/-ulo相当)=员(an=员hub合流・新字ゼロ)。PIV正式分解波(##偽分解マーカー)で露出。
 @('ator','员','administr/ator/o,spekt/ator/o,uzurp/ator/o,prestidigit/ator/o','','-ator人物義→员。administranto管理者/spektanto観客/uzurpulo簒奪者/prestidigitisto手品師。装置義ator=具ᴬは既定のまま(altern/gener/kondens等)。numer/ator(数学分子)は号具のまま=PIV語源合成(要裁定なら変更)'),
 @('astat','卤','astat/o','','-astat-(元素アスタチンAt=halogeno)→卤(液体ハロゲンbrom=卤と同カテゴリ§4.6)。astat/a=astatic(無定位)=无定 はmaster維持(disc不掲載)。astaten(=astato)はmaster卤'),
 @('lit','石','aer/o/lit/o,mega/lit/a,mega/lit/o,mono/lit/a,mono/lit/o,neo/lit/ik/o,paleo/lit/ik/o,epi/paleo/lit/ik/o,mez/o/lit/ik/o,mikro/lit/a,mikro/lit/o,piz/o/lit/o,fot/o/lit/o/grafi/o,krom/o/lit/o/grafi/o,lit/o/graf/o,lit/o/graf/i,lit/o/grafi/o,lit/o/graf/aj^/o,lit/o/graf/ist/o,lit/o/logi/o,lit/o/sfer/o,lit/o/skop/o,lit/o/tomi/o','','-lit-(lithos=石/-lith)→石。lito=寝台(床)はdu/kvar/tri/unu-lit/a・klap/krad/pend/port/ter/sof-o/pajl-o-lit で維持。elektrolit=-lyte(別形態素)は別sep lit→解(2026-06-23ユーザー裁定)。2026-07-18偽友スイープ: 石版印刷litograf系5形・岩石学litologi・岩石圏litosfer・膀胱結石litoskop/litotomi(医)を追加(床=寝台の誤友是正)'),
 # electrolyte の -lyte(溶解/分解。-lith石とは別形態素)→解。中国語「电解质」と一致(2026-06-23ユーザー裁定)。
 @('lit','解','elektr/o/lit/o,elektr/o/lit/a','','-lyte(電解質electrolyte=溶解/分解する物)→解。中国語 电解质 と一致。lithos=石(-lith)とは別形態素・寝台lit/o=床とも別'),
 @('te','神','a/te/ism/o,a/te/ist/a,a/te/ist/o,mono/te/ism/o,mono/te/ist/o,pan/te/ism/a,pan/te/ism/o,pan/te/ist/o,poli/te/ism/o,poli/te/ist/o,te/o/krati/a,te/o/krati/o,te/o/krat/o,te/o/logi/a,te/o/logi/ist/o,te/o/logi/o,te/o/log/o,te/o/goni/o,te/ism/o,te/ist/o','','-te-(theo=神)→神。teo=茶(茶)はbuter/te で維持(disc不掲載)。te/ism/o=有神論・te/ist/o=有神論者(theism/theist)も神(2026-06-23 sep派生形網羅)。2026-07-06 正本波でte/o/goni/o(神統記theogonia)露出→被覆漏れ是正で追加(teokrati/teologiと同神)'),
 @('top','境','bio/top/o','','-top-(topos=場所/-tope)→境(生境=habitat)。topo=檣楼(帆楼)はtop/o単独で維持'),
 # 2026-07-25 続17(ユーザー裁定): DICT正本が interpol/i→inter/pol/i・interpol/aj^/o→inter/pol/aj^/o と分割したため
 # 学習者版で whole-root interpol(插ᴵᵀ)が引けなくなり 间/pol と版間・版内が割れた。pol は未割当かつ pol/o=ポーランド人と
 # 同綴ゆえ master への単純割当は不可 → 数学義の見出しに限定した sep で 插 へ合流させる(新字ゼロ=插は既存)。
 # 識別子はハードコードせず _homonym_disp.ps1 が插群(stik=bare/insert=插ᴵ/interpol=插ᴵᵀ)に pol を入れて算出する
 # (p は插群で未使用ゆえ 插ᴾ)。結果 内挿=间/插ᴾ・外挿=外ᴱ/插ᴾ で日中の「内挿/外挿・内插/外插」と literal 一致し、
 # 元からラテンだった ekster/pol も同時に解消。ポーランド義(pol/a・pol/o・pol/a lingv/o)は disc 不掲載=ラテン維持。
 @('pol','插','inter/pol/i,inter/pol/aj^/o,ekster/pol/i,ekster/pol/o,pol/i','','【数】pol-(補間/補外 interpolate/extrapolate)→插(挿入)。既存 interpol/o=插ᴵᵀ・insert=插ᴵ・stik=插(基本形)と同hub。ポーランドpol/o・pol/a・pol/a lingv/oは§7固有名でラテン維持(disc不掲載)。DICT正本の PIV正式分解(inter/pol・ekster/pol)露出への追随'),
 # -goni-(-gony/-gonia=生成·発生·原細胞。ギリシャgonḗ「産む·種」)→源。角度goni/o=角ᴳ(ギリシャgōnía「角」=goniometr角度計等)は別語源の同綴ゆえ維持=homograph sep分離(2026-07-06ユーザー裁定)。genez/o=源ᴳ(genesis)と同源で「起源·生成」を的中。
 @('goni','源','kosm/o/goni/o,ov/o/goni/o,sperm/o/goni/o,spor/o/goni/o,te/o/goni/o','','-goni-(生成·発生·原細胞gonḗ)→源。宇宙起源kosmogoni=宇/源·神々の起源teogoni=神ᵀ/源·卵原ov/精原sperm/胞原spor/o/goni=卵·精液·胞子+源。角度goni=角ᴳ(gōnía別語源)は正本が X/o/goni へ分割した際に生成義へ化ける誤友ゆえ語スコープで是正。arkegoni=颈卵器(whole-root)·agoni=垂死·tetragoni=草ᵀᴱᵀ(植物属)·begoni/pelargoni/geraniは別語で不干渉'),
 # WSL最新分解(2026-06-21)同期で露出した結合形(多義のため列挙sep)。-cyte=胞。主義(引=citi引用)は disc不掲載で保護。
 # ※-poez-(造血·-poiesis)=生 は master poez=生 へ昇格(2026-06-22)。poez は詩義を持たず常に poiesis=生(詩は別語根 poezi=诗)。bare poez/o と複合の id 整合のため sep は廃止。
 @('il','基','aceton/il/o,benzo/il/o,form/i/il/o,fosfor/il/o,jod/il/o,karbon/il/o,kromi/il/o,benzo/il/i,fosfor/il/i,fosfor/il/ad/o,benzo/il-glicin/o','','化学ラジカル-il(-yl原子団)→基。器具-il=具は別。動詞/派生 benzo/il/i,fosfor/il/i,fosfor/il/ad/o,benzo/il-glicin/o(馬尿酸)も基(2026-06-23 sep派生形網羅)'),
 @('mon','单','mon/ism/o,mon/ist/o','','monos(単一)→单。金銭mon=钱は別'),
 @('au^t','自','au^t/ism/o,au^t/ism/ul/o,au^t/ism/a,au^t/o/bio/grafi/o,au^t/o/grafi/o,au^t/o/graf/o,au^t/o/krati/o,au^t/o/krat/ism/o,au^t/o/krat/o,au^t/o/krat/a,au^t/o/krat/ec/o,au^t/o/liz/o,au^t/o/gen/a,au^t/o/gen/o,au^t/o/gami/o,au^t/o/gir/o,au^t/o/kataliz/o,au^t/o/morfi/o,tele/au^t/o/graf/i,tele/au^t/o/graf/o','','auto-(自己)→自。自動車au^t/o/mobil=车は除外。au^t/o/gen=自家生成(WSL同期)。2026-07-15 自己義の取りこぼし追加(ユーザー裁定): au^t/o/gami=自家受精(memfekundig^o)・au^t/o/gir=オートジャイロ(自転翼)・au^t/o/kataliz=自己触媒(memkatalizo)・au^t/o/morfi=自己同型(sur g^in mem)・tele/au^t/o/graf=書画電送(自筆遠隔)。基本形車 au^t/o/mobil等は据置'),
 # autokrat専制の-krat-(専断的支配)→专。au^t=自(上のsep維持)+krat=专で「自专」=自己による専断支配=autocracy。治(krat master=统治)のままだと自治(autonomy=au^tonom)と同字別義衝突し「自律・自治権」に誤読される→明白誤解ゆえ語スコープで是正(2026-07-19ユーザー裁定)。teokrat=神治(神による支配=theocracy)等はmaster治維持で不干渉。学術版whole-word au^tokrat=专制と方向一致(版差=自专/专制は容認)。
 @('krat','专','au^t/o/krat/ism/o,au^t/o/krat/o,au^t/o/krat/a,au^t/o/krat/ec/o','','autokrat(専制)の-krat-→专。auto=自(自专=自己専断支配)。自治au^tonom(autonomy)との同字別義衝突を是正。teokrat神治/demokrat等unsplit(民)は不干渉。2026-07-19ユーザー裁定'),
 # au^t/o/krati/o は分節が krati(krat+i融合)ゆえ上の krat→专 sep が不発火。krati→专 を別途スコープ(治ᴷᴵ→专で自治衝突を解消)。teokrati=神治(te/o/krati)はmaster治維持で不干渉。
 @('krati','专','au^t/o/krati/o','','autokrati(専制政治)の krati分節→专。自专治→自专。te/o/krati=神治は不干渉。2026-07-19ユーザー裁定'),
 @('atm','气','atm/o/metr/o','','atmo-(大気·蒸気=希atmos)→气。蒸発計atmometr(atm/o/metr=气/计)。真我atm/o=我(atman=ヒンドゥー哲学の個我)はbase維持。大気atmosfer=气と同義だが別root(2026-07-15 誤友是正: 我=atmanの取りこぼしをword-scopedで是正)'),
 @('kok','菌','mikro/kok/o,diplo/kok/o,enter/o/kok/o,mening/o/kok/o','','-coccus(球菌)→菌。鶏kok=鸡は別'),
 @('poli','灰','poli/o/mjel/it/o,poli/o/bulb/it/o,poli/o/encefal/it/o,poli/o/bulbit/o,poli/o/encefalit/o','','polio-(灰白質=griza substanco mjela/cerba。PIV原本polio/定義)→灰。学術版は粗分節(poli/o/bulbit・poli/o/encefalit)ゆえ両granularityを列挙。急性灰白髓炎poliomjelit(灰/髓/炎)・灰白延髄炎poliobulbit(bulb延髓=球・灰/球/炎)・灰白脳炎polioencefalit(灰/脑/炎)。多義poly-(多:poligami多婚/poliglot多言語/polimer重合体/politeism多神)は多維持=word-scoped。2026-07-19 別AI監査是正: 学習者版poli=多ᴾ誤友(polio灰白質≠poly多)を是正。学術版poliomjelit=灰髓炎は既に正'),
 @('diplo','双','diplo/kok/o,diplo/pod/oj','','diplo-(希διπλόος=二重/double)→双。双球菌diplococcus(diplo/kok=双/菌)・倍足綱Diplopoda(diplo/pod=双/足)。頭蓋の板障diplo/o(diploe=海綿骨層)=板障は単独で維持・diploid二倍/diplomat外交/diplom証書は別語で不干渉。2026-07-19 偽友是正: diplo=double を diploe板障の同綴誤友から是正(polio灰型)'),
 # fiziologi(生理学)の fizi- は希φύσις(physis=自然·生命)由来で物理physics(fizik=物理)とは同綴別義。物理/学のままだと{Ｏ}生理学の語釈と矛盾し「物理学」に誤読される→明白誤解ゆえ語スコープで fizi→生理(生理/学=生理学)に是正(2026-07-19ユーザー裁定)。物理学fizik/o=物理・fizi/o(物理)は不干渉。polio灰/goni源型の同綴弁別。
 @('fizi','生理','fizi/o/logi/o,fizi/o/log/o,fizi/o/logi/a,plant/fizi/o/logi/o,psik/o/fizi/o/logi/o','','fiziologi(physis=生命)→生理。生理学(生理/学)。物理physics(fizik=物理)は同綴別義で不干渉。2026-07-19ユーザー裁定: {Ｏ}生理学との矛盾是正'),
 # antigen(抗原)の -gen は「抗体を生じさせる源」=希gennáō。生のままだと抗生=抗生素(antibiotiko)を想起し【医】抗原の語釈と矛盾→明白誤解ゆえ語スコープで gen→原(抗/原=抗原)に是正(2026-07-19ユーザー裁定)。genez生成/‑gen生(epilepsigen等)/au^togen自家生成は master生維持で不干渉。
 @('gen','原','anti/gen/o','','antigen(抗原)の-gen→原。抗/原=抗原。抗生(=antibiotiko想起)との誤読を是正。‑gen生/genez生成は不干渉。2026-07-19ユーザー裁定'),
 @('strat','层','kron/o/strat/i/grafi/o,strat/i/graf/o,strat/i/grafi/o,stratum/o','','stratum(地層)→层。街strat=街は別'),
 @('cit','胞','fag/o/cit/ad/o,fag/o/cit/i,fag/o/cit/o,fag/o/cit/oz/o,granul/o/cit/o,hiper/granul/o/cit/emi/o,hipo/granul/o/cit/emi/o,leu^ko/cit/o,leu^ko/cit/o/poez/o,leu^ko/cit/oz/o,limf/o/cit/o,ov/o/cit/o,spermat/o/cit/o,tromb/o/cit/o,eritr/o/cit/o,eritr/o/cit/o/poez/o,hiper/eritr/o/cit/emi/o,cit/oz/o,el/cit/oz/o,ekzo/cit/oz/o,en/cit/oz/o,endo/cit/oz/o','','-cyt-(細胞·-cyte)→胞。citi=引(re/cit・mis/cit・supr/e/cit)は保持。cit/oz(エキソ/エンドサイトーシス等)の接頭辞派生も胞(2026-06-23 sep派生形網羅。2026-07-03 WSL再分解 eritrocit→eritr/o/cit 露出で赤血球系eritr/o/cit/o・eritr/o/cit/o/poez/o 追加。2026-07-04 hiper/eritr/o/cit/emi/o(赤血球増加血症)追加=引=cite誤適用是正)'),
 # 結合形フォルスフレンド是正(2026-06-21・列挙sep)。phago=吞・thrombo=栓。主義(树=ブナ / 龙卷=竜巻)は disc不掲載で保護。一级:吞7画/栓10画。fag/trombはmasterに残し(树/龙卷)、医学文脈の見出しのみ上書き。
 @('fag','吞','bakteri/o/fag/o,fag/o/cit/ad/o,fag/o/cit/i,fag/o/cit/o,fag/o/cit/oz/o,antrop/o/fag/o,antrop/o/fag/ism/o,makr/o/fag/o','','-phago-/-phage(貪食)→吞。ブナfag/o(树)はfag/o,fag/ar/o,fag/ej/o,fag/o/frukt/o,fag/o/nuks/o,fag/ac/oj,sang/o/fag/o(赤葉ブナ),s^ajn/fag/o(ナンキョクブナ)で維持。ezofag(食道)/fagopir(蕎麦)/fagot(ファゴット)は別セグメントで無影響'),
 @('tromb','栓','tromb/oz/o,tromb/ektomi/o,tromb/o/cit/o','','-thrombo-(血栓)→栓。tromb/oz/o は cerb/a tromb/oz/o(脳血栓)内の同語も捕捉。竜巻tromb/o(気·第1義)とsabl/a tromb/o(陸竜巻)は龙卷を維持。trombon(トロンボーン)/trombin(トロンビン)/trombidi(ツツガムシ)は別セグメントで無影響'),
 # 結合形フォルスフレンド第2弾(2026-06-21・列挙sep)。網羅スイープで検出。各主義はmaster維持(热/锅/肾/我/神。patiはsuf情)、医学・数学文脈の見出しのみ上書き。一级:项病再肌二。
 @('term','项','term/o,du/term/o,tri/term/o','','terminus(数項·論名辞)→项。thermo(termometr/izoterm/termodinamik等は別語文字列)は热維持。bare term/o=【数】項;【論】名辞なので项'),
 @('pati','病','aden/o/pati/o,aden/pati/o,encefal/o/pati/o,kardi/o/pati/o,kardi/mi/o/pati/o,kinez/o/pati/o,koks/o/pati/o,limf/aden/o/pati/o,medol/o/pati/o,medol/pati/o,mi/o/pati/o,mjel/o/pati/o,nefr/o/pati/o,neu^r/o/pati/o,ost/o/pati/o,pati/o,pneu^mon/o/pati/o,psik/o/pati/o,psik/o/pati/ul/o,retin/o/pati/o,trik/o/pati/o,ost/e/o/pati/o,alo/pati/o,homeo/pati/o,homeo/pati/a','','-pathy(臓器疾患·療法)→病。逆症療法alo/pati(异/病)·同種療法homeo/pati(homeo/病)も医療体系ゆえ病。感情系 a/pati(無感動)·anti/pati(反感)·tele/pati(テレパシー) と simpati(亲) は情/亲のまま維持(disc不掲載)。2026-07-19 監査: alo/homeo/pati追加'),
 @('pat','病','pat/o/gen/a,pat/o/logi/a,pat/o/logi/o,pat/o/log/o,pat/o/genez/o,fit/o/pat/o/logi/o,plant/pat/o/logi/o,psik/o/pat/o/logi/o,sem/pat/o/logi/o,psik/o/pat/o','','patho-(病理·病原)→病。フライパンpat/o(锅)·チェスstalemate pat(困amb)は锅のまま維持(disc不掲載)。psik/o/pat/o=精神病質者も病'),
 @('ren','再','ren/ir/i','','古語接頭ren(=re再び·reniri帰る)→再。腎臓ren/o(肾)は維持(disc不掲載)'),
 @('mi','肌','mi/o,mi/it/o,mi/o/pati/o,mi/o/kardi/o,mi/o/fibr/it/o,mi/o/fibrit/o,mi/o/globin/o,mi/o/glob/in/o,mi/o/sarkom/o,kardi/mi/o/pati/o,mi/om/o,mi/on/o','','myo-(筋肉)→肌。代名詞mi(我)·所有mi/aj^/o(私の物=我)は維持(disc不掲載)。2026-07-18偽友スイープ: 筋腫mi/om・筋節mi/on・筋グロビンmi/o/glob/in(正本再分節globin→glob/in)追加(我=代名詞の誤友是正)。2026-07-20 学術版粗分節mi/o/fibrit/o追加(学習者mi/o/fibr/it/oと粒度差=学術のみmi=我偽友残存→肌。fibrit→纤炎はp_work併用で肌纤炎に)'),
 @('di','二','di/,di/morf/a,di/morf/ec/o,di/morf/ism/o,di/ploid/a,di/pod/o,di/pod/ed/oj,di/gram/o,di/kotiledon/oj,di/al/o,di/azot/o,di/azot/i,di/azot/at/o,di/metoksi/fenol/o,di/kromiat/o,di/mer/o,di/sakarid/o,di/tionat/o,di/sulf/id/o,di/oksid/o,di/klor/id/o,di/pter/oj,di/valent/a,karbon/di/oksid/o,sulfur/di/oksid/o,di/ol/o,di/ol/oj,di/kromi/at/o,di/sakar/id/o,di/som/a,di/met/oksi/fenol/o,di/odont/o','','数詞di-(2)→二。di/kromi/at重クロム酸塩・di/sakar/id二糖(WSL過細分解 Xat→X/at・Xid→X/id 同期)。di/odont(Diodon二歯魚=二/齿。2026-07-18 分類名分解パスで露出・di/pter双翅と同型)。神di/o系(di/o/tim神畏敬·di/skarab神甲=テントウムシ)は神維持(disc不掲載)。di/pter双翅·di/klor/id二塩化等のエス的分解##偽分解(PIV正式)を尊重し透明化。2026-07-03 WSL再分解でdisom→di/som(二体)・dimetoksi→di/met/oksi(二…)露出→di/som/a・di/met/oksi/fenol/o 追加'),
 @('mega','巨','mega/fon/o,mega/teri/o,mega/lit/a,mega/lit/o','','ギリシャ接頭mega-(大·巨 mégas)→巨(megalo=巨ᴹと同源)。megaphone拡声器(mega/fon=巨/声)·Megatherium大ナマケモノ(mega/teri=巨/兽)·megalith巨石(mega/lit=巨/石)。SI接頭mega-(10^6=百万)=mega/bajt百万/字节·mega/herc·mega/om·mega/tun·mega/elektr/on/volt は百万維持(disc不掲載)。2026-07-18 分類名分解パスで露出/2026-07-19 megalith追加'),
 @('bat','深','bat/o/metr/o,bat/o/metri/o','','bathy-(希βαθύς=深)→深。深度計bathometer(bat/o/metr=深/计)・測深学bathymetria(bat/o/metri=深/测)の bat のみ。打撃bat/i・bat/o(打)・心拍kor/bat は打維持(word-scoped)。2026-07-18 偽友スイープ是正'),
 @('halo','盐','halo/fit/o','','halo-(希ἅλς hals=塩)→盐。塩生植物halophyte(halo/fit=盐/植)の halo のみ。かさ・ハレーションhalo/o(晕)・電話「もしもし」halo は晕維持(word-scoped)。2026-07-18 偽友スイープ是正'),
 # methoxy過細分解露出(2026-07-03)。-met-(甲基methyl)→甲(旧whole-word metoksi=甲氧の復元)。動詞met/i=置(al/de/kun/en/dis/for-met/i等78語)はword-scopedで不干渉。
 @('met','甲','di/met/oksi/fenol/o','','methoxy中の-met-(甲基methyl)→甲。旧whole-word metoksi=甲氧を過細分解で露出(di/met/oksi/fenol)。動詞met/i=置(置く)は列挙語のみ上書きのword-scopedゆえ78語すべて保持'),
 # 結合形フォルスフレンド第3弾(2026-06-21・最終網羅スイープworkflow6agent検出)。各主義master維持、科学/医学文脈の見出しのみ上書き。一级:全时共向心种火压光耳尿根指图字。
 @('gram','图','aer/o/gram/o,anem/o/gram/o,dia/gram/o,elektr/o/kardi/o/gram/o,encefal/o/gram/o,faz/dia/gram/o,faz/o/dia/gram/o,hips/o/gram/o,holo/gram/o,kabl/o/gram/o,kardi/o/gram/o,nivel/dia/gram/o,organi/gram/o,orto/gram/o,paralel/o/gram/o,radi/o/gram/o,radi/o/tele/gram/o,scintil/o/gram/o,seism/o/gram/o,spektr/o/gram/o,tefi/gram/o,tele/gram/o,tele/gram/kod/o,tele/gram/port/ist/o,penta/gram/o,gram/o/fon/o,gram/o/fon/disk/o,-gram/','','-gram(記録·図像γράμμα)→图。重量gram(克):kilo/centi/mili/deka/hekto-gram·gram/atom·gram/molekul·gram/pez は克維持。文字義は字(別エントリ。表音文字fon/o/gram=声/字も字へ移管)。蓄音機gram/o/fon(記録音→图/声)も捕捉。接尾辞定義entry -gram/(=記録·図像の意)→图(ハイフン分岐のhsep下位分節適用)。dia/gram/oはflor/a等多語も捕捉'),
 @('gram','字','di/gram/o,ide/o/gram/o,mono/gram/o,tetra/gram/o,epi/gram/o,epi/gram/ist/o,fon/o/gram/o','','-gram(文字·書記素)→字。digraph二字·表意文字·組合せ文字·聖四文字·警句epigram(epi/gram=表ᴱ/字ᴳ)·表音文字phonogram(fon/o/gram=声ᶠᴼ/字ᴳ=音を表す文字。fon→声はfon sep)。記録図像は图·重量は克。2026-06-21 epigram/phonogram追加'),
 @('pan','全','pan/kromat/a,pan/te/ism/o,pan/te/ist/o,pan/te/ism/a,pan/slav/ism/o','','pan-(汎·全all)→全。パンpan/o(面包)·pan/ej/pan/um/pan/tranc^等は維持'),
 @('kron','时','izo/kron/a,izo/kron/ec/o,kron/o/graf/i,kron/o/graf/o,kron/o/logi/a,kron/o/logi/o,kron/o/metr/i,kron/o/metri/o,kron/o/metr/o,kron/o/metri/a,kron/o/metr/ist/o,kron/o/strat/i/grafi/o,sin/kron/a,sin/kron/ec/o,sin/kron/ig/i,sin/kron/ig/il/o,sin/kron/o/skop/o,post/sin/kron/ig/i,post/sin/kron/ig/o,mal/sin/kron/ig^/i,dia/kron/a,dendro/kron/o/log/o,dendro/kron/o/logi/o,geo/kron/o/logi/o','','chrono-(時)→时。王冠kron/o(冠)·戴冠kron/ad·冠状ウイルス·皇太子·コロナ放電kron/efluv·dethrone sen/kron/igは冠維持·クローネ通貨は币'),
 @('sin','共','sin/kron/a,sin/kron/ec/o,sin/kron/ig/i,sin/kron/ig/il/o,sin/kron/o/skop/o,post/sin/kron/ig/i,post/sin/kron/ig/o,mal/sin/kron/ig^/i,sin/onim/a,sin/onim/ec/o,sin/onim/o,sin/onim/ik/o,sin/artr/o,sin/ost/o','','syn-(共·同together)→共。胸sin/o(怀)·再帰sin(自)は別エントリで維持。2026-07-18 正本過細分解で露出: sin/artr(synarthrosis癒合関節=共/节)·sin/ost(synostosis骨癒合=共/骨)追加(syn-の偽友sin=怀を是正)'),
 @('sin','自','sin/kon/o,sin/asekur/o,sin/dev/ig/ad/o,sin/g^en/o,sin/g^en/ad/o,sin/kapt/ad/o,sin/mem/kulp/ig/o,sin/masturb/o,sin/nutr/ad/o,sin/pel/ad/o,sin/venen/ad/o','','再帰代名詞sin(si対格=自己oneself)→自。syn-(共)·胸sin/o(怀)は別義で維持(disc別記)。sin/mem/kulp/ig=自/自(mem=自と重複もR1衝突歓迎)。両版同11見出し'),
 @('trop','向','helio/trop/o,helio/trop/kolor/a,helio/trop/ism/o,izo/trop/a,izo/trop/ec/o,ne/izo/trop/a,ne/izo/trop/ec/o,an/izo/trop/a,trop/ism/o,cito/trop/a,enantio/trop/a,enantio/trop/ec/o,enantio/trop/ism/o,fot/o/trop/ism/o,geo/trop/ism/o,kortik/o/trop/a,neu^r/o/trop/a,tikso/trop/a,tikso/trop/ec/o,tiro/trop/a,-trop/','','-tropos(向·屈性)→向。修辞trop/o(喻)は維持。tropik热带/antrop人は別セグメント。2026-07-07 正本波で foto/trop/ism→fot/o/trop/ism・kortiko/trop→kortik/o/trop に-o境界正規化されたため語形更新(被覆漏れ是正=喻に化けるのを防ぐ)。2026-07-24 別AI round6被覆漏れ是正: tiro/trop/a(甲状腺刺激thyrotropic=甲状腺への向性)+接尾定義見出し -trop/(=havanta afinecon「向性」・-gram/と同型のハイフン分岐hsep適用)を追加=喻(修辞)に化けるのを防ぐ。既存向ᵀ使用で字種増やさず'),
 @('kard','心','endo/kard/it/o,endo/kard/o,peri/kard/o','','cardio-(心)→心。アザミkard/o(刺草)·梳毛kard/adは維持。kardi/o(-i付)は既に心ᴷᴰ。endo/kard/o=心内膜・peri/kard/o=心膜(WSL同期2026-06-27)'),
 @('pir','火','pir/heli/o/metr/o,pir/geo/metr/o,pir/o/elektr/a,pir/o/magnet/a,pir/o/teknik/aj^/o,pir/o/teknik/ist/o,pir/o/teknik/o,pir/o/liz/i,pir/o/liz/o,pir/o/metr/o,pir/o/fosf/at/o,pir/o/gajl/o,pir/o/gajlol/o,pir/o/sulf/at/o,pir/o/sulf/it/o,pir/o/fosfat/o,pir/oz/o','','pyro-(火·熱)→火。pir/o/fosfat=学術版粗分解(2026-06-23)。胸やけpirozo=火/症(pyrosis灼熱感。2026-07-19正本ドリフト piroz→pir/oz 露出)。洋ナシpir/o(梨)·pir/arb/pir/uj/pir/vinは維持'),
 @('bar','压','izo/bar/o,mili/bar/o,bar/o/graf/o,bar/o/metr/o,bar/o/skop/o','','baro-(気圧)→压。障害bar/i/bar/il/o(障)は維持。bar/o単独=障/圧二義はamb的に障維持'),
 @('fot','光','fot/on/o,fot/o/sfer/o,fot/o/sintez/o,fot/o/c^el/o,fot/o/kemi/o,fot/o/kemi/a,fot/o/metri/o,fot/o/metr/o,flagr/o/fot/o/metr/o,fot/o/metri/i,fot/o/jon/ig/i,fot/o/kondukt/iv/a,fot/o/liz/i,fot/o/terapi/o,fot/o/volta/a,fot/on/mikro/skop/o,fot/o/trop/ism/o','','photo-(光)→光(物理·化学·生物)。写真fot/o/fot/i/fot/o/graf等は拍維持。2026-07-07 正本波でfoto/trop/ism→fot/o/trop/ism露出→fot/o/trop/ism/o追加(Lumtropismo=光屈性ゆえ光。拍=写真は誤友)。複合語内の光物理/光化学派生も光へ網羅(2026-06-25 接尾辞悉皆監査の派生メモから: fot/o/kemi/a光化学[スモッグ/酸化剤句もカバー]・fot/o/jon/ig光電離・fot/o/kondukt/iv光伝導・fot/o/liz光解・fot/o/terapi光線療法・fot/o/volta光起電・fot/on/mikro/skop光子顕微鏡。hsep whole-word盲点の補完=al/翼と同型)'),
 @('ot','耳','ot/o,ot/it/o,ot/algi/o,ot/o/logi/o,ot/o/skop/o,ot/o/skop/i/o,ot/o-rin/o-laring/o/log/o,ot/o/rin/o/laring/o/logi/o,ot/o/salping/o,ot/o/salping/it/o,ot/o-rin/o-laringolog/o,ot/o/salpingit/o,ot/a','','oto-(耳)→耳。未来受動分詞-ot-(待。nask/ot/vend/ot/a等)は維持。2026-07-15 監査是正: 学術版の融合語形 ot/o-rin/o-laringolog/o(耳鼻喉科医)・ot/o/salpingit/o(耳管炎)を追加(待の取りこぼし是正)。ot/a(耳の)は旧$new重複を統合'),
 @('salping','管','ot/o/salping/o,ot/o/salping/it/o','','salpingo(希σάλπιγξ=筒·管)→管。耳管otosalpingo(耳/管=Au^da tubo=Eustachian tube)の文脈のみ。婦人科の卵管salping/o=卵管は基本形維持(word-scoped)。2026-07-15 監査是正: 耳管義と卵管義の真正な同綴異義を当該3見出しだけ分離。管はtub=管群の一員(自動でid付与)'),
 @('salpingit','管炎','ot/o/salpingit/o','','otosalpingito(耳管炎=耳/管炎)の学術版融合形→管炎。一般salpingit/o=卵管炎(婦人科)は基本形維持(word-scoped)。2026-07-15 監査是正'),
 @('ur','尿','ur/gener/a,ur/o/gener/a','','uro-(尿)→尿。オーロックスur/o(原牛)は維持。uro/log/uro/grafiは既に尿ᵁᴼ'),
 @('an','无','frid/an/estez/o','','否定接頭an-(=a-,無-)→无。frid/an/estez(冷却麻酔=冷/无/感。anesthesia=無感覚)のanのみ。接尾辞-an-(員=member)は基本形员を維持(word-scoped限定)。2026-07-15 監査是正'),
 @('riz','根','riz/o/morf/o,riz/o/pod/oj','','rhizo-(根)→根。米riz/o(米)·稲riz/kamp/riz/o/spik等は維持。rizom=根茎'),
 @('akant','刺','akant/o/cefal/oj,akant/o/pterig/oj','','akanto-(希ἄκανθα=棘·刺)→刺。棘頭虫Acanthocephala(akant/o/cefal=刺/头)・棘鰭類Acanthopterygii(akant/o/pterig=刺/翅)の thorn 義のみ。植物アカンサスakant/o(草=Acanthus属は棘葉だが植物として草維持)・トゲザメakantias(鱼)は不変。刺はdorn/pik/spron等と同じ棘グリフ(新字ゼロ)。2026-07-18 偽友スイープ'),
 @('heli','日','peri/heli/o,pir/heli/o/metr/o,ant/heli/o','','helios(希ἥλιος=太陽)→日。近日点perihelio(peri/heli=围/日)・日射計pirheliometr。ヘリウム気体heli/o=气ᴴᴹは別。標準helio=日ᴴと整合。2026-07-18 偽友スイープR3。2026-07-26 正本ドリフトで antheli/o→ant/heli/o が露出し heli が气ᴴ(ヘリウム)で描画→disc追加'),
 # 2026-07-26 正本ドリフト是正: antheli/o(対日像=太陽と反対側に見える光学現象)が ant/heli/o へ分解され、
 #   ant が分詞接尾 -ant-(在) で描画される誤友が露出。ここでの ant- は希 anti-(反対)なので 抗(=anti)へ。
 #   分詞接尾は disc外ゆえ不発火(在 を維持)。上の heli→日 と対で 抗ᴬ/日ᴴ = 反対側の太陽 と読める。
 @('ant','抗','ant/heli/o','','ant-(希 anti-=反対)→抗: antheli/o 対日像。分詞接尾 -ant-=在 は disc外で維持'),
 # 2026-07-26 第10レンズ: 正本が ribosom/o → rib/o/som/o(##偽分解(PIV正式分解)) へ分割したため、
 #   結合形masterの 核糖体 がオーファン化し、成分 rib が【植】スグリ属 Ribes の 醋栗 で描画され
 #   `rib/o/som/o⟦醋栗/o/体ˢᴹ/o⟧`(=スグリの実の体)という偽の友になっていた。
 #   ★PIV 自身が `ribo I`(スグリ) と `ribo II`(化学 ribo-) を別項目として立てており
 #     (riboz/o・deoksi/riboz/o の語釈末尾 "Vd ribo II")、同綴別語であることは原典で確定。
 #   ★割り当ては 核 ひとつに統一する(ユーザー方針=同綴多義でも可能な限り少ない種類で押し通す)。
 #     rib/oz     → 核/糖ᴼ      = 核糖(ribose)     ・de/oksi/rib/oz → 从/氧/核/糖 = 脱氧核糖
 #     rib/o/flav/in → 核/黄/in = 核黄素(riboflavin)・rib/o/enzim   → 核/酵素     = 核酶(ribozyme)
 #     rib/o/som  → 核/体ˢᴹ                        (中国語 核糖体。核+体で「核の小体」と読める)
 #     いずれも中国語の標準名と一致するか、透明に読める。2字熟語 核糖 を新設するより字種が増えない。
 #   果実の rib/o(スグリ)・rib/uj/o・rib/o/ber/o・rib/likvor/o・nigr/a rib/o 等は disc外で 醋栗 を維持。
 @('rib','核','rib/oz/o,de/oksi/rib/oz/o,rib/o/flav/in/o,rib/o/flavin/o,rib/o/enzim/o,rib/o/som/o,rib/o/som/a,plur/rib/o/som/o,poli/rib/o/som/o','','rib(化学 ribo- = PIV の ribo II)→核: 核糖/脱氧核糖/核黄素/核酶 と中国語標準名に一致。果実 Ribes(醋栗)は同綴別語で disc外維持'),
 # 2026-07-26 正本ドリフト是正: metencefal/o(後脳)が met/encefal/o へ分解され、met が meti(置く)=置 で
 #   描画される誤友が露出。ここでの met- は希 meta-(後方)なので 后(=post)へ。動詞 meti=置・化学 met=甲(天干)は
 #   いずれも disc外/別経路ゆえ不発火。后ᴹ/脑ᴱ = 後脳 と読める。
 @('met','后','met/encefal/o','','met-(希 meta-=後方)→后: metencefal/o 後脳。動詞 meti=置・系統化学 met=甲 は disc外で維持'),
 @('arke','原','arke/tip/o','','archē(希始まり·原型)→原。原型archetype(arke/tip=原/型)。ノアの箱船arke/o=方舟・考古arkeo/logi=古は別。2026-07-18 偽友スイープR3'),
 # arĥeo-(arh^eo)=arkeo-(archeo考古)の異綴り変種。arĥeologio/arĥeologo は arkeologio/arkeologo と同語(=別綴り)。arkeo/logi=古ᴬᴼと平行に arh^eo→古で被覆穴(latin残)を是正(2026-07-19)。arke原型/arke方舟とは別root。
 @('arh^eo','古','arh^eo/logi/o,arh^eo/log/o','','arĥeo-=arkeo-(archeo考古)異綴り→古。arkeo/logi=古と平行。arĥeologio/arĥeologo(=arkeologio/arkeologo変種綴り)。2026-07-19 被覆穴是正'),
 # chloro-(希χλωρός=緑green)の緑藻類→绿。klorofic緑藻綱(Chlorophyceae)・klorofit緑藻植物門(Chlorophyta)は定義verdalgoj=緑藻。氯(塩素)はwrong-morpheme(klorofil=叶绿greenと不整合・kloroform=氯形chlorineとは別義)。緑verd=绿とは同義で識別子区別。2026-07-19 REVIEW専用パス是正。
 @('klor','绿','klor/o/fic/o,klor/o/fic/oj,klor/o/fit/o,klor/o/fit/oj','','chloro-(χλωρός緑)→绿。緑藻klorofic/klorofit(verdalgoj)。氯(塩素kloroform)はwrong-morpheme。klorofil叶绿と整合。2026-07-19'),
 # caco-(希κακός=悪い/劣った)→劣。kakografi悪筆/誤記(Malbela au^ erarplena skribmaniero)。屎(feces)はwrong-morpheme(κακός=badで糞でない)。kakofoni=噪(騒音)とは別描画。劣志=劣った書き方。2026-07-19 REVIEW専用パス是正。
 @('kak','劣','kak/o/grafi/o,kak/o/grafi/a','','caco-(κακός悪い)→劣。悪筆kakografi(劣志=劣った書き方)。屎(feces)はwrong-morpheme。騒音kakofoni=噪は別。2026-07-19'),
 # 第22回追加(別AI監査で私の据置triage漏れを是正) — REVIEW残の明白wrong-morpheme4系(全て語スコープ)。
 # izo/glos=等语(等語線isogloss)。glos=希γλῶσσα(言語/舌)→语。注(注釈gloss=glosaro注释表)/舌(舌炎glosit)は別sepで不干渉=isoglossのglosのみ语。
 @('glos','语','izo/glos/o','','isogloss(等語線)のglos→语(希γλῶσσα言語)。注(glosaro注)/舌(glosit舌炎)は別。2026-07-19'),
 # skiz/o/micet=裂菌(Schizomycetes裂殖菌)。schizo=希σχίζω(分裂)→裂。skiz/o=草(sketch草稿)は別義で不干渉=skizomicetのskizのみ裂。skizofit=菌(whole-word)は無関係。
 @('skiz','裂','skiz/o/micet/o,skiz/o/micet/oj','','Schizomycetes(裂菌)のskiz→裂(schizo分裂)。sketch草稿skiz/o=草は別義。2026-07-19'),
 # fil/o/genez=系源(系統発生phylogenesis)。filo=希φῦλον(系統/種族)→系。息子fil/o=儿・愛philo=爱・phyllo葉は別=filogenezのfilのみ系(1形のみ)。
 @('fil','系','fil/o/genez/o','','phylogenesis(系統発生)のfil→系(φῦλον系統)。息子儿/愛爱は別義。2026-07-19'),
 # hetero/nomi=异律(他律heteronomy)。nomi=希νόμος(法)→律。学(-nomy科学astronomi天文学)/治(autonomi自治)は別=heteronomiのnomiのみ律。自治au^tonomiと対の他律。
 @('nomi','律','hetero/nomi/o','','heteronomy(他律)のnomi→律(νόμος法)。-nomy科学=学/autonomi自治は別。2026-07-19'),
 @('sol','液','cito/sol/o,c^el/sol/o','','Latin solutio(溶液)→液。細胞質液cytosol(cito/sol=胞/液)・ĉelsol。唯一sol/a・独唱sol/o等の sol=唯 は維持(word-scoped)。2026-07-18 偽友スイープR3'),
 @('fen','现','fen/o/tip/o','','phainein(希現れる·示す)→现。表現型phenotype(fen/o/tip=现/型)。フェーン風feno=焚风・フェノールfenol(化学)は別。fenomen现象と同源。2026-07-18 偽友スイープR3'),
 @('kromi','色','homo/kromi/o,fot/o/kromi/o,poli/kromi/a,poli/kromi/o,tri/kromi/o','','chroma(希色)→色。保護色homochromy(homo/kromi=同/色)・天然色写真術fotokromi(fot/o/kromi=拍/色)。多色polychromy(poli/kromi=多/色)・三色trichromy(tri/kromi=三/色)。金属クロムkromi/o=金・クロム酸塩kromiat等の化学は金維持(word-scoped)。krom→色と同源。2026-07-18 偽友スイープR3。2026-07-21 正本ドリフト polikromi→poli/kromi・trikromi→tri/kromi 露出で追加=多/金・三/金の誤描画を是正(第27回)'),
 @('cist','囊','kole/cist/o,kole/cist/a,kole/cist/it/o','','kystis(希嚢·袋)→囊。胆嚢cholecyst(kole/cist=胆/囊)・胆嚢炎kolecistit。ハンニチバナ属Cistus cist/o=草は維持(word-scoped)。膀胱kist/o=囊肿と同源。2026-07-18 偽友スイープR3'),
 @('pale','古','pale/o/grafi/o,pale/o/graf/o,pale/o/botanik/o,pale/o/eko/log/o,pale/o/eko/logi/o,pale/o/grund/o,pale/o/hist/o/logi/o,pale/o/magnet/ism/o,pale/o/ekolog/o,pale/o/ekologi/o,pale/o/histologi/o','','palaios(希古い)→古。古文書paleografi・古生態paleoekologi・古土壌paleogrund・古組織paleohistologi・古地磁気paleomagnetism等のpaleo-接頭辞。イネ科の内頴pale/o=内壳(palea)は維持(word-scoped)。paleo/lit旧石器=古ᴾと整合。2026-07-18 偽友スイープR3/2026-07-19 学術版粗分節pale/o/ekolog·ekologi·histologi追加(学習者版はeko/log等細分節でR3既発火・学術版は粗分節で未発火だった)'),
 @('plan','平','plan/i/metri/o,plan/i/metr/o','','plano(平面plane=平)→平。面積測定法planimetri(plan/i/metri=平/i/测)・プラニメータplanimetr(平/计)のplano-plane幾何。計画/図面plan/o=划(base)は維持(word-scoped)。平面eben=平と同字(識別子で弁別)。2026-07-19 偽友監査(planimetria=面積測定でplan=划は誤友)'),
 @('pedo','土','pedo/log/o','','希pedon(土壌soil)→土。土壌学者pedolog(pedo/log=土/学家)=grundolog(土/o/学家)の同義語。児童学pedo/logi/o=童(希pais子供)は同綴別語源で維持(word-scoped)。PIV定義「Specialisto pri pedologio. Sin. grundologo」=土壌学者ゆえ童は誤友。2026-07-19 偽友監査'),
 @('nomi','律','anti/nomi/o,anti/nomi/a','','ギリシャnomos(法·規範)の法義→律。二律背反antinomi(anti/nomi=抗/律。二律背反の律)。-nomy科学(agronomi農学·astronomi天文学·gastronomi美食学)のnomi=学ᴺは維持(word-scoped)。metr/o/nom=律(節拍器)と同源。2026-07-19 偽友スイープ最終'),
 @('log','戒','deka/log/o','','ギリシャlogos(言葉→戒め)→戒。モーセの十戒Dekalogo(deka/log=十/戒)。学問-logy/学者-logist=学家(biolog等)·対話dia/log=话·誘惑al/log=诱 とは別の第4義。2026-07-19 偽友スイープ最終'),
 @('log','志','nekr/o/log/o,nekr/o/log/ar/o','','ギリシャlogos(記録·名簿)→志。死亡記事·死亡者名簿necrolog(nekr/o/log=死/志)。学者-logist=学家·话·诱·戒 とは別の第5義。志=地方志/杂志の記録義。2026-07-19 偽友スイープ最終'),
 @('ont','在','ont/o/genez/o,ont/o/logi/o,bi/ont/o/logi/o','','ギリシャont-(ōn/ontos=存在するもの·being)→在(存在)。存在論ontologi(ont/o/logi=在/学)·個体発生ontogenez(在/源)·生物学biontologi(生/在/学)。将然分詞-ont-(faront将来〜する者=将)は将のまま維持(word-scoped)。paleont=古(古生物)は別morpheme。2026-07-19 偽友スイープ最終'),
 @('meteor','气','meteor/o/logi/o,meteor/o/log/o,meteor/o/logi/a','','ギリシャmeteoron(大気現象)→气(気象)。気象学meteorologi(meteor/o/logi=气/学)は隕石meteor/o=陨·流星体meteor/oid=陨/似 とは別(word-scoped)。既存meteo/logi=气ᴹと整合。隕石学(陨学)との誤読を是正。2026-07-19 偽友スイープ最終'),
 @('glos','舌','glos/ektomi/o,glos/it/o,hipo/glos/o','','ギリシャglōssa(舌tongue)の解剖義→舌。舌切除glosektomi(glos/除)·舌炎glosit(glos/炎)·舌下神経hipogloso(亚/舌)。注釈gloss(用語集glos/ar/o·gloso)のglos=注は維持(word-scoped 同綴別義)。2026-07-19 偽友スイープ最終'),
 @('daktil','指','daktil/o/graf/i,daktil/o/skop/i/o,pter/o/daktil/o','','dactylo-(指)→指。ナツメヤシdaktil/o(枣)·daktil/o/palm等は維持。2026-07-18 正本過細分解 pterodaktil→pter/o/daktil 露出→追加(pterodactyl翼指=翅/指。daktil→枣ナツメヤシの偽友是正)'),
 @('sperm','种','endo/sperm/o,peri/sperm/o,angi/o/sperm/oj','','-sperma(種·胚乳)→种。angi/o/sperm/oj(被子植物=覆われた種)もgimnosperm裸子(whole-word)・endo/peri/spermと平行に种(2026-07-04 WSL再分解angiosperm→angi/o/sperm露出で精液=semen誤適用を是正)。精液sperm/o(精液)·sperm/o/dukt等は維持'),
 # 結合形フォルスフレンド第4弾(2026-06-21・優先順位/方針 多エージェント監査で検出)。-log-=言葉(話)·-metr-=計器(计)。
 @('log','话','dia/log/a,dia/log/i,dia/log/o,dia/log/oj,dia/log/uj/o,dia/log/ist/o,mono/log/i,mono/log/o,pro/log/o,epi/log/o,neo/log/o,neo/log/ism/o,neo/log/ism/em/o,neo/log/ism/em/ul/o','','-log-(logos=言葉·談話/-logue)→话(parol=话と同字共有)。対話dia/独白mono/序言pro/跋epi/新語neo(neologism=新话)。-logist/-ology=学家(biolog等)·al-de+log=诱は別。katalog=录·analog=似(whole-root)は不変'),
 @('metr','米','centi/metr/o,deci/metr/o,deka/metr/o,hekto/metr/o,kilo/metr/o,mili/metr/o,mikro/metr/o,miria/metr/o,kub/metr/o,kilo/gram/metr/o,para/metr/o,izo/metr/o,izo/metr/a,heks/a/metr/o,penta/metr/o,kvadrat/metr/o,kilogram/metr/o','','-metr-の非計器(長さ·面積·体積単位/詩脚)は米(metre/measure)維持。下の comb metr→计(計器)を見出しで上書き。単位centi-kilo·parameter para·isometric izo·hexa-penta詩脚。※直径dia/半径du/on/dia/周径peri と幾何geo/metr は下の metr→测(measure)sepへ移管(2026-06-21/2026-07-15・ユーザー裁定)'),
 # 直径系の-metr-=抽象measure→测(mezur測る=测の基底・metri测ᴹᵀと同family。dia/metr=横切って測る=diameter語源)。米(metre単位)·计(計器)·测ᴹᵀ(metri)と並ぶmetrの第4文脈。2026-06-21ユーザー裁定 米→测。
 @('metr','测','dia/metr/o,dia/metr/a,du/on/dia/metr/o,peri/metr/o,geo/metr/o,geo/metr/ed/oj','','-metr-(抽象measure=直径/半径/周径/幾何)→测。测の基底mezur(測る)・metri(测ᴹᵀ)と同family。dia/metr=通ᴰ/测「横切って測る」=diameter語源。2026-07-15ユーザー裁定: 幾何geo/metr(=土地を測る)を米→测に移管(地测。シャクガ科geo/metr/edも土地を測る虫で整合)。※pir/geo/metr(pyrgeometer=地表放射を測る計器)は計器ゆえ comb metr→计(火/地/计)に戻す(2026-07-15 監査是正)。長さ単位centi/kilo·詩脚heks/pentaは米sep維持'),
 @('dinam','力','dinam/ism/o,dinam/o/metr/o,elektr/o/dinam/ism/o,elektr/o/dinam/o/metr/o,izo/dinam/o','','希dynamis(力·動力)の力義→力。dynamism力動説/dynamometer力計/electrodynamism電気力学/isodynamic等力線。発電機dinam/o(dynamo)=发电は基本形維持(word-scoped)。dinamik=力(別root力学)と整合。2026-07-15ユーザー裁定=发电の力義取りこぼしを是正'),
 # ギリシャ接頭pro-(前)·ワットwatt(瓦)の同綴是正(2026-06-21追補。/goal監査の据置項目をmerit判断で是正)
 @('pro','前','pro/log/o,pro/faz/o,pro/virus/o,pro/gnat/a,pro/gnat/ec/o','','ギリシャ接頭pro-(前·fore)→前。prologue序言(pro/log⟦前/话⟧)·prophase前相(pro/faz⟦前/相⟧)·provirus前駆ウイルス(pro/virus⟦前/毒⟧)·prognathous前突顎(pro/gnat⟦前/gnat⟧)。epi=后と対。エス前置詞pro=因(pro tio因此·proparol代弁·pro/pek贖罪·pro/mort等)は維持(disc不掲載)。2026-07-18 正本過細分解 prognat→pro/gnat 露出→追加(pro→因理由の偽友是正)'),
 @('vat','瓦','giga/vat/o,kilo/vat/o,mega/vat/o,vat/hor/o,vat/hor/o/metr/o,vat/metr/o,vat/sekund/o,kilo/vat/hor/o,mega/vat/hor/o,tera/vat/hor/o','','ワットwatt(瓦)→瓦。kilo/vat/hor=キロワット時・mega/vat/hor=メガワット時(2026-06-23 sep派生形網羅)。kilovat/megavat/gigavat/vatmetr電力計/vathor瓦時/vatsekund 等の電力複合。tera/vat/hor=テラワット時(2026-07-20 正本同期 teravat/hor→tera/vat/hor 露出で追加=vat棉誤適用是正・giga/kilo/megaと整合)。綿vat/o(棉)·suker/vat綿菓子·vat/baston綿棒·vat/it綿入 等は維持(disc不掲載)。bare vat/o=棉&瓦はamb(基本義 棉維持)'),
 @('ar','亩','centi/ar/o','','centiaro(1/100 are=1平方メートル)の ar=亩(are面積単位)→厘/亩。正本同期(2026-07-20)で centiar/o→centi/ar/o 露出。集合接尾-ar-(群)・bare ar/o(amb アール面積)とは別=word-scoped(centi/ar/o のみ)。hektar/o=公顷(whole)と整合'),
 # メトロノーム metronomo の同綴是正(2026-06-21。米/名は誤り→计/律。merit判断)。metr語頭idx0でcomb非適用→sepで计(計器)。nom=ギリシャnomos(法/掟)→律(leĝ=律と整合・かつ音律/拍節で楽器に二重適切)
 @('metr','计','metr/o/nom/o','','メトロノームmetr(計器·measure)→计。idx0でcomb metr→计 非適用のためsep明示。長さ単位等の非計器metrは上の米sepで処理'),
 @('nom','律','metr/o/nom/o','','メトロノームnom(ギリシャnomos=法/掟)→律。leĝ法律=律と整合し律=音律/拍節も兼ね楽器に二重適切。科学-nomy=学(agronom)·名前複合=名 とは別の第3義。计律=計測+音律=節拍器'),
 # aŭtomobil 過剰分解是正(2026-06-21・ユーザー裁定OptionA)。辞書 ##過細分解 au^t/o/mobil/o の mobil=挂饰(モビール)は誤友→动(-mobile=可動)。aŭt=车(基本形)はそのまま=车/o/动/o。aŭtomat(动)の兄弟として动群へ合流(动ᴹᴮ)。
 @('mobil','动','au^t/o/mobil/o,au^t/o/mobil/a,au^t/o/mobil/ism/o,au^t/o/mobil/ist/o,au^t/o/mobil/kompani/o,mobil/iz/i,mobil/iz/ad/o,mobil/iz/o,mal/mobil/iz/i,mal/mobil/iz/ig^/i,mal/mobil/iz/o,lok/o/mobil/o','','mobil(-mobile=可動·自動·移動)→动。aŭtomobil車+動員mobil/iz(復員mal/mobil/iz)+移動式蒸気機関lok/o/mobil。モビール装飾mobil/o(挂饰)はdisc不掲載で挂饰維持。aŭtomat=动と同群'),
 # 結合形フォルスフレンド第5弾(2026-06-21・/goal多エージェント敵対検証で検出)。全字一级(声/径)。既存sep機構。
 # ②phono-(声)が先頭分節idx0=蓄音機/音韻論。背景fon(底)はdisc不掲載で維持。gram/o/fon=声ᶠᴼ(idx>0)と整合。
 @('fon','声','fon/o/graf/o,fon/o/gram/o,fon/o/logi/o,fon/o/metr/o,fon/o/metri/o,fon/o/skop/o,fon/on/o','','phono-(音·声)結合形がidx0(先頭分節)=蓄音機/音韻論/音波測定等→声。背景fon/o(底)·fon/a/fon/bru/o/fon/farb/fon/muzik/o/fon/s^mink/fon/tol/fon/tul はdisc不掲載で底維持。phononフォノンfon/on/o=声/子(2026-06-23ユーザー裁定。fon=声[他phono-語と一貫]・on=子[$onStemにfon追加])'),
 # WSL再分解(2026-06-21・19:08版同期)で露出した接頭辞フォルスフレンド。bi-(two)→二・物理spin→旋。全字一级。
 @('bi','二','bi/,bi/dent/o,bi/labial/o,bi/dual/o,bi/gami/o,bi/gami/ul/o,bi/lion/o,bi/holo/morf/a,bi/holo/morfi/o,bi/jekci/a,bi/jekci/o,bi/karbon/at/o,bi/kromiat/o,bi/metal/a,bi/metal/ism/o,bi/sulf/at/o,bi/sulf/it/o,meta/bi/sulf/it/o,poli/klor/bi/fenil/o,bi/kromi/at/o,bi/holomorf/a,bi/holomorfi/o,bi/sulfat/o,bi/sulfit/o,meta/bi/sulfit/o,bi/konkav/a,bi/konveks/a,bi/plan/o,bi/fac/o,bi/faden/a,bi/fen/il/o,bi/fenil/o,poli/klor/bi/fen/il/o,bi/sak/o,bi/sekc/i','','bi-(two=二)→二。学術版粗分解 bi/holomorf(双正則)・bi/sulfat(重硫酸塩)・bi/sulfit(重亜硫酸塩)・meta/bi/sulfit も二(2026-06-23 sep派生形網羅。bio生はdisc不掲載で維持)。biot生(bi/ont/o/logi=生物学)はdisc不掲載で生維持。重婚bi/gami・重曹bi/karbon/at・双射bi/jekci・双金属bi/metal・重铬酸bi/kromiat・メタ重亜硫酸meta/bi/sulf/it・PCB poli/klor/bi/fenil 等。di-(二)と平行。十億 bi/lion/o=二/lion(乗数bi-=2。tri/lion=三/lion と平行。bio bi/ont=生 とは別の数詞bi。2026-06-29 WSL bilion→bi/lion 露出で sep列挙に追加=生ᴮᴵ誤適用を是正。2026-07-04 bilabial→bi/labial露出で bi/labial/o(両唇音=two-lipped)追加=生ᴮᴵ誤適用是正。aer/o/bi(好気=bio)・bi/ont(biont生)等は生のまま維持。2026-07-18偽友スイープR2: 両凹bi/konkav・両凸bi/konveks・複葉機bi/plan・両面石器bi/fac・二本糸bi/faden・ビフェニルbi/fen/il・二嚢bi/sak・二等分bi/sekc(Latin bi-two=二。生ᴮᴵ=bioの誤友是正))'),
 @('spin','旋','spin/momant/o,izo/spin/o','','物理spin(角運動量)→旋。背骨spin/o(脊)・脊髄spin/a・脳脊髄cerb/o/spin/a・cefal/o/spin/aは脊維持(disc不掲載)。spin/o=背骨/スピンの二義のうち物理複合のみ旋'),
 # /goal第2次敵対検証(2026-06-21)で検出した追加フォルスフレンド。allo-(他·異)→异・化学-id(-ide二元化合物)→化。全字一级。
 @('alo','异','alo/fon/o,alo/fon/a,alo/morf/o,alo/trofi/o,alo/pati/o','','ギリシャ接頭allo-(他·異different)→异。allophone异音(alo/fon)·allomorph异形态(alo/morf)·allotrophy异养(alo/trofi)·allopathy异/情(alo/pati=逆症療法。アロエでない)。アロエ alo/o(草)·alo/aj^/o(草)はdisc不掲載で草維持。合金aloj/oは別根(合金)'),
 @('id','化','brom/id/o,brom/id/paper/o,cian/id/o,klor/id/o,klor/id/a,di/klor/id/o,tri/klor/id/o,metil/klor/id/o,met/il/klor/id/o,vinil/klor/id/o,klor/id/emi/o,hipo/klor/id/emi/o,sen/klor/id/ig^/o,sulf/id/o,di/sulf/id/o,fluor/id/o,fosf/id/o,halogen/id/o,hidr/id/o,hidr/id/i,jod/id/o,karb/id/o,karbon/id/o,karbon/hidr/id/o,nitr/id/o,selen/id/o,silici/id/o,arsen/id/o,ure/id/o','','化学-id(-ide=二元化合物X化物)→化。塩-at/-it=盐の兄弟(-ide=化合物 / -ate-ite=塩)。子孫-id(bov/id仔牛·kat/id仔猫·c^eval/id等の動物の子)はdisc不掲載で子維持。lanthanoid lantan/id(系列)·saccharide sakar/id(糖類)は二元化合物でないため除外。2026-07-18 化物残件を追加: silici/id硅化物·arsen/id砷化物·met/il/klor/id塩化メチル(過細分解 metil→met/il でmetil/klor/idと不一致だった)。2026-07-24 別AI round8: karbon/hidr/id/o(炭化水素hidrokarbono=学習者版過細分解 karbon/h/i/d/r/id/o)追加=学術版karbon/hidrid/o(碳/氢化)と粒度整合・学習者版hidr/id/o(水ᴴ/化ᴵᴰ)と一致(碳/水ᴴ/子→碳/水ᴴ/化ᴵᴰ)') )
# 新54(root,override,headwordForm,2nd義キーワード(amb判別用),note)
$new=@(
 @('al','翼','al/o,helic/al/o,c^irkau^/al/a,frog/al/o,al/et/o,al/et/s^rau^b/ing/o','翼','翼(alo=翼/羽根)。前置詞al=向と別。複合語内al/o=翼も翼へ(helic/al/o=プロペラ羽根・c^irkau^/al/a=翼に囲まれた・frog/al/o=フログ翼部・al/et/o=蝶ナットのつまみ・al/et/s^rau^b/ing/o=蝶ねじ受け=aleto小翼。hsepはwhole-wordキーのため複合を明示列挙=2026-06-25 接尾辞悉皆監査WF・2026-07-04 aleto向誤適用是正)'),@('por','孔','por/o,por/a','孔','気孔。前置詞por=为と別'),@('sur','腿','sur/o','ふくらはぎ','ふくらはぎ。前置詞sur=上と別'),
 @('el','酒','el/o','エール','エール。前置詞el=出と別'),@('plum','笔','plum/o','ペン','ペン。plum=羽と同綴'),@('mat','将','mat/o,mat/i','詰','チェス詰み。mat=席と別行'),
 @('pat','困','pat/o','手詰','ステールメイト。pat=锅と別行'),@('vat','瓦','vat/o,vat/hor/o','ワット','ワット。vat=棉と別行'),@('kanon','典','kanon/o,kanon/a','典','正典/カノン。kanon=炮と別行'),
 @('karp','腕','karp/o','手首','手根。karp=鲤と別行'),@('sakr','荐','sakr/o,sakr/a','仙骨','仙骨。sakr=骂と別'),@('deviz','汇','deviz/o','外貨','外貨。deviz=铭と同綴'),
 @('mark','币','mark/o','マルク','マルク。mark=标と別行'),@('lir','币','lir/o','リラ','リラ通貨。lir=琴と別行'),@('kron','币','kron/o','クローネ','クローネ。kron=冠と別行'),
 @('dur','币','dur/o','ドゥーロ','ドゥーロ銀貨。dur=硬と別'),@('tak','币','tak/o','タカ','タカ通貨。tak=倾と別'),@('bac','币','bac/o','硬貨','古独貨。bac=响と別'),
 @('ar','亩','ar/o','アール','アール面積。ar=群と別行'),@('luks','照','luks/o','ルクス','ルクス照度。luks=奢と別行'),@('stok','粘','stok/o','ストークス','ストークス粘度。stok=储と別行'),
 @('kuri','居','kuri/o','キュリー','キュリー。kuri=廷と別行'),@('fon','响','fon/o','ホン','ホン音量。fon=底と別'),
 @('trik','毛','trik/o,trik/oz/o,poli/trik/o,trik/o/pati/o,trik/o/plazi/o,trik/o/pter/oj,trik/o/micet/oz/o','毛','毛(tricho-)。trik=织(編む)と別。tricho-毛の複合(trichosis毛症/Polytrichum多毛コケ/trichopathy毛病/trichoplasia毛増生/Trichoptera毛翅/trichomycosis毛/菌/症)も毛へ(2026-06-23/27 sep派生形網羅)'),   # ot/mi は $existing(耳/肌)へ統合し重複解消(2026-06-21)
 @('spin','旋','spin/o','スピン','物理スピン。spin=脊と別行'),@('var','内','var/a','内反','内反varus。var=货と別'),@('orkid','丸','orkid/o','睾丸','睾丸。orkid=兰と別'),
 @('spat','苞','spat/o','仏炎','仏炎苞。spat=石と別行'),@('sol','溶','sol/o','ゾル','ゾル。sol=唯と別行'),@('siren','牛','siren/o','海牛','海牛類。siren=警笛と別行'),
 @('ergot','距','ergot/o','蹴爪','蹴爪。ergot=麦角と別'),@('sor','胞','sor/o','胞子','胞子嚢群。sor=腾と別'),@('panikl','脂','panikl/o','皮下','皮下脂肪。panikl=圆锥と別'),
 @('rod','泊','rod/o','停泊','停泊地。rod=啃と別行'),@('bit','桩','bit/o','繋柱','繋柱。bit=位と別行'),@('jard','杆','jard/o','帆桁','帆桁。jard=码と別'),
 @('prot','匠','prot/o','組版','組版長。prot=质子と別'),@('prim','祷','prim/o','一時課','一時課。prim=质数と同行'),@('pic^','调','pic^/o','音高','音高。pic^=阴户と別行'),
 @('lab','验','lab/o','実験室','実験室。lab=皱胃と別'),@('arke','菌','arke/o,arke/oj','古細菌','古細菌。arke=方舟と別'),@('abak','顶','abak/o','柱頭','柱頭。abak=算盘と別'),
 @('file','线','file/o','罫線','罫線。file=里脊と別'),@('peon','佃','peon/o','隷農','隷農。peon=卒と別'),@('tang','舞','tang/o','タンゴ','タンゴ。tang=颠と別行'),
 @('klik','派','klik/o','徒党','徒党。klik=爪と別'),@('topik','敷','topik/o','外用','外用薬。topik=题と別'),@('er','纪','er/o','紀元','紀元。er=粒と別行'),
 @('po','草','po/o','Poa','Poa属。po=每と別行'),@('line','草','line/o','リンネ','リンネ草。line=线と別行'),@('tof','瘤','tof/o','痛風','痛風結節。tof=凝灰と別'),
 @('male','疫','male/o','鼻疽','馬鼻疽。male=锤ᴹᴸと別行'),@('sinus','弦','sinus/o','正弦','正弦sine。sinus=洞と別行'),
 @('mung','草','mung/o,mung/id/oj','緑豆','緑豆(Vigna radiata=マメ科)+豆もやし→草(§4.6最近一级字)。動詞mung/i=擦鼻(洟をかむ)と別行(2026-06-26 全コーパス監査)'),@('sed','草','sed/o','マンネングサ','Sedum=ベンケイソウ科の観賞植物属→草。接続詞/動詞sed・sed/i=但と別行'),@('ke','鸟','ke/o','ケア','Nestor notabilis=ケア(NZのオウム,鳥)→鸟。接続詞ke=事と別行') )
$rows=New-Object System.Collections.ArrayList
[void]$rows.Add("segment`toverride`ttype`tdisc`tnote")
foreach($e in $existing){ [void]$rows.Add(($e[0]+"`t"+$e[1]+"`tsep`t"+$e[2]+"`t"+$e[4])) }
# false sep(1見出しに主義と第2義が同居=同一見出し2義)→ amb 強制(=不採用、主義を維持)
$forceAmb=@('abak','deviz','orkid','ergot','panikl','jard','prim','klik','tof','peon','plum','fon','file','topik','lab','arke')
$sepN=0;$ambN=0
foreach($e in $new){ $root=$e[0];$ov=$e[1];$hw=$e[2];$kw=$e[3];$note=$e[4]
  $hw1=($hw -split ',')[0]; $hwe=[regex]::Escape($hw1)
  $n=@($lines|Where-Object{ $_ -match ("^"+$hwe+":") }).Count
  if(($forceAmb -contains $root) -or $n -ge 2){ $type='amb'; $disc=$kw; $ambN++ } else { $type='sep'; $disc=$hw; $sepN++ }
  [void]$rows.Add(($root+"`t"+$ov+"`t"+$type+"`t"+$disc+"`t"+$note)) }
# combining-form(ギリシャ結合形): idx>0 の完全一致分節で適用(段位置ベース。disc空)。同綴の内容語と別義。
$comb=@( @('fon','声','音(phone)結合形 telefon/mikrofon等。背景fon=底はidx0で別'), @('metr','计','計器(-meter)結合形 termometr/barometr/manometr/anemometr等→计(gauge)。idx>0の-metr-。長さ単位·詩脚·直径等の非計器はsep metr→米で除外。-metri-(科学)=测は別分節(metri)で不変'), @('nim','名','-onym(名)結合形の連結o吸収表層 homo/nim同名・hipo/nim下位語・pseu^do/nim偽名→名。onim=名ᴼ(an/onim/ant/onim)と同形態素だが先行母音がoを吸収してnim表層化。-onym以外のnim分節は皆無=idx>0で安全(2026-06-26 全コーパス監査)') )
$combN=0; foreach($e in $comb){ [void]$rows.Add(($e[0]+"`t"+$e[1]+"`tcomb`t`t"+$e[2])); $combN++ }
# === -oz/-on/-tom systematic 是正(2026-06-21・収束検証/goal第4次→残oz集約。ユーザー裁定「症+糖の2字に集約。膜/态/用/基の細分は廃止」) ===
# -oz: -ozo名詞→症(病-osis/過程変態/食作用/膜/iodoso/jetlag/条件形容詞=状態・症状全般に集約) / 糖類-ose→糖 / 標準語oz/o(単糖)→糖 / genuine -oza形容詞(rich/多い herb/bitum)→富。
# -on: 物理粒子-on→子(電子/陽子/中性子/光子/中間子/磁子/核子)。分数-on/o(分)・対格-on・継息子du/on/fil・帽子c^ap/on等は語幹非該当で維持。
$ozRich=@('herb/oz/a','bitum/oz/a')   # genuine -oza形容詞(草の多い/瀝青質の)→富。他の-oza(変態の/結核性等の条件形容詞)は症へ集約
$ozChem=@('jod/oz/o','fer/oz/a')   # 化学結合形-oz(iodoso=grupo IO 価数接尾辞・nitrozo同系列 / feroza第一鉄=Fe(II)価数)→どのoz discにも入れず=_inject_finalの$segLatでlatin化(病-osis症でない。2026-06-25 接尾辞悉皆監査WF。2026-07-21 fer/oz/a=铁/症の誤読是正=第27回)
$ozGlyco=@('rut/oz/id/o','nukle/oz/id/o','sap/oz/id/o','salik/oz/id/o','indig/oz/id/az/o')   # 配糖体(glycoside=糖誘導体)→糖。語釈が糖語(Heterozido/Enzimo等)で$sugar正規表現に掛からず症に誤分類されていた(2026-07-18ユーザー裁定「配糖体oz→症/富を既存の糖へ」)。兄弟gluk/oz/id・indig/oz/id は語釈にGlukozidを含み$sugarで既に糖。標準oz/id/oは下でoz/oと同様に明示追加(oz語幹idx0で自動分類外)
$onStem=@('elektr','prot','neu^tr','fot','mez','magnet','nukle','fon')   # fon追加: phonon=fon/on→子(2026-06-23ユーザー裁定。phono声+on子)
$ozD=New-Object System.Collections.ArrayList;$ozS=New-Object System.Collections.ArrayList;$onP=New-Object System.Collections.ArrayList
$ozK=@{};$onK=@{}
foreach($ln in $ozLines){ $ci=$ln.IndexOf(':'); if($ci -lt 1){continue}; $hh=$ln.Substring(0,$ci); $gg=$ln.Substring($ci+1)
  foreach($w in ($hh -split ' ')){ $sg=$w -split '/'
    $io=[array]::IndexOf($sg,'oz')
    if($io -ge 1 -and -not $ozK.ContainsKey($w)){
      $sugar=($gg -match '糖') -or ($gg -match '(?i)(sakar|sukero|monosakar|polisakar|glucid|pentoz|heksoz|glikoz|glukoz|aldehid)') -or ($w -match 'celul/oz') -or ($w -eq 'gren/malt/oz/aj^/o')   # celul/oz* (celul/oz/o・celul/oz/a・hemi/celul/oz/o)=多糖→糖。celuloseは常に多糖類(2026-06-23 sep派生形網羅)
      if($sugar){ $ozK[$w]=$true; [void]$ozS.Add($w) }
      elseif($ozGlyco -contains $w){ $ozK[$w]=$true; [void]$ozS.Add($w) }   # 配糖体→糖(語釈が糖語で$sugar非該当だが糖誘導体)
      elseif($ozRich -contains $w){ $ozK[$w]=$true }   # genuine -oza形容詞(草の多い/瀝青質の)→富(disp基底維持)
      elseif($ozChem -contains $w){ $ozK[$w]=$true }   # 化学結合形-oz(iodoso価数接尾辞)→どのoz discにも入れず=segLatでlatin
      else{ $ozK[$w]=$true; [void]$ozD.Add($w) }   # 他-oz全て→症(病/過程変態/食作用/膜/jetlag/条件形容詞=状態全般に集約)
    }
    $in=[array]::IndexOf($sg,'on')
    if($in -ge 1 -and -not $onK.ContainsKey($w) -and ($onStem -contains $sg[$in-1])){ $onK[$w]=$true; [void]$onP.Add($w) }
  } }
[void]$ozS.Add('oz/o')   # 標準語oz/o(単独=単糖monosaccharide)→糖。oz語幹idx0で自動分類外のため明示追加
[void]$ozS.Add('oz/id/o')   # oz/id/o(oside=配糖体一般名)→糖。oz語幹idx0で自動分類外・既定富から是正(2026-07-18。oz/oと同型)
if($ozD.Count){ [void]$rows.Add("oz`t症`tsep`t"+($ozD -join ',')+"`t-ozo名詞→症(状態/症状全般に集約。病/変態/食作用/膜/iodoso/jetlag。糖類のみ糖・genuine形容詞-oza富。2026-06-21ユーザー裁定で症+糖の2字に集約)") }
if($ozS.Count){ [void]$rows.Add("oz`t糖`tsep`t"+($ozS -join ',')+"`t-ose糖→糖(標準語oz/o単糖含む)") }
if($onP.Count){ [void]$rows.Add("on`t子`tsep`t"+($onP -join ',')+"`t物理粒子-on→子(電子/陽子/中性子/光子/中間子/磁子/核子。分数-on/o=分は維持)") }
[void]$rows.Add("tom`t切`tsep`tmikro/tom/o`t-tom(切る・微小切片機microtome)→切。-tomi=切ᵀᴹ・-ektomi=除ᴱᴷと同系")
Write-Host ("  [-oz/-on/-tom] 症{0}/糖{1}/子{2}/切1" -f $ozD.Count,$ozS.Count,$onP.Count)
[System.IO.File]::WriteAllLines("$dir\_homonym.tsv", $rows, (New-Object System.Text.UTF8Encoding($false)))
$existSep=$existing.Count
Write-Host ("台帳再構築: 既存{0}(sep) + 新{4} = 計{1}行 / sep {2} / amb {3} / comb {5}" -f $existSep,($rows.Count-1),($existSep+$sepN),$ambN,$new.Count,$combN)
Write-Host "--- amb(同一文字列・注入時に語義で判別) ---"
$rows|Where-Object{$_ -match "`tamb`t"}|ForEach-Object{ $p=$_ -split "`t"; "  {0,-7} →{1}  語義キー『{2}』" -f $p[0],$p[1],$p[3] }
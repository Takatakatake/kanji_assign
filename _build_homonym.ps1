# 同綴異義台帳(_homonym.tsv)を網羅版に再構築。型(sep=見出し分離可 / amb=同一文字列→語義判別)を辞書行数で自動判定。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
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
 @('krom','金','krom/o,krom/at/o,krom/at/a','','クロム(金属元素)→金。前置詞krom=外と別。krom/at=クロム酸塩→金/盐'),
 # chromo-(色=color。ギリシャ chroma)→色。クロム金属krom=金・前置詞krom=外 とは別綴り同根の第3義(2026-06-23)。
 @('krom','色','krom/o/fotografi/o,krom/o/litografi/o,krom/o/sfer/o','','chromo-(色=color)→色。chromosphere彩層(太陽)・chromolithography彩色石版・chromophotography彩色写真。金属クロムkrom/o=金・前置詞krom=外と別綴り同根'),
 @('titan','金','titan/o,titan/at/o,titan/at/a','','チタン(金属元素)→金。巨人titan/a=巨と別。titan/at=チタン酸塩→金/盐(krom/borと平行)'),
 @('bor','矿','bor/o,bor/at/o,bor/at/a,bor/o/tartr/at/o,tetra/bor/at/o,fluor/bor/at/o,bor/o/tartrat/o','','ホウ素(半金属元素)→矿。bor/o/tartrat=学術版粗分解(2026-06-23)。掘削bor/i=钻と別。bor/at=ホウ酸塩→矿/盐。bor/o/tartr/at=ホウ酒石酸塩(連結o複合)も矿。tetra/bor/at=四ホウ酸塩・fluor/bor/at=フルオロホウ酸塩(WSL過細分解 Xat→X/at 同期)'),
 @('tetr','四','tetr/','','tetra-接頭辞。鳥tetr/o=琴鸡が既定'),
 @('tetra','四','tetra/,tetra/gram/o,tetra/borat/o,tetra/mer/o,tetra/tionat/o,tetra/ol/o,tetra/bor/at/o','','tetra-数詞接頭辞(4)→四。鳥tetra/o=野鸡(基本形)は除外。tetra/ol→四(2026-06-22 ol精緻化)。tetra/bor/at(WSL過細分解同期)'),
 # 化学接頭 pent-(5炭素鎖=pentose由来)→五。penta=五ᴾ・heks=六ᴴ・tetra=四ᵀ と平行(2026-06-23 最終収束WF)。
 # ※pent/ozan/o(ペントザン=五炭糖多糖)の派生語1件のみ。後悔penti/pent/o/pent/em=悔・縮小辞-et-は別morphemeでdisc不掲載=悔維持。pent/接頭辞定義見出し(pent/⟦悔⟧)もamb(支配義悔)で据置(met置/but培/et小と平行・批評裁定)。
 @('pent','五','pent/ozan/o','','化学接頭pent-(5炭素鎖)→五。pent/ozan=ペントザン(ペントース多糖)。後悔penti=悔・縮小辞-et-とは別morpheme(disc不掲載で悔維持)。penta=五ᴾ/heks=六ᴴと平行。ozanは不透明でlatin維持'),
 @('kaj','码','kaj/o,kaj/oj','','埠頭。接続詞kaj=和と別'),
 @('log','诱','log/i,log/aj^/o,al/log/i,al/log/o,al/log/a,al/log/aj^/o,de/log/i,de/log/o,el/log/i,for/log/i,mal/log/i,log/il/o,log/bird/o,log/fajf/il/o,log/ig^/i,seks/al/log/o,sens/al/log/a,tromp/log/i,seks/log/o','','誘惑(allure/lure)。-log-=学家と別。接頭al/de+log=動詞诱(allogi魅了/delogi誘惑)。seks/al/log・sens/al/log・tromp/log・seks/log(allogo=性的魅力/誘惑)も诱。※連結o付 seks/o/log/o=性科学者は学家(別語)(2026-06-23 sep派生形網羅)'),
 @('c^iel','天','c^iel/o,c^iel/a,c^iel/ark/o,c^iel/ark/a,c^iel/blu/a,c^iel/ir/o,c^iel/mekanik/o,c^iel/o/sfer/o,c^iel/rug^/o,c^iel/skrap/ant/o,c^iel/skrap/ul/o,c^iel/tus^/a,c^iel/ul/o,c^iel/an/o,c^iel/fajr/o,sub/c^iel/a,sub/c^iel/e','','空。相関詞c^iel=全样と別'),
 @('c^ar','车','c^ar/o,c^ar/ist/o,c^ar/eg/o,c^ar/et/o,c^ar/um/o,c^ar/on,c^ar/far/ist/o,c^ar/lev/il/o,au^t/o/c^ar/o,antau^/c^ar/o,post/c^ar/o,bov/o/c^ar/o,c^eval/c^ar/o,bagag^/o/c^ar/o,beb/o/c^ar/et/o,infan/c^ar/et/o,ac^et/c^ar/et/o,pus^/c^ar/et/o,pus^/c^ar/o,fald/c^ar/o,fald/c^ar/et/o,fest/o/c^ar/o,furag^/o/c^ar/o,elektr/o/c^ar/o,krom/c^ar/o,lev/c^ar/o,plen/c^ar/o,s^arg^/o/c^ar/o,serv/o/c^ar/et/o,sid/c^ar/et/o,tir/c^ar/o,trole/c^ar/o','','荷車/車両(ĉaro=cart)→车。接続詞ĉar(因)はdisc不掲載で維持。荷車ĉar系32見出しを網羅(2026-06-21): aŭt/o/ĉar=バス・bov/o/ĉar=牛車・ĉeval/ĉar=馬車・krom/ĉar=側車(外/车)・各乳母車(beb/o/infan/fald)・手押車(puŝ/ĉar/um)・ショッピングカート(aĉet/puŝ)・フォークリフトlev/ĉar・山車fest/o/ĉar・リヤカーtir/ĉar 等'),
 @('nom','学','agr/o/nom/o,agr/o/nom/a,agr/o/nom,astr/o/nom/o,astr/o/nom/a,astr/o/nom,gastr/o/nom/o,gastr/o/nom/a,gastr/o/nom,erg/o/nom/o,erg/o/nom/a,erg/o/nom','','科学-nom-(agronom/astronom/gastronom/ergonom)→学。名前複合(famili/nom/dosier/nom等)は名のまま'),
 # ギリシャ結合形 同綴衝突(2026-06-21・列挙sep)。fon→声と同型だが多義のため見出し列挙。正当語(bo/fil息子・du/lit/aベッド・buter/te茶)は disc 不掲載で保護。全字一级。
 @('fil','爱','bibli/o/fil/o,bibli/o/fil/i/o,pedo/fil/i/o,gastr/o/fil/o,gips/o/fil/o,hidr/o/fil/a,nekr/o/fil/i/o,skop/o/fil/i/o,fil/antrop/o,fil/antrop/i/o,fil/o/logi/o,fil/o/logi/a,fil/o/logi/ist/o,fil/o/log/o','','-fil-(philos=愛/-phile)→爱。語頭philo-(filantrop博愛/filolog文献学=言葉への愛)も含む(2026-06-22)。filo=息子(儿)はbo/du-on/adopt-o/bapt-o/pra/sol/ge/sen-fil で維持(disc不掲載)。filogenez=phylon系統は別語源で対象外'),
 @('per','过','per/oksid/o,per/oksid/i,per/oksid/a,per/oksid/az/o,per/klor/at/o,per/sulf/at/o,per/sulf/at/oj,per/klorat/o,per/oksidaz/o,per/sulfat/oj,per/mangan/at/o','','per-(化学:過酸化/過…)→过。前置詞per=以 は別。学術版粗分解 per/klorat/per/oksidaz/per/sulfat も过・per/mangan/at=過マンガン酸塩(両版)も过(2026-06-23 sep派生形網羅)'),
 @('oks','氧','an/oks/emi/o,hipoks/emi/o','','oxy-(酸素)→氧。牛oks/o=牛 は別'),
 @('leu^k','白','leu^k/emi/o','','leuko-(白)→白(白血病)。leu^ko=白ᴸ は別root'),
 @('astat','卤','astat/o','','-astat-(元素アスタチンAt=halogeno)→卤(液体ハロゲンbrom=卤と同カテゴリ§4.6)。astat/a=astatic(無定位)=无定 はmaster維持(disc不掲載)。astaten(=astato)はmaster卤'),
 @('lit','石','aer/o/lit/o,mega/lit/a,mega/lit/o,mono/lit/a,mono/lit/o,neo/lit/ik/o,paleo/lit/ik/o,epi/paleo/lit/ik/o,mez/o/lit/ik/o,mikro/lit/a,mikro/lit/o,piz/o/lit/o,fot/o/lit/o/grafi/o,krom/o/lit/o/grafi/o','','-lit-(lithos=石/-lith)→石。lito=寝台(床)はdu/kvar/tri/unu-lit/a・klap/krad/pend/port/ter/sof-o/pajl-o-lit で維持。elektrolit=-lyte(別形態素)は別sep lit→解(2026-06-23ユーザー裁定)'),
 # electrolyte の -lyte(溶解/分解。-lith石とは別形態素)→解。中国語「电解质」と一致(2026-06-23ユーザー裁定)。
 @('lit','解','elektr/o/lit/o,elektr/o/lit/a','','-lyte(電解質electrolyte=溶解/分解する物)→解。中国語 电解质 と一致。lithos=石(-lith)とは別形態素・寝台lit/o=床とも別'),
 @('te','神','a/te/ism/o,a/te/ist/a,a/te/ist/o,mono/te/ism/o,mono/te/ist/o,pan/te/ism/a,pan/te/ism/o,pan/te/ist/o,poli/te/ism/o,poli/te/ist/o,te/o/krati/a,te/o/krati/o,te/o/krat/o,te/o/logi/a,te/o/logi/ist/o,te/o/logi/o,te/o/log/o,te/ism/o,te/ist/o','','-te-(theo=神)→神。teo=茶(茶)はbuter/te で維持(disc不掲載)。te/ism/o=有神論・te/ist/o=有神論者(theism/theist)も神(2026-06-23 sep派生形網羅)'),
 @('top','境','bio/top/o','','-top-(topos=場所/-tope)→境(生境=habitat)。topo=檣楼(帆楼)はtop/o単独で維持'),
 # WSL最新分解(2026-06-21)同期で露出した結合形(多義のため列挙sep)。-cyte=胞。主義(引=citi引用)は disc不掲載で保護。
 # ※-poez-(造血·-poiesis)=生 は master poez=生 へ昇格(2026-06-22)。poez は詩義を持たず常に poiesis=生(詩は別語根 poezi=诗)。bare poez/o と複合の id 整合のため sep は廃止。
 @('il','基','aceton/il/o,benzo/il/o,form/i/il/o,fosfor/il/o,jod/il/o,karbon/il/o,kromi/il/o,benzo/il/i,fosfor/il/i,fosfor/il/ad/o,benzo/il-glicin/o','','化学ラジカル-il(-yl原子団)→基。器具-il=具は別。動詞/派生 benzo/il/i,fosfor/il/i,fosfor/il/ad/o,benzo/il-glicin/o(馬尿酸)も基(2026-06-23 sep派生形網羅)'),
 @('mon','单','mon/ism/o,mon/ist/o','','monos(単一)→单。金銭mon=钱は別'),
 @('au^t','自','au^t/ism/o,au^t/ism/ul/o,au^t/ism/a,au^t/o/bio/grafi/o,au^t/o/grafi/o,au^t/o/graf/o,au^t/o/krati/o,au^t/o/krat/ism/o,au^t/o/krat/o,au^t/o/krat/a,au^t/o/krat/ec/o,au^t/o/liz/o,au^t/o/gen/a,au^t/o/gen/o','','auto-(自己)→自。自動車au^t/o/mobil=车は除外。au^t/o/gen=自家生成(WSL同期)'),
 @('kok','菌','mikro/kok/o,diplo/kok/o,enter/o/kok/o','','-coccus(球菌)→菌。鶏kok=鸡は別'),
 @('strat','层','kron/o/strat/i/grafi/o,strat/i/graf/o,strat/i/grafi/o,stratum/o','','stratum(地層)→层。街strat=街は別'),
 @('cit','胞','fag/o/cit/ad/o,fag/o/cit/i,fag/o/cit/o,fag/o/cit/oz/o,granul/o/cit/o,hiper/granul/o/cit/emi/o,hipo/granul/o/cit/emi/o,leu^ko/cit/o,leu^ko/cit/o/poez/o,leu^ko/cit/oz/o,limf/o/cit/o,ov/o/cit/o,spermat/o/cit/o,tromb/o/cit/o,cit/oz/o,el/cit/oz/o,ekzo/cit/oz/o,en/cit/oz/o,endo/cit/oz/o','','-cyt-(細胞·-cyte)→胞。citi=引(re/cit・mis/cit・supr/e/cit)は保持。cit/oz(エキソ/エンドサイトーシス等)の接頭辞派生も胞(2026-06-23 sep派生形網羅)'),
 # 結合形フォルスフレンド是正(2026-06-21・列挙sep)。phago=吞・thrombo=栓。主義(树=ブナ / 龙卷=竜巻)は disc不掲載で保護。一级:吞7画/栓10画。fag/trombはmasterに残し(树/龙卷)、医学文脈の見出しのみ上書き。
 @('fag','吞','bakteri/o/fag/o,fag/o/cit/ad/o,fag/o/cit/i,fag/o/cit/o,fag/o/cit/oz/o,antrop/o/fag/o,antrop/o/fag/ism/o,makr/o/fag/o','','-phago-/-phage(貪食)→吞。ブナfag/o(树)はfag/o,fag/ar/o,fag/ej/o,fag/o/frukt/o,fag/o/nuks/o,fag/ac/oj,sang/o/fag/o(赤葉ブナ),s^ajn/fag/o(ナンキョクブナ)で維持。ezofag(食道)/fagopir(蕎麦)/fagot(ファゴット)は別セグメントで無影響'),
 @('tromb','栓','tromb/oz/o,tromb/ektomi/o,tromb/o/cit/o','','-thrombo-(血栓)→栓。tromb/oz/o は cerb/a tromb/oz/o(脳血栓)内の同語も捕捉。竜巻tromb/o(気·第1義)とsabl/a tromb/o(陸竜巻)は龙卷を維持。trombon(トロンボーン)/trombin(トロンビン)/trombidi(ツツガムシ)は別セグメントで無影響'),
 # 結合形フォルスフレンド第2弾(2026-06-21・列挙sep)。網羅スイープで検出。各主義はmaster維持(热/锅/肾/我/神。patiはsuf情)、医学・数学文脈の見出しのみ上書き。一级:项病再肌二。
 @('term','项','term/o,du/term/o,tri/term/o','','terminus(数項·論名辞)→项。thermo(termometr/izoterm/termodinamik等は別語文字列)は热維持。bare term/o=【数】項;【論】名辞なので项'),
 @('pati','病','aden/o/pati/o,aden/pati/o,encefal/o/pati/o,kardi/o/pati/o,kardi/mi/o/pati/o,kinez/o/pati/o,koks/o/pati/o,limf/aden/o/pati/o,medol/o/pati/o,medol/pati/o,mi/o/pati/o,mjel/o/pati/o,nefr/o/pati/o,neu^r/o/pati/o,ost/o/pati/o,pati/o,pneu^mon/o/pati/o,psik/o/pati/o,psik/o/pati/ul/o,retin/o/pati/o,trik/o/pati/o','','-pathy(臓器疾患)→病。感情系 a/pati(無感動)·anti/pati(反感)·tele/pati(テレパシー) と simpati(亲) は情/亲のまま維持(disc不掲載)'),
 @('pat','病','pat/o/gen/a,pat/o/logi/a,pat/o/logi/o,pat/o/log/o,pat/o/genez/o,fit/o/pat/o/logi/o,plant/pat/o/logi/o,psik/o/pat/o/logi/o,sem/pat/o/logi/o,psik/o/pat/o','','patho-(病理·病原)→病。フライパンpat/o(锅)·チェスstalemate pat(困amb)は锅のまま維持(disc不掲載)。psik/o/pat/o=精神病質者も病'),
 @('ren','再','ren/ir/i','','古語接頭ren(=re再び·reniri帰る)→再。腎臓ren/o(肾)は維持(disc不掲載)'),
 @('mi','肌','mi/o,mi/it/o,mi/o/pati/o,mi/o/kardi/o,mi/o/fibr/it/o,mi/o/globin/o,mi/o/sarkom/o,kardi/mi/o/pati/o','','myo-(筋肉)→肌。代名詞mi(我)·所有mi/aj^/o(私の物=我)は維持(disc不掲載)'),
 @('di','二','di/,di/morf/a,di/morf/ec/o,di/morf/ism/o,di/ploid/a,di/pod/o,di/pod/ed/oj,di/gram/o,di/kotiledon/oj,di/al/o,di/azot/o,di/azot/i,di/azot/at/o,di/metoksi/fenol/o,di/kromiat/o,di/mer/o,di/sakarid/o,di/tionat/o,di/sulf/id/o,di/oksid/o,di/klor/id/o,di/pter/oj,di/valent/a,karbon/di/oksid/o,sulfur/di/oksid/o,di/ol/o,di/ol/oj,di/kromi/at/o,di/sakar/id/o','','数詞di-(2)→二。di/kromi/at重クロム酸塩・di/sakar/id二糖(WSL過細分解 Xat→X/at・Xid→X/id 同期)。神di/o系(di/o/tim神畏敬·di/skarab神甲=テントウムシ)は神維持(disc不掲載)。di/pter双翅·di/klor/id二塩化等のエス的分解##偽分解(PIV正式)を尊重し透明化'),
 # 結合形フォルスフレンド第3弾(2026-06-21・最終網羅スイープworkflow6agent検出)。各主義master維持、科学/医学文脈の見出しのみ上書き。一级:全时共向心种火压光耳尿根指图字。
 @('gram','图','aer/o/gram/o,anem/o/gram/o,dia/gram/o,elektr/o/kardi/o/gram/o,encefal/o/gram/o,faz/dia/gram/o,faz/o/dia/gram/o,hips/o/gram/o,holo/gram/o,kabl/o/gram/o,kardi/o/gram/o,nivel/dia/gram/o,organi/gram/o,orto/gram/o,paralel/o/gram/o,radi/o/gram/o,radi/o/tele/gram/o,scintil/o/gram/o,seism/o/gram/o,spektr/o/gram/o,tefi/gram/o,tele/gram/o,tele/gram/kod/o,tele/gram/port/ist/o,penta/gram/o,gram/o/fon/o,gram/o/fon/disk/o,-gram/','','-gram(記録·図像γράμμα)→图。重量gram(克):kilo/centi/mili/deka/hekto-gram·gram/atom·gram/molekul·gram/pez は克維持。文字義は字(別エントリ。表音文字fon/o/gram=声/字も字へ移管)。蓄音機gram/o/fon(記録音→图/声)も捕捉。接尾辞定義entry -gram/(=記録·図像の意)→图(ハイフン分岐のhsep下位分節適用)。dia/gram/oはflor/a等多語も捕捉'),
 @('gram','字','di/gram/o,ide/o/gram/o,mono/gram/o,tetra/gram/o,epi/gram/o,epi/gram/ist/o,fon/o/gram/o','','-gram(文字·書記素)→字。digraph二字·表意文字·組合せ文字·聖四文字·警句epigram(epi/gram=表ᴱ/字ᴳ)·表音文字phonogram(fon/o/gram=声ᶠᴼ/字ᴳ=音を表す文字。fon→声はfon sep)。記録図像は图·重量は克。2026-06-21 epigram/phonogram追加'),
 @('pan','全','pan/kromat/a,pan/te/ism/o,pan/te/ist/o,pan/te/ism/a,pan/slav/ism/o','','pan-(汎·全all)→全。パンpan/o(面包)·pan/ej/pan/um/pan/tranc^等は維持'),
 @('kron','时','izo/kron/a,izo/kron/ec/o,kron/o/graf/i,kron/o/graf/o,kron/o/logi/a,kron/o/logi/o,kron/o/metr/i,kron/o/metri/o,kron/o/metr/o,kron/o/metri/a,kron/o/metr/ist/o,kron/o/strat/i/grafi/o,sin/kron/a,sin/kron/ec/o,sin/kron/ig/i,sin/kron/ig/il/o,sin/kron/o/skop/o,post/sin/kron/ig/i,post/sin/kron/ig/o,mal/sin/kron/ig^/i,dia/kron/a,dendro/kron/o/log/o,dendro/kron/o/logi/o,geo/kron/o/logi/o','','chrono-(時)→时。王冠kron/o(冠)·戴冠kron/ad·冠状ウイルス·皇太子·コロナ放電kron/efluv·dethrone sen/kron/igは冠維持·クローネ通貨は币'),
 @('sin','共','sin/kron/a,sin/kron/ec/o,sin/kron/ig/i,sin/kron/ig/il/o,sin/kron/o/skop/o,post/sin/kron/ig/i,post/sin/kron/ig/o,mal/sin/kron/ig^/i,sin/onim/a,sin/onim/ec/o,sin/onim/o,sin/onim/ik/o','','syn-(共·同together)→共。胸sin/o(怀)·再帰sin(自)は別エントリで維持'),
 @('sin','自','sin/kon/o,sin/asekur/o,sin/dev/ig/ad/o,sin/g^en/o,sin/g^en/ad/o,sin/kapt/ad/o,sin/mem/kulp/ig/o,sin/masturb/o,sin/nutr/ad/o,sin/pel/ad/o,sin/venen/ad/o','','再帰代名詞sin(si対格=自己oneself)→自。syn-(共)·胸sin/o(怀)は別義で維持(disc別記)。sin/mem/kulp/ig=自/自(mem=自と重複もR1衝突歓迎)。両版同11見出し'),
 @('trop','向','helio/trop/o,helio/trop/kolor/a,helio/trop/ism/o,izo/trop/a,izo/trop/ec/o,ne/izo/trop/a,ne/izo/trop/ec/o,an/izo/trop/a,trop/ism/o,cito/trop/a,enantio/trop/a,enantio/trop/ec/o,enantio/trop/ism/o,foto/trop/ism/o,geo/trop/ism/o,kortiko/trop/a,neu^r/o/trop/a,tikso/trop/a,tikso/trop/ec/o','','-tropos(向·屈性)→向。修辞trop/o(喻)は維持。tropik热带/antrop人は別セグメント'),
 @('kard','心','endo/kard/it/o,endo/kard/o,peri/kard/o','','cardio-(心)→心。アザミkard/o(刺草)·梳毛kard/adは維持。kardi/o(-i付)は既に心ᴷᴰ。endo/kard/o=心内膜・peri/kard/o=心膜(WSL同期2026-06-27)'),
 @('pir','火','pir/heli/o/metr/o,pir/geo/metr/o,pir/o/elektr/a,pir/o/magnet/a,pir/o/teknik/aj^/o,pir/o/teknik/ist/o,pir/o/teknik/o,pir/o/liz/i,pir/o/liz/o,pir/o/metr/o,pir/o/fosf/at/o,pir/o/gajl/o,pir/o/gajlol/o,pir/o/sulf/at/o,pir/o/sulf/it/o,pir/o/fosfat/o','','pyro-(火·熱)→火。pir/o/fosfat=学術版粗分解(2026-06-23)。洋ナシpir/o(梨)·pir/arb/pir/uj/pir/vinは維持'),
 @('bar','压','izo/bar/o,mili/bar/o,bar/o/graf/o,bar/o/metr/o,bar/o/skop/o','','baro-(気圧)→压。障害bar/i/bar/il/o(障)は維持。bar/o単独=障/圧二義はamb的に障維持'),
 @('fot','光','fot/on/o,fot/o/sfer/o,fot/o/sintez/o,fot/o/c^el/o,fot/o/kemi/o,fot/o/kemi/a,fot/o/metri/o,fot/o/metr/o,fot/o/metri/i,fot/o/jon/ig/i,fot/o/kondukt/iv/a,fot/o/liz/i,fot/o/terapi/o,fot/o/volta/a,fot/on/mikro/skop/o','','photo-(光)→光(物理·化学·生物)。写真fot/o/fot/i/fot/o/graf等は拍維持。複合語内の光物理/光化学派生も光へ網羅(2026-06-25 接尾辞悉皆監査の派生メモから: fot/o/kemi/a光化学[スモッグ/酸化剤句もカバー]・fot/o/jon/ig光電離・fot/o/kondukt/iv光伝導・fot/o/liz光解・fot/o/terapi光線療法・fot/o/volta光起電・fot/on/mikro/skop光子顕微鏡。hsep whole-word盲点の補完=al/翼と同型)'),
 @('ot','耳','ot/o,ot/it/o,ot/algi/o,ot/o/logi/o,ot/o/skop/o,ot/o/skop/i/o,ot/o-rin/o-laring/o/log/o,ot/o/rin/o/laring/o/logi/o,ot/o/salping/o,ot/o/salping/it/o,ot/a','','oto-(耳)→耳。未来受動分詞-ot-(待。nask/ot/vend/ot/a等)は維持。ot/a(耳の)は旧$new重複を統合'),
 @('ur','尿','ur/gener/a,ur/o/gener/a','','uro-(尿)→尿。オーロックスur/o(原牛)は維持。uro/log/uro/grafiは既に尿ᵁᴼ'),
 @('riz','根','riz/o/morf/o,riz/o/pod/oj','','rhizo-(根)→根。米riz/o(米)·稲riz/kamp/riz/o/spik等は維持。rizom=根茎'),
 @('daktil','指','daktil/o/graf/i,daktil/o/skop/i/o','','dactylo-(指)→指。ナツメヤシdaktil/o(枣)·daktil/o/palm等は維持'),
 @('sperm','种','endo/sperm/o,peri/sperm/o','','-sperma(種·胚乳)→种。精液sperm/o(精液)·sperm/o/dukt等は維持'),
 # 結合形フォルスフレンド第4弾(2026-06-21・優先順位/方針 多エージェント監査で検出)。-log-=言葉(話)·-metr-=計器(计)。
 @('log','话','dia/log/a,dia/log/i,dia/log/o,dia/log/oj,dia/log/uj/o,dia/log/ist/o,mono/log/i,mono/log/o,pro/log/o,epi/log/o,neo/log/o,neo/log/ism/o,neo/log/ism/em/o,neo/log/ism/em/ul/o','','-log-(logos=言葉·談話/-logue)→话(parol=话と同字共有)。対話dia/独白mono/序言pro/跋epi/新語neo(neologism=新话)。-logist/-ology=学家(biolog等)·al-de+log=诱は別。katalog=录·analog=似(whole-root)は不変'),
 @('metr','米','centi/metr/o,deci/metr/o,deka/metr/o,hekto/metr/o,kilo/metr/o,mili/metr/o,mikro/metr/o,miria/metr/o,kub/metr/o,kilo/gram/metr/o,para/metr/o,izo/metr/o,izo/metr/a,heks/a/metr/o,penta/metr/o,geo/metr/o,kvadrat/metr/o,kilogram/metr/o','','-metr-の非計器(長さ·面積·体積単位/詩脚/人)は米(metre/measure)維持。下の comb metr→计(計器)を見出しで上書き。単位centi-kilo·parameter para·isometric izo·hexa-penta詩脚·geometer(人)geo。※直径dia/半径du/on/dia/周径peri は下の metr→测(measure)sepへ移管(2026-06-21・ユーザー裁定)'),
 # 直径系の-metr-=抽象measure→测(mezur測る=测の基底・metri测ᴹᵀと同family。dia/metr=横切って測る=diameter語源)。米(metre単位)·计(計器)·测ᴹᵀ(metri)と並ぶmetrの第4文脈。2026-06-21ユーザー裁定 米→测。
 @('metr','测','dia/metr/o,dia/metr/a,du/on/dia/metr/o,peri/metr/o','','-metr-(抽象measure=直径/半径/周径)→测。测の基底mezur(測る)・metri(测ᴹᵀ)と同family。dia/metr=通ᴰ/测「横切って測る」=diameter語源。長さ単位centi/kilo·詩脚heks/penta·geometer geoは米sep維持'),
 # ギリシャ接頭pro-(前)·ワットwatt(瓦)の同綴是正(2026-06-21追補。/goal監査の据置項目をmerit判断で是正)
 @('pro','前','pro/log/o,pro/faz/o,pro/virus/o','','ギリシャ接頭pro-(前·fore)→前。prologue序言(pro/log⟦前/话⟧)·prophase前相(pro/faz⟦前/相⟧)·provirus前駆ウイルス(pro/virus⟦前/毒⟧)。epi=后と対。エス前置詞pro=因(pro tio因此·proparol代弁·pro/pek贖罪·pro/mort等)は維持(disc不掲載)'),
 @('vat','瓦','giga/vat/o,kilo/vat/o,mega/vat/o,vat/hor/o,vat/hor/o/metr/o,vat/metr/o,vat/sekund/o,kilo/vat/hor/o,mega/vat/hor/o','','ワットwatt(瓦)→瓦。kilo/vat/hor=キロワット時・mega/vat/hor=メガワット時(2026-06-23 sep派生形網羅)。kilovat/megavat/gigavat/vatmetr電力計/vathor瓦時/vatsekund 等の電力複合。綿vat/o(棉)·suker/vat綿菓子·vat/baston綿棒·vat/it綿入 等は維持(disc不掲載)。bare vat/o=棉&瓦はamb(基本義 棉維持)'),
 # メトロノーム metronomo の同綴是正(2026-06-21。米/名は誤り→计/律。merit判断)。metr語頭idx0でcomb非適用→sepで计(計器)。nom=ギリシャnomos(法/掟)→律(leĝ=律と整合・かつ音律/拍節で楽器に二重適切)
 @('metr','计','metr/o/nom/o','','メトロノームmetr(計器·measure)→计。idx0でcomb metr→计 非適用のためsep明示。長さ単位等の非計器metrは上の米sepで処理'),
 @('nom','律','metr/o/nom/o','','メトロノームnom(ギリシャnomos=法/掟)→律。leĝ法律=律と整合し律=音律/拍節も兼ね楽器に二重適切。科学-nomy=学(agronom)·名前複合=名 とは別の第3義。计律=計測+音律=節拍器'),
 # aŭtomobil 過剰分解是正(2026-06-21・ユーザー裁定OptionA)。辞書 ##過細分解 au^t/o/mobil/o の mobil=挂饰(モビール)は誤友→动(-mobile=可動)。aŭt=车(基本形)はそのまま=车/o/动/o。aŭtomat(动)の兄弟として动群へ合流(动ᴹᴮ)。
 @('mobil','动','au^t/o/mobil/o,au^t/o/mobil/a,au^t/o/mobil/ism/o,au^t/o/mobil/ist/o,au^t/o/mobil/kompani/o,mobil/iz/i,mobil/iz/ad/o,mobil/iz/o,mal/mobil/iz/i,mal/mobil/iz/ig^/i,mal/mobil/iz/o,lok/o/mobil/o','','mobil(-mobile=可動·自動·移動)→动。aŭtomobil車+動員mobil/iz(復員mal/mobil/iz)+移動式蒸気機関lok/o/mobil。モビール装飾mobil/o(挂饰)はdisc不掲載で挂饰維持。aŭtomat=动と同群'),
 # 結合形フォルスフレンド第5弾(2026-06-21・/goal多エージェント敵対検証で検出)。全字一级(声/径)。既存sep機構。
 # ②phono-(声)が先頭分節idx0=蓄音機/音韻論。背景fon(底)はdisc不掲載で維持。gram/o/fon=声ᶠᴼ(idx>0)と整合。
 @('fon','声','fon/o/graf/o,fon/o/gram/o,fon/o/logi/o,fon/o/metr/o,fon/o/metri/o,fon/o/skop/o,fon/on/o','','phono-(音·声)結合形がidx0(先頭分節)=蓄音機/音韻論/音波測定等→声。背景fon/o(底)·fon/a/fon/bru/o/fon/farb/fon/muzik/o/fon/s^mink/fon/tol/fon/tul はdisc不掲載で底維持。phononフォノンfon/on/o=声/子(2026-06-23ユーザー裁定。fon=声[他phono-語と一貫]・on=子[$onStemにfon追加])'),
 # WSL再分解(2026-06-21・19:08版同期)で露出した接頭辞フォルスフレンド。bi-(two)→二・物理spin→旋。全字一级。
 @('bi','二','bi/,bi/dent/o,bi/dual/o,bi/gami/o,bi/gami/ul/o,bi/holo/morf/a,bi/holo/morfi/o,bi/jekci/a,bi/jekci/o,bi/karbon/at/o,bi/kromiat/o,bi/metal/a,bi/metal/ism/o,bi/sulf/at/o,bi/sulf/it/o,meta/bi/sulf/it/o,poli/klor/bi/fenil/o,bi/kromi/at/o,bi/holomorf/a,bi/holomorfi/o,bi/sulfat/o,bi/sulfit/o,meta/bi/sulfit/o','','bi-(two=二)→二。学術版粗分解 bi/holomorf(双正則)・bi/sulfat(重硫酸塩)・bi/sulfit(重亜硫酸塩)・meta/bi/sulfit も二(2026-06-23 sep派生形網羅。bio生はdisc不掲載で維持)。biot生(bi/ont/o/logi=生物学)はdisc不掲載で生維持。重婚bi/gami・重曹bi/karbon/at・双射bi/jekci・双金属bi/metal・重铬酸bi/kromiat・メタ重亜硫酸meta/bi/sulf/it・PCB poli/klor/bi/fenil 等。di-(二)と平行'),
 @('spin','旋','spin/momant/o,izo/spin/o','','物理spin(角運動量)→旋。背骨spin/o(脊)・脊髄spin/a・脳脊髄cerb/o/spin/a・cefal/o/spin/aは脊維持(disc不掲載)。spin/o=背骨/スピンの二義のうち物理複合のみ旋'),
 # /goal第2次敵対検証(2026-06-21)で検出した追加フォルスフレンド。allo-(他·異)→异・化学-id(-ide二元化合物)→化。全字一级。
 @('alo','异','alo/fon/o,alo/fon/a,alo/morf/o,alo/trofi/o','','ギリシャ接頭allo-(他·異different)→异。allophone异音(alo/fon)·allomorph异形态(alo/morf)·allotrophy异养(alo/trofi)。アロエ alo/o(草)·alo/aj^/o(草)はdisc不掲載で草維持。合金aloj/oは別根(合金)'),
 @('id','化','brom/id/o,brom/id/paper/o,cian/id/o,klor/id/o,klor/id/a,di/klor/id/o,tri/klor/id/o,metil/klor/id/o,vinil/klor/id/o,klor/id/emi/o,hipo/klor/id/emi/o,sen/klor/id/ig^/o,sulf/id/o,di/sulf/id/o,fluor/id/o,fosf/id/o,halogen/id/o,hidr/id/o,hidr/id/i,jod/id/o,karb/id/o,karbon/id/o,nitr/id/o,selen/id/o,ure/id/o','','化学-id(-ide=二元化合物X化物)→化。塩-at/-it=盐の兄弟(-ide=化合物 / -ate-ite=塩)。子孫-id(bov/id仔牛·kat/id仔猫·c^eval/id等の動物の子)はdisc不掲載で子維持。lanthanoid lantan/id(系列)·saccharide sakar/id(糖類)は二元化合物でないため除外') )
# 新54(root,override,headwordForm,2nd義キーワード(amb判別用),note)
$new=@(
 @('al','翼','al/o,helic/al/o,c^irkau^/al/a,frog/al/o','翼','翼(alo=翼/羽根)。前置詞al=向と別。複合語内al/o=翼も翼へ(helic/al/o=プロペラ羽根・c^irkau^/al/a=翼に囲まれた・frog/al/o=フログ翼部。hsepはwhole-wordキーのため複合を明示列挙=2026-06-25 接尾辞悉皆監査WF)'),@('por','孔','por/o,por/a','孔','気孔。前置詞por=为と別'),@('sur','腿','sur/o','ふくらはぎ','ふくらはぎ。前置詞sur=上と別'),
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
 @('male','疫','male/o','鼻疽','馬鼻疽。male=捶と別行'),@('sinus','弦','sinus/o','正弦','正弦sine。sinus=洞と別行'),
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
$ozChem=@('jod/oz/o')   # 化学結合形-oz(iodoso=grupo IO 価数接尾辞・nitrozo同系列)→どのoz discにも入れず=_inject_finalの$segLatでlatin化(病-osis症でない。2026-06-25 接尾辞悉皆監査WF)
$onStem=@('elektr','prot','neu^tr','fot','mez','magnet','nukle','fon')   # fon追加: phonon=fon/on→子(2026-06-23ユーザー裁定。phono声+on子)
$ozD=New-Object System.Collections.ArrayList;$ozS=New-Object System.Collections.ArrayList;$onP=New-Object System.Collections.ArrayList
$ozK=@{};$onK=@{}
foreach($ln in $ozLines){ $ci=$ln.IndexOf(':'); if($ci -lt 1){continue}; $hh=$ln.Substring(0,$ci); $gg=$ln.Substring($ci+1)
  foreach($w in ($hh -split ' ')){ $sg=$w -split '/'
    $io=[array]::IndexOf($sg,'oz')
    if($io -ge 1 -and -not $ozK.ContainsKey($w)){
      $sugar=($gg -match '糖') -or ($gg -match '(?i)(sakar|sukero|monosakar|polisakar|glucid|pentoz|heksoz|glikoz|glukoz|aldehid)') -or ($w -match 'celul/oz') -or ($w -eq 'gren/malt/oz/aj^/o')   # celul/oz* (celul/oz/o・celul/oz/a・hemi/celul/oz/o)=多糖→糖。celuloseは常に多糖類(2026-06-23 sep派生形網羅)
      if($sugar){ $ozK[$w]=$true; [void]$ozS.Add($w) }
      elseif($ozRich -contains $w){ $ozK[$w]=$true }   # genuine -oza形容詞(草の多い/瀝青質の)→富(disp基底維持)
      elseif($ozChem -contains $w){ $ozK[$w]=$true }   # 化学結合形-oz(iodoso価数接尾辞)→どのoz discにも入れず=segLatでlatin
      else{ $ozK[$w]=$true; [void]$ozD.Add($w) }   # 他-oz全て→症(病/過程変態/食作用/膜/jetlag/条件形容詞=状態全般に集約)
    }
    $in=[array]::IndexOf($sg,'on')
    if($in -ge 1 -and -not $onK.ContainsKey($w) -and ($onStem -contains $sg[$in-1])){ $onK[$w]=$true; [void]$onP.Add($w) }
  } }
[void]$ozS.Add('oz/o')   # 標準語oz/o(単独=単糖monosaccharide)→糖。oz語幹idx0で自動分類外のため明示追加
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
# 最終本番注入: 学習者版・学術版の両方に disp(漢字+§9識別子)を注入。homonym(sep見出し)・privative=无ᴬ・en・連結母o省略。各ファイルで原本diff=0検証。
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
$srcDir="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026"
$pairs=@(
  @('世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt','漢字注入_学習者版_20260620.txt'),
  @('世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt','漢字注入_学術版_20260620.txt') )
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^' }
# --- sidecar disp(主義) ---
# $disp=完全一致(case-sensitive)辞書 / $dispCI=大小無視フォールバック。既定@{}は大小無視のため leandr(虾ᴸᴺ)が Leandr(虾ᴸᴱ)に上書きされ、小文字leandrの引きが誤ってᴸᴱになる大小衝突を是正(2026-07-13)。引きは「完全一致優先→無ければ従来どおり大小無視」で、大小衝突する語根(現状 leandr/Leandr の1件のみ)だけが自分の識別子に直り、他は完全不変。
$disp=New-Object 'System.Collections.Generic.Dictionary[string,string]'; $dispCI=@{}
Import-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -Delimiter "`t" | ForEach-Object { $rk=(ToHsys $_.root); $disp[$rk]=$_.disp; $dispCI[$rk]=$_.disp }
function DispHas([string]$k){ $disp.ContainsKey($k) -or $dispCI.ContainsKey($k) }
function DispGet([string]$k){ if($disp.ContainsKey($k)){ $disp[$k] } elseif($dispCI.ContainsKey($k)){ $dispCI[$k] } }
# --- homonym台帳(sep見出しのみ適用。amb=同一文字列は不採用) ---
$hsep=@{}; $comb=@{}
Get-Content "$dir\_homonym_disp.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
  $p=$_ -split "`t"; if($p.Count -lt 5){return}; $seg=$p[0];$type=$p[1];$disc=$p[2];$d=$p[4]
  if($type -eq 'sep'){ foreach($hw in ($disc -split ',')){ $hw=$hw.Trim(); if(-not $hw){continue}; if(-not $hsep.ContainsKey($hw)){$hsep[$hw]=@{}}; $hsep[$hw][$seg]=$d } }
  elseif($type -eq 'comb'){ $comb[$seg]=$d }   # 結合形(ギリシャ): idx>0 の完全一致分節で適用(fon→声)
}
$chemAcid = @('acet','fosf','karbon','nitr','sulf','silik','silici','molibden','klor','brom','jod','krom','kromi','bor','arsen','fluor','volfram','vanad','selen','telur','antimon','tartr','sakar','cian','ur')  # 酸根(先頭分節判定用)。2026-07-23 WF round5: ur(尿酸uric acid)追加=ur/at/emi/o(尿酸血症)の -at→被(受動分詞)誤読を 盐 へ(兄弟fosf/at/emi/o=磷/盐ᴬ/血ᴱ と同型。ur/o=原牛は at/it無で不発火)。化学塩 X/at・X/it→酸根漢字+盐。tartr(酒石酸)/sakar(糖酸)は語釈に塩語が無い吐酒石(吐酒石のみ)等を取りこぼすため radical で確実化(2026-06-20)。kromi=クロム酸根/silici=ケイ酸根/cian=シアン酸根(di/kromi/at・silici/at・cian/at等。WSL細分解 2026-06-23)
$chemMid  = @('acet','fosf','karbon','nitr','sulf','silik','silici','molibden','klor','brom','jod','krom','kromi','arsen','fluor','volfram','vanad','selen','telur','antimon','tartr','sakar','cian')  # 中位分節判定用=bor を除外(bor=钻ドリル動詞 と同綴。verm/bor/it=虫食い受動 の誤爆防止。boron塩 bor/at は先頭分節+homonymで処理)
$saltAt = "盐$([char]0x1D2C)"   # 化学塩 -at(-ate)=盐ᴬ(sal=盐 と一意区別。AddSegId相当)
$saltIt = "盐$([char]0x1D35)"   # -it(-ite 亜…酸塩)=盐ᴵ
$medIt = "炎$([char]0x1D40)"   # 医学-it-(-itis 炎症)=炎ᵀ。受動分詞-it=受 と弁別(inflam=炎ᴵ/katar=炎 とも別の慣例トークン。塩 盐ᴬ/盐ᴵ と同型)。2026-06-22 第4次WF敵対検証で確証(artr/it=关节炎が受でなく炎)
$medStem=@{}; foreach($ms in @('aden','albugine','alveol','aneks','ang','angi','aort','apendic','araknoid','arteri','artr','atik','balan','bronk','bulb','burs','cekum','cist','dakriocist','derm','dermat','duoden','encefal','enter','ependim','ezofag','faring','fibr','fleb','folikl','gangli','gastr','gingiv','glos','hepat','ile','iris','kard','kardi','kerat','kojl','kondr','konjunktiv','kord','korne','koroid','koronari','laring','lien','mastoid','mediastin','medol','mening','mi','miring','mjel','nefr','neu^r','oftalm','orel','orkid','ost','ot','ovari','palat','palpebr','panikl','pankreat','parotid','penis','peritone','pjel','pleu^r','pneu^mon','prostat','pulp','radikl','rektum','retin','rin','salping','sinovi','sinus','sklerot','stomak','stomat','tarz','tenden','timpan','tiroid','tonsil','trah^e','trake','ureter','uretr','uter','uve','vagin','vaginal','vaskul','vejn','verumontan','vulv','epifiz','koks','testik','celul','periost','pulm','mejbom')){ $medStem[$ms]=$true }   # 医学-itis(-it→炎)発火用=体部位/医学語幹。これら語幹+/it/=器官+炎症で確実に-itis(受動分詞は動詞語幹で非該当)。2026-06-25 WSL同期で露出: celul(蜂巣炎)・periost(骨膜炎)・pulm(肺炎=pneŭmonito)を追加(各語幹は-it/oの炎症形のみ・受動分詞用法なし)。※mitrは/o炎症と/a受動(ミトラ授与)が分かれるため語幹でなく$medItWord(語単位)で処理
$medItWord = @{ 'mitr/it/o'=$true }   # 語単位の-itis→炎ᵀ override(語幹がambで医学語幹に入れられない語用)。mitr/it/o=僧帽弁炎→炎、mitr/it/a=ミトラを授けられた(受動)→受 を弁別(2026-06-25)
$privDisp = "无$([char]0x1D2C)"   # privative a-/an- = 无ᴬ
$enDisp = if(DispHas 'en'){DispGet 'en'}else{'内'}
$endingRe = '^(o|a|e|i|u|oj|aj|ojn|ajn|as|is|os|us|u|j|n)$'   # on/an/en は除外し、-on=分/-an=员/en=内 を位置で裁定
$sufSet = @('ad','aj^','an','ar','ec','eg','ej','em','end','er','estr','et','id','ig','ig^','il','in','ind','ing','ism','ist','obl','on','op','uj','ul','um')  # privativeガード: 直後が派生接尾辞のみなら privative 不発火(an/ar/o=员群 等)
$dropLinkO = $false   # 連結母o省略: 【無効】=連結oも保持し1:1構造を残す(美/性/o/酪/o)。省略は後処理に委ねる(ユーザー2026-06-20確定)。$true で再有効化可
$chemInWord = @{ 'kaze/in/o'=$true; 'te/foli/in/o'=$true; 'aglutin/in/o'=$true; 'dent/in/o'=$true; 'vitr/o/dent/in/o'=$true; 'encefal/in/o'=$true; 'stimul/in/o'=$true; 'tiroid/stimul/in/o'=$true; 'gonad/o/stimul/in/o'=$true; 'digital/in/o'=$true; 'gastr/in/o'=$true; 'lign/in/o'=$true; 'koka/in/ism/o'=$true; 'koka/in/iz/o'=$true; 'koka/in/o/mani/o'=$true; 'tuberkul/in/a'=$true; 'tuberkul/in/iz/ad/o'=$true; 'eritr/o/poez/in/o'=$true; 'narkot/in/o'=$true; 'folikl/in/o'=$true; 'sekreci/in/o'=$true; 'fibr/in/o'=$true; 'emulsi/in/o'=$true; 'ost/e/in/o'=$true; 'pekt/in/o'=$true; 'te/in/o'=$true; 'terebint/in/o'=$true; 'cikl/o/alk/in/o'=$true; 'lakt/o/flav/in/o'=$true; 'muskol/glob/in/o'=$true; 'vegetal/in/o'=$true }   # 化学-ine過剰分解語: -in分節のみラテン保持(女性接尾-in→女 の誤友回避)し、他分節は活かす(偽分解尊重・2026-06-22)。2026-07-23 敵対監査(WF round2)で露出した生化学/物質-ine 9語追加(【PIV】等で語釈駆動latin[L117]が不発火の漏出): emulsi/in酵素(乳ᴱ/in)・ost/e/in骨蛋白ossein(骨/e/in)・pekt/inペクチン多糖(pekt/in)・te/inテイン=カフェイン(茶/in)・terebint/inテレビン油樹脂(木ᵀᴿ/in)・cikl/o/alk/inシクロアルキン(环/o/alk/in)・lakt/o/flav/inリボフラビン(乳/o/黄/in)・muskol/glob/inミオグロビン蛋白(筋/球ᴳ/in)・vegetal/in植物性バター(植ⱽ/in)。いずれも物質名で女性接尾でない(女→in是正)。2026-07-22 敵対監査(WF)で露出した生化学-ine 3語追加: folikl/in/o(卵胞ホルモン=Oestrono・囊ᶠ/女→囊ᶠ/in)・sekreci/in/o(セクレチン=腸ホルモン・泌/女→泌/in・兄弟gastr/in/o胃ᴳと一致)・fibr/in/o(フィブリン=血液凝固蛋白/グルテン麩素・句"veget/aĵ/a fibr/in/o"の【植】見出しで纤/女に漏出→纤/in・単独fibr/in/oは【化】で既にlatin)。kaze/in→凝/in(カゼイン=凝固蛋白)・te/foli/in→茶/叶/in(テオフィリン=茶葉成分)。insulin=胰岛素等の不可分根は元から1形態素。2026-06-25 WSL同期で露出した生化学-ine 4語追加: aglutin/in(凝集素=抗体)・dent/in(象牙質)・encefal/in(エンケファリン=神経ペプチド・encefal/it炎は不変)・stimul/in(刺激ホルモン)。2026-06-27 WSL同期で gonad/o/stimul/in/o(性腺刺激ホルモン=gonadotropin)露出→追加(兄弟 stimul/in/o・tiroid/stimul/in/o と一致させ 性腺/o/激ˢ/in/o。同期前 gonad/o/stimulin/o=性腺/o/激素ˢ/o の透明性を維持)
# 系統化学(IUPAC)アルキル語幹→天干【2026-07-17 甲乙丙基システム=ユーザー裁定】: 中国化学命名 metil甲基/etil乙基/propil丙基/butan丁烷。
# 全て一级(甲乙丙丁戊己庚辛壬癸)。met=置(meti置く)/et=小(指小)/okt=八/di=神 等の非化学義は「化学タグ$isSysChem + 化学接尾隣接($alkylSuf)」の二重ゲートで弁別。烷/烯/苯は一级外ゆえ -an/-en/fen はlatin。既存 et/oksi→乙・met/oksi→甲(下)の系列拡張。
$alkylStem = @{ 'met'='甲'; 'et'='乙'; 'prop'='丙'; 'but'='丁'; 'pent'='戊'; 'heks'='己'; 'hept'='庚'; 'okt'='辛'; 'non'='壬'; 'dek'='癸' }
$alkylSuf  = @('an','il','en','on','ol','anol','anal','anon')   # アルキル語幹に続く化学接尾(この隣接時のみ天干化)
# 元々: $forceUnt=@() (krom/o→金・titan/o→金・bor/o→矿 は homonym。krom/at→金ᴷᴹ/盐ᴬ は化学塩へ)
# segment単位ラテン: 語中の固有名morphemeのみ未対応(latin)保持。語全体ではなくその分節だけ漢字化しない。Japana落松·T-胞·E-屋(語/ハイフン単位)の分節版。非mapped=被覆を水増ししない。§7
$segLat = @{ 'gram/negativ/a'=@('gram'); 'gram/pozitiv/a'=@('gram'); 'deci/bel/o'=@('bel'); 'melo/mani/o'=@('melo'); 'di/en/o'=@('di')   # di/en/o(diene=ジエン): 化学di-(=二)は神(dio=神)の偽の友→di分節のみラテン(en=-ene接尾もラテン)。di/in/o=女神(di神+in女)は神維持=正(2026-06-29 WSL同期で dien→di/en 露出)。 # lip/om/o は脂肪lip→脂の構造ルール($s -eq 'lip')へ移行(2026-06-28・lip/瘤→脂/瘤に透明化)。 人名Gram(グラム染色)=固有名→gram分節のみラテン(否/正は維持)。重量gram(克)·記録gram(图)とは別。2026-06-21。 deci/bel/o: bel=音響単位ベル(人名Bell由来)→bel分節のみラテン保持(deci=分ᴰᶜは維持=キロオームkilo/om型)。bela美(beautiful)とは別の偽の友。2026-06-27 WSL同期で decibel/o→deci/bel/o 露出。 melo/mani/o: melo=希melos(音楽)結合形→ラテン保持(mani=狂は維持)。melo/o虫ᴹ(アナグマ=甲虫属Meloe)とは同綴別語の偽の友。melodi调ᴹ(旋律)は別root。2026-06-28
  # 偽分解尊重(2026-06-22): 結合形/借用接尾が同綴の内容語字に化ける誤友を、当該分節のみラテン保持で是正(他分節は活かす)
  'tio/alkohol/o'=@('tio');'tio/bacil/o'=@('tio');'tio/bakteri/o'=@('tio');'tio/cianat/o'=@('tio');'tio/cian/at/o'=@('tio');'izotio/cian/at/o'=@('tio');'tio/eter/o'=@('tio');'tio/fenol/o'=@('tio');'tio/fosf/at/o'=@('tio');'tio/sulf/at/o'=@('tio');'tio/sulf/it/o'=@('tio');'tio/ure/o'=@('tio');'tio/keton/o'=@('tio');'tio/amid/o'=@('tio');'tio/aldehid/o'=@('tio')   # 化学thio-(硫黄)→ラテン。相関詞tio=那o と別
  'kred/it/or/o'=@('or');'mono/kromat/or/o'=@('or');'konvert/or/o'=@('or')   # 装置/行為者-or→ラテン。金属oro=金 と別
  'par/onim/o'=@('par')   # ギリシャpara-(類似)→ラテン。対/偶数par=偶 と別
  'od/o/metr/o'=@('od')   # ギリシャhodos(道)→ラテン。賛歌od=颂 と別
  'are/o/metr/o'=@('are')   # ギリシャaraios(希薄/比重)→ラテン。面積are=面 と別
  'gangli/on/o'=@('on')   # ganglion借用語末-on→ラテン。分数-on=分 と別
  'magnet/it/o'=@('it')   # 鉱物-ite→ラテン。受動分詞-it=受 と別(磁鉄鉱)
  'in/vari/ant/o'=@('in')   # ラテン否定in-→ラテン。女性-in=女 と別(不変量)
  'homo/log/a'=@('log');'homo/log/ec/o'=@('log');'ko/homo/log/a'=@('log');'homo/log/aj'=@('log')   # logos=対応/相同→ラテン。-ology=学家 と別(homologous)。homo/log/aj(複数形容詞: homo/log/aj element/oj等の句見出し)も漏れ補完=全屈折形latin統一(2026-06-26)
  'ton/al/o'=@('al');'ton/al/a'=@('al');'ton/al/ec/o'=@('al');'du/ton/al/ec/o'=@('al');'mult/ton/al/ec/o'=@('al');'ne/ton/al/a'=@('al');'sen/ton/al/a'=@('al');'a/ton/al/a'=@('al')   # 形容詞-al(tonal調性)→ラテン。前置詞al=向 と別(WSL分解 ton/al 2026-06-23)
  'aktini/id/oj'=@('aktini')   # actinides(放射性金属元素系列)→aktiniラテン。Actinia海葵(aktini/o=【動】第1義・aktini/ul目も海葵)の元素文脈での誤友回避(2026-06-25 WSL同期)
  # 2026-06-25 接尾辞悉皆監査(WF w3piqpnyc)で露出した非受動/非病/非前置詞のtransparent結合形:
  'fer/it/o'=@('it')   # ferrite(純鉄のα/γ/δ相=冶金相)→-itラテン。鉱物magnet/it磁鉄鉱と同型。受動分詞-it=受 でない(fer=鉄に他動詞なし)。fer/at=铁/盐ᴬ(ferrate塩)は別処理で正
  'jod/oz/o'=@('oz')   # iodoso基(grupo IO=ヨードソ価数接尾辞・nitrozo同系列)→-ozラテン。病-osis(症)でない。_build_homonymの$ozChemでoz-症 disc から除外し本segLatでlatin化
  'fer/oz/a'=@('oz')   # 第一鉄feroza(ferrous=Fe(II)価数接尾-oz=iodoso/nitrozo同系列)→-ozラテン。病-osis(症)でない=fer/oz/a⟦铁/症⟧の誤読是正(§6化学価数)。_build_homonymの$ozChemにも追加(2026-07-21 第27回)
  'trap/an/o'=@('trap')   # トラピスト修道会員(La Trappe修道会=固有名§7)→trapラテン。菱Trapa(trap/o=草)の偽の友=trap/an/o⟦草/员⟧の誤読是正(trap latin・an=员維持)。2026-07-21 第27回
  'umbr/a'=@('umbr')   # ウンブリア語/派(Umbrian=固有名§7)→umbrラテン。魚Umbra(umbr/o=鱼)の偽の友=umbr/a⟦鱼⟧の誤読是正。umbr/o(魚義と歴史義が同綴amb)は§6.5据置。2026-07-21 第27回
  'agami/a'=@('agami')   # 無性の(agamia=希a-privative無配偶・生物学)→agamiラテン。ラッパチョウagami/o=鸟(Psophia)の偽の友=agami/a⟦鸟⟧(asexual≠bird)の誤読是正。正本がagami whole分解ゆえ理想の无配は不可・誤読除去優先。2026-07-21 第27回
  'hipo/tal/o'=@('tal'); 'tal/fit/oj'=@('tal'); 'tal/o/fit/oj'=@('tal')   # 叶状体thallus(talo=地衣/藻類の植物体)→talラテン。距骨talus(tal/o=距=解剖の踵骨)の偽の友=hipotal/talfit(Thallophyta)⟦距⟧の誤読是正。tal/o=距骨は維持。2026-07-22 正本 hipotal→hipo/tal 露出で顕在化(第27回続)
  '2-buten/al/o'=@('al')   # クロトンアルデヒド(CH3-CH=CH-CHO)→-alラテン。アルデヒド結合形(cinam/al・klor/al兄弟と同型)。前置詞al=向 でない。##過細分解由来(学術版は単一根)
  'piridoks/al/fosf/at/o'=@('al')   # ピリドキサールリン酸(アルデヒド誘導体補酵素)→-alラテン。fosf/at=磷/盐ᴬ は正。##過細分解由来
  'miko/plasm/al/oj'=@('al')   # Mycoplasmatales(マイコプラズマ目)→分類学-al(目)はラテン。前置詞al=向 でない。##エス的分解由来
  # 2026-07-22 敵対監査(WF false-friend audit)で露出した -al=向 誤描画(学習者版のみ・学術版はwhole-root latinで健全):
  'femur/al/o'=@('al'); 'frunt/al/o'=@('al'); 'okcipit/al/o'=@('al'); 'pariet/al/o'=@('al')   # 解剖-al骨(=X-osto: 大腿骨/前頭骨/後頭骨/頭頂骨)→解剖形容詞-alはラテン。股/额/后脑/壁ᴾ 母体維持。前置詞al=向 でない(股ᶠ/向=「股へ」の誤読是正)。##過細分解 X/a/l/o 由来
  'erizif/al/oj'=@('al'); 'mukor/al/oj'=@('al'); 'rikeci/al/oj'=@('al'); 'spiroket/al/oj'=@('al'); 'ured/al/oj'=@('al'); 'ustilag/al/oj'=@('al')   # 分類学-al目(Ordo -ales: Erysiphales/Mucorales/Rickettsiales/Spirochaetales/Uredinales/Ustilaginales)→miko/plasm/al/oj と同型。菌ᴱᴿ/菌ᴹᴿ/rikeci/螺旋体/锈ᵁ/菌ᵁᵀ 母体維持・al=向でない
  'direkt/al/o'=@('al')   # 垂直安定板(【空】direktalo=尾翼・>>empeno)→形容詞-alはラテン(ton/al同型)。方(direkt master)維持。方/向=方向 の偶発可読が「方角」の誤読を招く=向除去。##過細分解 direkt/a/l/o 由来
  # 2026-07-22 敵対監査: föhn焚风fen の偽の友=phenol族(【PIV】のみで$isSysChem不発火→fen=焚风に漏出)。fen分節のみラテン(fen/ol/o【化】と一致):
  'fen/ol/at/o'=@('fen'); 'fen/ol/ftalein/o'=@('fen'); 'di/met/oksi/fen/ol/o'=@('fen')   # phenolate/phenolphthalein/dimethoxyphenol→fenラテン(苯 一级外)。盐ᴬ/ol/神/置/氧 等 他分節維持。焚风(気象フェーン fen/o=②)の偽の友
  # 2026-07-22 敵対監査: 因ᴾ(因果前置詞pro=〜のせいで)の偽の友=percent族(procento=羅pro centum「百につき」のpro=perで因果でない):
  'pro/cent/o'=@('pro'); 'pro/cent/eg/o'=@('pro'); 'pro/cent/eg/e'=@('pro'); 'pro/cent/eg/ist/o'=@('pro'); 'interez/pro/cent/o'=@('pro'); 'ripar/pro/cent/o'=@('pro')   # パーセント/高利/利率/修理率→proラテン。百(cent)維持=pro/百。因ᴾ/百「原因-百」の誤読是正。句"diskont/a pro/cent/o"内の pro/cent/o トークンも本キーで捕捉
  # 2026-07-22 敵対監査: 女性接尾-in=女 の偽の友(化学/固有名で母体無マッピングのため女に漏出):
  'klement/in/o'=@('in')   # クレメンティン(柑橘・Clément神父由来の固有名§7)→in全体ラテン。klement/女「クレメンの女」の誤読是正。兄弟klementin/uj/o・klementin/arb/oは木ᴷᴸᴱで別途正
  'a/klimat/iz/i'=@('a')   # 2026-07-24 別AI round6: acclimatize(aklimatizi=alklimatigi「気候順化」)のa-はラテン ad-(〜へ)で否定接頭でない→aラテン。无ᴬ/气候/化(non-climate)の誤読是正。a/klimat/iz/i⟦a/气候/化/i⟧。privativeルール(idx0 a→无)より$segLatが先発火で無害化
  'kub/an/o'=@('kub')   # 2026-07-23 WF round5: キューバ人(Kubo=固有名§7)→kub分節ラテン。方ᴷ(cube立方体kub/o)の偽の友=kub/an/o⟦方/员⟧の誤読是正→kub/员ᴬ(兄弟afrik/员ᴬ・meksik/员ᴬ と同型=固有名根latin+-an员)。立方kub/o=方は維持
  'lombard/a'=@('lombard')   # 2026-07-24 別AI round7: ロンバルド/ロンバルディア(Lombardo=固有名§7・語釈"Rilata al lombardoj")→lombard分節ラテン。質屋当ᴸ(lombard/o質入れ=Lombard銀行家由来の換喩)の偽の友=民族形容詞lombard/a⟦当ᴸ⟧の誤読是正。質入れ義lombard/o=当ᴸは維持(同綴多義の-o形は据置=民族と質入れがamb)。afrik/kub型の§7民族latin
  'ar/in/o'=@('ar','in')   # アライン/ベンザイン(aryne=aryl+-yne 芳香族反応中間体)→ar/in両分節ラテン(学術版arin/o whole latin と一致)。群/女「群れ-女」の誤読是正=過細分解 a/r/in/o の産物
  # 2026-07-23 敵対監査(WF round2)で露出した -on(単位/ケトン-one)の偽の友=分数接尾-on(分)に誤落ち(gangli/on/o同型):
  'kod/on/o'=@('on'); 'anti/kod/on/o'=@('on'); 'kontrau^/kod/on/o'=@('on')   # コドン/アンチコドン(遺伝暗号の三つ組=単位・分数でない)→onラテン。码/密码子 母体維持
  'mi/on/o'=@('on'); 'nefr/on/o'=@('on'); 'neu^r/on/o'=@('on')   # ミオン(筋機能単位)/ネフロン(腎単位)/ニューロン(神経細胞)=希語-on単位接尾→onラテン。肌/肾ᴺ/神经ᴺᵁ̆ 母体維持(分数-onでない)
  'alk/an/on/o'=@('on'); 'but/an/on/o'=@('on'); 'cikl/o/heks/an/on/o'=@('on')   # ケトン-one(alkanone/butanone/cyclohexanone)→onラテン。分「分数」の誤読是正。alk/丁/己 母体維持
  # 2026-07-23 敵対監査(WF round2)で露出した tal(距骨talus)の叶状体thallus誤適用(第27回続2 talの取りこぼし):
  'tal/plant/oj'=@('tal')   # Talofitoj=叶状体植物Thallophyta→talラテン(距骨talus=距 でない)。植 母体維持。両版に存在=$segLatは両版適用ゆえ両版是正。tal/o=距(距骨【解】)は維持
  # 2026-07-23 敵対監査(WF round2)で露出した pro(因果前置詞pro=因)の偽の友=percentと同型のper- loanword:
  'pro/mil/o'=@('pro')   # パーミル‰(promilo=羅pro mille「千につき」のpro=per)→proラテン。千(mil)維持=pro/千。因ᴾ/千「原因-千」の誤読是正(pro/cent/o percent族と同型・第27回続3)
  # 2026-07-23 敵対監査(WF round2): tuj化学モノテルペン(Thuja侧柏由来)の-an/-on接尾ラテン化(下のtuj→侧柏ルールと併用):
  'tuj/an/o'=@('an'); 'tuj/on/o'=@('on')   # thujane(-ane)/thujone(-one ketone)→接尾ラテン。tuj→侧柏(下のルール)と併せ 侧柏/an・侧柏/on。员ᴬ/分 の誤読是正(tuj/ol/oはol既にlatin)
  # 2026-07-23 WF round3: 非アルキル語幹テルペン+-ane(化学)の-an=员(member)誤読(tuj/an同型・別AI round3指摘):
  'ment/an/o'=@('an'); 'pin/an/o'=@('an')   # menthane(メンタンC10H20)/pinane(ピナン)=単環モノテルペン→anラテン。薄荷/松 母体維持。员ᴬ「メンバー」の誤読是正(alkyl語幹but/an=丁/an・et/an=乙/anはalkyl隣接で既にan latin=正)
}

foreach($pair in $pairs){
  $dict=Join-Path $srcDir $pair[0]; $outp=Join-Path $dir $pair[1]
  if(-not (Test-Path $dict)){ Write-Host ("skip(無): "+$pair[0]); continue }
  $lines = Get-Content $dict -Encoding UTF8
  $out = New-Object System.Collections.Generic.List[string]
  $tot=0;$inj=0;$segTot=0;$segMap=0;$hsepN=0;$privN=0
  foreach($line in $lines){
    $tot++
    $ci=$line.IndexOf(':'); if($ci -lt 1){ $out.Add($line); continue }
    $head=$line.Substring(0,$ci); $rest=$line.Substring($ci)
    if($head.Contains('##')){ $out.Add($line); continue }   # ##重複語等のマーカー見出しは注入せず原本のまま(重複語は正規見出しで割当済・diff=0)
    $words=$head -split ' '; $anyMapped=$false
    # 化学塩/酸 判定(行レベル): ①語釈に Sal[oj](Salo de/aŭ・Saloj de)・酸塩・酸盐 ②見出しに別語 acid/o(酸形 benzo/at/a acid/o) ③任意分節が酸根(中位は bor除外)。該当行の -at/-it→盐ᴬ/盐ᴵ。受動分詞-at(被)は非化学行で維持(am/at⟦爱/被⟧)
    $chemSaltLine = ($rest -match 'Sal[oj]+ ') -or ($rest -match '酸塩') -or ($rest -match '酸盐') -or ($rest -match 'Metal[a]?\s*deriva') -or ($rest -match 'Metal[a]?\s*kombina')   # Metalderivaĵo/Metalkombinaĵo de X = 金属誘導体/化合物=塩(sakar/at・etanol/at 等。Salo を含まない塩語釈)。2026-07-17: 分綴 "Metala kombinaĵo/derivaĵo"(空白入り)も捕捉=alk/an/ol/at(alkanolate=金属アルコキシド)の -at→被 誤描画を盐ᴬ に是正
    $isSysChem = ($rest -match '【化】|hidrokarbon|[Aa]lkan|[Aa]lkil|[Aa]lken|alkohol|[Aa]ldehid|Ketono|keton|Saturita|Nesaturita|brulebl|brulem|monoterpen|monosakar|[Mm]olekul|polimer|estero|glikol|propandiol|etandiol|hidroksil|morfin|[Hh]eroin|Radiko|radikal|Radikal|C\s?\d|CH\s?\d|H-CHO|アルコール|アルカン|アルキル|メタン|プロパン|ブタン|オクタン|グリコール') -or ($head -match 'bi/fen/il/o$') -or ($head -match '^(di/met/oksi/fen/ol/o|diazo/met/an/o|met/an/bakteri/oj)$') -or ($head -match 'okt/an/nombr') -or ($head -match '^poli/et/en/')   # 2026-07-23 WF round4: エス語釈のみ(【化】/カタカナ無)の系統化学2語を追加=okt/an/nombr/o(オクタン価・八度→辛)・poli/et/en/o(ポリエチレン・小→乙)。   # 系統化学(IUPAC)行=天干/-il基/-anラテン のゲート。2026-07-23 WF round2追加: di/met/oksi/fen/ol/o(グアヤコール)/diazo/met/an/o/met/an/bakteri/oj を化学強制→di二/met甲/fen苯latin(神/置 god/place誤描画是正)。2026-07-22 追加: 学習者版 bi/fen/il/o(ビフェニル・語釈"Vd feno"に【化】タグ無)/poli/klor/bi/fen/il/o(PCB) を化学強制=fen苯latin/il基 発火(焚风föhn/具device誤描画是正・第27回続)(アルキル語幹の非化学義 met置/et小/okt八・器具-il具・数列dek十 との弁別)。化学式/カタカナ/PIV化学語も捕捉。2026-07-17
    foreach($ww in $words){
      if($ww -match '^acid/(o|a|oj|aj)$'){ $chemSaltLine=$true }
      $sg=@($ww -split '/'); $midHit=$false; for($k=1;$k -lt $sg.Count;$k++){ if($chemMid -contains $sg[$k]){ $midHit=$true } }
      if((($sg -contains 'at') -or ($sg -contains 'it')) -and (($chemAcid -contains $sg[0]) -or $midHit)){ $chemSaltLine=$true }
    }
    $kwords = foreach($w in $words){
      if(($w -cmatch '^[A-ZĈĜĤĴŜŬ]') -and ($w -notmatch '^[A-ZĈĜĤĴŜŬ]-')){ $w; continue }   # 大文字始=固有名→一律未対応(latin)。Mal/i/o⟦反⟧・Liber/i/o⟦自由⟧・Kolomb⟦鸽⟧等の誤付与を防止(§7。2026-06-20)。※例外: 単一大文字+ハイフン(T-c^el/U-form/X-radi/H-bomb 等=型/略号接頭で固有名でない)はガードせず下のハイフン分解へ→T-胞/U-形/X-射(接頭字ラテン維持・内容形態素を漢字化。§3。2026-06-21)
      $segs=@($w -split '/'); $nseg=$segs.Count
# 化学アルコール -ol は【分節レベル】でラテン化(下の `$s -eq 'ol'` 分岐)。語全体ラテンを廃し偽分解尊重=他分節(ment薄荷/metan沼气/retin网膜/glik糖/mono单/tri三/poli多 等)を活かす(2026-06-22)。比較ol=比は単独語(nseg=1)のみ。di/ol→二・tetra/ol→四 は homonym sep で数詞化
      $firstContent=''; for($j=1;$j -lt $nseg;$j++){ if($segs[$j] -notmatch $endingRe){ $firstContent=$segs[$j]; break } }
      $privOk = ($firstContent -ne '') -and (-not ($sufSet -contains $firstContent))   # 直後が実語根(接尾辞でない)時のみ privative 発火
      $parts=New-Object System.Collections.Generic.List[string]; $mergeNext=$false; $prevMapped=$false; $medSeen=$false
      for($idx=0;$idx -lt $nseg;$idx++){
        $s=$segs[$idx]
        if($medStem.ContainsKey($s)){ $medSeen=$true }   # 医学-itis: 体部位語幹を前方で検出(後続の it を炎へ)
        $fagEat=$false; if($s -eq 'fag'){ for($jf=$idx+1;$jf -lt $nseg;$jf++){ if($segs[$jf] -eq 'o'){continue}; if($segs[$jf] -eq 'cit'){$fagEat=$true}; break }; if(-not $fagEat){ for($jf=$idx-1;$jf -ge 0;$jf--){ if($segs[$jf] -eq 'o'){continue}; if('makro','bakteri','antrop' -contains $segs[$jf]){$fagEat=$true}; break } } }   # -fag-(-phage 喰): 後続の非o分節=cit(fagocit食細胞) または 前方の非o分節=makro/bakteri/antrop(大食/細菌/人食)→食。ブナFagus(山毛榉=disp 树)と弁別: 単独fag/o·fag/ar·fag/ac·fag/o/frukt·sang/o/fag(銅葉ブナ栽培種)·ŝajn/fag(Notofago南方ブナ)は前後該当なし→树維持。希φάγος vs Fagus の同綴別語(2026-06-28)
        if($dropLinkO -and $s -eq 'o' -and $idx -gt 0 -and ($idx+1 -lt $nseg) -and $prevMapped -and (DispHas $segs[$idx+1])){ $mergeNext=$true; continue }   # 連結母o省略(現在 $dropLinkO=$false で無効=連結oを保持)
        $tok=$null; $thisMapped=$false
        if($s.Contains('-')){ $sub=$s -split '-'; $rp=@(); $anySub=$false; foreach($sp in $sub){ if($sp -eq ''){continue}; if($hsep.ContainsKey($w) -and $hsep[$w].ContainsKey($sp)){ $rp+=$hsep[$w][$sp]; $anySub=$true } elseif(($sp -eq 'al' -or $sp -eq 'ol') -and ($head -match '^-(al|ol)/$') -and ($rest -match 'Sufikso')){ $rp+=$sp } elseif(($sp -match '^(n|sek|ter|tert|izo|neo)$') -and $isSysChem -and ($sub | Where-Object { $alkylStem.ContainsKey(($_ -replace '^[0-9,]+-','')) -or $_ -match '^(met|et|prop|but|pent|heks|hept|okt|non|dek)(an|en|in|ol|il)' })){ $rp+=$sp } elseif($alkylStem.ContainsKey($sp) -and $isSysChem){ $rp+=$alkylStem[$sp]; $anySub=$true } elseif(DispHas $sp){ $rp+=(DispGet $sp); $anySub=$true } elseif($sp -match $endingRe){ $rp+=$sp } else { $rp+=$sp } }; $tok=($rp -join '-'); $thisMapped=$anySub }   # 2026-07-23 WF round4: ハイフン先頭にアルキル語幹が埋没した系統化学名(1-but/2-prop/1,2-et)を天干化。$isSysChemゲート内のみ=1-培/員(butter/member)誤読を1-丁/an へ是正。tri/di等の数量接頭はdisp(三)維持で無影響   # ハイフン複合は形態素分解(ĉi-jar→此-年・alfa-partikl→alfa-粒等。ĉi=此, jar=年)。下位分節もhomonym sep適用(- は / と同じ形態素境界。-gram/接尾辞定義→图等。既存はot/o-rin..のみで無影響)
        elseif($chemSaltLine -and ($s -eq 'at' -or $s -eq 'it') -and $idx -gt 0){ $tok=$(if($s -eq 'at'){$saltAt}else{$saltIt}); $thisMapped=$true }   # 化学塩/酸 -at→盐ᴬ・-it→盐ᴵ(行レベル判定 $chemSaltLine)。酸根は下の hsep(krom/titan/bor=金/金/矿)/disp(acet=醋・fer=铁等)で。受動分詞-at(被)は非化学行で維持
        elseif(($s -eq 'it') -and $idx -gt 0 -and ($medSeen -or $medItWord.ContainsKey($w))){ $tok=$medIt; $thisMapped=$true }   # 医学-it-(-itis 炎症)→炎ᵀ: 前方に体部位/医学語幹($medStem)がある時、または語単位override($medItWord=mitr/it/o等)。受動分詞-it(動詞語幹・far/it=做/受、mitr/it/a=ミトラ授与/受 等)は非該当で 受 維持。化学塩-it(盐)は上で先取
        elseif(($s -eq 'ol') -and $nseg -gt 1){ $tok='ol' }   # 化学アルコール -ol(多分節)=ラテン保持(opaque)。比較ol=比(disp)は単独語のみ。他分節は通常どおり漢字化(偽分解尊重・2026-06-22)
        elseif(($s -eq 'tio') -and $nseg -gt 1){ $tok='tio' }   # チオ(thio=硫黄)結合形(多分節)→ラテン保持。相関詞tio=那o(disp)は単独語(nseg=1)のみ。-ol同型の根治ルール。過細分解(izotio→izo/tio・tio/fosf/at→tio/fosfat等)でsegLat個別キーが外れる脆弱性を解消=上の$segLat tio群を包摂(2026-06-25)
        elseif(($s -eq 'in') -and $chemInWord.ContainsKey($w)){ $tok='in' }   # 化学-ine(kaze/in・te/foli/in)=ラテン保持。女性接尾-in→女 の誤友回避。他分節(凝/茶/叶)は活かす(偽分解尊重・2026-06-22)
        elseif(($s -eq 'in') -and $idx -gt 0 -and ($rest -match '【化】|【薬】|alkaloid|toksin|glukozid|protein|pigment|substanc|hormon|enzim|nukleobaz|antibiot|penicil')){ $tok='in' }   # 2026-07-17: 【薬】(医薬品)/antibiot/penicil を追加=penicil/in(ペニシリン=菌ᴾᴺ/女 誤描画)の -in→ラテン保持。抗生物質・医薬品の-ine は化学接尾で女性接尾でない   # 化学-ine(語釈駆動・systematic): 化学タグ【化】/アルカロイド/毒素/配糖体 を語釈に持つ -in→ラテン。女性接尾-in→女 の誤友回避。上流の化学-ine一括脱分解(strikn木ˢᴺ/in・akonit/in・efedr木ᴱᶠ/in・koni毒参/in・botul菌ᴮᵀ/in 等)に systematic 対応(語単位$chemInWordの増殖を解消)。-om→瘤と同型。母体(木/辣/菌/毒参等)は活かし -in分節のみlatin。女性-in(patr/in母・reg^/in后)は化学マーカー無で 女 維持(2026-06-27)
        elseif(($s -eq 'et') -and $idx -eq 0 -and $nseg -ge 2 -and ($segs[1] -eq 'oksi' -or ($segs[1] -eq 'in' -and $isSysChem))){ $tok='乙'; $thisMapped=$true }   # 化学エトキシ et/oksi(ethoxy=エチル基+酸素)→乙: 甲乙丙アルキル系列(metil甲/etil乙/propil丙)に合流。指小辞-et=小(dom/et小屋等)はidx0かつsegs[1]=oksiでないため不発火。「et+oksi(酸素)」は化学のみ=【化】タグ不要(metoksil等タグ無し参照行も捕捉)。両者漢字(latin化せず)で[F]監査非該当(2026-06-29)。2026-07-23 WF round3追加: et/in/o(アセチレンHC≡CH【化】)=et→乙(小「小さい」の誤読是正・in次分節は【化】でlatin=乙/in)。$isSysChemゲートで指小辞et/in(非化学)は不発火
        elseif(($s -eq 'met') -and $idx -eq 0 -and $nseg -ge 2 -and $segs[1] -eq 'oksi'){ $tok='甲'; $thisMapped=$true }   # 化学メトキシ met/oksi(methoxy)·met/oksi/l(methoxyl)→甲: metil甲と同系列。動詞met=置(meti置く)はsegs[1]=oksiでないため不発火。「met+oksi」は化学のみ=【化】不要(metoksilは語釈「=metoksio」でタグ無)。両者漢字で[F]監査非該当(2026-06-29)
        elseif(($s -eq 'end') -and $idx -eq 0 -and $nseg -ge 2 -and $segs[1] -eq 'osmoz'){ $tok='内'; $thisMapped=$true }   # endo-osmosis: end/osmoz(内方浸透endosmosis)→内/渗。上流がendo→end+osmozと過細分解した結果、endが-end接尾(须=義務・end/i)に化けるのを是正。endo=内(endo/kard内/心膜等)と整合。義務-end接尾(idx>0・leg/end等)は内向き接頭でなく须維持。両者漢字で[F]監査非該当(2026-06-29)
        elseif(($s -eq 'meso') -and $idx -eq 0){ $tok='中'; $thisMapped=$true }   # meso-(希mesos=中): 解剖meso/o(腹膜ひだ peritonea refaldo)·meso/enter/o(腸間膜)→中。Esperanto固有のmez=中(中央)と同源で統一。3字mes=祭(ミサ)とは別綴(meso=4字)につき誤友なし。2026-06-29 WSL同期で mesoentero→meso/enter 露出
        elseif(($s -eq 'mes') -and $idx -eq 0 -and $nseg -ge 2 -and $segs[1] -eq 'enter'){ $tok='中'; $thisMapped=$true }   # mesentero(腸間膜): mes=meso-(中)≠祭(ミサ)。上流の過細分解(mesentero→mes/enter)でmesがmes/o=祭(ミサ)に化けるのを是正→中/肠。宗教義 mes/o祭·mes/libr祭/书·mes/ofer祭/献 は segs[1]≠enterで祭維持。同源mez=中と整合。両者漢字で[F]非該当(2026-06-29)
        elseif(($s -eq 'nau^t') -and $idx -gt 0){ $tok='航'; $thisMapped=$true }   # -naut(航海者): astr/o/nau^t宇宙飛行士・aer/o/nau^t気球乗り・kosm/o/nau^t → 航(aviad航/navig航/nau^tik航 series)。標準nau^t/o(楽=9音程・naŭ由来)はidx0で不発火→latin維持。宇航員(astronaut)と一致(2026-06-29 WSL偽分解同期)
        elseif(($s -eq 'hipo') -and $idx -eq 0 -and (($segs -contains 'drom') -or ($segs -contains 'kas^tan') -or ($segs -contains 'kastan') -or ($segs -contains 'potam') -or ($segs -contains 'grif'))){ $tok='马'; $thisMapped=$true }   # hippo-(馬): hipo/drom競馬場・hipo/potam河馬・hipo/kas^tanマロニエ・hipo/grifヒッポグリフ → 马(ĉeval=马)。接頭hypo-(下/亜)=hipo/tez仮説・hipo/derm皮下 等は馬語幹(drom/potam/kas^tan/kastan/grif)を含まずidx0で不発火→亚(disp)維持(2026-06-29)
        elseif(($s -eq 'himen') -and $idx -eq 0 -and (($segs -contains 'pter') -or ($segs -contains 'micet'))){ $tok='膜'; $thisMapped=$true }   # himen/o/pter(膜翅類Hymenoptera): himen=膜(hymen=membrane)→膜(membran=膜)。標準himen/o(処女膜hymen)はpter無で处女膜(disp)維持。膜/翅=膜翅と一致(2026-06-29)
        elseif($s -eq 'kastan'){ $tok='栗'; $thisMapped=$true }   # PIV変種hipo/kastan(s^無し綴り Hippocastanum)=栗。学習版kas^tan(=栗 disp)と別綴のため明示(2026-06-29)
        elseif(($s -eq 'cer') -and ($segs -contains 'rin')){ $tok='角'; $thisMapped=$true }   # rin/o/cer(犀Rhinoceros=鼻角): cer=角(keras=horn)。rin(=鼻)文脈限定でcerebr/cert/cerv等の同綴誤友回避。鼻/角=サイ(2026-06-29)
        elseif(($s -eq 'ne') -and ($idx -eq 0) -and ($segs -contains 'ornit')){ $tok='新'; $thisMapped=$true }   # ne/ornit(Neornithes新鳥類=neo-新)→新: ne=neo-(新)。否定接頭ne=不/无(ne/ad不/行·ne/ag不/办·ne/agrabl不/快 等)はornit非隣接ゆえ不発火=不維持。ne/ornit(新/鸟)のみ。gnath/ornit系分類名の分解パスで露出(2026-07-18)
        elseif(($s -eq 'an') -and ($idx -gt 0) -and ($segs -contains 'pter') -and ($segs -contains 'odont')){ $tok=$privDisp; $thisMapped=$true }   # Pteranodon(pter/an/odont=無歯翼竜)→无ᴬ: 中位an-=privative(希an-無)。ptero翼+an無+odon歯=翅/无/odont。会員接尾-an=员・an/odont无/齿(idx0 privativeで既に无)とは別=pter+odont文脈限定で誤爆なし(2026-07-18)
        elseif(($s -eq 'ort') -and ($idx -eq 0) -and ($segs -contains 'gnat')){ $tok='直'; $thisMapped=$true }   # ort/o/gnat(orthognathous直顎=ortho-直/straight)→直: ort=直(orto-の直ᴼ[straight]と整合。orto/genez直ᴼ等)。右角ort=直角(基本形)はgnat非隣接ゆえ不発火=直角維持。gnat非割当→直/gnat。前突顎prognat(pro/gnat=前/gnat)と対義(2026-07-18)
        elseif(($s -eq 'rink') -and (($segs -contains 'ornit') -or ($segs -contains 'cefal'))){ $tok='嘴'; $thisMapped=$true }   # rink=嘴(希rhynchos=snout/beak くちばし): ornit/o/rink(カモノハシOrnithorhynchus=鳥嘴)·rink/o/cefal(Rhynchocephalia喙頭目=嘴/头)。分節rinkは全てrhyncho=嘴(drink/trinkは別分節)。ornit/cefal文脈で発火。2026-07-18 正本がrinkocefal→rink/o/cefal過細分解→rinkがornit限定ルール外でlatin残存し[F]drift(ornit/o/rink=嘴 と不整合)→cefalも許可で是正(2026-06-29/2026-07-18)
        elseif(($s -eq 'oni') -and $idx -gt 0 -and ($rest -match 'onio|Katjono|Kvarvalent|【化】')){ $tok='oni' }   # 化学-onium(陽イオン・語釈駆動): fosf/oni磷·hidr/oni水·sulf/oni硫·oksi/oni氧 の -oni-(オニウムイオン)→ラテン保持。代名詞oni=人(impersonal「人々」)はidx0で不発火=人維持。上流の化学過細分解(onio参照)に systematic 対応。母体(磷/水等)は活かし oni分節のみlatin(2026-06-29)
        elseif(($s -eq 'al') -and $idx -gt 0 -and ($rest -match 'ldehid|【化】')){ $tok='al' }   # 化学アルデヒド-al(語釈Aldehido/【化】)=ラテン保持。前置詞al=向 の誤友回避。母体(氯/沼气/桂/网膜等)は活かす。醛は一级外につきラテン。2026-06-28 retin/al(レチナール=網膜の【化】分子)が al→向 に化けたため【化】タグも追加(翼al/o・誘al/logはidx0で不発火・helic/al翼は【化】無で不発火=hsepへ)
        elseif(($s -eq 'om') -and $idx -gt 0 -and ($rest -match 'Tumor|腫|瘤|Neoplasm')){ $tok='瘤'; $thisMapped=$true }   # 医学-oma(腫瘍)→瘤: gloss駆動(angi/om血管腫・fibr/om線維腫・ost/om骨腫)。オーム単位 om/o(kilo/om・mega/om)はTumor語釈なしでlatin維持=誤爆なし。veruk瘤(疣)とR1同字歓迎。-itis=炎ᵀ と並行の透明医学接尾辞(2026-06-27)
        elseif(($s -eq 'sial') -and ($nseg -ge 3) -and ($rest -match 'saliv')){ $tok='唾'; $thisMapped=$true }   # 唾液sial(希sialon)→唾: 複合語sial/o/gen唾液生成·sial/ore唾液過多(nseg≥3かつ語釈saliv)。標準sial/o(nseg=2)は1見出し2義[【地質】硅铝=SiAl大陸地殻層 主義 / 【医】Salivo「en kunmetaĵoj=複合語で」]の主義=硅铝を維持。唾液義は語釈どおり複合語のみ。希sialon vs 地質SiAl の同綴別語(2026-06-28)
        elseif(($s -eq 'citr') -and ($rest -match '【化】')){ $tok='柑'; $thisMapped=$true }   # 柑橘citr(citric/citrate/citral=柑橘由来化学)→柑: citr/at柑/盐ᴬ(クエン酸塩)·citr/al柑/al(シトラール)。チターcitr/o(琴=【楽】古代弦楽器)·citr/ist琴/家 は【化】無で琴維持。柑橘 vs 弦楽器 の同綴別語(2026-06-28)
        elseif(($s -eq 'tuj') -and (($rest -match '【植】') -or ($w -eq 'tuj/an/o' -or $w -eq 'tuj/ol/o' -or $w -eq 'tuj/on/o'))){ $tok='侧柏'; $thisMapped=$true }   # 侧柏tuj(Thuja属クロベ・黒檜)→侧柏: 植物tuj/o(【植】)。超高頻度副詞tuj=即(すぐ・直ちに)は【植】無で即維持。2026-07-23 WF round2で残課題を解消: 化学tuj/an/ol/on(モノテルペン thujane/thujol/thujone=Thuja侧柏由来・中国化学名 侧柏酮/侧柏醇)を語単位で侧柏に(即「すぐに」の誤読是正)。-an/-on接尾は上の$segLatでラテン化(侧柏/an・侧柏/on)。Thuja vs すぐ の同綴別語(2026-06-28)
        elseif(($s -eq 'uri') -and ($idx -gt 0)){ $tok='尿'; $thisMapped=$true }   # -uria(尿症・希-ouria)→尿: 非初頭uri=尿(albumin/uri白蛋白/尿·an/uri无/尿=無尿·gluk/uri糖/尿·azot/uri氮/尿)。鳥uri/o(Uria属ウミガラス=鸟ᵁᴿ)は単独idx0で鸟維持。希uria vs 鳥Uria の同綴別語。systematic(2026-06-28)
        elseif(($s -eq 'lip') -and ((($idx -eq 0) -and ($nseg -ge 3) -and ($segs[1] -eq 'o' -or $segs[1] -eq 'om' -or $segs[1] -eq 'oid')) -or (($idx+1 -lt $nseg) -and ($segs[$idx+1] -eq 'az')))){ $tok='脂'; $thisMapped=$true }   # 脂肪lip(希lipos結合形)→脂: lip/o/X(連結o+科学形態素=lipolysis脂/解·lipoprotein脂/蛋白)·lip/om(lipoma脂/瘤)·lip/oid(脂样)。2026-07-22 追加: lip/az(lipase脂肪分解酵素=脂)・fosfo/lip/az(phospholipase)=次分節azで発火(idx不問)=唇/az誤描画是正(第27回続2)。脂肪系列gras脂/lipid脂ᴸᴾと統一(bare脂=veruk瘤型の直接注入)。唇lip(lip/o唇·lip/son唇音·lip/har口ひげ·lip/dent唇歯=連結o無しの直接native複合)はnseg<3 or segs[1]≠o/om/oid/次≠azで唇維持。希lipos vs 唇lip の同綴別語(2026-06-28)
        elseif(($s -eq 'fag') -and $fagEat){ $tok='吞'; $thisMapped=$true }   # -fag-=-phage(喰う/噬)→吞: 結合形faĝ(fag^=吞=ファージ・bakteriofaĝo)と同一ギリシャ語根φάγοςにつき統一。bakteriofago(fag)=bakteriofaĝo(fag^)は辞書上の同義語→共に菌/吞で整合。吞噬細胞=phagocyte の標準中国語と一致(fag/o/cit→吞/胞)。glut吞(嚥下)系列に合流(rare字を作らず既存hubへ=本ゴール方針)。makro/fag宏/吞(大食細胞)·antrop/o/fag人/吞(食人)。R1同字歓迎。ブナfagは下のdispで树
        elseif($alkylStem.ContainsKey($s) -and $idx -eq 0 -and ($rest -match 'montranta \S*karbonan c\^enon')){ $tok=$alkylStem[$s]; $thisMapped=$true }   # 2026-07-23 WF round4: 化学接頭辞headword(but/·pent/·okt/·et/·met/=「montranta N-karbonan c^enon」の炭素鎖接頭定義)→天干(丁戊辛乙甲)。培(butter)/悔(regret)/八度(octave)/小(small)/置(place)の誤読を、実化合物(but/an/ol=丁)と一致させる。gloss限定=meto置く(動詞・語釈非該当)は不発火
        elseif($alkylStem.ContainsKey($s) -and $isSysChem -and ($idx+1 -lt $nseg) -and (($alkylSuf -contains $segs[$idx+1]) -or ($segs[$idx+1] -eq 'oksi'))){ $tok=$alkylStem[$s]; $thisMapped=$true }   # アルキル語幹→天干(甲乙丙丁戊己庚辛壬癸): met/il甲/基·et/il乙/基·okt/an辛·di/met/oksi二/甲/氧。化学接尾/oksi隣接+化学タグの二重ゲート。met置/et小/okt八 の非化学義は不発火(2026-07-17)
        elseif(($s -eq 'il') -and $idx -gt 0 -and $isSysChem -and ($alkylStem.ContainsKey($segs[$idx-1]) -or (@('fen','alk','naft','nitrozo','sulfon','sulfur','pirid','okzal','en','salik') -contains $segs[$idx-1]))){ $tok='基'; $thisMapped=$true }   # 化学-yl(基)→基: 化学タグ+前分節がアルキル/アリル語幹の二重ゲート。器具-il→具(paf/il銃·but/il作業具Laborilo·dek/il数列·hak/et/il包丁=化学タグ無)は不発火=具維持(2026-07-17 器具/数列誤爆是正)。2026-07-23 WF round3で化学ラジカル-yl前分節追加: nitrozo/sulfon/sulfur/pirid/okzal(ニトロシル/スルホニル/スルフリル/ピリジル/オキサリル=La grupo/radiko【化】)+en(2-prop/en/il プロペニル)。いずれも【化】ゲート+実データで器具-ilo(agit/kirl/kolekt/kondens等)は非該当を確認=具維持
        elseif(($s -eq 'an') -and $idx -gt 0 -and ($idx -lt ($nseg-1)) -and ($alkylStem.ContainsKey(($segs[$idx-1] -replace '^[^-]*-','')) -or (@('alk','fen','naft') -contains ($segs[$idx-1] -replace '^[^-]*-','')))){ $tok='an' }   # 化学-an(-ane 烷=一级外)→ラテン: 前分節がアルキル/アリル語幹時のみ。会員-an→员(krist/an)は前分節が非アルキルで不発火=员維持・対格終端-anは下(2026-07-17)。2026-07-23 WF round4: 前分節の番号接頭(1-但/1,2-但)を剥がしてアルキル判定=1-but/an の an→员 誤読を latin へ是正
        elseif(($s -eq 'di') -and $isSysChem -and ($idx+1 -lt $nseg) -and (($idx -eq 0 -and ($alkylStem.ContainsKey($segs[$idx+1]) -or $segs[$idx+1] -eq 'oksi')) -or ($idx -gt 0 -and $segs[$idx+1] -eq 'ol'))){ $tok='二'; $thisMapped=$true }   # 化学倍数接頭di-→二(dimetoksi二/甲/氧)。神(di/o)はアルキル隣接+化学タグで弁別(2026-07-17)。2026-07-23 WF round4: 語中di-も次分節=ol(diol二価アルコール)+化学タグ時に二化=et/an/di/ol の di→神(god)誤読を二へ是正(glycol系)
        elseif((($s -eq 'fen') -or ($s -eq 'alk')) -and $isSysChem){ $tok=$s }   # 芳香/総称の一级外語幹→ラテン: fen(苯 一级外)·alk(烷総称)。föhn焚风fen②·elk驼鹿alk の誤友回避(2026-07-17)
        elseif(($s -eq 'dur') -and ($rest -match '銀貨|ドゥーロ')){ $tok='币'; $thisMapped=$true }   # dur/o同綴の語釈scoped是正: PEJVO銀貨ドゥーロ(【史】)→币。硬度dur=硬(base・PIV L46963)は語釈非該当で不発火。原本更新で同綴dur/o(硬度)追加によりsep→amb降格し銀貨が硬に退行→gloss限定で復元(2026-07-17)
        elseif(($s -eq 'kat') -and $idx -eq 0 -and ($rest -match 'latero.*triangul|C\^eorta latero')){ $tok='股'; $thisMapped=$true }   # kat/et同綴の語釈scoped是正: cathetus(kateto=直角三角形の直角辺・希káthetos垂線)→股(中国数学 勾股=直角边)。子猫kat/et(猫/小・語釈「小猫」)は非該当で不発火=猫維持(2026-07-18)
        elseif(($s -eq 'torn') -and ($rest -match 'rotacianta')){ $tok='旋'; $thisMapped=$true }   # torn/ad同綴の語釈scoped是正: tornado(【気】Fortega rotacianta=激しい回転暴風=竜巻)→旋(旋回)。旋盤torn/ad(车/行・語釈「旋盤加工」)は非該当で不発火=车維持(2026-07-18)
        elseif(($s -eq 'kub') -and $idx -eq 0 -and ($rest -match 'キューバ')){ $tok='kub' }   # 2026-07-24 別AI round6: kub/a同一綴二義の語釈scoped是正。キューバの/キューバ人(固有名Kubo§7)→kubラテン。立方体kub/a(立方体の・立方の・立方根/方程式等)は語釈非該当で不発火=方ᴷ維持。兄弟kub/an/o(=員ᴬ)と一致。方ᴷ(cube)偽の友を除去
        elseif(($s -eq 'te') -and ($rest -match 'Toksig\^o per teo')){ $tok='茶'; $thisMapped=$true }   # te/ism/o同一見出し二義の語釈scoped是正(2026-07-23 WF round3): 茶中毒(【医】Toksiĝo per teo)→茶(茶による中毒)。有神論(【哲】theismo=te神ᵀ+ism主义)は語釈非該当で不発火=神ᵀ維持。dur/kat/torn型の定義gated。te/o=茶(tea)と整合
        elseif(($s -eq 'rutin') -and ($rest -match 'Heterozido')){ $tok='rutin' }   # 2026-07-23 WF round4: rutin同綴二義の語釈scoped是正。黄酮配糖体ルチン(【化】【薬】Heterozido C27H30O16=ビタミンP成分)→ラテン。日課/慣例rutin=惯(語釈非該当)は不発火=惯維持。同綴別義(routine vs 化合物)
        elseif(($s -eq 'ur') -and $idx -eq 0 -and ($rest -match 'urata acid')){ $tok='ur' }   # 2026-07-23 WF round4: ur同綴の語釈scoped是正。尿酸塩urate(過細分解 u/r/at→原牛ur+盐)のur=尿酸系→ラテン。原牛ur/o(オーロックス=野生原牛Bos primigenius)は語釈非該当で不発火=原牛維持。原牛/盐(aurochs-salt)の誤読除去
        elseif(($s -eq 'po') -and $idx -eq 0 -and ($rest -match 'Poa el|poacoj|Poace')){ $tok='草'; $thisMapped=$true }   # 2026-07-23 WF round4: po同綴二義の語釈scoped是正。イネ科Poaceae/Poa属(【植】)→草(禾本科=草の系列と整合)。配分前置詞po=每(each/per・語釈非該当)は不発火=每維持。每/科(per-family)の誤読を草/科へ。同綴別語(preposition vs 植物属)
        elseif(($s -eq 'temp' -or $s -eq 'er') -and ($rest -match 'テンペラ')){ $tok=$s }   # 2026-07-24 別AI round8: temp/er/o・temp/er/e(テンペラ=絵画技法・temperare「混ぜる」由来)の时/粒(time/grain)は偽の友→temp/er分節ラテン(学術版whole temper/oが既にlatin=版間整合)。一瞬/瞬時temp/er/o(語釈テンペラ無=时/粒は時=time由来で解釈可)は据置。[F]$known追加(temp/er)
        elseif(($s -eq 'lizin') -and ($rest -match 'estiganta hemo lizon')){ $tok='解'; $thisMapped=$true }   # 2026-07-24 別AI round7: hemo/lizin/o(溶血素hemolysin)の-lizin=溶解lysis→解。lizin/o=赖(アミノ酸リジンlysine)の偽の友を語釈scoped是正。学術版はwhole分節hemo/lizin(lizin→赖に漏出)・学習者版hemo/liz/inは既に血ᴴ/解ᴸで正=版間整合。lysine(赖)vs lysis(解)の同綴別義。lizin/o単独(リジン)は語釈"Aminacido"で非該当=赖維持
        elseif($hsep.ContainsKey($w) -and $hsep[$w].ContainsKey($s)){ $tok=$hsep[$w][$s]; $thisMapped=$true; $hsepN++ }
        elseif($segLat.ContainsKey($w) -and ($segLat[$w] -contains $s)){ $tok=$s }   # 固有名分節(Gram染色)=ラテン保持・非mapped(§7)。disp(克)に落ちる前に捕捉

        elseif($idx -eq 0 -and ($s -eq 'a' -or $s -eq 'an') -and $privOk){ $tok=$privDisp; $thisMapped=$true; $privN++ }
        elseif($s -eq 'en'){ if($idx -eq 0){ $tok=$enDisp; $thisMapped=$true } else { $tok=$s } }
        elseif($s -eq 'ajn'){ if($idx -eq 0){ $tok=(DispGet 'ajn'); $thisMapped=$true } else { $tok=$s } }   # 相関詞/語根 ajn(任ᴬ=任意・どんな〜でも): 語頭/独立語(idx0)のみ注入。中位・終端の ajn は形容詞複数対格語尾-ajn(bon/ajn等)の可能性ゆえLatin維持(実データでは終端-ajnの見出しは0件だが将来安全のため位置ガード)。大文字Ajn(人名)は§7大文字ガードで既にLatin。enと同型(2026-07-13)
        elseif(($s -eq 'on' -or $s -eq 'an') -and $idx -gt 0 -and $idx -eq ($nseg-1)){ $tok=$s }   # 終端 -on/-an = 対格(名詞-o/形容詞-a + 対格-n)=文法語尾→ラテン保持(kat/on⟦猫/on⟧)。分数-on-(分)/会員-an-(员)は中位で維持(2026-06-20)
        elseif($s -match $endingRe){ $tok=$s }
        elseif($idx -gt 0 -and $comb.ContainsKey($s)){ $tok=$comb[$s]; $thisMapped=$true }   # 結合形(idx>0): fon→声 等。背景fon=底(idx0)は次の disp で
        elseif(DispHas $s){ $tok=(DispGet $s); $thisMapped=$true }
        else { $tok=$s }
        if($thisMapped){ $anyMapped=$true }
        if($s -notmatch $endingRe){ $segTot++; if($thisMapped){$segMap++} }
        if($mergeNext -and $parts.Count -gt 0){ $parts[$parts.Count-1]=$parts[$parts.Count-1]+$tok; $mergeNext=$false } else { $parts.Add($tok) }
        $prevMapped=$thisMapped
      }
      ($parts -join '/')
    }
    if($anyMapped){ $inj++; $out.Add("$head⟦$($kwords -join ' ')⟧$rest") } else { $out.Add($line) }
  }
  [System.IO.File]::WriteAllLines($outp,$out,(New-Object System.Text.UTF8Encoding($true)))
  $diff=0; for($i=0;$i -lt $lines.Count;$i++){ $st=$out[$i] -replace '⟦[^⟧]*⟧',''; if($st -ne $lines[$i]){ $diff++ } }
  Write-Host ("[{0}] 総行{1}/注入{2}/被覆{3}/{4}={5:P1}/homonym(sep){6}/priv{7}/原本diff {8} {9}" -f $pair[1],$tot,$inj,$segMap,$segTot,($segMap/[double]$segTot),$hsepN,$privN,$diff,$(if($diff -eq 0){'PASS'}else{'要調査!'}))
}
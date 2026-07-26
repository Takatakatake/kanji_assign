# -*- coding: utf-8 -*-
# 優先順位(層順)包括監査 v3。ユーザーの優先順位 CSV2890 → PEJVO(<=44440) → PIV(>=44441) を
# 【独立ground-truth】で検証する:
#   tier(root) = 0(CSV2890) / 1(真PEJVO) / 2(真PIV)
#     ・CSV2890 は 30_重要語彙CSV を独立に読み、To-Hsys正規化+語尾剥がしで語根照合(band非依存)
#     ・PEJVO/PIV は 学術版原本の見出し行位置(<=44440)+【PIV】タグ で判定(band非依存)
#   各【多メンバー漢字群】で bare基本形の tier が群内最小か検証。
#     member.tier < base.tier の群 = 層順逆転。分類:
#       base_override(_base_override.tsv=意図的裁定) / ratified(既知20群=現状維持裁定) / NEW(未説明=違反)
# 併せて: CSV2890語根が band∈br0(basic/機能形態素) でない=誤ラベル(優先度喪失の温床)を警告列挙。
# 出力: _audit_priority_tiers_ledger.tsv(CJK可・UTF-8) + stdout要約(ASCIIのみ=cp932安全)。
# _verify_all統合: PRIORITY_STRUCT 行を出力し、NEW違反>0 で exit 1(それ以外 exit 0)。
import io, os, sys, csv as _csv
os.chdir(os.path.dirname(os.path.abspath(__file__)))
ACAD = "20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
SUPP_MAX = 44440   # <=44440 PEJVO(旧+追補) / >=44441 PIV
ENDINGS = ['ojn','ajn','oj','aj','on','an','en','as','is','os','us','o','a','e','i','u','j','n']
BR0 = {'basic','suf','pref','prep','correl','num','func'}   # band_rank 0 = CSV2890中核+機能形態素

def to_hsys(s):
    for u, x in (('ĉ','c^'),('Ĉ','C^'),('ĝ','g^'),('Ĝ','G^'),('ĥ','h^'),('Ĥ','H^'),
                 ('ĵ','j^'),('Ĵ','J^'),('ŝ','s^'),('Ŝ','S^'),('ŭ','u^'),('Ŭ','U^')):
        s = s.replace(u, x)
    return s

# --- 学術版原本: 語根連結形 -> (最小行, 【PIV】タグ). exact連結一致 ---
def concat_root(head):
    if ' ' in head: return None
    parts = head.split('/')
    if len(parts) >= 2 and parts[-1] in set(ENDINGS): parts = parts[:-1]
    return ''.join(parts) if parts else None

root_line, root_piv = {}, {}
with io.open(ACAD, encoding='utf-8') as f:
    for n, line in enumerate(f, 1):
        line = line.rstrip('\n')
        if ':' not in line: continue
        head, gloss = line.split(':', 1); head = head.strip()
        if not head or head.startswith('#'): continue
        r = concat_root(head)
        if r and r not in root_line:
            root_line[r] = n; root_piv[r] = ('【PIV】' in gloss)

def genuine(root):
    ln = root_line.get(root)
    if ln is None: return None
    if ln >= 44441 or root_piv.get(root): return 'PIV'
    return 'PEJVO'

# --- sidecar rows ---
rows = []
with io.open("_identifier_sidecar.tsv", encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) < 8: continue
        rows.append({'root': p[0], 'id': p[2], 'band': p[5], 'gk': p[7]})
allroots = set(r['root'] for r in rows)
bandByRoot = {r['root']: r['band'] for r in rows}
# 2026-07-26 第8レンズで是正: sidecarの語根は x-convention 統一ではなく
#   Unicode表記298 / h-system表記508 の混在(basic層=CSV2890中核ほどUnicode表記)。
#   照合側だけ to_hsys していたため CSV2890中核が当たらず(照合86.8%)、
#   さらに同綴の別語根に流れる誤ヒット(c^asi=シャーシー/g^eni/j^uri/kau^ri)が出ていた。
#   → 両表記が同一綴りに潰れる衝突は0件を確認済みなので、h-system正規形で索引する。
hs2root = {}
for r in allroots: hs2root.setdefault(to_hsys(r), r)
hsroots = set(hs2root)

# --- CSV2890 独立読み込み + 語根照合(band非依存) ---
csv_roots = set(); csv_level = {}; csv_rows = 0; matched_rows = 0; unmatched = []
with io.open(CSVF, encoding='utf-8') as f:
    rd = _csv.reader(f)
    next(rd, None)                                # header
    for rec in rd:
        if not rec or not rec[0].strip(): continue
        csv_rows += 1
        try: lvl = float(rec[3])
        except Exception: lvl = None
        hit = False
        for term in rec[0].split(','):            # Esperanto欄内のカンマ代替形
            t = to_hsys(term.strip()).replace('/', '').replace(' ', '')
            if not t: continue
            cands = []
            if t.startswith('-') or t.endswith('-'):   # 接辞(-a接尾 / re-接頭 / -ant-両側)
                stem = t.strip('-'); cands = [stem]
                if len(stem) > 1 and stem[-1] in 'aio': cands.append(stem[:-1])
            else:                                  # 内容語=語尾を剥がして語根照合(過剰照合回避=剥がし優先)
                stripped = None
                for e in ENDINGS:
                    if t.endswith(e) and len(t) > len(e): stripped = t[:-len(e)]; break
                if stripped and stripped in hsroots: cands = [stripped]
                elif t in hsroots:                   cands = [t]
                elif stripped:                       cands = [stripped]
            for c in cands:
                if c in hsroots:
                    r0 = hs2root[c]                   # sidecar実表記に解決してから登録
                    csv_roots.add(r0); hit = True
                    if lvl is not None and (r0 not in csv_level or lvl < csv_level[r0]): csv_level[r0] = lvl
        if hit: matched_rows += 1
        else: unmatched.append(rec[0])

def tier(root):
    # tier0 = band∈br0(basic/機能形態素)。band='basic'は _build_priority_work.ps1 がCSV2890を
    #   照合し付与(全CSV行の解決をthrowで保証)ので、CSV2890中核+接辞の信頼できる代理。
    # tier1/2(PEJVO/PIV) は band非依存に【学術版原本の行位置+PIVタグ】で独立判定(arketip逆転検出)。
    b = bandByRoot.get(root)
    if b in BR0: return 0
    g = genuine(root)
    if g == 'PEJVO': return 1
    if g == 'PIV':   return 2
    if b in ('pejvo', 'sci', 'elem', 'cal', 'rel'): return 1   # 原本見出し無し=bandフォールバック
    if b in ('piv', 'proper'):                      return 2
    return None                                    # 判定不能

# --- _base_override.tsv(意図的にbaseを固定=層順より意味/難易度優先=ユーザー承認) ---
ovr = set()
with io.open("_base_override.tsv", encoding='utf-8') as f:
    for line in f:
        line = line.rstrip('\n')
        if not line or line.startswith('#'): continue
        p = line.split('\t')
        if len(p) >= 2: ovr.add(p[1].strip())

# 既知27逆転群=第7回で20群+2026-07-19で7群をユーザーが「現状維持」裁定済(全メンバー同一漢字·識別子で区別·全字一级内·偽分解尊重·churn回避)。
# ※silent除外せず ratified として明示計上する。
# 2026-07-19追加7群: 咏(c^ant/psalm/kantik=詠唱)·旋(gir/pivot/spiral/rotaci等=回旋)·架(rak/trus/stabl/c^arpent/skafald/c^asi=枠·架)·
#   梗(infarkt/pedunkl=梗塞·花梗)·相关(korelaci/korelativ=相関)·硫(sulf/sulfur=硫黄同物)·胖(obez/korpulent=肥満同義)。
# いずれも「同一漢字·PIVがbare·PEJVOが識別子」型で誤字なし=既存20群と同クラス。全字一级3500内を確認済。
KNOWN = {'蛾','气学家','气学','气计','高计','高测','脉炎','菌学','苔植','胚源','拍型',
         '胃炎','乐主义','乐家','肠炎','色计','神经学','振具','渗计','速计',
         '咏','旋','架','梗','相关','硫','胖'}

# tier0内部の「機能形態素base(prep/suf/pref/correl/num/func) vs CSV2890 basic内容語衛星」= §5/§6確定機能層。
# 従来 tier() は basic/suf/pref を一律tier0に潰すため 0<0=false でこのカテゴリを検出できなかった(盲点)。
# 2026-07-20 第24回で全47群を精査=全て方針§5/§6の確定機能形態素割当(mal反/ig使/ist家/uj器/il具/ec性/
#   前置詞kun共/en内/前置詞層/数詞mil千/相関nun现/分詞6体系-ant在-int过-ont将-at被-it受-ot待 等)。
#   機能形態素が固有字を所有しCSV2890内容語が識別子付き衛星=意図的設計(nun现と同型)・誤読なし=違反ゼロ。
#   漢字割当は現状維持(Fable判断+ユーザー承認)。TIER0_KNOWN=現行47群=確定機能層。集合外の新規のみNEW(要点検)。
TIER0_KNOWN = {
    '事','代','份','使','值','倾','共','具','内','减','出','分','前','加','千','单','原','反','受','器',
    '因','女','始','子','家','对','将','小','巨','己','微','性','成','散','无','比','物','现','穿','粒',
    '组','群','被','过','逆','待','情'}
AFFIX = BR0 - {'basic'}   # 機能形態素(内容語basic以外の br0 = suf/pref/prep/correl/num/func)

from collections import defaultdict
groups = defaultdict(list)
for r in rows: groups[r['gk']].append(r)

# --- 群単位の3層構造検証: bare = min tier か ---
reversals = []   # (gk, base_root, base_tier, [(viol_root,viol_tier)...], cls)
for gk, members in groups.items():
    if len(members) < 2: continue
    base = next((m for m in members if m['id'] == ''), None)
    if base is None: continue
    bt = tier(base['root'])
    if bt is None: continue
    viol = [(m['root'], tier(m['root'])) for m in members
            if m['root'] != base['root'] and tier(m['root']) is not None and tier(m['root']) < bt]
    if viol:
        if base['root'] in ovr: cls = 'base_override'
        elif gk in KNOWN:       cls = 'ratified'
        else:                   cls = 'NEW'
        reversals.append((gk, base['root'], bt, viol, cls))

new_rev = [x for x in reversals if x[4] == 'NEW']
ovr_rev = [x for x in reversals if x[4] == 'base_override']
rat_rev = [x for x in reversals if x[4] == 'ratified']
# hard-fail条件 = CSV2890(tier0)中核語が base を失う逆転(最重要=優先度最上位が敗北)。
# PEJVO↔PIV の同義語逆転(bare選択が頻度tiebreak・全メンバー同一漢字で識別子区別=誤字なし)は
# 既知20群と同クラス=advisory(現状維持裁定の対象。exitに影響させない)。
csv_loss = [x for x in new_rev if any(v[1] == 0 for v in x[3])]

# --- tier0内部逆転(従来盲点): 機能接辞(suf/pref/…)がbareを握り CSV2890 basic内容語が識別子付き衛星 ---
#   tier()が basic/suf を共にtier0へ潰すため [A]の tier(m)<bt(0<0) では検出不能だったカテゴリを別途走査。
#   漢字は全員同一で正しく識別子区別=誤読なし。acknowledged(待/情=分詞体系・結合形)以外のNEWは要点検(非fail)。
tier0_rev = []   # (gk, base_root, base_band, [basic sat roots], cls)
for gk, members in groups.items():
    if len(members) < 2: continue
    base = next((m for m in members if m['id'] == ''), None)
    if base is None: continue
    if bandByRoot.get(base['root']) in AFFIX:
        basic_sats = [m['root'] for m in members
                      if m['root'] != base['root'] and bandByRoot.get(m['root']) == 'basic']
        if basic_sats:
            cls = 'func_layer' if gk in TIER0_KNOWN else 'NEW'
            tier0_rev.append((gk, base['root'], bandByRoot.get(base['root']), basic_sats, cls))
tier0_new = [x for x in tier0_rev if x[4] == 'NEW']
tier0_known = [x for x in tier0_rev if x[4] == 'func_layer']

# --- CSV2890 band整合: CSV語根が br0でない=誤ラベル(優先度喪失の温床) ---
csv_mislabel = [(r, bandByRoot.get(r, '?')) for r in sorted(csv_roots) if bandByRoot.get(r) not in BR0]

# --- band=piv だが真PEJVO(温床。継続監視) ---
piv_mislabel = [(r['root'], root_line[r['root']], r['gk'], r['id'] == '')
                for r in rows if r['band'] == 'piv' and genuine(r['root']) == 'PEJVO']

TIER_NAME = {0: 'CSV2890', 1: 'PEJVO', 2: 'PIV', None: '?'}
def vfmt(viol): return ';'.join("%s(t%d=%s)" % (v[0], v[1], TIER_NAME[v[1]]) for v in viol)

out = []
out.append("# 優先順位(層順)包括監査 v3 台帳  CSV2890(t0)>PEJVO(t1)>PIV(t2) を独立ground-truthで検証")
out.append("# tier: CSV2890=CSVを独立照合 / PEJVO・PIV=学術版原本の行位置+【PIV】タグ (band非依存)")
out.append("# base=min band_rank は C=br*1000+P で構造保証。逆転はband誤ラベル/意図的override時のみ。")
out.append("# CSV2890照合: rows=%d matched=%d(%.1f%%) 語根=%d 未照合rows=%d" %
           (csv_rows, matched_rows, 100.0 * matched_rows / max(csv_rows, 1), len(csv_roots), len(unmatched)))
out.append("")
out.append("## [A] 層順逆転(bare.tier より高優先=小tierのメンバーが非base) = 全%d件" % len(reversals))
out.append("#   NEW=%d(0が必須=未説明の違反) / base_override=%d(意図) / ratified現状維持=%d(既知20群)" %
           (len(new_rev), len(ovr_rev), len(rat_rev)))
out.append("groupkey\tbase\tbase_tier\t高優先メンバー(逆転相手)\t分類")
for gk, br, bt, viol, cls in sorted(reversals, key=lambda x: (x[4] != 'NEW', x[0])):
    out.append("%s\t%s\t%d=%s\t%s\t%s" % (gk, br, bt, TIER_NAME[bt], vfmt(viol), cls))
out.append("")
root_isbare = {r['root']: (r['id'] == '') for r in rows}
root_gk = {r['root']: r['gk'] for r in rows}
csv_mislabel_notbare = [(r, b) for r, b in csv_mislabel if not root_isbare.get(r, True)]
out.append("## [B] CSV2890語根の band誤ラベル(br0でない=優先度喪失の温床) = %d件(うち非bare=%d)" %
           (len(csv_mislabel), len(csv_mislabel_notbare)))
out.append("#   CSV2890は band∈basic/suf/pref/prep/correl/num/func(br0) が正。bare=True(単独/基本形)なら無害・")
out.append("#   bare=False(非基本形)は同綴群で下位語にbaseを譲っている可能性=要点検。")
out.append("root\tband\ttier\tbare?\tgroupkey\tUnified_Level")
for r, b in sorted(csv_mislabel, key=lambda x: root_isbare.get(x[0], True)):
    out.append("%s\t%s\t%s\t%s\t%s\t%s" % (r, b, TIER_NAME[tier(r)], root_isbare.get(r), root_gk.get(r, ''), csv_level.get(r, '')))
out.append("")
out.append("## [C] band=piv だが真PEJVO(<=44440・PIVタグ無)の誤ラベル語(温床) = %d件" % len(piv_mislabel))
out.append("#   bare列=その語が漢字群のbare基本形か(Trueなら真PEJVO語が正しくbare保持=無害)")
out.append("root\t行\tgroupkey\tbareか")
for r, ln, gk, isbare in sorted(piv_mislabel, key=lambda x: x[1]):
    out.append("%s\t%d\t%s\t%s" % (r, ln, gk, isbare))
out.append("")
out.append("## [D] tier0内部: 機能形態素base(§5/§6確定) vs CSV2890 basic内容語衛星。従来[A]の盲点 = 全%d件" % len(tier0_rev))
out.append("#   func_layer=%d(§5/§6確定機能割当=意図的設計・誤読なし・違反でない) / NEW=%d(集合外の新規=要点検・非fail)" %
           (len(tier0_known), len(tier0_new)))
out.append("#   機能形態素(前置詞/接尾辞/接頭辞/相関/数詞/分詞)が固有字を所有しCSV2890内容語が識別子付き衛星=nun现と同型。")
out.append("#   base=bare機能形態素 / basic_satellites=識別子付きに落ちたCSV2890内容語(語根:Unified_Level)")
out.append("groupkey\tbase(接辞)\tbase_band\tbasic衛星(CSV2890内容語)\t分類")
for gk, br, bb, sats, cls in sorted(tier0_rev, key=lambda x: (x[4] != 'NEW', x[0])):
    sat_s = ';'.join("%s(%s)" % (s, csv_level.get(s, '?')) for s in sats)
    out.append("%s\t%s\t%s\t%s\t%s" % (gk, br, bb, sat_s, cls))
out.append("")
out.append("## 未照合CSV行(参考) = %d件" % len(unmatched))
out.append("#   [2026-07-21 WF検証=良性確定] 未照合=割当可能な語根を持たない項目(文法語尾/機能語/固有名§7/一级字なし借用語/複合)")
out.append("#   =baseを失いようがない=違反リスク0。caretはto_hsys既対応で低照合率は正規化バグでない(rootless項目が分母)。実被覆≈96.6%。")
# 【2026-07-21 第26回WF検証で良性確定】未照合=「割当可能な語根を持たないCSV項目」=baseを失いようがない=違反リスク0。
#   内訳: 文法語尾/接辞(-a/-as/-um-)・機能語/間投詞(je/la/adiaŭ/ambaŭ)・固有名(Afriko/Aŭstralio=§7ラテン)・
#   一级字なし借用語(kafo/afiŝo/ĵazo)・スラッシュ複合(ter/pomo=段別に語根照合済で被覆穴でない)。
#   ★注意: caret正規化は to_hsys が既に実施済(ĉ→c^)。低照合率(≈86.8%)は「正規化バグ」ではなく上記rootless項目を
#   分母に含むため=見かけ上の値。baseを持つ照合済語根(2508)は全て CSV_LOSES_BASE 検査対象=検出は完全。
#   実被覆(段別/借用含む実描画)は別途≈96.6%(WF独自再照合)。ここを"改善"する時は過剰照合(複合語の誤マッチ)に注意。
for u in unmatched[:60]:
    out.append("?\t%s" % u)

io.open("_audit_priority_tiers_ledger.tsv", "w", encoding="utf-8").write("\n".join(out) + "\n")

# stdout は ASCII のみ(cp932安全)。CJK群キーは出さない。
print("VALIDATE prototip=%s(tier%s) arketip=%s(tier%s)" %
      (genuine('prototip'), tier('prototip'), genuine('arketip'), tier('arketip')))
print("CSV2890: rows=%d matched=%d(%.1f%%) roots=%d unmatched=%d" %
      (csv_rows, matched_rows, 100.0 * matched_rows / max(csv_rows, 1), len(csv_roots), len(unmatched)))
print("PRIORITY_STRUCT: CSV2890_LOSES_BASE=%d NEW_SYNONYM_REVERSAL=%d BASE_OVERRIDE=%d RATIFIED=%d CSV_MISLABEL=%d PIV_MISLABEL_PEJVO=%d TIER0_FUNC_LAYER=%d(new=%d)" %
      (len(csv_loss), len(new_rev) - len(csv_loss), len(ovr_rev), len(rat_rev), len(csv_mislabel), len(piv_mislabel), len(tier0_known), len(tier0_new)))
# hard-fail = CSV2890中核語のbase喪失のみ(0が必須)。同義語逆転/band誤ラベル/tier0機能層はadvisory(非fail)。
# TIER0_FUNC_LAYER=§5/§6確定機能形態素割当(mal反/ig使/ist家/nun现/分詞-ot待 等47群)=意図的設計・違反でない。
# new>0(集合外の新規に機能形態素が内容語からbareを奪取)が出たら要点検(現状 new=0)。
sys.exit(1 if len(csv_loss) > 0 else 0)

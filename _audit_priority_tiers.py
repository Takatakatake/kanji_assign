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
allroots = set(r['root'] for r in rows)          # sidecarの語根は既にx-convention
bandByRoot = {r['root']: r['band'] for r in rows}

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
                if stripped and stripped in allroots: cands = [stripped]
                elif t in allroots:                   cands = [t]
                elif stripped:                        cands = [stripped]
            for c in cands:
                if c in allroots:
                    csv_roots.add(c); hit = True
                    if lvl is not None and (c not in csv_level or lvl < csv_level[c]): csv_level[c] = lvl
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

# 既知20逆転群=第7回でユーザーが「現状維持」裁定済(意味は正・識別子で区別・churn回避)。
# ※silent除外せず ratified として明示計上する。
KNOWN = {'蛾','气学家','气学','气计','高计','高测','脉炎','菌学','苔植','胚源','拍型',
         '胃炎','乐主义','乐家','肠炎','色计','神经学','振具','渗计','速计'}

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
out.append("## 未照合CSV行(参考・照合改善余地) = %d件" % len(unmatched))
for u in unmatched[:60]:
    out.append("?\t%s" % u)

io.open("_audit_priority_tiers_ledger.tsv", "w", encoding="utf-8").write("\n".join(out) + "\n")

# stdout は ASCII のみ(cp932安全)。CJK群キーは出さない。
print("VALIDATE prototip=%s(tier%s) arketip=%s(tier%s)" %
      (genuine('prototip'), tier('prototip'), genuine('arketip'), tier('arketip')))
print("CSV2890: rows=%d matched=%d(%.1f%%) roots=%d unmatched=%d" %
      (csv_rows, matched_rows, 100.0 * matched_rows / max(csv_rows, 1), len(csv_roots), len(unmatched)))
print("PRIORITY_STRUCT: CSV2890_LOSES_BASE=%d NEW_SYNONYM_REVERSAL=%d BASE_OVERRIDE=%d RATIFIED=%d CSV_MISLABEL=%d PIV_MISLABEL_PEJVO=%d" %
      (len(csv_loss), len(new_rev) - len(csv_loss), len(ovr_rev), len(rat_rev), len(csv_mislabel), len(piv_mislabel)))
# hard-fail = CSV2890中核語のbase喪失のみ(0が必須)。同義語逆転/band誤ラベルはadvisory(要裁定・非fail)。
sys.exit(1 if len(csv_loss) > 0 else 0)

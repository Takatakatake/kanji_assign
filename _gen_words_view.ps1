# 複合語(全注入語)の閲覧用HTML: 学習者版注入辞書から ⟦漢字⟧ 付き見出しを抽出し検索ビューアを生成。
# 出力: words.html(公開正本) + 複合語ビュー_yyyyMMdd.html(日付スナップショット)
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
$inj = "$dir\漢字注入_学習者版_20260620.txt"
$lines = [System.IO.File]::ReadAllLines($inj, [System.Text.Encoding]::UTF8)
$L = [char]0x27E6  # ⟦
$R = [char]0x27E7  # ⟧

function JEsc([string]$s){
  if(-not $s){ return '' }
  return $s.Replace('\','\\').Replace('"','\"').Replace("`t",' ').Replace('<',([char]92+'u003c'))
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.Append('[')
$n = 0
foreach($line in $lines){
  $li = $line.IndexOf($L); if($li -lt 1){ continue }       # ⟦ 無し=未割当はスキップ
  $ri = $line.IndexOf($R, $li); if($ri -lt 0){ continue }
  $head  = $line.Substring(0, $li)
  $kanji = $line.Substring($li+1, $ri-$li-1)
  $rest  = $line.Substring($ri+1)
  if($rest.StartsWith(':')){ $rest = $rest.Substring(1) }
  # レベルマーカー {X}(PEJVO: B=基本/O=公式 等)を抽出
  $lv = ''
  $m = [regex]::Match($rest, '^\{([^}]*)\}')
  if($m.Success){ $lv = $m.Groups[1].Value; $rest = $rest.Substring($m.Length) }
  # 語義: 内部タグ ## 以降を除去・トリム・長すぎは切詰
  $g = ($rest -replace '##.*$','').Trim()
  if($g.Length -gt 56){ $g = $g.Substring(0,56) }
  if($n -gt 0){ [void]$sb.Append(',') }
  [void]$sb.Append('{"h":"').Append((JEsc $head)).Append('","k":"').Append((JEsc $kanji)).Append('","g":"').Append((JEsc $g)).Append('","lv":"').Append((JEsc $lv)).Append('"}')
  $n++
}
[void]$sb.Append(']')
$json = $sb.ToString()

$tpl = @'
<!doctype html><html lang="ja"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>エスペラント複合語→漢字 割当ビュー(全注入語・学習者版)</title>
<style>
 body{font-family:"Segoe UI","Hiragino Sans","Yu Gothic UI",sans-serif;margin:0;background:#f6f8fa;color:#1f2328}
 header{position:sticky;top:0;background:#24292f;color:#fff;padding:10px 16px;z-index:10}
 header h1{margin:0;font-size:16px;font-weight:600}
 header a{color:#79c0ff;font-size:12px;text-decoration:none}header a:hover{text-decoration:underline}
 .stats{font-size:12px;color:#c9d1d9;margin-top:4px}.stats b{color:#fff}
 .controls{position:sticky;top:52px;background:#fff;border-bottom:1px solid #d0d7de;padding:8px 16px;display:flex;gap:8px;align-items:center;flex-wrap:wrap;z-index:9}
 input,select,button{font-size:13px;padding:5px 8px;border:1px solid #d0d7de;border-radius:6px;background:#fff}
 input#q{width:280px}#info{font-size:12px;color:#57606a;margin-left:auto}
 table{border-collapse:collapse;width:100%;background:#fff}
 th,td{padding:5px 12px;border-bottom:1px solid #eaeef2;text-align:left;font-size:13px;vertical-align:top}
 th{position:sticky;top:97px;background:#f6f8fa;cursor:pointer;user-select:none;font-size:12px;color:#57606a}th:hover{color:#0969da}
 td.h{font-family:Consolas,monospace;color:#0550ae;white-space:nowrap}
 td.k{font-size:18px;font-family:"KaiTi","SimSun",serif}
 td.k sup,td.k .ids{color:#cf222e;font-weight:700}
 td.lv{color:#57606a;font-variant-numeric:tabular-nums;white-space:nowrap}
 td.g{color:#3b434b;font-size:12px;max-width:520px}
 .lvb{display:inline-block;background:#eef2f6;color:#57606a;border-radius:10px;padding:1px 7px;font-size:11px}
</style></head><body>
<header><h1>エスペラント複合語 → 漢字 割当ビュー(全注入語・学習者版)</h1>
<div class="stats" id="hstats"></div>
<div style="margin-top:4px"><a href="kanji.html">▸ 語根ビュー(root→漢字)へ</a></div></header>
<div class="controls">
 <input id="q" placeholder="検索 (見出し・漢字・語義)"/>
 <select id="lf"><option value="">全レベル</option></select>
 <span id="info"></span>
</div>
<table><thead><tr>
 <th data-k="h">見出し(分解形)</th><th data-k="k">漢字割当</th><th data-k="lv">レベル</th><th data-k="g">語義</th>
</tr></thead><tbody id="tb"></tbody></table>
<script>
const D=DATAJSON;
let sk='h',sd=1,q='',lf='';
const tb=document.getElementById('tb'),info=document.getElementById('info');
const lvs={};D.forEach(d=>{if(d.lv)lvs[d.lv]=(lvs[d.lv]||0)+1});
const lfsel=document.getElementById('lf');
Object.keys(lvs).sort().forEach(k=>{const o=document.createElement('option');o.value=k;o.textContent='{'+k+'} ('+lvs[k]+')';lfsel.appendChild(o)});
document.getElementById('hstats').innerHTML='総複合語 <b>'+D.length.toLocaleString()+'</b> 件(⟦⟧付き=漢字割当あり・学習者版注入辞書より)';
function esc(s){return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;')}
function render(){
 let r=D.filter(d=>(!q||d.h.toLowerCase().includes(q)||d.k.includes(q)||(d.g&&d.g.includes(q)))&&(!lf||d.lv===lf));
 r.sort((a,b)=>{let x=a[sk]||'',y=b[sk]||'';return sd*String(x).localeCompare(String(y),'ja')});
 info.textContent=r.length.toLocaleString()+' 件';
 tb.innerHTML=r.slice(0,3000).map(d=>'<tr><td class=h>'+esc(d.h)+'</td><td class=k>'+esc(d.k)+'</td><td class=lv>'+(d.lv?'<span class=lvb>'+esc(d.lv)+'</span>':'')+'</td><td class=g>'+esc(d.g)+'</td></tr>').join('');
 if(r.length>3000)info.textContent+=' (上位3000表示・検索で絞り込み)';
}
document.getElementById('q').oninput=e=>{q=e.target.value.toLowerCase().trim();render()};
lfsel.onchange=e=>{lf=e.target.value;render()};
document.querySelectorAll('th').forEach(th=>th.onclick=()=>{let k=th.dataset.k;if(sk===k)sd=-sd;else{sk=k;sd=1}render()});
render();
</script></body></html>
'@

$html = $tpl.Replace('DATAJSON',$json)
$utf8bom = New-Object System.Text.UTF8Encoding($true)
$outMain  = "$dir\words.html"
$outDated = "$dir\複合語ビュー_$(Get-Date -Format 'yyyyMMdd').html"
[System.IO.File]::WriteAllText($outMain,  $html, $utf8bom)
[System.IO.File]::WriteAllText($outDated, $html, $utf8bom)
Write-Host "生成: $outMain + $outDated ($n 複合語)"

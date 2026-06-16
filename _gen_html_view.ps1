# 割当結果の閲覧用HTML(検索/ソート/バンドフィルタ/同字グループ/画数/語義)を生成
$ErrorActionPreference = 'Stop'
$dir = "d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613"
$dict = "$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){
  $s = $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^'
  return $s
}
$endingRe = '^(o|a|e|i|u|oj|aj|on|an|ojn|ajn|en|as|is|os|us|u|j|n)$'
# 画数マップ(一级∪二级)
$stroke = @{}
foreach($f in @("通用规范汉字表_一级3500字_画数.tsv","通用规范汉字表_二级3000字_画数.tsv")){
  Get-Content "$dir\$f" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
    $p = $_ -split "`t"; if($p.Count -ge 4){ $c=$p[1].Trim(); if($c){ $stroke[$c]=[int]$p[3].Trim() } }
  }
}
# === 辞書スキャン: word2root(正しい語根対応) + repGloss(代表語義: 日本語>非参照>content少>名詞語尾) ===
$csvPath = "$dir\30_重要語彙CSV_日中対照_2890語\2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
$endStrip = '(oj|aj|ojn|ajn|on|an|en|as|is|os|us|o|a|e|i|u|j|n)$'
$jpRe='[぀-ヿ一-龥]'
$endPri=@{ 'o'=0;'i'=1;'a'=2;'e'=3 }
$word2root=@{}; $repGloss=@{}; $repBest=@{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){ continue }
  $head=$line.Substring(0,$ci); $gl=($line.Substring($ci+1) -replace '^\{[^}]*\}','' -replace '##.*$','').Trim()
  $body=($gl -replace '^(【[^】]*】|《[^》]*》)+','').Trim()
  $isRef = if($body -match '^(=|Mll |&gt;|→|>>)'){1}else{0}
  $jpS = if($body -match $jpRe){0}else{1}
  foreach($w in ($head -split ' ')){
    $segs=@($w -split '/'); $cn=@($segs | Where-Object { $_ -notmatch $endingRe }).Count
    $last=$segs[-1]; $ep= if($endPri.ContainsKey($last)){$endPri[$last]}else{4}
    $ns=($w -replace '/',''); $fc=($segs | Where-Object { $_ -notmatch $endingRe } | Select-Object -First 1)
    if($ns -and $fc -and -not $word2root.ContainsKey($ns)){ $word2root[$ns]=$fc }
    foreach($s in $segs){
      if($s -match $endingRe -or $s.Length -lt 1){ continue }
      $score = $jpS*100000 + $isRef*10000 + $cn*1000 + $ep*100
      if(-not $repBest.ContainsKey($s) -or $score -lt $repBest[$s]){ $repBest[$s]=$score; $repGloss[$s]=$gl }
    }
  }
}
# === CSV(日中対照)=最も信頼。正しい語根(word2root)+接辞対応でキー(du=二/unu=一/-em-=傾向 等を正しく拾う) ===
$csvJp=@{}
if(Test-Path $csvPath){
  Import-Csv -Path $csvPath -Encoding UTF8 | ForEach-Object {
    $eo=$_.Esperanto.Trim(); if(-not $eo){ return }
    $jp=($_.Japanese_Trans -replace '^\{[^}]*\}','').Trim()
    if($eo -match '^-'){ $a=($eo.Trim('-')); $s=$a -replace $endStrip,''; $root=if($s){$s}else{$a} }
    else{ $eh=ToHsys $eo; $root= if($word2root.ContainsKey($eh)){$word2root[$eh]} elseif($word2root.ContainsKey($eo)){$word2root[$eo]} else { $s=$eo -replace $endStrip,''; if($s){$s}else{$eo} } }
    if($root.Length -ge 1 -and $jp -and -not $csvJp.ContainsKey($root)){ $csvJp[$root]=$jp }
  }
}
# PIVラテン語根の私の日本語訳(信頼度: CSV/PEJVO より下)
$ovr=@{}
if(Test-Path "$dir\_gloss_override.tsv"){ Get-Content "$dir\_gloss_override.tsv" -Encoding UTF8 | ForEach-Object { $p=$_ -split "`t"; if($p.Count -ge 2 -and $p[0]){ $ovr[$p[0].Trim()]=$p[1].Trim() } } }
# band_map から行を構築(語義付き)
$rows = New-Object System.Collections.ArrayList
Get-Content "$dir\_band_map.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
  $p = $_ -split "`t"; if($p.Count -lt 5){ return }
  $root=$p[1].Trim(); $kanji=$p[2].Trim(); $band=$p[3].Trim(); $f=[int]$p[4].Trim()
  if($kanji -eq '未対応' -or -not $kanji){ return }
  $st=0; $ok=$true
  foreach($ch in $kanji.ToCharArray()){ if([int][char]$ch -lt 128){continue}; if($stroke.ContainsKey([string]$ch)){ $st+=$stroke[[string]$ch] } else { $ok=$false } }
  # 語義の信頼度順: CSV(最信頼) > 辞書PEJVO日本語 > 私のPIV訳 > 辞書ラテン(最終)
  $rh=ToHsys $root
  $dictG = if($repGloss.ContainsKey($rh)){$repGloss[$rh]} elseif($repGloss.ContainsKey($root)){$repGloss[$root]} else {''}
  $dctClean = $dictG -replace '【[^】]*】','' -replace '《[^》]*》','' -replace '##.*$','' -replace '\([^)]*\)','' -replace '（[^）]*）',''
  $jpN=([regex]::Matches($dctClean,'[぀-ヿ一-龥]')).Count; $latN=([regex]::Matches($dctClean,'[A-Za-z]')).Count
  $dictHasJp = ($dictG -ne '') -and ($jpN -ge 2) -and ($jpN*3 -ge $latN)   # 日本語が主体の時のみ採用(ラテン定義+断片CJKの誤判定を防ぐ)
  $g=''
  if($csvJp.ContainsKey($root) -and $csvJp[$root]){ $g=$csvJp[$root] }
  elseif($dictHasJp){ $g=$dictG }
  elseif($ovr.ContainsKey($root) -and $ovr[$root]){ $g=$ovr[$root] }
  elseif($dictG){ $g=$dictG }
  $g = ($g -replace '##.*$','').Trim()
  $g = $g -replace '\s*(&gt;&gt;|>>|Vd |><)[^,，;；、。]*',''       # エスペラント相互参照(>>tendenco等)除去
  $g = $g -replace '[,，、]\s*=\s*[^、。,，;；]*$',''                # 末尾の ,=同義語(=dau^re等)除去
  $g = ($g -replace '[,，、；;]+$','').Trim()
  if(-not $g){ $g = ($repGloss[$rh] -replace '##.*$','').Trim() }   # 全部消えたら原文に戻す
  if($g.Length -gt 44){ $cut=$g.Substring(0,44); $m=[regex]::Match($cut,'^.{18,44}?[、；;，,]'); if($m.Success){ $g=$m.Value.TrimEnd([char[]]@('、','；',';','，',',')) } else { $g=$cut } }
  $null=$rows.Add([pscustomobject]@{ r=$root; k=$kanji; b=$band; f=$f; s=$(if($ok){$st}else{0}); g=$g })
}
$json = ($rows | ConvertTo-Json -Compress)
$total = $rows.Count
$tpl = @'
<!doctype html><html lang="ja"><head><meta charset="utf-8">
<title>エスペラント語根→漢字 割当ビュー</title>
<style>
 body{font-family:"Segoe UI","Hiragino Sans","Yu Gothic UI",sans-serif;margin:0;background:#f6f8fa;color:#1f2328}
 header{position:sticky;top:0;background:#24292f;color:#fff;padding:10px 16px;z-index:10}
 header h1{margin:0;font-size:16px;font-weight:600}
 .stats{font-size:12px;color:#c9d1d9;margin-top:4px}.stats b{color:#fff}
 .controls{position:sticky;top:52px;background:#fff;border-bottom:1px solid #d0d7de;padding:8px 16px;display:flex;gap:8px;align-items:center;flex-wrap:wrap;z-index:9}
 input,select,button{font-size:13px;padding:5px 8px;border:1px solid #d0d7de;border-radius:6px;background:#fff}
 input#q{width:240px}#info{font-size:12px;color:#57606a;margin-left:auto}
 table{border-collapse:collapse;width:100%;background:#fff}
 th,td{padding:5px 12px;border-bottom:1px solid #eaeef2;text-align:left;font-size:13px;vertical-align:top}
 th{position:sticky;top:97px;background:#f6f8fa;cursor:pointer;user-select:none;font-size:12px;color:#57606a}th:hover{color:#0969da}
 td.r{font-family:Consolas,monospace;color:#0550ae;white-space:nowrap}
 td.k{font-size:20px;font-family:"KaiTi","SimSun",serif;white-space:nowrap}
 td.n{text-align:right;color:#57606a;font-variant-numeric:tabular-nums}
 td.g{color:#3b434b;font-size:12px;max-width:520px}
 .badge{color:#fff;padding:1px 7px;border-radius:10px;font-size:11px}
 #groups{padding:8px 16px;display:none}
 .grp{display:inline-block;background:#fff;border:1px solid #d0d7de;border-radius:6px;padding:4px 8px;margin:3px;font-size:12px}
 .grp .gk{font-size:18px;font-family:"KaiTi",serif;margin-right:6px;color:#cf222e}.grp .gc{color:#57606a}
</style></head><body>
<header><h1>エスペラント語根 → 漢字 割当ビュー(語義付き)</h1><div class="stats" id="hstats"></div></header>
<div class="controls">
 <input id="q" placeholder="検索 (語根・漢字・語義)"/>
 <select id="bf"><option value="">全バンド</option><option>basic</option><option>pejvo</option><option>piv</option><option>func</option><option>suf</option><option>pref</option><option>correl</option><option>prep</option><option>sci</option><option>elem</option><option>num</option><option>cal</option><option>proper</option></select>
 <button id="gbtn">同字グループ表示/隠す</button><span id="info"></span>
</div>
<div id="groups"></div>
<table><thead><tr>
 <th data-k="r">語根 root</th><th data-k="k">漢字</th><th data-k="b">バンド</th><th data-k="f">F</th><th data-k="s">画数</th><th data-k="g">語義(辞書代表訳)</th>
</tr></thead><tbody id="tb"></tbody></table>
<script>
const D=DATAJSON;
const C={basic:'#1a7f37',pejvo:'#0969da',piv:'#8250df',func:'#9a6700',suf:'#9a6700',pref:'#9a6700',correl:'#9a6700',prep:'#9a6700',sci:'#bf3989',cal:'#bf3989',elem:'#bf3989',num:'#bf3989',proper:'#57606a',rel:'#57606a'};
let sk='f',sd=-1,q='',bf='';
const tb=document.getElementById('tb'),info=document.getElementById('info');
const cnt={};D.forEach(d=>cnt[d.b]=(cnt[d.b]||0)+1);
document.getElementById('hstats').innerHTML='総割当 <b>'+D.length+'</b> / basic <b>'+(cnt.basic||0)+'</b> · pejvo <b>'+(cnt.pejvo||0)+'</b> · piv <b>'+(cnt.piv||0)+'</b> · 機能語接辞他 <b>'+(D.length-(cnt.basic||0)-(cnt.pejvo||0)-(cnt.piv||0))+'</b> · 全字 二级以内';
function esc(s){return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;')}
function render(){
 let r=D.filter(d=>(!q||d.r.toLowerCase().includes(q)||d.k.includes(q)||(d.g&&d.g.includes(q)))&&(!bf||d.b===bf));
 r.sort((a,b)=>{let x=a[sk],y=b[sk];if(typeof x==='string')return sd*String(x).localeCompare(String(y));return sd*((x||0)-(y||0));});
 info.textContent=r.length+' 件';
 tb.innerHTML=r.slice(0,4000).map(d=>'<tr><td class=r>'+d.r+'</td><td class=k>'+d.k+'</td><td><span class=badge style="background:'+(C[d.b]||'#888')+'">'+d.b+'</span></td><td class=n>'+d.f+'</td><td class=n>'+(d.s||'')+'</td><td class=g>'+esc(d.g)+'</td></tr>').join('');
 if(r.length>4000)info.textContent+=' (上位4000表示)';
}
document.getElementById('q').oninput=e=>{q=e.target.value.toLowerCase().trim();render()};
document.getElementById('bf').onchange=e=>{bf=e.target.value;render()};
document.querySelectorAll('th').forEach(th=>th.onclick=()=>{let k=th.dataset.k;if(sk===k)sd=-sd;else{sk=k;sd=(k==='f'||k==='s')?-1:1}render()});
const gd=document.getElementById('groups');
document.getElementById('gbtn').onclick=()=>{
 if(gd.style.display==='block'){gd.style.display='none';return}
 const g={};D.forEach(d=>{(g[d.k]=g[d.k]||[]).push(d.r)});
 const sh=Object.entries(g).filter(e=>e[1].length>=2).sort((a,b)=>b[1].length-a[1].length);
 gd.innerHTML='<p style="font-size:12px;color:#57606a">同字共有グループ '+sh.length+'件(共有数の多い順)。R1=漢字を重複させて字種を最小化。</p>'+sh.map(e=>'<span class=grp><span class=gk>'+e[0]+'</span><span class=gc>×'+e[1].length+'</span> '+e[1].join(', ')+'</span>').join('');
 gd.style.display='block';
};
render();
</script></body></html>
'@
$html = $tpl.Replace('DATAJSON',$json)
$outp = "$dir\漢字割当ビュー_20260615.html"
[System.IO.File]::WriteAllText($outp, $html, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "生成: $outp ($total 行・語義付き)"
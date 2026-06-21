# 最終本番注入: 学習者版・学術版の両方に disp(漢字+§9識別子)を注入。homonym(sep見出し)・privative=无ᴬ・en・連結母o省略。各ファイルで原本diff=0検証。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$srcDir="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026"
$pairs=@(
  @('世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt','漢字注入_学習者版_20260620.txt'),
  @('世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt','漢字注入_学術版_20260620.txt') )
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'Ĉ','C^' -replace 'ĝ','g^' -replace 'Ĝ','G^' -replace 'ĥ','h^' -replace 'Ĥ','H^' -replace 'ĵ','j^' -replace 'Ĵ','J^' -replace 'ŝ','s^' -replace 'Ŝ','S^' -replace 'ŭ','u^' -replace 'Ŭ','U^' }
# --- sidecar disp(主義) ---
$disp=@{}; Import-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -Delimiter "`t" | ForEach-Object { $disp[(ToHsys $_.root)]=$_.disp }
# --- homonym台帳(sep見出しのみ適用。amb=同一文字列は不採用) ---
$hsep=@{}; $comb=@{}
Get-Content "$dir\_homonym_disp.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
  $p=$_ -split "`t"; if($p.Count -lt 5){return}; $seg=$p[0];$type=$p[1];$disc=$p[2];$d=$p[4]
  if($type -eq 'sep'){ foreach($hw in ($disc -split ',')){ $hw=$hw.Trim(); if(-not $hw){continue}; if(-not $hsep.ContainsKey($hw)){$hsep[$hw]=@{}}; $hsep[$hw][$seg]=$d } }
  elseif($type -eq 'comb'){ $comb[$seg]=$d }   # 結合形(ギリシャ): idx>0 の完全一致分節で適用(fon→声)
}
$chemAcid = @('acet','fosf','karbon','nitr','sulf','silik','molibden','klor','brom','jod','krom','bor','arsen','fluor','volfram','vanad','selen','telur','antimon','tartr','sakar')  # 酸根(先頭分節判定用)。化学塩 X/at・X/it→酸根漢字+盐。tartr(酒石酸)/sakar(糖酸)は語釈に塩語が無い吐酒石(吐酒石のみ)等を取りこぼすため radical で確実化(2026-06-20)
$chemMid  = @('acet','fosf','karbon','nitr','sulf','silik','molibden','klor','brom','jod','krom','arsen','fluor','volfram','vanad','selen','telur','antimon','tartr','sakar')  # 中位分節判定用=bor を除外(bor=钻ドリル動詞 と同綴。verm/bor/it=虫食い受動 の誤爆防止。boron塩 bor/at は先頭分節+homonymで処理)
$saltAt = "盐$([char]0x1D2C)"   # 化学塩 -at(-ate)=盐ᴬ(sal=盐 と一意区別。AddSegId相当)
$saltIt = "盐$([char]0x1D35)"   # -it(-ite 亜…酸塩)=盐ᴵ
$privDisp = "无$([char]0x1D2C)"   # privative a-/an- = 无ᴬ
$enDisp = if($disp.ContainsKey('en')){$disp['en']}else{'内'}
$endingRe = '^(o|a|e|i|u|oj|aj|ojn|ajn|as|is|os|us|u|j|n)$'   # on/an/en は除外し、-on=分/-an=员/en=内 を位置で裁定
$sufSet = @('ad','aj^','an','ar','ec','eg','ej','em','end','er','estr','et','id','ig','ig^','il','in','ind','ing','ism','ist','obl','on','op','uj','ul','um')  # privativeガード: 直後が派生接尾辞のみなら privative 不発火(an/ar/o=员群 等)
$dropLinkO = $false   # 連結母o省略: 【無効】=連結oも保持し1:1構造を残す(美/性/o/酪/o)。省略は後処理に委ねる(ユーザー2026-06-20確定)。$true で再有効化可
$forceUnt = @()   # krom/o→金・titan/o→金・bor/o→矿 は homonym。krom/at→金ᴷᴹ/盐ᴬ・bor/at→矿ᴮ/盐ᴬ は化学塩へ(2026-06-20。元素由来の未対応は無し)
# segment単位ラテン: 語中の固有名morphemeのみ未対応(latin)保持。語全体ではなくその分節だけ漢字化しない。Japana落松·T-胞·E-屋(語/ハイフン単位)の分節版。非mapped=被覆を水増ししない。§7
$segLat = @{ 'gram/negativ/a'=@('gram'); 'gram/pozitiv/a'=@('gram') }   # 人名Gram(グラム染色 Hans Christian Gram由来)=固有名→gram分節のみラテン(否/正は維持)。重量gram(克)·記録gram(图)とは別。2026-06-21

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
    $chemSaltLine = ($rest -match 'Sal[oj]+ ') -or ($rest -match '酸塩') -or ($rest -match '酸盐') -or ($rest -match 'Metalderiva') -or ($rest -match 'Metalkombina')   # Metalderivaĵo/Metalkombinaĵo de X = 金属誘導体/化合物=塩(sakar/at・etanol/at 等。Salo を含まない塩語釈)
    foreach($ww in $words){
      if($ww -match '^acid/(o|a|oj|aj)$'){ $chemSaltLine=$true }
      $sg=@($ww -split '/'); $midHit=$false; for($k=1;$k -lt $sg.Count;$k++){ if($chemMid -contains $sg[$k]){ $midHit=$true } }
      if((($sg -contains 'at') -or ($sg -contains 'it')) -and (($chemAcid -contains $sg[0]) -or $midHit)){ $chemSaltLine=$true }
    }
    $kwords = foreach($w in $words){
      if($forceUnt -contains $w){ $w; continue }   # 元素名は未対応(latin保持)
      if(($w -cmatch '^[A-ZĈĜĤĴŜŬ]') -and ($w -notmatch '^[A-ZĈĜĤĴŜŬ]-')){ $w; continue }   # 大文字始=固有名→一律未対応(latin)。Mal/i/o⟦反⟧・Liber/i/o⟦自由⟧・Kolomb⟦鸽⟧等の誤付与を防止(§7。2026-06-20)。※例外: 単一大文字+ハイフン(T-c^el/U-form/X-radi/H-bomb 等=型/略号接頭で固有名でない)はガードせず下のハイフン分解へ→T-胞/U-形/X-射(接頭字ラテン維持・内容形態素を漢字化。§3。2026-06-21)
      $segs=@($w -split '/'); $nseg=$segs.Count
      if($nseg -gt 1 -and ($segs -contains 'ol')){ $w; continue }   # 化学アルコール -ol(過細分解##偽分解 etan/ol/di/ol等)→未対応(latin)。比較ol=比は単独語のみ(2026-06-20)
      $firstContent=''; for($j=1;$j -lt $nseg;$j++){ if($segs[$j] -notmatch $endingRe){ $firstContent=$segs[$j]; break } }
      $privOk = ($firstContent -ne '') -and (-not ($sufSet -contains $firstContent))   # 直後が実語根(接尾辞でない)時のみ privative 発火
      $parts=New-Object System.Collections.Generic.List[string]; $mergeNext=$false; $prevMapped=$false
      for($idx=0;$idx -lt $nseg;$idx++){
        $s=$segs[$idx]
        if($dropLinkO -and $s -eq 'o' -and $idx -gt 0 -and ($idx+1 -lt $nseg) -and $prevMapped -and $disp.ContainsKey($segs[$idx+1])){ $mergeNext=$true; continue }   # 連結母o省略(現在 $dropLinkO=$false で無効=連結oを保持)
        $tok=$null; $thisMapped=$false
        if($s.Contains('-')){ $sub=$s -split '-'; $rp=@(); $anySub=$false; foreach($sp in $sub){ if($sp -eq ''){continue}; if($disp.ContainsKey($sp)){ $rp+=$disp[$sp]; $anySub=$true } elseif($sp -match $endingRe){ $rp+=$sp } else { $rp+=$sp } }; $tok=($rp -join '-'); $thisMapped=$anySub }   # ハイフン複合は形態素分解(ĉi-jar→此-年・alfa-partikl→alfa-粒等。ĉi=此, jar=年)
        elseif($chemSaltLine -and ($s -eq 'at' -or $s -eq 'it') -and $idx -gt 0){ $tok=$(if($s -eq 'at'){$saltAt}else{$saltIt}); $thisMapped=$true }   # 化学塩/酸 -at→盐ᴬ・-it→盐ᴵ(行レベル判定 $chemSaltLine)。酸根は下の hsep(krom/titan/bor=金/金/矿)/disp(acet=醋・fer=铁等)で。受動分詞-at(被)は非化学行で維持
        elseif($hsep.ContainsKey($w) -and $hsep[$w].ContainsKey($s)){ $tok=$hsep[$w][$s]; $thisMapped=$true; $hsepN++ }
        elseif($segLat.ContainsKey($w) -and ($segLat[$w] -contains $s)){ $tok=$s }   # 固有名分節(Gram染色)=ラテン保持・非mapped(§7)。disp(克)に落ちる前に捕捉

        elseif($idx -eq 0 -and ($s -eq 'a' -or $s -eq 'an') -and $privOk){ $tok=$privDisp; $thisMapped=$true; $privN++ }
        elseif($s -eq 'en'){ if($idx -eq 0){ $tok=$enDisp; $thisMapped=$true } else { $tok=$s } }
        elseif(($s -eq 'on' -or $s -eq 'an') -and $idx -gt 0 -and $idx -eq ($nseg-1)){ $tok=$s }   # 終端 -on/-an = 対格(名詞-o/形容詞-a + 対格-n)=文法語尾→ラテン保持(kat/on⟦猫/on⟧)。分数-on-(分)/会員-an-(员)は中位で維持(2026-06-20)
        elseif($s -match $endingRe){ $tok=$s }
        elseif($idx -gt 0 -and $comb.ContainsKey($s)){ $tok=$comb[$s]; $thisMapped=$true }   # 結合形(idx>0): fon→声 等。背景fon=底(idx0)は次の disp で
        elseif($disp.ContainsKey($s)){ $tok=$disp[$s]; $thisMapped=$true }
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
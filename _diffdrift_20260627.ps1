$ErrorActionPreference='Stop'
$wsl='\\wsl.localhost\Ubuntu\home\y\エスペラント辞書徹底語根分解_20260619'
$src='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621\20_PEJVO語彙リスト_原本・生成版_2024-2026'
$names=@('世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt','世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt')
foreach($n in $names){
  $w=[System.IO.File]::ReadAllLines((Join-Path $wsl $n))
  $p=[System.IO.File]::ReadAllLines((Join-Path $src $n))
  Write-Host ("==== {0} : WSL={1}行 PROJ={2}行 ====" -f $n.Substring(0,8),$w.Count,$p.Count)
  $cmp=Compare-Object $p $w -SyncWindow 12
  if(-not $cmp){ Write-Host "  差分なし(行内容一致)"; continue }
  foreach($c in $cmp){ $tag= if($c.SideIndicator -eq '=>'){'WSL新'}else{'PROJ旧'}; Write-Host ("  [{0}] {1}" -f $tag,$c.InputObject) }
}

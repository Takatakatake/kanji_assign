param([string]$path)
$ErrorActionPreference = "Stop"
$lines = Get-Content -LiteralPath $path -Encoding UTF8

$prio = @{
  "basic"=0; "suf"=0; "pref"=0; "prep"=0; "correl"=0; "num"=0; "func"=0;
  "pejvo"=1; "sci"=1; "elem"=1; "cal"=1; "rel"=1;
  "piv"=2; "proper"=2
}

$rows = @()
for ($i=1; $i -lt $lines.Count; $i++) {
  $l = $lines[$i]
  if ([string]::IsNullOrWhiteSpace($l)) { continue }
  $f = $l -split "`t"
  $cols = $f | ForEach-Object { ($_ -replace '^"','') -replace '"$','' }
  if ($cols.Count -lt 8) { continue }
  $rows += [pscustomobject]@{
    root=$cols[0]; kanji=$cols[1]; id=$cols[2]; id_super=$cols[3];
    disp=$cols[4]; band=$cols[5]; F=$cols[6]; groupkey=$cols[7]
  }
}

Write-Output "TOTAL_ROWS=$($rows.Count)"
$unknownBands = $rows | Where-Object { -not $prio.ContainsKey($_.band) } | Select-Object -ExpandProperty band -Unique
Write-Output "UNKNOWN_BANDS=[$($unknownBands -join ',')]"

$groups = $rows | Group-Object groupkey
$multi = $groups | Where-Object { $_.Count -ge 2 }
Write-Output "TOTAL_GROUPS=$($groups.Count)"
Write-Output "MULTI_ROOT_GROUPS=$($multi.Count)"

$reversals = @()
foreach ($g in $multi) {
  $members = $g.Group
  $bases = $members | Where-Object { [string]::IsNullOrEmpty($_.id_super) }
  if ($bases.Count -eq 0) { continue }
  foreach ($b in $bases) {
    $bp = $prio[$b.band]
    $betters = $members | Where-Object { -not [string]::IsNullOrEmpty($_.id_super) -and $prio[$_.band] -lt $bp }
    foreach ($bt in $betters) {
      $reversals += [pscustomobject]@{
        groupkey=$g.Name
        base_root=$b.root; base_band=$b.band; base_prio=$bp; base_disp=$b.disp; base_F=$b.F
        better_root=$bt.root; better_band=$bt.band; better_prio=$prio[$bt.band]; better_disp=$bt.disp; better_F=$bt.F
      }
    }
  }
}

Write-Output "REVERSAL_COUNT=$($reversals.Count)"
Write-Output "---REVERSALS---"
foreach ($r in $reversals) {
  Write-Output ("GK={0} | BASE={1}[band={2},p{3},F={9}]disp={4} | BETTER={5}[band={6},p{7},F={10}]disp={8}" -f $r.groupkey,$r.base_root,$r.base_band,$r.base_prio,$r.base_disp,$r.better_root,$r.better_band,$r.better_prio,$r.better_disp,$r.base_F,$r.better_F)
}

$multiBase = @()
foreach ($g in $multi) {
  $bcount = ($g.Group | Where-Object { [string]::IsNullOrEmpty($_.id_super) }).Count
  if ($bcount -gt 1) { $multiBase += [pscustomobject]@{ gk=$g.Name; n=$bcount } }
}
Write-Output "---MULTI_BASE_GROUPS---"
Write-Output "MULTI_BASE_COUNT=$($multiBase.Count)"
foreach ($m in $multiBase) { Write-Output ("GK={0} bases={1}" -f $m.gk,$m.n) }

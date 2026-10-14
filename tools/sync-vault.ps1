# Copies team\*.md into vault\team (read-only mirror). Re-run anytime.
$s='C:\Users\issao\Documents\DBTournament\team'; $d='C:\Users\issao\Documents\DBTournament\vault\team'
Get-ChildItem $s -Recurse -Filter *.md | % { $t = Join-Path $d $_.FullName.Substring($s.Length+1); New-Item -ItemType Directory -Force (Split-Path $t) | Out-Null; Copy-Item $_.FullName $t -Force }


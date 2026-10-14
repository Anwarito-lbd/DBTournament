# Lint only (no reformat). Usage: tools\lint.ps1 [path]
param([string]$Path = "C:\Users\issao\Documents\DBTournament\team")
Push-Location "C:\Users\issao\Documents\DBTournament\tools"; selene $Path; stylua --check $Path; Pop-Location


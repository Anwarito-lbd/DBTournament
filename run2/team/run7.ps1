$env:PYTHONIOENCODING='utf-8'
cd C:\Users\issao\Documents\DBTournament
$w = Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','maxstudio.ps1','watch' -WindowStyle Hidden -PassThru
python stopplay.py *> run7.log; python install.py *>> run7.log
python feel.py *>> run7.log
python priest6.py *>> run7.log
Stop-Process $w.Id
"RUN7 DONE" | Add-Content run7.log

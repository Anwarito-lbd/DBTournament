$env:PYTHONIOENCODING='utf-8'
cd C:\Users\issao\Documents\DBTournament
$w = Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','maxstudio.ps1','watch' -WindowStyle Hidden -PassThru
python install.py *> run8.log; python feel2.py *>> run8.log
Stop-Process $w.Id
Compress-Archive -Force v11_hit_*.png r8.zip
"RUN8 DONE" | Add-Content run8.log

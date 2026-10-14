Add-Type @"
using System;using System.Runtime.InteropServices;
public class WM{[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr h,int c);[DllImport("user32.dll")]public static extern bool IsIconic(IntPtr h);[DllImport("user32.dll")]public static extern bool IsZoomed(IntPtr h);}
"@
$p=Get-Process RobloxStudioBeta | Select-Object -First 1
if ($args[0] -eq "watch") { while ($true) { if (-not [WM]::IsZoomed($p.MainWindowHandle)) { [WM]::ShowWindow($p.MainWindowHandle,3) | Out-Null }; Start-Sleep -Milliseconds 500 } }
[WM]::ShowWindow($p.MainWindowHandle,3) | Out-Null; "zoomed=" + [WM]::IsZoomed($p.MainWindowHandle)

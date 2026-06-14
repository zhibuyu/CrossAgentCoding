Option Explicit

Dim shell, fso, folder, ps1, cmd

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

folder = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = fso.BuildPath(folder, "AgentMemoryManager.ps1")
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File " & Chr(34) & ps1 & Chr(34)

shell.Run cmd, 0, True

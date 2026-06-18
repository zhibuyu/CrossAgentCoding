Option Explicit

Dim shell, fso, folder, ps1, cmd, rc, logPath

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

folder = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = fso.BuildPath(folder, "AgentMemoryManager.ps1")
logPath = fso.BuildPath(shell.ExpandEnvironmentStrings("%TEMP%"), "CrossAgentCoding-error.log")

If Not fso.FileExists(ps1) Then
    MsgBox "CrossAgentCoding: missing AgentMemoryManager.ps1" & vbCrLf & ps1, vbCritical, "CrossAgentCoding"
    WScript.Quit 1
End If

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File " & Chr(34) & ps1 & Chr(34)

' Run PowerShell hidden and wait. The GUI handles and reports its own startup
' errors, so a non-zero exit code here means PowerShell could not start at all
' (e.g. blocked execution policy, a parse error, or a missing runtime).
On Error Resume Next
rc = shell.Run(cmd, 0, True)
If Err.Number <> 0 Then
    MsgBox "CrossAgentCoding failed to launch PowerShell." & vbCrLf & Err.Description, vbCritical, "CrossAgentCoding"
    WScript.Quit 1
End If
On Error Goto 0

If rc <> 0 Then
    MsgBox "CrossAgentCoding could not start (exit code " & rc & ")." & vbCrLf & _
        "See log if present: " & logPath, vbExclamation, "CrossAgentCoding"
End If

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "src"
$stage = Join-Path $root "_manager_stage"
$OutputExe = Join-Path $root "release\CrossAgentCoding.exe"

# Ensure the output directory exists
$outputDir = Split-Path -Parent $OutputExe
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Clean staging
if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force
}
New-Item -ItemType Directory -Path $stage | Out-Null

# ── Step 1: Find C# compiler ──
$csc = Get-ChildItem "$env:windir\Microsoft.NET\Framework64\v4*\csc.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if (-not $csc) {
    $csc = Get-ChildItem "$env:windir\Microsoft.NET\Framework\v4*\csc.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $csc) {
    throw "Cannot find csc.exe (C# compiler). Please install .NET Framework 4.x SDK."
}

# ── Step 2: Prepare the PS1 script as an embedded resource ──
$scriptSource = Join-Path $src "AgentMemoryManager.ps1"
$resourceFile = Join-Path $stage "AgentMemoryManager.ps1"
Copy-Item -LiteralPath $scriptSource -Destination $resourceFile -Force

# ── Step 3: Write the C# launcher source (no visible window) ──
$launcherCs = Join-Path $stage "Launcher.cs"
$iconPath = Join-Path $root "icon\icon.ico"

$launcherCode = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;

class CrossAgentCodingLauncher
{
    [DllImport("user32.dll")]
    static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    static extern bool IsIconic(IntPtr hWnd);

    const int SW_RESTORE = 9;
    const int SW_SHOW = 5;

    private Process psProcess;
    private System.Windows.Forms.Timer watchTimer;
    private System.Windows.Forms.Timer findWindowTimer;
    private IntPtr psFormHandle = IntPtr.Zero;
    private Form hiddenForm;

    public CrossAgentCodingLauncher()
    {
        // Create a hidden Form to host the message loop and timers.
        // This Form is never shown, never appears in taskbar, and has no icon.
        hiddenForm = new Form();
        hiddenForm.ShowInTaskbar = false;
        hiddenForm.ShowIcon = false;
        hiddenForm.Text = "CrossAgentCoding";
        hiddenForm.WindowState = FormWindowState.Minimized;
        hiddenForm.FormBorderStyle = FormBorderStyle.None;
        hiddenForm.Size = new System.Drawing.Size(1, 1);
        hiddenForm.StartPosition = FormStartPosition.Manual;
        hiddenForm.Location = new System.Drawing.Point(-9999, -9999);
        hiddenForm.Load += (s, e) => { hiddenForm.Hide(); };

        findWindowTimer = new System.Windows.Forms.Timer { Interval = 300 };
        findWindowTimer.Tick += (s, e) =>
        {
            if (psProcess != null && !psProcess.HasExited)
            {
                try
                {
                    IntPtr h = psProcess.MainWindowHandle;
                    if (h != IntPtr.Zero && h != psFormHandle)
                    {
                        psFormHandle = h;
                    }
                }
                catch { }
            }
        };
        findWindowTimer.Start();

        watchTimer = new System.Windows.Forms.Timer { Interval = 500 };
        watchTimer.Tick += (s, e) =>
        {
            if (psProcess != null && psProcess.HasExited)
            {
                watchTimer.Stop();
                findWindowTimer.Stop();
                hiddenForm.Close();
                Application.Exit();
            }
        };
        watchTimer.Start();
    }

    void LaunchPowerShell()
    {
        try
        {
            string scriptPath = ExtractScript();
            if (scriptPath == null) return;

            psProcess = new Process();
            psProcess.StartInfo.FileName = "powershell.exe";
            psProcess.StartInfo.Arguments = string.Format(
                "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File \"{0}\"",
                scriptPath);
            psProcess.StartInfo.UseShellExecute = false;
            psProcess.StartInfo.CreateNoWindow = true;
            psProcess.StartInfo.RedirectStandardOutput = false;
            psProcess.StartInfo.RedirectStandardError = false;
            psProcess.EnableRaisingEvents = true;
            psProcess.Start();
        }
        catch (Exception ex)
        {
            LogError("LaunchPowerShell failed: " + ex.ToString());
            Application.Exit();
        }
    }

    string ExtractScript()
    {
        try
        {
            Assembly asm = Assembly.GetExecutingAssembly();
            using (Stream stream = asm.GetManifestResourceStream("CrossAgentCoding.AgentMemoryManager.ps1"))
            {
                if (stream == null)
                {
                    LogError("Resource not found!");
                    Application.Exit();
                    return null;
                }

                string tempDir = Path.Combine(Path.GetTempPath(), "CrossAgentCoding");
                Directory.CreateDirectory(tempDir);
                string scriptPath = Path.Combine(tempDir, "AgentMemoryManager.ps1");

                string exePath = asm.Location;
                if (!File.Exists(scriptPath) ||
                    File.GetLastWriteTime(exePath) > File.GetLastWriteTime(scriptPath))
                {
                    using (FileStream fs = new FileStream(scriptPath, FileMode.Create, FileAccess.Write))
                    {
                        stream.CopyTo(fs);
                    }
                }

                return scriptPath;
            }
        }
        catch (Exception ex)
        {
            LogError("ExtractScript failed: " + ex.ToString());
            Application.Exit();
            return null;
        }
    }

    void LogError(string msg)
    {
        try
        {
            string logPath = Path.Combine(Path.GetTempPath(), "CrossAgentCoding-launcher.log");
            File.AppendAllText(logPath, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " " + msg + Environment.NewLine);
        }
        catch { }
    }

    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        var launcher = new CrossAgentCodingLauncher();
        launcher.LaunchPowerShell();
        Application.Run(launcher.hiddenForm);
    }
}
'@

Set-Content -LiteralPath $launcherCs -Value $launcherCode -Encoding UTF8

# ── Step 4: Compile the C# launcher with embedded PS1 resource and icon ──
Write-Host "Compiling launcher with embedded script and icon..."

$cscArgs = @(
    "/target:winexe",
    "/out:$OutputExe",
    "/reference:System.Windows.Forms.dll",
    "/reference:System.Drawing.dll",
    "/resource:$resourceFile,CrossAgentCoding.AgentMemoryManager.ps1",
    $launcherCs
)
if (Test-Path -LiteralPath $iconPath) {
    $cscArgs += "/win32icon:$iconPath"
}

$compileResult = & $csc $cscArgs 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host $compileResult
    throw "C# compilation failed"
}

# ── Step 5: Cleanup ──
Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue

$built = Get-Item -LiteralPath $OutputExe
$now = Get-Date
$built.CreationTime = $now
$built.LastWriteTime = $now

$fileSize = [math]::Round($built.Length / 1KB)
Write-Host "Built $OutputExe ($fileSize KB)"

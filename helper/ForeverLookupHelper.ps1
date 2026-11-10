# Forever Lookup Helper
# Watches the Windows clipboard. When you copy a Forever Lookup link (Wowhead Forever,
# WarcraftDB Forever or warcraft.wiki.gg search), it opens it in your default browser.
# It never touches WoW: it only reads the clipboard. Tray icon: right-click to pause or exit.
#
# Run:  powershell.exe -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File ForeverLookupHelper.ps1
# Test: powershell.exe -NoProfile -File ForeverLookupHelper.ps1 -Test

param([switch]$Test)

$ErrorActionPreference = 'Stop'

# Only these exact link shapes are opened. Anything else on the clipboard is ignored.
$Pattern = '^https://((www|de|es|fr|it|pt|ru|ko|cn|tw|mx)\.wowhead\.com/forever/[a-z]+=\d+(#comments)?|(www|de|es|fr|it|pt|ru|ko|cn|tw|mx)\.wowhead\.com/forever/search\?q=[\w%+.\-~]+|forever\.warcraftdb\.com/data/[a-z]+/\d+|forever\.warcraftdb\.com/search\?q=[\w%+.\-~]+|warcraft\.wiki\.gg/wiki/Special:Search\?search=[\w%+.\-~]+&go=Go)$'

function Test-LookupUrl([string]$text) {
    if ([string]::IsNullOrWhiteSpace($text)) { return $false }
    $t = $text.Trim()
    return ($t.Length -le 512) -and ($t -cmatch $Pattern)
}

if ($Test) {
    $cases = @{
        'https://www.wowhead.com/forever/item=6948'                                   = $true
        'https://www.wowhead.com/forever/search?q=Hogger%27s+Claw'                     = $true
        'https://forever.warcraftdb.com/data/npc/448'                                  = $true
        'https://forever.warcraftdb.com/search?q=Honor'                                = $true
        'https://warcraft.wiki.gg/wiki/Special:Search?search=Hogger&go=Go'             = $true
        'https://de.wowhead.com/forever/npc=448'                                       = $true
        'https://xx.wowhead.com/forever/npc=448'                                       = $false
        'https://de.wowhead.com/forever/npc=448#comments'                              = $true
        'https://www.wowhead.com/forever/item=6948#evil'                               = $false
        'https://www.wowhead.com/item=6948'                                            = $false
        'https://evil.example.com/forever/item=1'                                      = $false
        'https://www.wowhead.com/forever/item=6948 & calc.exe'                         = $false
        'https://www.wowhead.com/forever/item=6948"; start calc'                       = $false
        'hello world'                                                                  = $false
    }
    $fail = 0
    foreach ($k in $cases.Keys) {
        $got = Test-LookupUrl $k
        $ok = $got -eq $cases[$k]
        if (-not $ok) { $fail++ }
        '{0}  {1,-5}  {2}' -f ($(if ($ok) { 'PASS' } else { 'FAIL' })), $got, $k
    }
    exit $fail
}

# --- single instance ---
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\ForeverLookupHelper', [ref]$created)
if (-not $created) { exit 0 }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -Namespace FLH -Name Native -MemberDefinition '[DllImport("user32.dll")] public static extern uint GetClipboardSequenceNumber();'

$script:enabled = $true
$script:lastSeq = [FLH.Native]::GetClipboardSequenceNumber()
$script:lastOpen = [datetime]::MinValue

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = [System.Drawing.SystemIcons]::Information
$tray.Text = 'Forever Lookup Helper (on)'
$tray.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$toggle = $menu.Items.Add('Pause')
$exit = $menu.Items.Add('Exit')
$tray.ContextMenuStrip = $menu

$toggle.add_Click({
    $script:enabled = -not $script:enabled
    $toggle.Text = $(if ($script:enabled) { 'Pause' } else { 'Resume' })
    $tray.Text = 'Forever Lookup Helper (' + $(if ($script:enabled) { 'on' } else { 'paused' }) + ')'
})
$exit.add_Click({
    $timer.Stop()
    $tray.Visible = $false
    $tray.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300
$timer.add_Tick({
    try {
        $seq = [FLH.Native]::GetClipboardSequenceNumber()
        if ($seq -eq $script:lastSeq) { return }
        $script:lastSeq = $seq
        if (-not $script:enabled) { return }
        if (-not [System.Windows.Forms.Clipboard]::ContainsText()) { return }
        $text = [System.Windows.Forms.Clipboard]::GetText()
        if (-not (Test-LookupUrl $text)) { return }
        # ignore accidental double copies within a second
        if (([datetime]::Now - $script:lastOpen).TotalMilliseconds -lt 1000) { return }
        $script:lastOpen = [datetime]::Now
        Start-Process -FilePath ($text.Trim())
    } catch {
        # clipboard can be briefly locked by other apps; try again next tick
    }
})
$timer.Start()

[System.Windows.Forms.Application]::Run()
$mutex.ReleaseMutex()

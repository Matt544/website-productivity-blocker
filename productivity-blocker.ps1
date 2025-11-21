<#
.SYNOPSIS
    Productivity Blocker: Enables or disables access to specified distracting websites
    by modifying the hosts file.

.DESCRIPTION
    This script updates the Windows hosts file to either block or unblock a list
    of websites. It can operate in two modes:
      1. Automatic time-based mode: Blocks sites during specified work hours.
      2. Manual override mode: Forces sites to be blocked or unblocked via a command-line parameter.

.PARAMETER state
    Optional. Manual override for site blocking. Accepts:
      - "enabled"  → unblocks the sites
      - "disabled" → blocks the sites
    If omitted, the script uses the time-based automatic mode.

.USAGE
    # Automatic, based on current time
    .\productivity-blocker.ps1

    # Manual override to block sites
    .\productivity-blocker.ps1 -state disabled

    # Manual override to unblock sites
    .\productivity-blocker.ps1 -state enabled

.NOTES
    - Requires administrator privileges to modify the hosts file.
    - Scheduled tasks (e.g., Task Scheduler) should run this script at login
      and/or at the start of your blocking/enabling periods to ensure proper behavior.
    - To change the active blocking period, modify the $disableStart and $disableEnd
      TimeSpan values below. If you change these times, also update the Task Scheduler
      triggers to run shortly after the new start/end times.

#>


param(
    [ValidateSet("enabled","disabled")]
    [string]$state
)

$hostsFilePath   = "$env:WinDir\System32\drivers\etc\hosts"

# Markers to define the block region inside the hosts file
$startMarker = "# >>> Productivity block start"
$endMarker   = "# >>> Productivity block end"

# List of websites to block
$blockedSites = @(
    "youtube.com",
    "www.youtube.com"
)

# Redirect IP for blocking (will simply cause attempt to access the site to hang)
$blockIP = "127.0.0.1"

# 1. Determine whether we should block sites
if ($state) {
    # Manual mode
    $shouldDisable = ($state -eq "disabled")
} else {
    # Automatic time-based mode
    # Modify these values to change when sites are blocked
    $disableStart = [TimeSpan]::Parse("06:00")
    $disableEnd   = [TimeSpan]::Parse("22:00")
    $now = (Get-Date).TimeOfDay

    # Handle the case where start < end (normal) or overnight periods
    if ($disableStart -le $disableEnd) {
        $shouldDisable = ($now -ge $disableStart) -and ($now -lt $disableEnd)
    } else {
        $shouldDisable = ($now -ge $disableStart) -or ($now -lt $disableEnd)
    }
}

# 2. Read hosts file
$content = Get-Content -Raw -Path $hostsFilePath

# 3. Regex: find existing block markers
$pattern = [regex]::Escape($startMarker) + "(.*?)" + [regex]::Escape($endMarker)
$match = [regex]::Match(
    $content,
    $pattern,
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# 4. Build new inner block based on the desired state
if ($shouldDisable) {
    $newInner = "`r`n"
    foreach ($site in $blockedSites) {
        $newInner += "$blockIP $site`r`n"
    }
} else {
    # Remove entries → empty block,  enabling site access
    $newInner = "`r`n`r`n"
}

$replacement = "$startMarker$newInner$endMarker"

# 5. Update or insert the block
if ($match.Success) {
    # Replace existing block
    $newContent = [regex]::Replace(
        $content,
        $pattern,
        [System.Text.RegularExpressions.MatchEvaluator]{ $replacement },
        'Singleline'
    )

    $newContent | Out-File -FilePath $hostsFilePath -Encoding ASCII -Force
}
else {
    # Add block if disabling
    if ($shouldDisable) {
        $block = "$startMarker$newInner$endMarker`r`n"
        Add-Content -Path $hostsFilePath -Value $block -Encoding ASCII
    }
}

# 6. Flush the DNS cache so the new hosts file takes effect immediately
# - Note: this seems to be hit and miss. To assist in avoiding maintaining access to 
#   distracting sites when they are disabled, try to open a new browser session for 
#   those sites (maybe right-click "chrome > New Window" does that?).
Try {
    Write-Host "Flushing DNS cache..." -ForegroundColor Cyan
    ipconfig /flushdns | Out-Null
    Write-Host "DNS cache flushed." -ForegroundColor Green
} Catch {
    Write-Warning "Failed to flush DNS cache. Hosts file changes may not take effect immediately."
}

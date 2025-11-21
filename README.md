# Website Productivity Blocker
This setup automatically blocks or unblocks selected distracting websites on your 
Windows machine. It uses:
- A PowerShell script: productivity-blocker.ps1
- Task Scheduler task: XML import to run the script at designated times and at login.

## The powershell script
- Automatically enables blocking during work hours (default 6:00 AM – 10:00 PM)
- Automatically disables blocking outside work hours
- Permits manually override the state with a command-line parameter

Website access is enabled and disabled by modifies the "hosts" file (as written, this 
assumes "C:\Windows\System32\drivers\etc\hosts"). No browser plugin is needed.

## XML Task Files
The Task Scheduler XML files provide the parameters for the task and must reference the 
PowerShell script file.  
- Make sure the `<Arguments>` path in each XML file points to the actual location of 
"productivity-blocker.ps1" on your machine.  
- For example:
```xml
<Arguments>-NoProfile -ExecutionPolicy Bypass -File "C:\path\to\productivity-blocker.ps1"</Arguments>
```

If you move the PowerShell script to a different folder, you must update the XML file 
accordingly before importing it into Task Manager. To change an existing task, delete 
the old and import anew (see "Updating Task Times", below).

## Manual Override
To temporarily change the blocking-state without waiting for scheduled triggers, run this in a 
powershell terminal, from within the directory that contains the 
"productivity-blocker.ps1" file:
```powershell
# Disable all websites immediately
.\productivity-blocker.ps1 -state disabled

# Enable all websites immediately
.\productivity-blocker.ps1 -state enabled
```

Manual overrides do not affect scheduled operations — the next scheduled trigger will 
enforce the normal time-based behavior.

## Importing the Task into Task Scheduler
1. Open Task Scheduler (Win + R → taskschd.msc).
1. Select Task Scheduler Library (or create a subfolder).
1. In the right-hand Actions pane, click Import Task…
1. Navigate to the XML file, select it, and click Open
1. Review the settings, ensure Run with highest privileges is selected, then click OK

The task is now ready to run automatically on login.

## Disabling or Removing the Task
- To Disable: Right-click the task → Disable → preserves the task but prevents it from running
- To Enable: Right-click → Enable → restores automatic operation
- To Remove: Right-click → Delete → permanently removes the task from Task Scheduler

## Updating Task Times
To change the times the script enforces blocking/unblocking:
1. Modify the times in the PowerShell script (`$disableStart` and `$disableEnd`).

And if using Task Scheduler:
1. Update the XML triggers to times after the `$disableStart` and `$disableEnd` times.
1. Delete the existing task from Task Scheduler.
1. Re-import the updated XML file.

Note: Editing the XML file alone does not update an already-registered task in Task 
Scheduler.

## Changing Blocked Websites
To update the list of websites that are blocked:
1. Open `productivity-blocker.ps1` in a text editor.
1. Edit the `$blockedSites` array to add or remove domains.

Example:
```powershell
$blockedSites = @(
    "google.com",
    "www.google.com",
    "youtube.com",
    "www.youtube.com",
    "reddit.com",
    "www.reddit.com"
)
```

Do not add a trailing comma after the last entry.

To block a subdomain or alternative domain, you must list it explicitly (e.g., 
"m.youtube.com" or "news.google.com").

After saving the script, the next scheduled run (or a manual override) will use the 
updated list. However, note that browser caching can interfere with this. Consider using
distracting sites in separate browser sessions.

## Notes
- Requires administrator privileges to modify the "hosts" file.
- Works per user session (LogonTrigger).
- By default, uses "hosts" file entries to block websites system-wide.

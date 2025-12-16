# PowerShell Completions

`Profile.Completions.ps1` is derived from
[Jimmy Biggs' Lazy Loading Tab Completion Scripts in PowerShell](https://blog.noclocks.dev/lazy-loading-tab-completion-scripts-in-powershell).

```powershell
$completionPath = Split-Path $PROFILE | Join-Path -ChildPath "Completions"

& starship init powershell --print-full-init |
  Out-File -Encoding utf8 -Path "$completionPath\starship-profile.ps1"

((pandoc --bash-completion) -join "`n") |
  Set-Content -Encoding Ascii -NoNewline `
    -Path "$completionPath\pandoc-completion.sh"
```

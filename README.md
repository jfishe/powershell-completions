# PowerShell Completions

`Profile.Completions.ps1` is derived from Jimmy Biggs' No Clocks Blog,
*[Lazy Loading][lazy_loading] Tab Completion Scripts in PowerShell*.

PowerShell data files (`psd1`) only support static content, so the lazy-loading
registry lives in `Profile.Completions.ps1`.

At startup, the script registers one top-level native argument completer for
all known commands. The first time completion is requested for a command, that
command's loader runs once for the current session and registers the real
completion handler.

Completion loaders are grouped by source:

- Generated PowerShell completion scripts: `bat`, `pixi`, `rg`, `uv`
- Imported PowerShell modules: `vim`, `wsl`
- Saved bash completion files via `PSBashCompletions`: `copilot`, `pandoc`
- Native completion: `winget`

## Installation

Clone `powershell-completions` to a new folder
in the PowerShell profile directory.
Source the completions when starting PowerShell.

```powershell
Set-Location -Path (Split-Path $PROFILE)
git clone https://github.com/jfishe/powershell-completions.git Completions

@'
If ($host.Name -eq 'ConsoleHost') {
  . "$PSScriptRoot/Completions/Profile.Completions.ps1"
}
'@ | Out-File -Append -Path $PROFILE
```

## Bash completion files

[PSBashCompletions][psbashcompletions] adds support for `bash` completion
scripts. In this repository it is used for `copilot` and `pandoc`.

These completions are only registered when `bash` or `git` is available.

```powershell
$completionPath = Split-Path $PROFILE | Join-Path -ChildPath "Completions"

((pandoc --bash-completion) -join "`n") |
  Set-Content -Encoding Ascii -NoNewline `
    -Path "$completionPath\pandoc-completion.sh"
```

```powershell
$completionPath = Split-Path $PROFILE | Join-Path -ChildPath "Completions"

((copilot completion bash) -join "`n") |
  Set-Content -Encoding Ascii -NoNewline `
    -Path "$completionPath\copilot-completion.sh"
```

## Generated PowerShell completion scripts

`bat`, `pixi`, `rg`, and [Astral `uv`][uv] generate PowerShell completion
scripts on demand. The generated script is loaded the first time completion is
requested for each command in a PowerShell session.

## Testing

The repository includes Pester tests for the native completer registrations in
`Tests\Profile.Completions.Tests.ps1`.

Run the test file with Pester 5:

```powershell
Import-Module Pester -MinimumVersion 5.0
Invoke-Pester -Path .\Tests\Profile.Completions.Tests.ps1
```

To show detailed output without using Pester's legacy `-Show All` parameter set:

```powershell
Import-Module Pester -MinimumVersion 5.0
Invoke-Pester -Path .\Tests\Profile.Completions.Tests.ps1 `
  -Configuration @{ Output = @{ Verbosity = 'Detailed' } }
```

## Vim

`Vim` and its variants (e.g. `gvim`) use the PowerShell module
[VimTabCompletion][vimtabcompletion].
Complete with `vim` first; the variants are added by the module.

## Winget

[Winget][winget] uses native completion.

## Wsl

`wsl` uses the PowerShell module [WSLTabCompletion][wsltabcompletion].

[lazy_loading]: https://blog.noclocks.dev/lazy-loading-tab-completion-scripts-in-powershell
[psbashcompletions]: https://www.powershellgallery.com/packages/PSBashCompletions/
[uv]: https://docs.astral.sh/uv/getting-started/installation/
[vimtabcompletion]: https://www.powershellgallery.com/packages/VimTabCompletion
[winget]: https://learn.microsoft.com/en-us/windows/package-manager/winget/tab-completion
[wsltabcompletion]: https://www.powershellgallery.com/packages/WSLTabCompletion/

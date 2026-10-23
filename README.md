# PowerShell Completions

`Profile.Completions.ps1` is derived from Jimmy Briggs' No Clocks Blog,
*[Lazy Loading][lazy_loading] Tab Completion Scripts in PowerShell*.

PowerShell data files (`psd1`) only support static content, so the lazy-loading
registry lives in `Profile.Completions.ps1`.

At startup, the script registers a lazy loader as the native argument completer
for each known command. The first time completion is requested for a command,
that command's loader runs once for the current session, registers the real
completion handler, and re-runs completion so the first `Tab` returns
results.

Completion loaders are grouped by source:

- Generated PowerShell completion scripts: `bat`, `pixi`, `rg`, `uv`
- Imported PowerShell modules: `git`/`tgit`/`gitk` (posh-git), `vim` and its
  variants, `wsl`
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

Install the PowerShell modules the loaders import:

```powershell
Install-Module posh-git, PSBashCompletions, VimTabCompletion,
  WSLTabCompletion -Scope CurrentUser
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

## Git

`git`, `tgit`, and `gitk` use the PowerShell module [posh-git][posh-git].
It is lazy-loaded for completion only; starship draws the prompt.
An `Import-Module posh-git` in `$PROFILE` still works, but is no longer
needed; removing it keeps posh-git out of startup.

## Vim

`vim`, `vimdiff`, `gvim`, `gvimdiff`, and `evim` use the PowerShell module
[VimTabCompletion][vimtabcompletion]. Each variant lazy-loads the module on
its first completion.

## Winget

[Winget][winget] uses native completion.

## Wsl

`wsl` uses the PowerShell module [WSLTabCompletion][wsltabcompletion].

## Credits

- The lazy-loading approach is adapted from Jimmy Briggs' No Clocks Blog,
  *[Lazy Loading Tab Completion Scripts in PowerShell][lazy_loading]*.
- The `winget` completer is copied from Microsoft's
  [winget-cli completion docs][winget-completion] (MIT).
- Completions come from [posh-git][posh-git],
  [PSBashCompletions][psbashcompletions], [VimTabCompletion][vimtabcompletion],
  [WSLTabCompletion][wsltabcompletion], [bat][bat], [ripgrep][rg],
  [pixi][pixi], [uv][uv], [pandoc][pandoc], and [GitHub Copilot CLI][copilot].
  These projects are not bundled here and keep their own licenses.

See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for license details.

[lazy_loading]: https://blog.noclocks.dev/lazy-loading-tab-completion-scripts-in-powershell
[posh-git]: https://github.com/dahlbyk/posh-git
[psbashcompletions]: https://www.powershellgallery.com/packages/PSBashCompletions/
[uv]: https://docs.astral.sh/uv/getting-started/installation/
[vimtabcompletion]: https://www.powershellgallery.com/packages/VimTabCompletion
[winget]: https://learn.microsoft.com/en-us/windows/package-manager/winget/tab-completion
[wsltabcompletion]: https://www.powershellgallery.com/packages/WSLTabCompletion/
[bat]: https://github.com/sharkdp/bat
[copilot]: https://docs.github.com/en/copilot
[pandoc]: https://pandoc.org/
[pixi]: https://pixi.sh/
[rg]: https://github.com/BurntSushi/ripgrep
[winget-completion]: https://github.com/microsoft/winget-cli/blob/master/doc/Completion.md

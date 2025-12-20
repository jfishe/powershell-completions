# PowerShell Completions

`Profile.Completions.ps1` is derived from Jimmy Biggs' No Clocks Blog,
*[Lazy Loading][lazy_loading] Tab Completion Scripts in PowerShell*.

PowerShell data files (`psd1`) only support static content, so
`$CompletionScripts` moved to `$Profile.Completions.ps1`.
Each entry registers the associated Argument-Completer.

Where possible, script blocks replace sourcing generated completion scripts
because the overhead is low. This practice avoids regenerating the completion
scripts periodically.

## Condax

[Condax][condax] generates its own completion script,
which clobbers `PSReadLine` settings, unless
the first and last lines are stripped.

## PSBashCompletions

[PSBashCompletions][psbashcompletions] adds support for `bash` completion
scripts, e.g., `pandoc`.

```powershell
$completionPath = Split-Path $PROFILE | Join-Path -ChildPath "Completions"

((pandoc --bash-completion) -join "`n") |
  Set-Content -Encoding Ascii -NoNewline `
    -Path "$completionPath\pandoc-completion.sh"
```

## Astral uv

[Astral][uv] generates its own completion script.

## Vim

`Vim` and its variants (e.g. `gvim`) use the PowerShell module
[VimTabCompletion][vimtabcompletion].
Complete with `vim` first; the variants are added by the module.

## Winget

[Winget][winget] uses native completion.

## Wsl

`wsl` uses the PowerShell module [WSLTabCompletion][wsltabcompletion].

[condax]: https://mariusvniekerk.github.io/condax/installation/#shell-completion
[lazy_loading]: https://blog.noclocks.dev/lazy-loading-tab-completion-scripts-in-powershell
[psbashcompletions]: https://www.powershellgallery.com/packages/PSBashCompletions/
[uv]: https://docs.astral.sh/uv/getting-started/installation/
[vimtabcompletion]: https://www.powershellgallery.com/packages/VimTabCompletion
[winget]: https://learn.microsoft.com/en-us/windows/package-manager/winget/tab-completion
[wsltabcompletion]: https://www.powershellgallery.com/packages/WSLTabCompletion/

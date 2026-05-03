
<#PSScriptInfo

.VERSION 2.2

.GUID e666cc2a-8d7d-4112-a490-ee096bf66401

.AUTHOR jdfenw@gmail.com

.COMPANYNAME John D. Fisher

.COPYRIGHT 2026 John D. Fisher

.TAGS
 argumentcompleter

.LICENSEURI https://github.com/jfishe/powershell-completions/blob/main/LICENSE

.PROJECTURI https://github.com/jfishe/powershell-completions

.ICONURI

.EXTERNALMODULEDEPENDENCIES
 PSBashCompletions
 VimTabCompletion
 WSLTabCompletion

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES
 bat
 copilot
 pandoc
 rg
 uv
 winget
 pixi

.RELEASENOTES
 PowerShell data files (psd1) only support static content, so
 $CompletionScripts moved to $Profile.Completions.ps1.
 Each entry registers the associated Argument-Completer lazily.

 Completion loaders are grouped by source: generated scripts,
 imported modules, bash completion files, and native completions.

.PRIVATEDATA

#>

<#
.SYNOPSIS
 Lazy-loaded native command completions for PowerShell.

.DESCRIPTION
 Lazy-loaded native command completions for PowerShell.

 A single top-level argument completer defers command-specific setup until completion is first invoked for a command.
 Completion loaders are registered as script blocks and sourced from generated PowerShell scripts, PowerShell modules,
 bash completion files, or native completion handlers.

 Profile.Completions.ps1 derives from Jimmy Biggs' No Clocks Blog, Lazy Loading Tab Completion Scripts in PowerShell.

.LINK
 Jimmy Biggs' No Clocks Blog, Lazy Loading Tab Completion Scripts in PowerShell (https://blog.noclocks.dev/lazy-loading-tab-completion-scripts-in-powershell).
.LINK
 Bat is a Linux cat clone with syntax highlighting and Git integration (https://github.com/sharkdp/bat).
.LINK
 Pixi is a fast, modern, and reproducible package management tool for developers of all backgrounds (https://pixi.prefix.dev/dev/installation/#winget).
.LINK
 Ripgrep is a command line tool that searches your files for patterns that you give it (https://github.com/BurntSushi/ripgrep).
.LINK
 Uv is an extremely fast Python package and project manager, written in Rust (https://docs.astral.sh/uv/).
.LINK
 VimTabCompletion is a Vim Argument Completer for PowerShell (https://github.com/jfishe/VimTabCompletion).
.LINK
 GitHub Copilot CLI - An AI-powered coding assistant (https://docs.github.com/en/copilot).
 Pandoc is a universal document converter (https://pandoc.org/).
 PSBashCompletions is a bridge to enable bash completions to be run from within PowerShell (https://github.com/tillig/ps-bash-completions).
.LINK
 Winget is the Microsoft Windows Package Manager, a command line utility enables installing applications and other packages from the command line
 (https://github.com/microsoft/winget-cli/blob/master/doc/Completion.md).
.LINK
 Wsl is the command line interface to Windows Subsystem for Linux (https://learn.microsoft.com/en-us/windows/wsl/).
 WSLTabCompletion is a PowerShell module which includes a .Net ArgumentCompleter for the native wsl.exe command, used to launch and manage the Windows Subsystem for Linux.

.NOTES
 $CompletionScripts map commands and programs to a script block that registers or imports completion support.
 Additional commands and loaders may be added to $CompletionScripts.

  - The key is the command name.
  - The value is a script block executed once per session for that command.
#>
& {
    function New-GeneratedCompletionLoader {
        param(
            [Parameter(Mandatory = $true)]
            [String[]]$Command
        )

        $invocation = ($Command | ForEach-Object { "'{0}'" -f $_.Replace("'", "''") }) -join ' '
        $scriptText = @"
param(`$wordToComplete, `$commandAst, `$cursorPosition)
`$generatedScript = & $invocation | Out-String
if (`$generatedScript) {
    Invoke-Expression `$generatedScript
}
"@

        [scriptblock]::Create($scriptText)
    }

    function New-ModuleCompletionLoader {
        param(
            [Parameter(Mandatory = $true)]
            [String]$ModuleName
        )

        $escapedModuleName = $ModuleName.Replace("'", "''")
        [scriptblock]::Create(@"
param(`$wordToComplete, `$commandAst, `$cursorPosition)
Import-Module -Name '$escapedModuleName'
"@)
    }

    function New-BashCompletionLoader {
        param(
            [Parameter(Mandatory = $true)]
            [String]$CommandName,

            [Parameter(Mandatory = $true)]
            [String]$FileName
        )

        $escapedCommandName = $CommandName.Replace("'", "''")
        $escapedFileName = $FileName.Replace("'", "''")
        [scriptblock]::Create(@"
param(`$wordToComplete, `$commandAst, `$cursorPosition)
if ((Get-Command bash -ErrorAction Ignore) -or (Get-Command git -ErrorAction Ignore)) {
    Import-Module -Name PSBashCompletions
    `$completionPath = Join-Path -Path (Split-Path `$PROFILE) -ChildPath 'Completions'
    Register-BashArgumentCompleter '$escapedCommandName' (Join-Path -Path `$completionPath -ChildPath '$escapedFileName')
}
"@)
    }

    $completionLoaders = @{
        'winget' = {
            param($wordToComplete, $commandAst, $cursorPosition)
            [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
            $Local:word = $wordToComplete.Replace('"', '""')
            $Local:ast = $commandAst.ToString().Replace('"', '""')
            winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        }
    }

    $generatedCompletionCommands = @{
        'bat'  = @('bat', '--completion', 'ps1')
        'pixi' = @('pixi', 'completion', '--shell=powershell')
        'rg'   = @('rg', '--generate=complete-powershell')
        'uv'   = @('uv', 'generate-shell-completion', 'powershell')
    }

    foreach ($entry in $generatedCompletionCommands.GetEnumerator()) {
        $completionLoaders[$entry.Key] = New-GeneratedCompletionLoader -Command $entry.Value
    }

    $moduleCompletions = @{
        'vim' = 'VimTabCompletion'
        'wsl' = 'WSLTabCompletion'
    }

    foreach ($entry in $moduleCompletions.GetEnumerator()) {
        $completionLoaders[$entry.Key] = New-ModuleCompletionLoader -ModuleName $entry.Value
    }

    $bashCompletionFiles = @{
        'copilot' = 'copilot-completion.sh'
        'pandoc'  = 'pandoc-completion.sh'
    }

    foreach ($entry in $bashCompletionFiles.GetEnumerator()) {
        $completionLoaders[$entry.Key] = New-BashCompletionLoader -CommandName $entry.Key -FileName $entry.Value
    }

    if (!$UseLegacyTabExpansion -and ($PSVersionTable.PSVersion.Major -ge 5)) {
        foreach ($entry in $completionLoaders.GetEnumerator()) {
            Microsoft.PowerShell.Core\Register-ArgumentCompleter `
                -CommandName $entry.Key `
                -Native `
                -ScriptBlock $entry.Value
        }
    }
}

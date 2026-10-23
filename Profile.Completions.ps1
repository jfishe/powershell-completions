
<#PSScriptInfo

.VERSION 2.3

.GUID e666cc2a-8d7d-4112-a490-ee096bf66401

.AUTHOR jdfenw@gmail.com

.COMPANYNAME John D. Fisher

.COPYRIGHT 2020-2026 John D. Fisher

.TAGS
 argumentcompleter

.LICENSEURI https://github.com/jfishe/powershell-completions/blob/main/LICENSE

.PROJECTURI https://github.com/jfishe/powershell-completions

.ICONURI

.EXTERNALMODULEDEPENDENCIES
 posh-git
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
 the completion loader tables moved to Profile.Completions.ps1.
 Each entry registers the associated Argument-Completer lazily.

 Completion loaders are grouped by source: generated scripts,
 imported modules, bash completion files, and native completions.

 2.3: posh-git git completion moved here from the profile. All
 loaders now answer the first <Tab> instead of only registering,
 and every vim variant VimTabCompletion supports is lazy-loaded.

.PRIVATEDATA

#>

<#
.SYNOPSIS
 Lazy-loaded native command completions for PowerShell.

.DESCRIPTION
 Lazy-loaded native command completions for PowerShell.

 Each command gets a lazy loader, registered as a native argument completer, that defers command-specific setup until
 completion is first invoked for that command. The loader registers the real completer, sourced from a generated
 PowerShell script, a PowerShell module, or a bash completion file, then re-runs completion so the first <Tab> returns
 results. Commands with native completion handlers, such as winget, are registered directly.

 Profile.Completions.ps1 derives from Jimmy Briggs' No Clocks Blog, Lazy Loading Tab Completion Scripts in PowerShell.

.LINK
 Jimmy Briggs' No Clocks Blog, Lazy Loading Tab Completion Scripts in PowerShell (https://blog.noclocks.dev/lazy-loading-tab-completion-scripts-in-powershell).
.LINK
 Bat is a Linux cat clone with syntax highlighting and Git integration (https://github.com/sharkdp/bat).
.LINK
 Pixi is a fast, modern, and reproducible package management tool for developers of all backgrounds (https://pixi.prefix.dev/dev/installation/#winget).
.LINK
 Posh-git is a PowerShell module that provides Git tab completion (https://github.com/dahlbyk/posh-git).
.LINK
 Ripgrep is a command line tool that searches your files for patterns that you give it (https://github.com/BurntSushi/ripgrep).
.LINK
 Uv is an extremely fast Python package and project manager, written in Rust (https://docs.astral.sh/uv/).
.LINK
 VimTabCompletion is a Vim Argument Completer for PowerShell (https://github.com/jfishe/VimTabCompletion).
.LINK
 GitHub Copilot CLI - An AI-powered coding assistant (https://docs.github.com/en/copilot).
.LINK
 Pandoc is a universal document converter (https://pandoc.org/).
.LINK
 PSBashCompletions is a bridge to enable bash completions to be run from within PowerShell (https://github.com/tillig/ps-bash-completions).
.LINK
 Winget is the Microsoft Windows Package Manager, a command line utility enables installing applications and other packages from the command line
 (https://github.com/microsoft/winget-cli/blob/master/doc/Completion.md).
.LINK
 Wsl is the command line interface to Windows Subsystem for Linux (https://learn.microsoft.com/en-us/windows/wsl/).
.LINK
 WSLTabCompletion is a PowerShell module which includes a .Net ArgumentCompleter for the native wsl.exe command, used to launch and manage the Windows Subsystem for Linux
 (https://www.powershellgallery.com/packages/WSLTabCompletion/).

.NOTES
 $completionLoaders maps each command name to the script block registered as its native argument completer.
 Add a command by editing the table that matches its completion source:

  - $generatedCompletionCommands: command name -> argv that prints a PowerShell completion script.
  - $moduleCompletions: module name -> the commands its completer registers.
  - $bashCompletionFiles: command name -> bash completion file in the Completions folder.
  - $completionLoaders: command name -> a custom script block, such as winget's native completer.

 Loaders built by New-CompletionLoader run once per session for a command.
 Each registers the real completer, then re-runs completion so the first
 <Tab> returns results. $global:__CompletionLoaderActive guards that re-run
 against recursion when setup fails to register a completer.
#>
& {
    function New-CompletionLoader {
        param(
            [Parameter(Mandatory = $true)]
            [String]$Setup
        )

        # $Setup replaces this loader with the command's real completer, so
        # re-run completion to answer the first <Tab>. The guard stops
        # recursion if $Setup did not register a completer.
        [scriptblock]::Create(@"
param(`$wordToComplete, `$commandAst, `$cursorPosition)
if (`$global:__CompletionLoaderActive) { return }
$Setup
`$global:__CompletionLoaderActive = `$true
try {
    `$inputScript = `$commandAst.Extent.StartScriptPosition.GetFullScript()
    (TabExpansion2 -inputScript `$inputScript -cursorColumn `$cursorPosition).CompletionMatches
} finally {
    `$global:__CompletionLoaderActive = `$false
}
"@)
    }

    function New-GeneratedCompletionLoader {
        param(
            [Parameter(Mandatory = $true)]
            [String[]]$Command
        )

        $invocation = ($Command | ForEach-Object { "'{0}'" -f $_.Replace("'", "''") }) -join ' '
        New-CompletionLoader -Setup @"
`$generatedScript = & $invocation | Out-String
if (`$generatedScript) {
    Invoke-Expression `$generatedScript
}
"@
    }

    function New-ModuleCompletionLoader {
        param(
            [Parameter(Mandatory = $true)]
            [String]$ModuleName
        )

        # -Force re-runs the module's completer registration when the profile
        # imported it before this script replaced its completer.
        $escapedModuleName = $ModuleName.Replace("'", "''")
        New-CompletionLoader -Setup "Import-Module -Name '$escapedModuleName' -Global -Force"
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
        New-CompletionLoader -Setup @"
if ((Get-Command bash -ErrorAction Ignore) -or (Get-Command git -ErrorAction Ignore)) {
    Import-Module -Name PSBashCompletions -Global
    `$completionPath = Join-Path -Path (Split-Path `$PROFILE) -ChildPath 'Completions'
    Register-BashArgumentCompleter '$escapedCommandName' (Join-Path -Path `$completionPath -ChildPath '$escapedFileName')
}
"@
    }

    $completionLoaders = @{
        # From microsoft/winget-cli doc/Completion.md (MIT, (c) Microsoft Corporation).
        # See THIRD-PARTY-NOTICES.md.
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

    # Module name = the commands its completer registers. posh-git is only
    # used for completion (starship draws the prompt).
    $moduleCompletions = @{
        'posh-git'         = @('git', 'tgit', 'gitk')
        'VimTabCompletion' = @('vim', 'vimdiff', 'gvim', 'gvimdiff', 'evim')
        'WSLTabCompletion' = @('wsl')
    }

    foreach ($entry in $moduleCompletions.GetEnumerator()) {
        $loader = New-ModuleCompletionLoader -ModuleName $entry.Key
        foreach ($command in $entry.Value) {
            $completionLoaders[$command] = $loader
        }
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


<#PSScriptInfo

.VERSION 2.0

.GUID e666cc2a-8d7d-4112-a490-ee096bf66401

.AUTHOR jdfenw@gmail.com

.COMPANYNAME John D. Fisher

.COPYRIGHT 2025 John D. Fisher

.TAGS

.LICENSEURI https://github.com/jfishe/PowerShell/blob/main/LICENSE

.PROJECTURI https://github.com/jfishe/PowerShell

.ICONURI

.EXTERNALMODULEDEPENDENCIES
 PSBashCompletions
 VimTabCompletion
 WSLTabCompletion

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES
 condax
 pandoc
 uv
 winget

.RELEASENOTES
 PowerShell data files (psd1) only support static content, so
 $CompletionScripts moved to $Profile.Completions.ps1.
 Each entry registers the associated Argument-Completer.

 Where possible, script blocks replace sourcing generated completion scripts
 because the overhead is low and
 avoids the need to regenerate when the external application updates.

.SYNOPSIS
 Command-to-Script mapping hash-table, lazy loaded when completion first invoked for each command.

.DESCRIPTION
 Profile.Completions.ps1 implements a lazy-loading mechanism for completion scripts.

 Profile.Completions.ps1 derives from Jimmy Biggs' No Clocks Blog, Lazy Loading Tab Completion Scripts in PowerShell.

.LINK
 Jimmy Biggs' No Clocks Blog, Lazy Loading Tab Completion Scripts in PowerShell (https://blog.noclocks.dev/lazy-loading-tab-completion-scripts-in-powershell)

.NOTES
 $CompletionScripts map commands and programs to their corresponding shell completion scripts or modules. Additional commands and scripts may be added to $CompletionScripts.

  - The key is the command name.
  - The value is a script block that generates the completion script.
#>

$CompletionScripts = @{
    'uv'     = '& "uv" "generate-shell-completion" "powershell"'
    # Strip PSReadLine settings.
    'condax' = {
        $array = & condax --show-completion
        $array[2..($array.Length - 1)]
    }
    'vim'    = {
        Import-Module -Name VimTabCompletion
    }
    'pandoc' = {
        # PSBashCompletions
        if (($Null -ne (Get-Command bash -ErrorAction Ignore)) -or ($Null -ne (Get-Command git -ErrorAction Ignore))) {
            Import-Module -Name PSBashCompletions
            $completionPath = Split-Path $PROFILE | Join-Path -ChildPath "Completions"
            Register-BashArgumentCompleter pandoc "$completionPath\pandoc-completion.sh"
        }
    }
    'winget' = {
        # https://github.com/microsoft/winget-cli/blob/master/doc/Completion.md
        Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
            param($wordToComplete, $commandAst, $cursorPosition)
            [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
            $Local:word = $wordToComplete.Replace('"', '""')
            $Local:ast = $commandAst.ToString().Replace('"', '""')
            winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
        }
    }
    'wsl'    = {
        Import-Module WSLTabCompletion
    }
}

# ------------------------------------------------------------------------------
# Import-Completion
# ------------------------------------------------------------------------------

Function Import-Completion {
    <#
    .SYNOPSIS
        Load the completion script for the specified command.
    .DESCRIPTION
        This function loads the completion script for the specified command by dot-sourcing the script file.

        The function checks if the completion script for the specified command exists in the `$CompletionScripts` hash
        table and if it has not already been loaded. If both conditions are met, the function dot-sources the completion
        script defined in the hash table and sets the `$Script:CompletionLoaded` hash table entry for the specified
        command to `$true` (for the current session).

    .PARAMETER CommandName
        The name of the command for which to load the completion script. This parameter is mandatory and accepts input
        from the pipeline. The value of this parameter is validated against the keys in the `$CompletionScripts` hash
        table defined in the `Completions.psd1` file.

   .NOTES
       This function is used to implement a lazy-loading mechanism for importing completion scripts.

    .EXAMPLE
        # Load the completion script for the `aws` command.
        Import-Completion -CommandName 'aws'

        # Check if Loaded
        $Script:CompletionLoaded['aws']
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = 'None'
    )]
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({ $CompletionScripts.ContainsKey($_) })]
        [String]$CommandName
    )

    If ($CompletionScripts.ContainsKey($CommandName) -and -not $Script:CompletionLoaded[$CommandName]) {
        $CompletionScripts[$CommandName] | Invoke-Expression | Out-String | ? { $_ } | Invoke-Expression
        $Script:CompletionLoaded[$CommandName] = $true
    }
}

# Hashtable to track which completions have been loaded
$script:CompletionLoaded = @{}

## POWERSHELL CORE TAB COMPLETION ##############################################################
if (!$UseLegacyTabExpansion -and ($PSVersionTable.PSVersion.Major -ge 5)) {
    Microsoft.PowerShell.Core\Register-ArgumentCompleter `
        -Command @($CompletionScripts.Keys) `
        -Native `
        -ScriptBlock {
        param(
            $wordToComplete,
            $commandAst,
            $cursorPosition
        )
        Import-Completion -CommandName $commandAst.CommandElements[0]
    }
}

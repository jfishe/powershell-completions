
<#PSScriptInfo

.VERSION 1.0

.GUID e666cc2a-8d7d-4112-a490-ee096bf66401

.AUTHOR jdfen

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES
 PSBashCompletions

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#

.DESCRIPTION
 Profile.Completions.ps1

#>
Param()

<#
    .SYNOPSIS
        Command-to-Script Mapping Hash Table.
    .DESCRIPTION
        This PowerShell Data File (.psd1) contains the necessary mappings which map commands and programs to their
        corresponding shell completion scripts or modules.

        It is used in order to implement a lazy-loading mechanism for importing completion scripts.
    .NOTES
        - The key is the command name.
        - The value is the command that generates the completion script.

        Tools with names different than their commands:
            - Obsidian CLI uses `obs` as its CLI command.
            - 1Password CLI uses `op` as its CLI command.
            - `s` is the command for `s-search`.
            - `gh-copilot` is the key for the GitHub Copilot CLI Extension Completion Script, but the command is `gh copilot`.
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
            Import-Module PSBashCompletions
            $completionPath = "$env:PROFILEDIR/bash-completion"
            Register-BashArgumentCompleter pandoc "$completionPath/pandoc-completion.sh"
        }
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

Describe 'Profile.Completions' {
    BeforeAll {
        $profileCompletions = Join-Path (Split-Path -Parent $PSScriptRoot) 'Profile.Completions.ps1'
        function Global:Get-NativeArgumentCompleter {
            param(
                [String]$CommandName = '*'
            )

            $getExecutionContextFromTLS = [PowerShell].Assembly.GetType('System.Management.Automation.Runspaces.LocalPipeline').GetMethod(
                'GetExecutionContextFromTLS',
                [System.Reflection.BindingFlags]'Static,NonPublic'
            )
            $internalExecutionContext = $getExecutionContextFromTLS.Invoke(
                $null,
                [System.Reflection.BindingFlags]'Static, NonPublic',
                $null,
                $null,
                $psculture
            )

            $argumentCompletersProperty = $internalExecutionContext.GetType().GetProperty(
                'NativeArgumentCompleters',
                [System.Reflection.BindingFlags]'NonPublic, Instance'
            )

            $argumentCompleters = $argumentCompletersProperty.GetGetMethod($true).Invoke(
                $internalExecutionContext,
                [System.Reflection.BindingFlags]'Instance, NonPublic, GetProperty',
                $null,
                @(),
                $psculture
            )

            foreach ($completer in $argumentCompleters.Keys) {
                $name, $parameter = $completer -split ':'

                if ($name -like $CommandName) {
                    [PSCustomObject]@{
                        CommandName = $name
                        ParameterName = $parameter
                        Definition = $argumentCompleters[$completer]
                    }
                }
            }
        }

        . ([scriptblock]::Create((Get-Content -Path $profileCompletions -Raw)))
    }

    AfterAll {
        Remove-Item Function:\Get-NativeArgumentCompleter -ErrorAction SilentlyContinue
    }

    It 'does not leak loader builder functions after dot-sourcing' {
        Get-Command New-CompletionLoader, New-GeneratedCompletionLoader, New-ModuleCompletionLoader, New-BashCompletionLoader -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
    }

    It 'registers self-contained generated completion loaders for <CommandName>' -TestCases @(
        @{ CommandName = 'bat'; Invocation = "& 'bat' '--completion' 'ps1' | Out-String" }
        @{ CommandName = 'pixi'; Invocation = "& 'pixi' 'completion' '--shell=powershell' | Out-String" }
        @{ CommandName = 'rg'; Invocation = "& 'rg' '--generate=complete-powershell' | Out-String" }
        @{ CommandName = 'uv'; Invocation = "& 'uv' 'generate-shell-completion' 'powershell' | Out-String" }
    ) {
        param($CommandName, $Invocation)

        $completer = Get-NativeArgumentCompleter -CommandName $CommandName
        $completer | Should -Not -BeNullOrEmpty

        $definition = $completer.Definition.ToString()
        $definition | Should -Match '^\s*param\('
        $definition | Should -Match ([regex]::Escape($Invocation))
        $definition | Should -Match 'Invoke-Expression'
        $definition | Should -Not -Match 'New-GeneratedCompletionLoader|New-ModuleCompletionLoader|New-BashCompletionLoader|Import-Completion'
    }

    It 'registers self-contained module completion loaders for <CommandName>' -TestCases @(
        @{ CommandName = 'git'; ModuleName = 'posh-git' }
        @{ CommandName = 'tgit'; ModuleName = 'posh-git' }
        @{ CommandName = 'gitk'; ModuleName = 'posh-git' }
        @{ CommandName = 'vim'; ModuleName = 'VimTabCompletion' }
        @{ CommandName = 'vimdiff'; ModuleName = 'VimTabCompletion' }
        @{ CommandName = 'gvim'; ModuleName = 'VimTabCompletion' }
        @{ CommandName = 'gvimdiff'; ModuleName = 'VimTabCompletion' }
        @{ CommandName = 'evim'; ModuleName = 'VimTabCompletion' }
        @{ CommandName = 'wsl'; ModuleName = 'WSLTabCompletion' }
    ) {
        param($CommandName, $ModuleName)

        $completer = Get-NativeArgumentCompleter -CommandName $CommandName
        $completer | Should -Not -BeNullOrEmpty

        $definition = $completer.Definition.ToString()
        $definition | Should -Match '^\s*param\('
        $definition | Should -Match ([regex]::Escape("Import-Module -Name '$ModuleName' -Global -Force"))
        $definition | Should -Not -Match 'New-GeneratedCompletionLoader|New-ModuleCompletionLoader|New-BashCompletionLoader|Import-Completion'
    }

    It 'registers self-contained bash completion loaders for <CommandName>' -TestCases @(
        @{ CommandName = 'copilot'; FileName = 'copilot-completion.sh' }
        @{ CommandName = 'pandoc'; FileName = 'pandoc-completion.sh' }
    ) {
        param($CommandName, $FileName)

        $completer = Get-NativeArgumentCompleter -CommandName $CommandName
        $completer | Should -Not -BeNullOrEmpty

        $definition = $completer.Definition.ToString()
        $definition | Should -Match '^\s*param\('
        $definition | Should -Match 'Import-Module -Name PSBashCompletions -Global'
        $definition | Should -Match ([regex]::Escape("Register-BashArgumentCompleter '$CommandName'"))
        $definition | Should -Match ([regex]::Escape($FileName))
        $definition | Should -Not -Match 'New-GeneratedCompletionLoader|New-ModuleCompletionLoader|New-BashCompletionLoader|Import-Completion'
    }

    It 'registers a self-contained native winget completer' {
        $completer = Get-NativeArgumentCompleter -CommandName 'winget'
        $completer | Should -Not -BeNullOrEmpty

        $definition = $completer.Definition.ToString()
        $definition | Should -Match '^\s*param\('
        $definition | Should -Match 'winget complete'
        $definition | Should -Match 'CompletionResult'
        $definition | Should -Not -Match 'New-GeneratedCompletionLoader|New-ModuleCompletionLoader|New-BashCompletionLoader|Import-Completion'
    }

    It 'replays completion after loading for <CommandName>' -TestCases @(
        @{ CommandName = 'bat' }
        @{ CommandName = 'pixi' }
        @{ CommandName = 'rg' }
        @{ CommandName = 'uv' }
        @{ CommandName = 'git' }
        @{ CommandName = 'vim' }
        @{ CommandName = 'wsl' }
        @{ CommandName = 'copilot' }
        @{ CommandName = 'pandoc' }
    ) {
        param($CommandName)

        $definition = (Get-NativeArgumentCompleter -CommandName $CommandName).Definition.ToString()
        $definition | Should -Match ([regex]::Escape('$global:__CompletionLoaderActive'))
        $definition | Should -Match 'TabExpansion2'
    }
}

Describe 'Profile.Completions first-Tab replay' {
    BeforeAll {
        $profileCompletions = Join-Path (Split-Path -Parent $PSScriptRoot) 'Profile.Completions.ps1'

        # Functions win over bat.exe/rg.exe, so the generated loaders call these.
        function Global:bat {
            "Register-ArgumentCompleter -Native -CommandName bat -ScriptBlock { [System.Management.Automation.CompletionResult]::new('ok') }"
        }
        function Global:rg { }

        . ([scriptblock]::Create((Get-Content -Path $profileCompletions -Raw)))
    }

    AfterAll {
        Remove-Item Function:\bat, Function:\rg -ErrorAction SilentlyContinue
        Remove-Variable -Name __CompletionLoaderActive -Scope Global -ErrorAction SilentlyContinue
    }

    It 'answers the first Tab with the real completer' {
        $results = (TabExpansion2 -inputScript 'bat ' -cursorColumn 4).CompletionMatches
        $results.CompletionText | Should -Contain 'ok'
        $global:__CompletionLoaderActive | Should -BeFalse
    }

    It 'does not recurse when setup registers no completer' {
        { TabExpansion2 -inputScript 'rg ' -cursorColumn 3 } | Should -Not -Throw
        $global:__CompletionLoaderActive | Should -BeFalse
    }
}

Describe 'Profile.Completions with a module imported first' {
    BeforeAll {
        $profileCompletions = Join-Path (Split-Path -Parent $PSScriptRoot) 'Profile.Completions.ps1'

        # A profile that imports posh-git before dot-sourcing the completions.
        Import-Module -Name posh-git -Global
        . ([scriptblock]::Create((Get-Content -Path $profileCompletions -Raw)))
    }

    AfterAll {
        Remove-Module -Name posh-git -ErrorAction SilentlyContinue
        Remove-Variable -Name __CompletionLoaderActive -Scope Global -ErrorAction SilentlyContinue
    }

    It 'still completes git on the first Tab' {
        $results = (TabExpansion2 -inputScript 'git chec' -cursorColumn 8).CompletionMatches
        $results.CompletionText | Should -Contain 'checkout'
    }
}

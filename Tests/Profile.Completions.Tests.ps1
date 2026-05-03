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
        Get-Command New-GeneratedCompletionLoader, New-ModuleCompletionLoader, New-BashCompletionLoader -ErrorAction SilentlyContinue |
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
        @{ CommandName = 'vim'; ModuleName = 'VimTabCompletion' }
        @{ CommandName = 'wsl'; ModuleName = 'WSLTabCompletion' }
    ) {
        param($CommandName, $ModuleName)

        $completer = Get-NativeArgumentCompleter -CommandName $CommandName
        $completer | Should -Not -BeNullOrEmpty

        $definition = $completer.Definition.ToString()
        $definition | Should -Match '^\s*param\('
        $definition | Should -Match ([regex]::Escape("Import-Module -Name '$ModuleName'"))
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
        $definition | Should -Match 'Import-Module -Name PSBashCompletions'
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
}

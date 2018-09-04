#==================================================
# Module : PSTranslate
# Author : Mason Schleider
# 
# Copyright (2018). All rights reserved.
#==================================================

$ErrorActionPreference = 'Stop'

$TranslateAPI = @{
    Host = 'https://api.cognitive.microsofttranslator.com'
    Commands = @{
        Detect = '/detect?api-version=3.0'
        Languages = '/languages?api-version=3.0'
        Translate = '/translate?api-version=3.0'
    }
}

function Initialize-TranslateEnv {
    if ( !(Get-Variable -Name PSAzureTranslateApiKey -Scope Global -ErrorAction SilentlyContinue) ) {
        Write-Error "Global variable 'PSAzureTranslateApiKey' has not been set."
    } elseif ( !(Get-Variable -Name Languages -Scope Script -ErrorAction SilentlyContinue) ) {
        Write-Host 'Populating language list...'
        Set-LanguageList
    }
}

function Set-LanguageList {
    try {
        $Params = '&scope=translation'
        $RequestURI = $TranslateAPI.Host + $TranslateAPI.Commands.Languages + $Params
        
        $Response = Invoke-WebRequest -URI $RequestURI -Headers @{ 'Ocp-Apim-Subscription-Key' = $Global:PSAzureTranslateApiKey }
        $Script:Languages = ConvertFrom-Json $Response.Content
    } catch {
        Write-Error ($_ | Out-String)
    }
}

function Get-LanguageList {
    $Script:Languages.translation.psobject.Properties | % {
        [PSCustomObject]@{
            Name = $_.Value.Name
            Code = $_.Name
        }
    } | Sort-Object Name
}

function Get-Language {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Text
    )
    
    try {
        $RequestURI = $TranslateAPI.Host + $TranslateAPI.Commands.Detect
        $Content = @(
            @{
                Text = $Text
            }
        )
        $RequestBody = ConvertTo-Json $Content
        
        $Response = Invoke-WebRequest -URI $RequestURI -Body $RequestBody -ContentType 'application/json; charset=utf-8' `
            -Method 'Post' -Headers @{ 'Ocp-Apim-Subscription-Key' = $Global:PSAzureTranslateApiKey }
        $Response.Content | ConvertFrom-Json
    } catch {
        Write-Error ($_ | Out-String)
    }
}

function Get-Translation {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Text,
        
        [string] $From = 'auto',
        
        [string] $To = 'en'
    )
    
    try {
        $Params = "&to=$To"
        if ($From -ine 'auto') { $Params = "&from=$From$Params" }
        $RequestURI = $TranslateAPI.Host + $TranslateAPI.Commands.Translate + $Params
        $Content = @(
            @{
                Text = $Text
            }
        )
        $RequestBody = ConvertTo-Json $Content
        
        $Response = Invoke-WebRequest -URI $RequestURI -Body $RequestBody -ContentType 'application/json; charset=utf-8' `
            -Method 'Post' -Headers @{ 'Ocp-Apim-Subscription-Key' = $Global:PSAzureTranslateApiKey }
        $Response.Content | ConvertFrom-Json
    } catch {
        Write-Error ($_ | Out-String)
    }
}

Initialize-TranslateEnv

Export-ModuleMember -Function Get-LanguageList, Get-Language, Get-Translation
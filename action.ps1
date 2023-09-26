# HelloID-Task-SA-Target-AzureActiveDirectory-AccountUpdateManager
##################################################################
# Form mapping
$formObject = @{
    UserIdentity      = $form.UserIdentity
    userPrincipalName = $form.userPrincipalName
    ManagerIdentity   = $form.ManagerIdentity
}

try {
    Write-Information "Executing AzureActiveDirectory action: [AccountUpdateManager] for: [$($formObject.userPrincipalName)]"
    Write-Information "Retrieving Microsoft Graph AccessToken for tenant: [$AADTenantID]"
    $splatTokenParams = @{
        Uri         = "https://login.microsoftonline.com/$AADTenantID/oauth2/token"
        ContentType = 'application/x-www-form-urlencoded'
        Method      = 'POST'
        Verbose     = $false
        Body        = @{
            grant_type    = 'client_credentials'
            client_id     = $AADAppID
            client_secret = $AADAppSecret
            resource      = 'https://graph.microsoft.com'
        }
    }
    $accessToken = (Invoke-RestMethod @splatTokenParams).access_token

    $splatUpdateManagerParams = @{
        Uri     = "https://graph.microsoft.com/v1.0/users/$($formObject.UserIdentity)/manager/`$ref"
        Method  = 'PUT'
        Body    = @{
            '@odata.id' = "https://graph.microsoft.com/v1.0/users/$($formObject.ManagerIdentity)"
        } | ConvertTo-Json
        Verbose = $false
        Headers = @{
            Authorization  = "Bearer $accessToken"
            Accept         = 'application/json'
            'Content-Type' = 'application/json'
        }
    }
    $null = Invoke-RestMethod @splatUpdateManagerParams
    $auditLog = @{
        Action            = 'UpdateAccount'
        System            = 'AzureActiveDirectory'
        TargetIdentifier  = $formObject.UserIdentity
        TargetDisplayName = $formObject.userPrincipalName
        Message           = "AzureActiveDirectory action: [AccountUpdateManager] for: [$($formObject.userPrincipalName)] executed successfully"
        IsError           = $false
    }
    Write-Information -Tags 'Audit' -MessageData $auditLog
    Write-Information $auditLog.Message
} catch {
    $ex = $_
    $auditLog = @{
        Action            = 'UpdateAccount'
        System            = 'AzureActiveDirectory'
        TargetIdentifier  = $formObject.UserIdentity
        TargetDisplayName = $formObject.userPrincipalName
        Message           = "Could not execute AzureActiveDirectory action: [AccountUpdateManager] for: [$($formObject.userPrincipalName)], error: $($ex.Exception.Message)"
        IsError           = $true
    }
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException')) {
        $auditLog.Message = "Could not execute AzureActiveDirectory action: [AccountUpdateManager] for: [$($formObject.userPrincipalName)], error: error: $($ex.ErrorDetails)"
    }
    Write-Information -Tags 'Audit' -MessageData $auditLog
    Write-Error $auditLog.Message
}
##################################################################

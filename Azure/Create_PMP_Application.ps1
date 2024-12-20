#Import Module
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

# Variable Declaration
$AppName =  "PatchMyPC" # Insert your App Name

Connect-MgGraph -Scopes "Application.Read.All","Application.ReadWrite.All","User.Read.All" -NoWelcome -ForceRefresh

# Check if application exists
$App = Get-MgApplication | Where-Object { $_.DisplayName -eq $AppName}

# If the application exists, stop the script with an error message
if ($App) {
    Write-Output "Error: Application $AppName already exists."
    throw "Script terminated because the application already exists."
}

# Continue with the rest of the script if the application does not exist
Write-Output "Application $AppName does not exist. Proceeding..."

#Create AAD Application
$App = New-MgApplication -DisplayName $AppName
$APPObjectID = $App.Id

# List Created Application
# Get-MgApplication -ApplicationId $APPObjectID

# Add Application Permissions
$paramspermissions = @{
    RequiredResourceAccess = @(
        @{
            ResourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph API
            ResourceAccess = @(
                @{
                    Id = "78145de6-330d-4800-a6ce-494ff2d33d07" # DeviceManagementApps.ReadWrite.All
                    Type = "Role"
                },
                @{
                    Id = "dc377aa6-52d8-4e23-b271-2a7ae04cedf3" # DeviceManagementConfiguration.Read.All
                    Type = "Role"
                },
                @{
                    Id = "2f51be20-0bb4-4fed-bf7b-db946066c75e" # DeviceManagementManagedDevices.Read.All
                    Type = "Role"
                },
                @{
                    Id = "58ca0d9a-1575-47e1-a3cb-007ef2e4583b" # DeviceManagementRBAC.Read.All
                    Type = "Role"
                },
                @{
                    Id = "5ac13192-7ace-4fcf-b828-1a26f28068ee" # DeviceManagementServiceConfig.ReadWrite.All
                    Type = "Role"
                },
                @{
                    Id = "98830695-27a2-44f7-8c18-0c3ebc9698f6" # GroupMember.Read.All
                    Type = "Role"
                }
            )
        }
    )
}

# Update the application with the new permissions
Update-MgApplication -ApplicationId $APPObjectID -BodyParameter $paramspermissions

#Grant Admin Consent - Opens URL in Browser
Start-Sleep -Seconds 10
$App = Get-MgApplication | Where-Object {$_.DisplayName -eq $AppName} 
$TenantID = $App.PublisherDomain
$AppID = $App.AppID
$URL = "https://login.microsoftonline.com/$TenantID/adminconsent?client_id=$AppID"
Start-Process $URL

# Write tenant name to console
$tenantDetails = Get-MgOrganization | Select-Object -ExpandProperty VerifiedDomains
$tenantName = $tenantDetails | Where-Object { $_.IsDefault -eq $true } | Select-Object -ExpandProperty Name
Write-Output "Tenant Name: $tenantName"

Disconnect-MgGraph
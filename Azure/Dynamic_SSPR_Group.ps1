## Variable Declartion Start ##
$clientId = "InsertClientID"
$tenantId = "InsertTenantID"
$thumbprint = "InsertThumbprint"
$groupId = "InsertGroupID" # Replace with the Object ID of your target group

# Insert Enabled Authentication Methods
$authMethodsToCheck = @("#microsoft.graph.microsoftAuthenticatorAuthenticationMethod", 
                        "#microsoft.graph.smsAuthenticationMethod", 
                        "#microsoft.graph.emailAuthenticationMethod")

#Optional UPN Filter
#$UPNs = @("xyz.com",
#          "abc.com")

## Variable Declartion End ##

Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $thumbprint -NoWelcome

# Get all users in Azure AD
$users = Get-MgUser -All -ConsistencyLevel eventual -Property Id,UserPrincipalName
$totalUsers = $users.Count # Total number of users for progress tracking
$currentUser = 0         # Counter for processed users

Write-Output "Getting Users"

# Initialize list for eligible users
$eligibleUsers = @()

Write-Output "Checking Users - Outputting Status in 50 User Increments"

# Iterate through each user and check their authentication methods
foreach ($user in $users) {
    $currentUser++

    if ($currentUser % 50 -eq 0) {
        Write-Output "Checking user $currentUser/$totalUsers"
    }

    $eligible = $true
#Optional UPN Filter
#    foreach ($UPN in $UPNs) {
#        if ($user.UserPrincipalName -like "*$UPN") {
#            $eligible = $false
#            break
#        }
#    }

    if ($eligible) {
        try {
            # Retrieve authentication methods for the user
            $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction SilentlyContinue

            # Extract method types
            $authMethodTypes = $authMethods | ForEach-Object { $_.AdditionalProperties["@odata.type"] }

            # Check if user has at least one of the allowed authentication methods
            $hasAllowedAuthMethod = $false
            foreach ($method in $authMethodTypes) {
                if ($authMethodsToCheck -contains $method) {
                    $hasAllowedAuthMethod = $true
                    break
                }
            }

            # Add user to eligible list only if they have an allowed method
            if ($hasAllowedAuthMethod) {
                $eligibleUsers += $user.Id
            }
        } catch {
            Write-Output "Error processing user $($user.UserPrincipalName): $_"
            continue
        }
    }
}

Write-Output "`nFinished checking users."

# Add eligible users to the group, with progress updates
$totalEligibleUsers = $eligibleUsers.Count # Total number of eligible users
$currentEligibleUser = 0                   # Counter for added eligible users
$newMembersAdded = 0

foreach ($userId in $eligibleUsers) {
    $currentEligibleUser++

    # Update progress on the same line for adding users to the group
    Write-Output -NoNewline "`rAdding eligible user $currentEligibleUser/$totalEligibleUsers to the group"

    try {
        # Check if user is already a member of the group
        $isMember = Get-MgGroupMember -GroupId $groupId -All | Where-Object { $_.Id -eq $userId }

        if (-not $isMember) {
            New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId
            $newMembersAdded++
        }
    } catch {
        Write-Output "Could not add $userId to Group."
        continue
    }
}

Write-Output "`n`n----------------------------------------`n`n"
Write-Output "Process finished - Checked $totalUsers users - $($eligibleUsers.Count) users were eligible - Added $newMembersAdded new members to group"
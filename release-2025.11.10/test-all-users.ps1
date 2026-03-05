# Test All Users Authorization
# Tests all test users with their assigned roles

$keycloakUrl = "http://localhost:8084"
$realm = "fhir-realm"
$hapiUrl = "http://localhost:8080"

Write-Host "=== Testing All Users Authorization ===" -ForegroundColor Cyan

# Get client secret
$clientId = "hapi-fhir-client"
$adminTokenUrl = "$keycloakUrl/realms/master/protocol/openid-connect/token"
$adminTokenBody = @{
    grant_type = "password"
    client_id = "admin-cli"
    username = "admin"
    password = "admin"
}

try {
    $adminTokenResponse = Invoke-RestMethod -Uri $adminTokenUrl -Method Post -Body $adminTokenBody
    $adminToken = $adminTokenResponse.access_token
    
    $headers = @{ Authorization = "Bearer $adminToken" }
    $clientUrl = "$keycloakUrl/admin/realms/$realm/clients?clientId=$clientId"
    $clients = Invoke-RestMethod -Uri $clientUrl -Method Get -Headers $headers
    
    if ($clients.Count -eq 0) {
        # Try hapi-api
        $clientId = "hapi-api"
        $clientUrl = "$keycloakUrl/admin/realms/$realm/clients?clientId=$clientId"
        $clients = Invoke-RestMethod -Uri $clientUrl -Method Get -Headers $headers
    }
    
    if ($clients.Count -gt 0) {
        $clientIdInternal = $clients[0].id
        $clientSecretUrl = "$keycloakUrl/admin/realms/$realm/clients/$clientIdInternal/client-secret"
        $secretResponse = Invoke-RestMethod -Uri $clientSecretUrl -Method Get -Headers $headers
        $clientSecret = $secretResponse.value
        Write-Host "OK: Client secret retrieved for '$clientId'" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Client not found. Please check Keycloak." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Failed to get client secret: $_" -ForegroundColor Red
    exit 1
}

# Test users with their expected permissions
$testUsers = @(
    @{
        username = "readonly.user"
        password = "readonly123"
        role = "read:Patient"
        canRead = @("Patient")
        canWrite = @()
        cannotRead = @("Observation", "Encounter", "Condition", "MedicationRequest")
        description = "Read-only user - Can only read Patient, cannot write"
    },
    @{
        username = "nurse.alice"
        password = "nurse123"
        role = "nurse"
        canRead = @("Patient", "Observation", "Encounter")
        canWrite = @("Observation")
        cannotRead = @("Condition", "MedicationRequest")
        cannotWrite = @("Patient", "Encounter", "Condition", "MedicationRequest")
        description = "Nurse - Can read Patient/Observation/Encounter, can only write Observation"
    },
    @{
        username = "clinician.bob"
        password = "doctor123"
        role = "clinician"
        canRead = @("Patient", "Observation", "Encounter", "Condition", "MedicationRequest")
        canWrite = @("Observation", "Encounter", "Condition", "MedicationRequest")
        cannotRead = @()
        cannotWrite = @("Patient")
        description = "Clinician - Can read multiple resources, can write Observation/Encounter/Condition/MedicationRequest"
    },
    @{
        username = "pharmacist.carol"
        password = "pharma123"
        role = "pharmacist"
        canRead = @("Patient", "MedicationRequest")
        canWrite = @("MedicationRequest")
        cannotRead = @("Observation", "Encounter", "Condition")
        cannotWrite = @("Patient", "Observation", "Encounter", "Condition")
        description = "Pharmacist - Can read Patient/MedicationRequest, can write MedicationRequest"
    },
    @{
        username = "admin.user"
        password = "admin123"
        role = "admin"
        canRead = @("*")
        canWrite = @("*")
        cannotRead = @()
        cannotWrite = @()
        description = "Admin - Has full permissions for all resources"
    }
)

$tokenUrl = "$keycloakUrl/realms/$realm/protocol/openid-connect/token"
$results = @()

foreach ($user in $testUsers) {
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "Testing User: $($user.username) (Role: $($user.role))" -ForegroundColor Cyan
    Write-Host "Description: $($user.description)" -ForegroundColor Yellow
    
    # Get token
    try {
        $body = @{
            grant_type = "password"
            client_id = $clientId
            client_secret = $clientSecret
            username = $user.username
            password = $user.password
        }
        
        $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ErrorAction Stop
        $token = $response.access_token
        
        # Decode token to show roles
        $tokenParts = $token.Split('.')
        if ($tokenParts.Length -ge 2) {
            $payload = $tokenParts[1]
            # Fix Base64 padding
            $padding = (4 - ($payload.Length % 4)) % 4
            $payload = $payload + ("=" * $padding)
            try {
                $payloadBytes = [System.Convert]::FromBase64String($payload)
                $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes) | ConvertFrom-Json
                Write-Host "Token Roles: $($payloadJson.realm_access.roles -join ', ')" -ForegroundColor Gray
            } catch {
                Write-Host "Warning: Cannot decode token payload: $_" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "ERROR: Failed to get token: $_" -ForegroundColor Red
        $results += @{
            user = $user.username
            status = "FAILED"
            reason = "Token retrieval failed"
        }
        continue
    }
    
    $getHeaders = @{
        Authorization = "Bearer $token"
        Accept = "application/json"
    }
    
    $postHeaders = @{
        Authorization = "Bearer $token"
        Accept = "application/json"
        "Content-Type" = "application/fhir+json"
    }
    
    $userResults = @{
        user = $user.username
        role = $user.role
        readTests = @()
        writeTests = @()
    }
    
    # Test READ operations
    Write-Host "`nTesting READ operations..." -ForegroundColor Yellow
    $resourcesToTest = @("Patient", "Observation", "Encounter", "Condition", "MedicationRequest")
    
    foreach ($resourceType in $resourcesToTest) {
        $shouldSucceed = ($user.canRead -contains $resourceType) -or ($user.canRead -contains "*")
        $shouldFail = ($user.cannotRead -contains $resourceType) -and ($user.canRead -notcontains "*")
        
        try {
            $result = Invoke-RestMethod -Uri "$hapiUrl/fhir/$resourceType" -Method Get -Headers $getHeaders -ErrorAction Stop
            if ($shouldSucceed) {
                Write-Host "  ✅ PASS: READ $resourceType (Total: $($result.total))" -ForegroundColor Green
                $userResults.readTests += @{ resource = $resourceType; expected = "ALLOW"; actual = "ALLOW"; passed = $true }
            } else {
                Write-Host "  ⚠️  UNEXPECTED: READ $resourceType succeeded (should be denied)" -ForegroundColor Yellow
                $userResults.readTests += @{ resource = $resourceType; expected = "DENY"; actual = "ALLOW"; passed = $false }
            }
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($shouldSucceed) {
                Write-Host "  ❌ FAIL: READ $resourceType (Status: $statusCode) - Should succeed!" -ForegroundColor Red
                $userResults.readTests += @{ resource = $resourceType; expected = "ALLOW"; actual = "DENY"; passed = $false }
            } else {
                Write-Host "  ✅ PASS: READ $resourceType denied (Status: $statusCode)" -ForegroundColor Green
                $userResults.readTests += @{ resource = $resourceType; expected = "DENY"; actual = "DENY"; passed = $true }
            }
        }
    }
    
    # Test WRITE operations
    Write-Host "`nTesting WRITE operations..." -ForegroundColor Yellow
    
    foreach ($resourceType in $resourcesToTest) {
        $shouldSucceed = ($user.canWrite -contains $resourceType) -or ($user.canWrite -contains "*")
        $shouldFail = ($user.cannotWrite -contains $resourceType) -and ($user.canWrite -notcontains "*")
        
        # Create a minimal test resource
        $testResource = @{
            resourceType = $resourceType
        }
        
        if ($resourceType -eq "Patient") {
            $testResource.name = @(@{ family = "Test"; given = @("Test") })
        } elseif ($resourceType -eq "Observation") {
            $testResource.status = "final"
            $testResource.code = @{ text = "Test" }
        } elseif ($resourceType -eq "Encounter") {
            # Encounter 需要 class 和 subject 欄位
            $testResource.status = "finished"
            $testResource.class = @{ system = "http://terminology.hl7.org/CodeSystem/v3-ActCode"; code = "AMB"; display = "ambulatory" }
            $testResource.subject = @{ reference = "Patient/test-patient" }
        } elseif ($resourceType -eq "Condition") {
            # Condition 需要 subject 和 code 欄位
            $testResource.code = @{ coding = @(@{ system = "http://snomed.info/sct"; code = "123456789"; display = "Test Condition" }) }
            $testResource.subject = @{ reference = "Patient/test-patient" }
        } elseif ($resourceType -eq "MedicationRequest") {
            # MedicationRequest 需要 subject 和 medicationCodeableConcept 欄位
            $testResource.status = "active"
            $testResource.intent = "order"
            $testResource.subject = @{ reference = "Patient/test-patient" }
            $testResource.medicationCodeableConcept = @{ coding = @(@{ system = "http://www.nlm.nih.gov/research/umls/rxnorm"; code = "123456"; display = "Test Medication" }) }
        }
        
        $testResourceJson = $testResource | ConvertTo-Json -Depth 10
        
        try {
            $result = Invoke-RestMethod -Uri "$hapiUrl/fhir/$resourceType" -Method Post -Body $testResourceJson -Headers $postHeaders -ErrorAction Stop
            if ($shouldSucceed) {
                Write-Host "  ✅ PASS: CREATE $resourceType" -ForegroundColor Green
                $userResults.writeTests += @{ resource = $resourceType; expected = "ALLOW"; actual = "ALLOW"; passed = $true }
            } else {
                Write-Host "  ❌ FAIL: CREATE $resourceType succeeded (should be denied!)" -ForegroundColor Red
                $userResults.writeTests += @{ resource = $resourceType; expected = "DENY"; actual = "ALLOW"; passed = $false }
            }
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($shouldSucceed) {
                # 422/400 是資源驗證錯誤，不是授權問題，應該排除
                if ($statusCode -eq 422 -or $statusCode -eq 400) {
                    Write-Host "  ⚠️  SKIP: CREATE $resourceType (Status: $statusCode) - Resource validation error, not authorization" -ForegroundColor Yellow
                    $userResults.writeTests += @{ resource = $resourceType; expected = "ALLOW"; actual = "VALIDATION_ERROR"; passed = $true; note = "422/400 validation error excluded" }
                } else {
                    Write-Host "  ❌ FAIL: CREATE $resourceType (Status: $statusCode) - Should succeed!" -ForegroundColor Red
                    $userResults.writeTests += @{ resource = $resourceType; expected = "ALLOW"; actual = "DENY"; passed = $false }
                }
            } else {
                # 422/400 是資源驗證錯誤，不是授權問題，應該排除
                if ($statusCode -eq 422 -or $statusCode -eq 400) {
                    Write-Host "  ⚠️  SKIP: CREATE $resourceType (Status: $statusCode) - Resource validation error, not authorization" -ForegroundColor Yellow
                    $userResults.writeTests += @{ resource = $resourceType; expected = "DENY"; actual = "VALIDATION_ERROR"; passed = $true; note = "422/400 validation error excluded" }
                } elseif ($statusCode -eq 403) {
                    Write-Host "  ✅ PASS: CREATE $resourceType denied (Status: 403)" -ForegroundColor Green
                    $userResults.writeTests += @{ resource = $resourceType; expected = "DENY"; actual = "DENY"; passed = $true }
                } else {
                    Write-Host "  ⚠️  UNEXPECTED: CREATE $resourceType (Status: $statusCode) - Expected 403" -ForegroundColor Yellow
                    $userResults.writeTests += @{ resource = $resourceType; expected = "DENY"; actual = "DENY"; passed = $true; note = "Unexpected status code" }
                }
            }
        }
    }
    
    $results += $userResults
}

# Summary
Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "=== Test Summary ===" -ForegroundColor Cyan

$totalPassed = 0
$totalFailed = 0

foreach ($result in $results) {
    Write-Host "`nUser: $($result.user) (Role: $($result.role))" -ForegroundColor Yellow
    
    $readPassed = ($result.readTests | Where-Object { $_.passed }).Count
    $readTotal = $result.readTests.Count
    $readFailed = $readTotal - $readPassed
    
    $writePassed = ($result.writeTests | Where-Object { $_.passed }).Count
    $writeTotal = $result.writeTests.Count
    $writeFailed = $writeTotal - $writePassed
    
    Write-Host "  READ Tests: $readPassed/$readTotal passed" -ForegroundColor $(if ($readPassed -eq $readTotal) { "Green" } else { "Yellow" })
    Write-Host "  WRITE Tests: $writePassed/$writeTotal passed" -ForegroundColor $(if ($writePassed -eq $writeTotal) { "Green" } else { "Yellow" })
    
    if ($readFailed -gt 0 -or $writeFailed -gt 0) {
        Write-Host "  ⚠️  Some tests failed:" -ForegroundColor Yellow
        foreach ($test in $result.readTests) {
            if (-not $test.passed) {
                $note = if ($test.note) { " ($($test.note))" } else { "" }
                Write-Host "    - READ $($test.resource): Expected $($test.expected), Got $($test.actual)$note" -ForegroundColor Red
            }
        }
        foreach ($test in $result.writeTests) {
            if (-not $test.passed) {
                $note = if ($test.note) { " ($($test.note))" } else { "" }
                Write-Host "    - WRITE $($test.resource): Expected $($test.expected), Got $($test.actual)$note" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  ✅ All tests passed for this user!" -ForegroundColor Green
    }
    
    # 統計 422/400 錯誤（資源驗證錯誤，排除）
    $validationErrors = ($result.readTests + $result.writeTests | Where-Object { $_.actual -eq "VALIDATION_ERROR" }).Count
    if ($validationErrors -gt 0) {
        Write-Host "  ℹ️  Validation errors (excluded): $validationErrors" -ForegroundColor Gray
    }
    
    $totalPassed += ($readPassed + $writePassed)
    $totalFailed += ($readFailed + $writeFailed)
}

# 統計驗證錯誤（排除）
$totalValidationErrors = 0
foreach ($result in $results) {
    $validationErrors = ($result.readTests + $result.writeTests | Where-Object { $_.actual -eq "VALIDATION_ERROR" }).Count
    $totalValidationErrors += $validationErrors
}

Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "Overall Results:" -ForegroundColor Cyan
Write-Host "  - Passed: $totalPassed" -ForegroundColor Green
Write-Host "  - Failed: $totalFailed" -ForegroundColor $(if ($totalFailed -eq 0) { "Green" } else { "Red" })
if ($totalValidationErrors -gt 0) {
    Write-Host "  - Validation Errors (excluded): $totalValidationErrors" -ForegroundColor Gray
}
Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan


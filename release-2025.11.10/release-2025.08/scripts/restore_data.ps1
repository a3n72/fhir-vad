param(
  [string]$HapiSql = "hapi_data.sql",
  [string]$KcSql   = "keycloak_data.sql"
)

Get-Content ".env" | Where-Object { $_ -match "=" -and $_ -notmatch "^\s*#" } `
  | ForEach-Object {
      $kv = $_ -split "=",2
      Set-Item -Path ("env:{0}" -f $kv[0].Trim()) -Value ($kv[1].Trim('" '))
    }

$pgHapiId = (docker compose ps -q pg-hapi)
$pgKcId   = (docker compose ps -q pg-keycloak)

Write-Host "Restore HAPI from $HapiSql ..."
Get-Content $HapiSql | docker exec -i $pgHapiId psql -U $env:PG_HAPI_USER -d $env:PG_HAPI_DB

Write-Host "Restore Keycloak from $KcSql ..."
Get-Content $KcSql | docker exec -i $pgKcId   psql -U $env:PG_KC_USER -d $env:PG_KC_DB

Write-Host "Done."

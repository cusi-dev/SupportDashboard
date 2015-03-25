#Get Environment Specific Values
$dashboardURL = [Environment]::GetEnvironmentVariable("DASHBOARD_URL","Machine")
$authToken = [Environment]::GetEnvironmentVariable("DASHBOARD_AUTH_TOKEN","Machine")

$url = "$($dashboardURL)/dashboards/*"

$body = "{
    ""auth_token"" : ""$($authToken)"",
    ""event"" : ""reload""
}"

#Invoke-RestMethod -Method Post -Uri $url -Body $body -DisableKeepAlive
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

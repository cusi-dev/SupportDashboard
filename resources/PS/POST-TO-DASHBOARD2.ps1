﻿#Get Environment Specific Values
$dashboardURL = [Environment]::GetEnvironmentVariable("DASHBOARD_URL","Machine")
$authToken = [Environment]::GetEnvironmentVariable("DASHBOARD_AUTH_TOKEN","Machine")
$SqlInstance = [Environment]::GetEnvironmentVariable("DASHBOARD_SQL_INSTANCE","Machine")
$DatabaseName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_NAME","Machine")
$SqlUserName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_USERNAME","Machine")
$SqlPassword = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_PASSWORD","Machine")

#Build the SQL Server Connection String
$connStr = "Server=$($SqlInstance);Initial Catalog=$($DatabaseName);User Id=$($SqlUserName);Password=$($SqlPassword);"

$Date = Get-Date -Format d
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportMetrics] @i_Today = '$Date', @i_Period='DAY'"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

$fpStuff = $DataSet.Tables[0].Select("GroupName='ALL'")

$sla60 = $fpStuff.SLA60
$url = "$($dashboardURL)/widgets/sla60"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $sla60
}"

Invoke-RestMethod -Method Post -Uri $url -Body $json -DisableKeepAlive


$art = $fpStuff.AverageResponseTime
$url = "$($dashboardURL)/widgets/averageresponsetime"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $art
}"

Invoke-RestMethod -Method Post -Uri $url -Body $json -DisableKeepAlive
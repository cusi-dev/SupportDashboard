#Get Environment Specific Values
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

$umstickets = $DataSet.Tables[0].Select("GroupName='UMS'")
$sla30 = $umstickets.SLA30
$sla60 = $umstickets.SLA60
$sla61 = $umstickets.SLA61

$url = "$($dashboardURL)/widgets/umsopentickets"
$tester = "[
  {
    ""label"" : ""Under 30"",
    ""value"" : ""$sla30""
  },
  {
    ""label"" : ""Under 60"",
    ""value"" : ""$sla60""
  },
  {
    ""label"" : ""Over 60!"",
    ""value"" : ""$sla61""
  }
]"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""items"" : $tester
}"

Invoke-RestMethod -Method Post -Uri $url -Body $json -DisableKeepAlive

$cbswtickets = $DataSet.Tables[0].Select("GroupName='CBSW'")
$csla30 = $cbswtickets.SLA30
$csla60 = $cbswtickets.SLA60
$csla61 = $cbswtickets.SLA61

$url2 = "$($dashboardURL)/widgets/cbswopentickets"
$array = "[
  {
    ""label"" : ""Under 30"",
    ""value"" : ""$csla30""
  },
  {
    ""label"" : ""Under 60"",
    ""value"" : ""$csla60""
  },
  {
    ""label"" : ""Over 60!"",
    ""value"" : ""$csla61""
  }
]"

$json2 = "{
    ""auth_token"" : ""$($authToken)"",
    ""items"" : $array
}"

Invoke-RestMethod -Method Post -Uri $url2 -Body $json2 -DisableKeepAlive



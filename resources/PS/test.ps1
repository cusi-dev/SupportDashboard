#Get Environment Specific Values
$dashboardURL = [Environment]::GetEnvironmentVariable("DASHBOARD_URL","Machine")
$authToken = [Environment]::GetEnvironmentVariable("DASHBOARD_AUTH_TOKEN","Machine")
$SqlInstance = [Environment]::GetEnvironmentVariable("DASHBOARD_SQL_INSTANCE","Machine")
$DatabaseName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_NAME","Machine")
$SqlUserName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_USERNAME","Machine")
$SqlPassword = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_PASSWORD","Machine")

#Build the SQL Server Connection String
$connStr = "Server=$($SqlInstance);Initial Catalog=$($DatabaseName);User Id=$($SqlUserName);Password=$($SqlPassword);"

#Query 
$Date = Get-Date -Format d
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportAgentMetrics] @i_Today = '$Date'"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$rows = $DataSet.Tables[0].Rows
#$cols = $DataSet.Tables[0].Columns

#
#widget
#
$pb1max = 0
foreach ($row in $rows)
{
#    Write-Host $row[2]
    if ($row[2] -gt $pb1max)
    {
        $pb1max = $row[2]
    }
}
#write-host $pb1max

$pb1Count = $rows.Count

$i = 0
$pb1 = "["
foreach ($row in $rows)
{
    $i += 1
    $val = [math]::round(($row[2]/$pb1max)*100)
    #Write-Host $row[0]
    $pb1 += 
    "
        {
          ""name"" : ""$($row[0])"",
          ""progress"" : $($val)
        }
    "
    if ($i -lt $pb1Count)
    {
        $pb1 += ","
    }
}
$pb1 += "]"
$url = "$($dashboardURL)/widgets/cusi_progress_bars"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""progress_items"" : $pb1
}"
#Write-Host $url
#Write-Host $json

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json



#
#widget
#
$pb2 = "[
    [
        ""Agent"",""Resolved"",""Assigned""
    ],
"
$i = 0
foreach ($row in $rows)
{
    $i += 1
    $pb2 += "
        [ 
            ""$($row[0])"",$($row[2]),$($row[5]) 
        ]
    "
    if ($i -lt $rows.Count)
    {
        $pb2 += ","
    }
}
$pb2 += "]"
$url = "$($dashboardURL)/widgets/mychart"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""points"" : $pb2
}"
#Write-Host $url
Write-Host $json

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

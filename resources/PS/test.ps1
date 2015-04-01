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


###########################################################################

#$SqlCmd.CommandText = "exec [cusip_SupportAgentMetrics] @i_Today = '2015-03-27'"#'$Date'"
$SqlCmd.CommandText = "exec [cusip_SupportAgentMetrics] @i_Today = '$Date'"

###########################################################################


$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$rows = $DataSet.Tables[0].Rows


#
#contracted widget
#
$i = 0
$pb1 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb1 += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[12])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb1 += ","
    }
}
$pb1 += "]"
$url1 = "$($dashboardURL)/widgets/contracted"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb1
}"

(Invoke-WebRequest -Uri $url1 -Method Post -Body $json).content | ConvertFrom-Json


#
#pending widget
#
$i = 0
$pb2 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb2 += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[8])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb2 += ","
    }
}
$pb2 += "]"
$url2 = "$($dashboardURL)/widgets/pending"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb2
}"

(Invoke-WebRequest -Uri $url2 -Method Post -Body $json).content | ConvertFrom-Json


#pie resolved widget
$i = 0
$pb3 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb3 += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[2])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb3 += ","
    }
}
$pb3 += "]"
$url3 = "$($dashboardURL)/widgets/resolved"
$json3 = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb3
}"

(Invoke-WebRequest -Uri $url3 -Method Post -Body $json3).content | ConvertFrom-Json

#pie assigned widget
$i = 0
$pb4 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb4 += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[4])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb4 += ","
    }
}
$pb4 += "]"

$url = "$($dashboardURL)/widgets/assigned"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb4
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

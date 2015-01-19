#Get Environment Specific Values
$dashboardURL = [Environment]::GetEnvironmentVariable("DASHBOARD_URL","Machine")
$authToken = [Environment]::GetEnvironmentVariable("DASHBOARD_AUTH_TOKEN","Machine")
$SqlInstance = [Environment]::GetEnvironmentVariable("DASHBOARD_SQL_INSTANCE","Machine")
$DatabaseName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_NAME","Machine")
$SqlUserName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_USERNAME","Machine")
$SqlPassword = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_PASSWORD","Machine")

#Build the SQL Server Connection String
$connStr = "Server=$($SqlInstance);Initial Catalog=$($DatabaseName);User Id=$($SqlUserName);Password=$($SqlPassword);"

$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_ActiveTicketsTracking]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)

$url = "$($dashboardURL)/widgets/history"
$jArray = "["
$counter = $DataSet.Tables[0].Rows.Count - 1
for ($i=1; $i -lt $DataSet.Tables[0].Rows.Count; $i++)
{
    $jArray += "
    {
        ""x"" : $i,
        ""y"" : $($DataSet.Tables[0].Rows[$counter][0])
    }"
    $counter--

    if($i -ne $DataSet.Tables[0].Rows.Count - 1)
    {
        $jArray += ","
    }
}

$jArray += "]"

$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""points"" : $jArray
}"

Invoke-RestMethod -Method Post -Uri $url -Body $json -DisableKeepAlive

$SqlUpdateCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlUpdateCmd.CommandText = "INSERT INTO [tblCusiMetricsActiveTickets] (ActiveTickets, DateCaptured) VALUES ($($DataSet.Tables[1].Rows[0][0]), '$Date')"
$SqlUpdateCmd.Connection = $conn
$SqlUpdateCmd.ExecuteNonQuery()
$conn.Close()

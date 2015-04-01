#Get Environment Specific Values
$dashboardURL = [Environment]::GetEnvironmentVariable("DASHBOARD_URL","Machine")
$authToken = [Environment]::GetEnvironmentVariable("DASHBOARD_AUTH_TOKEN","Machine")
$SqlInstance = [Environment]::GetEnvironmentVariable("DASHBOARD_SQL_INSTANCE","Machine")
$DatabaseName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_NAME","Machine")
$SqlUserName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_USERNAME","Machine")
$SqlPassword = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_PASSWORD","Machine")

#Build the SQL Server Connection String
$connStr = "Server=$($SqlInstance);Initial Catalog=$($DatabaseName);User Id=$($SqlUserName);Password=$($SqlPassword);"

#Query cusip_SupportMetrics
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

#Assign results
$AllTickets = $DataSet.Tables[0].Select("GroupName='ALL'")
$UMSTickets = $DataSet.Tables[0].Select("GroupName='UMS'")
$CBSWTickets = $DataSet.Tables[0].Select("GroupName='CBSW'")

#
#SLA Under 30 widget
#
$sla30c = $CBSWTickets.SLA30
$sla30u = $UMSTickets.SLA30
$sla30 = "[
  {
    ""label"" : ""CBSW"",
    ""value"" : $sla30c
  },
  {
    ""label"" : ""UMS"",
    ""value"" : $sla30u
  }
]"
$url = "$($dashboardURL)/widgets/sla30"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $sla30
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#SLA Under 60 widget
#
$sla60c = $CBSWTickets.SLA60
$sla60u = $UMSTickets.SLA60
$sla60 = "[
  {
    ""label"" : ""CBSW"",
    ""value"" : $sla60c
  },
  {
    ""label"" : ""UMS"",
    ""value"" : $sla60u
  }
]"
$url = "$($dashboardURL)/widgets/sla60"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $sla60
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#SLA Over 60 widget
#
$sla61c = $CBSWTickets.SLA61
$sla61u = $UMSTickets.SLA61
$sla61 = "[
  {
    ""label"" : ""CBSW"",
    ""value"" : $sla61c
  },
  {
    ""label"" : ""UMS"",
    ""value"" : $sla61u
  }
]"
$url = "$($dashboardURL)/widgets/sla90"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $sla61
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#UMS tickets widget
#
$url = "$($dashboardURL)/widgets/umsopentickets"
$ums = "[
  {
    ""label"" : ""< 30"",
    ""value"" : $sla30u
  },
  {
    ""label"" : ""< 60"",
    ""value"" : $sla60u
  },
  {
    ""label"" : ""60+"",
    ""value"" : $sla61u
  }
]"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $ums
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#CBSW tickets widget
#
$url = "$($dashboardURL)/widgets/cbswopentickets"
$cbsw = "[
  {
    ""label"" : ""< 30"",
    ""value"" : $sla30c
  },
  {
    ""label"" : ""< 60"",
    ""value"" : $sla60c
  },
  {
    ""label"" : ""60+"",
    ""value"" : $sla61c
  }
]"

$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $cbsw
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Inbound tickets widget
#
$inb = $AllTickets.InboundTickets
$closed = $AllTickets.ClosedTickets
$noninb = $closed - $inb
$url = "$($dashboardURL)/widgets/inbound"
$points = "[
    {
        ""label"" : ""Inbound"",
        ""value"" : $inb
    },
    {
        ""label"" : ""Non"",
        ""value"" : $noninb
    }
]"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $points
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Response time widget
#
$art = $AllTickets.AverageResponseTime
$url = "$($dashboardURL)/widgets/averageresponsetime"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $art
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#New tickets today widget
#
$newtickets = $AllTickets.NewTickets
$url = "$($dashboardURL)/widgets/newtickets"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""current"" : $newtickets
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Wait time widget
#
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportResponseTime]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet) | Out-Null
$conn.Close()

$waittime = $DataSet.Tables[0].Rows[0][0]
$url = "$($dashboardURL)/widgets/waittime"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : ""$waittime""
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Active tickets today widget
#
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_ActiveTickets]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

$active = $DataSet.Tables[0].Rows[0][0]
$url = "$($dashboardURL)/widgets/active"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : ""$active""
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Open tickets widget
#
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_UnhandledTickets]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

$unhandled = $DataSet.Tables[0].Rows[0][0]
$url = "$($dashboardURL)/widgets/unhandled"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : ""$unhandled""
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

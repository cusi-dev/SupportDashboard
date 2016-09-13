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
#SLA Under 30 data
#
$sla30c = $CBSWTickets.SLA30
$sla30u = $UMSTickets.SLA30

#
#SLA Under 60 data
#
$sla60c = $CBSWTickets.SLA60
$sla60u = $UMSTickets.SLA60

#
#SLA Over 60 data
#
$sla61c = $CBSWTickets.SLA61
$sla61u = $UMSTickets.SLA61

#
#Inbound tickets data
#
$inb = $AllTickets.InboundTickets
$closed = $AllTickets.NewTickets
$noninb = $closed - $inb

#
#Chat tickets data
#
$ct = $AllTickets.ChatTickets
$ctn = $closed - $ct

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

$url = "http://10.10.1.132:8080/responsetime"
Invoke-WebRequest -Uri $url -Method Put -Body $art

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

$url = "http://10.10.1.132:8080/newticketstoday"
Invoke-WebRequest -Uri $url -Method Put -Body $newtickets

#
# SLA and Response Detail widgets
#

# SLA aggregate data
$val30 = $sla30c + $sla30u
$val60 = $sla60c + $sla60u
$val61 = $sla61c + $sla61u

$lbl30 = If ($val30 -eq 0){""}else{$val30}
$lbl60 = If ($val60 -eq 0){""}else{$val60}
$lbl61 = If ($val61 -eq 0){""}else{$val61}

# Response Detail data
$val30c = $sla30c
$val30u = $sla30u
$val60c = $sla60c
$val60u = $sla60u
$val61c = $sla61c
$val61u = $sla61u
$vali = $inb
$valn = $noninb
$valct = $ct
$valctn = $ctn

$lbl30c = If ($val30c -eq 0){""}else{$val30c}
$lbl30u = If ($val30u -eq 0){""}else{$val30u}
$lbl60c = If ($val60c -eq 0){""}else{$val60c}
$lbl60u = If ($val60u -eq 0){""}else{$val60u}
$lbl61c = If ($val61c -eq 0){""}else{$val61c}
$lbl61u = If ($val61u -eq 0){""}else{$val61u}

$lbli = If ($vali -eq 0 -and $valn -eq 0){""}else{$vali}
$lbln = If ($valn -eq 0 -and $vali -eq 0){""}else{$valn}
$lblct = If ($valct -eq 0 -and $valctn -eq 0){""}else{$valct}
$lblctn = If ($valctn -eq 0 -and $valct -eq 0){""}else{$valctn}

$normal = $valn - $valct

# SLA widget
$d = "
[
    [""Level"",""30"",{""role"": ""tooltip""},{""role"": ""annotation""},""60"",{""role"": ""tooltip""},{""role"": ""annotation""},""60+"",{""role"": ""tooltip""},{""role"": ""annotation""}],
    [""All Tickets"",$val30,""SLA30"",""$lbl30"",$val60,""SLA60"",""$lbl60"",$val61,""Over 60"",""$lbl61""],
    [""CBSW"",$val30c,""SLA30"",""$lbl30c"",$val60c,""SLA60"",""$lbl60c"",$val61c,""Over 60"",""$lbl61c""],
    [""UMS"",$val30u,""SLA30"",""$lbl30u"",$val60u,""SLA60"",""$lbl60u"",$val61u,""Over 60"",""$lbl61u""]
]"

$url = "$($dashboardURL)/widgets/slastack1"
$json = "{
    ""auth_token"" : ""$($authToken)"",

    ""points"" : $d
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

# Response widget
$d = "
[
    [""Group"",""Chat"" ,{""role"": ""tooltip""},{""role"": ""annotation""},""Inbound"" ,{""role"": ""tooltip""},{""role"": ""annotation""},""Normal"",{""role"": ""tooltip""},{""role"": ""annotation""}],
    [""Response Type"",$valct,""Chat"",""$lblct"",$vali,""Inbound"",""$lbli"",$normal,""Normal"",""$normal""]
]"

$url = "$($dashboardURL)/widgets/slastack2"
$json = "{
    ""auth_token"" : ""$($authToken)"",

    ""points"" : $d
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Wait time widget
#
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportWaitTime]"
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

$url = "http://10.10.1.132:8080/waittime"
Invoke-WebRequest -Uri $url -Method Put -Body $waittime

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


#
# AGENT DASHBOARD
#

#Query 
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


#
# PENDING
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


#
# RESOLVED
#
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

$i = 0
$pb3c = "["
foreach ($row in $rows)
{
    $i += 1
    $pb3c += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[4])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb3c += ","
    }
}
$pb3c += "]"
$url3c = "$($dashboardURL)/widgets/resolvedc"
$json3c = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb3c
}"

(Invoke-WebRequest -Uri $url3c -Method Post -Body $json3c).content | ConvertFrom-Json

$i = 0
$pb3u = "["
foreach ($row in $rows)
{
    $i += 1
    $pb3u += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[3])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb3u += ","
    }
}
$pb3u += "]"
$url3u = "$($dashboardURL)/widgets/resolvedu"
$json3u = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb3u
}"

(Invoke-WebRequest -Uri $url3u -Method Post -Body $json3u).content | ConvertFrom-Json

#
# ASSIGNED
#
$i = 0
$pb4 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb4 += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[5])
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

#
# Escalations
#
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportAgentEscalations]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$rows = $DataSet.Tables[0].Rows

$i = 0
$pb3h3 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb3h3 += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[1])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb3h3 += ","
    }
}
$pb3h3 += "]"

$url3 = "$($dashboardURL)/widgets/escalatedtable"
$json3 = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb3h3
}"

(Invoke-WebRequest -Uri $url3 -Method Post -Body $json3).content | ConvertFrom-Json

#
# Top callers
#
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_TopCallers]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$rows = $DataSet.Tables[0].Rows

$i = 0
$tcth = "
[ 
    {""cols"" : 
        [ 
            {""class"" : ""topcallerstablehdr1"", ""value"" : ""Company""},
            {""class"" : ""topcallerstablehdr2"", ""value"" : ""Tickets""} 
        ] 
    }
]
"
$tctr = "["
foreach ($row in $rows)
{
    $i += 1
    $tctr += "
        { ""cols"" : 
            [
                {""class"" : ""topcallerstablecol1"", ""value"" : ""$($row[0])""}, 
                {""class"" : ""topcallerstablecol2"", ""value"" : ""$($row[1])""}
            ]
        }
    "
    if ($i -lt $rows.Count)
    {
        $tctr += ","
    }
}
$tctr += "]"

$url3 = "$($dashboardURL)/widgets/topcallerstable"
$json3 = "{
    ""auth_token"" : ""$($authToken)"",
    ""hrows"" : $tcth,
    ""rows""  : $tctr
}"

(Invoke-WebRequest -Uri $url3 -Method Post -Body $json3).content | ConvertFrom-Json

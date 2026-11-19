#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$WebUrl = 'http://127.0.0.1:8081',
    [string]$ServerHost = '127.0.0.1',
    [int]$ServerPort = 10051
)

$web = Invoke-WebRequest -Uri $WebUrl -UseBasicParsing -TimeoutSec 15
if ($web.StatusCode -ne 200) {
    throw "Zabbix web returned HTTP $($web.StatusCode)."
}

$server = Test-NetConnection -ComputerName $ServerHost -Port $ServerPort -WarningAction SilentlyContinue
if (-not $server.TcpTestSucceeded) {
    throw "Zabbix server is not reachable at ${ServerHost}:$ServerPort."
}

Write-Host "Zabbix web and server port are reachable: $WebUrl, ${ServerHost}:$ServerPort" -ForegroundColor Green


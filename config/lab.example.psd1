@{
    DomainName          = 'corp.lab'
    NetBIOSName         = 'CORP'
    DomainController    = 'DC01'
    DomainControllerIp  = '192.168.56.10'
    PrefixLength        = 24
    LabGateway          = '192.168.56.1'
    DnsForwarders       = @('1.1.1.1', '8.8.8.8')

    HyperVSwitch        = 'Windows-AD-Lab'
    NatName             = 'Windows-AD-Lab-NAT'
    LabSubnet           = '192.168.56.0/24'

    DhcpScopeName       = 'CORP-LAB'
    DhcpScopeStart      = '192.168.56.100'
    DhcpScopeEnd        = '192.168.56.199'
    DhcpSubnetMask      = '255.255.255.0'

    OrganizationalUnits = @('Users', 'Computers', 'Servers', 'Groups', 'Service Accounts')
    SecurityGroups       = @('GG-IT-Admins', 'GG-Helpdesk', 'GG-Employees', 'GG-Shared-Read', 'GG-Shared-Modify')

    LabUsers = @(
        @{
            SamAccountName = 'lab.user'
            DisplayName    = 'Lab User'
            Department     = 'Operations'
            Groups          = @('GG-Employees', 'GG-Shared-Read')
        },
        @{
            SamAccountName = 'lab.helpdesk'
            DisplayName    = 'Lab Helpdesk'
            Department     = 'IT'
            Groups          = @('GG-Helpdesk', 'GG-Shared-Modify')
        }
    )

    ShareName            = 'Company'
    SharePath            = 'C:\Shares\Company'
    ZabbixServer          = '192.168.56.1'
}


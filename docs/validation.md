# Проверки и ожидаемые результаты

| Проверка | Команда | Ожидаемый результат |
|---|---|---|
| Поиск контроллера | `nltest /dsgetdc:corp.lab` | Найден DC01 |
| DNS A-запись | `Resolve-DnsName dc01.corp.lab` | `192.168.56.10` |
| LDAP | `Test-NetConnection 192.168.56.10 -Port 389` | `TcpTestSucceeded=True` |
| SMB | `Test-NetConnection 192.168.56.10 -Port 445` | `TcpTestSucceeded=True` |
| DHCP | `ipconfig /all` | Адрес из диапазона `.100-.199`, DNS `.10` |
| Домен | `whoami` | `corp\\lab.user` |
| GPO | `gpresult /r` | `CORP - Workstation Baseline` |
| Share read | открыть `\\DC01\Company` как lab.user | Чтение разрешено |
| Share modify | создать файл как lab.helpdesk | Изменение разрешено |
| Zabbix web | `Invoke-WebRequest http://127.0.0.1:8081` | HTTP 200 |
| Zabbix agent | `Get-Service 'Zabbix Agent 2'` | Running |

Сохраните вывод команд в заметки и объясните причину каждой проверки. Цель лаборатории — понимать зависимость DNS, Kerberos, LDAP, SMB, DHCP и GPO, а не просто получить зелёные строки.


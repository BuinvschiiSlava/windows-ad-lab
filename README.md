# Windows AD Lab

[![validate](https://github.com/BuinvschiiSlava/windows-ad-lab/actions/workflows/validate.yml/badge.svg)](https://github.com/BuinvschiiSlava/windows-ad-lab/actions/workflows/validate.yml)

Воспроизводимая лаборатория системного администратора: Hyper-V, Windows Server, Active Directory, DNS, DHCP, GPO, файловые права, доменный клиент и мониторинг Zabbix.

Проект предназначен для безопасной практики в изолированных виртуальных машинах. Он не является готовой конфигурацией производственного домена.

## Что строится

```text
Windows 10/11 host
└── Hyper-V internal switch + NAT      192.168.56.0/24
    ├── DC01                           192.168.56.10
    │   ├── Active Directory           corp.lab
    │   ├── DNS + DHCP
    │   ├── GPO
    │   └── SMB share
    └── CLIENT01                       DHCP
        ├── domain join
        ├── users and groups
        └── Zabbix Agent 2

Docker Desktop on host
└── Zabbix Server + Web + PostgreSQL   localhost:8081
```

## Чему учит стенд

- создавать изолированную сеть Hyper-V и NAT;
- готовить Windows Server к роли контроллера домена;
- разворачивать новый лес AD DS и интегрированный DNS;
- создавать OU, пользователей и группы по принципу RBAC;
- выдавать доступ к SMB-ресурсу через группы, а не отдельным пользователям;
- настраивать DHCP scope и DNS-параметры клиентов;
- создавать и привязывать базовую GPO;
- присоединять Windows-клиент к домену;
- проверять DNS, LDAP и SMB диагностическими командами;
- запускать Zabbix с PostgreSQL и подключать Windows Agent 2;
- проверять PowerShell и Compose в GitHub Actions.

## Безопасная последовательность

### 1. Подготовка

Нужны Windows 10/11 Pro, Hyper-V, 12 GB RAM, около 80 GB свободного места, Docker Desktop и установочные ISO Windows Server/Windows 10 или 11.

```powershell
Copy-Item .\config\lab.example.psd1 .\config\lab.psd1
.\scripts\host\Test-LabPrerequisites.ps1
```

Отредактируйте `config/lab.psd1`, если подсеть `192.168.56.0/24` уже используется.

### 2. Сеть и виртуальные машины

Сначала посмотрите план без изменений:

```powershell
.\scripts\host\Start-LabBootstrap.ps1 `
  -ServerIsoPath C:\ISO\WindowsServer.iso `
  -ClientIsoPath C:\ISO\Windows11.iso `
  -WhatIf
```

Затем запустите ту же команду из PowerShell от администратора без `-WhatIf`:

```powershell
.\scripts\host\Start-LabBootstrap.ps1 `
  -ServerIsoPath C:\ISO\WindowsServer.iso `
  -ClientIsoPath C:\ISO\Windows11.iso
```

Установите операционные системы вручную и создайте checkpoints до настройки ролей.

### 3. Контроллер домена

Скопируйте репозиторий или папки `config` и `scripts` в `DC01`.

```powershell
.\scripts\dc\10-PrepareDomainController.ps1 -WhatIf
.\scripts\dc\10-PrepareDomainController.ps1 -Restart
```

После перезагрузки:

```powershell
.\scripts\dc\20-InstallForest.ps1 -WhatIf
.\scripts\dc\20-InstallForest.ps1
```

После автоматической перезагрузки и входа доменным администратором:

```powershell
.\scripts\dc\30-ConfigureDirectory.ps1
.\scripts\dc\40-ConfigureDhcpAndShare.ps1
```

Пароли DSRM и тестовых пользователей запрашиваются интерактивно и не сохраняются в Git.

### 4. Доменный клиент

На `CLIENT01`:

```powershell
.\scripts\client\Join-LabDomain.ps1 -WhatIf
.\scripts\client\Join-LabDomain.ps1 -Restart
```

После перезагрузки войдите как `CORP\lab.user` и выполните:

```powershell
.\scripts\validation\Test-Lab.ps1
gpresult /r
```

Проверьте чтение `\\DC01\Company`. Пользователь `lab.helpdesk` должен иметь изменение файлов, а `lab.user` — только чтение.

## Zabbix

```powershell
Set-Location .\zabbix
Copy-Item .env.example .env
# Замените пароль PostgreSQL в .env.
docker compose --env-file .env up -d
docker compose ps
```

Интерфейс: `http://127.0.0.1:8081`. При первом входе используйте стандартную учётную запись из официальной документации Zabbix и сразу задайте новый пароль.

Для агента скачайте официальный Zabbix Agent 2 MSI, узнайте опубликованный SHA-256 и передайте локальный файл скрипту:

```powershell
.\scripts\monitoring\Install-ZabbixAgent.ps1 `
  -MsiPath C:\Install\zabbix_agent2.msi `
  -ExpectedSha256 <64-символьный-SHA256>
```

Скрипт откажется устанавливать MSI, если контрольная сумма не совпадает.

## Что проверено автоматически

- синтаксический разбор всех PowerShell-файлов;
- корректность `lab.example.psd1`;
- валидность Docker Compose для Zabbix;
- отсутствие паролей и установочных образов в Git.

Полный AD DS тест требует Windows Server VM и намеренно не выполняется на публичном CI runner.

## Документация

- [Архитектура](docs/architecture.md)
- [Пошаговая лабораторная работа](docs/lab-guide.md)
- [Проверки и ожидаемые результаты](docs/validation.md)
- [Диагностика проблем](docs/troubleshooting.md)
- [План подготовки на 12 недель](docs/learning-roadmap.md)
- [Модель безопасности](SECURITY.md)

## Официальные источники

- [Установка Active Directory Domain Services](https://learn.microsoft.com/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-)
- [Core Network Guide for Windows Server](https://learn.microsoft.com/windows-server/networking/core-network-guide/core-network-guide)
- [Zabbix containers](https://www.zabbix.com/documentation/current/en/manual/installation/containers)


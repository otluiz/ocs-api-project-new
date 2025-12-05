# Arquivo: ocs_inventory_json_client_v5.ps1
# Cliente de Inventario em PowerShell para Windows.
# Versao 5: Trata valores nulos em campos de software para evitar erro de validacao do Pydantic.

# --- Configuracoes ---
$ApiUrl = "http://192.168.200.30:8000/api/ingest"

# --- Funcoes Auxiliares (Mantidas da V4) ---

function Get-HardwareInfo {
    # Coleta informacoes basicas de hardware e OS
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem
    $Processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $NetworkAdapter = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -First 1
    
    # Converte RAM de KB para MB e garante que seja um numero
    $RamMB = [int][math]::Round($OS.TotalVisibleMemorySize / 1024)
    
    # Coleta UUID para device_id
    $UUID = (Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID
    
    $HardwareInfo = @{
        "device_id" = $UUID
        "hostname" = $ComputerSystem.Name
        "ip_address" = $NetworkAdapter.IPAddress[0]
        "mac_address" = $NetworkAdapter.MACAddress
        "os_name" = $OS.Caption
        "os_version" = $OS.Version
        "os_architecture" = $OS.OSArchitecture
        "manufacturer" = $ComputerSystem.Manufacturer
        "model" = $ComputerSystem.Model
        "serial_number" = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
        "cpu_name" = $Processor.Name.Trim()
        "cpu_cores" = [int]$Processor.NumberOfCores
        "ram_mb" = $RamMB
    }
    return $HardwareInfo
}

function Get-SoftwareInfo {
    # Coleta informacoes de software instalado
    $SoftwareList = @()
    # Usa Get-CimInstance para obter programas instalados (mais confiavel que o registro)
    # Filtra para garantir que o campo Name nao seja nulo, pois e obrigatorio
    $InstalledApps = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -ne $null } | Select-Object Name, Version, Vendor, InstallDate
    
    foreach ($App in $InstalledApps) {
        # Formata a data de instalacao para o padrao YYYY-MM-DD
        $InstallDate = if ($App.InstallDate) { [datetime]::ParseExact($App.InstallDate, "yyyyMMdd", $null).ToString("yyyy-MM-dd") } else { $null }
        
        # Garante que todos os campos de string sejam strings (tratando $null como string vazia)
        $SoftwareList += @{
            "name" = "$($App.Name)"
            "version" = "$($App.Version)"
            "publisher" = "$($App.Vendor)"
            "install_date" = $InstallDate
        }
    }
    return $SoftwareList
}

function Get-StorageInfo {
    # Coleta informacoes de discos
    $StorageList = @()
    $Disks = Get-CimInstance -ClassName Win32_DiskDrive | Where-Object { $_.MediaType -ne "Removable Media" }
    
    foreach ($Disk in $Disks) {
        # Converte tamanho de bytes para GB e garante que seja um numero
        $CapacityGB = [int][math]::Round($Disk.Size / 1GB)
        
        $StorageList += @{
            "disk_name" = "$($Disk.Caption)"
            "disk_type" = "$($Disk.MediaType)"
            "capacity_gb" = $CapacityGB
            "serial_number" = "$($Disk.SerialNumber)"
        }
    }
    return $StorageList
}

# --- Processo Principal ---

Write-Host "Iniciando coleta de inventario..."

# 1. Coleta de dados
$Hardware = Get-HardwareInfo
$Software = Get-SoftwareInfo
$Storage = Get-StorageInfo

# 2. Monta o payload final (simulando a estrutura do OCS)
$Payload = $Hardware
$Payload.Add("software", $Software)
$Payload.Add("storage", $Storage)
# Adiciona listas vazias para campos nao coletados para evitar erros na API
$Payload.Add("network_interfaces", @())
$Payload.Add("logged_users", @())

# 3. Converte para JSON
$JsonPayload = $Payload | ConvertTo-Json -Depth 10

# --- DEBUG: Exibe o JSON que sera enviado ---
Write-Host "--- JSON a ser enviado ---"
Write-Host $JsonPayload
Write-Host "---------------------------"

# 4. Envia para a API
Write-Host "Enviando inventario para $ApiUrl..."

try {
    $Headers = @{
        "Content-Type" = "application/json"
        "User-Agent" = "OCS-JSON-Client-PowerShell"
    }
    
    # Forca a codificacao UTF8 para o corpo da requisicao
    $BodyBytes = [System.Text.Encoding]::UTF8.GetBytes($JsonPayload)
    
    # Usando Invoke-WebRequest para ter mais controle sobre o corpo da requisicao
    $Response = Invoke-WebRequest -Uri $ApiUrl -Method Post -Headers $Headers -Body $BodyBytes -ContentType "application/json; charset=utf-8" -ErrorAction Stop
    
    # O Invoke-WebRequest retorna o conteudo da resposta em Content
    $ResponseContent = $Response.Content | ConvertFrom-Json
    
    Write-Host "--- Resposta do Servidor ---"
    Write-Host $ResponseContent | ConvertTo-Json -Depth 10
    
    if ($ResponseContent.status -eq "success") {
        Write-Host "SUCESSO: Inventario enviado e processado com sucesso. Device ID: $($ResponseContent.device_id)"
    } else {
        Write-Host "FALHA: Inventario enviado, mas a resposta do servidor nao foi a esperada."
    }
    
} catch {
    Write-Error "Erro ao enviar a requisicao POST: $($_.Exception.Message)"
    # Captura o corpo do erro para depuracao
    if ($_.Exception.Response) {
        $ErrorResponse = $_.Exception.Response.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($ErrorResponse)
        $Reader.BaseStream.Position = 0
        $ErrorBody = $Reader.ReadToEnd()
        Write-Error "Corpo do Erro: $ErrorBody"
    }
    exit 1
}

Write-Host "Processo concluido."

# Import the AWS PowerShell module
Import-Module AWSPowerShell

# Set the AWS region
$region = "ca-central-1"

# Get the instance ID from the metadata
$instanceId = "i-0b09d4434fcc95943"

# Get the network interface details
$networkInterface = Get-EC2NetworkInterface -Region $region -Filter @{ Name="attachment.instance-id"; Values=$instanceId }
$networkInterfaceId = $networkInterface.NetworkInterfaceId

# Get the current private IP addresses detail on the network interface
$currentIpDetails = $networkInterface.PrivateIpAddresses

# Extract the primary IP address
$currentPrimaryIpAddress = $currentIpDetails | Where-Object { $_.Primary -eq $true } | Select-Object -ExpandProperty IpAddress

# Extract all IP addresses
$currentAllIpAddresses = $currentIpDetails | Select-Object -ExpandProperty IpAddress

# Pull all non-loopback IPv4 addresses from the Windows server
$allWindowsIpAddresses = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' }).IPAddress

Write-Host "Current EC2 Primary IP: $currentPrimaryIpAddress"
Write-Host "Current EC2 All IPs: $currentAllIpAddresses"
Write-Host "Windows IPs: $allWindowsIpAddresses"

# Identify secondary IPs by excluding the primary IP
$windowsSecondaryIpAddresses = $allWindowsIpAddresses | Where-Object { $_ -ne $currentPrimaryIpAddress }

Write-Host "Secondary IPs found on Windows: $windowsSecondaryIpAddresses"

# Define function to remove an IP from the network interface
function Remove-SecondaryIpAddress {
    param (
        [string]$networkInterfaceId,
        [string]$ipAddress,
        [string]$region
    )
    if ($ipAddress) {
        Write-Host "Removing IP: $ipAddress from NetworkInterfaceId: $networkInterfaceId"
        Unregister-EC2PrivateIpAddress -NetworkInterfaceId $networkInterfaceId -PrivateIpAddress $ipAddress -Region $region
    }
}

# Define function to add an IP to the network interface
function Add-SecondaryIpAddress {
    param (
        [string]$networkInterfaceId,
        [string]$ipAddress,
        [string]$region
    )
    if ($ipAddress) {
        Write-Host "Adding IP: $ipAddress to NetworkInterfaceId: $networkInterfaceId"
        Register-EC2PrivateIpAddress -NetworkInterfaceId $networkInterfaceId -PrivateIpAddress $ipAddress -AllowReassignment $true -Region $region
    }
}

# Function to sync IP addresses
function Sync-Ips {
    param (
        [array]$awsIps,
        [array]$windowsIps,
        [string]$networkInterfaceId,
        [string]$region
    )

    # Add up to 9 secondary IPs (10 total including the primary IP)
    $currentSecondaryIpCount = $awsIps.Count - 1

    # Determine IPs to add
    $ipsToAdd = $windowsIps | Where-Object { $_ -notin $awsIps }

    foreach ($ip in $ipsToAdd) {
        if ($currentSecondaryIpCount -lt 9) {
            Add-SecondaryIpAddress -networkInterfaceId $networkInterfaceId -ipAddress $ip -region $region
            $currentSecondaryIpCount++
        } else {
            Write-Host "Maximum of 10 IP addresses (including primary) enforced. Skipping additional IPs."
            break
        }
    }

    # Determine IPs to remove
    $ipsToRemove = $awsIps | Where-Object { $_ -ne $currentPrimaryIpAddress -and $_ -notin $windowsIps }

    # Remove IPs not present on the Windows server
    foreach ($ip in $ipsToRemove) {
        Remove-SecondaryIpAddress -networkInterfaceId $networkInterfaceId -ipAddress $ip -region $region
    }
}

Sync-Ips -awsIps $currentAllIpAddresses -windowsIps $windowsSecondaryIpAddresses -networkInterfaceId $networkInterfaceId -region $region

Write-Host "IP synchronization completed."

function Get-VMNameList {

    #Import-Module -Name VMware.VimAutomation.Core
    Set-PowerCLIConfiguration -DefaultVIServerMode single -Scope Session -Confirm:$false

	Connect-VIServer -Server apc1vc01.apc.net -Credential $mgmtCred
    
    $Global:VMnameList = @()

	foreach ($vm in Get-VM){
        
        $Replica = 0
        $VMCluster = $null
        $Domain = $null

        if($vm.Name -like "*_replica"){$Replica = 1}

        $VMCluster = Get-Cluster -VM $vm
        
        try{
            $Domain = $vm.guest.hostname -split"\."
            $Domain = $vm.guest.hostname.substring($Domain[0].length +1)
            }
        catch{
            $Domain = "None"
            }
        
        $properties = [ordered]@{'Name'=$vm.Name;
            'Hostname'=$vm.Guest.Hostname;
            'Domain'=$Domain;
            'Clustername'=$VMCluster.Name;
            'Replica'=$Replica;
            'IPAddress0'=$vm.Guest.IPAddress[0];
            'IPAddress1'=$vm.Guest.IPAddress[1];
            'IPAddress2'=$vm.Guest.IPAddress[2];
            'OS'=$vm.Guest.OSFullName;
            'DiskUsed'=$vm.UsedSpaceGB;
            'DiskProvisioned'=$vm.ProvisionedSpaceGB}

        $VMname = New-Object -TypeName PSObject -Property $properties

        $Global:VMnameList += $VMname

	}
	
	$Global:VMnameList = $Global:VMnameList | Sort Name

Disconnect-VIServer -Confirm:$false

}


Function Get-WinDiskSpace { 
 Param (
 	[string[]]$Global:winServers, $providedCred) 
	 
	Foreach ($s in $Global:winServers){  
 	#Write-Output $s
	 
	 Try{ Get-WmiObject -Credential $providedCred -Class win32_volume -cn $s -ErrorAction Stop | 
            Select-Object @{LABEL='Computer';EXPRESSION={$s}}, 
            driveletter, label,  
            @{LABEL='GBfreespace';EXPRESSION={"{0:N2}" -f ($_.freespace/1GB)}} ,
		    @{LABEL='GBCapacity';EXPRESSION={"{0:N2}" -f ($_.capacity/1GB)}},
		    @{LABEL='GBUsed';EXPRESSION={"{0:N2}" -f (($_.capacity - $_.freespace)/1GB)}}
     }
     Catch{
            $WinServerErrs++
     }
   	 }
}


Write-Host "Please provide Management Credentials"
$mgmtCred = Get-Credential
Write-Host "Please provide Domain Credentials"
$domainCred = Get-Credential

$WinServerErrs = 0

Get-VMNameList

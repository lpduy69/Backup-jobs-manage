<#
 
.SYNOPSIS
    
 
.DESCRIPTION
This Script can do following these actions:
	Report VMs Backup
	Count the total of VM on Veeam backup for backup and backup job (not include tape) from last session backup
	Count the VM backup with Success status for backup and backup job from last session backup
	Count the VM backup with Failed status for backup and backup job from last session backup
 
.NOTES
	==> Update backup job not count disabled job
    REQUIREMENTS
    Intended to be run direct on the VBR server with Veeam Powershell addin installed
    Powershell v2 or better
    Veeam Backup and Replication v9.5 Update 4
 
.EXAMPLE
    .\count_vms.ps1
     
#>


#--------------------------------------------------------------------
# Static Variables
$server='192.168.xxx.xxx'
$servername="SRVVEEMBKxxxx"
$scriptName = "$servername report VM backup"
$scriptVer = "2.1"
$starttime = Get-Date -uformat "%m-%d-%Y %I:%M:%S"
$now = Get-Date -Format yyyyMMdd_HHmm
$user='admin'
$password='fKkC:YpwZkvwJ+8R%;s*'


$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

$Precontent = @"
<h1>$scriptName $now </h1>
"@

$results_array = @()
$results_array2 = @()

#--------------------------------------------------------------------
# Load Snap-ins
 
# Add Veeam snap-in if required
If ((Get-PSSnapin -Name VeeamPSSnapin -ErrorAction SilentlyContinue) -eq $null) {add-pssnapin VeeamPSSnapin}
Connect-VBRServer -Server $server -User $user -Password $password
#--------------------------------------------------------------------

#--------------------------------------------------------------------
# Functions


 
 
#--------------------------------------------------------------------
# Main Procedures
Clear-Host
Write-Host "$scriptName`tVer:$scriptVer`t`t`tStart Time:`t$starttime"
Write-Host "********************************************************************************`n"
write-host "Start to report VM on Server $servername"


$backupjobs = Get-VBRJob | Where-Object {$_.IsBackup} | Where-Object {$_.IsScheduleEnabled}
#$backupjobs = Get-VBRJob | ?{$_.JobType -eq "Backup"}

#$count_all_vms = $backupjobs.FindLastSession().GetTaskSessions().count
#$count_vms_success=($backupjobs.findlastsession().gettasksessions() | Where {$_.Status -eq "Success"}).count
#$count_vms_fail=($backupjobs.findlastsession().gettasksessions() | Where {$_.Status -eq "Failed"}).count
#$count_vms_warning=($backupjobs.findlastsession().gettasksessions() | Where {$_.Status -eq "Warning"}).count
#$count_vms_pending=($backupjobs.findlastsession().gettasksessions() | Where {$_.Status -eq "Pending"}).count
#$vms_fail=$backupjobs.findlastsession().gettasksessions() | Where {$_.Status -eq "Failed"}
#write-host "The Total amount of VM for backup is $count_all_vms" -ForegroundColor green
#write-host "The  amount of VM backup Success is $count_vms_success" -ForegroundColor green
#write-host "The  amount of VM backup Warning is $count_vms_warning" -ForegroundColor yellow
#write-host "The  amount of VM backup Pending is $count_vms_pending" -ForegroundColor yellow
#write-host "The  amount of VM backup Failed is $count_vms_fail" -ForegroundColor red


foreach($job in $backupjobs)
{
	$lastsession = $job.findlastsession()
	$tasksessions = $lastsession.GetTaskSessions() 
	
	foreach($tasksession in $lastsession.GetTaskSessions()) 
	{
		$objResult = [pscustomobject][ordered]@{
			Server = $server
			VmNametest = $tasksession.Name
			JobName = $job.Name
			LastResult = $job.GetLastResult()
			BackedUpDataGB  = [Math]::Round(($lastsession.Info.BackupTotalSize / 1GB), 2)
			BackupSizeGB    = [Math]::Round(($lastsession.Info.BackedUpSize / 1GB), 2)
			JobStartTime = $lastsession.CreationTime
			JobEndTime = $lastsession.EndTime
			TimeSpan_HHMMSS = [System.TimeSpan]::Parse($lastsession.EndTime - $lastsession.CreationTime)
		}
		$results_array += $objResult
	}
	
	$objSummary = [pscustomobject][ordered]@{
		JobName = $Job.Name
		Total_VMs = $tasksessions.count
		Success_VMs = ($tasksessions | Where {$_.Status -eq "Success"}).count
		Failed_VMs = ($tasksessions | Where {$_.Status -eq "Failed"}).count
		Warning_VMs = ($tasksessions | Where {$_.Status -eq "Warning"}).count
		Pending_VMs = ($tasksessions | Where {$_.Status -eq "Pending"}).count	
	}
	$results_array2 += $objSummary	
#	$starttime=$lastsession.CreationTime
#	$endtime = $lastsession.EndTime
#	$lastresult = $job.GetLastResult()
#	write-host "$job.Name ==> StartTime: $starttime | EndTime: $endtime "
#	write-host "Result: $lastresult" -ForegroundColor green
#	$j= $job.FindLastSession().GetTaskSessions().count
#	$s= ($job.findlastsession().GetTaskSessions() | Where {$_.Status -eq "Success"}).count
#	$f= ($job.findlastsession().GetTaskSessions() | Where {$_.Status -eq "Failed"}).count 
#	$w= ($job.findlastsession().GetTaskSessions() | Where {$_.Status -eq "Warning"}).count
#	$p = ($job.findlastsession().GetTaskSessions() | Where {$_.Status -eq "Pending"}).count
#	write-host "The amount VM Success: $s Vms" -ForegroundColor green
#	write-host "The amount VM Failed $f Vms" -ForegroundColor red
#	write-host "The amount VM Warning $w Vms" -ForegroundColor yellow
#	write-host "The amount VM Pending $p Vms" -ForegroundColor cyan
#	write-host "The amount VM have $j Vms" -ForegroundColor green
}

#Export to HTML file
$HTMLreportfilename = "$servername-BackupReport-Details-" + $now + ".html"
$results_array | Sort-Object JobName, VmName | ConvertTo-Html -Head $Header -Precontent $Precontent| Out-File $HTMLreportfilename
$HTMLreportfilename = "$servername-BackupReport-Summary-" + $now + ".html"
$results_array2 | Sort-Object JobName, VmName | ConvertTo-Html -Head $Header -Precontent $Precontent| Out-File $HTMLreportfilename
write-host "Report is finished" -ForegroundColor green

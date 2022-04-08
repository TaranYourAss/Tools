
function data-collection {
$LogicalProcessors = (Get-WmiObject –class Win32_processor -Property NumberOfLogicalProcessors).NumberOfLogicalProcessors;

$DATA=get-process -IncludeUserName `
    | select `
        @{Name="Time"; Expression={(Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")}},` 
        ID, `
        StartTime, `
        CPU, `
        @{Name='CPU_Usage'; Expression = { $TotalSec = (New-TimeSpan -Start $_.StartTime).TotalSeconds
            [Math]::Round( ($_.CPU * 100 / $TotalSec) /$LogicalProcessors, 2) }},`
        UserName,`
        ProcessName,`
        Path `
    | Where-Object CPU_Usage -GT 1
#On Powershell Versions 7+, you can also Select the 'CommandLine' property for each process. Will need Administrator priviliges


#Function track ($time, $process_id, $process_name, $process_path, $cpu){
#    
#}

#Calculates the total CPU usage (as a percentage of 100) being used
#$total_cpu = [double]0
#ForEach ($object in $DATA){
#    $total_cpu += $object.CPU_Usage
#}
#Write-Host $total_cpu


#Code Below Displays total CPU usage available as well as the amount of CPU percentage not being used

#$NumberOfLogicalProcessors=(Get-WmiObject -class Win32_processor | Measure-Object -Sum NumberOfLogicalProcessors).Sum
#(Get-Counter '\Process(*)\% Processor Time').Countersamples | Where cookedvalue -gt ($NumberOfLogicalProcessors*10) | Sort cookedvalue -Desc | ft -a instancename, @{Name='CPU %';Expr={[Math]::Round($_.CookedValue / $NumberOfLogicalProcessors)}}


#checks and creates the csv file for tracking
if (-not (Test-Path -Path ".\tracking.csv")){
    New-Item .\tracking.csv -ItemType File
    Add-Content -Path .\tracking.csv -Value 'Time,Process ID,Process Path, Process Name, CPU Usage (%)'
    #Add-Content -Path .\tracking.csv -Value 'Time,Process Name, CPU Usage (%)'
}

ForEach ($object in $DATA){
    $time = $object.Time.ToString()
    $process_id = $object.ID.ToString()
    $process_path = $object.Path.ToString()
    $process_name = $object.ProcessName.ToString()
    #$command_line = $object.CommandLine.ToString() #Powershell 7+ only
    $cpu = $object.CPU_Usage.ToString()
    #Add-Content -Path .\tracking.csv -Value "$time,$process_id,$process_name,$process_path,$command_line,$cpu" #Powershell 7+ only
    Add-Content -Path .\tracking.csv -Value "$time,$process_id,$process_name,$process_path,$cpu"
    #Add-Content -Path .\tracking.csv -Value "$time,$process_name,$cpu"
    $time = " "
    $process_id = " "
    $process_path = " "
    $process_name = " "
    $cpu = " "
    #$command_line = " " #Powershell 7+ Only
}
}
do {data-collection} until (Start-Sleep -Seconds 1)

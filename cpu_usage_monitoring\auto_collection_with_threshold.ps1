$data_directory = "C:\**\**\rSolutions-Auto_Collection"

Function Log {
    param(
        [string]
        $log
    )
    
    #used to send logs to a the auto_collection.log file 
    #creates a new file if none is found
    #looks for the .log file in the directory defined in 'data_directory'
    
    if (Test-Path -Path "$data_directory\rSolutions-Auto_Collection-Logs.log"){

        $date = (Get-Date).tostring("yyyy-MM-dd hh:mm:ss")
        Add-Content -Path "$data_directory\rSolutions-Auto_Collection-Logs.log" -value "`n[$date] $log"
    } else {
        New-Item -ItemType File -Path $data_directory -Name "rSolutions-Auto_Collection-Logs.log" -value "[$date] $log"
    }
}

Function Execute-Command {
    param(
        [string]
        $commandTitle,

        [string]
        $commandPath,

        [string]
        $commandArguments,

        [bool]
        $wait
    )
    
    #used to run non-PowerShell stuff
    $commandArguments
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $commandPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $commandArguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    if ($wait.Equals($true)) {
        $p.WaitForExit()
    }
    [pscustomobject]@{
        commandTitle = $commandTitle
        stdout = $p.StandardOutput.ReadToEnd()
        stderr = $p.StandardError.ReadToEnd()
        ExitCode = $p.ExitCode
    }
}



Function data_collection {
 
    #1. start ProcMon
    #2. start PerfMon
    #3. collect all processes and CPU usage - turned off
    #4. collect xagt logs
    #5. wait 15 minutes
    #6. end ProcMon 
    #7. end PerfMon 
    

    #1. start ProcMon
    start-process -filepath "$data_directory\Procmon.exe" -argumentlist "/accepteula /quiet /minimized /backingfile $data_directory\rSolutions-Auto_Collection-ProcMon.PML" -Passthru -NoNewWindow
    Log("ProcMon Capture Started")
    
    #2. start PerfMon
    $args = 'create counter rSolutions-Auto_Collection -f bincirc -v mmddhhmm -max 250 -c "\LogicalDisk(*)\*" "\Memory\*" "\Network Interface(*)\*" "\Paging File(*)\*" "\PhysicalDisk(*)\*" "\Process(*)\*" "\Redirector\*" "\Server\*" "\System\*" "\Thread(*)\*" -si 00:00:05' + " -o $data_directory\rSolutions-Auto_Collection-PerfMon.blg"

    Execute-Command `
        -commandTitle "initialize PerfMon" `
        -commandPath "logman.exe" `
        -commandArguments $args `
        -wait $true
    Log("PerfMon Data-Collector-Set created as 'rSolutions-Auto_Collection'")
    
    Execute-Command `
        -commandTitle "PerfMon Start" `
        -commandPath "logman.exe" `
        -commandArguments "start rSolutions-Auto_Collection" `
        -wait $false
    Log("PerfMon Capture Started")


    #3. collect all processes and CPU usage
    #Log("Export of All Processes:")
    #Get-Process `
    #    | select ProcessName, Path, ID, CPU, StartTime `
    #    | sort CPU -Descending `
    #    | Where-Object CPU -GT 0 `
    #    | Out-File -FilePath "$data_directory\rSolutions-Auto_Collection-Logs.log" -Append

    #4. collect xagt logs
    $xagt_export = Execute-Command `
        -commandTitle "Collect xagt Log" `
        -commandPath "C:\Program Files (x86)\FireEye\xagt\xagt.exe" `
        -commandArguments "-g $data_directory\rSolutions-Auto_Collection-XAGT_Logs.log" `
        -wait $true
    Log("XAGT Logs Exported")

    #5. wait 15 minutes
    Log("Waiting 15 Minutes")
    #Start-Sleep -Seconds 900
    Start-Sleep -Seconds 10

    #6. end ProcMon
    Start-Process -filepath "$data_directory\Procmon.exe" -argumentlist '/terminate' -wait -NoNewWindow
    Log("ProcMon Capture Terminated")

    #7. end PerfMon
    Execute-Command `
        -commandTitle "PerfMon Terminate" `
        -commandPath "logman.exe" `
        -commandArguments "stop rSolutions-Auto_Collection" `
        -wait $false
    Log("PerfMon Capture Terminated")
}

Function cpu_percent {
    param(
        [int]
        $threshold
    )

    #Collects total CPU percentage and starts data_collection when CPU usage is over the defined threshold  

    $cpu = Get-Counter -Counter "\Processor(_Total)\% Processor Time"
    if ($cpu.CounterSamples.CookedValue -GT $threshold){
        data_collection
        Log("Data Collection Complete")
        Write-Host("Data Collection Complete")
        Write-Host("Script Exiting...")
        exit
    }
    else {
        return
    }
}

do {cpu_percent($threshold = 90)} until (Start-Sleep -Seconds 1)

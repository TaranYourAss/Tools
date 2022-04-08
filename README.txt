cpu_usage_collection.ps1 will collect details around each process that has higher than 1% CPU usage every second. 

A csv file, entitled 'tracking.csv', will be created in the same directory as the script, which will continously increase in size as the script is ran. 

Details collected:
- Time
- Process ID
- Process Path
- Process Name
- CPU Usage Percentage


To run the script:

- Open a powershell instance as an Administrator
- navigate to the scripts location
- run the script:
	PC C:\path\to\script> .\cpu_usage_collection.ps1

To end the script:

- CTRL + C in the powershell instance




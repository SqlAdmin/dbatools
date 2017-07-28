function Remove-DbaAgentJob {
    <#
        .SYNOPSIS 
            Remove-DbaAgentJob removes a job.

        .DESCRIPTION
            Remove-DbaAgentJob removes a a job in the SQL Server Agent.

		.PARAMETER SqlInstance
			The SQL Server instance. Server version must be SQL Server version 2012 or higher.

		.PARAMETER SqlCredential
			Allows you to login to servers using SQL Logins instead of Windows Authentication (AKA Integrated or Trusted).
        
        .PARAMETER Job
            The name of the job. Can be null if the the job id is being used.

        .PARAMETER KeepHistory
            Specifies to keep the history for the job. By default is history is deleted.

        .PARAMETER KeepUnusedSchedule
            Specifies to keep the schedules attached to this job if they are not attached to any other job. 
            By default the unused schedule is deleted.

		.PARAMETER WhatIf
			If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

		.PARAMETER Confirm
			If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

		.PARAMETER Silent
			If this switch is enabled, the internal messaging functions will be silenced.

        .NOTES 
            Original Author: Sander Stad (@sqlstad, sqlstad.nl)
            Tags: Agent, Job
                
            Website: https://dbatools.io
            Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
            License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

        .LINK
            https://dbatools.io/Remove-DbaAgentJob

        .EXAMPLE   
            Remove-DbaAgentJob -SqlInstance sql1 -Job Job1

            Removes the job from the instance with the name Job1.

        .EXAMPLE   
            Remove-DbaAgentJob -SqlInstance sql1 -Job Job1 -KeepHistory

            Removes the job but keeps the history.

        .EXAMPLE   
            Remove-DbaAgentJob -SqlInstance sql1 -Job Job1 -KeepUnusedSchedule

            Removes the job but keeps the unused schedules.

        .EXAMPLE   
            Remove-DbaAgentJob -SqlInstance sql1, sql2, sql3 -Job Job1 

            Removes the job from multiple servers.

        .EXAMPLE   
            sql1, sql2, sql3 | Remove-DbaAgentJob -Job Job1 

            Removes the job from multiple servers using pipe line

    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low")]

    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("ServerInstance", "SqlServer")]
        [object[]]$SqlInstance,

        [Parameter(Mandatory = $false)]
        [PSCredential]$SqlCredential,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Job,
        
        [Parameter(Mandatory = $false)]
        [switch]$KeepHistory,
        
        [Parameter(Mandatory = $false)]
        [switch]$KeepUnusedSchedule,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    process {

        foreach ($instance in $sqlinstance) {

            # Try connecting to the instance
            Write-Message -Message "Attempting to connect to $instance" -Level Verbose
            try {
                $server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $SqlCredential
            }
            catch {
                Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }
        
            foreach ($j in $Job) {

                # Check if the job exists
                if ($Server.JobServer.Jobs.Name -notcontains $j) {
                    Write-Message -Message "Job $j doesn't exists on $instance" -Warning
                }
                else {   
                    # Get the job
                    try {
                        $currentjob = $Server.JobServer.Jobs[$j] 
                    }
                    catch {
                        Stop-Function -Message "Something went wrong creating the job. `n$($_.Exception.Message)" -Target $instance -Continue
                    }

                    # Delete the history
                    if (-not $KeepHistory) {
                        Write-Message -Message "Purging job history" -Level Verbose
                        $currentjob.PurgeHistory()
                    }

                    # Execute 
                    if ($PSCmdlet.ShouldProcess($instance, "Removing the job on $instance")) {
                        try {
                            Write-Message -Message "Removing the job" -Level Output

                            if ($KeepUnusedSchedule) {
                                # Drop the job keeping the unused schedules
                                Write-Message -Message "Removing job keeping unused schedules" -Level Verbose
                                $currentjob.Drop($true) 
                            }
                            else {
                                # Drop the job removing the unused schedules
                                Write-Message -Message "Removing job removing unused schedules" -Level Verbose
                                $currentjob.Drop($false) 
                            }
                    
                        }
                        catch {
                            Stop-Function -Message  "Something went wrong removing the job. `n$($_.Exception.Message)" -Target $instance -Continue
                        }
                    } 
                }

            } # foreach object job
        } # forech object instance
    } # process

    end {
        Write-Message -Message "Finished removing jobs(s)." -Level Output
    }
}
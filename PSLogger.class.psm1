using module ".\loglevel-enum.psm1"

Class PsLogger
{
    hidden $loggingScript =
    {
        try{$logFile = New-Item -ItemType File -Path $logLocation -ErrorAction "Stop"}catch{$logFile = Get-ChildItem $logLocation}
        function Start-Logging
        {
            param($logFile)
            $loggingTimer = new-object Timers.Timer
            $action = {
                $StreamWriter = $logFile.AppendText()
                while (-not $logEntries.IsEmpty)
                {
                    $entry = ''
                    $null = $logEntries.TryDequeue([ref]$entry)
                    $StreamWriter.WriteLine($entry)
                }
                $StreamWriter.Flush()
                $StreamWriter.Close()
            }
            $loggingTimer.Interval = 1000
            $null = Register-ObjectEvent -InputObject $loggingTimer -EventName elapsed -Sourceidentifier loggingTimer -Action $action
            $loggingTimer.start()
        }
    
        Start-Logging $logFile
    }
    hidden $_loggingRunspace = [runspacefactory]::CreateRunspace()
    hidden $_loggingPoSHSession
    hidden $_loggingJob
    hidden $_logEntries = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    hidden $_logLocation = $env:temp
    
    PsLogger([string]$logLocation)
	{
        $this._logLocation = $logLocation

        # Start Logging runspace
        $this._StartLogging()
    }
    
    hidden QueueLog([string]$message, [LogLevel]$severity)
    {
        $addResult = $false
        while ($addResult -eq $false)
        {
            $msg = '{0} : {1} : {2}' -f ([LogLevel]::$severity), [DateTime]::UtcNow.tostring('yyyy-MM-ddTHH:mm:ssZz'), $message
            $addResult = $this._logEntries.TryAdd($msg)
        }
    }

    hidden QueueLog([string]$message, [loglevel]$severity, [string]$component) 
    {
        switch ($severity) {
            [loglevel]'critical' {$severity = 'error'}
            [loglevel]'verbose' {$severity = 'info'}
        }
        $msg = "<![LOG[$Message]LOG]!>" +`
        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
        "component=`"$Component`" " +`
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
        "type=`"$severity`" " +`
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
        "file=`"`">"    
        $addResult = $false
        while ($addResult -eq $false)
        {
            $addResult = $this._logEntries.TryAdd($msg)
        }
    }

    hidden _StartLogging()
    {
        $this._LoggingRunspace.ThreadOptions = "ReuseThread"
        $this._LoggingRunspace.Open()
        $this._LoggingRunspace.SessionStateProxy.SetVariable("logEntries", $this._logEntries)
        $this._LoggingRunspace.SessionStateProxy.SetVariable("logLocation", $this._logLocation)
        $this._loggingPoSHSession = [PowerShell]::Create().AddScript($this.loggingScript)
      
        $this._loggingPoSHSession.Runspace = $this._LoggingRunspace
        $this._LoggingJob = $this._loggingPoSHSession.BeginInvoke()
    }

    [void] StopLogging(){
        $this._loggingPoSHSession.EndInvoke($this._loggingJob)
        $this._loggingRunspace.Close()
    }
}

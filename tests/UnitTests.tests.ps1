using module ../src/PSLogger.class.psm1
BeforeAll{
    #declare some path vars
    $here = $PSScriptRoot
    $parent = split-path $here -Parent
    
    #import the module for testing
    import-module "$parent/src/PSLogWriter.psd1"
}    
Describe "PSLogger class"{
    BeforeAll {
        $logger = new-object PSLogger("$testdrive/test.log")
        $loggerMembers = $logger | get-member -Force
    }
    Context "should have methods" {
        It "<method>" -TestCases @(
            @{method="QueueLog"}
            @{method="_StartLogging"}
            @{method="StopLogging"}) {
            $method | Should -BeIn $loggerMembers.name
        }
    }
    AfterAll {
        $logger.StopLogging()
    }
}

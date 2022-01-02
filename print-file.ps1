<#
    .SYNOPSIS
        This script will print the content of the chosen file with numbered lines
    .DESCRIPTION
        The user can optionally provide a folder to pick from the files inside.
        If no folder is provided, c:\Windows\System32\drivers\etc\ will be used as default.
        The user will be presented with a menu that shows all files in the folder, and after
        confirming the selection, the content of the file will be printed to the console with numbered lines.
        The script takes optional array of file names to be excluded from the menu.
    .EXAMPLE
        Suppose you have 
        c:\MyFolder\
        |-- test1.txt
        |-- test2.txt
        $ echo Hello World > c:|MyFolder\test1.txt  
        $ Print-File -FilePath c:\MyFolder
            Please choose from the menu below:
            1) test1.txt
            2) test2.txt
        $ 1
            .\Print the file c:\MyFolder\test1.txt? [y/n]
        $ y
            1) Hello World
    .EXAMPLE
        Suppose you have 
            c:\MyFolder\
            |-- test1.txt
            |-- test2.txt
        $ echo Hello World > c:|MyFolder\test1.txt
        $ .\Print-File -FilePath c:\MyFolder -ExcludeNames test2.txt
            Please choose from the menu below:
            1) test1.txt
        $ 1
            Print the file c:\MyFolder\test1.txt? [y/n]
        $ y
            1) Hello World
        
    .EXAMPLE
        Suppose you have 
            c:\MyFolder\
            |-- test1.txt
            |-- test2.txt

        $ echo "Example 2 content" > c:\MyFolder\test2.txt 

        $ .\Print-File -FilePath c:\MyFolder
            Please choose from the menu below:
            1) test1.txt
            2) test2.txt
        $ 3
            WARNING: Please choose a valid number
            Please choose from the menu below:
        # 1
            Print the file c:\MyFolder\test1.txt? [y/n]
        $ n
            Please choose from the menu below:
            1) test1.txt
            2) test2.txt
        $ 2
            1) Example 2 content
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [String]
        # The location to search files in
        $FilePath="c:\Windows\System32\drivers\etc\",

        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [string[]]
        # The files that won't show in the menu
        $ExcludeNames = @("lmhosts.sam", "services"),

        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [string]
        # Where to save log output
        $LogPath = "$FilePath\logs\"
        
    )

<##################
#### FUNCTIONS ####
###################>



function Get-FileNames {
    # get list of files from the arg given to the script or default location
    if (Test-Path -Path $FilePath)
    {
        $FilesNames = Get-ChildItem -File $FilePath | Where-Object { $ExcludeNames -NotContains $PSItem.Name }
    }
    Write-Output $FilesNames.Name
}

# This helper function decides what options will be presented to the user.
# An option is made of a key to select that option, and a name to suggest what it does.
# For example: 1) exit
#              2) do something
function Get-MenuOptions {
    
    [CmdletBinding()]
    param (

    ) 

    process {
        $Options = @()
        $Options += @{
            "prefix" = "1) "
            "displayName"= "exit"
            "color" =  "Red"
            }
        
        $Options += @{
            "prefix" = "2) " 
            "displayName" = "say hello" 
            "color" = "Blue"
            }
        # read all the files and append them to the list of menu options
        $FilesNames = Get-FileNames
        $OptionsLength = $Options.Count
        for ($i = $Options.Count +1; $i -le ($OptionsLength + $FilesNames.Count); $i++)
        {
            $File = $FilesNames[$i - 1 - $OptionsLength]
            $item = @{
                "prefix" = "$i) "
                "displayName" = "$File"
                "color" = "Green"
            }
            $Options += ($item)
        }

        Write-Output $Options
    }

}

# This function recieves a list of options and displays them to the user with numbered lines
function Show-Menu {

    [CmdletBinding()]
    param (
        [Parameter()]
        [Object[]]
        # All of the selectable options the user can choose
        $MenuOptions
    )
    process {
        Write-Host ""
        Write-Host "~~~~~~~~~~~~~~~~ MAIN MENU ~~~~~~~~~~~~~~~~"
        Write-Host "~~~ Please choose an option from below: ~~~"
        
        $MenuOptions | Foreach-Object {
            Write-Host $_.prefix -ForegroundColor Gray -NoNewLine
            Write-Host $PSItem.displayName -ForegroundColor $PSItem.color
        }
        Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    }
}

# This function recieves the options from the menu and whichever number the user chose,
# And handles that particular choice`
function Invoke-MainLoop {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [object]
        # function that runs on every iteration and returns menu options to display
        $GetMenu
    )

    process {
        $MenuDisplayState = "running"
        while ($MenuDisplayState -eq "running")
        {
            # update the menu options and display it
            $MenuOptions = & $GetMenu            
            Show-Menu $MenuOptions

            $UserChoice = Read-Host -Prompt "Your answer"
            if ($null -ne $FilesNames -and $UserChoice -as [int]  -and [int]$UserChoice -gt 0 -and [int]$UserChoice -le $MenuOptions.Count)
            {
                $OptionName = $MenuOptions[$UserChoice -1].displayName

                # What to do based on the option the user selected.
                # If you want to handle more cases, simply add a clause to the switch statement
                switch ($OptionName) {
                    "exit" { 
                        $MenuDisplayState = "finished" 
                        Write-Log $? $OptionName
                    }
                    "say hello" { 
                        Write-Host -ForegroundColor Blue "  Hello! How are you doing?"
                        Write-Log $? $OptionName
                    }
                    Default {
                        
                        # Print the content of the file after confirmation
                        do
                        {
                            Write-Host -ForegroundColor Yellow "  Are you sure you want to print " -NoNewLine
                            Write-Host -ForegroundColor Green "$FilePath\$OptionName" -NoNewLine
                            Write-Host -ForegroundColor Yellow "? [y|n]" 
                            $ConfirmState = Read-Host
                        } while ( $ConfirmState -NotMatch 'n|no' -and $ConfirmState -NotMatch "y|yes" )
                    
                        if ($ConfirmState -match 'y|yes') 
                        {
                            Show-File $OptionName
                            Write-Log $? $OptionName
                            $MenuDisplayState = "finished"
                        }

                    }
                }
            
            }
            else # Input is not a number or isn't in range
            {
                Write-Host " Please choose a valid number!" -ForegroundColor Red
            }

        }
    }


}

# Prints the content of the given file with numbered lines
function Show-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$false)]
        [String]
        # The name of file to print
        $FileToPrint
    )


    if (Test-Path -Path $FilePath\$FileToPrint)
    {
        # Read the file, and insert the line number in each line
        $AllLines = Get-Content $FilePath\$FileToPrint
        for ($i = 0; $i -lt $AllLines.Count; $i++)
        {
            $Prefix = $i + 1
            $Line = $AllLines[$i]
            Write-Host -ForegroundColor DarkGray "$Prefix) " -NoNewLine
            Write-Host -ForegroundColor Black -BackgroundColor White "$Line"
        }   
    } else
    {
        Write-Warning "Error reading file $FileToPrint . Please check the path of this file"

    }

    

}

# Bonus function: Writes the result and name of operation to the log file with current date
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        # Whether the logged action was succesful or not
        $result,
        [Parameter(Mandatory=$true)]
        [string]
        # The action to be logged
        $action
    )
    $Date = Get-Date
    try {
        Write-Output "$Date   |   $result |   $action "> $FilePath        
    }
    catch {
        Write-Debug "Can't write to $FilePath"
    }
}

<#####################
####  MAIN SCRIPT ####
######################>

# get list of files from the arg given to the script or default location
if (Test-Path -Path $FilePath)
{
    $FilesNames = Get-ChildItem -File $FilePath | Where-Object { $ExcludeNames -NotContains $PSItem.Name }
}

if ($null -eq $FilesNames)
{
    # a hint to user in case no files were found
    Write-Warning "No files were found at this location. Hint: Try a different -FilePath or -ExcludeNames"
} 
    else
{

    # show title of the program
    Write-Host "
     __ _ _                   _       _            
    / _(_) | ___   _ __  _ __(_)_ __ | |_ ___ _ __ 
   | |_| | |/ _ \ | '_ \| '__| | '_ \| __/ _ \ '__|
   |  _| | |  __/ | |_) | |  | | | | | ||  __/ |   
   |_| |_|_|\___| | .__/|_|  |_|_| |_|\__\___|_|   
                  |_|                              
    
    "
    <#
    The event loop is made of 3 main stepts: Construct the menu, display the menu to the user and wait for response,
    then process that result.
    A function is given as parameter that will be called in each iteration, and update the menu.
    This guarantees that the menu is up to date in each iteration (new files added) 
    and that we can easily implement new kind of menus in the future
    #>
    Invoke-MainLoop { Get-MenuOptions  }

    Write-Host "~~~~~~~~~~~~~~~~~~~~"
    Write-Host "Goodbye!"

}
# SIG # Begin signature block
# MIIRzwYJKoZIhvcNAQcCoIIRwDCCEbwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvUhE3zF41AKmg3u5xkgu4V8l
# aIeggg05MIIC/jCCAeagAwIBAgIQE6G8nP6L0KFOjrT3qSt9vjANBgkqhkiG9w0B
# AQsFADAXMRUwEwYDVQQDDAxBdXRoZW50aWNvZGUwHhcNMjExMjMxMTEyNzU5WhcN
# MjIxMjMxMTE0NzU5WjAXMRUwEwYDVQQDDAxBdXRoZW50aWNvZGUwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQDGJMPXFuIMw668ZWfO0Meq8FYFzjcnylsb
# ZsXbga1IKSD4vw+rG9ETm2xS+ZBdSIeq6X/02sqIrfY3h+W/n5sRJlA2rFcOCGJy
# 8lDf44DlFG5b2b0oDzpagJU5Fxa1nDm9Y7fpvQk5PVNIc9hE/wkwSdjddrzgPFOf
# hw8ZBKGPr5sc4/izLw/+2IcMdSiICmcdFgdjvU1IIErfumSd9q4USPLCZqebDswW
# k29zFy32dTVR8SMP3XimTwetd5FsfDn2fcB5piKzaKOUe+7rL8ls4ktXS10XTSO3
# v+08sJ107q8MF6vzPFfB+wxreLRYODhysea8whSCAViCDR8VvFa1AgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# y4H7lAKmd0ToHhJcaVnZcPm/zEMwDQYJKoZIhvcNAQELBQADggEBALyXwc4iqduJ
# zmr1iohTs+Bfst5Y4h+g5kw91uVMMXCRh0Jg1L6Y1Hk/AMDdP4PX0J8vWCVXYn8y
# lpoldvlHGwf9nS7s69XHHl5+FsZhggd9dbyWsYOkbyr+CtSXb5nRk3sCqqyep5c1
# MAvmC3r4tBfIQo5+JQxSfRv7fdBETjdX3iRd54pPHDsmj5T3smDF6gpxMtzbCpD0
# ESBbqF8U7W0VsmWirGiOb5YFaUM/2V0BssKQwao1v68orAiggK3h5uEEFg79/rgu
# 3LKi+/FHe3z0H5B57Vehjgyw8TCm+3BkcHCqZPsteREgntvm2OzrfH2A+0d6+WzR
# GXXDdwuzmkUwggT+MIID5qADAgECAhANQkrgvjqI/2BAIc4UAPDdMA0GCSqGSIb3
# DQEBCwUAMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIg
# QXNzdXJlZCBJRCBUaW1lc3RhbXBpbmcgQ0EwHhcNMjEwMTAxMDAwMDAwWhcNMzEw
# MTA2MDAwMDAwWjBIMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIElu
# Yy4xIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDIxMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwuZhhGfFivUNCKRFymNrUdc6EUK9CnV1TZS0
# DFC1JhD+HchvkWsMlucaXEjvROW/m2HNFZFiWrj/ZwucY/02aoH6KfjdK3CF3gIY
# 83htvH35x20JPb5qdofpir34hF0edsnkxnZ2OlPR0dNaNo/Go+EvGzq3YdZz7E5t
# M4p8XUUtS7FQ5kE6N1aG3JMjjfdQJehk5t3Tjy9XtYcg6w6OLNUj2vRNeEbjA4Mx
# KUpcDDGKSoyIxfcwWvkUrxVfbENJCf0mI1P2jWPoGqtbsR0wwptpgrTb/FZUvB+h
# h6u+elsKIC9LCcmVp42y+tZji06lchzun3oBc/gZ1v4NSYS9AQIDAQABo4IBuDCC
# AbQwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwQQYDVR0gBDowODA2BglghkgBhv1sBwEwKTAnBggrBgEFBQcCARYb
# aHR0cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMB8GA1UdIwQYMBaAFPS24SAd/imu
# 0uRhpbKiJbLIFzVuMB0GA1UdDgQWBBQ2RIaOpLqwZr68KC0dRDbd42p6vDBxBgNV
# HR8EajBoMDKgMKAuhixodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1
# cmVkLXRzLmNybDAyoDCgLoYsaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTIt
# YXNzdXJlZC10cy5jcmwwgYUGCCsGAQUFBwEBBHkwdzAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuZGlnaWNlcnQuY29tME8GCCsGAQUFBzAChkNodHRwOi8vY2FjZXJ0
# cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNzdXJlZElEVGltZXN0YW1waW5n
# Q0EuY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQBIHNy16ZojvOca5yAOjmdG/UJyUXQK
# I0ejq5LSJcRwWb4UoOUngaVNFBUZB3nw0QTDhtk7vf5EAmZN7WmkD/a4cM9i6PVR
# Snh5Nnont/PnUp+Tp+1DnnvntN1BIon7h6JGA0789P63ZHdjXyNSaYOC+hpT7ZDM
# jaEXcw3082U5cEvznNZ6e9oMvD0y0BvL9WH8dQgAdryBDvjA4VzPxBFy5xtkSdgi
# mnUVQvUtMjiB2vRgorq0Uvtc4GEkJU+y38kpqHNDUdq9Y9YfW5v3LhtPEx33Sg1x
# fpe39D+E68Hjo0mh+s6nv1bPull2YYlffqe0jmd4+TaY4cso2luHpoovMIIFMTCC
# BBmgAwIBAgIQCqEl1tYyG35B5AXaNpfCFTANBgkqhkiG9w0BAQsFADBlMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0Ew
# HhcNMTYwMTA3MTIwMDAwWhcNMzEwMTA3MTIwMDAwWjByMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5n
# IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvdAy7kvNj3/dqbqC
# mcU5VChXtiNKxA4HRTNREH3Q+X1NaH7ntqD0jbOI5Je/YyGQmL8TvFfTw+F+CNZq
# FAA49y4eO+7MpvYyWf5fZT/gm+vjRkcGGlV+Cyd+wKL1oODeIj8O/36V+/OjuiI+
# GKwR5PCZA207hXwJ0+5dyJoLVOOoCXFr4M8iEA91z3FyTgqt30A6XLdR4aF5FMZN
# JCMwXbzsPGBqrC8HzP3w6kfZiFBe/WZuVmEnKYmEUeaC50ZQ/ZQqLKfkdT66mA+E
# f58xFNat1fJky3seBdCEGXIX8RcG7z3N1k3vBkL9olMqT4UdxB08r8/arBD13ays
# 6Vb/kwIDAQABo4IBzjCCAcowHQYDVR0OBBYEFPS24SAd/imu0uRhpbKiJbLIFzVu
# MB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHkGCCsG
# AQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29t
# MEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8v
# Y3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqg
# OKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3JsMFAGA1UdIARJMEcwOAYKYIZIAYb9bAACBDAqMCgGCCsGAQUFBwIB
# FhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAsGCWCGSAGG/WwHATANBgkq
# hkiG9w0BAQsFAAOCAQEAcZUS6VGHVmnN793afKpjerN4zwY3QITvS4S/ys8DAv3F
# p8MOIEIsr3fzKx8MIVoqtwU0HWqumfgnoma/Capg33akOpMP+LLR2HwZYuhegiUe
# xLoceywh4tZbLBQ1QwRostt1AuByx5jWPGTlH0gQGF+JOGFNYkYkh2OMkVIsrymJ
# 5Xgf1gsUpYDXEkdws3XVk4WTfraSZ/tTYYmo9WuWwPRYaQ18yAGxuSh1t5ljhSKM
# Ycp5lH5Z/IwP42+1ASa2bKXuh1Eh5Fhgm7oMLSttosR+u8QlK0cCCHxJrhO24XxC
# QijGGFbPQTS2Zl22dHv1VjMiLyI2skuiSpXY9aaOUjGCBAAwggP8AgEBMCswFzEV
# MBMGA1UEAwwMQXV0aGVudGljb2RlAhATobyc/ovQoU6OtPepK32+MAkGBSsOAwIa
# BQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgor
# BgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3
# DQEJBDEWBBRT3qC31ZILXj0BhtHftjXOoNqSKDANBgkqhkiG9w0BAQEFAASCAQCG
# htjgCMtdYC7qL//1UekqQt0nWu4kfNKy7Zr3di53bJZciPYQ0Nqk4m8HivFw+IEm
# xkbi2rxMgX4ngMUUP6e/apfdPBMjE0++kBL7D1fsEW4Rs2RDkPK+7PFAbtuuoLq4
# 8i4jaqpXn/7WPTOwvEnrjHQaiWUNmAalEZRR+QnTNHfSzzaz5hZBxUZK0zRHt66P
# PAR8pqNxRPzPGDJnw2rvcucW4nmiFregAyUtHcdUpqbkTVLbeU1ri2Dw4mA9G/DF
# jAYWa0A+oP3H7GWmDW4Oy1YpMLXkxb4ULOSXEChN0T+0uJWX76pwjTEkIFjIe6pV
# petvwwo46syA3utMDy1noYICMDCCAiwGCSqGSIb3DQEJBjGCAh0wggIZAgEBMIGG
# MHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT
# EHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJl
# ZCBJRCBUaW1lc3RhbXBpbmcgQ0ECEA1CSuC+Ooj/YEAhzhQA8N0wDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yMTEyMzExMTQzNTJaMC8GCSqGSIb3DQEJBDEiBCCnyycjdZJ5g6EIoflnn4as
# KRjhiJKy1Swbt7hsY3QKhTANBgkqhkiG9w0BAQEFAASCAQAGefsJPqZUOWYycJ3v
# uVStHsWxmMBqgNB2bPSLvI/Dn1bFeF1E+NLX0Pl7va1oKwU+tjS7EUIr2ku/HTOp
# AFf8IaoDBQonF5e8cAuvGRbB7RXDkeVIoSCm3iZGGqiP/kiwQhIWD+cPZJwvqVXb
# qrT98sjkSg5KpJnwHNV0ZkUlMlmbYwVB8DzkkofVYQEOQ3xOTiyjR9mVKNWzfx4j
# XlGMc6AteAOtghoFLG70BsQgmMuQrtE9NOa+yn587VlxJnxD4rjPNd/dOEBIPqJD
# cV3In9Au4e5mXeKwdHMmzUU6hKCbDVSUj5PDNLvUu/fdhxhzSMs6LM4q6gpP8Gq5
# HQF6
# SIG # End signature block

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
    Write-Output $FilesNames
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
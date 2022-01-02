1. ## What is \$_ ?

   \$_ Is the same as $PSItem and their value is the current object in pipeline. For example in the following code
   `1..10 | Where {$_ -gt 5 -and $PSItem -lt 7}`


    both \$_ and $PSItem recieve the values of 1 in the first iteration, 2 in the next iteration, and so on.
    So the condition will evaluate to true on the sixth iteration when their value is 6.

2. ## How many Output Streams are in Powershell ?

   Powershell has 7 output streams. There is a special character * that refers to all the streams.
3. ## What is the difference between Write-Host vs Write-Output, Write-Error, Write-Warning, Write-Debug ?

   The differences are their logical role, and where you can access the data of the stream.
   Each stream has a different number,
   and data sent to one stream won't be available in another stream, unless explicitly specified.
   For example, Write-Host will always output to the terminal that it was typed in, and won't be redirected into a file or another pipeline.
   Also, Write-Host allows to optionally write with different colors, which is why I chose to use it in the task.

# powershell-print-file
An interactive powershell script that lists all files in a given directory and print the content of any particular file that you choose

## How to use
1. Go to the repository \<code\> tab
2. In the Code dropdown, click Download ZIP
3. Extract the zip in your folder of choice
4. Open powershell in that folder and run .\print-file.ps1
5. If you can't run the script, use `UnblockFile -Path .\print-file.ps1` or `Set-ExecutionPolicy AllSigned` to grant permission to execute

## EXAMPLE
### Execute the script
Run `.\print-file.ps1`
![image](https://user-images.githubusercontent.com/51367111/147822535-e87d9d78-0c30-4bf9-910b-c80ed6c19311.png)
You can see the main menu

### Choose any file from the list
for example, type 8
![image](https://user-images.githubusercontent.com/51367111/147822577-ac4dc3d4-70b4-4ac4-8750-3207ede57292.png)

### Confirm
type y or yes to confirm. The content of the file will be printed with numbered lines
![image](https://user-images.githubusercontent.com/51367111/147822808-4926a4e8-be0b-4f83-8460-dc1f594934c5.png)

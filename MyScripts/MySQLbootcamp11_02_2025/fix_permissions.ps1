$KeyFile = Read-Host -Prompt "Enter the key file to fix"

Write-Host "Working path $pwd"

if ( (Test-Path -Path $KeyFile) ) {
   $Confirmation = Read-Host -Prompt "Are you sure that you want to fix the file $KeyFile ? [y/N] "

   if ( $Confirmation -eq "y" ) {
      Write-Host "Fixing $KeyFile"

      Icacls $KeyFile /c /t /Inheritance:d

      Icacls $KeyFile /c /t /Grant ${env:UserName}:F
      
      TakeOwn /F $KeyFile
      
      Icacls $KeyFile /c /t /Grant:r ${env:UserName}:F
      
      Icacls $KeyFile /c /t /Remove:g Administrator "Authenticated Users" BUILTIN\Administrators BUILTIN Everyone System Users
      
      Icacls $KeyFile
      
      Write-Host "File $KeyFile fixed"

   } else {
      Write-Host "Execution aborted by user"
   }
   
}else {
      Write-Warning "File $KeyFile not found"
}



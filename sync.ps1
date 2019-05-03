$source_folder = 'C:\Users\sn0wflake\Videos\'
$destination_folder = '\\DESKTOP-COMPUTER\Users\sn0wflake\Videos\'

# Step 1. Copy from source to destination.
Get-ChildItem -LiteralPath $source_folder -Recurse | ForEach-Object {
    $destination_file = "$($destination_folder)$($_.FullName.Replace($source_folder,''))"

    if(Test-Path -LiteralPath $destination_file) {
        if($_.Attributes -ne 'Directory') {
            if((Get-ChildItem -LiteralPath $destination_file).Length -ne (Get-ChildItem -LiteralPath $_.FullName).Length) { # Compare file sizes.
                Write-Host "File size different. OVERWRITING $($_)"
                Copy-Item -LiteralPath $_.FullName -Destination $destination_file
                } elseif((Get-ChildItem -LiteralPath $destination_file).Length -lt 99999999) { # Bigger mumber = more CPU + network traffic.
                if((Get-FileHash -LiteralPath $_.FullName).Hash -ne (Get-FileHash -LiteralPath $destination_file).Hash) { # Compare hashes.
                    Write-Host "Hash code different. OVERWRITING $($_)"
                    Copy-Item -LiteralPath $_.FullName -Destination $destination_file
                }
            }
        }
        } else {
        # Copy error over network wont throw an error, so validate afterwards.
        Write-Host "Target does not exist. COPY FILE $($_)"
        Copy-Item -LiteralPath $_.FullName -Destination $destination_file

        # Validate copy process.
        if(Test-Path -LiteralPath $destination_file) {
            # Path was found. Do hash check.
            if((Get-FileHash $_.FullName).Hash -ne (Get-FileHash $destination_file).Hash) {
                Write-Host "ERROR COPYING FILE $($_)"
                break;
            }
            # Path was not found. I/O error.
            } else {
            Write-Host "ERROR COPYING FILE $($_)"
            break;
        }
    }
}

# Step 2. Cleanup destination. Rename items instead of deleting due to no recycle bin support over network.
Get-ChildItem -LiteralPath $destination_folder -Recurse | ForEach-Object {
    if($_.Extension -ne '.DELETE') {
        if(!(Test-Path -LiteralPath $_.FullName.Replace($destination_folder,$source_folder))) {
            Write-Host "Source item no longer exists. RENAMING $($_.FullName)"
            Rename-Item -LiteralPath $_.FullName -NewName "$($_.FullName).DELETE"
        }
    }
}
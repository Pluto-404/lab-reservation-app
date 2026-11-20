# Script untuk menyemai (seed) data laboratorium awal ke Firestore
# Project: bookinglab-3c4cb

$projectId = "bookinglab-3c4cb"
$baseUrl = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/laboratories"

$labs = @(
    @{
        id = "lab-komputer-a"
        fields = @{
            lab_id = @{ stringValue = "lab-komputer-a" }
            name = @{ stringValue = "Lab Komputer A" }
            building = @{ stringValue = "Gedung E FKIP Lantai 2" }
            capacity = @{ integerValue = 35 }
            facilities = @{
                arrayValue = @{
                    values = @(
                        @{ stringValue = "35 Unit PC Core i7" },
                        @{ stringValue = "AC 2 Unit" },
                        @{ stringValue = "Proyektor & Screen" },
                        @{ stringValue = "Whiteboard" },
                        @{ stringValue = "Internet Gigabit LAN & Wi-Fi" },
                        @{ stringValue = "Sound System & Mic" }
                    )
                }
            }
            operational_hours = @{ stringValue = "08:00 - 16:00" }
            is_active = @{ booleanValue = $true }
            image_url = @{ nullValue = $null }
        }
    },
    @{
        id = "lab-komputer-b"
        fields = @{
            lab_id = @{ stringValue = "lab-komputer-b" }
            name = @{ stringValue = "Lab Komputer B" }
            building = @{ stringValue = "Gedung E FKIP Lantai 2" }
            capacity = @{ integerValue = 35 }
            facilities = @{
                arrayValue = @{
                    values = @(
                        @{ stringValue = "35 Unit PC Core i5" },
                        @{ stringValue = "AC 2 Unit" },
                        @{ stringValue = "Proyektor & Screen" },
                        @{ stringValue = "Whiteboard" },
                        @{ stringValue = "Internet Gigabit LAN & Wi-Fi" },
                        @{ stringValue = "Audio Monitor" }
                    )
                }
            }
            operational_hours = @{ stringValue = "08:00 - 16:00" }
            is_active = @{ booleanValue = $true }
            image_url = @{ nullValue = $null }
        }
    }
)

foreach ($lab in $labs) {
    $id = $lab.id
    $body = @{ fields = $lab.fields } | ConvertTo-Json -Depth 6
    Write-Host "Menambahkan $id ($($lab.fields.name.stringValue))..."
    $uri = "$baseUrl?documentId=$id"
    try {
        $res = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
        Write-Host "Berhasil menambahkan $id!" -ForegroundColor Green
    } catch {
        # Jika sudah ada, lakukan PATCH update
        $patchUri = "$baseUrl/$id"
        $res = Invoke-RestMethod -Uri $patchUri -Method Patch -Body $body -ContentType "application/json"
        Write-Host "Berhasil memperbarui $id!" -ForegroundColor Cyan
    }
}

Write-Host "`nSelesai menyemai data laboratorium." -ForegroundColor Green

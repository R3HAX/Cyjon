del /F /Q build\disk.vdi

virtualbox\VBoxManage.exe convertfromraw build\disk.raw build\disk.vdi --format VDI --uuid "12345678-1234-1234-1234-123456789087"

pause
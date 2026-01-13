$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<session xmlns="http://winscp.net/schema/session/1.0" name="test" start="2023-01-01T12:00:00.000Z">
  <ls>
    <destination value="/remote/path" />
    <file>
      <filename value="." />
      <type value="d" />
      <modification value="2023-01-01T12:00:00.000Z" />
      <permissions value="rwxr-xr-x" />
    </file>
    <file>
      <filename value="karton-dev_0.7.260121805.apk" />
      <type value="-" />
      <size value="12345" />
      <modification value="2023-01-01T12:00:00.000Z" />
      <permissions value="rw-r--r--" />
    </file>
  </ls>
</session>
"@

$Pattern = "karton-dev_*.apk"
[xml]$xml = $xmlContent

# Simulate OLD logic (Fail)
Write-Host "--- OLD LOGIC ---"
$fileNodes = $xml.SelectNodes("//file") 
# Note: XPath is namespace sensitive in SelectNodes usually, but let's see. 
# WinSCP uses namespace, so //file might fail without namespace manager if not using local-name()
# But PowerShell adaptors sometimes help.

# Using property access
$fileNodes = $xml.session.ls.file
foreach ($node in $fileNodes) {
    # Check what properties exist
    # Write-Host "Checking node: $($node.filename)" 
    # This outputs System.Xml.XmlElement if using .filename directly without .value
    
    if ($node.type -eq "file" -and $node.filename -like $Pattern) {
        Write-Host "MATCH: $($node.filename)"
    } else {
        Write-Host "NO MATCH: Type='$($node.type)' Filename='$($node.filename)'"
    }
}

# Simulate NEW logic (Pass)
Write-Host "`n--- NEW LOGIC ---"
$fileNodes = $xml.session.ls.file
foreach ($node in $fileNodes) {
    $name = $node.filename.value
    $type = $node.type.value
    
    if ($type -eq "-" -and $name -like $Pattern) {
        Write-Host "MATCH: $name"
    } else {
        Write-Host "NO MATCH: Type='$type' Filename='$name'"
    }
}

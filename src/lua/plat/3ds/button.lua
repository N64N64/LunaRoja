function Button.Scan()
    C.hidScanInput()
    Button.KeysDown = C.hidKeysDown()
    Button.KeysUp = C.hidKeysUp()
    Button.KeysHeld = C.hidKeysHeld()
end

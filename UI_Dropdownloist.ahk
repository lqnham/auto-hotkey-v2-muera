#Requires AutoHotkey v2.0

; Global variables
global delayUp := 145
global delayDown := 90
global running := false
global selectedHwnd := 0
global hwndList := Map()

; Create GUI
MyGui := Gui()
MyGui.Add("Text", , "Enter delay for WheelUp (ms):")
delayUpInput := MyGui.Add("Edit", "vDelayUp", delayUp)
MyGui.Add("Text", , "Enter delay for WheelDown (ms):")
delayDownInput := MyGui.Add("Edit", "vDelayDown", delayDown)
MyGui.Add("Button", "default", "Save Settings").OnEvent("Click", ProcessUserInput)

MyGui.Add("Text", , "Select an LDPlayer window:")
windowList := myGui.Add("DropDownList", "w300")
hwndList := Map()

for hwnd in WinGetList() {
    title := WinGetTitle(hwnd)
    if InStr(title, "LDP_MU_") = 1 {
        windowList.Add([title])
        hwndList[title] := hwnd
    }
}

windowList.OnEvent("Change", WindowSelected)
WindowSelected(ctrl, info) {
    global windowList, hwndList, selectedHwnd
    choice := windowList.Text
    if hwndList.Has(choice) {
        selectedHwnd := hwndList[choice]
        ToolTip("✅ Selected window: " choice, 10, 30)
    } else {
        selectedHwnd := 0
        ToolTip("❌ Could not identify the window!", 10, 30)
    }
    SetTimer(() => ToolTip(), -1500)
}


MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show()

; Toggle scrolling with right-click
; Right click to start/stop scrolling
~RButton:: {
    global running
    running := !running
    if (running) {
        ToolTip("🔁 Scrolling started", 10, 10)
        SetTimer(() => ToolTip(), -1000)
        SetTimer(() => SpinWheelLoop(), 10)
    } else {
        ToolTip("⏹️ Scrolling stopped", 10, 10)
        SetTimer(() => ToolTip(), -1000)
        SetTimer(() => SpinWheelLoop(), 10)
    }
}


; Save delay settings
ProcessUserInput(*) {
    global delayUp, delayDown
    delayUp := Integer(delayUpInput.Text)
    delayDown := Integer(delayDownInput.Text)
    ToolTip("✅ Settings saved", 10, 50)
    SetTimer(() => ToolTip(), -1000)
}

; Scrolling loop for the selected window
SpinWheelLoop() {
    global running, delayUp, delayDown, selectedHwnd
    static lastTime := 0

    if (!running || !selectedHwnd)
        return

    WinActivate(selectedHwnd)

    currentTime := A_TickCount
    if (currentTime - lastTime >= 140) {
        WinGetPos(&x, &y, &w, &h, selectedHwnd)
        Send("{WheelUp}")
        Sleep(delayUp)
        Send("{WheelDown}")
        Sleep(delayDown)

        lastTime := currentTime
    }
}

; Send mouse wheel event to the selected window
MouseWheel(direction) {
    global selectedHwnd
    if (!selectedHwnd)
        return
    WM_MOUSEWHEEL := 0x020A
    delta := 120 * direction
    MouseGetPos(&x, &y)
    hwnd := DllCall("WindowFromPoint", "int64", (y << 32) | (x & 0xFFFFFFFF), "ptr")
    if (!hwnd)
        return
    PostMessage(WM_MOUSEWHEEL, delta << 16, 0, selectedHwnd)
}

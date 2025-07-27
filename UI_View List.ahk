#Requires AutoHotkey v2.0

global delayUp := 145
global delayDown := 90
global running := false
global hwndList := Map()
global MyGui, windowList

; GUI setup
MyGui := Gui()
MyGui.Add("Text", , "Select LDPlayer windows:")
windowList := MyGui.Add("ListView", "w400 r8 Checked", ["Window Title"])

MyGui.Add("Text", "xm section", "Delay Lăn lên (ms):     ")
delayUpInput := MyGui.Add("Edit", "x+10 w100 h25 Number", delayUp)
MyGui.Add("UpDown", "Range1-1000", delayUp)

MyGui.Add("Text", "xs y+15", "Delay Lăn xuống (ms):")
delayDownInput := MyGui.Add("Edit", "x+10 w100 h25 Number", delayDown)
MyGui.Add("UpDown", "Range1-1000", delayDown)

MyGui.Add("Button", "default", "Save Settings").OnEvent("Click", ProcessUserInput)

; Populate ListView with LDPlayer windows
for hwnd in WinGetList() {
    title := WinGetTitle(hwnd)
    if InStr(title, "LDP_MU_") = 1 {
        hwndList[title] := hwnd
        windowList.Add("", title)
    }
}

MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show()

; Save delay
ProcessUserInput(*) {
    global delayUp, delayDown
    delayUp := Integer(delayUpInput.Text)
    delayDown := Integer(delayDownInput.Text)
    ToolTip("✅ Settings saved", 10, 50)
    SetTimer(() => ToolTip(), -1000)
}

; Toggle with right-click
~RButton:: {
    global running
    running := !running
    if (running) {
        ToolTip("🔁 Scrolling started", 10, 10)
        SetTimer(() => ToolTip(), -1000)
        SetTimer(SpinWheelLoop, 10)
    } else {
        ToolTip("⏹️ Scrolling stopped", 10, 10)
        SetTimer(() => ToolTip(), -1000)
        SetTimer(SpinWheelLoop, 0)
    }
}

SpinWheelLoop() {
    global running, delayUp, delayDown, hwndList, windowList
    static lastTime := 0
    if (!running)
        return

    currentTime := A_TickCount
    if (currentTime - lastTime < 140)
        return

    ; Lấy chỉ số từng hàng được check
    row := 0
    while (row := windowList.GetNext(row, "Checked")) {
        title := windowList.GetText(row)
        if hwndList.Has(title) {
            hwnd := hwndList[title]
            if WinExist("ahk_id " hwnd) {
                Send("{WheelUp}")
                Sleep(delayUp)
                Send("{WheelDown}")
                Sleep(delayDown)
            }
        }
    }

    lastTime := currentTime
}

#Requires AutoHotkey v2.0

global delayUp := 145
global delayDown := 90
global configFile := "config_history.ini"
global running := false
global hwndList := Map()
global MyGui, windowList, configListView

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

MyGui.Add("Button", "default xm", "Save Settings").OnEvent("Click", ProcessUserInput)

MyGui.Add("Text", "xs y+10", "📜 Lịch sử cấu hình đã lưu:")
configListView := MyGui.Add("ListView", "xs w220 r6", ["DelayUp", "DelayDown"])
configListView.OnEvent("Click", ConfigSelected)

; Load history
LoadConfigHistory()

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

; Process Save Settings
ProcessUserInput(*) {
    global delayUp, delayDown
    delayUp := Integer(delayUpInput.Text)
    delayDown := Integer(delayDownInput.Text)

    SaveConfig(delayUp, delayDown)
    ToolTip("✅ Settings saved", 10, 50)
    SetTimer(() => ToolTip(), -1000)
}

; Save to file and update config list
SaveConfig(up, down) {
    global configFile, configListView

    section := Format("Config{}", A_Now)
    IniWrite(up, configFile, section, "delayUp")
    IniWrite(down, configFile, section, "delayDown")

    configListView.Add(, up, down)
}

; Load config history from file
LoadConfigHistory() {
    global configFile, configListView
    configListView.Delete()

    if !FileExist(configFile)
        return

    sections := IniRead(configFile)
    for section in StrSplit(sections, "`n") {
        up := IniRead(configFile, section, "delayUp", "")
        down := IniRead(configFile, section, "delayDown", "")
        if (up != "" && down != "")
            configListView.Add(, up, down)
    }
}

; When user selects a saved config
ConfigSelected(LV, Row) {
    global delayUpInput, delayDownInput
    up := LV.GetText(Row, 1)
    down := LV.GetText(Row, 2)
    delayUpInput.Text := up
    delayDownInput.Text := down
}

; Toggle scroll on/off with right-click
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

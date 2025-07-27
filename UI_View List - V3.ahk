#Requires AutoHotkey v2.0

global delayUp := 145
global delayDown := 90
global configFile := "config_history.ini"
global running := false
global hwndList := Map()
global MyGui, windowList, configListView, labelInput

; GUI setup
MyGui := Gui()
SetWindowIcon(MyGui, "tychuot.ico")
MyGui.Add("Text", , "🪟 Chọn cửa sổ LDPlayer:")
windowList := MyGui.Add("ListView", "w400 r8 Checked", ["Window Title"])

MyGui.Add("Text", "xs y+10", "⏫ Delay lăn lên (ms):")
delayUpInput := MyGui.Add("Edit", "x+10 w100 h25 Number", delayUp)
MyGui.Add("UpDown", "Range1-1000", delayUp)

MyGui.Add("Text", "xs y+10", "⏬ Delay lăn xuống (ms):")
delayDownInput := MyGui.Add("Edit", "x+10 w100 h25 Number", delayDown)
MyGui.Add("UpDown", "Range1-1000", delayDown)

MyGui.Add("Text", "xs y+10", "🏷️ Tên cấu hình:")
labelInput := MyGui.Add("Edit", "xs w250", "")

MyGui.Add("Button", "default xs y+10", "💾 Lưu cấu hình").OnEvent("Click", ProcessUserInput)
MyGui.Add("Text", "xs y+10", "📜 Lịch sử cấu hình:")
configListView := MyGui.Add("ListView", "xs w400 r6", ["Tên", "DelayUp", "DelayDown"])
configListView.ModifyCol(1, 180)  ; Cột "Tên"
configListView.ModifyCol(2, 80)   ; DelayUp
configListView.ModifyCol(3, 80)   ; DelayDown

configListView.OnEvent("Click", ConfigSelected)

MyGui.Add("Text", "xs y+10 cGray", "© Bản quyền thuộc về Tý Chuột")
; Load LDPlayer windows
for hwnd in WinGetList() {
    title := WinGetTitle(hwnd)
    if InStr(title, "LDP_MU_") = 1 {
        hwndList[title] := hwnd
        windowList.Add("", title)
    }
}

; Load cấu hình đã lưu từ file
LoadConfigHistory()

; Event khi đóng GUI
MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show()

; ----------- FUNCTION -----------

ProcessUserInput(*) {
    global delayUp, delayDown
    delayUp := Integer(delayUpInput.Text)
    delayDown := Integer(delayDownInput.Text)
    SaveConfig(delayUp, delayDown)
    ToolTip("✅ Đã lưu cấu hình!", 10, 50)
    SetTimer(() => ToolTip(), -1000)
}

SaveConfig(up, down) {
    global configFile, configListView, labelInput

    label := Trim(labelInput.Text)
    if (label = "")
        label := Format("Cấu hình {}", A_Now)
    safeLabel := StrReplace(label, "`n", "")

    IniWrite(up, configFile, safeLabel, "delayUp")
    IniWrite(down, configFile, safeLabel, "delayDown")

    ; Tránh thêm trùng tên cấu hình
    count := configListView.GetCount()
    Loop count {
        if (configListView.GetText(A_Index, 1) = safeLabel)
            return  ; Đã có rồi, không thêm lại
    }

    configListView.Add(, safeLabel, up, down)
}

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
            configListView.Add(, section, up, down)
    }
}

ConfigSelected(LV, Row) {
    global delayUpInput, delayDownInput, labelInput
    label := LV.GetText(Row, 1)
    up := LV.GetText(Row, 2)
    down := LV.GetText(Row, 3)
    delayUpInput.Text := up
    delayDownInput.Text := down
    labelInput.Text := label
}

; Toggle auto scroll bằng chuột phải
~RButton:: {
    global running
    running := !running
    if (running) {
        ToolTip("🔁 Đang tự cuộn...", 10, 10)
        SetTimer(() => ToolTip(), -1000)
        SetTimer(SpinWheelLoop, 10)
    } else {
        ToolTip("⏹️ Đã dừng cuộn", 10, 10)
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

SetWindowIcon(guiObj, iconPath) {
    hIcon := LoadPicture(iconPath, "Icon1 w32 h32", &imgType)
    if !hIcon {
        MsgBox "Không thể load icon: " iconPath
        return
    }
    WM_SETICON := 0x80
    SendMessage(WM_SETICON, 0, hIcon, guiObj.Hwnd)
}

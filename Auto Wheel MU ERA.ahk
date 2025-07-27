#Requires AutoHotkey v2.0

; ================= Global variable =================
global delayUp := 0
global delayDown := 0
global configFile := "config_history.ini"
global running := false
global hwndList := Map()
global MyGui, windowList, configListView, labelInput

; ================= GUI setup =================
MyGui := Gui()
SetWindowIcon(MyGui, "tychuot.ico")


MyGui.Add("Text", , "🪟 Chọn cửa sổ LDPlayer:")
windowList := MyGui.Add("ListView", "x10 y+0 w400 r5 Checked vWindowLV", ["Window Title"])
MyGui.Opt("+Resize +MinSize300x200")


MyGui.Add("Text", "x10 y+10 w120", "⏫ Delay lăn lên (ms):")
delayUpInput := MyGui.Add("Edit", "x+10 w100 h25 Number", delayUp)
MyGui.Add("UpDown", "Range1-1000", delayUp)


MyGui.Add("Text", "x10 y+10 w120", "⏬ Delay lăn xuống (ms):")
delayDownInput := MyGui.Add("Edit", "x+10 w100 h25 Number", delayDown)
MyGui.Add("UpDown", "Range1-1000", delayDown)


MyGui.Add("Text", "x10 y+10 w120", "🏷️ Config name:")
labelInput := MyGui.Add("Edit", "x+10 w200", "")
MyGui.Add("Button", "x+10", "💾 Save").OnEvent("Click", ProcessUserInput)


MyGui.Add("Text", "xs y+10", "📜 Lịch sử cấu hình:")
configListView := MyGui.Add("ListView", "xs w400 r6", ["Tên", "Lăn lên", "Lăn xuống"])
configListView.ModifyCol(1, 180)
configListView.ModifyCol(2, 50)
configListView.ModifyCol(3, 65)


MyGui.Add("Text", "xs y+10 cGray", "© Bản quyền thuộc về Tý Chuột")


; ================== Custom tooltips
global tipGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
tipGui.BackColor := "Yellow" 
ToolTipCustom(text, x := 10, y := 10) {
    global tipGui

    tipGui.Destroy()  ; Xóa GUI cũ nếu có
    tipGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    tipGui.BackColor := "Yellow"
    tipGui.SetFont("s12 Bold", "Segoe UI")
    tipGui.Add("Text", "Center cRed", text)
    ;MouseGetPos(&x, &y)
    tipGui.Show("NoActivate x" x " y" y)
    SetTimer(() => tipGui.Hide(), -500)
}


; =================>>>>>>>>>>>> Event <<<<<<<<<<<<=================


configListView.OnEvent("Click", ConfigSelected)
MyGui.OnEvent("Close", (*) => ExitApp())

SetWindowIcon(guiObj, iconPath) {
    hIcon := LoadPicture(iconPath, "Icon1 w32 h32", &imgType)
    if !hIcon {
        MsgBox "Không thể load icon: " iconPath
        return
    }
    WM_SETICON := 0x80
    SendMessage(WM_SETICON, 0, hIcon, guiObj.Hwnd)
}


; Load LDPlayer windows 
for hwnd in WinGetList() {
    title := WinGetTitle(hwnd)
    if InStr(title, "LDP_MU_") = 1 {
        hwndList[title] := hwnd
        windowList.Add("", title)
    }
}

LoadConfigHistory()
LoadFirstConfig()
MyGui.Show()
; =================>>>>>>>>>>>> Function <<<<<<<<<<<<=================


; Khi Trigger chuột phải
~RButton:: {
    global running
    running := !running
    if (running) {
        ToolTipCustom("🔁 RUNNING", 40, 40)
        
        SetTimer(SpinWheelLoop, 10)
    } else {
        ToolTipCustom("⏹️ STOP", 40, 30)
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


ProcessUserInput(*) {
    global delayUp, delayDown
    upText := Trim(delayUpInput.Text)
    downText := Trim(delayDownInput.Text)
    
    if !IsInteger(upText) || !IsInteger(downText) {
        MsgBox("❌ Vui lòng nhập số hợp lệ cho thời gian delay.")
        return
    }

    delayUp := Integer(upText)
    delayDown := Integer(downText)
    
    SaveConfig(delayUp, delayDown)
    ToolTipCustom("✅ Đã lưu cấu hình!", 10, 50)
    SetTimer(() => ToolTip(), -1000)
}

IsInteger(val) {
    return val ~= "^-?\d+$"
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


ConfigSelected(LV, Row) {
    global delayUpInput, delayDownInput, labelInput
    label := LV.GetText(Row, 1)
    up := LV.GetText(Row, 2)
    down := LV.GetText(Row, 3)
    delayUpInput.Text := up
    delayDownInput.Text := down
    labelInput.Text := label
}



LoadFirstConfig() {
    global configFile, delayUp, delayDown, delayUpInput, delayDownInput, labelInput, configListView

    if !FileExist(configFile)
        return

    sections := IniRead(configFile)
    sectionList := StrSplit(sections, "`n")
    if (sectionList.Length = 0)
        return

    firstSection := sectionList[1]
    up := IniRead(configFile, firstSection, "delayUp", "")
    down := IniRead(configFile, firstSection, "delayDown", "")
    
    if (up != "" && down != "") {
        delayUp := Integer(up)
        delayDown := Integer(down)

        delayUpInput.Text := up
        delayDownInput.Text := down
        labelInput.Text := firstSection
    }
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




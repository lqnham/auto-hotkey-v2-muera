#Requires AutoHotkey v2.0


ProcessUserInput(*) {
    global delayUp, delayDown, delayUpInput, delayDownInput, MyGui

    delayUp := Integer(delayUpInput.Text)
    delayDown := Integer(delayDownInput.Text)

    MyGui.Hide()
    MsgBox "✅ Đã lưu cài đặt. Bấm chuột phải để bật/tắt cuộn."
}

running := false
delayUp := 140  ; Delay mặc định cho WheelUp
delayDown := 80  ; Delay mặc định cho WheelDown

; Tạo giao diện người dùng để nhập delay
MyGui := Gui()  ; Tạo đối tượng GUI
MyGui.Add("Text", , "Nhập delay cho WheelUp (ms):")
delayUpInput := MyGui.Add("Edit", "vDelayUp", delayUp)
MyGui.Add("Text", , "Nhập delay cho WheelDown (ms):")
delayDownInput := MyGui.Add("Edit", "vDelayDown", delayDown)

; Tạo nút và gán sự kiện khi nút được nhấn
MyGui.Add("Button", "default", "OK").OnEvent("Click", ProcessUserInput)
MyGui.OnEvent("Close", ProcessUserInput)


MyGui.Show()

return

SaveSettings()
{
    global delayUp, delayDown, delayUpInput, delayDownInput, MyGui
    MyGui.Submit()  ; Lưu giá trị nhập vào các biến
    delayUp := delayUpInput.Value
    delayDown := delayDownInput.Value
    MyGui.Destroy()  ; Đóng giao diện
    MsgBox("Cài đặt đã được lưu.")
}


~RButton::
{
    global running, delayUp, delayDown
    running := !running

    if (running) {
        Tooltip("🔁 Đang cuộn liên tục", 10, 10)
        SetTimer(() => Tooltip(), -1000)
        SetTimer(SpinWheelLoop, 1) ; Gọi liên tục càng nhanh càng tốt
    } else {
        Tooltip("⏹️ Đã dừng", 10, 10)
        SetTimer(() => Tooltip(), -1000)
        SetTimer(SpinWheelLoop, 0) ; Dừng
    }
}

SpinWheelLoop()
{
    global running, delayUp, delayDown
    static lastTime := 0

    if (!running)
        return

    currentTime := A_TickCount
    if (currentTime - lastTime >= 140) { ; tổng delay 140ms
        MouseWheel(1)   ; WheelUp
        Sleep(delayUp)  ; Delay giữa các WheelUp
        MouseWheel(-1)  ; WheelDown
        Sleep(delayDown) ; Delay giữa các WheelDown
        lastTime := currentTime
    }
}

MouseWheel(direction)
{
    WM_MOUSEWHEEL := 0x020A
    delta := 120 * direction

    ; Lấy vị trí của chuột
    MouseGetPos(&x, &y)

    ; Lấy cửa sổ tại vị trí chuột
    hwnd := DllCall("WindowFromPoint", "int64", (y << 32) | (x & 0xFFFFFFFF), "ptr")
    
    ; Kiểm tra xem có lấy được cửa sổ không
    if (!hwnd)
        return

    ; Gửi sự kiện cuộn chuột tới cửa sổ
    PostMessage(WM_MOUSEWHEEL, delta << 16, 0, hwnd)
}


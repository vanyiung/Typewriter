#Requires AutoHotkey v2.0

currentHotkey := "F8"
delayedHotkey := "F9"
delayMsValue := 3000
typeSpeedValue := 30

appName := "Typewriter"
appVersion := "v1.0.0"
appAuthor := "vanyiung"
appGithub := "https://github.com/vanyiung/Typewriter-"
appIcon := A_ScriptDir "\Typewriter.ico"


; 配置文件用于保存用户偏好（例如始终置顶）
settingsFile := A_ScriptDir "\\typewriter.ini"
saved := IniRead(settingsFile, "Main", "AlwaysOnTop", "")
if saved = ""
	isAlwaysOnTop := true
else
	isAlwaysOnTop := (saved = "1")

; ===== 开机自启状态 =====
autoStartPath := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "Typewriter", "")
isAutoStart := (autoStartPath != "")

mainGui := Gui(, "Typewriter")
mainGui.SetFont("s10")

; ===== 菜单栏 =====
viewMenu := Menu()
viewMenu.Add("始终置顶", ToggleAlwaysOnTop)
viewMenu.Add("开机自启", ToggleAutoStart)

settingsMenu := Menu()
settingsMenu.Add("快捷键设置", OpenSettings)

helpMenu := Menu()
helpMenu.Add("关于", ShowAbout)

mainMenuBar := MenuBar()
mainMenuBar.Add("置顶与自启", viewMenu)
mainMenuBar.Add("快捷键设置", settingsMenu)
mainMenuBar.Add("关于", helpMenu)

mainGui.MenuBar := mainMenuBar

; ===== 托盘菜单 =====
A_TrayMenu.Delete()
A_TrayMenu.Add("显示主窗口", ShowMainWindow)
A_TrayMenu.Add()
A_TrayMenu.Add("始终置顶", TrayToggleAlwaysOnTop)
A_TrayMenu.Add("开机自启", TrayToggleAutoStart)
A_TrayMenu.Add("快捷键设置", TrayOpenSettings)
A_TrayMenu.Add()
A_TrayMenu.Add("退出", ExitAppHandler)
A_TrayMenu.Default := "显示主窗口"

if isAlwaysOnTop
	A_TrayMenu.Check("始终置顶")
if isAutoStart
	A_TrayMenu.Check("开机自启")

; 如果默认始终置顶，则应用到主窗口并勾选菜单
if isAlwaysOnTop
{
	mainGui.Opt("+AlwaysOnTop")
	viewMenu.Check("始终置顶")
}

if isAutoStart
	viewMenu.Check("开机自启")

; ===== 主界面 =====
editBox := mainGui.AddEdit("xm ym w540 h300")

btnSelectAll := mainGui.AddButton("xm y+10 w100", "全选")
btnCopy      := mainGui.AddButton("x+10 w100", "复制")
btnPaste     := mainGui.AddButton("x+10 w100", "粘贴")
btnCut       := mainGui.AddButton("x+10 w100", "剪切")
btnClear     := mainGui.AddButton("x+10 w100", "清除")

btnSendNow   := mainGui.AddButton("xm y+10 w540 h30", FormatHotkeyLabel("普通输入", currentHotkey))
btnDelaySend := mainGui.AddButton("xm y+8  w540 h30", FormatHotkeyLabel("延迟输入", delayedHotkey))



; 覆盖在按钮上的进度条（默认隐藏）
delayProgress := mainGui.AddProgress("xp yp wp hp cGreen Range0-100 Hidden", 0)
delayText := mainGui.AddText("xp yp wp hp +0x200 Center BackgroundTrans Hidden", "")

btnSendNow.OnEvent("Click", StartSendNow)
btnDelaySend.OnEvent("Click", StartDelayedSend)
btnSelectAll.OnEvent("Click", SelectAllText)
btnClear.OnEvent("Click", ClearText)
btnCut.OnEvent("Click", CutText)
btnCopy.OnEvent("Click", CopyText)
btnPaste.OnEvent("Click", PasteText)

mainGui.Show()

; ===== 注册热键 =====
Hotkey(currentHotkey, SendNow)
Hotkey(delayedHotkey, SendWithDelay)

; =========================
; 菜单功能
; =========================

FormatHotkeyLabel(prefix, hotkeyText)
{
	return prefix " [" hotkeyText "]"
}

ToggleAlwaysOnTop(ItemName, ItemPos, MyMenu)
{
	global mainGui, settingsGui, aboutGui, delayGui, isAlwaysOnTop, settingsFile

	isAlwaysOnTop := !isAlwaysOnTop

	if isAlwaysOnTop
	{
		mainGui.Opt("+AlwaysOnTop")
		MyMenu.Check(ItemName)
		A_TrayMenu.Check("始终置顶")
	}
	else
	{
		mainGui.Opt("-AlwaysOnTop")
		MyMenu.Uncheck(ItemName)
		A_TrayMenu.Uncheck("始终置顶")
	}

	if IsSet(settingsGui)
		settingsGui.Opt(isAlwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop")
	if IsSet(aboutGui)
		aboutGui.Opt(isAlwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop")
	if IsSet(delayGui)
		delayGui.Opt(isAlwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop")

	IniWrite(isAlwaysOnTop ? "1" : "0", settingsFile, "Main", "AlwaysOnTop")
}

ToggleAutoStart(ItemName, ItemPos, MyMenu)
{
	global isAutoStart

	exePath := A_ScriptFullPath

	; 如果是 .ahk，用解释器运行
	if !InStr(exePath, ".exe")
		exePath := A_AhkPath ' "' A_ScriptFullPath '"'

	if isAutoStart
	{
		; 关闭自启
		RegDelete("HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "Typewriter")
		MyMenu.Uncheck(ItemName)
		A_TrayMenu.Uncheck("开机自启")
		isAutoStart := false
	}
	else
	{
		; 开启自启
		RegWrite(exePath, "REG_SZ", "HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "Typewriter")
		MyMenu.Check(ItemName)
		A_TrayMenu.Check("开机自启")
		isAutoStart := true
	}
}


ShowMainWindow(*)
{
	global mainGui
	mainGui.Show()
	WinActivate "ahk_id " mainGui.Hwnd
}

TrayOpenSettings(*)
{
	OpenSettings()
}

TrayToggleAlwaysOnTop(*)
{
	global isAlwaysOnTop, mainGui, settingsGui, aboutGui, delayGui, settingsFile, viewMenu

	isAlwaysOnTop := !isAlwaysOnTop

	if isAlwaysOnTop
	{
		mainGui.Opt("+AlwaysOnTop")
		viewMenu.Check("始终置顶")
		A_TrayMenu.Check("始终置顶")
	}
	else
	{
		mainGui.Opt("-AlwaysOnTop")
		viewMenu.Uncheck("始终置顶")
		A_TrayMenu.Uncheck("始终置顶")
	}

	if IsSet(settingsGui)
		settingsGui.Opt(isAlwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop")
	if IsSet(aboutGui)
		aboutGui.Opt(isAlwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop")
	if IsSet(delayGui)
		delayGui.Opt(isAlwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop")

	IniWrite(isAlwaysOnTop ? "1" : "0", settingsFile, "Main", "AlwaysOnTop")
}

TrayToggleAutoStart(*)
{
	global isAutoStart, viewMenu

	exePath := A_ScriptFullPath
	if !InStr(exePath, ".exe")
		exePath := A_AhkPath ' "' A_ScriptFullPath '"'

	if isAutoStart
	{
		RegDelete("HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "Typewriter")
		isAutoStart := false
		viewMenu.Uncheck("开机自启")
		A_TrayMenu.Uncheck("开机自启")
	}
	else
	{
		RegWrite(exePath, "REG_SZ", "HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "Typewriter")
		isAutoStart := true
		viewMenu.Check("开机自启")
		A_TrayMenu.Check("开机自启")
	}
}

CenterChildToMain(childGui)
{
	global mainGui

	; 主窗口位置和大小
	mainGui.GetPos(&mx, &my, &mw, &mh)

	; 子窗口当前位置和大小
	childGui.GetPos(&cx, &cy, &cw, &ch)

	; 先按主窗口中心计算
	x := mx + Floor((mw - cw) / 2)
	y := my + Floor((mh - ch) / 2)

	; 找主窗口中心所在的显示器工作区
	centerX := mx + Floor(mw / 2)
	centerY := my + Floor(mh / 2)

	monitorIndex := MonitorGetPrimary()
	monitorCount := MonitorGetCount()

	loop monitorCount
	{
		MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)
		if (centerX >= left && centerX < right && centerY >= top && centerY < bottom)
		{
			monitorIndex := A_Index
			break
		}
	}

	MonitorGetWorkArea(monitorIndex, &workLeft, &workTop, &workRight, &workBottom)

	; 限制不要超出工作区
	if (x < workLeft)
		x := workLeft
	if (y < workTop)
		y := workTop
	if (x + cw > workRight)
		x := workRight - cw
	if (y + ch > workBottom)
		y := workBottom - ch

	childGui.Move(x, y)
}

ShowChildCentered(childGui)
{
	global isAlwaysOnTop

	if isAlwaysOnTop
		childGui.Opt("+AlwaysOnTop")
	else
		childGui.Opt("-AlwaysOnTop")

	; 先放到屏幕外创建并完成 AutoSize，避免闪烁
	childGui.Show("AutoSize x-32000 y-32000")
	Sleep 10

	; 这时尺寸已经确定，再居中并限制到工作区
	CenterChildToMain(childGui)

	; 激活到最前
	WinActivate "ahk_id " childGui.Hwnd
}

OpenSettings(*)
{
	global settingsGui
	global mainGui
	global currentHotkey, delayedHotkey, delayMsValue, typeSpeedValue
	global hotkeyEdit, delayHotkeyEdit, delayMsEdit, typeSpeedEdit

	if !IsSet(settingsGui)
	{
		settingsGui := Gui("+Owner" mainGui.Hwnd, "设置")
		settingsGui.SetFont("s10")

		settingsGui.AddText("xm ym", "普通输入快捷键：")
		hotkeyEdit := settingsGui.AddEdit("w140", currentHotkey)

		settingsGui.AddText("xm y+15", "延迟输入快捷键：")
		delayHotkeyEdit := settingsGui.AddEdit("w140", delayedHotkey)

		settingsGui.AddText("xm y+15", "延迟时间（毫秒）：")
		delayMsEdit := settingsGui.AddEdit("w140", delayMsValue)

		settingsGui.AddText("xm y+15", "打字速度（毫秒/字）：")
		typeSpeedEdit := settingsGui.AddEdit("w140", typeSpeedValue)

		btnApply := settingsGui.AddButton("xm y+20 w100", "应用")
		btnClose := settingsGui.AddButton("x+10 w100", "关闭")

		btnApply.OnEvent("Click", ApplySettings)
		btnClose.OnEvent("Click", CloseSettings)
		settingsGui.OnEvent("Close", HideSettings)
	}

	hotkeyEdit.Value := currentHotkey
	delayHotkeyEdit.Value := delayedHotkey
	delayMsEdit.Value := delayMsValue
	typeSpeedEdit.Value := typeSpeedValue

	ShowChildCentered(settingsGui)
}

ApplySettings(*)
{
	global currentHotkey, delayedHotkey, delayMsValue, typeSpeedValue
	global hotkeyEdit, delayHotkeyEdit, delayMsEdit, typeSpeedEdit

	newHotkey := Trim(hotkeyEdit.Value)
	newDelayedHotkey := Trim(delayHotkeyEdit.Value)
	newDelayMs := Trim(delayMsEdit.Value)
	newTypeSpeed := Trim(typeSpeedEdit.Value)

	if newHotkey = ""
	{
		MsgBox "普通输入快捷键不能为空。"
		return
	}

	if newDelayedHotkey = ""
	{
		MsgBox "延迟输入快捷键不能为空。"
		return
	}

	if !RegExMatch(newDelayMs, "^\d+$")
	{
		MsgBox "延迟时间必须是整数毫秒。`n例如：1000、3000、5000"
		return
	}

	if !RegExMatch(newTypeSpeed, "^\d+$")
	{
		MsgBox "打字速度必须是整数毫秒。`n例如：10、30、50"
		return
	}

	oldHotkey := currentHotkey
	oldDelayedHotkey := delayedHotkey

	try
	{
		Hotkey(oldHotkey, "Off")
		Hotkey(oldDelayedHotkey, "Off")

		Hotkey(newHotkey, SendNow, "On")
		Hotkey(newDelayedHotkey, SendWithDelay, "On")

		currentHotkey := newHotkey
		delayedHotkey := newDelayedHotkey
		delayMsValue := Integer(newDelayMs)
		typeSpeedValue := Integer(newTypeSpeed)
		
		global btnSendNow, btnDelaySend
		btnSendNow.Text := FormatHotkeyLabel("普通输入", currentHotkey)
		btnDelaySend.Text := FormatHotkeyLabel("延迟输入", delayedHotkey)

		MsgBox "设置已应用。"
	}
	catch
	{
		try Hotkey(oldHotkey, SendNow, "On")
		try Hotkey(oldDelayedHotkey, SendWithDelay, "On")
		MsgBox "热键格式无效。`n例如：F8、^j、!q、+F8、^!t"
	}
}

CloseSettings(*)
{
	global settingsGui
	settingsGui.Hide()
}

HideSettings(*)
{
	global settingsGui
	settingsGui.Hide()
}

ShowAbout(*)
{
	global aboutGui
	global mainGui
	global appName, appVersion, appAuthor, appGithub, appIcon

	if !IsSet(aboutGui)
	{
		aboutGui := Gui("+Owner" mainGui.Hwnd, "关于")
		aboutGui.SetFont("s10", "Segoe UI")

		; 左侧图标
		try
			aboutGui.AddPicture("xm ym w48 h48 Icon1", appIcon)
		catch
			aboutGui.AddText("xm ym w48 h48 Center +0x200", "TWR")

		; 右侧标题和信息
		aboutGui.SetFont("s14 bold", "Segoe UI")
		aboutGui.AddText("x+12 yp", appName)

		aboutGui.SetFont("s10 norm", "Segoe UI")
		aboutGui.AddText("xp y+28", "版本: " appVersion)
		aboutGui.AddText("xp y+22", "作者: " appAuthor)
		aboutGui.AddText("xp y+22", "一个为解决某些网站禁用粘贴的轻量文本打字机工具，觉得好用的话欢迎star支持")
		aboutLink := aboutGui.AddLink("xp y+22", '<a href="' appGithub '">GitHub: ' appGithub '</a>')

		; 底部按钮
		btnCloseAbout := aboutGui.AddButton("xm y+28 w100 h28", "关闭")
		btnCloseAbout.OnEvent("Click", CloseAbout)

		aboutGui.OnEvent("Close", HideAbout)
		
	}

	ShowChildCentered(aboutGui)
}

CloseAbout(*)
{
	global aboutGui
	aboutGui.Hide()
}

HideAbout(*)
{
	global aboutGui
	aboutGui.Hide()
}

ExitAppHandler(*)
{
	ExitApp
}

; =========================
; 输入逻辑
; =========================

SendNow(*)
{
	global editBox
	text := editBox.Value

	if text = ""
	{
		MsgBox "请先输入内容。"
		return
	}

	SendTextSlow(text)
}

SendWithDelay(*)
{
	global editBox
	text := editBox.Value

	if text = ""
	{
		MsgBox "请先输入内容。"
		return
	}

	ShowDelayProgressAndSend(text)
}

SendTextSlow(text)
{
	global typeSpeedValue

	for char in StrSplit(text)
	{
		SendText char
		Sleep typeSpeedValue
	}
}

; =========================
; 文本框按钮功能
; =========================

SelectAllText(*)
{
	global editBox
	editBox.Focus()
	Send "^a"
}

ClearText(*)
{
	global editBox
	editBox.Value := ""
	editBox.Focus()
}

CutText(*)
{
	global editBox
	editBox.Focus()
	Send "^a"
	Sleep 50
	Send "^x"
}

CopyText(*)
{
	global editBox
	editBox.Focus()
	Send "^a"
	Sleep 50
	Send "^c"
}

PasteText(*)
{
	global editBox
	editBox.Focus()
	Send "^v"
}

StartDelayedSend(*)
{
	global editBox, delayMsValue
	global delayProgress, delayText, btnDelaySend

	text := editBox.Value
	if text = ""
	{
		MsgBox "请先输入内容。"
		return
	}

	btnDelaySend.Enabled := false

	oldBtnText := btnDelaySend.Text
	btnDelaySend.Text := ""
	delayProgress.Visible := true
	delayText.Visible := true

	startTime := A_TickCount
	totalMs := delayMsValue

	loop
	{
		elapsed := A_TickCount - startTime
		percent := Floor((elapsed / totalMs) * 100)

		if percent > 100
			percent := 100

		delayProgress.Value := percent
		delayText.Text := percent "%"

		if elapsed >= totalMs
			break

		Sleep 30
	}

	delayProgress.Value := 0
	delayText.Text := ""
	delayProgress.Visible := false
	delayText.Visible := false
	btnDelaySend.Enabled := true
	global delayedHotkey
	btnDelaySend.Text := FormatHotkeyLabel("延迟输入", delayedHotkey)

	SendTextSlow(text)
}

StartSendNow(*)
{
	global editBox

	text := editBox.Value
	if text = ""
	{
		MsgBox "请先输入内容。"
		return
	}

	SendTextSlow(text)
}

ShowDelayProgressAndSend(text)
{
	global delayGui, delayProgressBar, delayPercentText
	global mainGui, delayMsValue

	if !IsSet(delayGui)
	{
		delayGui := Gui("+Owner" mainGui.Hwnd " -MinimizeBox -MaximizeBox", "延迟输入确认")
		delayGui.SetFont("s10")

		delayGui.AddText("xm ym", "正在等待开始输入...")
		delayProgressBar := delayGui.AddProgress("xm y+10 w320 h22 cGreen Range0-100", 0)
		delayPercentText := delayGui.AddText("xm y+8 w320 Center", "0%")
	}

	delayProgressBar.Value := 0
	delayPercentText.Text := "0%"

	ShowChildCentered(delayGui)

	startTime := A_TickCount
	totalMs := delayMsValue

	loop
	{
		elapsed := A_TickCount - startTime
		percent := Floor((elapsed / totalMs) * 100)

		if percent > 100
			percent := 100

		delayProgressBar.Value := percent
		delayPercentText.Text := percent "%"

		if elapsed >= totalMs
			break

		Sleep 30
	}

	delayGui.Hide()
	SendTextSlow(text)
}

Esc::ExitApp
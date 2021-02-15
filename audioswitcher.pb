; AudioSwitcher - Switch audio from speakers & webcam to headset
; 2020 by Alex

; Variables
Global NewMap Config$()

; Procedures
Declare ReadPreference(Map PrefMap$())
Declare SoundDevice(Command$, Device$, Param$ = "", Wait = #False)
Declare WritePreference(Key$, Device$)
Declare.s findDevice(device.s, type.s)

; Config
ReadPreference(Config$())
Restore profileTemplate
Read.s profileTemplate$

; GUI
XIncludeFile "bevelbutton.pb"
XIncludeFile "audioswitcher-window.pbf"

; Modules
XIncludeFile "Registry.pbi"
UseModule Registry

; Fonts
gadgetFont = LoadFont(#PB_Any, Config$("font"), Val(Config$("fontSize")), #PB_Font_HighQuality)
font = FontID(gadgetFont)
gadgetFont = LoadFont(#PB_Any, Config$("font"), Val(Config$("fontSizeHeadline")), #PB_Font_HighQuality)
fontHeadline = FontID(gadgetFont)

; Window
OpenWindowMain()
; Set text
SetGadgetFont(HeadlineDevices, fontHeadline)
SetGadgetText(HeadlineDevices, Config$("devicesHeadline"))
BevelButton::SetText(ButtonDevices1, Config$("devices1Text"), font)
BevelButton::SetText(ButtonDevices2, Config$("devices2Text"), font)
SetGadgetFont(HeadlineVolumes, fontHeadline)
SetGadgetText(HeadlineVolumes, Config$("volumesHeadline"))
BevelButton::SetText(ButtonVolumes1, Config$(Config$("lastDevice") + "volumes1Text"), font)
BevelButton::SetText(ButtonVolumes2, Config$(Config$("lastDevice") + "volumes2Text"), font)

; Set current state
Select Config$("lastDevice")
  Case "devices1"
    BevelButton::Enable(ButtonDevices1)
    BevelButton::Disable(ButtonDevices2)
  Case "devices2"
    BevelButton::Enable(ButtonDevices2)
    BevelButton::Disable(ButtonDevices1)
EndSelect
Select Config$("lastVolume")
  Case "volumes1"
    BevelButton::Enable(ButtonVolumes1)
    BevelButton::Disable(ButtonVolumes2)
  Case "volumes2"
    BevelButton::Enable(ButtonVolumes2)
    BevelButton::Disable(ButtonVolumes1)
EndSelect

; ----------------------------------------------------------------------------------------------------------------------------------

; Loop
HideWindow(WindowMain, #False)
Repeat
  Event = WaitWindowEvent()
  
  Select Event
    Case #PB_Event_Gadget

      ; Toogle Buttons
      LockWindowUpdate_(WindowID(WindowMain))
      Select EventGadget()
        Case BevelButton::GetGadgetID(ButtonDevices1)
          Config$("lastDevice") = "devices1"
          BevelButton::Enable(ButtonDevices1)
          BevelButton::Disable(ButtonDevices2)
          ; Set Volume-Buttons
          BevelButton::SetText(ButtonVolumes1, Config$(Config$("lastDevice") + "volumes1Text"))
          BevelButton::SetText(ButtonVolumes2, Config$(Config$("lastDevice") + "volumes2Text"))
        Case BevelButton::GetGadgetID(ButtonDevices2)
          Config$("lastDevice") = "devices2"
          BevelButton::Enable(ButtonDevices2)
          BevelButton::Disable(ButtonDevices1)
          ; Set Volume-Buttons
          BevelButton::SetText(ButtonVolumes1, Config$(Config$("lastDevice") + "volumes1Text"))
          BevelButton::SetText(ButtonVolumes2, Config$(Config$("lastDevice") + "volumes2Text"))
        Case BevelButton::GetGadgetID(ButtonVolumes1)
          Config$("lastVolume") = "volumes1"
          BevelButton::Enable(ButtonVolumes1)
          BevelButton::Disable(ButtonVolumes2)
        Case BevelButton::GetGadgetID(ButtonVolumes2)
          Config$("lastVolume") = "volumes2"
          BevelButton::Enable(ButtonVolumes2)
          BevelButton::Disable(ButtonVolumes1)
      EndSelect
      ; Dark button
      If BevelButton::GetButton(EventGadget())
        BevelButton::ColorDark(BevelButton::GetButton(EventGadget()))
      EndIf
      LockWindowUpdate_(0)
      UpdateWindow_(WindowID(WindowMain))
      
      ; Set Device/Volume
      Select EventGadget()
        Case BevelButton::GetGadgetID(ButtonDevices1), BevelButton::GetGadgetID(ButtonDevices2), BevelButton::GetGadgetID(ButtonVolumes1), BevelButton::GetGadgetID(ButtonVolumes2)

          template$ = profileTemplate$
          template$ = ReplaceString(template$, "###deviceRender###", Config$(Config$("lastDevice") + "SpeakerID"))
          template$ = ReplaceString(template$, "###deviceCapture###", Config$(Config$("lastDevice") + "MicID"))
          template$ = ReplaceString(template$, "###volume###", FormatNumber(ValF(Config$(Config$("lastDevice") + Config$("lastVolume") + "Value"))/100, 2))
          
          ; Write Profile
          If OpenFile(0, "profile.spr")
            WriteString(0, template$)
            CloseFile(0)
          Else
            MessageRequester("Error", "Unable to write profile-file!")
            Continue
          EndIf

          ; Set Profile
          SoundDevice("LoadProfile", "profile.spr", "", #True)
          
          ; Finished setting
          BevelButton::ColorNormal(BevelButton::GetButton(EventGadget()))
      EndSelect

  EndSelect
Until Event = #PB_Event_CloseWindow
HideWindow(WindowMain, #True)

; Write last state
WritePreference("lastDevice", Config$("lastDevice"))
WritePreference("lastVolume", Config$("lastVolume"))

; Free Memory
BevelButton::Delete(ButtonDevices2)
BevelButton::Delete(ButtonDevices1)
BevelButton::Delete(ButtonVolumes2)
BevelButton::Delete(ButtonVolumes1)

End

; ----------------------------------------------------------------------------------------------------------------------------------

Procedure SoundDevice(Command$, Device$, Param$ = "", Wait = #False)
  allParams$ = "/" + Command$ + " " + Chr(34) + Device$ + Chr(34) + " " + Param$
  ; Flags
  Flags = 0
  If Wait = #True
    Flags = #PB_Program_Wait
  EndIf
  ; Run SoundVolumeView
  RunProgram("SoundVolumeView/SoundVolumeView", allParams$, "", Flags)
EndProcedure

Procedure ReadPreference(Map PrefMap$())
  ; Open Preferences
  FileIni.s = GetFilePart(ProgramFilename(),#PB_FileSystem_NoExtension) + ".ini"
  If (OpenPreferences(FileIni) = 0)
    MessageRequester("Error", "Can not open ini-file: "+FileIni)
    End
  EndIf
  
  ; Read
  ExaminePreferenceGroups()
  While NextPreferenceGroup()
    ExaminePreferenceKeys()
    While  NextPreferenceKey()
      ; Debug PreferenceGroupName() + ": " + PreferenceKeyName() + "=" + PreferenceKeyValue()
      PrefMap$(PreferenceKeyName())=PreferenceKeyValue()
    Wend
  Wend
  
  ; Get device IDs
  For i=1 To 2
    key.s = "devices" + Str(i) + "Speaker"
    PrefMap$(key+"ID") = findDevice(PrefMap$(key), "Render")
    ; Debug key+"ID" + "=" + PrefMap$(key+"ID")
    key.s = "devices" + Str(i) + "Mic"
    PrefMap$(key+"ID") = findDevice(PrefMap$(key), "Capture")
    ; Debug key+"ID" + "=" + PrefMap$(key+"ID")
  Next

  ; Close
  ClosePreferences()
EndProcedure

Procedure WritePreference(Key$, Device$)
  ; Open Preferences
  FileIni.s = GetFilePart(ProgramFilename(),#PB_FileSystem_NoExtension) + ".ini"
  If (OpenPreferences(FileIni) = 0)
    MessageRequester("Error", "Can not open ini-file: "+FileIni)
    End
  EndIf
  
  ; Write
  PreferenceGroup("base")
  WritePreferenceString(Key$, Device$)

  ; Close
  ClosePreferences()
EndProcedure

DataSection
  profileTemplate:
  Data.s "" +
         ; Render Device
         "[ProfileItem0]" + #CRLF$ +
         "ID=###deviceRender###" + #CRLF$ +
         "DefaultRender=1" + #CRLF$ +
         "DefaultRenderCommunications=1" + #CRLF$ +
         "DefaultRenderMultimedia=1" + #CRLF$ +
         "VolumeScalar=###volume###" + #CRLF$ +
         ; Capture Device
         "[ProfileItem1]" + #CRLF$ +
         "ID=###deviceCapture###" + #CRLF$ +
         "DefaultCapture=1" + #CRLF$ +
         "DefaultCaptureCommunications=1" + #CRLF$ +
         "DefaultCaptureMultimedia=1" + #CRLF$ +
         ; General
         "[General]" + #CRLF$ +
         "ItemsCount=2" + #CRLF$
EndDataSection

Procedure.s findDevice(device.s, type.s)
  Protected devicenameKey.s = "{b3f8fa53-0004-438e-9003-51a46e139bfc},6"
  Protected nameKey.s = "{a45c254e-df1c-4efd-8020-67d146a850e0},2"
  Protected basekey.s = "SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\" + type
  Protected NewMap devices.s()
  Protected deviceID.s, devicePath.s
  Protected i
  
  ; All devices
  ; Example: Logitech Speaker\Device\Speaker\Render
  For i = 0 To CountSubKeys(#HKEY_LOCAL_MACHINE, basekey, #True ) - 1
    deviceID = ListSubKey(#HKEY_LOCAL_MACHINE, basekey, i, #True )
    devicePath = basekey + "\" + deviceID + "\Properties"
    devices(ReadValue(#HKEY_LOCAL_MACHINE, devicePath, devicenameKey, #True) + "\Device\" + ReadValue(#HKEY_LOCAL_MACHINE, devicePath, nameKey, #True) + "\" + type) = deviceID
  Next
  
  ; Return ID
  If FindMapElement(devices(), device)
    If type = "Render"
      ProcedureReturn "{0.0.0.00000000}." + devices(device)
    Else
      ProcedureReturn "{0.0.1.00000000}." + devices(device)
    EndIf
  Else
    MessageRequester("Error", "Unable to find device '" + device + "' with type '" + type + "'!")
  EndIf
EndProcedure

; IDE Options = PureBasic 5.73 LTS (Windows - x86)
; CursorPosition = 61
; FirstLine = 21
; Folding = -
; EnableXP
; UseIcon = icon.ico
; Executable = audioswitcher.exe
; DisableDebugger
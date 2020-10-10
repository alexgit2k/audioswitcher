; AudioSwitcher - Switch audio from speakers & webcam to headset
; 2020 by Alex

; Variables
Global NewMap Config$()

; Procedures
Declare ReadPreference(Map PrefMap$())
Declare SoundDevice(Command$, Device$, Param$ = "", Wait = #False)
Declare WritePreference(Key$, Device$)

; Config
ReadPreference(Config$())

; GUI
XIncludeFile "bevelbutton.pb"
XIncludeFile "audioswitcher-window.pbf"

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
      LockWindowUpdate_(0)
      UpdateWindow_(WindowID(WindowMain))
      
      ; Set Device/Volume
      Select EventGadget()
        Case BevelButton::GetGadgetID(ButtonDevices1), BevelButton::GetGadgetID(ButtonDevices2)
          ; Switch Audio
          SoundDevice("SetDefault", Config$(Config$("lastDevice") + "Mic"))
          SoundDevice("SetDefault", Config$(Config$("lastDevice") + "Speaker"))
          SoundDevice("SetDefault", Config$(Config$("lastDevice") + "Mic"), "2")
          SoundDevice("SetDefault", Config$(Config$("lastDevice") + "Speaker"), "2")
         
          ; Set Volume & wait
          SoundDevice("SetVolume", Config$(Config$("lastDevice") + "Speaker"), Config$(Config$("lastDevice") + Config$("lastVolume") + "Value"), True)
        Case BevelButton::GetGadgetID(ButtonVolumes1), BevelButton::GetGadgetID(ButtonVolumes2)
          ; Set Volume
          SoundDevice("SetVolume", Config$(Config$("lastDevice") + "Speaker"), Config$(Config$("lastDevice") + Config$("lastVolume") + "Value"), True)
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
  If Wait = True
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

; IDE Options = PureBasic 5.72 (Windows - x86)
; CursorPosition = 61
; FirstLine = 21
; Folding = -
; EnableXP
; UseIcon = icon.ico
; Executable = audioswitcher.exe
; DisableDebugger
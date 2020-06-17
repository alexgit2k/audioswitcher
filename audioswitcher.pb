; AudioSwitcher - Switch audio from speakers & webcam to headset
; 2020 by Alex

; Variables
Global NewMap Config$()

; Procedures
Declare ReadPreference(Map PrefMap$())
Declare SoundDevice(Device$, Type = -1, Wait = #False)
Declare WritePreference(Device$)

; Config
ReadPreference(Config$())

; GUI
XIncludeFile "bevelbutton.pb"
XIncludeFile "audioswitcher-window.pbf"

; Font
gadgetFont = LoadFont(#PB_Any, Config$("font"), Val(Config$("fontSize")), #PB_Font_HighQuality)
font = FontID(gadgetFont)

; Window
OpenWindowMain()
BevelButton::SetText(ButtonDevices1, Config$("devices1Text"), font)
BevelButton::SetText(ButtonDevices2, Config$("devices2Text"), font)

; Set current state
Select Config$("last")
  Case "devices1"
    BevelButton::Enable(ButtonDevices1)
    BevelButton::Disable(ButtonDevices2)
  Case "devices2"
    BevelButton::Enable(ButtonDevices2)
    BevelButton::Disable(ButtonDevices1)
EndSelect

; ----------------------------------------------------------------------------------------------------------------------------------

; Loop
Repeat
  Event = WaitWindowEvent()
  
  Select Event
    Case #PB_Event_Gadget
      Select EventGadget()
        Case BevelButton::GetGadgetID(ButtonDevices1)
          
          ; Toggle Buttons
          BevelButton::Enable(ButtonDevices1)
          BevelButton::Disable(ButtonDevices2)
          
          ; Switch Audio
          SoundDevice(Config$("devices1Mic"))
          SoundDevice(Config$("devices1Speaker"))
          SoundDevice(Config$("devices1Mic"), 2)
          SoundDevice(Config$("devices1Speaker"), 2, True)
          
          Config$("last") = "devices1"
        Case BevelButton::GetGadgetID(ButtonDevices2)
          
          ; Toggle Buttons
          BevelButton::Enable(ButtonDevices2)
          BevelButton::Disable(ButtonDevices1)
          
          ; Switch Audio
          SoundDevice(Config$("devices2Mic"))
          SoundDevice(Config$("devices2Speaker"))
          SoundDevice(Config$("devices2Mic"), 2)
          SoundDevice(Config$("devices2Speaker"), 2, True)
          
          Config$("last") = "devices2"
      EndSelect
  EndSelect
Until Event = #PB_Event_CloseWindow

; Write last state
WritePreference(Config$("last"))

; Free Memory
BevelButton::Delete(ButtonDevices2)
BevelButton::Delete(ButtonDevices1)

End

; ----------------------------------------------------------------------------------------------------------------------------------

Procedure SoundDevice(Device$, Type = -1, Wait = #False)
  param$ = "/SetDefault " + Chr(34) + Device$ + Chr(34)
  ; Add type if available
  If Type <> -1
    param$ = param$ + " " + Str(Type)
  EndIf
  ; Flags
  Flags = 0
  If Wait = True
    Flags = #PB_Program_Wait
  EndIf
  ; Run SoundVolumeView
  RunProgram("SoundVolumeView/SoundVolumeView", param$, "", Flags)
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

Procedure WritePreference(Device$)
  ; Open Preferences
  FileIni.s = GetFilePart(ProgramFilename(),#PB_FileSystem_NoExtension) + ".ini"
  If (OpenPreferences(FileIni) = 0)
    MessageRequester("Error", "Can not open ini-file: "+FileIni)
    End
  EndIf
  
  ; Write
  PreferenceGroup("base")
  WritePreferenceString("last", Device$)

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
; BevelButton Menu

DeclareModule BevelButton
  Structure button
    gadget.l
    width.i
    height.i
    text.s
    font.i
  EndStructure
  
  Declare New(x, y, width, height, image, text.s, font = 0, flags = 0)
  Declare Delete(*button.button)
  Declare Redraw(*button.button)
  Declare Enable(*button.button)
  Declare Disable(*button.button)
  Declare GetGadgetID(*button.button)
  Declare SetText(*button.button, text.s, font = 0)
  Declare.s GetText(*button.button)
  Declare SetFont(*button.button, font)
EndDeclareModule

Module BevelButton
  Procedure New(x, y, width, height, image, text.s, font = 0, flags = 0)
    Protected *button.button
    *button = AllocateMemory(SizeOf(button))
    *button\gadget = ButtonImageGadget(#PB_Any, x, y, width, height, image, flags)
    *button\width = width
    *button\height = height
    *button\font = font
    *button\text = text
    
    Redraw(*button)
    ProcedureReturn *button
  EndProcedure
  
  Procedure Delete(*button.button)
    FreeMemory(*button)
  EndProcedure
  
  Procedure Redraw(*button.button)
    Protected color, image
  
    ; Button state
    If GetGadgetState(*button\gadget) = #True
      color = RGB(0, 255, 0)
    Else
      color = GetSysColor_(#COLOR_BTNFACE)
    EndIf
    
    ; Draw button-image
    image = CreateImage(#PB_Any, *button\width, *button\height)
    StartDrawing(ImageOutput(image))
    DrawingMode(#PB_2DDrawing_Transparent)
    ; Background
    Box(0, 0, *button\width, *button\height, color)
    ; Text
    If *button\font <> 0
      DrawingFont(*button\font)
    EndIf
    FrontColor(GetSysColor_(#COLOR_BTNTEXT))
    DrawText((*button\width - TextWidth(*button\text)) / 2, (*button\height - TextHeight(*button\text)) / 2, *button\text)
    StopDrawing()
    SetGadgetAttribute(*button\gadget, #PB_Button_Image, ImageID(image))
  EndProcedure
  
  Procedure Enable(*button.button)
    SetGadgetState(*button\gadget, #True)
    Redraw(*button)
  EndProcedure
  
  Procedure Disable(*button.button)
    SetGadgetState(*button\gadget, #False)
    Redraw(*button)
  EndProcedure
  
  Procedure GetGadgetID(*button.button)
    ProcedureReturn *button\gadget
  EndProcedure
  
  Procedure SetText(*button.button, text.s, font = 0)
    *button\text = text
    If font <> 0
      *button\font = font
    EndIf
    Redraw(*button)
  EndProcedure
  
  Procedure.s GetText(*button.button)
    ProcedureReturn *button\text
  EndProcedure
  
  Procedure SetFont(*button.button, font)
    *button\font = font
	Redraw(*button)
  EndProcedure
EndModule

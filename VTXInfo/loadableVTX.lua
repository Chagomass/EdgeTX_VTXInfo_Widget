local zone, options = ...

local libGUI = loadGUI()

local gui = libGUI.newGUI()


-- The widget table will be returned to the main script
local widget = {
	zone = zone,
	options = options
 }

--gui.label(5, 0, zone.w/2, h, title, flags)

function widget.refresh(event, touchState)
  -- gui.run(event, touchState)
    gui.run(event, touchState)
    -- gui.drawText(x, y, text, flags, inversColor)
end

function libGUI.widgetRefresh()
  -- lcd.drawRectangle(0, 0, zone.w, zone.h, libGUI.colors.primary3)
  -- zone.w = 213, zone.h = 63

  local x_offset = 10
  local y_offset = 7

  local zone_w_available = zone.w - 2*x_offset
  local zone_h_available = zone.h

  local VTXpValue = model.getGlobalVariable(0,0) .. ""-- GV1, Flight Mode 0
  local VTXpMap = {}
  VTXpMap["-1000"] = "PIT"
  VTXpMap["-500"] ="25 mW"
  VTXpMap["0"] = "200 mW"
  VTXpMap["500"] = "400 mW"
  VTXpMap["1000"] = "600 mW"
  VTXpMap["1024"] = "PIT"
  VTXpMap["-1024"] = "600 mW"

  local VTXcValue = model.getGlobalVariable(1,0) -- GV2, Flight Mode 0

  local VTXChannel = math.floor((VTXcValue+100)/40)+1
  if VTXChannel == 4 then
  	VTXChannel = 5
  elseif VTXChannel == 5 then
  	VTXChannel = 6
  elseif VTXChannel == 6 then
  	VTXChannel = 8
  end

  local VTXBand = "R"

  print("############# ".." ############## " .. " for " .. VTXpValue)

  local y_Middle_Values_Text = zone_h_available/2 + y_offset/2

  lcd.drawText(x_offset/2, 10, "VTX", BOLD + LEFT + VCENTER)

  lcd.drawText(x_offset+zone_w_available/3/2, y_Middle_Values_Text - y_offset, "Power", SMLSIZE + CENTER + VCENTER + libGUI.colors.primary3)
  lcd.drawText(x_offset+zone_w_available/3/2, y_Middle_Values_Text + y_offset, VTXpMap[VTXpValue], BOLD + CENTER + VCENTER + libGUI.colors.primary3)

  lcd.drawText(x_offset+zone_w_available*2/3+zone_w_available/6, y_Middle_Values_Text - y_offset, "Channel", SMLSIZE + CENTER + VCENTER + libGUI.colors.primary3)
  lcd.drawText(x_offset+zone_w_available*2/3+zone_w_available/6, y_Middle_Values_Text + y_offset, VTXChannel, BOLD + CENTER + VCENTER + libGUI.colors.primary3)

  lcd.drawText(x_offset + zone_w_available/3 + zone_w_available/6, y_Middle_Values_Text - y_offset, "Band", SMLSIZE + CENTER + VCENTER + libGUI.colors.primary3)
  lcd.drawText(x_offset + zone_w_available/3 + zone_w_available/6, y_Middle_Values_Text + y_offset, VTXBand, BOLD + CENTER + VCENTER + libGUI.colors.primary3)

end


return widget
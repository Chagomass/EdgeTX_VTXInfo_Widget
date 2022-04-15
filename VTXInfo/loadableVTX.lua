local zone, options = ...

--[[

Improvements to do

-> Create reverse tables to avoid doing so much lookups
-> Write VTX settings to Global Variables to allow control using customs switches etc.. (define it in settings)

--]]

-- ################## CONSTANTS DECLARATION ##################

local VERBOSE = true

-- The widget table will be returned to the main script
local widget = {
  zone = zone,
  options = options
 }

local libGUI = loadGUI()
local gui = libGUI.newGUI()

MSP_VTX_CONFIG = 88
MSP_VTX_SET_CONFIG= 89 

sel_Band = 0
sel_Channel = 0
sel_Freq = 0
sel_Power = 0
local lineSpacing = 3
local horizontal_dist = 5

-- ######### VTX Table constants
local vtx_tables = loadScript("/BF/VTX/"..model.getInfo().name..".lua")
if vtx_tables then
    vtx_tables = vtx_tables()
else
    --vtx_tables = getVtxTables() -- Might override VTX Band, Channel and Power Level

    vtx_tables = loadScript("/BF/VTX/vtx_defaults.lua")()
end

powerTable = {[0]="PIT", "25 mW", "200 mW", "400 mW", "600 mW"}
frequencyTable = vtx_tables["frequencyTable"]
local VTxTableHeight = 180
local VTxTableWidth = LCD_W - 50
local HeaderHeight = 30
local FootNoteHeight = 30

numCols = vtx_tables["frequenciesPerBand"]
numRows = #frequencyTable

toggleHeight = (VTxTableHeight - (numRows + 1) * lineSpacing) / numRows
toggleWidth = (VTxTableWidth - (numCols + 1) * horizontal_dist) / numCols

toggle_list = {}
chan_label_list = {}
band_label_list = {}

default_flags = SMLSIZE + CENTER + VCENTER + WHITE -- set color to white // theme dependant?
focused_flags = BOLD + CENTER + VCENTER + libGUI.colors.primary1 -- 


-- ######### Current Output setting zone constants
middle_bottom_row = (2*lineSpacing + HeaderHeight + VTxTableHeight) + (LCD_H - (2*lineSpacing + HeaderHeight + VTxTableHeight))/2

w1, h1 = lcd.sizeText("R:8:600", focused_flags)

curr_sett_x = 10
curr_sett_w = w1 + 2*horizontal_dist
curr_sett_h = h1 + 2*lineSpacing

curr_sett_y = middle_bottom_row - curr_sett_h/2

-- ######### PowerTable constants
-- We want the PowerTable to be on the left half side of the screen
pwr_table_h = curr_sett_h

pwr_table_x = curr_sett_x + curr_sett_w + horizontal_dist
pwr_table_y = middle_bottom_row - pwr_table_h/2
pwr_table_w = (LCD_W/2 - pwr_table_x - horizontal_dist)

--[[local pwr_rect = gui.custom({ }, pwr_table_x, pwr_table_y, pwr_table_w+4, pwr_table_h)
function pwr_rect.draw(focused)
  lcd.drawRectangle(pwr_table_x, pwr_table_y, pwr_table_w+4, pwr_table_h, WHITE, 2)
end
function pwr_rect.onEvent(event, touchState)
end--]]


-- ######### Save & Exit buttons constants
save_x = LCD_W/2 + horizontal_dist -- *2
save_y = pwr_table_y 
save_w = LCD_W/4 - 2*horizontal_dist
save_h = curr_sett_h

exit_x = LCD_W *3/4 + horizontal_dist
exit_y = save_y
exit_w = LCD_W/4 - 2*horizontal_dist
exit_h = curr_sett_h


-- ################## FUNCTIONS DECLARATION ##################
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end -- dump(...)

function log(s)
  if VERBOSE then
    local file, err = io.open("/WIDGETS/VTXInfo/log.txt",'a')
    if file then
        datetime = getDateTime()
        w = tostring(datetime.day .. "-" ..datetime.mon .. "-" ..datetime.hour .. "-" ..datetime.min .. datetime.sec .." : " .. s .. "\n")
        io.write(file, w)
        io.close(file)
    else
        print("lua : error:", err) -- not so hard?
    end
  end
end -- log(...)

function VTxTableCallBack(self)
  log("v5 - VTX Call Back by " .. self.title)
  i_self = 0
  j_self = 0
  for k, v in pairs(toggle_list) do
    if v == self then
      j_self = (k-1)%numCols+1 -- Returns the column index
      i_self = math.floor((k-1)/numCols)+1 -- Returns the row index

      --log(i_self ..","..j_self ..":"..frequencyTable[i_self][j_self])

      chan_label_list[j_self].flags = focused_flags
      band_label_list[i_self].flags = focused_flags
    end
  end
  for k, v in pairs(toggle_list) do
    if (v ~= self) and v.value then
      -- log(v.title .. " is true and not self")
      v.value = false
      j = (k-1)%numCols+1 -- Returns the column index
      i = math.floor((k-1)/numCols)+1 -- Returns the row index
      if j ~= j_self then
        chan_label_list[j].flags = default_flags
      end
      if i ~= i_self then
        band_label_list[i].flags = default_flags
      end
    end
  end
  if self.value == false then -- In case someone tries to desactivate the currently selected freq, only this callback can disable other_than_self toggles
    self.value = true
  end
end -- VTxTableCallBack(...)

function SaveButtonCallback(self) log("Saved settings : " .. sel_Band ..":" .. sel_Channel .. ":" .. sel_Power) end

function ExitButtonCallback(self) log("Exit") end

function GetBandChannelFromFreq(Freq)
  for i = 1, #frequencyTable do
    for j= 1, vtx_tables["frequenciesPerBand"] do
      if frequencyTable[i][j] == Freq then
        return i, j
      end
    end
  end
  return 0, 0
end --GetBandChannelFromFreq(...)

function GetSelectedBandChannelFreq()
  for i=1, #toggle_list do
    if toggle_list[i].value then
      local txFreq = toggle_list[i].title
      local txBand, TxChannel = GetBandChannelFromFreq(txFreq)
      return txBand, TxChannel, txFreq
    end
  end
  return 0, 0, 0
end --GetSelectedBandChannelFreq(...)

local function VTXconfig(TxPower, TxBand, TxChannel,TxPitMode)
   local channel = (TxBand-1)*8 + TxChannel-1
   return { bit32.band(channel,0xFF), bit32.rshift(channel,8), TxPower, TxPitMode }  -- last 0 disables PIT mode
end --VTXconfig(...)



-- ################## DRAWING ##################

-- ######## Drawing the VTX Table and its labels for rows and columns
for i = 1, numRows do
  for j = 1, numCols do
    local x = 50 + j * horizontal_dist + (j-1) * toggleWidth
    local y = HeaderHeight + i + i * lineSpacing + (i-1)*toggleHeight

    if i == 1 then
      -- Header row, we add the labels that will hold the channel labels
      chan_label_list[#chan_label_list+1] = gui.label(x, y - lineSpacing - HeaderHeight, toggleWidth, toggleHeight, "Ch. "..j, default_flags) -- (x, y, w, h, title, flags)
    end

    if j == 1 then
      -- First column, we add the labels that will hold the band name
      band_label_list[#band_label_list+1] = gui.label(x - 50 - horizontal_dist, y, 50, toggleHeight, vtx_tables["bandTable"][i], default_flags)
    end

    toggle_list[#toggle_list+1] = gui.toggleButton(x, y, toggleWidth, toggleHeight, frequencyTable[i][j], false, VTxTableCallBack, SMLSIZE)

  end
end

-- ######## Drawing current output setting

--log("setting y : " .. curr_sett_y .. " ending at " .. curr_sett_y+curr_sett_h .. " for " .. LCD_H)
--log(curr_sett_x .. "," .. curr_sett_y .. "," .. curr_sett_w .. "," .. curr_sett_h)
curr_sett_label = gui.label(curr_sett_x, curr_sett_y, curr_sett_w, curr_sett_h, "R:8:600", BOLD + CENTER + VCENTER + WHITE)

local rect = gui.custom({ }, curr_sett_x, curr_sett_y, curr_sett_w, curr_sett_h)
function rect.draw(focused)
  lcd.drawRectangle(curr_sett_x, curr_sett_y, curr_sett_w, curr_sett_h, WHITE, 2)
end
function rect.onEvent(event, touchState)
end

-- These below don't work, WTF ?
-- rect = gui.drawRectangle(curr_sett_x-2, curr_sett_y-2, curr_sett_w+4, curr_sett_h+4, WHITE, 2)
-- rect = lcd.drawRectangle(50,50,50,50, WHITE, 2)

-- ######## Drawing Power dropdown

pwr_dropdown = gui.dropDown(pwr_table_x, pwr_table_y, pwr_table_w, pwr_table_h, powerTable, sel_Power, nil, focused_flags) --, callBack, flags)

save_button = gui.button(save_x, save_y, save_w, save_h, "Save", SaveButtonCallback, BOLD + CENTER + VCENTER)
exit_button = gui.button(exit_x, exit_y, exit_w, exit_h, "Exit", ExitButtonCallback, BOLD + CENTER + VCENTER)
-- ################## RUNNING ##################

function widget.refresh(event, touchState)
  -- print("lua : I was here")
  -- gui.run(event, touchState)
    if event == nil then
      libGUI.widgetRefresh()
    else
      --print("lua : Fullscreen, event is " .. event .. " and touchState is " .. type(touchState))
      gui.run(event, touchState)
    end
    local txBand, txChannel, txFreq = GetSelectedBandChannelFreq()
    -- log(txBand ..":".. txChannel ..":".. txFreq)
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

  -- print("############# ".." ############## " .. " for " .. VTXpValue)

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

--[[Notes on the BF MSP communications


common.mspSendRequest(cmd, payload)
	--> Will add the command and payload to the MspTxBuf following this format :

	PayloadLength .. bit32.band(  cmd  ,0xFF) .. bit32.band(payload[i],0xFF)

	then set mspLastReq = cmd and 
	return mspProcessTxQ()

common.mspProcessTxQ()
	if #MspTxBuf = 0 : return false
	if not protocol.push() : return true   ## push is used to send data but without arguments will return the status of the output buffer
										   ## If this is false then it would mean that the output buffer is nil ?

	Then it will construct a payload respecting the TXbufferSize using MspTxBuf
	If the request is ended, it will then add the MspTxCRC token (Cyclic redundancy check) and 0 pad the output
	
	MspSeq + MSP_VERSION + MSP_STARTFLAG + PayloadLength + CMD + PAYLOAD + CRC

	the payload is then passed to  :
	call protocol.mspSend(payload) then
	return True

crsf.protocol.mspSend(payload)
	add CRSF_ADDRESS_BETAFLIGHT and CRSF_ADDRESS_RADIO_TRANSMITTER to the beginning of the payload

	then
	
	protocol.push(crsfMspCmd, payloadOut)



common.mspPollReply()
    while true do
        local ret = protocol.mspPoll() --- Will be the mspRxBuf -> The data received without header
        if type(ret) == "table" then
            mspLastReq = 0
            return mspRxReq, ret --- the returned is the requested command alongside the data received
        else
            break
        end
    end
    return nil


crsf.protocol.mspPoll()

	local command, data = crossfireTelemetryPop()
	do some checks (is the data a response ?) and puts data into mspData and calls

	mspReceivedReply(mspData)

common.mspReceivedReply(payload)
	populate and return mspRxBuf with the data
	if data is longer than the buffer size then we use mspRemoteSeq to store the sequence and resume populating mspRxBuf next call
	mspRxReq  = mspLastReq
	
	return mspRxBuf



###########

Commands : 

local MSP_VTX_CONFIG = 88
local MSP_VTXTABLE_BAND = 137
local MSP_VTXTABLE_POWERLEVEL = 138
read           = 88, -- MSP_VTX_CONFIG
write          = 89, -- MSP_VTX_SET_CONFIG



Page Handling :

-- Vals                     Fields
-- 1 Device Type            Band
-- 2 Band                   Channel
-- 3 Channel                Power
-- 4 Power                  Pit
-- 5 Pit                    Device Type
-- 6 Freq                   Frequency


--]]

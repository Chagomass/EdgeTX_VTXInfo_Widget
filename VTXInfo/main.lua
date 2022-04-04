local name = "VTXInfo"


local function create(zone, options)
  -- Loadable code chunk is called immediately and returns a widget table
  return loadScript("/WIDGETS/" .. name .. "/loadableVTX.lua")(zone, options)
end

local function refresh(widget, event, touchState)
  widget.refresh(event, touchState)
end

local function background(widget)
end

local options = { 
}

local function update(widget, options)
end

return {
  name = name,
  create = create,
  refresh = refresh,
  background = background,
  options = options,
  update = update
}
WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "hdd", "Memory - Flash EEPROM", "gmod_wire_hdd", nil, "Flash EEPROMs" )

if ( CLIENT ) then
	language.Add( "Tool.wire_hdd.name", "Flash (EEPROM) tool (Wire)" )
	language.Add( "Tool.wire_hdd.desc", "Spawns flash memory. It is used for permanent storage of data (carried over sessions)" )
	language.Add( "Tool.wire_hdd.0", "Primary: Create/Update flash memory" )

	WireToolSetup.setToolMenuIcon( "icon16/database.png" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if (SERVER) then
	function TOOL:GetConVars() 
		return self:GetClientNumber("driveid"), self:GetClientNumber("drivecap")
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"
TOOL.ClientConVar[ "driveid" ] = 0
TOOL.ClientConVar[ "client_driveid" ] = 0
TOOL.ClientConVar[ "drivecap" ] = 128

TOOL.ClientConVar[ "packet_bandwidth" ] = 100
TOOL.ClientConVar[ "packet_rate" ] = 0.4

local function GetStructName(steamID,HDD,name)
	return "WireFlash\\"..(steamID or "UNKNOWN").."\\HDD"..HDD.."\\"..name..".txt"
end

local function ParseFormatData(formatData)
	local driveCap = 0
	local blockSize = 16
	if tonumber(formatData) then
		driveCap = tonumber(formatData)
	else
		local formatInfo = string.Explode("\n",formatData)
		if formatInfo[1] == "FLASH1" then
			driveCap = tonumber(formatInfo[2]) or 0
			blockSize = 32
		end
	end
	return driveCap,blockSize
end

local function GetFloatTable(Text)
	local text = Text
	local tbl = {}
	local ptr = 0
	while (string.len(text) > 0) do
		local value = string.sub(text,1,24)
		text = string.sub(text,24,string.len(text))
		tbl[ptr] = tonumber(value)
		ptr = ptr + 1
	end
	return tbl
end

local function MakeFloatTable(Table)
	local text = ""
	for i=0,#Table-1 do
		--Clamp size to 24 chars
		local floatstr = string.sub(tostring(Table[i]),1,24)
		--Make a string, and append missing spaces
		floatstr = floatstr .. string.rep(" ",24-string.len(floatstr))

		text = text..floatstr
	end

	return text
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_hdd.name", Description = "#Tool.wire_hdd.desc" })

	local mdl = vgui.Create("DWireModelSelect")
	mdl:SetModelList( list.Get("Wire_gate_Models"), "wire_hdd_model" )
	mdl:SetHeight( 5 )
	panel:AddItem( mdl )

	panel:AddControl("Slider", {
		Label = "Drive ID",
		Type = "Integer",
		Min = "0",
		Max = "3",
		Command = "wire_hdd_driveid"
	})

	panel:AddControl("Slider", {
		Label = "Capacity (KB)",
		Type = "Integer",
		Min = "0",
		Max = "128",
		Command = "wire_hdd_drivecap"
	})

	panel:AddControl("Label", { Text = "" })
	panel:AddControl("Label", { Text = "Flash memory manager" })

	panel:AddControl("Slider", {
		Label = "Server drive ID",
		Type = "Integer",
		Min = "0",
		Max = "3",
		Command = "wire_hdd_driveid"
	})

	panel:AddControl("Slider", {
		Label = "Client drive ID",
		Type = "Integer",
		Min = "0",
		Max = "99",
		Command = "wire_hdd_client_driveid"
	})

	local Button = vgui.Create("DButton", panel)
	panel:AddPanel(Button)
	Button:SetText("Download server drive to client drive")
	Button.DoClick = function()
			RunConsoleCommand("wire_hdd_download",GetConVarNumber("wire_hdd_driveid"))
	end

	panel:AddControl("Button", {
		Text = "Upload client drive to server drive",
		Command = "wire_hdd_upload"
	})

	local Button = vgui.Create("DButton", panel)
	panel:AddPanel(Button)
	Button:SetText("Clear server drive")
	Button.DoClick = function()
		RunConsoleCommand("wire_hdd_clearhdd",GetConVarNumber("wire_hdd_driveid"))
	end

	panel:AddControl("Button", {
		Text = "Clear client drive",
		Command = "wire_hdd_clearhdd_client"
	})

end

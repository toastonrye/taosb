--[[
TAOSB - toastonrye's AE2 One Stack Blaster

-- AP, AE2, CC
-- This script is difficult to view in-game, highly recommend using a text editor
-- The only settings that should need to be adjust are in USER SETTINGS
-- This script requires specific placement of ME Interfaces and Inverted Toggle Buses to work!
-- Hopefully I get around to posting a picture and or making a video...
--
--]]

-- [PROGRAM SETTINGS] -----------------------------------------------------------------------------
local version = 0.3
local didYouBackupYourSave = true		-- Please backup, just to be safe :)
if not didYouBackupYourSave then error("Change 'didYouBackupYourSave' to 'true' in this script.") end

-- [USER SETTINGS] --------------------------------------------------------------------------------
local exportToInterface = "right"		-- Position related to the AP ME Bridge.
local invToggleBus = "bottom"			-- Position related to the CC computer.
local startCommand = "left"				-- Position related to the CC computer. i.e. Stone Button.
local filterMode = -1          			-- -1 = BLACKLIST, 0 = TRANSFER ALL, 1 = WHITELIST.
local transferDelay = 0.0				-- 0 should be okay, increase to 0.1 if exports fail.
local maxFailCount = 3					-- Amount of failed item exports before stopping script.
local queryOnly = false					-- If 'true' the script doesn't transfer any items.
local createLogFile = true				-- Generates a log file of transferred items.
local timeZoneOffset = 0				-- Adjusts the timestamp in the log file.

local modFilterList = {				-- Use F3+H in-game to see advanced tooltips. Hovering over an
	minecraft = true,				-- item shows the mod id, minecraft:iron_axe
	ae2 = true,
	artifacts = true,			-- The script takes longer to run, when there is more 'true'.
	irons_jewelry = true		-- Advice is keep filtering from 0 to 2 mods. Or be patient :)
}

-- [HELPER FUNCTIONS] -----------------------------------------------------------------------------
local function getModId(fullItemName)	
	return string.match(fullItemName, "^(.-):")
end

local function shouldTransfer(modId)
	if filterMode == 0 then return true end								-- Transfer all 
	if filterMode == -1 then return not modFilterList[modId] end		-- Blacklist mode
	if filterMode == 1 then return modFilterList[modId] end				-- Whitelist mode
	return false
end

local function filterModeString(filterMode)
	if filterMode == 0 then return "TRANSFER ALL"
		elseif filterMode == 1 then return "WHITELIST MODE"
		elseif filterMode == -1 then return "BLACKLIST MODE"
		else return error("'filterMode' setting is incorrect.", 0)
	end
end

local function formatStats(uniqueItemStacks, totalItems, totalExports)
	return {
		("[STATS] %d unique item stacks out of %d."):format(uniqueItemStacks, totalItems),
		("[STATS] %d total items were exported."):format(totalExports)
	}
end

local function updateProgress(totalExports)
	local x, y = term.getCursorPos()
	term.setCursorPos(19, 1)
	term.setTextColour(colours.red)
	print(('[IN PROGRESS] %d items exported'):format(totalExports))
	term.setCursorPos(x, y)
	term.setTextColour(colours.white)
end

local function earlyShutdown(commnd)
	return {
		("[FAILED] At least %d items failed to export."):format(maxFailCount),
		("[FAILED] Check if ME Interface is jammed!")
	}
end

-- [LOGGING SYSTEM] ------------------------------------------------------------------------
local Logger = {}
Logger.__index = Logger

function Logger.new()
	local self = setmetatable({}, Logger)
	self.buffer = {}
	local dir, date = "TAOSB_Logs", os.date("%Y-%m-%d")
	if not fs.exists(dir) then fs.makeDir(dir) end
	self.file = fs.open(("%s/log_%s.txt"):format(dir, date), "a")
	return self
end

function Logger:append(msg)
	local time = textutils.formatTime(os.time("local") + timeZoneOffset, true)
	table.insert(self.buffer, ("%s %s"):format(os.date("%Y-%m-%d") .. " " .. time, msg))
end

function Logger:flush()
	for _, line in ipairs(self.buffer) do self.file.writeLine(line) end
	self.file.flush()
end

function Logger:close() self:flush(); self.file.close() end

-- [MAIN FUNCTION] -------------------------------------------------------------------------
local function main()
	local ae = peripheral.find("meBridge") or error("[AP] ME Bridge not found!")

	redstone.setOutput(invToggleBus, true)
	os.sleep(1)

	local startTime = os.epoch("utc")

	local itemsTable = ae.listItems()
	local totalExports, uniqueItemStacks, failCount = 0, 0, 0
	local exportItemsBuffer = {}
	local logger = createLogFile and Logger.new() or nil

	if logger then
		logger:append("--------------------------------------------------------------------------------------------")
		logger:append("[NEW SCAN] TAOSB v" .. version)
		logger:append("[SCRIPT SETTINGS]")
		logger:append(" >> exportToInterface = " .. exportToInterface)
		logger:append(" >> invToggleBus = " .. invToggleBus)
		logger:append(" >> queryOnly = " .. tostring(queryOnly))
		logger:append((" >> filterMode = %s"):format(filterModeString(filterMode)))
		logger:append("[COUNT] | [DISPLAY NAME] | [MODID:ITEMNAME] | [FINGERPRINT MD5 HASH]")
	end

	local function flushBuffer()
		for _, item in ipairs(exportItemsBuffer) do
			local exported = ae.exportItem(item, exportToInterface)
			if exported > 0 then
				totalExports = totalExports + exported
				if logger then logger:append(("  %s | %s | %s"):format(item.count,item.displayName, item.name, item.fingerprint)) end
			else
				failCount = failCount + 1
				if logger then logger:append(("[FAILED] %s | %s | %s"):format(item.count, item.displayName, item.name, item.fingerprint)) end
				if failCount >= maxFailCount then
					term.setTextColour(colours.red)
					for _, msg in ipairs(earlyShutdown()) do print(msg); if logger then logger:append(msg) end end
					updateProgress(totalExports)
					if logger then logger:close() end
					error("Stopping Script", 0)
				end
			end
		end
		updateProgress(totalExports)
		exportItemsBuffer = {}
		os.sleep(transferDelay)
	end

	for _, item in ipairs(itemsTable) do
		if item.maxStackSize == 1 then
			if shouldTransfer(getModId(item.name)) then
				uniqueItemStacks = uniqueItemStacks + 1
				if not queryOnly then
					local remainingBatch = item.count	-- Batch because 10 lava buckets won't fit in a 9 slot inventory
					while remainingBatch > 0 do
						local batch = math.min(remainingBatch, 9)
						table.insert(exportItemsBuffer, {
							count = batch,
							name = item.name,
							fingerprint = item.fingerprint,
							displayName = item.displayName
						})
						remainingBatch = remainingBatch - batch
					end
					if #exportItemsBuffer >= 9 then flushBuffer() end
				end
			end
		end
	end

	if #exportItemsBuffer > 0 then flushBuffer() end

	local endTime = os.epoch("utc")
	local duration = math.floor((endTime - startTime) / 1000 + 0.5)
	local itemsPerSecond = math.floor((totalExports/duration) * 100 + 0.5) / 100
	local timingMsg = ("[DONE] Script took %d seconds. %.2f items/s"):format(duration, itemsPerSecond)

	for _, msg in pairs(formatStats(uniqueItemStacks, #itemsTable, totalExports)) do
		print(msg)
		if logger then logger:append(msg) end
	end
	term.setTextColour(colours.green)
	print(timingMsg)
	term.setTextColour(colours.white)

	if logger then
		logger:append(queryOnly and "[COMPLETED] Queury Only, no exports." or "[COMPLETED] Items exported!")
		logger:append(timingMsg)
		logger:close()
	end
	redstone.setOutput(invToggleBus, false)
end

local function signalWatcher()
	local function init()
		term.clear()
		term.setCursorPos(1, 1)
		print("TAOSB v" .. version)
		print("Exports items with a maxStackSize = 1")
		print(("%s\n"):format(filterModeString(filterMode)))
	end

	init()

	while true do
		print("\n... Waiting for a Redstone signal!")
		os.pullEvent("redstone")
		if redstone.getInput(startCommand) then
			init()
			main()
		end
	end
end

-- [PARALLEL FUNCTION] ----------------------------------------------------------------------------
parallel.waitForAny(signalWatcher)

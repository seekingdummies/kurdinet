local HttpService = game:GetService("HttpService")

-- Detect and assign HTTP request function
local httprequest = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

-- HWID and Executor detection
local hwid = (gethwid and gethwid()) or "Unavailable"
local executor = (identifyexecutor and identifyexecutor()) or "Unknown"

-- Function to get full IP and location info
local function getLocationInfo()
	if not httprequest then
		warn("No compatible HTTP request function found.")
		return nil
	end

	local response = httprequest({
		Url = "https://ipapi.co/json/",
		Method = "GET"
	})

	if response and response.Body then
		local success, data = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)

		if success then
			return data
		else
			warn("Failed to decode JSON.")
		end
	else
		warn("Request failed or returned no body.")
	end

	return nil
end

-- Print HWID info
print("====== HWID & IP INFO ======")
print("HWID: " .. tostring(hwid))
print("Executor: " .. tostring(executor))
print("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"))
print("============================")

-- Fetch and print IP info
local info = getLocationInfo()
if info then
	print("IP: " .. tostring(info.ip))
	print("City: " .. tostring(info.city))
	print("Region: " .. tostring(info.region))
	print("Country: " .. tostring(info.country_name))
	print("Postal: " .. tostring(info.postal))
	print("Continent: " .. tostring(info.continent_code))
	print("=======================")
end

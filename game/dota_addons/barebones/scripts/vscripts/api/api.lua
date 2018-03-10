
require("api/json")

local ApiConfig = {
	endpoint = "http://api.dota2imba.org",
	agent = "xhs-"..tostring(X_HERO_SIEGE_V), -- Add the version AND UPDATE it here
	timeout = 10000,
	debug = false
}

local ApiEndpoints = {
	donators = "/xhs/donators"
}

function ApiDebug(text, ignore)
	if ApiConfig.debug or ignore ~= nil then
		print("[api] " .. tostring(text))
	end
end

function ApiPerform(robj, endpoint, callback)

	local payload = nil
	local method = "GET"

	-- build base request
	if robj ~= nil then
		local baseRequest = {
			agent = ApiConfig.agent,
			version = 1,
			frames = tonumber(GetFrameCount()),
			server_system_datetime = tostring(GetSystemDate()) .. " " .. tostring(GetSystemTime()),
			server_time = tonumber(Time()),
			data = robj
		}

		method = "POST"

		-- encode with json
		payload = json.encode(baseRequest)
	end

	ApiDebug("Performing " .. method .. " @ " .. endpoint, true)

	if (method == "POST") then
		ApiDebug("Payload " .. payload)
	end

	-- create request
	rqH = CreateHTTPRequestScriptVM(method, ApiConfig.endpoint .. endpoint)
	rqH:SetHTTPRequestAbsoluteTimeoutMS(ApiConfig.timeout)

	-- set payload
	if payload ~= nil then
		rqH:SetHTTPRequestRawPostBody("application/json", payload)
	end

	ApiDebug("Performing Request to " .. ApiConfig.endpoint .. endpoint)

	-- send request
	rqH:Send(function (result)
		-- decode response (we should always get json)
		-- 500 indi
		if result.StatusCode == 503 then
			ApiDebug("Server not available!", true)
			callback(true, nil)
		elseif result.StatusCode ~= 200 then
			ApiDebug("Request failed with Invalid status: " .. result.StatusCode, true)
			callback(true, nil)
		else
			rp = json.decode(result.Body)
			if rp.error then
				ApiDebug("Request failed with custom error: " .. rp.message, true)
				callback(true, rp)
			else
				ApiDebug("Request succesful")
				ApiDebug("Payload: " .. result.Body)
				callback(false, rp)
			end
		end
	end)
end

ApiCache = {
	donators = nil
}

function ApiLoad()
	ApiPerform(nil, ApiEndpoints.donators, function (err, response)
		if (err) then
			ApiDebug("Donators Request failed!", true)
		else
			ApiCache.donators = response.data
		end
	end)
end

function ApiGetDonators()
	return ApiCache.donators
end

function IsDonator(hero)
	if hero:GetPlayerID() == -1 or hero:IsIllusion() or ApiCache.donators == nil then return end
	for i = 1, #ApiCache.donators do
		if tostring(PlayerResource:GetSteamID(hero:GetPlayerID())) == ApiCache.donators[i].steamId64 then
			return ApiCache.donators[i].status
		elseif i == #ApiCache.donators then
			return false
		end
	end
end

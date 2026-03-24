-- EVADE ULTIMATE LOADER
-- Loader for Evade Ultimate Script

local function LoadFromGitHub(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local runSuccess, runError = pcall(function()
            loadstring(response)()
        end)

        if not runSuccess then
            warn("❌ Script execution failed:", runError)
        end
    else
        warn("❌ Failed to fetch script:", response)
    end
end

local SupportedGames = {
    -- Evade
    [9872472334] = function()
        LoadFromGitHub("https://raw.githubusercontent.com/fdddyyree-spec/evade/refs/heads/main/evade_ultimate.lua")
    end,
}

local PlaceId = game.PlaceId

if SupportedGames[PlaceId] then
    print("✅ Supported game detected! Loading Evade Ultimate Script...")
    SupportedGames[PlaceId]()
else
    warn("❌ Unsupported game ID:", PlaceId)
    warn("This script is designed for Evade only!")
end

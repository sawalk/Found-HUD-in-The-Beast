BeastStats = RegisterMod("Found HUD in The Beast", 1)
local mod = BeastStats

------ Mod Config Menu ------
local json = require("json")

mod.config = {
    toggleKey = Keyboard.KEY_SEMICOLON,
    showStats = true
}

if ModConfigMenu then
    ModConfigMenu.AddSetting("Found HUD Beast", nil,
        {
            Type = ModConfigMenu.OptionType.KEYBIND_KEYBOARD,
            CurrentSetting = function()
                return mod.config.toggleKey
            end,
            Display = function()
                local key = "None"
                if (InputHelper.KeyboardToString[mod.config.toggleKey]) then
                    key = InputHelper.KeyboardToString[mod.config.toggleKey]
                end
                return "Toggle Key: " .. key
            end,
            OnChange = function(currentNum)
                mod.config.toggleKey = currentNum or -1
            end,
            PopupGfx = ModConfigMenu.PopupGfx.WIDE_SMALL,
            PopupWidth = 280,
            Popup = function()
                local currentValue = mod.config.toggleKey
                local keepSettingString = ""
                if currentValue > -1 then
                    local currentSettingString = InputHelper.KeyboardToString[currentValue]
                    keepSettingString = 'Current key: "' .. currentSettingString .. 
                        '".$newlinePress this key again to keep it.$newline$newline'
                end
                return "Press any key to set as toggle key.$newline$newline" ..
                    keepSettingString .. "Press ESCAPE to clear this setting."
            end,
            Info = "You can toggle the Found HUD off and on with the key you set."
        }
    )
end

mod:AddPriorityCallback(
    ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.IMPORTANT,
    ---@param isContinued boolean
    function(_, isContinued)
        if not mod:HasData() then
            return
        end

        local jsonString = mod:LoadData()
        mod.config = json.decode(jsonString)
        mod.config.toggleKey = mod.config.toggleKey or Keyboard.KEY_SEMICOLON
    end
)

mod:AddPriorityCallback(
    ModCallbacks.MC_PRE_GAME_EXIT, CallbackPriority.LATE,
    function(shouldSave)
        local jsonString = json.encode(mod.config)
        mod:SaveData(jsonString)
    end
)


------ 스프라이트 로드 ------
------ To modders who want to reference this code. THIS CODE IS UNSTABLE!!! DROP THAT IDEA RIGHT NOW!!!
local idleSprite = Sprite()
idleSprite:Load("beaststats.anm2", true)

local function GetCurrentModPath()
    if debug then
        return string.sub(debug.getinfo(GetCurrentModPath).source, 2) .. "/../"
    else
        Isaac.DebugString("디버그 환경이 아니므로 기본 스프라이트를 사용합니다.")
        return nil
    end
end

local function GetModsPath()
    local currentModPath = GetCurrentModPath()
    if not currentModPath then return nil end
    return string.match(currentModPath, "(.+/mods/)")
end

local modsPath = GetModsPath()
if modsPath then
    local modsToCheck = {
        "!diegostarultra_foundhudresprite_2797938360",   -- by DiegoStarUltra
        "afterbirth+ stat icons_2485933538",             -- by dany_ev3
        "classic found hud_842540059",                   -- by Maleverus
        "color_stat_hud_rep_2555296681",                 -- by Nabal-Gion
        "colorcodedhudicons_3372513808",                 -- by Kōhaku
        "colored rebirth stat icons_1705392676",         -- by dany_ev3
        "foundhud icon2text cn_3049634552",              -- by kBlankii@蛛蛛！
        "foundhud icon2text_3049633188",                 -- by kBlankii@蛛蛛！
        "mashup color hud + altertweaks_1392570201",     -- by LRubik
        "medalhud [rep]_2879131773",                     -- by Fruitsnacs
        "pophud_2611855187",                             -- by Paltham
        "statrespritetest_3292277654",                   -- by Blend_r
        "stickerhud - full_2492547126"                   -- by BreadEnjoyer
    }

    for _, modName in ipairs(modsToCheck) do
        local success = io.open(GetModsPath() .. modName .. "/metadata.xml", "r")
        if success then
            if io.open(GetModsPath() .. modName .. "/disable.it", "r") then
                Isaac.DebugString(modName .. "가 비활성화됨.")
            else
                Isaac.DebugString(modName .. "를 불러옴.")
                idleSprite:Load("other mods/" .. modName .. "/beaststats.anm2", true)
            end
            success:close()
        else
            Isaac.DebugString(modName .. "가 존재하지 않음.")
        end
    end
end


------ 구현 ------
local statsFont = Font()
statsFont:Load("font/luaminioutlined.fnt")

local fadeAlpha = 0
local fadeSpeed = 0.1117

local function GetStatsText(player)
    return {
        Speed = string.format("%.2f", player.MoveSpeed),
        Tears = string.format("%.2f", 30 / (player.MaxFireDelay + 1)),
        Damage = string.format("%.2f", player.Damage),
        Range = string.format("%.2f", player.TearRange / 40),
        ShotSpeed = string.format("%.2f", player.ShotSpeed),
        Luck = string.format("%.2f", player.Luck)
    }
end

local function RenderStats(stats, pos, color, lineHeight, isSpeedOnly, isJacob)
    local speedYOffset = isJacob and 5 or 0
    local alphaColor = KColor(color.Red, color.Green, color.Blue, fadeAlpha)
    if not isSpeedOnly then
        statsFont:DrawStringUTF8(stats.Speed, pos.X + Game().ScreenShakeOffset.X, pos.Y + speedYOffset + Game().ScreenShakeOffset.Y, alphaColor, 0, true)
    end
    for i, stat in ipairs({stats.Tears, stats.Damage, stats.Range, stats.ShotSpeed, stats.Luck}) do
        statsFont:DrawStringUTF8(stat, pos.X + Game().ScreenShakeOffset.X, pos.Y + (i + (isSpeedOnly and -1 or 0)) * lineHeight + Game().ScreenShakeOffset.Y, alphaColor, 0, true)
    end
end

local function RenderPlayerStats()
    local RepentancePlusOffset = Vector(0, 2)
    if REPENTANCE_PLUS then
        RepentancePlusOffset = Vector(0, 0)
    end

    if Input.IsButtonTriggered(mod.config.toggleKey, 0) then
        mod.config.showStats = not mod.config.showStats
    end
    if not mod.config.showStats then return end

    local player1 = Isaac.GetPlayer(0)
    local player2 = Isaac.GetPlayer(1)

    local playerType = player1:GetPlayerType()
    local isJacob = playerType == PlayerType.PLAYER_JACOB or playerType == PlayerType.PLAYER_ESAU
    local isBethany = playerType == PlayerType.PLAYER_BETHANY or playerType == PlayerType.PLAYER_BETHANY_B

    idleSprite:Play(isJacob and "Idle2" or "Idle")

    local HUDOffset = Vector(20 * Options.HUDOffset, 12 * Options.HUDOffset)
    local spritePos = Vector(0, (isJacob and 104 or (isBethany and 99 or 90)) - RepentancePlusOffset.Y) + HUDOffset

    local alphaSpriteColor = Color(1, 1, 1, fadeAlpha, 0, 0, 0)
    idleSprite.Color = alphaSpriteColor
    idleSprite:Update()
    idleSprite:Render(spritePos, Vector(0, 0), Vector(0, 0))

    local stats1 = GetStatsText(player1)
    local stats2 = GetStatsText(player2)

    local basePos = Vector(16, (isJacob and 100 or (isBethany and 99 or 90)) - RepentancePlusOffset.Y) + HUDOffset
    local lineHeightBase = isJacob and 14 or 12
    local lineHeight = math.max(lineHeightBase * Options.HUDOffset, lineHeightBase)

    if isJacob then
        RenderStats(stats1, basePos, KColor(1, 1, 1, 0.67), lineHeight, false, true)
        RenderStats(stats2, basePos + Vector(4, 21), KColor(1, 0.75, 0.75, 0.67), lineHeight, true, false)
    else
        RenderStats(stats1, basePos, KColor(1, 1, 1, 0.67), lineHeight, false, false)
    end
end

local function IsBeastRoom(room)
    return room and room:GetType() == RoomType.ROOM_DUNGEON and room:GetRoomConfigStage() == 35
end

function mod:CheckForBeastAndRenderStats()
    if IsBeastRoom(Game():GetRoom()) then
        if not mod.isRendering then
            mod.isRendering = true
            fadeAlpha = 0
            mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.FadeInRender)
        end
    elseif mod.isRendering then
        mod.isRendering = false
        mod:RemoveCallback(ModCallbacks.MC_POST_RENDER, mod.FadeInRender)
    end
end

function mod:FadeInRender()
    if fadeAlpha < 0.67 then
        fadeAlpha = math.min(fadeAlpha + fadeSpeed, 1)
    end
    RenderPlayerStats()
end

function mod:ResetRender(isContinued)
    mod.isRendering = false
    fadeAlpha = 0
    mod:RemoveCallback(ModCallbacks.MC_POST_RENDER, mod.FadeInRender)
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.CheckForBeastAndRenderStats)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.ResetRender)

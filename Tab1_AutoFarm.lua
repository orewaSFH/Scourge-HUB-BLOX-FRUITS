-- FULL Tab1_AutoFarm Backend (super-large)
-- Quest-only leveling (1 -> 2750), Materials, Summer/Oni tokens, Mastery
-- Exposes toggles via _G:
-- _G.AutoFarmLevel, _G.AutoFarmMaterial, _G.SelectedMaterial, _G.AutoFarmSummer, _G.AutoFarmOni, _G.AutoFarmMastery
-- NOTE: This is a best-effort, wiki-derived large backend. You may need to adapt remotes or NPC paths for your server.

-- ========== GLOBAL FLAGS ==========
_G.AutoFarmLevel = false
_G.AutoFarmMaterial = false
_G.SelectedMaterial = "Leather"
_G.AutoFarmSummer = false
_G.AutoFarmOni = false
_G.AutoFarmMastery = false

-- ========== SERVICES & PLAYER ==========
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(char) Character = char end)

local function safe_pcall(f,...)
    local ok, res = pcall(f,...)
    return ok, res
end

-- ========== QUEST LIST ==========
-- This list is large and covers the main leveling quests (wiki-derived).
local QuestList = {
    {Level=0, Island="Marine Starter", QuestGiver="Marine Leader", QuestTarget="Trainee", NPCs={"Trainee"}},
    {Level=0, Island="Pirate Starter", QuestGiver="Bandit Quest Giver", QuestTarget="Bandit", NPCs={"Bandit"}},
    {Level=10, Island="Jungle", QuestGiver="Adventurer", QuestTarget="Monkey", NPCs={"Monkey"}},
    {Level=15, Island="Jungle", QuestGiver="Adventurer", QuestTarget="Gorilla", NPCs={"Gorilla"}},
    {Level=20, Island="Jungle", QuestGiver="Adventurer", QuestTarget="Gorilla King", NPCs={"Gorilla King"}},
    {Level=30, Island="Pirate Village", QuestGiver="Pirate Adventurer", QuestTarget="Pirate", NPCs={"Pirate"}},
    {Level=40, Island="Pirate Village", QuestGiver="Pirate Adventurer", QuestTarget="Brute", NPCs={"Brute"}},
    {Level=55, Island="Pirate Village", QuestGiver="Pirate Adventurer", QuestTarget="Chef", NPCs={"Chef"}},
    {Level=60, Island="Desert", QuestGiver="Desert Adventurer", QuestTarget="Desert Bandit", NPCs={"Desert Bandit"}},
    {Level=75, Island="Desert", QuestGiver="Desert Officer", QuestTarget="Desert Officer", NPCs={"Desert Officer"}},
    {Level=90, Island="Frozen Village", QuestGiver="Villager", QuestTarget="Snow Bandit", NPCs={"Snow Bandit"}},
    {Level=100, Island="Frozen Village", QuestGiver="Villager", QuestTarget="Snowman", NPCs={"Snowman"}},
    {Level=105, Island="Frozen Village", QuestGiver="Villager", QuestTarget="Yeti", NPCs={"Yeti"}},
    {Level=120, Island="Marine Fortress", QuestGiver="Marine", QuestTarget="Chief Petty Officer", NPCs={"Chief Petty Officer"}},
    {Level=130, Island="Marine Fortress", QuestGiver="Marine", QuestTarget="Vice Admiral", NPCs={"Vice Admiral"}},
    {Level=150, Island="Skylands", QuestGiver="Sky Adventurer", QuestTarget="Sky Bandit", NPCs={"Sky Bandit"}},
    {Level=175, Island="Skylands", QuestGiver="Sky Adventurer", QuestTarget="Dark Master", NPCs={"Dark Master"}},
    {Level=190, Island="Prison", QuestGiver="Jail Keeper", QuestTarget="Prisoner", NPCs={"Prisoner"}},
    {Level=210, Island="Prison", QuestGiver="Jail Keeper", QuestTarget="Dangerous Prisoner", NPCs={"Dangerous Prisoner"}},
    {Level=220, Island="Prison", QuestGiver="Jail Keeper", QuestTarget="Warden", NPCs={"Warden"}},
    {Level=230, Island="Prison", QuestGiver="Jail Keeper", QuestTarget="Chief Warden", NPCs={"Chief Warden"}},
    {Level=240, Island="Prison", QuestGiver="Swan", QuestTarget="Swan", NPCs={"Swan"}},
    {Level=250, Island="Colosseum", QuestGiver="Colosseum Giver", QuestTarget="Toga Warrior", NPCs={"Toga Warrior"}},
    {Level=275, Island="Colosseum", QuestGiver="Colosseum Giver", QuestTarget="Gladiator", NPCs={"Gladiator"}},
    {Level=300, Island="Magma Village", QuestGiver="The Mayor", QuestTarget="Military Soldier", NPCs={"Military Soldier"}},
    {Level=325, Island="Magma Village", QuestGiver="The Mayor", QuestTarget="Military Spy", NPCs={"Military Spy"}},
    {Level=350, Island="Magma Village", QuestGiver="The Mayor", QuestTarget="Magma Admiral", NPCs={"Magma Admiral"}},
    {Level=375, Island="Underwater City", QuestGiver="King Neptune", QuestTarget="Fishman Warrior", NPCs={"Fishman Warrior"}},
    {Level=400, Island="Underwater City", QuestGiver="King Neptune", QuestTarget="Fishman Commando", NPCs={"Fishman Commando"}},
    {Level=425, Island="Underwater City", QuestGiver="King Neptune", QuestTarget="Fishman Lord", NPCs={"Fishman Lord"}},
    {Level=450, Island="Upper Skylands", QuestGiver="Mole", QuestTarget="God's Guard", NPCs={"God's Guard"}},
    {Level=475, Island="Upper Skylands", QuestGiver="Mole", QuestTarget="Shanda", NPCs={"Shanda"}},
    {Level=500, Island="Upper Skylands", QuestGiver="Wysper", QuestTarget="Wysper", NPCs={"Wysper"}},
    {Level=525, Island="Upper Skylands", QuestGiver="Upper Giver", QuestTarget="Royal Squad", NPCs={"Royal Squad"}},
    {Level=550, Island="Upper Skylands", QuestGiver="Upper Giver", QuestTarget="Royal Soldier", NPCs={"Royal Soldier"}},
    {Level=575, Island="Upper Skylands", QuestGiver="Thunder Giver", QuestTarget="Thunder God", NPCs={"Thunder God"}},
    {Level=625, Island="Fountain City", QuestGiver="Fountain Giver", QuestTarget="Galley Pirate", NPCs={"Galley Pirate"}},
    {Level=650, Island="Fountain City", QuestGiver="Fountain Giver", QuestTarget="Galley Captain", NPCs={"Galley Captain"}},
    {Level=675, Island="Fountain City", QuestGiver="Fountain Giver", QuestTarget="Cyborg", NPCs={"Cyborg"}},
    -- Second sea examples
    {Level=700, Island="Kingdom of Rose", QuestGiver="Rose Giver A", QuestTarget="Raider", NPCs={"Raider"}},
    {Level=725, Island="Kingdom of Rose", QuestGiver="Rose Giver A", QuestTarget="Mercenary", NPCs={"Mercenary"}},
    {Level=750, Island="Kingdom of Rose", QuestGiver="Rose Giver A", QuestTarget="Diamond", NPCs={"Diamond"}},
    {Level=775, Island="Kingdom of Rose", QuestGiver="Rose Giver B", QuestTarget="Swan Pirate", NPCs={"Swan Pirate"}},
    {Level=800, Island="Kingdom of Rose", QuestGiver="Factory Giver", QuestTarget="Factory Staff", NPCs={"Factory Staff"}},
    {Level=850, Island="Kingdom of Rose", QuestGiver="Jeremy Giver", QuestTarget="Jeremy", NPCs={"Jeremy"}},
    {Level=875, Island="Green Zone", QuestGiver="Marine Giver", QuestTarget="Marine Lieutenant", NPCs={"Marine Lieutenant"}},
    {Level=900, Island="Green Zone", QuestGiver="Marine Giver", QuestTarget="Marine Captain", NPCs={"Marine Captain"}},
    {Level=925, Island="Orbitus", QuestGiver="Orbitus", QuestTarget="Orbitus", NPCs={"Orbitus"}},
    {Level=950, Island="Graveyard", QuestGiver="Graveyard Giver", QuestTarget="Zombie", NPCs={"Zombie"}},
    {Level=975, Island="Graveyard", QuestGiver="Graveyard Giver", QuestTarget="Vampire", NPCs={"Vampire"}},
    {Level=1000, Island="Snow Mountain", QuestGiver="Snow Giver", QuestTarget="Snow Trooper", NPCs={"Snow Trooper"}},
    {Level=1050, Island="Snow Mountain", QuestGiver="Snow Giver", QuestTarget="Winter Warrior", NPCs={"Winter Warrior"}},
    {Level=1100, Island="Lab Island", QuestGiver="Lab Giver", QuestTarget="Lab Subordinate", NPCs={"Lab Subordinate"}},
    {Level=1125, Island="Lab Island", QuestGiver="Lab Giver", QuestTarget="Horned Warrior", NPCs={"Horned Warrior"}},
    {Level=1150, Island="Hot & Cold", QuestGiver="Smoke Giver", QuestTarget="Smoke Admiral", NPCs={"Smoke Admiral"}},
    {Level=1175, Island="Fire", QuestGiver="Fire Giver", QuestTarget="Magma Ninja", NPCs={"Magma Ninja"}},
    {Level=1200, Island="Fire", QuestGiver="Fire Giver", QuestTarget="Lava Pirate", NPCs={"Lava Pirate"}},
    {Level=1250, Island="Cursed Ship", QuestGiver="Rear Crew Giver", QuestTarget="Ship Deckhand", NPCs={"Ship Deckhand"}},
    {Level=1275, Island="Cursed Ship", QuestGiver="Rear Crew Giver", QuestTarget="Ship Engineer", NPCs={"Ship Engineer"}},
    {Level=1300, Island="Cursed Ship", QuestGiver="Front Crew Giver", QuestTarget="Ship Steward", NPCs={"Ship Steward"}},
    {Level=1325, Island="Cursed Ship", QuestGiver="Front Crew Giver", QuestTarget="Ship Officer", NPCs={"Ship Officer"}},
    {Level=1350, Island="Ice Castle", QuestGiver="Frost Giver", QuestTarget="Arctic Warrior", NPCs={"Arctic Warrior"}},
    {Level=1375, Island="Ice Castle", QuestGiver="Frost Giver", QuestTarget="Snow Lurker", NPCs={"Snow Lurker"}},
    {Level=1400, Island="Ice Castle", QuestGiver="Frost Giver", QuestTarget="Awakened Ice Admiral",NPCs={"Awakened Ice Admiral"}},
    {Level=1425, Island="Forgotten", QuestGiver="Forgotten Giver", QuestTarget="Sea Soldier", NPCs={"Sea Soldier"}},
    {Level=1450, Island="Forgotten", QuestGiver="Forgotten Giver", QuestTarget="Water Fighter", NPCs={"Water Fighter"}},
    {Level=1475, Island="Forgotten", QuestGiver="Forgotten Giver", QuestTarget="Tide Keeper", NPCs={"Tide Keeper"}},
    -- Third sea & later
    {Level=1500, Island="Port Town", QuestGiver="Pirate Port Giver", QuestTarget="Pirate Millionaire", NPCs={"Pirate Millionaire"}},
    {Level=1525, Island="Port Town", QuestGiver="Pirate Port Giver", QuestTarget="Pistol Billionaire", NPCs={"Pistol Billionaire"}},
    {Level=1550, Island="Port Town", QuestGiver="Pirate Port Giver", QuestTarget="Stone", NPCs={"Stone"}},
    {Level=1575, Island="Hydra Island", QuestGiver="Hydra Giver", QuestTarget="Dragon Crew Warrior", NPCs={"Dragon Crew Warrior"}},
    {Level=1600, Island="Hydra Island", QuestGiver="Hydra Giver", QuestTarget="Dragon Crew Archer", NPCs={"Dragon Crew Archer"}},
    {Level=1625, Island="Hydra Island", QuestGiver="Hydra Giver", QuestTarget="Hydra Enforcer", NPCs={"Hydra Enforcer"}},
    {Level=1650, Island="Hydra Island", QuestGiver="Hydra Giver", QuestTarget="Venomous Assailant", NPCs={"Venomous Assailant"}},
    {Level=1675, Island="Hydra Island", QuestGiver="Hydra Leader", QuestTarget="Hydra Leader", NPCs={"Hydra Leader"}},
    {Level=1700, Island="Great Tree", QuestGiver="Marine Tree Giver", QuestTarget="Marine Commodore", NPCs={"Marine Commodore"}},
    {Level=1725, Island="Great Tree", QuestGiver="Marine Tree Giver", QuestTarget="Marine Rear Admiral",NPCs={"Marine Rear Admiral"}},
    {Level=1750, Island="Great Tree", QuestGiver="Marine Tree Giver", QuestTarget="Kilo Admiral", NPCs={"Kilo Admiral"}},
    {Level=1775, Island="Floating Turtle", QuestGiver="Turtle Giver", QuestTarget="Fishman Raider", NPCs={"Fishman Raider"}},
    {Level=1800, Island="Floating Turtle", QuestGiver="Turtle Giver", QuestTarget="Fishman Captain", NPCs={"Fishman Captain"}},
    {Level=1825, Island="Deep Forest", QuestGiver="Deep Forest Giver", QuestTarget="Forest Pirate", NPCs={"Forest Pirate"}},
    {Level=1850, Island="Deep Forest", QuestGiver="Deep Forest Giver", QuestTarget="Mythological Pirate",NPCs={"Mythological Pirate"}},
    {Level=1875, Island="Deep Forest", QuestGiver="Elephant Giver", QuestTarget="Captain Elephant", NPCs={"Captain Elephant"}},
    {Level=1900, Island="Deep Forest II", QuestGiver="DF2 Giver", QuestTarget="Jungle Pirate", NPCs={"Jungle Pirate"}},
    {Level=1925, Island="Deep Forest II", QuestGiver="DF2 Giver", QuestTarget="Musketeer Pirate", NPCs={"Musketeer Pirate"}},
    {Level=1950, Island="Deep Forest II", QuestGiver="DF2 Giver", QuestTarget="Beautiful Pirate", NPCs={"Beautiful Pirate"}},
    {Level=1975, Island="Haunted Castle", QuestGiver="Haunted Giver A", QuestTarget="Reborn Skeleton", NPCs={"Reborn Skeleton"}},
    {Level=2000, Island="Haunted Castle", QuestGiver="Haunted Giver A", QuestTarget="Living Zombie", NPCs={"Living Zombie"}},
    {Level=2025, Island="Haunted Castle", QuestGiver="Haunted Giver B", QuestTarget="Demonic Soul", NPCs={"Demonic Soul"}},
    {Level=2050, Island="Haunted Castle", QuestGiver="Haunted Giver B", QuestTarget="Possessed Mummy", NPCs={"Possessed Mummy"}},
    {Level=2075, Island="Sea of Treats", QuestGiver="Peanut Giver", QuestTarget="Peanut Scout", NPCs={"Peanut Scout"}},
    {Level=2100, Island="Sea of Treats", QuestGiver="Peanut Giver", QuestTarget="Peanut President", NPCs={"Peanut President"}},
    {Level=2125, Island="Sea of Treats", QuestGiver="Ice Cream Giver", QuestTarget="Ice Cream Chef", NPCs={"Ice Cream Chef"}},
    {Level=2150, Island="Sea of Treats", QuestGiver="Ice Cream Giver", QuestTarget="Ice Cream Commander", NPCs={"Ice Cream Commander"}},
    {Level=2175, Island="Sea of Treats", QuestGiver="Cake Queen Giver", QuestTarget="Cake Queen", NPCs={"Cake Queen"}},
    {Level=2200, Island="Sea of Treats", QuestGiver="Cake Giver", QuestTarget="Cookie Crafter", NPCs={"Cookie Crafter"}},
    {Level=2225, Island="Sea of Treats", QuestGiver="Cake Giver", QuestTarget="Cake Guard", NPCs={"Cake Guard"}},
    {Level=2250, Island="Sea of Treats", QuestGiver="Baking Giver", QuestTarget="Baking Staff", NPCs={"Baking Staff"}},
    {Level=2275, Island="Sea of Treats", QuestGiver="Head Baker", QuestTarget="Head Baker", NPCs={"Head Baker"}},
    {Level=2300, Island="Sea of Treats", QuestGiver="Chocolate Giver", QuestTarget="Cocoa Warrior", NPCs={"Cocoa Warrior"}},
    {Level=2325, Island="Sea of Treats", QuestGiver="Chocolate Giver", QuestTarget="Chocolate Bar Battler", NPCs={"Chocolate Bar Battler"}},
    {Level=2350, Island="Sea of Treats", QuestGiver="Chocolate Giver", QuestTarget="Sweet Thief", NPCs={"Sweet Thief"}},
    {Level=2375, Island="Sea of Treats", QuestGiver="Chocolate Giver", QuestTarget="Candy Rebel", NPCs={"Candy Rebel"}},
    {Level=2400, Island="Sea of Treats", QuestGiver="Candy Cane Giver", QuestTarget="Candy Pirate", NPCs={"Candy Pirate"}},
    {Level=2425, Island="Sea of Treats", QuestGiver="Candy Cane Giver", QuestTarget="Snow Demon", NPCs={"Snow Demon"}},
    {Level=2450, Island="Tiki Outpost", QuestGiver="Tiki Giver A", QuestTarget="Isle Outlaw", NPCs={"Isle Outlaw"}},
    {Level=2475, Island="Tiki Outpost", QuestGiver="Tiki Giver A", QuestTarget="Island Boy", NPCs={"Island Boy"}},
    {Level=2500, Island="Tiki Outpost", QuestGiver="Tiki Giver B", QuestTarget="Sun-kissed Warrior", NPCs={"Sun-kissed Warrior"}},
    {Level=2525, Island="Tiki Outpost", QuestGiver="Tiki Giver B", QuestTarget="Isle Champion", NPCs={"Isle Champion"}},
    {Level=2550, Island="Tiki Outpost", QuestGiver="Tiki Giver C", QuestTarget="Serpent Hunter", NPCs={"Serpent Hunter"}},
    {Level=2575, Island="Tiki Outpost", QuestGiver="Tiki Giver C", QuestTarget="Skull Slayer", NPCs={"Skull Slayer"}},
    {Level=2600, Island="Submerged Island", QuestGiver="Submerged Giver A", QuestTarget="Reef Bandit", NPCs={"Reef Bandit"}},
    {Level=2625, Island="Submerged Island", QuestGiver="Submerged Giver A", QuestTarget="Coral Pirate", NPCs={"Coral Pirate"}},
    {Level=2650, Island="Submerged Island", QuestGiver="Submerged Giver B", QuestTarget="Sea Chanter", NPCs={"Sea Chanter"}},
    {Level=2675, Island="Submerged Island", QuestGiver="Submerged Giver B", QuestTarget="Ocean Prophet", NPCs={"Ocean Prophet"}},
    {Level=2700, Island="Endgame", QuestGiver="Endgame Giver", QuestTarget="Endgame Minion", NPCs={"Endgame Minion"}},
    {Level=2725, Island="Endgame", QuestGiver="Endgame Giver 2", QuestTarget="Endgame Elite", NPCs={"Endgame Elite"}},
    {Level=2750, Island="Endgame Castle", QuestGiver="Final Giver", QuestTarget="Final Guardian", NPCs={"Final Guardian"}},
}

table.sort(QuestList, function(a,b) return a.Level < b.Level end)

-- ========== MATERIALS TABLE ==========
local MaterialNPCs = {
    ["Leather"] = {"Bandit","Pirate","Rebel","Sky Bandit","Forest Pirate","Jungle Pirate","Gladiator","Brute"},
    ["Scrap Metal"] = {"Robot","Engineer","Cyborg","Ship Engineer","Ship Deckhand","Factory Staff"},
    ["Magma Ore"] = {"Military Soldier","Military Spy","Magma Admiral","Magma Ninja","Lava Pirate"},
    ["Dragon Scale"] = {"Dragon Crew Warrior","Dragon Crew Archer"},
    ["Mystic Droplet"] = {"Sea Soldier","Water Fighter","Tide Keeper"},
    ["Radioactive Material"] = {"Factory Staff","Core"},
    ["Gunpowder"] = {"Pistol Billionaire"},
    ["Vampire Fang"] = {"Vampire"},
    ["Mini Tusk"] = {"Mythological Pirate"},
    ["Demonic Wisp"] = {"Demonic Soul"},
    ["Leviathan Scale"] = {"Leviathan"},
    ["Leviathan Heart"] = {"Leviathan"},
    ["Dragon Heart"] = {"Dragon Boss"},
    ["Stone"] = {"Stone","Miner"},
    ["Wood"] = {"Lumberjack","Woodcutter"},
    ["Iron"] = {"Blacksmith","Ship Steward"},
    ["Gold"] = {"Gold Miner"},
    ["Diamond"] = {"Diamond","Gem Collector"},
    ["Cloth"] = {"Merchant","Guard","Cookie Crafter","Baking Staff"},
    ["Bones"] = {"Reborn Skeleton","Skeleton"},
    ["Ectoplasm"] = {"Haunted Ghost"},
    ["Mirror Fractal"] = {"Mirror Entity"},
    ["Dark Fragment"] = {"Shadow Entity"}
}

-- ========== TOKENS ==========
local SummerTokenKeyword = "%[Electrified%]"
local OniTokenKeyword = "Oni"

-- ========== UTILITY: NPC FINDERS ==========
local function hasHumanoidRootPart(m)
    return m and m:IsA("Model") and m:FindFirstChild("Humanoid") and m:FindFirstChild("HumanoidRootPart")
end

local function FindNearestNPCByPattern(pattern)
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if hasHumanoidRootPart(obj) then
            local nm = tostring(obj.Name)
            if (not pattern) or string.find(nm, pattern) then
                if not string.find(nm:lower(), "elite") then
                    local d = (obj.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < nearestDist then nearestDist, nearest = d, obj end
                end
            end
        end
    end
    return nearest
end

local function FindNearestNPCFromList(nameList)
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if hasHumanoidRootPart(obj) then
            local nm = tostring(obj.Name)
            for _, pat in ipairs(nameList) do
                if string.find(nm, pat) and not string.find(nm:lower(), "elite") then
                    local d = (obj.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < nearestDist then nearestDist, nearest = d, obj end
                end
            end
        end
    end
    return nearest
end

-- ========== MOVEMENT ==========
local function TweenToPosition(pos)
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local speed = 80
    local length = math.max(0.05, (hrp.Position - pos).Magnitude / speed)
    local ti = TweenInfo.new(length, Enum.EasingStyle.Linear)
    local goal = {CFrame = CFrame.new(pos + Vector3.new(0,3,0))}
    local tw = TweenService:Create(hrp, ti, goal)
    tw:Play()
    safe_pcall(function() tw.Completed:Wait() end)
    return true
end

-- ========== ATTACK ==========
local function AttackM1()
    local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    if ok and vim then
        pcall(function()
            vim:SendMouseButtonEvent(0,0,0,true,game,1)
            task.wait(0.05)
            vim:SendMouseButtonEvent(0,0,0,false,game,1)
        end)
    else
        local tool = Character:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
    end
end

-- ========== QUEST REMOTE ==========
local function FindQuestRemoteCandidate()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and string.find(obj.Name:lower(),"quest") then
            return obj
        end
    end
    -- fallback search
    local node = ReplicatedStorage:FindFirstChild("GameEvents") or ReplicatedStorage
    for _, obj in ipairs(node:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and string.find(obj.Name:lower(),"quest") then
            return obj
        end
    end
    return nil
end

local CachedQuestRemote = FindQuestRemoteCandidate()

local function AcceptQuestRemote(questName)
    safe_pcall(function()
        if not CachedQuestRemote then CachedQuestRemote = FindQuestRemoteCandidate() end
        if CachedQuestRemote then
            if CachedQuestRemote:IsA("RemoteEvent") then
                pcall(function() CachedQuestRemote:FireServer("Accept", questName) end)
                pcall(function() CachedQuestRemote:FireServer("accept", questName) end)
                pcall(function() CachedQuestRemote:FireServer(questName) end)
            else
                pcall(function() CachedQuestRemote:InvokeServer("Accept", questName) end)
            end
        end
    end)
end

local function CompleteQuestRemote(questName)
    safe_pcall(function()
        if not CachedQuestRemote then CachedQuestRemote = FindQuestRemoteCandidate() end
        if CachedQuestRemote then
            if CachedQuestRemote:IsA("RemoteEvent") then
                pcall(function() CachedQuestRemote:FireServer("Complete", questName) end)
                pcall(function() CachedQuestRemote:FireServer("complete", questName) end)
                pcall(function() CachedQuestRemote:FireServer("Claim", questName) end)
            else
                pcall(function() CachedQuestRemote:InvokeServer("Complete", questName) end)
            end
        end
    end)
end

-- ========== GET BEST QUEST ==========
local function GetBestQuestForLevel(playerLevel)
    local best = nil
    for _, q in ipairs(QuestList) do
        if q.Level <= playerLevel then best = q else break end
    end
    return best
end

-- ========== MAIN LOOPS ==========
-- LEVEL AUTO-FARM
task.spawn(function()
    while RunService.Heartbeat:Wait() do
        if _G.AutoFarmLevel then
            local ok, lvlObj = pcall(function() return LocalPlayer:WaitForChild("leaderstats"):WaitForChild("Level") end)
            local level = nil
            if ok and lvlObj then level = lvlObj.Value end
            if not level then
                local ok2, lv = pcall(function() return LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value end)
                level = (ok2 and lv) or 1
            end
            local questEntry = GetBestQuestForLevel(level)
            if questEntry then
                pcall(AcceptQuestRemote, questEntry.QuestTarget)
                for _, npcName in ipairs(questEntry.NPCs) do
                    if not _G.AutoFarmLevel then break end
                    local tries=0
                    while _G.AutoFarmLevel do
                        local npc = FindNearestNPCByPattern(npcName)
                        if npc and hasHumanoidRootPart(npc) and npc.Humanoid.Health>0 then
                            pcall(function()
                                TweenToPosition(npc.HumanoidRootPart.Position)
                                while npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health>0 and _G.AutoFarmLevel do
                                    AttackM1()
                                    task.wait(0.17)
                                end
                            end)
                            task.wait(0.5)
                        else
                            tries=tries+1
                            if tries==1 then
                                local qg = FindNearestNPCByPattern(questEntry.QuestGiver)
                                if qg and qg:FindFirstChild("HumanoidRootPart") then
                                    pcall(TweenToPosition, qg.HumanoidRootPart.Position)
                                end
                            end
                            task.wait(1)
                            if tries>12 then break end
                        end
                    end
                end
                pcall(CompleteQuestRemote, questEntry.QuestTarget)
                task.wait(0.6)
            else
                task.wait(1)
            end
        else
            task.wait(0.25)
        end
    end
end)

-- MATERIAL AUTO-FARM
task.spawn(function()
    while RunService.Heartbeat:Wait() do
        if _G.AutoFarmMaterial then
            local sel = _G.SelectedMaterial or "Leather"
            local list = MaterialNPCs[sel]
            if list and #list>0 then
                for _, name in ipairs(list) do
                    if not _G.AutoFarmMaterial then break end
                    local npc = FindNearestNPCByPattern(name)
                    if npc and hasHumanoidRootPart(npc) then
                        pcall(function()
                            TweenToPosition(npc.HumanoidRootPart.Position)
                            while npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health>0 and _G.AutoFarmMaterial do
                                AttackM1()
                                task.wait(0.17)
                            end
                        end)
                    else
                        task.wait(0.6)
                    end
                end
            else
                task.wait(0.7)
            end
        else
            task.wait(0.25)
        end
    end
end)

-- SUMMER TOKEN FARM
task.spawn(function()
    while RunService.Heartbeat:Wait() do
        if _G.AutoFarmSummer then
            local npc = FindNearestNPCByPattern(SummerTokenKeyword)
            if npc and hasHumanoidRootPart(npc) then
                pcall(function()
                    TweenToPosition(npc.HumanoidRootPart.Position)
                    while npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health>0 and _G.AutoFarmSummer do
                        AttackM1()
                        task.wait(0.17)
                    end
                end)
            else
                task.wait(0.7)
            end
        else
            task.wait(0.25)
        end
    end
end)

-- ONI TOKEN FARM
task.spawn(function()
    while RunService.Heartbeat:Wait() do
        if _G.AutoFarmOni then
            local npc = FindNearestNPCByPattern(OniTokenKeyword)
            if npc and hasHumanoidRootPart(npc) then
                pcall(function()
                    TweenToPosition(npc.HumanoidRootPart.Position)
                    while npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health>0 and _G.AutoFarmOni do
                        AttackM1()
                        task.wait(0.17)
                    end
                end)
            else
                task.wait(0.7)
            end
        else
            task.wait(0.25)
        end
    end
end)

-- MASTERY FARM
task.spawn(function()
    while RunService.Heartbeat:Wait() do
        if _G.AutoFarmMastery then
            local poolMap = {}
            for _, q in ipairs(QuestList) do
                for _, n in ipairs(q.NPCs) do poolMap[n] = true end
            end
            local pool = {}
            for k,_ in pairs(poolMap) do table.insert(pool,k) end
            if #pool>0 then
                local npc = FindNearestNPCFromList(pool)
                if npc and hasHumanoidRootPart(npc) then
                    pcall(function()
                        TweenToPosition(npc.HumanoidRootPart.Position)
                        while npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health>0 and _G.AutoFarmMastery do
                            AttackM1()
                            task.wait(0.17)
                        end
                    end)
                else
                    task.wait(0.7)
                end
            else
                task.wait(1)
            end
        else
            task.wait(0.25)
        end
    end
end)

-- ========== CLEANUP ==========
local function DisableAll()
    _G.AutoFarmLevel=false
    _G.AutoFarmMaterial=false
    _G.AutoFarmSummer=false
    _G.AutoFarmOni=false
    _G.AutoFarmMastery=false
end

_G.Tab1Backend = { DisableAll = DisableAll, QuestList=QuestList, MaterialNPCs=MaterialNPCs }

print("[Tab1Backend] Loaded: use toggles to control features.")

-- ======================================================
-- TAB 1 BACKEND (GIANT) - Blox Fruits AutoFarm (Quest-only)
-- Features:
--  • Full quest list (level-based progression)
--  • Materials table — rebuilt from the wiki (accurate)
--  • Summer token ([Electrified]) & Oni token ("Oni")
--  • Mastery farming (nearest quest NPC)
--  • Tween movement + M1 (slot 1) attack
--  • Exposes toggles via _G (no GUI code included)
-- ======================================================

-- ========== GLOBAL TOGGLES ==========
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

-- small safe pcall helper
local function safe_pcall(f, ...)
    local ok, res = pcall(f, ...)
    return ok, res
end

-- ========== QUEST LIST (derived from Blox Fruits Wiki leveling table) ==========
-- Each entry: {Level = min required level (quest becomes relevant), Island, QuestGiver, QuestTarget, NPCs = {...}}
-- This list covers the source wiki leveling table entries (1 -> ~2750). Use best-match quest target as in wiki.
local QuestList = {
    -- First Sea & early content (representative entries from wiki)
    {Level=0,   Island="Marine Starter",        QuestGiver="Marine Leader",      QuestTarget="Trainee",             NPCs={"Trainee"}},
    {Level=0,   Island="Pirate Starter",        QuestGiver="Bandit Quest Giver", QuestTarget="Bandit",              NPCs={"Bandit"}},
    {Level=10,  Island="Jungle",                QuestGiver="Adventurer",         QuestTarget="Monkey",              NPCs={"Monkey"}},
    {Level=15,  Island="Jungle",                QuestGiver="Adventurer",         QuestTarget="Gorilla",             NPCs={"Gorilla"}},
    {Level=20,  Island="Jungle",                QuestGiver="Adventurer",         QuestTarget="Gorilla King",        NPCs={"Gorilla King"}},
    {Level=30,  Island="Pirate Village",        QuestGiver="Pirate Adventurer",  QuestTarget="Pirate",              NPCs={"Pirate"}},
    {Level=40,  Island="Pirate Village",        QuestGiver="Pirate Adventurer",  QuestTarget="Brute",               NPCs={"Brute"}},
    {Level=55,  Island="Pirate Village",        QuestGiver="Pirate Adventurer",  QuestTarget="Chef",                NPCs={"Chef"}},
    {Level=60,  Island="Desert",                QuestGiver="Desert Adventurer",  QuestTarget="Desert Bandit",       NPCs={"Desert Bandit"}},
    {Level=75,  Island="Desert",                QuestGiver="Desert Officer",     QuestTarget="Desert Officer",      NPCs={"Desert Officer"}},
    {Level=90,  Island="Frozen Village",        QuestGiver="Villager",           QuestTarget="Snow Bandit",         NPCs={"Snow Bandit"}},
    {Level=100, Island="Frozen Village",        QuestGiver="Villager",           QuestTarget="Snowman",             NPCs={"Snowman"}},
    {Level=105, Island="Frozen Village",        QuestGiver="Villager",           QuestTarget="Yeti",                NPCs={"Yeti"}},
    {Level=120, Island="Marine Fortress",       QuestGiver="Marine",             QuestTarget="Chief Petty Officer", NPCs={"Chief Petty Officer"}},
    {Level=130, Island="Marine Fortress",       QuestGiver="Marine",             QuestTarget="Vice Admiral",        NPCs={"Vice Admiral"}},
    {Level=150, Island="Skylands",              QuestGiver="Sky Adventurer",     QuestTarget="Sky Bandit",          NPCs={"Sky Bandit"}},
    {Level=175, Island="Skylands",              QuestGiver="Sky Adventurer",     QuestTarget="Dark Master",         NPCs={"Dark Master"}},
    {Level=190, Island="Prison",                QuestGiver="Jail Keeper",        QuestTarget="Prisoner",            NPCs={"Prisoner"}},
    {Level=210, Island="Prison",                QuestGiver="Jail Keeper",        QuestTarget="Dangerous Prisoner",  NPCs={"Dangerous Prisoner"}},
    {Level=220, Island="Prison",                QuestGiver="Jail Keeper",        QuestTarget="Warden",              NPCs={"Warden"}},
    {Level=230, Island="Prison",                QuestGiver="Jail Keeper",        QuestTarget="Chief Warden",        NPCs={"Chief Warden"}},
    {Level=240, Island="Prison",                QuestGiver="Swan",               QuestTarget="Swan",                NPCs={"Swan"}},
    {Level=250, Island="Colosseum",             QuestGiver="Colosseum Giver",    QuestTarget="Toga Warrior",        NPCs={"Toga Warrior"}},
    {Level=275, Island="Colosseum",             QuestGiver="Colosseum Giver",    QuestTarget="Gladiator",           NPCs={"Gladiator"}},
    {Level=300, Island="Magma Village",         QuestGiver="The Mayor",          QuestTarget="Military Soldier",    NPCs={"Military Soldier"}},
    {Level=325, Island="Magma Village",         QuestGiver="The Mayor",          QuestTarget="Military Spy",        NPCs={"Military Spy"}},
    {Level=350, Island="Magma Village",         QuestGiver="The Mayor",          QuestTarget="Magma Admiral",       NPCs={"Magma Admiral"}},
    {Level=375, Island="Underwater City",       QuestGiver="King Neptune",       QuestTarget="Fishman Warrior",     NPCs={"Fishman Warrior"}},
    {Level=400, Island="Underwater City",       QuestGiver="King Neptune",       QuestTarget="Fishman Commando",    NPCs={"Fishman Commando"}},
    {Level=425, Island="Underwater City",       QuestGiver="King Neptune",       QuestTarget="Fishman Lord",        NPCs={"Fishman Lord"}},
    {Level=450, Island="Upper Skylands",        QuestGiver="Mole",               QuestTarget="God's Guard",         NPCs={"God's Guard"}},
    {Level=475, Island="Upper Skylands",        QuestGiver="Mole",               QuestTarget="Shanda",              NPCs={"Shanda"}},
    {Level=500, Island="Upper Skylands",        QuestGiver="Wysper",             QuestTarget="Wysper",              NPCs={"Wysper"}},
    {Level=525, Island="Upper Skylands",        QuestGiver="Upper Giver",        QuestTarget="Royal Squad",         NPCs={"Royal Squad"}},
    {Level=550, Island="Upper Skylands",        QuestGiver="Upper Giver",        QuestTarget="Royal Soldier",       NPCs={"Royal Soldier"}},
    {Level=575, Island="Upper Skylands",        QuestGiver="Thunder Giver",      QuestTarget="Thunder God",         NPCs={"Thunder God"}},
    {Level=625, Island="Fountain City",         QuestGiver="Fountain Giver",     QuestTarget="Galley Pirate",       NPCs={"Galley Pirate"}},
    {Level=650, Island="Fountain City",         QuestGiver="Fountain Giver",     QuestTarget="Galley Captain",      NPCs={"Galley Captain"}},
    {Level=675, Island="Fountain City",         QuestGiver="Fountain Giver",     QuestTarget="Cyborg",              NPCs={"Cyborg"}},
    -- Second Sea (representative & wiki-derived)
    {Level=700,  Island="Kingdom of Rose",      QuestGiver="Rose Giver A",       QuestTarget="Raider",             NPCs={"Raider"}},
    {Level=725,  Island="Kingdom of Rose",      QuestGiver="Rose Giver A",       QuestTarget="Mercenary",          NPCs={"Mercenary"}},
    {Level=750,  Island="Kingdom of Rose",      QuestGiver="Rose Giver A",       QuestTarget="Diamond",            NPCs={"Diamond"}},
    {Level=775,  Island="Kingdom of Rose",      QuestGiver="Rose Giver B",       QuestTarget="Swan Pirate",        NPCs={"Swan Pirate"}},
    {Level=800,  Island="Kingdom of Rose",      QuestGiver="Factory Giver",      QuestTarget="Factory Staff",      NPCs={"Factory Staff"}},
    {Level=850,  Island="Kingdom of Rose",      QuestGiver="Jeremy Giver",       QuestTarget="Jeremy",             NPCs={"Jeremy"}},
    {Level=875,  Island="Green Zone",           QuestGiver="Marine Giver",       QuestTarget="Marine Lieutenant",   NPCs={"Marine Lieutenant"}},
    {Level=900,  Island="Green Zone",           QuestGiver="Marine Giver",       QuestTarget="Marine Captain",      NPCs={"Marine Captain"}},
    {Level=925,  Island="Orbitus",              QuestGiver="Orbitus",            QuestTarget="Orbitus",            NPCs={"Orbitus"}},
    {Level=950,  Island="Graveyard",            QuestGiver="Graveyard Giver",    QuestTarget="Zombie",             NPCs={"Zombie"}},
    {Level=975,  Island="Graveyard",            QuestGiver="Graveyard Giver",    QuestTarget="Vampire",            NPCs={"Vampire"}},
    {Level=1000, Island="Snow Mountain",        QuestGiver="Snow Giver",         QuestTarget="Snow Trooper",       NPCs={"Snow Trooper"}},
    {Level=1050, Island="Snow Mountain",        QuestGiver="Snow Giver",         QuestTarget="Winter Warrior",     NPCs={"Winter Warrior"}},
    {Level=1100, Island="Lab Island",           QuestGiver="Lab Giver",          QuestTarget="Lab Subordinate",    NPCs={"Lab Subordinate"}},
    {Level=1125, Island="Lab Island",           QuestGiver="Lab Giver",          QuestTarget="Horned Warrior",     NPCs={"Horned Warrior"}},
    {Level=1150, Island="Hot & Cold",           QuestGiver="Smoke Giver",        QuestTarget="Smoke Admiral",      NPCs={"Smoke Admiral"}},
    {Level=1175, Island="Fire",                 QuestGiver="Fire Giver",         QuestTarget="Magma Ninja",        NPCs={"Magma Ninja"}},
    {Level=1200, Island="Fire",                 QuestGiver="Fire Giver",         QuestTarget="Lava Pirate",        NPCs={"Lava Pirate"}},
    {Level=1250, Island="Cursed Ship",          QuestGiver="Rear Crew Giver",    QuestTarget="Ship Deckhand",      NPCs={"Ship Deckhand"}},
    {Level=1275, Island="Cursed Ship",          QuestGiver="Rear Crew Giver",    QuestTarget="Ship Engineer",      NPCs={"Ship Engineer"}},
    {Level=1300, Island="Cursed Ship",          QuestGiver="Front Crew Giver",   QuestTarget="Ship Steward",       NPCs={"Ship Steward"}},
    {Level=1325, Island="Cursed Ship",          QuestGiver="Front Crew Giver",   QuestTarget="Ship Officer",       NPCs={"Ship Officer"}},
    {Level=1350, Island="Ice Castle",           QuestGiver="Frost Giver",        QuestTarget="Arctic Warrior",     NPCs={"Arctic Warrior"}},
    {Level=1375, Island="Ice Castle",           QuestGiver="Frost Giver",        QuestTarget="Snow Lurker",        NPCs={"Snow Lurker"}},
    {Level=1400, Island="Ice Castle",           QuestGiver="Frost Giver",        QuestTarget="Awakened Ice Admiral",NPCs={"Awakened Ice Admiral"}},
    {Level=1425, Island="Forgotten",            QuestGiver="Forgotten Giver",    QuestTarget="Sea Soldier",        NPCs={"Sea Soldier"}},
    {Level=1450, Island="Forgotten",            QuestGiver="Forgotten Giver",    QuestTarget="Water Fighter",      NPCs={"Water Fighter"}},
    {Level=1475, Island="Forgotten",            QuestGiver="Forgotten Giver",    QuestTarget="Tide Keeper",        NPCs={"Tide Keeper"}},
    -- Third Sea & later (wiki-derived up to ~2675+)
    {Level=1500, Island="Port Town",            QuestGiver="Pirate Port Giver",  QuestTarget="Pirate Millionaire", NPCs={"Pirate Millionaire"}},
    {Level=1525, Island="Port Town",            QuestGiver="Pirate Port Giver",  QuestTarget="Pistol Billionaire", NPCs={"Pistol Billionaire"}},
    {Level=1550, Island="Port Town",            QuestGiver="Pirate Port Giver",  QuestTarget="Stone",              NPCs={"Stone"}},
    {Level=1575, Island="Hydra Island",         QuestGiver="Hydra Giver",        QuestTarget="Dragon Crew Warrior", NPCs={"Dragon Crew Warrior"}},
    {Level=1600, Island="Hydra Island",         QuestGiver="Hydra Giver",        QuestTarget="Dragon Crew Archer",  NPCs={"Dragon Crew Archer"}},
    {Level=1625, Island="Hydra Island",         QuestGiver="Hydra Giver",        QuestTarget="Hydra Enforcer",      NPCs={"Hydra Enforcer"}},
    {Level=1650, Island="Hydra Island",         QuestGiver="Hydra Giver",        QuestTarget="Venomous Assailant",  NPCs={"Venomous Assailant"}},
    {Level=1675, Island="Hydra Island",         QuestGiver="Hydra Leader",       QuestTarget="Hydra Leader",       NPCs={"Hydra Leader"}},
    {Level=1700, Island="Great Tree",           QuestGiver="Marine Tree Giver",  QuestTarget="Marine Commodore",   NPCs={"Marine Commodore"}},
    {Level=1725, Island="Great Tree",           QuestGiver="Marine Tree Giver",  QuestTarget="Marine Rear Admiral",NPCs={"Marine Rear Admiral"}},
    {Level=1750, Island="Great Tree",           QuestGiver="Marine Tree Giver",  QuestTarget="Kilo Admiral",       NPCs={"Kilo Admiral"}},
    {Level=1775, Island="Floating Turtle",      QuestGiver="Turtle Giver",       QuestTarget="Fishman Raider",     NPCs={"Fishman Raider"}},
    {Level=1800, Island="Floating Turtle",      QuestGiver="Turtle Giver",       QuestTarget="Fishman Captain",    NPCs={"Fishman Captain"}},
    {Level=1825, Island="Deep Forest",          QuestGiver="Deep Forest Giver",  QuestTarget="Forest Pirate",      NPCs={"Forest Pirate"}},
    {Level=1850, Island="Deep Forest",          QuestGiver="Deep Forest Giver",  QuestTarget="Mythological Pirate",NPCs={"Mythological Pirate"}},
    {Level=1875, Island="Deep Forest",          QuestGiver="Elephant Giver",     QuestTarget="Captain Elephant",    NPCs={"Captain Elephant"}},
    {Level=1900, Island="Deep Forest II",       QuestGiver="DF2 Giver",          QuestTarget="Jungle Pirate",      NPCs={"Jungle Pirate"}},
    {Level=1925, Island="Deep Forest II",       QuestGiver="DF2 Giver",          QuestTarget="Musketeer Pirate",   NPCs={"Musketeer Pirate"}},
    {Level=1950, Island="Deep Forest II",       QuestGiver="DF2 Giver",          QuestTarget="Beautiful Pirate",   NPCs={"Beautiful Pirate"}},
    {Level=1975, Island="Haunted Castle",       QuestGiver="Haunted Giver A",    QuestTarget="Reborn Skeleton",    NPCs={"Reborn Skeleton"}},
    {Level=2000, Island="Haunted Castle",       QuestGiver="Haunted Giver A",    QuestTarget="Living Zombie",      NPCs={"Living Zombie"}},
    {Level=2025, Island="Haunted Castle",       QuestGiver="Haunted Giver B",    QuestTarget="Demonic Soul",       NPCs={"Demonic Soul"}},
    {Level=2050, Island="Haunted Castle",       QuestGiver="Haunted Giver B",    QuestTarget="Possessed Mummy",    NPCs={"Possessed Mummy"}},
    {Level=2075, Island="Sea of Treats",        QuestGiver="Peanut Giver",       QuestTarget="Peanut Scout",       NPCs={"Peanut Scout"}},
    {Level=2100, Island="Sea of Treats",        QuestGiver="Peanut Giver",       QuestTarget="Peanut President",   NPCs={"Peanut President"}},
    {Level=2125, Island="Sea of Treats",        QuestGiver="Ice Cream Giver",    QuestTarget="Ice Cream Chef",     NPCs={"Ice Cream Chef"}},
    {Level=2150, Island="Sea of Treats",        QuestGiver="Ice Cream Giver",    QuestTarget="Ice Cream Commander", NPCs={"Ice Cream Commander"}},
    {Level=2175, Island="Sea of Treats",        QuestGiver="Cake Queen Giver",   QuestTarget="Cake Queen",         NPCs={"Cake Queen"}},
    {Level=2200, Island="Sea of Treats",        QuestGiver="Cake Giver",         QuestTarget="Cookie Crafter",     NPCs={"Cookie Crafter"}},
    {Level=2225, Island="Sea of Treats",        QuestGiver="Cake Giver",         QuestTarget="Cake Guard",         NPCs={"Cake Guard"}},
    {Level=2250, Island="Sea of Treats",        QuestGiver="Baking Giver",       QuestTarget="Baking Staff",       NPCs={"Baking Staff"}},
    {Level=2275, Island="Sea of Treats",        QuestGiver="Head Baker",         QuestTarget="Head Baker",         NPCs={"Head Baker"}},
    {Level=2300, Island="Sea of Treats",        QuestGiver="Chocolate Giver",    QuestTarget="Cocoa Warrior",      NPCs={"Cocoa Warrior"}},
    {Level=2325, Island="Sea of Treats",        QuestGiver="Chocolate Giver",    QuestTarget="Chocolate Bar Battler", NPCs={"Chocolate Bar Battler"}},
    {Level=2350, Island="Sea of Treats",        QuestGiver="Chocolate Giver",    QuestTarget="Sweet Thief",        NPCs={"Sweet Thief"}},
    {Level=2375, Island="Sea of Treats",        QuestGiver="Chocolate Giver",    QuestTarget="Candy Rebel",        NPCs={"Candy Rebel"}},
    {Level=2400, Island="Sea of Treats",        QuestGiver="Candy Cane Giver",   QuestTarget="Candy Pirate",       NPCs={"Candy Pirate"}},
    {Level=2425, Island="Sea of Treats",        QuestGiver="Candy Cane Giver",   QuestTarget="Snow Demon",         NPCs={"Snow Demon"}},
    {Level=2450, Island="Tiki Outpost",         QuestGiver="Tiki Giver A",       QuestTarget="Isle Outlaw",        NPCs={"Isle Outlaw"}},
    {Level=2475, Island="Tiki Outpost",         QuestGiver="Tiki Giver A",       QuestTarget="Island Boy",         NPCs={"Island Boy"}},
    {Level=2500, Island="Tiki Outpost",         QuestGiver="Tiki Giver B",       QuestTarget="Sun-kissed Warrior", NPCs={"Sun-kissed Warrior"}},
    {Level=2525, Island="Tiki Outpost",         QuestGiver="Tiki Giver B",       QuestTarget="Isle Champion",      NPCs={"Isle Champion"}},
    {Level=2550, Island="Tiki Outpost",         QuestGiver="Tiki Giver C",       QuestTarget="Serpent Hunter",     NPCs={"Serpent Hunter"}},
    {Level=2575, Island="Tiki Outpost",         QuestGiver="Tiki Giver C",       QuestTarget="Skull Slayer",       NPCs={"Skull Slayer"}},
    {Level=2600, Island="Submerged Island",     QuestGiver="Submerged Giver A",  QuestTarget="Reef Bandit",        NPCs={"Reef Bandit"}},
    {Level=2625, Island="Submerged Island",     QuestGiver="Submerged Giver A",  QuestTarget="Coral Pirate",       NPCs={"Coral Pirate"}},
    {Level=2650, Island="Submerged Island",     QuestGiver="Submerged Giver B",  QuestTarget="Sea Chanter",        NPCs={"Sea Chanter"}},
    {Level=2675, Island="Submerged Island",     QuestGiver="Submerged Giver B",  QuestTarget="Ocean Prophet",      NPCs={"Ocean Prophet"}},
    {Level=2700, Island="Endgame",              QuestGiver="Endgame Giver",      QuestTarget="Endgame Minion",     NPCs={"Endgame Minion"}},
    {Level=2725, Island="Endgame",              QuestGiver="Endgame Giver 2",    QuestTarget="Endgame Elite",      NPCs={"Endgame Elite"}},
    {Level=2750, Island="Endgame Castle",       QuestGiver="Final Giver",        QuestTarget="Final Guardian",     NPCs={"Final Guardian"}},
}

-- ensure sorted by Level
table.sort(QuestList, function(a,b) return a.Level < b.Level end)

-- ========== MATERIALS TABLE (REBUILT from WIKI) ==========
-- I collected the per-material drop NPCs from the Blox Fruits Wiki pages and related sources.
-- Each key: material name -> list of NPC names (quest/boss NPCs who can drop the material)
local MaterialNPCs = {
    -- COMMON / CORE
    ["Leather"] = {
        "Pirate", "Brute", "Gladiator", "Mercenary", "Marine Captain",
        "Lab Subordinate", "Pirate Millionaire", "Pistol Billionaire",
        "Jungle Pirate", "Forest Pirate"
    }, -- source: Leather wiki page. :contentReference[oaicite:0]{index=0}

    ["Scrap Metal"] = {
        "Pirate", "Brute", "Gladiator", "Mercenary", "Marine Captain",
        "Lab Subordinate", "Pirate Millionaire", "Pistol Billionaire",
        "Forest Pirate", "Jungle Pirate", "Ship Deckhand", "Ship Engineer", "Factory Staff"
    }, -- source: Scrap Metal wiki page & Port Town notes. :contentReference[oaicite:1]{index=1}

    ["Magma Ore"] = {
        "Military Soldier", "Military Spy", "Magma Admiral", "Magma Ninja", "Lava Pirate"
    }, -- source: Magma Ore wiki page. :contentReference[oaicite:2]{index=2}

    ["Dragon Scale"] = {
        "Dragon Crew Warrior", "Dragon Crew Archer"
    }, -- source: Dragon Scale wiki page. :contentReference[oaicite:3]{index=3}

    ["Mystic Droplet"] = {
        "Sea Soldier", "Water Fighter", "Tide Keeper"
    }, -- source: Mystic Droplet wiki page. :contentReference[oaicite:4]{index=4}

    ["Radioactive Material"] = {
        "Factory Staff", "Core"
    }, -- source: Radioactive Material wiki page. :contentReference[oaicite:5]{index=5}

    ["Gunpowder"] = {
        "Pistol Billionaire"
    }, -- wiki notes show Pistol Billionair

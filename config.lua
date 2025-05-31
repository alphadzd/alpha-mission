Config = {}

Config.NPCLocation = vector4(785.84, -1117.69, 22.69, 357.12)
Config.NPCModel = "a_m_y_business_03"
Config.NPCScenario = "WORLD_HUMAN_STAND_IMPATIENT"

Config.EnableBlip = true
Config.BlipSprite = 280
Config.BlipColor = 2
Config.BlipScale = 0.7
Config.BlipName = "Big Boss"

Config.EnableInteraction = true
Config.UseTarget = true
Config.InteractionDistance = 2.0
Config.InteractionText = "Talk to Big Boss"
Config.TargetIcon = "fas fa-comment"
Config.TargetLabel = "Talk to Big Boss"

Config.MissionCooldown = 60 * 60
Config.BagItem = "mission_bag"

Config.DeliveryLocations = {
    vector4(1240.61, -355.91, 69.08, 258.69),
    vector4(892.48, -2172.12, 32.28, 174.5),
    vector4(-1117.21, -503.65, 35.81, 302.78),
    vector4(147.66, -1039.3, 29.37, 339.57),
    vector4(-1285.92, -1387.87, 4.25, 109.39)
}
Config.DeliveryNPCModel = "s_m_m_highsec_01"
Config.DeliveryNPCScenario = "WORLD_HUMAN_STAND_MOBILE"

Config.EnemyVehicles = {
    "schafter3",
    "kuruma",
    "cognoscenti",
    "sultan",
    "fugitive"
}

Config.EnemyPeds = {
    "g_m_y_mexgang_01",
    "g_m_y_mexgoon_01",
    "g_m_y_mexgoon_02",
    "g_m_y_mexgoon_03"
}

Config.EnemyWeapon = "WEAPON_MICROSMG" -- السلاح الذي يستخدمه الأعداء
Config.EnemyWeaponAccuracy = 30 -- دقة إطلاق النار (0 إلى 100)
Config.EnemyArmor = 100 -- قيمة الدرع (0 إلى 100)
Config.EnemyCarsCount = 5 -- عدد سيارات الأعداء
Config.EnemiesPerCar = 4 -- عدد الأعداء داخل كل سيارة
Config.EnemyDifficulty = 2 -- صعوبة الأعداء (1 = سهل، 2 = متوسط، 3 = صعب)

-- إعدادات المكافآت
Config.Rewards = {
    -- مكافآت نقدية
    Cash = {
        Enabled = true, -- تفعيل مكافآت الكاش
        MinAmount = 5000, -- الحد الأدنى للمبلغ
        MaxAmount = 10000, -- الحد الأعلى للمبلغ
        TeamMemberMinAmount = 3000, -- الحد الأدنى لأعضاء الفريق
        TeamMemberMaxAmount = 7000 -- الحد الأعلى لأعضاء الفريق
    },
    
    -- مكافآت العناصر
    Items = {
        Enabled = false, -- تفعيل/تعطيل مكافآت العناصر
        PossibleItems = {
            {name = "weapon_pistol", amount = 1, chance = 10}, -- احتمال 10%
            {name = "armor", amount = 2, chance = 30},         -- احتمال 30%
            {name = "lockpick", amount = 5, chance = 60},      -- احتمال 60%
            {name = "phone", amount = 1, chance = 5}           -- احتمال 5%
        }
    },
    
    -- مكافآت خاصة
    SpecialRewards = {
        Enabled = false, -- تفعيل/تعطيل المكافآت الخاصة
        ChanceToTrigger = 5, -- احتمال حدوث مكافأة خاصة (5%)
        PossibleRewards = {
            {type = "vehicle", model = "sultan", chance = 1},   -- احتمال 1%
            {type = "weapon", name = "WEAPON_PISTOL50", chance = 4} -- احتمال 4%
        }
    }
}

-- إعدادات واجهة 
Config.UI = {
    PrimaryColor = "#8A2BE2", 
    SecondaryColor = "#4B0082",
    AccentColor = "#9370DB", 
    TextColor = "#FFFFFF", 
    BackgroundColor = "#2A0A29", 
    BorderColor = "#9932CC"
}

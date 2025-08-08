Config = {}

Config.StartPed = {
    model = 'g_m_m_mexboss_01',
    coords = vec4(-1123.56, -2873.23, 13.95, 237.14)
}

Config.RequiredItem = 'cokebrick'
Config.RequiredAmount = 5

Config.PlaneModel = 'dodo'
Config.SpawnPlane = vector4(-1127.771, -2915.047, 13.945, 148.641)
Config.LandingZone = vec3(-1130.45, -2870.32, 13.0)

Config.DropCountRange = {min = 3, max = 6}
Config.DropLocations = {
    vec3(-1000.0, -3200.0, 150.0),
    vec3(-500.0, -3000.0, 160.0),
    vec3(-1500.0, -3500.0, 155.0),
    vec3(-750.0, -3400.0, 145.0),
    vec3(-1300.0, -3300.0, 150.0),
    vec3(-1100.0, -3100.0, 140.0),
}


Config.StashPrefix = 'drugplane_stash_' -- final stash ID becomes e.g. drugplane_stash_123
Config.RequiredItem = 'coke_batch'
Config.PayoutPerPurity = 10 -- 1 purity = $10
Config.StashSize = {
    slots = 10,
    weight = 50000,
}

Config.AllowedDrugs = {
    'coke_batch',
    '',
    ''
}

Config.RequiredAmount = 3


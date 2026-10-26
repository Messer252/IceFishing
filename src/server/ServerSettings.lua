-- This module stays in ServerScriptService, never ReplicatedStorage.
return {
    LiveStoreName = "FrostbitePlayers_v2",
    StudioStoreName = "FrostbiteStudio_TEST_v2",
    StudioPersistence = false, -- Explicitly enable only in a published TEST place.
    AutosaveSeconds = 60,
    LeaseSeconds = 180,
    AdminUsername = "unbenator",
    AdminUserIds = {}, -- Optional permanent numeric IDs; independent of renames.
    StudioAdminUserIds = {}, -- Optional Studio test players, e.g. -1; never live.
    MaxMoneyGrant = 1000000,
    MaxXPGrant = 100000,
    FlySpeed = 55,
}

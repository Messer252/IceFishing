local Models, Config, Recipes = dofile("tests/model_support.lua").load()
local count = 0
local function check(value, text) assert(value, text) count = count + 1 end
local function named(model, name)
    local result = {} for _, part in ipairs(model:GetChildren()) do if part.Name == name then table.insert(result, part) end end return result
end
local function signature(model)
    local result = {}
    for _, p in ipairs(model:GetChildren()) do
        table.insert(result, string.format("%s:%s:%.3f:%.3f:%.3f:%.3f:%.3f:%.3f", p.Name, p.ClassName, p.Size.X, p.Size.Y, p.Size.Z, p.Position.X, p.Position.Y, p.Position.Z))
    end
    return table.concat(result, "|")
end
local models, fingerprints = {}, {}
for _, species in ipairs(Config.Fish) do
    check(Recipes[species.id] ~= nil, "Every species needs a deliberate appearance recipe: " .. species.id)
    local model = Models.build(species.id, species.color, false, "Normal", "high")
    local low = Models.build(species.id, species.color, false, "Normal", "low")
    models[species.id] = model
    local fingerprint = signature(model)
    check(not fingerprints[fingerprint], "Species must differ in geometry, not only color: " .. species.id)
    fingerprints[fingerprint] = true
    check(#model:GetChildren() <= 180 and #low:GetChildren() <= 110, "Models must respect the preview geometry budget: " .. species.id)
    for _, p in ipairs(model:GetChildren()) do
        assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Preview fish cannot affect gameplay physics")
        assert(p.Size.X > 0 and p.Size.Y > 0 and p.Size.Z > 0, "Geometry dimensions must be positive")
    end
    local silhouette = Models.build(species.id, nil, true)
    for _, p in ipairs(silhouette:GetChildren()) do assert(p.Color.R == 31 / 255 and p.Color.G == 47 / 255 and p.Color.B == 59 / 255, "Undiscovered silhouettes must not leak skin patterns") end
end
check(models.pike.PrimaryPart.Size.X / models.pike.PrimaryPart.Size.Y > 4 * models.bluegill.PrimaryPart.Size.X / models.bluegill.PrimaryPart.Size.Y, "Pike and bluegill have visibly different slenderness")
check(#named(models.perch, "VerticalBar") >= 30, "Yellow perch have dark vertical bars")
check(#named(models.whitebass, "LateralStripe") >= 60, "White bass have multiple horizontal stripes")
check(#named(models.pumpkinseed, "TurquoiseCheekRay") == 8 and #named(models.pumpkinseed, "OrangeEarEdge") == 2, "Pumpkinseed have turquoise face lines and orange ear edges")
check(#named(models.bluegill, "OpercularSpot") == 2, "Bluegill have dark opercular spots")
check(#named(models.trout, "RoseLateralStripe") > 0 and #named(models.trout, "SpeciesSpot") > 0, "Rainbow trout have a rose stripe and dark speckles")
check(#named(models.char, "WhiteFinEdge") == 2 and #named(models.char, "SpeciesSpot") > 0, "Arctic char have pale spots and white fin edges")
check(#named(models.walleye, "DorsalFin") == 2 and #named(models.walleye, "WhiteTailTip") == 1, "Walleye have separated dorsal fins and a white lower tail tip")
check(#named(models.sturgeon, "LateralScute") >= 30 and #named(models.sturgeon, "Barbel") == 4 and #named(models.sturgeon, "UnderslungMouth") == 1, "Sturgeon have scutes, an underslung mouth, and four barbels")
check(#named(models.flathead, "Barbel") == 8 and #named(models.burbot, "Barbel") == 1, "Catfish and burbot use the correct different barbel arrangements")
check(named(models.tundragar, "Snout")[1].Size.X > named(models.pike, "Snout")[1].Size.X and #named(models.tundragar, "GanoidScale") > 0, "Gar have long narrow snouts and ganoid-scale markings")
check(#named(models.glasskoi, "KoiColorPatch") > 0 and #named(models.glasskoi, "FlowingTail") == 3, "Koi have patchwork coloration and flowing tails")
local gold = Models.build("pike", { 248, 203, 83 }, false, "Golden")
check(signature(gold) == signature(models.pike), "Variants preserve species anatomy and marking geometry")
check(gold.PrimaryPart.Color.R ~= models.pike.PrimaryPart.Color.R and #named(gold, "SpeciesSpot") == #named(models.pike, "SpeciesSpot"), "Variants tint the body without erasing its spots")
check(math.abs(models.pike.PrimaryPart.Color.R - Recipes.pike.body[1] / 255) < 0.000001, "Normal fish use their natural palette instead of a rarity color")
print("PASS: " .. count .. " fish anatomy, markings, variant and geometry-budget checks (API fakes)")

// ============================================================
// main.gsc
// ============================================================

/*
    ░█████╗░██████╗░██████╗░░█████╗░██████╗░██╗████████╗██╗░█████╗░███╗░░██╗
    ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║╚══██╔══╝██║██╔══██╗████╗░██║
    ███████║██████╔╝██████╔╝███████║██████╔╝██║░░░██║░░░██║██║░░██║██╔██╗██║
    ██╔══██║██╔═══╝░██╔═══╝░██╔══██║██╔══██╗██║░░░██║░░░██║██║░░██║██║╚████║
    ██║░░██║██║░░░░░██║░░░░░██║░░██║██║░░██║██║░░░██║░░░██║╚█████╔╝██║░╚███║
    ╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

    Menu:                 Apparition
    Developer:            CF4_99
    Version:              1.6.0.9
    Discord:              cf4_99
    YouTube:              https://www.youtube.com/c/CF499
    Project Start Date:   6/10/21
    Initial Release Date: 1/29/23

    Apparition Discord Server: https://discord.gg/apparitionbo3
    Menu Source & Current Update: https://github.com/CF4x99/Apparition
    Menu Source(For Mod Tools): https://github.com/CF4x99/Apparition-ModTools

    IF YOU USE ANY SCRIPTS FROM THIS PROJECT, OR MAKE AN EDIT, LEAVE CREDIT.
    PLEASE DO NOT REUPLOAD THIS PROJECT TO THE WORKSHOP!

    Credits:
        - Extinct ~ Ideas, Suggestions, Constructive Criticism, and His Spec-Nade
        - CraftyCritter ~ BO3 Compiler
        - ItsFebiven ~ Ideas and Suggestions
        - Joel ~ Suggestions, Bug Reports, and Testing The Unique String Crash Protection

    If you find any bugs, or come across something that you feel isn't working as it should, please message me on discord.

    Discord: cf4_99
*/

#using scripts\zm\_zm;
#using scripts\zm\_util;
#using scripts\zm\_zm_net;
#using scripts\zm\_zm_bgb;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_stats;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_zonemgr;
#using scripts\zm\_zm_spawner;
#using scripts\zm\_zm_blockers;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_behavior;
#using scripts\zm\_zm_magicbox;
#using scripts\zm\_zm_equipment;
#using scripts\zm\_zm_laststand;
#using scripts\zm\_zm_unitrigger;
#using scripts\shared\music_shared;
#using scripts\zm\_zm_melee_weapon;
#using scripts\zm\_zm_placeable_mine;
#using scripts\zm\gametypes\_globallogic;
#using scripts\zm\craftables\_zm_craftables;
#using scripts\zm\_zm_powerup_weapon_minigun;
#using scripts\zm\gametypes\_globallogic_score;

#using scripts\shared\ai_shared;
#using scripts\shared\bots\_bot;
#using scripts\shared\hud_shared;
#using scripts\shared\lui_shared;
#using scripts\shared\aat_shared;
#using scripts\shared\util_shared;
#using scripts\codescripts\struct;
#using scripts\shared\math_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\rank_shared;
#using scripts\shared\_burnplayer;
#using scripts\shared\scene_shared;
#using scripts\shared\array_shared;
#using scripts\shared\system_shared;
#using scripts\shared\ai\systems\gib;
#using scripts\shared\spawner_shared;
#using scripts\shared\vehicle_shared;
#using scripts\shared\ai\zombie_death;
#using scripts\shared\hud_util_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\gameskill_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\ai\zombie_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\ai\zombie_utility;
#using scripts\shared\tweakables_shared;
#using scripts\shared\ai\systems\shared;
#using scripts\shared\vehicle_ai_shared;
#using scripts\shared\scoreevents_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\visionset_mgr_shared;
#using scripts\shared\damagefeedback_shared;
#using scripts\shared\abilities\_ability_power;

#namespace duplicate_render;

function autoexec __init__system__()
{
    system::register("duplicate_render", &__init__, undefined, undefined);
}

function __init__()
{
    callback::on_spawned(&onPlayerSpawned);
    callback::on_disconnect(&onPlayerDisconnect);
}

function onPlayerSpawned()
{
    self endon("disconnect");

    if(Is_True(self.runningSpawned))
        return;
    self.runningSpawned = true;
    
    if(self IsHost() && !IsDefined(self.playerSpawned))
    {
        level thread RGBFade();
        self thread AntiEndGame();

        GSpawnMax = ReturnMapGSpawnLimit();

        if(IsDefined(GSpawnMax) && GSpawnMax)
            self thread GSpawnProtection();
        
        level SetGameOverrides();
    }

    if(IsDefined(self.overrideplayerdamage))
        self.saved_playeroverrideplayerdamage = self.overrideplayerdamage;
    
    self.overrideplayerdamage = &override_player_damage;

    self thread GivePlayerLoadout();
    level flag::wait_till("initial_blackscreen_passed");
    self notify("stop_player_out_of_playable_area_monitor");

    self AllowWallRun(0);
    self AllowDoubleJump(0);

    self.StartOrigin = self.origin;

    if(GetDvarString(level.script + "Spawn" + self GetEntityNumber()) != "")
    {
        savedPos = GetDvarVector1(level.script + "Spawn" + self GetEntityNumber());

        if(savedPos != (0, 0, 0))
            self SetOrigin(savedPos);
    }

    if(Is_True(self._retain_perks) && IsDefined(self.retained_perks) && self.retained_perks.size)
    {
        for(a = 0; a < self.retained_perks.size; a++)
        {
            self notify(self.retained_perks[a] + "_stop");

            if(self HasPerk(self.retained_perks[a]))
            {
                self UnSetPerk(self.retained_perks[a]);
                self.num_perks--;

                if(self.num_perks < 0)
                    self.num_perks = 0;
                
                if(IsDefined(self.perks_active) && isInArray(self.perks_active, self.retained_perks[a]))
                    ArrayRemoveValue(self.perks_active, self.retained_perks[a], 0);
            }

            self zm_perks::give_perk(self.retained_perks[a], true);
        }
    }
    
    self.runningSpawned = BoolVar(self.runningSpawned);

    //Anything Above This Is Ran Every Time The Player Spawns
    if(IsDefined(self.playerSpawned))
        return;
    self.playerSpawned = true;
    
    self playerSetup();
}

function DefineMenuArrays()
{
    level.BgGravity = GetDvarInt("bg_gravity");
    level.GSpeed = GetDvarString("g_speed");
    level.roundIntermissionTime = ((IsDefined(level.zombie_vars) && IsDefined(level.zombie_vars["zombie_between_round_time"])) ? level.zombie_vars["zombie_between_round_time"] : 10);
    
    level.menu_entities = [];
    level.menu_models = Array("defaultactor", "defaultvehicle");
    ents = GetEntArray("script_model", "classname");

    if(IsDefined(ents) && ents.size)
    {
        foreach(entity in ents)
        {
            if(!IsDefined(entity) || !IsDefined(entity.model) || entity.model == "" || entity.model == "tag_origin" || IsSubStr(entity.model, "collision"))
                continue;

            array::add(level.menu_models, entity.model, 0);
            level.menu_entities[level.menu_entities.size] = entity;
            
            entity.savedOrigin = entity.origin;
            entity.savedAngles = entity.angles;
        }
    }
    
    tempEffects = [];
    level.menuFX = [];
    fxs = GetArrayKeys(level._effect);

    if(IsDefined(fxs) && fxs.size)
    {
        for(a = 0; a < fxs.size; a++)
        {
            if(!IsDefined(fxs[a]))
                continue;
            
            if(IsSubStr(fxs[a], "step_") || IsSubStr(fxs[a], "fall_") || IsSubStr(fxs[a], "tesla_viewmodel") || isInArray(level.menuFX, fxs[a]) || isInArray(tempEffects, level._effect[fxs[a]]))
                continue;
            
            level.menuFX[level.menuFX.size] = fxs[a];
            tempEffects[tempEffects.size] = level._effect[fxs[a]];
        }
    }
    
    level.custom_boxWeapons = [];
    weapons = GetArrayKeys(level.zombie_weapons);

    if(IsDefined(weapons) && weapons.size)
    {
        for(a = 0; a < weapons.size; a++)
        {
            if(IsDefined(weapons[a]) && Is_True(level.zombie_weapons[weapons[a]].is_in_box))
                array::add(level.custom_boxWeapons, weapons[a], 0);
        }
    }

    trapTypes = Array("zombie_trap", "gas_access", "trap_electric", "trap_fire", "use_trap_chain");
    level.menu_traps = [];

    for(a = 0; a < trapTypes.size; a++)
    {
        traps = GetEntArray(trapTypes[a], "targetname");

        if(IsDefined(traps) && traps.size)
        {
            for(b = 0; b < traps.size; b++)
            {
                if(!IsDefined(traps[b]) || !IsDefined(traps[b].prefabname))
                    continue;
                
                duplicate = false;

                foreach(trap in level.menu_traps)
                {
                    if(IsDefined(trap.prefabname) && trap.prefabname == traps[b].prefabname)
                    {
                        duplicate = true;
                        break;
                    }
                }

                if(!duplicate)
                    array::add(level.menu_traps, traps[b], 0);
            }
        }
    }

    foreach(DeathBarrier in GetEntArray("trigger_hurt", "classname"))
    {
        if(!IsDefined(DeathBarrier))
            continue;
        
        DeathBarrier Delete();
    }

    level.saved_jokerModel = level.chest_joker_model;
    
    SetDvar("wallRun_maxTimeMs_zm", 10000);
    SetDvar("playerEnergy_maxReserve_zm", 200);
    SetDvar("doublejump_enabled", 1);
    SetDvar("playerEnergy_enabled", 1);
    SetDvar("wallrun_enabled", 1);
}

function playerSetup()
{
    if(self util::is_bot())
    {
        self.accessLevel = GetAccessLevels()[0];
        return;
    }

    self.hud_count = 0;
    self.menuUI = [];
    
    //Menu Design Variables
    self LoadMenuVars();

    accessValue = GetDvarInt("ApparitionV_" + self GetXUID());
    accessLevel = (IsDefined(accessValue) ? ((accessValue > 0 && accessValue < (GetAccessLevels().size - 1)) ? accessValue : 1) : 1);

    self.accessLevel = (self isDeveloper() ? GetAccessLevels()[(GetAccessLevels().size - 1)] : (self IsHost() ? GetAccessLevels()[(GetAccessLevels().size - 2)] : GetAccessLevels()[accessLevel]));
    
    if(self hasMenu())
    {
        self thread MenuInstructionsDisplay();
        self thread menuMonitor();
    }

    if(self IsHost())
    {
        level DefineMenuArrays();

        entityCount = GetDvarInt("EntityCountDisplay");

        if(IsDefined(entityCount) && entityCount)
            self thread EntityCountDisplay();

        if(ReturnMapName() == "Unknown" || IsSupportedCustomMap())
            self DebugiPrint("^1" + ToUpper(GetMenuName()) + ": ^7On Custom Maps, Some Things Might Not Work As They Should");
        
        if(IsDefined(level.uiparent) && IsDefined(level.uiparent.children) && level.uiparent.children.size)
        {
            for(a = 0; a < level.uiparent.children.size; a++)
            {
                if(!IsDefined(level.uiparent.children[a]))
                    continue;
                
                level.uiparent.children[a] hud::destroyelem();
            }

            level.uiparent.children = [];
        }
    }
}

function MenuInstructionsDisplay()
{
    self endon("disconnect");
    
    if(Is_True(self.MenuInstructionsDisplay))
        return;
    self.MenuInstructionsDisplay = true;

    self.menuInstructionsUI = [];
    
    while(self hasMenu() && !Is_True(self.DisableMenuInstructions))
    {
        if(self hasMenu() && (!Is_True(self.DisableMenuInstructions) && (!IsDefined(self.menuInstructionsUI["background"]) && !Is_True(self.DisableInstructionsBackground) || !IsDefined(self.menuInstructionsUI["outline"]) && !Is_True(self.DisableInstructionsBackground) || !IsDefined(self.menuInstructionsUI["string"]))))
        {
            alt = Is_True(self.AlternateInstructions);
            bgAlpha = ((self.MenuDesign == "Classic") ? 0.85 : 1);
            bgColor = ((self.MenuDesign == "Classic") ? (25, 25, 25) : ((self.MenuDesign == "Apparition") ? (42, 42, 42) : (0, 0, 0)));

            if(!IsDefined(self.menuInstructionsUI["background"]) && !Is_True(self.DisableInstructionsBackground))
                self.menuInstructionsUI["background"] = self createRectangle((alt ? "CENTER" : "TOP_LEFT"), self.instructionsX, self.instructionsY, 0, 15, bgColor, 2, bgAlpha, "white");
            
            if(!IsDefined(self.menuInstructionsUI["outline"]) && !Is_True(self.DisableInstructionsBackground))
                self.menuInstructionsUI["outline"] = self createRectangle((alt ? "CENTER" : "TOP_LEFT"), (alt ? self.instructionsX : (self.instructionsX - 1)), (alt ? self.instructionsY : (self.instructionsY - 1)), 0, 17, self.MainTheme, 1, 1, "white");
            
            if(!IsDefined(self.menuInstructionsUI["string"]))
                self.menuInstructionsUI["string"] = self createText("default", 1.1, 3, "", ((alt && !Is_True(self.DisableInstructionsBackground)) ? "CENTER" : "LEFT"), (alt ? self.instructionsX : (self.instructionsX + 1)), (alt ? self.instructionsY : (self.instructionsY + 7)), 1, (255, 255, 255));
        }

        if(IsDefined(self.menuInstructionsUI["string"]) && Is_True(self.DisableMenuInstructions) || !self hasMenu() || !Is_Alive(self) && !Is_True(self.refreshInstructionsUI) || Is_True(self.InstructionsForceRefresh))
        {
            if(Is_True(self.DisableMenuInstructions) || !self hasMenu() || !Is_Alive(self) && !Is_True(self.refreshInstructionsUI) || Is_True(self.InstructionsForceRefresh))
                self DestroyInstructions();
            
            self.menuInstructionsUI = [];
            
            if(!Is_Alive(self) && !Is_True(self.refreshInstructionsUI))
                self.refreshInstructionsUI = true; //Instructions Need To Be Refreshed To Make Sure They Are Archived Correctly To Be Shown While Dead
            
            if(Is_True(self.InstructionsForceRefresh))
                self.InstructionsForceRefresh = undefined;
        }

        if(Is_Alive(self) && Is_True(self.refreshInstructionsUI))
            self.refreshInstructionsUI = undefined;
        
        if(IsDefined(self.menuInstructionsUI["string"]))
        {
            if(Is_Alive(self))
            {
                if(!IsDefined(self.instructionsString))
                {
                    if(!self isInMenu(true))
                    {
                        str = "";

                        foreach(index, btn in self.OpenControls)
                            str += ((index < (self.OpenControls.size - 1)) ? "[{" + btn + "}] & " : "[{" + btn + "}]");
                        
                        str += ": Open " + GetMenuName();

                        if(!Is_True(self.DisableQM))
                        {
                            str += "\n";
                            
                            foreach(index, btn in self.QuickControls)
                                str += ((index < (self.QuickControls.size - 1)) ? "[{" + btn + "}] & " : "[{" + btn + "}]");

                            str += ": Open Quick Menu";
                        }
                    }
                    else
                    {
                        str = Array("[{+attack}]/[{+speed_throw}]/[{+actionslot 1}]/[{+actionslot 2}]: Scroll", "[{+actionslot 3}]/[{+actionslot 4}]: Slider Left/Right", "[{+activate}]: Select", "[{+melee}]: Go Back/Exit");
                    }
                }
                else
                {
                    str = self.instructionsString;
                }
            }
            else
            {
                str = (self isInMenu(true) ? Array("[{+attack}]/[{+speed_throw}]: Scroll", "[{+actionslot 3}]/[{+actionslot 4}]: Slider Left/Right", "[{+activate}]: Select", "[{+gostand}]: Exit") : "[{+speed_throw}] & [{+gostand}]: Open Quick Menu");
            }

            str = self GetInstructionString(str);
            
            if(self.menuInstructionsUI["string"].text != str)
                self.menuInstructionsUI["string"] SetTextString(str);
            
            self SetInstructionsPosition(str);
        }

        wait 0.01;
    }

    if(Is_True(self.MenuInstructionsDisplay))
        self.MenuInstructionsDisplay = BoolVar(self.MenuInstructionsDisplay);
    
    self DestroyInstructions();
}

function GetInstructionString(str = "")
{
    if(IsArray(str))
    {
        newStr = "";

        if(str.size)
        {
            for(a = 0; a < str.size; a++)
                newStr += ((a < (str.size - 1)) ? (Is_True(self.AlternateInstructions) ? str[a] + "  |  " : str[a] + "\n") : str[a]);
        }

        return newStr;
    }

    if(str == "" || !IsSubStr(str, "\n") || !Is_True(self.AlternateInstructions))
        return str;

    toks = StrTok(str, "\n");
    newStr = "";

    for(a = 0; a < toks.size; a++)
    {
        if(toks[a] == "")
            continue;

        newStr += ((newStr == "") ? toks[a] : "  |  " + toks[a]);
    }

    return newStr;
}

function SetInstructionsPosition(str)
{
    if(!IsDefined(self.menuInstructionsUI) || !IsDefined(self.menuInstructionsUI["string"]))
        return;
    
    alt = Is_True(self.AlternateInstructions);
    
    switch(self.MenuDesign)
    {
        case "Basic":
        case "Classic":
            yOffset = 5;
            xOffset = 0;
            widthOffset = 0;
            break;
        
        case "AIO":
            yOffset = 30;
            xOffset = -1;
            widthOffset = 2;
            break;
        
        case "Native":
            yOffset = 5;
            xOffset = 1;
            widthOffset = -2;
            break;
        
        default:
            yOffset = 18;
            xOffset = 1;
            widthOffset = -2;
            break;
    }

    width = (Is_True(self.AlternateInstructions) ? (self.menuInstructionsUI["string"] GetTextWidth3arc(self) - 28) : self.menuInstructionsUI["string"] GetTextWidth3arc(self));
    height = (IsSubStr(str, "\n") ? (CorrectNL_BGHeight(str) - 5) : CorrectNL_BGHeight(str));

    if(self isInMenu(true) && Is_True(self.AdaptiveMenuInstructions) && !Is_True(self.RepositionMenuInstructions))
    {
        menuWidth = ((IsDefined(self.menuUI) && IsDefined(self.menuUI["background"])) ? (self.menuUI["background"].width + widthOffset) : (self.MenuWidth + widthOffset));

        if(width < menuWidth)
            width = menuWidth;
    }
    
    if(IsDefined(self.menuInstructionsUI["background"]) && (self.menuInstructionsUI["background"].width != width || self.menuInstructionsUI["background"].height != height))
    {
        self.menuInstructionsUI["background"] SetShaderValues(undefined, width, height);
        self.menuInstructionsUI["outline"] SetShaderValues(undefined, (width + 2), (height + 2));
    }

    xPos = ((self isInMenu(true) && Is_True(self.AdaptiveMenuInstructions) && !Is_True(self.RepositionMenuInstructions)) ? ((IsDefined(self.menuUI) && IsDefined(self.menuUI["background"])) ? (self.menuUI["background"].x + xOffset) : (self.menuX + xOffset)) : self.instructionsX);
    yPos = ((self isInMenu(true) && Is_True(self.AdaptiveMenuInstructions) && !Is_True(self.RepositionMenuInstructions) && IsDefined(self.menuUI) && IsDefined(self.menuUI["background"])) ? ((self.menuUI["background"].y + self.menuUI["background"].height) + yOffset) : (self.instructionsY - height));

    if(IsDefined(self.menuInstructionsUI["background"]) && (self.menuInstructionsUI["background"].y != yPos || self.menuInstructionsUI["background"].x != xPos))
    {
        self.menuInstructionsUI["background"].y = yPos;
        self.menuInstructionsUI["outline"].y = (alt ? yPos : (yPos - 1));

        self.menuInstructionsUI["background"].x = xPos;
        self.menuInstructionsUI["outline"].x = (alt ? xPos : (xPos - 1));
    }

    stringYPos = (alt ? yPos : (yPos + 6));
    stringXPos = (alt ? xPos : (xPos + 1));

    if(IsDefined(self.menuInstructionsUI["string"]) && (self.menuInstructionsUI["string"].y != stringYPos || self.menuInstructionsUI["string"].x != stringXPos))
    {
        self.menuInstructionsUI["string"].y = stringYPos;
        self.menuInstructionsUI["string"].x = stringXPos;
    }
}

function DestroyInstructions()
{
    if(!IsDefined(self.menuInstructionsUI))
        return;
    
    if(IsDefined(self.menuInstructionsUI["string"]))
        self.menuInstructionsUI["string"] DestroyHud();

    if(IsDefined(self.menuInstructionsUI["background"]))
        self.menuInstructionsUI["background"] DestroyHud();
    
    if(IsDefined(self.menuInstructionsUI["outline"]))
        self.menuInstructionsUI["outline"] DestroyHud();
    
    self.menuInstructionsUI = undefined;
}

function SetMenuInstructions(text)
{
    self.instructionsString = ((!IsDefined(text) || !IsArray(text) && text == "" || IsArray(text) && !text.size) ? undefined : text);
}

// ============================================================
// Functions/advanced_scripts.gsc
// ============================================================

function PopulateAdvancedScripts(menu)
{
    switch(menu)
    {
        case "Advanced Scripts":
            self addMenu(menu);
                self addOpt("Custom Sentry", &newMenu, "Custom Sentry");
                self addOpt("Artillery Strike", &ArtilleryStrike);
                self addOpt("Flyable UFO", &FlyableUFO);
                self addOptSlider("AC-130", &AC130, Array("Fly", "Walking"));
                self addOptSlider("Controllable Zombie", &ControllableZombie, Array("Friendly", "Enemy"));
                self addOptBool(self.ZombieTeleportGrenades, "Zombie Teleport Grenades", &ZombieTeleportGrenades);

                if(ReturnMapName() != "Moon" && ReturnMapName() != "Origins")
                    self addOptBool(level.MoonDoors, "Moon Doors", &MoonDoors);
                
                self addOptBool(self.BodyGuard, "Body Guard", &BodyGuard);
            break;
        
        case "Custom Sentry":
            if(!IsDefined(self.CustomSentryWeapon))
                self.CustomSentryWeapon = GetWeapon("minigun");

            self addMenu(menu);
                self addOptBool(self.CustomSentry, "Custom Sentry", &CustomSentry);
                self addOpt("");
                self addOptBool((self.CustomSentryWeapon == GetWeapon("minigun")), "Death Machine", &SetCustomSentryWeapon, GetWeapon("minigun"));

                if(!IsVerkoMap())
                {
                    arr = [];
                    weaps = GetArrayKeys(level.zombie_weapons);
                    weaponsVar = Array("assault", "smg", "lmg", "sniper", "cqb", "pistol", "launcher", "special");

                    if(IsDefined(weaps) && weaps.size)
                    {
                        for(a = 0; a < weaps.size; a++)
                        {
                            if(IsInArray(weaponsVar, ToLower(CleanString(zm_utility::GetWeaponClassZM(weaps[a])))) && !weaps[a].isgrenadeweapon && !IsSubStr(weaps[a].name, "knife") && weaps[a].name != "none")
                            {
                                strn = ((MakeLocalizedString(weaps[a].displayname) != "") ? weaps[a].displayname : weaps[a].name);
                                    
                                if(!IsInArray(arr, strn))
                                {
                                    arr[arr.size] = strn;
                                    self addOptBool((self.CustomSentryWeapon == weaps[a]), strn, &SetCustomSentryWeapon, weaps[a]);
                                }
                            }
                        }
                    }
                }
                else
                {
                    for(a = 0; a < level.var_21b77150.size; a++)
                        self addOptBool((self.CustomSentryWeapon == GetWeapon(level.var_7df703ba[a])), level.var_7df703ba[a], &SetCustomSentryWeapon, GetWeapon(level.var_21b77150[a]));
                }
            break;
    }
}

function CustomSentry(origin)
{
    self endon("disconnect");

    self.CustomSentry = BoolVar(self.CustomSentry);

    if(Is_True(self.CustomSentry))
    {
        if(!IsDefined(origin))
            origin = self.origin;

        self.CustomSentryOrigin = origin;
        
        sentrygun = self.CustomSentryWeapon;
        self.sentrygun_weapon = zm_utility::spawn_weapon_model(sentrygun, undefined, origin, (0, self GetPlayerAngles()[1], 0));
        self.sentrygun_weapon.owner = self;

        self.sentrygun_weapon clientfield::set("zm_aat_fire_works", 1);
        self.sentrygun_weapon MoveTo(origin + (0, 0, 56), 0.5);
        self.sentrygun_weapon waittill("movedone");
        
        while(Is_True(self.CustomSentry))
        {
            zombie = self.sentrygun_weapon CustomSentryGetTarget();
            v_target_pos = (!IsDefined(zombie) ? (self.sentrygun_weapon.origin + VectorScale(AnglesToForward((0, RandomIntRange(0, 360), 0)), 40)) : zombie GetTagOrigin("j_head"));

            if(IsDefined(zombie) && !IsDefined(v_target_pos))
                v_target_pos = zombie GetTagOrigin("tag_body");
            
            if(IsDefined(v_target_pos) && IsVec(v_target_pos))
            {
                self.sentrygun_weapon.angles = VectorToAngles(v_target_pos - self.sentrygun_weapon.origin);
                self.sentrygun_weapon DontInterpolate();

                if(IsDefined(zombie))
                    MagicBullet(sentrygun, self.sentrygun_weapon GetTagOrigin("tag_flash"), v_target_pos, self.sentrygun_weapon);
            }

            util::wait_network_frame();
        }
    }
    else
    {
        if(IsDefined(self.sentrygun_weapon))
        {
            self.sentrygun_weapon clientfield::set("zm_aat_fire_works", 0);
            wait 0.01;

            self.sentrygun_weapon Delete();
        }
    }
}

function CustomSentryGetTarget()
{
    zombies = GetAITeamArray(level.zombie_team);

    if(!IsDefined(zombies) || !zombies.size)
        return;

    enemy = undefined;
    
    for(a = 0; a < zombies.size; a++)
    {
        if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || zombies[a] DamageConeTrace(self.origin, self) < 0.1)
            continue;
        
        if(zombies[a].archetype == "zombie" && !Is_True(zombies[a].zombie_think_done) || zombies[a].archetype != "zombie" && Is_True(zombies[a].ignoreme))
            continue;
        
        if(!IsDefined(enemy))
            enemy = zombies[a];
        
        if(enemy == zombies[a])
            continue;
        
        if(Closer(self.origin, zombies[a].origin, enemy.origin))
            enemy = zombies[a];
    }

    return enemy;
}

function SetCustomSentryWeapon(weapon)
{
    if(self.CustomSentryWeapon == weapon)
        return;
    
    self.CustomSentryWeapon = weapon;

    if(Is_True(self.CustomSentry))
    {
        for(a = 0; a < 2; a++)
            self CustomSentry(self.CustomSentryOrigin);
    }
}

function ControllableZombie(team)
{
    if(Is_True(self.ControllableZombie))
        return;
    
    if(self isPlayerLinked())
        return self iPrintlnBold("^1ERROR: ^7Player Is Linked To An Entity");
    
    if(Is_True(self.BodyGuard))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use Controllable Zombie While Body Guard Is Enabled");
    
    self endon("disconnect");
    
    self closeMenu1();
    self.ControllableZombie = true;
    self.DisableMenuControls = true;
    self.ignoreme = true;

    CZSavedOrigin = self.origin;
    CZSavedAngles = self GetPlayerAngles();

    zombie = self ServerSpawnZombie(self.origin);
    self SetStance("stand");
    wait 0.1;
    
    if(IsDefined(zombie))
    {
        self Hide();
        zombie.ignoreme = 1;

        viewModel = SpawnScriptModel((zombie.origin + (0, 0, 18)) + (AnglesToForward(zombie.angles) * -40), "tag_origin", zombie.angles);
        viewModel LinkTo(zombie);
        
        self PlayerLinkToDelta(viewModel, "tag_origin", 0, 85, 85, 35, 35, true, true);
        self FreezeControlsAllowLook(true);
        self DisableWeapons();
        self DisableOffhandWeapons();
        self SetPlayerAngles(zombie.angles);
        
        zombie.ignore_find_flesh = 1;
        zombie.team = ((team == "Friendly") ? self.team : level.zombie_team);
        zombie thread zombie_utility::set_zombie_run_cycle("sprint");

        while(!CanControl(zombie) && IsAlive(zombie))
        {
            if(self MeleeButtonPressed())
                zombie DoDamage(zombie.health + 666, zombie GetTagOrigin("j_head"));
            
            wait 0.1;
        }
        
        goalPos = SpawnScriptModel(GetGroundPos(self TraceBullet()), "tag_origin");
        PlayFXOnTag(level._effect["powerup_on"], goalPos, "tag_origin");
        
        goalPos SetInvisibleToAll();
        goalPos SetVisibleToPlayer(self);
        
        while(IsDefined(zombie) && IsAlive(zombie))
        {
            zombie.ignore_find_flesh = 1;
            zombie.ignoreme = 1;
            goalPos.origin = self TraceBullet();
            
            if(CanControl(zombie))
            {
                if(Distance(zombie.origin, goalPos.origin) >= 100)
                {
                    zombie SetGoal(goalPos.origin, true);

                    if(IsDefined(zombie.zombie_move_speed) && zombie.zombie_move_speed != "sprint")
                        zombie thread zombie_utility::set_zombie_run_cycle("sprint");
                }
                
                if(self AttackButtonPressed())
                    zombie ZombieAttack();
            }
            
            if(self MeleeButtonPressed())
            {
                zombie DoDamage((zombie.health + 666), zombie GetTagOrigin("j_head"));
                wait 0.8;

                break;
            }
            
            wait 0.01;
        }
    }
    else
    {
        self iPrintlnBold("^1ERROR: ^7Couldn't Spawn Zombie");
    }
    
    wait 0.1;

    if(!Is_True(self.Invisibility))
        self Show();
    
    self Unlink();
    self FreezeControlsAllowLook(false);
    self EnableWeapons();
    self EnableOffhandWeapons();

    if(IsDefined(viewModel))
        viewModel Delete();
    
    if(IsDefined(goalPos))
        goalPos Delete();
    
    self SetOrigin(CZSavedOrigin);
    self SetPlayerAngles(CZSavedAngles);

    if(Is_True(self.DisableMenuControls))
        self.DisableMenuControls = BoolVar(self.DisableMenuControls);

    if(Is_True(self.ControllableZombie))
        self.ControllableZombie = BoolVar(self.ControllableZombie);

    if(Is_True(self.ignoreme))
        self.ignoreme = false;
}

function ZombieAttack()
{
    self endon("death");
    
    v_angles = self.angles;

    if(IsDefined(self.attacking_point))
    {
        v_angles = (self.attacking_point.v_center_pillar - self.origin);
        v_angles = VectorToAngles((v_angles[0], v_angles[1], 0));
    }
    
    animation = "ai_zombie_base_ad_attack_v1";
    self AnimScripted("attack_anim", self.origin, v_angles, animation);
    
    wait GetAnimLength(animation);
}

function AC130(type)
{
    if(Is_True(self.AC130))
        return;
    self.AC130 = true;

    self endon("disconnect");

    if(Is_True(self.ThirdPerson))
    {
        self.ThirdPerson = undefined;
        self SetClientThirdPerson(0);
    }

    self closeMenu1();
    self.DisableMenuControls = true;
    
    if(type == "Fly")
    {
        ACSavedOrigin = self.origin;
        ACSavedAngles = self GetPlayerAngles();
        SetAngles = VectorToAngles(ACSavedOrigin - self GetEye());
        
        linker = SpawnScriptModel(ACSavedOrigin, "tag_origin", (0, SetAngles[1], 0));
        c130 = SpawnScriptModel(((linker.origin + (AnglesToRight(linker.angles) * 1800)) + (0, 0, ((self.StartOrigin[2] + 1500) - linker.origin[2]))), "tag_origin");

        if(!IsDefined(linker) || !IsDefined(c130))
        {
            if(IsDefined(linker))
                linker Delete();
            
            if(IsDefined(c130))
                c130 Delete();
            
            self.AC130 = undefined;
            self.DisableMenuControls = undefined;
            return;
        }
        
        c130.angles = VectorToAngles(linker.origin - c130.origin);
        c130 LinkTo(linker);
        linker thread AC130Rotate();

        self SetStance("stand");
        self AllowCrouch(false);
        self SetOrigin(c130.origin);
        self PlayerLinkToDelta(c130, "tag_origin", 0, 50, 50, 15, 15);
        self Hide();
    }

    if(!IsDefined(self.AC130DisableFire))
        self.AC130DisableFire = [];

    ammoType = GetWeapon("minigun");
    ammoTime = 0.01;

    self RefreshAC130HUD(ammoType);
    self DisableWeapons(true);
    self DisableOffhandWeapons();
    self SetClientUIVisibilityFlag("hud_visible", 0);
    
    while(1)
    {
        if(type == "Fly")
        {
            if(self GetStance() != "stand")
                self SetStance("stand");
        }

        if(self AttackButtonPressed())
        {
            if(!Is_True(self.AC130DisableFire[ammoType]))
                self thread FireAC130(ammoType);
        }
        else if(self GamepadUsedLast() && self WeaponSwitchButtonPressed() || !self GamepadUsedLast() && self UseButtonPressed())
        {
            ammoType = AC130NextWeapon(ammoType);
            self RefreshAC130HUD(ammoType);
            
            wait 0.15;
        }

        if(self MeleeButtonPressed())
            break;
        
        if(Is_True(self.AC130DisableFire[ammoType]) && ammoType != GetWeapon("minigun"))
        {
            if(!IsDefined(self.AC130Reloading))
            {
                self.AC130Reloading = self createText("objective", 1.4, 1, "RELOADING...", "CENTER", 320, 340, 1, (1, 1, 1));
                self.AC130Reloading thread AC130FlashingHud();
            }
        }
        else
        {
            if(IsDefined(self.AC130Reloading))
                self.AC130Reloading DestroyHud();
        }

        wait 0.01;
    }
    
    if(IsDefined(self.AC130HUD))
        destroyAll(self.AC130HUD);
    
    if(IsDefined(self.AC130Reloading))
        self.AC130Reloading DestroyHud();
    
    self EnableWeapons();
    self EnableOffhandWeapons();
    self SetClientUIVisibilityFlag("hud_visible", 1);

    if(type == "Fly")
    {
        if(IsDefined(linker))
            linker Delete();
        
        if(IsDefined(c130))
            c130 Delete();

        self AllowCrouch(true);

        if(IsDefined(ACSavedOrigin) && IsVec(ACSavedOrigin))
            self SetOrigin(ACSavedOrigin);
        
        if(IsDefined(ACSavedAngles) && IsVec(ACSavedAngles))
            self SetPlayerAngles(ACSavedAngles);

        if(!Is_True(self.Invisibility))
            self Show();
    }

    self.DisableMenuControls = undefined;
    self.AC130 = undefined;
}

function AC130FlashingHud()
{
    if(!IsDefined(self))
        return;
    
    self endon("death");

    while(IsDefined(self))
    {
        self hudFade(0.2, 0.35);

        if(IsDefined(self))
            self hudFade(1, 0.35);
        
        wait 0.01;
    }
}

function AC130NextWeapon(current)
{
    weapon40MM = (IsVerkoMap() ? GetWeapon("vk_tra_pis_t9_1911_rdw_lvl3") : zm_weapons::get_upgrade_weapon(level.start_weapon));
    return ((current == GetWeapon("minigun")) ? weapon40MM : ((current == weapon40MM) ? GetWeapon("hunter_rocket_turret_player") : GetWeapon("minigun")));
}

function AC130FireRate(ammo)
{
    weapon40MM = (IsVerkoMap() ? GetWeapon("vk_tra_pis_t9_1911_rdw_lvl3") : zm_weapons::get_upgrade_weapon(level.start_weapon));
    return ((ammo == GetWeapon("minigun")) ? 0.01 : ((ammo == weapon40MM) ? 1 : 5));
}

function FireAC130(ammoType)
{
    self endon("disconnect");

    if(!IsDefined(self.AC130DisableFire))
        self.AC130DisableFire = [];
    
    self.AC130DisableFire[ammoType] = true;

    fire_origin = self GetTagOrigin("j_neck") + (AnglesToForward(self GetPlayerAngles()) * 5) + (AnglesToRight(self GetPlayerAngles()) * -5);
    weapon40MM = (IsVerkoMap() ? GetWeapon("vk_tra_pis_t9_1911_rdw_lvl3") : zm_weapons::get_upgrade_weapon(level.start_weapon));

    if(ammoType == GetWeapon("hunter_rocket_turret_player"))
    {
        for(a = 0; a < 6; a++)
            MagicBullet(ammoType, fire_origin, BulletTrace(fire_origin, fire_origin + self GetWeaponForwardDir() * 100, 0, undefined)["position"] + (Cos(a * 60) * 3, Sin(a * 60) * 3, 0), self);
    }
    else
    {
        MagicBullet(((ReturnMapName() == "Origins" && ammoType == weapon40MM) ? GetWeapon("hunter_rocket_turret_player") : ammoType), fire_origin, self TraceBullet(), self);
    }
    
    wait AC130FireRate(ammoType);

    if(Is_True(self.AC130DisableFire[ammoType]))
        self.AC130DisableFire[ammoType] = BoolVar(self.AC130DisableFire[ammoType]);
}

function AC130Rotate()
{
    if(!IsDefined(self))
        return;
    
    while(IsDefined(self))
    {
        self RotateYaw(360, 50);
        wait 49.9;
    }
}

function RefreshAC130HUD(ammo)
{
    if(IsDefined(self.AC130HUD))
        destroyAll(self.AC130HUD);

    self.AC130HUD = [];

    weapon40MM = (IsVerkoMap() ? GetWeapon("vk_tra_pis_t9_1911_rdw_lvl3") : zm_weapons::get_upgrade_weapon(level.start_weapon));
    AC130HudValues = ((ammo == GetWeapon("minigun")) ? Array("320,290,2,80", "360,240,60,2", "280,240,60,2", "140,391,2,50", "165,415,50,2", "500,391,2,50", "475,415,50,2", "500,89,2,50", "475,65,50,2", "140,89,2,50", "165,65,50,2") : ((ammo == weapon40MM) ? Array("320,320,2,120", "320,160,2,120", "320,194,10,1", "320,148,10,1", "320,100,14,1", "320,286,10,1", "320,332,10,1", "320,380,14,1", "405,240,130,2", "235,240,130,2", "357,240,1,10", "395,240,1,10", "432,240,1,10", "470,240,1,14", "283,240,1,10", "245,240,1,10", "208,240,1,10", "170,240,1,14") : Array("320,265,51,2", "320,215,51,2", "345,240,2,51", "295,240,2,52", "320,290,2,51", "320,190,2,51", "370,240,51,2", "270,240,51,2", "545,401,2,30", "530,415,30,2", "95,401,2,30", "110,415,30,2", "95,79,2,30", "110,65,30,2", "545,79,2,30", "530,65,30,2")));
    text = ((ammo == GetWeapon("minigun")) ? "25mm" : ((ammo == weapon40MM) ? "40mm" : "105mm"));

    for(a = 0; a < AC130HudValues.size; a++)
        self.AC130HUD[self.AC130HUD.size] = self createRectangle("CENTER", Int(StrTok(AC130HudValues[a], ",")[0]), Int(StrTok(AC130HudValues[a], ",")[1]), Int(StrTok(AC130HudValues[a], ",")[2]), Int(StrTok(AC130HudValues[a], ",")[3]), (1, 1, 1), 1, 1, "white");
    
    button = (self GamepadUsedLast() ? "[{+weapnext_inventory}]" : "[{+activate}]");
    self.AC130HUD[self.AC130HUD.size] = self createText("objective", 1.2, 1, text + "\n^3" + button + " ^7To Change Weapon", "LEFT", -80, 240, 1, (1, 1, 1));
}

function FlyableUFO()
{
    if(Is_True(self.FlyableUFO))
        return;
    self.FlyableUFO = true;

    self endon("disconnect");

    if(Is_True(self.ThirdPerson))
    {
        self.ThirdPerson = undefined;
        self SetClientThirdPerson(0);
    }

    self closeMenu1();
    self.DisableMenuControls = true;

    savedOrigin = self.origin;
    savedAngles = self GetPlayerAngles();

    base = [];
    base[0] = SpawnScriptModel(savedOrigin + (0, 0, 1500), "test_sphere_silver");

    if(IsDefined(base[0]))
    {
        base[0] SetScale(4);
        playerLinker = SpawnScriptModel(base[0].origin, "tag_origin");
    }

    if(!IsDefined(base[0]) || !IsDefined(playerLinker))
    {
        self.FlyableUFO = undefined;
        self.DisableMenuControls = undefined;
        return self iPrintlnBold("^1ERROR: ^7Unable To Spawn Flyable UFO");
    }

    model = GetSpawnableBaseModel("vending_three_gun");

    for(a = 0; a < 10; a++)
    {
        base[base.size] = SpawnScriptModel(base[0].origin - (0, 0, 8), model, (0, a * 36, 90), 0.01);

        if(IsDefined(base[(base.size - 1)]))
        {
            base[(base.size - 1)] LinkTo(base[0]);
            base[(base.size - 1)] NotSolid();
            base[(base.size - 1)] SetScale(0.5);
        }
    }

    base[0] thread UFOSpin();
    
    self DisableWeapons(true);
    self DisableOffhandWeapons();
    self SetClientUIVisibilityFlag("hud_visible", 0);
    self SetStance("stand");
    self Hide();

    self PlayerLinkTo(playerLinker, "tag_origin");
    hud = self createWaypoint(self TraceBullet());
    self SetMenuInstructions(Array("[{+attack}] - Fire Orb", "[{+speed_throw}] - Move Forward", "[{+frag}] - Move Up", "[{+smoke}] - Move Down", "[{+melee}] - Exit"));
    
    while(1)
    {
        if(!IsDefined(base[0]) || !IsDefined(playerLinker))
            break;
        
        if(self GetStance() != "stand")
            self SetStance("stand");

        self.ignoreme = true;

        if(IsDefined(hud))
        {
            pos = BulletTrace(base[0].origin, base[0].origin + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, base[0])["position"];

            hud.x = pos[0];
            hud.y = pos[1];
            hud.z = pos[2];
        }

        playerLinker.angles = (playerLinker.angles[0], self GetPlayerAngles()[1], playerLinker.angles[2]);

        if(self AttackButtonPressed())
            self thread UFOShoot((base[0].origin + (AnglesToUp(base[0].angles) * -10)), base[0].origin, 350, 0.35, true, base[0]);

        if(self AdsButtonPressed())
            playerLinker.origin = playerLinker.origin + AnglesToForward(playerLinker.angles) * 25;

        if(self FragButtonPressed())
            playerLinker.origin = playerLinker.origin + AnglesToUp(playerLinker.angles) * 25;
        else if(self SecondaryOffhandButtonPressed())
            playerLinker.origin = playerLinker.origin - AnglesToUp(playerLinker.angles) * 25;
        
        if(self MeleeButtonPressed())
            break;
        
        base[0].origin = (self.origin + (AnglesToForward(playerLinker.angles) * 75) + (AnglesToUp(playerLinker.angles) * -25));

        wait 0.01;
    }

    if(!Is_True(self.Invisibility))
        self Show();

    if(IsDefined(base) && base.size)
    {
        for(a = 0; a < base.size; a++)
        {
            if(IsDefined(base[a]))
                base[a] Delete();
        }
    }
    
    if(IsDefined(playerLinker))
        playerLinker Delete();
    
    if(IsDefined(hud))
        hud Destroy();
    
    if(IsDefined(savedOrigin))
        self SetOrigin(savedOrigin);
    
    if(IsDefined(savedAngles))
        self SetPlayerAngles(savedAngles);

    if(!Is_True(self.playerIgnoreMe))
        self.ignoreme = false;
    
    if(Is_True(self.UFOShoot))
        self.UFOShoot = undefined;

    self EnableWeapons();
    self EnableOffhandWeapons();
    self SetClientUIVisibilityFlag("hud_visible", 1);
    self AllowCrouch(true);

    self.FlyableUFO = undefined;
    self.DisableMenuControls = undefined;
    self SetMenuInstructions();
}

function UFOSpin()
{
    if(!IsDefined(self))
        return;
    
    self endon("death");

    while(IsDefined(self))
    {
        self RotateYaw(360, 1);
        wait 1;
    }
}

function UFOShoot(startOrigin, endOrigin, range = 350, moveTime = 0.35, runTrace = false, ignoreEnt)
{
    if(Is_True(self.UFOShoot) || !IsDefined(startOrigin) || !IsVec(startOrigin) || !IsDefined(endOrigin) || !IsVec(endOrigin))
        return;
    
    if(Is_True(runTrace))
    {
        if(!IsDefined(ignoreEnt) || !IsEntity(ignoreEnt))
            ignoreEnt = self;

        trace = BulletTrace(endOrigin, endOrigin + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, ignoreEnt);
        surface = trace["surfacetype"];
        endOrigin = trace["position"];

        if(surface == "none" || surface == "default")
            return;
    }

    self.UFOShoot = true;

    self endon("disconnect");
    
    bullet = SpawnScriptModel(startOrigin, "tag_origin");

    if(IsDefined(bullet))
    {
        bullet clientfield::set("powerup_fx", Int(Pow(2, RandomInt(3))));

        if(IsDefined(level._effect["tesla_bolt"]))
            PlayFXOnTag(level._effect["tesla_bolt"], bullet, "tag_origin");

        time = moveTime;
        bullet MoveTo(endOrigin, time);
        wait (time / 2);

        self.UFOShoot = undefined;
        wait (time / 2);
        
        if(IsDefined(bullet))
            bullet Delete();
        
        Earthquake(0.75, 2, endOrigin, 255);
        RadiusDamage(endOrigin, range, 696969, 696969, self);

        if(IsDefined(level._effect["raps_impact"]))
            PlayFX(level._effect["raps_impact"], endOrigin);
        else if(IsDefined(level._effect["dog_gib"]))
            PlayFX(level._effect["dog_gib"], endOrigin);
    }
    else
    {
        self.UFOShoot = undefined;
    }
}

function MoonDoors()
{
    if(!Is_True(level.MoonDoors) && !IsAllDoorsOpen())
    {
        menu = self getCurrent();
        curs = self getCursor();

        self OpenAllDoors();
    }

    level.MoonDoors = BoolVar(level.MoonDoors);
    
    if(Is_True(level.MoonDoors))
    {
        thread OpenCloseMoonDoors();
    }
    else
    {
        types = Array("zombie_door", "zombie_airlock_buy", "zombie_debris");
        script_strings = Array("rotate", "slide_apart", "move");

        for(a = 0; a < types.size; a++)
        {
            doors = GetEntArray(types[a], "targetname");

            if(!IsDefined(doors))
                continue;

            for(b = 0; b < doors.size; b++)
            {
                if(!IsDefined(doors[b]) || doors[b] IsDoorOpen(types[a]))
                    continue;
                
                for(c = 0; c < doors[b].doors.size; c++)
                {
                    if(IsDefined(doors[b].doors[c]) && isInArray(script_strings, doors[b].doors[c].script_string))
                        doors[b].doors[c] thread SetMoonDoorState(doors[b], true);
                }
            }
        }
    }

    if(IsDefined(menu) && IsDefined(curs))
        self RefreshMenu(menu, curs);
}

function OpenCloseMoonDoors()
{
    types = Array("zombie_door", "zombie_airlock_buy", "zombie_debris");
    script_strings = Array("rotate", "slide_apart", "move");

    while(Is_True(level.MoonDoors))
    {
        for(a = 0; a < types.size; a++)
        {
            doors = GetEntArray(types[a], "targetname");

            if(!IsDefined(doors))
                continue;

            for(b = 0; b < doors.size; b++)
            {
                if(!IsDefined(doors[b]))
                    continue;
                
                if(AnyoneNearDoor(doors[b]) && !doors[b] IsDoorOpen(types[a]))
                {
                    for(c = 0; c < doors[b].doors.size; c++)
                    {
                        if(IsDefined(doors[b].doors[c]) && isInArray(script_strings, doors[b].doors[c].script_string))
                            doors[b].doors[c] thread SetMoonDoorState(doors[b], true);
                    }
                }
                else if(!AnyoneNearDoor(doors[b]) && doors[b] IsDoorOpen(types[a]))
                {
                    for(c = 0; c < doors[b].doors.size; c++)
                    {
                        if(IsDefined(doors[b].doors[c]) && isInArray(script_strings, doors[b].doors[c].script_string))
                            doors[b].doors[c] thread SetMoonDoorState(doors[b], false);
                    }
                }
            }
        }

        wait 0.01;
    }
}

function SetMoonDoorState(door, open)
{
    time = (IsDefined(self.script_transition_time) ? self.script_transition_time : 1);
    scale = (open ? 1 : -1);
    door.has_been_opened = open;
    
    switch(self.script_string)
    {
        case "rotate":
            angles = (open ? self.script_angles : self.savedAngles);

            if(IsDefined(angles))
            {
                self RotateTo(angles, time, 0, 0);
                self thread zm_blockers::door_solid_thread();

                wait time;
            }
            break;
        
        case "slide_apart":
            if(IsDefined(self.script_vector))
            {
                vector = VectorScale(self.script_vector, scale);
                goalOrigin = (open ? (self.origin + vector) : self.savedOrigin);

                if(time >= 0.5)
                    self MoveTo(goalOrigin, time, (time * 0.25), (time * 0.25));
                else
                    self MoveTo(goalOrigin, time);

                self thread zm_blockers::door_solid_thread();
                wait time;
            }
            break;
        
        case "move":
            if(IsDefined(self.script_vector))
            {
                goalOrigin = (open ? (self.origin + VectorScale(self.script_vector, scale)) : self.savedOrigin);
                
                if(IsDefined(goalOrigin))
                {
                    if(time >= 0.5)
                        self MoveTo(goalOrigin, time, (time * 0.25), (time * 0.25));
                    else
                        self MoveTo(goalOrigin, time);

                    self thread zm_blockers::door_solid_thread();
                }

                wait time;
            }
            break;
        
        default:
            break;
    }
}

function AnyoneNearDoor(door)
{
    foreach(ai in GetAITeamArray(level.zombie_team))
    {
        if(IsDefined(ai) && IsAlive(ai) && Distance(ai.origin, door.origin) <= 255)
            return true;
    }

    foreach(player in level.players)
    {
        if(IsDefined(player) && Is_Alive(player) && Distance(player.origin, door.origin) <= 255)
            return true;
    }

    return false;
}

function BodyGuard()
{
    self endon("disconnect");
    
    if(Is_True(self.ControllableZombie) && !Is_True(self.BodyGuard))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use Body Guard While Controllable Zombie Is Enabled");
    
    self.BodyGuard = BoolVar(self.BodyGuard);
    
    if(Is_True(self.BodyGuard))
    {
        self.BodyGuardZombie = self ServerSpawnZombie(self.origin);
        wait 0.1;
        
        if(Is_True(self.BodyGuard) && IsDefined(self.BodyGuardZombie) && IsAlive(self.BodyGuardZombie))
        {
            self.BodyGuardZombie.ignoreme = 1;
            self.BodyGuardZombie.team = self.team;
            self.BodyGuardZombie.no_gib = 1;
            self.BodyGuardZombie.allowdeath = 0;
            self.BodyGuardZombie.allowpain = 0;
            self.BodyGuardZombie.aat_turned = 1;
            self.BodyGuardZombie.n_aat_turned_zombie_kills = 0;
            self.BodyGuardZombie clientfield::set("zm_aat_turned", 1);
            
            while(Is_True(self.BodyGuard))
            {
                target = self.BodyGuardZombie GetBodyGuardTarget(self);

                if(!IsDefined(target))
                    target = self.BodyGuardZombie GetBodyGuardTarget(self.BodyGuardZombie); //Attempt to find a target that is near the body guard, if there isn't one near the player
                
                if(!IsDefined(target))
                {
                    self.BodyGuardZombie ClearForcedGoal();

                    goalPos = (self.origin + VectorScale(AnglesToForward(self GetPlayerAngles()), 100));
                    speed = ((Distance(goalPos, self.BodyGuardZombie.origin) > 200) ? "super_sprint" : "walk");

                    if(IsDefined(self.BodyGuardZombie.zombie_move_speed) && self.BodyGuardZombie.zombie_move_speed != speed)
                        self.BodyGuardZombie thread zombie_utility::set_zombie_run_cycle(speed);

                    self.BodyGuardZombie SetGoal(goalPos, true, 255);
                }
                else
                {
                    if(IsDefined(self.BodyGuardZombie.zombie_move_speed) && self.BodyGuardZombie.zombie_move_speed != "super_sprint")
                        self.BodyGuardZombie thread zombie_utility::set_zombie_run_cycle("super_sprint");

                    self.BodyGuardZombie SetGoal(target.origin, true);
                }
                
                wait 0.01;
            }
        }
    }
    else
    {
        if(IsDefined(self.BodyGuardZombie))
        {
            self.BodyGuardZombie thread clientfield::set("zm_aat_turned", 0);

            self.BodyGuardZombie.no_gib = 0;
            self.BodyGuardZombie.allowdeath = 1;
            self.BodyGuardZombie.allowpain = 1;
            
            self.BodyGuardZombie DoDamage(self.BodyGuardZombie.health + 666, self.BodyGuardZombie GetTagOrigin("j_head"));
        }

        if(IsDefined(self.BodyGuardZombieLinker))
            self.BodyGuardZombieLinker Delete();
    }
}

function GetBodyGuardTarget(player)
{
    zombie = undefined;
    zombies = GetAITeamArray(level.zombie_team);

    for(a = 0; a < zombies.size; a++)
    {
        if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || zombies[a] == self || !zm_behavior::inplayablearea(zombies[a]))
            continue;
        
        if(Distance(player.origin, zombies[a].origin) > 500 || !player DamageConeTrace(zombies[a] GetCentroid()) || IsDefined(zombie) && Distance(player.origin, zombies[a].origin) > Distance(player.origin, zombie.origin))
            continue;
        
        zombie = zombies[a];
    }

    return zombie;
}

function ZombieTeleportGrenades()
{
    self endon("disconnect");
    self endon("EndZombieTeleportGrenades");
    
    self.ZombieTeleportGrenades = BoolVar(self.ZombieTeleportGrenades);

    if(Is_True(self.ZombieTeleportGrenades))
    {
        while(IsDefined(self.ZombieTeleportGrenades))
        {
            self waittill("grenade_fire", grenade);

            while(IsDefined(grenade))
            {
                origin = grenade.origin;
                wait 0.05;
            }

            PlayFX(level._effect["samantha_steal"], origin);
            PlayFX(level._effect["teleport_splash"], origin);
            PlayFX(level._effect["teleport_aoe"], origin);

            zombies = GetAITeamArray(level.zombie_team);

            for(a = 0; a < zombies.size; a++)
            {
                zombies[a] ForceTeleport(origin);
                zombies[a].find_flesh_struct_string = "find_flesh";
                zombies[a].ai_state = "find_flesh";
            }
        }
    }
    else
    {
        self notify("EndZombieTeleportGrenades");
    }
}

function ArtilleryStrike()
{
    if(Is_True(self.ArtilleryStrike))
        return;
    self.ArtilleryStrike = true;
    
    self endon("disconnect");

    self closeMenu1();
    wait 0.25;

    self.DisableMenuControls = true;
    self SetMenuInstructions(Array("[{+attack}] - Confirm Location", "[{+melee}] - Cancel"));
    hud = createWaypoint(self TraceBullet());
    
    while(1)
    {
        trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);
        origin = trace["position"];
        surface = trace["surfacetype"];

        if(IsDefined(hud))
        {
            hud.x = origin[0];
            hud.y = origin[1];
            hud.z = origin[2];
        }

        if(self UseButtonPressed() || self AttackButtonPressed())
        {
            if(surface != "none" && surface != "default")
            {
                targetPos = origin;
                break;
            }
            else
            {
                self iPrintlnBold("^1ERROR: ^7Invalid Surface");
            }
        }
        
        if(self MeleeButtonPressed())
            break;

        wait 0.01;
    }
    
    if(IsDefined(hud))
        hud Destroy();

    if(Is_True(self.DisableMenuControls))
        self.DisableMenuControls = BoolVar(self.DisableMenuControls);

    self SetMenuInstructions();
    
    if(IsDefined(targetPos))
    {
        targetPos = targetPos + (0, 0, 3500);

        for(a = -1; a < 2; a += 2)
        {
            for(b = 0; b < 5; b++)
            {
                MagicBullet(GetWeapon("launcher_standard"), targetPos, targetPos - (0, b * (a * 25), 2500));
                wait 0.25;
            }
        }

        for(a = -1; a < 2; a += 2)
        {
            for(b = 0; b < 5; b++)
            {
                MagicBullet(GetWeapon("launcher_standard"), targetPos, targetPos - (b * (a * 25), 0, 2500));
                wait 0.25;
            }
        }
    }
    
    if(Is_True(self.ArtilleryStrike))
        self.ArtilleryStrike = BoolVar(self.ArtilleryStrike);
}

// ============================================================
// Functions/aimbot.gsc
// ============================================================

function PopulateAimbotMenu(menu, player)
{
    switch(menu)
    {
        case "Aimbot Menu":
            if(!IsDefined(player.AimbotType))
                player.AimbotType = "Snap";
            
            if(!IsDefined(player.AimBoneTag))
                player.AimBoneTag = "j_head";
            
            if(!IsDefined(player.AimbotKey))
                player.AimbotKey = "None";
            
            if(!IsDefined(player.AimbotVisibilityRequirement))
                player.AimbotVisibilityRequirement = "None";
            
            if(!IsDefined(player.AimbotDistance))
                player.AimbotDistance = 100;
            
            if(!IsDefined(player.SmoothSnaps))
                player.SmoothSnaps = 5;
            
            self addMenu(menu);
                self addOptBool(player.Aimbot, "Aimbot", &Aimbot, player);
                self addOptSlider("Type", &AimbotType, Array("Snap", "Smooth Snap", "Silent"), player);
                self addOptSlider("Tag", &AimBoneTag, Array("j_head", "j_neck", "j_spine4", "j_spinelower", "j_mainroot", "pelvis", "tag_body", "j_ankle_le", "j_ankle_ri"), player);
                self addOptSlider("Key", &AimbotKey, Array("None", "Aiming", "Firing"), player);
                self addOptSlider("Requirement", &AimbotVisibilityRequirement, Array("None", "Visible", "Damageable"), player);
                self addOptIncSlider("Smooth Snaps", &SetSmoothSnaps, 5, 5, 15, 1, player);
                self addOptBool(player.PlayableAreaCheck, "In Playable Area", &AimbotOptions, 1, player);
                self addOptBool(player.AutoFire, "Auto-Fire", &AimbotOptions, 2, player);
                self addOptBool(player.MenuOpenCheck, "Menu Open Check", &AimbotOptions, 3, player);
                self addOptBool(player.AimbotDistanceCheck, "Distance", &AimbotOptions, 4, player);

                if(Is_True(player.AimbotDistanceCheck))
                    self addOptIncSlider("Max Distance", &AimbotDistance, 100, 100, 1000, 100, player);
            break;
    }
}

function Aimbot(player)
{
    player endon("disconnect");

    player.Aimbot = BoolVar(player.Aimbot);

    while(Is_True(player.Aimbot))
    {
        enemy = player GetClosestTarget();

        if(Is_True(player.Noclip) || Is_True(player.UFOMode) || Is_True(player.ControllableZombie) || Is_True(player.AC130) || Is_True(player.FlyableUFO) || Is_True(player.MenuOpenCheck) && player isInMenu(true))
            enemy = undefined;

        if(IsDefined(enemy) && Is_True(player.AimbotDistanceCheck) && Distance(player.origin, enemy.origin) > player.AimbotDistance)
            enemy = undefined;
        
        if(IsDefined(enemy) && Is_True(player.PlayableAreaCheck) && enemy.archetype == "zombie" && !zm_behavior::inplayablearea(enemy))
            enemy = undefined;
        
        if(IsDefined(enemy) && player.AimbotVisibilityRequirement != "None")
        {
            if(player.AimbotVisibilityRequirement == "Damageable" && enemy DamageConeTrace(player GetEye(), player) < 0.1)
                enemy = undefined;
            
            if(player.AimbotVisibilityRequirement == "Visible" && !player IsVisible(enemy, player.AimBoneTag))
                enemy = undefined;
        }
        
        if(player.AimbotKey == "Aiming" && !player AdsButtonPressed() || player.AimbotKey == "Firing" && !player isFiring1())
            enemy = undefined;

        if(IsDefined(enemy))
        {
            origin = enemy GetTagOrigin(player.AimBoneTag);

            if(!IsDefined(origin) || !IsVec(origin))
            {
                test = enemy GetTagOrigin("tag_body");

                if(!IsDefined(test) || !IsVec(test))
                    enemy = undefined;
                else
                    origin = test;
            }

            if(IsDefined(enemy) && IsDefined(origin) && IsVec(origin))
            {
                if(player.AimbotType == "Snap")
                {
                    player SetPlayerAngles(VectorToAngles(origin - player GetEye()));

                    if(Is_True(player.AutoFire))
                        player FireGun();
                }
                else if(player.AimbotType == "Smooth Snap")
                {
                    if(!IsDefined(player.smoothTarget) || player.smoothTarget != enemy)
                    {
                        player.smoothTarget = enemy;
                        player.snapsRemaining = player.SmoothSnaps;
                        player.snapAngles = VectorToAngles(origin - player GetEye());
                    }

                    if(player.snapsRemaining)
                    {
                        viewAngles = player GetPlayerAngles();
                        
                        smoothangles = (AngleNormalize180(player.snapAngles[0] - viewAngles[0]), AngleNormalize180(player.snapAngles[1] - viewAngles[1]), 0);
                        smoothangles /= player.snapsRemaining;

                        player SetPlayerAngles((AngleNormalize180(viewAngles[0] + smoothangles[0]), AngleNormalize180(viewAngles[1] + smoothangles[1]), 0));
                        player.snapsRemaining--;
                    }
                    else
                    {
                        player SetPlayerAngles(VectorToAngles(origin - player GetEye())); //After it has finished the smooth snap to the target, it will stay locked on
                    }

                    if(Is_True(player.AutoFire) && player.snapsRemaining <= 1)
                        player FireGun();
                }
                else if(player.AimbotType == "Silent")
                {
                    if(Is_True(player.AutoFire) || player isFiring1())
                        player FireGun(origin + (5, 0, 0), origin, false);
                }
            }
            else
            {
                if(IsDefined(player.smoothTarget))
                {
                    player.smoothTarget = undefined;
                    player.snapsRemaining = undefined;
                    player.snapAngles = undefined;
                }
            }
        }
        else
        {
            if(IsDefined(player.smoothTarget))
            {
                player.smoothTarget = undefined;
                player.snapsRemaining = undefined;
                player.snapAngles = undefined;
            }
        }

        wait 0.01;
    }
}

function SetSmoothSnaps(snaps, player)
{
    player.SmoothSnaps = snaps;
}

function GetClosestTarget()
{
    zombies = GetAITeamArray(level.zombie_team);
    enemy = undefined;

    for(a = 0; a < zombies.size; a++)
    {
        if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]))
            continue;
        
        if(Is_True(self.AimbotDistanceCheck) && Distance(self.origin, zombies[a].origin) > self.AimbotDistance)
            continue;
        
        if(self.AimbotVisibilityRequirement == "Damageable" && zombies[a] DamageConeTrace(self GetEye(), self) < 0.1)
            continue;
        
        if(self.AimbotVisibilityRequirement == "Visible" && !self IsVisible(zombies[a], self.AimBoneTag))
            continue;
        
        if(Is_True(self.PlayableAreaCheck) && zombies[a].archetype == "zombie" && !zm_behavior::inplayablearea(zombies[a]))
            continue;
        
        if(zombies[a].archetype == "zombie" && !Is_True(zombies[a].zombie_think_done) || zombies[a].archetype != "zombie" && Is_True(zombies[a].ignoreme))
            continue;
        
        if(!IsDefined(enemy))
            enemy = zombies[a];
        
        if(enemy == zombies[a])
            continue;

        if(Closer(self.origin, zombies[a].origin, enemy.origin))
            enemy = zombies[a];
    }

    return enemy;
}

function IsVisible(enemy, tag)
{
    if(!IsDefined(enemy) || !IsAlive(enemy))
        return false;
    
    tag = (!IsDefined(tag) ? enemy GetEye() : enemy GetTagOrigin(tag));

    if(!IsDefined(tag) || !IsVec(tag))
    {
        test = enemy GetTagOrigin("tag_body");
        
        if(!IsDefined(test) || !IsVec(test))
            return false;
        
        tag = test;
    }

    return VectorDot(AnglesToForward(self GetTagAngles("tag_weapon_right")), VectorNormalize(tag - self GetEye())) > Cos(40) && BulletTracePassed(self GetEye(), tag, false, self);
}

function isFiring1()
{
    return (self isFiring() && !self IsMeleeing());
}

function FireGun(startPosition, targetPosition, takeAmmo = false)
{
    self endon("disconnect");

    weapon = self GetCurrentWeapon();

    if(!IsDefined(weapon) || weapon == level.weaponnone)
        return;
    
    if(!self GetWeaponAmmoClip(weapon) || self IsReloading() || self isOnLadder() || self IsMantling() || self IsSwitchingWeapons() || self IsMeleeing() || self IsSprinting())
        return;
    
    start = self GetWeaponMuzzlePoint();

    if(!IsDefined(start) || !IsVec(start))
        start = self GetEye();
    
    MagicBullet(weapon, ((IsDefined(startPosition) && IsVec(startPosition)) ? startPosition : start), (IsDefined(targetPosition) ? targetPosition : self TraceBullet()), self);
    
    if(Is_True(takeAmmo))
        self SetWeaponAmmoClip(weapon, (self GetWeaponAmmoClip(weapon) - 1));
    
    self WeaponPlayEjectBrass();
    time = weapon.fireTime;

    if(!IsDefined(time) || time <= 0)
        time = 0.1;

    wait (time / 2);
}

function AimbotType(type, player)
{
    player.AimbotType = type;
}

function AimBoneTag(tag, player)
{
    player.AimBoneTag = tag;
}

function AimbotKey(key, player)
{
    player.AimbotKey = key;
}

function AimbotVisibilityRequirement(requirement, player)
{
    player.AimbotVisibilityRequirement = requirement;
}

function AimbotDistance(distance, player)
{
    player.AimbotDistance = distance;
}

function AimbotOptions(a, player)
{
    switch(a)
    {
        case 1:
            player.PlayableAreaCheck = BoolVar(player.PlayableAreaCheck);
            break;
        
        case 2:
            player.AutoFire = BoolVar(player.AutoFire);
            break;
        
        case 3:
            player.MenuOpenCheck = BoolVar(player.MenuOpenCheck);
            break;
        
        case 4:
            player.AimbotDistanceCheck = BoolVar(player.AimbotDistanceCheck);
            break;
        
        default:
            break;
    }
}

// ============================================================
// Functions/aispawner.gsc
// ============================================================

function AISpawnLocation(location)
{
    self.AISpawnLocation = location;
}

function GetAISpawnLocation()
{
    switch(self.AISpawnLocation)
    {
        case "Crosshairs":
            return self TraceBullet();

        case "Self":
            return self.origin + (0, 0, 10);

        default:
            return;
    }
}

function ServerSpawnAI(amount, spawner)
{
    if(!IsDefined(spawner) || !IsFunctionPtr((spawner)))
        return;

    location = self GetAISpawnLocation();

    for(a = 0; a < amount; a++)
    {
        self thread [[ spawner ]](location);
        wait 0.1;
    }
}


//Zombies
function ServerSpawnZombie(target)
{
    if(!IsDefined(level.zombie_spawners))
        return;

    spawner = (IsDefined(level.fn_custom_zombie_spawner_selection) ? [[ level.fn_custom_zombie_spawner_selection ]]() : (Is_True(level.use_multiple_spawns) ? ((IsDefined(level.spawner_int) && (IsDefined(level.zombie_spawn[level.spawner_int].size) && level.zombie_spawn[level.spawner_int].size)) ? array::random(level.zombie_spawn[level.spawner_int]) : array::random(level.zombie_spawners)) : array::random(level.zombie_spawners)));
    zombie = zombie_utility::spawn_zombie(spawner);

    if(IsDefined(zombie) && IsDefined(target) && IsVec(target))
    {
        zombie endon("death");

        wait 0.1;
        zombie StopAnimScripted(0);

        linker = Spawn("script_origin", zombie.origin);
        linker.origin = zombie.origin;
        linker.angles = zombie.angles;

        zombie LinkTo(linker);
        linker MoveTo(target, 0.01);

        linker waittill("movedone");

        zombie Unlink();
        linker Delete();

        zombie.completed_emerging_into_playable_area = 1;
        zombie.find_flesh_struct_string = "find_flesh";
        zombie.ai_state = "find_flesh";
        zombie notify("zombie_custom_think_done", "find_flesh");
    }

    return zombie;
}



//Hellhounds
function ServerSpawnDog(location)
{
    favorite_enemy = dogs_get_favorite_enemy();
    spawn_loc = (IsDefined(level.dog_spawn_func) ? [[ level.dog_spawn_func ]](level.dog_spawners, favorite_enemy) : dog_spawn_factory_logic(favorite_enemy));
    ai = zombie_utility::spawn_zombie(level.dog_spawners[0]);

    if(IsDefined(ai))
    {
        ai.favoriteenemy = favorite_enemy;
        self thread dog_spawn_fx(ai, spawn_loc, location);
        level flag::set("dog_clips");
    }
}

function dogs_get_favorite_enemy()
{
    dog_targets = GetPlayers();
    least_hunted = dog_targets[0];

    for(i = 0; i < dog_targets.size; i++)
    {
        if(!IsDefined(dog_targets[i].hunted_by))
            dog_targets[i].hunted_by = 0;

        if(!zm_utility::is_player_valid(dog_targets[i]))
            continue;

        if(!zm_utility::is_player_valid(least_hunted))
            least_hunted = dog_targets[i];

        if(dog_targets[i].hunted_by < least_hunted.hunted_by)
            least_hunted = dog_targets[i];
    }

    if(!zm_utility::is_player_valid(least_hunted))
        return undefined;

    least_hunted.hunted_by = (least_hunted.hunted_by + 1);
    return least_hunted;
}

function dog_spawn_fx(ai, ent, location)
{
    ai endon("death");

    target = ((IsDefined(location) && IsVec(location)) ? location : ent.origin);
    ai SetFreeCameraLockOnAllowed(0);
    PlayFX(level._effect["lightning_dog_spawn"], target);
    PlaySoundAtPosition("zmb_hellhound_prespawn", target);
    wait 1.5;

    PlaySoundAtPosition("zmb_hellhound_bolt", target);
    Earthquake(0.5, 0.75, target, 1000);
    PlaySoundAtPosition("zmb_hellhound_spawn", target);

    angles = (IsDefined(ai.favoriteenemy) ? (ai.angles[0], VectorToAngles(ai.favoriteenemy.origin - target)[1], ai.angles[2]) : ent.angles);

    ai ForceTeleport(target, angles);
    ai zombie_setup_attack_properties_dog();
    ai util::stop_magic_bullet_shield();
    wait 0.1;

    ai Show();
    ai SetFreeCameraLockOnAllowed(1);
    ai.ignoreme = 0;
    ai notify("visible");
}

function zombie_setup_attack_properties_dog()
{
    self zm_spawner::zombie_history("zombie_setup_attack_properties()");
    self thread dog_behind_audio();
    self.ignoreall = 0;
    self.meleeattackdist = 64;
    self.disablearrivals = 1;
    self.disableexits = 1;

    if(IsDefined(level.dog_setup_func))
        self [[ level.dog_setup_func ]]();
}

function dog_behind_audio()
{
    self thread stop_dog_sound_on_death();
    self endon("death");
    self util::waittill_any("dog_running", "dog_combat");
    self notify("bhtn_action_notify", "close");
    wait 3;

    while(1)
    {
        foreach(player in GetPlayers())
        {
            if(IsAlive(player) && !IsDefined(player.revivetrigger) && Abs(AngleClamp180(VectorToAngles(self.origin - player.origin)[1] - player.angles[1])) > 90 && Distance2D(self.origin, player.origin) > 100)
            {
                self notify("bhtn_action_notify", "close");
                wait 3;
            }
        }

        wait 0.75;
    }
}

function stop_dog_sound_on_death()
{
    self waittill("death");
    self StopSounds();
}

function dog_spawn_factory_logic(favorite_enemy)
{
    dog_locs = array::randomize(level.zm_loc_types["dog_location"]);

    for(i = 0; i < dog_locs.size; i++)
    {
        if(IsDefined(level.old_dog_spawn) && level.old_dog_spawn == dog_locs[i] || !IsDefined(favorite_enemy))
            continue;

        dist_squared = DistanceSquared(dog_locs[i].origin, favorite_enemy.origin);

        if(dist_squared > 160000 && dist_squared < 1000000)
        {
            level.old_dog_spawn = dog_locs[i];
            return dog_locs[i];
        }
    }

    return dog_locs[0];
}



//Margwa
function ServerSpawnMargwa()
{
    trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);

    origin = trace["position"];
    surface = trace["surfacetype"];

    if(surface == "none" || surface == "default")
        return self iPrintlnBold("^1ERROR: ^7Invalid Surface");

    s_location = ((self.AISpawnLocation == "Crosshairs") ? self TraceBullet() : self.origin);

    if(!IsDefined(level.var_b398aafa) || !IsArray(level.var_b398aafa))
        return;

    level.var_b398aafa[0].script_forcespawn = 1;
    ai = zombie_utility::spawn_zombie(level.var_b398aafa[0], "margwa", s_location);

    if(!IsDefined(ai))
        return;

    ai DisableAimAssist();
    ai.actor_damage_func = ai.overrideactordamage;
    ai.canDamage = 0;
    ai.targetname = "margwa";
    ai.holdFire = 1;
    e_player = zm_utility::get_closest_player(s_location);
    v_dir = e_player.origin - s_location;
    v_dir = VectorNormalize(v_dir);
    v_angles = VectorToAngles(v_dir);
    ai ForceTeleport(s_location, v_angles);
    ai function_551e32b4();

    if(IsDefined(level.var_7cef68dc))
        ai thread function_8d578a58();

    ai.ignore_round_robbin_death = 1;
    ai thread function_3d56f587();
}

function function_551e32b4()
{
    self.isFrozen = 1;
    self Ghost();
    self NotSolid();
    self PathMode("dont move");
}

function function_8d578a58()
{
    if(!IsDefined(self))
        return;

    self waittill("death", attacker, mod, weapon);

    foreach(player in level.players)
        if(IsDefined(player.am_i_valid) && player.am_i_valid && (!(IsDefined(level.var_1f6ca9c8) && level.var_1f6ca9c8)) && (!(IsDefined(self.var_2d5d7413) && self.var_2d5d7413)))
            scoreevents::processScoreEvent("kill_margwa", player, undefined, undefined);

    level notify(#"hash_1a2d33d7");
    [[ level.var_7cef68dc ]]();
}

function function_3d56f587()
{
    util::wait_network_frame();
    self clientfield::increment("margwa_fx_spawn");
    wait 3;

    self function_26c35525();
    self.canDamage = 1;
    self.needSpawn = 1;
}

function function_26c35525()
{
    self.isFrozen = 0;
    self Show();
    self Solid();
    self PathMode("move allowed");
}



//Wasp
function ServerSpawnWasp()
{
    players = GetPlayers();
    favorite_enemy = wasp_get_favorite_enemy();
    spawn_enemy = favorite_enemy;

    if(!IsDefined(spawn_enemy))
        spawn_enemy = players[0];

    if(IsDefined(level.wasp_spawn_func))
        spawn_point = [[ level.wasp_spawn_func ]](spawn_enemy);

    while(!IsDefined(spawn_point))
    {
        if(!IsDefined(spawn_point))
            spawn_point = wasp_spawn_logic(spawn_enemy);

        if(IsDefined(spawn_point))
            break;

        wait 0.05;
    }

    //SOE and Revelations have different wasp spawner variables
    spawner = (IsDefined(level.var_c200ab6) ? level.var_c200ab6[0] : level.wasp_spawners[0]);

    ai = zombie_utility::spawn_zombie(spawner);
    v_spawn_origin = spawn_point.origin;

    if(IsDefined(ai))
    {
        queryresult = PositionQuery_Source_Navigation(v_spawn_origin, 0, 32, 32, 15, "navvolume_small");

        if(queryresult.data.size)
            v_spawn_origin = queryresult.data[RandomInt(queryresult.data.size)].origin;

        ai set_parasite_enemy(favorite_enemy);
        ai.does_not_count_to_round = 1;
        level thread wasp_spawn_init(ai, v_spawn_origin, 1);
    }
}

function wasp_get_favorite_enemy()
{
    if(level.a_wasp_priority_targets.size > 0)
    {
        e_enemy = level.a_wasp_priority_targets[0];

        if(IsDefined(e_enemy))
        {
            ArrayRemoveValue(level.a_wasp_priority_targets, e_enemy);
            return e_enemy;
        }
    }

    if(IsDefined(level.fn_custom_wasp_favourate_enemy))
    {
        e_enemy = [[ level.fn_custom_wasp_favourate_enemy ]]();
        return e_enemy;
    }

    target = get_parasite_enemy();

    return target;
}

function get_parasite_enemy()
{
    parasite_targets = GetPlayers();
    least_hunted = parasite_targets[0];

    for(i = 0; i < parasite_targets.size; i++)
    {
        if(!IsDefined(parasite_targets[i].hunted_by))
            parasite_targets[i].hunted_by = 0;

        if(!wasp_is_target_valid(parasite_targets[i]))
            continue;

        if(!wasp_is_target_valid(least_hunted))
            least_hunted = parasite_targets[i];

        if(parasite_targets[i].hunted_by < least_hunted.hunted_by)
            least_hunted = parasite_targets[i];
    }

    if(!wasp_is_target_valid(least_hunted))
        return undefined;

    return least_hunted;
}

function wasp_is_target_valid(target)
{
    if(!IsDefined(target))
        return 0;

    if(!IsAlive(target))
        return 0;

    if(IsPlayer(target) && target.sessionstate == "spectator")
        return 0;

    if(IsPlayer(target) && target.sessionstate == "intermission")
        return 0;

    if(IsDefined(target.ignoreme) && target.ignoreme)
        return 0;

    if(target IsNoTarget())
        return 0;

    if(IsDefined(self.is_target_valid_cb))
        return self [[ self.is_target_valid_cb ]](target);

    return 1;
}

function wasp_spawn_logic(favorite_enemy)
{
    queryresult = PositionQuery_Source_Navigation(favorite_enemy.origin + (0, 0, RandomIntRange(40, 100)), 300, 1200, 10, 10, "navvolume_small");

    foreach(point in array::randomize(queryresult.data))
    {
        if(BulletTracePassed(point.origin, favorite_enemy.origin, 0, favorite_enemy))
        {
            level.old_wasp_spawn = point;
            return point;
        }
    }

    return array::randomize(queryresult.data)[0];
}

function set_parasite_enemy(enemy)
{
    if(!wasp_is_target_valid(enemy))
        return;

    if(IsDefined(self.parasiteenemy))
    {
        if(!IsDefined(self.parasiteenemy.hunted_by))
            self.parasiteenemy.hunted_by = 0;

        if(self.parasiteenemy.hunted_by > 0)
            self.parasiteenemy.hunted_by--;
    }

    self.parasiteenemy = enemy;

    if(!IsDefined(self.parasiteenemy.hunted_by))
        self.parasiteenemy.hunted_by = 0;

    self.parasiteenemy.hunted_by++;
    self SetLookAtEnt(self.parasiteenemy);
    self SetTurretTargetEnt(self.parasiteenemy);
}

function wasp_spawn_init(ai, origin, should_spawn_fx)
{
    if(!IsDefined(should_spawn_fx))
        should_spawn_fx = 1;

    ai endon("death");

    ai SetInvisibleToAll();
    v_origin = (IsDefined(origin) ? origin : ai.origin);

    if(should_spawn_fx)
        PlayFX(level._effect["lightning_wasp_spawn"], v_origin);

    wait 1.5;
    Earthquake(0.3, 0.5, v_origin, 256);

    angle = (IsDefined(ai.favoriteenemy) ? VectorToAngles(ai.favoriteenemy.origin - v_origin) : ai.angles);
    angles = (ai.angles[0], angle[1], ai.angles[2]);

    ai.origin = v_origin;
    ai.angles = angles;
    ai thread zombie_setup_attack_properties_wasp();

    if(IsDefined(level._wasp_death_cb))
        ai callback::add_callback(#"hash_acb66515", level._wasp_death_cb);

    ai SetVisibleToAll();
    ai.ignoreme = 0;
    ai notify("visible");
}

function zombie_setup_attack_properties_wasp()
{
    self zm_spawner::zombie_history("zombie_setup_attack_properties()");
    self thread wasp_behind_audio();

    self.ignoreall = 0;
    self.meleeattackdist = 64;
    self.disablearrivals = 1;
    self.disableexits = 1;

    if(level.wasp_round_count == 2)
        self ai::set_behavior_attribute("firing_rate", "medium");
    else if(level.wasp_round_count > 2)
        self ai::set_behavior_attribute("firing_rate", "fast");
}

function wasp_behind_audio()
{
    self thread stop_wasp_sound_on_death();
    self endon("death");

    self util::waittill_any("wasp_running", "wasp_combat");
    wait 3;

    while(1)
    {
        foreach(player in GetPlayers())
        {
            if(IsAlive(player) && !IsDefined(player.revivetrigger))
            {
                if(Abs(AngleClamp180(VectorToAngles(self.origin - player.origin)[1] - player.angles[1])) > 90 && Distance2D(self.origin, player.origin) > 100)
                    wait 3;
            }
        }

        wait 0.75;
    }
}

function stop_wasp_sound_on_death()
{
    self waittill("death");
    self StopSounds();
}

function function_7085a2e4(einflictor, eattacker, idamage, idflags, smeansofdeath, weapon, vpoint, vdir, shitloc, vdamageorigin, psoffsettime, damagefromunderneath, modelindex, partname, vsurfacenormal)
{
    if(IsPlayer(eattacker) && (IsDefined(eattacker.var_e8e8daad) && eattacker.var_e8e8daad))
        idamage = Int(idamage * 1.5);

    return idamage;
}


//Civil Protector
function ServerSpawnCivilProtector()
{
    trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);

    origin = trace["position"];
    surface = trace["surfacetype"];

    if(surface == "none" || surface == "default")
        return self iPrintlnBold("^1ERROR: ^7Invalid Surface");

    v_ground_position = ((self.AISpawnLocation == "Crosshairs") ? self TraceBullet() : self.origin);
    var_36e9b69a = v_ground_position + VectorScale((0, 0, 1), 650);
    level thread function_70541dc1(v_ground_position);

    spawner = (level flag::get("ee_complete") ? level.var_c1b7d765[0] : level.zombie_robot_spawners[0]);
    level.ai_robot = spawner SpawnFromSpawner("companion_spawner", 1);
    level.ai_robot.maxhealth = level.ai_robot.health;
    level.ai_robot.allow_zombie_to_target_ai = 0;
    level.ai_robot.on_train = 0;
    level.ai_robot.can_gib_zombies = 1;
    level.ai_robot SetCanDamage(0);
    level.ai_robot.time_expired = 0;
    level.ai_robot PlayLoopSound("fly_civil_protector_loop");

    foreach(player in level.players)
        player SetPerk("specialty_pistoldeath");

    if(IsDefined(level.ai_robot))
    {
        level.ai_robot ForceTeleport(var_36e9b69a);
        level.ai_robot thread function_ab4d9ece(v_ground_position);
        level.ai_robot scene::play("cin_zod_robot_companion_entrance");
        level notify(#"hash_10a36fa2");
        level.ai_robot.companion_anchor_point = v_ground_position;
    }

    level thread function_f9a6039c(level.ai_robot, "active", 2);
    level.ai_robot thread function_be60a9fd();
    level.ai_robot thread function_677061ac();
    function_490cbdf5();
    level.ai_robot.time_expired = 1;

    while(level.ai_robot.reviving_a_player == 1)
        wait 0.05;

    foreach(player in level.players)
        player UnSetPerk("specialty_pistoldeath");

    level.ai_robot SetCanDamage(1);

    if(IsDefined(level.o_zod_train))
    {
        if([[ level.o_zod_train ]]() is_touching_train_volume(level.ai_robot))
            level.ai_robot LinkTo([[ level.o_zod_train ]]() function_8cf8e3a5());
    }

    level.ai_robot scene::play("cin_zod_robot_companion_exit_death");
    level.ai_robot = undefined;
    players = GetPlayers();

    if(players.size != 1 || !level flag::get("solo_game") || (!(IsDefined(players[0].waiting_to_revive) && players[0].waiting_to_revive)))
        level zm::checkforalldead();
}

function function_8cf8e3a5()
{
    return self.var_36e768e4;
}

function is_touching_train_volume(ent)
{
    return ent IsTouching(self.m_e_volume);
}

function function_70541dc1(v_ground_position)
{
    var_b47822ca = Spawn("script_model", v_ground_position);
    var_b47822ca SetModel("tag_origin");

    PlayFXOnTag(level._effect["robot_ground_spawn"], var_b47822ca, "tag_origin");
    level waittill(#"hash_10a36fa2");
    var_b47822ca Delete();
}

function function_ab4d9ece(var_21e230b7)
{
    level.ai_robot thread robot_sky_trail();
    wait 0.5;

    Earthquake(0.55, 1.2, var_21e230b7, 1200);
    PlayFX(level._effect["robot_landing"], var_21e230b7);
    level thread function_fa1df614(var_21e230b7, undefined, 350);

    for(i = 0; i < 5; i++)
    {
        foreach(player in level.players)
            player PlayRumbleOnEntity("damage_heavy");

        wait 0.1;
    }
}

function robot_sky_trail()
{
    var_8d888091 = Spawn("script_model", self.origin);
    var_8d888091 SetModel("tag_origin");

    PlayFXOnTag(level._effect["robot_sky_trail"], var_8d888091, "tag_origin");
    var_8d888091 LinkTo(self);

    level waittill(#"hash_10a36fa2");
    var_8d888091 Delete();
}

function function_fa1df614(v_origin, eattacker, n_radius)
{
    team = (IsDefined(level.zombie_team) ? level.zombie_team : "axis");
    a_ai_zombies = array::get_all_closest(v_origin, GetAITeamArray(team), undefined, undefined, n_radius);

    foreach(ai_zombie in a_ai_zombies)
    {
        ai_zombie DoDamage(ai_zombie.health + 10000, ai_zombie.origin, (IsDefined(eattacker) ? eattacker : undefined));

        v_fling = VectorNormalize(((ai_zombie.origin - v_origin) + VectorScale((0, 0, 1), 15)));
        v_fling = (v_fling[0], v_fling[1], abs(v_fling[2]));
        v_fling = VectorScale(v_fling, (70 * (DistanceSquared(ai_zombie.origin, v_origin) / (n_radius * n_radius))));

        ai_zombie StartRagdoll();
        ai_zombie LaunchRagdoll(v_fling);
    }
}

function function_f9a6039c(entity, suffix, delay)
{
    entity endon("death");
    entity endon("disconnect");

    num_variants = zm_spawner::get_number_variants("vox_crbt_robot_" + suffix);

    if(num_variants <= 0)
        return;

    if(IsDefined(delay))
        wait delay;

    if(IsDefined(entity) && (!(IsDefined(entity.is_speaking) && entity.is_speaking)))
    {
        entity.is_speaking = 1;
        entity PlaySoundWithNotify("vox_crbt_robot_" + suffix + "_" + RandomIntRange(0, num_variants + 1), "sndDone");
        entity waittill("snddone");
        entity.is_speaking = 0;
    }
}

function function_be60a9fd()
{
    self endon("death");
    self endon("disconnect");

    while(1)
    {
        self waittill("killed", who);

        if(RandomIntRange(0, 101) <= 30)
            level thread function_f9a6039c(level.ai_robot, "kills");
    }
}

function function_677061ac()
{
    self endon("death");
    self endon("disconnect");

    while(1)
    {
        wait RandomIntRange(15, 25);
        level thread function_f9a6039c(level.ai_robot, "active");
    }
}

function function_490cbdf5()
{
    level endon(#"hash_223edfde");
    wait 120;
}

function update_readouts_for_remaining_robot_cost()
{
    foreach(e_readout in GetEntArray("robot_readout_model", "targetname"))
        e_readout update_readout_for_remaining_robot_cost();
}

function update_readout_for_remaining_robot_cost()
{
    a_cost = get_placed_array_from_number(level.ai_robot_remaining_cost);

    for(i = 0; i < 4; i++)
    {
        j = 0;

        while(j < 10)
        {
            self HidePart("J_" + i + "_" + j);
            j++;
        }

        self ShowPart("J_" + i + "_" + a_cost[i]);
    }
}

function get_placed_array_from_number(n_number)
{
    a_number = [];

    for(i = 0; i < 4; i++)
    {
        n_place = Pow(10, 3 - i);
        a_number[i] = Floor(n_number / n_place);
        n_number = n_number - a_number[i] * n_place;
    }

    return a_number;
}



//Raps
function ServerSpawnRaps()
{
    if(!IsDefined(level.raps_spawners) || level.raps_spawners.size < 1)
        return;

    favorite_enemy = raps_get_favorite_enemy();

    if(!IsDefined(favorite_enemy))
        return;

    if(IsDefined(level.raps_spawn_func))
        s_spawn_loc = [[ level.raps_spawn_func ]](favorite_enemy);
    else
        s_spawn_loc = raps_calculate_spawn_position(favorite_enemy);

    if(!IsDefined(s_spawn_loc))
        return;

    ai = zombie_utility::spawn_zombie(level.raps_spawners[0]);

    if(IsDefined(ai))
    {
        ai.favoriteenemy = favorite_enemy;
        ai.favoriteenemy.hunted_by++;
        s_spawn_loc thread raps_spawn_fx(ai, s_spawn_loc);
        level.zombie_total--;
    }
}

function raps_get_favorite_enemy()
{
    raps_targets = GetPlayers();
    e_least_hunted = undefined;

    for(i = 0; i < raps_targets.size; i++)
    {
        e_target = raps_targets[i];

        if(!IsDefined(e_target.hunted_by))
            e_target.hunted_by = 0;

        if(!zm_utility::is_player_valid(e_target))
            continue;

        if(IsDefined(level.is_player_accessible_to_raps) && ![[ level.is_player_accessible_to_raps ]](e_target))
            continue;

        if(!IsDefined(e_least_hunted))
        {
            e_least_hunted = e_target;
            continue;
        }

        if(e_target.hunted_by < e_least_hunted.hunted_by)
            e_least_hunted = e_target;
    }

    return e_least_hunted;
}

function raps_calculate_spawn_position(favorite_enemy)
{
    position = favorite_enemy.last_valid_position;

    if(!IsDefined(position))
        position = favorite_enemy.origin;

    switch(level.players.size)
    {
        case 1:
            n_raps_spawn_dist_min = 450;
            n_raps_spawn_dist_max = 900;
            break;

        case 2:
            n_raps_spawn_dist_min = 450;
            n_raps_spawn_dist_max = 850;
            break;

        case 3:
            n_raps_spawn_dist_min = 700;
            n_raps_spawn_dist_max = 1000;
            break;

        case 4:
            n_raps_spawn_dist_min = 800;
            n_raps_spawn_dist_max = 1200;
            break;
    }

    query_result = PositionQuery_Source_Navigation(position, n_raps_spawn_dist_min, n_raps_spawn_dist_max, 200, 32, 16);

    if(query_result.data.size)
    {
        a_s_locs = array::randomize(query_result.data);

        if(IsDefined(a_s_locs))
        {
            foreach(s_loc in a_s_locs)
            {
                if(zm_utility::check_point_in_enabled_zone(s_loc.origin, 1, level.active_zones))
                {
                    s_loc.origin = s_loc.origin + VectorScale((0, 0, 1), 16);
                    return s_loc;
                }
            }
        }
    }

    return undefined;
}

function raps_spawn_fx(ai, ent)
{
    ai endon("death");

    if(!IsDefined(ent))
        ent = self;

    ai vehicle_ai::set_state("scripted");
    trace = BulletTrace(ent.origin, ent.origin + VectorScale((0, 0, -1), 720), 0, ai);
    raps_impact_location = trace["position"];
    angle = VectorToAngles(ai.favoriteenemy.origin - ent.origin);
    angles = (ai.angles[0], angle[1], ai.angles[2]);
    ai.origin = raps_impact_location;
    ai.angles = angles;
    ai Hide();
    pos = raps_impact_location + VectorScale((0, 0, 1), 720);

    if(!BulletTracePassed(ent.origin, pos, 0, ai))
    {
        trace = BulletTrace(ent.origin, pos, 0, ai);
        pos = trace["position"];
    }

    portal_fx_location = Spawn("script_model", pos);
    portal_fx_location SetModel("tag_origin");

    if(!IsDefined(level._effect["raps_portal"]))
        level._effect["raps_portal"] = "zombie/fx_meatball_portal_sky_zod_zmb";

    PlayFXOnTag(level._effect["raps_portal"], portal_fx_location, "tag_origin");
    ground_tell_location = Spawn("script_model", raps_impact_location);
    ground_tell_location SetModel("tag_origin");

    if(!IsDefined(level._effect["raps_ground_spawn"]))
        level._effect["raps_ground_spawn"] = "zombie/fx_meatball_impact_ground_tell_zod_zmb";

    PlayFXOnTag(level._effect["raps_ground_spawn"], ground_tell_location, "tag_origin");
    ground_tell_location PlaySound("zmb_meatball_spawn_tell");
    PlaySoundAtPosition("zmb_meatball_spawn_rise", pos);
    ai thread cleanup_meteor_fx(portal_fx_location, ground_tell_location);
    wait 0.5;

    raps_meteor = Spawn("script_model", pos);
    model = ai.model;
    raps_meteor SetModel(model);
    raps_meteor.angles = angles;
    raps_meteor PlayLoopSound("zmb_meatball_spawn_loop", 0.25);

    if(!IsDefined(level._effect["raps_meteor_fire"]))
        level._effect["raps_meteor_fire"] = "zombie/fx_meatball_trail_sky_zod_zmb";

    PlayFXOnTag(level._effect["raps_meteor_fire"], raps_meteor, "tag_origin");
    fall_dist = Sqrt(DistanceSquared(pos, raps_impact_location));
    fall_time = fall_dist / 720;
    raps_meteor MoveTo(raps_impact_location, fall_time);
    raps_meteor.ai = ai;
    raps_meteor thread cleanup_meteor();
    wait fall_time;

    raps_meteor Delete();

    if(IsDefined(portal_fx_location))
        portal_fx_location Delete();

    if(IsDefined(ground_tell_location))
        ground_tell_location Delete();

    ai vehicle_ai::set_state("combat");
    ai.origin = raps_impact_location;
    ai.angles = angles;
    ai Show();

    if(!IsDefined(level._effect["raps_impact"]))
        level._effect["raps_impact"] = "zombie/fx_meatball_impact_ground_zod_zmb";

    PlayFX(level._effect["raps_impact"], raps_impact_location);
    PlaySoundAtPosition("zmb_meatball_spawn_impact", raps_impact_location);
    Earthquake(0.3, 0.75, raps_impact_location, 512);

    ai zombie_setup_attack_properties_raps();
    ai SetVisibleToAll();
    ai.ignoreme = 0;
    ai notify("visible");
}

function cleanup_meteor_fx(portal_fx, ground_tell)
{
    self waittill("death");

    if(IsDefined(portal_fx))
        portal_fx Delete();

    if(IsDefined(ground_tell))
        ground_tell Delete();
}

function cleanup_meteor()
{
    self endon("death");

    self.ai waittill("death");
    self Delete();
}

function zombie_setup_attack_properties_raps()
{
    self zm_spawner::zombie_history("zombie_setup_attack_properties()");
    self.ignoreall = 0;
    self.meleeattackdist = 64;
    self.disablearrivals = 1;
    self.disableexits = 1;
}



//Mechz
function ServerSpawnMechz(pos)
{
    if(!IsDefined(pos))
    {
        trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);

        origin = trace["position"];
        surface = trace["surfacetype"];

        if(surface == "none" || surface == "default")
            return self iPrintlnBold("^1ERROR: ^7Invalid Surface");

        s_location = ((self.AISpawnLocation == "Crosshairs") ? self TraceBullet() : self.origin);
    }
    else
        s_location = pos;

    flyin = 0;

    if(IsDefined(level.var_7f2a926d))
        [[ level.var_7f2a926d ]]();

    level.mechz_spawners[0].script_forcespawn = 1;
    ai = zombie_utility::spawn_zombie(level.mechz_spawners[0], "mechz", s_location);

    if(IsDefined(ai))
    {
        ai DisableAimAssist();
        ai thread function_ef1ba7e5();
        ai thread function_949a3fdf();

        ai.actor_damage_func = ai.actor_damage_func;
        ai.damage_scoring_function = &function_b03abc02;
        ai.mechz_melee_knockdown_function = &function_55483494;
        ai.health = level.mechz_health;
        ai.faceplate_health = level.mechz_faceplate_health;
        ai.powercap_cover_health = level.mechz_powercap_cover_health;
        ai.powercap_health = level.mechz_powercap_health;
        ai.left_knee_armor_health = level.var_2cbc5b59;
        ai.right_knee_armor_health = level.var_2cbc5b59;
        ai.left_shoulder_armor_health = level.var_2cbc5b59;
        ai.right_shoulder_armor_health = level.var_2cbc5b59;
        ai.heroweapon_kill_power = 10;
        e_player = zm_utility::get_closest_player(s_location);
        v_dir = e_player.origin - s_location;
        v_dir = VectorNormalize(v_dir);
        v_angles = VectorToAngles(v_dir);
        var_89f898ad = zm_utility::flat_angle(v_angles);

        v_ground_position = s_location;
        var_1750e965 = v_ground_position;

        if(IsDefined(level.var_e1e49cc1))
            ai thread [[ level.var_e1e49cc1 ]]();

        ai ForceTeleport(var_1750e965, var_89f898ad);

        if(flyin == 1)
        {
            ai thread function_d07fd448();
            ai thread scene::play("cin_zm_castle_mechz_entrance", ai);
            ai thread function_c441eaba(var_1750e965);
            ai thread function_bbdc1f34(var_1750e965);
        }
        else if(IsDefined(level.var_7d2a391d))
            ai thread [[ level.var_7d2a391d ]]();

        ai.b_flyin_done = 1;
        ai thread function_bb048b27();
        ai.ignore_round_robbin_death = 1;

        return ai;
    }
}

function function_ef1ba7e5()
{
    self waittill("death");

    if(IsPlayer(self.attacker))
    {
        if(!(IsDefined(self.deathpoints_already_given) && self.deathpoints_already_given))
            self.attacker zm_score::player_add_points("death_mechz", 1500);

        if(IsDefined(level.hero_power_update))
            [[ level.hero_power_update ]](self.attacker, self);
    }
}

function function_949a3fdf()
{
    self waittill(#"hash_46c1e51d");

    v_origin = self.origin;
    a_ai = GetAISpeciesArray(level.zombie_team);
    a_ai_kill_zombies = ArraySortClosest(a_ai, v_origin, 18, 0, 200);

    foreach(ai_enemy in a_ai_kill_zombies)
    {
        if(IsDefined(ai_enemy))
        {
            if(ai_enemy.archetype == "mechz")
                ai_enemy DoDamage(level.mechz_health * 0.25, v_origin);
            else
                ai_enemy DoDamage(ai_enemy.health + 100, v_origin);
        }

        wait 0.05;
    }
}

function function_b03abc02(inflictor, attacker, damage, dflags, mod, weapon, point, dir, hitloc, offsettime, boneindex, modelindex)
{
    if(IsDefined(attacker) && IsPlayer(attacker))
    {
        if(!(IsDefined(self.no_damage_points) && self.no_damage_points))
            attacker zm_score::player_add_points((zm_spawner::player_using_hi_score_weapon(attacker) ? "damage" : "damage_light"), mod, hitloc, self.isdog, self.team, weapon);
    }
}

function function_55483494()
{
    a_zombies = GetAIArchetypeArray("zombie");

    foreach(var_a3a3ed4c, zombie in a_zombies)
    {
        if(!IsDefined(zombie) || !IsAlive(zombie))
            continue;

        if(zombie function_10d36217(self) && DistanceSquared(self.origin, zombie.origin) <= 12544)
            self function_3efae612(zombie);
    }
}

function function_10d36217(mechz)
{
    facing_vec = AnglesToForward(mechz.angles);
    enemy_vec = (self.origin - mechz.origin);
    enemy_dot = VectorDot(VectorNormalize((facing_vec[0], facing_vec[1], 0)), VectorNormalize((enemy_vec[0], enemy_vec[1], 0)));

    if(enemy_dot < 0.7)
        return 0;

    if(Abs(AngleClamp180(VectorToAngles(enemy_vec)[0])) > 45)
        return 0;

    return 1;
}

function function_3efae612(zombie)
{
    zombie.knockdown = 1;
    zombie.knockdown_type = "knockdown_shoved";
    zombie_to_mechz = self.origin - zombie.origin;
    zombie_to_mechz_2d = VectorNormalize((zombie_to_mechz[0], zombie_to_mechz[1], 0));
    zombie_forward = AnglestoForward(zombie.angles);
    zombie_forward_2d = VectorNormalize((zombie_forward[0], zombie_forward[1], 0));
    zombie_right = AnglestoRight(zombie.angles);
    zombie_right_2d = VectorNormalize((zombie_right[0], zombie_right[1], 0));
    dot = VectorDot(zombie_to_mechz_2d, zombie_forward_2d);

    if(dot >= 0.5)
    {
        zombie.knockdown_direction = "front";
        zombie.getup_direction = "getup_back";
    }
    else if(dot < 0.5 && dot > -0.5)
    {
        dot = VectorDot(zombie_to_mechz_2d, zombie_right_2d);

        if(dot > 0)
        {
            zombie.knockdown_direction = "right";
            zombie.getup_direction = (math::cointoss() ? "getup_back" : "getup_belly");
        }
        else
        {
            zombie.knockdown_direction = "left";
            zombie.getup_direction = "getup_belly";
        }
    }
    else
    {
        zombie.knockdown_direction = "back";
        zombie.getup_direction = "getup_belly";
    }
}

function function_d07fd448()
{
    self endon("death");

    self.b_flyin_done = 0;
    self.bgbignorefearinheadlights = 1;
    self util::waittill_any("mechz_flyin_done", "scene_done");
    self.b_flyin_done = 1;
    self.bgbignorefearinheadlights = 0;
}

function function_c441eaba(var_678a2319)
{
    self endon("death");

    self waittill(#"hash_f93797a6");

    foreach(e_zombie in GetAIArchetypeArray("zombie"))
    {
        if(DistanceSquared(e_zombie.origin, var_678a2319) <= 2304)
            e_zombie Kill();
    }

    foreach(player in GetPlayers())
    {
        dist_sq = DistanceSquared(player.origin, var_678a2319);

        if(dist_sq <= 2304)
            player DoDamage(100, var_678a2319, self, self);

        scale = 2250000 - dist_sq / 2250000;

        if(scale <= 0 || scale >= 1)
            return;

        earthquake_scale = scale * 0.15;
        Earthquake(earthquake_scale, 0.1, var_678a2319, 1500);

        if(scale >= 0.66)
        {
            player PlayRumbleOnEntity("shotgun_fire");
            continue;
        }

        if(scale >= 0.33)
        {
            player PlayRumbleOnEntity("damage_heavy");
            continue;
        }

        player PlayRumbleOnEntity("reload_small");
    }

    if(IsDefined(self.var_1411e129))
        self.var_1411e129 Delete();
}

function function_bbdc1f34(var_678a2319)
{
    self endon("death");
    self endon(#"hash_f93797a6");

    self waittill(#"hash_3d18ed4f");
    distance = 9216;

    while(1)
    {
        foreach(player in GetPlayers())
        {
            if(DistanceSquared(player.origin, var_678a2319) <= distance)
            {
                if(!(IsDefined(player.is_burning) && player.is_burning) && zombie_utility::is_player_valid(player, 0))
                    player function_3389e2f3(self);
            }
        }

        foreach(e_zombie in function_d41418b8())
        {
            if(DistanceSquared(e_zombie.origin, var_678a2319) <= distance && self.var_e05d0be2 != 1)
            {
                self function_3efae612(e_zombie);
                e_zombie function_f4defbc2();
            }
        }

        wait 0.1;
    }
}

function function_3389e2f3(mechz)
{
    if(!(IsDefined(self.is_burning) && self.is_burning) && zombie_utility::is_player_valid(self, 1))
    {
        self.is_burning = 1;
        self burnplayer::setplayerburning(1.5, 0.5, (!self HasPerk("specialty_armorvest") ? 30 : 20), mechz, undefined);

        wait 1.5;
        self.is_burning = 0;
    }
}

function function_d41418b8()
{
    a_zombies = GetAIArchetypeArray("zombie");
    a_filtered_zombies = array::filter(a_zombies, 0, &function_b804eb62);

    return a_filtered_zombies;
}

function function_b804eb62(ai_zombie)
{
    return ai_zombie.is_elemental_zombie != 1;
}

function function_361f6caa(ai_zombie, type)
{
    return ai_zombie.var_9a02a614 == type;
}

function function_f4defbc2()
{
    if(!IsDefined(self))
        return;
    
    ai_zombie = self;
    var_ac4641b = function_4aeed0a5("napalm");

    if(!IsDefined(level.var_bd64e31e) || var_ac4641b < level.var_bd64e31e)
    {
        if(!IsDefined(ai_zombie.is_elemental_zombie) || ai_zombie.is_elemental_zombie == 0)
        {
            ai_zombie.is_elemental_zombie = 1;
            ai_zombie.var_9a02a614 = "napalm";
            ai_zombie clientfield::set("arch_actor_fire_fx", 1);
            ai_zombie clientfield::set("napalm_sfx", 1);
            ai_zombie.health = Int(ai_zombie.health * 0.75);
            ai_zombie thread napalm_zombie_death();
            ai_zombie thread function_d070bfba();
            ai_zombie zombie_utility::set_zombie_run_cycle("sprint");
        }
    }
}

function function_4aeed0a5(type)
{
    a_zombies = function_c50e890f(type);
    return a_zombies.size;
}

function function_c50e890f(type)
{
    a_zombies = GetAIArchetypeArray("zombie");
    a_filtered_zombies = array::filter(a_zombies, 0, &function_361f6caa, type);

    return a_filtered_zombies;
}

function napalm_zombie_death()
{
    ai_zombie = self;
    ai_zombie waittill("death", attacker);

    if(!IsDefined(ai_zombie) || ai_zombie.nuked == 1)
        return;

    ai_zombie clientfield::set("napalm_zombie_death_fx", 1);
    ai_zombie zombie_utility::gib_random_parts();
    gibserverutils::annihilate(ai_zombie);

    if(IsDefined(level.var_36b5dab) && level.var_36b5dab || (IsDefined(ai_zombie.var_36b5dab) && ai_zombie.var_36b5dab))
        ai_zombie.custom_player_shellshock = &function_e6cd7e78;

    RadiusDamage(ai_zombie.origin + VectorScale((0, 0, 1), 35), 128, 70, 30, self, "MOD_EXPLOSIVE");
}

function function_e6cd7e78(damage, attacker, direction_vec, point, mod)
{
    if(GetDvarString("blurpain") == "on")
        self Shellshock("pain_zm", 0.5);
}

function function_d070bfba()
{
    self endon("entityshutdown");
    self endon("death");

    while(1)
    {
        self waittill("damage");

        if(RandomInt(100) < 50)
            self clientfield::increment("napalm_damaged_fx");

        wait 0.05;
    }
}

function function_bb048b27()
{
    self endon("death");

    while(1)
    {
        wait RandomIntRange(9, 14);
        self PlaySound("zmb_ai_mechz_vox_ambient");
    }
}








//Sentinel Drone
function ServerSpawnSentinelDrone()
{
    trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);

    origin = trace["position"];
    surface = trace["surfacetype"];

    if(surface == "none" || surface == "default")
        return self iPrintlnBold("^1ERROR: ^7Invalid Surface");

    s_location = ((self.AISpawnLocation == "Crosshairs") ? self TraceBullet() : self.origin);
    s_location += (0, 0, 25);
    ai = function_fded8158(level.var_fda4b3f3[0]);

    if(IsDefined(ai))
    {
        ai.nuke_damage_func = &function_306f9403;
        ai.instakill_func = &function_306f9403;
        ai.s_spawn_loc = s_location;
        ai thread function_b27530eb(s_location);

        level.zombie_total--;
    }
}

function function_f9c9e7e0()
{
    a_s_spawn_locs = [];
    s_spawn_loc = undefined;

    foreach(var_12e32073, s_zone in level.zones)
    {
        if(s_zone.is_enabled && IsDefined(s_zone.a_loc_types["sentinel_location"]) && s_zone.a_loc_types["sentinel_location"].size)
        {
            foreach(var_ef5f441b, s_loc in s_zone.a_loc_types["sentinel_location"])
            {
                foreach(var_6b780c35, player in level.activeplayers)
                {
                    n_dist_sq = DistanceSquared(player.origin, s_loc.origin);

                    if(n_dist_sq > 65536 && n_dist_sq < 2250000)
                    {
                        if(!IsDefined(a_s_spawn_locs))
                            a_s_spawn_locs = [];
                        else if(!IsArray(a_s_spawn_locs))
                            a_s_spawn_locs = Array(a_s_spawn_locs);

                        a_s_spawn_locs[a_s_spawn_locs.size] = s_loc;
                        break;
                    }
                }
            }
        }
    }

    s_spawn_loc = array::random(a_s_spawn_locs);

    if(!IsDefined(s_spawn_loc))
        s_spawn_loc = array::random(level.zm_loc_types["sentinel_location"]);

    return s_spawn_loc;
}

function function_fded8158(spawner, s_spot)
{
    var_663b2442 = zombie_utility::spawn_zombie(level.var_fda4b3f3[0], "sentinel", s_spot);

    if(IsDefined(var_663b2442))
        var_663b2442.check_point_in_enabled_zone = &zm_utility::check_point_in_playable_area;

    return var_663b2442;
}

function function_306f9403(player, mod, hit_location)
{
    return 1;
}

function function_b27530eb(v_pos)
{
    self endon("death");

    self sentinel_intro();
    var_92968756 = v_pos + VectorScale((0, 0, 1), 30);
    self.origin = v_pos + VectorScale((0, 0, 1), 5000);
    self.angles = (0, RandomIntRange(0, 360), 0);
    e_origin = Spawn("script_origin", self.origin);
    e_origin.angles = self.angles;
    self LinkTo(e_origin);
    e_origin MoveTo(var_92968756, 0.01);
    e_origin PlaySound("zmb_sentinel_intro_spawn");
    e_origin util::delay(0.01, undefined, &function_e6bf0279);
    self clientfield::set("sentinel_spawn_fx", 1);
    wait 0.05;

    self clientfield::set("sentinel_spawn_fx", 0);
    wait 0.05;

    self.origin = var_92968756;
    self Unlink();
    e_origin Delete();
    self flag::set("completed_spawning");

    wait 0.05;
    self sentinel_introcompleted();
}

function toggle_sounds(on)
{
    self clientfield::set("toggle_sounds", !on);
}

function function_e6bf0279()
{
    self PlaySound("zmb_sentinel_intro_land");
}

function sentinel_intro()
{
    sentinel_navigationstandstill();
    self.playing_intro_anim = 1;
    self ASMRequestSubstate("intro@default");
}

function sentinel_navigationstandstill()
{
    self endon("change_state");
    self endon("death");
    self notify("abort_navigation");
    self notify("near_goal");

    wait 0.05;

    if(GetDvarInt("sentinel_NavigationStandStill_new", 0) > 0)
    {
        self ClearVehGoalPos();
        self SetVehVelocity((0, 0, 0));
        self.vehaircraftcollisionenabled = 1;
        return;
    }

    if(GetDvarInt("sentinel_ClearVehGoalPos", 1) == 1)
        self ClearVehGoalPos();

    if(GetDvarInt("sentinel_PathVariableOffsetClear", 1) == 1)
        self PathVariableOffsetClear();

    if(GetDvarInt("sentinel_PathFixedOffsetClear", 1) == 1)
        self PathFixedOffsetClear();

    if(GetDvarInt("sentinel_ClearSpeed", 1) == 1)
    {
        self SetSpeed(0);
        self SetVehVelocity((0, 0, 0));
        self SetPhysAcceleration((0, 0, 0));
        self SetAngularVelocity((0, 0, 0));
    }

    self.vehaircraftcollisionenabled = 1;
}

function sentinel_introcompleted()
{
    self.playing_intro_anim = 0;

    if(!self is_instate("scripted"))
        self thread sentinel_navigatetheworld();
}

function is_instate(statename)
{
    if(IsDefined(self.current_role) && IsDefined(self.state_machines[self.current_role].current_state))
        return self.state_machines[self.current_role].current_state.name == statename;

    return 0;
}

function sentinel_navigatetheworld()
{
    self endon("change_state");
    self endon("death");
    self endon("abort_navigation");
    self notify("sentinel_navigatetheworld");
    self endon("sentinel_navigatetheworld");

    lasttimechangeposition = 0;
    self.shouldgotonewposition = 0;
    self.last_failsafe_count = 0;
    sentinel_move_speed = GetDvarInt("Sentinel_Move_Speed", 25);
    sentinel_evade_speed = GetDvarInt("Sentinel_Evade_Speed", 40);
    self SetSpeed(sentinel_move_speed);
    self ASMRequestSubstate("locomotion@movement");
    self.current_pathto_pos = undefined;
    self.next_near_player_check = 0;
    b_use_path_finding = 1;

    while(1)
    {
        current_pathto_pos = undefined;
        b_in_tactical_position = 0;

        if(IsDefined(self.playing_intro_anim) && self.playing_intro_anim)
        {
            wait 0.1;
        }
        else if(self.goalforced)
        {
            returndata = [];
            returndata["origin"] = self GetClosestPointOnNavVolume(self.goalpos, 100);
            returndata["centerOnNav"] = IsPointInNavVolume(self.origin, "navvolume_small");
            current_pathto_pos = returndata["origin"];
        }
        else if(IsDefined(self.forced_pos))
        {
            returndata = [];
            returndata["origin"] = self GetClosestPointOnNavVolume(self.forced_pos, 100);
            returndata["centerOnNav"] = IsPointInNavVolume(self.origin, "navvolume_small");
            current_pathto_pos = returndata["origin"];
        }
        else if(sentinel_shouldchangesentinelposition())
        {
            if(IsDefined(self.evading_player) && self.evading_player)
            {
                self.evading_player = 0;
                self SetSpeed(sentinel_evade_speed);
            }
            else
                self SetSpeed(sentinel_move_speed);

            returndata = sentinel_getnextmovepositiontactical(self.should_buff_zombies);
            current_pathto_pos = returndata["origin"];
            self.lastjuketime = GetTime();
            self.nextjuketime = GetTime() + 1000 + RandomInt(4000);
            b_in_tactical_position = 1;
        }
        else if(GetTime() > self.next_near_player_check && sentinel_isnearanotherplayer(self.origin, 100))
        {
            self.evading_player = 1;
            self.next_near_player_check = GetTime() + 1000;
            self.nextjuketime = 0;
            self notify("near_goal");
        }

        is_on_nav_volume = IsPointInNavVolume(self.origin, "navvolume_small");

        if(IsDefined(current_pathto_pos))
        {
            if(IsDefined(self.stucktime) && (IsDefined(is_on_nav_volume) && is_on_nav_volume))
                self.stucktime = undefined;

            if(self SetVehGoalPos(current_pathto_pos, 1, b_use_path_finding))
            {
                b_use_path_finding = 1;
                self.b_in_tactical_position = b_in_tactical_position;
                self thread sentinel_pathupdateinterrupt();
                self waittill_pathing_done(5);
                current_pathto_pos = undefined;
            }
            else if(IsDefined(is_on_nav_volume) && is_on_nav_volume)
            {
                self sentinel_killmyself();
                self.last_failsafe_time = undefined;
            }
        }

        if(!(IsDefined(is_on_nav_volume) && is_on_nav_volume))
        {
            if(!IsDefined(self.last_failsafe_time))
                self.last_failsafe_time = GetTime();

            if(GetTime() - self.last_failsafe_time >= 3000)
                self.last_failsafe_count = 0;
            else
                self.last_failsafe_count++;

            self.last_failsafe_time = GetTime();

            if(self.last_failsafe_count > 25)
            {
                new_sentinel_pos = self GetClosestPointOnNavVolume(self.origin, 120);

                if(IsDefined(new_sentinel_pos))
                {
                    dvar_sentinel_getback_to_volume_epsilon = GetDvarInt("dvar_sentinel_getback_to_volume_epsilon", 5);

                    if(Distance(self.origin, new_sentinel_pos) < dvar_sentinel_getback_to_volume_epsilon)
                        self.origin = new_sentinel_pos;
                    else
                    {
                        self.vehaircraftcollisionenabled = 0;

                        if(self SetVehGoalPos(new_sentinel_pos, 1, 0))
                        {
                            self thread sentinel_pathupdateinterrupt();
                            self waittill_pathing_done(5);
                            current_pathto_pos = undefined;
                        }

                        self.vehaircraftcollisionenabled = 1;
                    }
                }
                else if(self.last_failsafe_count > 100)
                    self sentinel_killmyself();
            }
        }

        if(!(IsDefined(is_on_nav_volume) && is_on_nav_volume))
        {
            if(!IsDefined(self.stucktime))
                self.stucktime = GetTime();

            if(GetTime() - self.stucktime > 15000)
                self sentinel_killmyself();
        }

        wait 0.1;
    }
}

function sentinel_shouldchangesentinelposition()
{
    if(GetTime() > self.nextjuketime || IsDefined(self.sentinel_droneenemy) && IsDefined(self.lastjuketime) && GetTime() - self.lastjuketime > 3000 && self GetSpeed() < 1 && !sentinel_isinsideengagementdistance(self.origin, self.sentinel_droneenemy.origin + VectorScale((0, 0, 1), 48), 1))
        return 1;

    return 0;
}

function sentinel_isinsideengagementdistance(origin, position, b_accept_negative_height)
{
    if(!(Distance2DSquared(position, origin) > sentinel_getengagementdistmin() * sentinel_getengagementdistmin() && Distance2DSquared(position, origin) < sentinel_getengagementdistmax() * sentinel_getengagementdistmax()))
        return 0;

    if(IsDefined(b_accept_negative_height) && b_accept_negative_height)
        return Abs(origin[2] - position[2]) >= sentinel_getengagementheightmin() && Abs(origin[2] - position[2]) <= sentinel_getengagementheightmax();

    return position[2] - origin[2] >= sentinel_getengagementheightmin() && position[2] - origin[2] <= sentinel_getengagementheightmax();
}

function sentinel_getengagementdistmin()
{
    if(sentinel_isenemyinnarrowplace())
        return self.settings.engagementdistmin * 0.2;

    if(IsDefined(self.in_compact_mode) && self.in_compact_mode)
        return self.settings.engagementdistmin * 0.5;

    return self.settings.engagementdistmin;
}

function sentinel_getengagementdistmax()
{
    if(sentinel_isenemyinnarrowplace())
        return self.settings.engagementdistmax * 0.3;

    if(IsDefined(self.in_compact_mode) && self.in_compact_mode)
        return self.settings.engagementdistmax * 0.85;

    return self.settings.engagementdistmax;
}

function sentinel_getengagementheightmin()
{
    if(!IsDefined(self.sentinel_droneenemy))
        return self.settings.engagementheightmin * 3;

    return self.settings.engagementheightmin;
}

function sentinel_getengagementheightmax()
{
    if(IsDefined(self.in_compact_mode) && self.in_compact_mode)
        return self.settings.engagementheightmax * 0.8;

    return self.settings.engagementheightmax;
}

function sentinel_isenemyinnarrowplace()
{
    if(!IsDefined(self.sentinel_droneenemy))
        return 0;

    if(!IsDefined(self.v_narrow_volume))
        self.v_narrow_volume = GetEnt("sentinel_narrow_nav", "targetname");

    if(IsDefined(self.v_narrow_volume) && IsDefined(self.sentinel_droneenemy))
    {
        if(self.sentinel_droneenemy IsTouching(self.v_narrow_volume))
            return 1;
    }

    return 0;
}

function sentinel_getnextmovepositiontactical(b_do_not_chase_enemy)
{
    self endon("change_state");
    self endon("death");

    selfdisttotarget = (IsDefined(self.sentinel_droneenemy) ? Distance2D(self.origin, self.sentinel_droneenemy.origin) : 0);
    gooddist = 0.5 * sentinel_getengagementdistmin() + sentinel_getengagementdistmax();
    closedist = 1.2 * gooddist;
    fardist = 3 * gooddist;
    querymultiplier = MapFloat(closedist, fardist, 1, 3, selfdisttotarget);
    preferedheightrange = 0.5 * sentinel_getengagementheightmax() + sentinel_getengagementheightmin();
    randomness = 20;
    sentinel_drone_too_close_to_self_dist_ex = GetDvarInt("SENTINEL_DRONE_TOO_CLOSE_TO_SELF_DIST_EX", 70);
    sentinel_drone_move_dist_max_ex = GetDvarInt("SENTINEL_DRONE_MOVE_DIST_MAX_EX", 600);
    sentinel_drone_move_spacing = GetDvarInt("SENTINEL_DRONE_MOVE_SPACING", 25);
    sentinel_drone_radius_ex = GetDvarInt("SENTINEL_DRONE_RADIUS_EX", 35);
    sentinel_drone_hight_ex = GetDvarInt("SENTINEL_DRONE_HIGHT_EX", Int(preferedheightrange));
    spacing_multiplier = 1.5;
    query_min_dist = self.settings.engagementdistmin;
    query_max_dist = sentinel_drone_move_dist_max_ex;

    if(!(IsDefined(b_do_not_chase_enemy) && b_do_not_chase_enemy) && IsDefined(self.sentinel_droneenemy) && GetTime() > self.targetplayertime)
    {
        charge_at_position = self.sentinel_droneenemy.origin + VectorScale((0, 0, 1), 48);

        if(!IsPointInNavVolume(charge_at_position, "navvolume_small"))
        {
            closest_point_on_nav_volume = GetDvarInt("closest_point_on_nav_volume", 120);
            charge_at_position = self GetClosestPointOnNavVolume(charge_at_position, closest_point_on_nav_volume);
        }

        if(!IsDefined(charge_at_position))
            queryresult = PositionQuery_Source_Navigation(self.origin, sentinel_drone_too_close_to_self_dist_ex, sentinel_drone_move_dist_max_ex * querymultiplier, sentinel_drone_hight_ex * querymultiplier, sentinel_drone_move_spacing, "navvolume_small", sentinel_drone_move_spacing * spacing_multiplier);
        else if(sentinel_isenemyinnarrowplace())
        {
            spacing_multiplier = 1;
            sentinel_drone_move_spacing = 15;
            query_min_dist = self.settings.engagementdistmin * GetDvarFloat("sentinel_query_min_dist", 0.2);
            query_max_dist = query_max_dist * 0.5;
        }
        else if(IsDefined(self.in_compact_mode) && self.in_compact_mode || sentinel_isenemyindoors())
        {
            spacing_multiplier = 1;
            sentinel_drone_move_spacing = 15;
            query_min_dist = self.settings.engagementdistmin * GetDvarFloat("sentinel_query_min_dist", 0.5);
        }

        queryresult = PositionQuery_Source_Navigation(charge_at_position, query_min_dist, query_max_dist * querymultiplier, sentinel_drone_hight_ex * querymultiplier, sentinel_drone_move_spacing, "navvolume_small", sentinel_drone_move_spacing * spacing_multiplier);
    }
    else
        queryresult = PositionQuery_Source_Navigation(self.origin, sentinel_drone_too_close_to_self_dist_ex, sentinel_drone_move_dist_max_ex * querymultiplier, sentinel_drone_hight_ex * querymultiplier, sentinel_drone_move_spacing, "navvolume_small", sentinel_drone_move_spacing * spacing_multiplier);

    PositionQuery_Filter_DistanceToGoal(queryresult, self);
    PositionQuery_Filter_OutOfGoalAnchor(queryresult);

    if(IsDefined(self.sentinel_droneenemy))
    {
        if(RandomInt(100) > 15)
            self PositionQuery_Filter_EngagementDist(queryresult, self.sentinel_droneenemy, sentinel_getengagementdistmin(), sentinel_getengagementdistmax());

        goalheight = self.sentinel_droneenemy.origin[2] + 0.5 * sentinel_getengagementheightmin() + sentinel_getengagementheightmax();
        enemy_origin = self.sentinel_droneenemy.origin + VectorScale((0, 0, 1), 48);
    }
    else
    {
        goalheight = self.origin[2] + 0.5 * sentinel_getengagementheightmin() + sentinel_getengagementheightmax();
        enemy_origin = self.origin;
    }

    best_point = undefined;
    best_score = undefined;
    trace_count = 0;

    foreach(var_5855669, point in queryresult.data)
    {
        if(sentinel_isinsideengagementdistance(enemy_origin, point.origin))
            point.score = point.score + 25;

        point.score = point.score + RandomFloatRange(0, randomness);

        if(IsDefined(point.distawayfromengagementarea))
            point.score = point.score + point.distawayfromengagementarea * -1;

        is_near_another_sentinel = sentinel_isnearanothersentinel(point.origin, 200);

        if(IsDefined(is_near_another_sentinel) && is_near_another_sentinel)
            point.score = point.score + -200;

        is_overlap_another_sentinel = sentinel_isnearanothersentinel(point.origin, 100);

        if(IsDefined(is_overlap_another_sentinel) && is_overlap_another_sentinel)
            point.score = point.score + -2000;

        is_near_another_player = sentinel_isnearanotherplayer(point.origin, 150);

        if(IsDefined(is_near_another_player) && is_near_another_player)
            point.score = point.score + -200;

        distfrompreferredheight = Abs(point.origin[2] - goalheight);

        if(distfrompreferredheight > preferedheightrange)
        {
            heightscore = distfrompreferredheight - preferedheightrange * 3;
            point.score = point.score + heightscore * -1;
        }

        if(!IsDefined(best_score))
        {
            best_score = point.score;
            best_point = point;
            best_point.visibile = (IsDefined(self.sentinel_droneenemy) ? Int(BulletTracePassed(point.origin, enemy_origin, 0, self, self.sentinel_droneenemy)) : Int(BulletTracePassed(point.origin, enemy_origin, 0, self)));
            continue;
        }

        if(point.score > best_score)
        {
            point.visibile = (IsDefined(self.sentinel_droneenemy) ? Int(BulletTracePassed(point.origin, enemy_origin, 0, self, self.sentinel_droneenemy)) : Int(BulletTracePassed(point.origin, enemy_origin, 0, self)));

            if(point.visibile >= best_point.visibile)
            {
                best_score = point.score;
                best_point = point;
            }
        }
    }

    if(IsDefined(best_point))
    {
        if(best_point.score < -1000)
            best_point = undefined;
    }

    returndata = [];
    returndata["origin"] = (IsDefined(best_point) ? best_point.origin : undefined);
    returndata["centerOnNav"] = queryresult.centeronnav;

    return returndata;
}

function sentinel_isenemyindoors()
{
    if(!IsDefined(self.v_compact_mode))
        v_compact_mode = GetEnt("sentinel_compact", "targetname");

    if(IsDefined(v_compact_mode))
    {
        if(self.sentinel_droneenemy IsTouching(v_compact_mode))
            return 1;
    }

    return 0;
}

function positionquery_filter_outofgoalanchor(queryresult, tolerance = 1)
{
    foreach(point in queryresult.data)
    {
        if(point.disttogoal > tolerance)
            point.score = (point.score + ((-10000 - point.disttogoal) * 10));
    }
}

function positionquery_filter_engagementdist(queryresult, enemy, engagementdistancemin, engagementdistancemax)
{
    if(!IsDefined(enemy))
        return;

    engagementdistance = engagementdistancemin + engagementdistancemax * 0.5;
    half_engagement_width = Abs(engagementdistancemax - engagementdistance);
    enemy_origin = (enemy.origin[0], enemy.origin[1], 0);
    vec_enemy_to_self = VectorNormalize((self.origin[0], self.origin[1], 0) - enemy_origin);

    foreach(var_27b71730, point in queryresult.data)
    {
        point.distawayfromengagementarea = 0;
        vec_enemy_to_point = (point.origin[0], point.origin[1], 0) - enemy_origin;
        dist_in_front_of_enemy = VectorDot(vec_enemy_to_point, vec_enemy_to_self);

        if(Abs(dist_in_front_of_enemy) < engagementdistancemin)
            dist_in_front_of_enemy = engagementdistancemin * -1;

        dist_away_from_sweet_line = Abs(dist_in_front_of_enemy - engagementdistance);

        if(dist_away_from_sweet_line > half_engagement_width)
            point.distawayfromengagementarea = dist_away_from_sweet_line - half_engagement_width;

        too_far_dist = engagementdistancemax * 1.1;
        too_far_dist_sq = too_far_dist * too_far_dist;
        dist_from_enemy_sq = Distance2DSquared(point.origin, enemy_origin);

        if(dist_from_enemy_sq > too_far_dist_sq)
        {
            ratiosq = dist_from_enemy_sq / too_far_dist_sq;
            dist = ratiosq * too_far_dist;
            dist_outside = dist - too_far_dist;

            if(dist_outside > point.distawayfromengagementarea)
                point.distawayfromengagementarea = dist_outside;
        }
    }
}

function sentinel_isnearanothersentinel(point, min_distance)
{
    if(!IsDefined(level.a_sentinel_drones))
        return 0;

    for(i = 0; i < level.a_sentinel_drones.size; i++)
    {
        if(!IsDefined(level.a_sentinel_drones[i]))
            continue;

        if(level.a_sentinel_drones[i] == self)
            continue;

        if(DistanceSquared(level.a_sentinel_drones[i].origin, point) < (min_distance * min_distance))
            return 1;
    }

    return 0;
}

function sentinel_isnearanotherplayer(origin, min_distance)
{
    foreach(player in GetPlayers())
    {
        if(!sentinel_is_target_valid(player))
            continue;

        if(DistanceSquared(origin, player.origin + VectorScale((0, 0, 1), 48)) < (min_distance * min_distance))
            return 1;
    }

    return 0;
}

function sentinel_is_target_valid(target)
{
    if(!IsDefined(target))
        return 0;

    if(!IsAlive(target))
        return 0;

    if(IsPlayer(target) && target.sessionstate == "spectator")
        return 0;

    if(IsPlayer(target) && target.sessionstate == "intermission")
        return 0;

    if(IsDefined(target.ignoreme) && target.ignoreme)
        return 0;

    if(target IsNoTarget())
        return 0;

    if(IsDefined(target.is_elemental_zombie) && target.is_elemental_zombie)
        return 0;

    if(IsDefined(level.is_valid_player_for_sentinel_drone))
    {
        if(![[ level.is_valid_player_for_sentinel_drone ]](target))
            return 0;
    }

    if(IsDefined(self.should_buff_zombies) && self.should_buff_zombies && IsPlayer(target))
    {
        if(IsDefined(get_sentinel_nearest_zombie()))
            return 0;
    }

    return 1;
}

function get_sentinel_nearest_zombie(b_ignore_elemental = 1, b_outside_playable_area = 1, radius = 2000)
{
    if(IsDefined(self.sentinel_getnearestzombie))
    {
        ai_zombie = [[ self.sentinel_getnearestzombie ]](self.origin, b_ignore_elemental, b_outside_playable_area, radius);
        return ai_zombie;
    }

    return undefined;
}

function sentinel_pathupdateinterrupt()
{
    self endon("death");
    self endon("change_state");
    self endon("near_goal");
    self endon("reached_end_node");
    self notify("sentinel_pathupdateinterrupt");
    self endon("sentinel_pathupdateinterrupt");

    skip_sentinel_pathupdateinterrupt = GetDvarInt("skip_sentinel_PathUpdateInterrupt", 1);

    if(skip_sentinel_pathupdateinterrupt == 1)
        return;

    wait 1;

    while(1)
    {
        if(IsDefined(self.current_pathto_pos))
        {
            if(Distance2DSquared(self.origin, self.goalpos) < self.goalradius * self.goalradius)
            {
                wait 0.2;
                self notify("near_goal");
            }
        }

        wait 0.2;
    }
}

function waittill_pathing_done(maxtime = 15)
{
    self endon("change_state");
    self util::waittill_any_ex(maxtime, "near_goal", "force_goal", "reached_end_node", "goal", "pathfind_failed", "change_state");
}

function sentinel_killmyself()
{
    self DoDamage(self.health + 100, self.origin);
}
















//Mangler
function ServerSpawnMangler()
{
    var_19764360 = mangler_get_favorite_enemy();

    if(!IsDefined(var_19764360))
        return;
    
    trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);

    origin = trace["position"];
    surface = trace["surfacetype"];

    if(surface == "none" || surface == "default")
        return self iPrintlnBold("^1ERROR: ^7Invalid Surface");

    s_location = ((self.AISpawnLocation == "Crosshairs") ? self TraceBullet() : self.origin);
    ai = function_665a13cd(level.var_6bca5baa[0]);

    if(IsDefined(ai))
    {
        ai thread function_b8671cc0(s_location);
        ai ForceTeleport(s_location);

        if(IsDefined(var_19764360))
        {
            ai.favoriteenemy = var_19764360;
            ai.favoriteenemy.hunted_by++;
        }

        level.zombie_total--;
    }
}

function mangler_get_favorite_enemy()
{
    var_bc3f44bf = GetPlayers();
    e_least_hunted = undefined;

    foreach(var_9e2c0900, e_target in var_bc3f44bf)
    {
        if(!IsDefined(e_target.hunted_by))
            e_target.hunted_by = 0;

        if(!zm_utility::is_player_valid(e_target) || IsDefined(level.var_3fded92e) && ![[ level.var_3fded92e ]](e_target))
            continue;

        if(!IsDefined(e_least_hunted))
        {
            e_least_hunted = e_target;
            continue;
        }

        if(e_target.hunted_by < e_least_hunted.hunted_by)
            e_least_hunted = e_target;
    }

    return e_least_hunted;
}

function function_665a13cd(spawner, s_spot)
{
    var_a09c80cd = zombie_utility::spawn_zombie(level.var_6bca5baa[0], "raz", s_spot);

    if(IsDefined(var_a09c80cd))
    {
        var_a09c80cd.check_point_in_enabled_zone = &zm_utility::check_point_in_playable_area;
        var_a09c80cd thread zombie_utility::round_spawn_failsafe();
        var_a09c80cd thread function_b8671cc0(s_spot);
    }

    return var_a09c80cd;
}

function function_b8671cc0(s_spot)
{
    if(IsDefined(level.var_71ab2462))
        self thread [[ level.var_71ab2462 ]](s_spot);

    if(IsDefined(level.var_ae95a175))
        self thread [[ level.var_ae95a175 ]]();
}










//Thrasher
function ServerSpawnThrasher(location)
{
    var_e3372b59 = zombie_utility::spawn_zombie(level.var_feebf312[0], "thrasher", location);

    if(IsDefined(var_e3372b59) && IsDefined(location))
    {
        var_e3372b59 Forceteleport(location);
        PlaySoundAtPosition("zmb_vocals_thrash_spawn", var_e3372b59.origin);

        if(!var_e3372b59 zm_utility::in_playable_area())
        {
            player = array::random(level.players);

            if(zm_utility::is_player_valid(player, 0, 1))
                var_e3372b59 thread function_89976d94(player.origin);
        }

        return var_e3372b59;
    }
}

function function_89976d94(v_pos)
{
    self endon("death");

    var_2e57f81c = util::spawn_model("tag_origin", self.origin, self.angles);
    var_2e57f81c thread scene::play("scene_zm_dlc2_thrasher_teleport_out", self);
    self util::waittill_notify_or_timeout("thrasher_teleport_out_done", 4);
    a_v_points = util::positionquery_pointarray(v_pos, 128, 750, 32, 64, self);

    if(IsDefined(self.thrasher_teleport_dest_func))
        a_v_points = self [[ self.thrasher_teleport_dest_func ]](a_v_points);

    var_72436e1a = ArrayGetFarthest(v_pos, a_v_points);

    if(IsDefined(var_72436e1a))
    {
        var_948d85e3 = util::spawn_model("tag_origin", var_72436e1a, VectorToAngles(VectorNormalize((v_pos - var_72436e1a))));
        var_2e57f81c scene::stop("scene_zm_dlc2_thrasher_teleport_out");
        var_948d85e3 thread scene::play("scene_zm_dlc2_thrasher_teleport_in_v1", self);
    }
    else
    {
        var_948d85e3 = util::spawn_model("tag_origin", v_pos, (0, 0, 0));
        var_2e57f81c scene::stop("scene_zm_dlc2_thrasher_teleport_out");
        var_948d85e3 thread scene::play("scene_zm_dlc2_thrasher_teleport_in_v1", self);
    }
}














//Spiders
function ServerSpawnSpider(location)
{
    ai = zombie_utility::spawn_zombie(level.var_c38a4fee[0]);

    if(IsDefined(ai))
    {
        thread function_49e57a3b(ai, location);
        level.zombie_total--;
        level flag::set("spider_clips");
    }

    if(IsDefined(ai))
        return ai;
}

function spider_get_favorite_enemy()
{
    var_5a210579 = level.players;
    e_least_hunted = var_5a210579[0];

    for(i = 0; i < var_5a210579.size; i++)
    {
        if(!IsDefined(var_5a210579[i].hunted_by))
            var_5a210579[i].hunted_by = 0;

        if(!zm_utility::is_player_valid(var_5a210579[i]))
            continue;

        if(!zm_utility::is_player_valid(e_least_hunted))
            e_least_hunted = var_5a210579[i];

        if(var_5a210579[i].hunted_by < e_least_hunted.hunted_by)
            e_least_hunted = var_5a210579[i];
    }

    e_least_hunted.hunted_by = (e_least_hunted.hunted_by + 1);

    return e_least_hunted;
}

function function_49e57a3b(var_c79d3f71, location)
{
    var_c79d3f71 endon("death");

    var_c79d3f71 ai::set_ignoreall(1);
    var_c79d3f71 Ghost();
    var_c79d3f71 util::delay(0.2, "death", &Show);
    var_c79d3f71 util::delay_notify(0.2, "visible", "death");
    var_c79d3f71.origin = location;
    var_c79d3f71 vehicle_ai::set_state("scripted");

    if(IsAlive(var_c79d3f71))
    {
        a_ground_trace = GroundTrace((var_c79d3f71.origin + VectorScale((0, 0, 1), 100)), (var_c79d3f71.origin - VectorScale((0, 0, 1), 1000)), 0, var_c79d3f71, 1);
        var_197f1988 = util::spawn_model("tag_origin", (IsDefined(a_ground_trace["position"]) ? a_ground_trace["position"] : var_c79d3f71.origin), var_c79d3f71.angles);

        var_197f1988 scene::play("scene_zm_dlc2_spider_burrow_out_of_ground", var_c79d3f71);
        var_c79d3f71 vehicle_ai::set_state(((RandomFloat(1) > 0.6) ? "meleeCombat" : "combat"));
        var_c79d3f71 SetVisibleToAll();
        var_c79d3f71 ai::set_ignoreme(0);
    }

    var_c79d3f71 ai::set_ignoreall(0);
}


















//Fury
function ServerSpawnFury(location)
{
    var_33504256 = SpawnActor("spawner_zm_genesis_apothicon_fury", location, (0, 0, 0), undefined, 1, 1);

    if(IsDefined(var_33504256))
    {
        var_33504256 endon("death");

        var_33504256.spawn_time = GetTime();
        var_33504256.var_1cba9ac3 = 1;
        var_33504256.heroweapon_kill_power = 2;
        var_33504256.completed_emerging_into_playable_area = 1;
        var_33504256 thread apothicon_fury_death();
        var_33504256 thread zm::update_zone_name();
        level thread zm_spawner::zombie_death_event(var_33504256);
        var_33504256 thread zm_spawner::enemy_death_detection();
        var_33504256 thread function_7ba80ea7();
        var_33504256 thread function_1be68e3f();
        var_33504256.voiceprefix = "fury";
        var_33504256.animname = "fury";
        var_33504256 thread zm_spawner::play_ambient_zombie_vocals();
        var_33504256 thread zm_audio::zmbaivox_notifyconvert();
        var_33504256 PlaySound("zmb_vocals_fury_spawn");

        wait 1;
        var_33504256.zombie_think_done = 1;
        return var_33504256;
    }

    return undefined;
}

function apothicon_fury_death()
{
    self waittill("death", e_attacker);

    if(IsDefined(e_attacker) && IsDefined(e_attacker.var_4d307aef))
        e_attacker.var_4d307aef++;

    if(IsDefined(e_attacker) && IsDefined(e_attacker.var_8b5008fe))
        e_attacker.var_8b5008fe++;
}

function function_7ba80ea7()
{
    self.is_zombie = 1;
    zombiehealth = level.zombie_health;

    if(!IsDefined(zombiehealth))
        zombiehealth = level.zombie_vars["zombie_health_start"];

    self.maxhealth = ((level.round_number <= 20) ? (zombiehealth * 1.2) : ((level.round_number <= 50) ? (zombiehealth * 1.5) : (zombiehealth * 1.7)));

    if(!IsDefined(self.maxhealth) || self.maxhealth <= 0 || self.maxhealth > 2147483647 || self.maxhealth != self.maxhealth)
        self.maxhealth = zombiehealth;

    self.health = Int(self.maxhealth);
}

function function_1be68e3f()
{
    self endon("death");

    while(1)
    {
        if(IsDefined(self.zone_name))
        {
            if(self.zone_name == "dark_arena_zone" || self.zone_name == "dark_arena2_zone")
            {
                if(!IsPointOnNavMesh(self.origin))
                    self ForceTeleport(GetClosestPointOnNavMesh(self.origin, 256, 30));
            }
        }

        wait 0.25;
    }
}














//Quad Zombie(Nova Gas Zombie)
function ServerSpawnNovaZombie(location)
{
    spawn_array = (IsDefined(level.quad_spawners) ? level.quad_spawners : GetEntArray("quad_zombie_spawner", "script_noteworthy"));
    spawn_point = spawn_array[RandomInt(spawn_array.size)];
    ai = zombie_utility::spawn_zombie(spawn_point);

    if(IsDefined(ai))
    {
        ai thread zombie_utility::round_spawn_failsafe();
        ai thread QuadSetup();
        wait 1;

        linker = Spawn("script_origin", ai.origin);
        linker.origin = ai.origin;
        linker.angles = ai.angles;

        ai LinkTo(linker);
        linker MoveTo(location, 0.01);

        linker waittill("movedone");

        ai Unlink();
        linker Delete();

        ai thread quad_traverse_death_fx();
    }
}

function quad_traverse_death_fx()
{
    self endon("traverse_anim");

    self waittill("death");
    PlayFX(level._effect["quad_grnd_dust_spwnr"], self.origin);
}

function QuadSetup()
{
    self.animname = "quad_zombie";
    self.no_gib = 1;
    self.no_eye_glow = 1;
    self.no_widows_wine = 1;
    self.canbetargetedbyturnedzombies = 1;
    self zm_spawner::zombie_spawn_init(1);
    self.zombie_can_sidestep = 0;
    self.maxhealth = Int((self.maxhealth * 0.75));
    self.health = self.maxhealth;
    self.freezegun_damage = 0;
    self.meleedamage = 45;
    self PlaySound("zmb_quad_spawn");
    self.death_explo_radius_zomb = 96;
    self.death_explo_radius_plr = 96;
    self.death_explo_damage_zomb = 1.05;
    self.death_gas_radius = 125;
    self.death_gas_time = 7;

    if(IsDefined(level.quad_explode) && level.quad_explode)
    {
        self.deathfunction = &quad_post_death;
        self.actor_killed_override = &quad_killed_override;
    }

    self set_default_attack_properties();
    self.thundergun_knockdown_func = &quad_thundergun_knockdown;
    self.pre_teleport_func = &quad_pre_teleport;
    self.post_teleport_func = &quad_post_teleport;
    self.can_explode = 0;
    self.exploded = 0;
    self thread quad_trail();
    self AllowPitchAngle(1);
    self SetPhysParams(15, 0, 24);

    if(IsDefined(level.quad_prespawn))
        self thread [[ level.quad_prespawn ]]();
}

function quad_post_death(einflictor, attacker, idamage, smeansofdeath, weapon, vdir, shitloc, psoffsettime)
{
    self zm_spawner::zombie_death_animscript();
    return 0;
}

function quad_killed_override(einflictor, attacker, idamage, smeansofdeath, weapon, vdir, shitloc, psoffsettime)
{
    if(smeansofdeath == "MOD_PISTOL_BULLET" || smeansofdeath == "MOD_RIFLE_BULLET")
        self.can_explode = 1;
    else
    {
        self.can_explode = 0;

        if(IsDefined(self.fx_quad_trail))
        {
            self.fx_quad_trail Unlink();
            self.fx_quad_trail Delete();
        }
    }

    if(IsDefined(level._override_quad_explosion))
        [[ level._override_quad_explosion ]](self);
}

function set_default_attack_properties()
{
    self.goalradius = 16;
    self.maxsightdistsqrd = 16384;
    self.can_leap = 0;
}

function quad_thundergun_knockdown(player, gib)
{
    self DoDamage(Int(self.maxhealth * 0.5), player.origin, player);
}

function quad_pre_teleport()
{
    if(IsDefined(self.fx_quad_trail))
    {
        self.fx_quad_trail Unlink();
        self.fx_quad_trail Delete();

        wait 0.1;
    }
}

function quad_post_teleport()
{
    if(IsDefined(self.fx_quad_trail))
    {
        self.fx_quad_trail Unlink();
        self.fx_quad_trail Delete();
    }

    if(self.health > 0)
    {
        self.fx_quad_trail = Spawn("script_model", self GetTagOrigin("tag_origin"));
        self.fx_quad_trail.angles = self GetTagAngles("tag_origin");
        self.fx_quad_trail SetModel("tag_origin");
        self.fx_quad_trail LinkTo(self, "tag_origin");
        zm_net::network_safe_play_fx_on_tag("quad_fx", 2, level._effect["quad_trail"], self.fx_quad_trail, "tag_origin");
    }
}

function quad_trail()
{
    self endon("death");

    self.fx_quad_trail = Spawn("script_model", self GetTagOrigin("tag_origin"));
    self.fx_quad_trail.angles = self GetTagAngles("tag_origin");
    self.fx_quad_trail SetModel("tag_origin");
    self.fx_quad_trail LinkTo(self, "tag_origin");
    zm_net::network_safe_play_fx_on_tag("quad_fx", 2, level._effect["quad_trail"], self.fx_quad_trail, "tag_origin");
}

// ============================================================
// Functions/allplayers.gsc
// ============================================================

function PopulateAllPlayerOptions(menu)
{
    switch(menu)
    {
        case "All Players":
            self addMenu("All Players Menu");
                self addOpt("Verification", &newMenu, "All Players Verification");
                self addOptSlider("Teleport", &AllPlayersTeleport, Array("Self", "Crosshairs", "Sky"));
                self addOpt("Model Manipulation", &newMenu, "All Players Model Manipulation");
                self addOpt("Malicious Options", &newMenu, "All Players Malicious Options");
                self addOptBool(AllClientsGodModeCheck(), "God Mode", &AllClientsGodMode);
                self addOpt("Send Message", &Keyboard, &MessageAllPlayers);
                self addOpt("Kick", &AllPlayersFunction, &KickPlayer);
                self addOpt("Down", &AllPlayersFunction, &PlayerDeath, "Down");
                self addOpt("Revive", &AllPlayersFunction, &PlayerRevive);
                self addOpt("Respawn", &AllPlayersFunction, &ServerRespawnPlayer);
            break;
        
        case "All Players Verification":
            self addMenu("Verification");

                for(a = 1; a < (GetAccessLevels().size - 2); a++)
                    self addOpt(GetAccessLevels()[a], &SetVerificationAllPlayers, a, true);
            break;
        
        case "All Players Model Manipulation":
            self addMenu("Model Manipulation");
                
                if(IsDefined(level.menu_models) && level.menu_models.size)
                {
                    self addOpt("Reset", &AllPlayersFunction, &ResetPlayerModel);
                    self addOpt("");

                    for(a = 0; a < level.menu_models.size; a++)
                        self addOpt(CleanString(level.menu_models[a]), &AllPlayersFunction, &SetPlayerModel, level.menu_models[a]);
                }
            break;
        
        case "All Players Malicious Options":
            self addMenu("Malicious Options");
                self addOpt("Launch", &AllPlayersFunction, &LaunchPlayer);
                self addOpt("Mortar Strike", &AllPlayersFunction, &MortarStrikePlayer);
                self addOpt("Fake Derank", &AllPlayersFunction, &FakeDerank);
                self addOpt("Fake Damage", &AllPlayersFunction, &FakeDamagePlayer);
                self addOpt("Crash Game", &AllPlayersFunction, &CrashPlayer);
            break;
    }
}

function AllPlayersFunction(fnc, param, param2)
{
    if(!IsDefined(fnc))
        return;
    
    foreach(player in level.players)
    {
        if(player IsHost() || player isDeveloper())
            continue;
        
        if(IsDefined(param2))
            self thread [[ fnc ]](param, param2, player);
        else if(IsDefined(param))
            self thread [[ fnc ]](param, player);
        else
            self thread [[ fnc ]](player);
    }
}

function AllPlayersTeleport(origin)
{
    switch(origin)
    {
        case "Sky":
            foreach(player in level.players)
            {
                if(!player IsHost() && !player isDeveloper() && player != self)
                    player SetOrigin(player.origin + (0, 0, 35000));
            }
            break;
        
        case "Crosshairs":
            foreach(player in level.players)
            {
                if(!player IsHost() && !player isDeveloper() && player != self)
                    player SetOrigin(self TraceBullet());
            }
            break;
        
        case "Self":
            foreach(player in level.players)
            {
                if(!player IsHost() && !player isDeveloper() && player != self)
                    player SetOrigin(self.origin);
            }
            break;
        
        default:
            break;
    }
}

function AllClientsGodModeCheck()
{
    foreach(player in level.players)
    {
        if(!Is_True(player.playerGodmode))
            return false;
    }
    
    return true;
}

function AllClientsGodMode()
{
    if(!AllClientsGodModeCheck())
    {
        foreach(player in level.players)
        {
            if(!Is_True(player.playerGodmode))
                Godmode(player);
        }
    }
    else
    {
        foreach(player in level.players)
        {
            if(Is_True(player.playerGodmode))
                Godmode(player);
        }
    }
}

function MessageAllPlayers(msg)
{
    foreach(player in level.players)
    {
        if(player == self)
            continue;
        
        player iPrintlnBold("^2" + CleanName(self getName()) + ": ^7" + msg);
    }
}

// ============================================================
// Functions/basic.gsc
// ============================================================

function PopulateBasicScripts(menu, player)
{
    switch(menu)
    {
        case "Basic Scripts":
            self addMenu(menu);
                self addOptBool(player.playerGodmode, "God Mode", &Godmode, player);
                self addOptBool(player.PlayerDemiGod, "Demi-God", &DemiGod, player);
                self addOptBool(player.Noclip, "Noclip", &Noclip1, player);
                self addOptBool(player.NoclipBind1, "Bind Noclip To [{+frag}]", &BindNoclip, player);
                self addOptBool(player.UFOMode, "UFO Mode", &UFOMode, player);
                self addOptSlider("Unlimited Ammo", &UnlimitedAmmo, Array("Continuous", "Reload", "Disable"), player);
                self addOptBool(player.UnlimitedEquipment, "Unlimited Equipment", &UnlimitedEquipment, player);
                self addOptBool(player.UnlimitedSpecial, "Unlimited Special Weapon", &UnlimitedSpecial, player);
                self addOptSlider("Modify Score", &ModifyScore, Array("1000000", "100000", "10000", "1000", "100", "10", "0", "-10", "-100", "-1000", "-10000", "-100000", "-1000000"), player);
                self addOpt("Perk Menu", &newMenu, "Perk Menu");
                self addOpt("Gobblegum Menu", &newMenu, "Gobblegum Menu");
                self addOptIncSlider("Movement Speed", &SetMovementSpeed, 0, 1, 3, 0.5, player);
                self addOptBool(player.ThirdPerson, "Third Person", &ThirdPerson, player);
                self addOptBool(player.Invisibility, "Invisibility", &Invisibility, player);
                self addOptSlider("Clone", &PlayerClone, Array("Clone", "Dead"), player);
                self addOptBool(player.playerIgnoreMe, "No Target", &NoTarget, player);
                self addOptBool(player.ReducedSpread, "Reduced Spread", &ReducedSpread, player);
                self addOptBool(player.MultiJump, "Multi-Jump", &MultiJump, player);
                self addOptBool(player.DisablePlayerHUD, "Disable HUD", &DisablePlayerHUD, player);
                self addOpt("Visual Effects", &newMenu, "Visual Effects");
                self addOptSlider("Set Vision", &PlayerSetVision, Array("Default", "zombie_last_stand", "zombie_death", "flashbang", "zm_bgb_candy_bluez", "zm_bgb_candy_greenz", "zm_bgb_candy_purplez", "zm_bgb_candy_yellowz", "zm_bgb_now_you_see_me", "zombie_noire"), player);
                self addOptSlider("Zombie Charms", &ZombieCharms, Array("None", "Orange", "Green", "Purple", "Blue"), player);
                self addOptSlider("Custom Crosshairs", &CustomCrosshairs, Array("Disable", "+", "@", "x", "o", "> <", "CF4_99", "Extinct", "Daltax", "GBP", "AOC", GetMenuName(), "discord.gg/apparitionbo3", CleanName(player getName())), player);
                self addOptBool(player.NoExplosiveDamage, "No Explosive Damage", &NoExplosiveDamage, player);
                self addOptIncSlider("Character Model Index", &SetCharacterModelIndex, 0, player.characterIndex, 8, 1, player);
                self addOptBool(player.LoopCharacterModelIndex, "Random Character Model Index", &LoopCharacterModelIndex, player);
                self addOptBool(player HasPerk("specialty_sprintfire"), "Shoot While Sprinting", &ShootWhileSprinting, player);
                self addOptBool(player HasPerk("specialty_unlimitedsprint"), "Unlimited Sprint", &UnlimitedSprint, player);
                self addOpt("Respawn", &ServerRespawnPlayer, player);
                self addOpt("Revive", &PlayerRevive, player);
                self addOptSlider("Death", &PlayerDeath, Array("Down", "Kill"), player);
            break;
        
        case "Perk Menu":
            MenuPerks = [];
            perks = GetArrayKeys(level._custom_perks);

            for(a = 0; a < perks.size; a++)
                array::add(MenuPerks, perks[a], 0);

            self addMenu(menu);
            
                if(IsDefined(MenuPerks) && MenuPerks.size)
                {
                    self addOptBool((IsDefined(player.perks_active) && player.perks_active.size == MenuPerks.size), "All Perks", &PlayerAllPerks, player);
                    self addOptBool(player._retain_perks, "Retain Perks", &PlayerRetainPerks, player);

                    for(a = 0; a < MenuPerks.size; a++) self addOptBool((player HasPerk(MenuPerks[a]) || player zm_perks::has_perk_paused(MenuPerks[a])), ((ReturnPerkName(CleanString(MenuPerks[a])) == "Unknown Perk") ? CleanString(MenuPerks[a]) : ReturnPerkName(CleanString(MenuPerks[a]))), &GivePlayerPerk, MenuPerks[a], player);
                }
            break;
        
        case "Gobblegum Menu":
            MenuBGB = [];
            bgb = GetArrayKeys(level.bgb);

            for(a = 0; a < bgb.size; a++)
                array::add(MenuBGB, bgb[a], 0);

            self addMenu(menu);

                if(IsDefined(MenuBGB) && MenuBGB.size)
                {
                    for(a = 0; a < MenuBGB.size; a++)
                        self addOptBool((player.bgb == MenuBGB[a]), GobblegumName(MenuBGB[a]), &GivePlayerGobblegum, MenuBGB[a], player);
                }
            break;
        
        case "Visual Effects":

            if(!IsDefined(player.ClientVisualEffect))
                player.ClientVisualEffect = "None";

            types = Array("visionset", "overlay");
            invalid = Array("none", "__none", "last_stand", "_death", "thrasher");
            visuals = [];

            self addMenu(menu);

                if(IsDefined(level.vsmgr) && level.vsmgr.size)
                {
                    for(a = 0; a < types.size; a++)
                    {
                        if(IsDefined(level.vsmgr[types[a]]) && IsDefined(level.vsmgr[types[a]].info))
                        {
                            foreach(key in GetArrayKeys(level.vsmgr[types[a]].info))
                            {
                                if(isInArray(visuals, key) || isInArray(invalid, key))
                                    continue;
                                
                                skip = false;

                                for(b = 0; b < invalid.size; b++)
                                {
                                    if(IsSubStr(key, invalid[b]))
                                        skip = true;
                                }
                                
                                if(skip)
                                    continue;
                                
                                visuals[visuals.size] = key;
                                self addOptBool(player GetVisualEffectState(key), CleanString(key), &SetClientVisualEffects, key, player);
                            }
                        }
                    }
                }
            break;
    }
}

function Godmode(player)
{
    if(Is_True(player.PlayerDemiGod))
        player DemiGod(player);
    
    player.playerGodmode = BoolVar(player.playerGodmode);
}

function DemiGod(player)
{
    if(Is_True(player.playerGodmode))
        player Godmode(player);

    player.PlayerDemiGod = BoolVar(player.PlayerDemiGod);
}

function Noclip1(player)
{
    player endon("disconnect");

    if(!Is_True(player.Noclip) && player isPlayerLinked())
        return self iPrintlnBold("^1ERROR: ^7Player Is Linked To An Entity");
    
    player.Noclip = BoolVar(player.Noclip);
    
    if(Is_True(player.Noclip))
    {
        if(player hasMenu() && player isInMenu(true))
            player closeMenu1();

        player DisableWeapons();
        player DisableOffHandWeapons();
        player SetStance("stand");

        player.nocliplinker = SpawnScriptModel(player.origin, "tag_origin");
        player PlayerLinkTo(player.nocliplinker, "tag_origin");
        player.DisableMenuControls = true;
        player SetMenuInstructions(Array("[{+attack}] - Move Forward", "[{+speed_throw}] - Move Backwards", "[{+melee}] - Exit"));
        
        while(Is_True(player.Noclip) && Is_Alive(player) && !player isPlayerLinked(player.nocliplinker))
        {
            if(player GetStance() != "stand")
                player SetStance("stand");

            if(player AttackButtonPressed())
                player.nocliplinker.origin = player.nocliplinker.origin + AnglesToForward(player GetPlayerAngles()) * 60;
            else if(player AdsButtonPressed())
                player.nocliplinker.origin = player.nocliplinker.origin - AnglesToForward(player GetPlayerAngles()) * 60;

            if(player MeleeButtonPressed())
                break;

            wait 0.01;
        }

        if(Is_True(player.Noclip))
            player Noclip1(player);
    }
    else
    {
        player Unlink();

        if(IsDefined(player.nocliplinker))
            player.nocliplinker Delete();

        player EnableWeapons();
        player EnableOffHandWeapons();

        if(Is_True(player.DisableMenuControls))
            player.DisableMenuControls = BoolVar(player.DisableMenuControls);
        
        player SetMenuInstructions();
    }
}

function BindNoclip(player)
{
    player endon("disconnect");

    if(Is_True(player.Jetpack) && !Is_True(player.NoclipBind1))
        return self iPrintlnBold("^1ERROR: ^7Player Has Jetpack Enabled");
    
    if(Is_True(player.SpecNade) && !Is_True(player.NoclipBind1))
        return self iPrintlnBold("^1ERROR: ^7Player Has Spec-Nade Enabled");
    
    player.NoclipBind1 = BoolVar(player.NoclipBind1);
    
    while(Is_True(player.NoclipBind1))
    {
        if(player FragButtonPressed() && !Is_True(player.DisableMenuControls))
        {
            player Noclip1(player);
            wait 0.2;
        }

        wait 0.025;
    }
}

function UFOMode(player)
{
    player endon("disconnect");

    if(!Is_True(player.UFOMode) && player isPlayerLinked())
        return self iPrintlnBold("^1ERROR: ^7Player Is Linked To An Entity");
    
    player.UFOMode = BoolVar(player.UFOMode);
    
    if(Is_True(player.UFOMode))
    {
        if(player hasMenu() && player isInMenu(true))
            player closeMenu1();

        player DisableWeapons();
        player DisableOffHandWeapons();
        player SetStance("stand");

        player.ufolinker = SpawnScriptModel(player.origin, "tag_origin");
        player PlayerLinkTo(player.ufolinker, "tag_origin");
        player.DisableMenuControls = true;
        player SetMenuInstructions(Array("[{+attack}] - Move Up", "[{+speed_throw}] - Move Down", "[{+frag}] - Move Forward", "[{+melee}] - Exit"));
        
        while(Is_True(player.UFOMode) && Is_Alive(player) && !player isPlayerLinked(player.ufolinker))
        {
            if(player GetStance() != "stand")
                player SetStance("stand");
            
            player.ufolinker.angles = (player.ufolinker.angles[0], player GetPlayerAngles()[1], player.ufolinker.angles[2]);

            if(player AttackButtonPressed())
                player.ufolinker.origin = player.ufolinker.origin + AnglesToUp(player.ufolinker.angles) * 60;
            else if(player AdsButtonPressed())
                player.ufolinker.origin = player.ufolinker.origin - AnglesToUp(player.ufolinker.angles) * 60;

            if(player FragButtonPressed())
                player.ufolinker.origin = player.ufolinker.origin + AnglesToForward(player.ufolinker.angles) * 60;
            
            if(player MeleeButtonPressed())
                break;

            wait 0.01;
        }

        if(Is_True(player.UFOMode))
            player UFOMode(player);
    }
    else
    {
        player Unlink();

        if(IsDefined(player.ufolinker))
            player.ufolinker Delete();

        player EnableWeapons();
        player EnableOffHandWeapons();

        if(Is_True(player.DisableMenuControls))
            player.DisableMenuControls = BoolVar(player.DisableMenuControls);
        
        player SetMenuInstructions();
    }
}

function UnlimitedAmmo(type, player)
{
    player notify("EndUnlimitedAmmo");
    player endon("EndUnlimitedAmmo");
    player endon("disconnect");

    if(type != "Disable")
    {
        while(1)
        {
            weapon = player GetCurrentWeapon();

            if(IsDefined(weapon) && weapon != level.weaponnone)
            {
                player GiveMaxAmmo(weapon);

                if(type == "Continuous")
                    player SetWeaponAmmoClip(weapon, weapon.clipsize);
            }

            player util::waittill_any("weapon_fired", "weapon_change");
        }
    }
}

function UnlimitedEquipment(player)
{
    player endon("disconnect");

    player.UnlimitedEquipment = BoolVar(player.UnlimitedEquipment);

    while(Is_True(player.UnlimitedEquipment))
    {
        lethal = player zm_utility::get_player_lethal_grenade();
        tactical = player zm_utility::get_player_tactical_grenade();

        if(IsDefined(lethal) && lethal != level.weaponnone)
        {
            if(!player HasWeapon(lethal))
                player GiveWeapon(lethal);
            
            player GiveMaxAmmo(lethal);
        }
        
        if(IsDefined(tactical) && tactical != level.weaponnone)
        {
            if(!player HasWeapon(tactical))
                player GiveWeapon(tactical);
            
            player GiveMaxAmmo(tactical);
        }
        
        player waittill("grenade_fire");
    }
}

function UnlimitedSpecial(player)
{
    player endon("disconnect");

    player.UnlimitedSpecial = BoolVar(player.UnlimitedSpecial);

    while(Is_True(player.UnlimitedSpecial))
    {
        if(player GadgetIsActive(0))
            player GadgetPowerSet(0, 99);
        else if(player GadgetPowerGet(0) < 100)
            player GadgetPowerSet(0, 100);

        wait 0.01;
    }
}

function ModifyScore(score, player)
{
    score = Int(score);

    if(score > 0)
    {
        player zm_score::add_to_player_score(score);
    }
    else if(score < 0)
    {
        player zm_score::minus_to_player_score((score * -1));
    }
    else
    {
        if(player.score > 0)
            player zm_score::minus_to_player_score(player.score);
        else if(player.score < 0)
            player zm_score::add_to_player_score((player.score * -1));
    }
}

function PlayerAllPerks(player)
{
    player endon("disconnect");

    MenuPerks = [];
    perks = GetArrayKeys(level._custom_perks);

    for(a = 0; a < perks.size; a++)
        array::add(MenuPerks, perks[a], 0);

    if(!IsDefined(player.perks_active) || player.perks_active.size != MenuPerks.size)
    {
        for(a = 0; a < MenuPerks.size; a++)
        {
            if(!player HasPerk(MenuPerks[a]) && !player zm_perks::has_perk_paused(MenuPerks[a]))
                player zm_perks::give_perk(MenuPerks[a], true);
        }
    }
    else
    {
        for(a = 0; a < MenuPerks.size; a++)
        {
            if(player HasPerk(MenuPerks[a]) || player zm_perks::has_perk_paused(MenuPerks[a]))
                player notify(MenuPerks[a] + "_stop");
        }
    }
}

function PlayerRetainPerks(player)
{
    player endon("disconnect");

    MenuPerks = [];
    perks = GetArrayKeys(level._custom_perks);

    for(a = 0; a < perks.size; a++)
        array::add(MenuPerks, perks[a], 0);

    if(!Is_True(player._retain_perks))
    {
        player._retain_perks = true;
    }
    else
    {
        player._retain_perks = false;

        if(IsDefined(player._retain_perks_array))
            player._retain_perks_array = undefined;
        
        for(a = 0; a < MenuPerks.size; a++)
        {
            if(player HasPerk(MenuPerks[a]) || player zm_perks::has_perk_paused(MenuPerks[a]))
                player thread zm_perks::perk_think(MenuPerks[a]);
        }
    }
}

function GivePlayerPerk(perk, player)
{
    if(player HasPerk(perk) || player zm_perks::has_perk_paused(perk))
        player notify(perk + "_stop");
    else
        player zm_perks::give_perk(perk, true);
}

function GivePlayerGobblegum(name, player)
{
    player endon("disconnect");

    if(player.bgb != name)
    {
        menu = self getCurrent();
        curs = self getCursor();

        if(SessionModeIsOnlineGame()) //Don't need to use the recreated function if it's a ranked game
        {
            player bgb::bgb_gumball_anim(name, false);

            while(player.bgb != name)
                wait 0.01;
        }
        else
        {
            //bgb_play_gumball_anim_begin
            player zm_utility::increment_is_drinking();
            player zm_utility::disable_player_move_states(1);

            weapon = GetWeapon("zombie_bgb_grab");
            curWeapon = player GetCurrentWeapon();

            player GiveWeapon(weapon, player CalcWeaponOptions(level.bgb[name].camo_index, 0, 0));
            player SwitchToWeapon(weapon);
            player PlaySound("zmb_bgb_powerup_default");
            
            //bgb_gumball_anim
            evt = player util::waittill_any_return("fake_death", "death", "player_downed", "weapon_change_complete", "disconnect");

            if(evt == "weapon_change_complete")
            {
                player notify("bgb_gumball_anim_give", name);

                player bgb::give(name);
                player zm_stats::increment_client_stat("bgbs_chewed");
                player zm_stats::increment_player_stat("bgbs_chewed");
                player zm_stats::increment_challenge_stat("GUM_GOBBLER_CONSUME");
                player AddDStat("ItemStats", level.bgb[name].item_index, "stats", "used", "StatValue", 1);
                IncrementCounter("zm_bgb_consumed", 1);
            }

            //bgb_play_gumball_anim_end
            player zm_utility::enable_player_move_states();
            player TakeWeapon(weapon);

            if(player laststand::player_is_in_laststand() || (IsDefined(player.intermission) && player.intermission))
                return;
            
            if(player zm_utility::is_multiple_drinking())
            {
                player zm_utility::decrement_is_drinking();
                return;
            }
            
            if(curWeapon != level.weaponnone && !zm_utility::is_placeable_mine(curWeapon) && !zm_equipment::is_equipment_that_blocks_purchase(curWeapon))
            {
                player zm_weapons::switch_back_primary_weapon(curWeapon);

                if(zm_utility::is_melee_weapon(curWeapon))
                {
                    player zm_utility::decrement_is_drinking();
                    return;
                }
            }
            else
            {
                player zm_weapons::switch_back_primary_weapon(curWeapon);
            }
            
            player util::waittill_any_timeout(1, "weapon_change_complete");

            if(!player laststand::player_is_in_laststand() && (!(IsDefined(player.intermission) && player.intermission)))
                player zm_utility::decrement_is_drinking();
        }

        self RefreshMenu(menu, curs);
    }
    else
    {
        player bgb::take();
    }
}

function SetMovementSpeed(scale, player)
{
    player notify("EndMoveSpeed");
    player endon("EndMoveSpeed");
    player endon("disconnect");
    
    player.MovementSpeed = ((scale == 1) ? undefined : scale);
    player SetMoveSpeedScale(scale);
    
    while(IsDefined(player.MovementSpeed) && player.MovementSpeed != 1)
    {
        player SetMoveSpeedScale(scale);
        wait 0.5;
    }
}

function ThirdPerson(player)
{
    if(Is_True(self.AC130) || Is_True(self.FlyableUFO))
        return self iPrintlnBold("^1ERROR: ^7You Can't Enable Third Person For This Player Right Now");
    
    player.ThirdPerson = BoolVar(player.ThirdPerson);
    player SetClientThirdPerson(Is_True(player.ThirdPerson));
}

function Invisibility(player)
{
    player.Invisibility = BoolVar(player.Invisibility);

    if(Is_True(player.Invisibility))
        player Hide();
    else
        player Show();
}

function PlayerClone(type, player)
{
    switch(type)
    {
        case "Clone":
            player ClonePlayer(999999, player GetCurrentWeapon(), player);
            break;
        
        case "Dead":
            clone = player ClonePlayer(999999, player GetCurrentWeapon(), player);
            clone StartRagdoll(1);
            break;
        
        default:
            break;
    }
}

function NoTarget(player)
{
    player endon("disconnect");
    
    if(Is_True(player.AIPrioritizePlayer))
        AIPrioritizePlayer(player);
    
    player.playerIgnoreMe = BoolVar(player.playerIgnoreMe);
    
    if(Is_True(player.playerIgnoreMe))
    {
        while(Is_True(player.playerIgnoreMe))
        {
            player.ignoreme = true;
            wait 0.5;
        }
    }
    else
    {
        player.ignoreme = false;
    }
}

function ReducedSpread(player)
{
    player.ReducedSpread = BoolVar(player.ReducedSpread);

    if(Is_True(player.ReducedSpread))
        player SetSpreadOverride(1);
    else
        player ResetSpreadOverride();
}

function MultiJump(player)
{
    player endon("disconnect");

    player.MultiJump = BoolVar(player.MultiJump);
    firstJump = true;

    while(Is_True(player.MultiJump))
    {
        if(player IsOnGround())
            firstJump = true;
        
        if(player JumpButtonPressed() && !player IsOnGround() && Is_True(firstJump))
        {
            while(player JumpButtonPressed())
                wait 0.01;
            
            firstJump = false;
        }
        
        if(Is_Alive(player) && !player IsOnGround() && !Is_True(firstJump))
        {
            if(player JumpButtonPressed())
            {
                while(player JumpButtonPressed())
                    wait 0.01;
                
                player SetVelocity(player GetVelocity() + (0, 0, 250));
            }
        }
        
        wait 0.05;
    }
}

function DisablePlayerHUD(player)
{
    player.DisablePlayerHUD = BoolVar(player.DisablePlayerHUD);
    player SetClientUIVisibilityFlag("hud_visible", !Is_True(player.DisablePlayerHUD));
}

function GetVisualType(effect)
{
    types = Array("visionset", "overlay");
    type = undefined;

    for(a = 0; a < types.size; a++)
    {
        foreach(key in GetArrayKeys(level.vsmgr[types[a]].info))
        {
            if(IsDefined(key) && key == effect)
                type = (IsDefined(type) ? "Both" : types[a]);
        }
    }

    return type;
}

function GetVisualEffectState(effect)
{
    type = GetVisualType(effect);

    if(type == "Both")
    {
        types = Array("visionset", "overlay");

        for(a = 0; a < types.size; a++)
        {
            state = level.vsmgr[types[a]].info[effect].state;

            if(IsDefined(state.players[self GetEntityNumber()].active) && state.players[self GetEntityNumber()].active == 1)
                return true;
        }

        return false;
    }

    state = level.vsmgr[type].info[effect].state;
    
    if(!IsDefined(state.players[self GetEntityNumber()]))
        return false;
    
    return IsDefined(state.players[self GetEntityNumber()].active) && state.players[self GetEntityNumber()].active == 1;
}

function SetClientVisualEffects(effect, player)
{
    player endon("disconnect");

    type = GetVisualType(effect);

    if(!IsDefined(type))
        return;

    player notify("kill_full_period_hold");

    if(IsDefined(player.ClientVisualEffect))
    {
        if(effect == player.ClientVisualEffect)
            effect = "None";
        else if(effect != player.ClientVisualEffect && player GetVisualEffectState(effect))
            dEffect = effect;
    }

    if(IsDefined(player.ClientVisualEffect) && player.ClientVisualEffect != "None" || IsDefined(dEffect))
    {
        if(IsDefined(dEffect))
        {
            disable = dEffect;
        }
        else
        {
            if(IsDefined(player.ClientVisualEffect))
                disable = player.ClientVisualEffect;
        }
        
        if(IsDefined(disable))
        {
            removeType = GetVisualType(disable);

            if(removeType == "visionset" || removeType == "Both")
                visionset_mgr::deactivate("visionset", disable, player);
            
            if(removeType == "overlay" || removeType == "Both")
                visionset_mgr::deactivate("overlay", disable, player);
        }
    }

    if(!IsDefined(dEffect))
    {
        player.ClientVisualEffect = effect;

        if(IsDefined(effect) && effect != "None")
        {
            if(type == "visionset" || type == "Both")
                visionset_mgr::activate("visionset", effect, player, 1.25, &full_period_hold, 1);

            if(type == "overlay" || type == "Both")
            {
                if(IsDefined(level.vsmgr["overlay"]) && IsDefined(level.vsmgr["overlay"].info) && IsDefined(level.vsmgr["overlay"].info[effect]) && IsDefined(level.vsmgr["overlay"].info[effect].state) && IsDefined(level.vsmgr["overlay"].info[effect].state.lerp_thread))
                    lerp = level.vsmgr["overlay"].info[effect].state.lerp_thread;
                
                visionset_mgr::activate("overlay", effect, player, ((IsDefined(lerp) && lerp == &visionset_mgr::ramp_in_out_thread_per_player || IsDefined(lerp) && lerp == &visionset_mgr::ramp_in_out_thread) ? 1.25 : 1), ((IsDefined(lerp) && lerp == &visionset_mgr::duration_lerp_thread_per_player) ? 1 : ((IsDefined(lerp) && lerp == &visionset_mgr::ramp_in_out_thread_per_player || IsDefined(lerp) && lerp == &visionset_mgr::ramp_in_out_thread) ? &full_period_hold : undefined)), ((IsDefined(lerp) && lerp == &visionset_mgr::ramp_in_out_thread_per_player || IsDefined(lerp) && lerp == &visionset_mgr::ramp_in_out_thread) ? 1 : undefined));
            }
        }
    }
}

function full_period_hold()
{
    self endon("disconnect");
    self endon("kill_full_period_hold");

    while(1)
    {
        wait 1;
    }
}

function PlayerSetVision(vision, player)
{
    player UseServerVisionSet(vision != "Default");

    if(vision != "Default")
        player SetVisionSetForPlayer(vision, 0);
}

function ZombieCharms(color, player)
{
    switch(color)
    {
        case "None":
            color = 0;
            break;
        
        case "Orange":
            color = 1;
            break;
        
        case "Green":
            color = 2;
            break;
        
        case "Purple":
            color = 3;
            break;
        
        case "Blue":
            color = 4;
            break;
        
        default:
            color = 0;
            break;
    }

    player clientfield::set_to_player("eye_candy_render", color);
}

function CustomCrosshairs(text, player)
{
    if(text == "Disable")
    {
        if(!Is_True(player.CustomCrosshairs))
            return;

        if(IsDefined(player.CustomCrosshairsUI))
            player CloseLUIMenu(player.CustomCrosshairsUI);
        
        player.CustomCrosshairsUI = undefined;
        player.CustomCrosshairs = BoolVar(player.CustomCrosshairs);
        return;
    }

    if(Is_True(player.CustomCrosshairs) && IsDefined(player.CustomCrosshairsUI))
        return player SetLUIMenuData(player.CustomCrosshairsUI, "text", text);

    player.CustomCrosshairs = true;

    if(!IsDefined(player.CustomCrosshairsUI))
        player.CustomCrosshairsUI = player LUI_createText(text, 2, 513, 345, 255, player.MainTheme);
}

function NoExplosiveDamage(player)
{
    player.NoExplosiveDamage = BoolVar(player.NoExplosiveDamage);
}

function SetCharacterModelIndex(index, player, disableEffect)
{
    if(player.characterIndex == index)
        return;
    
    player endon("disconnect");

    if(!IsDefined(disableEffect) || !disableEffect)
    {
        PlayFX(level._effect["teleport_splash"], player.origin);
        PlayFX(level._effect["teleport_aoe_kill"], player GetTagOrigin("j_spineupper"));
    }

    player.characterIndex = index;
    player SetCharacterBodyType(index);
    player zm_audio::setexertvoice(index);
}

function LoopCharacterModelIndex(player)
{
    player endon("disconnect");

    player.LoopCharacterModelIndex = BoolVar(player.LoopCharacterModelIndex);

    while(Is_True(player.LoopCharacterModelIndex))
    {
        SetCharacterModelIndex(RandomInt(9), player, true);
        wait 0.25;
    }
}

function ShootWhileSprinting(player)
{
    if(!player HasPerk("specialty_sprintfire"))
        player SetPerk("specialty_sprintfire");
    else
        player UnSetPerk("specialty_sprintfire");
}

function UnlimitedSprint(player)
{
    if(!player HasPerk("specialty_unlimitedsprint"))
        player SetPerk("specialty_unlimitedsprint");
    else
        player UnSetPerk("specialty_unlimitedsprint");
}

function ServerRespawnPlayer(player)
{
    player endon("disconnect");

    if(player.sessionstate != "spectator")
        return;
    
    if(!IsDefined(level.custom_spawnplayer))
        level.custom_spawnplayer = &zm::spectator_respawn;

    player [[ level.spawnplayer ]]();
    zm::refresh_player_navcard_hud();

    if(IsDefined(level.script) && level.round_number > 6 && player.score < 1500)
    {
        player.old_score = player.score;

        if(IsDefined(level.spectator_respawn_custom_score))
            player [[ level.spectator_respawn_custom_score ]]();

        player.score = 1500;
    }

    if(player isInMenu(true))
        player closeMenu1();
}

function PlayerRevive(player)
{
    if(!player isDown())
        return;

    player zm_laststand::auto_revive(player);
}

function PlayerDeath(type, player)
{
    player endon("disconnect");

    if(!Is_Alive(player))
        return self iPrintlnBold("^1ERROR: ^7Player Isn't Alive");
    
    if(Is_True(player.playerGodmode))
        player Godmode(player);

    if(Is_True(player.PlayerDemiGod))
        player DemiGod(player);
    
    player DisableInvulnerability(); //Just to ensure that the player is able to be damaged.
    
    switch(type)
    {
        case "Down":
            if(player IsDown())
                return self iPrintlnBold("^1ERROR: ^7Player Is Already Down");
            
            player DoDamage(player.health + 999, (0, 0, 0));
            break;
        
        case "Kill":
            if(level.players.size < 2 && (player HasPerk("specialty_quickrevive") || player zm_perks::has_perk_paused("specialty_quickrevive")))
            {
                player notify("specialty_quickrevive_stop");
                wait 0.5;
            }

            if(!player IsDown())
            {
                player DoDamage(player.health + 999, (0, 0, 0));
                wait 0.25;
            }
            
            if(player IsDown() && level.players.size > 1)
            {
                player notify("bled_out");
                player zm_laststand::bleed_out();
            }
            break;
        
        default:
            break;
    }
}

// ============================================================
// Functions/bullet.gsc
// ============================================================

function PopulateBulletMenu(menu, player)
{
    switch(menu)
    {
        case "Bullet Menu":
            self addMenu(menu);
                self addOpt("Projectiles", &newMenu, "Weapon Projectiles");
                self addOpt("Equipment", &newMenu, "Equipment Bullets");
                self addOpt("Effects", &newMenu, "Bullet Effects");
                self addOpt("Spawnables", &newMenu, "Bullet Spawnables");
                self addOpt("Explosive Bullets", &newMenu, "Explosive Bullets");
                self addOpt("Reset", &ResetBullet, player);
            break;
        
        case "Weapon Projectiles":
            if(!IsDefined(player.ProjectileMultiplier))
                player.ProjectileMultiplier = 1;
            
            if(!IsDefined(player.ProjectileSpreadMultiplier))
                player.ProjectileSpreadMultiplier = 1;
            
            self addMenu("Projectiles");
                self addOptIncSlider("Projectile Multiplier", &ProjectileMultiplier, 1, 1, 3, 1, player);
                self addOptIncSlider("Spread Multiplier", &ProjectileSpreadMultiplier, 1, 1, 50, 1, player);
                self addOpt("");

                if(IsVerkoMap())
                {
                    for(a = 0; a < level.var_21b77150.size; a++)
                        self addOpt(level.var_7df703ba[a], &BulletProjectile, GetWeapon(level.var_21b77150[a]), "Projectile", player);
                }
                else
                {
                    arr = [];
                    weaps = GetArrayKeys(level.zombie_weapons);
                    weaponsVar = Array("assault", "smg", "lmg", "sniper", "cqb", "pistol", "launcher", "special");

                    if(IsDefined(weaps) && weaps.size)
                    {
                        for(a = 0; a < weaps.size; a++)
                        {
                            if(IsInArray(weaponsVar, ToLower(CleanString(zm_utility::GetWeaponClassZM(weaps[a])))) && !weaps[a].isgrenadeweapon && !IsSubStr(weaps[a].name, "knife") && weaps[a].name != "none")
                            {
                                strng = ((MakeLocalizedString(weaps[a].displayname) != "") ? weaps[a].displayname : weaps[a].name);
                                
                                if(!IsInArray(arr, strng))
                                {
                                    arr[arr.size] = strng;
                                    upgrade = zm_weapons::get_upgrade_weapon(weaps[a], 1);

                                    self addOptSlider(strng, &ProjectileWeaponSelection, (!IsDefined(upgrade) ? Array("Base Weapon") : Array("Base Weapon", "Upgraded")), weaps[a], player);
                                }
                            }
                        }
                    }
                }
            break;
        
        case "Equipment Bullets":

            if(IsDefined(level.zombie_include_equipment))
                include_equipment = GetArrayKeys(level.zombie_include_equipment);
            
            equipment = ArrayCombine(level.zombie_lethal_grenade_list, level.zombie_tactical_grenade_list, 0, 1);
            keys = GetArrayKeys(equipment);

            self addMenu("Equipment");

                if(IsDefined(keys) && keys.size || IsDefined(include_equipment) && include_equipment.size)
                {
                    foreach(weapon in GetArrayKeys(level.zombie_weapons))
                    {
                        if(IsSubStr(weapon.name, "shield"))
                            continue;
                        
                        if(isInArray(equipment, weapon))
                            self addOpt(weapon.displayname, &BulletProjectile, weapon, "Equipment", player);
                    }
                    

                    if(IsDefined(include_equipment) && include_equipment.size)
                    {
                        foreach(weapon in include_equipment)
                        {
                            if(IsSubStr(weapon.name, "shield"))
                                continue;

                            self addOpt(weapon.displayname, &BulletProjectile, weapon, "Equipment", player);
                        }
                    }
                }
            break;
        
        case "Bullet Effects":
            self addMenu("Effects");

                for(a = 0; a < level.menuFX.size; a++)
                    self addOpt(CleanString(level.menuFX[a]), &BulletProjectile, level.menuFX[a], "Effect", player);
            break;
        
        case "Bullet Spawnables":
            self addMenu("Spawnables");

                if(IsDefined(level.menu_models) && level.menu_models.size)
                {
                    for(a = 0; a < level.menu_models.size; a++)
                        self addOpt(CleanString(level.menu_models[a]), &BulletProjectile, level.menu_models[a], "Spawnable", player);
                }
            break;
        
        case "Explosive Bullets":
            if(!IsDefined(player.ExplosiveBulletsRange))
                player.ExplosiveBulletsRange = 250;
            
            if(!IsDefined(player.ExplosiveBulletsDamage))
                player.ExplosiveBulletsDamage = 100;
            
            self addMenu(menu);
                self addOptBool(player.ExplosiveBullets, "Explosive Bullets", &ExplosiveBullets, player);
                self addOptBool(player.ExplosiveBulletEffect, "Effect", &ExplosiveBulletEffect, player);
                self addOptIncSlider("Range", &ExplosiveBulletRange, 25, 250, 500, 25, player);
                self addOptIncSlider("Damage", &ExplosiveBulletDamage, 25, 100, 500, 25, player);
            break;
    }
}

function ProjectileWeaponSelection(type, weapon, player)
{
    if(!IsDefined(type) || !IsDefined(weapon))
        return;
    
    if(type == "Upgraded")
    {
        upgrade_weapon = zm_weapons::get_upgrade_weapon(weapon, 1);
        
        if(!IsDefined(upgrade_weapon))
            return;
        
        weapon = upgrade_weapon;
    }
    
    BulletProjectile(weapon, "Projectile", player);
}

function BulletProjectile(projectile, type, player)
{
    player notify("endProjectile");
    player endon("endProjectile");
    player endon("disconnect");
    
    while(1)
    {
        player waittill("weapon_fired");

        start = player GetWeaponMuzzlePoint();

        if(!IsDefined(start) || !IsVec(start))
            start = player GetEye();
        
        fwdDir = player GetWeaponForwardDir();
        
        if(!IsDefined(fwdDir) || !IsVec(fwdDir))
            fwdDir = AnglesToForward(player GetPlayerAngles());

        switch(type)
        {
            case "Projectile":
                for(a = 0; a < player.ProjectileMultiplier; a++)
                    MagicBullet(projectile, start, BulletTrace(start, start + fwdDir * 100, 0, undefined)["position"] + (RandomFloatRange((-1 * player.ProjectileSpreadMultiplier), player.ProjectileSpreadMultiplier), RandomFloatRange((-1 * player.ProjectileSpreadMultiplier), player.ProjectileSpreadMultiplier), RandomFloatRange((-1 * player.ProjectileSpreadMultiplier), player.ProjectileSpreadMultiplier)), player);
                break;
            
            case "Equipment":
                player MagicGrenadeType(projectile, start, VectorScale(fwdDir, 3000), 1);
                break;
            
            case "Spawnable":
                bspawn = SpawnScriptModel(player TraceBullet(), projectile);

                if(IsDefined(bspawn))
                {
                    bspawn NotSolid();
                    bspawn thread deleteAfter(5);
                }
                break;
            
            case "Effect":
                impactfx = SpawnScriptModel(player TraceBullet(), "tag_origin");
                
                if(IsDefined(impactfx))
                {
                    PlayFXOnTag(level._effect[projectile], impactfx, "tag_origin");
                    impactfx thread deleteAfter(0.5);
                }
                break;
            
            default:
                break;
        }
    }
}

function ProjectileMultiplier(multiplier, player)
{
    player.ProjectileMultiplier = multiplier;
}

function ProjectileSpreadMultiplier(multiplier, player)
{
    player.ProjectileSpreadMultiplier = multiplier;
}

function ExplosiveBullets(player)
{
    player endon("disconnect");
    player endon("EndExplosiveBullets");
    
    player.ExplosiveBullets = BoolVar(player.ExplosiveBullets);

    if(Is_True(player.ExplosiveBullets))
    {
        while(Is_True(player.ExplosiveBullets))
        {
            player waittill("weapon_fired");

            if(Is_True(player.ExplosiveBulletEffect))
            {
                if(IsDefined(level._effect["raps_impact"]))
                    PlayFX(level._effect["raps_impact"], player TraceBullet());
                else if(IsDefined(level._effect["dog_gib"]))
                    PlayFX(level._effect["dog_gib"], player TraceBullet());
            }

            RadiusDamage(player TraceBullet(), player.ExplosiveBulletsRange, player.ExplosiveBulletsDamage, player.ExplosiveBulletsDamage, player);
        }
    }
    else
    {
        player notify("EndExplosiveBullets");
    }
}

function ExplosiveBulletEffect(player)
{
    player.ExplosiveBulletEffect = BoolVar(player.ExplosiveBulletEffect);
}

function ExplosiveBulletDamage(num, player)
{
    player.ExplosiveBulletsDamage = num;
}

function ExplosiveBulletRange(num, player)
{
    player.ExplosiveBulletsRange = num;
}

function ResetBullet(player)
{
    player notify("endProjectile");
    player notify("EndExplosiveBullets");

    if(Is_True(player.ExplosiveBullets))
        player.ExplosiveBullets = BoolVar(player.ExplosiveBullets);
}

// ============================================================
// Functions/entity_options.gsc
// ============================================================

function PopulateEntityOptions(menu)
{
    switch(menu)
    {
        case "Entity Options":
            self addMenu(menu);
                
                if(IsDefined(level.menu_entities) && level.menu_entities.size)
                {
                    self addOpt("Entity Editing List", &newMenu, "Entity Editing List");
                    self addOptBool(AllEntitiesInvisible(), "Invisibility", &EntitiesInvisibility);
                    self addOpt("Delete", &DeleteEntities);
                    self addOpt("Rotation", &newMenu, "Entities Rotation");
                    self addOptIncSlider("Scale", &EntitiesScale, 0.5, 1, 10, 0.5);
                    self addOptSlider("Teleport", &TeleportEntities, Array("To Self", "To Crosshairs"));
                    self addOpt("Reset Origin", &EntitiesResetOrigins);
                }
            break;

        case "Entity Editing List":
            self addMenu(menu);

                if(IsDefined(level.menu_entities) && level.menu_entities.size)
                {
                    for(a = 0; a < level.menu_entities.size; a++)
                    {
                        if(IsDefined(level.menu_entities[a]) && IsDefined(level.menu_entities[a].model) && level.menu_entities[a].model != "")
                            self addOpt(CleanString(level.menu_entities[a].model), &newMenu, "Entity Editor", false, a);
                    }
                }
            break;

        case "Entity Editor":            
            self addMenu(CleanString(level.menu_entities[self.EntityEditorNumber].model));
                self addOpt("Delete", &DeleteEntity, level.menu_entities[self.EntityEditorNumber]);
                self addOptBool(level.menu_entities[self.EntityEditorNumber].Invisibility, "Invisibility", &EntityInvisibility, level.menu_entities[self.EntityEditorNumber]);
                self addOpt("Rotation", &newMenu, "Entity Rotation", false, self.EntityEditorNumber);
                self addOptIncSlider("Scale", &EntityScale, 0.5, 1, 10, 0.5, level.menu_entities[self.EntityEditorNumber]);
                self addOptSlider("Teleport", &TeleportEntity, Array("To Self", "To Entity", "To Crosshairs"), level.menu_entities[self.EntityEditorNumber]);
                self addOpt("Reset Origin", &EntityResetOrigin, level.menu_entities[self.EntityEditorNumber]);
            break;

        case "Entity Rotation":
            self addMenu("Rotation");
                self addOpt("Reset", &EntityResetAngles, level.menu_entities[self.EntityEditorNumber]);
                self addOptIncSlider("Pitch", &EntityRotation, -10, 0, 10, 1, "Pitch", level.menu_entities[self.EntityEditorNumber]);
                self addOptIncSlider("Yaw", &EntityRotation, -10, 0, 10, 1, "Yaw", level.menu_entities[self.EntityEditorNumber]);
                self addOptIncSlider("Roll", &EntityRotation, -10, 0, 10, 1, "Roll", level.menu_entities[self.EntityEditorNumber]);
            break;

        case "Entities Rotation":
            self addMenu("Rotation");
                self addOpt("Reset", &EntitiesResetAngles);
                self addOptIncSlider("Pitch", &EntitiesRotation, -10, 0, 10, 1, "Pitch");
                self addOptIncSlider("Yaw", &EntitiesRotation, -10, 0, 10, 1, "Yaw");
                self addOptIncSlider("Roll", &EntitiesRotation, -10, 0, 10, 1, "Roll");
            break;
    }
}

function DeleteEntity(ent)
{
    if(!IsDefined(ent) || !IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    isLast = level.menu_entities.size <= 1;
    level.menu_entities = (isLast ? undefined : ArrayRemove(level.menu_entities, ent));
    self newMenu((isLast ? "Main" : undefined));
    ent Delete();
}

function EntityInvisibility(ent)
{
    if(!IsDefined(ent) || !IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;

    ent.Invisibility = BoolVar(ent.Invisibility);

    if(Is_True(ent.Invisibility))
        ent Hide();
    else
        ent Show();
}

function EntityScale(scale, ent)
{
    if(!IsDefined(ent) || !IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    ent SetScale(scale);
}

function EntityResetAngles(ent)
{
    if(!IsDefined(ent) || !IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    ent RotateTo(ent.savedAngles, 0.01);
}

function EntityRotation(value, type, ent)
{
    if(!IsDefined(ent) || !IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    switch(type)
    {
        case "Pitch":
            ent RotatePitch(value, 0.2);
            break;
        
        case "Yaw":
            ent RotateYaw(value, 0.2);
            break;
        
        case "Roll":
            ent RotateRoll(value, 0.2);
            break;
        
        default:
            break;
    }
}

function TeleportEntity(location, ent)
{
    if(!IsDefined(ent) || !IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    switch(location)
    {
        case "To Self":
            ent.origin = self.origin;
            break;
        
        case "To Crosshairs":
            ent.origin = self TraceBullet();
            break;
        
        case "To Entity":
            self SetOrigin(ent.origin);
            break;
        
        default:
            break;
    }
}

function EntityResetOrigin(ent)
{
    if(!IsDefined(ent) || !IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    ent.origin = ent.savedOrigin;
}

function EntitiesInvisibility()
{
    if(!IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    level.EntitiesInvisibility = BoolVar(level.EntitiesInvisibility);
    
    foreach(ent in level.menu_entities)
    {
        if(!IsDefined(ent))
            continue;
        
        if(Is_True(level.EntitiesInvisibility))
        {
            if(!Is_True(ent.Invisibility))
                EntityInvisibility(ent);
        }
        else
        {
            if(Is_True(ent.Invisibility))
                EntityInvisibility(ent);
        }
    }
}

function AllEntitiesInvisible()
{
    if(!IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    foreach(ent in level.menu_entities)
    {
        if(IsDefined(ent) && !Is_True(ent.Invisibility))
            return false;
    }
    
    return true;
}

function DeleteEntities()
{
    if(!IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    foreach(ent in level.menu_entities)
    {
        if(IsDefined(ent))
            ent Delete();
    }
    
    level.menu_entities = undefined;
    self newMenu("Main");
}

function EntitiesScale(scale)
{
    if(!IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    foreach(ent in level.menu_entities)
    {
        if(IsDefined(ent))
            ent SetScale(scale);
    }
}

function EntitiesResetAngles()
{
    if(!IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    foreach(ent in level.menu_entities)
    {
        if(IsDefined(ent))
            ent RotateTo(ent.savedAngles, 0.01);
    }
}

function EntitiesRotation(value, type)
{
    if(!IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    switch(type)
    {
        case "Pitch":
            foreach(ent in level.menu_entities)
            {
                if(IsDefined(ent))
                    ent RotatePitch(value, 0.2);
            }
            break;
        
        case "Yaw":
            foreach(ent in level.menu_entities)
            {
                if(IsDefined(ent))
                    ent RotateYaw(value, 0.2);
            }
            break;
        
        case "Roll":
            foreach(ent in level.menu_entities)
            {
                if(IsDefined(ent))
                    ent RotateRoll(value, 0.2);
            }
            break;
        
        default:
            break;
    }
}

function TeleportEntities(location)
{
    if(!IsDefined(level.menu_entities) || IsDefined(level.menu_entities) && !level.menu_entities.size)
        return;

    origin = ((IsDefined(location) && location == "To Self") ? self.origin : self TraceBullet());

    foreach(ent in level.menu_entities)
    {
        if(IsDefined(ent))
            ent.origin = origin;
    }
}

function EntitiesResetOrigins()
{
    if(!isDefined(level.menu_entities) || isDefined(level.menu_entities) && !level.menu_entities.size)
        return;
    
    foreach(ent in level.menu_entities)
    {
        if(IsDefined(ent))
            ent.origin = ent.savedOrigin;
    }
}

// ============================================================
// Functions/forge.gsc
// ============================================================

function PopulateForgeOptions(menu)
{
    switch(menu)
    {
        case "Forge Options":
            if(!IsDefined(self.forgeModelDistance))
                self.forgeModelDistance = 200;
            
            if(!IsDefined(self.forgeModelScale))
                self.forgeModelScale = 1;
            
            self addMenu(menu);
                self addOpt("Spawn", &newMenu, "Spawn Script Model");
                self addOptIncSlider("Scale", &ForgeModelScale, 0.5, 1, 10, 0.5);
                self addOpt("Place", &ForgePlaceModel);
                self addOpt("Copy", &ForgeCopyModel);
                self addOpt("Rotate", &newMenu, "Rotate Script Model");
                self addOpt("Delete", &ForgeDeleteModel);
                self addOpt("Drop", &ForgeDropModel);
                self addOptIncSlider("Distance", &ForgeModelDistance, 100, 200, 500, 25);
                self addOptBool(self.forgeignoreCollisions, "Ignore Collisions", &ForgeIgnoreCollisions);
                self addOpt("Delete Last Spawn", &ForgeDeleteLastSpawn);
                self addOpt("Delete All Spawned", &ForgeDeleteAllSpawned);
                self addOptBool(self.ForgeShootModel, "Shoot Model", &ForgeShootModel);
            break;
        
        case "Spawn Script Model":
            self addMenu("Spawn");

                if(IsDefined(level.menu_models) && level.menu_models.size)
                {
                    for(a = 0; a < level.menu_models.size; a++)
                        self addOpt(CleanString(level.menu_models[a]), &ForgeSpawnModel, level.menu_models[a]);
                }
            break;
        
        case "Rotate Script Model":
            self addMenu("Rotate");
                self addOpt("Reset", &ForgeRotateModel, 0, "Reset");
                self addOptIncSlider("Roll", &ForgeRotateModel, -10, 0, 10, 1, "Roll");
                self addOptIncSlider("Yaw", &ForgeRotateModel, -10, 0, 10, 1, "Yaw");
                self addOptIncSlider("Pitch", &ForgeRotateModel, -10, 0, 10, 1, "Pitch");
            break;
    }
}

function ForgeSpawnModel(model)
{
    if(Is_True(self.ForgeShootModel))
        self ForgeShootModel();
    
    if(!IsDefined(self.forgeSpawnedArray))
        self.forgeSpawnedArray = [];
    
    if(IsDefined(self.forgemodel))
        self.forgemodel Delete();
    
    self.forgemodel = SpawnScriptModel(self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), self.forgeModelDistance), model, (0, 0, 0));

    if(IsDefined(self.forgemodel))
        self.forgemodel SetScale(self.forgeModelScale);
    
    self thread ForgeCarryModel();
}

function ForgeCarryModel()
{
    self notify("EndCarryModel");
    self endon("EndCarryModel");
    
    self endon("disconnect");
    
    while(IsDefined(self.forgemodel))
    {
        self.forgemodel MoveTo((Is_True(self.forgeignoreCollisions) ? self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), self.forgeModelDistance) : BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), self.forgeModelDistance), false, self.forgemodel)["position"]), 0.1);
        wait 0.05;
    }
}

function ForgeModelScale(scale)
{
    self.forgeModelScale = scale;

    if(IsDefined(self.forgemodel))
        self.forgemodel SetScale(scale);
}

function ForgePlaceModel()
{
    if(!IsDefined(self.forgemodel))
        return;
    
    if(!IsDefined(self.forgeSpawnedArray))
        self.forgeSpawnedArray = [];
    
    spawn = SpawnScriptModel(self.forgemodel.origin, self.forgemodel.model, self.forgemodel.angles);

    if(IsDefined(spawn))
    {
        self.forgeSpawnedArray[self.forgeSpawnedArray.size] = spawn;
        spawn SetScale(self.forgeModelScale);
    }
    
    self notify("EndCarryModel");
    self.forgemodel Delete();
}

function ForgeCopyModel()
{
    if(!IsDefined(self.forgemodel))
        return;
    
    if(!IsDefined(self.forgeSpawnedArray))
        self.forgeSpawnedArray = [];
    
    spawn = SpawnScriptModel(self.forgemodel.origin, self.forgemodel.model, self.forgemodel.angles);

    if(!IsDefined(spawn))
        return;
    
    self.forgeSpawnedArray[self.forgeSpawnedArray.size] = spawn;
    spawn SetScale(self.forgeModelScale);
}

function ForgeRotateModel(int, type)
{
    if(!IsDefined(self.forgemodel))
        return;
    
    switch(type)
    {
        case "Reset":
            self.forgemodel RotateTo((0, 0, 0), 0.1);
            break;
        
        case "Roll":
            self.forgemodel RotateRoll(int, 0.1);
            break;
        
        case "Yaw":
            self.forgemodel RotateYaw(int, 0.1);
            break;
        
        case "Pitch":
            self.forgemodel RotatePitch(int, 0.1);
            break;
        
        default:
            break;
    }
}

function ForgeDeleteModel()
{
    if(!IsDefined(self.forgemodel))
        return;
    
    self notify("EndCarryModel");
    self.forgemodel Delete();
}

function ForgeDropModel()
{
    if(!IsDefined(self.forgemodel))
        return;
    
    if(!IsDefined(self.forgeSpawnedArray))
        self.forgeSpawnedArray = [];
    
    spawn = SpawnScriptModel(self.forgemodel.origin, self.forgemodel.model, self.forgemodel.angles);

    if(IsDefined(spawn))
    {
        spawn SetScale(self.forgeModelScale);
        self.forgeSpawnedArray[self.forgeSpawnedArray.size] = spawn;
        spawn Launch(VectorScale(AnglesToForward(self GetPlayerAngles()), 10));
    }

    self notify("EndCarryModel");
    self.forgemodel Delete();
}

function ForgeModelDistance(num)
{
    self.forgeModelDistance = num;
}

function ForgeIgnoreCollisions()
{
    self.forgeignoreCollisions = BoolVar(self.forgeignoreCollisions);
}

function ForgeDeleteLastSpawn()
{
    if(!IsDefined(self.forgeSpawnedArray) || IsDefined(self.forgeSpawnedArray) && !self.forgeSpawnedArray.size || !IsDefined(self.forgeSpawnedArray[(self.forgeSpawnedArray.size - 1)]))
        return;
    
    self.forgeSpawnedArray[(self.forgeSpawnedArray.size - 1)] Delete();

    if(self.forgeSpawnedArray.size > 1)
    {
        arry = [];

        for(a = 0; a < (self.forgeSpawnedArray.size - 1); a++)
            arry[arry.size] = self.forgeSpawnedArray[a];
        
        self.forgeSpawnedArray = arry;
    }
    else
    {
        self.forgeSpawnedArray = undefined;
    }
}

function ForgeDeleteAllSpawned()
{
    if(!IsDefined(self.forgeSpawnedArray) || IsDefined(self.forgeSpawnedArray) && !self.forgeSpawnedArray.size)
        return;
    
    for(a = 0; a < self.forgeSpawnedArray.size; a++)
    {
        if(IsDefined(self.forgeSpawnedArray[a]))
            self.forgeSpawnedArray[a] Delete();
    }
    
    self.forgeSpawnedArray = undefined;
}

function ForgeShootModel()
{
    if(!IsDefined(self.forgemodel) && !Is_True(self.ForgeShootModel))
        return;
    
    self endon("disconnect");
    self endon("EndShootModel");
    
    self.ForgeShootModel = BoolVar(self.ForgeShootModel);
    
    if(Is_True(self.ForgeShootModel))
    {
        ent = self.forgemodel.model;
        self ForgeDeleteModel();
        
        while(Is_True(self.ForgeShootModel))
        {
            self waittill("weapon_fired");
            
            spawn = SpawnScriptModel(self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 60), ent);

            if(IsDefined(spawn))
            {
                spawn SetScale(self.forgeModelScale);
                spawn NotSolid();
                
                spawn PhysicsLaunch(spawn.origin, VectorScale(AnglesToForward(self GetPlayerAngles()), 255));
                spawn thread deleteAfter(10);
            }
        }
    }
    else
    {
        self notify("EndShootModel");
    }
}

// ============================================================
// Functions/fun.gsc
// ============================================================

function PopulateFunScripts(menu, player)
{
    switch(menu)
    {
        case "Fun Scripts":
            if(!IsDefined(player.DamagePointsMultiplier))
                player.DamagePointsMultiplier = 1;
            
            self addMenu(menu);
                self addOpt("Earthquake", &SendEarthquake, player);
                self addOpt("Adventure Time", &AdventureTime, player);
                self addOpt("Force Field Options", &newMenu, "Force Field Options");
                self addOpt("Effects Man Options", &newMenu, "Effects Man Options");
                self addOpt("Sounds & Jingles", &newMenu, "Sounds & Jingles");
                self addOpt("Hit Markers", &newMenu, "Hit Markers");
                self addOptSlider("Insta-Kill", &PlayerInstaKill, Array("Disable", "All", "Melee"), player);
                self addOptSlider("Death Skull", &SpawnDeathSkull, Array("Spawn", "Delete All"), player);
                self addOptSlider("Mount Camera", &PlayerMountCamera, Array("Disable", "j_head", "j_neck", "j_spine4", "j_spinelower", "j_mainroot", "pelvis", "j_ankle_le", "j_ankle_ri"), player);
                self addOptSlider("Shoot Power-Ups", &ShootPowerUps, Array("Disable", "Drop", "Apply Physics"), player);
                self addOptBool(player.DropCamera, "Drop Camera", &PlayerDropCamera, player);
                self addOptBool(player.DeadOpsView, "Dead Ops View", &DeadOpsView, player);
                self addOptBool(player.ZombieCounter, "Zombie Counter", &ZombieCounter, player);
                self addOptBool(player.LightProtector, "Light Protector", &LightProtector, player);
                self addOptBool(player.SpecialMovements, "Special Movements", &SpecialMovements, player);
                self addOptBool(player GetPlayerGravity() == 136, "Moon Gravity", &MoonGravity, player);
                self addOptBool(player.IceSkating, "Ice Skating", &IceSkating, player);
                self addOptBool(player.ForgeMode, "Forge Mode", &ForgeMode, player);
                self addOptBool(player.SpecNade, "Spec-Nade", &SpecNade, player);
                self addOptBool(player.NukeNades, "Nuke Nades", &NukeNades, player);
                self addOptBool(player.CodJumper, "Cod Jumper", &CodJumper, player);
                self addOptBool(player.FrogJump, "Frog Jump", &FrogJump, player);
                self addOptBool(player.Jetpack, "Jetpack", &Jetpack, player);
                self addOptBool(player.HealthBar, "Health Bar", &HealthBar, player);
                self addOptBool(player.ClusterGrenades, "Cluster Grenades", &ClusterGrenades, player);
                self addOptBool(player.ElectricFireCherry, "Electric Fire Cherry", &ElectricFireCherry, player);
                self addOptBool(player.HumanCentipede, "Human Centipede", &HumanCentipede, player);
                self addOptBool(player.RocketRiding, "Rocket Riding", &RocketRiding, player);
                self addOptBool(player.GrapplingGun, "Grappling Gun", &GrapplingGun, player);
                self addOptBool(player.GravityGun, "Gravity Gun", &GravityGun, player);
                self addOptBool(player.DeleteGun, "Delete Gun", &DeleteGun, player);
                self addOptBool(player.RapidFire, "Rapid Fire", &RapidFire, player);
                self addOptBool(player.ExtraGore, "Extra Gore", &ExtraGore, player);
                self addOptBool(player HasPerk("specialty_locdamagecountsasheadshot"), "Head Drama", &HeadDrama, player);
                self addOptBool(player.PowerUpMagnet, "Power-Up Magnet", &PowerUpMagnet, player);
                self addOptBool(player.DisableEarningPoints, "Disable Earning Points", &DisableEarningPoints, player);
                self addOptIncSlider("Points Multiplier", &DamagePointsMultiplier, 1, 1, 10, 0.5, player);
            break;
        
        case "Force Field Options":
            if(!IsDefined(player.ForceFieldSize))
                player.ForceFieldSize = 90;
            
            if(!IsDefined(player.ForceFieldType))
                player.ForceFieldType = "Invisible";
            
            self addMenu(menu);
                self addOptBool(player.ForceField, "Force Field", &ForceField, player);
                self addOptIncSlider("Size", &ForceFieldSize, 90, player.ForceFieldSize, 500, 10, player);
                self addOptSlider("Type", &ForceFieldType, Array("Invisible", "Death Skulls", "Light"), player);
            break;
        
        case "Effects Man Options":
            if(!IsDefined(player.EffectManTag))
                player.EffectManTag = "j_head";

            self addMenu(menu);
                self addOptBool(!IsDefined(player.EffectMan), "Disable", &DisableEffectMan, player);
                self addOptSlider("Tag", &SetEffectManTag, Array("j_head", "j_neck", "j_spine4", "j_spinelower", "j_mainroot", "pelvis", "j_ankle_ri", "j_ankle_le"), player);
                self addOpt("");

                for(a = 0; a < level.menuFX.size; a++)
                    self addOptBool((IsDefined(player.SavedFX) && player.SavedFX == level._effect[level.menuFX[a]]), CleanString(level.menuFX[a]), &EffectMan, level._effect[level.menuFX[a]], player);
            break;
        
        case "Hit Markers":
            if(!IsDefined(player.HitmarkerFeedback))
                player.HitmarkerFeedback = "damage_feedback";
            
            if(!IsDefined(player.HitMarkerColor))
                player.HitMarkerColor = (255, 255, 255);
            
            self addMenu(menu);
                self addOptBool(player.ShowHitmarkers, "Hit Markers", &ShowHitmarkers, player);
                self addOptSlider("Hit Marker Sound", &HitmarkerSound, Array("None", "fly_melee_lunge_victim_bat", "fly_melee_lunge_victim_pistol", "fly_melee_lunge_rifle", "fly_melee_lunge_victim_knife", "fly_melee_lunge_victim_nunchucks"), player);
                self addOptSlider("Feedback", &HitmarkerFeedback, Array("damage_feedback", "damage_feedback_glow_orange", "damage_feedback_flak", "damage_feedback_tac", "damage_feedback_armor"), player);
                self addOpt("");

                for(a = 0; a < GetColorNames().size; a++)
                    self addOptBool((IsVec(player.HitMarkerColor) && player.HitMarkerColor == GetColorValues()[a]), GetColorNames()[a], &HitMarkerColor, GetColorValues()[a], player);
                
                self addOptBool((IsString(player.HitMarkerColor) && player.HitMarkerColor == "Rainbow"), "Smooth Rainbow", &HitMarkerColor, "Rainbow", player);
            break;
        
        case "Sounds & Jingles":
            MenuVOXCategory = [];

            foreach(category, sound in level.sndplayervox)
                array::add(MenuVOXCategory, CleanString(category, true), 0);

            self addMenu(menu);
                self addOpt("Perk Jingles & Quotes", &newMenu, "Perk Jingles & Quotes");

                for(a = 0; a < MenuVOXCategory.size; a++)
                    self addOpt(MenuVOXCategory[a], &newMenu, MenuVOXCategory[a]);
            break;
        
        case "Perk Jingles & Quotes":
            perkArray = [];
            vendings = GetEntArray("zombie_vending", "targetname");

            self addMenu(menu);
                
                for(a = 0; a < vendings.size; a++)
                {
                    if(!IsDefined(vendings[a]))
                        continue;
                    
                    perkName = vendings[a].script_noteworthy;

                    if(isInArray(perkArray, perkName))
                        continue;
                    
                    self addOpt(ReturnPerkName(CleanString(vendings[a].script_noteworthy)) + " Jingle", &PlayPerkMachineSound, vendings[a].script_sound, player);
                    self addOpt(ReturnPerkName(CleanString(vendings[a].script_noteworthy)) + " Quote", &PlayPerkMachineSound, vendings[a].script_label, player);

                    perkArray[perkArray.size] = perkName;
                }
            break;
        
        default:
            MenuVOXCategory = [];
            
            foreach(category, sound in level.sndplayervox)
                array::add(MenuVOXCategory, CleanString(category, true), 0);
            
            if(isInArray(MenuVOXCategory, menu))
            {
                self addMenu(menu);

                foreach(category, sound in level.sndplayervox)
                {
                    if(CleanString(category, true) != menu)
                        continue;
                    
                    foreach(subcategory, vox in level.sndplayervox[category]) self addOpt((IsSubStr(subcategory, "specialty") ? ReturnPerkName(CleanString(subcategory)) : CleanString(subcategory, true)), &create_and_play_dialog, category, subcategory, player);
                }
            }
            break;
    }
}

function SendEarthquake(player)
{
    Earthquake(1, 15, player.origin, 750);
}

function AdventureTime(player)
{
    if(Is_True(player.AdventureTime))
        return;

    if(player isPlayerLinked())
        return self iPrintlnBold("^1ERROR: ^7Player Is Linked To An Entity");

    player endon("disconnect");

    player.AdventureTime = true;

    origin = player.origin;
    model = SpawnScriptModel(player.origin, "test_sphere_silver", (0, player.angles[1], 0));

    model SetScale(7);
    player PlayerLinkTo(model);

    for(a = 0; a < 10; a++)
    {
        newOrigin = origin + (RandomIntRange(-7500, 7500), RandomIntRange(-7500, 7500), RandomIntRange(1000, 5500));
        model MoveTo(newOrigin, 1.5);

        wait 3;
    }

    model MoveTo(origin, 3);
    wait 3.5;

    player Unlink();
    model Delete();

    if(Is_True(player.AdventureTime))
        player.AdventureTime = BoolVar(player.AdventureTime);
}

function ForceField(player)
{
    player.ForceField = BoolVar(player.ForceField);

    if(Is_True(player.ForceField))
    {
        player endon("disconnect");

        if(!IsDefined(player.ForceFieldEnts))
            player.ForceFieldEnts = [];
        
        if(!player.ForceFieldEnts.size)
        {
            color = Pow(2, RandomInt(3));

            if(!IsDefined(player.ForceFieldLinker))
                player.ForceFieldLinker = SpawnScriptModel(player.origin);
            
            player.ForceFieldLinker thread ForceFieldLinker();
            player.ForceFieldLinker LinkTo(player);
            
            for(a = 0; a < 4; a++)
            {
                player.ForceFieldEnts[player.ForceFieldEnts.size] = SpawnScriptModel(player.origin + (Cos(a * 90) * player.ForceFieldSize, Sin(a * 90) * player.ForceFieldSize, 30), ((player.ForceFieldType == "Death Skulls") ? level.zombie_powerups["insta_kill"].model_name : "tag_origin"), (0, (a * 90), 0));
                player.ForceFieldEnts[(player.ForceFieldEnts.size - 1)] clientfield::set("powerup_fx", Int(color));
                player.ForceFieldEnts[(player.ForceFieldEnts.size - 1)] LinkTo(player.ForceFieldLinker);

                if(player.ForceFieldType == "Invisible")
                    player.ForceFieldEnts[(player.ForceFieldEnts.size - 1)] SetInvisibleToAll();
            }
        }

        while(Is_True(player.ForceField))
        {
            zombies = GetAITeamArray(level.zombie_team);

            for(a = 0; a < zombies.size; a++)
            {
                if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]))
                    continue;
                
                kill = false;

                for(b = 0; b < player.ForceFieldEnts.size; b++)
                {
                    if(zombies[a] IsTouching(player.ForceFieldEnts[b]))
                        kill = true;
                }

                if(Distance(player.origin, zombies[a].origin) <= player.ForceFieldSize && zombies[a] DamageConeTrace(player GetEye(), player) > 0.1 || kill)
                {
                    zombies[a].ZombieFling = true;
                    zombies[a] DoDamage((zombies[a].health + 666), player.origin);
                }
            }

            wait 0.01;
        }

        if(IsDefined(player.ForceFieldLinker))
            player.ForceFieldLinker Delete();
        
        if(IsDefined(player.ForceFieldEnts) && player.ForceFieldEnts.size)
        {
            for(a = 0; a < player.ForceFieldEnts.size; a++)
            {
                if(IsDefined(player.ForceFieldEnts[a]))
                    player.ForceFieldEnts[a] Delete();
            }

            player.ForceFieldEnts = [];
        }
    }
}

function ForceFieldLinker()
{
    if(!IsDefined(self))
        return;
    
    while(IsDefined(self))
    {
        self RotateYaw(360, 1.5);
        wait 1.5;
    }
}

function ForceFieldSize(num, player)
{
    player.ForceFieldSize = num;

    if(Is_True(player.ForceField))
    {
        for(a = 0; a < 2; a++)
        {
            ForceField(player);
            wait 0.1;
        }
    }
}

function ForceFieldType(type, player)
{
    if(player.ForceFieldType == type)
        return;
    
    player.ForceFieldType = type;

    if(Is_True(player.ForceField) && IsDefined(player.ForceFieldEnts) && player.ForceFieldEnts.size)
    {
        for(a = 0; a < player.ForceFieldEnts.size; a++)
        {
            if(IsDefined(player.ForceFieldEnts[a]))
            {
                player.ForceFieldEnts[a] SetModel(((player.ForceFieldType == "Death Skulls") ? level.zombie_powerups["insta_kill"].model_name : "tag_origin"));
                
                if(type == "Invisible") //This will hide the power up fx that is applied to the spawned model
                    player.ForceFieldEnts[a] SetInvisibleToAll();
                else
                    player.ForceFieldEnts[a] SetVisibleToAll();
            }
        }
    }
}

function EffectMan(fx, player)
{
    if(IsDefined(player.SavedFX) && player.SavedFX == fx)
    {
        DisableEffectMan(player);
        return;
    }

    player notify("EndEffectMan");
    player endon("EndEffectMan");
    player endon("disconnect");

    player.EffectMan = true;

    if(IsDefined(player.fxent))
        player.fxent Delete();

    wait 0.05;
    player.SavedFX = fx;
    player.SavedFXTag = player.EffectManTag;

    while(IsDefined(player.EffectMan))
    {
        player.fxent = SpawnFX(player.SavedFX, player GetTagOrigin(player.SavedFXTag));

        if(IsDefined(player.fxent))
            TriggerFX(player.fxent);
        wait 0.1;

        if(IsDefined(player.fxent))
            player.fxent Delete();

        wait 0.2;
    }
}

function SetEffectManTag(tag, player)
{
    player.EffectManTag = tag;
    player.EffectMan = undefined;

    if(IsDefined(player.SavedFX))
        player thread EffectMan(player.SavedFX, player);
}

function DisableEffectMan(player)
{
    player notify("EndEffectMan");
    player.EffectMan = undefined;

    if(IsDefined(player.fxent))
        player.fxent Delete();

    wait 0.05;
    player.SavedFX = undefined;
}

function PlayPerkMachineSound(sound, player)
{
    player notify("sndDone");
	player PlaySoundWithNotify(sound, "sndDone");
}

function create_and_play_dialog(category, subcategory, player)
{
    player zm_audio::create_and_play_dialog(category, subcategory);
}

function ShowHitmarkers(player)
{
    player.ShowHitmarkers = BoolVar(player.ShowHitmarkers);
}

function HitmarkerSound(snd, player)
{
    player.HitmarkerFeedbackSound = snd;
}

function HitmarkerFeedback(feedback, player)
{
    player.HitmarkerFeedback = feedback;

    if(IsDefined(player.hud_damagefeedback))
        player.hud_damagefeedback SetShaderValues(player.HitmarkerFeedback, 24, 48);
}

function HitMarkerColor(color, player)
{
    player.HitMarkerColor = color;

    if(IsDefined(player.hud_damagefeedback) && IsVec(color))
        player.hud_damagefeedback.color = GetColorVec(color);
}

function PlayerInstaKill(type, player)
{
    player.PlayerInstaKill = ((type != "Disable") ? type : undefined);
}

function SpawnDeathSkull(action, player)
{
    switch(action)
    {
        case "Spawn":
            if(!IsDefined(player.DeathSkullEnts))
                player.DeathSkullEnts = [];

            linkedSkulls = [];
            color = Pow(2, RandomInt(3));
            linkerIndex = player.DeathSkullEnts.size;
            player.DeathSkullEnts[player.DeathSkullEnts.size] = SpawnScriptModel(player.origin);
            
            for(a = 0; a < 4; a++)
            {
                player.DeathSkullEnts[player.DeathSkullEnts.size] = SpawnScriptModel(player.origin + (Cos(a * 90) * 35, Sin(a * 90) * 35, 45), level.zombie_powerups["insta_kill"].model_name, (0, (a * 90), 0));
                player.DeathSkullEnts[(player.DeathSkullEnts.size - 1)] clientfield::set("powerup_fx", Int(color));
                player.DeathSkullEnts[(player.DeathSkullEnts.size - 1)] LinkTo(player.DeathSkullEnts[linkerIndex]);

                linkedSkulls[linkedSkulls.size] = player.DeathSkullEnts[(player.DeathSkullEnts.size - 1)];
            }

            player.DeathSkullEnts[linkerIndex] thread DeathSkullLinker(linkedSkulls, player);
            break;
        
        case "Delete All":
            if(!IsDefined(player.DeathSkullEnts) || !player.DeathSkullEnts.size)
                return;
            
            for(a = 0; a < player.DeathSkullEnts.size; a++)
            {
                if(IsDefined(player.DeathSkullEnts[a]))
                    player.DeathSkullEnts[a] Delete();
            }
            
            player.DeathSkullEnts = [];
            break;
        
        default:
            break;
    }
}

function DeathSkullLinker(skulls, player)
{
    if(!IsDefined(self))
        return;
    
    self endon("death");
    
    while(IsDefined(self))
    {
        if(IsDefined(skulls) && skulls.size && IsDefined(level._effect["tesla_bolt"]))
        {
            for(a = 0; a < skulls.size; a++)
            {
                if(IsDefined(skulls[a]))
                    PlayFXOnTag(level._effect["tesla_bolt"], skulls[a], "tag_origin");
            }
        }

        self MoveZ(25, 5);

        for(a = 0; a < 20; a++)
        {
            self RotateYaw(360, 0.25);
            wait 0.25;
        }
        
        for(a = 0; a < 5; a++)
        {
            foreach(skull in skulls)
                skull SetInvisibleToAll();
            
            wait 0.1;

            foreach(skull in skulls)
                skull SetVisibleToAll();
            
            wait 0.1;
        }

        wait 0.5;
        self MoveZ(-25, 0.1);

        wait 0.1;
        Earthquake(0.75, 2, self.origin, 255);
        RadiusDamage(self.origin, 350, 999, 999, player);

        if(IsDefined(level._effect["raps_impact"]))
            PlayFX(level._effect["raps_impact"], self.origin);
        else if(IsDefined(level._effect["dog_gib"]))
            PlayFX(level._effect["dog_gib"], self.origin);
        
        PlayFX(level._effect["grenade_samantha_steal"], self.origin);
        PlayFX(level._effect["poltergeist"], self.origin);
        PlayFX("zombie/fx_powerup_nuke_zmb", self.origin);
        wait 1;
    }
}

function PlayerMountCamera(tag, player)
{
    player endon("disconnect");

    if(Is_True(player.SpecNade) && !Is_True(player.PlayerMountCamera))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Spec-Nade Is Enabled");
    
    if(Is_True(player.DropCamera) && !Is_True(player.PlayerMountCamera))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Drop Camera Is Enabled");
    
    if(Is_True(player.DeadOpsView) && !Is_True(player.PlayerMountCamera))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Dead Ops View Is Enabled");
    
    if(tag != "Disable")
    {
        tagOrigin = player GetTagOrigin(tag);

        if(!IsDefined(tagOrigin))
            return self iPrintlnBold("^1ERROR: ^7Couldn't Find Tag On Player");
        
        if(Is_True(player.PlayerMountCamera))
            PlayerMountCamera("Disable", player);
    }

    player.PlayerMountCamera = BoolVar(player.PlayerMountCamera);
    
    if(tag != "Disable")
    {
        player.camlinker = SpawnScriptModel(tagOrigin + (AnglesToForward(player GetPlayerAngles()) * 9), "tag_origin");

        if(!IsDefined(player.camlinker))
        {
            player.PlayerMountCamera = undefined;
            return;
        }

        player.camlinker LinkToBlendToTag(player, tag);

        player CameraSetPosition(player.camlinker);
        player CameraActivate(true);
    }
    else
    {
        player CameraActivate(false);
        
        if(IsDefined(player.camlinker))
            player.camlinker Delete();
    }
}

function PlayerDropCamera(player)
{
    player endon("disconnect");
    
    if(Is_True(player.SpecNade) && !Is_True(player.DropCamera))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Spec-Nade Is Enabled");
    
    if(Is_True(player.PlayerMountCamera) && !Is_True(player.DropCamera))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Mount Camera Is Enabled");
    
    if(Is_True(player.DeadOpsView) && !Is_True(player.DropCamera))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Dead Ops View Is Enabled");
    
    player.DropCamera = BoolVar(player.DropCamera);
    
    if(Is_True(player.DropCamera))
    {
        player.camlinker = SpawnScriptModel(player GetTagOrigin("j_head"), "tag_origin");

        if(!IsDefined(player.camlinker))
        {
            player.DropCamera = undefined;
            return;
        }

        player CameraSetLookAt(player);
        player CameraSetPosition(player.camlinker);
        player CameraActivate(true);

        player.camlinker Launch(VectorScale(AnglesToForward(player GetPlayerAngles()), 10));
    }
    else
    {
        player CameraActivate(false);

        if(IsDefined(player.camlinker))
            player.camlinker Delete();
    }
}

function DeadOpsView(player)
{
    if(!Is_Alive(player) && !Is_True(player.DeadOpsView))
        return self iPrintlnBold("^1ERROR: ^7Player Needs To Be Alive To Enable Dead Ops View");
    
    if(Is_True(player.SpecNade) && !Is_True(player.DeadOpsView))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Spec-Nade Is Enabled");
    
    if(Is_True(player.DropCamera) && !Is_True(player.DeadOpsView))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Drop Camera Is Enabled");
    
    player.DeadOpsView = BoolVar(player.DeadOpsView);
    
    if(Is_True(player.DeadOpsView))
    {
        player endon("disconnect");
        
        tracePosition = BulletTrace(player.origin, player.origin + (0, 0, 350), 0, player)["position"];
        player.camlinker = SpawnScriptModel(tracePosition, "tag_origin", (90, 90, 0));

        if(!IsDefined(player.camlinker))
        {
            player.DeadOpsView = undefined;
            return;
        }
        
        player CameraSetPosition(player.camlinker);
        player CameraSetLookAt(player.camlinker);
        player CameraActivate(true);
        
        while(Is_True(player.DeadOpsView))
        {
            if(IsAlive(player))
            {
                tracePosition = BulletTrace(player.origin, player.origin + (0, 0, 350), 0, player)["position"];
                
                if(IsDefined(player.camlinker) && player.camlinker.origin != tracePosition)
                    player.camlinker.origin = tracePosition;
            }
            
            wait 0.01;
        }
    }
    else
    {
        player CameraActivate(false);
        
        if(IsDefined(player.camlinker))
            player.camlinker Delete();
    }
}

function ZombieCounter(player)
{
    player endon("disconnect");

    player.ZombieCounter = BoolVar(player.ZombieCounter);
    
    if(Is_True(player.ZombieCounter))
    {
        while(Is_True(player.ZombieCounter) && Is_Alive(player))
        {
            bgAlpha = ((self.MenuDesign == "Classic") ? 0.85 : 1);
            bgColor = ((self.MenuDesign == "Classic") ? (25, 25, 25) : ((self.MenuDesign == "Apparition") ? (42, 42, 42) : (0, 0, 0)));
            
            if(!IsDefined(player.ZombieCounterHud) || !player.ZombieCounterHud.size)
            {
                if(!IsDefined(player.ZombieCounterHud))
                    player.ZombieCounterHud = [];
                
                xPos = 5;
                yPos = 5;

                player.ZombieCounterHud[0] = player LUI_createRectangle(0, (xPos - 3), (yPos - 1), 227, 49, player.MainTheme, "white", 1);
                player.ZombieCounterHud[1] = player LUI_createRectangle(0, (xPos - 2), yPos, (player GetLUIMenuData(player.ZombieCounterHud[0], "width") - 2), (player GetLUIMenuData(player.ZombieCounterHud[0], "height") - 2), bgColor, "white", bgAlpha);
                
                player.ZombieCounterHud[2] = player LUI_createText("Alive: ", 0, xPos, yPos, 41, (1, 1, 1));
                player.ZombieCounterHud[3] = player LUI_createText("Remaining For Round: ", 0, xPos, (yPos + 20), 154, (1, 1, 1));

                player.ZombieCounterHud[4] = player LUI_createText(zombie_utility::get_current_zombie_count(), 0, player GetLUIMenuData(player.ZombieCounterHud[2], "x") + player GetLUIMenuData(player.ZombieCounterHud[2], "width"), player GetLUIMenuData(player.ZombieCounterHud[2], "y"), 255, (1, 1, 1));
                player.ZombieCounterHud[5] = player LUI_createText(level.zombie_total, 0, player GetLUIMenuData(player.ZombieCounterHud[3], "x") + player GetLUIMenuData(player.ZombieCounterHud[3], "width"), player GetLUIMenuData(player.ZombieCounterHud[3], "y"), 255, (1, 1, 1));
            }
            else
            {
                if(IsDefined(player.ZombieCounterHud) && player.ZombieCounterHud.size)
                {
                    if(Is_Alive(player) && !Is_True(player.refreshZombieCounter))
                    {
                        if(IsDefined(player.ZombieCounterHud[4]))
                            player SetLUIMenuData(player.ZombieCounterHud[4], "text", zombie_utility::get_current_zombie_count());
                        
                        if(IsDefined(player.ZombieCounterHud[5]))
                            player SetLUIMenuData(player.ZombieCounterHud[5], "text", level.zombie_total);
                    }
                    else
                    {
                        for(a = 0; a < player.ZombieCounterHud.size; a++)
                        {
                            if(IsDefined(player.ZombieCounterHud[a]))
                                player CloseLUIMenu(player.ZombieCounterHud[a]);
                        }
                        
                        player.ZombieCounterHud = undefined;
                        player.refreshZombieCounter = undefined;
                    }
                }
            }

            wait 0.01;
        }

        if(Is_True(player.ZombieCounter)) //LUI hud destroys on death, so we need to disable zombie counter on death
            ZombieCounter(player);
    }
    else
    {
        if(IsDefined(player.ZombieCounterHud) && player.ZombieCounterHud.size)
        {
            for(a = 0; a < player.ZombieCounterHud.size; a++)
            {
                if(IsDefined(player.ZombieCounterHud[a]))
                    player CloseLUIMenu(player.ZombieCounterHud[a]);
            }
        }

        player.ZombieCounterHud = undefined;
    }
}

function LightProtector(player)
{
    player endon("disconnect");
    player endon("EndLightProtector");

    player.LightProtector = BoolVar(player.LightProtector);

    if(Is_True(player.LightProtector))
    {
        player.LightProtect = SpawnScriptModel(player GetTagOrigin("j_head") + (0, 0, 45), "tag_origin");
        player.LightProtect clientfield::set("powerup_fx", Int(Pow(2, RandomInt(3))));

        while(Is_True(player.LightProtector) && IsDefined(player.LightProtect) && Is_Alive(player))
        {
            player.LightProtect.origin = player GetTagOrigin("j_head") + (0, 0, 45);
            target = player GetLightProtectorTarget();
            
            if(IsDefined(target) && CanControl(target) && !Is_True(target.LightProtector))
            {
                player thread LightProtectorTarget(target);
            }
            
            wait 0.01;
        }

        if(Is_True(player.LightProtector) && !IsDefined(player.LightProtect))
            LightProtector(player);
    }
    else
    {
        if(IsDefined(player.LightProtect))
            player.LightProtect Delete();
        
        player.UFOShoot = undefined;
        player notify("EndLightProtector");
    }
}

function LightProtectorTarget(target)
{
    self endon("disconnect");
    target endon("death");

    if(Is_True(target.LightProtector) || !IsDefined(target) || !IsAlive(target))
        return;
    
    target.LightProtector = true;
    targetOrigin = target GetTagOrigin("j_mainroot");

    if(!IsDefined(targetOrigin) || !IsVec(targetOrigin))
    {
        test = target GetTagOrigin("tag_body");

        if(IsDefined(test) && IsVec(test))
            targetOrigin = test;
        else
            target = undefined;
    }

    if(IsDefined(target) && IsDefined(targetOrigin) && IsVec(targetOrigin))
        self thread UFOShoot(self.LightProtect.origin, targetOrigin, 100, 0.1);
    
    wait 1;

    if(IsDefined(target) && IsAlive(target))
        target.LightProtector = undefined;
}

function GetLightProtectorTarget(distance = 500)
{
    zombies = GetAITeamArray(level.zombie_team);

    if(!IsDefined(zombies) || !zombies.size)
        return;

    enemy = undefined;
    
    for(a = 0; a < zombies.size; a++)
    {
        if(!CanControl(zombies[a]) || zombies[a] DamageConeTrace(self.origin, self) < 0.1 || Distance(self.origin, zombies[a].origin) > distance || Is_True(zombies[a].LightProtector))
            continue;
        
        if(zombies[a].archetype == "zombie" && !Is_True(zombies[a].zombie_think_done) || zombies[a].archetype != "zombie" && Is_True(zombies[a].ignoreme))
            continue;
        
        if(!IsDefined(enemy))
            enemy = zombies[a];
        
        if(enemy == zombies[a])
            continue;
        
        if(Closer(self.origin, zombies[a].origin, enemy.origin))
            enemy = zombies[a];
    }

    return enemy;
}

function SpecialMovements(player)
{
    player endon("disconnect");

    player.SpecialMovements = BoolVar(player.SpecialMovements);

    if(Is_True(player.SpecialMovements))
    {
        while(Is_True(player.SpecialMovements))
        {
            player.b_wall_run_enabled = 1;

            player AllowWallRun(1);
            player AllowDoubleJump(1);

            wait 0.1;
        }
    }
    else
    {
        player.b_wall_run_enabled = 0;

        player AllowWallRun(0);
        player AllowDoubleJump(0);
    }
}

function MoonGravity(player)
{
    if(player GetPlayerGravity() == 136)
        player ClearPlayerGravity();
    else
        player SetPlayerGravity(136);
}

function IceSkating(player)
{
    player.IceSkating = BoolVar(player.IceSkating);
    player ForceSlick(Is_True(player.IceSkating));
}

function ForgeMode(player)
{
    player endon("disconnect");

    if(Is_True(player.DeleteGun))
        player DeleteGun(player);
    
    if(Is_True(player.GravityGun))
        player GravityGun(player);
    
    player.ForgeMode = BoolVar(player.ForgeMode);

    if(Is_True(player.ForgeMode))
    {
        player iPrintlnBold("Aim At Entities/Zombies/Players To Pick Them Up");
        player iPrintlnBold("[{+attack}] To Release");
        
        grabEnt = undefined;

        while(Is_True(player.ForgeMode))
        {
            if(IsDefined(grabEnt) && (IsPlayer(grabEnt) && !Is_Alive(grabEnt) || Is_True(grabEnt.is_zombie) && !IsAlive(grabEnt)))
                grabEnt = undefined;
            
            if(IsDefined(grabEnt))
            {
                if(IsPlayer(grabEnt))
                    grabEnt SetOrigin((player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 250)));
                else if(Is_True(grabEnt.is_zombie))
                    grabEnt ForceTeleport((player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 250)));
                else
                    grabEnt.origin = (player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 250));

                if(player AttackButtonPressed())
                    grabEnt = undefined;
            }

            if(player AdsButtonPressed() && !IsDefined(grabEnt))
            {
                trace = BulletTrace(player GetEye(), player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 1000000), 1, player);

                if(IsDefined(trace["entity"]) && trace["entity"].model != "tag_origin")
                    grabEnt = trace["entity"];
            }

            wait 0.01;
        }
    }
}

function SpecNade(player) //Credit to Extinct for his spec-nade
{
    player endon("disconnect");
    player endon("EndSpecNade");
    
    if(player isPlayerLinked() && !Is_True(player.SpecNade))
        return self iPrintlnBold("^1ERROR: ^7Player Is Linked To An Entity");
    
    if(Is_True(player.NoclipBind1) && !Is_True(player.SpecNade))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Noclip Bind Is Enabled");
    
    if(Is_True(player.DropCamera) && !Is_True(player.SpecNade))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Drop Camera Is Enabled");
    
    if(Is_True(player.DeadOpsView) && !Is_True(player.SpecNade))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Dead Ops View Is Enabled");
    
    if(Is_True(player.PlayerMountCamera) && !Is_True(player.SpecNade))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While Mount Camera Is Enabled");
    
    player.SpecNade = BoolVar(player.SpecNade);

    if(Is_True(player.SpecNade))
    {
        while(Is_True(player.SpecNade))
        {
            player waittill("grenade_fire", grenade, weapon);
            
            if(zm_utility::is_placeable_mine(weapon) || player isPlayerLinked() || !IsDefined(grenade))
                continue;
            
            player.nadelinker = SpawnScriptModel(grenade.origin - AnglesToForward(grenade.angles) * 50, "tag_origin");
            player.nadelinker LinkToBlendToTag(grenade, "tag_origin");

            player.ignoreme = true;
            player Hide();

            player CameraSetPosition(player.nadelinker);
            player CameraSetLookAt(grenade);
            player CameraActivate(true);

            grenade SpecNadeFollow(player.nadelinker);

            player CameraActivate(false);
            player.nadelinker Delete();

            if(Is_True(player.ignoreme))
                player.ignoreme = false;
            
            if(!Is_True(player.Invisibility))
                player Show();
        }
    }
    else
    {
        if(IsDefined(player.nadelinker))
        {
            player CameraActivate(false);
            player.nadelinker Delete();
            
            if(!Is_True(player.Invisibility))
                player Show();
        }

        if(Is_True(player.ignoreme))
            player.ignoreme = false;
        
        player notify("EndSpecNade");
    }
}

function SpecNadeFollow(camera)
{
    if(!IsDefined(camera))
        return;
    
    self endon("death");

    while(IsDefined(self))
    {
        if(IsDefined(camera))
            camera.origin = ((self.origin + (0, 0, 10)) - (AnglesToForward(camera.angles) * 50));

        wait 0.05;
    }
}

function NukeNades(player)
{
    player endon("disconnect");
    player endon("EndNukeNades");

    player.NukeNades = BoolVar(player.NukeNades);
    
    if(Is_True(player.NukeNades))
    {
        while(Is_True(player.NukeNades))
        {
            player waittill("grenade_fire", grenade, weapon);
            
            if(zm_utility::is_placeable_mine(weapon) || !IsDefined(grenade))
                continue;

            grenade thread NukeNade();
        }
    }
    else
    {
        player notify("EndNukeNades");
    }
}

function NukeNade()
{
    if(!IsDefined(self))
        return;
    
    nukeModel = SpawnScriptModel(self.origin, "p7_zm_power_up_nuke", self.angles);

    if(!IsDefined(nukeModel))
        return;

    nukeModel clientfield::set("powerup_fx", Int(Pow(2, RandomInt(3))));
    nukeModel LinkTo(self);

    while(IsDefined(self))
    {
        origin = self.origin;
        wait 0.05;
    }
    
    origin += (0, 0, 25);

    if(IsDefined(nukeModel))
        nukeModel Delete();
    
    PlayFX(level._effect["grenade_samantha_steal"], origin);
    PlayFX(level._effect["poltergeist"], origin);
    PlayFX("zombie/fx_powerup_nuke_zmb", origin);

    zombies = GetAITeamArray(level.zombie_team);
    
    for(a = 0; a < zombies.size; a++)
    {
        if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || Distance(origin, zombies[a].origin) > 500)
            continue;
        
        zombies[a].ZombieFling = true;
        zombies[a] clientfield::increment("zm_nuked");
        wait 0.1;

        zombies[a] DoDamage((zombies[a].health + 666), origin);
    }
}

function CodJumper(player)
{
    player endon("disconnect");
    player endon("EndCodJumper");

    player.CodJumper = BoolVar(player.CodJumper);
    
    if(Is_True(player.CodJumper))
    {
        player.codboxes = [];

        player iPrintlnBold("^1" + ToUpper(GetMenuName()) + ": ^7Shoot To Spawn Cod Jumper At Your Crosshairs");

        while(Is_True(player.CodJumper))
        {
            player waittill("weapon_fired");
            
            if(IsDefined(player.codboxes) && player.codboxes.size)
            {
                for(a = 0; a < player.codboxes.size; a++)
                {
                    if(IsDefined(player.codboxes[a]))
                        player.codboxes[a] Delete();
                }
            }

            color = Pow(2, RandomInt(3));
            trace = BulletTrace(player GetEye(), player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 1000000), 0, player);
            
            origin = trace["position"];
            surface = trace["surfacetype"];

            if(surface != "none" && surface != "default")
            {
                for(a = 0; a < 3; a++)
                {
                    for(b = 0; b < 4; b++)
                    {
                        player.codboxes[player.codboxes.size] = SpawnScriptModel(GetGroundPos(origin + ((a * 20), (b * 10), 0)), "p7_zm_power_up_max_ammo", (0, 0, 0));
                        player.codboxes[(player.codboxes.size - 1)] clientfield::set("powerup_fx", Int(color));
                        player.codboxes[(player.codboxes.size - 1)] thread CodBoxHandler();
                    }
                }
            }
        }
    }
    else
    {
        if(IsDefined(player.codboxes) && player.codboxes.size)
        {
            foreach(box in player.codboxes)
            {
                if(IsDefined(box))
                    box Delete();
            }
        }
        
        player notify("EndCodJumper");
    }
}

function CodBoxHandler()
{
    while(IsDefined(self))
    {
        foreach(player in level.players)
        {
            if(!Is_Alive(player) || player isDown() || !player IsTouching(self))
                continue;
            
            if(player IsOnGround())
                player SetOrigin(player.origin + (0, 0, 5));
            
            player SetVelocity((player GetVelocity()[0], player GetVelocity()[1], 600));
        }

        wait 0.01;
    }
}

function FrogJump(player)
{
    player.FrogJump = BoolVar(player.FrogJump);

    if(Is_True(player.FrogJump))
    {
        player endon("disconnect");
        
        while(Is_True(player.FrogJump))
        {
            if(player JumpButtonPressed() && !player IsOnGround() && player GetStance() == "stand" && Is_Alive(player))
            {
                AngF = AnglesToForward(player GetPlayerAngles());
                player SetVelocity((AngF[0] * 550, AngF[1] * 550, 400));
                
                while(!player IsOnGround())
                    wait 0.05;
            }
            
            wait 0.01;
        }
    }
}

function Jetpack(player)
{
    player endon("disconnect");

    if(player isPlayerLinked() && !Is_True(player.Jetpack))
        return self iPrintlnBold("^1ERROR: ^7Player Is Linked To An Entity");
    
    if(Is_True(player.NoclipBind1) && !Is_True(player.Jetpack))
        return self iPrintlnBold("^1ERROR: ^7Player Has Noclip Bind Enabled");
    
    player.Jetpack = BoolVar(player.Jetpack);

    if(Is_True(player.Jetpack))
    {
        player iPrintlnBold("Press & Hold [{+frag}] To Use Jetpack");

        while(Is_True(player.Jetpack))
        {
            if(player FragButtonPressed() && !player isPlayerLinked())
            {
                if(player IsOnGround())
                    player SetOrigin((player.origin + (0, 0, 5)));
                
                Earthquake(0.55, 0.05, player GetTagOrigin("back_low"), 25);
                player SetVelocity((player GetVelocity() + (0, 0, 50)));
                PlayFX(level._effect["character_fire_death_torso"], player GetTagOrigin("back_low"));
            }

            wait 0.05;
        }
    }
}

function HealthBar(player)
{
    player.HealthBar = BoolVar(player.HealthBar);

    if(Is_True(player.HealthBar))
    {
        player endon("disconnect");

        while(Is_True(player.HealthBar) && Is_Alive(player))
        {
            healthWidth = player.health;
            maxHealthWidth = player.maxhealth;

            if(maxHealthWidth > 150)
            {
                healthWidth = Int((healthWidth / maxHealthWidth) * 150);
                maxHealthWidth = 150;
            }

            if(!IsDefined(player.HealthBarUI) || !player.HealthBarUI.size)
            {
                player.HealthBarUI = [];
                player.HealthBarUI[0] = player LUI_createRectangle(0, 24, 600, (maxHealthWidth + 2), 14, (0, 0, 0), "white", 1);
                player.HealthBarUI[1] = player LUI_createRectangle(0, 25, 601, healthWidth, 12, (1, 1, 1), "white", 0.9);
            }
            else
            {
                player SetLUIMenuData(player.HealthBarUI[0], "width", (maxHealthWidth + 2));
                player SetLUIMenuData(player.HealthBarUI[1], "width", healthWidth);
            }

            wait 0.01;
        }

        if(Is_True(player.HealthBar))
            HealthBar(player);
    }
    else
    {
        if(IsDefined(player.HealthBarUI) && player.HealthBarUI.size)
        {
            player CloseLUIMenu(player.HealthBarUI[0]);
            player CloseLUIMenu(player.HealthBarUI[1]);
            player.HealthBarUI = undefined;
        }
    }
}

function ClusterGrenades(player)
{
    player endon("disconnect");
    player endon("EndClusterGrenades");

    player.ClusterGrenades = BoolVar(player.ClusterGrenades);
    
    if(Is_True(player.ClusterGrenades))
    {
        while(Is_True(player.ClusterGrenades))
        {
            player waittill("grenade_fire", grenade, weapon);

            if(!IsDefined(grenade) || !IsDefined(weapon) || zm_utility::is_placeable_mine(weapon))
                continue;
            
            while(IsDefined(grenade))
            {
                origin = grenade.origin;
                wait 0.1;
            }

            for(a = 0; a < 10; a++)
                player MagicGrenadeType(weapon, origin, GetRandomThrowSpeed(), ((30 + a) / 10));
        }
    }
    else
    {
        player notify("EndClusterGrenades");
    }
}

function GetRandomThrowSpeed()
{
    yaw = RandomFloat(360);
    pitch = RandomFloatRange(65, 85);
    
    return (((Cos(yaw) * Cos(pitch)), (Sin(yaw) * Cos(pitch)), Sin(pitch)) * RandomFloatRange(400, 600));
}

function ElectricFireCherry(player)
{
    player endon("disconnect");
    player endon("EndElectricFireCherry");
    
    player.ElectricFireCherry = BoolVar(player.ElectricFireCherry);

    if(Is_True(player.ElectricFireCherry))
    {
        player.consecutive_electric_fire_cherry_attacks = 0;
        player.wait_on_reload = [];

        while(Is_True(player.ElectricFireCherry))
        {
            player waittill("reload_start");

            current_weapon = player GetCurrentWeapon();

            if(isInArray(player.wait_on_reload, current_weapon))
                continue;
            
            player.wait_on_reload[player.wait_on_reload.size] = current_weapon;
            player.consecutive_electric_fire_cherry_attacks++;

            player thread check_for_reload_complete(current_weapon);
            player thread electric_fire_cherry_cooldown_timer(current_weapon);

            switch(player.consecutive_electric_fire_cherry_attacks)
            {
                case 0:
                case 1:
                    n_zombie_limit = undefined;
                    break;
                
                case 2:
                    n_zombie_limit = 12;
                    break;
                
                case 3:
                    n_zombie_limit = 8;
                    break;
                
                case 4:
                    n_zombie_limit = 4;
                    break;
                
                default:
                    n_zombie_limit = 0;
                    break;
            }

            //Makes sure electric_cherry is used, which will mean 'electric_cherry_reload_fx' is registered as a client field
            if(IsDefined(level._effect["electric_cherry_explode"]))
                CodeSetClientField(player, "electric_cherry_reload_fx", 1);

            player PlaySound("zmb_bgb_powerup_burnedout");
            player PlaySound("zmb_cherry_explode");

            player clientfield::increment_to_player("zm_bgb_burned_out_1ptoplayer");
            player clientfield::increment("zm_bgb_burned_out_3p_allplayers");

            zombies = array::get_all_closest(player.origin, GetAITeamArray(level.zombie_team), undefined, undefined, 375);

            if(!IsDefined(zombies) || !zombies.size)
            {
                //Makes sure electric_cherry is used, which will mean 'electric_cherry_reload_fx' is registered as a client field
                if(IsDefined(level._effect["electric_cherry_explode"]))
                    CodeSetClientField(player, "electric_cherry_reload_fx", 0);

                continue;
            }

            targets = [];

            for(a = 0; a < zombies.size; a++)
            {
                if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || isInArray(targets, zombies[a]) || IsDefined(n_zombie_limit) && targets.size >= n_zombie_limit)
                    continue;
                
                zombies[a].marked_for_death = 1;
                zombies[a] PlaySound("zmb_elec_jib_zombie");

                if(IsVehicle(zombies[a]))
                {
                    if(!(IsDefined(zombies[a].head_gibbed) && zombies[a].head_gibbed))
                        zombies[a] clientfield::set("tesla_shock_eyes_fx_veh", 1);
                    else
                        zombies[a] clientfield::set("tesla_death_fx_veh", 1);
                    
                    zombies[a] clientfield::increment("zm_bgb_burned_out_fire_torso_vehicle");
                }
                else
                {
                    if(!(IsDefined(zombies[a].head_gibbed) && zombies[a].head_gibbed))
                        zombies[a] clientfield::set("tesla_shock_eyes_fx", 1);
                    else
                        zombies[a] clientfield::set("tesla_death_fx", 1);
                    
                    zombies[a] clientfield::increment("zm_bgb_burned_out_fire_torso_actor");
                }
                
                targets[targets.size] = zombies[a];
            }

            if(IsDefined(targets) && targets.size)
            {
                for(a = 0; a < targets.size; a++)
                {
                    wait 0.1;

                    if(!IsDefined(targets[a]) || !IsAlive(targets[a]))
                        continue;
                    
                    targets[a].ZombieFling = true;
                    targets[a] DoDamage((targets[a].health + 666), targets[a].origin);
                    player zm_score::add_to_player_score(40);
                }
            }

            //Makes sure electric_cherry is used, which will mean 'electric_cherry_reload_fx' is registered as a client field
            if(IsDefined(level._effect["electric_cherry_explode"]))
                CodeSetClientField(player, "electric_cherry_reload_fx", 0);
        }
    }
    else
    {
        //Makes sure electric_cherry is used, which will mean 'electric_cherry_reload_fx' is registered as a client field
        if(IsDefined(level._effect["electric_cherry_explode"]))
            CodeSetClientField(player, "electric_cherry_reload_fx", 0);
        
        player notify("EndElectricFireCherry");
    }
}

function electric_fire_cherry_cooldown_timer(current_weapon)
{
    self notify("electric_fire_cherry_cooldown_started");
    self endon("electric_fire_cherry_cooldown_started");
    
    self endon("death");
    self endon("disconnect");

    reloadTime = (self HasPerk("specialty_fastreload") ? (0.25 * GetDvarFloat("perk_weapReloadMultiplier")) : 0.25);
    waitTime = (reloadTime + 3);

    wait waitTime;
    self.consecutive_electric_fire_cherry_attacks = 0;
}

function check_for_reload_complete(weapon)
{
    self endon("death");
    self endon("disconnect");
    self endon("player_lost_weapon_" + weapon.name);

    self thread weapon_replaced_monitor(weapon);

    while(1)
    {
        self waittill("reload");

        current_weapon = self GetCurrentWeapon();

        if(current_weapon == weapon)
        {
            ArrayRemoveValue(self.wait_on_reload, weapon);
            self notify("weapon_reload_complete_" + weapon.name);
            break;
        }
    }
}

function weapon_replaced_monitor(weapon)
{
    self endon("death");
    self endon("disconnect");
    self endon("weapon_reload_complete_" + weapon.name);

    while(1)
    {
        self waittill("weapon_change");

        primaryweapons = self GetWeaponsListPrimaries();

        if(!isInArray(primaryweapons, weapon))
        {
            self notify("player_lost_weapon_" + weapon.name);
            ArrayRemoveValue(self.wait_on_reload, weapon);
            break;
        }
    }
}

function HumanCentipede(player)
{
    player endon("disconnect");
    
    player.HumanCentipede = BoolVar(player.HumanCentipede);

    if(Is_True(player.HumanCentipede))
    {
        player.HumanCentipedeArray = [];
        player.HumanCentipedeClone = 0;
        
        while(Is_True(player.HumanCentipede))
        {
            if(Is_Alive(player))
            {
                player.HumanCentipedeArray[player.HumanCentipedeClone] = player ClonePlayer(999999, player GetCurrentWeapon(), player);
                player.HumanCentipedeArray[player.HumanCentipedeClone] StartRagDoll(1);
                
                player.HumanCentipedeClone++;
                
                if(player.HumanCentipedeArray.size >= 8)
                {
                    if(player.HumanCentipedeClone >= 8)
                        player.HumanCentipedeClone = 0;
                    
                    if(IsDefined(player.HumanCentipedeArray[player.HumanCentipedeClone]))
                        player.HumanCentipedeArray[player.HumanCentipedeClone] Delete();
                }
            }
            else
            {
                if(player.HumanCentipedeArray.size)
                {
                    foreach(clone in player.HumanCentipedeArray)
                    {
                        if(IsDefined(clone))
                            clone Delete();
                    }
                }
            }
            
            wait 0.25;
        }
    }
    else
    {
        foreach(clone in player.HumanCentipedeArray)
        {
            if(IsDefined(clone))
                clone Delete();
        }
    }
}

function ShootPowerUps(type = "Disable", player)
{
    if(!IsDefined(level.zombie_include_powerups) || !level.zombie_include_powerups.size)
        return;
    
    player notify("EndShootPowerUps");

    if(type == "Disable")
        return;

    player endon("EndShootPowerUps");
    player endon("disconnect");
    
    while(1)
    {
        player waittill("weapon_fired");

        trace = BulletTrace(player GetEye(), player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 1000000), 0, player);
        origin = trace["position"];
        surface = trace["surfacetype"];

        if(surface == "none" || surface == "default")
            continue;
        
        powerups = GetArrayKeys(level.zombie_include_powerups);
        
        if(type == "Drop")
        {
            player SpawnPowerUp(powerups[RandomInt(powerups.size)], origin);
        }
        else
        {
            powerup = level CustomPowerupSpawn(powerups[RandomInt(powerups.size)], player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 60));
        
            if(IsDefined(powerup))
                powerup PhysicsLaunch(powerup.origin, VectorScale(AnglesToForward(player GetPlayerAngles()), 175));
        }
    }
}

function RocketRiding(player)
{
    player endon("disconnect");
    player endon("EndRocketRiding");

    player.RocketRiding = BoolVar(player.RocketRiding);
    
    if(Is_True(player.RocketRiding))
    {
        while(Is_True(player.RocketRiding))
        {
            player waittill("missile_fire", missile, weaponName);

            if(zm_utility::GetWeaponClassZM(weaponName) != "weapon_launcher")
                continue;
            
            trace = BulletTrace(player GetEye(), player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 200), 1, player);
            rider = undefined;

            foreach(client in level.players)
            {
                if(!Is_Alive(client) || client == player)
                    continue;
                
                if(Distance(client.origin, trace["position"]) <= 225)
                {
                    if(!IsDefined(rider))
                    {
                        rider = client;
                    }
                    else
                    {
                        if(Distance(client.origin, trace["position"]) < Distance(rider.origin, trace["position"]))
                            rider = client;
                    }
                }
            }
            
            if(!IsDefined(rider))
                rider = player;
            
            if(Is_True(rider.RidingRocket))
            {
                rider notify("StopRidingRocket");
                rider Unlink();
                rider.RocketRidingLinker Delete();
                rider.RidingRocket = BoolVar(rider.RidingRocket);
            }
            
            wait 0.2;
            rider.RocketRidingLinker = SpawnScriptModel(missile.origin, "tag_origin");

            if(!IsDefined(rider.RocketRidingLinker))
                continue;

            rider.RidingRocket = true;
            rider.RocketRidingLinker LinkTo(missile);
            rider SetOrigin(rider.RocketRidingLinker.origin);
            rider PlayerLinkTo(rider.RocketRidingLinker);

            wait 0.1;
            rider thread WatchRocket(missile);
        }
    }
    else
    {
        player notify("EndRocketRiding");
    }
}

function WatchRocket(rocket)
{
    self endon("death");
    self endon("disconnect");
    self endon("StopRidingRocket");
    
    while(IsDefined(rocket) && Is_Alive(self))
    {
        if(self MeleeButtonPressed())
            break;

        wait 0.05;
    }
    
    self Unlink();

    if(IsDefined(self.RocketRidingLinker))
        self.RocketRidingLinker Delete();
    
    if(Is_True(self.RidingRocket))
        self.RidingRocket = BoolVar(self.RidingRocket);
}

function GrapplingGun(player)
{
    player endon("disconnect");
    player endon("EndGrapplingGun");
    
    player.GrapplingGun = BoolVar(player.GrapplingGun);

    if(Is_True(player.GrapplingGun))
    {
        while(Is_True(player.GrapplingGun))
        {
            player waittill("weapon_fired");

            trace = BulletTrace(player GetEye(), player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 1000000), 0, player);
            origin = trace["position"];
            surface = trace["surfacetype"];

            if(surface == "none" || surface == "default" || IsDefined(player.grapplingent))
                continue;
            
            player.grapplingent = SpawnScriptModel(player.origin, "tag_origin");

            if(!IsDefined(player.grapplingent))
                continue;

            player PlayerLinkTo(player.grapplingent);
            player.grapplingent MoveTo(origin, 1);
            player.grapplingent waittill("movedone");

            if(!IsDefined(player.grapplingent))
                continue;
            
            player Unlink();
            player.grapplingent Delete();
        }
    }
    else
    {
        if(IsDefined(player.grapplingent))
        {
            player Unlink();
            player.grapplingent Delete();
        }
        
        player notify("EndGrapplingGun");
    }
}

function GravityGun(player)
{
    player endon("disconnect");

    if(Is_True(player.DeleteGun))
        player DeleteGun(player);
    
    if(Is_True(player.ForgeMode))
        player ForgeMode(player);
    
    player.GravityGun = BoolVar(player.GravityGun);

    if(Is_True(player.GravityGun))
    {
        player iPrintlnBold("Aim At Entities/Zombies/Players To Pick Them Up");
        player iPrintlnBold("[{+attack}] To Launch");

        grabEnt = undefined;
        
        while(Is_True(player.GravityGun))
        {
            if(IsDefined(grabEnt) && (IsPlayer(grabEnt) && !Is_Alive(grabEnt) || Is_True(grabEnt.is_zombie) && !IsAlive(grabEnt)))
                grabEnt = undefined;
            
            if(IsDefined(grabEnt))
            {
                if(IsPlayer(grabEnt))
                    grabEnt SetOrigin((player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 250)));
                else if(Is_True(grabEnt.is_zombie))
                    grabEnt ForceTeleport((player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 250)));
                else
                    grabEnt.origin = (player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 250));
                
                if(player AttackButtonPressed() && IsDefined(grabEnt))
                {
                    shootEnt = SpawnScriptModel(grabEnt.origin, "tag_origin");

                    if(IsPlayer(grabEnt))
                        grabEnt PlayerLinkTo(shootEnt);
                    else
                        grabEnt LinkTo(shootEnt);
                    
                    grabEnt.GravityGunLaunched = true;
                    shootEnt.GravityGunLaunched = true;

                    shootEnt thread deleteAfter(5);
                    grabEnt thread GravityGunUnlinkAfter(5);
                    shootEnt Launch(VectorScale(AnglesToForward(player GetPlayerAngles()), 2500));
                    wait 0.1;

                    grabEnt = undefined;
                }
            }

            if(player AdsButtonPressed() && !IsDefined(grabEnt))
            {
                trace = BulletTrace(player GetEye(), player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 1000000), 1, player);

                if(IsDefined(trace["entity"]) && !Is_True(trace["entity"].GravityGunLaunched) && trace["entity"].model != "tag_origin")
                    grabEnt = trace["entity"];
            }

            wait 0.01;
        }
    }
}

function GravityGunUnlinkAfter(time)
{
    self endon("death");
    self endon("disconnect");
    
    wait time;

    if(IsDefined(self))
        self Unlink();

    if(IsDefined(self) && Is_True(self.GravityGunLaunched))
        self.GravityGunLaunched = BoolVar(self.GravityGunLaunched);
}

function DeleteGun(player)
{
    player endon("disconnect");

    if(Is_True(player.GravityGun))
        player GravityGun(player);
    
    if(Is_True(player.ForgeMode))
        player ForgeMode(player);
    
    player.DeleteGun = BoolVar(player.DeleteGun);

    if(Is_True(player.DeleteGun))
    {
        player iPrintlnBold("Aim At Entities/Zombies To Delete Them");
        
        while(Is_True(player.DeleteGun))
        {
            if(player AdsButtonPressed())
            {
                trace = BulletTrace(player GetEye(), player GetEye() + VectorScale(AnglesToForward(player GetPlayerAngles()), 1000000), 1, player);

                if(IsDefined(trace["entity"]) && !IsPlayer(trace["entity"]))
                    trace["entity"] Delete();
            }

            wait 0.01;
        }
    }
}

function RapidFire(player)
{
    player endon("disconnect");
    player endon("EndRapidFire");

    player.RapidFire = BoolVar(player.RapidFire);
    
    if(Is_True(player.RapidFire))
    {
        while(Is_True(player.RapidFire))
        {
            player waittill("weapon_fired");

            weapon = player GetCurrentWeapon();

            if(!IsDefined(weapon) || weapon == level.weaponnone)
                continue;
            
            while(player AttackButtonPressed())
            {
                currentWeapon = player GetCurrentWeapon();

                if(!IsDefined(currentWeapon) || currentWeapon == level.weaponnone || currentWeapon != weapon)
                    break;
                
                start = player GetWeaponMuzzlePoint();

                if(!IsDefined(start) || !IsVec(start))
                    start = player GetEye();
                
                fwdDir = player GetWeaponForwardDir();
            
                if(!IsDefined(fwdDir) || !IsVec(fwdDir))
                    fwdDir = AnglesToForward(player GetPlayerAngles());
                
                MagicBullet(weapon, start, BulletTrace(start, start + fwdDir * 100, 0, undefined)["position"] + (RandomFloatRange(-5, 5), RandomFloatRange(-5, 5), RandomFloatRange(-5, 5)), player);
                wait 0.1;
            }
        }
    }
    else
    {
        player notify("EndRapidFire");
    }
}

function ExtraGore(player)
{
    player.ExtraGore = BoolVar(player.ExtraGore);
}

function HeadDrama(player)
{
    if(!player HasPerk("specialty_locdamagecountsasheadshot"))
        player SetPerk("specialty_locdamagecountsasheadshot");
    else
        player UnSetPerk("specialty_locdamagecountsasheadshot");
}

function PowerUpMagnet(player)
{
    player endon("disconnect");
        
    player.PowerUpMagnet = BoolVar(player.PowerUpMagnet);
    
    while(Is_True(player.PowerUpMagnet))
    {
        powerups = zm_powerups::get_powerups(player.origin, 500);

        if(IsDefined(powerups) && powerups.size)
        {
            foreach(index, powerup in powerups)
            {
                if(IsDefined(powerup) && BulletTracePassed(player GetEye(), powerup.origin, 0, player) && !Is_True(powerup.movingtoplayer))
                {
                    powerup.movingtoplayer = true;
                    mainRoot = player GetTagOrigin("j_mainroot");

                    if(IsDefined(mainRoot))
                        powerup MoveTo(mainRoot, CalcDistance(1100, powerup.origin, mainRoot));
                    
                    wait 0.05;

                    if(IsDefined(powerup) && Is_True(powerup.movingtoplayer)) //making sure the powerup still exists
                        powerup.movingtoplayer = BoolVar(powerup.movingtoplayer);
                }
            }
        }

        wait 0.1;
    }
}

function DisableEarningPoints(player)
{
    player.DisableEarningPoints = BoolVar(player.DisableEarningPoints);
}

function DamagePointsMultiplier(multiplier, player)
{
    player.DamagePointsMultiplier = multiplier;
}

// ============================================================
// Functions/GameModes/AllTheWeapons.gsc
// ============================================================

//All The Weapons game mode developed by CF4_99
function initAllTheWeapons(type)
{
    if(Is_True(level.initAllTheWeapons) || Is_True(level.GameModeSelected))
        return;
    level.initAllTheWeapons = true;
    level.GameModeSelected = true;

    level endon("game_ended");
    
    thread SetRound(15);
    level.zombie_vars["zombie_between_round_time"] = 0.1;
    level thread ATWGameOverHandle();

    weaponArray = [];
    usedWeaponArray = (!IsVerkoMap() ? ((type == "Base Weapons") ? GetArrayKeys(level.zombie_weapons) : ((type == "Upgraded Weapons") ? GetArrayKeys(level.zombie_weapons_upgraded) : ArrayCombine(GetArrayKeys(level.zombie_weapons), GetArrayKeys(level.zombie_weapons_upgraded), 0, 1))) : ((type == "Base Weapons") ? level.var_21b77150 : ((type == "Upgraded Weapons") ? level.var_2b893b73 : ArrayCombine(level.var_21b77150, level.var_2b893b73, 0, 1))));

    foreach(weapon in usedWeaponArray)
    {
        wpn = (!IsVerkoMap() ? weapon : GetWeapon(weapon));

        if(wpn.isgrenadeweapon || wpn.ismeleeweapon || type == "Base Weapons" && IsSubStr(wpn.name, "upgraded") || wpn.name == "none")
            continue;
        
        weaponArray[weaponArray.size] = wpn;
    }

    weaponArray = array::randomize(weaponArray);

    MenuPerks = [];
    perks = GetArrayKeys(level._custom_perks);

    for(a = 0; a < perks.size; a++)
        array::add(MenuPerks, perks[a], 0);

    foreach(player in level.players)
    {
        if(player isDown())
            player thread PlayerRevive(player);
        
        if(player.sessionstate == "spectator")
            player thread ServerRespawnPlayer(player);
        
        if(player isInMenu(true))
            player thread closeMenu1();
        
        thread UnlimitedAmmo("Reload", player);

        if(!IsDefined(player.perks_active) || player.perks_active.size != MenuPerks.size)
            thread PlayerAllPerks(player);
        
        if(!Is_True(player._retain_perks))
            thread PlayerRetainPerks(player);
        
        //remove everyones verification
        player.accessLevel = GetAccessLevels()[1];
        
        if(player isInMenu(true))
            player thread closeMenu1();
        
        player notify("endMenuMonitor");

        if(Is_True(player.menuMonitor))
            player.menuMonitor = BoolVar(player.menuMonitor);
        
        player thread ModeWeaponMonitor(weaponArray);
    }

    wait 0.1;

    currentWeaponIndex = -1;
    level.indexAllTheWeapons = 0;
    level.killsAllTheWeapons = 0;
    level.killGoalAllTheWeapons = 15;
    level.currentWeaponAllTheWeapons = weaponArray[level.indexAllTheWeapons];

    foreach(msg in Array("Game Mode: All The Weapons\nDeveloped By: CF4_99", "You Will Get A New Weapon Every " + level.killGoalAllTheWeapons + " Kills\nEvery Kill Has To Be With The Given Weapon"))
        thread typeWriter(msg);

    while(level.indexAllTheWeapons < (weaponArray.size - 1))
    {
        foreach(player in level.players)
        {
            if(!IsDefined(player.weaponKillsCounter))
            {
                player.weaponKillsCounter = player LUI_createText("Kills: " + level.killsAllTheWeapons + "/" + level.killGoalAllTheWeapons, 2, 0, 55, 255, (1, 1, 1));
            }
            else
            {
                if(player GetLUIMenuData(player.weaponKillsCounter, "text") != "Kills: " + level.killsAllTheWeapons + "/" + level.killGoalAllTheWeapons)
                    player SetLUIMenuData(player.weaponKillsCounter, "text", "Kills: " + level.killsAllTheWeapons + "/" + level.killGoalAllTheWeapons);
            }
        }
        
        if(currentWeaponIndex != level.indexAllTheWeapons)
        {
            currentWeaponIndex = level.indexAllTheWeapons;
            level.currentWeaponAllTheWeapons = weaponArray[level.indexAllTheWeapons];

            foreach(player in level.players)
            {
                TakePlayerWeapons(player);
                
                if(!IsDefined(player.weaponIndexUI))
                    player.weaponIndexUI = player LUI_createText("Weapon: " + (level.indexAllTheWeapons + 1) + "/" + weaponArray.size, 2, 0, 25, 255, (1, 1, 1));
                else
                    player SetLUIMenuData(player.weaponIndexUI, "text", "Weapon: " + (level.indexAllTheWeapons + 1) + "/" + weaponArray.size);

                newWeapon = player zm_weapons::weapon_give(level.currentWeaponAllTheWeapons, false, false, true);
                player GiveStartAmmo(newWeapon);
                player SwitchToWeapon(newWeapon);
            }
        }

        wait 0.1;
    }

    wait 1;
    
    foreach(player in level.players)
    {
        if(Is_Alive(player))
            PlayerDeath("Kill", player);
    }
}

function ATWGameOverHandle()
{
    level waittill("game_ended");

    foreach(player in level.players)
    {
        if(IsDefined(player.weaponKillsCounter))
            player CloseLUIMenu(player.weaponKillsCounter);
        
        if(IsDefined(player.weaponIndexUI))
            player CloseLUIMenu(player.weaponIndexUI);
    }
}

// ============================================================
// Functions/GameModes/ModeCommonScripts.gsc
// ============================================================

function ModeWeaponMonitor(weaponArray)
{
    if(Is_True(self.ModeWeaponMonitor))
        return;
    self.ModeWeaponMonitor = true;

    level endon("game_ended");

    while(1)
    {
        self waittill("weapon_change", newWeapon);
        wait 0.1; //this buffer should help avoid the death machine powerup icon from sticking

        keepWeapon = (Is_True(level.initSharpshooter) ? weaponArray[level.indexSharpshooter] : level.currentWeaponAllTheWeapons);

        if(newWeapon != keepWeapon)
        {
            self TakeWeapon(newWeapon);

            if(!self HasWeapon(keepWeapon))
            {
                keepWeapon = self zm_weapons::weapon_give(keepWeapon, false, false, true);
                self GiveStartAmmo(keepWeapon);
            }
            
            self SwitchToWeapon(keepWeapon);
        }
    }
}

// ============================================================
// Functions/GameModes/ModMenuLobby.gsc
// ============================================================

function InitModMenuLobby(access)
{
    if(Is_True(level.GameModeSelected))
        return;
    level.GameModeSelected = true;

    if(!Is_True(level.AutoRevive))
        level thread AutoRevive();
    
    if(!Is_True(level.AutoRespawn))
        level thread AutoRespawn();

    MenuPerks = [];
    perks = GetArrayKeys(level._custom_perks);

    for(a = 0; a < perks.size; a++)
        array::add(MenuPerks, perks[a], 0);

    foreach(player in level.players)
    {
        player.playerGodmode = true;

        if(Is_True(player.PlayerDemiGod))
            player.PlayerDemiGod = undefined;
        
        thread UnlimitedAmmo("Continuous", player);

        if(!IsDefined(player.perks_active) || player.perks_active.size != MenuPerks.size)
            thread PlayerAllPerks(player);
        
        if(!Is_True(player._retain_perks))
            thread PlayerRetainPerks(player);
        
        if(!Is_True(player.ReducedSpread))
            ReducedSpread(player);
        
        ModifyScore(4194303, player);
        CustomCrosshairs("+", player);

        player SetPerk("specialty_unlimitedsprint");
        player SetPerk("specialty_sprintfire");

        if(player isInMenu(true))
            player thread closeMenu1();
        
        player.currentMenu = undefined;
        player.menuCursor = undefined;
        player.menu_parent = undefined;
        player.menu_parentQM = undefined;
    }

    SetVerificationAllPlayers(access);
    level thread ModMenuLobbyMessage();

    wait 1;
    level.SuperJump = true;
    SetJumpHeight(1023);
    SetDvar("bg_gravity", 200);
    SetDvar("g_speed", "500");

    if(!Is_True(level.Newsbar))
        level thread Newsbar();
    
    if(!Is_True(level.Doheart))
    {
        level.DoheartStyle = "Moving";
        level.DoheartSavedText = "discord.gg/apparitionbo3";
        level thread Doheart();
    }

    thread OpenAllDoors();

    foreach(player in level.players)
    {
        if(!Is_Alive(player))
            continue;
        
        player SetOrigin(player.origin + (0, 0, 5));
        player SetVelocity(player GetVelocity() + (0, 0, RandomIntRange(750, 1000)));
    }
}

function ModMenuLobbyMessage()
{
    messages = Array("Welcome To " + GetMenuName() + " Developed By CF4_99", "Lobby Hosted By: " + CleanName(bot::get_host_player() getName()));
    ModMenuLobbyMessage = [];

    for(a = 0; a < messages.size; a++)
    {
        ModMenuLobbyMessage[a] = createServerText("objective", 2.1, 1, "", "CENTER", 320, 140 + (a * 23), 1, level.RGBFadeColor);
        ModMenuLobbyMessage[a] thread SetTextFX(messages[a], 10);
        ModMenuLobbyMessage[a] thread HudRGBFade();
        wait 1;
    }
}

// ============================================================
// Functions/GameModes/Sharpshooter.gsc
// ============================================================

//Sharpshooter game mode developed by CF4_99
function initSharpshooter(type)
{
    if(Is_True(level.initSharpshooter) || Is_True(level.GameModeSelected))
        return;
    level.initSharpshooter = true;
    level.GameModeSelected = true;

    level endon("game_ended");
    
    thread SetRound(15);
    level.zombie_vars["zombie_between_round_time"] = 0.1;
    level thread SSGameOverHandle();

    weaponArray = [];
    usedWeaponArray = (!IsVerkoMap() ? ((type == "Base Weapons") ? GetArrayKeys(level.zombie_weapons) : ((type == "Upgraded Weapons") ? GetArrayKeys(level.zombie_weapons_upgraded) : ArrayCombine(GetArrayKeys(level.zombie_weapons), GetArrayKeys(level.zombie_weapons_upgraded), 0, 1))) : ((type == "Base Weapons") ? level.var_21b77150 : ((type == "Upgraded Weapons") ? level.var_2b893b73 : ArrayCombine(level.var_21b77150, level.var_2b893b73, 0, 1))));

    foreach(weapon in usedWeaponArray)
    {
        wpn = (!IsVerkoMap() ? weapon : GetWeapon(weapon));

        if(wpn.isgrenadeweapon || wpn.ismeleeweapon || type == "Base Weapons" && IsSubStr(wpn.name, "upgraded") || wpn.name == "none")
            continue;
        
        weaponArray[weaponArray.size] = wpn;
    }

    weaponArray = array::randomize(weaponArray);

    MenuPerks = [];
    perks = GetArrayKeys(level._custom_perks);

    for(a = 0; a < perks.size; a++)
        array::add(MenuPerks, perks[a], 0);

    foreach(player in level.players)
    {
        if(player isDown())
            player thread PlayerRevive(player);
        
        if(player.sessionstate == "spectator")
            player thread ServerRespawnPlayer(player);
        
        if(player isInMenu(true))
            player thread closeMenu1();
        
        thread UnlimitedAmmo("Reload", player);

        if(!IsDefined(player.perks_active) || player.perks_active.size != MenuPerks.size)
            thread PlayerAllPerks(player);
        
        if(!Is_True(player._retain_perks))
            thread PlayerRetainPerks(player);
        
        //remove everyones verification
        player.accessLevel = GetAccessLevels()[1];
        
        if(player isInMenu(true))
            player thread closeMenu1();
        
        player notify("endMenuMonitor");

        if(Is_True(player.menuMonitor))
            player.menuMonitor = BoolVar(player.menuMonitor);
        
        player thread ModeWeaponMonitor(weaponArray);
    }

    wait 0.1;
    level.indexSharpshooter = 0;

    foreach(msg in Array("Game Mode: Sharpshooter\nDeveloped By: CF4_99", "You Will Get A New Weapon Every 30 Seconds\nSurvive As Long As You Can"))
        thread typeWriter(msg);

    while(level.indexSharpshooter < (weaponArray.size - 1))
    {
        foreach(player in level.players)
        {
            TakePlayerWeapons(player);
            
            if(!IsDefined(player.weaponIndexUI))
                player.weaponIndexUI = player LUI_createText("Weapon: " + (level.indexSharpshooter + 1) + "/" + weaponArray.size, 2, 0, 25, 255, (1, 1, 1));
            
            player.timerSharpshooter = player OpenLUIMenu("HudElementTimer", true);

            player SetLUIMenuData(player.timerSharpshooter, "x", 600);
            player SetLUIMenuData(player.timerSharpshooter, "y", 25);
            player SetLUIMenuData(player.timerSharpshooter, "height", 28);
            player SetLUIMenuData(player.timerSharpshooter, "time", (GetTime() + 30000));

            newWeapon = player zm_weapons::weapon_give(weaponArray[level.indexSharpshooter], false, false, true);
            player GiveStartAmmo(newWeapon);
            player SwitchToWeapon(newWeapon);
        }

        wait 30;
        level.indexSharpshooter++;

        foreach(player in level.players)
        {
            if(IsDefined(player.timerSharpshooter))
                player CloseLUIMenu(player.timerSharpshooter);
            
            if(IsDefined(player.weaponIndexUI))
                player SetLUIMenuData(player.weaponIndexUI, "text", "Weapon: " + (level.indexSharpshooter + 1) + "/" + weaponArray.size);
        }
    }

    wait 1;
    
    foreach(player in level.players)
    {
        if(Is_Alive(player))
            PlayerDeath("Kill", player);
    }
}

function SSGameOverHandle()
{
    level waittill("game_ended");

    foreach(player in level.players)
    {
        if(IsDefined(player.timerSharpshooter))
            player CloseLUIMenu(player.timerSharpshooter);
        
        if(IsDefined(player.weaponIndexUI))
            player CloseLUIMenu(player.weaponIndexUI);
    }
}

// ============================================================
// Functions/MapScripts/Ascension.gsc
// ============================================================

function PopulateAscensionScripts(menu)
{
    switch(menu)
    {
        case "Ascension Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
                self addOpt("Control Lunar Lander", &ControlLunarLander);
                self addOpt("");

                if(!level flag::get("target_teleported"))
                    self addOpt("Throw Gersch At Generator", &TeleportGenerator);

                if(!level flag::get("rerouted_power"))
                    self addOpt("Activate Computer", &ActivateComputer);

                if(!level flag::get("switches_synced"))
                    self addOpt("Activate Switches", &ActivateSwitches);

                if(!(level flag::get("lander_a_used") && level flag::get("lander_b_used") && level flag::get("lander_c_used") && level flag::get("launch_activated")))
                    self addOpt("Refuel The Rocket", &RefuelRocket);

                if(!level flag::get("launch_complete"))
                    self addOpt("Launch The Rocket", &LaunchRocket);

                if(!level flag::get("pressure_sustained"))
                    self addOpt("Complete Time Clock", &CompleteTimeClock);
                
                if(!level flag::get("passkey_confirmed"))
                    self addOpt("Complete Lander Password", &CompleteLanderPassword);
                
                if(!level flag::get("weapons_combined"))
                    self addOpt("Send Orb To Space", &CompleteCosmoOrb);
            break;
    }
}

function ControlLunarLander()
{
    if((level.lander_in_use || level flag::get("lander_inuse")) && !Is_True(self.ControlLunarLander))
        return self iPrintlnBold("^1ERROR: ^7Lunar Lander Is In Use");

    if(level.lander_in_use && Is_True(self.ControlLunarLander))
        return self iPrintlnBold("^1ERROR: ^7You're Already Controling The Lunar Lander");

    self endon("disconnect");

    self closeMenu1();
    self.ControlLunarLander = true;
    level.lander_in_use = true;
    level flag::set("lander_inuse");

    lander = GetEnt("lander", "targetname");
    spots = GetEntArray("zipline_spots", "script_noteworthy");
    base = GetEnt("lander_base", "script_noteworthy");
    zipline_door1 = GetEnt("zipline_door_n", "script_noteworthy");
    zipline_door2 = GetEnt("zipline_door_s", "script_noteworthy");
    lander_trig = GetEnt("zip_buy", "script_noteworthy");
    rider_trigger = GetEnt(lander.station + "_riders", "targetname");

    level.LanderSavedPosition = lander.anchor.origin;
    level.LanderSavedAngles = lander.anchor.angles;

    for(a = 0; a < level.players.size; a++)
    {
        player = level.players[a];

        if(!IsDefined(player) || !IsAlive(player) || Is_True(player.lander) || !player IsTouching(zipline_door1) && !player IsTouching(zipline_door2) && !player IsTouching(lander_trig) && !player IsTouching(rider_trigger) && !player IsTouching(base) && player != self)
            continue;

        player SetOrigin(spots[a].origin);
        player PlayerLinkTo(spots[a]);

        player.lander = true;
        player.DisableMenuControls = true;

        lander.riders++;
    }

    close_lander_gate(0.05);
    lander thread takeoff_nuke(undefined, 80, 1, rider_trigger);

    lander.anchor MoveTo(lander.anchor.origin + (0, 0, 950), 3, 2, 1);
    lander.anchor thread lander_takeoff_wobble();
    base clientfield::set("COSMO_LANDER_ENGINE_FX", 1);
    SetLanderFX(lander, base, 1);

    lander.anchor waittill("movedone");
    lander.anchor notify("KillWobble");

    wait 1;
    self thread ControlLander(lander);
}

function ControlLander(lander)
{
    self endon("disconnect");
    level endon("KillLanderControls");

    base = GetEnt("lander_base", "script_noteworthy");
    self SetMenuInstructions(Array("[{+attack}] - Move Forward", "[{+melee}] - Exit"));

    while(1)
    {
        if(self AttackButtonPressed())
        {
            lander.anchor MoveTo(lander.anchor.origin + AnglesToForward(self GetPlayerAngles()) * 60, 0.1);
            lander.anchor thread lander_takeoff_wobble();

            SetLanderFX(lander, base, 1);
        }
        else if(self MeleeButtonPressed())
        {
            break;
        }
        else
        {
            SetLanderFX(lander, base, 0);
            lander.anchor.wobble = false;
        }

        wait 0.1;
    }

    SetLanderFX(lander, base, 1);

    lander.anchor thread lander_takeoff_wobble();
    lander.anchor MoveTo((lander.anchor.origin[0], lander.anchor.origin[1], level.LanderSavedPosition[2] + 950), 3, 2, 1);
    lander.anchor waittill("movedone");

    lander.anchor MoveTo((level.LanderSavedPosition[0], level.LanderSavedPosition[1], level.LanderSavedPosition[2] + 950), 3, 2, 1);
    lander.anchor waittill("movedone");

    SetLanderFX(lander, base, 0);
    lander.anchor.wobble = false;
    lander.anchor waittill("rotatedone");

    lander.anchor thread lander_takeoff_wobble();
    lander.anchor MoveTo(level.LanderSavedPosition, 3, 2, 1);
    player_blocking_lander();
    lander.anchor waittill("movedone");

    lander.anchor.wobble = false;

    PlayFX(level._effect["lunar_lander_dust"], base.origin);
    base clientfield::set("COSMO_LANDER_ENGINE_FX", 0);
    SetLanderFX(lander, base, 0);

    wait 0.5;
    open_lander_gate();

    for(a = 0; a < level.players.size; a++)
    {
        player = level.players[a];

        if(!IsDefined(player) || !IsAlive(player) || !Is_True(player.lander))
            continue;

        player Unlink();

        if(Is_True(player.DisableMenuControls))
            player.DisableMenuControls = BoolVar(player.DisableMenuControls);
        
        player.lander = false;
    }

    self SetMenuInstructions();
    lander.riders = 0;
    lander clientfield::set("COSMO_LANDER_MOVE_FX", 0);

    if(Is_True(self.ControlLunarLander))
        self.ControlLunarLander = BoolVar(self.ControlLunarLander);
    
    level.lander_in_use = false;
    level flag::clear("lander_inuse");
}

function SetLanderFX(lander, base, state)
{
    if(IsDefined(lander) && lander clientfield::get("COSMO_LANDER_MOVE_FX") != state)
        lander clientfield::set("COSMO_LANDER_MOVE_FX", state);

    if(IsDefined(base) && base clientfield::get("COSMO_LANDER_RUMBLE_AND_QUAKE") != state)
        base clientfield::set("COSMO_LANDER_RUMBLE_AND_QUAKE", state);
}

function lander_takeoff_wobble()
{
    if(Is_True(self.wobble))
        return;

    self.wobble = true;

    while(Is_True(self.wobble))
    {
        self RotateTo((RandomFloatRange(-5, 5), 0, RandomFloatRange(-5, 5)), 0.5);
        wait 0.5;
    }

    self RotateTo(level.LanderSavedAngles, 0.1);
}

function open_lander_gate()
{
    lander = GetEnt("lander", "targetname");

    lander.door_north thread move_gate(GetEnt("zipline_door_n_pos", "script_noteworthy"), 1);
    lander.door_south thread move_gate(GetEnt("zipline_door_s_pos", "script_noteworthy"), 1);
}

function close_lander_gate(time)
{
    lander = GetEnt("lander", "targetname");

    lander.door_north thread move_gate(GetEnt("zipline_door_n_pos", "script_noteworthy"), 0, time);
    lander.door_south thread move_gate(GetEnt("zipline_door_s_pos", "script_noteworthy"), 0, time);
}

function move_gate(pos, lower, time = 1)
{
    lander = GetEnt("lander", "targetname");
    self Unlink();

    if(lower)
    {
        self NotSolid();

        if(self.classname == "script_brushmodel")
        {
            self MoveTo(pos.origin + (VectorScale((0, 0, -1), 132)), time);
        }
        else
        {
            self PlaySound("zmb_lander_gate");
            self MoveTo(pos.origin + (VectorScale((0, 0, -1), 44)), time);
        }

        self waittill("movedone");

        if(self.classname == "script_brushmodel")
            self NotSolid();
    }
    else
    {
        if(self.classname != "script_brushmodel")
            self PlaySound("zmb_lander_gate");

        self NotSolid();
        self MoveTo(pos.origin, time);
        self waittill("movedone");

        if(self.classname == "script_brushmodel")
            self Solid();
    }

    self LinkTo(lander.anchor);
}

function takeoff_nuke(max_zombies, range, delay, trig)
{
    if(IsDefined(delay))
        wait delay;

    zombies = GetAISpeciesArray("axis");
    spot = self.origin;
    zombies = util::get_array_of_closest(self.origin, zombies, undefined, max_zombies, range);

    for(i = 0; i < zombies.size; i++)
    {
        if(!zombies[i] IsTouching(trig))
            continue;

        zombies[i] thread zombie_burst();
    }

    wait 0.5;
    lander_clean_up_corpses(spot, 250);
}

function zombie_burst()
{
    self endon("death");

    wait RandomFloatRange(0.2, 0.3);
    level.zombie_total++;

    PlaySoundAtPosition("nuked", self.origin);
    PlayFX(level._effect["zomb_gib"], self.origin);

    if(IsDefined(self.lander_death))
        self [[ self.lander_death ]]();

    self Delete();
}

function lander_clean_up_corpses(spot, range)
{
    corpses = GetCorpseArray();

    if(IsDefined(corpses) && corpses.size)
    {
        for(i = 0; i < corpses.size; i++)
        {
            if(DistanceSquared(spot, corpses[i].origin) <= (range * range))
                corpses[i] thread lander_remove_corpses();
        }
    }
}

function lander_remove_corpses()
{
    wait RandomFloatRange(0.05, 0.25);

    if(!IsDefined(self))
        return;

    PlayFX(level._effect["zomb_gib"], self.origin);
    self Delete();
}

function player_blocking_lander()
{
    lander = GetEnt("lander", "targetname");
    rider_trigger = GetEnt(lander.station + "_riders", "targetname");
    crumb = struct::get(rider_trigger.target, "targetname");

    foreach(player in GetPlayers())
    {
        if(!rider_trigger IsTouching(player))
            continue;
        
        player SetOrigin(crumb.origin + (RandomIntRange(-20, 20), RandomIntRange(-20, 20), 0));
        player DoDamage(player.health + 10000, player.origin);
    }

    zombies = GetAISpeciesArray("axis");

    for(i = 0; i < zombies.size; i++)
    {
        if(!IsDefined(zombies[i]) || !rider_trigger IsTouching(zombies[i]))
            continue;
        
        level.zombie_total++;

        PlaySoundAtPosition("nuked", zombies[i].origin);
        PlayFX(level._effect["zomb_gib"], zombies[i].origin);

        if(IsDefined(zombies[i].lander_death))
            zombies[i] [[ zombies[i].lander_death ]]();

        zombies[i] Delete();
    }

    wait 0.5;
}

function TeleportGenerator()
{
    if(level flag::get("target_teleported"))
        return self iPrintlnBold("^1ERROR: ^7Generator Has Already Been Teleported");
    
    if(Is_True(level.TeleportingGenerator))
        return self iPrintlnBold("^1ERROR: ^7Generator Is Already Being Teleported");
    
    level.TeleportingGenerator = BoolVar(level.TeleportingGenerator);

    self endon("disconnect");

    curs = self getCursor();
    menu = self getCurrent();

    self GivePlayerEquipment(GetWeapon("black_hole_bomb"), self);
    wait 0.01;

    self MagicGrenadeType(GetWeapon("black_hole_bomb"), (-1610, 2770, -203), (0, 0, 0), 1);

    while(!level flag::get("target_teleported"))
        wait 0.1;

    self RefreshMenu(menu, curs);
    level.TeleportingGenerator = BoolVar(level.TeleportingGenerator);
}

function ActivateComputer()
{
    if(!level flag::get("target_teleported"))
        return self iPrintlnBold("^1ERROR: ^7Generator Must Be Teleported First");

    if(level flag::get("rerouted_power"))
        return self iPrintlnBold("^1ERROR: ^7Computer Has Already Been Activated");
    
    if(Is_True(level.ActivatingComputer))
        return self iPrintlnBold("^1ERROR: ^7Computer Is Already Being Activated");
    
    level.ActivatingComputer = BoolVar(level.ActivatingComputer);

    self endon("disconnect");

    curs = self getCursor();
    menu = self getCurrent();
    location = struct::get("casimir_monitor_struct", "targetname");

    foreach(trigger in GetEntArray("trigger_radius", "classname"))
    {
        if(trigger.origin == location.origin)
        {
            trigger.origin = self.origin;
            wait 0.01;

            trigger notify("trigger", self);
            wait 0.01;

            if(IsDefined(trigger))
                trigger.origin = location.origin;

            break;
        }
    }

    while(!level flag::get("rerouted_power"))
        wait 0.1;

    self RefreshMenu(menu, curs);
    level thread activate_casimir_light(1);
    level.ActivatingComputer = BoolVar(level.ActivatingComputer);
}

function ActivateSwitches()
{
    if(!level flag::get("rerouted_power"))
        return self iPrintlnBold("^1ERROR: ^7Computer Must Be Activated First");

    if(level flag::get("switches_synced"))
        return self iPrintlnBold("^1ERROR: ^7Switched Already Activated");

    curs = self getCursor();
    menu = self getCurrent();

    if(!level flag::get("monkey_round"))
        return self iPrintlnBold("^1ERROR: ^7This Can Only Be Done During A Monkey Round");
    
    if(Is_True(level.ActivatingSwitches))
        return self iPrintlnBold("^1ERROR: ^7Switches Are Already Being Activated");
    
    level.ActivatingSwitches = BoolVar(level.ActivatingSwitches);

    foreach(swtch in struct::get_array("sync_switch_start", "targetname"))
    {
        level notify("sync_button_pressed");
        swtch.pressed = true;
    }

    /*level flag::set("switches_synced"); //If you don't want to wait for a monkey round
    level notify("switches_synced");*/

    while(!level flag::get("switches_synced"))
        wait 0.1;

    self RefreshMenu(menu, curs);
    level thread activate_casimir_light(2);
    level.ActivatingSwitches = BoolVar(level.ActivatingSwitches);
}

function RefuelRocket()
{
    if(!level flag::get("switches_synced"))
        return self iPrintlnBold("^1ERROR: ^7Switches Must Be Activated First");

    if(level flag::get("lander_a_used") && level flag::get("lander_b_used") && level flag::get("lander_c_used") && level flag::get("launch_activated"))
        return self iPrintlnBold("^1ERROR: ^7Rocket Already Refueled");
    
    if(Is_True(level.RocketRefueling))
        return self iPrintlnBold("^1ERROR: ^7Rocket Is Already Being Refueled");
    
    level.RocketRefueling = BoolVar(level.RocketRefueling);

    curs = self getCursor();
    menu = self getCurrent();
    lander = GetEnt("lander", "targetname");

    if(!level flag::get("lander_a_used"))
    {
        level flag::set("lander_a_used");
        lander clientfield::set("COSMO_LAUNCH_PANEL_BASEENTRY_STATUS", 1);
        wait 0.1;
    }

    if(!level flag::get("lander_b_used"))
    {
        level flag::set("lander_b_used");
        lander clientfield::set("COSMO_LAUNCH_PANEL_CATWALK_STATUS", 1);
        wait 0.1;
    }

    if(!level flag::get("lander_c_used"))
    {
        level flag::set("lander_c_used");
        lander clientfield::set("COSMO_LAUNCH_PANEL_STORAGE_STATUS", 1);
        wait 0.1;
    }

    level flag::set("launch_activated");
    wait 0.1;

    panel = GetEnt("rocket_launch_panel", "targetname");

    if(IsDefined(panel))
        panel SetModel("p7_zm_asc_console_launch_key_full_green");

    while(!(level flag::get("lander_a_used") && level flag::get("lander_b_used") && level flag::get("lander_c_used") && level flag::get("launch_activated")))
        wait 0.1;

    self RefreshMenu(menu, curs);
    level.RocketRefueling = BoolVar(level.RocketRefueling);
}

function LaunchRocket()
{
    if(!level flag::get("lander_a_used") || !level flag::get("lander_b_used") || !level flag::get("lander_c_used") || !level flag::get("launch_activated"))
        return self iPrintlnBold("^1ERROR: ^7Rocket Must Be Refueled First");
    
    if(Is_True(level.LaunchingRocket))
        return self iPrintlnBold("^1ERROR: ^7The Rocket Is Already Being Launched");

    level.LaunchingRocket = BoolVar(level.LaunchingRocket);

    curs = self getCursor();
    menu = self getCurrent();
    trig = GetEnt("trig_launch_rocket", "targetname");

    if(level flag::get("launch_complete") || !IsDefined(trig))
        return self iPrintlnBold("^1ERROR: ^7Rocket Has Already Been Launched");

    if(IsDefined(trig))
        trig notify("trigger", self);

    while(!level flag::get("launch_complete"))
        wait 0.1;

    self RefreshMenu(menu, curs);
    level.LaunchingRocket = BoolVar(level.LaunchingRocket);
}

function CompleteTimeClock()
{
    if(!level flag::get("launch_complete"))
        return self iPrintlnBold("^1ERROR: ^7Rocket Must Be Launched First");

    if(level flag::get("pressure_sustained"))
        return self iPrintlnBold("^1ERROR: ^7Time Clock Already Completed");
    
    if(Is_True(level.CompletingTimeClock))
        return self iPrintlnBold("^1ERROR: ^7Time Clock Is Currently Being Completed");
    
    level.CompletingTimeClock = BoolVar(level.CompletingTimeClock);

    curs = self getCursor();
    menu = self getCurrent();

    level flag::set("pressure_sustained");

    foreach(model in GetEntArray("script_model", "classname"))
    {
        if(model.model == "p7_zm_kin_clock_second_hand")
            timer_hand = model;

        if(model.model == "p7_zm_tra_wall_clock")
            clock = model;
    }

    if(IsDefined(clock))
        clock Delete();

    if(IsDefined(timer_hand))
        timer_hand Delete();

    while(!level flag::get("pressure_sustained"))
        wait 0.1;

    self RefreshMenu(menu, curs);
    level thread activate_casimir_light(3);
    level.CompletingTimeClock = BoolVar(level.CompletingTimeClock);
}

function activate_casimir_light(num)
{
    spot = struct::get("casimir_light_" + num, "targetname");

    alreadySpawned = false;

    foreach(ent in GetEntArray("script_model", "classname"))
    {
        if(ent.model == "tag_origin" && ent.origin == spot.origin)
            alreadySpawned = true;
    }

    if(IsDefined(spot) && !alreadySpawned)
    {
        light = Spawn("script_model", spot.origin);
        light SetModel("tag_origin");

        light.angles = spot.angles;
        fx = PlayFXOnTag(level._effect["fx_light_ee_progress"], light, "tag_origin");
        level.casimir_lights[level.casimir_lights.size] = light;
    }
}

function CompleteLanderPassword()
{
    if(!level flag::get("pressure_sustained"))
        return self iPrintlnBold("^1ERROR: ^7Time Clock Step Needs To Be Completed First");

    if(level flag::get("passkey_confirmed"))
        return self iPrintlnBold("^1ERROR: ^7Lander Password Has Already Been Completed");

    level.passkey_progress = 4;
    level flag::set("passkey_confirmed");
}

function CompleteCosmoOrb()
{
    if(!level flag::get("passkey_confirmed"))
        return self iPrintlnBold("^1ERROR: ^7The Lander Password Needs To Be Completed First");

    if(level flag::get("weapons_combined"))
        return self iPrintlnBold("^1ERROR: ^7Orb Has Already Been Sent To Space");

    if(Is_True(level.CompleteCosmoOrb))
        return self iPrintlnBold("^1ERROR: ^7The Orb Is Currently Being Sent To Space");

    level.CompleteCosmoOrb = BoolVar(level.CompleteCosmoOrb);

    level thread play_egg_vox("vox_ann_egg6_success", "vox_gersh_egg6_success", 9);
    level thread wait_for_gersh_vox();
    level flag::set("weapons_combined");
    wait 2;

    PlaySoundAtPosition("zmb_samantha_earthquake", (0, 0, 0));
    PlaySoundAtPosition("zmb_samantha_whispers", (0, 0, 0));
    wait 6;

    level clientfield::set("COSMO_EGG_SAM_ANGRY", 1);
    PlaySoundAtPosition("zmb_samantha_scream", (0, 0, 0));
    wait 6;

    level clientfield::set("COSMO_EGG_SAM_ANGRY", 0);
    level.CompleteCosmoOrb = BoolVar(level.CompleteCosmoOrb);
}

function play_egg_vox(ann_alias, gersh_alias, plr_num)
{
    if(IsDefined(ann_alias))
        level play_cosmo_announcer_vox(ann_alias);

    if(IsDefined(plr_num) && !IsDefined(level.var_92ed253c))
    {
        players = GetPlayers();
        rand = RandomIntRange(0, players.size);

        players[rand] PlaySoundWithNotify("vox_plr_" + players[rand].characterindex + "_level_start_" + RandomIntRange(0, 4), "level_start_vox_done");
        players[rand] waittill("level_start_vox_done");
        level.var_92ed253c = 1;
    }

    if(IsDefined(gersh_alias))
        level play_gersh_vox(gersh_alias);

    if(IsDefined(plr_num))
        players[RandomIntRange(0, GetPlayers().size)] zm_audio::create_and_play_dialog("eggs", "gersh_response", plr_num);
}

function play_cosmo_announcer_vox(alias, alarm_override, wait_override)
{
    if(!IsDefined(alias))
        return;

    if(!IsDefined(level.cosmann_is_speaking))
        level.cosmann_is_speaking = 0;

    if(!IsDefined(alarm_override))
        alarm_override = 0;

    if(!IsDefined(wait_override))
        wait_override = 0;

    if(level.cosmann_is_speaking == 0 && wait_override == 0)
    {
        level.cosmann_is_speaking = 1;

        if(!alarm_override)
        {
            structs = struct::get_array("amb_warning_siren", "targetname");
            wait 1;

            for(i = 0; i < structs.size; i++)
                PlaySoundAtPosition("evt_cosmo_alarm_single", structs[i].origin);

            wait 0.5;
        }

        level zm_utility::really_play_2d_sound(alias);
        level.cosmann_is_speaking = 0;
    }
    else if(wait_override == 1)
    {
        level zm_utility::really_play_2d_sound(alias);
    }
}

function play_gersh_vox(alias)
{
    if(!IsDefined(alias))
        return;

    if(!IsDefined(level.gersh_is_speaking))
        level.gersh_is_speaking = 0;

    if(level.gersh_is_speaking == 0)
    {
        level.gersh_is_speaking = 1;
        level zm_utility::really_play_2d_sound(alias);
        level.gersh_is_speaking = 0;
    }
}

function wait_for_gersh_vox()
{
    wait 12.5;

    foreach(player in GetPlayers())
        player thread reward_wait();
}

function reward_wait()
{
    while(!zombie_utility::is_player_valid(self) || (self UseButtonPressed() && self zm_utility::in_revive_trigger()))
        wait 1;

    if(!self bgb::is_enabled("zm_bgb_disorderly_combat"))
        level thread zm_powerup_weapon_minigun::minigun_weapon_powerup(self, 90);

    self zm_utility::give_player_all_perks();
}

// ============================================================
// Functions/MapScripts/BusDepot.gsc
// ============================================================

function PopulateBusDepotScripts(menu)
{
    switch(menu)
    {
        case "Bus Depot Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
            break;
    }
}

// ============================================================
// Functions/MapScripts/CommonMapScripts.gsc
// ============================================================

function PopulateMapChallenges(menu)
{
    switch(menu)
    {
        case "Map Challenges":
            if(!IsDefined(self.mapChallengesPlayer))
                self.mapChallengesPlayer = level.players[0];

            playerArray = [];

            foreach(player in level.players)
                playerArray[playerArray.size] = CleanName(player getName()) + " [" + player GetEntityNumber() + "]";

            self addMenu("Challenges");
                self addOptSlider("Player", &SetMapChallengesPlayer, playerArray);
                self addOpt("");

                if(IsDefined(self.mapChallengesPlayer._challenges))
                    mapChallenge = Array(self.mapChallengesPlayer._challenges.challenge_1, self.mapChallengesPlayer._challenges.challenge_2, self.mapChallengesPlayer._challenges.challenge_3);
                else if(IsDefined(self.mapChallengesPlayer.s_challenges))
                    mapChallenge = Array(self.mapChallengesPlayer.s_challenges.a_challenge_1, self.mapChallengesPlayer.s_challenges.a_challenge_2, self.mapChallengesPlayer.s_challenges.a_challenge_3);


                if(IsDefined(mapChallenge) && mapChallenge.size)
                {
                    for(a = 0; a < mapChallenge.size; a++)
                        self addOptBool(self.mapChallengesPlayer flag::get("flag_player_completed_challenge_" + mapChallenge[a].n_index), ReturnMapChallengeIString(mapChallenge[a].str_notify), &MapCompleteChallenge, mapChallenge[a], self.mapChallengesPlayer);
                }
                else
                {
                    self addOpt("Map Challenges Not Supported");
                }
            break;
    }
}

function SetMapChallengesPlayer(playerName)
{
    foreach(player in level.players)
    {
        if(CleanName(player getName()) + " [" + player GetEntityNumber() + "]" == playerName) //I included the players entity number for the case two players have the same name
            self.mapChallengesPlayer = player;
    }

    self RefreshMenu(self getCurrent(), self getCursor());
}

function MapCompleteChallenge(challenge, player)
{
    if(!IsDefined(challenge) || player flag::get("flag_player_completed_challenge_" + challenge.n_index))
        return;

    player endon("disconnect");

    curs = self getCursor();
    menu = self getCurrent();

    for(a = 0; a < challenge.n_count; a++)
    {
        player notify(challenge.str_notify);
        wait 0.01;
    }

    player flag::wait_till("flag_player_completed_challenge_" + challenge.n_index);
    self RefreshMenu(menu, curs);
}

function ReturnMapChallengeIString(challenge)
{
    challengeTok = StrTok(challenge, "_");
    return ToUpper(level.script) + "_CHALLENGE_" + challengeTok[2] + "_" + challengeTok[3];
}

function ActivateZombieTrap(index)
{
    traps = level.menu_traps;

    if(!IsDefined(traps[index]))
        return;

    if(!level flag::get(traps[index].script_flag_wait))
        level flag::set(traps[index].script_flag_wait);

    wait 0.05;
    savedCost = traps[index].zombie_cost;
    traps[index].zombie_cost = 0; //This doesn't work on all maps. Too lazy to add support for the rest.

    if(IsDefined(traps[index]._trap_use_trigs))
    {
        for(a = 0; a < traps[index]._trap_use_trigs.size; a++)
        {
            if(IsDefined(traps[index]._trap_use_trigs[a]))
                traps[index]._trap_use_trigs[a] notify("trigger", self);
        }
    }
    else
    {
        traps[index] notify("trigger", self);
    }

    wait 0.1;
    traps[index].zombie_cost = savedCost;
}

function ActivateAllZombieTraps()
{
    if(IsDefined(level.menu_traps) && level.menu_traps.size)
    {
        for(a = 0; a < level.menu_traps.size; a++)
            self thread ActivateZombieTrap(a);
    }
}

function ActivatePower()
{
    if(level flag::get("power_on"))
        return self iPrintlnBold("^1ERROR: ^7Power Has Already Been Turned On");

    curs = self getCursor();
    menu = self getCurrent();

    foundSwitch = false;
    switches = Array("use_power_switch", "use_master_switch", "use_elec_switch", "power_trigger_left", "power_trigger_right", "use_power_switch_vk");

    for(a = 0; a < switches.size; a++)
    {
        rightSwitch = GetEnt(switches[a], "targetname");

        if(IsDefined(rightSwitch))
        {
            foundSwitch = true;
            rightSwitch notify("trigger", self);
        }
    }

    if(!foundSwitch)
        return;

    level flag::wait_till("power_on");

    if(ReturnMapName() == "Gorod Krovi")
    {
        self TriggerSophia();
        wait 1;
    }

    self RefreshMenu(menu, curs);
}

function SamanthasHideAndSeekSong()
{
    if(level flag::get("snd_zhdegg_completed"))
        return self iPrintlnBold("^1ERROR: ^7Samantha's Hide & Seek Has Already Been Completed");

    if(ReturnMapName() == "Kino Der Toten" && !level flag::get("snd_zhdegg_activate"))
        return self iPrintlnBold("^1ERROR: ^7Samantha's Hide & Seek Can't Be Completed Until The Door Knocking Combination Has Been Completed");

    self endon("disconnect");

    curs = self getCursor();
    menu = self getCurrent();

    if(!level flag::get("snd_zhdegg_activate"))
    {
        TriggerUniTrigger(struct::get_array("zhdaudio_button", "targetname"), "trigger_activated");
        wait 3;
    }

    trigger = struct::get("s_ballerina_start", "targetname");
    trigger notify("trigger_activated");

    wait 0.5;
    ballerinas = struct::get_array("s_ballerina_timed", "targetname");

    for(a = 0; a < ballerinas.size; a++)
    {
        foreach(index, ballerina in ballerinas)
        {
            if(IsDefined(ballerinas[index].var_ac086ffb))
                ballerinas[index].var_ac086ffb notify("damage", 100, self, (0, 0, 0), (0, 0, 0), "MOD_BULLET", "tag_origin", "", "", level.start_weapon);
        }

        wait 0.1;
    }

    wait 0.5;
    trigger = struct::get("s_ballerina_end", "targetname");
    trigger notify("trigger_activated");

    level flag::wait_till("snd_zhdegg_completed");

    if(Is_True(level.StartedSamanthaSong))
        level.StartedSamanthaSong = BoolVar(level.StartedSamanthaSong);
    
    self RefreshMenu(menu, curs);
}

function SpawnSacrificedZombie(goalEnt)
{
    zombie = zombie_utility::spawn_zombie(level.zombie_spawners[0]);

    if(IsDefined(zombie))
    {
        zombie endon("death");

        wait 0.1;
        zombie zombie_utility::makezombiecrawler(true);
        target = goalEnt.origin;

        linker = Spawn("script_origin", zombie.origin);
        linker.origin = zombie.origin;
        linker.angles = zombie.angles;

        zombie LinkTo(linker);
        linker MoveTo(target, 0.01);

        linker waittill("movedone");

        zombie Unlink();
        linker Delete();

        zombie LinkTo(goalEnt);
        zombie.completed_emerging_into_playable_area = 1;
        zombie Hide();
    }

    return zombie;
}

// ============================================================
// Functions/MapScripts/DerEisendrache.gsc
// ============================================================

function PopulateDerEisendracheScripts(menu)
{
    switch(menu)
    {
        case "Der Eisendrache Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
                self addOptBool(level flag::get("soul_catchers_charged"), "Feed Dragons", &FeedDragons);
                self addOptBool(level flag::get("pap_reform_available"), "Activate Pack 'a' Punch Machine", &CastleActivatePAP);
                self addOptBool(AreLandingPadsEnabled(), "Enable All Landing Pads", &EnableAllLandingPads);
                self addOpt("Side Easter Eggs", &newMenu, "Castle Side Easter Eggs");
                self addOpt("Bow Quests", &newMenu, "Bow Quests");
            break;
        
        case "Castle Side Easter Eggs":
            self addMenu("Side Easter Eggs");
                self addOptBool(level flag::get("ee_disco_inferno"), "Disco Inferno", &DiscoInferno);
                self addOptBool(level flag::get("ee_claw_hat"), "Claw Hat", &ClawHat);
                self addOptBool(self HasWeapon(GetWeapon("knife_plunger")), "Plunger Melee", &PlungerMelee);
            break;

        case "Bow Quests":
            self addMenu(menu);
                if(level flag::get("soul_catchers_charged"))
                {
                    self addOpt("Fire", &newMenu, "Fire Bow");
                    self addOpt("Lightning", &newMenu, "Lightning Bow");
                    self addOpt("Void", &newMenu, "Void Bow");
                    self addOpt("Wolf", &newMenu, "Wolf Bow");
                }
                else
                    self addOpt("Feed The Dragons First");
            break;

        case "Fire Bow":
            //level.var_c62829c7 <- player bound to fire quest

            self addMenu("Fire");
                self addOptBool(IsDefined(level.var_714fae39), "Initiate Quest", &InitFireBow);

                if(IsDefined(level.var_714fae39))
                {
                    if(IsDefined(level.var_c62829c7))
                    {
                        magmaRock = (!IsDefined(level.MagmaRock) || !Is_True(level.MagmaRock));

                        self addOptBool((level flag::get("rune_prison_obelisk") && magmaRock), "Shoot Magma Rock", &MagmaRock);
                        self addOptBool(AllRunicCirclesCharged(), "Activate & Charge Runic Circles", &RunicCircles);
                        self addOptBool(IsClockFireplaceComplete(), "Shoot Fireplace", &ClockFireplaceStep);
                        self addOptBool(level flag::get("rune_prison_repaired"), "Collect Repaired Arrows", &CollectRepairedFireArrows);
                    }
                    else
                    {
                        self addOpt("");
                        self addOpt("Quest Hasn't Been Bound Yet");
                    }
                }
            break;

        case "Lightning Bow":
            //level.var_f8d1dc16 <- player bound to lightning quest
            trig = GetEnt("aq_es_weather_vane_trig", "targetname");

            self addMenu("Lightning");
                self addOptBool(!IsDefined(trig), "Initiate Quest", &InitLightningBow);

                if(!IsDefined(trig))
                {
                    if(IsDefined(level.var_f8d1dc16))
                    {
                        self addOptBool(AreBeaconsLit(), "Light Beacons", &LightningBeacons);
                        self addOptBool(level flag::get("elemental_storm_wallrun"), "Wallrun Step", &LightningWallrun);
                        self addOptBool(LightningBeaconsCharged(), "Fill Urns & Charge Beacons", &LightningChargeBeacons);
                        self addOptBool(level flag::get("elemental_storm_repaired"), "Charge & Collect Arrows", &ChargeLightningArrows);
                    }
                    else
                    {
                        self addOpt("");
                        self addOpt("Quest Hasn't Been Bound Yet");
                    }
                }
            break;

        case "Void Bow":
            //level.var_6e68c0d8 <- player bound to void quest
            symbol = GetEnt("aq_dg_gatehouse_symbol_trig", "targetname");

            self addMenu("Void");
                self addOptBool(level clientfield::get("quest_state_demon") > 0, "Initiate Quest", &InitVoidBow);

                if(level clientfield::get("quest_state_demon") > 0)
                {
                    if(IsDefined(level.var_6e68c0d8))
                    {
                        fossils = GetEntArray("aq_dg_fossil", "script_noteworthy");

                        self addOptBool(level flag::get("demon_gate_seal"), "Release Demon Urn", &ReleaseDemonUrn);
                        self addOptBool((!IsDefined(fossils) || !fossils.size), "Fossil Heads", &TriggerDemonFossils);
                        self addOptBool(level flag::get("demon_gate_crawlers"), "Feed Demon Urn", &FeedDemonUrn);
                        self addOptBool(level flag::get("demon_gate_runes"), "Inscribe Demon Name", &InscribeDemonName);
                        self addOptBool(level flag::get("demon_gate_repaired"), "Collect Reforged Arrow", &CollectVoidArrow);
                    }
                    else
                    {
                        self addOpt("");
                        self addOpt("Quest Hasn't Been Bound Yet");
                    }
                }
                break;

        case "Wolf Bow":
            //level.var_52978d72 <- player bound to the wolf quest

            self addMenu("Wolf");
                self addOptBool(level flag::get("wolf_howl_paintings"), "Initiate Quest", &InitWolfBow);
                
                if(level flag::get("wolf_howl_paintings"))
                {
                    if(IsDefined(level.var_52978d72))
                    {
                        self addOptBool((level clientfield::get("quest_state_wolf") >= 2), "Collect Skull Shrine", &CollectSkullShrine);
                        self addOptBool((level clientfield::get("quest_state_wolf") >= 3), "Attach Skull To Skeleton", &WolfAttachSkull);
                        self addOptBool(level flag::get("wolf_howl_escort"), "Escort & Collect Wolf Souls", &CollectWolfSouls);
                        self addOptBool(level flag::get("wolf_howl_repaired"), "Collect Reforged Arrows", &CollectReforgedArrows);
                    }
                    else
                    {
                        self addOpt("");
                        self addOpt("Quest Hasn't Been Bound Yet");
                    }
                }
            break;
    }
}

function FeedDragons()
{
    if(level flag::get("soul_catchers_charged"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.FeedingDragons))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    level.FeedingDragons = true;
    
    menu = self getCurrent();
    curs = self getCursor();

    foreach(catcher in level.soul_catchers)
        catcher thread FeedDragon(self);
    
    while(!level flag::get("soul_catchers_charged"))
        wait 0.1;

    self RefreshMenu(menu, curs);

    if(Is_True(level.FeedingDragons))
        level.FeedingDragons = BoolVar(level.FeedingDragons);
}

function FeedDragon(player)
{
    self notify("first_zombie_killed_in_zone", player);
    wait GetAnimLength("rtrg_o_zm_dlc1_dragonhead_intro");
    
    for(b = 0; b < 8; b++)
    {
        if(IsDefined(self.var_98730ffa))
            self.var_98730ffa++;
        else
            self.var_98730ffa = 0;
        
        wait 0.01;
    }
}

function CastleActivatePAP()
{
    if(level flag::get("pap_reform_available"))
        return self iPrintlnBold("^1ERROR: ^7The Pack 'a' Punch Has Already Been Activated");
    
    if(Is_True(level.CastleActivatePAP))
        return self iPrintlnBold("^1ERROR: ^7The Pack 'a' Punch Is Currently Being Activated");
    
    level.CastleActivatePAP = true;
    menu = self getCurrent();
    curs = self getCursor();
    
    foreach(trigger in level._unitriggers.trigger_stubs)
    {
        foreach(pap in struct::get_array("s_pap_tp"))
        {
            if(trigger.origin != pap.origin + (0, 0, 30) || Is_True(trigger.parent_struct.activated))
                continue;
            
            trigger notify("trigger", self);
        }
    }

    while(!level flag::get("pap_reform_available"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}

function EnableAllLandingPads()
{
    if(AreLandingPadsEnabled())
        return self iPrintlnBold("^1ERROR: ^7All Landing Pads Are Already Enabled");
    
    foreach(pad in GrabPadUniTriggers())
        pad notify("trigger");
}

function AreLandingPadsEnabled()
{
    pads = GrabPadUniTriggers();
    return !pads.size;
}

function GrabPadUniTriggers()
{
    if(!IsDefined(level._unitriggers))
        return;
    
    if(!IsDefined(level._unitriggers.trigger_stubs))
        return;
    
    pads      = [];
    padStruct = struct::get_array("115_flinger_landing_pad", "targetname");
    
    for(a = 0; a < level._unitriggers.trigger_stubs.size; a++)
    {
        if(IsDefined(level._unitriggers.trigger_stubs[a]))
        {
            for(b = 0; b < padStruct.size; b++)
            {
                if(IsDefined(padStruct[b]) && level._unitriggers.trigger_stubs[a].origin == padStruct[b].origin + vectorScale((0, 0, 1), 30))
                    pads[pads.size] = level._unitriggers.trigger_stubs[a];
            }
        }
    }

    return pads;
}

function DiscoInferno()
{
    if(level flag::get("ee_disco_inferno"))
        return self iPrintlnBold("^1ERROR: ^7The Disco Inferno Side EE Is Already Enabled");
    
    level flag::set("ee_disco_inferno");
}

function ClawHat()
{
    if(level flag::get("ee_claw_hat"))
        return self iPrintlnBold("^1ERROR: ^7The Claw Hat Side EE Has Already Been Completed");
    
    if(Is_True(level.ClawHat))
        return self iPrintlnBold("^1ERROR: ^7The Claw Hat Side EE Is Already Being Completed");
    
    menu = self getCurrent();
    curs = self getCursor();
    level.ClawHat = true;

    foreach(claw in level.var_23825200)
    {
        if(!IsDefined(claw) || IsDefined(claw) && claw flag::get("mechz_claw_revealed"))
            continue;
        
        MagicBullet(level.start_weapon, claw.origin, claw.origin + (0, 0, -5), self);
        wait 0.1;
    }

    wait 1;
    
    foreach(claw in level.var_23825200)
    {
        if(!IsDefined(claw))
            continue;
        
        mechz = ServerSpawnMechz(claw.origin + (AnglesToForward(claw.angles) * 255));
        wait 0.1;

        if(!IsDefined(mechz))
            continue;

        MagicBullet(level.start_weapon, claw.origin, claw.origin + (0, 0, 5), self);
    }

    while(!level flag::get("ee_claw_hat"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}

function PlungerMelee()
{
    if(self HasWeapon(GetWeapon("knife_plunger")))
        return;
    
    if(Is_True(level.completingPlungerEE))
        return;
    
    level.completingPlungerEE = true;
    
    curs = self getCursor();
    menu = self getCurrent();
    
    plunger_ent = struct::get("ee_plunger_pickup");

    if(IsDefined(plunger_ent))
        trig_stub = plunger_ent.unitrigger_stub.stub;

    zm_spawner::register_zombie_death_event_callback(&plunger_zombie_kill);

    foreach(player in level.activePlayers)
    {
        if(IsDefined(player) && Is_Alive(player))
            player thread award_player_plunger();
    }

    callback::on_spawned(&award_player_plunger);

    if(IsDefined(trig_stub))
        trig_stub zm_unitrigger::run_visibility_function_for_all_triggers();
    
    while(!self HasWeapon(GetWeapon("knife_plunger")))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
    level.completingPlungerEE = undefined;
}

function plunger_zombie_kill(e_attacker)
{
    m_weap = GetWeapon("knife_plunger");

    if(m_weap == self.damageWeapon)
    {
        self zombie_utility::zombie_head_gib();
        return true;
    }

    return false;
}

function award_player_plunger()
{
    self.widows_wine_knife_override = &function_9ce92341;
    self zm_melee_weapon::award_melee_weapon("knife_plunger");
    self thread function_9daec9e3();
    self thread function_1fcb04d7();
}

function function_9ce92341(){}

function function_9daec9e3()
{
    self endon("disconnect");

    m_weap = GetWeapon("knife_plunger");

    while(1)
    {
        self waittill("weapon_melee", weapon);
        
        if(weapon == m_weap && IsDefined(self.var_ea5424ae) && self.var_ea5424ae > 0)
            self clientfield::increment_to_player("plunger_charged_strike");
    }
}

function function_1fcb04d7()
{
    self endon("disconnect");

    self waittill("bled_out");
    self.widows_wine_knife_override = undefined;
}


















//Fire Bow Quest
function InitFireBow()
{
    if(IsDefined(level.var_714fae39))
        return;
    
    if(Is_True(level.InitFireBow))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    level.InitFireBow = true;
    
    menu = self getCurrent();
    curs = self getCursor();
    clock = GetEnt("aq_rp_clock_wall_trig", "targetname");

    if(IsDefined(clock))
        MagicBullet(GetWeapon("elemental_bow"), clock.origin, clock.origin + (0, 5, 0), self);

    while(!IsDefined(level.var_714fae39) || !level.var_714fae39)
        wait 0.1;

    self RefreshMenu(menu, curs);
}

function MagmaRock()
{
    if(Is_True(level.MagmaRock))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(level flag::get("rune_prison_obelisk"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(!IsDefined(level.var_c62829c7))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.MagmaRock = true;
    
    menu = self getCurrent();
    curs = self getCursor();

    level flag::set("rune_prison_obelisk_magma_enabled");
    wait 0.1;

    rock = GetEnt("aq_rp_obelisk_magma_trig", "targetname");

    if(IsDefined(rock))
        MagicBullet(GetWeapon("elemental_bow"), rock.origin, rock.origin + (0, 5, 0), level.var_c62829c7);
    
    while(!level flag::get("rune_prison_obelisk"))
        wait 0.1;
    
    wait 9;

    if(Is_True(level.MagmaRock))
        level.MagmaRock = BoolVar(level.MagmaRock);
    
    self RefreshMenu(menu, curs);
}

function RunicCircles()
{
    if(!level flag::get("rune_prison_obelisk"))
        return self iPrintlnBold("^1ERROR: ^7Magma Rock Step Must Be Completed First");
    
    if(Is_True(level.MagmaRock))
        return self iPrintlnBold("^1ERROR: ^7Magma Rock Is Still Being Completed");
    
    if(AllRunicCirclesCharged())
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.ChargingCircles))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_c62829c7))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.ChargingCircles = true;
    
    menu = self getCurrent();
    curs = self getCursor();

    level.var_c62829c7.is_flung = true;
    wait 1;

    circles = GetEntArray("aq_rp_runic_circle_volume", "script_noteworthy");

    if(IsDefined(circles))
    {
        for(a = 0; a < circles.size; a++)
        {
            if(!IsDefined(circles[a]) || circles[a] flag::get("runic_circle_activated"))
                continue;
            
            cirTarget = GetEnt(circles[a].target + "_trig", "targetname");

            if(IsDefined(cirTarget))
                MagicBullet(GetWeapon("elemental_bow"), cirTarget.origin, cirTarget.origin, level.var_c62829c7);
            
            wait 0.05;
        }
    }

    wait 1;
    level.var_c62829c7.is_flung = false;
    array::thread_all(circles, &ChargeRunicCircle);

    while(!AllRunicCirclesCharged())
        wait 0.1;
    
    self RefreshMenu(menu, curs);
    wait 5; //Allows buffer time between this, and the next step to help ensure we don't run into any issues

    if(Is_True(level.ChargingCircles))
        level.ChargingCircles = BoolVar(level.ChargingCircles);
}

function ChargeRunicCircle()
{
    if(!IsDefined(self) || self flag::get("runic_circle_charged"))
        return;
    
    while(!self flag::get("runic_circle_activated"))
        wait 0.1;
    
    while(!self flag::get("runic_circle_charged"))
    {
        self notify("killed");
        wait 0.1;
    }
}

function AllRunicCirclesCharged()
{
    circles = GetEntArray("aq_rp_runic_circle_volume", "script_noteworthy");

    if(IsDefined(circles) && circles.size)
    {
        for(a = 0; a < circles.size; a++)
        {
            if(!IsDefined(circles[a]))
                continue;
            
            if(!circles[a] flag::exists("runic_circle_activated") || !circles[a] flag::get("runic_circle_activated") || !circles[a] flag::exists("runic_circle_charged") || !circles[a] flag::get("runic_circle_charged"))
                return false;
        }
    }

    return true;
}

function ClockFireplaceStep()
{
    if(!AllRunicCirclesCharged() || Is_True(level.ChargingCircles))
        return self iPrintlnBold("^1ERROR: ^7Runic Circles Must Be Activated & Charged First");
    
    if(IsClockFireplaceComplete())
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.ClockFireplaceStep))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_c62829c7))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");

    level.ClockFireplaceStep = true;
    
    menu = self getCurrent();
    curs = self getCursor();

    clock = struct::get("aq_rp_clock_use_struct", "targetname");
    clock.var_67b5dd94 notify("trigger", level.var_c62829c7);

    while(!IsDefined(level.var_2e55cb98))
        wait 1;

    level.var_c62829c7 FreezeControls(1);
    level.var_2e55cb98.origin = level.var_c62829c7.origin;
    wait 1;

    target = GetEnt(level.var_2e55cb98.var_336f1366.target, "targetname");
    firePlace = LocateFireplace(); //Need to find the fireplace before this part of the step is completed

    if(IsDefined(target))
    {
        for(a = 0; a < 2; a++) //Target must be hit twice
        {
            MagicBullet(GetWeapon("elemental_bow"), target.origin, target.origin + (0, 5, 0), level.var_c62829c7);
            wait 0.1;
        }
    }

    if(IsDefined(firePlace))
        firePlace.var_67b5dd94 notify("trigger", level.var_c62829c7);
    
    level.var_c62829c7 FreezeControls(0);

    while(!IsClockFireplaceComplete())
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}

function LocateFireplace()
{
    circles = GetEntArray("aq_rp_runic_circle_volume", "script_noteworthy");
    firePlaces = struct::get_array("aq_rp_fireplace_struct", "targetname");

    //By this point in the quest, only one runic circle should still be defined.
    //But, we're still gonna scan through just to be sure.

    if(IsDefined(circles))
    {
        for(a = 0; a < circles.size; a++)
        {
            if(!IsDefined(circles[a]))
                continue;
            
            for(b = 0; b < firePlaces.size; b++)
            {
                if(circles[a].script_label == firePlaces[b].script_noteworthy)
                    return firePlaces[b];
            }
        }
    }
}

function IsClockFireplaceComplete()
{
    magmaBall = GetEnt("aq_rp_magma_ball_tag", "targetname");

    if(level flag::exists("rune_prison_golf") && level flag::get("rune_prison_golf"))
    {
        if(!IsDefined(magmaBall))
            return true;
        
        if(IsDefined(magmaBall) && magmaBall flag::exists("magma_ball_move_done") && magmaBall flag::get("magma_ball_move_done"))
            return true;
    }

    return false;
}

function CollectRepairedFireArrows()
{
    if(level flag::get("rune_prison_repaired"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(!IsClockFireplaceComplete())
        return self iPrintlnBold("^1ERROR: ^7The Fireplace Step Must Be Completed First");
    
    if(Is_True(level.CollectRepairedFireArrows))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_c62829c7))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");

    level.CollectRepairedFireArrows = true;

    menu = self getCurrent();
    curs = self getCursor();
    
    MagmaBall = struct::get("quest_reforge_rune_prison", "targetname");

    if(IsDefined(MagmaBall))
        MagmaBall.var_67b5dd94 notify("trigger", level.var_c62829c7);

    wait 9;

    if(IsDefined(MagmaBall))
        MagmaBall.var_67b5dd94 notify("trigger", level.var_c62829c7);
    
    while(!level flag::get("rune_prison_repaired"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}


















//Lightning Bow Quest
function InitLightningBow()
{
    trig = GetEnt("aq_es_weather_vane_trig", "targetname");

    if(!IsDefined(trig))
        return;

    if(Is_True(level.InitLightningBow))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    level.InitLightningBow = true;
    
    menu = self getCurrent();
    curs = self getCursor();

    if(IsDefined(trig))
        MagicBullet(GetWeapon("elemental_bow"), trig.origin, trig.origin + (0, 0, 5), self);

    while(IsDefined(trig))
        wait 0.1;

    self RefreshMenu(menu, curs);
}

function LightningBeacons()
{
    if(AreBeaconsLit())
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.LightningBeacons))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_f8d1dc16))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.LightningBeacons = true;

    menu = self getCurrent();
    curs = self getCursor();

    beacons = GetEntArray("aq_es_beacon_trig", "script_noteworthy");

    for(a = 0; a < beacons.size; a++)
    {
        if(!IsDefined(beacons[a]))
            continue;
        
        MagicBullet(GetWeapon("elemental_bow"), beacons[a].origin + (0, 0, 5), beacons[a].origin, level.var_f8d1dc16);
        wait 0.1;
    }

    while(!AreBeaconsLit())
        wait 0.1;

    self RefreshMenu(menu, curs);
}

function AreBeaconsLit()
{
    beacons = GetEntArray("aq_es_beacon_trig", "script_noteworthy");

    if(!IsDefined(beacons))
        return false;

    for(a = 0; a < beacons.size; a++)
    {
        if(!IsDefined(beacons[a]))
            continue;
        
        s_beacon = struct::get(beacons[a].target);

        if(!IsDefined(s_beacon) || !IsDefined(s_beacon.var_41f52afd) || !s_beacon.var_41f52afd clientfield::get("beacon_fx"))
            return false;
    }

    return true;
}

function LightningWallrun()
{
    if(level flag::get("elemental_storm_wallrun"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.LightningWallrun))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!AreBeaconsLit())
        return self iPrintlnBold("^1ERROR: ^7Beacons Must Be Lit First");
    
    if(!IsDefined(level.var_f8d1dc16))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.LightningWallrun = true;

    menu = self getCurrent();
    curs = self getCursor();
    trigs = GetEntArray("aq_es_wallrun_trigger", "targetname");

    for(a = 0; a < trigs.size; a++)
    {
        if(!IsDefined(trigs[a]) || IsDefined(level.var_f8d1dc16.var_a4f04654) && level.var_f8d1dc16.var_a4f04654 >= 4)
            continue;
        
        trigs[a] notify("trigger", level.var_f8d1dc16);
    }

    while(!level flag::get("elemental_storm_wallrun"))
        wait 0.1;

    self RefreshMenu(menu, curs);
}

function LightningChargeBeacons()
{
    if(LightningBeaconsCharged())
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.LightningChargeBeacons))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!level flag::get("elemental_storm_wallrun"))
        return self iPrintlnBold("^1ERROR: ^7Wallrun Step Must Be Completed First");
    
    if(!IsDefined(level.var_f8d1dc16))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.LightningChargeBeacons = true;

    menu = self getCurrent();
    curs = self getCursor();

    if(!level flag::get("elemental_storm_batteries"))
    {
        beacons = GetEntArray("aq_es_battery_volume", "script_noteworthy");

        for(a = 0; a < beacons.size; a++)
        {
            if(!IsDefined(beacons[a]))
                continue;
            
            while(!Is_True(beacons[a].b_activated))
            {
                beacons[a] notify("killed");
                wait 0.1;
            }

            wait 0.1;
        }

        level.var_f8d1dc16 thread LightningMissileCharger();
    }

    bTrigs = GetEntArray("aq_es_beacon_trig", "script_noteworthy");

    for(a = 0; a < bTrigs.size; a++)
    {
        if(!IsDefined(bTrigs[a]) || IsDefined(bTrigs[a].b_charged) && bTrigs[a].b_charged)
            continue;
        
        MagicBullet(GetWeapon("elemental_bow"), bTrigs[a].origin + (0, 0, 500), bTrigs[a].origin, level.var_f8d1dc16);
        wait 0.1;
    }

    while(!LightningBeaconsCharged())
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}

function LightningMissileCharger()
{
    used = [];

    while(!LightningBeaconsCharged())
    {
        self waittill("missile_fire", projectile, weapon);

        chosen = false;
        charged = GetEntArray("aq_es_battery_volume_charged", "script_noteworthy");

        for(a = 0; a < charged.size; a++)
        {
            if(!IsDefined(charged[a]) || isInArray(used, a) || Is_True(chosen))
                continue;
            
            chosen = true;
            used[used.size] = a;
            projectile.var_8f88d1fd = charged[a];
            level.var_f8d1dc16.var_55301590 = charged[a];
        }

        projectile.var_e4594d27 = true;
    }
}

function LightningBeaconsCharged()
{
    return (level flag::get("elemental_storm_batteries") && level flag::get("elemental_storm_beacons_charged"));
}

function ChargeLightningArrows()
{
    if(level flag::get("elemental_storm_repaired"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.ChargeLightningArrows))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!LightningBeaconsCharged())
        return self iPrintlnBold("^1ERROR: ^7Urns Must Filled & Beacons Need To Be Charged First");
    
    if(!IsDefined(level.var_f8d1dc16))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");

    level.ChargeLightningArrows = true;

    menu = self getCurrent();
    curs = self getCursor();
    storm = struct::get("quest_reforge_elemental_storm");

    if(IsDefined(storm))
        storm.var_67b5dd94 notify("trigger", level.var_f8d1dc16);

    wait 18;

    if(IsDefined(storm))
        storm.var_67b5dd94 notify("trigger", level.var_f8d1dc16);

    while(!level flag::get("elemental_storm_repaired"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}





















//Void Bow Quest
function InitVoidBow()
{
    if(level clientfield::get("quest_state_demon") > 0)
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.InitVoidBow))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    level.InitVoidBow = true;

    menu = self getCurrent();
    curs = self getCursor();
    symbol = GetEnt("aq_dg_gatehouse_symbol_trig", "targetname");

    if(IsDefined(symbol))
        MagicBullet(GetWeapon("elemental_bow"), symbol.origin, symbol.origin + (0, 0, 5), self);

    while(IsDefined(symbol))
        wait 0.1;

    self RefreshMenu(menu, curs);
}

function ReleaseDemonUrn()
{
    if(level flag::get("demon_gate_seal"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.ReleaseDemonUrn))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_6e68c0d8))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.ReleaseDemonUrn = true;

    menu = self getCurrent();
    curs = self getCursor();

    level flag::set("demon_gate_seal"); //Hate doing it this way. But, nothing will get skipped over by doing it like this.
    wait 5;

    urn = struct::get("aq_dg_urn_struct", "targetname");
    urn.var_67b5dd94 notify("trigger", level.var_6e68c0d8);

    while(!level flag::get("demon_gate_seal"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
    wait 5;

    if(Is_True(level.ReleaseDemonUrn))
        level.ReleaseDemonUrn = BoolVar(level.ReleaseDemonUrn);
}

function TriggerDemonFossils()
{
    if(!level flag::get("demon_gate_seal") || level clientfield::get("quest_state_demon") < 2)
        return self iPrintlnBold("^1ERROR: ^7The Demon Urn Must Be Released First");
    
    fossils = GetEntArray("aq_dg_fossil", "script_noteworthy");

    if(!IsDefined(fossils) || !fossils.size)
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.TriggerDemonFossils))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(Is_True(level.ReleaseDemonUrn))
        return self iPrintlnBold("^1ERROR: ^7Release Demon Urn Is Still Being Completed");
    
    if(!IsDefined(level.var_6e68c0d8))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.TriggerDemonFossils = true;

    menu = self getCurrent();
    curs = self getCursor();

    for(a = 0; a < fossils.size; a++)
    {
        if(!IsDefined(fossils[a]))
            continue;
        
        fossils[a].var_67b5dd94 notify("trigger", level.var_6e68c0d8);
        wait 0.1;
    }

    while(1)
    {
        fossils = GetEntArray("aq_dg_fossil", "script_noteworthy");

        if(!IsDefined(fossils) || !fossils.size)
            break;
        
        wait 0.1;
    }
    
    self RefreshMenu(menu, curs);
}

function FeedDemonUrn()
{
    fossils = GetEntArray("aq_dg_fossil", "script_noteworthy");

    if(IsDefined(fossils) && fossils.size || level clientfield::get("quest_state_demon") < 3)
        return self iPrintlnBold("^1ERROR: ^7All Fossil Heads Must Be Triggered First");
    
    if(level flag::get("demon_gate_crawlers"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.FeedDemonUrn))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_6e68c0d8))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.FeedDemonUrn = true;

    menu = self getCurrent();
    curs = self getCursor();
    wait 2;

    urnTrig = GetEnt("aq_dg_trophy_room_trig", "targetname");

    if(IsDefined(urnTrig))
        urnTrig notify("trigger", level.var_6e68c0d8);

    wait 0.1;
    urn = GetEnt("aq_dg_demonic_circle_volume", "targetname");

    sacrificedZombies = [];
    goalEnt = GetEnt("aq_dg_demonic_circle_volume", "targetname");

    while(urn.var_e1f456ae < 6)
    {
        sacrificedZombie = SpawnSacrificedZombie(goalEnt);

        if(IsDefined(sacrificedZombie))
            sacrificedZombies[sacrificedZombies.size] = sacrificedZombie;
        
        wait 1;
    }

    while(!level flag::get("demon_gate_crawlers"))
        wait 0.1;
    
    if(IsDefined(sacrificedZombies) && sacrificedZombies.size)
    {
        for(a = 0; a < sacrificedZombies.size; a++)
        {
            if(!IsDefined(sacrificedZombies[a]) || !IsAlive(sacrificedZombies[a]))
                continue;
            
            sacrificedZombies[a] DoDamage(sacrificedZombies[a].health + 666, sacrificedZombies[a].origin);
        }
    }
    
    self RefreshMenu(menu, curs);
}

function InscribeDemonName()
{
    if(!level flag::get("demon_gate_crawlers") || level clientfield::get("quest_state_demon") < 4)
        return self iPrintlnBold("^1ERROR: ^7You Must Feed The Demon Urn First");
    
    if(level flag::get("demon_gate_runes"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.InscribeDemonName))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_6e68c0d8))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    menu = self getCurrent();
    curs = self getCursor();
    level.InscribeDemonName = true;
    
    powerups = GetArrayKeys(level.zombie_include_powerups);

    for(a = 0; a < powerups.size; a++)
    {
        if(!IsDefined(powerups[a]) || !IsSubStr(powerups[a], "rune"))
            continue;
        
        drop = level zm_powerups::specific_powerup_drop(powerups[a], level.var_6e68c0d8.origin);
    }

    wait 1;
    
    foreach(icon in struct::get_array("aq_dg_rune_sequence_struct", "script_noteworthy"))
    {
        foreach(trig in GetEntArray("aq_dg_circle_rune_trig", "targetname"))
        {
            iconTok = StrTok(icon.var_a991b2d8, "_");
            trigTok = StrTok(trig.script_noteworthy, "_");

            if(iconTok[(iconTok.size - 1)] != trigTok[(trigTok.size - 1)])
                continue;
            
            MagicBullet(GetWeapon("elemental_bow"), trig.origin + (0, 0, 5), trig.origin, level.var_6e68c0d8);
            wait 1;
        }
    }

    while(!level flag::get("demon_gate_runes"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
    wait 8;

    level.InscribeDemonName = BoolVar(level.InscribeDemonName);
}

function CollectVoidArrow()
{
    if(!level flag::get("demon_gate_runes") || Is_True(level.InscribeDemonName))
        return self iPrintlnBold("^1ERROR: ^7You Must Inscribe The Demon Name First");
    
    if(level flag::get("demon_gate_repaired"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.CollectVoidArrow))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_6e68c0d8))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    menu = self getCurrent();
    curs = self getCursor();
    level.CollectVoidArrow = true;

    reforgeGate = struct::get("quest_reforge_demon_gate", "targetname");
    reforgeGate.var_67b5dd94 notify("trigger", level.var_6e68c0d8);

    level waittill(#"hash_66b2458c");
    wait 4;

    reforgeGate.var_67b5dd94 notify("trigger", level.var_6e68c0d8);

    while(!level flag::get("demon_gate_repaired"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}




























//Wolf Bow Quest
function InitWolfBow()
{
    if(level flag::get("wolf_howl_paintings"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(!self HasWeapon(getweapon("elemental_bow")))
        return self iPrintlnBold("^1ERROR: ^7You Need To Have The Elemental Bow To Complete This Step");
    
    if(Is_True(level.InitWolfBow))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    level.InitWolfBow = true;
    
    menu = self getCurrent();
    curs = self getCursor();

    paintings = Array("p7_zm_ctl_kings_painting_01", "p7_zm_ctl_kings_painting_02", "p7_zm_ctl_kings_painting_03", "p7_zm_ctl_kings_painting_04");
    paintStruct = struct::get_array("aq_wh_painting_struct", "script_noteworthy");

    for(a = 0; a < paintings.size; a++)
    {
        for(b = 0; b < paintStruct.size; b++)
        {
            if(paintStruct[b].var_b5b31795.model != paintings[a])
                continue;
            
            paintStruct[b].var_67b5dd94 notify("trigger", self);
        }

        wait 0.1;
    }

    while(!level flag::get("wolf_howl_paintings"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}

function CollectSkullShrine()
{
    if(!level flag::get("wolf_howl_paintings"))
        return self iPrintlnBold("^1ERROR: ^7The Wolf Bow Quest Must Be Initiated First");
    
    if(level clientfield::get("quest_state_wolf") >= 2)
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.CollectSkullShrine))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_52978d72))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.CollectSkullShrine = true;

    menu = self getCurrent();
    curs = self getCursor();
    
    shrine = GetEnt("aq_wh_skull_shrine_trig", "targetname");
    MagicBullet(GetWeapon("elemental_bow"), shrine.origin + (0, 0, 5), shrine.origin, level.var_52978d72);
    wait 10;

    skull = GetEnt("wolf_skull_roll_down", "targetname");
    skull.var_67b5dd94 notify("trigger", level.var_52978d72);
    wait 3;

    while(1)
    {
        skull = GetEnt("wolf_skull_roll_down", "targetname");

        if(!IsDefined(skull))
            break;
        
        wait 0.1;
    }
    
    self RefreshMenu(menu, curs);
    level.CollectSkullShrine = BoolVar(level.CollectSkullShrine);
}

function WolfAttachSkull()
{
    if(level clientfield::get("quest_state_wolf") < 2 || Is_True(level.CollectSkullShrine))
        return self iPrintlnBold("^1ERROR: ^7Skull Shrine Must Be Collected First");
    
    if(level clientfield::get("quest_state_wolf") >= 3)
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.WolfAttachSkull))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_52978d72))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    menu = self getCurrent();
    curs = self getCursor();
    
    level.WolfAttachSkull = true;

    skull = GetEnt("aq_wh_skadi_skull", "targetname");
    skull.var_67b5dd94 notify("trigger", level.var_52978d72);

    while(level clientfield::get("quest_state_wolf") < 2)
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}

function CollectWolfSouls()
{
    if(level clientfield::get("quest_state_wolf") < 3)
        return self iPrintlnBold("^1ERROR: ^7You Must Attach The Skull To The Skeleton First");
    
    if(level flag::get("wolf_howl_escort"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.CollectWolfSouls))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_52978d72))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    menu = self getCurrent();
    curs = self getCursor();
    
    level.CollectWolfSouls = true;
    self iPrintlnBold("^1" + ToUpper(GetMenuName()) + ": ^7This Step Is Going To Take A Few Minutes To Complete");

    while(!level flag::get("wolf_howl_escort"))
    {
        /*
            This notify will end the script checking if the player loses the wolf.
            Usually, if the player loses the wolf(wolf isn't in sight of the player for too long) it will end the quest step, and it will have to be started again by the player
        */
        level.var_52978d72 notify("player_found_skadi");

        if(!IsDefined(level.var_e6d07014) && !level flag::get("wolf_howl_escort")) //This is a fail safe, in the case the quest step gets killed. It will allow the script to be ran again when the step is restarted
        {
            self iPrintlnBold("^1ERROR: ^7Failed To Escort & Collect Wolf Souls");
            break;
        }
        
        if(IsDefined(level.var_e6d07014.var_5c4d212e) && !level.var_e6d07014.var_5c4d212e flag::get("dig_spot_complete"))
        {
            sacrificedZombies = [];
            targetName = level.var_e6d07014.var_5c4d212e.targetName;
            targetToks = StrTok(targetName, "_");

            while(level.var_e6d07014.var_5c4d212e.var_252d000d < 10)
            {
                zombie = SpawnSacrificedZombie(level.var_e6d07014.var_5c4d212e);

                if(IsDefined(zombie))
                {
                    sacrificedZombies[sacrificedZombies.size] = zombie;
                    MagicBullet(GetWeapon("elemental_bow"), zombie.origin + (0, 0, 5), zombie.origin, level.var_52978d72);
                }
                
                wait 0.05;
            }

            wait 10;
            bonePile = GetEnt("aq_wh_bones_" + targetToks[(targetToks.size - 1)], "targetname");
            bonePile.var_67b5dd94 notify("trigger", level.var_52978d72);

            if(IsDefined(sacrificedZombies) && sacrificedZombies.size)
            {
                for(a = 0; a < sacrificedZombies.size; a++)
                {
                    if(!IsDefined(sacrificedZombies[a]) || !IsAlive(sacrificedZombies[a]))
                        continue;
                    
                    sacrificedZombies[a] DoDamage(sacrificedZombies[a].health + 666, sacrificedZombies[a].origin);
                }
            }
        }

        wait 1;
    }

    level.CollectWolfSouls = BoolVar(level.CollectWolfSouls);
    self RefreshMenu(menu, curs);
}

function CollectReforgedArrows()
{
    if(!level flag::get("wolf_howl_escort"))
        return self iPrintlnBold("^1ERROR: ^7You Must Escort & Collect Wolf Souls First");
    
    if(level flag::get("wolf_howl_repaired"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.CollectReforgedArrows))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    if(!IsDefined(level.var_52978d72))
        return self iPrintlnBold("^1ERROR: ^7There Is No Player Bound To The Quest");
    
    level.CollectReforgedArrows = true;
    
    menu = self getCurrent();
    curs = self getCursor();
    rtnValue = level.var_52978d72.var_374fd3ef;
    
    damageTrig = GetEnt("aq_wh_burial_chamber_damage_trig", "targetname");
    level.var_52978d72 thread WolfWallRunning();
    MagicBullet(GetWeapon("elemental_bow"), damageTrig.origin + (AnglesToForward(damageTrig.angles) * -10), damageTrig.origin + (0, 0, 5), level.var_52978d72);

    ledgeCollision = GetEnt("aq_wh_ledge_collision", "targetname");

    while(!ledgeCollision flag::get("ledge_built"))
        wait 0.1;

    reforgedArrows = struct::get("quest_reforge_wolf_howl", "targetname");
    reforgedArrows.var_67b5dd94 notify("trigger", level.var_52978d72);

    wait 5.5;
    reforgedArrows.var_67b5dd94 notify("trigger", level.var_52978d72);

    while(!level flag::get("wolf_howl_repaired"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}

function WolfWallRunning()
{
    self endon("disconnect");

    ledgeCollision = GetEnt("aq_wh_ledge_collision", "targetname");

    while(!level flag::get("wolf_howl_repaired"))
    {
        self.var_374fd3ef = true;
        wait 0.01;
    }
}

// ============================================================
// Functions/MapScripts/DerRieseDeclassified.gsc
// ============================================================

function PopulateDerRieseScripts(menu)
{
    switch(menu)
    {
        case "Der Riese: Declassified Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
            break;
    }
}

// ============================================================
// Functions/MapScripts/DieRise.gsc
// ============================================================

function PopulateDieRiseScripts(menu)
{
    switch(menu)
    {
        case "Die Rise Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
                self addOpt("Elevator Keys", &newMenu, "Die Rise Elevator Keys");
                self addOpt("Bank Cash", &newMenu, "Die Rise Bank Cash");
                self addOpt("Player Ranks", &newMenu, "Die Rise Player Ranks");
            break;
        
        case "Die Rise Elevator Keys":
            self addMenu(menu);
                
                foreach(player in level.players)
                    self addOptBool(player.var_7e6e237, CleanName(player getName()), &CollectElevatorKey, player);
            break;
        
        case "Die Rise Bank Cash":
            self addMenu(menu);

                foreach(player in level.players)
                    self addOptSlider(CleanName(player getName()), &SetPlayerBank, Array("Max", "Reset"), player);
            break;
        
        case "Die Rise Player Ranks":
            if(!IsDefined(self.DieRiseRankPlayer))
                self.DieRiseRankPlayer = level.players[0];

            playerArray = [];

            foreach(player in level.players)
                playerArray[playerArray.size] = CleanName(player getName()) + " [" + player GetEntityNumber() + "]";
            
            self addMenu(menu);
                self addOptSlider("Player", &SetDieRiseRankPlayer, playerArray);
                self addOpt("");
                self addOptIncSlider("Rank", &SetDieRisePlayerRank, 1, 1, 5, 1, self.DieRiseRankPlayer);
            break;
    }
}

function CollectElevatorKey(player)
{
    if(!Is_True(player.var_7e6e237) && IsDefined(player.var_6f657589) && IsDefined(player.var_6f657589.trigger))
        player.var_6f657589.trigger notify("trigger_activated", player);
}

function SetPlayerBank(amount, player)
{
    cash = ((amount == "Max") ? 250 : 0);
    player SetClientDieRiseStat("bank_account_value", cash);
    player.account_value = cash;
}

function SetClientDieRiseStat(stat_name, stat_value)
{
    if(!IsDefined(self.var_37f38876) || !IsDefined(self.var_37f38876[stat_name]))
        return;

    self.var_37f38876[stat_name].value = stat_value;
    self.pers[stat_name] = stat_value;
    self.stats_this_frame[stat_name] = 1;
    self ForceSaveStatsDieRise();
}

function GetClientDieRiseStat(stat_name)
{
    if(!IsDefined(self.var_37f38876) || !IsDefined(self.var_37f38876[stat_name]))
        return 0;

    return self.var_37f38876[stat_name].value;
}

function ForceSaveStatsDieRise()
{
    self.var_977970a0 = 1;
    self notify(#"hash_412e4eb1");
    self function_56809df9();
    function_4e89efbc(self, "UploadData", "bruh");
    self.var_977970a0 = 0;
}

function function_56809df9()
{
    self endon("disconnect");

    foreach(var_2f24aac7 in self.var_3d64c45d)
    {
        data = var_2f24aac7 + "=";

        foreach(stat in self.var_37f38876)
        {
            if(!IsInt(stat) && stat.set == var_2f24aac7 && (IsDefined(stat.var_f82847be) && stat.var_f82847be))
                data = data + stat.name + "." + stat.value + ",";
        }

        data = data + "|";
        function_4e89efbc(self, "UpdateDataSet", data);
        util::wait_network_frame();
        wait 0.05;
    }
}

function function_4e89efbc(player, type, msg)
{
    if(isPlayer(player))
    {
        level util::setClientSysState("dbSendClientMsg", type + "-**" + msg, player);
    }
}

function SetDieRiseRankPlayer(playerName)
{
    foreach(player in level.players)
    {
        if(CleanName(player getName()) + " [" + player GetEntityNumber() + "]" == playerName) //I included the players entity number for the case two players have the same name
            self.DieRiseRankPlayer = player;
    }

    self RefreshMenu(self getCurrent(), self getCursor());
}

function SetDieRisePlayerRank(rank, player)
{
    time_played = player GetClientDieRiseStat("total_time_played");
	rounds = player GetClientDieRiseStat("weighted_rounds");
	downs = player GetClientDieRiseStat("weighted_downs");

    if(rank > 1)
    {
        if(!downs)
        {
            player SetClientDieRiseStat("weighted_downs", 1);
            downs = player GetClientDieRiseStat("weighted_downs");
        }
        
        if(!rounds)
        {
            player SetClientDieRiseStat("weighted_rounds", 1);
            rounds = player GetClientDieRiseStat("weighted_rounds");
        }
    }

    newRatio = false;
    ratio = (rounds / downs);

    switch(rank)
    {
        case 1:
            player SetClientDieRiseStat("total_time_played", 0); //the ratio doesn't matter for rank 1
            break;
        
        case 2:
            if(time_played < 3600 || time_played >= 18000)
                player SetClientDieRiseStat("total_time_played", 3600);
            
            newRatio = (ratio < 0.005);
            break;
        
        case 3:
            if(time_played < 18000 || time_played >= 54000)
                player SetClientDieRiseStat("total_time_played", 18000);
            
            newRatio = (ratio < 0.013);
            break;
        
        case 4:
            if(time_played < 54000 || time_played >= 108000)
                player SetClientDieRiseStat("total_time_played", 54000);
            
            newRatio = (ratio < 0.054);
            break;
        
        case 5:
            if(time_played < 108000)
                player SetClientDieRiseStat("total_time_played", 108000);
            
            newRatio = (ratio < 0.13);
            break;
    }

    if(newRatio)
        player SetClientDieRiseStat("weighted_rounds", player GetClientDieRiseStat("weighted_downs")); //this will make the new ratio 1(which will allow the player to meet the standard for any rank)

    level notify("force_player_rank_update");
}

// ============================================================
// Functions/MapScripts/Diner.gsc
// ============================================================

function PopulateDinerScripts(menu)
{
    switch(menu)
    {
        case "Diner Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
            break;
    }
}

// ============================================================
// Functions/MapScripts/Farm.gsc
// ============================================================

function PopulateFarmScripts(menu)
{
    switch(menu)
    {
        case "Farm Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
            break;
    }
}

// ============================================================
// Functions/MapScripts/GorodKrovi.gsc
// ============================================================

function PopulateGorodKroviScripts(menu)
{
    switch(menu)
    {
        case "Gorod Krovi Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
                self addOpt("Challenges", &newMenu, "Map Challenges");
            break;
    }
}

function TriggerSophia()
{
}

// ============================================================
// Functions/MapScripts/KinoDerToten.gsc
// ============================================================

function PopulateKinoScripts(menu)
{
    switch(menu)
    {
        case "Kino Der Toten Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
                self addOptBool(level flag::get("snd_zhdegg_activate"), "Door Knocking Combination", &CompleteDoorKnockingCombination);
                self addOptBool(level flag::get("snd_zhdegg_completed"), "Samantha's Hide & Seek", &SamanthasHideAndSeekSong);
                self addOptBool(level flag::get("snd_song_completed"), "Meteor 115 Song", &CompleteMeteorEE);
            break;
    }
}

function CompleteDoorKnockingCombination()
{
    if(level flag::get("snd_zhdegg_activate"))
        return self iPrintlnBold("^1ERROR: ^7The Door Knocking Combination Has Already Been Completed");

    if(Is_True(level.KnockingCombination))
        return self iPrintlnBold("^1ERROR: ^7The Door Knocking Combination Is Currently Being Completed");

    level.KnockingCombination = true;

    while(1) //This will complete it properly. If you just set the flag, the knocking will continue.
    {
        if(level flag::get("snd_zhdegg_activate"))
            break;

        level notify("zhd_knocker_success");
        wait 0.025;
    }

    if(Is_True(level.KnockingCombination))
        level.KnockingCombination = BoolVar(level.KnockingCombination);
    
    level flag::set("snd_zhdegg_activate");
}

function CompleteMeteorEE()
{
    foreach(meteor in struct::get_array("songstructs", "targetname"))
    {
        triggerObj = undefined;

        foreach(ent in GetEntArray("script_origin", "classname"))
        {
            if(ent.origin == meteor.origin)
            {
                triggerObj = ent;
                break;
            }
        }

        if(IsDefined(triggerObj))
            triggerObj notify("trigger_activated", self);

        wait 0.05;
    }
}

// ============================================================
// Functions/MapScripts/Leviathan.gsc
// ============================================================

function PopulateLeviathanScripts(menu)
{
    switch(menu)
    {
        case "Leviathan Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
            break;
    }
}

// ============================================================
// Functions/MapScripts/MobOfTheDead.gsc
// ============================================================

function PopulateMOTDScripts(menu)
{
    switch(menu)
    {
        case "Mob Of The Dead Scripts":
            self addMenu(menu);
                self addOptBool((level.soul_catchers_charged >= level.soul_catchers.size), "Feed Devil Dogs", &FeedDevilDogs);
                self addOpt("Power Generators", &newMenu, "MOTD Power Generators");
                self addOpt("Modify After Life Lives", &newMenu, "Modify After Life Lives");
            break;
        
        case "MOTD Power Generators":
            generators = GetEntArray("afterlife_interact", "targetname");

            self addMenu("Power Generators");
                
                foreach(index, generator in generators)
                {
                    if(!IsDefined(generator) || generator IsGeneratorActive())
                        continue;
                    
                    self addOpt(GetMOTDGeneratorName(index), &DamageMOTDGenerator, generator);
                }
            break;

        case "Modify After Life Lives":
            self addMenu(menu);
                
                foreach(player in level.players)
                    self addOptIncSlider(CleanName(player getName()) + " [ Lives: " + player.lives + " ]", &ModifyPlayerAfterLives, -1, 1, 1, 1, player);
            break;
    }
}

function FeedDevilDogs()
{
    if(level.soul_catchers_charged >= level.soul_catchers.size)
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.FeedDevilDogs))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    level.FeedDevilDogs = true;
    
    menu = self getCurrent();
    curs = self getCursor();

    foreach(catcher in level.soul_catchers)
    {
        if(!IsDefined(catcher) || Is_True(catcher.is_charged))
            continue;
        
        catcher thread FeedDevilDog(self);
    }
    
    while(level.soul_catchers_charged < level.soul_catchers.size)
        wait 0.1;

    self RefreshMenu(menu, curs);

    if(Is_True(level.FeedDevilDogs))
        level.FeedDevilDogs = BoolVar(level.FeedDevilDogs);
}

function FeedDevilDog(player)
{
    if(!self.souls_received)
    {
        self notify("first_zombie_killed_in_zone", player);
        wait GetAnimLength("xanim_wolf_dreamcatcher_intro");
    }
    
    while(self.souls_received < 6)
    {
        self.souls_received++;
        wait 0.1;
    }
}

function DamageMOTDGenerator(generator)
{
    if(!IsDefined(generator) || Is_True(generator.triggering))
        return;
    
    generator.triggering = true;
    
    menu = self getCurrent();
    curs = self getCursor();

    generator notify("damage", 1, level);
    wait 0.1;

    self RefreshMenu(menu, curs);

    if(IsDefined(generator) && Is_True(generator.triggering))
        generator.triggering = BoolVar(generator.triggering);
}

function IsGeneratorActive()
{
    if(IsDefined(self.unitrigger_stub) && Is_True(self.unitrigger_stub.is_activated_in_afterlife))
        return true;
    
    if(!IsDefined(self.unitrigger_stub) && !IsDefined(self.t_bump))
        return true;
    
    return false;
}

function ModifyPlayerAfterLives(amount, player)
{
    if(!player.lives && amount <= 0)
        return;
    
    menu = self getCurrent();
    curs = self getCursor();
    
    if(amount == 0)
        player.lives = 0;
    
    player.lives += amount;

    if(amount > 0)
        player PlaySoundToPlayer("zmb_afterlife_add", player);
    
	player clientfield::set_player_uimodel("player_lives", player.lives);
    self RefreshMenu(menu, curs);
}

function GetMOTDGeneratorName(index)
{
    switch(index)
    {
        case 0:
            return "Spawn(Power-Up)";
        
        case 1:
            return "Broadway";
        
        case 2:
            return "Broadway Tunnel(In The Wall)";
        
        case 3:
            return "Deadshot Daiquiri";
        
        case 4:
            return "Stamin-Up";
        
        case 5:
            return "Roof";
        
        case 6:
            return "Electric Cherry";
        
        case 7:
            return "Michigan(Power-Up)";
        
        case 8:
            return "Warden's Office Stairs";
        
        case 9:
            return "Speed Cola";
        
        case 10:
            return "Double Tap";
        
        case 11:
            return "Laundry Room";
        
        case 12:
            return "Jugger-Nog";
        
        case 13:
            return "Docks Tower";
        
        case 14:
            return "Zipline To Docks";
        
        case 15:
            return "Zipline From Docks";
    }
}

// ============================================================
// Functions/MapScripts/Moon.gsc
// ============================================================

function PopulateMoonScripts(menu)
{
    switch(menu)
    {
        case "Moon Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
                self addOptSlider("Activate Excavator", &ActivateDigger, Array("Teleporter", "Hangar", "Biodome"));
                self addOptBool(level.FastExcavators, "Fast Excavators", &FastExcavators);

                if(level flag::get("power_on"))
                {
                    self addOptBool(level flag::get("ss1"), "Samantha Says Part 1", &CompleteSamanthaSays, "ss1");

                    if(level flag::get("ss1"))
                        self addOptBool(level flag::get("be2"), "Samantha Says Part 2", &CompleteSamanthaSays, "be2");
                }
            break;
    }
}

function ActivateDigger(force_digger)
{
    force_digger = ToLower(force_digger);

    if(level flag::get("start_" + force_digger + "_digger"))
        return self iPrintlnBold("^1ERROR: ^7Excavator Is Already Activated");

    level flag::set("start_" + force_digger + "_digger");
    level thread send_clientnotify(force_digger, 0);
    level thread play_digger_start_vox(force_digger);
    wait 1;

    level notify(force_digger + "_vox_timer_stop");
    level thread play_timer_vox(force_digger);
}

function send_clientnotify(digger_name, pause)
{
    switch(digger_name)
    {
        case "hangar": util::clientnotify((!pause ? "Dz3" : "Dz3e"));
            break;

        case "teleporter": util::clientnotify((!pause ? "Dz2" : "Dz2e"));
            break;

        case "biodome": util::clientnotify((!pause ? "Dz5" : "Dz5e"));
            break;

        default:
            break;
    }
}

function play_digger_start_vox(digger_name)
{
    level thread play_mooncomp_vox("vox_mcomp_digger_start_", digger_name);
    wait 7;

    if(!Is_True(level.on_the_moon))
        return;

    GetPlayers()[RandomIntRange(0, GetPlayers().size)] thread zm_audio::create_and_play_dialog("digger", "incoming");
}

function do_mooncomp_vox(alias)
{
    for(i = 0; i < GetPlayers().size; i++)
    {
        if(GetPlayers()[i] zm_equipment::is_active(level.var_f486078e))
            GetPlayers()[i] PlaySoundToPlayer(alias + "_f", GetPlayers()[i]);
    }

    if(!IsDefined(level.var_2ff0efb3))
        return;

    foreach(speaker in level.var_2ff0efb3)
    {
        PlaySoundAtPosition(alias, speaker.origin);
        wait 0.05;
    }
}

function play_timer_vox(digger_name)
{
    level endon(digger_name + "_vox_timer_stop");

    time_left = level.diggers_global_time;
    played180sec = 0;
    played120sec = 0;
    played60sec = 0;
    played30sec = 0;
    digger_start_time = GetTime();

    while(time_left > 0)
    {
        time_left = level.diggers_global_time - ((GetTime() - digger_start_time) / 1000);

        if(time_left <= 180 && !played180sec)
        {
            level thread play_mooncomp_vox("vox_mcomp_digger_start_", digger_name);
            played180sec = 1;
        }

        if(time_left <= 120 && !played120sec)
        {
            level thread play_mooncomp_vox("vox_mcomp_digger_start_", digger_name);
            played120sec = 1;
        }

        if(time_left <= 60 && !played60sec)
        {
            level thread play_mooncomp_vox("vox_mcomp_digger_time_60_", digger_name);
            played60sec = 1;
        }

        if(time_left <= 30 && !played30sec)
        {
            level thread play_mooncomp_vox("vox_mcomp_digger_time_30_", digger_name);
            played30sec = 1;
        }

        wait 1;
    }
}

function play_mooncomp_vox(alias, digger)
{
    if(!IsDefined(alias) || !Is_True(level.on_the_moon))
        return;

    if(IsDefined(digger))
    {
        switch(digger)
        {
            case "hangar":
                num = 1;
                break;

            case "teleporter":
                num = 0;
                break;

            case "biodome":
                num = 2;
                break;

            default:
                num = 0;
                break;
        }
    }
    else
    {
        num = "";
    }

    if(!IsDefined(level.mooncomp_is_speaking))
        level.mooncomp_is_speaking = 0;

    if(!level.mooncomp_is_speaking)
    {
        level.mooncomp_is_speaking = 1;
        level do_mooncomp_vox(alias + num);
        level.mooncomp_is_speaking = 0;
    }
}

function CompleteSamanthaSays(part)
{
    if(!level flag::get("power_on"))
        return self iPrintlnBold("^1ERROR: ^7The Power Needs To Be Turned On Before Using This Option");

    if(part == "be2" && !level flag::get("vg_charged"))
        return self iPrintlnBold("^1ERROR: ^7This Step Can't Be Completed Yet");

    if(level flag::get(part))
        return self iPrintlnBold("^1ERROR: ^7Samantha Says Has Already Been Completed");

    if(Is_True(level.SamanthaSays))
        return self iPrintlnBold("^1ERROR: ^7Samantha Says Is Currently Being Completed");

    level.SamanthaSays = true;

    curs = self getCursor();
    menu = self getCurrent();

    while(!level flag::get(part))
    {
        level notify("ss_won");
        level._ss_sequence_matched = true;

        wait 0.025;
    }

    self RefreshMenu(menu, curs);

    if(Is_True(level.SamanthaSays))
        level.SamanthaSays = BoolVar(level.SamanthaSays);
}

function FastExcavators()
{
    level endon("EndFastExcavators");

    level.FastExcavators = BoolVar(level.FastExcavators);

    if(Is_True(level.FastExcavators))
    {
        while(Is_True(level.FastExcavators))
        {
            level flag::wait_till("digger_moving");

            while(level flag::get("digger_moving"))
            {
                foreach(digger in GetEntArray("digger_body", "targetname"))
                {
                    tracks = ((digger.script_string == "teleporter_digger_stopped") ? GetEntArray(digger.target, "targetname")[0] : GetEntArray(digger.target, "targetname")[1]);
                    tracks.digger_speed = 2000; //Set This To Whatever. Default is around 30 - 50. You don't need to reset it since it gets recalculated everytime they move.
                }

                wait 0.1;
            }
        }
    }
    else
    {
        level notify("EndFastExcavators");
    }
}

// ============================================================
// Functions/MapScripts/Nacht.gsc
// ============================================================

function PopulateNachtScripts(menu)
{
    switch(menu)
    {
        case "Nacht Der Untoten Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("snd_zhdegg_completed"), "Samantha's Hide & Seek", &SamanthasHideAndSeekSong);
                self addOptBool(level.NachtUndoneSong, "Undone Song", &NachtUndoneSong);
            break;
    }
}

function NachtUndoneSong()
{
    if(Is_True(level.NachtUndoneSong))
        return self iPrintlnBold("^1ERROR: ^7Undone Song Already Activated");

    level.NachtUndoneSong = true;
    arry = ArrayCombine(GetEntArray("explodable_barrel", "targetname"), GetEntArray("explodable_barrel", "script_noteworthy"), 0, 1);

    foreach(index, barrel in arry)
        barrel DoDamage(barrel.health + 666, barrel.origin, self);
}

// ============================================================
// Functions/MapScripts/Origins.gsc
// ============================================================

function PopulateOriginsScripts(menu)
{
    switch(menu)
    {
        case "Origins Scripts":
            self addMenu(menu);
                self addOptSlider("Weather", &OriginsSetWeather, Array("None", "Rain", "Snow"));
                self addOpt("Generators", &newMenu, "Origins Generators");
                self addOpt("Gateways", &newMenu, "Origins Gateways");
                self addOpt("Give Shovel", &newMenu, "Give Shovel Origins");
                self addOpt("Give Helmet", &newMenu, "Give Helmet Origins");
                self addOpt("Soul Boxes", &newMenu, "Soul Boxes");
                self addOpt("Challenges", &newMenu, "Origins Challenges");
                self addOpt("Staff Puzzles", &newMenu, "Origins Puzzles");
                self addOpt("G-Strike Quest", &newMenu, "Origins G-Strike Quest");
                self addOptBool(level flag::get("crypt_opened"), "Open Crypt", &OpenOriginsCrypt);
                self addOptBool(level.DisableMudSlowdown, "Disable Mud Slowdown", &DisableMudSlowdown);
                self addOptBool(level.DisableTankCooldown, "Disable Tank Cooldown", &DisableTankCooldown);
                self addOptIncSlider("Tank Speed [Default = 8]", &OriginsTankSpeed, 1, 8, 25, 1);
            break;

        case "Origins Generators":
            generators = struct::get_array("s_generator", "targetname");

            self addMenu("Generators");
                self addOptBool(AllOriginsGensActive(), "Enable All", &EnableAllOriginsGens);
                self addOpt("");

                for(a = 0; a < generators.size; a++)
                {
                    foreach(index, generator in struct::get_array("s_generator", "targetname"))
                    {
                        if(generator.script_int != (a + 1)) //The goal is to put the generators in the correct order 1 - 6
                            continue;

                        self addOptBool(generator flag::get("player_controlled"), "Generator " + generator.script_int, &SetGeneratorState, index);
                    }
                }
            break;

        case "Origins Gateways":
            gateways = struct::get_array("trigger_teleport_pad", "targetname");

            self addMenu("Gateways");
                self addOptBool(AreAllGateWaysOpen(), "Enable All", &OpenAllGateways);
                self addOpt("");

                for(a = 0; a < gateways.size; a++)
                    self addOptBool(GetGatewayState(gateways[a]), ReturnGatewayName(gateways[a].target), &SetGatewayState, gateways[a]);
            break;

        case "Give Shovel Origins":
            self addMenu("Give Shovel");

                foreach(player in level.players)
                    self addOptSlider(CleanName(player getName()), &GivePlayerShovel, Array("Normal", "Golden"), player);
            break;

        case "Give Helmet Origins":
            self addMenu("Give Helmet");

                foreach(player in level.players)
                    self addOptBool(player.dig_vars["has_helmet"], CleanName(player getName()), &GivePlayerHelmet, player);
            break;

        case "Soul Boxes":
            boxes = GetEntArray("foot_box", "script_noteworthy");

            self addMenu(menu);

                if(IsDefined(boxes) && boxes.size)
                {
                    self addOpt("Fill All", &FillAllSoulBoxes);
                    self addOpt("");
                    
                    foreach(box in boxes)
                        self addOpt(ReturnSoulBoxName(box.script_int) + " Soul Box", &FillSoulbox, box);
                }
            break;

        case "Origins Challenges":
            if(!IsDefined(self.originsPlayer))
                self.originsPlayer = level.players[0];

            playerArray = [];

            foreach(player in level.players)
                playerArray[playerArray.size] = CleanName(player getName()) + " [" + player GetEntityNumber() + "]";

            self addMenu("Challenges");
                self addOptSlider("Player", &SetOriginsPlayer, playerArray);
                self addOpt("");

                foreach(challenge in level._challenges.a_stats)
                    self addOptBool(get_stat(challenge.str_name, self.originsPlayer).b_medal_awarded, ReturnOriginsIString(challenge.str_name), &CompleteOriginChallenge, challenge.str_name, self.originsPlayer);
            break;

        case "Origins Puzzles":
            self addMenu("Puzzles");
                self addOpt("Ice", &newMenu, "Ice Puzzles");
                self addOpt("Wind", &newMenu, "Wind Puzzles");
                self addOpt("Fire", &newMenu, "Fire Puzzles");
                self addOpt("Lightning", &newMenu, "Lightning Puzzles");
                self addOpt("");
                self addOptSlider("115 Rings", &Align115Rings, Array("Ice", "Lightning", "Fire", "Wind"));
            break;

        case "Ice Puzzles":
            self addMenu("Ice");
                self addOptBool(level flag::get("ice_puzzle_1_complete"), "Tiles", &CompleteIceTiles);
                self addOptBool(level flag::get("ice_puzzle_2_complete"), "Tombstones", &CompleteIceTombstones);
                self addOptBool(level flag::get("staff_water_upgrade_unlocked"), "Damage Orb", &OriginsDamageOrb, "ice");
            break;

        case "Wind Puzzles":
            self addMenu("Wind");
                self addOptBool(level flag::get("air_puzzle_1_complete"), "Rings", &CompleteWindRings);
                self addOptBool(level flag::get("air_puzzle_2_complete"), "Smoke", &CompleteWindSmoke);
                self addOptBool(level flag::get("staff_air_upgrade_unlocked"), "Damage Orb", &OriginsDamageOrb, "air");
            break;

        case "Fire Puzzles":
            self addMenu("Fire");
                self addOptBool(level flag::get("fire_puzzle_1_complete"), "Fill Cauldrons", &ComepleteFireCauldrons);
                self addOptBool(level flag::get("fire_puzzle_2_complete"), "Light Torches", &CompleteFireTorches);
                self addOptBool(level flag::get("staff_fire_upgrade_unlocked"), "Damage Orb", &OriginsDamageOrb, "fire");
            break;

        case "Lightning Puzzles":
            self addMenu("Lightning");
                self addOptBool(level flag::get("electric_puzzle_1_complete"), "Song", &CompleteLightningSong);
                self addOptBool(level flag::get("electric_puzzle_2_complete"), "Turn Dials", &CompleteLightningDials);
                self addOptBool(level flag::get("staff_lightning_upgrade_unlocked"), "Damage Orb", &OriginsDamageOrb, "lightning");
            break;
        
        case "Origins G-Strike Quest":
            self addMenu("G-Strike Quest");
                
                foreach(player in level.players)
                    self addOptBool((IsDefined(player.sq_one_inch_punch_stage) && player.sq_one_inch_punch_stage >= 6), CleanName(player getName()), &OriginsGStrikeQuest, player);
            break;
    }
}

function OriginsSetWeather(weather)
{
    level.last_snow_round = 0;
    level.last_rain_round = 0;

    switch(weather)
    {
        case "Rain":
            level.weather_snow = 0;
            level.weather_rain = RandomIntRange(1, 5);
            level.weather_vision = 1;
            break;

        case "Snow":
            level.weather_snow = RandomIntRange(1, 5);
            level.weather_rain = 0;
            level.weather_vision = 2;
            break;

        case "None":
            level.weather_snow = 0;
            level.weather_rain = 0;
            level.weather_vision = 3;
            break;

        default:
            break;
    }

    level clientfield::set("rain_level", level.weather_rain);
    level clientfield::set("snow_level", level.weather_snow);

    level util::set_lighting_state(weather == "Rain");

    foreach(player in level.players)
    {
        if(zombie_utility::is_player_valid(player, 0, 1))
            player clientfield::set_to_player("player_weather_visionset", level.weather_vision);
    }
}

function EnableAllOriginsGens()
{
    allActive = AllOriginsGensActive();

    foreach(index, generator in struct::get_array("s_generator", "targetname"))
    {
        if(!allActive && !generator flag::get("player_controlled") || allActive && generator flag::get("player_controlled"))
            thread SetGeneratorState(index);
    }
}

function AllOriginsGensActive()
{
    foreach(index, generator in struct::get_array("s_generator", "targetname"))
    {
        if(!generator flag::get("player_controlled"))
            return false;
    }

    return true;
}

function SetGeneratorState(generator)
{
    generators = struct::get_array("s_generator", "targetname");
    struct = generators[generator];

    if(struct flag::get("zone_contested"))
        struct kill_all_capture_zombies();

    struct flag::clear("zone_contested");

    foreach(e_player in level.players)
        e_player thread zm_craftables::player_show_craftable_parts_ui(undefined, "zmInventory.capture_generator_wheel_widget", 0);

    if(!struct flag::get("player_controlled"))
    {
        level.zone_capture.last_zone_captured = struct;

        struct flag::set("player_controlled");
        struct flag::clear("attacked_by_recapture_zombies");

        level clientfield::set("zone_capture_hud_generator_" + struct.script_int, 1);
        level clientfield::set("zone_capture_monolith_crystal_" + struct.script_int, 0);

        if(!IsDefined(struct.perk_fx_func) || [[ struct.perk_fx_func ]]())
            level clientfield::set("zone_capture_perk_machine_smoke_fx_" + struct.script_int, 1);

        struct flag::set("player_controlled");

        struct enable_perk_machines_in_zone();
        struct enable_random_perk_machines_in_zone();
        struct enable_mystery_boxes_in_zone();
        struct function_c3b54f6d();

        level notify("zone_captured_by_player", struct.str_zone);
        PlayFX(level._effect["capture_complete"], struct.origin);

        struct reward_players_in_capture_zone();
    }
    else
    {
        struct flag::clear("player_controlled");
        level clientfield::set("zone_capture_hud_generator_" + struct.script_int, 2);
        level clientfield::set("zone_capture_monolith_crystal_" + struct.script_int, 1);
        level clientfield::set("zone_capture_perk_machine_smoke_fx_" + struct.script_int, 0);

        struct disable_perk_machines_in_zone();
        struct disable_random_perk_machines_in_zone();
        struct disable_mystery_boxes_in_zone();
        struct function_1138b343();
    }

    update_captured_zone_count();

    struct.n_current_progress = (struct flag::get("player_controlled") ? 100 : 0);
    struct.n_last_progress = struct.n_current_progress;

    level clientfield::set("state_" + struct.script_noteworthy, (struct flag::get("player_controlled") ? 2 : 4));
    level clientfield::set(struct.script_noteworthy, struct.n_current_progress / 100);

    play_pap_anim(struct flag::get("player_controlled"));
}

function kill_all_capture_zombies()
{
    while(IsDefined(self.capture_zombies) && self.capture_zombies.size > 0)
    {
        foreach(zombie in self.capture_zombies)
        {
            if(IsDefined(zombie) && IsAlive(zombie))
            {
                PlayFX(level._effect["tesla_elec_kill"], zombie.origin);
                zombie DoDamage(zombie.health + 100, zombie.origin);
            }

            util::wait_network_frame();
        }

        self.capture_zombies = array::remove_dead(self.capture_zombies);
    }

    self.capture_zombies = [];
}

function update_captured_zone_count()
{
    level.total_capture_zones = get_captured_zone_count();

    if(level.total_capture_zones == 6)
        level flag::set("all_zones_captured");
    else
        level flag::clear("all_zones_captured");
}

function get_captured_zone_count()
{
    n_player_controlled_zones = 0;

    foreach(generator in level.zone_capture.zones)
    {
        if(generator flag::get("player_controlled"))
            n_player_controlled_zones++;
    }

    return n_player_controlled_zones;
}

function enable_perk_machines_in_zone()
{
    if(IsDefined(self.perk_machines) && IsArray(self.perk_machines))
    {
        a_keys = GetArrayKeys(self.perk_machines);

        for(a = 0; a < a_keys.size; a++)
        {
            level notify(a_keys[a] + "_on");

            self.perk_machines[a_keys[a]].is_locked = 0;
            self.perk_machines[a_keys[a]] zm_perks::reset_vending_hint_string();
        }
    }
}

function enable_random_perk_machines_in_zone()
{
    if(IsDefined(self.perk_machines_random) && IsArray(self.perk_machines_random))
    {
        foreach(random_perk_machine in self.perk_machines_random)
        {
            random_perk_machine.is_locked = 0;

            if(IsDefined(random_perk_machine.current_perk_random_machine) && random_perk_machine.current_perk_random_machine)
            {
                random_perk_machine set_perk_random_machine_state("idle");
                continue;
            }

            random_perk_machine set_perk_random_machine_state("away");
        }
    }
}

function set_perk_random_machine_state(state)
{
    wait 0.1;

    for(i = 0; i < self GetNumZBarrierPieces(); i++)
        self HideZBarrierPiece(i);

    self notify("zbarrier_state_change");
    self [[ level.perk_random_machine_state_func ]](state);
}

function enable_mystery_boxes_in_zone()
{
    foreach(mystery_box in self.mystery_boxes)
    {
        mystery_box.is_locked = 0;

        mystery_box.zbarrier [[ level.magic_box_zbarrier_state_func ]]("player_controlled"); 
        mystery_box.zbarrier clientfield::set("magicbox_runes", 1);
    }
}

function function_c3b54f6d()
{
    level flag::set("power_on" + self.script_int);
}

function disable_perk_machines_in_zone()
{
    if(IsDefined(self.perk_machines) && IsArray(self.perk_machines))
    {
        a_keys = GetArrayKeys(self.perk_machines);

        for(a = 0; a < a_keys.size; a++)
        {
            level notify(a_keys[a] + "_off");

            e_perk_trigger = self.perk_machines[a_keys[a]];
            e_perk_trigger.is_locked = 1;
            e_perk_trigger SetHintString(&"ZM_TOMB_ZC");
        }
    }
}

function disable_random_perk_machines_in_zone()
{
    if(IsDefined(self.perk_machines_random) && IsArray(self.perk_machines_random))
    {
        foreach(random_perk_machine in self.perk_machines_random)
        {
            random_perk_machine.is_locked = 1;

            if(IsDefined(random_perk_machine.current_perk_random_machine) && random_perk_machine.current_perk_random_machine)
            {
                random_perk_machine set_perk_random_machine_state("initial");
                continue;
            }

            random_perk_machine set_perk_random_machine_state("power_off");
        }
    }
}

function disable_mystery_boxes_in_zone()
{
    foreach(mystery_box in self.mystery_boxes)
    {
        mystery_box.is_locked = 1;

        mystery_box.zbarrier [[ level.magic_box_zbarrier_state_func ]]("zombie_controlled");
        mystery_box.zbarrier clientfield::set("magicbox_runes", 0);
    }
}

function function_1138b343()
{
    level flag::clear("power_on" + self.script_int);
}

function play_pap_anim(b_assemble)
{
    level clientfield::set("packapunch_anim", get_captured_zone_count());
}

function AreAllGateWaysOpen()
{
    gateways = struct::get_array("trigger_teleport_pad", "targetname");

    foreach(gateway in gateways)
    {
        if(!IsDefined(gateway))
            continue;
        
        if(!GetGatewayState(gateway))
            return false;
    }

    return true;
}

function OpenAllGateways()
{
    state = !AreAllGateWaysOpen();
    gateways = struct::get_array("trigger_teleport_pad", "targetname");

    foreach(gateway in gateways)
    {
        if(!IsDefined(gateway))
            continue;

        if(GetGateWayState(gateway) != state)
            SetGateWayState(gateway);
    }
}

function SetGatewayState(gateway)
{
    target = struct::get_array("stargate_gramophone_pos", "targetname")[gateway.script_int];

    if(!GetGatewayState(gateway))
    {
        level flag::set("enable_teleporter_" + gateway.script_int);

        if(IsDefined(target) && IsDefined(target.script_flag))
            level flag::set(target.script_flag);
    }
    else
    {
        level flag::clear("enable_teleporter_" + gateway.script_int);

        if(IsDefined(target) && IsDefined(target.script_flag))
            level flag::clear(target.script_flag);
    }
}

function GetGatewayState(gateway)
{
    return level flag::get("enable_teleporter_" + gateway.script_int);
}

function ReturnGatewayName(targetname)
{
    switch(targetname)
    {
        case "fire_teleport_player":
            return "Fire";

        case "air_teleport_player":
            return "Wind";

        case "water_teleport_player":
            return "Ice";

        case "electric_teleport_player":
            return "Lightning";

        default:
            return "Unknown";
    }
}

function GivePlayerShovel(type, player)
{
    if(!player.dig_vars["has_shovel"])
    {
        player.dig_vars["has_shovel"] = 1;
        level clientfield::set("player" + player GetEntityNumber() + "hasItem", 1);
        player PlaySound("zmb_craftable_pickup");

        wait 0.1;
    }

    if(type == "Normal")
        return;

    //Golden shovel
    player.dig_vars["has_upgraded_shovel"] = 1;
    level clientfield::set("player" + player GetEntityNumber() + "hasItem", 2);
    player PlaySoundToPlayer("zmb_squest_golden_anything", player);
}

function GivePlayerHelmet(player)
{
    if(player.dig_vars["has_helmet"])
        return;

    player.dig_vars["has_helmet"] = 1;
    level clientfield::set("player" + player GetEntityNumber() + "wearableItem", 1);
    player PlaySoundToPlayer("zmb_squest_golden_anything", player);

    if(!IsDefined(player.var_8e065802))
        player.var_8e065802 = SpawnStruct();

    player.var_8e065802.model = "c_t7_zm_dlchd_origins_golden_helmet";
    player.var_8e065802.tag = "j_head";
    player.var_ae07e72c = "golden_helmet";
    player Attach(player.var_8e065802.model, player.var_8e065802.tag);

    if(player.characterindex == 1)
        player SetCharacterBodyStyle(2);
}

function FillAllSoulBoxes()
{
    boxes = GetEntArray("foot_box", "script_noteworthy");

    if(!IsDefined(boxes) || !boxes.size)
        return;
    
    foreach(box in boxes)
    {
        if(!IsDefined(box) || Is_True(box.fillingBox) || box.n_souls_absorbed >= 30)
            continue;
        
        thread FillSoulBox(box);
    }
}

function FillSoulBox(box)
{
    if(!IsDefined(box))
        return;

    if(Is_True(box.fillingBox) || box.n_souls_absorbed >= 30)
        return self iPrintlnBold("^1ERROR: ^7Soul Box Is Already Being Filled");

    box.fillingBox = BoolVar(box.fillingBox);

    curs = self getCursor();
    menu = self getCurrent();

    while(IsDefined(box))
    {
        if(IsDefined(box) && box.n_souls_absorbed < 30)
            box notify("soul_absorbed", self);

        wait 0.01;
    }

    self RefreshMenu(menu, curs, true);
}

function ReturnSoulBoxName(index)
{
    switch(index)
    {
        case 0:
            return "Pack 'a' Punch";

        case 1:
            return "Generator 4";

        case 2:
            return "Church";

        case 3:
            return "Generator 5";
    }
}

function SetOriginsPlayer(playerName)
{
    foreach(player in level.players)
    {
        if(CleanName(player getName()) + " [" + player GetEntityNumber() + "]" == playerName) //I included the players entity number for the case two players have the same name
            self.originsPlayer = player;
    }

    self RefreshMenu(self getCurrent(), self getCursor());
}

function ReturnOriginsIString(stat)
{
    switch(stat)
    {
        case "zc_headshots":
            return "ZM_TOMB_CH1";

        case "zc_zone_captures":
            return "ZM_TOMB_CH2";

        case "zc_points_spent":
            return "ZM_TOMB_CH3";

        case "zc_boxes_filled":
            return "ZM_TOMB_CHT";

        default:
            return "Unknown";
    }
}

function CompleteOriginChallenge(challenge, player)
{
    stat = get_stat(challenge, player);

    if(stat.b_medal_awarded)
        return;

    if(stat.n_value < stat.s_parent.n_goal)
    {
        diff = (stat.s_parent.n_goal - stat.n_value);
        player increment_stat(challenge, diff);
    }
}

function reward_players_in_capture_zone()
{
    if(self flag::get("player_controlled"))
    {
        foreach(player in GetPlayers())
        {
            player notify("completed_zone_capture");

            if(challenge_exists("zc_zone_captures"))
                player increment_stat("zc_zone_captures");
        }
    }
}

function challenge_exists(str_name)
{
    return IsDefined(level._challenges.a_stats[str_name]);
}

function increment_stat(str_stat, n_increment = 1)
{
    s_stat = get_stat(str_stat, self);

    if(!s_stat.b_medal_awarded)
    {
        s_stat.n_value = s_stat.n_value + n_increment;
        check_stat_complete(s_stat);
    }
}

function get_stat(str_stat, player)
{
    if(level._challenges.a_stats[str_stat].b_team)
        return level._challenges.s_team.a_stats[str_stat];

    return level._challenges.a_players[player.characterindex].a_stats[str_stat];
}

function check_stat_complete(s_stat)
{
    if(s_stat.b_medal_awarded)
        return 1;

    if(s_stat.n_value >= s_stat.s_parent.n_goal)
    {
        s_stat.b_medal_awarded = 1;

        if(s_stat.s_parent.b_team)
        {
            level._challenges.s_team.n_completed++;
            level._challenges.s_team.n_medals_held++;

            foreach(player in GetPlayers())
            {
                player clientfield::set_to_player(s_stat.s_parent.cf_complete, 1);
                player function_fbbc8608(s_stat.s_parent.str_hint, s_stat.s_parent.n_index);
                player PlaySound("evt_medal_acquired");

                util::wait_network_frame();
            }
        }
        else
        {
            s_player_stats = level._challenges.a_players[self.characterindex];
            s_player_stats.n_completed++;
            s_player_stats.n_medals_held++;

            self PlaySound("evt_medal_acquired");
            self clientfield::set_to_player(s_stat.s_parent.cf_complete, 1);
            self function_fbbc8608(s_stat.s_parent.str_hint, s_stat.s_parent.n_index);
        }

        foreach(m_board in level.a_m_challenge_boards)
            m_board ShowPart(s_stat.str_glow_tag);

        if(IsPlayer(self))
        {
            if(level._challenges.a_players[self.characterindex].n_completed + level._challenges.s_team.n_completed == level._challenges.a_stats.size)
                self notify("all_challenges_complete");
        }
        else
        {
            foreach(player in GetPlayers())
            {
                if(IsDefined(player.characterindex) && level._challenges.a_players[player.characterindex].n_completed + level._challenges.s_team.n_completed == level._challenges.a_stats.size)
                    player notify("all_challenges_complete");
            }
        }

        util::wait_network_frame();
    }
}

function function_fbbc8608(str_hint, var_7ca2c2ae)
{
    self luinotifyevent(&"trial_complete", 3, &"ZM_TOMB_CHALLENGE_COMPLETED", str_hint, var_7ca2c2ae);
}











//Ice Staff
function CompleteIceTiles()
{
    if(level flag::get("ice_puzzle_1_complete"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.IceTilesInit))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    level.IceTilesInit = true;

    curs = self getCursor();
    menu = self getCurrent();
    ice_gem = GetEnt("ice_chamber_gem", "targetname");

    while(!level flag::get("ice_puzzle_1_complete"))
    {
        if(IsDefined(level.unsolved_tiles) && level.unsolved_tiles.size)
        {
            if(!IsDefined(ice_gem))
                break;

            foreach(tile in level.unsolved_tiles)
            {
                if(!IsDefined(tile) || ice_gem.value != tile.value || !tile.showing_tile_side)
                    continue;

                tile notify("damage", 1, self, (0, 0, 0), tile.origin, undefined, undefined, undefined, undefined, GetWeapon("staff_water"));
            }
        }

        wait 0.01;
    }

    wait 0.1;
    self RefreshMenu(menu, curs);
}

function CompleteIceTombstones()
{
    if(!level flag::get("ice_puzzle_1_complete"))
        return self iPrintlnBold("^1ERROR: ^7Tiles Must Be Completed Before Using This Option");

    if(level flag::get("ice_puzzle_2_complete"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.IceTombstones))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    level.IceTombstones = true;

    curs = self getCursor();
    menu = self getCurrent();
    tombstones = struct::get_array("puzzle_stone_water", "targetname");

    while(!level flag::get("ice_puzzle_2_complete"))
    {
        if(IsDefined(tombstones) && tombstones.size)
        {
            foreach(tombstone in tombstones)
            {
                if(!IsDefined(tombstone) || !IsDefined(tombstone.e_model))
                    continue;

                if(tombstone.e_model.model != "p7_zm_ori_note_rock_01_anim")
                {
                    tombstone.e_model notify("damage", 1, self, (0, 0, 0), tombstone.e_model.origin, undefined, undefined, undefined, undefined, GetWeapon("staff_water"));
                    wait 0.5;
                }

                tombstone.e_model notify("damage", 1, self, (0, 0, 0), tombstone.e_model.origin, "BULLET", undefined, undefined, undefined, level.start_weapon);
            }
        }

        wait 0.01;
    }

    wait 0.1;
    self RefreshMenu(menu, curs);
}








//Wind Staff
function CompleteWindRings()
{
    if(level flag::get("air_puzzle_1_complete"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.WindRings))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    curs = self getCursor();
    menu = self getCurrent();
    level.WindRings = true;

    if(!IsDefined(level.a_ceiling_rings))
        level.a_ceiling_rings = GetEntArray("ceiling_ring", "script_noteworthy");

    while(!level flag::get("air_puzzle_1_complete"))
    {
        if(IsDefined(level.a_ceiling_rings) && level.a_ceiling_rings.size)
        {
            foreach(ring in level.a_ceiling_rings)
            {
                while(ring.position != ring.script_int)
                {
                    if(IsSubStr(ring.targetname, "01"))
                        point = ring.origin + (120, 0, 0);
                    else if(IsSubStr(ring.targetname, "02"))
                        point = ring.origin + (180, 0, 0);
                    else if(IsSubStr(ring.targetname, "03"))
                        point = ring.origin + (240, 0, 0);
                    else if(IsSubStr(ring.targetname, "04"))
                        point = ring.origin + (300, 0, 0);

                    ring notify("damage", 1, self, (0, 0, 0), point, undefined, undefined, undefined, undefined, GetWeapon("staff_air"));
                    wait 1;
                }

                wait 0.1;
            }
        }

        wait 0.01;
    }

    wait 0.1;
    self RefreshMenu(menu, curs);
}

function CompleteWindSmoke()
{
    if(!level flag::get("air_puzzle_1_complete"))
        return self iPrintlnBold("^1ERROR: ^7Rings Must Be Completed Before Using This Option");

    if(level flag::get("air_puzzle_2_complete"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.WindSmoke))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    level.WindSmoke = true;

    curs = self getCursor();
    menu = self getCurrent();

    smokes = struct::get_array("puzzle_smoke_origin", "targetname");
    s_dest = struct::get("puzzle_smoke_dest", "targetname");

    foreach(smoke in smokes)
    {
        if(!IsDefined(smoke) || !IsDefined(smoke.detector_brush))
            continue;

        smoke.detector_brush notify("damage", 1, self, VectorNormalize(s_dest.origin - smoke.origin), undefined, undefined, undefined, undefined, undefined, GetWeapon("staff_air"));
    }

    while(!level flag::get("air_puzzle_2_complete"))
        wait 0.1;

    self RefreshMenu(menu, curs);
}









//Fire Staff
function ComepleteFireCauldrons()
{
    if(level flag::get("fire_puzzle_1_complete"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.FireCauldrons))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    if(!is_chamber_occupied())
        return self iPrintlnBold("^1ERROR: ^7A Player Must Be In The Crazy Place To Complete This Step");

    level.FireCauldrons = true;
    curs = self getCursor();
    menu = self getCurrent();
    self iPrintlnBold("^1" + ToUpper(GetMenuName()) + ": ^7A Player Must Stay In The Crazy Place While This Step Is Being Completed");

    if(!IsDefined(level.sacrifice_volumes))
        level.sacrifice_volumes = GetEntArray("fire_sacrifice_volume", "targetname");

    if(IsDefined(level.sacrifice_volumes) && level.sacrifice_volumes.size)
    {
        foreach(vols in level.sacrifice_volumes)
        {
            if(!is_chamber_occupied())
            {
                level.FireCauldrons = undefined;
                return self iPrintlnBold("^1ERROR: ^7Fire Cauldrons Reset -- A Player Must Remain In The Crazy Place While The Step Is Being Completed");
            }

            if(vols.b_gods_pleased || vols.num_sacrifices_received >= 32)
                continue;

            self notify("projectile_impact", GetWeapon("staff_fire"), vols.origin, 100, GetWeapon("staff_fire"));

            for(a = 0; a < 33; a++)
            {
                level notify("vo_try_puzzle_fire1", self);
                vols.num_sacrifices_received++;
                vols.pct_sacrifices_received = (vols.num_sacrifices_received / 32);

                wait 0.1;
            }

            self notify("projectile_impact", GetWeapon("staff_fire"), vols.origin, 100, GetWeapon("staff_fire"));
            vols.b_gods_pleased = 1;

            wait 2;
        }
    }

    while(!level flag::get("fire_puzzle_1_complete"))
        wait 0.1;

    self RefreshMenu(menu, curs);
}

function is_chamber_occupied()
{
    foreach(e_player in GetPlayers())
    {
        if(is_point_in_chamber(e_player.origin))
            return 1;
    }

    return 0;
}

function is_point_in_chamber(v_origin)
{
    if(!IsDefined(level.s_chamber_center))
    {
        level.s_chamber_center = struct::get("chamber_center", "targetname");
        level.s_chamber_center.radius_sq = (level.s_chamber_center.script_float * level.s_chamber_center.script_float);
    }

    return (Distance2DSquared(level.s_chamber_center.origin, v_origin) < level.s_chamber_center.radius_sq);
}

function CompleteFireTorches()
{
    if(!level flag::get("fire_puzzle_1_complete"))
        return self iPrintlnBold("^1ERROR: ^7The Cauldrons Must Be Filled Before Using This Option");

    if(level flag::get("fire_puzzle_2_complete"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.FireTorches))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    level.FireTorches = true;
    curs = self getCursor();
    menu = self getCurrent();

    torches = GetEntArray("fire_torch_ternary", "script_noteworthy");

    if(IsDefined(torches) && torches.size)
    {
        foreach(torch in torches)
        {
            target = struct::get(torch.target, "targetname");

            if(!IsDefined(target) || !target.b_correct_torch)
                continue;

            self notify("projectile_impact", GetWeapon("staff_fire"), target.origin, 100, GetWeapon("staff_fire"));
            wait 0.5;
        }
    }

    while(!level flag::get("fire_puzzle_2_complete"))
        wait 0.1;

    self RefreshMenu(menu, curs);
}












//Lightning Staff
function CompleteLightningSong()
{
    if(level flag::get("electric_puzzle_1_complete"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    if(Is_True(level.LightningSong))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    if(!is_chamber_occupied())
        return self iPrintlnBold("^1ERROR: ^7A Player Must Be In The Crazy Place To Complete This Step");

    level.LightningSong = true;
    curs = self getCursor();
    menu = self getCurrent();
    self iPrintlnBold("^1" + ToUpper(GetMenuName()) + ": ^7A Player Must Stay In The Crazy Place While This Step Is Being Completed");

    order = Array(11, 7, 3, 7, 4, 2, 9, 5, 3); //The order is always the same

    level notify("piano_keys_stop");
	level.a_piano_keys_playing = [];
    wait 4;

    for(a = 0; a < 3; a++)
    {
        if(!is_chamber_occupied())
        {
            level.LightningSong = undefined;
            return self iPrintlnBold("^1ERROR: ^7Lightning Song Reset -- A Player Must Remain In The Crazy Place While The Step Is Being Completed");
        }

        for(b = (0 + (3 * a)); b < (3 + (3 * a)); b++)
        {
            self notify("projectile_impact", GetWeapon("staff_lightning"), struct::get_array("piano_key", "script_noteworthy")[order[b]].origin);
            wait 0.5;
        }

        wait 5;
    }

    while(!level flag::get("electric_puzzle_1_complete"))
        wait 0.1;

    self RefreshMenu(menu, curs);
}

function CompleteLightningDials()
{
    if(!level flag::get("electric_puzzle_1_complete"))
        return self iPrintlnBold("^1ERROR: ^7The Song Must Be Completed Before Using This Option");

    if(level flag::get("electric_puzzle_2_complete"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.turndials))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    level.turndials = true;
    curs = self getCursor();
    menu = self getCurrent();

    foreach(relay in level.electric_relays)
    {
        if(relay.position == 2)
            continue;

        while(!IsDefined(relay.connections[relay.position]) || relay.connections[relay.position] == "")
        {
            relay.trigger_stub notify("trigger", self);
            wait 0.1;
        }

        wait 0.5;
    }

    while(!level flag::get("electric_puzzle_2_complete"))
        wait 0.1;

    self RefreshMenu(menu, curs);
}

//End Staff Puzzles


//This script was thrown together in the matter of a few minutes. So it is a little sloppy and not fully tested :P
// Suggested by: aesthet_ic
function OriginsDamageOrb(type)
{
    fixType = ((type == "ice") ? "water" : type);

    if(level flag::get("staff_" + fixType + "_upgrade_unlocked"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");
    
    menu = self getCurrent();
    curs = self getCursor();

    gems = GetEntArray("crypt_gem", "script_noteworthy");
    gemType = ((type == "lightning") ? "elec" : type);

    foreach(gem in gems)
    {
        if(!IsDefined(gem) || gem.targetname != "crypt_gem_" + gemType)
            continue;
        
        targetGem = gem;
    }

    if(IsDefined(targetGem)) //based on the code, if the gem still exists, then we aren't ready for this step yet.
        return self iPrintlnBold("^1ERROR: ^7This Step Can't Be Completed Yet");

    if(!IsDefined(level.damageOrb))
        level.damageOrb = [];
    
    if(Is_True(level.damageOrb[type]))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");
    
    level.damageOrb[type] = true;
    rings = Align115Rings(((type == "air") ? "wind" : type));

    if(!Is_True(rings))
    {
        level.damageOrb[type] = undefined;
        return self iPrintlnBold("^1ERROR: ^7Couldn't Align Rings For Orb");
    }

    foreach(ent in GetEntArray("script_model", "classname"))
    {
        if(!IsDefined(ent) || ent.model != struct::get(type + "_orb_exit_path", "targetname").model)
            continue;
        
        ent notify("damage", 99, self, (0, 0, 0), ent.origin, undefined, undefined, undefined, undefined, GetWeapon("staff_" + fixType));
    }

    while(!level flag::get("staff_" + fixType + "_upgrade_unlocked"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
    level.damageOrb[type] = undefined;
}



function Align115Rings(type)
{
    type = ToLower(type);

    if(level flag::get("disc_rotation_active"))
        return self iPrintlnBold("^1ERROR: ^7Rings Are Currently Rotating");

    switch(type)
    {
        case "ice":
            num = 0;
            break;

        case "lightning":
            num = 1;
            break;

        case "fire":
            num = 2;
            break;

        case "wind":
            num = 3;
            break;

        default:
            num = 0;
            break;
    }

    level flag::set("disc_rotation_active");

    foreach(ring in GetEntArray("crypt_puzzle_disc", "script_noteworthy"))
    {
        if(ring.position == num || !IsDefined(ring.target))
            continue;

        ring.position = num;
        ring RotateTo((ring.angles[0], (ring.position * 90), ring.angles[2]), 1, 0, 0);
        ring PlaySound("zmb_crypt_disc_turn");

        wait 0.75;
        ring.n_bryce_cake = ((ring.n_bryce_cake + 1) % 2);

        if(IsDefined(ring.var_b1c02d8a))
            ring.var_b1c02d8a clientfield::set("bryce_cake", ring.n_bryce_cake);

        wait 0.25;
        ring.n_bryce_cake = ((ring.n_bryce_cake + 1) % 2);

        if(IsDefined(ring.var_b1c02d8a))
            ring.var_b1c02d8a clientfield::set("bryce_cake", ring.n_bryce_cake);

        ring PlaySound("zmb_crypt_disc_stop");
        rumble_nearby_players(ring.origin, 1000, 2);

        wait 1;
        level notify("crypt_disc_rotation");
    }

    level flag::clear("disc_rotation_active");
    return true;
}

function rumble_nearby_players(v_center, n_range, n_rumble_enum)
{
    a_rumbled_players = [];

    foreach(e_player in GetPlayers())
    {
        if(DistanceSquared(v_center, e_player.origin) < (n_range * n_range))
        {
            e_player clientfield::set_to_player("player_rumble_and_shake", n_rumble_enum);
            a_rumbled_players[a_rumbled_players.size] = e_player;
        }
    }

    util::wait_network_frame();

    foreach(e_player in a_rumbled_players)
        e_player clientfield::set_to_player("player_rumble_and_shake", 0);
}

function OpenOriginsCrypt()
{
    if(level flag::get("crypt_opened"))
        return;
    
    if(Is_True(level.OpeningCrypt))
        return self iPrintlnBold("^1ERROR: ^7The Crypt Is Already Being Opened");
    
    level.OpeningCrypt = true;
    menu = self getCurrent();
    curs = self getCursor();

    level notify("open_all_gramophone_doors");
    a_door_main = GetEntArray("chamber_entrance", "targetname");
    trig_position = struct::get(a_door_main[1].targetname + "_position", "targetname");
    trig_position.has_vinyl = true;
    wait 0.5;

    if(IsDefined(trig_position.trigger))
        trig_position.trigger notify("trigger", self);
    
    wait 6;
    level.b_open_all_gramophone_doors = undefined;

    while(IsDefined(a_door_main[1]))
        wait 0.1;

    if(IsDefined(trig_position.trigger))
        trig_position.trigger notify("trigger", self);

    while(!level flag::get("crypt_opened"))
        wait 0.1;
    
    level.OpeningCrypt = undefined;
    self RefreshMenu(menu, curs);
}




//G-Strike Quest
function OriginsGStrikeQuest(player)
{
    player endon("disconnect");

    if(!IsDefined(level.n_tablets_remaining) || level.n_tablets_remaining <= 0)
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(!IsDefined(player.sq_one_inch_punch_stage))
        return self iPrintlnBold("^1ERROR: ^7This Quest Can't Be Completed");
    
    if(player.sq_one_inch_punch_stage >= 6)
        return self iPrintlnBold("^1ERROR: ^7This Quest Has Already Been Completed");

    if(Is_True(player.completingGStrike))
        return self iPrintlnBold("^1ERROR: ^7This Quest Is Currently Being Completed");

    player.completingGStrike = true;
    menu = self getCurrent();
    curs = self getCursor();

    t_bunker = GetEnt("trigger_oneinchpunch_bunker_table", "targetname");
    t_birdbath = GetEnt("trigger_oneinchpunch_church_birdbath", "targetname");

    if(player.sq_one_inch_punch_stage == 0)
    {
        if(IsDefined(t_bunker))
            t_bunker notify("trigger", player);
        
        wait 0.5;
    }

    if(player.sq_one_inch_punch_stage == 1)
    {
        if(IsDefined(t_birdbath))
            t_birdbath notify("trigger", player);
        
        wait 0.5;
    }

    if(player.sq_one_inch_punch_stage == 2)
    {
        spawnedZombies = [];
        churchVolume = GetEnt("oneinchpunch_church_volume", "targetname");

        if(IsDefined(churchVolume))
        {
            while(player.sq_one_inch_punch_stage == 2)
            {
                zombie = SpawnSacrificedZombie(churchVolume);
                
                if(IsDefined(zombie))
                {
                    spawnedZombies[spawnedZombies.size] = zombie;
                    zombie DoDamage(zombie.health + 666, zombie.origin, player, player, undefined, "MOD_MELEE");
                }
            }
        }

        if(spawnedZombies.size)
        {
            for(a = 0; a < spawnedZombies.size; a++)
            {
                if(!IsDefined(spawnedZombies[a]) || !IsAlive(spawnedZombies[a]))
                    continue;
                
                spawnedZombies[a] DoDamage(spawnedZombies[a].health + 666, spawnedZombies[a].origin);
            }

            wait 0.5;
            spawnedZombies = undefined;
        }

        wait 0.5;
    }

    if(player.sq_one_inch_punch_stage == 3)
    {
        if(IsDefined(t_birdbath))
            t_birdbath notify("trigger", player);
        
        wait 0.5;
    }

    if(player.sq_one_inch_punch_stage == 4)
    {
        if(IsDefined(t_bunker))
            t_bunker notify("trigger", player);
        
        wait 0.5;
    }

    if(player.sq_one_inch_punch_stage == 5)
    {
        spawnedZombies = [];
        churchVolume = GetEnt("oneinchpunch_bunker_volume", "targetname");

        if(IsDefined(churchVolume))
        {
            while(player.sq_one_inch_punch_kills < 20)
            {
                zombie = SpawnSacrificedZombie(churchVolume);
                
                if(IsDefined(zombie))
                {
                    spawnedZombies[spawnedZombies.size] = zombie;
                    zombie DoDamage(zombie.health + 666, zombie.origin, player, player, undefined, "MOD_MELEE");
                }
            }
        }

        if(spawnedZombies.size)
        {
            for(a = 0; a < spawnedZombies.size; a++)
            {
                if(!IsDefined(spawnedZombies[a]) || !IsAlive(spawnedZombies[a]))
                    continue;
                
                spawnedZombies[a] DoDamage(spawnedZombies[a].health + 666, spawnedZombies[a].origin);
            }

            wait 0.5;
            spawnedZombies = undefined;
        }

        wait 0.5;
    }

    if(player.sq_one_inch_punch_stage == 6)
    {
        while(!Is_True(player.beacon_ready))
            wait 0.1;
        
        if(IsDefined(t_bunker))
            t_bunker notify("trigger", player);
    }

    player.completingGStrike = BoolVar(player.completingGStrike);
    self RefreshMenu(menu, curs);
}





//Miscellaneous
function DisableMudSlowdown()
{
    level.DisableMudSlowdown = BoolVar(level.DisableMudSlowdown);
    level.a_e_slow_areas = (Is_True(level.DisableMudSlowdown) ? GetEntArray("trigger_out_of_bounds", "classname") : GetEntArray("player_slow_area", "targetname"));
}

function DisableTankCooldown()
{
    level.DisableTankCooldown = BoolVar(level.DisableTankCooldown);

    while(IsDefined(level.DisableTankCooldown))
    {
        if(level.vh_tank flag::get("tank_moving"))
            level.vh_tank.str_location_current = ""; //End the loop that sets the cooldown time while moving

        if(level.vh_tank flag::get("tank_cooldown"))
            level.vh_tank.n_cooldown_timer = 2; //2 seconds is actuall the minimum the cooldown script allows
        
        wait 0.01;
    }
}

function OriginsTankSpeed(speed)
{
    level notify("EndTankSpeed");
    level endon("EndTankSpeed");

    if(speed != 8)
    {
        while(1)
        {
            while(level.vh_tank flag::get("tank_moving"))
            {
                level.vh_tank SetSpeedImmediate(speed);
                wait 0.5;
            }

            level.vh_tank flag::wait_till("tank_moving");
        }
    }
    else
    {
        if(level.vh_tank flag::get("tank_moving"))
            level.vh_tank SetSpeedImmediate(8);
    }
}

// ============================================================
// Functions/MapScripts/Revelations.gsc
// ============================================================

function PopulateRevelationsScripts(menu)
{
    switch(menu)
    {
        case "Revelations Scripts":
            self addMenu(menu);
                self addOpt("Challenges", &newMenu, "Map Challenges");
                self addOpt("Keeper Companion Parts", &newMenu, "Revelations Keeper Companion");
                self addOptBool(level flag::get("all_power_on"), "Corrupt All Generators", &RevelationsPowerOn);
                self addOptBool(level flag::get("apothicon_trapped"), "Trap Apothicon", &TrapApothicon);
                self addOptBool(level flag::get("apotho_pack_freed"), "Free Pack 'a' Punch", &RevelationsFreePackAPunch);
                self addOptBool(level flag::get("character_stones_done"), "Damage Tombstones", &DamageTombstones);
            break;

        case "Revelations Keeper Companion":
            self addMenu("Keeper Companion");
                self addOptBool(level flag::get("keeper_callbox_gem_found"), "Gem", &RevelationsKeeperCraftable, "gem");
                self addOptBool(level flag::get("keeper_callbox_head_found"), "Skull", &RevelationsKeeperCraftable, "head");
                self addOptBool(level flag::get("keeper_callbox_totem_found"), "Keeper Flag", &RevelationsKeeperCraftable, "totem");
            break;
    }
}

function RevelationsKeeperCraftable(craftable)
{
    if(!IsDefined(craftable) || !level flag::exists("keeper_callbox_" + craftable + "_found") || level flag::get("keeper_callbox_" + craftable + "_found"))
        return;

    partStruct = struct::get_array("companion_" + craftable + "_part", "targetname");

    foreach(part in partStruct)
    {
        if(IsDefined(part) && IsString(part.var_fdb628a4) && part.var_fdb628a4 == "keeper_callbox_" + craftable)
            cPart = part;
    }

    if(IsDefined(cPart))
        cPart notify("trigger_activated", self);
}

function RevelationsPowerOn()
{
    if(level flag::get("all_power_on"))
        return self iPrintlnBold("^1ERROR: All Power Generators Are Already Corrupt");

    level flag::set("power_on");
}

function TrapApothicon()
{
    if(level flag::get("apothicon_trapped"))
        return self iPrintlnBold("^1ERROR: ^7The Apothicon Has Already Been Trapped");

    if(!level flag::get("all_power_on"))
        return self iPrintlnBold("^1ERROR: ^7All Power Generators Must Be Corrupt First");

    if(IsDefined(level.TrappingApothicon))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    level.TrappingApothicon = true;

    menu = self getCurrent();
    curs = self getCursor();

    if(!level flag::get("apothicon_near_trap"))
    {
        self iPrintlnBold("^1" + ToUpper(GetMenuName()) + ": ^7Waiting For The Apothicon To Be Near The Trap");

        while(!level flag::get("apothicon_near_trap"))
            wait 0.01;
    }

    trapTrigger = struct::get("apothicon_trap_trig", "targetname");
    trapTrigger notify("trigger_activated", self);

    wait 0.1;
    self RefreshMenu(menu, curs);
    level.TrappingApothicon = undefined;
}

function RevelationsFreePackAPunch()
{
    if(!level flag::get("apothicon_trapped"))
        return self iPrintlnBold("^1ERROR: ^7The Apothicon Needs To Be Trapped First");

    if(level flag::get("apotho_pack_freed"))
        return self iPrintlnBold("^1ERROR: ^7The Pack 'a' Punch Has Already Been Freed");

    menu = self getCurrent();
    curs = self getCursor();

    //I couldn't find the entities, so decided to go the lazy route after 10 minutes.
    origins = Array((1200, 139, -2769), (932, 418, -2817), (841, -206, -2822));

    for(a = 0; a < origins.size; a++)
        RadiusDamage(origins[a], 100, 999, 999, self);

    while(!level flag::get("apotho_pack_freed"))
        wait 0.1;

    self RefreshMenu(menu, curs);
}

function DamageTombstones()
{
    if(level flag::get("character_stones_done"))
        return self iPrintlnBold("^1ERROR: ^7This Step Has Already Been Completed");

    if(Is_True(level.DamageGraveStones))
        return self iPrintlnBold("^1ERROR: ^7This Step Is Currently Being Completed");

    level.DamageGraveStones = true;

    menu = self getCurrent();
    curs = self getCursor();

    script_int = 1;
    stones = GetEntArray("tombstone", "targetname");

    while(script_int <= 4)
    {
        foreach(stone in stones)
        {
            if(stone.script_int != script_int)
                continue;

            stone notify("trigger");
            script_int++;

            wait 0.1;
        }

        wait 0.1;
    }

    while(!level flag::get("character_stones_done"))
        wait 0.1;

    self RefreshMenu(menu, curs);
}

// ============================================================
// Functions/MapScripts/ShadowsOfEvil.gsc
// ============================================================

function PopulateSOEScripts(menu)
{
    switch(menu)
    {
        case "Shadows Of Evil Scripts":
            self addMenu(menu);
                self addOpt("Beast Mode", &newMenu, "Beast Mode");
                self addOpt("Fumigator", &newMenu, "SOE Fumigator");
                self addOpt("Smashables", &newMenu, "SOE Smashables");
                self addOpt("Power Switches", &newMenu, "SOE Power Switches");
                self addOpt("Snakeskin Boots", &newMenu, "Snakeskin Boots");

                if(level.players.size < 4)
                    self addOptBool(level.SOEAllowFullEE, "Allow Full Easter Egg(Less Than 4 Players)", &SOEAllowFullEE);

                self addOpt("Show Wall Symbol Code", &SOEShowCode);
            break;

        case "Beast Mode":
            self addMenu(menu);

                foreach(player in level.players)
                    self addOptBool(player.beastmode, CleanName(player getName()), &PlayerBeastMode, player);
            break;

        case "SOE Fumigator":
            self addMenu("Fumigator");

                foreach(player in level.players)
                    self addOptBool(player clientfield::get_to_player("pod_sprayer_held"), CleanName(player getName()), &SOEGrabFumigator, player);
            break;

        case "SOE Smashables":
            self addMenu("Smashables");

                if(SOESmashablesRemaining())
                {
                    foreach(smashable in GetEntArray("beast_melee_only", "script_noteworthy"))
                    {
                        target = GetEnt(smashable.target, "targetname");

                        if(!IsDefined(target))
                            continue;

                        self addOpt(ReturnSOESmashableName(CleanString(smashable.targetname)), &TriggerSOESmashable, smashable);
                    }
                }
            break;

        case "SOE Power Switches":
            self addMenu("Power Switches");

                if(SOEPowerSwitchesRemaining())
                {
                    foreach(ooze in GetEntArray("ooze_only", "script_noteworthy"))
                    {
                        if(IsSubStr(ooze.targetname, "keeper_sword") || IsSubStr(ooze.targetname, "ee_district_rail"))
                            continue;

                        self addOpt(ReturnSOEPowerName(ooze.script_int), &TriggerSOEESwitch, ooze);
                    }
                }
            break;

        case "Snakeskin Boots":
            self addMenu(menu);

                foreach(index, radio in GetEntArray("hs_radio", "targetname"))
                {
                    if(IsDefined(radio) && !Is_True(radio.b_activated))
                        self addOpt(ReturnRadioName(index) + " Radio", &ActivateSOERadio, radio);
                }
            break;
    }
}

function PlayerBeastMode(player)
{
    if(Is_True(player.beastModeExecution))
        return;
    player.beastModeExecution = true;

    curs = self getCursor();
    menu = self getCurrent();

    player endon("disconnect");

    if(!Is_True(player.beastmode))
    {
        player.altbody = 1;
        player.var_b2356a6c = player.origin;
        player.var_227fe352 = player.angles;

        player SetPerk("specialty_playeriszombie");
        player thread function_72c3fae0(1);
        player SetCharacterBodyType(level.altbody_charindexes["beast_mode"]);
        player SetCharacterBodyStyle(0);
        player SetCharacterHelmetStyle(0);
        player clientfield::set_to_player("player_in_afterlife", 1);
        player function_96a57786("beast_mode");
        player thread function_43af326a("beast_mode");

        if(IsDefined(level.altbody_enter_callbacks["beast_mode"]))
            player [[ level.altbody_enter_callbacks["beast_mode"] ]]("beast_mode");

        player clientfield::set("player_altbody", 1);
        player thread BeastModeWatchForCancel();
    }
    else
    {
        player notify("altbody_end");
    }

    wait 0.1;
    self RefreshMenu(menu, curs);
    
    if(IsDefined(player.is_drinking) && player.is_drinking)
        player.is_drinking = 0;
    
    player.beastModeExecution = undefined;
}

function function_a27a52af(name)
{
    foreach(str_bgb in level.var_ba1ef2b1[name])
    {
        if(self bgb::is_enabled(str_bgb))
            return true;
    }

    return false;
}

function Exit_BeastMode()
{
    self endon("disconnect");

    self.altbody = 0;
    self clientfield::set("player_altbody", 0);
    self clientfield::set_to_player("player_in_afterlife", 0);
    callback = level.altbody_exit_callbacks["beast_mode"];

    if(IsDefined(callback))
        self [[ callback ]]("beast_mode");

    if(!IsDefined(self.altbody_visionset))
        self.altbody_visionset = [];

    visionset = level.altbody_visionsets["beast_mode"];

    if(IsDefined(visionset))
    {
        visionset_mgr::deactivate("visionset", visionset, self);
        self.altbody_visionset["beast_mode"] = 0;
    }

    self thread function_d97ca744("beast_mode");
    self UnSetPerk("specialty_playeriszombie");
    self DetachAll();
    self thread function_72c3fae0(0);
    self [[ level.givecustomcharacters ]]();
}

function BeastModeWatchForCancel()
{
    self endon("death");
    self endon("disconnect");

    self waittill("altbody_end");
    self Exit_BeastMode();
}

function function_72c3fae0(washuman)
{
    if(washuman)
    {
        PlayFX(level._effect["human_disappears"], self.origin);
    }
    else
    {
        PlayFX(level._effect["zombie_disappears"], self.origin);
        PlaySoundAtPosition("zmb_player_disapparate", self.origin);
        self PlayLocalSound("zmb_player_disapparate_2d");
    }
}

function function_96a57786(name)
{
    self endon("disconnect");

    self bgb::suspend_weapon_cycling();
    loadout = level.altbody_loadouts[name];

    if(IsDefined(loadout))
    {
        self DisableWeaponCycling();
        self.get_player_weapon_limit = &get_altbody_weapon_limit;
        self.altbody_loadout[name] = zm_weapons::player_get_loadout();
        self zm_weapons::player_give_loadout(loadout, 0, 1);

        if(!IsDefined(self.altbody_loadout_ever_had))
            self.altbody_loadout_ever_had = [];

        if(IsDefined(self.altbody_loadout_ever_had[name]) && self.altbody_loadout_ever_had[name])
            self SetEverHadWeaponAll(1);

        self.altbody_loadout_ever_had[name] = 1;
        self util::waittill_any_timeout(1, "weapon_change_complete");
        self ResetAnimations();
    }
}

function get_altbody_weapon_limit(player)
{
    return 16;
}

function function_43af326a(name)
{
    self endon("disconnect");

    if(!IsDefined(self.altbody_visionset))
        self.altbody_visionset = [];

    visionset = level.altbody_visionsets[name];

    if(IsDefined(visionset))
    {
        if(IsDefined(self.altbody_visionset[name]) && self.altbody_visionset[name])
        {
            visionset_mgr::deactivate("visionset", visionset, self);
            util::wait_network_frame();
            util::wait_network_frame();

            if(!IsDefined(self))
                return;
        }

        visionset_mgr::activate("visionset", visionset, self);
        self.altbody_visionset[name] = 1;
    }
}

function function_d97ca744(name, trigger)
{
    self endon("disconnect");

    loadout = level.altbody_loadouts[name];

    if(IsDefined(loadout))
    {
        if(IsDefined(self.altbody_loadout[name]))
        {
            self zm_weapons::switch_back_primary_weapon(self.altbody_loadout[name].current, 1);
            self.altbody_loadout[name] = undefined;
            self util::waittill_any_timeout(1, "weapon_change_complete");
        }

        self zm_weapons::player_take_loadout(loadout);
        self.get_player_weapon_limit = undefined;
        self ResetAnimations();
        self EnableWeaponCycling();
    }

    self bgb::resume_weapon_cycling();
}

function SOEGrabFumigator(player)
{
    if(player clientfield::get_to_player("pod_sprayer_held"))
        return;

    a_sprayers = array::randomize(struct::get_array("pod_sprayer_location", "targetname"));

    foreach(spray in a_sprayers)
    {
        if(IsDefined(spray) && IsDefined(spray.trigger))
        {
            spray.trigger notify("trigger", player);
            break;
        }
    }
}

function TriggerSOESmashable(smashable)
{
    target = GetEnt(smashable.target, "targetname");

    if(!IsDefined(smashable) || !IsDefined(target))
        return;

    curs = self getCursor();
    menu = self getCurrent();

    level notify("beast_melee", self, smashable.origin);

    wait 0.1;
    self RefreshMenu(menu, curs);
}

function ReturnSOESmashableName(name)
{
    switch(name)
    {
        case "Pf29459 Auto3":
            return "Canal Apothicon Statue";

        case "Pf29461 Auto3":
            return "Junction Apothicon Statue";

        case "Pf29468 Auto3":
            return "Waterfront Apothicon Statue";

        case "Pf29470 Auto3":
            return "Rift Apothicon Statue";

        case "Unlock Quest Key":
            return "Summoning Key";

        case "Memento Detective Drop":
            return "Detective Badge";

        case "Memento Femme Drop":
            return "Hair Piece";

        case "Memento Boxer Drop":
            return "Championship Belt";

        case "Smash Trigger Open Slums":
            return "Boxing Gym Door";

        case "Smash Unnamed 0":
            return "Loading Dock Door";

        case "Canal Portal":
            return "Canal Rift Door";

        case "Theater Portal":
            return "Theater Rift Door";

        case "Slums Portal":
            return "Slums Rift Portal";

        default:
            return "Unknown";
    }
}

function SOESmashablesRemaining()
{
    foreach(smashable in GetEntArray("beast_melee_only", "script_noteworthy"))
    {
        target = GetEnt(smashable.target, "targetname");

        if(IsDefined(target))
            return true;
    }

    return false;
}

function SOEPowerSwitchesRemaining()
{
    foreach(ooze in GetEntArray("ooze_only", "script_noteworthy"))
    {
        if(IsSubStr(ooze.targetname, "keeper_sword") || IsSubStr(ooze.targetname, "ee_district_rail"))
            continue;

        return true;
    }

    return false;
}

function TriggerSOEESwitch(eswitch)
{
    target = GetEnt(eswitch.target, "targetname");

    if(!IsDefined(eswitch) || !IsDefined(target))
        return;

    curs = self getCursor();
    menu = self getCurrent();

    target notify("damage", 1, self, undefined, undefined, undefined, undefined, undefined, undefined, GetWeapon("zombie_beast_lightning_dwl"));

    wait 0.1;
    self RefreshMenu(menu, curs);
}

function ReturnSOEPowerName(ints)
{
    switch(ints)
    {
        case 1:
            return "Quick Revive";

        case 2:
            return "Stamin-Up";

        case 3:
            return "Mule Kick";

        case 4:
            return "Jugger-Nog";

        case 5:
            return "Speed Cola";

        case 6:
            return "Double Tap";

        case 7:
            return "Widow's Wine";

        case 11:
            return "Waterfront Stairs";

        case 12:
            return "Canal Stairs";

        case 13:
            return "Footlight Stairs";

        case 14:
            return "Neros Landing Stairs";

        case 15:
            return "Rift Power Door";

        case 16:
            return "Ruby Rabbit Stairs";

        case 20:
            return "Golden Fountain Pen Crane";

        case 21:
            return "The Black Lace Door";

        case 23:
            return "Canal Power";

        default:
            return "unknown";
    }
}

function ActivateSOERadio(radio)
{
    if(!IsDefined(radio) || Is_True(radio.b_activated))
        return;

    menu = self getCurrent();
    curs = self getCursor();

    radio notify("trigger_activated");
    wait 0.1;

    self RefreshMenu(menu, curs);
}

function ReturnRadioName(ints)
{
    switch(ints)
    {
        case 0:
            return "Ruby Rabbit";

        case 1:
            return "Boxing Gym";

        case 2:
            return "Footlight Station";
    }
}

function SOEAllowFullEE()
{
    if(level flag::get("ee_begin"))
        return self iPrintlnBold("^1ERROR: ^7It's Too Late To Enable The Solo Easter Egg");

    if(IsDefined(level.SOEAllowFullEE))
        return self iPrintlnBold("^1ERROR: ^7The Full Easter Egg Has Already Been Enabled");

    level.SOEAllowFullEE = true;

    level flag::wait_till("ee_begin");
    level.var_421ff75e = 1;

    level endon(#"hash_53e673b7");
    level waittill(#"hash_fbc505ba");

    for(a = 0; a < 4; a++)
    {
        railEnt = GetEnt("ee_district_rail_electrified_" + a, "targetname");

        if(IsDefined(railEnt))
            railEnt thread SOE_RailStayElectrified(a);
    }
}

function SOE_RailStayElectrified(index)
{
    self waittill("trigger", player);

    while(1)
    {
        level flag::wait_till_clear("ee_district_rail_electrified_" + index);

        if(!IsDefined(self))
            break;

        self notify("trigger", player);
        wait 0.05;
    }
}

function SOEShowCode()
{
    self iPrintlnBold("Left To Right -- " + (level.o_canal_beastcode.m_a_codes[0][0] + 1) + " " + (level.o_canal_beastcode.m_a_codes[0][1] + 1) + " " + (level.o_canal_beastcode.m_a_codes[0][2] + 1));
}

// ============================================================
// Functions/MapScripts/ShangriLa.gsc
// ============================================================

function PopulateShangriLaScripts(menu)
{
    switch(menu)
    {
        case "Shangri-La Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
                self addOptBool(level flag::get("snd_zhdegg_completed"), "Samantha's Hide & Seek", &ShangHideAndSeekSong);
                
                if(level.players.size < 4)
                    self addOptBool(level.TempleAllowFullEE, "Allow Full Easter Egg(Less Than 4 Players)", &TempleAllowFullEE);
            break;
    }
}

function ShangHideAndSeekSong()
{
    if(level flag::get("snd_zhdegg_completed"))
        return self iPrintlnBold("^1ERROR: ^7Samantha's Hide & Seek Has Already Been Completed");

    if(Is_True(level.StartedSamanthaSong))
        return self iPrintlnBold("^1ERROR: ^7Samantha's Hide & Seek Has Already Been Started");

    level.StartedSamanthaSong = true;

    curs = self getCursor();
    menu = self getCurrent();

    gongs = GetEntArray("sq_gong", "targetname");

    for(a = 0; a < gongs.size; a++)
    {
        if(gongs[a].right_gong)
            gongs[a] notify("triggered", self);
    }

    wait 0.1;
    pans = GetEntArray("zhdsnd_pans", "targetname");

    for(a = 0; a < pans.size; a++) //Magic Bullet Has To Be The Starting Pistol
    {
        if(pans[a].script_int == 1) //Pan 1 Has To Get Shot Twice
        {
            for(b = 0; b < 2; b++)
            {
                MagicBullet(level.start_weapon, pans[a].origin + (-5, 0, 0), pans[a].origin, self);
                wait 0.05;
            }
        }
        else if(pans[a].script_int == 5) //Pan 5 Has To Get Shot Once
        {
            MagicBullet(level.start_weapon, pans[a].origin + (-5, 0, 0), pans[a].origin, self);
        }

        wait 0.05;
    }

    wait 3;
    self SamanthasHideAndSeekSong();
}

function TempleAllowFullEE()
{
    level.TempleAllowFullEE = BoolVar(level.TempleAllowFullEE);

    while(Is_True(level.TempleAllowFullEE))
    {
        playerCount = level.players.size;

        if(level._sundial_buttons_pressed == playerCount)
            level._sundial_buttons_pressed = 4;

        if(playerCount == 1 && IsDefined(level.var_66c77de0))
            level.var_d8ceed1b = level.var_66c77de0;

        if(level.var_a775df2e >= (playerCount - 1) && !level flag::get("dgcwf_on_plate"))
            level flag::set("dgcwf_on_plate");

        if(level flag::get("dgcwf_on_plate") && level.var_a775df2e < (playerCount - 1))
            level flag::clear("dgcwf_on_plate");

        wait 0.01;
    }
}

// ============================================================
// Functions/MapScripts/Shino.gsc
// ============================================================

function PopulateShinoScripts(menu)
{
    switch(menu)
    {
        case "Shi No Numa Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("snd_zhdegg_completed"), "Samantha's Hide & Seek", &ShinoHideAndSeek);
                self addOptBool(level.ShinoTheOneSong, "The One Song", &ShinoTheOneSong);
            break;
    }
}

function ShinoHideAndSeek()
{
    if(level flag::get("snd_zhdegg_completed"))
        return self iPrintlnBold("^1ERROR: ^7Samantha's Hide & Seek Has Already Been Completed");

    if(Is_True(level.StartedSamanthaSong))
        return self iPrintlnBold("^1ERROR: ^7Samantha's Hide & Seek Has Already Been Started");

    level.StartedSamanthaSong = true;

    curs = self getCursor();
    menu = self getCurrent();

    plates = GetEntArray("sndzhd_plates", "targetname");

    for(a = 0; a < plates.size; a++)
    {
        MagicBullet(level.start_weapon, plates[a].origin + (AnglesToForward(plates[a].angles) * 2), plates[a].origin, self);
        wait 0.05;
    }

    wait 3;
    self SamanthasHideAndSeekSong();
}

function ShinoTheOneSong()
{
    if(Is_True(level.ShinoTheOneSong))
        return self iPrintlnBold("^1ERROR: ^7The One Song Has Already Been Activated");

    level.ShinoTheOneSong = true;
    trigger = struct::get("s_phone_egg", "targetname");

    for(a = 0; a < 4; a++)
    {
        trigger notify("trigger_activated");
        wait (!a ? 1 : 0.25);
    }
}

// ============================================================
// Functions/MapScripts/TheGiant.gsc
// ============================================================

function PopulateTheGiantScripts(menu)
{
    switch(menu)
    {
        case "The Giant Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
                self addOpt("Link Teleporters", &newMenu, "The Giant Teleporters");
                self addOptBool(level flag::get("snow_ee_completed"), "Complete Sixth Perk", &GiantCompleteSixthPerk);
                self addOptBool((IsDefined(level.HideAndSeekInit) || level flag::get("hide_and_seek")), "Start Hide & Seek", &InitializeGiantHideAndSeek);
                self addOptBool((IsDefined(level.GiantHideAndSeekCompleted) || level flag::get("hide_and_seek") && !level flag::get("flytrap")), "Complete Hide & Seek", &GiantCompleteHideAndSeek);
            break;

        case "The Giant Teleporters":
            self addMenu("Link Teleporters");
                self addOptBool((level.active_links == 3), "Link All", &GiantLinkAllTeleporters);

                for(a = 0; a < 3; a++)
                    self addOptBool((level.teleport[a] == "active"), "Teleporter " + (a + 1), &GiantLinkTeleporterToMainframe, a);
            break;
    }
}

function GiantLinkAllTeleporters()
{
    curs = self getCursor();
    menu = self getCurrent();

    if(!level flag::get("power_on"))
        return self iPrintlnBold("^1ERROR: ^7Power Needs To Be Activated First");

    for(a = 0; a < 3; a++)
        GiantLinkTeleporterToMainframe(a);

    if(level.active_links < 3)
        while(level.active_links < 3)
            wait 0.05;

    self RefreshMenu(menu, curs);
}

function GiantLinkTeleporterToMainframe(index)
{
    if(!level flag::get("power_on"))
        return self iPrintlnBold("^1ERROR: ^7Power Needs To Be Activated First");

    if(level.teleport[index] == "active")
        return;

    if(level.teleport[index] == "waiting")
    {
        trigger = level.teleporter_pad_trig[index];
        trigger notify("trigger");

        wait 0.075;
    }

    trigger_core = GetEnt("trigger_teleport_core", "targetname");
    trigger_core notify("trigger");
}

function GiantCompleteSixthPerk()
{
    if(level flag::get("snow_ee_completed"))
        return self iPrintlnBold("^1ERROR: ^7Sixth Perk Already Completed");

    curs = self getCursor();
    menu = self getCurrent();

    if(!level flag::get("power_on"))
        ActivatePower();

    wait 0.1;

    if(level.active_links < 3)
        GiantLinkAllTeleporters();

    wait 0.1;
    flags = Array("one", "two", "three");
    consoles = Array("blue", "green", "red");

    for(a = 0; a < flags.size; a++)
    {
        if(!level flag::get("console_" + flags[a] + "_completed"))
        {
            level flag::set("console_" + flags[a] + "_completed");
            level clientfield::set("console_" + consoles[a], 1);
        }
    }

    wait 0.1;
    TriggerUniTrigger(struct::get("snowpile_console"), "trigger_activated");
    level flag::wait_till("snow_ee_completed");

    self RefreshMenu(menu, curs);
}

function InitializeGiantHideAndSeek()
{
    if(level flag::get("hide_and_seek") || Is_True(level.HideAndSeekInit))
        return self iPrintlnBold("^1ERROR: ^7Hide & Seek Already Started");

    level.HideAndSeekInit = true;

    curs = self getCursor();
    menu = self getCurrent();

    trig_control_panel = GetEnt("trig_ee_flytrap", "targetname");
    MagicBullet(GetWeapon("ray_gun_upgraded"), trig_control_panel.origin - (5, 5, 5), trig_control_panel.origin, self, trig_control_panel);

    level flag::wait_till("hide_and_seek");
    self RefreshMenu(menu, curs);
}

function GiantCompleteHideAndSeek()
{
    if(Is_True(level.GiantHideAndSeekCompleted))
        return self iPrintlnBold("^1ERROR: ^7Hide & Seek Already Completed");

    curs = self getCursor();
    menu = self getCurrent();

    if(!level flag::get("hide_and_seek") && !Is_True(level.HideAndSeekInit))
    {
        InitializeGiantHideAndSeek();
        wait 0.1;
    }

    if(!level flag::get("hide_and_seek"))
        level flag::wait_till("hide_and_seek");

    ents = Array("ee_exp_monkey", "ee_bowie_bear", "ee_perk_bear");

    for(a = 0; a < ents.size; a++)
    {
        if(!level flag::get(ents[a]))
        {
            trig = GetEnt("trig_" + ents[a], "targetname");

            if(IsDefined(trig))
                trig notify("trigger");

            wait 0.15;
        }
    }

    level.GiantHideAndSeekCompleted = true;
    self RefreshMenu(menu, curs);
}

// ============================================================
// Functions/MapScripts/Tunnel.gsc
// ============================================================

function PopulateTunnelScripts(menu)
{
    switch(menu)
    {
        case "Tunnel Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
            break;
    }
}

// ============================================================
// Functions/MapScripts/Verruckt.gsc
// ============================================================

function PopulateVerrucktScripts(menu)
{
    switch(menu)
    {
        case "Verruckt Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ActivatePower);
                self addOptBool(level flag::get("snd_zhdegg_completed"), "Samantha's Hide & Seek", &VerrucktHideAndSeekSong);
                self addOptBool(level.VerrucktLullaby, "Lullaby For A Dead Man Song", &VerrucktLullabyForADeadMan);
            break;
    }
}

function VerrucktHideAndSeekSong()
{
    if(level flag::get("snd_zhdegg_completed"))
        return self iPrintlnBold("^1ERROR: ^7Samantha's Hide & Seek Has Already Been Completed");

    if(Is_True(level.StartedSamanthaSong))
        return self iPrintlnBold("^1ERROR: ^7Samantha's Hide & Seek Has Already Been Started");

    level.StartedSamanthaSong = true;

    curs = self getCursor();
    menu = self getCurrent();

    toilets = struct::get_array("s_toilet_zhd", "targetname");

    foreach(index, toilet in toilets)
    {
        for(a = 0; a < toilet.script_int; a++)
        {
            toilet notify("trigger_activated");
            wait 0.1;
        }

        wait 0.5;
    }

    wait 3;
    self SamanthasHideAndSeekSong();
}

function VerrucktLullabyForADeadMan()
{
    if(Is_True(level.VerrucktLullaby))
        return self iPrintlnBold("^1ERROR: ^7Lullaby For A Dead Man Already Activated");

    level.VerrucktLullaby = true;
    trigger = struct::get("snd_flusher", "targetname");

    for(a = 0; a < 3; a++)
    {
        trigger notify("trigger_activated");
        wait 3.8;
    }
}

// ============================================================
// Functions/MapScripts/ZetsubouNoShima.gsc
// ============================================================

function PopulateZetsubouNoShimaScripts(menu)
{
    switch(menu)
    {
        case "Zetsubou No Shima Scripts":
            self addMenu(menu);
                self addOptBool(level flag::get("power_on"), "Turn On Power", &ZNS_ActivatePower);
                self addOptBool(self clientfield::get_to_player("bucket_held"), "Collect Bucket", &ZNSGrabWaterBucket);
                self addOpt("Bucket Water", &newMenu, "ZNS Bucket Water");
                
                if(!level flag::get("valve1_found") || !level flag::get("valve2_found") || !level flag::get("valve3_found"))
                    self addOpt("Pack 'a' Punch Parts", &newMenu, "Pack 'a' Punch Parts");

                if(!level flag::get("ww1_found") && !level flag::get("ww2_found") && !level flag::get("ww3_found"))
                    self addOpt("KT-4 Parts", &newMenu, "KT-4 Parts");
                
                if(!level flag::get("wwup1_found") || !level flag::get("wwup3_found"))
                    self addOpt("KT-4 Upgrade Parts", &newMenu, "KT-4 Upgrade Parts");
                
                self addOpt("Skulltar Teleports", &newMenu, "Skulltar Teleports");
                self addOpt("Challenges", &newMenu, "Map Challenges");
                self addOptBool((level flag::exists("trilogy_released") && level flag::get("trilogy_released")), "Mesmerize Map", &MesmerizeMap);
                self addOptBool((level flag::exists("player_has_aa_gun_ammo") && level flag::get("player_has_aa_gun_ammo")), "Flak Gun Bullet", &ZNSFlakBullet);
                self addOptBool(self HasWeapon(level.w_controllable_spider), "Controllable Spider", &GiveControllableSpider);
            break;
        
        case "KT-4 Parts":
            self addMenu(menu);

                if(!level flag::get("ww1_found"))
                    self addOpt("Vial", &CollectKT4Parts, "ww1_found");
                
                if(!level flag::get("ww2_found"))
                    self addOpt("Plant", &CollectKT4Parts, "ww2_found");
                
                if(!level flag::get("ww3_found"))
                    self addOpt("Venom", &CollectKT4Parts, "ww3_found");
            break;
        
        case "KT-4 Upgrade Parts":
            self addMenu(menu);

                if(!level flag::get("wwup1_found"))
                    self addOpt("Vial", &CollectKT4UpgradeParts, "wwup1_found");
                
                //Step is fast and easy...so I'm not making a script for it
                //if(!level flag::get("wwup2_found"))
                    //self addOpt("Spider Fang", ::CollectKT4UpgradeParts, "wwup2_found");
                
                if(!level flag::get("wwup3_found"))
                    self addOpt("Plant", &CollectKT4UpgradeParts, "wwup3_found");
            break;
        
        case "ZNS Bucket Water":
            self addMenu("Bucket Water");

                sources = GetEntArray("water_source", "targetname");

                if(IsDefined(sources) && sources.size)
                {
                    foreach(source in sources)
                    {
                        if(IsDefined(source))
                            self addOptBool((IsDefined(self.var_c6cad973) && self.var_c6cad973 == source.script_int), ZNSReturnWaterType(source.script_int), &ZNSFillBucket, source);
                    }
                }

                rainbowEnt = GetEnt("water_source_ee", "targetname");

                if(IsDefined(rainbowEnt))
                    self addOptBool((IsDefined(self.var_c6cad973) && self.var_c6cad973 == rainbowEnt.script_int), "Rainbow", &ZNSFillBucket, rainbowEnt);
            break;
        
        case "Pack 'a' Punch Parts":
            self addMenu(menu);

                if(!level flag::get("valve1_found"))
                    self addOptBool(level flag::get("valve1_found"), "Gauge", &ZNS_PaPQuest, 1);
                
                if(!level flag::get("valve2_found"))
                    self addOptBool(level flag::get("valve2_found"), "Wheel", &ZNS_PaPQuest, 2);
                
                if(!level flag::get("valve3_found"))
                    self addOptBool(level flag::get("valve3_found"), "Whistle", &ZNS_PaPQuest, 3);
            break;
        
        case "Skulltar Teleports":
            skulltars = GetEntArray("mdl_skulltar", "targetname");

            self addMenu(menu);
                self addOpt("Podium", &TeleportPlayer, (2439.987, -1223.967, -375.875), self);

                for(a = 0; a < skulltars.size; a++)
                    self addOpt("Skulltar " + (a + 1), &TeleportPlayer, skulltars[a].origin, self);
            break;
    }
}

function CollectKT4Parts(part)
{
    if(level flag::get(part))
        return;

    self endon("disconnect");

    curs = self getCursor();
    menu = self getCurrent();

    switch(part)
    {
        case "ww1_found":
            if(Is_True(level.find_ww1))
                return self iPrintlnBold("^1ERROR: ^7Part Is Currently Being Collected");

            level.find_ww1 = true;

            //Part that is usually collected from a zombie
            if(!level flag::get("ww1_found"))
            {
                level.var_622692a9++;
                self notify("player_got_ww_part");
                level flag::set("ww1_found");

                foreach(player in level.players)
                {
                    player clientfield::set_to_player("wonderweapon_part_wwi", 1);
                    player thread zm_craftables::player_show_craftable_parts_ui("zmInventory.wonderweapon_part_wwi", "zmInventory.widget_wonderweapon_parts", 0);
                }

                wait 0.1;
            }

            if(Is_True(level.find_ww1))
                level.find_ww1 = BoolVar(level.find_ww1);
            break;

        case "ww2_found":
            if(Is_True(level.find_ww2))
                return self iPrintlnBold("^1ERROR: ^7Part Is Currently Being Collected");

            level.find_ww2 = true;

            //Part that is found in the underwater cave
            if(!level flag::get("ww2_found"))
            {
                part = struct::get("ww_part_underwater", "script_noteworthy");

                foreach(stub in level._unitriggers.dynamic_stubs)
                {
                    if(stub.origin == part.origin)
                    {
                        partTrigger = stub;
                        break;
                    }
                }

                if(IsDefined(partTrigger))
                    partTrigger notify("trigger", self);

                wait 0.1;
            }

            if(Is_True(level.find_ww2))
                level.find_ww2 = BoolVar(level.find_ww2);
            break;

        case "ww3_found":
            if(Is_True(level.find_ww3))
                return self iPrintlnBold("^1ERROR: ^7Part Is Currently Being Collected");

            level.find_ww3 = true;

            //Part that is extracted from a spider
            if(!level flag::get("ww3_found"))
            {
                level.var_622692a9++;
                self notify("player_got_ww_part");
                level flag::set("ww3_found");

                extractor = GetEnt("venom_extractor", "targetname");
                extractor scene::play("p7_fxanim_zm_island_venom_extractor_end_bundle", extractor);
                extractor SetModel("p7_fxanim_zm_island_venom_extractor_red_mod");
                extractor scene::init("p7_fxanim_zm_island_venom_extractor_red_bundle", extractor);

                foreach(player in level.players)
                {
                    player clientfield::set_to_player("wonderweapon_part_wwiii", 1);
                    player thread zm_craftables::player_show_craftable_parts_ui("zmInventory.wonderweapon_part_wwiii", "zmInventory.widget_wonderweapon_parts", 0);
                }
            }

            if(Is_True(level.find_ww3))
                level.find_ww3 = BoolVar(level.find_ww3);
            break;

        default:
            break;
    }

    self RefreshMenu(menu, curs);
}

function CollectKT4UpgradeParts(part)
{
    if(level flag::get(part))
        return;
    
    if(!level flag::get("ww_obtained"))
        return self iPrintlnBold("^1ERROR: ^7You Need To Build The KT-4 First");

    self endon("disconnect");

    curs = self getCursor();
    menu = self getCurrent();

    switch(part)
    {
        case "wwup1_found":
            if(Is_True(level.find_wwup1))
                return self iPrintlnBold("^1ERROR: ^7Part Is Currently Being Collected");
            
            level.find_wwup1 = true;
            
            partStruct = struct::get("wweapon_up_part_wwup1");

            if(IsDefined(partStruct) && !level flag::get(part))
            {
                ents = GetEntArray("script_model", "classname");

                foreach(ent in ents)
                {
                    if(!IsDefined(ent) || ent.origin != partStruct.origin)
                        continue;
                    
                    vial = ent;
                }

                if(IsDefined(vial))
                {
                    if(IsDefined(vial.trigger))
                        vial.trigger notify("trigger", self);
                }
            }

            if(Is_True(level.find_wwup1))
                level.find_wwup1 = BoolVar(level.find_wwup1);
            break;
        
        case "wwup2_found":
            //Step is fast and easy...so I'm not making a script for it
            break;
        
        case "wwup3_found":
            if(Is_True(level.find_wwup3))
                return self iPrintlnBold("^1ERROR: ^7Part Is Currently Being Collected");
            
            level.find_wwup3 = true;

            partStruct = struct::get("ee_planting_spot", "script_noteworthy");
            level flag::set("ww_upgrade_spawned_from_plant");
            wait 0.5;

            if(IsDefined(partStruct) && !level flag::get(part))
            {
                ents = GetEntArray("script_model", "classname");

                foreach(ent in ents)
                {
                    if(!IsDefined(ent) || ent.origin != partStruct.origin)
                        continue;
                    
                    plant = ent;
                }

                if(IsDefined(plant))
                {
                    if(IsDefined(plant.trigger))
                        plant.trigger notify("trigger", self);
                }
            }

            if(Is_True(level.find_wwup3))
                level.find_wwup3 = BoolVar(level.find_wwup3);
            break;
        
        default:
            break;
    }

    wait 0.5;
    self RefreshMenu(menu, curs);
}

function MesmerizeMap()
{
    if(level flag::exists("trilogy_released") && level flag::get("trilogy_released"))
        return;
    
    map = GetEnt("mdl_main_ee_map", "targetname");

    foreach(player in level.players)
    {
        if(map == player.var_abd1c759)
        {
            player.var_abd1c759 = undefined;
            player notify("someone_revealed_" + map.targetname);
        }
    }

    map.var_f0b65c0a = self;
    PlaySoundAtPosition("zmb_wpn_skullgun_discover", map.origin);
    self notify("skullweapon_revealed_location");

    map clientfield::set("do_fade_material", 1);
	level flag::set("trilogy_released");
	exploder::exploder("lgt_elevator");
}

function ZNSFlakBullet()
{
    if(level flag::exists("player_has_aa_gun_ammo") && level flag::get("player_has_aa_gun_ammo"))
        return;
    
    level flag::set("player_has_aa_gun_ammo");
}

function ZNSGrabWaterBucket()
{
    if(self clientfield::get_to_player("bucket_held"))
        return;

    var_c66f413a = struct::get_array("water_bucket_location", "targetname");
    var_c66f413a = array::randomize(var_c66f413a);

    foreach(bucket in var_c66f413a)
    {
        if(IsDefined(bucket) && IsDefined(bucket.trigger))
        {
            bucket.trigger notify("trigger", self);
            break;
        }
    }
}

function ZNSFillBucket(source)
{
    if(!self clientfield::get_to_player("bucket_held"))
        return self iPrintlnBold("^1ERROR: ^7You Need To Collect A Bucket First");

    water_type = source.script_int;

    if(self.var_c6cad973 == water_type)
        return;

    self.var_bb2fd41c = 3;
    self PlaySound("zmb_bucket_water_pickup");
    self.var_c6cad973 = water_type;
    self thread function_ef097ea(self.var_c6cad973, self.var_bb2fd41c, self function_89538fbb(), 1);

    if(self.var_bb2fd41c <= 0)
    {
        self.var_bb2fd41c = 0;
        self.var_c6cad973 = 0;
    }

    self thread function_ef097ea(self.var_c6cad973, self.var_bb2fd41c, self function_89538fbb(), 1);
}

function function_ef097ea(var_c6cad973 = 0, var_44bdb80e = 0, var_3f242b55 = 0, var_b89973c8 = 0)
{
    self thread function_3945e60c(var_c6cad973, var_44bdb80e, var_3f242b55, var_b89973c8);
    self thread function_16ae5bf5();
    self thread function_53f26a4c();
}

function function_89538fbb()
{
    if(IsDefined(self.var_6fd3d65c) && self.var_6fd3d65c && (IsDefined(self.var_b6a244f9) && self.var_b6a244f9))
        return 2;

    if(IsDefined(self.var_6fd3d65c) && self.var_6fd3d65c && (!(IsDefined(self.var_b6a244f9) && self.var_b6a244f9)))
        return 1;

    return 0;
}

function function_3945e60c(var_c6cad973, var_44bdb80e, var_3f242b55, var_b89973c8)
{
    self clientfield::set_to_player("bucket_held", var_3f242b55);
    self clientfield::set_to_player("bucket_bucket_type", var_3f242b55);

    if(var_c6cad973 > 0)
        self clientfield::set_to_player("bucket_bucket_water_type", (var_c6cad973 - 1));

    self clientfield::set_to_player("bucket_bucket_water_level", var_44bdb80e);

    if(var_b89973c8)
        self thread zm_craftables::player_show_craftable_parts_ui(undefined, "zmInventory.widget_bucket_parts", 0);
}

function function_16ae5bf5()
{
    if(!self clientfield::get_to_player("bucket_held"))
    {
        foreach(var_b2b5bcc5, var_7e208829 in level.var_4a0060c0)
            var_7e208829 SetInvisibleToPlayer(self);

        return;
    }

    foreach(var_82a1e97d, var_7e208829 in level.var_4a0060c0)
    {
        if(self.var_bb2fd41c == 3 && self.var_c6cad973 == var_7e208829.script_int)
        {
            var_7e208829 SetInvisibleToPlayer(self);
            continue;
        }

        var_7e208829 SetVisibleToPlayer(self);
    }
}

function function_53f26a4c()
{
    if(!IsDefined(self.var_bb2fd41c))
        return;

    if(self.var_bb2fd41c == 3)
    {
        foreach(var_537f5e5a, var_5972e249 in level.var_769c0729)
        {
            if(IsDefined(var_5972e249))
                var_5972e249 SetHintStringForPlayer(self, &"ZOMBIE_ELECTRIC_SWITCH");
        }
    }
    else if(self.var_bb2fd41c > 0)
    {
        foreach(var_3b4a0f61, var_5972e249 in level.var_769c0729)
        {
            if(IsDefined(var_5972e249))
                var_5972e249 SetHintStringForPlayer(self, &"ZM_ISLAND_POWER_SWITCH_NEEEDS_MORE_WATER");
        }
    }
    else
    {
        foreach(var_b9e1758c, var_5972e249 in level.var_769c0729)
        {
            if(IsDefined(var_5972e249))
                var_5972e249 SetHintStringForPlayer(self, &"ZM_ISLAND_POWER_SWITCH_NEEEDS_WATER");
        }
    }
}

function ZNSReturnWaterType(sourceint)
{
    switch(sourceint)
    {
        case 1:
            return "Blue";

        case 2:
            return "Green";

        case 3:
            return "Purple";

        default:
            return "Unknown";
    }
}












//Controllable Spider
//Luckily the rest of the Controllable Spider logic is handled in the _zm_weap_controllable_spider.gsc scripts. So these are the only scripts that needed to be ripped from the files.
function GiveControllableSpider()
{
    w_weapon = GetWeapon("controllable_spider");

    if(!self HasWeapon(w_weapon))
    {
        self thread zm_placeable_mine::setup_for_player(w_weapon, "hudItems.showDpadRight_Spider");
        self GiveMaxAmmo(w_weapon);

        if(!level flag::get("controllable_spider_equipped"))
        {
            level flag::set("controllable_spider_equipped");
            level.zone_occupied_func = &zone_occupied_func;

            level.closest_player_targets_override = &closest_player_targets_override;
            level.get_closest_valid_player_override = &closest_player_targets_override;
        }
    }
}

function closest_player_targets_override()
{
    a_targets = GetPlayers();

    for(a = 0; a < a_targets.size; a++)
    {
        if(IsDefined(a_targets[a].var_59bd3c5a))
            a_targets[a] = a_targets[a].var_59bd3c5a;
    }

    return a_targets;
}

function zone_occupied_func(zone_name)
{
    if(!zm_zonemgr::zone_is_enabled(zone_name))
        return false;

    zone = level.zones[zone_name];

    for(i = 0; i < zone.volumes.size; i++)
    {
        players = GetPlayers();

        for(j = 0; j < players.size; j++)
        {
            if(IsDefined(players[j].var_59bd3c5a))
            {
                if(players[j].var_59bd3c5a IsTouching(zone.volumes[i]) && (IsDefined(players[j].var_59bd3c5a.sessionstate) && players[j].var_59bd3c5a.sessionstate != "spectator" || !IsDefined(players[j].var_59bd3c5a.sessionstate)))
                    return true;

                continue;
            }

            if(players[j] IsTouching(zone.volumes[i]) && (IsDefined(players[j].sessionstate) && players[j].sessionstate != "spectator" || !IsDefined(players[j].sessionstate)))
                return true;
        }
    }

    return false;
}

function ZNS_ActivatePower()
{
    if(Is_True(level.ActivatingPower))
        return self iPrintlnBold("^1ERROR: ^7Power Is Already Being Turned On");
    
    if(level flag::get("power_on"))
        return self iPrintlnBold("^1ERROR: Power Is Already Turned On");
    
    menu = self getCurrent();
    curs = self getCursor();
    level.ActivatingPower = true;
    
    if(!self clientfield::get_to_player("bucket_held"))
    {
        self ZNSGrabWaterBucket();
        wait 1;
    }

    foreach(source in GetEntArray("water_source", "targetname"))
    {
        if(source.script_int == 1)
            waterSource = source;
    }
    
    trigs = GetEntArray("use_elec_switch", "targetname");

    foreach(trig in trigs)
    {
        if(level flag::get("power_on" + trig.script_int))
            continue;
        
        self ZNSFillBucket(waterSource);
        wait 1;

        trig notify("trigger", self);
        wait 1;
    }

    wait 3;
    web_trigger = GetEnt("penstock_web_trigger", "targetname");

    if(IsDefined(web_trigger))
        web_trigger notify("web_torn");
    
    level flag::wait_till("defend_over");
    power_switch = GetEnt("use_elec_switch_deferred", "targetname");
    power_switch notify("trigger", self);

    while(!level flag::get("power_on"))
        wait 0.1;

    self RefreshMenu(menu, curs);
    level.ActivatingPower = BoolVar(level.ActivatingPower);
}

function ZNS_PaPQuest(step)
{
    if(!level flag::get("power_on"))
        return self iPrintlnBold("^1ERROR: ^7Power Must Be Turned On First");
    
    if(level flag::get("valve" + step + "_found"))
        return self iPrintlnBold("^1ERROR: ^7This Part Has Already Been Collected");
    
    menu = self getCurrent();
    curs = self getCursor();
    
    switch(step)
    {
        case 1:
            if(Is_True(level.find_valve1))
                return self iPrintlnBold("^1ERROR: ^7This Part Is Already Being Collected");
            
            level.find_valve1 = true;

            foreach(cocoon in GetEntArray("cocoon_bunker", "targetname"))
            {
                if(!IsDefined(cocoon) || Is_True(cocoon.is_open))
                    continue;
                
                cocoon notify("damage", cocoon.health + 99, self, (0, 0, 0), (0, 0, 0), "MOD_MELEE");
            }
            
            wait 1;
            self ZNS_TriggerPaPPieceModel("p7_zm_isl_pap_elements_gauge");
            level.find_valve1 = BoolVar(level.find_valve1);
            break;
        
        case 2:
            if(!level flag::get("connect_bunker_exterior_to_bunker_interior"))
                return self iPrintlnBold("^1ERROR: ^7Bunker Door Needs To Be Opened First");
            
            if(Is_True(level.find_valve2))
                return self iPrintlnBold("^1ERROR: ^7This Part Is Already Being Collected");
            
            level.find_valve2 = true;
            
            self ZNS_TriggerPaPPieceModel("p7_zm_isl_pap_elements_wheel");
            level.find_valve2 = BoolVar(level.find_valve2);
            break;
        
        case 3:
            if(Is_True(level.find_valve3))
                return self iPrintlnBold("^1ERROR: ^7This Part Is Already Being Collected");
            
            level.find_valve3 = true;
            
            self ZNS_TriggerPaPPieceModel("p7_zm_isl_pap_elements_whistle");
            level.find_valve3 = BoolVar(level.find_valve3);
            break;
        
        default:
            break;
    }

    while(!level flag::get("valve" + step + "_found"))
        wait 0.1;
    
    self RefreshMenu(menu, curs);
}

function ZNS_TriggerPaPPieceModel(model)
{
    foreach(script_model in GetEntArray("script_model", "classname"))
    {
        if(!IsDefined(script_model) || script_model.model != model)
            continue;
        
        script_model.trigger notify("trigger", self);
    }
}

// ============================================================
// Functions/message.gsc
// ============================================================

function PopulateMessageMenu(menu)
{
    switch(menu)
    {
        case "Message Menu":
            self addMenu(menu);
                self addOptSlider("Display Type", &MessageDisplay, Array("Notify", "Print Bold"));
                self addOpt("Custom Message", &Keyboard, &DisplayMessage);
                self addOpt("Miscellaneous", &newMenu, "Miscellaneous Messages");
                self addOpt("Advertisements", &newMenu, "Advertisements Messages");
            break;
        
        case "Miscellaneous Messages":
            self addMenu("Miscellaneous");
                self addOpt("Want Menu?", &DisplayMessage, "Want Menu?");
                self addOpt("Who's Modding?", &DisplayMessage, "Who's Modding?");
                self addOpt(CleanName(self getName()), &DisplayMessage, CleanName(self getName()) + " <3");
                self addOpt("Deranked", &DisplayMessage, "You've Been ^1Deranked");
                self addOpt("^BBUTTON_ZM_VIAL_ICON^", &DisplayMessage, "^BBUTTON_ZM_VIAL_ICON^ ^BBUTTON_ZM_VIAL_ICON^ ^BBUTTON_ZM_VIAL_ICON^");
                self addOpt("Host", &DisplayMessage, "Your Host Today Is " + CleanName(bot::get_host_player() getName()));
            break;
        
        case "Advertisements Messages":
            self addMenu("Advertisements");
                self addOpt("Welcome", &DisplayMessage, "Welcome To " + GetMenuName());
                self addOpt("Discord Server", &DisplayMessage, "Discord Server: discord.gg/apparitionbo3");
                self addOpt(GetMenuName(), &DisplayMessage, GetMenuName() + " Is The Biggest & Best Menu For BO3 Zombies");
                self addOpt("Developer", &DisplayMessage, GetMenuName() + " Was Developed By CF4_99");
                self addOpt("YouTube", &DisplayMessage, "YouTube: CF4_99");
            break;
    }
}

function MessageDisplay(type)
{
    self.MessageDisplay = type;
}

function DisplayMessage(message)
{
    if(!IsDefined(self.MessageDisplay))
        self.MessageDisplay = "Notify";
    
    switch(self.MessageDisplay)
    {
        case "Notify":
            thread typeWriter(message);
            break;
        
        case "Print Bold":
            iPrintlnBold(message);
            break;
        
        default:
            break;
    }
}

function typeWriter(message)
{
    if(!IsDefined(level.LobbyMessageQueue))
        level.LobbyMessageQueue = [];

    level.LobbyMessageQueue[level.LobbyMessageQueue.size] = message;

    if(Is_True(level.LobbyTypeWriterCreating) || IsDefined(level.LobbyTypeWriterMessage))
        return;

    level.LobbyTypeWriterCreating = true;

    while(level.LobbyMessageQueue.size)
    {
        next = level.LobbyMessageQueue[0];
        newQueue = [];

        for(a = 1; a < level.LobbyMessageQueue.size; a++)
            newQueue[newQueue.size] = level.LobbyMessageQueue[a];
        
        level.LobbyMessageQueue = newQueue;

        level.LobbyTypeWriterMessage = level createServerText("objective", 2, 1, "", "TOP", 320, 75, 1, level.RGBFadeColor);
        level.LobbyTypeWriterMessage thread SetTextFX(next, 4);
        level.LobbyTypeWriterMessage thread HudRGBFade();

        while(IsDefined(level.LobbyTypeWriterMessage))
            wait 0.1;
    }

    level.LobbyTypeWriterCreating = undefined;
}

// ============================================================
// Functions/model_manipulation.gsc
// ============================================================

function PopulateModelManipulation(menu, player)
{
    switch(menu)
    {
        case "Model Manipulation":            
            self addMenu(menu);
                self addOptBool(player.ThirdPerson, "Third Person", &ThirdPerson, player);
                self addOpt("Reset", &ResetPlayerModel, player);
                self addOpt("");

                if(IsDefined(level.menu_models) && level.menu_models.size)
                {
                    for(a = 0; a < level.menu_models.size; a++)
                        self addOpt(CleanString(level.menu_models[a]), &SetPlayerModel, level.menu_models[a], player);
                }
            break;
    }
}

function ResetPlayerModel(player)
{
    if(Is_True(player.ModelManipulation))
        player.ModelManipulation = BoolVar(player.ModelManipulation);

    if(IsDefined(player.spawnedPlayerModel))
        player.spawnedPlayerModel Delete();
    
    if(!Is_True(player.Invisibility))
        player Show();
}

function SetPlayerModel(model, player)
{
    player endon("disconnect");
    player notify("StopSetPlayerModel");
    player endon("StopSetPlayerModel");

    if(IsDefined(player.spawnedPlayerModel))
        player.spawnedPlayerModel Delete();

    wait 0.05;

    player.ModelManipulation = true;
    player.spawnedPlayerModel = Spawn("script_model", player.origin);
    player.spawnedPlayerModel.angles = player.angles;
    player.spawnedPlayerModel SetModel(model);
    player.spawnedPlayerModel NotSolid();

    while(Is_True(player.ModelManipulation) && Is_Alive(player))
    {
        player Hide();

        if(IsDefined(player.spawnedPlayerModel))
        {
            player.spawnedPlayerModel MoveTo(player.origin, 0.1);
            player.spawnedPlayerModel RotateTo(player.angles, 0.1);
        }

        wait 0.1;
    }

    if(Is_True(player.ModelManipulation))
        player ResetPlayerModel(player);
}

// ============================================================
// Functions/player.gsc
// ============================================================

function PopulatePlayerOptions(menu, player)
{
    switch(menu)
    {
        case "Options":
            submenus = Array("Verification", "Basic Scripts", "Teleport Menu", "Weaponry", "Bullet Menu", "Fun Scripts", "Model Manipulation", "Aimbot Menu", "Model Attachment", "Malicious Options");
            
            self addMenu("[^2" + player.accessLevel + "^7]" + CleanName(player getName()));

                for(a = 0; a < submenus.size; a++)
                    self addOpt(submenus[a], &newMenu, submenus[a]);

                self addOpt("Send Message", &Keyboard, &MessagePlayer, player);
                self addOptBool(player.FreezePlayer, "Freeze", &FreezePlayer, player);
                self addOpt("Kick", &KickPlayer, player);
            break;
        
        case "Verification":
            self addMenu(menu);
                self addOpt("Save Verification", &SavePlayerVerification, player);

                for(a = 1; a < (GetAccessLevels().size - 2); a++)
                    self addOptBool((player getVerification() == a), GetAccessLevels()[a], &setVerification, a, player, true);
            break;
        
        case "Model Attachment":
            if(!IsDefined(self.playerAttachBone))
                self.playerAttachBone = "j_head";

            self addMenu(menu);
                
                if(IsDefined(level.menu_models) && level.menu_models.size)
                {
                    self addOptSlider("Tag", &PlayerAttachmentBone, Array("j_head", "j_neck", "j_spine4", "j_spinelower", "j_mainroot", "pelvis", "j_ankle_ri", "j_ankle_le"));
                    self addOpt("Detach All", &PlayerDetachModels, player);
                    self addOpt("");

                    for(a = 0; a < level.menu_models.size; a++)
                    {
                        if(level.menu_models[a] != "defaultactor") //Attaching the defaultactor to a player can cause a crash.
                            self addOpt(CleanString(level.menu_models[a]), &PlayerModelAttachment, level.menu_models[a], player);
                    }
                }
            break;
        
        case "Malicious Options":
            if(!IsDefined(player.ShellShockTime))
                player.ShellShockTime = 1;
            
            self addMenu(menu);
                self addOpt("Open Pause Menu", &PlayerOpenPauseMenu, player);
                self addOpt("Disable Actions", &newMenu, "Disable Actions");
                self addOptSlider("Set Stance", &SetPlayerStance, Array("Prone", "Crouch", "Stand"), player);
                self addOptSlider("Loop Stance", &LoopStance, Array("Disable", "Prone", "Crouch", "Stand"), player);
                self addOpt("Launch", &LaunchPlayer, player);
                self addOpt("Mortar Strike", &MortarStrikePlayer, player);

                if(ReturnMapName() == "Shadows Of Evil" || ReturnMapName() == "Origins")
                    self addOptSlider("Jump Scare", &JumpScarePlayer, Array("Sound & Picture", "Sound Only"), player);
                
                self addOptBool(player.SyncPlayerVelocity, "Sync Velocity With You", &SyncPlayerVelocity, player);
                self addOptBool(player.SyncPlayerAngles, "Sync Angles With You", &SyncPlayerAngles, player);
                self addOptBool(player.AutoDown, "Auto-Down", &AutoDownPlayer, player);
                self addOptBool(player.FlashLoop, "Flash Loop", &FlashLoop, player);
                self addOptBool(player.SpinPlayer, "Spin Player", &SpinPlayer, player);
                self addOptBool(player.BlackScreen, "Black Screen", &BlackScreenPlayer, player);
                self addOptBool(player.FakeLag, "Fake Lag", &FakeLag, player);
                self addOptBool(self.AttachToPlayer, "Attach Self To Player", &AttachSelfToPlayer, player);
                self addOptSlider("Shellshock", &ApplyShellShock, Array("Concussion Grenade", "Zombie Death", "Explosion"), player);
                self addOptIncSlider("Shellshock Time", &SetShellShockTime, 1, 1, 30, 1, player);
                self addOptSlider("Show IP", &ShowPlayerIP, Array("Self", "Player"), player);
                self addOpt("Fake Derank", &FakeDerank, player);
                self addOpt("Fake Damage", &FakeDamagePlayer, player);
                self addOpt("Crash Game", &CrashPlayer, player);
            break;
        
        case "Disable Actions":
            self addMenu(menu);
                self addOptBool(player.DisableAiming, "Aiming", &DisableAiming, player);
                self addOptBool(player.DisableJumping, "Jumping", &DisableJumping, player);
                self addOptBool(player.DisableSprinting, "Sprinting", &DisableSprinting, player);
                self addOptBool(player.DisableWeaps, "Weapons", &DisableWeaps, player);
                self addOptBool(player.DisableOffhands, "Offhand Weapons", &DisableOffhands, player);
            break;
    }
}

//Miscellaneous Player Scripts
function MessagePlayer(msg, player)
{
    player iPrintlnBold("^2" + CleanName(self getName()) + ": ^7" + msg);
}

function FreezePlayer(player)
{
    player endon("disconnect");

    player.FreezePlayer = BoolVar(player.FreezePlayer);
    
    if(Is_True(player.FreezePlayer))
    {
        while(Is_True(player.FreezePlayer))
        {
            player FreezeControls(true);
            wait 0.1;
        }
    }
    else
    {
        player FreezeControls(false);
    }
}

function KickPlayer(player)
{
    if(player IsHost())
        return self iPrintlnBold("^1ERROR: ^7You Can't Kick The Host");
    
    if(player isDeveloper())
        return self iPrintlnBold("^1ERROR: ^7You Can't Kick The Developer");
    
    Kick(player GetEntityNumber(), "EXE_PLAYERKICKED_NOTSPAWNED");
}

//Model Attachment Functions
function PlayerAttachmentBone(tag)
{
    self.playerAttachBone = tag;
}

function PlayerModelAttachment(model, player)
{
    if(!IsDefined(player.ModelAttachment))
        player.ModelAttachment = [];

    player.ModelAttachment[player.ModelAttachment.size] = model + ";" + self.playerAttachBone;
    player Attach(model, self.playerAttachBone, true);
}

function PlayerDetachModels(player)
{
    if(!IsDefined(player.ModelAttachment) || IsDefined(player.ModelAttachment) && !player.ModelAttachment.size)
        return self iPrintlnBold("^1ERROR: ^7No Attached Models Found");
    
    for(a = 0; a < player.ModelAttachment.size; a++)
    {
        attach = StrTok(player.ModelAttachment[a], ";");
        player Detach(attach[0], attach[1]);
    }

    player.ModelAttachment = undefined;
}

//Malicious Player Functions
function PlayerOpenPauseMenu(player)
{
    player OpenMenu("StartMenu_Main");
}

function DisableAiming(player)
{
    player endon("disconnect");

    player.DisableAiming = BoolVar(player.DisableAiming);

    if(Is_True(player.DisableAiming))
    {
        while(Is_True(player.DisableAiming))
        {
            player AllowAds(false);
            wait 0.1;
        }
    }
    else
    {
        player AllowAds(true);
    }
}

function DisableJumping(player)
{
    player endon("disconnect");

    player.DisableJumping = BoolVar(player.DisableJumping);
    
    if(Is_True(player.DisableJumping))
    {
        while(Is_True(player.DisableJumping))
        {
            player AllowJump(false);
            wait 0.1;
        }
    }
    else
    {
        player AllowJump(true);
    }
}

function DisableSprinting(player)
{
    player endon("disconnect");

    player.DisableSprinting = BoolVar(player.DisableSprinting);
    
    if(Is_True(player.DisableSprinting))
    {
        while(Is_True(player.DisableSprinting))
        {
            player AllowSprint(false);
            wait 0.1;
        }
    }
    else
    {
        player AllowSprint(true);
    }
}

function DisableOffhands(player)
{
    player endon("disconnect");

    player.DisableOffhands = BoolVar(player.DisableOffhands);
    
    if(Is_True(player.DisableOffhands))
    {
        while(Is_True(player.DisableOffhands))
        {
            player DisableOffHandWeapons();
            wait 0.1;
        }
    }
    else
    {
        player EnableOffHandWeapons();
    }
}

function DisableWeaps(player)
{
    player endon("disconnect");

    player.DisableWeaps = BoolVar(player.DisableWeaps);
    
    if(Is_True(player.DisableWeaps))
    {
        while(Is_True(player.DisableWeaps))
        {
            player DisableWeapons();
            wait 0.1;
        }
    }
    else
    {
        player EnableWeapons();
    }
}

function SetPlayerStance(stance, player)
{
    player SetStance(ToLower(stance));
}

function LoopStance(stance = "Disable", player)
{
    player notify("EndLoopStance");
    player endon("EndLoopStance");
    player endon("disconnect");
    
    while(stance != "Disable")
    {
        player SetStance(ToLower(stance));
        wait 0.01;
    }
}

function LaunchPlayer(player)
{
    player SetOrigin(player.origin + (0, 0, 5));
    player SetVelocity(player GetVelocity() + (RandomIntRange(-500, 500), RandomIntRange(-500, 500), RandomIntRange(1500, 5000)));
}

function MortarStrikePlayer(player)
{
    player endon("disconnect");

    for(a = 0; a < 3; a++)
    {
        MagicBullet(GetWeapon("launcher_standard"), player.origin + (0, 0, 2500), player.origin);
        wait 0.15;
    }
}

function JumpScarePlayer(type, player)
{
    if(Is_True(player.JumpScarePlayer))
        return;
    player.JumpScarePlayer = true;

    player endon("disconnect");

    player PlaySoundToPlayer(((ReturnMapName() == "Shadows Of Evil") ? "zmb_zod_egg_scream" : "zmb_easteregg_scarydog"), player);

    if(type == "Sound & Picture") player.var_92fcfed8 = player OpenLUIMenu(((ReturnMapName() == "Shadows Of Evil") ? "JumpScare" : "JumpScare-Tomb"));

    wait 0.55;

    if(IsDefined(player.var_92fcfed8))
        player CloseLUIMenu(player.var_92fcfed8);
    
    player.JumpScarePlayer = BoolVar(player.JumpScarePlayer);
}

function SyncPlayerVelocity(player)
{
    if(player == self && !Is_True(player.SyncPlayerVelocity))
        return self iPrintlnBold("^1ERROR: ^7You Can't Sync Velocity With Yourself");
    
    self endon("disconnect");
    player endon("disconnect");

    player.SyncPlayerVelocity = BoolVar(player.SyncPlayerVelocity);

    while(Is_True(player.SyncPlayerVelocity))
    {
        player SetVelocity(self GetVelocity());
        wait 0.01;
    }
}

function SyncPlayerAngles(player)
{
    if(player == self && !Is_True(player.SyncPlayerAngles))
        return self iPrintlnBold("^1ERROR: ^7You Can't Sync Angles With Yourself");
    
    self endon("disconnect");
    player endon("disconnect");

    player.SyncPlayerAngles = BoolVar(player.SyncPlayerAngles);

    while(Is_True(player.SyncPlayerAngles))
    {
        player SetPlayerAngles(self GetPlayerAngles());
        wait 0.01;
    }
}

function AutoDownPlayer(player)
{
    if(player IsHost() || player isDeveloper())
        return;
    
    player endon("disconnect");

    player.AutoDown = BoolVar(player.AutoDown);
    
    while(Is_True(player.AutoDown))
    {
        if(Is_Alive(player) && !player IsDown())
        {
            if(Is_True(player.playerGodmode))
                player Godmode(player);

            if(Is_True(player.PlayerDemiGod))
                player DemiGod(player);
            
            player DisableInvulnerability(); //Just to ensure that the player is able to be damaged.
            player DoDamage(player.health + 999, (0, 0, 0));
        }

        wait 0.1;
    }
}

function FlashLoop(player)
{
    player endon("disconnect");

    player.FlashLoop = BoolVar(player.FlashLoop);
    
    if(Is_True(player.FlashLoop))
    {
        while(Is_True(player.FlashLoop))
        {
            player ShellShock("concussion_grenade_mp", 5);
            wait 5;
        }
    }
    else
    {
        player StopShellShock();
    }
}

function SpinPlayer(player)
{
    player endon("disconnect");

    player.SpinPlayer = BoolVar(player.SpinPlayer);
    
    while(Is_True(player.SpinPlayer))
    {
        if(Is_Alive(player))
            player SetPlayerAngles(player GetPlayerAngles() + (0, 25, 0));
        
        wait 0.01;
    }
}

function BlackScreenPlayer(player)
{
    player.BlackScreen = BoolVar(player.BlackScreen);

    if(Is_True(player.BlackScreen))
    {
        if(IsDefined(player.BlackScreenHud) && player.BlackScreenHud.size)
            destroyAll(player.BlackScreenHud);
        
        player.BlackScreenHud = [];

        for(a = 0; a < 2; a++)
        {
            index = player.BlackScreenHud.size;
            player.BlackScreenHud[index] = player createRectangle("CENTER", 320, 240, 1000, 1000, (0, 0, 0), 0, 1, "black");
            player.BlackScreenHud[index].horzalign = "fullscreen";
        }
    }
    else
    {
        destroyAll(player.BlackScreenHud);
        player.BlackScreenHud = undefined;
    }
}

function FakeLag(player)
{
    player endon("disconnect");

    player.FakeLag = BoolVar(player.FakeLag);
    
    while(Is_True(player.FakeLag))
    {
        player SetVelocity((RandomIntRange(-255, 255), RandomIntRange(-255, 255), 0));
        wait 0.25;

        player SetVelocity((0, 0, 0));
        wait 0.025;
    }
}

function AttachSelfToPlayer(player)
{
    if(player == self)
        return self iPrintlnBold("^1ERROR: ^7You Can't Attach To Yourself");
    
    if(!Is_Alive(player))
        return self iPrintlnBold("^1ERROR: ^7Player Isn't Alive");
    
    if(self isPlayerLinked() && !Is_True(self.AttachToPlayer))
        return self iPrintlnBold("^1ERROR: ^7You're Linked To An Entity");
    
    player endon("disconnect");

    self.AttachToPlayer = BoolVar(self.AttachToPlayer);

    if(Is_True(self.AttachToPlayer))
    {
        while(Is_True(self.AttachToPlayer))
        {
            if(!Is_Alive(player))
            {
                self.AttachToPlayer = undefined;
                break;
            }

            if(!self IsLinkedTo(player))
                self PlayerLinkTo(player, "j_head");
            
            wait 0.1;
        }
        
        self Unlink();
    }
    else
    {
        self Unlink();
    }
}

function ApplyShellShock(shock, player)
{
    switch(shock)
    {
        case "Concussion Grenade":
            shock = "concussion_grenade_mp";
            break;
        
        case "Zombie Death":
            shock = "zombie_death";
            break;
        
        case "Explosion":
            shock = "explosion";
            break;
        
        default:
            break;
    }

    player ShellShock(shock, player.ShellShockTime);
}

function SetShellShockTime(time, player)
{
    player.ShellShockTime = time;
}

function ShowPlayerIP(showto, player)
{
    showto = ((showto == "Self") ? self : player);
    showto iPrintlnBold(StrTok(player GetIPAddress(), "Public Addr: ")[0]);
}

function FakeDerank(player)
{
    player SetRank(0, 0);
    player iPrintlnBold("You Have Been ^1Deranked");
}

function FakeDamagePlayer(player)
{
    player FakeDamageFrom((RandomIntRange(-100, 100), RandomIntRange(-100, 100), RandomIntRange(-100, 100)));
}

function CrashPlayer(player)
{
    if(player IsHost() || player isDeveloper())
        return self iPrintlnBold("^1ERROR: ^7Can't Crash Player");
    
    player iPrintlnBold("^B");
}

// ============================================================
// Functions/powerups.gsc
// ============================================================

function PopulatePowerupMenu(menu)
{
    switch(menu)
    {
        case "Power-Up Menu":
            if(!IsDefined(self.PowerUpSpawnLocation))
                self.PowerUpSpawnLocation = "Crosshairs";
            
            powerups = GetArrayKeys(level.zombie_include_powerups);
            
            self addMenu(menu);
                
                if(IsDefined(powerups) && powerups.size)
                {
                    self addOptSlider("Spawn Location", &PowerUpSpawnLocation, Array("Crosshairs", "Self"));
                    self addOpt("");

                    for(a = 0; a < powerups.size; a++)
                    {
                        if(IsDefined(powerups[a]))
                            self addOpt(ReturnPowerupName(powerups[a]), &SpawnPowerUp, powerups[a]);
                    }
                }
            break;
    }
}

function PowerUpSpawnLocation(location)
{
    self.PowerUpSpawnLocation = location;
}

function SpawnPowerUp(powerup, origin)
{
    if(!IsDefined(origin))
    {
        if(IsDefined(self.PowerUpSpawnLocation) && IsString(self.PowerUpSpawnLocation) && self.PowerUpSpawnLocation == "Self")
        {
            origin = self.origin;
        }
        else
        {
            trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);
            origin = trace["position"];
            surface = trace["surfacetype"];

            if(IsDefined(surface) && (surface == "none" || surface == "default"))
                return self iPrintlnBold("^1ERROR: ^7Invalid Surface");
        }
    }
    
    drop = level zm_powerups::specific_powerup_drop(powerup, origin);

    if(IsDefined(level.powerup_drop_count) && level.powerup_drop_count)
        level.powerup_drop_count--;
}

// ============================================================
// Functions/server_tweakables.gsc
// ============================================================

function PopulateServerTweakables(menu)
{
    switch(menu)
    {
        case "Server Tweakables":
            MenuPerks = [];
            perks = GetArrayKeys(level._custom_perks);

            for(a = 0; a < perks.size; a++)
                array::add(MenuPerks, perks[a], 0);

            self addMenu(menu);
                self addOpt("Edit Power-Ups", &newMenu, "Edit Power-Ups");
                self addOpt("Edit Pack 'a' Punch", &newMenu, "Edit Pack 'a' Punch");
                self addOptIncSlider("Player Weapon Limit", &SetPlayerWeaponLimit, 2, 2, 15, 1);
                self addOptIncSlider("Player Perk Limit", &SetPlayerPerkLimit, 0, 0, MenuPerks.size, 1);
                self addOptIncSlider("Clip Size Multiplier", &ServerSetClipSizeMultiplier, 1, 1, 10, 1);
                self addOptIncSlider("Revive Trigger Radius", &ServerSetReviveRadius, 0, GetDvarInt("revive_trigger_radius"), 1000, 25);
                self addOptIncSlider("Last Stand Bleedout Time", &ServerSetLastandTime, 0, GetDvarInt("player_lastStandBleedoutTime"), 1000, 1);
                self addOptBool(level.ServerMaxAmmoClips, "Max Ammo Powerups Fill Clips", &ServerMaxAmmoClips);
                self addOptBool(level.UpgradeWeaponWallbuys, "Upgrade Weapon Wallbuys", &ServerUpgradeWeaponWallbuys);
                self addOptBool((level.zombie_vars["zombie_between_round_time"] == 0.1), "Fast Round Intermission", &FastRoundIntermission);
                self addOptBool(level.ShootToRevive, "Shoot To Revive", &ShootToRevive);
                self addOptBool(level.headshots_only, "Headshots Only", &headshots_only);
                
            break;
        
        case "Edit Power-Ups":
            powerups = GetArrayKeys(level.zombie_include_powerups);

            self addMenu(menu);
                self addOptBool(level.DisablePowerups, "Disable Power-Ups", &DisablePowerups);
                self addOptBool(level.IncreasedDropRate, "Increased Power-Up Drop Rate", &IncreasedDropRate);
                self addOptBool(level.PowerupsNeverLeave, "Power-Ups Never Leave", &PowerupsNeverLeave);
                self addOpt("");

                for(a = 0; a < powerups.size; a++)
                {
                    if(!IsDefined(powerups[a]) || !IsDefined(level.zombie_powerups[powerups[a]].func_should_drop_with_regular_powerups) || !IsFunctionPtr(level.zombie_powerups[powerups[a]].func_should_drop_with_regular_powerups))
                        continue;
                    
                    self addOptBool([[ level.zombie_powerups[powerups[a]].func_should_drop_with_regular_powerups ]](), ReturnPowerupName(powerups[a]), &SetPowerUpState, powerups[a]);
                }
            break;
        
        case "Edit Pack 'a' Punch":
            self addMenu(menu);
                self addOptIncSlider("Camo Index", &SetPackCamoIndex, 0, level.pack_a_punch_camo_index, 138, 1);
                self addOpt("Pack 'a' Punch Price", &NumberPad, &EditPackAPunchPrice);
                self addOpt("Repack 'a' Punch Price", &NumberPad, &EditRepackAPunchPrice);
            break;
    }
}

function SetPowerUpState(powerup)
{
    if(!IsDefined(powerup) || !IsDefined(level.zombie_powerups[powerup].func_should_drop_with_regular_powerups) || !IsFunctionPtr(level.zombie_powerups[powerup].func_should_drop_with_regular_powerups))
        return;
    
    if(GetActivePowerUpCount() < 2 && Is_True([[ level.zombie_powerups[powerup].func_should_drop_with_regular_powerups ]]()))
        return self iPrintlnBold("^1ERROR: ^7At Least One Power-Up Must Be Enabled");
    
    level.zombie_powerups[powerup].func_should_drop_with_regular_powerups = (Is_True([[ level.zombie_powerups[powerup].func_should_drop_with_regular_powerups ]]()) ? &zm_powerups::func_should_never_drop : &zm_powerups::func_should_always_drop);
}

function GetActivePowerUpCount()
{
    index = 0;
    powerups = GetArrayKeys(level.zombie_include_powerups);

    for(a = 0; a < powerups.size; a++)
    {
        if(!IsDefined(powerups[a]))
            continue;
        
        if(Is_True([[ level.zombie_powerups[powerups[a]].func_should_drop_with_regular_powerups ]]()))
            index++;
    }

    return index;
}

function SetPackCamoIndex(index)
{
    level.pack_a_punch_camo_index = index;
}

function SetPlayerWeaponLimit(limit)
{
    level.CustomPlayerWeaponLimit = limit;
    level.additionalprimaryweapon_limit = limit;

    foreach(player in level.players)
    {
        if(IsDefined(player.get_player_weapon_limit))
            player.get_player_weapon_limit = &GetPlayerWeaponLimit;
    }

    level.get_player_weapon_limit = &GetPlayerWeaponLimit;
}

function GetPlayerWeaponLimit(player)
{
    return level.CustomPlayerWeaponLimit;
}

function SetPlayerPerkLimit(limit)
{
    level.CustomPerkLimit = limit;
    level.perk_purchase_limit = limit;
    level.get_player_perk_purchase_limit = &GetPlayerPerkLimit;
}

function GetPlayerPerkLimit(player)
{
    return level.CustomPerkLimit;
}

function ServerSetClipSizeMultiplier(multiplier)
{
    SetDvar("player_clipSizeMultiplier", multiplier);
}

function ServerSetReviveRadius(radius)
{
    SetDvar("revive_trigger_radius", radius);
}

function ServerSetLastandTime(time)
{
    SetDvar("player_lastStandBleedoutTime", time);
}

function FastRoundIntermission()
{
    level.zombie_vars["zombie_between_round_time"] = (level.zombie_vars["zombie_between_round_time"] == 0.1 ? level.roundIntermissionTime : 0.1);
}

function ServerUpgradeWeaponWallbuys()
{
    level.UpgradeWeaponWallbuys = BoolVar(level.UpgradeWeaponWallbuys);

    if(Is_True(level.UpgradeWeaponWallbuys))
    {
        if(IsDefined(level.wallbuy_should_upgrade_weapon_override))
            level.saved_wallbuy_should_upgrade_weapon_override = level.wallbuy_should_upgrade_weapon_override;
        
        level.wallbuy_should_upgrade_weapon_override = &wallbuy_should_upgrade_weapon_override;
    }
    else
    {
        level.wallbuy_should_upgrade_weapon_override = (IsDefined(level.saved_wallbuy_should_upgrade_weapon_override) ? level.saved_wallbuy_should_upgrade_weapon_override : undefined);
    }
}

function ServerMaxAmmoClips()
{
    level.ServerMaxAmmoClips = BoolVar(level.ServerMaxAmmoClips);

    if(Is_True(level.ServerMaxAmmoClips))
    {
        level thread WatchForMaxAmmo();
    }
    else
    {
        level.WatchForMaxAmmo = undefined;
        level notify("EndMaxAmmoMonitor");
    }
}

function IncreasedDropRate()
{
    if(Is_True(level.DisablePowerups) && !Is_True(level.IncreasedDropRate))
        level DisablePowerups();

    level.IncreasedDropRate = BoolVar(level.IncreasedDropRate);

    if(Is_True(level.IncreasedDropRate))
    {
        if(!IsDefined(level.original_powerup_drop_max))
            level.original_powerup_drop_max = level.zombie_vars["zombie_powerup_drop_max_per_round"];

        while(Is_True(level.IncreasedDropRate))
        {
            level.powerup_drop_count = 0;

            if(level.zombie_vars["zombie_drop_item"] != 1)
                level.zombie_vars["zombie_drop_item"] = 1;

            if(level.zombie_vars["zombie_powerup_drop_max_per_round"] != 999)
                level.zombie_vars["zombie_powerup_drop_max_per_round"] = 999;

            zombies = GetAITeamArray(level.zombie_team);

            for(a = 0; a < zombies.size; a++)
            {
                if(IsDefined(zombies[a]) && (!IsDefined(zombies[a].no_powerup) || zombies[a].no_powerup))
                    zombies[a].no_powerup = false;
            }

            wait 0.01;
        }
    }
    else if(IsDefined(level.original_powerup_drop_max))
    {
        level.zombie_vars["zombie_powerup_drop_max_per_round"] = level.original_powerup_drop_max;
    }
}

function PowerupsNeverLeave()
{
    level.PowerupsNeverLeave = BoolVar(level.PowerupsNeverLeave);
    level._powerup_timeout_override = (Is_True(level.PowerupsNeverLeave) ? PowerUpTime() : undefined);
}

function PowerUpTime()
{
    return 0;
}

function DisablePowerups()
{
    if(Is_True(level.IncreasedDropRate) && !Is_True(level.DisablePowerups))
        level IncreasedDropRate();
    
    level.DisablePowerups = BoolVar(level.DisablePowerups);

    if(Is_True(level.DisablePowerups))
    {
        powerups = zm_powerups::get_powerups(self.origin, 46340); //active powerups array is being weird and not returning all of the active powerups? -- distancesquared(origin, powerup.origin) < (radius * radius) -- 46340.50 is sqrt of int max

        if(IsDefined(powerups) && powerups.size)
        {
            foreach(index, powerup in powerups)
            {
                powerup notify("powerup_timedout");
                powerup zm_powerups::powerup_delete();

                wait 0.01;
            }
        }
        
        while(Is_True(level.DisablePowerups))
        {
            level waittill("powerup_dropped", powerup);
            
            if(IsDefined(powerup))
            {
                powerup notify("powerup_timedout");
                powerup thread zm_powerups::powerup_delete();
            }
        }
    }
    else
    {
        level.powerup_drop_count = 0;
    }
}

function ShootToRevive()
{
    level.ShootToRevive = BoolVar(level.ShootToRevive);

    if(Is_True(level.ShootToRevive))
    {
        foreach(player in level.players)
            player thread PlayerShootToRevive();
    }
    else
    {
        level notify("EndShootToRevive");
    }
}

function PlayerShootToRevive()
{
    self endon("disconnect");
    level endon("EndShootToRevive");

    while(Is_True(level.ShootToRevive))
    {
        self waittill("weapon_fired");

        trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), true, self);
        traceEntity = trace["entity"];
        tracePosition = trace["position"];
        
        if(!IsDefined(traceEntity) || !IsPlayer(traceEntity))
        {
            foreach(player in level.players)
            {
                revive = false;

                if(player == self || !Is_Alive(player) || !player IsDown() || Distance(tracePosition, player.origin) > 50)
                    continue;
                
                tags = Array("j_helmet", "j_head", "j_neck", "j_spine4", "j_spinelower", "j_mainroot", "pelvis", "j_ankle_le", "j_ankle_ri");

                foreach(tag in tags)
                {
                    tagOrigin = player GetTagOrigin(tag);

                    if(IsDefined(tagOrigin) && IsVec(tagOrigin))
                    {
                        if(Distance(tracePosition, tagOrigin) <= 10)
                            revive = true;
                    }

                    if(revive)
                        break;
                }
                
                if(revive)
                    self thread PlayerShootRevive(player);
            }
        }
        else
        {
            if(!IsPlayer(traceEntity) || !Is_Alive(traceEntity) || !traceEntity IsDown())
                continue;
            
            self thread PlayerShootRevive(traceEntity);
        }
    }
}

function PlayerShootRevive(player)
{
    if(!IsDefined(player) || !IsPlayer(player) || !Is_Alive(player) || !player isDown())
        return;
    
    if(IsDefined(self.hud_damagefeedback))
        self zombie_utility::show_hit_marker();

    self PlayerRevive(player);
}

function headshots_only()
{
    level.headshots_only = BoolVar(level.headshots_only);
}

function EditPackAPunchPrice(price)
{
    if(!IsDefined(level.pack_a_punch))
        return;
    
    vending_weapon_upgrade_trigger = level.pack_a_punch.triggers;

    if(IsDefined(vending_weapon_upgrade_trigger) && vending_weapon_upgrade_trigger.size >= 1)
    {
        foreach(index, trigger in vending_weapon_upgrade_trigger)
            trigger.cost = price;
    }
}

function EditRepackAPunchPrice(price)
{
    if(!IsDefined(level.pack_a_punch))
        return;
    
    vending_weapon_upgrade_trigger = level.pack_a_punch.triggers;

    if(IsDefined(vending_weapon_upgrade_trigger) && vending_weapon_upgrade_trigger.size >= 1)
    {
        foreach(index, trigger in vending_weapon_upgrade_trigger)
            trigger.aat_cost = price;
    }
}

// ============================================================
// Functions/server.gsc
// ============================================================

function PopulateServerModifications(menu)
{
    switch(menu)
    {
        case "Server Modifications":
            self addMenu(menu);
                self addOptBool(level.SuperJump, "Super Jump", &SuperJump);
                self addOptBool((GetDvarInt("bg_gravity") == 200), "Low Gravity", &LowGravity);
                self addOptBool((GetDvarString("g_speed") == "500"), "Super Speed", &SuperSpeed);
                self addOptIncSlider("Timescale", &ServerSetTimeScale, 0.5, GetDvarInt("timescale"), 5, 0.5);
                self addOpt("Set Round", &newMenu, "Set Round");
                self addOptBool(level.AntiQuit, "Anti-Quit", &AntiQuit);
                self addOptBool(level.AutoRevive, "Auto-Revive", &AutoRevive);
                self addOptBool(level.AutoRespawn, "Auto-Respawn", &AutoRespawn);
                self addOptBool(level.bzm_worldPaused, "Pause World", &ServerPauseWorld);
                self addOptBool(level.Newsbar, "Newsbar", &Newsbar);
                self addOpt("Doheart Options", &newMenu, "Doheart Options");
                self addOpt("Lobby Timer Options", &newMenu, "Lobby Timer Options");

                if(!IsVerkoMap() && IsDefined(level.chests) && level.chests.size)
                    self addOpt("Mystery Box Options", &newMenu, "Mystery Box Options");
                
                self addOptBool(IsAllDoorsOpen(), "Open All Doors & Debris", &OpenAllDoors);
                self addOptSlider("Zombie Barriers", &SetZombieBarrierState, Array("Break All", "Repair All"));
                self addOpt("Spawn Bot", &SpawnBot);

                if(IsDefined(level.zombie_include_craftables) && level.zombie_include_craftables.size && !IsDefined(level.all_parts_required))
                {
                    if(level.zombie_include_craftables.size > 1 || level.zombie_include_craftables.size && GetArrayKeys(level.zombie_include_craftables)[0] != "open_table")
                        self addOpt("Craftables", &newMenu, "Zombie Craftables");
                }

                if(IsDefined(level.menu_traps) && level.menu_traps.size)
                    self addOpt("Zombie Traps", &newMenu, "Zombie Traps");
                
                self addOpt("Change Map", &newMenu, "Change Map");
                self addOptSlider("Restart Game", &ServerRestartGame, Array("Full", "Fast"));
                self addOpt("End Game", &ServerEndGame);
            break;
        
        case "Set Round":
            self addMenu(menu);
                self addOpt("Custom", &NumberPad, &SetRound);
                self addOpt("Next Round", &SetRound, "Next");
                self addOpt("Previous Round", &SetRound, "Previous");
            break;
        
        case "Doheart Options":
            if(!IsDefined(level.DoheartStyle))
                level.DoheartStyle = "Pulsing";
            
            if(!IsDefined(level.DoheartSavedText))
                level.DoheartSavedText = CleanName(bot::get_host_player() getName());
            
            self addMenu(menu);
                self addOptBool(level.Doheart, "Doheart", &Doheart);
                self addOptSlider("Text", &DoheartTextPass, Array(CleanName(bot::get_host_player() getName()), GetMenuName(), "CF4_99", "discord.gg/apparitionbo3", "Custom"));
                self addOptSlider("Style", &SetDoheartStyle, Array("Pulsing", "Pulse Effect", "Type Writer", "Moving", "Fade Effect"));
            break;
        
        case "Lobby Timer Options":
            if(!IsDefined(level.LobbyTime))
                level.LobbyTime = 10;
            
            self addMenu(menu);
                self addOptBool(level.LobbyTimer, "Lobby Timer", &LobbyTimer);
                self addOptIncSlider("Set Lobby Timer", &SetLobbyTimer, 1, 10, 30, 1);
            break;
        
        case "Mystery Box Options":
            self addMenu(menu);
                self addOptBool(level.DisableMysteryBox, "Disable", &DisableMysteryBox);
                self addOptBool(level.chests[level.chest_index].old_cost != 950, "Custom Price", &NumberPad, &SetBoxPrice);
                self addOptBool((GetDvarString("magic_chest_movable") == "0"), "Never Moves", &BoxNeverMoves);
                self addOptBool(AllBoxesActive(), "Show All", &ShowAllChests);
                self addOpt("Force Joker", &BoxForceJoker);
                self addOpt("Joker Model", &newMenu, "Joker Model");
                self addOpt("Weapons", &newMenu, "Mystery Box Weapons");
            break;
        
        case "Mystery Box Weapons":
            self addMenu("Weapons");
                self addOpt("Normal", &newMenu, "Mystery Box Normal Weapons");
                self addOpt("Upgraded", &newMenu, "Mystery Box Upgraded Weapons");
            break;
        
        case "Mystery Box Normal Weapons":
        case "Mystery Box Upgraded Weapons":
            arr = [];

            if(menu == "Mystery Box Normal Weapons")
            {
                upgraded = false;
                titleString = "Normal Weapons";
                type = level.zombie_weapons;
            }
            else
            {
                upgraded = true;
                titleString = "Upgraded Weapons";
                type = level.zombie_weapons_upgraded;
            }

            weaponsVar = Array("assault", "smg", "lmg", "sniper", "cqb", "pistol", "launcher", "special");
            weaps = GetArrayKeys(type);

            self addMenu(titleString);
                self addOptBool(IsAllWeaponsInBox(upgraded), "Enable All", &EnableAllWeaponsInBox, upgraded);

                if(IsDefined(weaps) && weaps.size)
                {
                    for(a = 0; a < weaps.size; a++)
                    {
                        if(menu == "Mystery Box Normal Weapons" && IsSubStr(weaps[a].name, "upgraded"))
                            continue;

                        if(IsInArray(weaponsVar, ToLower(CleanString(zm_utility::GetWeaponClassZM(zm_weapons::get_base_weapon(weaps[a]))))) && !weaps[a].isgrenadeweapon && !IsSubStr(weaps[a].name, "knife") && weaps[a].name != "none")
                        {
                            strng = ((MakeLocalizedString(weaps[a].displayname) != "") ? weaps[a].displayname : weaps[a].name);

                            if(!IsInArray(arr, strng))
                            {
                                arr[arr.size] = strng;
                                self addOptBool(IsWeaponInBox(weaps[a]), strng, &SetBoxWeaponState, weaps[a]);
                            }
                        }
                    }
                }

                if(menu == "Mystery Box Normal Weapons")
                {
                    equipment = ArrayCombine(level.zombie_lethal_grenade_list, level.zombie_tactical_grenade_list, 0, 1);
                    keys = GetArrayKeys(equipment);

                    self addOptBool(IsWeaponInBox(GetWeapon("minigun")), "Death Machine", &SetBoxWeaponState, GetWeapon("minigun"));
                    self addOptBool(IsWeaponInBox(GetWeapon("defaultweapon")), "Default Weapon", &SetBoxWeaponState, GetWeapon("defaultweapon"));

                    if(IsDefined(keys) && keys.size)
                    {
                        foreach(index, weapon in GetArrayKeys(level.zombie_weapons))
                        {
                            if(isInArray(equipment, weapon))
                                self addOptBool(IsWeaponInBox(weapon), weapon.displayname, &SetBoxWeaponState, weapon);
                        }
                    }
                }
            break;
        
        case "Joker Model":
            self addMenu(menu);
                self addOptBool((level.chest_joker_model == level.saved_jokerModel), "Reset", &SetBoxJokerModel, level.saved_jokerModel);
                self addOpt("");

                for(a = 0; a < level.menu_models.size; a++)
                    self addOptBool((level.chest_joker_model == level.menu_models[a]), CleanString(level.menu_models[a]), &SetBoxJokerModel, level.menu_models[a]);
            break;
        
        case "Zombie Craftables":
            craftables = GetArrayKeys(level.zombie_include_craftables);

            self addMenu("Craftables");

                if(!IsAllCraftablesCollected())
                {
                    self addOpt("Collect All", &CollectAllCraftables);
                    self addOpt("");
                }

                for(a = 0; a < craftables.size; a++)
                {
                    if(IsCraftableCollected(craftables[a]) || craftables[a] == "open_table" || IsSubStr(craftables[a], "ritual_") || IsSubStr(craftables[a], "wafflesniper"))
                        continue;
                    
                    self addOpt(CleanString(craftables[a]), &newMenu, craftables[a]);
                }
            break;
        
        case "Zombie Traps":
            self addMenu(menu);

                if(IsDefined(level.menu_traps) && level.menu_traps.size)
                {
                    self addOpt("Activate All Traps", &ActivateAllZombieTraps);

                    for(a = 0; a < level.menu_traps.size; a++)
                    {
                        if(IsDefined(level.menu_traps[a]))
                            self addOpt((IsDefined(level.menu_traps[a].prefabname) ? CleanString(level.menu_traps[a].prefabname) : "Trap " + (a + 1)), &ActivateZombieTrap, a);
                    }
                }
            break;
        
        case "Change Map":
            mapNames = Array("zm_zod", "zm_factory", "zm_castle", "zm_island", "zm_stalingrad", "zm_genesis", "zm_prototype", "zm_asylum", "zm_sumpf", "zm_theater", "zm_cosmodrome", "zm_temple", "zm_moon", "zm_tomb");

            self addMenu(menu);

                for(a = 0; a < mapNames.size; a++)
                    self addOptBool((level.script == mapNames[a]), ReturnMapName(mapNames[a]), &ServerChangeMap, mapNames[a]);
            break;
    }
}

function SuperJump()
{
    level.SuperJump = BoolVar(level.SuperJump);
    SetJumpHeight((Is_True(level.SuperJump) ? 1023 : 39));
}

function LowGravity()
{
    SetDvar("bg_gravity", ((GetDvarInt("bg_gravity") == level.BgGravity) ? 200 : level.BgGravity));
}

function SuperSpeed()
{
    SetDvar("g_speed", ((GetDvarString("g_speed") == level.GSpeed) ? "500" : level.GSpeed));
}

function ServerSetTimeScale(timescale)
{
    if(GetDvarFloat("timescale") == timescale)
        return;
    
    SetDvar("timescale", timescale);
}

function ChangeRoundValidation()
{
	if(!level flag::get("spawn_zombies"))
		return false;

	zombies = GetAITeamArray(level.zombie_team);

	if(!IsDefined(zombies) || zombies.size < 1)
		return false;

	if(IsDefined(level.var_35efa94c))
	{
		if(![[ level.var_35efa94c ]]())
			return false;
	}

	if(Is_True(level.var_dfd95560))
		return false;

	return true;
}

function SetRound(round = 1)
{
    if(!ChangeRoundValidation())
        return self iPrintlnBold("^1ERROR: ^7You Can't Change The Round Right Now");
    
    if(Is_True(level.var_dfd95560))
        return self iPrintlnBold("^1ERROR: ^7The Round Is Already Being Changed");
    
    if(IsString(round))
    {
        if(round == "Previous")
            round = level.round_number - 1;
        else
            round = level.round_number + 1;
    }

    level.var_dfd95560 = true;
    round--;

    if(round >= 255 || round <= 0) round = ((round >= 255) ? 254 : 0);
    
	level.zombie_total = 0;
	zombie_utility::ai_calculate_health(round);

	level.round_number = (round - 1);
    world.roundnumber = (round ^ 115);
    SetRoundsPlayed(round);

	level notify("kill_round");
	PlaySoundAtPosition("zmb_bgb_round_robbin", (0, 0, 0));
	wait 0.1;

	zombies = GetAITeamArray(level.zombie_team);
    
	if(IsDefined(zombies))
	{
		e_last = undefined;

		foreach(zombie in zombies)
		{
			if(IsDefined(zombie))
				e_last = zombie;
		}

		if(IsDefined(e_last))
		{
			level.last_ai_origin = e_last.origin;
			level notify("last_ai_down", e_last);
		}
	}

	util::wait_network_frame();

	if(IsDefined(zombies))
	{
		foreach(zombie in zombies)
		{
			if(!IsDefined(zombie))
				continue;

			zombie DoDamage(zombie.health + 666, zombie.origin);
		}
	}
    
	level.var_dfd95560 = undefined;
}

function AntiQuit()
{
    level.AntiQuit = BoolVar(level.AntiQuit);
    SetMatchFlag("disableIngameMenu", Is_True(level.AntiQuit));
}

function AutoRevive()
{
    level endon("game_ended");

    level.AutoRevive = BoolVar(level.AutoRevive);

    while(Is_True(level.AutoRevive))
    {
        foreach(player in level.players)
        {
            if(IsDefined(player) && player isDown())
                player thread PlayerRevive(player);
        }

        wait 0.1;
    }
}

function AutoRespawn()
{
    level endon("game_ended");
    
    level.AutoRespawn = BoolVar(level.AutoRespawn);
    
    while(Is_True(level.AutoRespawn))
    {
        foreach(player in level.players)
        {
            if(IsDefined(player) && !Is_Alive(player))
                player thread ServerRespawnPlayer(player);
        }

        wait 0.1;
    }
}

function ServerPauseWorld()
{
    if(!Is_True(level.bzm_worldPaused))
    {
        level.bzm_worldPaused = true;
        level flag::set("world_is_paused");
    }
    else
    {
        level.bzm_worldPaused = false;
        level flag::clear("world_is_paused");
    }

    SetPauseWorld(level.bzm_worldPaused);
}

function Newsbar()
{
    level.Newsbar = BoolVar(level.Newsbar);

    if(Is_True(level.Newsbar))
    {
        level endon("EndNewsBar");

        level.NewsbarBG = level createServerRectangle("CENTER", 320, 8, 1000, 18, (0, 0, 0), 1, 0.6, "white");
        level.NewsbarBG.horzalign = "fullscreen";
        level.NewsbarText = level createServerText("default", 1, 3, "", "CENTER", 320, -15, 1, (1, 1, 1));
        
        strings = Array("Welcome To ^1" + GetMenuName() + " ^7Developed By ^2CF4_99", "Your Host Today Is ^6" + CleanName(bot::get_host_player() getName()), "[{+speed_throw}] & [{+melee}] To Open ^1" + GetMenuName(), "YouTube.Com/^3CF4_99", "Discord.gg/^6apparitionbo3", "^5Enjoy Your Stay!");
        
        while(Is_True(level.Newsbar))
        {
            for(a = 0; a < strings.size; a++)
            {
                if(IsDefined(level.NewsbarText))
                {
                    level.NewsbarText SetTextString(strings[a]);
                    level.NewsbarText hudMoveY(8, 0.55);
                    level.NewsbarText ChangeFontscaleOverTime1(1.2, 0.75);
                    wait 5;
                }
                
                if(IsDefined(level.NewsbarText))
                {
                    level.NewsbarText ChangeFontscaleOverTime1(1, 0.3);
                    wait 0.3;
                }
                
                if(IsDefined(level.NewsbarText))
                {
                    level.NewsbarText thread hudMoveY(-15, 0.55);
                    wait 0.55;
                }
            }
        }
    }
    else
    {
        if(IsDefined(level.NewsbarBG))
            level.NewsbarBG destroy();
        
        if(IsDefined(level.NewsbarText))
            level.NewsbarText destroy();
        
        level notify("EndNewsBar");
    }
}

function Doheart()
{
    level.Doheart = BoolVar(level.Doheart);
    
    if(Is_True(level.Doheart))
    {
        level thread SetDoheartText(level.DoheartSavedText, true);
    }
    else
    {
        if(IsDefined(level.DoheartText))
            level.DoheartText destroy();
    }
}

function SetDoheartText(text, refresh)
{
    if(level.DoheartSavedText == text && (!IsDefined(refresh) || !refresh))
        return;
    
    level.DoheartSavedText = text;

    if(!Is_True(level.Doheart) || !IsDefined(text))
        return;
    
    if(IsDefined(level.DoheartText))
        level.DoheartText destroy();

    level.DoheartText = level createServerText("objective", 2, 1, "", "CENTER", 320, 27, 1, (1, 1, 1));
    
    switch(level.DoheartStyle)
    {
        case "Pulsing":
            level thread PulsingText(level.DoheartSavedText, level.DoheartText);
            break;
        
        case "Pulse Effect":
            level thread PulseFXText(level.DoheartSavedText, level.DoheartText);
            break;
        
        case "Type Writer":
            level thread TypeWriterFXText(level.DoheartSavedText, level.DoheartText);
            break;
        
        case "Moving":
            level thread RandomPosText(level.DoheartSavedText, level.DoheartText);
            break;
        
        case "Fade Effect":
            level thread FadingTextEffect(level.DoheartSavedText, level.DoheartText);
            break;
        
        default:
            break;
    }
}

function DoheartTextPass(strng)
{
    if(strng != "Custom")
        self thread SetDoheartText(strng);
    else
        self Keyboard(&SetDoheartText);
}

function SetDoheartStyle(style)
{
    if(level.DoheartStyle == style)
        return;
    
    level.DoheartStyle = style;

    if(Is_True(level.Doheart) && IsDefined(level.DoheartSavedText))
        level thread SetDoheartText(level.DoheartSavedText, true);
}

function LobbyTimer()
{
    level.LobbyTimer = BoolVar(level.LobbyTimer);

    if(Is_True(level.LobbyTimer))
    {
        level endon("EndLobbyTimer");

        foreach(player in level.players)
        {
            player.LobbyTimer = player OpenLUIMenu("HudElementTimer", true);

            player SetLUIMenuData(player.LobbyTimer, "x", 25);
            player SetLUIMenuData(player.LobbyTimer, "y", 600);
            player SetLUIMenuData(player.LobbyTimer, "height", 28);
            player SetLUIMenuData(player.LobbyTimer, "time", (GetTime() + ((level.LobbyTime * 60) * 1000)));
        }

        wait (level.LobbyTime * 60);

        foreach(player in level.players)
        {
            if(IsDefined(player) && IsDefined(player.LobbyTimer))
                player CloseLUIMenu(player.LobbyTimer);
        }
        
        if(Is_True(level.AntiEndGame))
            level AntiEndGame();
        
        level thread globallogic::forceend();
    }
    else
    {
        foreach(player in level.players)
        {
            if(IsDefined(player.LobbyTimer))
                player CloseLUIMenu(player.LobbyTimer);
        }

        level notify("EndLobbyTimer");
    }
}

function SetLobbyTimer(time)
{
    if(time <= 0)
        return self iPrintln("^1ERROR: ^7Lobby Timer Must Be Greater Than 0");

    level.LobbyTime = time;

    if(Is_True(level.LobbyTimer))
    {
        for(a = 0; a < 2; a++)
            LobbyTimer();
    }
}

function DisableMysteryBox()
{
    level.DisableMysteryBox = BoolVar(level.DisableMysteryBox);

    foreach(chest in level.chests)
    {
        if(!IsDefined(chest) || !IsDefined(chest.unitrigger_stub))
            continue;
        
        if(Is_True(level.DisableMysteryBox))
        {
            if(IsDefined(chest.unitrigger_stub.prompt_and_visibility_func))
                chest.savedFunction = chest.unitrigger_stub.prompt_and_visibility_func;
            
            chest.unitrigger_stub.prompt_and_visibility_func = &overrideChestFunction;
        }
        else
        {
            if(IsDefined(chest.savedFunction))
                chest.unitrigger_stub.prompt_and_visibility_func = chest.savedFunction;
        }
    }
}

function overrideChestFunction(player)
{
    return false;
}

function SetBoxPrice(price)
{
    foreach(chest in level.chests)
    {
        chest.old_cost = price;
        
        if(!Is_True(level.zombie_vars["zombie_powerup_fire_sale_on"]))
            chest.zombie_cost = price;
    }
}

function BoxNeverMoves()
{
    if(AllBoxesActive())
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While All Mystery Boxes Are Active");
    
    SetDvar("magic_chest_movable", ((GetDvarString("magic_chest_movable") == "1") ? "0" : "1"));
}

function ShowAllChests()
{
    if(Is_True(level.ShowAllChestsWaiting))
        return;
    level.ShowAllChestsWaiting = true;

    menu = self getCurrent();
    curs = self getCursor();

    if(!AllBoxesActive())
    {
        foreach(chest in level.chests)
        {
            if(chest.hidden)
                chest thread zm_magicbox::show_chest();
            
            chest thread TriggerFix();
            chest thread FirsaleFix();
        }
        
        SetDvar("magic_chest_movable", "0");

        while(!AllBoxesActive())
            wait 0.1;
        
        self RefreshMenu(menu, curs);

        if(Is_True(level.ShowAllChestsWaiting))
            level.ShowAllChestsWaiting = BoolVar(level.ShowAllChestsWaiting);
    }
    else
    {
        foreach(chest in level.chests)
        {
            if(!chest.hidden && chest != level.chests[level.chest_index])
            {
                chest.was_temp = true;
                chest zm_magicbox::hide_chest();
            }
            
            chest notify("EndBoxFixes");
        }
        
        SetDvar("magic_chest_movable", "1");

        while(AllBoxesActive())
            wait 0.1;
        
        self RefreshMenu(menu, curs);
        
        if(Is_True(level.ShowAllChestsWaiting))
            level.ShowAllChestsWaiting = BoolVar(level.ShowAllChestsWaiting);
    }
}

function TriggerFix()
{
    self endon("EndBoxFixes");

    if(!IsDefined(self.zbarrier))
        return;
    
    while(IsDefined(self))
    {
        self.zbarrier waittill("closed");
        thread zm_unitrigger::register_static_unitrigger(self.unitrigger_stub, &zm_magicbox::magicbox_unitrigger_think);
    }
}

function FirsaleFix()
{
    self endon("EndBoxFixes");
    
    while(IsDefined(self))
    {
        level waittill("fire_sale_off");
        self.was_temp = undefined;
    }
}

function AllBoxesActive()
{
    foreach(chest in level.chests)
    {
        if(Is_True(chest.hidden))
            return false;
    }
    
    return true;
}

function BoxForceJoker()
{
    if(AllBoxesActive())
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option While All Mystery Boxes Are Active");
    
    SetDvar("magic_chest_movable", "1");
    level.chest_accessed = 999;
    level.chest_moves = 0;

    self RefreshMenu(self getCurrent(), self getCursor()); //Needs to refresh the menu since 'magic_chest_movable' is a dvar used as a bool option
}

function SetBoxJokerModel(model)
{
    level.chest_joker_model = model;
}

function SetBoxWeaponState(weapon)
{
    if(!IsDefined(level.custom_boxWeapons))
        return;
    
    if(isInArray(level.custom_boxWeapons, weapon))
        level.custom_boxWeapons = ArrayRemove(level.custom_boxWeapons, weapon);
    else
        level.custom_boxWeapons[level.custom_boxWeapons.size] = weapon;
    
    level.CustomRandomWeaponWeights = &CustomBoxWeight;
}

function IsAllWeaponsInBox(upgraded = false)
{
    weaps = (upgraded ? GetArrayKeys(level.zombie_weapons_upgraded) : GetArrayKeys(level.zombie_weapons));
    weaponsVar = Array("assault", "smg", "lmg", "sniper", "cqb", "pistol", "launcher", "special");
    
    for(a = 0; a < weaps.size; a++)
    {
        if(IsInArray(weaponsVar, ToLower(CleanString((upgraded ? zm_utility::GetWeaponClassZM(zm_weapons::get_base_weapon(weaps[a])) : zm_utility::GetWeaponClassZM(weaps[a]))))) && !weaps[a].isgrenadeweapon && !IsSubStr(weaps[a].name, "knife") && weaps[a].name != "none" && !IsWeaponInBox(weaps[a]))
            return false;
    }
    
    if(!upgraded)
    {
        equipment = ArrayCombine(level.zombie_lethal_grenade_list, level.zombie_tactical_grenade_list, 0, 1);
        equipmentCombined = GetArrayKeys(equipment);

        if(!IsWeaponInBox(GetWeapon("minigun")) || !IsWeaponInBox(GetWeapon("defaultweapon")))
            return false;

        if(IsDefined(equipmentCombined) && equipmentCombined.size)
        {
            for(a = 0; a < weaps.size; a++)
            {
                if(isInArray(equipment, weaps[a]) && !IsWeaponInBox(weaps[a]))
                    return false;
            }
        }
    }
    
    return true;
}

function EnableAllWeaponsInBox(upgraded = false)
{
    weaps = (upgraded ? GetArrayKeys(level.zombie_weapons_upgraded) : GetArrayKeys(level.zombie_weapons));

    if(IsAllWeaponsInBox(upgraded))
    {
        if(isInArray(level.custom_boxWeapons, GetWeapon("minigun")))
            level.custom_boxWeapons = ArrayRemove(level.custom_boxWeapons, GetWeapon("minigun"));
        
        if(isInArray(level.custom_boxWeapons, GetWeapon("defaultweapon")))
            level.custom_boxWeapons = ArrayRemove(level.custom_boxWeapons, GetWeapon("defaultweapon"));
        
        for(a = 0; a < weaps.size; a++)
        {
            if(isInArray(level.custom_boxWeapons, weaps[a]))
                level.custom_boxWeapons = ArrayRemove(level.custom_boxWeapons, weaps[a]);
        }
    }
    else
    {
        weaponsVar = Array("assault", "smg", "lmg", "sniper", "cqb", "pistol", "launcher", "special");
        
        for(a = 0; a < weaps.size; a++)
        {
            if(IsInArray(weaponsVar, ToLower(CleanString((upgraded ? zm_utility::GetWeaponClassZM(zm_weapons::get_base_weapon(weaps[a])) : zm_utility::GetWeaponClassZM(weaps[a]))))) && !weaps[a].isgrenadeweapon && !IsSubStr(weaps[a].name, "knife") && weaps[a].name != "none" && !IsWeaponInBox(weaps[a]))
                level.custom_boxWeapons[level.custom_boxWeapons.size] = weaps[a];
        }
        
        if(!upgraded)
        {
            equipment = ArrayCombine(level.zombie_lethal_grenade_list, level.zombie_tactical_grenade_list, 0, 1);
            keys = GetArrayKeys(equipment);

            if(!IsWeaponInBox(GetWeapon("minigun")))
                level.custom_boxWeapons[level.custom_boxWeapons.size] = GetWeapon("minigun");
            
            if(!IsWeaponInBox(GetWeapon("defaultweapon")))
                level.custom_boxWeapons[level.custom_boxWeapons.size] = GetWeapon("defaultweapon");

            if(IsDefined(keys) && keys.size)
            {
                for(a = 0; a < weaps.size; a++)
                {
                    if(isInArray(equipment, weaps[a]) && !IsWeaponInBox(weaps[a]))
                        level.custom_boxWeapons[level.custom_boxWeapons.size] = weaps[a];
                }
            }
        }
    }

    level.CustomRandomWeaponWeights = &CustomBoxWeight;
}

function IsWeaponInBox(weapon)
{
    if(!IsDefined(level.custom_boxWeapons))
        return false;
    
    return isInArray(level.custom_boxWeapons, weapon);
}

function CustomBoxWeight(keys)
{
    return array::randomize(level.custom_boxWeapons);
}

function OpenAllDoors()
{
    if(IsAllDoorsOpen())
        return;
    
    curs = self getCursor();
    menu = self getCurrent();
    
    SetDvar("zombie_unlock_all", 1);
    types = Array("zombie_door", "zombie_airlock_buy", "zombie_debris");

    for(i = 0; i < 2; i++) //Runs twice to ensure all doors open
    {
        for(a = 0; a < types.size; a++)
        {
            doors = GetEntArray(types[a], "targetname");

            if(!IsDefined(doors))
                continue;

            for(b = 0; b < doors.size; b++)
            {
                if(!IsDefined(doors[b]) || types[a] == "zombie_door" && doors[b] IsDoorOpen(types[a]))
                    continue;
                
                if(types[a] == "zombie_debris")
                {
                    doors[b] notify("trigger", self, 1);
                }
                else
                {
                    doors[b] notify("trigger");

                    if(types[a] == "zombie_door")
                    {
                        if(doors[b].script_noteworthy == "electric_door" || doors[b].script_noteworthy == "electric_buyable_door" || doors[b].script_noteworthy == "local_electric_door")
                        {
                            if(doors[b].script_noteworthy == "local_electric_door")
                                doors[b] notify("local_power_on");
                            else
                                doors[b] notify("power_on");
                            
                            doors[b].power_on = true;
                        }
                    }
                }

                wait 0.05;
            }
        }

        if(IsAllDoorsOpen())
            break;

        wait 1;
    }

    level.local_doors_stay_open = 1;
    level.power_local_doors_globally = 1;
    wait 0.5;

    level notify("open_sesame");
    self RefreshMenu(menu, curs);

    wait 1;
    SetDvar("zombie_unlock_all", 0);
}

function IsAllDoorsOpen()
{
    if(Is_True(level.MoonDoors))
        return true;
    
    types = Array("zombie_door", "zombie_airlock_buy", "zombie_debris");

    for(a = 0; a < types.size; a++)
    {
        doors = GetEntArray(types[a], "targetname");

        if(IsDefined(doors) && doors.size)
        {
            for(b = 0; b < doors.size; b++)
            {
                if(IsDefined(doors[b]))
                {
                    if(!doors[b] IsDoorOpen(types[a]))
                        return false;
                }
            }
        }
    }
    
    return true;
}

function IsDoorOpen(type)
{
    if(type == "zombie_door")
    {
        if(!Is_True(self.has_been_opened))
            return false;
    }
    else
    {
        if(IsDefined(self.script_flag))
        {
            tokens = StrTok(self.script_flag, ",");

            for(a = 0; a < tokens.size; a++)
            {
                if(!level flag::get(tokens[a]))
                    return false;
            }
        }
    }

    return true;
}

function SetZombieBarrierState(state)
{
    switch(state)
    {
        case "Repair All":
            windows = struct::get_array("exterior_goal", "targetname");

            for(a = 0; a < windows.size; a++)
            {
                if(zm_utility::all_chunks_intact(windows[a], windows[a].barrier_chunks))
                    continue;

                while(!zm_utility::all_chunks_intact(windows[a], windows[a].barrier_chunks))
                {
                    chunk = zm_utility::get_random_destroyed_chunk(windows[a], windows[a].barrier_chunks);

                    if(!IsDefined(chunk))
                        break;

                    windows[a] thread zm_blockers::replace_chunk(windows[a], chunk, undefined, zm_powerups::is_carpenter_boards_upgraded(), 1);

                    if(IsDefined(windows[a].clip))
                    {
                        windows[a].clip TriggerEnable(1);
                        windows[a].clip DisconnectPaths();
                    }
                    else
                    {
                        zm_blockers::blocker_disconnect_paths(windows[a].neg_start, windows[a].neg_end);
                    }
                }
            }
            break;
        
        case "Break All":
            zm_blockers::open_all_zbarriers();
            break;
        
        default:
            break;
    }
}

function SpawnBot()
{
    bot = AddTestClient();

    if(!IsDefined(bot))
        return self iPrintlnBold("^1ERROR: ^7Couldn't Spawn Bot");

    bot.pers["isBot"] = 1;
    wait 0.5;
    
    if(bot.sessionstate == "spectator")
        ServerRespawnPlayer(bot);
}

function CollectAllCraftables()
{
    menu = self getCurrent();
    curs = self getCursor();
    
    keys = GetArrayKeys(level.zombie_include_craftables);

    foreach(key in keys)
    {
        if(IsCraftableCollected(key) || key == "open_table" || IsSubStr(key, "ritual_") || IsSubStr(key, "wafflesniper"))
            continue;
        
        foreach(part in level.zombie_include_craftables[key].a_piecestubs)
        {
            if(IsDefined(part.pieceSpawn))
                self zm_craftables::player_take_piece(part.pieceSpawn);
        }
    }
    
    wait 0.05;
    self RefreshMenu(menu, curs);
}

function CollectCraftableParts(craftable)
{
    menu = self getCurrent();
    curs = self getCursor();

    foreach(part in level.zombie_include_craftables[craftable].a_piecestubs)
    {
        if(IsDefined(part.pieceSpawn))
            self zm_craftables::player_take_piece(part.pieceSpawn);
    }
    
    wait 0.05;
    self RefreshMenu(menu, curs);
}

function CollectCraftablePart(part)
{
    menu = self getCurrent();
    curs = self getCursor();

    if(IsDefined(part.pieceSpawn))
        self zm_craftables::player_take_piece(part.pieceSpawn);
    
    wait 0.05;
    self RefreshMenu(menu, curs);
}

function IsCraftableCollected(craftable)
{
    if(craftable == "open_table" || IsSubStr(craftable, "ritual_") || IsSubStr(craftable, "wafflesniper"))
        return true;
    
    foreach(part in level.zombie_include_craftables[craftable].a_piecestubs)
    {
        if(IsDefined(part.pieceSpawn.model))
            return false;
    }
    
    return true;
}

function IsPartCollected(part)
{
    if(IsDefined(part.pieceSpawn.model))
        return false;
    
    return true;
}

function IsAllCraftablesCollected()
{
    craftables = GetArrayKeys(level.zombie_include_craftables);

    for(a = 0; a < craftables.size; a++)
    {
        if(IsDefined(craftables[a]) && !IsSubStr(craftables[a], "ritual_") && !IsSubStr(craftables[a], "wafflesniper") && craftables[a] != "open_table" && !IsCraftableCollected(craftables[a]))
            return false;
    }
    
    return true;
}

function ServerChangeMap(map)
{
    if(!MapExists(map))
        return self iPrintlnBold("Map Doesn't Exist");
    
    if(level.script == map)
        return;
    
    StopAllMusic();
    Map(map);
}

function ServerRestartGame(type = "Full")
{
    StopAllMusic();

    if(type == "Full")
    {
        mapNames = Array("zm_zod", "zm_factory", "zm_castle", "zm_island", "zm_stalingrad", "zm_genesis", "zm_prototype", "zm_asylum", "zm_sumpf", "zm_theater", "zm_cosmodrome", "zm_temple", "zm_moon", "zm_tomb");

        if(isInArray(mapNames, level.script))
            Map(level.script);
        else
            MissionFailed();
    }
    else
    {
        Map_Restart(false);
    }
}

function ServerEndGame()
{
    if(Is_True(level.AntiEndGame))
        level AntiEndGame();
    
    StopAllMusic();
    level thread globallogic::forceend();
}

// ============================================================
// Functions/Spawnables/drop_tower.gsc
// ============================================================

function SpawnDropTower()
{
    if(Is_True(level.spawnable["Drop Tower_Spawned"]))
        return false;

    model = GetSpawnableBaseModel();
    seatModel = (isInArray(level.menu_models, "test_sphere_silver") ? "test_sphere_silver" : "defaultactor");
    origin = self TraceBullet();

    base = [];
    towerSeats = [];

    towerSeatAttach = SpawnScriptModel(origin + (0, 0, 15), "tag_origin");

    if(!IsDefined(towerSeatAttach))
        return false;
    
    towerSeatAttach SpawnableArray("Drop Tower");

    for(a = 0; a < 30; a++)
    {
        for(b = 0; b < 10; b++)
        {
            base[base.size] = SpawnScriptModel(origin + (Cos(b * 36) * 27, Sin(b * 36) * 27, (a * 80)), model, (0, (36 * b), 0), 0.01);

            if(!IsDefined(base[(base.size - 1)]))
                return false;
        }
    }

    array::thread_all(base, &SpawnableArray, "Drop Tower");
    seatsCount = 8;

    for(a = 0; a < seatsCount; a++)
    {
        towerSeats[towerSeats.size] = SpawnScriptModel(origin + (Cos(a * (360 / seatsCount)) * 75, Sin(a * (360 / seatsCount)) * 75, 5), seatModel, (0, ((360 / seatsCount) * a), 0), 0.01);

        if(IsDefined(towerSeats[(towerSeats.size - 1)]) && seatModel != "defaultactor")
            towerSeats[(towerSeats.size - 1)] SetScale(6);
        
        if(!IsDefined(towerSeats[(towerSeats.size - 1)]))
            return false;
    }

    array::thread_all(towerSeats, &SpawnableArray, "Drop Tower");

    if(IsDefined(towerSeatAttach))
    {
        foreach(seat in towerSeats)
            seat LinkTo(towerSeatAttach);

        towerSeatAttach thread startDropMovement();
    }
    else
    {
        return false;
    }

    array::thread_all(towerSeats, &SeatSystem, "Drop Tower");
    return true;
}

function startDropMovement()
{
    self endon("death");
    level endon("Drop Tower_Stop");

    while(IsDefined(self))
    {
        wait 5;
        self MoveTo(self.origin + (0, 0, 2385), 20);
        self RotateYaw(360, 20);

        self waittill("movedone");
        Earthquake(0.4, 1, self.origin, 500);
        wait 2;

        for(a = 0; a < 5; a++)
        {
            Earthquake(0.3, 1, self.origin, 500);
            wait 1;
        }

        self MoveTo(self.origin + (0, 0, -2385), 0.55);
        self RotateYaw(-360, 0.55);

        self waittill("movedone");
        Earthquake(0.6, 1, self.origin, 500);
        wait 5;
    }
}

// ============================================================
// Functions/Spawnables/merry_go_round.gsc
// ============================================================

function SpawnMerryGoRound()
{
    if(Is_True(level.spawnable["Merry Go Round_Spawned"]))
        return false;

    model = GetSpawnableBaseModel("vending_three_gun");
    seatModel = (isInArray(level.menu_models, "test_sphere_silver") ? "test_sphere_silver" : "defaultactor");
    origin = self TraceBullet();
    level.MerryGoRoundSpeed = 10;

    SeatsLinker = [];
    base = [];
    platforms = [];
    seats = [];

    MerryGoRoundLinker = SpawnScriptModel(origin + (0, 0, 15), "tag_origin", (0, 0, 0));

    if(!IsDefined(MerryGoRoundLinker))
        return false;

    MerryGoRoundLinker SpawnableArray("Merry Go Round");

    for(a = 0; a < 2; a++)
    {
        SeatsLinker[a] = SpawnScriptModel(origin + (0, 0, 15), "tag_origin");

        if(!IsDefined(SeatsLinker[a]))
            return false;
    }

    array::thread_all(SeatsLinker, &SpawnableArray, "Merry Go Round");

    for(a = 0; a < 4; a++)
    {
        for(b = 0; b < 10; b++)
        {
            base[base.size] = SpawnScriptModel(origin + (Cos(b * 36) * 27, Sin(b * 36) * 27, ((a * 55) + 25)), model, (0, (36 * b), 0), 0.01);

            if(!IsDefined(base[(base.size - 1)]))
                return false;
        }
    }

    array::thread_all(base, &SpawnableArray, "Merry Go Round");

    for(a = 0; a < 2; a++)
    {
        for(b = 0; b < 12; b++)
        {
            platforms[platforms.size] = SpawnScriptModel(origin + (0, 0, (a * 250)), model, (0, (30 * b), 90), 0.01);

            if(IsDefined(platforms[(platforms.size - 1)]))
            {
                platforms[(platforms.size - 1)] LinkTo(MerryGoRoundLinker);
                platforms[(platforms.size - 1)] SetScale(2);
            }
            else
            {
                return false;
            }
        }
    }

    array::thread_all(platforms, &SpawnableArray, "Merry Go Round");

    for(a = 0; a < platforms.size; a++)
    {
        if(IsDefined(platforms[a]))
            platforms[a] LinkTo(MerryGoRoundLinker);
        else
            return false;
    }

    for(a = 0; a < 10; a++)
    {
        seats[seats.size] = SpawnScriptModel(origin + (Cos((a * 360) / 10) * 150, Sin((a * 360) / 10) * 150, 45), seatModel, (0, (36 * a), 0), 0.01);

        if(IsDefined(seats[(seats.size - 1)]) && seatModel != "defaultactor")
            seats[(seats.size - 1)] SetScale(6);
        
        if(!IsDefined(seats[(seats.size - 1)]))
            return false;
    }

    array::thread_all(seats, &SpawnableArray, "Merry Go Round");

    for(a = 0; a < seats.size; a++)
    {
        if(!IsDefined(seats[a]))
            return false;

        seats[a] LinkTo(SeatsLinker[(a % 2 ? 0 : 1)]);
    }
    
    if(!IsDefined(MerryGoRoundLinker))
        return false;
    
    MerryGoRoundLinker thread RotateMerryYaw();

    array::thread_all(SeatsLinker, &RotateMerryYaw);
    array::thread_all(seats, &SeatSystem, "Merry Go Round");

    for(a = 0; a < SeatsLinker.size; a++)
    {
        if(IsDefined(SeatsLinker[a]))
        {
            SeatsLinker[a] thread SeatsMove(origin[2] + 45);
            wait 0.6;
        }
        else
        {
            return false;
        }
    }

    return true;
}

function RotateMerryYaw()
{
    level endon("Merry Go Round_Stop");

    while(IsDefined(self))
    {
        self RotateYaw(360, level.MerryGoRoundSpeed);
        wait level.MerryGoRoundSpeed;
    }
}

function SetMerryGoRoundSpeed(speed)
{
    speeds = Array(0, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
    level.MerryGoRoundSpeed = speeds[speed];

    if(Is_True(level.spawnable["Merry Go Round_Spawned"]))
        self iPrintlnBold("^1NOTE: ^7This Might Take A Few Seconds To Take Effect");
}

function SeatsMove(origin)
{
    self endon("death");
    level endon("Merry Go Round_Stop");

    while(IsDefined(self))
    {
        self MoveZ(((self.origin[2] > origin) ? -50 : 50), 0.65);
        wait 0.6;
    }
}

// ============================================================
// Functions/Spawnables/skybase.gsc
// ============================================================

function SpawnSkybase()
{
    if(Is_True(level.spawnable["Skybase_Spawned"]))
        return false;
    
    //These values control the size of the base
    x = 10;
    y = 5;

    //DON'T CHANGE THESE VALUES
    width = 51;
    height = 90;

    origin = GetSkybaseOriginForMap();
    model = GetSpawnableBaseModel("vending_doubletap");
    location = ((!IsVec(origin) || !IsDefined(level.SkybaseLocation)) ? "Custom" : level.SkybaseLocation);

    if(location == "Custom")
    {
        self closeMenu1();

        cancel = false;
        distance = 650;
        cfIndex = Int(Pow(2, RandomInt(3)));
        trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), distance), 0, self)["position"];

        goalPos = SpawnScriptModel(trace, "tag_origin");
        goalPos clientfield::set("powerup_fx", cfIndex);

        if(!IsDefined(goalPos))
            return false;

        self.DisableMenuControls = true;
        self SetMenuInstructions(Array("[{+attack}] - Increase Distance", "[{+speed_throw}] - Decrease Distance", "[{+activate}] - Confirm Location", "[{+melee}] - Cancel"));

        preview = [];

        for(a = 0; a < x; a++)
        {
            for(b = 0; b < y; b++)
            {
                preview[preview.size] = SpawnScriptModel(trace + ((a * width), (b * height), 0), "tag_origin", (0, 0, 0));

                if(IsDefined(preview[(preview.size - 1)]))
                {
                    preview[(preview.size - 1)] clientfield::set("powerup_fx", cfIndex);
                    preview[(preview.size - 1)] LinkTo(goalPos);
                }
                else
                {
                    return false;
                }

                wait 0.01;
            }
        }

        while(1)
        {
            if(!IsDefined(goalPos))
            {
                cancel = true;
                break;
            }
            
            trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), distance), 0, self)["position"];
            goalPos.origin = trace;

            if(self AttackButtonPressed())
            {
                distance += 25;
            }
            else if(self AdsButtonPressed())
            {
                distance -= 25;
            }
            else if(self UseButtonPressed())
            {
                origin = trace;
                break;
            }
            else if(self MeleeButtonPressed())
            {
                cancel = true;
                break;
            }

            if(distance < 100)
                distance = 100;
            else if(distance > 2500)
                distance = 2500;

            wait 0.01;
        }

        if(IsDefined(goalPos))
            goalPos Delete();
        
        if(IsDefined(preview) && preview.size)
        {
            for(a = 0; a < preview.size; a++)
            {
                if(IsDefined(preview[a]))
                    preview[a] Delete();
            }
        }
        
        if(Is_True(self.DisableMenuControls))
            self.DisableMenuControls = BoolVar(self.DisableMenuControls);
        
        self SetMenuInstructions();

        if(Is_True(cancel))
            return false;
    }

    if(!IsDefined(origin) || !IsVec(origin) || origin == (0, 0, 0))
        return false;
    
    level.SkybaseOrigin = origin;
    level.skybaseLinker = SpawnScriptModel(origin, "tag_origin");

    if(!IsDefined(level.skybaseLinker))
        return false;

    floor = [];
    roof = [];
    walls = [];
    corners = [];

    for(a = 0; a < x; a++)
    {
        for(b = 0; b < y; b++)
        {
            floor[floor.size] = SpawnScriptModel(origin + ((a * width), (b * height), 0), model, (0, 0, 90), 0.01);

            if(!IsDefined(floor[(floor.size - 1)]))
                return false;
            
            if(IsDefined(level.skybaseLinker))
                floor[(floor.size - 1)] LinkTo(level.skybaseLinker);
        }
    }

    array::thread_all(floor, &SpawnableArray, "Skybase");

    for(a = 0; a < x; a++)
    {
        for(b = 0; b < y; b++)
        {
            roof[roof.size] = SpawnScriptModel(origin + ((a * width), (b * height), (height + 35)), model, (180, 0, 90), 0.01);

            if(!IsDefined(roof[(roof.size - 1)]))
                return false;
            
            if(IsDefined(level.skybaseLinker))
                roof[(roof.size - 1)] LinkTo(level.skybaseLinker);
        }
    }

    array::thread_all(roof, &SpawnableArray, "Skybase");

    for(a = 0; a < 2; a++)
    {
        for(b = 0; b < y; b++)
        {
            walls[walls.size] = SpawnScriptModel(origin + (-25 + ((width * x) * a) + (10 * a), (b * height), 19), model, (90 - (180 * a), 0, 90), 0.01);

            if(!IsDefined(walls[(walls.size - 1)]))
                return false;
            
            if(IsDefined(level.skybaseLinker))
                walls[(walls.size - 1)] LinkTo(level.skybaseLinker);
        }
    }

    for(a = 0; a < 2; a++)
    {
        for(b = 0; b < (x - 4); b++)
        {
            walls[walls.size] = SpawnScriptModel(origin + (5 + width + (b * height), (height * -1) + ((height * y) * a), 19), model, (-90 + (180 * a), 0, 0 - (180 * a)), 0.01);

            if(!IsDefined(walls[(walls.size - 1)]))
                return false;
            
            if(IsDefined(level.skybaseLinker))
                walls[(walls.size - 1)] LinkTo(level.skybaseLinker);
        }
    }

    array::thread_all(walls, &SpawnableArray, "Skybase");

    for(a = 0; a < 2; a++)
    {
        for(b = 0; b < 2; b++)
        {
            corners[corners.size] = SpawnScriptModel(origin + (0 - (((25 * b) + (25 * a)) - ((50 * a) * b)), (height * -1) + (15 * b) + (((height * y) - 15) * a), 44), model, (0, 0 - ((b * 90) + (a * 90)), 0), 0.01);

            if(!IsDefined(corners[(corners.size - 1)]))
                return false;
            
            if(IsDefined(level.skybaseLinker))
                corners[(corners.size - 1)] LinkTo(level.skybaseLinker);
        }
    }

    for(a = 0; a < 2; a++)
    {
        for(b = 0; b < 2; b++)
        {
            corners[corners.size] = SpawnScriptModel(origin + ((width * (x - 1)) + (((36 * b) + (36 * a)) - ((72 * a) * b)), (height * -1) + (15 * b) + (((height * y) - 15) * a), 44), model, (0, 0 + ((b * 90) + (a * 90)), 0), 0.01);

            if(!IsDefined(corners[(corners.size - 1)]))
                return false;
            
            if(IsDefined(level.skybaseLinker))
                corners[(corners.size - 1)] LinkTo(level.skybaseLinker);
        }
    }

    array::thread_all(corners, &SpawnableArray, "Skybase");

    //SpawnProp(origin = (0, 0, 0), model = "defaultactor", angles = (0, 0, 0), bounce = true, glow = true, triggerFunction, hintString)
    bottle = SpawnProp(origin + (10, (55 * (y + 1)), 55), GetSpawnablePerkBottle(), (0, 0, 0), true, true, &SkybasePerkTrigger, "Press ^3[{+activate}]^7 For All Perks");

    if(!IsDefined(bottle))
        return false;

    level.skybaseProps = Array(bottle);
    array::thread_all(level.skybaseProps, &SpawnableArray, "Skybase");
    

    return true;
}

function SkybasePerkTrigger()
{
    MenuPerks = [];
    perks = GetArrayKeys(level._custom_perks);

    for(a = 0; a < perks.size; a++)
        array::add(MenuPerks, perks[a], 0);
    
    if(IsDefined(self.perks_active) && self.perks_active.size == MenuPerks.size)
        return;
    
    PlayerAllPerks(self);
}

function SpawnSkybaseTeleporter()
{
    if(Is_True(level.spawnable["Skybase_Building"]) || Is_True(level.spawnable["Skybase_Dismantle"]) || Is_True(level.spawnable["Skybase_Deleted"]) || !Is_True(level.spawnable["Skybase_Spawned"]))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use This Option Right Now");

    if(!IsDefined(level.SkybaseTeleporters) || !level.SkybaseTeleporters.size)
    {
        traceSurface = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self)["surfacetype"];

        if(traceSurface == "none" || traceSurface == "default")
            return self iPrintlnBold("^1ERROR: ^7Invalid Surface");

        crosshairs = self TraceBullet();
        level.SkybaseTeleporters = [];

        for(a = 0; a < 2; a++) level.SkybaseTeleporters[level.SkybaseTeleporters.size] = SpawnTeleporter("Spawn", (a ? (level.SkybaseOrigin + (20, -45, 45)) : (crosshairs + (0, 0, 45))), !a, true);
    }
    else
    {
        foreach(teleporter in level.SkybaseTeleporters)
            teleporter Delete();

        level.SkybaseTeleporters = undefined;
    }
}

function SkybaseLocation(location)
{
    level.SkybaseLocation = location;
}

function GetSkybaseOriginForMap()
{
    map = ReturnMapName();

    switch(map)
    {
        case "Shadows Of Evil":
            return (2546, -5263, 450);

        case "The Giant":
            return (-230, -515, 522);
        
        case "Der Eisendrache":
            return (-754, 342, 877);

        case "Zetsubou No Shima":
            return (3407, 1277, -475);
        
        case "Gorod Krovi":
            return (-218, -803, 216);

        case "Revelations":
            return (271, -864, -272);

        case "Nacht Der Untoten":
            return (1182, 572, 296);

        case "Verruckt":
            return (16, -69, 308);

        case "Shi No Numa":
            return (10165, 974, -268);

        case "Kino Der Toten":
            return (-360, 328, 239);

        case "Ascension":
            return (-2461, 1682, 361);

        case "Shangri-La":
            return (-2401, -1066, -162);

        case "Moon":
            return (21835, -37689, -529);

        case "Origins":
            return (294.5, 1213, 557);
        
        default:
            return "invalid";
    }
}

function MoveSkybase(amount = 0, axis = "X")
{
    if(Is_True(level.spawnable["Skybase_Building"]))
        return self iPrintlnBold("^1ERROR: ^7You Can't Move The Skybase While It's Being Built");
    
    if(!Is_True(level.spawnable["Skybase_Spawned"]))
        return self iPrintlnBold("^1ERROR: ^7The Skybase Hasn't Been Spawned Yet");
    
    if(Is_True(level.spawnable["Skybase_Dismantle"]) || Is_True(level.spawnable["Skybase_Deleted"]))
        return self iPrintlnBold("^1ERROR: ^7You Can't Move The Skybase Right Now");
    
    if(!IsDefined(level.skybaseLinker))
        return self iPrintlnBold("^1ERROR: ^7Failed To Move Skybase");
    
    switch(axis)
    {
        case "X":
            level.skybaseLinker.origin += (amount, 0, 0);

            if(IsDefined(level.SkybaseOrigin))
                level.SkybaseOrigin += (amount, 0, 0);

            for(a = 0; a < level.skybaseProps.size; a++)
            {
                if(IsDefined(level.skybaseProps[a]))
                {
                    level.skybaseProps[a].origin += (amount, 0, 0);

                    if(IsDefined(level.skybaseProps[a].original_origin) && IsVec(level.skybaseProps[a].original_origin))
                        level.skybaseProps[a].original_origin += (amount, 0, 0);
                }
            }
            break;
        
        case "Y":
            level.skybaseLinker.origin += (0, amount, 0);

            if(IsDefined(level.SkybaseOrigin))
                level.SkybaseOrigin += (0, amount, 0);

            for(a = 0; a < level.skybaseProps.size; a++)
            {
                if(IsDefined(level.skybaseProps[a]))
                {
                    level.skybaseProps[a].origin += (0, amount, 0);

                    if(IsDefined(level.skybaseProps[a].original_origin) && IsVec(level.skybaseProps[a].original_origin))
                        level.skybaseProps[a].original_origin += (0, amount, 0);
                }
            }
            break;
        
        case "Z":
            level.skybaseLinker.origin += (0, 0, amount);

            if(IsDefined(level.SkybaseOrigin))
                level.SkybaseOrigin += (0, 0, amount);

            for(a = 0; a < level.skybaseProps.size; a++)
            {
                if(IsDefined(level.skybaseProps[a]))
                {
                    level.skybaseProps[a].origin += (0, 0, amount);

                    if(IsDefined(level.skybaseProps[a].original_origin) && IsVec(level.skybaseProps[a].original_origin))
                        level.skybaseProps[a].original_origin += (0, 0, amount);
                }
            }
            break;
        
        default:
            break;
    }
}

// ============================================================
// Functions/Spawnables/spawnable_system.gsc
// ============================================================

function PopulateSpawnables(menu)
{
    switch(menu)
    {
        case "Spawnables":
            if(!IsDefined(level.spawnable))
                level.spawnable = [];

            self addMenu(menu);
                self addOpt("Rain Options", &newMenu, "Rain Options");
                self addOpt("Small Spawnables", &newMenu, "Small Spawnables");
                self addOpt("Large Spawnables", &newMenu, "Large Spawnables");
            break;
        
        case "Rain Options":
            self addMenu(menu);
                self addOpt("Disable", &DisableLobbyRain);
                self addOpt("Models", &newMenu, "Rain Models");
                self addOpt("Effects", &newMenu, "Rain Effects");
                self addOpt("Projectiles", &newMenu, "Rain Projectiles");

                if(IsDefined(level.zombie_include_powerups) && level.zombie_include_powerups.size)
                    self addOptBool(level.RainPowerups, "Rain Power-Ups", &RainPowerups);
            break;
        
        case "Rain Models":
            self addMenu("Models");

                if(IsDefined(level.menu_models) && level.menu_models.size)
                {
                    for(a = 0; a < level.menu_models.size; a++)
                    {
                        isCurrent = IsDefined(level.LobbyRainType) && level.LobbyRainType == "Model" && IsDefined(level.LobbyRain) && level.LobbyRain == level.menu_models[a];
                        self addOptBool(isCurrent, CleanString(level.menu_models[a]), &LobbyRain, "Model", level.menu_models[a]);
                    }
                }
            break;
        
        case "Rain Effects":
            self addMenu("Effects");

                for(a = 0; a < level.menuFX.size; a++)
                {
                    isCurrent = IsDefined(level.LobbyRainType) && level.LobbyRainType == "FX" && IsDefined(level.LobbyRain) && level.LobbyRain == level.menuFX[a];
                    self addOptBool(isCurrent, CleanString(level.menuFX[a]), &LobbyRain, "FX", level.menuFX[a]);
                }
            break;
        
        case "Rain Projectiles":
            self addMenu("Projectiles");

                if(!IsVerkoMap())
                {
                    arr = [];
                    weaponsVar = Array("assault", "smg", "lmg", "sniper", "cqb", "pistol", "launcher", "special");
                    weaps = GetArrayKeys(level.zombie_weapons);

                    if(IsDefined(weaps) && weaps.size)
                    {
                        for(a = 0; a < weaps.size; a++)
                        {
                            if(IsInArray(weaponsVar, ToLower(CleanString(zm_utility::GetWeaponClassZM(weaps[a])))) && !weaps[a].isgrenadeweapon && !IsSubStr(weaps[a].name, "knife") && weaps[a].name != "none")
                            {
                                strn = ((MakeLocalizedString(weaps[a].displayname) != "") ? weaps[a].displayname : weaps[a].name);
                                
                                if(!IsInArray(arr, strn))
                                {
                                    arr[arr.size] = strn;
                                    isCurrent = IsDefined(level.LobbyRainType) && level.LobbyRainType == "Projectile" && IsDefined(level.LobbyRain) && level.LobbyRain == weaps[a];

                                    self addOptBool(isCurrent, strn, &LobbyRain, "Projectile", weaps[a]);
                                }
                            }
                        }
                    }
                }
                else
                {
                    for(a = 0; a < level.var_21b77150.size; a++)
                        self addOpt(level.var_7df703ba[a], &LobbyRain, "Projectile", GetWeapon(level.var_21b77150[a]));
                }
            break;
        
        case "Small Spawnables":
            self addMenu(menu);
                self addOptBool(level.TornadoSpawned, "Tornado", &Tornado);
                self addOptIncSlider("Mexican Wave", &MexicanWave, 2, 2, 15, 1);
                self addOptIncSlider("Spiral Staircase", &SpiralStaircase, 5, 5, 50, 1);
                self addOptSlider("Teleporter", &SpawnTeleporter, Array("Spawn", "Delete All"));
            break;
        
        case "Large Spawnables":
            self addMenu(menu);
                self addOpt("Skybase", &newMenu, "Skybase");
                self addOptSlider("Drop Tower", &SpawnSystem, Array("Spawn", "Dismantle", "Delete"), "Drop Tower", &SpawnDropTower);
                self addOptSlider("Merry Go Round", &SpawnSystem, Array("Spawn", "Dismantle", "Delete"), "Merry Go Round", &SpawnMerryGoRound);

                if(IsDefined(level.spawnable["Merry Go Round_Spawned"]))
                    self addOptIncSlider("Merry Go Round Speed", &SetMerryGoRoundSpeed, 1, 1, 10, 1);
            break;
        
        case "Skybase":
            self addMenu(menu);

                /*
                This was used for getting the pre-set locations for the skybase
                I left it here and commented it out in case anyone wants to make changes to the locations
                The origin doesn't auto-update in the menu, so you will need to exit the skybase submenu and reenter it to see the new origin if/when changed
                
                origin = IsDefined(level.SkybaseOrigin) ? level.SkybaseOrigin : (0, 0, 0);
                self addOpt("Origin: " + origin);
                */

                baseOrigin = GetSkybaseOriginForMap();
                
                if(!IsDefined(level.SkybaseLocation)) level.SkybaseLocation = (IsVec(baseOrigin) ? "Pre-Set" : "Custom");

                self addOptSlider("Skybase", &SpawnSystem, Array("Spawn", "Dismantle", "Delete"), "Skybase", &SpawnSkybase);
                self addOptSlider("Location", &SkybaseLocation, (IsVec(baseOrigin) ? Array("Pre-Set", "Custom") : Array("Custom")));
                self addOptBool((IsDefined(level.SkybaseTeleporters) && level.SkybaseTeleporters.size), "Spawn Skybase Teleporter", &SpawnSkybaseTeleporter);
                
                self addOpt("");
                self addOptIncSlider("Move X", &MoveSkybase, -25, 0, 25, 1, "X");
                self addOptIncSlider("Move Y", &MoveSkybase, -25, 0, 25, 1, "Y");
                self addOptIncSlider("Move Z", &MoveSkybase, -25, 0, 25, 1, "Z");
            break;
    }
}

function SpawnSystem(action, type, func)
{
    checkModel = GetSpawnableBaseModel();

    if(!IsDefined(checkModel))
        return self iPrintlnBold("^1ERROR: ^7Couldn't Find A Valid Base Model For Spawnables");

    if(!IsDefined(level.spawnable))
        level.spawnable = [];

    if(Is_True(level.spawnable[type + "_Building"]))
        return self iPrintlnBold("^1ERROR: ^7" + CleanString(type) + " Is Being Built");

    if(Is_True(level.spawnable[type + "_Dismantle"]))
        return self iPrintlnBold("^1ERROR: ^7" + CleanString(type) + " Is Being Dismantled");

    if(Is_True(level.spawnable[type + "_Deleted"]))
        return self iPrintlnBold("^1ERROR: ^7" + CleanString(type) + " Is Being Deleted");

    if(!Is_True(level.spawnable[type + "_Spawned"]) && type != "Skybase")
    {
        traceSurface = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self)["surfacetype"];

        if(traceSurface == "none" || traceSurface == "default")
            return self iPrintlnBold("^1ERROR: ^7Invalid Surface");
    }

    if(action != "Spawn")
    {
        if(!Is_True(level.spawnable[type + "_Spawned"]))
            return self iPrintlnBold("^1ERROR: ^7" + CleanString(type) + " Hasn't Been Spawned Yet");
    }
    else
    {
        if(IsDefined(level.spawnable["LargeSpawnable"]) && isLargeSpawnable(type))
            return self iPrintlnBold("^1ERROR: ^7You Must Delete The " + level.spawnable["LargeSpawnable"] + " First");

        if(Is_True(level.spawnable[type + "_Spawned"]))
            return self iPrintlnBold("^1ERROR: ^7" + CleanString(type) + " Has Already Been Spawned");
    }

    if(IsDefined(level.SpawnableSystemBusy))
        return self iPrintlnBold("^1ERROR: ^7The Spawnable System Is Currently Busy");

    level.SpawnableSystemBusy = type;

    menu = self getCurrent();
    curs = self getCursor();

    if(!IsDefined(level.SpawnableArray))
        level.SpawnableArray = [];
    
    if(!IsDefined(level.SpawnableArray[type]))
        level.SpawnableArray[type] = [];

    switch(action)
    {
        case "Spawn":
            if(isLargeSpawnable(type))
                level.spawnable["LargeSpawnable"] = type;

            level.spawnable[type + "_Building"] = true;

            if(IsDefined(func) && IsFunctionPtr(func))
                built = self [[ func ]]();
            
            if(Is_True(level.spawnable[type + "_Building"]))
                level.spawnable[type + "_Building"] = BoolVar(level.spawnable[type + "_Building"]);
            
            if(!IsDefined(func) || !IsFunctionPtr(func) || !Is_True(built))
            {
                DeleteSpawnable(type, "Delete");
                self iPrintlnBold("^1ERROR: ^7Failed To Spawn " + type);
            }
            else
            {
                level.spawnable[type + "_Spawned"] = true;
            }

            break;

        case "Delete":
            DeleteSpawnable(type, action);
            break;

        case "Dismantle":
            if(IsDefined(level.SpawnableArray[type]) && level.SpawnableArray[type].size)
            {
                for(a = 0; a < level.SpawnableArray[type].size; a++)
                {
                    if(!IsDefined(level.SpawnableArray[type][a]))
                        continue;

                    if(Is_True(level.SpawnableArray[type][a].propActivated))
                        level.SpawnableArray[type][a].propActivated = false;
                    
                    level.SpawnableArray[type][a] NotSolid();
                    level.SpawnableArray[type][a] Unlink();
                    level.SpawnableArray[type][a] Launch(VectorScale(AnglesToForward(level.SpawnableArray[type][a].angles), RandomIntRange(-255, 255)));
                }
            }

            if(type == "Skybase")
            {
                if(IsDefined(level.SkybaseTeleporters) && level.SkybaseTeleporters.size)
                {
                    for(a = 0; a < level.SkybaseTeleporters.size; a++)
                    {
                        if(!IsDefined(level.SkybaseTeleporters[a]))
                            continue;

                        level.SkybaseTeleporters[a] Unlink();
                        level.SkybaseTeleporters[a] Launch(VectorScale(AnglesToForward(level.SkybaseTeleporters[a].angles), RandomIntRange(-255, 255)));
                    }
                }
            }

            DeleteSpawnable(type, action);
            break;

        default:
            break;
    }

    level.SpawnableSystemBusy = undefined;
    RefreshMenu(menu, curs);
}

function DeleteSpawnable(spawn, type)
{
    level notify(spawn + "_Stop");

    if(!IsDefined(level.spawnable))
        level.spawnable = [];

    if(!IsDefined(level.SpawnableArray))
        level.SpawnableArray = [];
    
    if(!IsDefined(level.SpawnableArray[type]))
        level.SpawnableArray[type] = [];

    if(isLargeSpawnable(spawn))
    {
        foreach(player in level.players)
        {
            if(Is_True(player.OnSpawnable))
                player StopRidingSpawnable(spawn);
        }
    }

    level.spawnable[spawn + "_" + type] = true;

    if(type == "Dismantle")
        wait 5;

    if(IsDefined(level.SpawnableArray) && IsDefined(level.SpawnableArray[spawn]) && level.SpawnableArray[spawn].size)
    {
        for(a = 0; a < level.SpawnableArray[spawn].size; a++)
        {
            if(IsDefined(level.SpawnableArray[spawn][a]))
                level.SpawnableArray[spawn][a] Delete();
        }
    }

    if(spawn == "Skybase")
    {
        if(IsDefined(level.SkybaseTeleporters) && level.SkybaseTeleporters.size)
        {
            for(a = 0; a < level.SkybaseTeleporters.size; a++)
            {
                if(!IsDefined(level.SkybaseTeleporters[a]))
                    continue;

                level.SkybaseTeleporters[a] Delete();
            }

            level.SkybaseTeleporters = undefined;
        }
    }

    //after delete
    level.SpawnableArray[spawn] = undefined;

    if(Is_True(level.spawnable[spawn + "_" + type]))
        level.spawnable[spawn + "_" + type] = BoolVar(level.spawnable[spawn + "_" + type]);

    if(Is_True(level.spawnable[spawn + "_Spawned"]))
        level.spawnable[spawn + "_Spawned"] = BoolVar(level.spawnable[spawn + "_Spawned"]);

    if(isLargeSpawnable(spawn))
        level.spawnable["LargeSpawnable"] = undefined;
}

function isLargeSpawnable(type)
{
    spawns = Array("Skybase", "Merry Go Round", "Drop Tower");
    return isInArray(spawns, type);
}

function SpawnableArray(spawn)
{
    if(!IsDefined(self) || !IsDefined(spawn))
        return;

    if(!IsDefined(level.SpawnableArray))
        level.SpawnableArray = [];

    if(!IsDefined(level.SpawnableArray[spawn]))
        level.SpawnableArray[spawn] = [];

    level.SpawnableArray[spawn][level.SpawnableArray[spawn].size] = self;
}

function SeatSystem(type)
{
    if(!IsDefined(type) || !IsDefined(self))
        return;

    level endon(type + "_Stop");

    self MakeUsable();
    self SetCursorHint("HINT_NOICON");
    self SetHintString("Press [{+activate}] To Ride The " + type);

    while(IsDefined(self))
    {
        self waittill("trigger", player);

        if(IsDefined(self.Rider) && player == self.Rider)
        {
            player StopRidingSpawnable(type, self);
            wait 1;

            continue;
        }

        if(IsDefined(self.Rider) || Is_True(player.OnSpawnable) || player isPlayerLinked(self))
            continue;

        player.SpawnableSavedOrigin = player.origin;
        player.SpawnableSavedAngles = player.angles;

        switch(type)
        {
            case "Merry Go Round":
                player PlayerLinkTo(self);
                break;

            case "Drop Tower":
                player PlayerLinkToAbsolute(self);
                break;

            default:
                player PlayerLinkTo(self);
                break;
        }

        player.OnSpawnable = true;
        self.Rider = player;

        self SetHintString("Press [{+activate}] To Exit The " + type);
        wait 1;
    }
}

function StopRidingSpawnable(type, seat)
{
    self Unlink();
    self SetOrigin(self.SpawnableSavedOrigin);
    self SetPlayerAngles(self.SpawnableSavedAngles);

    if(IsDefined(seat))
    {
        seat.Rider = undefined;
        seat SetHintString("Press [{+activate}] To Ride The " + type);
    }

    if(Is_True(self.OnSpawnable))
        self.OnSpawnable = BoolVar(self.OnSpawnable);
}

function GetSpawnableBaseModel(favor)
{
    if(!IsDefined(level.menu_models) || !level.menu_models.size)
        return "defaultactor";
    
    //This will be a fallback for maps that don't have the favored models for spawnables
    for(a = 0; a < level.menu_models.size; a++)
    {
        if(IsDefined(level.menu_models[a]) && IsSubStr(level.menu_models[a], "vending_") && !IsSubStr(level.menu_models[a], "upgrade") && !IsSubStr(level.menu_models[a], "packapunch"))
            model = level.menu_models[a];
    }
    
    for(a = 0; a < level.menu_models.size; a++)
    {
        if(!IsSubStr(level.menu_models[a], "web_") && (IsSubStr(level.menu_models[a], "vending_doubletap") || IsSubStr(level.menu_models[a], "vending_sleight") || IsSubStr(level.menu_models[a], "vending_three_gun")))
        {
            model = level.menu_models[a];

            if(IsDefined(favor) && IsDefined(model) && (model == favor || IsSubStr(model, favor)))
                return model;
        }
    }

    if(!IsDefined(model)) //If a model still isn't found after this, then spawnbales won't be available for the map
    {
        for(a = 0; a < level.menu_models.size; a++)
        {
            if(IsDefined(level.menu_models[a]) && IsSubStr(level.menu_models[a], "machine"))
                model = level.menu_models[a];
        }
    }

    return model;
}

function GetSpawnablePerkBottle()
{
    for(a = 0; a < level.menu_models.size; a++)
    {
        if(IsDefined(level.menu_models[a]) && IsSubStr(level.menu_models[a], "perk_bottle") && !IsSubStr(level.menu_models[a], "broken"))
            return level.menu_models[a];
    }

    //If there is no perk bottle found on the map, then we will just use the insta-kill model..if that isn't found, it will fallback to defaultactor
    return ((IsDefined(level.zombie_powerups) && IsDefined(level.zombie_powerups["insta_kill"])) ? level.zombie_powerups["insta_kill"].model_name : "defaultactor");
}





//Rain Options
function DisableLobbyRain(includePowerups = true)
{
    level notify("EndLobbyRain");

    if(Is_True(includePowerups))
        level.RainPowerups = undefined;
    
    level.LobbyRain = undefined;
    level.LobbyRainType = undefined;
}

function LobbyRain(type, rain)
{
    if(IsDefined(level.LobbyRain) && IsDefined(level.LobbyRainType) && level.LobbyRainType == type && level.LobbyRain == rain)
        return DisableLobbyRain(false);

    level notify("EndLobbyRain");
    level endon("EndLobbyRain");

    level.LobbyRain = rain;
    level.LobbyRainType = type;
    
    while(1)
    {
        player = bot::get_host_player();

        if(!IsDefined(player) || !Is_Alive(player))
        {
            foreach(client in level.players)
            {
                if(!IsDefined(client) || !Is_Alive(client))
                    continue;
                
                player = client;
                break;
            }
        }

        origin = (player.origin + (RandomIntRange(-2500, 2500), RandomIntRange(-2500, 2500), RandomIntRange(750, 3000)));

        switch(type)
        {
            case "Projectile":
                MagicBullet(rain, origin, (origin + (0, 0, -1000)));
                break;
            
            case "Model":
                RainModel = SpawnScriptModel(origin, rain);

                if(!IsDefined(RainModel))
                    break;
                
                RainModel NotSolid();
                RainModel Launch(VectorScale(AnglesToForward(RainModel.angles), 10));
                RainModel thread deleteAfter(10);
                break;
            
            case "FX":
                linker = SpawnScriptModel(origin, "tag_origin");

                if(!IsDefined(linker))
                    break;
                
                linker thread RainPlayFXOnTag(level._effect[rain], "tag_origin");
                linker Launch(VectorScale(AnglesToForward(linker.angles), 10));
                linker thread deleteAfter(10);
                break;
            
            default:
                break;
        }
        
        wait ((type == "Model") ? 0.1 : 0.05);
    }
}

function RainPlayFXOnTag(FX, tag)
{
    while(IsDefined(self))
    {
        PlayFXOnTag(FX, self, tag);
        wait 0.5;
    }
}

function RainPowerups()
{
    level.RainPowerups = BoolVar(level.RainPowerups);

    while(Is_True(level.RainPowerups))
    {
        player = bot::get_host_player();

        if(!IsDefined(player) || !Is_Alive(player))
        {
            foreach(client in level.players)
            {
                if(!IsDefined(client) || !Is_Alive(client))
                    continue;
                
                player = client;
                break;
            }
        }

        powerup = level CustomPowerupSpawn(GetArrayKeys(level.zombie_include_powerups)[RandomInt(level.zombie_include_powerups.size)], player.origin + (RandomIntRange(-1000, 1000), RandomIntRange(-1000, 1000), RandomIntRange(750, 2000)));
        
        if(IsDefined(powerup))
            powerup PhysicsLaunch(powerup.origin, (RandomIntRange(-5, 5), RandomIntRange(-5, 5), RandomIntRange(-5, 5)));

        wait 0.05;
    }
}

function CustomPowerupSpawn(powerup_name, drop_spot)
{
    powerup = zm_net::network_safe_spawn("powerup", 1, "script_model", drop_spot);

    if(IsDefined(powerup))
    {
        powerup zm_powerups::powerup_setup(powerup_name);

        if(!IsDefined(powerup))
            return;

        if(isInArray(level.active_powerups, powerup))
            level.active_powerups = ArrayRemove(level.active_powerups, powerup);

        powerup thread custom_powerup_timeout();
        powerup thread zm_powerups::powerup_grab();
        powerup thread zm_powerups::powerup_wobble_fx();

        return powerup;
    }
}

function custom_powerup_timeout()
{
    wait 5;

    if(!IsDefined(self))
        return;
    
    self notify("powerup_timedout");
    self zm_powerups::powerup_delete();
}








//Small Spawnables
function Tornado()
{
    if(!Is_True(level.TornadoSpawned))
    {
        trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);
        
        origin = trace["position"];
        surface = trace["surfacetype"];

        if(IsDefined(surface) && (surface == "none" || surface == "default"))
            return self iPrintlnBold("^1ERROR: ^7Invalid Surface");
    }
    else
    {
        if(!IsDefined(level.SpawnableArray["Tornado"]) || !level.SpawnableArray["Tornado"].size)
            return;
        
        for(a = 0; a < level.SpawnableArray["Tornado"].size; a++)
        {
            if(IsDefined(level.SpawnableArray["Tornado"][a]))
                level.SpawnableArray["Tornado"][a] Delete();
        }
        
        level notify("Tornado_Stop");
        level.TornadoSpawned = BoolVar(level.TornadoSpawned);
        return;
    }

    level endon("Tornado_Stop");
    level.TornadoSpawned = true;
    
    TornadoParts = [];
    level.tornadoTime = 0;
    
    TornadoParts[0] = SpawnScriptModel(origin, "tag_origin");
    TornadoParts[0] SpawnableArray("Tornado");
    color = Int(Pow(2, RandomInt(3)));

    for(a = 1; a < 15; a++)
    {
        for(b = 0; b < (a + 2); b++)
        {
            TornadoParts[TornadoParts.size] = SpawnScriptModel(TornadoParts[0].origin + (Cos((b * 360) / (a + 2)) * (a * 6), Sin((b * 360) / (a + 2)) * (a * 6), (a * 18)), "tag_origin");
            
            TornadoParts[(TornadoParts.size - 1)] LinkTo(TornadoParts[0]);
            TornadoParts[(TornadoParts.size - 1)] SpawnableArray("Tornado");
            TornadoParts[(TornadoParts.size - 1)] clientfield::set("powerup_fx", color);
            wait 0.01;
        }
    }

    TornadoParts[0] thread TornadoMovement(TornadoParts[0].origin);
    level thread TornadoWatchEntities(TornadoParts);
}

function TornadoMovement(defaultOrigin)
{
    level endon("Tornado_Stop");
    self endon("EndTornadoMovement");
    
    while(IsDefined(self))
    {
        self zm_utility::create_zombie_point_of_interest(5000, 255, 10000, 1);
        self MoveTo(self.origin + (RandomIntRange(-100, 100), RandomIntRange(-100, 100), 0), 3);
        self RotateYaw(360, 3);
        wait 3;
    
        if(!IsDefined(self))
            break;

        if(Distance(defaultOrigin, self.origin) >= 750)
        {
            self MoveTo(defaultOrigin, 3);
            self RotateYaw(360, 3);

            wait 3;
        }
    }
}

function TornadoWatchEntities(TornadoParts)
{
    level endon("Tornado_Stop");

    wait 3;

    while(1)
    {
        if(!IsDefined(TornadoParts) || !TornadoParts.size)
            break;
        
        foreach(entity in GetEntArray("script_model", "classname"))
        {
            if(!IsDefined(entity) || isInArray(TornadoParts, entity) || Is_True(entity.OnTornado) || entity.model == "tag_origin")
                continue;
            
            for(a = 1; a < TornadoParts.size; a++)
            {
                if(IsDefined(TornadoParts[a]) && Distance(TornadoParts[a].origin, entity.origin) <= 100)
                {
                    entity thread TornadoLaunchEntity(a, TornadoParts);
                    break;
                }
            }
        }

        foreach(player in level.players)
        {
            if(!IsDefined(player) || !Is_Alive(player) || player isPlayerLinked() || Is_True(player.OnTornado))
                continue;
            
            for(a = 1; a < TornadoParts.size; a++)
            {
                if(IsDefined(TornadoParts[a]) && Distance(TornadoParts[a].origin, player.origin) <= 100)
                {
                    player thread TornadoLaunchPlayer(a, TornadoParts);
                    break;
                }
            }
        }
        
        foreach(zombie in GetAITeamArray(level.zombie_team))
        {
            if(!IsDefined(zombie) || !IsAlive(zombie) || Is_True(zombie.OnTornado))
                continue;
            
            for(a = 1; a < TornadoParts.size; a++)
            {
                if(IsDefined(TornadoParts[a]) && Distance(TornadoParts[a].origin, zombie.origin) <= 100)
                {
                    zombie thread TornadoLaunchZombie(a, TornadoParts);
                    break;
                }
            }
        }

        wait 0.01;
    }
}

function TornadoLaunchPlayer(a, TornadoParts)
{
    if(!IsDefined(self) || !Is_Alive(self))
        return;
    
    level endon("Tornado_Stop");
    self endon("disconnect");

    self.OnTornado = true;

    for(b = a; b < TornadoParts.size; b++)
    {
        if(!IsDefined(self) || !Is_Alive(self))
            break;
        
        if(IsDefined(TornadoParts[b]) && b % 2)
        {
            self PlayerLinkTo(TornadoParts[b], "tag_origin");
            wait 0.025;
        }
    }

    if(!IsDefined(self) || !Is_Alive(self))
        return;

    self Unlink();

    if(self IsOnGround())
        self SetOrigin(self.origin + (0, 0, 5));

    self SetVelocity(AnglesToForward(self GetPlayerAngles()) * 3500);
    wait 1;

    if(!IsDefined(self) || !Is_Alive(self))
        return;

    if(Is_True(self.OnTornado))
        self.OnTornado = BoolVar(self.OnTornado);
}

function TornadoLaunchZombie(a, TornadoParts)
{
    if(!IsDefined(self) || !IsAlive(self))
        return;
    
    level endon("Tornado_Stop");

    self.OnTornado = true;

    for(b = a; b < TornadoParts.size; b++)
    {
        if(!IsDefined(self) || !IsAlive(self))
            break;
        
        if(IsDefined(TornadoParts[b]) && b % 2)
        {
            self ForceTeleport(TornadoParts[b].origin);
            self LinkTo(TornadoParts[b]);

            wait 0.025;
        }
    }
    
    if(!IsDefined(self) || !IsAlive(self))
        return;

    linker = SpawnScriptModel(self.origin, "tag_origin");
    self LinkTo(linker, "tag_origin");
    linker Launch(AnglesToForward(self.angles) * 3500);
    wait 1;

    if(!IsDefined(self) || !IsAlive(self))
        return;

    if(IsDefined(linker))
        linker Delete();
    
    if(Is_True(self.OnTornado))
        self.OnTornado = BoolVar(self.OnTornado);
}

function TornadoLaunchEntity(a, TornadoParts)
{
    if(!IsDefined(self))
        return;
    
    self.OnTornado = true;

    for(b = a; b < TornadoParts.size; b++)
    {
        if(!IsDefined(self))
            break;
        
        if(b % 2 && IsDefined(TornadoParts[b]))
        {
            self.origin = TornadoParts[b].origin;
            self LinkTo(TornadoParts[b]);

            wait 0.025;
        }
    }

    if(!IsDefined(self))
        return;

    self Unlink();
    self Launch(AnglesToForward(self.angles) * 5500);
    wait 1;

    if(!IsDefined(self))
        return;

    if(Is_True(self.OnTornado))
        self.OnTornado = BoolVar(self.OnTornado);
}

function MexicanWave(size = 0)
{
    if(Is_True(self.MexicanWaveSpawning) && size > 0)
        return self iPrintlnBold("^1ERROR: Mexican Wave Is Currently Spawning");

    if(IsDefined(self.MexicanWave) && self.MexicanWave.size || size < 1)
    {
        if(IsDefined(self.MexicanWave) && self.MexicanWave.size)
        {
            for(a = 0; a < self.MexicanWave.size; a++)
            {
                if(IsDefined(self.MexicanWave[a]))
                    self.MexicanWave[a] Delete();
            }
        }
        
        self.MexicanWaveSpawning = undefined;
        self.MexicanWave = undefined;
        return;
    }

    trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);
    origin = trace["position"];
    surface = trace["surfacetype"];

    if(IsDefined(surface) && (surface == "none" || surface == "default"))
        return self iPrintlnBold("^1ERROR: ^7Invalid Surface");
    
    self.MexicanWave = [];
    angles = self GetPlayerAngles();
    self.MexicanWaveSpawning = true;

    for(a = 0; a < size; a++)
    {
        self.MexicanWave[self.MexicanWave.size] = SpawnScriptModel(origin + (AnglesToRight(angles) * (a * 45)), "defaultactor", (0, angles[1], 0));

        if(!IsDefined(self.MexicanWave[(self.MexicanWave.size - 1)]))
        {
            self MexicanWave(0);
            self iPrintlnBold("^1ERROR: ^7Mexican Wave Failed To Spawn");
            break;
        }

        self.MexicanWave[(self.MexicanWave.size - 1)] thread MexicanWaveMove(a);
        wait 0.1;
    }

    self.MexicanWaveSpawning = undefined;
}

function MexicanWaveMove(index)
{
    wait (index * 0.2);

    while(IsDefined(self))
    {
        self MoveZ(55, 0.75);
        wait 0.74;

        if(IsDefined(self))
            self MoveZ(-55, 0.75);
        
        wait 0.74;
    }
}

function SpiralStaircase(size)
{
    if(Is_True(level.SpiralStaircaseSpawning) && size > 0)
        return self iPrintlnBold("^1ERROR: ^7Spiral Staircase Is Being Built");
    
    if(Is_True(level.SpiralStaircaseDeleting))
        return self iPrintlnBold("^1ERROR: ^7Spiral Staircase Is Being Deleted");
    
    if(IsDefined(level.SpiralStaircase) && level.SpiralStaircase.size || size < 1)
    {
        level.SpiralStaircaseSpawning = undefined;
        level.SpiralStaircaseDeleting = true;

        if(IsDefined(level.SpiralStaircase) && level.SpiralStaircase.size)
        {
            for(a = 0; a < level.SpiralStaircase.size; a++)
            {
                if(IsDefined(level.SpiralStaircase[a]))
                {
                    level.SpiralStaircase[a] Launch(VectorScale(AnglesToForward(level.SpiralStaircase[a].angles), 255));
                    level.SpiralStaircase[a] NotSolid();
                    level.SpiralStaircase[a] thread deleteAfter(5);

                    wait 0.01;
                }
            }
        }
        
        wait 5;
        level.SpiralStaircase = [];
        level.SpiralStaircaseDeleting = undefined;
    }
    else
    {
        model = GetSpawnableBaseModel();
        trace = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self);

        if(!isInArray(level.menu_models, model))
            return self iPrintlnBold("^1ERROR: ^7Couldn't Find A Valid Base Model For The Spiral Staircase");
    
        origin = trace["position"];
        surface = trace["surfacetype"];

        if(IsDefined(surface) && (surface == "none" || surface == "default"))
            return self iPrintlnBold("^1ERROR: ^7Invalid Surface");
        
        level.SpiralStaircaseSpawning = true;

        if(!IsDefined(level.SpiralStaircase))
            level.SpiralStaircase = [];
        
        level.SpiralStaircase[0] = SpawnScriptModel(origin, model, (-28, self GetPlayerAngles()[1], 90));
        
        for(a = 1; a < size; a++)
        {
            if(!IsDefined(level.SpiralStaircase[(level.SpiralStaircase.size - 1)]))
            {
                self iPrintlnBold("^1ERROR: ^7Spiral Staircase Failed To Spawn");
                self SpiralStaircase(0);
                return;
            }
            
            level.SpiralStaircase[level.SpiralStaircase.size] = SpawnScriptModel((level.SpiralStaircase[(level.SpiralStaircase.size - 1)].origin + (AnglesToForward(level.SpiralStaircase[(level.SpiralStaircase.size - 1)].angles) * 10) + (0, 0, 8)), model, (level.SpiralStaircase[0].angles[0], (level.SpiralStaircase[(level.SpiralStaircase.size - 1)].angles[1] + 12), level.SpiralStaircase[0].angles[2]), 0.01);
        }

        level.SpiralStaircaseSpawning = undefined;
    }
}

function SpawnTeleporter(action = "Spawn", origin, skipLink = false, skipDelete = false)
{
    if(IsDefined(action) && action == "Delete All")
    {
        DeleteTeleporters();
        return;
    }

    if(!IsDefined(origin))
    {
        traceSurface = BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self)["surfacetype"];

        if(traceSurface == "none" || traceSurface == "default")
            return self iPrintlnBold("^1ERROR: ^7Invalid Surface");
        
        origin = self TraceBullet() + (0, 0, 45);
    }

    linker = SpawnScriptModel(origin, "tag_origin");
    linker thread AddActiveTeleporter(skipLink, skipDelete);

    return linker;
}

function DeleteTeleporters()
{
    if(!IsDefined(level.ActiveTeleporters) || !level.ActiveTeleporters.size)
        return;
    
    foreach(teleporter in level.ActiveTeleporters)
    {
        if(IsDefined(teleporter) && !Is_True(teleporter.skipDelete))
            teleporter Delete();
    }
}

function AddActiveTeleporter(skipLink = false, skipDelete = false)
{
    if(!IsDefined(level.ActiveTeleporters))
        level.ActiveTeleporters = [];
    
    if(isInArray(level.ActiveTeleporters, self))
        return;
    
    if(level.ActiveTeleporters.size && !skipLink)
    {
        if(IsDefined(level.ActiveTeleporters[(level.ActiveTeleporters.size - 1)]) && !IsDefined(level.ActiveTeleporters[(level.ActiveTeleporters.size - 1)].LinkedTeleporter))
        {
            self.LinkedTeleporter = level.ActiveTeleporters[(level.ActiveTeleporters.size - 1)];
            level.ActiveTeleporters[(level.ActiveTeleporters.size - 1)].LinkedTeleporter = self;
        }
    }

    self.skipDelete = skipDelete;
    level.ActiveTeleporters[level.ActiveTeleporters.size] = self;

    self MakeUsable();
    self SetCursorHint("HINT_NOICON");
    self SetHintString("Press ^3[{+activate}]^7 To Teleport");
    self thread ActivateTeleporter();

    while(IsDefined(self))
    {
        PlayFXOnTag(level._effect["teleport_aoe_kill"], self, "tag_origin");
        wait 0.25;
    }
}

function ActivateTeleporter()
{
    if(IsDefined(self.TeleporterActivated))
        return;
    self.TeleporterActivated = true;

    while(IsDefined(self))
    {
        self waittill("trigger", player);
        
        if(Is_True(player.UsingTeleporter) || !IsDefined(self))
            continue;
        
        if(!IsDefined(self.LinkedTeleporter))
        {
            player iPrintlnBold("^1ERROR: ^7No Linked Teleporter Found");
            continue;
        }
        
        player thread UseTeleporter(self);
    }
}

function UseTeleporter(teleporter)
{
    if(!IsDefined(teleporter) || Is_True(self.UsingTeleporter) || !IsDefined(teleporter.LinkedTeleporter))
        return;
    
    self.UsingTeleporter = true;
    PlayFX(level._effect["teleport_splash"], teleporter.origin);
    wait 0.05;

    self SetOrigin(teleporter.LinkedTeleporter.origin);
    PlayFX(level._effect["teleport_splash"], teleporter.LinkedTeleporter.origin);
    wait 1.5;

    if(Is_True(self.UsingTeleporter))
        self.UsingTeleporter = BoolVar(self.UsingTeleporter);
}

// ============================================================
// Functions/teleport.gsc
// ============================================================

function PopulateTeleportMenu(menu, player)
{
    switch(menu)
    {
        case "Teleport Menu":

            MenuSpawnPoints = ArrayCombine(struct::get_array("player_respawn_point_arena", "targetname"), struct::get_array("player_respawn_point", "targetname"), 0, 1);
            mapStr = ReturnMapName();
            
            self addMenu(menu);
                self addOptBool(player.DisableTeleportEffect, "Disable Teleport Effect", &DisableTeleportEffect, player);
                
                if(IsDefined(MenuSpawnPoints) && MenuSpawnPoints.size)
                    self addOptIncSlider("Official Spawn Points", &OfficialSpawnPoint, 0, 0, (MenuSpawnPoints.size - 1), 1, MenuSpawnPoints, player);
                
                if(ReturnMapName() != "Unknown")
                    self addOpt(mapStr + " Teleports", &newMenu, mapStr + " Teleports");
                
                self addOpt("Entity Teleports", &newMenu, "Entity Teleports");
                self addOptSlider("Teleport", &TeleportPlayer, Array("Crosshairs", "Sky", "Random Player"), player);
                self addOptBool(player.TeleportGun, "Teleport Gun", &TeleportGun, player);
                self addOptBool(player.SaveAndLoad, "Save & Load Position", &SaveAndLoad, player);
                self addOpt("Save Current Location", &SaveCurrentLocation, player);
                self addOpt("Load Saved Location", &LoadSavedLocation, player);

                if(player != self)
                {
                    self addOpt("Teleport To Self", &TeleportPlayer, self, player);
                    self addOpt("Teleport To Player", &TeleportPlayer, player, self);
                }
            break;
        
        case "Entity Teleports":            
            self addMenu(menu);

                if(IsDefined(level.chests[level.chest_index]))
                    self addOpt("Mystery Box", &EntityTeleport, "Mystery Box", player);
                
                if(IsDefined(level.bgb_machines) && level.bgb_machines.size)
                    self addOptIncSlider("BGB Machine", &EntityTeleport, 0, 0, (level.bgb_machines.size - 1), 1, player, "BGB Machine");
                
                tables = level.a_uts_craftables;

                if(IsDefined(tables) && tables.size)
                {
                    valid = [];

                    for(a = 0; a < tables.size; a++)
                    {
                        if(IsDefined(tables[a]) && IsDefined(tables[a].targetname))
                        {
                            if(tables[a].targetname != "open_craftable_trigger")
                                continue;
                            
                            valid[valid.size] = a;
                        }
                    }

                    if(valid.size)
                        self addOptIncSlider("Crafting Table", &EntityTeleport, 0, 0, (valid.size - 1), 1, player, "Table");
                }

                perks = GetEntArray("zombie_vending", "targetname");

                if(IsDefined(perks) && perks.size)
                {
                    foreach(perk in perks)
                    {
                        perkname = ReturnPerkName(CleanString(perk.script_noteworthy));

                        if(perkname == "Unknown Perk")
                            perkname = CleanString(perk.script_noteworthy);
                        
                        self addOpt(perkname, &EntityTeleport, perk.script_noteworthy, player);
                    }
                }
            break;
    }
}

function DisableTeleportEffect(player)
{
    player.DisableTeleportEffect = BoolVar(player.DisableTeleportEffect);
}

function OfficialSpawnPoint(index, points, player)
{
    player SetOrigin(points[index].origin);
    player SetPlayerAngles(points[index].angles);

    player PlayTeleportEffect();
}

function TeleportPlayer(origin, player, angles, name)
{
    if(!IsDefined(origin))
        return;

    if(IsPlayer(origin))
        newOrigin = origin.origin;
    
    if(IsString(origin))
    {
        switch(origin)
        {
            case "Crosshairs":
                newOrigin = self TraceBullet();
                break;
            
            case "Sky":
                newOrigin = player.origin + (0, 0, 35000);
                break;
            
            case "Random Player":
                if(level.players.size < 2)
                    return self iPrintlnBold("^1ERROR: ^7Not Enough Players To Use This Option");
                
                index = RandomInt(level.players.size);

                while(level.players[index] == player || !IsDefined(level.players[index]) || !IsPlayer(level.players[index]))
                    index = RandomInt(level.players.size);
                
                newOrigin = level.players[index].origin;
                break;
        }
    }
    
    if(!IsDefined(newOrigin))
        newOrigin = origin;
    
    if(IsDefined(name) && ReturnMapName() == "Origins" && IsSubStr(name, "Robot Head") && !IsDefined(player.teleport_initial_origin))
        player.teleport_initial_origin = player.origin;
    
    player SetOrigin(newOrigin);

    if(IsDefined(angles))
        player SetPlayerAngles(angles);

    player PlayTeleportEffect();
}

function EntityTeleport(entity, player, eEntity)
{
    if(IsString(entity))
    {
        if(entity == "Mystery Box")
        {
            if(!IsDefined(level.chests) || !level.chests.size || !IsDefined(level.chests[level.chest_index]))
                return;
            
            ent = level.chests[level.chest_index];
            entAngleDir = (AnglesToRight(ent.angles) * -1);
        }
        
        perks = GetEntArray("zombie_vending", "targetname");
                    
        if(IsDefined(perks) && perks.size)
        {
            foreach(perk in perks)
            {
                if(IsDefined(perk) && IsString(entity) && entity == perk.script_noteworthy)
                {
                    ent = perk.machine;
                    
                    if(IsDefined(ent))
                        entAngleDir = AnglesToRight(ent.angles);
                    
                    break;
                }
            }
        }
    }
    else if(IsInt(entity) && IsDefined(eEntity) && eEntity == "BGB Machine")
    {
        if(!IsDefined(level.bgb_machines) || !level.bgb_machines.size)
            return;
        
        ent = level.bgb_machines[entity];

        if(!IsDefined(ent))
            return;
        
        entAngleDir = AnglesToRight(ent.angles);
    }
    else if(IsInt(entity) && IsDefined(eEntity) && eEntity == "Table")
    {
        tables = level.a_uts_craftables;

        if(!IsDefined(tables) || !tables.size)
            return;
        
        valid = [];

        for(a = 0; a < tables.size; a++)
        {
            if(IsDefined(tables[a]) && IsDefined(tables[a].targetname))
            {
                if(tables[a].targetname != "open_craftable_trigger")
                    continue;
                
                valid[valid.size] = a;
            }
        }
        
        ent = tables[valid[entity]];

        if(!IsDefined(ent))
            return;

        entAngleDir = AnglesToForward(ent.angles);
    }

    if(!IsDefined(ent) || !IsDefined(entAngleDir))
        return;
    
    player SetOrigin(ent.origin + (entAngleDir * 70));
    player SetPlayerAngles(VectorToAngles((ent.origin + (0, 0, 55)) - player GetEye()));

    player PlayTeleportEffect();
}

function TeleportGun(player)
{
    player endon("disconnect");
    player endon("EndTeleportGun");
    
    player.TeleportGun = BoolVar(player.TeleportGun);

    if(Is_True(player.TeleportGun))
    {
        while(Is_True(player.TeleportGun))
        {
            player waittill("weapon_fired");
            
            player SetOrigin(player TraceBullet());
            player PlayTeleportEffect();
        }
    }
    else
    {
        player notify("EndTeleportGun");
    }
}

function SaveAndLoad(player)
{
    player endon("disconnect");

    player.SaveAndLoad = BoolVar(player.SaveAndLoad);

    if(Is_True(player.SaveAndLoad))
    {
        player iPrintlnBold("Press [{+actionslot 3}] To ^2Save Current Location");
        player iPrintlnBold("Press [{+actionslot 2}] To ^2Load Saved Location");

        while(Is_True(player.SaveAndLoad))
        {
            if(!player isInMenu(true))
            {
                if(player ActionslotThreeButtonPressed())
                {
                    player SaveCurrentLocation(player);
                    wait 0.05;
                }

                if(player ActionslotTwoButtonPressed() && IsDefined(player.SavedOrigin))
                {
                    player LoadSavedLocation(player);
                    wait 0.05;
                }
            }

            wait 0.05;
        }
    }
}

function SaveCurrentLocation(player)
{
    player.SavedOrigin = player.origin;
    player.SavedAngles = player.angles;
}

function LoadSavedLocation(player)
{
    if(!IsDefined(player.SavedOrigin))
    {
        if(player != self)
            self iPrintlnBold("^1ERROR: ^7Player Doesn't Have A Location Saved");
        else
            self iPrintlnBold("^1ERROR: ^7You Have To Save A Location Before Using This Option");
        
        return;
    }
    
    player SetOrigin(player.SavedOrigin);
    player SetPlayerAngles(player.SavedAngles);

    player PlayTeleportEffect();
}

function PlayTeleportEffect()
{
    if(!Is_True(self.DisableTeleportEffect))
    {
        PlayFX(level._effect["teleport_splash"], self.origin);
        PlayFX(level._effect["teleport_aoe_kill"], self GetTagOrigin("j_spineupper"));
        
        self PlaySound("zmb_bgb_abh_teleport_in");
    }
}

function GenerateMapTeleports()
{
    map = ReturnMapName();

    if(map != "Unknown") //Feel free to add your own custom teleport locations
    {
        //Teleport Name, Followed By The Origin
        //[< teleport location name >, < (x, y, z) origin >]

        switch(map)
        {
            case "Shadows Of Evil":
                locations = Array("Spawn", (1077.87, -5364.46, 124.719), "Pack 'a' Punch", (2614.68, -2348.33, -351.875), "Prison", (3007, -6542, 296.125));
                break;
            
            case "The Giant":
                locations = Array("Spawn", (-56.6293, 286.99, 98.125), "Power", (529.258, -1835.94, 61.6158), "Pack 'a' Punch", (-53.7356, 499.323, 101.125), "Prison", (-93.9053, -3268.56, -104.875));
                break;
            
            case "Der Eisendrache":
                locations = Array("Spawn", (421.786, 559.05, -47.875), "Power", (-27.8228, 2784.15, 848.125), "Pyramid", (-1476.97, 2253.83, 200.2), "Boss Fight Room", (-3182.63, 6962.58, -252.375), "Time Travel Room", (-278.407, 5001.93, 152.125), "Prison", (917.821, 912.26, 144.125));
                break;
            
            case "Zetsubou No Shima":
                locations = Array("Spawn", (393.455, -3181.32, -501.117), "Power", (-1475.2, 3456.67, -426.877), "Pack 'a' Punch", (246.815, 3818.53, -503.875), "Easter Egg Room", (-1974.675, 767.305, 276.125), "Prison", (2608, 1135, -175.875));
                break;
            
            case "Gorod Krovi":
                locations = Array("Spawn", (-144, -184, 0.125), "Power", (102, 4969, 144.125), "Pack 'a' Punch", (-2967, 21660, 0.125), "Prison", (-2152, 3644, 160.125));
                break;
            
            case "Revelations":
                locations = Array("Spawn", (-4812, 72, -451.2), "Pack 'a' Punch", (819, 145, -3301.9), "Origins", (-3006, 3470, 1066), "Nacht Der Untoten", (109, 448, -379.6), "Verruckt", (5027, -2366, 230), "Kino Der Toten", (-1393, -9218, -1663.5), "Shangri-La", (-2023, -4151, -1699.5), "Mob Of The Dead", (478, 3301, 1264.125), "Prison", (154, 474, -740.125));
                break;
            
            case "Nacht Der Untoten":
                locations = Array("Spawn", (53, 415, 5.25), "Prison", (-162, -396, 1.125));
                break;
            
            case "Verruckt":
                locations = Array("Spawn", (1097, 302, 64.125), "Power", (-357, -219, 226.125), "Prison", (1154, 791, 64.125));
                break;
            
            case "Shi No Numa":
                locations = Array("Spawn", (10267, 514, -528.875), "Out Of The Map", (12374, 4523, -664.875), "Under The Map", (11838, -1614, -1217.94), "Prison", (12500, -939, -644.875));
                break;
            
            case "Kino Der Toten":
                locations = Array("Spawn", (13.2366, -1262.8, 90.125), "Power", (-619.298, 1391.23, -15.875), "Pack 'a' Punch", (5.74551, -376.756, 320.125), "Air Force Room", (1154.75, 2650.46, -367.875), "Surgical Room", (1948.13, -2204.91, 136.125), "Samantha's Room", (-2636.31, 189.825, 52.125), "Samantha's Red Room", (-2620.55, -1106.91, 53.3851), "Prison", (-1590.36, -4760.5, -167.875));
                break;
            
            case "Ascension":
                locations = Array("Spawn", (-512, 3, -484.875), "Power", (-464, 1028, 220.125), "Pack 'a' Punch", (487, 389, -303.875), "Prison", (-228, 1306, -485.875));
                break;
            
            case "Shangri-La":
                locations = Array("Spawn", (-10, -740, 20.125), "Pack 'a' Punch", (-2, 381, 289.125), "Prison", (1052, 1275, -547.875));
                break;
            
            case "Moon":
                locations = Array("Earth Spawn", (22250, -38663, -679.875), "Moon Spawn", (-4, 32, -1.875), "Power", (42, 3100, -587.875), "Dome", (-162, 6893, 0.45), "Prison", (743, 966, -220.875));
                break;
            
            case "Origins":
                locations = Array("Spawn", (2698.43, 5290.48, -346.219), "Staff Chamber", (-2.4956, -2.693, -751.875), "The Crazy Place", (10334.5, -7891.93, -411.875), "Lightning Tunnel", (-3234, -372, -188), "Wind Tunnel", (3330, 1227, -343), "Fire Tunnel", (3064, 4395, -599), "Ice Tunnel", (1431, -1728, -121), "Robot Head: Odin", (-6759.17, -6541.72, 159.375), "Robot Head: Thor", (-6223.59, -6547.65, 159.375), "Robot Head: Freya", (-5699.83, -6540.03, 159.375), "Prison", (-3142.11, 1125.09, -63.875));
                break;
            
            case "Mob Of The Dead":
                locations = Array("Spawn", (-2185.649, 5548.136, 2688.125), "Pack 'a' Punch(Bridge)", (-10931.269, 31045.974, 3800.125), "Roof", (115.627, 4876.537, 3052.125), "Prison", (-2744.295, 3911.298, 2792.125));
                break;
            
            case "Die Rise":
                locations = Array("Spawn", (-880.691, 362.408, 1808.125), "Power", (460.962, -1024.275, -287.875), "Bank Showers", (0.08, -394.350, -287.875), "Prison", (-200.960, -1127.386, 944.125));
                break;
            
            case "Bus Depot":
                locations = Array("Spawn", (1444.05, 4467.5, 0.125), "Power", (1272.86, 4339.175, -151.625), "Pack 'a' Punch", (3121.84, 1892.9, 21.812), "Prison", (-484.175, 260.947, 0.125));
                break;
            
            case "Tunnel":
                locations = Array("Spawn", (1490.38, -2368.4, 275.8), "Power", (3952.9, -1431.5, 72.125), "Pack 'a' Punch", (1444.7, -449.98, 103.19), "Prison", (2175, -2836.6, 320.125));
                break;
            
            case "Diner":
                locations = Array("Spawn", (7583.19, -12471.09, -0.625), "Power", (10258.39, -12906.60, 95.125), "Pack 'a' Punch", (5171.02, -13046.58, 0.64), "Prison", (5516.14, -19922.40, -115.875));
                break;
            
            case "Farm":
                locations = Array("Spawn", (4924.46, -586.4, 80.92), "Power", (7154.933, 1721.47, -487.875), "Pack 'a' Punch", (6463.42, 1914.62, -487.875), "Prison", (5152.64, 2035.49, -247.875));
                break;
            
            case "Der Riese: Declassified":
                locations = Array("Spawn", (-51.78, 305.3, 98.375), "Power", (530.13, -1810.82, 61.125), "Pack 'a' Punch", (-55.18, 511, 101.125), "Prison", (5454.43, -20.8, -271.875), "Kino Der Toten", (28491.7, -1889, -323.16), "Nacht Der Untoten", (24360.625, -10584, -872.52), "Richtofen's Lab", (23457.99, 961.57, 57.21), "Samantha's Bedroom", (23346.86, -1918.75, 174.125), "Forest", (27320.9, -10309.79, -879.73), "Boss Fight", (41130, 37102.87, -1995.35));
                break;
            
            case "Leviathan":
                locations = Array("Spawn", (-789.95, -29.18, -484.875));
                break;
        }

        return locations;
    }
}

// ============================================================
// Functions/weaponry.gsc
// ============================================================

function PopulateWeaponry(menu, player)
{
    switch(menu)
    {
        case "Weaponry":
            weapons = Array("Assault Rifles", "Sub Machine Guns", "Light Machine Guns", "Sniper Rifles", "Shotguns", "Pistols", "Launchers", "Specials");

            self addMenu(menu);

                if(!IsVerkoMap())
                {
                    self addOpt("Options", &newMenu, "Weapon Options");
                    self addOpt("Attachments", &newMenu, "Weapon Attachments");
                    self addOpt("Loadout", &newMenu, "Weapon Loadout");
                    self addOpt("Camo", &newMenu, "Weapon Camo");
                    self addOpt("AAT", &newMenu, "Weapon AAT");
                }
                else
                {
                    self addOpt("Take Current Weapon", &TakeCurrentWeapon, player);
                    self addOpt("Take All Weapons", &TakePlayerWeapons, player);
                    self addOptSlider("Drop Current Weapon", &DropCurrentWeapon, Array("Take", "Don't Take"), player);
                    self addOptSlider("Pack 'a' Punch Current Weapon", &VerkoPackCurrentWeapon, Array("None", "Upgrade", "Mastery"), player);
                }

                self addOpt("");
                self addOpt("Equipment", &newMenu, "Equipment Menu");

                if(!IsVerkoMap())
                {
                    for(a = 0; a < weapons.size; a++)
                        self addOpt(weapons[a], &newMenu, weapons[a]);
                }
                else
                {
                    for(a = 0; a < level.var_21b77150.size; a++)
                        self addOptBool(player HasWeapon1(GetWeapon(level.var_21b77150[a])), level.var_7df703ba[a], &GivePlayerWeapon, GetWeapon(level.var_21b77150[a]), player);
                }
            break;
        
        case "Weapon Options":
            self addMenu("Options");
                self addOpt("Take Current Weapon", &TakeCurrentWeapon, player);
                self addOpt("Take All Weapons", &TakePlayerWeapons, player);
                self addOptSlider("Drop Current Weapon", &DropCurrentWeapon, Array("Take", "Don't Take"), player);
                self addOptBool(player zm_weapons::is_weapon_upgraded(player GetCurrentWeapon()), "Pack 'a' Punch Current Weapon", &PackCurrentWeapon, player);
            break;
        
        case "Weapon Loadout":
            self addMenu("Loadout");
                self addOpt("Save Primary Weapon", &SaveCurrentLoadout, "Primary", player);
                self addOpt("Save Secondary Weapon", &SaveCurrentLoadout, "Secondary", player);
                self addOpt("Save Primary Offhand", &SaveCurrentLoadout, "Primary Offhand", player);
                self addOpt("Save Secondary Offhand", &SaveCurrentLoadout, "Secondary Offhand", player);
                self addOpt("");
                self addOpt("Reset", &ClearLoadout, player);
            break;
        
        case "Weapon Camo":
            self addMenu("Camo");
                self addOptBool(player.FlashingCamo, "Flashing Camo", &FlashingCamo, player);
                self addOpt("");

                skip = Array(37, 72, 127, 128, 129, 130); //These are camos that aren't in the game anymore, so they will be skipped

                for(a = 0; a < 139; a++)
                {
                    if(isInArray(skip, a))
                        continue;
                    
                    self addOpt(((ReturnCamoName((a + 45)) == "" || IsSubStr(ReturnCamoName((a + 45)), "PLACEHOLDER") || ReturnCamoName((a + 45)) == "MPUI_CAMO_LOOT_CONTRACT") ? CleanString(ReturnRawCamoName((a + 45))) : ReturnCamoName((a + 45))), &SetPlayerCamo, a, player);
                }
            break;
        
        case "Weapon Attachments":
            weapon = player GetCurrentWeapon();
            
            self addMenu("Attachments");

                if(IsDefined(weapon.supportedAttachments) && weapon.supportedAttachments.size)
                {
                    foreach(attachment in weapon.supportedAttachments)
                    {
                        name = ReturnAttachmentName(attachment);

                        if(!IsDefined(name) || name == "" || attachment == "dw")
                            continue;
                        
                        if(attachment == "none")
                            self addOpt(name, &GivePlayerAttachment, attachment, player);
                        else
                            self addOptBool((IsDefined(weapon.attachments) && isInArray(weapon.attachments, attachment)), name, &GivePlayerAttachment, attachment, player);
                    }
                }
                else
                {
                    self addOpt("No Supported Attachments Found");
                }
            break;
        
        case "Weapon AAT":
            keys = GetArrayKeys(level.aat);
            
            self addMenu("AAT");
                
                if(IsDefined(keys) && keys.size)
                {
                    for(a = 0; a < keys.size; a++)
                    {
                        if(IsDefined(keys[a]) && level.aat[keys[a]].name != "none")
                            self addOptBool((IsDefined(player.aat[player aat::get_nonalternate_weapon(player GetCurrentWeapon())]) && player.aat[player aat::get_nonalternate_weapon(player GetCurrentWeapon())] == keys[a]), CleanString(level.aat[keys[a]].name), &GiveWeaponAAT, keys[a], player);
                    }
                }
            break;
        
        case "Equipment Menu":
            if(IsDefined(level.zombie_include_equipment))
                include_equipment = GetArrayKeys(level.zombie_include_equipment);

            equipment = ArrayCombine(level.zombie_lethal_grenade_list, level.zombie_tactical_grenade_list, 0, 1);
            keys = GetArrayKeys(equipment);

            self addMenu("Equipment");

                if(IsDefined(keys) && keys.size || IsDefined(include_equipment) && include_equipment.size)
                {
                    foreach(index, weapon in GetArrayKeys(level.zombie_weapons))
                    {
                        if(isInArray(equipment, weapon))
                            self addOptBool(player HasWeapon(weapon), weapon.displayname, &GivePlayerEquipment, weapon, player);
                    }

                    if(IsDefined(include_equipment) && include_equipment.size)
                    {
                        foreach(weapon in include_equipment)
                            self addOptBool(player HasWeapon(weapon), weapon.displayname, &GivePlayerEquipment, weapon, player);
                    }
                }
            break;
    }
}

function PopulateWeaponCategoryMenu(menu, index, player)
{
    if(!IsDefined(index) || index < 0)
        return;

    self addMenu(menu);

    weaponClasses = Array("assault", "smg", "lmg", "sniper", "cqb", "pistol", "launcher", "special");
    weaponReclass = Array("ar", "smg", "lmg", "sniper", "shotgun", "pistol", "launcher", "special");

    foreach(weapon in GetArrayKeys(level.zombie_weapons))
    {
        if(!IsDefined(weapon) || weapon == level.weaponnone)
            continue;
        
        if(Is_True(weapon.isgrenadeweapon) || IsSubStr(weapon.name, "knife") || IsSubStr(weapon.name, "upgraded"))
            continue;
        
        zmClass = zm_utility::GetWeaponClassZM(weapon);
        newClass = undefined;

        if(zmClass == "weapon_pistol")
        {
            weapTok = StrTok(weapon.name, "_");
            newClass = weapTok[0];

            if(!isInArray(weaponReclass, newClass))
            {
                zmClass = "weapon_special";
            }
            else
            {
                for(a = 0; a < weaponReclass.size; a++)
                {
                    if(weaponReclass[a] == newClass)
                        zmClass = "weapon_" + weaponClasses[a];
                }
            }
        }

        if(zmClass != "weapon_" + weaponClasses[index])
            continue;

        self addOptBool(player HasWeapon1(weapon), ((IsDefined(weapon.displayname) && MakeLocalizedString(weapon.displayname) != "") ? weapon.displayname : weapon.name), &GivePlayerWeapon, weapon, player);
    }

    if(menu == "Specials")
    {
        defaultWeapon = GetWeapon("defaultweapon");
        minigun = GetWeapon("minigun");

        self addOptBool(player HasWeapon1(defaultWeapon), "Default Weapon", &GivePlayerWeapon, defaultWeapon, player);
        self addOptBool(player HasWeapon1(minigun), minigun.displayname, &GivePlayerWeapon, minigun, player);

        if(ReturnMapName() == "Shadows Of Evil")
        {
            teslaGun = GetWeapon("tesla_gun");
            self addOptBool(player HasWeapon1(teslaGun), teslaGun.displayname, &GivePlayerWeapon, teslaGun, player);
        }
    }
}

function TakeCurrentWeapon(player)
{
    weapon = player GetCurrentWeapon();

    if(!IsDefined(weapon) || weapon == level.weaponnone || IsDefined(level.weaponbasemelee) && weapon == level.weaponbasemelee || IsSubStr(weapon.name, "_knife"))
        return;
    
    player TakeWeapon(weapon);
}

function TakePlayerWeapons(player)
{
    foreach(weapon in player GetWeaponsList(1))
    {
        if(!IsDefined(weapon) || weapon == level.weaponnone || IsDefined(level.weaponbasemelee) && weapon == level.weaponbasemelee || IsSubStr(weapon.name, "_knife"))
            continue;
        
        player TakeWeapon(weapon);
    }
}

function DropCurrentWeapon(type, player)
{
    weapon = player GetCurrentWeapon();
    clip = player GetWeaponAmmoClip(player GetCurrentWeapon());
    stock = player GetWeaponAmmoStock(player GetCurrentWeapon());

    if(IsDefined(player.aat[player aat::get_nonalternate_weapon(weapon)]))
        aat = player.aat[player aat::get_nonalternate_weapon(weapon)];

    player DropItem(weapon);

    if(type == "Don't Take")
    {
        newWeapon = player zm_weapons::weapon_give(weapon, false, false, true);
    
        if(!IsDefined(newWeapon))
            return;

        if(IsDefined(weapon.savedCamo))
            SetPlayerCamo(weapon.savedCamo, player);
        
        if(IsDefined(aat))
            player aat::acquire(weapon, aat);
        
        player SetWeaponAmmoClip(newWeapon, clip);
        player SetWeaponAmmoStock(newWeapon, stock);

        if(!IsSubStr(newWeapon.name, "_knife"))
            player SetSpawnWeapon(newWeapon, true);
    }
}

function PackCurrentWeapon(player, buildKit = true)
{
    player endon("disconnect");

    originalWeapon = player GetCurrentWeapon();

    if(!IsDefined(originalWeapon) || !zm_weapons::can_upgrade_weapon(originalWeapon))
        return self iPrintlnBold("^1ERROR: ^7Invalid Weapon");

    newWeapon = (!zm_weapons::is_weapon_upgraded(player GetCurrentWeapon()) ? zm_weapons::get_upgrade_weapon(player GetCurrentWeapon()) : zm_weapons::get_base_weapon(player GetCurrentWeapon()));

    if(!IsDefined(newWeapon))
        return;

    base_weapon = newWeapon;
    upgraded = 0;

    if(zm_weapons::is_weapon_upgraded(newWeapon))
    {
        upgraded = 1;
        base_weapon = zm_weapons::get_base_weapon(newWeapon);
    }

    if(zm_weapons::is_weapon_included(base_weapon))
        force_attachments = zm_weapons::get_force_attachments(base_weapon.rootweapon);

    camo = ((!upgraded && IsDefined(originalWeapon.savedCamo) && originalWeapon.savedCamo != level.pack_a_punch_camo_index) ? originalWeapon.savedCamo : (upgraded ? level.pack_a_punch_camo_index : undefined));

    if(IsDefined(force_attachments) && force_attachments.size)
    {
        if(upgraded)
        {
            packed_attachments = [];

            packed_attachments[packed_attachments.size] = "extclip";
            packed_attachments[packed_attachments.size] = "fmj";

            force_attachments = ArrayCombine(force_attachments, packed_attachments, 0, 0);
        }

        acvi = 0;
        newWeapon = GetWeapon(newWeapon.rootweapon.name, force_attachments);
        weapon_options = player CalcWeaponOptions(camo, 0, 0);
    }
    else
    {
        if(buildKit)
        {
            newWeapon = player GetBuildKitWeapon(newWeapon, upgraded);
            weapon_options = player GetBuildKitWeaponOptions(newWeapon, camo);
            acvi = player GetBuildKitAttachmentCosmeticVariantIndexes(newWeapon, upgraded);
        }
        else
        {
            acvi = 0;
            weapon_options = player CalcWeaponOptions(camo, 0, 0);
        }
    }

    if(!IsDefined(newWeapon))
        return;

    newWeapon.savedCamo = camo;

    player TakeWeapon(player GetCurrentWeapon());
    player GiveWeapon(newWeapon, weapon_options, acvi);
    player GiveStartAmmo(newWeapon);
    player SetSpawnWeapon(newWeapon, true);
}

function VerkoPackCurrentWeapon(type, player)
{
    currentWeapon = player GetCurrentWeapon();

    if(!IsDefined(currentWeapon) || currentWeapon == level.weaponnone)
        return self iPrintlnBold("^1ERROR: ^7Not A Valid Weapon");
    
    if(isInArray(level.var_21b77150, currentWeapon.name))
    {
        currentArray = level.var_21b77150;

        if(type == "None")
            return;
    }
    else if(isInArray(level.var_2b893b73, currentWeapon.name))
    {
        currentArray = level.var_2b893b73;

        if(type == "Upgrade")
            return;
    }
    else if(isInArray(level.var_23af580e, currentWeapon.name))
    {
        currentArray = level.var_23af580e;

        if(type == "Mastery")
            return;
    }
    else
    {
        return self iPrintlnBold("^1ERROR: Not A Valid Weapon");
    }
    
    weaponIndex = 0;

    for(a = 0; a < currentArray.size; a++)
    {
        if(currentArray[a] == currentWeapon.name)
            weaponIndex = a;
    }
    
    switch(type)
    {
        case "None":
            newWeapon = GetWeapon(level.var_21b77150[weaponIndex]);
            break;
        
        case "Upgrade":
            newWeapon = GetWeapon(level.var_2b893b73[weaponIndex]);
            break;
        
        case "Mastery":
            newWeapon = GetWeapon(level.var_23af580e[weaponIndex]);
            break;
    }
    
    player TakeWeapon(currentWeapon);
    player GiveWeapon(newWeapon);
    player GiveStartAmmo(newWeapon);
    player SetSpawnWeapon(newWeapon, true);
    wait 0.05;

    if(type == "Mastery")
    {
        aatName = VerkoGetAAT(level.var_fc480cef[weaponIndex]);

        if(aatName != "undefined")
            player thread aat::acquire(newWeapon, aatName);
    }
}

function VerkoGetAAT(aat)
{
    switch(aat)
    {
        case "deadwire":
            return "zm_aat_dead_wire";
        
        case "blastfurnace":
            return "zm_aat_blast_furnace";
        
        case "thunderwall":
            return "zm_aat_thunder_wall";
        
        case "turned":
            return "zm_aat_turned";
        
        case "fireworks":
            return "zm_aat_fire_works";
        
        case "aethercollapse":
            return "zm_aat_aethercollapse";
        
        default:
            return "undefined";
    }
}

function GivePlayerAttachment(attachment, player)
{
    player endon("disconnect");

    weapon = player GetCurrentWeapon();
    attachments = weapon.attachments;

    if(IsDefined(player.aat[player aat::get_nonalternate_weapon(weapon)]))
        aat = player.aat[player aat::get_nonalternate_weapon(weapon)];
    
    if(isInArray(attachments, attachment)) //If the weapon has the attachment, it will be removed
    {
        attachments = ArrayRemove(attachments, attachment);
    }
    else //If the weapon doesn't have the attachment, it will be added
    {
        if(!IsValidCombination(attachments, attachment))
        {
            invalid = GetInvalidAttachments(attachments, attachment);

            if(IsDefined(invalid) && invalid.size)
            {
                for(a = 0; a < invalid.size; a++)
                    attachments = ArrayRemove(attachments, invalid[a]);
            }
        }
        
        array::add(attachments, attachment, 0);

        if(attachments.size > 8)
            return self iPrintlnBold("^1ERROR: ^7Attachment Limit Reached");
    }

    newWeapon = GetWeapon(weapon.rootweapon.name, attachments);
    camo = (IsDefined(weapon.savedCamo) ? weapon.savedCamo : 0);
    weapon_options = player CalcWeaponOptions(camo, 0, 0);
    newWeapon.savedCamo = camo;
    
    player TakeWeapon(weapon);
    player GiveWeapon(newWeapon, weapon_options);
    player SetSpawnWeapon(newWeapon, true);

    if(IsDefined(aat))
        player aat::acquire(newWeapon, aat);
}

function IsValidCombination(attachments, attachment)
{
    valid = ReturnAttachmentCombinations(attachment);
    tokens = StrTok(valid, " ");

    for(a = 0; a < attachments.size; a++)
    {
        if(!isInArray(tokens, attachments[a]))
            return false;
    }
    
    return true;
}

function GetInvalidAttachments(attachments, attachment)
{
    valid = ReturnAttachmentCombinations(attachment);
    tokens = StrTok(valid, " ");

    invalid = [];

    for(a = 0; a < attachments.size; a++)
    {
        if(!isInArray(tokens, attachments[a]))
            array::add(invalid, attachments[a], 0);
    }
    
    return invalid;
}

function SaveCurrentLoadout(type, player)
{
    userID = player GetXUID();

    if(!IsSubStr(ToLower(type), "offhand"))
    {
        weapon = player GetCurrentWeapon();

        if(!IsDefined(weapon) || weapon == level.weaponnone || weapon == level.weaponbasemelee || IsSubStr(weapon.name, "_knife"))
            return self iPrintlnBold("^1ERROR: ^7Invalid Weapon");

        if(IsDefined(weapon.attachments) && weapon.attachments.size)
        {
            attachments = "";

            foreach(index, attachment in weapon.attachments) attachments += ((index == (weapon.attachments.size - 1)) ? attachment : attachment + ";");
        }
        else
        {
            attachments = "none";
        }
        
        SetDvar("Loadout_" + type + "_" + userID, zm_weapons::get_base_weapon(weapon).name);
        SetDvar("Loadout_" + type + "_Attachments_" + userID, attachments);
        SetDvar("Loadout_" + type + "_Camo_" + userID, (IsDefined(weapon.savedCamo) ? weapon.savedCamo : 0));
        SetDvar("Loadout_" + type + "_Upgraded_" + userID, zm_weapons::is_weapon_upgraded(weapon));
        SetDvar("Loadout_" + type + "_AAT_" + userID, (IsDefined(player.aat[player aat::get_nonalternate_weapon(weapon)]) ? player.aat[player aat::get_nonalternate_weapon(weapon)] : "none"));
    }
    else
    {
        saveType = ((type == "Primary Offhand") ? "primary_offhand" : "secondary_offhand");
        weapon = ((type == "Primary Offhand") ? player zm_utility::get_player_lethal_grenade() : player zm_utility::get_player_tactical_grenade());
        
        if(!IsDefined(weapon) || weapon == level.weaponnone)
            return self iPrintlnBold("^1ERROR: ^7Invalid Offhand");
        
        SetDvar("Loadout_" + saveType + "_" + userID, weapon.name);
    }
    
    SetDvar("Apparition_Loadout_" + userID, 1);
    self iPrintlnBold(type + " ^2Saved");
}

function ClearLoadout(player)
{
    userID = player GetXUID();
    saved = GetDvarInt("Apparition_Loadout_" + userID);

    if(!IsDefined(saved) || !saved)
        return;
    
    types = Array("Primary", "Secondary");

    SetDvar("Apparition_Loadout_" + userID, 0);

    foreach(type in types)
    {
        SetDvar("Loadout_" + type + "_" + userID, "");
        SetDvar("Loadout_" + type + "_Attachments_" + userID, "");
        SetDvar("Loadout_" + type + "_Camo_" + userID, 0);
        SetDvar("Loadout_" + type + "_Upgraded_" + userID, 0);
        SetDvar("Loadout_" + type + "_AAT_" + userID, "");
    }

    types = Array("primary_offhand", "secondary_offhand");

    foreach(type in types)
        SetDvar("Loadout_" + type + "_" + userID, "");
    
    self iPrintlnBold("Loadout ^2Cleared");
}

function GivePlayerLoadout()
{
    self endon("disconnect");

    userID = self GetXUID();
    
    if(GetDvarInt("Apparition_Loadout_" + userID))
    {
        types = Array("Secondary", "Primary");
        first = true;

        foreach(type in types)
        {
            weapon = GetDvarString("Loadout_" + type + "_" + userID);

            if(!IsDefined(weapon) || weapon == "" || !isInArrayKeys(level.zombie_weapons, GetWeapon(weapon)))
                continue;
            
            if(first)
            {
                foreach(primary in self GetWeaponsListPrimaries())
                {
                    if(!IsDefined(primary) || primary == level.weaponnone || primary == level.weaponbasemelee || IsSubStr(primary.name, "_knife"))
                        continue;
                    
                    self TakeWeapon(primary);
                }

                first = false;
            }

            newWeapon = GivePlayerWeapon(GetWeapon(weapon), self);

            if(IsDefined(newWeapon.attachments) && newWeapon.attachments.size) //Fix for build kit attachments conflicting saved attachments
            {
                attachments = [];
                baseWeapon = GetWeapon(newWeapon.rootweapon.name, attachments);

                self TakeWeapon(newWeapon);
                self GiveWeapon(baseWeapon);
                self SetSpawnWeapon(baseWeapon, true);
            }

            if(GetDvarInt("Loadout_" + type + "_Upgraded_" + userID))
                PackCurrentWeapon(self, false);
            
            weaponCamo = GetDvarInt("Loadout_" + type + "_Camo_" + userID);

            if(weaponCamo)
            {
                newWeapon.savedCamo = weaponCamo;
                SetPlayerCamo(weaponCamo, self);
            }

            weaponAAT = GetDvarString("Loadout_" + type + "_AAT_" + userID);

            if(IsDefined(weaponAAT) && weaponAAT != "" && weaponAAT != "none")
                GiveWeaponAAT(weaponAAT, self);
            
            weaponAttachments = GetDvarString("Loadout_" + type + "_Attachments_" + userID);

            if(IsDefined(weaponAttachments) && weaponAttachments != "" && weaponAttachments != "none")
            {
                attachments = StrTok(weaponAttachments, ";");

                for(a = 0; a < attachments.size; a++)
                    GivePlayerAttachment(attachments[a], self);
            }
        }

        level flag::wait_till("initial_blackscreen_passed");
        wait 4;

        types = Array("primary_offhand", "secondary_offhand");

        foreach(type in types)
        {
            weapon = GetDvarString("Loadout_" + type + "_" + userID);

            if(!IsDefined(weapon) || weapon == "" || weapon == level.weaponnone || !isInArrayKeys(level.zombie_weapons, GetWeapon(weapon)) && !isInArrayKeys(level.zombie_include_equipment, GetWeapon(weapon)))
                continue;
            
            if(self HasWeapon(GetWeapon(weapon)))
            {
                self GiveStartAmmo(GetWeapon(weapon));
                continue;
            }
            
            GivePlayerEquipment(GetWeapon(weapon), self);
            self GiveStartAmmo(GetWeapon(weapon));
        }
    }
}

function SetPlayerCamo(camo, player)
{
    weap = player GetCurrentWeapon();

    if(!IsDefined(weap) || weap == level.weaponnone)
        return;

    weapon = player CalcWeaponOptions(camo, 0, 0);
    NewWeapon = player GetBuildKitAttachmentCosmeticVariantIndexes(weap, zm_weapons::is_weapon_upgraded(player GetCurrentWeapon()));
    
    player TakeWeapon(weap);
    player GiveWeapon(weap, weapon, NewWeapon);
    player SetSpawnWeapon(weap, true);

    weap.savedCamo = camo;
}

function FlashingCamo(player)
{
    player endon("disconnect");

    player.FlashingCamo = BoolVar(player.FlashingCamo);

    while(Is_True(player.FlashingCamo))
    {
        if(!player IsMeleeing() && !player IsSwitchingWeapons() && !player IsReloading() && !player IsSprinting() && !player IsUsingOffhand() && !zm_utility::is_placeable_mine(player GetCurrentWeapon()) && !zm_equipment::is_equipment(player GetCurrentWeapon()) && !player zm_utility::has_powerup_weapon() && !zm_utility::is_hero_weapon(player GetCurrentWeapon()) && !player zm_utility::in_revive_trigger() && !player.is_drinking && player GetCurrentWeapon() != level.weaponnone)
            SetPlayerCamo(RandomInt(139), player);
        
        wait 0.25;
    }
}

function GiveWeaponAAT(aat, player)
{
    player endon("disconnect");

    if(!IsDefined(player.aat))
        player.aat = [];
    
    if(!IsDefined(player.aat[player aat::get_nonalternate_weapon(player GetCurrentWeapon())]) || player.aat[player aat::get_nonalternate_weapon(player GetCurrentWeapon())] != aat)
    {
        player aat::acquire(player GetCurrentWeapon(), aat);
    }
    else
    {
        player aat::remove(player GetCurrentWeapon());
        player clientfield::set_to_player("aat_current", 0);
    }
}

function GivePlayerEquipment(equipment, player)
{
    if(player HasWeapon(equipment))
        player TakeWeapon(equipment);
    else
        player zm_weapons::weapon_give(equipment, false, false, true);
}

function GivePlayerWeapon(weapon, player)
{
    if(player HasWeapon1(weapon))
    {
        weapons = player GetWeaponsList(true);

        if(!IsVerkoMap())
        {
            for(a = 0; a < weapons.size; a++)
            {
                if(zm_weapons::get_base_weapon(weapons[a]) == zm_weapons::get_base_weapon(weapon))
                    weapon = weapons[a];
            }
        }
        else
        {
            for(a = 0; a < weapons.size; a++)
            {
                if(VerkoGetBaseWeapon(weapons[a]) == VerkoGetBaseWeapon(weapon))
                    weapon = weapons[a];
            }
        }

        player TakeWeapon(weapon);
        return;
    }
    
    newWeapon = player zm_weapons::weapon_give(weapon, false, false, true);
    player GiveStartAmmo(newWeapon);

    if(!IsSubStr(newWeapon.name, "_knife"))
        player SetSpawnWeapon(newWeapon, true);
    
    return newWeapon;
}

function VerkoGetBaseWeapon(weapon)
{
    if(!isInArray(level.var_2b893b73, weapon.name) && !isInArray(level.var_23af580e, weapon.name))
        return weapon;
    
    if(isInArray(level.var_2b893b73, weapon.name))
        currentArray = level.var_2b893b73;
    else if(isInArray(level.var_23af580e, weapon.name))
        currentArray = level.var_23af580e;
    
    if(!IsDefined(currentArray))
        return weapon;
    
    for(a = 0; a < currentArray.size; a++)
    {
        if(currentArray[a] == weapon.name)
            return GetWeapon(level.var_21b77150[a]);
    }
}

function HasWeapon1(weapon)
{
    if(!IsDefined(weapon))
        return false;
    
    weapons = self GetWeaponsList(true);

    if(!IsDefined(weapons) || !weapons.size)
        return false;

    if(!IsVerkoMap())
    {
        for(a = 0; a < weapons.size; a++)
        {
            if(zm_weapons::get_base_weapon(weapons[a]) == zm_weapons::get_base_weapon(weapon))
                return true;
        }
    }
    else
    {
        for(a = 0; a < weapons.size; a++)
        {
            if(VerkoGetBaseWeapon(weapons[a]) == VerkoGetBaseWeapon(weapon))
                return true;
        }
    }

    return false;
}

// ============================================================
// Functions/zombies.gsc
// ============================================================

function PopulateZombieOptions(menu)
{
    switch(menu)
    {
        case "Zombie Options":
            self addMenu(menu);
                self addOpt("Spawner", &newMenu, "AI Spawner");
                self addOpt("Prioritize", &newMenu, "Prioritize Players");
                self addOpt("Death Effect", &newMenu, "Zombie Death Effect");
                self addOpt("Damage Effect", &newMenu, "Zombie Damage Effect");
                self addOpt("Animations", &newMenu, "Zombie Animations");
                self addOpt("Model", &newMenu, "Zombie Model Manipulation");
                self addOptSlider("Gib", &ZombieGibBone, Array("Random", "Head", "Right Leg", "Left Leg", "Right Arm", "Left Arm"));
                self addOptSlider("Kill", &KillZombies, Array("Death", "Head Gib", "Flame", "Delete"));
                self addOptSlider("Health", &SetZombieHealth, Array("Custom", "Reset"));
                self addOptSlider("Movement", &SetZombieRunSpeed, Array("Walk", "Run", "Sprint", "Super Sprint"));
                
                //The only map Knockdown isn't registered on is The Giant
                if(ReturnMapName() != "The Giant")
                    self addOptSlider("Knockdown", &KnockdownZombies, Array("Front", "Back"));

                //Push is only registered on SOE
                if(ReturnMapName() == "Shadows Of Evil")
                    self addOptSlider("Push", &PushZombies, Array("Left", "Right"));
                
                self addOptSlider("Teleport", &TeleportZombies, Array("Crosshairs", "Self"));
                self addOptIncSlider("Animation Speed", &SetZombieAnimationSpeed, 1, 1, 2, 0.5);
                self addOptBool(level.ZombiesToCrosshairsLoop, "Teleport To Crosshairs", &ZombiesToCrosshairsLoop);
                self addOptBool(level.DisableZombieCollision, "Disable Player Collision", &DisableZombieCollision);
                self addOptBool((GetDvarString("ai_disableSpawn") == "1"), "Disable Spawning", &DisableZombieSpawning);
                self addOptBool(level.DisableZombiePush, "Disable Push", &DisableZombiePush);
                self addOptBool(level.ZombiesInvisibility, "Invisibility", &ZombiesInvisibility);
                self addOptBool((GetDvarString("g_ai") == "0"), "Freeze", &FreezeZombies);
                self addOptBool(level.ZombieDeathSounds, "Death Sounds", &ZombieDeathSounds);
                self addOptBool(level.ZombieProjectileVomiting, "Projectile Vomit", &ZombieProjectileVomiting);
                self addOptBool(level.DisappearingZombies, "Disappearing Zombies", &DisappearingZombies);
                self addOptBool(level.ExplodingZombies, "Exploding Zombies", &ExplodingZombies);
                self addOptBool(level.ZombieRagdoll, "Ragdoll After Death", &ZombieRagdoll);
                self addOptBool(level.StackZombies, "Stack Zombies", &StackZombies);
                self addOptBool(level.RemoveZombieEyes, "Remove Eyes", &RemoveZombieEyes);
                self addOptBool((GetDvarVector("phys_gravity_dir") == (0, 0, -1)), "Bodies Float", &BodiesFloat);
                self addOpt("Make Crawlers", &ForceZombieCrawlers);
                self addOpt("Detach Heads", &DetachZombieHeads);
                self addOpt("Clear All Corpses", &ServerClearCorpses);
            break;
        
        case "AI Spawner":
            if(!IsDefined(self.AISpawnLocation))
                self.AISpawnLocation = "Crosshairs";
            
            map = ReturnMapName();
            
            self addMenu("Spawner");
                self addOptSlider("Spawn Location", &AISpawnLocation, Array("Crosshairs", "Random", "Self"));
                self addOptIncSlider("Zombie", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnZombie);

                if(map != "Unknown")
                {
                    maps = Array("Shi No Numa", "The Giant", "Moon", "Kino Der Toten", "Der Eisendrache");

                    if(isInArray(maps, map))
                        self addOptIncSlider("Hellhound", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnDog);
                    
                    maps = Array("Shadows Of Evil", "Revelations", "Gorod Krovi");

                    if(isInArray(maps, map))
                    {
                        if(map != "Gorod Krovi")
                        {
                            self addOptIncSlider("Wasp", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnWasp);
                            self addOptIncSlider("Margwa", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnMargwa);

                            if(map == "Shadows Of Evil")
                                self addOptIncSlider("Civil Protector", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnCivilProtector);
                        }
                        
                        if(map != "Revelations")
                            self addOptIncSlider("Raps", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnRaps);
                    }

                    maps = Array("Origins", "Der Eisendrache", "Revelations");

                    if(isInArray(maps, map))
                        self addOptIncSlider("Mechz", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnMechz);
                    
                    if(map == "Gorod Krovi")
                    {
                        self addOptIncSlider("Sentinel Drone", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnSentinelDrone);
                        self addOptIncSlider("Mangler", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnMangler);
                    }

                    if(map == "Zetsubou No Shima" || map == "Revelations")
                    {
                        if(map == "Zetsubou No Shima")
                            self addOptIncSlider("Thrasher", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnThrasher);
                        
                        self addOptIncSlider("Spider", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnSpider);
                    }

                    if(map == "Revelations")
                        self addOptIncSlider("Fury", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnFury);
                    
                    if(map == "Kino Der Toten")
                        self addOptIncSlider("Nova Zombie", &ServerSpawnAI, 1, 1, 10, 1, &ServerSpawnNovaZombie);
                }
            break;
        
        case "Prioritize Players":
            self addMenu(menu);
            
                foreach(player in level.players)
                    self addOptBool(player.AIPrioritizePlayer, CleanName(player getName()), &AIPrioritizePlayer, player);
            break;
        
        case "Zombie Death Effect":
            self addMenu("Death Effect");
                self addOptBool(!IsDefined(level.ZombiesDeathFX), "Disable", &SetZombiesDeathEffect, "");
                self addOpt("");

                for(a = 0; a < level.menuFX.size; a++)
                    self addOptBool((IsDefined(level.ZombiesDeathFX) && level.ZombiesDeathFX == level.menuFX[a]), CleanString(level.menuFX[a]), &SetZombiesDeathEffect, level.menuFX[a]);
            break;

        case "Zombie Damage Effect":
            self addMenu("Damage Effect");
                self addOptBool(!IsDefined(level.ZombiesDamageFX), "Disable", &SetZombiesDamageEffect, "");
                self addOpt("");

                for(a = 0; a < level.menuFX.size; a++)
                    self addOptBool((IsDefined(level.ZombiesDamageFX) && level.ZombiesDamageFX == level.menuFX[a]), CleanString(level.menuFX[a]), &SetZombiesDamageEffect, level.menuFX[a]);
            break;
        
        case "Zombie Animations":

            //These are base animations that will work on every map
            anims = Array("ai_zombie_base_ad_attack_v1", "ai_zombie_base_ad_attack_v2", "ai_zombie_base_ad_attack_v3", "ai_zombie_base_ad_attack_v4", "ai_zombie_taunts_4");
            notifies = Array("attack_anim", "attack_anim", "attack_anim", "attack_anim", "taunt_anim");

            //These are the animations that are map specific
            if(ReturnMapName() == "Origins")
            {
                add_anims = Array("ai_zombie_mech_ft_burn_player", "ai_zombie_mech_exit", "ai_zombie_mech_exit_hover", "ai_zombie_mech_arrive");
                add_notifies = Array("flamethrower_anim", "zm_fly_out", "zm_fly_hover_finished", "zm_fly_in");
            }
            
            if(IsDefined(add_anims) && add_anims.size)
            {
                anims = ArrayCombine(anims, add_anims, 0, 1);
                notifies = ArrayCombine(notifies, add_notifies, 0, 1);
            }

            self addMenu("Animations");

                for(a = 0; a < anims.size; a++)
                    self addOpt(CleanString(anims[a]), &ZombieAnimScript, anims[a], notifies[a]);
            break;
        
        case "Zombie Model Manipulation":
            self addMenu("Model Manipulation");
                
                if(IsDefined(level.menu_models) && level.menu_models.size)
                {
                    self addOptBool(!IsDefined(level.ZombieModel), "Disable", &DisableZombieModel);
                    self addOpt("");

                    for(a = 0; a < level.menu_models.size; a++)
                        self addOptBool((IsDefined(level.ZombieModel) && level.ZombieModel == level.menu_models[a]), CleanString(level.menu_models[a]), &SetZombieModel, level.menu_models[a]);
                }
            break;
    }
}

function AIPrioritizePlayer(player)
{
    player endon("disconnect");
        
    player.AIPrioritizePlayer = BoolVar(player.AIPrioritizePlayer);
    
    if(Is_True(player.AIPrioritizePlayer))
    {
        if(Is_True(player.playerIgnoreMe))
            NoTarget(player);
        
        while(Is_True(player.AIPrioritizePlayer))
        {
            if(!Is_True(player.b_is_designated_target))
                player.b_is_designated_target = true;
            
            wait 0.1;
        }
    }
    else
    {
        player.b_is_designated_target = false;
    }
}

function SetZombiesDeathEffect(effect)
{
    if(!IsDefined(effect) || !IsString(effect) || effect == "" || IsDefined(level.ZombiesDeathFX) && level.ZombiesDeathFX == effect)
        level.ZombiesDeathFX = undefined;
    else
        level.ZombiesDeathFX = effect;
}

function SetZombiesDamageEffect(effect)
{
    if(!IsDefined(effect) || !IsString(effect) || effect == "" || IsDefined(level.ZombiesDamageFX) && level.ZombiesDamageFX == effect)
        level.ZombiesDamageFX = undefined;
    else
        level.ZombiesDamageFX = effect;
}

function ZombieAnimScript(anm, ntfy)
{
    zombies = GetAITeamArray(level.zombie_team);

    for(a = 0; a < zombies.size; a++)
    {
        if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]))
            continue;
        
        zombies[a] StopAnimScripted(0);
        zombies[a] AnimScripted(ntfy, zombies[a].origin, zombies[a].angles, anm);
    }
}

function SetZombieModel(model)
{
    if(IsDefined(level.ZombieModel) && model != level.ZombieModel || !IsDefined(level.ZombieModel))
    {
        level.ZombieModel = model;
        zombies = GetAITeamArray(level.zombie_team);

        if(IsDefined(zombies) && zombies.size)
        {
            foreach(zombie in zombies)
            {
                if(IsDefined(zombie) && IsAlive(zombie) && zombie.model != level.ZombieModel)
                {
                    if(!IsDefined(zombie.savedModel))
                        zombie.savedModel = zombie.model;
                    
                    zombie SetModel(level.ZombieModel);
                }
            }
        }

        spawner::add_archetype_spawn_function("zombie", &SetZombieSpawnModel);
    }
    else
    {
        DisableZombieModel();
    }
}

function SetZombieSpawnModel()
{
    while(!IsAlive(self))
        wait 0.1;
    
    self.savedModel = self.model;

    if(IsDefined(level.ZombieModel))
        self SetModel(level.ZombieModel);
}

function DisableZombieModel()
{
    level.ZombieModel = undefined;
    spawner::remove_global_spawn_function("zombie", &SetZombieSpawnModel);
    zombies = GetAITeamArray(level.zombie_team);

    if(IsDefined(zombies) && zombies.size)
    {
        foreach(zombie in zombies)
        {
            if(IsDefined(zombie) && IsAlive(zombie) && IsDefined(zombie.savedModel))
                zombie SetModel(zombie.savedModel);
        }
    }
}

function ZombieGibBone(bone)
{
    zombies = GetAITeamArray(level.zombie_team);

    for(a = 0; a < zombies.size; a++)
    {
        if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]))
            continue;
        
        switch(bone)
        {
            case "Random":
                switch(RandomInt(5))
                {
                    case 0:
                        zombies[a] thread zombie_utility::zombie_head_gib();
                        break;
                    
                    case 1:
                        thread gibserverutils::gibrightleg(zombies[a]);
                        break;
                    
                    case 2:
                        thread gibserverutils::gibleftleg(zombies[a]);
                        break;
                    
                    case 3:
                        thread gibserverutils::gibrightarm(zombies[a]);
                        break;
                    
                    case 4:
                        thread gibserverutils::gibleftarm(zombies[a]);
                        break;
                    
                    default:
                        zombies[a] thread zombie_utility::zombie_head_gib();
                        break;
                }
                break;
            
            case "Head":
                zombies[a] thread zombie_utility::zombie_head_gib();
                break;
            
            case "Right Leg":
                thread gibserverutils::gibrightleg(zombies[a]);
                break;
            
            case "Left Leg":
                thread gibserverutils::gibleftleg(zombies[a]);
                break;
            
            case "Right Arm":
                thread gibserverutils::gibrightarm(zombies[a]);
                break;
            
            case "Left Arm":
                thread gibserverutils::gibleftarm(zombies[a]);
                break;
            
            default:
                zombies[a] thread zombie_utility::zombie_head_gib();
                break;
        }
    }
}

function KillZombies(type = "Death")
{
    zombies = GetAITeamArray(level.zombie_team);

    for(a = 0; a < zombies.size; a++)
    {
        if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]))
            continue;
        
        switch(type)
        {
            case "Death":
                zombies[a] DoDamage((zombies[a].health + 666), zombies[a].origin);
                break;
            
            case "Head Gib":
                zombies[a] thread ZombieHeadGib();
                break;
            
            case "Flame":
                zombies[a] thread zombie_death::flame_death_fx();

                if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
                    zombies[a] DoDamage((zombies[a].health + 666), zombies[a].origin);
                break;
            
            case "Delete":
                zombies[a] Delete();
                break;
            
            default:
                break;
        }
    }
}

function ZombieHeadGib()
{
    if(!IsDefined(self) || !IsAlive(self))
        return;

    self endon("death");

    self clientfield::set("zm_bgb_mind_ray_fx", 1);
    wait RandomFloatRange(0.65, 2.5);

    self clientfield::set("zm_bgb_mind_pop_fx", 1);
    self PlaySoundOnTag("zmb_bgb_mindblown_pop", "tag_eye");
    self zombie_utility::zombie_head_gib();
    wait 0.1;

    if(IsDefined(self) && IsAlive(self))
        self DoDamage((self.health + 666), self.origin);
}

function SetZombieHealth(type)
{
    switch(type)
    {
        case "Custom":
            self thread NumberPad(&SetZombieSpawnHealth);
            break;
        
        case "Reset":
            spawner::remove_global_spawn_function("zombie", &EditZombieHealth);
            level SetZombieHealth1(GetZombieHealthFromRound(level.round_number));
            break;
        
        default:
            break;
    }
}

function SetZombieSpawnHealth(health)
{
    spawner::remove_global_spawn_function("zombie", &EditZombieHealth);
    wait 0.1;

    zombies = GetAITeamArray(level.zombie_team);
    
    for(a = 0; a < zombies.size; a++)
    {
        if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || IsDefined(zombies[a].maxhealth) && zombies[a].maxhealth == health)
            continue;
        
        zombies[a] thread EditZombieHealth(health);
    }

    //This will only apply to zombies that haven't spawned yet. The code above, will set the health of zombies that have already been spawned
    spawner::add_archetype_spawn_function("zombie", &EditZombieHealth, health);
}

function EditZombieHealth(health)
{
    while(!IsDefined(self.maxhealth) && IsDefined(self) && IsAlive(self))
        wait 0.1;
    
    if(IsDefined(self) && IsAlive(self))
    {
        self.maxhealth = health;
        self.health = health;
    }
}

function GetZombieHealthFromRound(round_number)
{
    zombie_health = level.zombie_vars["zombie_health_start"];

    for(a = 2; a <= round_number; a++)
    {
        if(a >= 10)
        {
            old_health = zombie_health;
            zombie_health = zombie_health + (Int(zombie_health * level.zombie_vars["zombie_health_increase_multiplier"]));

            if(zombie_health < old_health)
                return old_health;
        }
        else
        {
            zombie_health = Int(zombie_health + level.zombie_vars["zombie_health_increase"]);
        }
    }

    return zombie_health;
}

function SetZombieHealth1(health)
{
    level.zombie_health = health;
    zombies = GetAITeamArray(level.zombie_team);
    
    for(a = 0; a < zombies.size; a++)
    {
        if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || IsDefined(zombies[a].maxhealth) && zombies[a].maxhealth == health)
            continue;
        
        zombies[a].maxhealth = health;
        zombies[a].health = zombies[a].maxhealth;
    }
}

function SetZombieRunSpeed(speed)
{
    speed = ToLower(speed);

    if(speed == "super sprint")
        speed = "super_sprint";

    zombies = GetAITeamArray(level.zombie_team);

    for(a = 0; a < zombies.size; a++)
    {
        if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
            zombies[a] zombie_utility::set_zombie_run_cycle(speed);
    }
}

function KnockdownZombies(dir)
{
    switch(dir)
    {
        case "Back":
            knockDir = "front";
            upDir = "getup_back";
            break;
        
        case "Front":
            knockDir = "back";
            upDir = "getup_belly";
            break;
    }

    if(!IsDefined(knockDir) || !IsDefined(upDir))
        return;

    zombies = GetAITeamArray(level.zombie_team);
    
    foreach(zombie in zombies)
    {
        if(!IsDefined(zombie) || !IsAlive(zombie) || zombie.missinglegs || Is_True(zombie.knockdown))
            continue;
        
        zombie.knockdown = 1;
        zombie.knockdown_direction = knockDir;
        zombie.getup_direction = upDir;
        zombie.knockdown_type = "knockdown_shoved";

        BlackBoardAttribute(zombie, "_knockdown_direction", zombie.knockdown_direction);
        BlackBoardAttribute(zombie, "_knockdown_type", zombie.knockdown_type);
        BlackBoardAttribute(zombie, "_getup_direction", zombie.getup_direction);
    }
}

function PushZombies(dir)
{
    zombies = GetAITeamArray(level.zombie_team);
    
    foreach(zombie in zombies)
    {
        if(!IsDefined(zombie) || !IsAlive(zombie) || zombie.missinglegs || Is_True(zombie.pushed))
            continue;
        
        zombie.pushed = 1;
        zombie.push_direction = ToLower(dir);

        BlackBoardAttribute(zombie, "_push_direction", zombie.push_direction);
    }
}

function BlackBoardAttribute(entity, attributename, attributevalue)
{
    if(!IsDefined(entity) || !IsDefined(entity.__blackboard))
        return;
    
    if(IsDefined(entity.__blackboard[attributename]))
    {
        if(!IsDefined(attributevalue) && IsFunctionPtr(entity.__blackboard[attributename]))
            return;
    }

    entity.__blackboard[attributename] = attributevalue;
}

function TeleportZombies(loc)
{
    origin = ((IsString(loc) && loc == "Crosshairs") ? self TraceBullet() : self.origin);
    zombies = GetAITeamArray(level.zombie_team);

    for(a = 0; a < zombies.size; a++)
    {
        if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
        {
            zombies[a] StopAnimScripted(0);
            zombies[a] ForceTeleport(origin);
            zombies[a].find_flesh_struct_string = "find_flesh";
            zombies[a].ai_state = "find_flesh";
            zombies[a] notify("zombie_custom_think_done", "find_flesh");
        }
    }
}

function SetZombieAnimationSpeed(rate)
{
    spawner::remove_global_spawn_function("zombie", &ZombieAnimationWait);
    zombies = GetAITeamArray(level.zombie_team);

    if(IsDefined(zombies) && zombies.size)
    {
        for(a = 0; a < zombies.size; a++)
        {
            if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]))
                continue;
            
            if(rate != 1)
                zombies[a] thread ZombieAnimationWait(rate);
            else
                zombies[a] ASMSetAnimationRate(rate);
        }
    }

    if(rate != 1)
        spawner::add_archetype_spawn_function("zombie", &ZombieAnimationWait, rate);
}

function ZombieAnimationWait(rate)
{
    while(!CanControl(self) && IsAlive(self))
        wait 0.1;
    
    if(IsDefined(self) && IsAlive(self))
        self ASMSetAnimationRate(rate);
}

function ZombiesToCrosshairsLoop()
{
    level.ZombiesToCrosshairsLoop = BoolVar(level.ZombiesToCrosshairsLoop);

    if(Is_True(level.ZombiesToCrosshairsLoop))
    {
        origin = self TraceBullet();

        while(Is_True(level.ZombiesToCrosshairsLoop))
        {
            zombies = GetAITeamArray(level.zombie_team);

            for(a = 0; a < zombies.size; a++)
            {
                if(IsDefined(zombies[a]) && IsAlive(zombies[a]) && IsActor(zombies[a]))
                {
                    zombies[a] StopAnimScripted(0);
                    zombies[a] ForceTeleport(origin);
                }
            }

            wait 0.05;
        }
    }
}

function DisableZombieCollision()
{
    level.DisableZombieCollision = BoolVar(level.DisableZombieCollision);
    zombies = GetAITeamArray(level.zombie_team);

    if(Is_True(level.DisableZombieCollision))
        spawner::add_archetype_spawn_function("zombie", &DisableZombieSpawnCollision);
    else
        spawner::remove_global_spawn_function("zombie", &DisableZombieSpawnCollision);

    for(a = 0; a < zombies.size; a++)
    {
        if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
            zombies[a] SetPlayerCollision(!Is_True(level.DisableZombieCollision));
    }
}

function DisableZombieSpawnCollision()
{
    while(!IsAlive(self))
        wait 0.1;
    
    self SetPlayerCollision(0);
}

function DisableZombieSpawning()
{
    SetDvar("ai_disableSpawn", ((GetDvarString("ai_disableSpawn") == "0") ? "1" : "0"));
    KillZombies("Head Gib");
}

function DisableZombiePush()
{
    level.DisableZombiePush = BoolVar(level.DisableZombiePush);

    if(Is_True(level.DisableZombiePush))
    {
        while(Is_True(level.DisableZombiePush))
        {
            foreach(player in level.players)
                player SetClientPlayerPushAmount(0);

            wait 0.1;
        }
    }
    else
    {
        foreach(player in level.players)
            player SetClientPlayerPushAmount(1);
    }
}

function ZombiesInvisibility()
{
    level.ZombiesInvisibility = BoolVar(level.ZombiesInvisibility);

    if(Is_True(level.ZombiesInvisibility))
    {
        while(Is_True(level.ZombiesInvisibility))
        {
            zombies = GetAITeamArray(level.zombie_team);

            for(a = 0; a < zombies.size; a++)
            {
                if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
                    zombies[a] Hide();
            }

            wait 0.5;
        }
    }
    else
    {
        zombies = GetAITeamArray(level.zombie_team);

        for(a = 0; a < zombies.size; a++)
        {
            if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
                zombies[a] Show();
        }
    }
}

function FreezeZombies()
{
    SetDvar("g_ai", ((GetDvarString("g_ai") == "1") ? "0" : "1"));
}

function ZombieDeathSounds()
{
    level.ZombieDeathSounds = BoolVar(level.ZombieDeathSounds);
    zombies = GetAITeamArray(level.zombie_team);

    if(Is_True(level.ZombieDeathSounds))
        spawner::add_archetype_spawn_function("zombie", &ZombieDeathSound);
    else
        spawner::remove_global_spawn_function("zombie", &ZombieDeathSound);
    
    for(a = 0; a < zombies.size; a++)
    {
        if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
            zombies[a].bgb_tone_death = (Is_True(level.ZombieDeathSounds) ? true : undefined);
    }
}

function ZombieDeathSound()
{
    if(!IsDefined(self))
        return;
    
    self.bgb_tone_death = true;
}

function ZombieProjectileVomiting()
{
    level.ZombieProjectileVomiting = BoolVar(level.ZombieProjectileVomiting);

    while(Is_True(level.ZombieProjectileVomiting))
    {
        zombies = GetAITeamArray(level.zombie_team);

        for(a = 0; a < zombies.size; a++)
        {
            if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || Is_True(zombies[a].ProjectileVomit))
                continue;
            
            zombies[a] thread ZombieProjectileVomit();
        }

        wait 0.1;
    }
}

function ZombieProjectileVomit()
{
    if(!IsDefined(self) || !IsAlive(self) || Is_True(self.ProjectileVomit))
        return;
    
    self endon("death");
    
    self.ProjectileVomit = true;
    self clientfield::increment("projectile_vomit", 1);
    wait 6;

    if(Is_True(self.ProjectileVomit))
        self.ProjectileVomit = BoolVar(self.ProjectileVomit);
}

function DisappearingZombies()
{
    level.DisappearingZombies = BoolVar(level.DisappearingZombies);
    zombies = GetAITeamArray(level.zombie_team);

    if(Is_True(level.DisappearingZombies))
    {
        spawner::add_archetype_spawn_function("zombie", &ZombieSpawnDisappearingZombie);
    }
    else
    {
        spawner::remove_global_spawn_function("zombie", &ZombieSpawnDisappearingZombie);
        level notify("EndDisappearingZombies");
    }

    for(a = 0; a < zombies.size; a++)
    {
        if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
        {
            if(Is_True(level.DisappearingZombies))
            {
                zombies[a] thread DisappearingZombie();
            }
            else
            {
                if(Is_True(zombies[a].disappearing))
                    zombies[a].disappearing = BoolVar(zombies[a].disappearing);

                if(!Is_True(level.ZombiesInvisibility))
                    zombies[a] Show();
                else
                    zombies[a] Hide();
            }
        }
    }
}

function ZombieSpawnDisappearingZombie()
{
    while(!IsAlive(self))
        wait 0.1;
    
    self thread DisappearingZombie();
}

function DisappearingZombie()
{
    if(Is_True(self.disappearing))
        return;
    self.disappearing = true;

    if(!IsDefined(self) || !IsAlive(self))
        return;
    
    level endon("EndDisappearingZombies");
    
    while(IsDefined(self) && IsAlive(self))
    {
        self Hide();
        wait RandomFloatRange(1, 5);

        if(IsDefined(self) && IsAlive(self))
            self Show();
        
        wait RandomFloatRange(1, 5);
    }
}

function ExplodingZombies()
{
    level.ExplodingZombies = BoolVar(level.ExplodingZombies);

    if(Is_True(level.ExplodingZombies))
    {
        while(Is_True(level.ExplodingZombies))
        {
            zombies = GetAITeamArray(level.zombie_team);

            for(a = 0; a < zombies.size; a++)
            {
                if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || Is_True(zombies[a].explodingzombie))
                    continue;
                
                zombies[a].explodingzombie = true;
                zombies[a] clientfield::set("arch_actor_fire_fx", 1);
                zombies[a] thread ZombieBurnPlayers();
            }
            
            wait 0.01;
        }
    }
    else
    {
        zombies = GetAITeamArray(level.zombie_team);

        for(a = 0; a < zombies.size; a++)
        {
            if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || !Is_True(zombies[a].explodingzombie))
                continue;
            
            zombies[a] clientfield::set("arch_actor_fire_fx", 0);
            zombies[a].explodingzombie = BoolVar(zombies[a].explodingzombie);

            if(Is_True(zombies[a].burnplayers))
                zombies[a].burnplayers = BoolVar(zombies[a].burnplayers);
        }
    }
}

function ZombieBurnPlayers()
{
    if(Is_True(self.burnplayers))
        return;
    self.burnplayers = true;

    self endon("death");

    while(IsAlive(self) && Is_True(level.ExplodingZombies))
    {
        foreach(player in GetPlayers())
        {
            if(DistanceSquared(player.origin, self.origin) <= 9216 && !Is_True(player.is_burning) && zombie_utility::is_player_valid(player, 0))
                player function_3389e2f3(self);
        }

        wait 0.1;
    }
}

function ZombieRagdoll()
{
    level.ZombieRagdoll = BoolVar(level.ZombieRagdoll);
}

function StackZombies()
{
    level endon("EndStackZombies");
    
    level.StackZombies = BoolVar(level.StackZombies);

    if(Is_True(level.StackZombies))
    {
        while(Is_True(level.StackZombies))
        {
            zombies = GetAITeamArray(level.zombie_team);

            for(a = 0; a < zombies.size; a++)
            {
                if(!CanControl(zombies[a]) || Is_True(zombies[a].stacked))
                    continue;
                
                tag = "tag_origin"; //Had to choose a tag that doesn't move/rotate
                tagCheck = zombies[a] GetTagOrigin(tag); //Gonna be used to make sure it's a valid tag for the ai
                offset = (0, 0, 70); //(x, y, z) offset for the given tag

                if(!IsDefined(tagCheck))
                {
                    tag = "tag_body"; //Backup tag for ai that don't have the default tag given
                    tagCheck = zombies[a] GetTagOrigin(tag);
                }

                if(!IsDefined(tagCheck)) //If the backup tag can't be used for the AI, then it will be skipped
                    continue;
                
                bottom = zombies[a];
                top = undefined;

                for(b = 0; b < zombies.size; b++)
                {
                    if(!CanControl(zombies[b]) || Is_True(zombies[b].stacked) || IsDefined(zombies[b]) && zombies[b] == bottom)
                        continue;
                    
                    top = zombies[b];
                    break;
                }

                if(IsDefined(bottom) && IsDefined(top))
                {
                    top LinkTo(bottom, tag, offset);
                    bottom thread StackedZombieWatcher(top);

                    top.stacked = true;
                    bottom.stacked = true;
                }
            }

            wait 1;
        }
    }
    else
    {
        zombies = GetAITeamArray(level.zombie_team);

        for(a = 0; a < zombies.size; a++)
        {
            if(!IsDefined(zombies[a]) || !IsAlive(zombies[a]) || !Is_True(zombies[a].stacked))
                continue;
            
            zombies[a] Unlink();

            if(Is_True(zombies[a].stacked))
                zombies[a].stacked = BoolVar(zombies[a].stacked);
        }

        level notify("EndStackZombies");
    }
}

function StackedZombieWatcher(top)
{
    if(!IsDefined(self) || !IsAlive(self) || !IsDefined(top) || !IsAlive(top))
        return;
    
    level endon("EndStackZombies");
    top endon("death");

    self waittill("death");

    if(IsDefined(top) && IsAlive(top))
    {
        top Unlink();

        if(Is_True(top.stacked))
            top.stacked = BoolVar(top.stacked);
    }
}

function RemoveZombieEyes()
{
    level.RemoveZombieEyes = BoolVar(level.RemoveZombieEyes);
    zombies = GetAITeamArray(level.zombie_team);

    if(Is_True(level.RemoveZombieEyes))
    {
        spawner::add_archetype_spawn_function("zombie", &ZombieSpawnNoEyes);

        foreach(zombie in zombies)
        {
            if(!IsDefined(zombie) || !IsAlive(zombie) || Is_True(zombie.no_eye_glow))
                continue;
            
            zombie clientfield::set("zombie_has_eyes", 0);
            zombie.no_eye_glow = true;
        }
    }
    else
    {
        spawner::remove_global_spawn_function("zombie", &ZombieSpawnNoEyes);

        foreach(zombie in zombies)
        {
            if(!IsDefined(zombie) || !IsAlive(zombie) || !Is_True(zombie.no_eye_glow))
                continue;
            
            zombie clientfield::set("zombie_has_eyes", 1);
            zombie.no_eye_glow = false;
        }
    }
}

function ZombieSpawnNoEyes()
{
    if(Is_True(self.no_eye_glow))
        return;
    
    self clientfield::set("zombie_has_eyes", 0);
    self.no_eye_glow = true;
}

function BodiesFloat()
{
    SetDvar("phys_gravity_dir", ((GetDvarVector("phys_gravity_dir") == (0, 0, -1)) ? (0, 0, 1) : (0, 0, -1)));
}

function ForceZombieCrawlers()
{
    zombies = GetAITeamArray(level.zombie_team);

    for(a = 0; a < zombies.size; a++)
    {
        if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
            zombies[a] zombie_utility::makezombiecrawler(true);
    }
}

function DetachZombieHeads()
{
    zombies = GetAITeamArray(level.zombie_team);
    
    for(a = 0; a < zombies.size; a++)
    {
        if(IsDefined(zombies[a]) && IsAlive(zombies[a]))
            zombies[a] DetachAll();
    }
}

function ServerClearCorpses()
{
    corpse_array = GetCorpseArray();

    if(IsDefined(corpse_array) && corpse_array.size)
    {
        for(a = 0; a < corpse_array.size; a++)
        {
            if(IsDefined(corpse_array[a]))
                corpse_array[a] Delete();
        }
    }
}

// ============================================================
// Menu/base.gsc
// ============================================================

#define OPT_NAME 0
#define OPT_FUNC 1
#define OPT_IN1 2
#define OPT_IN2 3
#define OPT_IN3 4
#define OPT_IN4 5
#define OPT_BOOL 6
#define OPT_BOOLOPT 7
#define OPT_SHADER 8
#define OPT_COLOR 9
#define OPT_INCSLIDER 10
#define OPT_MIN 11
#define OPT_MAX 12
#define OPT_START 13
#define OPT_INCREMENT 14
#define OPT_SLIDER 15
#define OPT_SLIDERVALUES 16

function menuMonitor()
{
    if(Is_True(self.menuMonitor))
        return;
    self.menuMonitor = true;

    self endon("endMenuMonitor");
    self endon("disconnect");

    while(1)
    {
        if(self hasMenu() && !Is_True(self.DisableMenuControls))
        {
            if(!self isInMenu(true))
            {
                self.menuUI = [];
                
                if(self AreButtonsPressed(self.OpenControls) && Is_Alive(self))
                {
                    self openMenu1();
                    wait 0.5;
                }
                else if(Is_Alive(self) && self AreButtonsPressed(self.QuickControls) || !Is_Alive(self) && self AdsButtonPressed() && self JumpButtonPressed())
                {
                    if(!Is_True(self.DisableQM))
                    {
                        self openQuickMenu1();
                        wait 0.5;
                    }
                }
            }
            else
            {
                if(self isInMenu(false) && !Is_Alive(self))
                    self closeMenu1();
                
                if(ReturnMapName() != "Origins")
                    self SetActionSlot(3, "");
                
                self SetActionSlot(1, "");

                if(Is_True(self.MenuNoTarget))
                    self.ignoreme = true;

                menu = self getCurrent();
                curs = self getCursor();

                if((self AdsButtonPressed() || self ActionSlotOneButtonPressed()) && !(self AttackButtonPressed() || self ActionSlotTwoButtonPressed()) || (self AttackButtonPressed() || self ActionSlotTwoButtonPressed()) && !(self AdsButtonPressed() || self ActionSlotOneButtonPressed()))
                {
                    dir = ((self AdsButtonPressed() || self ActionSlotOneButtonPressed()) ? -1 : 1);

                    self setCursor(curs + dir);
                    self ScrollingSystem(dir, curs);

                    wait (self.ScrollAnimationTime + 0.025);
                }
                else if(self UseButtonPressed())
                {
                    if(IsDefined(self.menuStructure) && IsDefined(self.menuStructure[curs]) && IsDefined(self GetOption(curs, OPT_FUNC)))
                    {
                        optSlider = self GetOption(curs, OPT_SLIDER);
                        optIncSlider = self GetOption(curs, OPT_INCSLIDER);
                        sliderValues = self GetOption(curs, OPT_SLIDERVALUES);

                        if(Is_True(optSlider) || Is_True(optIncSlider))
                        {
                            self ExeFunction(self GetOption(curs, OPT_FUNC), (Is_True(optSlider) ? sliderValues[self.menuSlider[menu][curs]] : self.menuSlider[menu][curs]), self GetOption(curs, OPT_IN1), self GetOption(curs, OPT_IN2), self GetOption(curs, OPT_IN3), self GetOption(curs, OPT_IN4));
                        }
                        else
                        {
                            self ExeFunction(self GetOption(curs, OPT_FUNC), self GetOption(curs, OPT_IN1), self GetOption(curs, OPT_IN2), self GetOption(curs, OPT_IN3), self GetOption(curs, OPT_IN4));
                            boolOpt = self GetOption(curs, OPT_BOOLOPT);

                            if(IsDefined(self.menuStructure) && IsDefined(self.menuStructure[curs]) && Is_True(boolOpt))
                            {
                                wait 0.18;
                                self RefreshMenu(menu, curs);
                            }
                        }

                        wait 0.2;
                    }
                }
                else if(self ActionslotThreeButtonPressed() && !self ActionSlotFourButtonPressed() || self ActionslotFourButtonPressed() && !self ActionSlotThreeButtonPressed())
                {
                    optSlider = self GetOption(curs, OPT_SLIDER);
                    optIncSlider = self GetOption(curs, OPT_INCSLIDER);
                    
                    if(IsDefined(self.menuStructure) && (Is_True(optSlider) || Is_True(optIncSlider)))
                    {
                        dir = (self ActionslotThreeButtonPressed() ? -1 : 1);

                        if(Is_True(optSlider))
                            self SetSlider(dir);
                        else
                            self SetIncSlider(dir);
                        
                        wait 0.13;
                    }
                }
                else if(self MeleeButtonPressed() || !Is_Alive(self) && self JumpButtonPressed())
                {
                    if(menu == "Main" || menu == "Quick Menu")
                    {
                        if(self isInQuickMenu())
                            self closeQuickMenu();
                        else
                            self closeMenu1();
                    }
                    else
                    {
                        if(Is_True(self.QuickExit))
                        {
                            goal = 10;
                            count = 0;

                            while(self MeleeButtonPressed())
                            {
                                count++;

                                if(count >= goal)
                                    break;
                                
                                wait 0.01;
                            }

                            if(count >= goal)
                            {
                                if(self isInQuickMenu())
                                    self closeQuickMenu();
                                else
                                    self closeMenu1();
                            }
                            else
                            {
                                self newMenu();
                            }
                        }
                        else
                        {
                            self newMenu();
                        }
                    }

                    wait 0.2;
                }
            }
        }

        wait 0.05;
    }
}

function ExeFunction(fnc, i1, i2, i3, i4, i5, i6)
{
    self endon("disconnect");

    if(!IsDefined(fnc))
        return;
    
    if(IsDefined(i6))
        return self thread [[ fnc ]](i1, i2, i3, i4, i5, i6);
    
    if(IsDefined(i5))
        return self thread [[ fnc ]](i1, i2, i3, i4, i5);
    
    if(IsDefined(i4))
        return self thread [[ fnc ]](i1, i2, i3, i4);
    
    if(IsDefined(i3))
        return self thread [[ fnc ]](i1, i2, i3);
    
    if(IsDefined(i2))
        return self thread [[ fnc ]](i1, i2);
    
    if(IsDefined(i1))
        return self thread [[ fnc ]](i1);

    return self thread [[ fnc ]]();
}

function openMenu1(showAnim = true)
{
    self endon("disconnect");

    self.isInMenu = true;
    wait 0.05;

    if(!IsDefined(self.currentMenu) || self.currentMenu == "")
        self.currentMenu = "Main";
    
    if(!IsDefined(self.menu_parent))
        self.menu_parent = [];

    if(isInArray(self.menu_parent, "Players") && IsDefined(self.SavedSelectedPlayer))
        self.SelectedPlayer = self.SavedSelectedPlayer;

    self createMenuHud();
    self drawText(showAnim);

    if(self getCurrent() == "Players" && !Is_True(self.PlayerInfoHandler))
        self thread PlayerInfoHandler();
}

function closeMenu1(showAnim = false)
{
    self endon("disconnect");

    if(self isInQuickMenu())
    {
        self closeQuickMenu();
        return;
    }

    if(!self isInMenu())
        return;
    
    self notify("menuClosed");
    self.CreditsPlaying = undefined;

    destroyAll(self.menuUI);
    self.menuUI = undefined;
    self.menuStructure = undefined;

    if(Is_True(self.isInMenu))
        self.isInMenu = BoolVar(self.isInMenu);

    self.DisableMenuControls = undefined;

    if(ReturnMapName() != "Origins")
        self SetActionSlot(3, "altMode");
    
    if(IsDefined(self.bgb) && self.bgb != "none")
        self SetActionSlot(1, "bgb");
    
    if(!Is_True(self.playerIgnoreMe) && Is_True(self.MenuNoTarget))
        self.ignoreme = false;
}

function openQuickMenu1()
{
    self endon("disconnect");

    self.isInQuickMenu = true;
    self.SelectedPlayer = self;

    if(!IsDefined(self.menu_parentQM))
        self.menu_parentQM = [];

    if(!IsDefined(self.currentMenuQM))
        self.currentMenuQM = "Quick Menu";
    
    self createMenuHud();
    self drawText(true);
}

function closeQuickMenu()
{
    if(!self isInQuickMenu())
        return;
    
    self endon("disconnect");

    destroyAll(self.menuUI);
    self.menuUI = undefined;
    self.menuStructure = undefined;

    if(Is_True(self.isInQuickMenu))
        self.isInQuickMenu = BoolVar(self.isInQuickMenu);
    
    self.DisableMenuControls = undefined;

    if(ReturnMapName() != "Origins")
        self SetActionSlot(3, "altMode");
    
    if(IsDefined(self.bgb) && self.bgb != "none")
        self SetActionSlot(1, "bgb");
    
    if(!Is_True(self.playerIgnoreMe) && Is_True(self.MenuNoTarget))
        self.ignoreme = false;
}

function drawText(showAnim = false)
{
    self endon("menuClosed");
    self endon("disconnect");

    self DestroyOpts();
    self RunMenuOptions(self getCurrent());
    self SetMenuTitle();

    if(!IsDefined(self.menuStructure) || !self.menuStructure.size)
        self addOpt("No Options Found");
    
    cursor = self getCursor();
    maxOptions = self GetMaxOptions();
    
    if(!IsDefined(cursor))
        self setCursor(0);
    
    if(self getCursor() >= self.menuStructure.size)
        self setCursor((self.menuStructure.size - 1));
    
    hud = Array("text", "subMenu", "BoolOpt", "BoolBack", "BoolText", "IntSlider", "StringSlider", "invalidOption");
    numOpts = ((self.menuStructure.size > maxOptions) ? maxOptions : self.menuStructure.size);
    start = self GetScrollStart(self getCursor());

    for(a = 0; a < hud.size; a++)
    {
        if(!IsDefined(self.menuUI[hud[a]]))
            self.menuUI[hud[a]] = [];
    }

    offset = ((self.MenuDesign == "Classic") ? 11 : ((self.MenuDesign == "AIO") ? 15 : ((self.MenuDesign == "Basic") ? 30 : 8)));
    startY = (self.menuUI["background"].y + offset);

    for(a = 0; a < numOpts; a++)
    {
        self createOption((start + a), (startY + (a * 18)), ((start + a) == self getCursor()), showAnim);

        if(Is_True(showAnim))
        {
            for(b = 0; b < hud.size; b++)
            {
                if(!IsDefined(self.menuUI[hud[b]]) || !self.menuUI[hud[b]].size || !IsDefined(self.menuUI[hud[b]][(start + a)]))
                    continue;
                
                self.menuUI[hud[b]][(start + a)] thread hudFade(((Is_True(self.SpotlightCursor) && ((start + a) != self getCursor())) ? 0.4 : 1), (a * 0.1));
            }
        }
    }

    if(!IsDefined(self.menuUI["text"][self getCursor()]))
        self.menuCursor[self getCurrent()] = (self.menuStructure.size - 1);
    
    if(IsDefined(self.menuUI["scroller"]) && IsDefined(self.menuUI["text"][self getCursor()]))
    {
        scrollOffset = ((self.MenuDesign == "AIO") ? 11 : 8);
        self.menuUI["scroller"].y = (self.menuUI["text"][self getCursor()].y - scrollOffset);

        if(IsDefined(self.menuUI["cursIndex"]))
        {
            self.menuUI["cursIndex"] SetValue(self getCursor() + 1);
            self.menuUI["optCount"] SetValue(self.menuStructure.size);

            if(IsDefined(self.menuUI["cursIndex"]))
            {
                posOffset = ((self.menuStructure.size >= 10) ? 16 : 12);

                self.menuUI["counterSep"].x = self.menuUI["background"].x + (self.menuUI["background"].width - posOffset);
                self.menuUI["cursIndex"].x = self.menuUI["counterSep"].x - 3;
                self.menuUI["optCount"].x = self.menuUI["counterSep"].x + 3;
            }
        }
    }

    if(IsDefined(self.menuUI) && IsDefined(self.menuUI["text"]) && self.menuUI["text"].size)
    {
        heightOffset = ((self.MenuDesign == "Classic") ? 25 : ((self.MenuDesign == "AIO") ? 31 : ((self.MenuDesign == "Basic") ? 40 : 18)));

        if(IsDefined(self.menuUI["background"]))
            self.menuUI["background"] SetShaderValues(undefined, undefined, (heightOffset + (18 * (self.menuUI["text"].size - 1))));

        if(IsDefined(self.menuUI["banner"]) && (self.MenuDesign == GetMenuName() || self.MenuDesign == "Classic"))
        {
            bannerOffset = ((self.MenuDesign == GetMenuName()) ? 35 : 14);
            self.menuUI["banner"] SetShaderValues(undefined, undefined, bannerOffset + self.menuUI["background"].height);
        }

        if(IsDefined(self.menuUI["bottomLine"]))
        {
            self.menuUI["bottomLine"].y = (self.menuUI["background"].y + self.menuUI["background"].height);

            if(IsDefined(self.menuUI["cursIndex"]))
            {
                self.menuUI["counterSep"].y = self.menuUI["bottomLine"].y + (self.menuUI["bottomLine"].height + 7);
                self.menuUI["cursIndex"].y = self.menuUI["bottomLine"].y + (self.menuUI["bottomLine"].height + 7);
                self.menuUI["optCount"].y = self.menuUI["bottomLine"].y + (self.menuUI["bottomLine"].height + 7);
            }

            if(self.MenuDesign == "AIO")
            {
                if(IsDefined(self.menuUI["menuName"]))
                    self.menuUI["menuName"].y = (self.menuUI["bottomLine"].y + ((self.menuUI["bottomLine"].height / 2) - 1));
                
                if(IsDefined(self.menuUI["backgroundouter"]))
                    self.menuUI["backgroundouter"] SetShaderValues(undefined, undefined, (4 + (self.menuUI["background"].height + self.menuUI["separator"].height + self.menuUI["bottomLine"].height)));
            }
        }
    }
}

function createOption(index = 0, optY = 0, selected = false, fadeIn = false)
{
    boolVal = self GetOption(index, OPT_BOOL);
    boolOpt = self GetOption(index, OPT_BOOLOPT);
    optName = self GetOption(index, OPT_NAME);
    optFunc = self GetOption(index, OPT_FUNC);
    optSlider = self GetOption(index, OPT_SLIDER);
    optIncSlider = self GetOption(index, OPT_INCSLIDER);
    sliderValues = self GetOption(index, OPT_SLIDERVALUES);

    fontColor = ((!selected || self.MenuDesign == "Native" || self.MenuDesign == "Classic" || !Is_True(self.ColoredCursor)) ? (1, 1, 1) : self.MainTheme);
    fontScale = ((Is_True(self.LargeCursor) && selected) ? 1.2 : 1);
    alpha = (Is_True(fadeIn) ? 0 : ((Is_True(self.SpotlightCursor) && !selected) ? 0.4 : 1));
    optX = (self.menuUI["background"].x + 4);

    if(Is_True(boolOpt) && self.BoolDisplay != "Text Color")
    {
        if(self.BoolDisplay == "Boxes")
        {
            boxX = ((self.BoolLocation == "Left") ? (self.menuUI["background"].x + 9) : (self.menuUI["background"].x + (self.menuUI["background"].width - 8)));

            self.menuUI["BoolBack"][index] = self createRectangle("CENTER", boxX, optY, 10, 10, (0.25, 0.25, 0.25), 5, alpha, "white");
            self.menuUI["BoolOpt"][index] = self createRectangle("CENTER", boxX, optY, 8, 8, (Is_True(boolVal) ? self.MainTheme : (0, 0, 0)), 6, alpha, "white");
            
            if(self.BoolLocation == "Left")
                optX = ((self.menuUI["BoolBack"][index].x + (self.menuUI["BoolBack"][index].width / 2)) + 4);
        }
        else
        {
            self.menuUI["BoolText"][index] = self createText("default", fontScale, 5, (Is_True(boolVal) ? "ON" : "OFF"), "RIGHT", (self.menuUI["background"].x + (self.menuUI["background"].width - 4)), optY, alpha, fontColor);
        }
    }

    if(IsDefined(optFunc) && optFunc == &newMenu)
        self.menuUI["subMenu"][index] = self createText("default", fontScale, 5, ">", "RIGHT", (self.menuUI["background"].x + (self.menuUI["background"].width - 4)), optY, alpha, fontColor);

    if(Is_True(optIncSlider))
        self.menuUI["IntSlider"][index] = self createText("default", fontScale, 5, self.menuSlider[self getCurrent()][index], "RIGHT", (self.menuUI["background"].x + (self.menuUI["background"].width - 4)), optY, alpha, fontColor);

    if(Is_True(optSlider))
        self.menuUI["StringSlider"][index] = self createText("default", fontScale, 5, "< " + sliderValues[self.menuSlider[self getCurrent()][index]] + " > [" + (self.menuSlider[self getCurrent()][index] + 1) + "/" + sliderValues.size + "]", "RIGHT", (self.menuUI["background"].x + (self.menuUI["background"].width - 4)), optY, alpha, fontColor);

    self.menuUI["text"][index] = self createText("default", fontScale, 5, optName, "LEFT", optX, optY, alpha, ((self.BoolDisplay == "Text Color" && Is_True(boolOpt) && Is_True(boolVal)) ? (0, 1, 0) : fontColor));

    if(IsInvalidOption(optName))
        self.menuUI["invalidOption"][index] = self createRectangle("CENTER", (self.menuUI["background"].x + (self.menuUI["background"].width / 2)), optY, (self.MenuWidth - 60), 1, self.MainTheme, 5, 0.4, "white");
}

function ScrollingSystem(dir, OldCurs)
{
    self endon("menuClosed");
    self endon("disconnect");

    curs = self getCursor();
    hud = Array("text", "BoolOpt", "BoolBack", "BoolText", "subMenu", "IntSlider", "StringSlider", "invalidOption");
    size = self.menuStructure.size;
    maxOptions = self GetMaxOptions();
    time = self.ScrollAnimationTime;

    if(curs < 0 || curs > (size - 1))
    {
        self setCursor(((curs < 0) ? (size - 1) : 0));

        curs = self getCursor();
        OldCurs = curs;

        if(size > maxOptions)
        {
            self RefreshMenu();
            return;
        }
    }
    else
    {
        oldStart = self GetScrollStart(OldCurs);
        newStart = self GetScrollStart(curs);

        if(size > maxOptions && oldStart != newStart)
        {
            diff = (newStart - oldStart);

            if(diff != 1 && diff != -1)
            {
                self RefreshMenu();
                return;
            }

            scrollDown = (newStart > oldStart);
            anchorRow = (scrollDown ? ((oldStart + maxOptions) - 1) : oldStart);

            if(!IsDefined(self.menuUI["text"][anchorRow]))
            {
                self RefreshMenu();
                return;
            }

            remove = (scrollDown ? oldStart : ((oldStart + maxOptions) - 1));
            create = (scrollDown ? (oldStart + maxOptions) : (oldStart - 1));
            optsStart = (scrollDown ? (oldStart + 1) : oldStart);
            optsEnd = (scrollDown ? ((oldStart + maxOptions) - 1) : ((oldStart + maxOptions) - 2));
            optY = self.menuUI["text"][anchorRow].y;

            for(a = 0; a < hud.size; a++)
            {
                if(IsDefined(self.menuUI[hud[a]][remove]))
                {
                    if(time > 0)
                        self.menuUI[hud[a]][remove] thread hudFadeDestroy(0, time);
                    else
                        self.menuUI[hud[a]][remove] DestroyHud();

                    self.menuUI[hud[a]][remove] = undefined;
                }
            }

            for(a = optsStart; a <= optsEnd; a++)
            {
                for(b = 0; b < hud.size; b++)
                {
                    if(!IsDefined(self.menuUI[hud[b]][a]) || Is_True(self.menuUI[hud[b]][a].fadeDestroy))
                        continue;

                    newY = (scrollDown ? (self.menuUI[hud[b]][a].y - 18) : (self.menuUI[hud[b]][a].y + 18));

                    if(self.menuUI[hud[b]][a].y != newY)
                        self.menuUI[hud[b]][a] thread hudMoveY(newY, time);
                }
            }

            self createOption(create, optY, self getCursor() == create, true);
            self HudArchiveState(newStart, maxOptions, hud);

            for(a = 0; a < hud.size; a++)
            {
                if(IsDefined(self.menuUI[hud[a]][create]))
                    self.menuUI[hud[a]][create] thread hudFade(((Is_True(self.SpotlightCursor) && create != curs || hud[a] == "invalidOption") ? 0.4 : 1), time);
            }
        }
    }

    if(IsDefined(self.menuStructure[curs]) && IsInvalidOption(self GetOption(curs, OPT_NAME)))
    {
        wait (time / 2);
        self setCursor(curs + dir);

        if(oldStart != newStart)
        {
            self RefreshMenu();
            return;
        }

        return self ScrollingSystem(dir, curs);
    }

    for(a = 0; a < size; a++)
    {
        for(b = 0; b < hud.size; b++)
        {
            if(!IsDefined(self.menuUI[hud[b]][a]) || hud[b] == "invalidOption" || Is_True(self.menuUI[hud[b]][a].fadeDestroy))
                continue;
            
            if(hud[b] != "BoolOpt" && hud[b] != "BoolBack")
            {
                boolVal = self GetOption(a, OPT_BOOL);
                boolOpt = self GetOption(a, OPT_BOOLOPT);

                self.menuUI[hud[b]][a] hudFadeColor(((self.BoolDisplay == "Text Color" && Is_True(boolOpt) && Is_True(boolVal)) ? (0, 1, 0) : ((curs != a || self.MenuDesign == "Native" || self.MenuDesign == "Classic" || !Is_True(self.ColoredCursor)) ? (1, 1, 1) : self.MainTheme)), time);
                self.menuUI[hud[b]][a] ChangeFontscaleOverTime1(((Is_True(self.LargeCursor) && curs == a) ? 1.2 : 1), time);
            }

            self.menuUI[hud[b]][a] thread hudFade(((Is_True(self.SpotlightCursor) && a != curs || hud[b] == "invalidOption") ? 0.4 : 1), time);
        }
    }
    
    scrollOffset = ((self.MenuDesign == "AIO") ? 11 : 8);
    scrollPos = (self.menuUI["text"][curs].y - scrollOffset);

    if(IsDefined(self.menuUI["scroller"]) && IsDefined(self.menuUI["text"][curs]) && self.menuUI["scroller"].y != scrollPos)
        self.menuUI["scroller"] thread hudMoveY(scrollPos, time);
    
    if(IsDefined(self.menuUI["cursIndex"]))
        self.menuUI["cursIndex"] SetValue(curs + 1);
}

function HudArchiveState(start, maxOptions, hud)
{
    end = ((start + maxOptions) - 1);
    count = self.hud_count;

    for(a = start; a <= end; a++)
    {
        for(b = 0; b < hud.size; b++)
        {
            if(IsDefined(self.menuUI[hud[b]][a]) && !Is_True(self.menuUI[hud[b]][a].fadeDestroy))
                count--;
        }
    }

    if(count < 0)
        count = 0;

    newCount = count;

    for(a = start; a <= end; a++)
    {
        for(b = 0; b < hud.size; b++)
        {
            if(!IsDefined(self.menuUI[hud[b]][a]) || Is_True(self.menuUI[hud[b]][a].fadeDestroy))
                continue;

            self.menuUI[hud[b]][a].archived = self ShouldArchive(newCount);
            newCount++;
        }
    }
}

function GetScrollStart(cursor)
{
    if(!IsDefined(self.menuStructure) || !self.menuStructure.size)
        return 0;

    size = self.menuStructure.size;
    maxOptions = self GetMaxOptions();

    if(size <= maxOptions)
        return 0;

    sub = Int((maxOptions - 1) / 2);
    add = Int((maxOptions + 1) / 2);

    if(cursor <= sub)
        return 0;

    if(cursor >= (size - add))
        return (size - maxOptions);

    return (cursor - sub);
}

function SoftLockMenu(bgHeight = 100, hideScroller = false)
{
    if(!self hasMenu() || self hasMenu() && !self isInMenu())
        return;

    self endon("disconnect");

    self.DisableMenuControls = true;
    self DestroyOpts();

    destroyHud = Array("counterSep", "cursIndex", "optCount");

    for(a = 0; a < destroyHud.size; a++)
    {
        if(IsDefined(self.menuUI[destroyHud[a]]))
            self.menuUI[destroyHud[a]] DestroyHud();
    }

    if(IsDefined(self.menuUI["scroller"]) && hideScroller)
        self.menuUI["scroller"].alpha = 0;

    if(IsDefined(self.menuUI["background"]))
        self.menuUI["background"] SetShaderValues(undefined, self.MenuWidth, bgHeight);
    
    if(IsDefined(self.menuUI["banner"]) && (self.MenuDesign == GetMenuName() || self.MenuDesign == "Classic"))
    {
        bannerOffset = ((self.MenuDesign == GetMenuName()) ? 35 : 14);
        self.menuUI["banner"] SetShaderValues(undefined, undefined, bannerOffset + self.menuUI["background"].height);
    }

    if(IsDefined(self.menuUI["bottomLine"]))
        self.menuUI["bottomLine"].y = self.menuUI["background"].y + (self.menuUI["background"].height - 1);

    if(self.MenuDesign == "AIO")
    {
        if(IsDefined(self.menuUI["menuName"]))
            self.menuUI["menuName"].y = self.menuUI["bottomLine"].y + ((self.menuUI["bottomLine"].height / 2) - 1);
        
        if(IsDefined(self.menuUI["backgroundouter"]))
            self.menuUI["backgroundouter"] SetShaderValues(undefined, undefined, (3 + (self.menuUI["background"].height + self.menuUI["separator"].height + self.menuUI["bottomLine"].height)));
    }
}

function SoftUnlockMenu()
{
    if(!self hasMenu() || !self isInMenu())
        return;
    
    self endon("disconnect");
    
    self.CreditsPlaying = undefined;

    self closeMenu1();
    self.DisableMenuControls = true;

    self openMenu1(false);
    wait 0.1;

    self.DisableMenuControls = undefined;
}

function SetMenuTitle(title)
{
    self endon("disconnect");

    if(!IsDefined(self.menuUI["title"]))
        return;

    if(!IsDefined(title))
        title = self.menuTitle;

    self.menuUI["title"] SetTextString(title);
}

function RefreshMenu(menu, curs, force)
{
    self endon("disconnect");

    if(IsDefined(menu) && !IsDefined(curs) || !IsDefined(menu) && IsDefined(curs))
        return;
    
    if(IsDefined(menu) && IsDefined(curs))
    {
        foreach(player in level.players)
        {
            if(!IsDefined(player) || !IsDefined(player.menuUI) || !player hasMenu() || !player isInMenu(true) || Is_True(player.DisableMenuControls))
                continue;
            
            if(player getCurrent() == menu || self != player && player PlayerHasOption(self, menu, curs))
            {
                if(IsDefined(player.menuUI["text"][curs]) || player == self && player getCurrent() == menu && IsDefined(player.menuUI["text"][curs]) || self != player && player PlayerHasOption(self, menu, curs) || IsDefined(force) && force)
                    player drawText();
            }
        }
    }
    else
    {
        if(IsDefined(self) && self hasMenu() && self isInMenu(true) && !Is_True(self.DisableMenuControls))
        {
            self drawText();
        }
    }
}

function PlayerHasOption(source, menu, curs)
{
    option = source GetOption(curs, OPT_NAME);

    if(IsDefined(self.menuStructure) && self.menuStructure.size && IsDefined(option))
    {
        for(a = 0; a < self.menuStructure.size; a++)
        {
            if(option == self GetOption(a, OPT_NAME) && (source.SelectedPlayer == self || self.SelectedPlayer == self && source.SelectedPlayer == source && self getCurrent() == menu))
                return true;
        }
    }

    return false;
}

function DestroyOpts()
{
    self endon("disconnect");
    
    hud = Array("text", "BoolOpt", "BoolBack", "BoolText", "subMenu", "IntSlider", "StringSlider", "invalidOption");
    
    if(IsDefined(self.menuUI) && self.menuUI.size)
    {
        for(a = 0; a < hud.size; a++)
        {
            if(IsDefined(self.menuUI[hud[a]]) && self.menuUI[hud[a]].size)
            {
                destroyAll(self.menuUI[hud[a]]);
                self.menuUI[hud[a]] = undefined;
            }
        }
    }

    self.menuStructure = undefined;
}

function IsInvalidOption(text)
{
    if(!IsDefined(text))
        return true;
    
    if(!IsDefined(text.size)) //.size of localized string will be undefined -- Even if the string = "" the size should be 0
        return false;
    
    if(text == "")
        return true;
    
    for(a = 0; a < text.size; a++)
    {
        if(text[a] != " ")
            return false;
    }
    
    return true;
}

function BackMenu()
{
    if(!self isInQuickMenu())
    {
        if(IsDefined(self.menu_parent) && self.menu_parent.size)
            return self.menu_parent[(self.menu_parent.size - 1)];
        
        return "Main";
    }

    if(IsDefined(self.menu_parentQM) && self.menu_parentQM.size)
        return self.menu_parentQM[(self.menu_parentQM.size - 1)];
    
    return "Quick Menu";
}

function isInMenu(iqm)
{
    return Is_True(self.isInMenu) || Is_True(iqm) && Is_True(self.isInQuickMenu);
}

function isInQuickMenu()
{
    return Is_True(self.isInQuickMenu);
}

function getCurrent()
{
    if(!self isInMenu(true))
        return;
    
    if(self isInQuickMenu())
        return self.currentMenuQM;

    return self.currentMenu;
}

function getCursor()
{
    if(!IsDefined(self.menuCursor))
        return;
    
    if(!IsDefined(self.menuCursor[self getCurrent()]))
        self.menuCursor[self getCurrent()] = 0;
    
    return self.menuCursor[self getCurrent()];
}

function setCursor(curs)
{
    if(!IsDefined(self.menuCursor))
        self.menuCursor = [];
    
    self.menuCursor[self getCurrent()] = curs;
}

function SetSlider(dir)
{
    menu = self getCurrent();
    curs = self getCursor();

    if(!IsDefined(self.menuSlider))
        self.menuSlider = [];
    
    if(!IsDefined(self.menuSlider[menu]))
        self.menuSlider[menu] = [];
    
    if(!IsDefined(self.menuSlider[menu][curs]))
        self.menuSlider[menu][curs] = 0;

    sliderValues = self GetOption(curs, OPT_SLIDERVALUES);

    if(!IsDefined(sliderValues) || !sliderValues.size)
        sliderValues = Array("invalid slider");

    max = (sliderValues.size - 1);

    self.menuSlider[menu][curs] += ((!IsDefined(dir) || !IsInt(dir) || dir > 0) ? 1 : -1);
    
    if((self.menuSlider[menu][curs] > max) || (self.menuSlider[menu][curs] < 0)) self.menuSlider[menu][curs] = ((self.menuSlider[menu][curs] > max) ? 0 : max);
    
    if(IsDefined(self.menuUI) && IsDefined(self.menuUI["StringSlider"]) && IsDefined(self.menuUI["StringSlider"][curs]))
        self.menuUI["StringSlider"][curs] SetTextString("< " + sliderValues[self.menuSlider[menu][curs]] + " > [" + (self.menuSlider[menu][curs] + 1) + "/" + sliderValues.size + "]");
}

function SetIncSlider(dir)
{
    menu = self getCurrent();
    curs = self getCursor();

    if(!IsDefined(self.menuSlider))
        self.menuSlider = [];
    
    if(!IsDefined(self.menuSlider[menu]))
        self.menuSlider[menu] = [];
    
    if(!IsDefined(self.menuSlider[menu][curs]))
        self.menuSlider[menu][curs] = 0;
    
    val = self GetOption(curs, OPT_INCREMENT);
    max = self GetOption(curs, OPT_MAX);
    min = self GetOption(curs, OPT_MIN);
    
    if(self.menuSlider[menu][curs] < max && (self.menuSlider[menu][curs] + val) > max || (self.menuSlider[menu][curs] > min) && (self.menuSlider[menu][curs] - val) < min) self.menuSlider[menu][curs] = ((self.menuSlider[menu][curs] < max && (self.menuSlider[menu][curs] + val) > max) ? max : min);
    else self.menuSlider[menu][curs] += ((!IsDefined(dir) || !IsInt(dir) || dir > 0) ? val : (val * -1));
    
    if((self.menuSlider[menu][curs] > max) || (self.menuSlider[menu][curs] < min)) self.menuSlider[menu][curs] = ((self.menuSlider[menu][curs] > max) ? min : max);
    
    if(IsDefined(self.menuUI) && IsDefined(self.menuUI["IntSlider"]) && IsDefined(self.menuUI["IntSlider"][curs]))
        self.menuUI["IntSlider"][curs] SetValue(self.menuSlider[menu][curs]);
}

function newMenu(menu, dontSave, i1)
{
    self endon("disconnect");
    self notify("EndSwitchWeaponMonitor");
    self endon("menuClosed");

    if(!IsDefined(self.menu_parent))
        self.menu_parent = [];
    
    if(!IsDefined(self.menu_parentQM))
        self.menu_parentQM = [];

    if(self getCurrent() == "Players" && IsDefined(menu))
    {
        player = level.players[self getCursor()];

        //This will make it so only the host developers can access the host's player options. Also, only the developers can access other developer's player options.
        if(player IsHost() && !self IsHost() && !self isDeveloper() || player isDeveloper() && !self isDeveloper())
            return self iPrintlnBold("^1ERROR: ^7Access Denied");

        self.SelectedPlayer = player;
        self.SavedSelectedPlayer = player; //Fix for force closing the menu while navigating a players options and opening the quick menu.
    }
    else if(self getCurrent() == "Players" && !IsDefined(menu))
    {
        self.SelectedPlayer = self;
    }
    else if(self isInMenu(false) && isInArray(self.menu_parent, "Players"))
    {
        self.SelectedPlayer = self.SavedSelectedPlayer;
    }
    
    if(!IsDefined(menu))
    {
        menu = self BackMenu();
        
        if(!self isInQuickMenu())
            self.menu_parent[(self.menu_parent.size - 1)] = undefined;
        else
            self.menu_parentQM[(self.menu_parentQM.size - 1)] = undefined;
    }
    else
    {
        if(!IsDefined(dontSave) || IsDefined(dontSave) && !dontSave)
        {
            if(!self isInQuickMenu())
                self.menu_parent[self.menu_parent.size] = self getCurrent();
            else
                self.menu_parentQM[self.menu_parentQM.size] = self getCurrent();
        }
    }

    for(a = 0; a < self.menuStructure.size; a++)
    {
        optIncSlider = self GetOption(a, OPT_INCSLIDER);

        if(!IsDefined(self.menuStructure[a]) || !Is_True(optIncSlider) || !IsDefined(self.menuSlider) || !IsDefined(self.menuSlider[menu]))
            continue;
        
        optStart = self GetOption(a, OPT_START);

        if(IsDefined(self.menuSlider[menu][a]) && IsDefined(optStart) && self.menuSlider[menu][a] == optStart)
            self.menuSlider[menu][a] = undefined;
    }
    
    if(!self isInQuickMenu())
        self.currentMenu = menu;
    else
        self.currentMenuQM = menu;

    refresh = (IsVerkoMap() ? Array("Weaponry") : Array("Weapon Options", "Weapon Attachments", "Weapon AAT"));

    if(isInArray(refresh, menu)) //Submenus that should be refreshed when player switches weapons
    {
        player = self.SelectedPlayer;

        if(IsDefined(player))
            player thread WatchMenuWeaponSwitch(menu, self);
    }

    if(menu == "Players" && !Is_True(self.PlayerInfoHandler))
        self thread PlayerInfoHandler();
    
    if(isDefined(i1))
    {
        self.EntityEditorNumber = i1;
    }
    
    self drawText();
}

function WatchMenuWeaponSwitch(menu, player)
{
    self endon("disconnect");
    player endon("disconnect");
    player endon("menuClosed");
    player endon("EndSwitchWeaponMonitor");

    while(player getCurrent() == menu)
    {
        self waittill("weapon_change", newWeapon);

        if(player getCurrent() == menu)
            player RefreshMenu(player getCurrent(), player getCursor(), true);
    }
}

function PlayerInfoHandler()
{
    if(Is_True(self.PlayerInfoHandler) || Is_True(level.DisablePlayerInfo))
        return;
    self.PlayerInfoHandler = true;

    self endon("disconnect");

    wait 0.1; //buffer (needed)
    bgTempX = 0;

    self.playerInfoHud = [];

    while(self isInMenu() && self getCurrent() == "Players" && !Is_True(level.DisablePlayerInfo))
    {
        player = level.players[self getCursor()];
        infoString = ((IsDefined(player) && IsPlayer(player)) ? ((player IsHost() || player isDeveloper()) ? "HIDDEN" : player BuildInfoString()) : "^1PLAYER NOT FOUND");
        
        if(!IsDefined(self.menuUI["scroller"]) || !IsDefined(self.menuUI["background"]))
            break;
        
        bgAlpha = ((self.MenuDesign == "Classic") ? 0.85 : 1);
        bgColor = ((self.MenuDesign == "Classic") ? (25, 25, 25) : ((self.MenuDesign == "Apparition") ? (42, 42, 42) : (0, 0, 0)));

        if(!IsDefined(self.playerInfoHud["background"]))
            self.playerInfoHud["background"] = self createRectangle("TOP_LEFT", bgTempX, self.menuUI["scroller"].y, 0, 0, bgColor, 2, bgAlpha, "white");
        
        if(!IsDefined(self.playerInfoHud["outline"]))
            self.playerInfoHud["outline"] = self createRectangle("TOP_LEFT", (bgTempX - 1), (self.menuUI["scroller"].y - 1), 0, 0, self.MainTheme, 1, 1, "white");
        
        if(!IsDefined(self.playerInfoHud["string"]))
            self.playerInfoHud["string"] = self createText("default", 1.2, 3, "", "LEFT", (self.playerInfoHud["background"].x + 1), (self.playerInfoHud["background"].y + 6), 1, (1, 1, 1));

        if(self.playerInfoHud["string"].text != infoString)
            self.playerInfoHud["string"] SetTextString(infoString);
        
        width = self.playerInfoHud["string"] GetTextWidth3arc(self);
        bgTempX = ((self.menuUI["background"].x > 97) ? (self.menuUI["background"].x - (width + 5)) : ((self.menuUI["background"].x + self.menuUI["background"].width) + 15));

        if(self.playerInfoHud["background"].y != self.menuUI["scroller"].y || self.playerInfoHud["background"].x != bgTempX)
        {
            self.playerInfoHud["background"].y = self.menuUI["scroller"].y;
            self.playerInfoHud["outline"].y = (self.menuUI["scroller"].y - 1);
            self.playerInfoHud["string"].y = self.playerInfoHud["background"].y + 6;

            self.playerInfoHud["background"].x = bgTempX;
            self.playerInfoHud["outline"].x = (bgTempX - 1);
            self.playerInfoHud["string"].x = (self.playerInfoHud["background"].x + 1);
        }
        
        if(self.playerInfoHud["background"].width != width || self.playerInfoHud["background"].height != CorrectNL_BGHeight(infoString))
        {
            height = CorrectNL_BGHeight(infoString);
            
            self.playerInfoHud["background"] SetShaderValues(undefined, width, height);
            self.playerInfoHud["outline"] SetShaderValues(undefined, (width + 2), (height + 2));
        }

        wait 0.01;
    }

    keys = GetArrayKeys(self.playerInfoHud);

    foreach(key in keys)
    {
        if(IsDefined(self.playerInfoHud[key]))
            self.playerInfoHud[key] DestroyHud();
    }

    self.PlayerInfoHandler = undefined;
    self.playerInfoHud = undefined;
}

function BuildInfoString()
{
    strng = "";
    strng += "^1PLAYER INFO:";
    strng += "\n^7Name: ^2" + CleanName(self getName());
    strng += "\n^7Verification: ^2" + self.accessLevel;

    if(Is_True(level.IncludeIPInfo))
        strng += "\n^7IP: ^2" + StrTok(self GetIPAddress(), "Public Addr: ")[0];
    
    strng += "\n^7XUID: ^2" + self GetXUID();
    strng += "\n^7STEAM ID: ^2" + self GetXUID(1);
    strng += "\n^7Controller: ^2" + (self GamepadUsedLast() ? "Yes" : "No");

    weapon = self GetCurrentWeapon();
    weaponName = ((IsDefined(weapon) && IsDefined(weapon.name) && weapon != level.weaponnone) ? weapon.name : "None");

    strng += "\n^7Weapon: ^2" + StrTok(weaponName, "+")[0]; //Can't use the displayname

    return strng;
}

function AreButtonsPressed(btnArray)
{
    pressed = false;

    foreach(buttonString in btnArray)
    {
        switch(buttonString)
        {
            case "+actionslot 1":
                pressed = self ActionSlotOneButtonPressed();
                break;
            
            case "+actionslot 2":
                pressed = self ActionSlotTwoButtonPressed();
                break;
            
            case "+actionslot 3":
                pressed = self ActionSlotThreeButtonPressed();
                break;
            
            case "+actionslot 4":
                pressed = self ActionslotFourButtonPressed();
                break;
            
            case "+melee":
                pressed = self MeleeButtonPressed();
                break;
            
            case "+speed_throw":
                pressed = self AdsButtonPressed();
                break;
            
            case "+attack":
                pressed = self AttackButtonPressed();
                break;
            
            case "+breath_sprint":
                pressed = self SprintButtonPressed();
                break;
            
            case "+activate":
                pressed = self UseButtonPressed();
                break;
            
            case "+frag":
                pressed = self FragButtonPressed();
                break;
            
            case "+smoke":
                pressed = self SecondaryOffhandButtonPressed();
                break;
            
            case "+stance":
                pressed = self StanceButtonPressed();
                break;
            
            case "+gostand":
                pressed = self JumpButtonPressed();
                break;
            
            case "None":
                pressed = true;
                break;
            
            default:
                pressed = false;
                break;
        }

        if(!pressed) //After checking either button, if this variable is still false, then the player didn't press the opening bind(s)
            return false;
    }

    return true;
}

function SetOpenButtons(type, buttonString)
{
    openControls = (IsDefined(type) && type == GetMenuName());
    buttonIndex = (self.OpenControlIndex - 1);
    controlsArry = (openControls ? self.OpenControls : self.QuickControls);

    if(!buttonIndex && buttonString == "None")
        return self iPrintlnBold("^1ERROR: ^7Button 1 Can't Be Set To None");
    
    if(isInArray(controlsArry, buttonString) && buttonString != "None")
        return self iPrintlnBold("^1ERROR: ^7This Button Is Already Being Used");
    
    if(buttonIndex && !IsDefined(controlsArry[(buttonIndex - 1)])) //Makes sure the player has selected slots in the correct order
        return self iPrintlnBold("^1ERROR: ^7You Need To Fill Bind Slot " + buttonIndex + " First");
    
    if(buttonString == "None") //If the player clears a slot, then we want to clear the following slots as well
    {
        saved = [];

        for(a = 0; a < buttonIndex; a++)
            saved[saved.size] = controlsArry[a];

        if(openControls)
            self.OpenControls = saved;
        else
            self.QuickControls = saved;
        
        self SaveMenuTheme();
        return;
    }

    if(Is_True(openControls) && (isInArray(self.OpenControls, "+frag") && self.OpenControls[buttonIndex] != "+frag" && buttonString == "+smoke" || isInArray(self.OpenControls, "+smoke") && self.OpenControls[buttonIndex] != "+smoke" && buttonString == "+frag") || !Is_True(openControls) && (isInArray(self.QuickControls, "+frag") && self.QuickControls[buttonIndex] != "+frag" && buttonString == "+smoke" || isInArray(self.QuickControls, "+smoke") && self.QuickControls[buttonIndex] != "+smoke" && buttonString == "+frag"))
        return self iPrintlnBold("^1ERROR: ^7You Can't Have [{+frag}] & [{+smoke}] Paired Together");
    
    if(openControls)
        self.OpenControls[buttonIndex] = buttonString;
    else
        self.QuickControls[buttonIndex] = buttonString;
    
    self SaveMenuTheme();
}

function OpenControlIndex(index)
{
    if(!IsDefined(index) || !IsInt(index) || index < 0)
        return;
    
    self.OpenControlIndex = index;
    self RefreshMenu(self getCurrent(), self getCursor());
}

function OpenControlType(type)
{
    if(!IsDefined(type) || IsDefined(self.OpenControlType) && self.OpenControlType == type)
        return;
    
    self.OpenControlType = type;
    self RefreshMenu(self getCurrent(), self getCursor());
}





//option structures
function addMenu(title)
{
    self.menuStructure = [];

    if(IsDefined(title))
        self.menuTitle = title;
}

function addOpt(name, fnc = &EmptyFunction, input1, input2, input3, input4)
{
    if(!IsDefined(self.menuStructure))
        self.menuStructure = [];

    option = [];
    option[OPT_NAME] = name;
    option[OPT_FUNC] = fnc;

    if(IsDefined(input1)) option[OPT_IN1] = input1;
    if(IsDefined(input2)) option[OPT_IN2] = input2;
    if(IsDefined(input3)) option[OPT_IN3] = input3;
    if(IsDefined(input4)) option[OPT_IN4] = input4;
    
    self.menuStructure[self.menuStructure.size] = option;
}

function addOptBool(boolVar, name, fnc = &EmptyFunction, input1, input2, input3, input4)
{
    if(!IsDefined(self.menuStructure))
        self.menuStructure = [];
    
    option = [];
    option[OPT_NAME] = name;
    option[OPT_FUNC] = fnc;

    if(IsDefined(input1)) option[OPT_IN1] = input1;
    if(IsDefined(input2)) option[OPT_IN2] = input2;
    if(IsDefined(input3)) option[OPT_IN3] = input3;
    if(IsDefined(input4)) option[OPT_IN4] = input4;

    option[OPT_BOOL] = Is_True(boolVar);
    option[OPT_BOOLOPT] = true;
    
    self.menuStructure[self.menuStructure.size] = option;
}

function addOptIncSlider(name, fnc = &EmptyFunction, min = 0, start = 0, max = 1, increment = 1, input1, input2, input3, input4)
{
    if(!IsDefined(self.menuStructure))
        self.menuStructure = [];
    
    if(!IsDefined(self.menuSlider))
        self.menuSlider = [];
    
    option = [];
    index = self.menuStructure.size;
    menu = (self isInQuickMenu() ? self.currentMenuQM : self.currentMenu);

    if(!IsDefined(self.menuSlider[menu]))
        self.menuSlider[menu] = [];
    
    option[OPT_NAME] = name;
    option[OPT_FUNC] = fnc;
    
    if(IsDefined(input1)) option[OPT_IN1] = input1;
    if(IsDefined(input2)) option[OPT_IN2] = input2;
    if(IsDefined(input3)) option[OPT_IN3] = input3;
    if(IsDefined(input4)) option[OPT_IN4] = input4;

    option[OPT_INCSLIDER] = true;
    option[OPT_MIN] = min;
    option[OPT_MAX] = ((max < min) ? min : max);

    option[OPT_START] = ((start > max || start < min) ? ((start > max) ? max : min) : start);
    option[OPT_INCREMENT] = increment;
    
    if(!IsDefined(self.menuSlider[menu][index]))
    {
        self.menuSlider[menu][index] = option[OPT_START];
    }
    else
    {
        if(self.menuSlider[menu][index] > max || self.menuSlider[menu][index] < min)
            self.menuSlider[menu][index] = (self.menuSlider[menu][index] < min ? min : max);
    }
    
    self.menuStructure[self.menuStructure.size] = option;
}

function addOptSlider(name, fnc = &EmptyFunction, values, input1, input2, input3, input4)
{
    if(!IsDefined(self.menuStructure))
        self.menuStructure = [];
    
    if(!IsDefined(self.menuSlider))
        self.menuSlider = [];
    
    index = self.menuStructure.size;
    menu = (self isInQuickMenu() ? self.currentMenuQM : self.currentMenu);

    if(!IsDefined(self.menuSlider[menu]))
        self.menuSlider[menu] = [];

    option = [];
    option[OPT_NAME] = name;
    option[OPT_FUNC] = fnc;
    
    if(IsDefined(input1)) option[OPT_IN1] = input1;
    if(IsDefined(input2)) option[OPT_IN2] = input2;
    if(IsDefined(input3)) option[OPT_IN3] = input3;
    if(IsDefined(input4)) option[OPT_IN4] = input4;

    if(!IsArray(values))
        values = Array("Invalid array values passed");

    option[OPT_SLIDER] = true;
    option[OPT_SLIDERVALUES] = values;
    
    if(!IsDefined(self.menuSlider[menu][index]))
        self.menuSlider[menu][index] = 0;
    
    self.menuStructure[self.menuStructure.size] = option;
}

function GetOption(index, data)
{
    if(!IsDefined(self.menuStructure) || !IsDefined(self.menuStructure[index]))
        return;
    
    value = self.menuStructure[index][data];

    if(!IsDefined(value))
        return;

    return value;
}

function EmptyFunction(){}

// ============================================================
// Menu/designHud.gsc
// ============================================================

function createMenuHud()
{
    switch(self.MenuDesign)
    {
        case "Classic":
            self ClassicHud();
            break;
        
        case "Native":
            self NativeHud();
            break;
        
        case "AIO":
            self AIOHud();
            break;
        
        case "Basic":
            self BasicHud();
            break;
        
        default:
            self ApparitionHud();
            break;
    }
}

function ApparitionHud()
{
    self.menuUI["background"] = self createRectangle("TOP_LEFT", self.menuX, self.menuY, self.MenuWidth, 300, (25, 25, 25), 3, 0.5, "white");
    self.menuUI["banner"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, (self.menuUI["background"].y - 20), self.MenuWidth, (self.menuUI["background"].height + 20), (55, 55, 55), 2, 1, "white");
    self.menuUI["separator"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, (self.menuUI["background"].y - 1), self.MenuWidth, 1, self.MainTheme, 5, 1, "white");
    self.menuUI["bottomLine"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, (self.menuUI["background"].y + self.menuUI["background"].height), self.MenuWidth, 1, self.MainTheme, 5, 1, "white");
    self.menuUI["scroller"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, self.menuUI["background"].y, self.MenuWidth, 18, (55, 55, 55), 4, 1, "white");

    self.menuUI["title"] = self createText("default", 1.5, 7, "", "CENTER", self.menuUI["background"].x + (self.menuUI["background"].width / 2), (self.menuUI["banner"].y + 8), 1, self.MainTheme);

    if(Is_True(self.OptionCounter))
    {
        self.menuUI["counterSep"] = self createText("default", 1, 7, "/", "CENTER", (self.menuUI["background"].x + (self.menuUI["background"].width - 16)), (self.menuUI["title"].y + 8), 0.7, (255, 255, 255));
        self.menuUI["cursIndex"] = self createText("default", 1, 7, 0, "RIGHT", (self.menuUI["counterSep"].x - 3), self.menuUI["counterSep"].y, 0.7, (255, 255, 255));
        self.menuUI["optCount"] = self createText("default", 1, 7, 0, "LEFT", (self.menuUI["counterSep"].x + 3), self.menuUI["counterSep"].y, 0.7, (255, 255, 255));
    }
}

function ClassicHud()
{
    self.menuUI["background"] = self createRectangle("TOP_LEFT", self.menuX, self.menuY, self.MenuWidth, 300, (25, 25, 25), 3, 0.85, "white");
    self.menuUI["banner"] = self createRectangle("TOP_LEFT", (self.menuUI["background"].x - 1), (self.menuUI["background"].y - 13), (self.MenuWidth + 2), (self.menuUI["background"].height + 14), self.MainTheme, 2, 1, "white");
    self.menuUI["scroller"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, self.menuUI["background"].y, self.MenuWidth, 18, self.MainTheme, 4, 1, "white");

    self.menuUI["title"] = self createText("default", 1.2, 7, "", "LEFT", (self.menuUI["background"].x + 4), (self.menuUI["banner"].y + 6), 1, (255, 255, 255));

    if(Is_True(self.OptionCounter))
    {
        self.menuUI["counterSep"] = self createText("default", 1, 7, "/", "CENTER", (self.menuUI["background"].x + (self.menuUI["background"].width - 16)), self.menuUI["title"].y, 1, (255, 255, 255));
        self.menuUI["cursIndex"] = self createText("default", 1, 7, 0, "RIGHT", (self.menuUI["counterSep"].x - 3), self.menuUI["counterSep"].y, 1, (255, 255, 255));
        self.menuUI["optCount"] = self createText("default", 1, 7, 0, "LEFT", (self.menuUI["counterSep"].x + 3), self.menuUI["counterSep"].y, 1, (255, 255, 255));
    }
}

function NativeHud()
{
    self.menuUI["background"] = self createRectangle("TOP_LEFT", self.menuX, self.menuY, self.MenuWidth, 300, (25, 25, 25), 3, 0.45, "white");
    self.menuUI["separator"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, (self.menuUI["background"].y - 17), self.MenuWidth, 17, (0, 0, 0), 5, 1, "white");
    self.menuUI["banner"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, (self.menuUI["separator"].y - 38), self.MenuWidth, 38, self.MainTheme, 2, 0.9, "white");
    self.menuUI["scroller"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, self.menuUI["background"].y, self.MenuWidth, 18, self.MainTheme, 4, 0.7, "white");

    self.menuUI["title"] = self createText("default", 1, 7, "", "LEFT", (self.menuUI["background"].x + 4), ((self.menuUI["separator"].y + (self.menuUI["separator"].height / 2)) - 1), 0.7, (255, 255, 255));
    self.menuUI["menuName"] = self createText("default", 1.6, 7, GetMenuName(), "CENTER", (self.menuUI["background"].x + (self.menuUI["background"].width / 2)), (self.menuUI["banner"].y + (self.menuUI["banner"].height / 2)), 1, (255, 255, 255));

    if(Is_True(self.OptionCounter))
    {
        self.menuUI["counterSep"] = self createText("default", 1, 7, "/", "CENTER", (self.menuUI["background"].x + (self.menuUI["background"].width - 16)), self.menuUI["title"].y, 0.7, (255, 255, 255));
        self.menuUI["cursIndex"] = self createText("default", 1, 7, 0, "RIGHT", (self.menuUI["counterSep"].x - 3), self.menuUI["counterSep"].y, 0.7, (255, 255, 255));
        self.menuUI["optCount"] = self createText("default", 1, 7, 0, "LEFT", (self.menuUI["counterSep"].x + 3), self.menuUI["counterSep"].y, 0.7, (255, 255, 255));
    }
}

function AIOHud()
{
    self.menuUI["background"] = self createRectangle("TOP_LEFT", self.menuX, self.menuY, self.MenuWidth, 300, (0, 0, 0), 3, 0.45, "white");
    self.menuUI["separator"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, (self.menuUI["background"].y - 25), self.MenuWidth, 25, self.MainTheme, 5, 1, "white");
    self.menuUI["bottomLine"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, (self.menuUI["background"].y + self.menuUI["background"].height), self.MenuWidth, 25, self.MainTheme, 5, 1, "white");
    self.menuUI["backgroundouter"] = self createRectangle("TOP_LEFT", (self.menuUI["background"].x - 2), (self.menuUI["separator"].y - 2), (self.MenuWidth + 4), (4 + (self.menuUI["background"].height + self.menuUI["separator"].height + self.menuUI["bottomLine"].height)), (0, 0, 0), 1, 0.3, "white");
    self.menuUI["scroller"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, self.menuUI["background"].y, 2, 23, self.MainTheme, 4, 1, "white");

    self.menuUI["title"] = self createText("default", 1.4, 7, "", "LEFT", (self.menuUI["background"].x + 4), (self.menuUI["separator"].y + ((self.menuUI["separator"].height / 2) - 1)), 1, (255, 255, 255));
    self.menuUI["menuName"] = self createText("default", 1.4, 7, "Status: " + self.accessLevel, "LEFT", (self.menuUI["background"].x + 2), (self.menuUI["bottomLine"].y + ((self.menuUI["bottomLine"].height / 2) - 1)), 1, (255, 255, 255));
}

function BasicHud()
{
    self.menuUI["background"] = self createRectangle("TOP_LEFT", self.menuX, self.menuY, self.MenuWidth, 300, (0, 0, 0), 3, 0.45, "white");
    self.menuUI["banner"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, self.menuUI["background"].y, self.MenuWidth, 20, (0, 0, 0), 4, 1, "white");
    self.menuUI["scroller"] = self createRectangle("TOP_LEFT", self.menuUI["background"].x, self.menuUI["background"].y, self.MenuWidth, 18, (0, 0, 0), 4, 1, "white");
    self.menuUI["title"] = self createText("default", 1.4, 7, "", "CENTER", (self.menuUI["background"].x + (self.menuUI["background"].width / 2)), (self.menuUI["background"].y + ((self.menuUI["banner"].height / 2) - 1)), 1, self.MainTheme);
}

// ============================================================
// Menu/menu_customization.gsc
// ============================================================

function PopulateMenuCustomization(menu)
{
    switch(menu)
    {
        case "Menu Customization":
            self addMenu(menu);
                self addOpt("Menu Credits", &MenuCredits);
                self addOpt("Open Controls", &newMenu, "Open Controls");
                self addOpt("Width Editor", &MenuWidthEditor);
                self addOpt("Reposition Menu", &RepositionMenu);
                self addOpt("Menu Instructions", &newMenu, "Menu Instructions");
                self addOpt("Main Design Color", &newMenu, "Main Design Color");
                self addOpt("Menu Preferences", &newMenu, "Menu Preferences");
            break;
        
        case "Open Controls":
            if(!IsDefined(self.OpenControlIndex))
                self.OpenControlIndex = 1;
            
            if(!IsDefined(self.OpenControlType))
                self.OpenControlType = GetMenuName();
            
            buttons = Array("+actionslot 1", "+actionslot 2", "+actionslot 3", "+actionslot 4", "+melee", "+speed_throw", "+attack", "+breath_sprint", "+activate", "+frag", "+smoke", "+stance", "+gostand");
            type = ((self.OpenControlType == GetMenuName()) ? self.OpenControls : self.QuickControls);

            self addMenu(menu);
                self addOptSlider("Menu", &OpenControlType, Array(GetMenuName(), "Quick Menu"));
                self addOptIncSlider("Bind Slot", &OpenControlIndex, 1, 1, 3, 1); //If you want to allow more buttons to be chosen, change the '3' to whatever number you want.
                self addOpt("");

                if(self.OpenControlIndex != 1)
                    self addOptBool(!IsDefined(type[(self.OpenControlIndex - 1)]), "None", &SetOpenButtons, self.OpenControlType, "None");

                foreach(button in buttons)
                    self addOptBool((IsDefined(type[(self.OpenControlIndex - 1)]) && type[(self.OpenControlIndex - 1)] == button), "[{" + button + "}]", &SetOpenButtons, self.OpenControlType, button);
            break;
        
        case "Menu Instructions":
            self addMenu(menu);
                self addOptBool(self.DisableMenuInstructions, "Disable", &DisableMenuInstructions);
                self addOptBool(self.AlternateInstructions, "Alternate Style", &AlternateInstructions);
                self addOptBool(self.DisableInstructionsBackground, "Disable Background", &DisableInstructionsBackground);
                self addOptBool(self.AdaptiveMenuInstructions, "Adaptive Position", &AdaptiveMenuInstructions);
                self addOpt("Reposition", &RepositionMenuInstructions);
                self addOpt("Reset Position", &ResetMenuInstructions);
            break;
        
        case "Main Design Color":
            self addMenu(menu);
                
                for(a = 0; a < GetColorNames().size; a++)
                    self addOptBool((!Is_True(self.SmoothRainbowTheme) && self.MainTheme == GetColorValues()[a]), GetColorNames()[a], &MenuTheme, GetColorValues()[a]);
                
                self addOptBool(self.SmoothRainbowTheme, "Smooth Rainbow", &SmoothRainbowTheme);
            break;
        
        case "Menu Preferences":
            self addMenu(menu);
                self addOptSlider("Design", &MenuDesign, Array(GetMenuName(), "Classic", "Native", "AIO", "Basic"));
                self addOptSlider("Bool Display", &BoolDisplay, Array("Boxes", "Text", "Text Color"));
                self addOptSlider("Bool Box Location", &BoolLocation, Array("Right", "Left"));
                self addOptIncSlider("Scroll Animation Time (ms)", &ScrollAnimationTime, 10, Int(self.ScrollAnimationTime * 100), 25, 1);
                self addOptBool(self.QuickExit, "Quick Exit [ Hold [{+melee}] ]", &QuickExit);
                self addOptBool(self.DisableQM, "Disable Quick Menu", &DisableQuickMenu);
                self addOptBool(self.SpotlightCursor, "Spotlight Cursor", &SpotlightCursor);
                self addOptBool(self.ColoredCursor, "Colored Cursor", &ColoredCursor);
                self addOptBool(self.LargeCursor, "Large Cursor", &LargeCursor);
                self addOptBool(self.OptionCounter, "Option Counter", &OptionCounter);
                self addOptBool(self.StealthUI, "Stealth UI", &StealthUI);
                self addOptBool(self.MenuNoTarget, "No Target While In Menu", &MenuNoTarget);
            break;
    }
}

function MenuTheme(color)
{
    self notify("EndSmoothRainbowTheme");

    if(Is_True(self.SmoothRainbowTheme))
        self.SmoothRainbowTheme = BoolVar(self.SmoothRainbowTheme);
    
    hud = Array("text", "BoolText", "subMenu", "IntSlider", "StringSlider");
    
    if(IsDefined(self.menuUI))
    {
        if(IsDefined(self.menuStructure) && self.menuStructure.size)
        {
            for(a = 0; a < self.menuStructure.size; a++)
            {
                boolVal = self GetOption(a, 6);
                boolOpt = self GetOption(a, OPT_BOOLOPT);
                selectedColor = (!Is_True(self.ColoredCursor) ? (1, 1, 1) : color);

                if(IsDefined(self.menuUI["BoolOpt"]) && IsDefined(self.menuUI["BoolOpt"][a]) && Is_True(boolOpt) && Is_True(boolVal))
                    self.menuUI["BoolOpt"][a] hudFadeColor(color, 0.5);
                
                if(IsDefined(self.menuUI["invalidOption"]) && IsDefined(self.menuUI["invalidOption"][a]))
                    self.menuUI["invalidOption"][a] hudFadeColor(color, 0.5);
                
                for(b = 0; b < hud.size; b++)
                {
                    if(IsDefined(self.menuUI[hud[b]][a]))
                        self.menuUI[hud[b]][a] hudFadeColor(((self.BoolDisplay == "Text Color" && Is_True(boolOpt) && Is_True(boolVal)) ? (0, 1, 0) : ((a == self getCursor()) ? selectedColor : (1, 1, 1))), 1);
                }
            }
        }

        if(IsDefined(self.menuUI["scroller"]) && self.MenuDesign != GetMenuName() && self.MenuDesign != "Basic")
            self.menuUI["scroller"] hudFadeColor(color, 0.5);

        if(self.MenuDesign == "Native" || self.MenuDesign == "Classic")
        {
            if(IsDefined(self.menuUI["banner"]))
                self.menuUI["banner"] hudFadeColor(color, 0.5);
        }
        else
        {
            if(IsDefined(self.menuUI["title"]) && self.MenuDesign != "AIO")
                self.menuUI["title"] hudFadeColor(color, 0.5);
            
            if(IsDefined(self.menuUI["separator"]))
                self.menuUI["separator"] hudFadeColor(color, 0.5);
            
            if(IsDefined(self.menuUI["bottomLine"]))
                self.menuUI["bottomLine"] hudFadeColor(color, 0.5);
        }
    }

    instructionsHud = ((self.MenuDesign == "AIO") ? "background" : "outline");

    if(IsDefined(self.menuInstructionsUI) && IsDefined(self.menuInstructionsUI[instructionsHud]))
        self.menuInstructionsUI[instructionsHud] hudFadeColor(color, 0.5);
    
    infoHud = ((self.MenuDesign == "AIO") ? "background" : "outline");
    
    if(IsDefined(self.playerInfoHud) && IsDefined(self.playerInfoHud[infoHud]))
        self.playerInfoHud[infoHud] hudFadeColor(color, 0.5);

    col = GetColorVec(color);
    
    if(Is_True(self.ZombieCounter) && IsDefined(self.ZombieCounterHud) && IsDefined(self.ZombieCounterHud[0]))
    {
        self SetLUIMenuData(self.ZombieCounterHud[0], "red", col[0]);
        self SetLUIMenuData(self.ZombieCounterHud[0], "green", col[1]);
        self SetLUIMenuData(self.ZombieCounterHud[0], "blue", col[2]);
    }

    if(Is_True(self.EntityCountDisplay) && IsDefined(self.EntityCountHud) && IsDefined(self.EntityCountHud[0]))
    {
        self SetLUIMenuData(self.EntityCountHud[0], "red", col[0]);
        self SetLUIMenuData(self.EntityCountHud[0], "green", col[1]);
        self SetLUIMenuData(self.EntityCountHud[0], "blue", col[2]);
    }

    if(Is_True(self.CustomCrosshairs) && IsDefined(self.CustomCrosshairsUI))
    {
        self SetLUIMenuData(self.CustomCrosshairsUI, "red", col[0]);
        self SetLUIMenuData(self.CustomCrosshairsUI, "green", col[1]);
        self SetLUIMenuData(self.CustomCrosshairsUI, "blue", col[2]);
    }
    
    self.MainTheme = color;
    self SaveMenuTheme();
}

function SmoothRainbowTheme()
{
    if(Is_True(self.SmoothRainbowTheme))
        return;
    self.SmoothRainbowTheme = true;
    
    self SaveMenuTheme();
    
    self endon("disconnect");
    self endon("EndSmoothRainbowTheme");

    hud = Array("text", "BoolText", "subMenu", "IntSlider", "StringSlider");
    
    while(Is_True(self.SmoothRainbowTheme))
    {
        color = level.RGBFadeColor;

        if(IsDefined(self.menuUI))
        {
            if(IsDefined(self.menuStructure) && self.menuStructure.size)
            {
                for(a = 0; a < self.menuStructure.size; a++)
                {
                    boolVal = self GetOption(a, 6);
                    boolOpt = self GetOption(a, OPT_BOOLOPT);
                    selectedColor = (!Is_True(self.ColoredCursor) ? (1, 1, 1) : color);

                    if(IsDefined(self.menuUI["BoolOpt"]) && IsDefined(self.menuUI["BoolOpt"][a]) && Is_True(boolOpt) && Is_True(boolVal))
                        self.menuUI["BoolOpt"][a].color = color;
                    
                    if(IsDefined(self.menuUI["invalidOption"]) && IsDefined(self.menuUI["invalidOption"][a]))
                        self.menuUI["invalidOption"][a].color = color;
                    
                    for(b = 0; b < hud.size; b++)
                    {
                        if(IsDefined(self.menuUI[hud[b]][a]))
                            self.menuUI[hud[b]][a].color = ((self.BoolDisplay == "Text Color" && Is_True(boolOpt) && Is_True(boolVal)) ? (0, 1, 0) : ((a == self getCursor()) ? selectedColor : (1, 1, 1)));
                    }
                }
            }

            if(IsDefined(self.menuUI["scroller"]) && (self.MenuDesign != GetMenuName() || IsDefined(self.menuUI["kbString"])))
                self.menuUI["scroller"].color = color;

            if(self.MenuDesign == "Native" || self.MenuDesign == "Classic")
            {
                if(IsDefined(self.menuUI["banner"]))
                    self.menuUI["banner"].color = color;
            }
            else
            {
                if(IsDefined(self.menuUI["title"]) && self.MenuDesign != "AIO")
                    self.menuUI["title"].color = color;

                if(IsDefined(self.menuUI["separator"]))
                    self.menuUI["separator"].color = color;
                
                if(IsDefined(self.menuUI["bottomLine"]))
                    self.menuUI["bottomLine"].color = color;
            }
        }

        instructionsHud = ((self.MenuDesign == "AIO") ? "background" : "outline");

        if(IsDefined(self.menuInstructionsUI) && IsDefined(self.menuInstructionsUI[instructionsHud]))
            self.menuInstructionsUI[instructionsHud].color = color;
        
        infoHud = ((self.MenuDesign == "AIO") ? "background" : "outline");
        
        if(IsDefined(self.playerInfoHud) && IsDefined(self.playerInfoHud[infoHud]))
            self.playerInfoHud[infoHud].color = color;
        
        if(Is_True(self.ZombieCounter) && IsDefined(self.ZombieCounterHud) && IsDefined(self.ZombieCounterHud[0]))
        {
            self SetLUIMenuData(self.ZombieCounterHud[0], "red", color[0]);
            self SetLUIMenuData(self.ZombieCounterHud[0], "green", color[1]);
            self SetLUIMenuData(self.ZombieCounterHud[0], "blue", color[2]);
        }

        if(Is_True(self.EntityCountDisplay) && IsDefined(self.EntityCountHud) && IsDefined(self.EntityCountHud[0]))
        {
            self SetLUIMenuData(self.EntityCountHud[0], "red", color[0]);
            self SetLUIMenuData(self.EntityCountHud[0], "green", color[1]);
            self SetLUIMenuData(self.EntityCountHud[0], "blue", color[2]);
        }

        if(Is_True(self.CustomCrosshairs) && IsDefined(self.CustomCrosshairsUI))
        {
            self SetLUIMenuData(self.CustomCrosshairsUI, "red", color[0]);
            self SetLUIMenuData(self.CustomCrosshairsUI, "green", color[1]);
            self SetLUIMenuData(self.CustomCrosshairsUI, "blue", color[2]);
        }
        
        self.MainTheme = color;
        wait 0.01;
    }
}

function RepositionMenu()
{
    self endon("disconnect");
    
    self SoftLockMenu(122, true);
    self.menuUI["reposition"] = self createText("default", 1, 5, "[{+actionslot 1}] - Move Up\n[{+actionslot 2}] - Move Down\n[{+actionslot 3}] - Move Left\n[{+actionslot 4}] - Move Right\n[{+frag}] - Increase Offset\n[{+smoke}] - Decrease Offset\n[{+melee}] - Exit", "LEFT", (self.menuX + 4), (self.menuUI["background"].y + 22), 1, (1, 1, 1));
    
    offset = 1;
    offsetY = (self.menuUI["reposition"].y + (CorrectNL_BGHeight(self.menuUI["reposition"].text)) - 10);
    self.menuUI["offset"] = self createText("default", 1, 5, "Offset Value: ", "LEFT", (self.menuX + 4), offsetY, 1, (1, 1, 1));
    self.menuUI["offsetValue"] = self createText("default", 1, 5, offset, "LEFT", (self.menuUI["offset"].x + (self.menuUI["offset"] GetTextWidth3arc(self, 4) - 7)), offsetY, 1, (0, 1, 0));
    
    while(self isInMenu(true))
    {
        if(self ActionSlotOneButtonPressed() || self ActionSlotTwoButtonPressed())
        {
            incValue = (self ActionSlotTwoButtonPressed() ? offset : (offset * -1));
            
            foreach(key in GetArrayKeys(self.menuUI))
            {
                if(!IsDefined(self.menuUI[key]))
                    continue;
                
                if(IsArray(self.menuUI[key]))
                {
                    for(a = 0; a < self.menuUI[key].size; a++)
                    {
                        if(IsDefined(self.menuUI[key][a]))
                            self.menuUI[key][a].y += incValue;
                    }
                }
                else
                {
                    self.menuUI[key].y += incValue;
                }
            }
            
            self.menuY += incValue;
        }
        else if(self ActionSlotThreeButtonPressed() || self ActionSlotFourButtonPressed())
        {
            incValue = (self ActionSlotFourButtonPressed() ? offset : (offset * -1));
            
            foreach(key in GetArrayKeys(self.menuUI))
            {
                if(!IsDefined(self.menuUI[key]))
                    continue;
                
                if(IsArray(self.menuUI[key]))
                {
                    for(a = 0; a < self.menuUI[key].size; a++)
                    {
                        if(IsDefined(self.menuUI[key][a]))
                            self.menuUI[key][a].x += incValue;
                    }
                }
                else
                {
                    self.menuUI[key].x += incValue;
                }
            }
            
            self.menuX += incValue;
        }
        else if(self SecondaryOffhandButtonPressed())
        {
            if(offset > 1)
                offset--;
            
            self.menuUI["offsetValue"] SetValue(offset);
            wait 0.1;
        }
        else if(self FragButtonPressed())
        {
            if(offset < 10)
                offset++;
            
            self.menuUI["offsetValue"] SetValue(offset);
            wait 0.1;
        }
        else if(self MeleeButtonPressed())
        {
            break;
        }
        
        wait 0.025;
    }
    
    self SoftUnlockMenu();
    self SaveMenuTheme();
}

function MenuWidthEditor()
{
    self endon("disconnect");
    
    self SoftLockMenu(120, true);
    txtHud = Array("title", "menuName");
    hud = Array("background", "banner", "separator", "bottomLine", "backgroundouter");

    for(a = 0; a < txtHud.size; a++)
    {
        if(IsDefined(self.menuUI[txtHud[a]]))
            self.menuUI[txtHud[a]] DestroyHud();
    }
    
    self.menuUI["editwidth"] = self createText("default", 1, 5, "[{+attack}] - Increase Width\n[{+speed_throw}] - Decrease Width\n[{+actionslot 4}] - Increase Offset\n[{+actionslot 3}] - Decrease Offset\n[{+melee}] - Exit", "LEFT", self.menuX + 4, (self.menuUI["background"].y + 25), 1, (1, 1, 1));

    offset = 1;
    offsetY = (self.menuUI["editwidth"].y + CorrectNL_BGHeight(self.menuUI["editwidth"].text));
    self.menuUI["offset"] = self createText("default", 1, 5, "Offset Value: ", "LEFT", self.menuX + 4, offsetY, 1, (1, 1, 1));
    self.menuUI["offsetValue"] = self createText("default", 1, 5, offset, "LEFT", (self.menuUI["offset"].x + (self.menuUI["offset"] GetTextWidth3arc(self, 4) - 7)), offsetY, 1, (0, 1, 0));

    min = 200;
    max = 500;
    
    while(self isInMenu(true))
    {
        if(self AttackButtonPressed())
        {
            value = offset;

            if((self.MenuWidth + offset) > max)
                value = (max - self.MenuWidth);

            if(value)
            {
                for(a = 0; a < hud.size; a++)
                {
                    if(IsDefined(self.menuUI[hud[a]]))
                        self.menuUI[hud[a]] thread hudScaleOverTime(0.05, self.menuUI[hud[a]].width + value, self.menuUI[hud[a]].height);
                }

                self.MenuWidth += value;
            }

            wait 0.05;
        }
        else if(self AdsButtonPressed())
        {
            value = offset;

            if((self.MenuWidth - offset) < min)
                value = (self.MenuWidth - min);

            if(value)
            {
                for(a = 0; a < hud.size; a++)
                {
                    if(IsDefined(self.menuUI[hud[a]]))
                        self.menuUI[hud[a]] thread hudScaleOverTime(0.05, self.menuUI[hud[a]].width - value, self.menuUI[hud[a]].height);
                }

                self.MenuWidth -= value;
            }

            wait 0.05;
        }
        else if(self ActionSlotThreeButtonPressed())
        {
            if(offset > 1)
                offset--;
            
            self.menuUI["offsetValue"] SetValue(offset);
            wait 0.1;
        }
        else if(self ActionSlotFourButtonPressed())
        {
            if(offset < 10)
                offset++;
            
            self.menuUI["offsetValue"] SetValue(offset);
            wait 0.1;
        }
        else if(self MeleeButtonPressed())
        {
            break;
        }
        
        wait 0.025;
    }
    
    self SoftUnlockMenu();
    self SaveMenuTheme();
}

function MenuDesign(design)
{
    if(self.MenuDesign == design)
        return;
    
    self.MenuDesign = design;

    if((design == "Native" || design == "Classic") && Is_True(self.ColoredCursor))
        self.ColoredCursor = BoolVar(self.ColoredCursor);
    
    if((design == "AIO" || design == "Basic") && Is_True(self.OptionCounter))
        self.OptionCounter = BoolVar(self.OptionCounter);

    self closeMenu1();
    self openMenu1();
    self.InstructionsForceRefresh = true;

    if(Is_True(self.ZombieCounter))
        self.refreshZombieCounter = true;
    
    if(Is_True(self.EntityCountDisplay))
        self.refreshEntityCount = true;
    
    self SaveMenuTheme();
}

function BoolDisplay(type)
{
    if(self.BoolDisplay == type)
        return;

    if(type == "Boxes" && Is_True(self.StealthUI))
        return self iPrintlnBold("^1ERROR: ^7Bool Display Can't Be Set To Boxes While Stealth UI Is Enabled");
    
    self.BoolDisplay = type;
    self SaveMenuTheme();
    self RefreshMenu();
}

function BoolLocation(location)
{
    if(self.BoolLocation == location)
        return;
    
    self.BoolLocation = location;
    self SaveMenuTheme();
    self RefreshMenu();
}

function ScrollAnimationTime(time)
{
    self.ScrollAnimationTime = (time * 0.01);
    self SaveMenuTheme();
}

function QuickExit()
{
    self.QuickExit = BoolVar(self.QuickExit);
    self SaveMenuTheme();
}

function DisableMenuInstructions()
{
    self.DisableMenuInstructions = BoolVar(self.DisableMenuInstructions);
    self SaveMenuTheme();
    self RefreshMenu(); //Instructions display will count towards the max options shown

    if(!Is_True(self.DisableMenuInstructions))
        self thread MenuInstructionsDisplay();
}

function AlternateInstructions()
{
    if(Is_True(self.AdaptiveMenuInstructions))
        self.AdaptiveMenuInstructions = undefined;

    self.AlternateInstructions = BoolVar(self.AlternateInstructions);
    self.InstructionsForceRefresh = true;
    self ResetMenuInstructions();
}

function DisableInstructionsBackground()
{
    self.DisableInstructionsBackground = BoolVar(self.DisableInstructionsBackground);
    self.InstructionsForceRefresh = true;
    self SaveMenuTheme();
}

function AdaptiveMenuInstructions()
{
    if(Is_True(self.AlternateInstructions))
        return self iPrintlnBold("^1ERROR: ^7Adaptive Position Can't Be Used with Alternate Instructions Enabled");
    
    self.AdaptiveMenuInstructions = BoolVar(self.AdaptiveMenuInstructions);
    self SaveMenuTheme();
}

function RepositionMenuInstructions()
{
    if(Is_True(self.DisableMenuInstructions))
        return self iPrintlnBold("^1ERROR: ^7You Can't Reposition Instructions While They're Disabled");

    self endon("disconnect");
    
    self SoftLockMenu(20, true);
    self SetMenuInstructions(Array("[{+actionslot 1}] - Move Up", "[{+actionslot 2}] - Move Down", "[{+actionslot 3}] - Move Left", "[{+actionslot 4}] - Move Right", "[{+melee}] - Exit"));

    wait 0.1;
    self.RepositionMenuInstructions = true;
    
    while(1)
    {
        if(self ActionSlotOneButtonPressed() || self ActionSlotTwoButtonPressed())
        {
            incValue = (self ActionSlotTwoButtonPressed() ? 8 : -8);
            
            foreach(key in GetArrayKeys(self.menuInstructionsUI))
            {
                if(!IsDefined(self.menuInstructionsUI[key]))
                    continue;
                
                if(IsArray(self.menuInstructionsUI[key]))
                {
                    for(a = 0; a < self.menuInstructionsUI[key].size; a++)
                    {
                        if(IsDefined(self.menuInstructionsUI[key][a]))
                            self.menuInstructionsUI[key][a].y += incValue;
                    }
                }
                else
                {
                    self.menuInstructionsUI[key].y += incValue;
                }
            }
            
            self.instructionsY += incValue;
        }
        else if(self ActionSlotThreeButtonPressed() || self ActionSlotFourButtonPressed())
        {
            incValue = (self ActionSlotFourButtonPressed() ? 8 : -8);
            
            foreach(key in GetArrayKeys(self.menuInstructionsUI))
            {
                if(!IsDefined(self.menuInstructionsUI[key]))
                    continue;
                
                if(IsArray(self.menuInstructionsUI[key]))
                {
                    for(a = 0; a < self.menuInstructionsUI[key].size; a++)
                    {
                        if(IsDefined(self.menuInstructionsUI[key][a]))
                            self.menuInstructionsUI[key][a].x += incValue;
                    }
                }
                else
                {
                    self.menuInstructionsUI[key].x += incValue;
                }
            }
            
            self.instructionsX += incValue;
        }
        else if(self MeleeButtonPressed())
        {
            break;
        }
        
        wait 0.025;
    }
    
    wait 0.1;
    self.RepositionMenuInstructions = undefined;
    self SetMenuInstructions();
    self SoftUnlockMenu();
    self SaveMenuTheme();
}

function ResetMenuInstructions()
{
    self.instructionsX = (Is_True(self.AlternateInstructions) ? 320 : 255);
    self.instructionsY = 472;
    self SaveMenuTheme();
}

function DisableQuickMenu()
{
    self.DisableQM = BoolVar(self.DisableQM);
    self SaveMenuTheme();
}

function SpotlightCursor()
{
    self.SpotlightCursor = BoolVar(self.SpotlightCursor);
    self SaveMenuTheme();
}

function ColoredCursor()
{
    if(self.MenuDesign == "Native" || self.MenuDesign == "Classic")
        return self iPrintlnBold("^1ERROR: ^7You Can't Use Colored Cursor With This Design");
    
    self.ColoredCursor = BoolVar(self.ColoredCursor);
    self SaveMenuTheme();
}

function LargeCursor()
{
    self.LargeCursor = BoolVar(self.LargeCursor);
    self SaveMenuTheme();
}

function OptionCounter()
{
    if(Is_True(self.StealthUI))
        return self iPrintlnBold("^1ERROR: ^7You Can't Use The Option Counter While Stealth UI Is Enabled");
    
    if(self.MenuDesign == "AIO" || self.MenuDesign == "Basic")
        return self iPrintlnBold("^1ERROR: ^7You Can't Use The Option Counter With This Design");
    
    self.OptionCounter = BoolVar(self.OptionCounter);
    self closeMenu1();
    self openMenu1();
    self SaveMenuTheme();
}

function StealthUI()
{
    self.StealthUI = BoolVar(self.StealthUI);

    if(Is_True(self.StealthUI) && self.BoolDisplay == "Boxes")
        self.BoolDisplay = "Text";
    
    if(Is_True(self.OptionCounter))
    {
        self.OptionCounter = undefined;
        self closeMenu1();
        self openMenu1();
    }

    self SaveMenuTheme();
}

function MenuNoTarget()
{
    self.MenuNoTarget = BoolVar(self.MenuNoTarget);

    if(!Is_True(self.MenuNoTarget) && !Is_True(self.playerIgnoreMe))
        self.ignoreme = false;
}

function SaveMenuTheme()
{
    variables = Array("menuSaved", "menuX", "menuY", "instructionsX", "instructionsY", "MenuWidth", "DisableMenuInstructions", "AlternateInstructions", "DisableInstructionsBackground", "AdaptiveMenuInstructions", "MainTheme", "MenuDesign", "OpenControls", "QuickControls", "QuickExit", "BoolDisplay", "BoolLocation", "ScrollAnimationTime", "DisableQM", "SpotlightCursor", "ColoredCursor", "LargeCursor", "OptionCounter", "StealthUI", "MenuNoTarget");
    values    = Array(1, self.menuX, self.menuY, self.instructionsX, self.instructionsY, self.MenuWidth, self.DisableMenuInstructions, self.AlternateInstructions, self.DisableInstructionsBackground, self.AdaptiveMenuInstructions, self.MainTheme, self.MenuDesign, self.OpenControls, self.QuickControls, self.QuickExit, self.BoolDisplay, self.BoolLocation, (self.ScrollAnimationTime * 100), self.DisableQM, self.SpotlightCursor, self.ColoredCursor, self.LargeCursor, self.OptionCounter, self.StealthUI, self.MenuNoTarget);
    
    foreach(index, variable in variables)
    {
        value = (IsDefined(values[index]) ? values[index] : 0);

        if(variable == "OpenControls")
        {
            str = "";

            foreach(indx, btn in self.OpenControls) str += ((indx < (self.OpenControls.size - 1)) ? btn + "," : btn);
            
            value = str;
        }
        else if(variable == "QuickControls")
        {
            str = "";

            foreach(indx, btn in self.QuickControls) str += ((indx < (self.QuickControls.size - 1)) ? btn + "," : btn);
            
            value = str;
        }

        self SetSavedVariable(variable, ((variable == "MainTheme" && Is_True(self.SmoothRainbowTheme)) ? "Rainbow" : value));
    }
}

function SetSavedVariable(variable, value)
{
    //Every value will be saved as a string. The data type can be converted after the value is grabbed.
    SetDvar(variable + self GetXUID(), "" + value);
}

function GetSavedVariable(variable)
{
    //Every value will be grabbed as a string. Convert to the desired data type when you load it
    //i.e. Int(GetSavedVariable(< variable >))
    return GetDvarString(variable + self GetXUID());
}

function LoadMenuVars()
{
    self.menuX = 0; //Keep in mind that the position is close to the center to ensure the menu is visible on any resolution(use the menu position editor to place it where it best fits your liking)
    self.menuY = 85;
    self.instructionsX = (Is_True(self.AlternateInstructions) ? 320 : 255);
    self.instructionsY = 472;
    self.MenuWidth = 260;
    self.MainTheme = (57, 152, 254);
    self.MenuDesign = GetMenuName();
    self.BoolDisplay = "Boxes";
    self.BoolLocation = "Right";
    self.OpenControls = Array("+speed_throw", "+melee");
    self.QuickControls = Array("+speed_throw", "+smoke");
    self.ScrollAnimationTime = 0.12;
    self.ColoredCursor = true;
    self.SpotlightCursor = true;
    saved = Int(self GetSavedVariable("menuSaved"));
    
    if(Is_True(saved))
    {
        self.menuX                         = Int(self GetSavedVariable("menuX"));
        self.menuY                         = Int(self GetSavedVariable("menuY"));
        self.instructionsX                 = Int(self GetSavedVariable("instructionsX"));
        self.instructionsY                 = Int(self GetSavedVariable("instructionsY"));
        self.MenuWidth                     = Int(self GetSavedVariable("MenuWidth"));
        self.DisableMenuInstructions       = returnBool(Int(self GetSavedVariable("DisableMenuInstructions")));
        self.AlternateInstructions         = returnBool(Int(self GetSavedVariable("AlternateInstructions")));
        self.DisableInstructionsBackground = returnBool(Int(self GetSavedVariable("DisableInstructionsBackground")));
        self.AdaptiveMenuInstructions      = returnBool(Int(self GetSavedVariable("AdaptiveMenuInstructions")));
        self.MenuDesign                    = self GetSavedVariable("MenuDesign");
        self.BoolDisplay                   = self GetSavedVariable("BoolDisplay");
        self.BoolLocation                  = self GetSavedVariable("BoolLocation");
        self.ScrollAnimationTime           = (Int(self GetSavedVariable("ScrollAnimationTime")) * 0.01);
        self.QuickExit                     = returnBool(Int(self GetSavedVariable("QuickExit")));
        self.DisableQM                     = returnBool(Int(self GetSavedVariable("DisableQM")));
        self.SpotlightCursor               = returnBool(Int(self GetSavedVariable("SpotlightCursor")));
        self.ColoredCursor                 = returnBool(Int(self GetSavedVariable("ColoredCursor")));
        self.LargeCursor                   = returnBool(Int(self GetSavedVariable("LargeCursor")));
        self.OptionCounter                 = returnBool(Int(self GetSavedVariable("OptionCounter")));
        self.StealthUI                     = returnBool(Int(self GetSavedVariable("StealthUI")));
        self.MenuNoTarget                  = returnBool(Int(self GetSavedVariable("MenuNoTarget")));

        self.OpenControls = [];
        btnToks = StrTok(self GetSavedVariable("OpenControls"), ",");

        foreach(btn in btnToks)
            self.OpenControls[self.OpenControls.size] = btn;
        
        self.QuickControls = [];
        btnToks = StrTok(self GetSavedVariable("QuickControls"), ",");

        foreach(btn in btnToks)
            self.QuickControls[self.QuickControls.size] = btn;

        if(self GetSavedVariable("MainTheme") == "Rainbow")
            self thread SmoothRainbowTheme();
        else
            self.MainTheme = GetDvarVector1("MainTheme" + self GetXUID());
    }
    else
    {
        self SaveMenuTheme();
    }
}

function returnBool(boolVar)
{
    return (Is_True(boolVar) ? true : undefined);
}

function GetMaxOptions()
{
    if(Is_True(self.StealthUI))
        return 5;
    
    if(IsDefined(self.MaxOptionsOverride))
        return self.MaxOptionsOverride;
    
    MaxOptions = 10;

    if(Is_True(self.DisableMenuInstructions))
        MaxOptions++;
    
    if(self.BoolDisplay != "Boxes")
    {
        MaxOptions += 2;

        if(Is_True(self.DisableMenuInstructions))
            MaxOptions++;
    }

    if(Is_True(self.OptionCounter))
        MaxOptions -= 2;
    
    return MaxOptions;
}

// ============================================================
// Menu/menu.gsc
// ============================================================

function RunMenuOptions(menu)
{
    switch(menu)
    {
        case "Main":
            self addMenu(((self.MenuDesign == "Native") ? "Main Menu" : GetMenuName()));
                self addOpt("Basic Scripts", &newMenu, "Basic Scripts");
                self addOpt("Menu Customization", &newMenu, "Menu Customization");
                self addOpt("Message Menu", &newMenu,"Message Menu");
                self addOpt("Teleport Menu", &newMenu, "Teleport Menu");

                if(self getVerification() > 2) //VIP
                {
                    self addOpt("Power-Up Menu", &newMenu, "Power-Up Menu");
                    self addOpt("Model Manipulation", &newMenu, "Model Manipulation");
                    self addOpt("Weaponry", &newMenu, "Weaponry");
                    self addOpt("Bullet Menu", &newMenu, "Bullet Menu");
                    self addOpt("Fun Scripts", &newMenu, "Fun Scripts");
                    self addOpt("Aimbot Menu", &newMenu, "Aimbot Menu");

                    if(self getVerification() > 3) //Admin
                    {
                        self addOpt("Forge Options", &newMenu, "Forge Options");
                        self addOpt("Entity Options", &newMenu, "Entity Options");
                        self addOpt("Advanced Scripts", &newMenu, "Advanced Scripts");

                        if(ReturnMapName() != "Unknown")
                            self addOpt(ReturnMapName() + " Scripts", &newMenu, ReturnMapName() + " Scripts");
                        
                        if(self getVerification() > 4) //Co-Host
                        {
                            self addOpt("Server Modifications", &newMenu, "Server Modifications");
                            self addOpt("Server Tweakables", &newMenu, "Server Tweakables");
                            self addOpt("Zombie Options", &newMenu, "Zombie Options");
                            self addOpt("Spawnables", &newMenu, "Spawnables");

                            if(self IsHost() || self isDeveloper())
                                self addOpt("Host Menu", &newMenu, "Host Menu");
                            
                            self addOpt("Players Menu", &newMenu, "Players");
                            self addOpt("All Players Menu", &newMenu, "All Players");

                            if(!Is_True(level.GameModeSelected) && (self IsHost() || self isDeveloper()))
                                self addOpt("Game Modes", &newMenu, "Game Modes");
                        }
                    }
                }
            break;
        
        case "Quick Menu":
            self addMenu(menu);

                if(Is_Alive(self))
                {
                    self addOptBool(self.playerGodmode, "God Mode", &Godmode, self);
                    self addOptBool(self.Noclip, "Noclip", &Noclip1, self);
                    self addOptBool(self.NoclipBind1, "Bind Noclip To [{+frag}]", &BindNoclip, self);
                    self addOptSlider("Unlimited Ammo", &UnlimitedAmmo, Array("Continuous", "Reload", "Disable"), self);
                    self addOptBool(self.UnlimitedEquipment, "Unlimited Equipment", &UnlimitedEquipment, self);
                    self addOptSlider("Modify Score", &ModifyScore, Array("1000000", "100000", "10000", "1000", "100", "10", "0", "-10", "-100", "-1000", "-10000", "-100000", "-1000000"), self);
                    self addOpt("Perk Menu", &newMenu, "Perk Menu");
                    self addOptBool(self.playerIgnoreMe, "No Target", &NoTarget, self);
                    self addOptBool(self.ReducedSpread, "Reduced Spread", &ReducedSpread, self);
                    self addOptBool(self HasPerk("specialty_unlimitedsprint"), "Unlimited Sprint", &UnlimitedSprint, self);
                }

                self addOpt("Respawn", &ServerRespawnPlayer, self);

                if(Is_Alive(self))
                    self addOpt("Revive", &PlayerRevive, self);

                if(self IsHost() || self isDeveloper())
                {
                    self addOptSlider("Restart Game", &ServerRestartGame, Array("Full", "Fast"));
                    self addOpt("Disconnect", &disconnect);
                }
            break;
        
        case "Menu Customization":
        case "Open Controls":
        case "Menu Instructions":
        case "Main Design Color":
        case "Menu Preferences":
            self PopulateMenuCustomization(menu);
            break;
        
        case "Message Menu":
        case "Miscellaneous Messages":
        case "Advertisements Messages":
            self PopulateMessageMenu(menu);
            break;
        
        case "Power-Up Menu":
            self PopulatePowerupMenu(menu);
            break;
        
        case "Advanced Scripts":
        case "Custom Sentry":
            self PopulateAdvancedScripts(menu);
            break;
        
        case "Forge Options":
        case "Spawn Script Model":
        case "Rotate Script Model":
            self PopulateForgeOptions(menu);
            break;
        
        case "Entity Options":
        case "Entity Editing List":
        case "Entity Editor":
        case "Entity Rotation":
        case "Entities Rotation":

            if((!IsDefined(level.menu_entities) || !level.menu_entities.size) && menu != "Entity Options")
            {
                self.menu_parent = Array("Main");
                menu = "Entity Options";
            }
            
            if((menu == "Entity Editor" || menu == "Entity Rotation") && !IsDefined(level.menu_entities[self.EntityEditorNumber]))
            {
                self.menu_parent = Array("Main", "Entity Options");
                menu = "Entity Editing List";
            }

            self.currentMenu = menu;
            self PopulateEntityOptions(menu);
            break;
        
        case "The Giant Scripts":
        case "The Giant Teleporters":
            self PopulateTheGiantScripts(menu);
            break;
        
        case "Nacht Der Untoten Scripts":
            self PopulateNachtScripts(menu);
            break;
        
        case "Kino Der Toten Scripts":
            self PopulateKinoScripts(menu);
            break;
        
        case "Moon Scripts":
            self PopulateMoonScripts(menu);
            break;
        
        case "Shangri-La Scripts":
            self PopulateShangriLaScripts(menu);
            break;
        
        case "Verruckt Scripts":
            self PopulateVerrucktScripts(menu);
            break;
        
        case "Shi No Numa Scripts":
            self PopulateShinoScripts(menu);
            break;
        
        case "Origins Scripts":
        case "Origins Generators":
        case "Origins Gateways":
        case "Give Shovel Origins":
        case "Give Helmet Origins":
        case "Soul Boxes":
        case "Origins Challenges":
        case "Origins Puzzles":
        case "Ice Puzzles":
        case "Wind Puzzles":
        case "Fire Puzzles":
        case "Lightning Puzzles":
        case "Origins G-Strike Quest":
            self PopulateOriginsScripts(menu);
            break;
        
        case "Gorod Krovi Scripts":
            self PopulateGorodKroviScripts(menu);
            break;
        
        case "Zetsubou No Shima Scripts":
        case "Pack 'a' Punch Parts":
        case "KT-4 Parts":
        case "KT-4 Upgrade Parts":
        case "Skulltar Teleports":
        case "ZNS Bucket Water":
            self PopulateZetsubouNoShimaScripts(menu);
            break;
        
        case "Ascension Scripts":
            self PopulateAscensionScripts(menu);
            break;
        
        case "Der Eisendrache Scripts":
        case "Castle Side Easter Eggs":
        case "Bow Quests":
        case "Fire Bow":
        case "Lightning Bow":
        case "Void Bow":
        case "Wolf Bow":
            self PopulateDerEisendracheScripts(menu);
            break;
        
        case "Shadows Of Evil Scripts":
        case "Beast Mode":
        case "SOE Fumigator":
        case "SOE Smashables":
        case "SOE Power Switches":
        case "Snakeskin Boots":
            self PopulateSOEScripts(menu);
            break;
        
        case "Revelations Scripts":
        case "Revelations Keeper Companion":
            self PopulateRevelationsScripts(menu);
            break;
        
        case "Mob Of The Dead Scripts":
        case "Modify After Life Lives":
        case "MOTD Power Generators":
            self PopulateMOTDScripts(menu);
            break;
        
        case "Die Rise Scripts":
        case "Die Rise Elevator Keys":
        case "Die Rise Bank Cash":
        case "Die Rise Player Ranks":
            self PopulateDieRiseScripts(menu);
            break;
        
        case "Bus Depot Scripts":
            self PopulateBusDepotScripts(menu);
            break;
        
        case "Tunnel Scripts":
            self PopulateTunnelScripts(menu);
            break;
        
        case "Diner Scripts":
            self PopulateDinerScripts(menu);
            break;
        
        case "Farm Scripts":
            self PopulateFarmScripts(menu);
            break;
        
        case "Der Riese: Declassified Scripts":
            self PopulateDerRieseScripts(menu);
            break;
        
        case "Leviathan Scripts":
            self PopulateLeviathanScripts(menu);
            break;
        
        case "Map Challenges":
            self PopulateMapChallenges(menu);
            break;
        
        case "Server Modifications":
        case "Set Round":
        case "Anti-Join":
        case "Doheart Options":
        case "Lobby Timer Options":
        case "Zombie Craftables":
        case "Zombie Traps":
        case "Mystery Box Options":
        case "Mystery Box Weapons":
        case "Mystery Box Normal Weapons":
        case "Mystery Box Upgraded Weapons":
        case "Joker Model":
        case "Change Map":
            self PopulateServerModifications(menu);
            break;
        
        case "Server Tweakables":
        case "Edit Power-Ups":
        case "Edit Pack 'a' Punch":
            self PopulateServerTweakables(menu);
            break;
        
        case "Zombie Options":
        case "AI Spawner":
        case "Prioritize Players":
        case "Zombie Model Manipulation":
        case "Zombie Animations":
        case "Zombie Death Effect":
        case "Zombie Damage Effect":
            self PopulateZombieOptions(menu);
            break;
        
        case "Spawnables":
        case "Rain Options":
        case "Rain Models":
        case "Rain Effects":
        case "Rain Projectiles":
        case "Small Spawnables":
        case "Large Spawnables":
        case "Skybase":
            self PopulateSpawnables(menu);
            break;
        
        case "Host Menu":
            self addMenu(menu);
                self addOpt("Disconnect", &disconnect);
                self addOpt("Player Info", &newMenu, "Player Info");
                self addOpt("Music Player", &newMenu, "Music Player");
                self addOpt("Custom Map Spawns", &newMenu, "Custom Map Spawns");
                self addOpt("Player Score & Overhead Name Color", &newMenu, "Player Score & Overhead Name Color");
                self addOptIncSlider("Field Of View Scale", &FieldOfViewScale, 65, GetDvarFloat("cg_fov"), 85, 1);
                self addOptIncSlider("Field Of View", &FieldOfView, 65, GetDvarFloat("cg_fov_default"), 120, 1);
                self addOptBool(self.ShowOrigin, "Show Origin", &ShowOrigin);
                self addOptBool(level.AntiEndGame, "Anti-End Game", &AntiEndGame);
                self addOptBool(self.EntityCountDisplay, "Entity Count Display", &EntityCountDisplay);

                GSpawnMax = ReturnMapGSpawnLimit();

                if(IsDefined(GSpawnMax) && GSpawnMax)
                    self addOptBool(level.GSpawnProtection, "G_Spawn Crash Protection", &GSpawnProtection);
                
                self addOptBool((GetDvarString("r_showTris") == "1"), "Tris Lines", &TrisLines);
                self addOptBool((GetDvarString("ui_lobbyDebugVis") == "1"), "DevGui Info", &DevGUIInfo);
                self addOptBool((GetDvarString("r_fog") == "0"), "Disable Fog", &DisableFog);
                self addOptBool((GetDvarString("sv_cheats") == "1"), "SV Cheats", &ServerCheats);
                self addOptBool((GetDvarInt("developer") == 2), "Developer Mode", &SetDeveloperMode);
            break;
        
        case "Player Info":
            self addMenu(menu);
                self addOptBool(level.DisablePlayerInfo, "Disable", &DisablePlayerInfo);
                self addOptBool(level.IncludeIPInfo, "Include IP", &IncludeIPInfo);
            break;
        
        case "Music Player":
            self addMenu(menu);
                self addOptBool((!IsDefined(level.nextsong) || level.nextsong == ""), "Stop Music", &StopAllMusic);
                self addOpt("");
                
                for(a = 0; a < 99; a++)
                {
                    track = ReturnMusicRaw(a);

                    if(!IsDefined(track) || track == "")
                        continue;
                    
                    name = ReturnMusicName(track);

                    if(!IsDefined(name) || name == "")
                        continue;
                    
                    self addOptBool((IsDefined(level.nextsong) && level.nextsong == track), name, &PlayMusicTrack, track);
                }
            break;
        
        case "Custom Map Spawns":
            self addMenu(menu);
                self addOptSlider("Set Map Spawn Location", &SetMapSpawn, Array("Player 1", "Player 2", "Player 3", "Player 4"), "Set");
                self addOptSlider("Clear Map Spawn Location", &SetMapSpawn, Array("Player 1", "Player 2", "Player 3", "Player 4"), "Clear");
            break;
        
        case "Player Score & Overhead Name Color":

            if(!IsDefined(self.PlayerScoreIndex))
                self.PlayerScoreIndex = 0;
            
            colorVar = [];
            colorVec = [];

            for(a = 0; a < 4; a++)
            {
                colorVar[a] = GetDvarString("scoreColor" + a);

                if(IsDefined(colorVar[a]) && colorVar[a] != "")
                {
                    vect = GetDvarVector1("scoreColor" + a);

                    if(IsDefined(vect))
                        colorVec[a] = (Int(vect[0]), Int(vect[1]), Int(vect[2]));
                }
                else
                {
                    colorVec[a] = (255, 255, 255);
                }
            }

            self addMenu(menu);
                self addOptIncSlider("Player Index", &PlayerScoreIndex, 1, 1, 4, 1);
                self addOpt("");

                for(a = 0; a < GetColorNames().size; a++)
                    self addOptBool((IsDefined(colorVar[self.PlayerScoreIndex]) && IsDefined(colorVec[self.PlayerScoreIndex]) && colorVec[self.PlayerScoreIndex] == GetColorValues()[a]), GetColorNames()[a], &PlayerScoreColor, GetColorValues()[a], self.PlayerScoreIndex);
            break;
        
        case "Players":
            self addMenu(menu);

                foreach(player in level.players)
                {
                    if(!IsDefined(player.accessLevel)) //If A Player Doesn't Have A Verification Set, They Won't Show. Mainly Happens If They Are Still Connecting
                        player.accessLevel = GetAccessLevels()[1];
                    
                    self addOpt("[^2" + player.accessLevel + "^7]" + CleanName(player getName()), &newMenu, "Options");
                }
            break;
        
        case "All Players":
        case "All Players Verification":
        case "All Players Model Manipulation":
        case "All Players Malicious Options":
            self PopulateAllPlayerOptions(menu);
            break;
        
        case "Game Modes":
            accessLevels = GetAccessLevels();
            accessOptions = [];
            
            for(a = 2; a < (accessLevels.size - 2); a++)
                accessOptions[accessOptions.size] = accessLevels[a];
            
            self addMenu(menu);
                self addOptSlider("Mod Menu Lobby", &InitModMenuLobby, accessOptions);
                self addOptSlider("Sharpshooter", &initSharpshooter, Array("Base Weapons", "Upgraded Weapons", "Both"));
                self addOptSlider("All The Weapons", &initAllTheWeapons, Array("Base Weapons", "Upgraded Weapons", "Both"));
            break;
        
        default:
            
            if(IsDefined(level.zombie_include_craftables) && level.zombie_include_craftables.size)
                craftables = GetArrayKeys(level.zombie_include_craftables);

            if(IsDefined(craftables) && craftables.size && isInArray(craftables, menu))
            {
                self addMenu(CleanString(menu));

                    for(a = 0; a < craftables.size; a++)
                    {
                        if(craftables[a] != menu)
                            continue;
                        
                        craftable = craftables[a];
                        
                        if(IsDefined(craftable))
                        {
                            if(!IsCraftableCollected(craftable))
                            {
                                self addOpt("Collect All", &CollectCraftableParts, craftable);
                                self addOpt("");
                            }
                            
                            if(IsDefined(level.zombie_include_craftables[craftable].a_piecestubs))
                            {
                                foreach(part in level.zombie_include_craftables[craftable].a_piecestubs)
                                {
                                    if(IsPartCollected(part))
                                        continue;
                                    
                                    if(IsDefined(part.pieceSpawn.model))
                                        self addOpt(CleanString(part.pieceSpawn.piecename), &CollectCraftablePart, part);
                                }
                            }
                        }
                    }
            }
            else
            {
                if(!IsDefined(self.SelectedPlayer))
                    self.SelectedPlayer = self;
                
                self MenuOptionsPlayer(menu, self.SelectedPlayer);
            }
            break;
    }
}

function MenuOptionsPlayer(menu, player)
{
    if(!IsDefined(player) || !IsPlayer(player))
        menu = "404";
    
    switch(menu)
    {
        case "Basic Scripts":
        case "Perk Menu":
        case "Gobblegum Menu":
        case "Visual Effects":
            self PopulateBasicScripts(menu, player);
            break;
        
        case "Teleport Menu":
        case "Entity Teleports":            
            self PopulateTeleportMenu(menu, player);
            break;

        case "Weaponry":
        case "Weapon Options":
        case "Weapon Loadout":
        case "Weapon Camo":
        case "Weapon Attachments":
        case "Weapon AAT":
        case "Equipment Menu":
            self PopulateWeaponry(menu, player);
            break;
        
        case "Bullet Menu":
        case "Weapon Projectiles":
        case "Equipment Bullets":
        case "Bullet Effects":
        case "Bullet Spawnables":
        case "Explosive Bullets":
            self PopulateBulletMenu(menu, player);
            break;
        
        case "Fun Scripts":
        case "Sounds & Jingles":
        case "Perk Jingles & Quotes":
        case "Effects Man Options":
        case "Hit Markers":
        case "Force Field Options":
            self PopulateFunScripts(menu, player);
            break;
        
        case "Model Manipulation":
            self PopulateModelManipulation(menu, player);
            break;
        
        case "Aimbot Menu":
            self PopulateAimbotMenu(menu, player);
            break;
        
        case "Options":
        case "Verification":
        case "Model Attachment":
        case "Malicious Options":
        case "Disable Actions":
            self PopulatePlayerOptions(menu, player);
            break;
        
        default:
            weapons = Array("Assault Rifles", "Sub Machine Guns", "Light Machine Guns", "Sniper Rifles", "Shotguns", "Pistols", "Launchers", "Specials");
            MenuVOXCategory = [];

            foreach(category, sound in level.sndplayervox)
                array::add(MenuVOXCategory, CleanString(category, true), 0);
            
            if(isInArray(weapons, menu))
            {
                for(a = 0; a < weapons.size; a++)
                {
                    if(weapons[a] == menu)
                        index = a;
                }

                self PopulateWeaponCategoryMenu(menu, index, player);
            }
            else if(isInArray(MenuVOXCategory, menu))
            {
                self PopulateFunScripts(menu, player);
            }
            else
            {
                error404 = true;

                if(IsSubStr(menu, ReturnMapName() + " Teleports") || menu == ReturnMapName() + " Teleports")
                {
                    error404 = false;
                    locations = GenerateMapTeleports();

                    self addMenu(ReturnMapName() + " Teleports");
                        
                        if(IsDefined(locations) && locations.size)
                        {
                            for(a = 0; a < locations.size; a += 2)
                                self addOpt(locations[a], &TeleportPlayer, locations[(a + 1)], player, undefined, locations[a]);
                        }
                }

                if(error404)
                {
                    self addMenu("404 ERROR");
                        self addOpt("Page Not Found");
                }
            }
            break;
    }
}

// ============================================================
// Menu/overrides.gsc
// ============================================================

function SetGameOverrides()
{
    level.player_out_of_playable_area_monitor = 0;
    level.player_out_of_playable_area_monitor_callback = &player_out_of_playable_area_monitor;
    level.player_intersection_tracker_override = &player_intersection_tracker;

    if(IsDefined(level.overrideplayerdamage))
        level.saved_overrideplayerdamage = level.overrideplayerdamage;

    level.overrideplayerdamage = &override_player_damage;

    if(IsDefined(level.global_damage_func))
        level.saved_global_damage_func = level.global_damage_func;
    
    level.global_damage_func = &override_zombie_damage;

    if(IsDefined(level.global_damage_func_ads))
        level.saved_global_damage_func_ads = level.global_damage_func_ads;
    
    level.global_damage_func_ads = &override_zombie_damage_ads;

    if(IsDefined(level.callbackactorkilled))
        level.saved_callbackactorkilled = level.callbackactorkilled;
    
    level.callbackactorkilled = &override_actor_killed;

    if(ReturnMapName() != "Unknown")
        level.custom_game_over_hud_elem = &override_game_over_hud_elem;

    if(IsDefined(level.player_score_override))
        level.saved_player_score_override = level.player_score_override;
    
    level.player_score_override = &override_player_points;
}

function override_player_damage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
    if(Is_True(self.playerGodmode) || Is_True(self.PlayerDemiGod) || Is_True(self.NoExplosiveDamage) && zm_utility::is_explosive_damage(sMeansOfDeath) || Is_True(self.ControllableZombie) || Is_True(self.AC130) || Is_True(self.lander))
    {
        if(Is_True(self.PlayerDemiGod))
            self FakeDamageFrom(vDir);
        
        return 0;
    }

    if(iDamage > self.health)
    {
        self.retained_perks = [];

        if(Is_True(self._retain_perks))
        {
            perks = GetArrayKeys(level._custom_perks);

            if(IsDefined(perks) && perks.size)
            {
                MenuPerks = [];
                
                for(a = 0; a < perks.size; a++)
                    array::add(MenuPerks, perks[a], 0);
                
                for(a = 0; a < MenuPerks.size; a++)
                {
                    if(self HasPerk(MenuPerks[a]))
                    {
                        self.retained_perks[self.retained_perks.size] = MenuPerks[a];
                    }
                }
            }
        }
    }

    if(IsDefined(level.saved_overrideplayerdamage))
        return [[ level.saved_overrideplayerdamage ]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime);
    
    if(IsDefined(self.saved_playeroverrideplayerdamage))
        return [[ self.saved_playeroverrideplayerdamage ]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime);
    
    return zm::player_damage_override(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

function override_zombie_damage(mod, hit_location, hit_origin, player, amount, team, weapon, direction_vec, tagname, modelname, partname, dflags, inflictor, chargelevel)
{
    if(zm_utility::is_magic_bullet_shield_enabled(self) || IsDefined(self.marked_for_death) || !IsDefined(player) || self zm_spawner::check_zombie_damage_callbacks(mod, hit_location, hit_origin, player, amount, weapon, direction_vec, tagname, modelname, partname, dflags, inflictor, chargelevel))
        return;
    
    self CommonDamageOverride(mod, hit_location, hit_origin, player, amount, team, weapon, direction_vec, tagname, modelname, partname, dflags, inflictor, chargelevel);

    if(IsDefined(level.saved_global_damage_func))
        self thread [[ level.saved_global_damage_func ]](mod, hit_location, hit_origin, player, amount, team, weapon, direction_vec, tagname, modelname, partname, dflags, inflictor, chargelevel);
}

function override_zombie_damage_ads(mod, hit_location, hit_origin, player, amount, team, weapon, direction_vec, tagname, modelname, partname, dflags, inflictor, chargelevel)
{
    if(zm_utility::is_magic_bullet_shield_enabled(self) || !IsDefined(player) || self zm_spawner::check_zombie_damage_callbacks(mod, hit_location, hit_origin, player, amount, weapon, direction_vec, tagname, modelname, partname, dflags, inflictor, chargelevel))
        return;
    
    self CommonDamageOverride(mod, hit_location, hit_origin, player, amount, team, weapon, direction_vec, tagname, modelname, partname, dflags, inflictor, chargelevel);

    if(IsDefined(level.saved_global_damage_func_ads))
        self thread [[ level.saved_global_damage_func_ads ]](mod, hit_location, hit_origin, player, amount, team, weapon, direction_vec, tagname, modelname, partname, dflags, inflictor, chargelevel);
}

function CommonDamageOverride(mod, hit_location, hit_origin, player, amount, team, weapon, direction_vec, tagname, modelname, partname, dflags, inflictor, chargelevel)
{
    if(IsDefined(self))
    {
        if(IsDefined(level.ZombiesDamageFX))
            thread DisplayZombieEffect(level.ZombiesDamageFX, hit_origin);
        
        if(IsDefined(player) && IsPlayer(player))
        {
            if(Is_True(player.ExtraGore) && IsDefined(level._effect["bloodspurt"]))
            {
                fx = SpawnFX(level._effect["bloodspurt"], hit_origin, direction_vec);

                if(IsDefined(fx))
                    TriggerFX(fx);
            }
            
            if(IsDefined(player.hud_damagefeedback) && Is_True(player.ShowHitmarkers))
                player DamageFeedBack();
            
            if(amount == 696969 && self.health > amount)
            {
                self.maxhealth = 69;
                self.health = 69;
            }

            if(IsDefined(player.PlayerInstaKill) && (player.PlayerInstaKill == "All" || player.PlayerInstaKill == "Melee" && mod == "MOD_MELEE"))
            {
                self.health = 1;
                self DoDamage((self.health + 666), self.origin, player, self, hit_location, zm_utility::remove_mod_from_methodofdeath(mod));
                player notify("zombie_killed");
            }
        }
    }
}

function override_actor_killed(einflictor, attacker, idamage, smeansofdeath, weapon, vdir, shitloc, psoffsettime)
{
    if(game["state"] == "postgame")
        return;
    
    if(IsDefined(level.ZombiesDeathFX))
        thread DisplayZombieEffect(level.ZombiesDeathFX, self.origin);
    
    if(IsDefined(attacker) && IsPlayer(attacker))
    {
        if(Is_True(attacker.ExtraGore) && IsDefined(level._effect["bloodspurt"]))
        {
            fx = SpawnFX(level._effect["bloodspurt"], self.origin, vdir);

            if(IsDefined(fx))
                TriggerFX(fx);
        }

        if(IsDefined(attacker.hud_damagefeedback) && Is_True(attacker.ShowHitmarkers))
            attacker DamageFeedBack();
        
        if(Is_True(level.initAllTheWeapons))
        {
            baseWeapon = (!IsVerkoMap() ? zm_weapons::get_base_weapon(weapon) : weapon);

            if(baseWeapon == level.currentWeaponAllTheWeapons)
                level.killsAllTheWeapons++;
            
            if(level.killsAllTheWeapons >= level.killGoalAllTheWeapons)
            {
                level.indexAllTheWeapons++;
                level.killsAllTheWeapons = 0;
            }
        }
    }
    
    if(Is_True(self.explodingzombie) || Is_True(self.ZombieFling) || Is_True(level.ZombieRagdoll) || IsDefined(idamage) && IsInt(idamage) && idamage == 696969)
    {
        self thread zm_spawner::zombie_ragdoll_then_explode(VectorScale(vdir, 145), attacker);

        if(Is_True(self.explodingzombie) && !Is_True(self.nuked))
            self MagicGrenadeType(GetWeapon("frag_grenade"), self GetTagOrigin("j_mainroot"), (0, 0, 0), 0.01);
    }
    
    if(IsDefined(level.saved_callbackactorkilled))
        self thread [[ level.saved_callbackactorkilled ]](einflictor, attacker, idamage, smeansofdeath, weapon, vdir, shitloc, psoffsettime);
}

function override_player_points(damage_weapon, player_points)
{
    if(IsDefined(level.saved_player_score_override)) //Der Eisendrache and some custom maps use this override as well
        player_points = self [[ level.saved_player_score_override ]](damage_weapon, player_points);
    
    if(IsDefined(self.DamagePointsMultiplier) || Is_True(self.DisableEarningPoints)) player_points = ((IsDefined(self.DamagePointsMultiplier) && !Is_True(self.DisableEarningPoints)) ? (player_points * self.DamagePointsMultiplier) : 0);
    
    return player_points;
}

function DamageFeedBack()
{
    if(!IsDefined(self.hud_damagefeedback))
        return;
    
    if(IsDefined(self.HitMarkerColor))
    {
        if(IsString(self.HitMarkerColor) && self.HitMarkerColor == "Rainbow")
        {
            self.hud_damagefeedback thread HudRGBFade();
        }
        else
        {
            if(Is_True(self.hud_damagefeedback.RGBFade))
                self.hud_damagefeedback.RGBFade = BoolVar(self.hud_damagefeedback.RGBFade);
            
            self.hud_damagefeedback.color = GetColorVec(self.HitMarkerColor);
        }
    }
    
    self zombie_utility::show_hit_marker();

    if(IsDefined(self.HitmarkerFeedbackSound) && self.HitmarkerFeedbackSound != "None" && Is_True(self.hitsoundtracker))
        self PlaySoundToPlayer(self.HitmarkerFeedbackSound, self);
    
    if(IsDefined(self.HitmarkerFeedback))
        self.hud_damagefeedback SetShaderValues(self.HitmarkerFeedback, 24, 48);
}

function DisplayZombieEffect(fx, origin)
{
    if(!IsDefined(fx) || !IsString(fx) || !IsDefined(origin) || !IsVec(origin) || !IsDefined(level._effect) || !IsDefined(level._effect[fx]))
        return;
    
    impactfx = SpawnScriptModel(origin, "tag_origin");

    if(IsDefined(impactfx))
    {
        PlayFXOnTag(level._effect[fx], impactfx, "tag_origin");
        impactfx deleteAfter(0.5);
    }
}

function override_game_over_hud_elem(player, game_over, survived)
{
    game_over.alignx = "CENTER";
    game_over.aligny = "MIDDLE";

    game_over.horzalign = "CENTER";
    game_over.vertalign = "MIDDLE";

    game_over.y = (game_over.y - 130);
    game_over.foreground = 1;
    game_over.fontscale = 3;
    game_over.alpha = 0;
    game_over.color = (player hasMenu() ? level.RGBFadeColor : (1, 1, 1));
    game_over.hidewheninmenu = 1;

    game_over SetText((player hasMenu() ? "Thanks For Using " + GetMenuName() + " Developed By CF4_99" : &"ZOMBIE_GAME_OVER"));
    game_over FadeOverTime(1);
    game_over.alpha = 1;

    if(player IsSplitScreen())
    {
        game_over.fontscale = 2;
        game_over.y = (game_over.y + 40);
    }

    survived.alignx = "CENTER";
    survived.aligny = "MIDDLE";

    survived.horzalign = "CENTER";
    survived.vertalign = "MIDDLE";

    survived.y = (survived.y - 100);
    survived.foreground = 1;
    survived.fontscale = 2;
    survived.alpha = 0;
    survived.color = (player hasMenu() ? level.RGBFadeColor : (1, 1, 1));
    survived.hidewheninmenu = 1;

    if(player IsHost())
        player thread HoldMeleeToRestart(survived);

    if(player IsSplitScreen())
    {
        survived.fontscale = 1.5;
        survived.y = (survived.y + 40);
    }
}

function HoldMeleeToRestart(survived)
{
    if(!IsDefined(self))
        return;
    
    self endon("disconnect");

    while(survived.alpha != 1)
        wait 0.05;
    
    survived SetText("Press & Hold [{+melee}] To Restart The Match");
    goal = 15; //1.5 seconds

    while(1)
    {
        count = 0;

        while(self MeleeButtonPressed())
        {
            count++;

            if(count >= goal)
                break;
            
            wait 0.1;
        }

        if(count >= goal)
            break;
        
        wait 0.01;
    }

    if(count >= goal)
        ServerRestartGame();
}

function player_out_of_playable_area_monitor()
{
    return 0;
}

function player_intersection_tracker(player)
{
    return 1;
}

function WatchForMaxAmmo()
{
    if(Is_True(level.WatchForMaxAmmo))
        return;
    level.WatchForMaxAmmo = true;

    level endon("EndMaxAmmoMonitor");

    while(Is_True(level.ServerMaxAmmoClips))
    {
        level waittill("zmb_max_ammo_level");
        
        if(!Is_True(level.ServerMaxAmmoClips))
            continue;
        
        foreach(player in level.players)
        {
            if(!IsDefined(player) || !Is_Alive(player))
                continue;
            
            foreach(weapon in player GetWeaponsList(1))
            {
                if(!IsDefined(weapon) || weapon == level.weaponnone)
                    continue;
                
                clipAmmo = player GetWeaponAmmoClip(weapon);
                clipSize = weapon.clipsize;

                if(!IsDefined(clipAmmo) || !IsDefined(clipSize))
                    continue;

                if(clipAmmo < clipSize)
                    player SetWeaponAmmoClip(weapon, clipSize);

                if(weapon.isdualwield && weapon.dualwieldweapon != level.weaponnone)
                    player SetWeaponAmmoClip(weapon.dualwieldweapon, clipSize);
            }
        }
    }
}

function wallbuy_should_upgrade_weapon_override()
{
    return true;
}

function onPlayerDisconnect()
{
    if(self IsHost())
        return;
    
    foreach(player in level.players)
    {
        if(!IsDefined(player) || !IsPlayer(player) || player == self || !player hasMenu())
            continue;
        
        //If a player is navigating another players options, and that player disconnects, it will kick them back to the player menu
        if(IsDefined(player.menu_parent) && isInArray(player.menu_parent, "Players") && player.SelectedPlayer == self)
        {
            openMenu = player isInMenu(false);

            if(openMenu)
                player closeMenu1();
            
            player.menu_parent = [];
            player.currentMenu = "Players";
            player.menu_parent[player.menu_parent.size] = "Main";

            if(openMenu)
            {
                player openMenu1();
                player iPrintlnBold("^1ERROR: ^7Player Has Disconnected");
            }
        }
        else if(player isInMenu() && player getCurrent() == "Players") //If a player is viewing the player menu when a player disconnects, it will refresh the player list
        {
            player RefreshMenu();
        }
    }
}

// ============================================================
// Menu/StringTables.gsc
// ============================================================

function GobblegumName(name)
{
    return TableLookup("gamedata/stats/zm/zm_statstable.csv", 4, name, 3);
}

function ReturnCamoName(index)
{
    return TableLookupColumnForRow("gamedata/weapons/common/attachmenttable.csv", index, 3);
}

function ReturnRawCamoName(index)
{
    return TableLookupColumnForRow("gamedata/weapons/common/attachmenttable.csv", index, 4);
}

function ReturnAttachmentType(index)
{
    return TableLookup("gamedata/weapons/common/attachmenttable.csv", 0, index, 2);
}

function ReturnAttachment(index)
{
    return TableLookup("gamedata/weapons/common/attachmenttable.csv", 0, index, 4);
}

function ReturnAttachmentName(attachment)
{
    return TableLookup("gamedata/weapons/common/attachmenttable.csv", 4, attachment, 3);
}

function ReturnAttachmentCombinations(attachment)
{
    return TableLookup("gamedata/weapons/common/attachmenttable.csv", 4, attachment, 12);
}

function ReturnMusicRaw(index)
{
    return TableLookup("gamedata/tables/common/music_player.csv", 0, index, 1);
}

function ReturnMusicName(name)
{
    return TableLookup("gamedata/tables/common/music_player.csv", 1, name, 2);
}

// ============================================================
// Menu/utilities.gsc
// ============================================================

function createText(font, fontSize, sort, text, align, x, y, alpha, color)
{
    textElem = NewClientHudElem(self);
    textElem.elemtype = "font";
    
    textElem.hidewheninmenu = true;
    textElem.archived = self ShouldArchive();
    textElem.foreground = true;
    textElem.player = self;
    textElem.hidden = false;
    textElem.font = font;
    textElem.fontscale = fontSize;
    textElem.sort = sort;
    textElem.alpha = alpha;
    textElem.width = 0;
    textElem.height = Int(level.fontheight * fontSize);
    textElem.color = (IsDefined(color) ? (IsVec(color) ? GetColorVec(color) : (IsString(color) ? level.RGBFadeColor : (0, 0, 0))) : (0, 0, 0));
    textElem SetPoint(align, x, y);

    if(IsInt(text) || IsFloat(text))
        textElem SetValue(text);
    else
        textElem SetTextString(text);

    self.hud_count++;
    return textElem;
}

function LUI_createText(text, align, x, y, width, color)
{
    textElem = self OpenLUIMenu("HudElementText");

    //0 - LEFT | 1 - RIGHT | 2 - CENTER
    self SetLUIMenuData(textElem, "text", text);
    self SetLUIMenuData(textElem, "alignment", align);
    self SetLUIMenuData(textElem, "x", x);
    self SetLUIMenuData(textElem, "y", y);
    self SetLUIMenuData(textElem, "width", width);
    
    color = GetColorVec(color);

    self SetLUIMenuData(textElem, "red", color[0]);
    self SetLUIMenuData(textElem, "green", color[1]);
    self SetLUIMenuData(textElem, "blue", color[2]);

    return textElem;
}

function createServerText(font, fontSize, sort, text, align, x, y, alpha, color)
{
    textElem = NewHudElem();
    textElem.elemtype = "font";
    
    textElem.hidewheninmenu = true;
    textElem.archived = true;
    textElem.foreground = true;
    textElem.player = self;
    textElem.hidden = false;
    textElem.font = font;
    textElem.fontscale = fontSize;
    textElem.sort = sort;
    textElem.alpha = alpha;
    textElem.width = 0;
    textElem.height = Int(level.fontheight * fontSize);
    textElem.color = (IsDefined(color) ? (IsVec(color) ? GetColorVec(color) : (IsString(color) ? level.RGBFadeColor : (0, 0, 0))) : (0, 0, 0));
    textElem SetPoint(align, x, y);

    if(IsInt(text) || IsFloat(text))
        textElem SetValue(text);
    else
        textElem SetTextString(text);
    
    return textElem;
}

function createRectangle(align, x, y, width, height, color, sort, alpha, shader)
{
    uiElement = NewClientHudElem(self);
    uiElement.elemType = "icon";
    
    uiElement.hidewheninmenu = true;
    uiElement.archived = self ShouldArchive();
    uiElement.foreground = true;
    uiElement.hidden = false;
    uiElement.player = self;
    uiElement.sort = sort;
    uiElement.color = ((IsDefined(color) && IsVec(color)) ? GetColorVec(color) : (IsString(color) ? level.RGBFadeColor : (0, 0, 0)));
    uiElement.alpha = alpha;
    
    uiElement SetShaderValues(shader, width, height);
    uiElement SetPoint(align, x, y);

    self.hud_count++;
    return uiElement;
}

function LUI_createRectangle(align, x, y, width, height, color, shader, alpha)
{
    boxElem = self OpenLUIMenu("HudElementImage");

    //0 - LEFT | 1 - RIGHT | 2 - CENTER
    self SetLUIMenuData(boxElem, "alignment", align);
    self SetLUIMenuData(boxElem, "x", x);
    self SetLUIMenuData(boxElem, "y", y);
    self SetLUIMenuData(boxElem, "width", width);
    self SetLUIMenuData(boxElem, "height", height);
    self SetLUIMenuData(boxElem, "alpha", alpha);
    self SetLUIMenuData(boxElem, "material", shader);

    color = GetColorVec(color);

    self SetLUIMenuData(boxElem, "red", color[0]);
    self SetLUIMenuData(boxElem, "green", color[1]);
    self SetLUIMenuData(boxElem, "blue", color[2]);

    return boxElem;
}

function createServerRectangle(align, x, y, width, height, color, sort, alpha, shader)
{
    uiElement = NewHudElem();
    uiElement.elemType = "icon";
    
    uiElement.hidewheninmenu = true;
    uiElement.archived = true;
    uiElement.foreground = true;
    uiElement.hidden = false;
    uiElement.sort = sort;
    uiElement.color = GetColorVec(color);
    uiElement.alpha = alpha;
    
    uiElement SetShaderValues(shader, width, height);
    uiElement SetPoint(align, x, y);
    
    return uiElement;
}

function createWaypoint(origin, shader = "damage_feedback_glow_orange", color = (1, 1, 1), alpha = 1)
{
    uiElement = NewClientHudElem(self);
    uiElement.sort = 0;
    uiElement.archived = 1;
    uiElement.x = origin[0];
    uiElement.y = origin[1];
    uiElement.z = origin[2];
    uiElement.alpha = alpha;
    uiElement.color = color;
    
    uiElement SetShader("damage_feedback_glow_orange", 15, 15);
    uiElement SetWaypoint(false);
    
    return uiElement;
}

function SetPoint(point = "CENTER", xpos = 0, ypos = 0)
{
    self.alignx = "center";
    self.aligny = "middle";

    self.x = xpos;
    self.y = ypos;

    switch(point)
    {
        case "TOP":
            self.aligny = "top";
            break;

        case "BOTTOM":
            self.aligny = "bottom";
            break;

        case "LEFT":
            self.alignx = "left";
            break;

        case "RIGHT":
            self.alignx = "right";
            break;

        case "TOPRIGHT":
        case "TOP_RIGHT":
            self.aligny = "top";
            self.alignx = "right";
            break;

        case "TOPLEFT":
        case "TOP_LEFT":
            self.aligny = "top";
            self.alignx = "left";
            break;

        case "TOPCENTER":
            self.aligny = "top";
            self.alignx = "center";
            break;

        case "BOTTOM RIGHT":
        case "BOTTOM_RIGHT":
            self.aligny = "bottom";
            self.alignx = "right";
            break;

        case "BOTTOM LEFT":
        case "BOTTOM_LEFT":
            self.aligny = "bottom";
            self.alignx = "left";
            break;

        default:
            break;
    }
}

function GetColorVec(color)
{
    colors = Array(0, 0, 0);

    if(IsDefined(color) && IsVec(color))
    {
        for(a = 0; a < 3; a++)
        {
            c = (IsDefined(color[a]) ? color[a] : 0);

            if(c < 0)
                c = 0;
            else if(c > 255)
                c = 255;
            
            colors[a] = ((c >= 0 && c <= 1) ? c : (c / 255));
        }
    }

    return (colors[0], colors[1], colors[2]);
}

function ShouldArchive(count)
{
    if(!IsDefined(count))
        count = self.hud_count;

    if(Is_True(self.StealthUI))
        return false;
    
    if(!Is_Alive(self) || count < 26)
        return false;
    
    return true;
}

function DestroyHud()
{
    if(!IsDefined(self))
        return;
    
    self destroy();

    if(IsDefined(self.player) && IsPlayer(self.player))
    {
        self.player.hud_count--;

        if(self.player.hud_count < 0)
            self.player.hud_count = 0;
    }
}

function SetTextString(text)
{
    if(!IsDefined(self) || !IsDefined(text))
        return;
    
    text = AddToStringCache(text);

    self.text = text;
    self SetText(text);
}

function AddToStringCache(text)
{
    if(IsBlankString(text))
        return "";

    if(!IsDefined(level.uniqueStrings))
        level.uniqueStrings = [];

    if(!IsDefined(level.uniqueStringCount))
        level.uniqueStringCount = 0;

    IsUniqueString = IsUniqueString(text);

    if(Is_True(IsUniqueString))
    {
        if(level.uniqueStringCount >= 1450)
        {
            text = "UNIQUE STRING LIMIT REACHED";

            if(!IsDefined(level.uniqueStringLimitNotify))
            {
                bot::get_host_player() DebugiPrint("^1" + ToUpper(GetMenuName()) + ": ^7Unique String Limit Has Been Reached. To Prevent Crashing, No More Unique Strings Will Be Created.");
                level.uniqueStringLimitNotify = true;
            }
        }
        else
        {
            level.uniqueStringCount++;

            if(!IsDefined(level.uniqueStrings[text[0]]))
                level.uniqueStrings[text[0]] = [];
            
            level.uniqueStrings[text[0]][level.uniqueStrings[text[0]].size] = text;
        }
    }
    
    if(!IsSubStr(text, "[{"))
        text = MakeLocalizedString(text);

    return text;
    fixme = "}";
}

function IsUniqueString(text)
{
    if(!IsDefined(level.uniqueStrings) || !isInArray(GetArrayKeys(level.uniqueStrings), text[0]))
        return true;
    
    return !isInArray(level.uniqueStrings[text[0]], text);
}

function IsBlankString(text)
{
    if(!IsDefined(text) || text == "")
        return true;

    for(a = 0; a < text.size; a++)
    {
        if(text[a] != " ")
            return false;
    }

    return true;
}

function SetShaderValues(shader, width, height)
{
    if(!IsDefined(self))
        return;
    
    if(!IsDefined(shader))
    {
        if(!IsDefined(self.shader))
            return;
        
        shader = self.shader;
    }
    
    if(!IsDefined(width))
    {
        if(!IsDefined(self.width))
            return;
        
        width = self.width;
    }
    
    if(!IsDefined(height))
    {
        if(!IsDefined(self.height))
            return;
        
        height = self.height;
    }
    
    self.shader = shader;
    self.width = width;
    self.height = height;

    self SetShader(shader, width, height);
}

function hudMoveY(y, time)
{
    if(!IsDefined(self))
        return;
    
    if(time > 0)
        self MoveOverTime(time);
    
    self.y = y;

    if(time > 0)
        wait time;
}

function hudMoveX(x, time)
{
    if(!IsDefined(self))
        return;
    
    if(time > 0)
        self MoveOverTime(time);
    
    self.x = x;

    if(time > 0)
        wait time;
}

function hudMoveXY(x, y, time)
{
    if(!IsDefined(self))
        return;
    
    if(time > 0)
        self MoveOverTime(time);
    
    self.x = x;
    self.y = y;

    if(time > 0)
        wait time;
}

function hudFade(alpha, time)
{
    if(!IsDefined(self))
        return;
    
    if(time > 0)
        self FadeOverTime(time);
    
    self.alpha = alpha;

    if(time > 0)
        wait time;
}

function hudFadeDestroy(alpha = 0, time = 0)
{
    if(!IsDefined(self))
        return;
    
    self.fadeDestroy = true;
    
    if(time > 0)
        self hudFade(alpha, time);
    
    self DestroyHud();
}

function hudFadeColor(color, time)
{
    if(!IsDefined(self))
        return;
    
    if(time > 0)
        self FadeOverTime(time);
    
    self.color = GetColorVec(color);
}

function hudScaleOverTime(time, width, height)
{
    if(!IsDefined(self))
        return;
    
    if(time > 0)
        self ScaleOverTime(time, width, height);

    self.width = width;
    self.height = height;

    if(time > 0)
        wait time;
}

function HudRGBFade()
{
    if(!IsDefined(self) || Is_True(self.RGBFade))
        return;
    self.RGBFade = true;

    self endon("death");
    level endon("stop_intermission"); //For custom end game hud

    while(IsDefined(self) && Is_True(self.RGBFade))
    {
        self.color = level.RGBFadeColor;
        wait 0.01;
    }
}

function ChangeFontscaleOverTime1(scale, time)
{
    if(IsDefined(self.fontScale) && self.fontScale == scale)
        return;
    
    if(time > 0)
        self ChangeFontscaleOverTime(time);
    
    self.fontScale = scale;
}

function destroyAll(arry)
{
    if(!IsDefined(arry))
        return;
    
    keys = GetArrayKeys(arry);

    for(a = 0; a < keys.size; a++)
    {
        if(IsArray(arry[keys[a]]))
        {
            foreach(value in arry[keys[a]])
            {
                if(IsDefined(value))
                    value DestroyHud();
            }
        }
        else
        {
            if(IsDefined(arry[keys[a]]))
                arry[keys[a]] DestroyHud();
        }
    }
}

function getName()
{
    name = self.name;

    if(!IsDefined(name) || !IsString(name) || name == "")
        return "";

    if(name[0] != "[")
        return name;
    
    tagSize = -1;

    for(a = 1; a < name.size; a++)
    {
        if(name[a] == "]")
        {
            tagSize = a;
            break;
        }
    }

    if(tagSize < 0 || (tagSize - 1) > 4)
        return name;
    
    return GetSubStr(name, (tagSize + 1));
}

function GetMenuName()
{
    return "Apparition";
}

function GetColorNames()
{
    return Array("Red", "Green", "Blue", "Black", "White", "Gray", "Dodger Blue", "Ocean Blue", "Deep Blue", "Midnight Blue", "Sky Blue", "Cyan", "Aqua", "Teal", "Pink", "AIO Pink", "Hot Pink", "Rose", "Fuchsia", "Purple", "Lavender", "Violet", "Indigo", "Plasma Purple", "Neon Purple", "Crimson", "Fire Red", "Ruby", "Orange", "Deep Orange", "Yellow", "Gold", "Mint", "Lime", "Toxic Green", "Emerald");
}

function GetColorValues()
{
    return Array((255, 0, 0), (0, 255, 0), (0, 0, 255), (0, 0, 0), (255, 255, 255), (128, 128, 128), (57, 152, 254), (0, 100, 200), (0, 0, 139), (25, 25, 112), (135, 206, 250), (0, 255, 255), (0, 255, 200), (0, 128, 128), (255, 110, 255), (255, 150, 255), (255, 20, 147), (255, 102, 204), (255, 0, 255), (128, 0, 255), (200, 162, 255), (238, 130, 238), (75, 0, 130), (200, 0, 255), (170, 0, 255), (220, 20, 60), (255, 30, 30), (224, 17, 95), (255, 128, 0), (255, 80, 0), (255, 255, 0), (255, 215, 0), (152, 255, 152), (150, 255, 0), (0, 255, 100), (0, 201, 87));
}

function isInArray(arry, text)
{
    if(!IsDefined(arry) || !IsArray(arry) || !IsDefined(text))
        return false;
    
    for(a = 0; a < arry.size; a++)
    {
        if(arry[a] == text)
            return true;
    }

    return false;
}

function isInArrayKeys(arry, item)
{
    if(!IsDefined(arry) || !IsArray(arry) || !IsDefined(item))
        return false;
    
    foreach(key in GetArrayKeys(arry))
    {
        if(key == item)
            return true;
    }
    
    return false;
}

function ArrayRemove(arry, value)
{
    if(!IsDefined(arry) || !IsDefined(value))
        return;
    
    newArray = [];

    for(a = 0; a < arry.size; a++)
    {
        if(arry[a] != value)
            newArray[newArray.size] = arry[a];
    }

    return newArray;
}

function ArrayReverse(arry)
{
    newArray = [];

    for(a = (arry.size - 1); a >= 0; a--)
        newArray[newArray.size] = arry[a];

    return newArray;
}

function ArrayGetClosest(arry, point)
{
    if(!IsDefined(arry) || !IsArray(arry) || !arry.size || !IsDefined(point) || !IsVec(point))
        return;
    
    closest = undefined;

    foreach(ent in arry)
    {
        if(!IsDefined(ent) || !IsDefined(ent.origin) || !IsVec(ent.origin))
            continue;
        
        if(!IsDefined(closest) || Closer(point, ent.origin, closest.origin))
            closest = ent;
    }

    return closest;
}

function RemoveDuplicateEntArray(name)
{
    newarray = [];
    savearray = [];

    foreach(item in GetEntArray(name, "targetname"))
    {
        if(!isInArray(newarray, item.script_noteworthy))
        {
            newarray[newarray.size] = item.script_noteworthy;
            savearray[savearray.size] = item;
        }
    }

    return savearray;
}

function isConsole()
{
    return level.console;
}

function CleanString(strn, onlyReplace)
{
    if(!IsDefined(strn) || !IsString(strn) || strn == "")
        return "";
    
    if(strn[0] == ToUpper(strn[0]))
    {
        if(IsSubStr(strn, " ") && !IsSubStr(strn, "_"))
            return strn;
    }
    
    strn = StrTok(ToLower(strn), "_");
    str = "";

    //List of strings what will be removed from the final string output
    strings = Array("specialty", "zombie", "zm", "t7", "t6", "p7", "zmb", "zod", "ai", "g", "bg", "perk", "player", "weapon", "wpn", "aat", "bgb", "visionset", "equip", "craft", "der", "viewmodel", "mod", "fxanim", "moo", "moon", "zmhd", "fb", "bc", "asc", "vending", "part", "camo", "placeholder", "zmu", "hat", "ctl", "hd", "ori", "veh", "zhd", "isl");

    //This will replace any '_' found in the string
    replacement = " ";
    
    for(a = 0; a < strn.size; a++)
    {
        if(!isInArray(strings, strn[a]) || isInArray(strings, strn[a]) && Is_True(onlyReplace))
        {
            for(b = 0; b < strn[a].size; b++)
                str += ((b != 0) ? strn[a][b] : ToUpper(strn[a][b]));
            
            if(a != (strn.size - 1))
                str += replacement;
        }
    }
    
    return str;
}

function CleanName(name)
{
    if(!IsDefined(name) || !IsString(name) || name == "")
        return "";
    
    str = "";
    invalid = Array("^A", "^B", "^F", "^H", "^I", "^0", "^1", "^2", "^3", "^4", "^5", "^6", "^7", "^8", "^9", "j=");

    for(a = 0; a < name.size; a++)
    {
        if(a < (name.size - 1))
        {
            if(isInArray(invalid, name[a] + name[(a + 1)]))
            {
                a += 2;

                if(a >= name.size)
                    break;
            }
        }
        
        if(IsDefined(name[a]) && a < name.size)
            str += name[a];
    }
    
    return str;
}

function CalcDistance(speed, origin, moveto)
{
    return Distance(origin, moveto) / speed;
}

function TraceBullet()
{
    return BulletTrace(self GetEye(), self GetEye() + VectorScale(AnglesToForward(self GetPlayerAngles()), 1000000), 0, self)["position"];
}

function AngleNormalize180(angle)
{
    if(!IsDefined(angle))
        return (0, 0, 0);
    
    v3 = Floor((angle * 0.0027777778));
    result = (((angle * 0.0027777778) - v3) * 360.0);
    angle = (((result - 360.0) < 0.0) ? (((angle * 0.0027777778) - v3) * 360.0) : (result - 360.0));

    if(angle > 180)
        angle -= 360;
    
    return angle;
}

function SpawnScriptModel(origin, model, angles = (0, 0, 0), time)
{
    if(!IsDefined(origin) || !IsVec(origin))
        return;
    
    if(IsDefined(time))
        wait time;

    ent = Spawn("script_model", origin);

    if(IsDefined(model))
        ent SetModel(model);
    
    ent.angles = angles;

    return ent;
}

function SpawnProp(origin = (0, 0, 0), model = "defaultactor", angles = (0, 0, 0), bounce = true, glow = true, triggerFunction, hintString)
{
    prop = SpawnScriptModel(origin, model, angles);

    if(!IsDefined(prop))
        return;
    
    prop.original_origin = origin;

    if(IsDefined(triggerFunction) && IsFunctionPtr(triggerFunction))
        prop.triggerFunction = triggerFunction;
    
    if(IsDefined(hintString) && IsString(hintString))
        prop.hintString = hintString;
    
    if(Is_True(glow))
        prop clientfield::set("powerup_fx", Int(Pow(2, RandomInt(3))));
    
    if(IsDefined(prop.triggerFunction) || Is_True(bounce))
        prop thread ActivateProp(origin, bounce);

    return prop;
}

function ActivateProp(origin, bounce = true)
{
    if(!IsDefined(self) || !IsDefined(origin) || Is_True(self.propActivated))
        return;
    
    self.propActivated = true;
    
    self endon("death");

    if(IsDefined(self.triggerFunction))
    {
        self MakeUsable();
        self SetCursorHint("HINT_NOICON");

        if(IsDefined(self.hintString))
            self SetHintString(self.hintString);

        self thread PropTrigger();
    }
    
    if(Is_True(bounce))
    {
        while(IsDefined(self) && Is_True(self.propActivated))
        {
            for(a = 0; a < 2; a++)
            {
                if(!IsDefined(self) || !Is_True(self.propActivated))
                    break;

                self MoveTo(self.original_origin + (0, 0, (25 - (50 * a))), 1, 0.25, 0.25);
                self RotateYaw(360, 1, 0.5, 0.5);
                wait 1;
            }

            wait 0.1;
        }
    }
}

function PropTrigger()
{
    if(!IsDefined(self))
        return;
    
    self endon("death");

    while(IsDefined(self))
    {
        self waittill("trigger", player);

        if(!IsDefined(self) || !IsPlayer(player) || !Is_Alive(player) || player isDown() || !IsDefined(self.triggerFunction) || !Is_True(self.propActivated))
            continue;

        player thread [[ self.triggerFunction ]]();
    }
}

function deleteAfter(time)
{
    wait time;

    if(IsDefined(self))
        self Delete();
}

function SetTextFX(text, time = 3)
{
    if(!IsDefined(text) || !IsDefined(self))
        return;
    
    self SetTextString(text);
    self thread hudFade(1, 0.5);
    self SetTypeWriterFX(38, Int((time * 1000)), 1000);
    wait time;

    if(IsDefined(self))
        self hudFade(0, 0.5);

    if(IsDefined(self))
        self DestroyHud();
}

function PulseFXText(text, hud)
{
    if(!IsDefined(text) || !IsDefined(hud))
        return;
    
    hud SetTextString(text);
    
    while(IsDefined(hud))
    {
        hud.color = (RandomInt(255) / 255, RandomInt(255) / 255, RandomInt(255) / 255);
        hud SetCOD7DecodeFX(25, 2000, 500);
        wait 3;
    }
}

function TypeWriterFXText(text, hud)
{
    if(!IsDefined(text) || !IsDefined(hud))
        return;
    
    hud SetTextString(text);

    while(IsDefined(hud))
    {
        hud.color = (RandomInt(255) / 255, RandomInt(255) / 255, RandomInt(255) / 255);
        hud SetTypeWriterFX(25, 2000, 500);
        wait 3;
    }
}

function RandomPosText(text, hud)
{
    if(!IsDefined(text) || !IsDefined(hud))
        return;
    
    hud SetTextString(text);
    
    while(IsDefined(hud))
    {
        hud FadeOverTime(2);
        hud.color = (RandomInt(255) / 255, RandomInt(255) / 255, RandomInt(255) / 255);
        hud thread hudMoveXY(RandomIntRange(-100, 475), RandomIntRange(20, 460), 2);
        wait 1.98;
    }
}

function PulsingText(text, hud)
{
    if(!IsDefined(text) || !IsDefined(hud))
        return;
    
    hud SetTextString(text);
    savedFontScale = hud.FontScale;
    
    while(IsDefined(hud))
    {
        hud ChangeFontscaleOverTime1(savedFontScale + 0.8, 0.6);
        hud hudFadeColor((RandomInt(255) / 255, RandomInt(255) / 255, RandomInt(255) / 255), 0.6);
        wait 0.6;

        if(IsDefined(hud))
        {
            hud ChangeFontscaleOverTime1(savedFontScale - 0.5, 0.6);
            hud hudFadeColor((RandomInt(255) / 255, RandomInt(255) / 255, RandomInt(255) / 255), 0.6);
            wait 0.6;
        }
    }
}

function FadingTextEffect(text, hud)
{
    if(!IsDefined(text) || !IsDefined(hud))
        return;
    
    hud SetTextString(text);
    hud.color = (RandomInt(255) / 255, RandomInt(255) / 255, RandomInt(255) / 255);

    while(IsDefined(hud))
    {
        hud hudFade(0, 1);
        
        if(IsDefined(hud))
            hud.color = (RandomInt(255) / 255, RandomInt(255) / 255, RandomInt(255) / 255);
        
        wait 0.25;

        if(IsDefined(hud))
            hud hudFade(1, 1);
        
        wait 0.25;
    }
}

function Keyboard(func, player)
{
    if(!self isInMenu())
        return;
    
    self endon("disconnect");
    
    if(IsDefined(self.menuUI["scroller"]))
    {
        self.menuUI["scroller"] hudScaleOverTime(0.1, 16, 16);
        self.menuUI["scroller"] hudFadeColor(self.MainTheme, 0.1);
    }
    
    self SoftLockMenu(130);
    
    letters = [];
    lettersTok = Array("0ANan=", "1BObo.", "2CPcp<", "3DQdq$", "4ERer#", "5FSfs-", "6GTgt{", "7HUhu}", "8IViv@", "9JWjw/", "^KXkx_", "!LYly[", "?MZmz]");
    
    for(a = 0; a < lettersTok.size; a++)
    {
        letters[a] = "";

        for(b = 0; b < lettersTok[a].size; b++)
            letters[a] += lettersTok[a][b] + "\n";
    }

    yOffset = ((self.MenuDesign == "Basic") ? 28 : 12);
    self.menuUI["kbString"] = self createText("objective", 1.1, 5, "", "CENTER", self.menuX + (self.menuUI["background"].width / 2), (self.menuUI["background"].y + yOffset), 1, (1, 1, 1));

    for(a = 0; a < letters.size; a++)
        self.menuUI["kbKeys" + a] = self createText("objective", 1.2, 5, letters[a], "CENTER", self.menuX + (self.menuUI["background"].width / 2) - (((lettersTok.size - 1) * 15) / 2) + (a * 15), (self.menuUI["kbString"].y + 20), 1, (1, 1, 1));
    
    if(IsDefined(self.menuUI["scroller"]))
        self.menuUI["scroller"] hudMoveXY(self.menuUI["kbKeys0"].x - 8, (self.menuUI["kbKeys0"].y - 8), 0.01);
    
    cursY = 0;
    cursX = 0;
    strng = "";

    self SetMenuInstructions(Array("[{+actionslot 1}]/[{+actionslot 2}]/[{+actionslot 3}]/[{+actionslot 4}] - Scroll", "[{+activate}] - Select", "[{+frag}] - Add Space", "[{+gostand}] - Confirm", "[{+melee}] - Backspace/Cancel"));
    wait 0.5;
    
    while(1)
    {
        if(self ActionSlotOneButtonPressed() || self ActionSlotTwoButtonPressed())
        {
            cursY += (self ActionSlotOneButtonPressed() ? -1 : 1);

            if(cursY < 0 || cursY > 5) cursY = ((cursY < 0) ? 5 : 0);
            
            if(IsDefined(self.menuUI["scroller"]))
                self.menuUI["scroller"] thread hudMoveY((self.menuUI["kbKeys0"].y - 8) + (14.5 * cursY), 0.05);
            
            wait 0.05;
        }
        else if(self ActionSlotThreeButtonPressed() || self ActionSlotFourButtonPressed())
        {
            fixDir = (self GamepadUsedLast() ? self ActionSlotFourButtonPressed() : self ActionSlotThreeButtonPressed());
            cursX += (fixDir ? 1 : -1);

            if(cursX < 0 || cursX > 12) cursX = ((cursX < 0) ? 12 : 0);
            
            if(IsDefined(self.menuUI["scroller"]))
                self.menuUI["scroller"] thread hudMoveX((self.menuUI["kbKeys0"].x - 8) + (15 * cursX), 0.05);
            
            wait 0.05;
        }
        else if(self UseButtonPressed())
        {
            if(strng.size < 45)
            {
                strng += lettersTok[cursX][cursY];
                self.menuUI["kbString"] SetTextString(strng);
            }
            else
            {
                self iPrintlnBold("^1ERROR: ^7Max String Size Reached");
            }

            wait 0.15;
        }
        else if(self FragButtonPressed())
        {
            if(strng.size < 45)
            {
                strng += " ";
                self.menuUI["kbString"] SetTextString(strng);
            }
            else
            {
                self iPrintlnBold("^1ERROR: ^7Max String Size Reached");
            }

            wait 0.1;
        }
        else if(self JumpButtonPressed())
        {
            if(!strng.size)
                break;

            if(IsDefined(func))
            {
                if(IsDefined(player))
                    self ExeFunction(func, strng, player);
                else
                    self ExeFunction(func, strng);
            }
            else
            {
                returnString = true;
            }

            break;
        }
        else if(self MeleeButtonPressed())
        {
            if(strng.size)
            {
                backspace = "";

                for(a = 0; a < (strng.size - 1); a++)
                    backspace += strng[a];

                strng = backspace;
                self.menuUI["kbString"] SetTextString(strng);

                wait 0.1;
            }
            else
            {
                break;
            }
        }

        wait 0.05;
    }
    
    self SoftUnlockMenu();
    self SetMenuInstructions();

    if(IsDefined(returnString))
        return strng;
}

function NumberPad(func, player, param)
{
    if(!self isInMenu())
        return;
    
    self endon("disconnect");

    if(IsDefined(self.menuUI["scroller"]))
    {
        self.menuUI["scroller"] hudScaleOverTime(0.1, 14, 14);
        self.menuUI["scroller"] hudFadeColor(self.MainTheme, 0.1);
    }
    
    self SoftLockMenu(58);
    
    letters = [];

    for(a = 0; a < 10; a++)
        letters[a] = a;
    
    yOffset = ((self.MenuDesign == "Basic") ? 28 : 12);
    self.menuUI["kbString"] = self createText("objective", 1.2, 5, 0, "CENTER", self.menuX + (self.menuUI["background"].width / 2), (self.menuUI["background"].y + yOffset), 1, (1, 1, 1));

    for(a = 0; a < letters.size; a++)
        self.menuUI["kbKeys" + a] = self createText("objective", 1.2, 5, letters[a], "CENTER", self.menuX + (self.menuUI["background"].width / 2) - (((letters.size - 1) * 15) / 2) + (a * 15), (self.menuUI["kbString"].y + 20), 1, (1, 1, 1));
    
    if(IsDefined(self.menuUI["scroller"]))
        self.menuUI["scroller"] hudMoveXY(self.menuUI["kbKeys0"].x - 7, (self.menuUI["kbKeys0"].y - 7), 0.01);
    
    cursX = 0;
    stringLimit = 10;
    strng = "0";

    self SetMenuInstructions(Array("[{+actionslot 3}]/[{+actionslot 4}] - Scroll", "[{+activate}] - Select", "[{+gostand}] - Confirm", "[{+melee}] - Backspace/Cancel"));
    wait 0.5;
    
    while(1)
    {
        if(self ActionSlotThreeButtonPressed() || self ActionSlotFourButtonPressed())
        {
            fixDir = (self GamepadUsedLast() ? self ActionSlotFourButtonPressed() : self ActionSlotThreeButtonPressed());
            cursX += (fixDir ? 1 : -1);

            if(cursX < 0 || cursX > 9) cursX = ((cursX < 0) ? 9 : 0);

            if(IsDefined(self.menuUI["scroller"]))
                self.menuUI["scroller"] thread hudMoveX((self.menuUI["kbKeys0"].x - 7) + (15 * cursX), 0.05);
            
            wait 0.05;
        }
        else if(self UseButtonPressed())
        {
            if(strng.size < stringLimit)
            {
                if(strng == "0")
                    strng = "";
                
                strng += letters[cursX];
                self.menuUI["kbString"] SetValue(Int(strng));
            }

            wait 0.15;
        }
        else if(self JumpButtonPressed())
        {
            if(!strng.size)
                strng = "0";
            
            if(IsDefined(func))
            {
                if(IsDefined(player))
                    self ExeFunction(func, Int(strng), player, param);
                else
                    self ExeFunction(func, Int(strng));
            }
            else
            {
                returnValue = true;
            }

            break;
        }
        else if(self MeleeButtonPressed())
        {
            if(strng.size && strng != "0" && strng != "")
            {
                backspace = "";

                if(strng.size > 1)
                {
                    for(a = 0; a < (strng.size - 1); a++)
                        backspace += strng[a];
                    
                    strng = backspace;
                }
                else
                {
                    strng = "0";
                }
                
                self.menuUI["kbString"] SetValue(Int(strng));
                wait 0.1;
            }
            else
            {
                break;
            }
        }
        
        wait 0.05;
    }
    
    self SoftUnlockMenu();
    self SetMenuInstructions();

    if(IsDefined(returnValue))
        return Int(strng);
}

function RGBFade()
{
    if(IsDefined(level.RGBFadeColor))
        return;

    hue = RandomFloatRange(0, 1);
    value = 0.95;

    while(1)
    {
        scaled = (hue * 6);
        step = (Int(scaled) % 6);

        switch(step)
        {
            case 0:
                level.RGBFadeColor = (value, ((scaled - step) * value), 0);
                break;
            
            case 1:
                level.RGBFadeColor = (((1 - (scaled - step)) * value), value, 0);
                break;
            
            case 2:
                level.RGBFadeColor = (0, value, ((scaled - step) * value));
                break;
            
            case 3:
                level.RGBFadeColor = (0, ((1 - (scaled - step)) * value), value);
                break;
            
            case 4:
                level.RGBFadeColor = (((scaled - step) * value), 0, value);
                break;
            
            default:
                level.RGBFadeColor = (value, 0, ((1 - (scaled - step)) * value));
                break;
        }

        hue += 0.001; //speed -- The faster it goes, the more choppy it will look

        if(hue >= 1)
            hue -= 1;

        wait 0.01;
    }
}

function isDeveloper()
{
    return (self GetXUID() == "1100001444ecf60" || self GetXUID() == "1100001494c623f" || self GetXUID() == "110000109f81429" || self GetXUID() == "110000142b9f2ba" || self GetXUID() == "1100001186a8f57");
}

function isDown()
{
    if(!IsDefined(self) || !IsPlayer(self) || !Is_Alive(self))
        return false;
    
    return IsDefined(self.revivetrigger);
}

function Is_Alive(player)
{
    return (IsAlive(player) && IsDefined(player.sessionstate) && player.sessionstate != "spectator");
}

function CanControl(ai)
{
    if(!IsDefined(ai))
        return false;
    
    if(!IsAI(ai))
        return false;
    
    if(!IsAlive(ai))
        return false;
    
    if(Is_True(ai.is_traversing))
        return false;
    
    if(Is_True(ai.is_leaping))
        return false;
    
    if(Is_True(ai.barricade_enter))
        return false;
    
    if(IsDefined(ai.archetype) && ai.archetype == "zombie" && !zm_behavior::inplayablearea(ai))
        return false;
    
    return true;
}

function isPlayerLinked(exclude)
{
    ents = GetEntArray("script_model", "classname");

    if(!IsDefined(ents) || !ents.size)
        return false;

    for(a = 0; a < ents.size; a++)
    {
        if(self IsLinkedTo(ents[a]) && (!IsDefined(exclude) || ents[a] != exclude))
            return true;
    }

    return false;
}

function ReturnPerkName(perk)
{
    perk = ToLower(perk);
    
    switch(perk)
    {
        case "additionalprimaryweapon":
            return "Mule Kick";
        
        case "doubletap2":
            return "Double Tap";
        
        case "deadshot":
            return "Deadshot Daiquiri";
        
        case "armorvest":
            return "Jugger-Nog";
        
        case "quickrevive":
            return "Quick Revive";
        
        case "fastreload":
            return "Speed Cola";
        
        case "staminup":
            return "Stamin-Up";
        
        case "widowswine":
            return "Widow's Wine";
        
        case "electriccherry":
            return "Electric Cherry";
        
        case "gpsjammer":
            return "Snail's Pace Slurpee";
        
        case "vultureaid":
            return "Vulture Aid";
        
        case "directionalfire":
            return "Vigor Rush";
        
        case "phdflopper":
            return "PHD Flopper";
        
        case "jetquiet":
            return "Fighter's Fizz";
        
        case "immunecounteruav":
            return "I.C.U.";
        
        case "combat efficiency":
            return "Elemental Pop";
        
        case "nottargetedbyairsupport":
            return "Ethereal Razor";
        
        case "loudenemies":
            return "PHD Flopper";
        
        case "quieter":
            return "I.C.U.";
        
        default:
            return "Unknown Perk";
    }
}

function ReturnPowerupName(name)
{
    name = ToLower(name);
    
    switch(name)
    {
        case "code_cylinder_red":
            return "Red Cylinder";
        
        case "code_cylinder_yellow":
            return "Yellow Cylinder";
        
        case "code_cylinder_blue":
            return "Blue Cylinder";
        
        case "monkey_swarm":
            return "Monkey Swarm";
        
        case "insta_kill_ug":
            return "Insta-Kill UG";
        
        case "beast_mana":
            return "Beast Mana";
        
        case "bonfire_sale":
            return "Bonfire Sale";
        
        case "bonus_points_player":
            return "Bonus Points Player";
        
        case "bonus_points_team":
            return "Bonus Points Team";
        
        case "carpenter":
            return "Carpenter";
        
        case "demonic_rune_lor":
            return "Runic: Lor";
        
        case "demonic_rune_ulla":
            return "Runic: Ulla";
        
        case "demonic_rune_oth":
            return "Runic: Oth";
        
        case "demonic_rune_zor":
            return "Runic: Zor";
        
        case "demonic_rune_mar":
            return "Runic: Mar";
        
        case "demonic_rune_uja":
            return "Runic: Uja";
        
        case "castle_tram_token":
            return "Tram Token";
        
        case "double_points":
            return "Double Points";
        
        case "free_perk":
            return "Free Perk";
        
        case "empty_perk":
            return "Empty Perk";
        
        case "fire_sale":
            return "Fire Sale";
        
        case "full_ammo":
            return "Max Ammo";
        
        case "genesis_random_weapon":
            return "Random Weapon";
        
        case "insta_kill":
            return "Insta-Kill";
        
        case "island_seed":
            return "Seed";
        
        case "nuke":
            return "Nuke";
        
        case "shield_charge":
            return "Shield Charge";
        
        case "minigun":
            return "Death Machine";
        
        case "ww_grenade":
            return "Widow's Wine Grenades";
        
        case "zombie_blood":
            return "Zombie Blood";
        
        default:
            return CleanString(name);
    }
}

function ReturnMapName(map = level.script)
{
    switch(map)
    {
        case "zm_zod":
            return "Shadows Of Evil";
        
        case "zm_factory":
            return "The Giant";
        
        case "zm_castle":
            return "Der Eisendrache";
        
        case "zm_island":
            return "Zetsubou No Shima";
        
        case "zm_stalingrad":
            return "Gorod Krovi";
        
        case "zm_genesis":
            return "Revelations";
        
        case "zm_prototype":
            return "Nacht Der Untoten";
        
        case "zm_asylum":
            return "Verruckt";
        
        case "zm_sumpf":
            return "Shi No Numa";
        
        case "zm_theater":
            return "Kino Der Toten";
        
        case "zm_cosmodrome":
            return "Ascension";
        
        case "zm_temple":
            return "Shangri-La";

        case "zm_moon":
            return "Moon";
        
        case "zm_tomb":
            return "Origins";
        

        //supported custom maps
        case "zm_prison":
            return "Mob Of The Dead";
        
        case "zm_die":
            return "Die Rise";
        
        case "zm_vk_tra_sur_busdepot":
            return "Bus Depot";
        
        case "zm_vk_tra_sur_tunnel":
            return "Tunnel";

        case "zm_vk_tra_sur_diner":
            return "Diner";
        
        case "zm_vk_tra_sur_farm":
            return "Farm";
        
        case "zm_der_riese":
            return "Der Riese: Declassified";
        
        case "zm_leviathan":
            return "Leviathan";
        
        default:
            return "Unknown";
    }
}

function IsSupportedCustomMap(map = level.script)
{
    switch(map)
    {
        case "zm_prison":
        case "zm_die":
        case "zm_vk_tra_sur_busdepot":
        case "zm_vk_tra_sur_tunnel":
        case "zm_vk_tra_sur_diner":
        case "zm_vk_tra_sur_farm":
        case "zm_der_riese":
        case "zm_leviathan":
            return true;
        
        default:
            return false;
    }
}

function IsVerkoMap(map = level.script)
{
    return IsSubStr(map, "zm_vk_tra_");
}

function TriggerUniTrigger(struct, trigger_notify, time) //For Basic Uni Triggers
{
    if(!IsDefined(struct) || !IsDefined(trigger_notify))
        return;

    if(!IsDefined(time))
        time = 0.01;

    if(IsArray(struct))
    {
        foreach(index, entity in struct)
        {
            if(!IsDefined(entity))
                continue;
            
            entity notify(trigger_notify);
            wait time;
        }
    }
    else
    {
        struct notify(trigger_notify);
    }
}

function disconnect()
{
    StopAllMusic();
    ExitLevel(false);
}

function DisablePlayerInfo()
{
    level.DisablePlayerInfo = BoolVar(level.DisablePlayerInfo);
}

function IncludeIPInfo()
{
    level.IncludeIPInfo = BoolVar(level.IncludeIPInfo);
}

function PlayMusicTrack(track)
{
    if(!IsDefined(level.nextsong))
        level.nextsong = "";

    if(!IsDefined(level.musicsystem))
    {
        level.musicsystem = SpawnStruct();
        level.musicsystem.currentplaytype = 0;
        level.musicsystem.currentstate = undefined;
    }

    level notify("sndstatestop");

    foreach(player in level.players)
        player StopSounds();

    if(!IsDefined(track) || track == "" || level.nextsong == track)
    {
        level.nextsong = "";
        level.musicsystem.currentplaytype = 0;
        level.musicsystem.currentstate = undefined;
        music::setmusicstate("none");
        return;
    }

    level endon("sndstatestop");
    level endon("end_game");
    level endon("game_ended");

    level.nextsong = track;
    level.musicsystem.currentplaytype = 4;
    level.musicsystem.currentstate = track;

    ent = Spawn("script_origin", (0,0,0));

    if(IsDefined(ent))
    {
        ent thread KillMusicOnStop(track);
        ent PlaySound(track);
    }

    playbacktime = SoundGetPlaybackTime(track);
    wait((IsDefined(playbacktime) && playbacktime > 0) ? (playbacktime * 0.001) : 1);

    level.musicsystem.currentplaytype = 0;
    level.musicsystem.currentstate = undefined;
}

function KillMusicOnStop(track)
{
    level util::waittill_any("sndstatestop", "end_game", "game_ended");

    if(IsDefined(self))
        self StopSound(track);

    wait 0.1;

    if(IsDefined(self))
        self Delete();
}

function StopAllMusic()
{
    level endon("stopAllMusic");
    level notify("sndstatestop");
    level notify("end_mus");
    level notify("new_mus");

    level.nextsong = "";

    if(IsDefined(level.musicsystem))
    {
        level.musicsystem.currentplaytype = 0;
        level.musicsystem.currentState = undefined;
        level.musicsystem.queue = 0;
    }

    level zm_audio::sndmusicsystem_stopandflush();

    music::setmusicstate("none");
    music::setmusicstate("SILENT");
}

function SetMapSpawn(plyer, type)
{
    SetDvar(level.script + "Spawn" + (Int(StrTok(plyer, "Player ")[0]) - 1), ((IsDefined(type) && type == "Set") ? self.origin : ""));
}

function AntiEndGame()
{
    level.AntiEndGame = BoolVar(level.AntiEndGame);

    if(Is_True(level.AntiEndGame))
    {
        foreach(player in level.players)
        {
            if(Is_True(player.AntiEndGameHandler))
                continue;
            
            player.AntiEndGameHandler = true;
            player thread WatchForEndRound();
        }
    }
    else
    {
        level notify("EndAntiEndGame");

        level.hostforcedend = false;
        level.forcedend = false;
        level.gameended = false;

        foreach(player in level.players)
        {
            if(Is_True(player.AntiEndGameHandler))
                player.AntiEndGameHandler = BoolVar(player.AntiEndGameHandler);
        }
    }
}

function WatchForEndRound()
{
    self endon("disconnect");
    level endon("EndAntiEndGame");

    while(Is_True(level.AntiEndGame))
    {
        if(Is_True(level.hostforcedend))
            level.hostforcedend = false;
        
        if(Is_True(level.forcedend))
            level.forcedend = false;
        
        if(Is_True(level.gameended))
            level.gameended = false;

        self waittill("menuresponse", menu, response);

        if(response != "endround")
            continue;
        
        if(self IsHost())
            break;

        level.hostforcedend = true;
        level.forcedend = true;
        level.gameended = true;

        self iPrintlnBold("^1" + ToUpper(GetMenuName()) + ": ^7Blocked End Game Response");
        bot::get_host_player() DebugiPrint("^1" + ToUpper(GetMenuName()) + ": ^2" + CleanName(self getName()) + " ^7Tried To End The Game");
        wait 0.5; //buffer
    }
}

function EntityCountDisplay()
{
    self endon("disconnect");

    self.EntityCountDisplay = BoolVar(self.EntityCountDisplay);
    SetDvar("EntityCountDisplay", Is_True(self.EntityCountDisplay));
    
    if(Is_True(self.EntityCountDisplay))
    {
        GSpawnMax = ReturnMapGSpawnLimit();

        while(Is_True(self.EntityCountDisplay))
        {
            bgAlpha = ((self.MenuDesign == "Classic") ? 0.85 : 1);
            bgColor = ((self.MenuDesign == "Classic") ? (25, 25, 25) : ((self.MenuDesign == "Apparition") ? (42, 42, 42) : (0, 0, 0)));

            xPos = ((Is_True(self.ZombieCounter) && IsDefined(self.ZombieCounterHud) && IsDefined(self.ZombieCounterHud[0])) ? (self GetLUIMenuData(self.ZombieCounterHud[0], "width") + 4) : 5);
            yPos = 5;

            if(Is_Alive(self) && (!IsDefined(self.EntityCountHud) || !self.EntityCountHud.size))
            {
                if(!IsDefined(self.EntityCountHud))
                    self.EntityCountHud = [];

                self.EntityCountHud[0] = self LUI_createRectangle(0, xPos, (yPos - 1), ((IsDefined(GSpawnMax) && GSpawnMax) ? 217 : 145), 28, self.MainTheme, "white", 1);
                self.EntityCountHud[1] = self LUI_createRectangle(0, (xPos + 1), yPos, (self GetLUIMenuData(self.EntityCountHud[0], "width") - 2), (self GetLUIMenuData(self.EntityCountHud[0], "height") - 2), bgColor, "white", bgAlpha);
                
                self.EntityCountHud[2] = self LUI_createText(((IsDefined(GSpawnMax) && GSpawnMax) ? "Entity Count(Max: " + GSpawnMax + "): " : "Entity Count: "), 0, (xPos + 3), yPos, ((IsDefined(GSpawnMax) && GSpawnMax) ? 172 : 100), (1, 1, 1));
                self.EntityCountHud[3] = self LUI_createText(GetEntArray().size, 0, (self GetLUIMenuData(self.EntityCountHud[2], "x") + self GetLUIMenuData(self.EntityCountHud[2], "width")), self GetLUIMenuData(self.EntityCountHud[2], "y"), 255, (1, 1, 1));
            }
            else
            {
                if(IsDefined(self.EntityCountHud) && self.EntityCountHud.size)
                {
                    if(Is_Alive(self) && !Is_True(self.refreshEntityCount))
                    {
                        if(IsDefined(self.EntityCountHud[3]))
                            self SetLUIMenuData(self.EntityCountHud[3], "text", GetEntArray().size);
                        
                        xPositions = Array(xPos, (xPos + 1), (xPos + 3));

                        for(a = 0; a < 3; a++)
                        {
                            if(IsDefined(self.EntityCountHud[a]))
                            {
                                if(self GetLUIMenuData(self.EntityCountHud[a], "x") != xPositions[a])
                                    self SetLUIMenuData(self.EntityCountHud[a], "x", xPositions[a]);
                            }
                        }

                        if(IsDefined(self.EntityCountHud[2]) && IsDefined(self.EntityCountHud[3]))
                        {
                            valueX = (self GetLUIMenuData(self.EntityCountHud[2], "x") + self GetLUIMenuData(self.EntityCountHud[2], "width"));

                            if(self GetLUIMenuData(self.EntityCountHud[3], "x") != valueX)
                                self SetLUIMenuData(self.EntityCountHud[3], "x", valueX);
                        }
                    }
                    else
                    {
                        for(a = 0; a < self.EntityCountHud.size; a++)
                        {
                            if(IsDefined(self.EntityCountHud[a]))
                                self CloseLUIMenu(self.EntityCountHud[a]);
                        }
                        
                        self.EntityCountHud = undefined;
                        self.refreshEntityCount = undefined;
                    }
                }
            }

            wait 0.01;
        }
    }
    else
    {
        if(IsDefined(self.EntityCountHud) && self.EntityCountHud.size)
        {
            for(a = 0; a < self.EntityCountHud.size; a++)
            {
                if(IsDefined(self.EntityCountHud[a]))
                    self CloseLUIMenu(self.EntityCountHud[a]);
            }
        }

        self.EntityCountHud = undefined;
    }
}

function GSpawnProtection()
{
    GSpawnMax = ReturnMapGSpawnLimit();

    if(!IsDefined(GSpawnMax) || !GSpawnMax)
        return;

    level.GSpawnProtection = BoolVar(level.GSpawnProtection);

    if(Is_True(level.GSpawnProtection))
    {
        while(Is_True(level.GSpawnProtection))
        {
            entityCount = GetEntArray().size;
            ents = ArrayReverse(GetEntArray("script_model", "classname"));

            if(entityCount > (GSpawnMax - 20))
            {
                amount = ((entityCount >= GSpawnMax) ? 30 : 5);

                for(a = 0; a < amount; a++)
                {
                    if(IsDefined(ents[a]))
                        ents[a] Delete();
                }
                
                bot::get_host_player() DebugiPrint("^1" + ToUpper(GetMenuName()) + ": ^7G_Spawn Crash Prevented || " + entityCount + " -> " + GetEntArray().size);
            }
            
            wait 0.05;
        }
    }
}

function ReturnMapGSpawnLimit()
{
    switch(level.script)
    {
        case "zm_prototype":
            return 815;
        
        case "zm_asylum":
            return 850;
        
        case "zm_cosmodrome":
            return 890;
        
        case "zm_theater":
        case "zm_sumpf":
        case "zm_factory":
        case "zm_vk_tra_sur_tunnel":
        case "zm_vk_tra_sur_busdepot":
        case "zm_prison":
            return 915;
        
        case "zm_tomb":
        case "zm_moon":
        case "zm_temple":
        case "zm_der_riese":
            return 950;
        
        case "zm_stalingrad":
            return 980;
        
        case "zm_castle":
        case "zm_genesis":
        case "zm_vk_tra_sur_diner":
        case "zm_vk_tra_sur_farm":
            return 1000;
        
        case "zm_zod":
            return 1015;
        
        case "zm_die":
        case "zm_island":
            return 1050;
        
        case "zm_leviathan":
            return 1450;
        
        default:
            return 0;
    }
}

function TrisLines()
{
    value = GetDvarString("r_showTris");
    SetDvar("r_showTris", ((IsDefined(value) && value == "1") ? "0" : "1"));
}

function DevGUIInfo()
{
    value = GetDvarString("ui_lobbyDebugVis");
    SetDvar("ui_lobbyDebugVis", ((IsDefined(value) && value == "1") ? "0" : "1"));
}

function DisableFog()
{
    value = GetDvarString("r_fog");
    SetDvar("r_fog", ((IsDefined(value) && value == "1") ? "0" : "1"));
}

function ServerCheats()
{
    value = GetDvarString("sv_cheats");
    SetDvar("sv_cheats", ((IsDefined(value) && value == "1") ? "0" : "1"));
}

function SetDeveloperMode()
{
    value = GetDvarInt("developer");
    SetDvar("developer", ((IsDefined(value) && value == 0 || !IsDefined(value)) ? 2 : 0));
}

function GetGroundPos(position)
{
    return BulletTrace((position + (0, 0, 50)), (position - (0, 0, 1000)), 0, undefined)["position"];
}

function MenuCredits()
{
    if(Is_True(self.CreditsPlaying))
        return;
    self.CreditsPlaying = true;
    
    self endon("disconnect");
    
    self SoftLockMenu(220, true);
    MenuTextStartCredits = Array("^1" + GetMenuName(), "The Biggest & Best Menu For ^1Black Ops 3 Zombies", "Developed By: ^1CF4_99", "Discord.gg/^1apparitionbo3", " ", "^1Extinct", "Ideas", "Suggestions", "Constructive Criticism", "His Spec-Nade", " ", "^1ItsFebiven", "Ideas", "Suggestions", " ", "^1CraftyCritter", "BO3 GSC Compiler", " ", "^1Joel", "Testing", "Breaking Shit", "Bug Reporting", " ", "^1Thanks For Choosing " + GetMenuName(), "YouTube: ^1CF4_99", "Discord: ^1cf4_99");
    
    self thread MenuCreditsStart(MenuTextStartCredits);
    self SetMenuInstructions("[{+melee}] - Exit Menu Credits");
    
    while(Is_True(self.CreditsPlaying))
    {
        if(self MeleeButtonPressed())
            break;
        
        wait 0.025;
    }
    
    if(Is_True(self.CreditsPlaying))
        self.CreditsPlaying = BoolVar(self.CreditsPlaying);
    
    self notify("EndMenuCredits");
    self SetMenuInstructions();
    self SoftUnlockMenu();
}

function MenuCreditsStart(creditArray)
{
    self endon("disconnect");
    self endon("EndMenuCredits");
    
    self.menuUI["MenuCreditsHud"] = [];
    moveTime = 10;
    title = true;

    for(a = 0; a < creditArray.size; a++)
    {
        if(creditArray[a] != " ")
        {
            self.menuUI["MenuCreditsHud"][a] = self createText("objective", (title ? 1.4 : 1.1), 4, "", "CENTER", self.menuX + (self.menuUI["background"].width / 2), (self.menuUI["background"].y + (self.menuUI["background"].height - 8)), 0, (1, 1, 1));
            self thread CreditsFadeIn(self.menuUI["MenuCreditsHud"][a], creditArray[a], moveTime, 0.5);
            
            title = false;
            wait (moveTime / 12);
        }
        else
        {
            title = true;
            wait (moveTime / 4);
        }
    }
    
    wait moveTime;

    if(Is_True(self.CreditsPlaying))
        self.CreditsPlaying = BoolVar(self.CreditsPlaying);
}

function CreditsFadeIn(hud, text, moveTime, fadeTime)
{
    if(!IsDefined(hud))
        return;
    
    self endon("EndMenuCredits");
    
    self thread credits_delete(hud);
    hud SetTextString(text);
    hud thread hudFade(1, fadeTime);
    hud thread hudMoveY((self.menuUI["background"].y + 12), moveTime);
    
    wait (moveTime - fadeTime);
    
    if(IsDefined(hud))
        hud hudFadeDestroy(0, fadeTime);
}

function credits_delete(hud)
{
    if(!IsDefined(hud))
        return;
    
    self endon("disconnect");
    
    self waittill("EndMenuCredits");
    
    if(IsDefined(hud))
        hud DestroyHud();
}

function DebugiPrint(message)
{
    if(!IsDefined(self))
    {
        foreach(player in level.players)
            player DebugiPrint(message);
        
        return;
    }
    
    if(!IsDefined(self.PrintMessageQueue))
        self.PrintMessageQueue = [];
    
    if(!IsDefined(self.PrintMessageInt) || (IsDefined(self.PrintMessageInt) && self.PrintMessageInt > 4))
        self.PrintMessageInt = 0;
    
    if(IsDefined(self.PrintMessageQueue[self.PrintMessageInt]))
    {
        self CloseLUIMenu(self.PrintMessageQueue[self.PrintMessageInt]);
        self.PrintMessageQueue[self.PrintMessageInt] = undefined;

        self notify("PrintDeleted" + self.PrintMessageInt);
    }
    
    for(a = 0; a < 5; a++)
    {
        if(IsDefined(self.PrintMessageQueue[a]))
            self SetLUIMenuData(self.PrintMessageQueue[a], "y", (self GetLUIMenuData(self.PrintMessageQueue[a], "y") - 22));
    }
    
    self.PrintMessageQueue[self.PrintMessageInt] = self LUI_createText(message, 0, 20, 500 - ((GetPlayers().size - 1) * 22), 1000, (1, 1, 1));
    self thread iPrintMessageDestroy(self.PrintMessageInt);

    self.PrintMessageInt++;
}

function iPrintMessageDestroy(index)
{
    self endon("PrintDeleted" + index);

    wait 5;

    if(IsDefined(self.PrintMessageQueue[index]))
        self CloseLUIMenu(self.PrintMessageQueue[index]);
    
    self.PrintMessageQueue[index] = undefined;
}

/*
    Built To Auto-Size The Width Of A Shader Based On The String Length
    Supports The Use Of \n and button codes(when \n is used, it will scale based on the longest string line)
    Pass The Extra Scaling As A Parameter To Adjust To The Hud Fontscale(Default is 7 if no parameter is passed)

    This will auto-adjust to changes in fontscale
    It will only auto-adjust to the fontscale change if the fontscale is greater than 1.1
    If it is less than, or equal to 1.1, then it will just base it off of 1.1 by default
*/

function GetTextWidth3arc(player, widthScale)
{
    if(!IsDefined(self.text) || self.text == "")
        return 1;

    hasButtons = IsSubStr(self.text, "[{");
    fixme = "}";

    if(!IsDefined(widthScale))
    {
        if(hasButtons)
        {
            widthScale = 7;

            if(IsDefined(player) && IsPlayer(player) && player GamePadUsedLast())
                widthScale = 6;
        }
        else
        {
            widthScale = 5;
        }
    }

    widthScale = self GetHudScaleWidth(widthScale);
    nlToks = StrTok(self.text, "\n");
    longest = 0;
    longestSize = 0;

    for(a = 0; a < nlToks.size; a++)
    {
        stripped = StripStringButtons(nlToks[a]);

        if(stripped.size >= longestSize)
        {
            longest = a;
            longestSize = stripped.size;
        }
    }

    strng = StripStringButtons(nlToks[longest]);
    buttonCount = CountButtonCodes(nlToks[longest]);
    width = 1;

    for(a = 0; a < strng.size; a++)
        width += GetHUDCharWidth(strng[a], widthScale);

    if(buttonCount)
        width += Int(widthScale * 1.5) * buttonCount;

    if(width <= 0)
        return widthScale;

    return width;
}

function GetHUDCharWidth(ch, widthScale)
{
    if(IsSmallChar(ch))
        return 0;

    if(isInArray(Array("/", ":", "-", "&", "|", " "), ch))
        return Int(widthScale * 0.6);

    return widthScale;
}

function GetHudScaleWidth(scale)
{
    if(self.fontscale <= 1.1)
        return scale;

    extra = Int((self.fontscale - 1.1) * 10 + 0.0001);
    return scale + Int(extra / 2);
}

function CountButtonCodes(str)
{
    count = 0;

    if(!IsDefined(str) || str == "")
        return count;

    for(a = 0; a < (str.size - 1); a++)
    {
        if(str[a] == "[" && str[(a + 1)] == "{")
            count++;
    }

    return count;
    fixme = "}";
}

function StripStringButtons(str)
{
    if(!IsDefined(str) || str == "")
        return "";

    newString = "";

    for(a = 0; a < str.size; a++)
    {
        if(a < (str.size - 1) && str[a] == "[" && str[(a + 1)] == "{")
        {
            for(b = (a + 2); b < str.size; b++)
            {
                if(b < (str.size - 1) && str[b] == "}" && str[(b + 1)] == "]")
                {
                    a = (b + 1);
                    break;
                }
            }

            if(a >= str.size)
                break;

            continue;
        }

        if(a < (str.size - 1) && IsCodeChars(str[a] + str[(a + 1)]))
        {
            a++;
            continue;
        }

        if(IsSmallChar(str[a]))
            continue;

        newString += str[a];
    }

    return newString;
}

function IsCodeChars(chars)
{
    return isInArray(Array("^A", "^B", "^F", "^H", "^I", "^0", "^1", "^2", "^3", "^4", "^5", "^6", "^7", "^8", "^9"), chars);
}

function IsSmallChar(char)
{
    return isInArray(Array("[", "]", ".", ",", "'", "!", "{", "}", "|"), char);
}

/*
    Built to auto-size a shader based on the given string
    It auto-sizes based on every \n(next line) found in a string
    NOTE: it does not adjust to fontscale
*/

function CorrectNL_BGHeight(str)
{
    if(!IsDefined(str))
        return;
    
    if(!IsSubStr(str, "\n"))
        return 12;

    multiplier = 0;
    toks = StrTok(str, "\n");

    if(IsDefined(toks) && toks.size)
    {
        for(a = 0; a < toks.size; a++)
            multiplier++;
    }

    return 3 + (14 * multiplier);
}

//Decided to remake GetDvarVector
function GetDvarVector1(vecVar)
{
    dvar = "";
    vecVar = GetDvarString(vecVar);

    if(!IsDefined(vecVar) || vecVar == "")
        return (0, 0, 0);

    for(a = 0; a < vecVar.size; a++)
    {
        if(vecVar[a] != "(" && vecVar[a] != " " && vecVar[a] != ")")
            dvar += vecVar[a];
    }
    
    vals = [];
    toks = StrTok(dvar, ",");
    
    for(a = 0; a < toks.size; a++)
        vals[a] = Float(toks[a]);
    
    if(vals.size < 3)
        return (0, 0, 0);
    
    return (vals[0], vals[1], vals[2]);
}

function PlayerScoreIndex(index)
{
    self.PlayerScoreIndex = (index - 1);
    self RefreshMenu(self getCurrent(), self getCursor());
}

function PlayerScoreColor(color, index = 1)
{
    if(!IsDefined(color) || !IsVec(color))
        color = (1, 1, 1);
    
    SetDvar("scoreColor" + index, "" + color);
    
    color = GetColorVec(color);
    SetDvar("cg_scorescolor_gamertag_" + index, color[0] + " " + color[1] + " " + color[2] + " 1");
    self RefreshMenu(self getCurrent(), self getCursor());

    self iPrintlnBold("^1" + ToUpper(GetMenuName()) + ": ^7Score Color Will Update At The Start Of Your Next Match");
}

function FieldOfViewScale(scale)
{
    SetDvar("cg_fov", scale);
}

function FieldOfView(value)
{
    SetDvar("cg_fov_default", value);
}

function ShowOrigin()
{
    self.ShowOrigin = BoolVar(self.ShowOrigin);

    if(Is_True(self.ShowOrigin))
    {
        self endon("disconnect");
        self.originHud = [];

        for(a = 0; a < 3; a++)
            self.originHud[self.originHud.size] = self createText("default", 1, 1, 0, "CENTER", 320, 315 + (a * 16), 1, (1, 1, 1));

        while(Is_True(self.ShowOrigin))
        {
            for(a = 0; a < self.originHud.size; a++)
            {
                if(IsDefined(self.originHud[a]))
                    self.originHud[a] SetValue(self.origin[a]);
            }
            
            wait 0.01;
        }
    }
    else
    {
        if(IsDefined(self.originHud) && self.originHud.size)
        {
            for(a = 0; a < self.originHud.size; a++)
            {
                if(IsDefined(self.originHud[a]))
                    self.originHud[a] DestroyHud();
            }
        }
    }
}

function Is_True(boolVar)
{
    if(!IsDefined(boolVar) || !boolVar)
        return false;
    
    return true;
}

function BoolVar(variable)
{
    if(Is_True(variable))
        return undefined;
    
    return true;
}

// ============================================================
// Menu/verification.gsc
// ============================================================

function setVerification(access = 1, player, msg)
{
    if(IsString(access))
    {
        levels = GetAccessLevels();

        if(isInArray(levels, access))
        {
            for(a = 0; a < levels.size; a++)
            {
                if(levels[a] == access)
                {
                    access = a;
                    break;
                }
            }
        }
        else
        {
            access = 1;
        }
    }

    if(player IsHost() || player isDeveloper() || player getVerification() == access || player == self || player util::is_bot())
    {
        if(Is_True(msg))
        {
            if(player util::is_bot())
                return self iPrintlnBold("^1ERROR: ^7You Can't Change The Verification Of A Bot");
            
            if(player isHost())
                return self iPrintlnBold("^1ERROR: ^7You Can't Change The Status Of The Host");
            
            if(player isDeveloper())
                return self iPrintlnBold("^1ERROR: ^7You Can't Change The Status Of The Developer");
            
            if(player getVerification() == access)
                return self iPrintlnBold("^1ERROR: ^7Player's Verification Is Already Set To ^2" + GetAccessLevels()[access]);
            
            if(player == self)
                return self iPrintlnBold("^1ERROR: ^7You Can't Change Your Own Status");
        }

        return;
    }
    
    player.accessLevel = GetAccessLevels()[access];
    player iPrintlnBold("Your Status Has Been Set To ^2" + player.accessLevel);
    
    if(player isInMenu(true))
        player closeMenu1();
    
    player.currentMenu = undefined;
    player.menuCursor = undefined;
    player.menu_parent = undefined;
    player.menu_parentQM = undefined;
    
    player notify("endMenuMonitor");

    if(Is_True(player.menuMonitor))
        player.menuMonitor = BoolVar(player.menuMonitor);

    if(Is_True(player.MenuInstructionsDisplay))
        player.MenuInstructionsDisplay = BoolVar(player.MenuInstructionsDisplay);

    if(player hasMenu())
    {
        player thread MenuInstructionsDisplay();
        player thread menuMonitor();
    }
}

function SetVerificationAllPlayers(access = 1, msg)
{
    if(IsString(access))
    {
        levels = GetAccessLevels();

        if(isInArray(levels, access))
        {
            for(a = 0; a < levels.size; a++)
            {
                if(levels[a] == access)
                {
                    access = a;
                    break;
                }
            }
        }
        else
        {
            access = 1;
        }
    }

    foreach(player in level.players)
        self thread setVerification(access, player);
    
    if(Is_True(msg))
        self iPrintlnBold("All Players Verification Set To ^2" + GetAccessLevels()[access]);
}

function getVerification()
{
    if(self util::is_bot())
        return 0;
    
    if(!IsDefined(self.accessLevel))
        return 1;

    for(a = 0; a < GetAccessLevels().size; a++)
    {
        if(self.accessLevel == GetAccessLevels()[a])
            return a;
    }

    return 1;
}

function hasMenu()
{
    return self getVerification() > 1;
}

function SavePlayerVerification(player)
{
    if(player IsHost() || player isDeveloper() || player util::is_bot() || player getVerification() < 2)
        return self iPrintlnBold("^1ERROR: ^7Couldn't Save Players Verification");
    
    SetDvar("ApparitionV_" + player GetXUID(), player getVerification());
    self iPrintlnBold(CleanName(player getName()) + "'s Status Has Been ^2Saved");
}

function GetAccessLevels()
{
    return Array("Bot", "None", "Verified", "VIP", "Admin", "Co-Host", "Host", "Developer");
}

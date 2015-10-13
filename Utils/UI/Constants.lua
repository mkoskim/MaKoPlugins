-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Built-in bitmaps
-- ----------------------------------------------------------------------------

Icons = {
    SadPanda = 0x410F24E3,          -- 32x32

    Close = {                       -- 16x16
        Blue = {
            Disabled = nil,
            NoFocus  = 0x41000196,
            Focus    = 0x41000198,
            Pressed  = 0x41000197
        },
        Red = {
            Disabled = nil,
            NoFocus  = 0x41005F41,
            Focus    = 0x41005F50,
            Pressed  = 0x41005F49
        },
    },

    Arrow = {                       -- 25x25
        Right = {
            Disabled = 0x41000273,
            NoFocus  = 0x41000272,
            Focus    = 0x41000275,
            Pressed  = 0x41000274
        },
        Left = {
            Disabled = 0x41000277,
            NoFocus  = 0x41000276,
            Focus    = 0x41000279,
            Pressed  = 0x41000278
        },
    },

    CheckBox = {                    -- 16x16
        Unchecked = 0x410001A4,
        Checked   = 0x410001A3
    },

    -- Remove as in keymap options
    Remove = {                      -- 16x16
        Disabled = 0x410001C6,
        NoFocus  = 0x410001C5,
        Focus    = 0x410001C5,      -- same image
        Pressed  = 0x410001C4
    },

    Collapse = 0x41007E26,          -- 16x16
    Expand = 0x41007E27,            -- 16x16

    -- ------------------------------------------------------------------------
    -- Resize icon in chat window corner
    Resize = 0x4100013D,            -- 16x16

    -- ------------------------------------------------------------------------

    HeaderBackground = {            -- 9x16
        Blue = 0x411105A6,
        Red  = 0x41110DB5
    },

    Background = {
        Item = {                    -- 32x32
            Grey   = 0x41000001,
            Green  = 0x41000002,
            Purple = 0x41000003,
            Teal   = 0x41000004,
            Gold   = 0x41000005,
            Bronze = 0x41000E44,    -- e.g. food
            0x41001430,             -- Sort of sparkling teal
            0x410030C4,             -- Darker purple..
            0x410030E2,             -- Brownish...
            0x4101DBB0,             -- PvP green
            --- And more, and more...
        },
        Quickslot = 0x41007F4A,     -- empty quickslot
    },

    -- Animated borders...
    Animated = {
        YellowDashBorder = {        -- 32x32
            0x41007F09,
            0x41007F0A,
            0x41007F0B,
            0x41007F0C,
            0x41007F0D,
            -- 0x41020101,          -- Some extras...?
            -- 0x41020102,
            -- 0x41020103,
        },
        WhiteDashBorder = {         -- 32x32
            0x41007F0E,
            0x41007F0F,
            0x41007F10,
            0x41007F11,
            0x41007F12,
            0x41007F13,
            0x41007F14,
            0x41007F15,
        }
    },

    -- ------------------------------------------------------------------------

    ToolBar = {                     -- 25x25
        Help = {
            NoFocus = 0x41101830,
            Focus   = 0x4110182F,
            Pressed = 0x41101831,
        },
        Options = {
            NoFocus = 0x41101833,
            Focus   = 0x41101832,
            Pressed = 0x41101834,
        },
    },

    -- ------------------------------------------------------------------------

    Cursor = {
        Resize = 0x41007E20,        -- 32x32
    },

    -- ------------------------------------------------------------------------

    Voice = {                       -- 20x20
        Disabled = 0x410202F4,
    },

    ChatBubble =                    -- 16x16
    {
        Disabled = nil,
        NoFocus  = 0x41007E1E,
        Focus    = 0x41007E1F,
        Pressed  = 0x41007E1D,
    },

    --[[
    CoolDown = {                    -- 32x32
        Begin = 0x41007E35,
        End   = 0x41007E70,
    },
    ]]--

    -- LockOpen   = 0x410001CF,        -- 20x20
    -- LockClosed = 0x410001D0,        -- 20x20
    -- ]]--

    -- ------------------------------------------------------------------------
    -- Icons in LI name editing
    -- ------------------------------------------------------------------------

    Edit = {                        -- 16 × 16
        Start = {
            Disabled = 0x411646FE,
            NoFocus  = 0x411646FF,
            Focus    = 0x411646F9,
            Pressed  = 0x41164702
        },
        Accept = {
            Disabled = 0x411646F8,
            NoFocus  = 0x411646FB,
            Focus    = 0x411646FC,
            Pressed  = 0x411646FD
        },
        Cancel = {
            Disabled = 0x41164700,
            NoFocus  = 0x411646FA,
            Focus    = 0x41164701,
            Pressed  = 0x41164703
        }
    },

    -- ------------------------------------------------------------------------
    -- Lock control icons in bags
    -- ------------------------------------------------------------------------

    Lock = {                        -- 16x16
        Open = {
            Disabled = 0x411523BA,
            NoFocus  = 0x411523A9,
            Focus    = 0x411523A9,
            Pressed  = 0x411523A5
        },
        Closed = {
            Disabled = 0x411523BA,
            NoFocus  = 0x411523A7,
            Focus    = 0x411523A8,
            Pressed  = nil, -- 0x411523A5,
        }
    },

    -- ------------------------------------------------------------------------
    -- Equipment slot background images
    -- ------------------------------------------------------------------------

    EquipmentSlot = {                                   -- 44x44
        [Turbine.Gameplay.Equipment.Undefined]          = nil,
        [Turbine.Gameplay.Equipment.Head]               = 0x41007EED,
        [Turbine.Gameplay.Equipment.Chest]              = 0x41007EF0,
        [Turbine.Gameplay.Equipment.Legs]               = 0x41007EF1,
        [Turbine.Gameplay.Equipment.Gloves]             = 0x41007EF2,
        [Turbine.Gameplay.Equipment.Boots]              = 0x41007EF5,
        [Turbine.Gameplay.Equipment.Shoulder]           = 0x41007EEE,
        [Turbine.Gameplay.Equipment.Back]               = 0x41007EE9,
        [Turbine.Gameplay.Equipment.Bracelet1]          = 0x41007EF8,
        [Turbine.Gameplay.Equipment.Bracelet2]          = 0x41007EF9,
        [Turbine.Gameplay.Equipment.Necklace]           = 0x41007EEF,
        [Turbine.Gameplay.Equipment.Ring1]              = 0x41007EF3,
        [Turbine.Gameplay.Equipment.Ring2]              = 0x41007EF4,
        [Turbine.Gameplay.Equipment.Earring1]           = 0x41007EF6,
        [Turbine.Gameplay.Equipment.Earring2]           = 0x41007EF7,
        [Turbine.Gameplay.Equipment.Pocket]             = 0x41007EFA,
        [Turbine.Gameplay.Equipment.PrimaryWeapon]      = 0x41007EEA,
        [Turbine.Gameplay.Equipment.SecondaryWeapon]    = 0x41007EEB,
        [Turbine.Gameplay.Equipment.RangedWeapon]       = 0x41007EEC,
        [Turbine.Gameplay.Equipment.CraftTool]          = 0x41007EFB,
        [Turbine.Gameplay.Equipment.Class]              = 0x410E8680,
    },

    -- ------------------------------------------------------------------------
    -- Class icons
    -- ------------------------------------------------------------------------

    Class = {
        i50x50 = {
            [Turbine.Gameplay.Class.Burglar]    = 0x410000E4,
            [Turbine.Gameplay.Class.Captain]    = 0x410000E5,
            [Turbine.Gameplay.Class.Champion]   = 0x410000E6,
            [Turbine.Gameplay.Class.Guardian]   = 0x410000E7,
            [Turbine.Gameplay.Class.Hunter]     = 0x410000E8,
            [Turbine.Gameplay.Class.LoreMaster] = 0x410000E9,
            [Turbine.Gameplay.Class.Minstrel]   = 0x410000EA,
            
            [Turbine.Gameplay.Class.Reaver]     = 0x41007DC9,
            [Turbine.Gameplay.Class.Weaver]     = 0x41007DCA,
            [Turbine.Gameplay.Class.BlackArrow] = 0x41007DCB,
            [Turbine.Gameplay.Class.WarLeader]  = 0x41007DCC,
            [Turbine.Gameplay.Class.Stalker]    = 0x41007DCD,
            
            [Turbine.Gameplay.Class.Chicken]    = 0x41091DEF,
            [Turbine.Gameplay.Class.Troll]      = 0x41091DF0,
            [Turbine.Gameplay.Class.Ranger]     = 0x41091DF1,

            [Turbine.Gameplay.Class.Defiler]    = 0x410E6BF6,
        },
        -- 48x48 is found, but spread over the ID space
        i32x32 = {
            [Turbine.Gameplay.Class.Warden]     = 0x41108673,
            [Turbine.Gameplay.Class.Burglar]    = 0x41108674,
            [Turbine.Gameplay.Class.Captain]    = 0x41108675,
            [Turbine.Gameplay.Class.Champion]   = 0x41108676,
            [Turbine.Gameplay.Class.Guardian]   = 0x41108677,
            [Turbine.Gameplay.Class.Hunter]     = 0x41108678,
            [Turbine.Gameplay.Class.LoreMaster] = 0x41108679,
            [Turbine.Gameplay.Class.Minstrel]   = 0x4110867A,
            [Turbine.Gameplay.Class.RuneKeeper] = 0x4110867B,
        },
        i25x25 = {
            [Turbine.Gameplay.Class.Minstrel]   = 0x41007DD6,
            [Turbine.Gameplay.Class.Captain]    = 0x41007DD7,
            [Turbine.Gameplay.Class.Guardian]   = 0x41007DD8,
            [Turbine.Gameplay.Class.LoreMaster] = 0x41007DD9,
            [Turbine.Gameplay.Class.Hunter]     = 0x41007DDA,
            [Turbine.Gameplay.Class.Burglar]    = 0x41007DDB,
            [Turbine.Gameplay.Class.Champion]   = 0x41007DDC,

            [Turbine.Gameplay.Class.Reaver]     = 0x41007DDD,
            [Turbine.Gameplay.Class.WarLeader]  = 0x41007DDE,
            [Turbine.Gameplay.Class.BlackArrow] = 0x41007DDF,
            [Turbine.Gameplay.Class.Weaver]     = 0x41007DE0,
            [Turbine.Gameplay.Class.Stalker]    = 0x41007DE1,
            
            [Turbine.Gameplay.Class.Chicken]    = 0x41091DDE,
            [Turbine.Gameplay.Class.Troll]      = 0x41091DDF,
            [Turbine.Gameplay.Class.Ranger]     = 0x41091DE0,

            [Turbine.Gameplay.Class.Defiler]    = 0x410E6BF5,
        },
        i20x20 = {
            [Turbine.Gameplay.Class.Minstrel]   = 0x41007DE6,
            [Turbine.Gameplay.Class.Captain]    = 0x41007DE7,
            [Turbine.Gameplay.Class.Guardian]   = 0x41007DE8,
            [Turbine.Gameplay.Class.LoreMaster] = 0x41007DE9,
            [Turbine.Gameplay.Class.Hunter]     = 0x41007DEA,
            [Turbine.Gameplay.Class.Burglar]    = 0x41007DEB,
            [Turbine.Gameplay.Class.Champion]   = 0x41007DEC,

            [Turbine.Gameplay.Class.Reaver]     = 0x41007DED,
            [Turbine.Gameplay.Class.Weaver]     = 0x41007DEE,
            [Turbine.Gameplay.Class.BlackArrow] = 0x41007DEF,
            [Turbine.Gameplay.Class.WarLeader]  = 0x41007DF0,
            [Turbine.Gameplay.Class.Stalker]    = 0x41007DF1,

            [Turbine.Gameplay.Class.Chicken]    = 0x41091DE1,
            [Turbine.Gameplay.Class.Troll]      = 0x41091DE2,
            [Turbine.Gameplay.Class.Ranger]     = 0x41091DE3,

            [Turbine.Gameplay.Class.Defiler]    = 0x410E6BF4,
        },
    },
}

-- ----------------------------------------------------------------------------
-- Colors
-- ----------------------------------------------------------------------------

bgColor = Turbine.UI.Color( 0, 0, 0);
focusColor = Turbine.UI.Color(1, 0.15, 0.15, 0.15);

frameColor = Turbine.UI.Color(0.8,0.8,0.8)

-- ----------------------------------------------------------------------------
-- Keyboard actions
-- ----------------------------------------------------------------------------

Actions = {
    ESC = Turbine.UI.Lotro.Action.Escape,
    HUDToggle = 268435635,
    HUDReposition = 268435579,
}


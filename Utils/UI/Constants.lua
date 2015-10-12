-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Built-in bitmaps
-- ----------------------------------------------------------------------------

Icons = {
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
        }
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
        }
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

    HeaderBackground = {            -- 9x16
        Blue = 0x411105A6,
        Red  = 0x41110DB5
    },

    Voice = {                       -- 20x20
        Disabled = 0x410202F4,
    },

    ChatBubble =                    -- 16x16
    {
        Disabled = nil,
        NoFocus  = 0x41007E1D,
        Focus    = 0x41007E1F,
        Pressed  = nil, --0x41007E1E,
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
    -- Locking control icons in bags
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


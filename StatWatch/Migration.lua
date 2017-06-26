-- ****************************************************************************
-- ****************************************************************************
--
-- Migrating old settings version to newest one.
--
-- ****************************************************************************
-- ****************************************************************************

function Migrate(Settings, DefaultSettings)
    if Settings == nil then
        Settings = DefaultSettings
    end

    if Settings["SettingsVersion"] == nil then
        Settings = {
            ExpandedGroups = Settings.ExpandedGroups,
            ShowPercentages = Settings.ShowPercentages,

            BrowseWindow = {
                Left    = Settings.WindowPosition.Left,
                Top     = Settings.WindowPosition.Top,
                Width   = Settings.WindowPosition.Width,
                Height  = Settings.WindowPosition.Height,
                Visible = Settings.WindowVisible,
            },
            ShareWindow = DefaultSettings.ShareWindow,
            SettingsVersion = 1,
        }
    end

    if Settings["SettingsVersion"] == 1 then
        Settings.BrowseWindow.Toggle = DefaultSettings.BrowseWindow.Toggle
        Settings.ShareWindow.Toggle = DefaultSettings.ShareWindow.Toggle
        Settings.SettingsVersion = 2
    end

    if Settings["SettingsVersion"] == 2 then
        Settings.Modifiers = DefaultSettings.Modifiers
        Settings.SettingsVersion = 3
    end

    if Settings["SettingsVersion"] == 3 then
        Settings.References = DefaultSettings.References
        Settings.SettingsVersion = 4
    end

    return Settings
end



--[[
- Import libraries, other files.
- Create custom context menu library.

DToX, 2015
Licensed under the same terms as Lua itself.
--]]





-- *****************
-- * Documentation *
-- *****************
--[[
===== Quick start
- To create menu object use Turbine.UI.ContextMenu2().
Example:
   local menu = Turbine.UI.ContextMenu2();

- To create menu item object use Turbine.UI.MenuItem2().
Example:
   local item = Turbine.UI.MenuItem2( "Menu item" );
   Or
   local item = Turbine.UI.MenuItem2( "Menu item", false, true ); -- Disabled, Checked

- Other functions are the same.
Example:
   local menuItems = menu:GetItems();
   menuItems:Add( item );


===== Additional features
- To change font use menu's function: SetFont( <name> ).
Example:
   local menu = Turbine.UI.ContextMenu2();
   menu:SetFont( "Verdana16" );

- To access menu item's objects you can use fields Icon, Label and Arrow.
Example:
   local item = Turbine.UI.MenuItem2( "Menu item" );
   local label = item.Label;

- If you want to scale custom image with item's height, you can set field ScaleImage.
Example:
   local icon = item.Icon;
   icon:SetBackground( 0x410001D1 );
   icon.ScaleImage = true;


===== Behaviour
=== Differences
- If item is disabled and has submenu, it won't open.
   Default menu: open submenu.

- Shows empty submenu (without items).
   Default menu: hide empty submenu.

- Submenus show all disabled items.
   Default menu: disabled items in submenus are not displayed.
      Bug?

- MenuItemList:Add function doesn't add same item twice.
   Default menu: adds same items.

Example:
   local menu = Turbine.UI.ContextMenu();
   local menuItems = menu:GetItems();
   local item = Turbine.UI.MenuItem( "Menu item" );
   menuItems:Add( item );
   menuItems:Add( item ); -- Menu contains two same items

   local menu2 = Turbine.UI.ContextMenu2();
   local menuItems2 = menu2:GetItems();
   local item = Turbine.UI.MenuItem2( "Menu item" );
   menuItems2:Add( item );
   menuItems2:Add( item ); -- Menu contains one item
   local item = Turbine.UI.MenuItem2( "Menu item" );
   menuItems2:Add( item ); -- Menu contains two item


=== Keep menu open
To keep menu open, when user clicks on item, use "KeepOpen" field of the item object.
Example:
1)
   local item = Turbine.UI.MenuItem2( "Menu item" );
   item.KeepOpen = true;

2)
   function item:Click()
      self.KeepOpen = true;
      ...
   end

--]]





-- import "Turbine";
-- import "Turbine.UI";
import "Turbine.UI.Lotro";



-- From text library. Calculates text's size
-- DToX, 2014
local Text = {};
Text.Step = {
   Height = 1;
   Width = 1;
   Maximum = 5000;
};

-- Calculates width or height of the text
local function getSideSize( objScroll, sideName )
   local i = 0;
   local sideSize;
   local stepSizeH = Text.Step.Height;
   local stepSizeW = Text.Step.Width;
   local maxSteps = Text.Step.Maximum;

   while ( objScroll:IsVisible() ) do
      i = i + 1;
      if ( sideName == "H" ) then
         sideSize = stepSizeH * i;
         Text.Label:SetHeight( sideSize );
      elseif ( sideName == "W" ) then
         sideSize = stepSizeW * i;
         Text.Label:SetWidth( sideSize );
      end

      -- Just in case. To prevent infinite loop
      i = i + 1;
      if ( i > maxSteps ) then
         Turbine.Shell.WriteLine( ">> Error. Text.getSideSize (" .. sideName .. "): " .. i .. " steps, possible infinite loop." );
         return nil;
      end
   end

   return sideSize;
end

-- Resets and sets text's values, calculates and returns text's width and height
--[[ Examples:
Calculate width (limit to 1 symbol on the line) and height, return size
   local W, H = Text:getSize( "1234", Turbine.UI.Lotro.Font.Verdana14 );

Limit width to 50, calculate height, return size
   local W, H = Text:getSize( "1234", Turbine.UI.Lotro.Font.Verdana14, 50 );

All text on single line, calculate width and height, return size
!! Doesn't support \n. 
   local W, H = Text:getSize( "1234", Turbine.UI.Lotro.Font.Verdana14, "Single" );
--]]
Text.getSize = function( self, text, font, widthOrSingleLine )
   local label = Turbine.UI.Label();
   self.Label = label;

   -- Scroll. For measuring text's height
   local vScroll = Turbine.UI.Lotro.ScrollBar();
   vScroll:SetParent( label );
   label:SetVerticalScrollBar( vScroll );

   -- Scroll. For measuring text's width
   local hScroll = Turbine.UI.Lotro.ScrollBar();
   hScroll:SetParent( label );
   label:SetHorizontalScrollBar( hScroll );

   local W;
   local H;

   local bWidth = false;
   if ( type( widthOrSingleLine ) == "number" ) then
      bWidth = true;
      W = widthOrSingleLine;
   end

   self.Label:SetSize( 0, 0 );
   if ( bWidth ) then
      self.Label:SetWidth( W );
   end

   self.Label:SetMultiline( true );
   if ( widthOrSingleLine and not bWidth ) then
      self.Label:SetMultiline( false );
   end

   self.Label:SetFont( font );
   self.Label:SetText( text );

   -- Calculate width
   function hScroll.VisibleChanged()
      if ( not bWidth ) then
         W = getSideSize( hScroll, "W" );
      end
   end
   hScroll.VisibleChanged();

   -- Calculate height
   function vScroll.VisibleChanged()
      H = getSideSize( vScroll, "H" );
   end
   vScroll.VisibleChanged();

   return W, H;
end





-- ***********************
-- * Custom context menu *
-- ***********************

-- Variables and constants
--
local colors = Turbine.UI.Color;
local fonts = Turbine.UI.Lotro.Font;
-- Contains all opened menus. For closing/opening
local openedMenus = {}; -- <Menu's level> = <Menu's object>

local fontName = "Verdana14";
local fontColor = "BurlyWood";
-- local fontDisabledColor = "DarkGray";
local fontDisabledColor = "LightGray";
local lineHeight = 16; -- Text's height. Same for all menus

local ITEM_OFFSET_V = 2;
local ITEM_OFFSET_H = 5;
local DEFAULT_IMAGE_SIZE = 16;
-- Images: 16*16
local IMAGE_CHECK = 0x41007F80; -- Disabled: 0x410F44A3
local IMAGE_ARROW = 0x41007F7F;





-- Closes all menus. With level closes only >= level menus
local function closeMenus( level )
   for i, menu in pairs( openedMenus ) do
      if ( not level ) then
         menu:Close();
      elseif ( level and i >= level ) then
         menu:Close();
      end
   end
end

-- Shows/Hides all menus
local function showMenus( bShow )
   for i, menu in pairs( openedMenus ) do
      menu:SetVisible( bShow );
   end
end

-- Updates menu's size and item's height
local function updateMenu( carrier, itemList )
   local gFont = fonts[fontName];
   local maxTextWidth = 0;
   local maxTextHeight = 0;
   local n = itemList:GetCount();

   -- Get max text's size
   for i = 1, n do
      local item = itemList:Get( i );

      local label = item.Label;
      local font = label:GetFont();
      local text = label:GetText();

      -- Update font
      if ( font ~= gFont ) then
         label:SetFont( gFont );
         label:SetText( text );
      end

      local textWidth, textHeight = Text:getSize( text, gFont, "Single" );

      if ( textWidth > maxTextWidth ) then
         maxTextWidth = textWidth;
      end
      if ( textHeight > maxTextHeight ) then
         maxTextHeight = textHeight;
      end
   end

   -- Update saved line's height
   if ( maxTextHeight > lineHeight ) then
      lineHeight = maxTextHeight;
   end

   -- Calculate new menu's size
   local bChanged = false;
   local carrierWidth, carrierHeight = carrier:GetSize();
   local newCarrierHeight = lineHeight * n + ITEM_OFFSET_V * ( n + 1 );
   local newCarrierWidth = maxTextWidth + lineHeight * 2 + ITEM_OFFSET_H * 4;

   -- Check menu's size
   if ( newCarrierWidth ~= carrierWidth ) then
      carrierWidth = newCarrierWidth;
      bChanged = true;
   end
   if ( newCarrierHeight ~= carrierHeight ) then
      carrierHeight = newCarrierHeight;
      bChanged = true;
   end

   -- Change menu's size
   if ( bChanged ) then
      carrier:SetSize( carrierWidth, carrierHeight );
   end

end

-- Sets size and positions of the list's items
local function updateMenuItemList( itemList, newWidth )
   local list = itemList;
   local width = newWidth;
   local height = lineHeight;
   local n = list:GetCount();

   for i = 1, n do
      local item = list:Get( i );
      local W, H = item:GetSize();
      local newItemHeight = lineHeight + ITEM_OFFSET_V * 2;

      -- If item's width and height didn't change, exit
      if ( W == width and H == newItemHeight ) then
         return;
      end

      local icon = item.Icon;
      local label = item.Label;
      local arrow = item.Arrow;
      local newTop = ( lineHeight + ITEM_OFFSET_V ) * ( i - 1);

      -- Calculate additional image's offset, because it doesn't want to scale -_-
      local imageOffsetH = ITEM_OFFSET_H;
      local imageOffsetV = ITEM_OFFSET_V;
      if ( height > DEFAULT_IMAGE_SIZE ) then
         local offset = ( height - DEFAULT_IMAGE_SIZE ) / 2;
         imageOffsetH = imageOffsetH + offset;
         imageOffsetV = imageOffsetV + offset;
      end

      -- Set item's size
      local labelWidth = width - ( height * 2 + ITEM_OFFSET_H * 4 );
      item:SetSize( width, newItemHeight );
      label:SetSize( labelWidth, height );

      if ( icon.ScaleImage ) then
         icon:SetSize( height, height );
      else
         icon:SetSize( DEFAULT_IMAGE_SIZE, DEFAULT_IMAGE_SIZE );
      end

      if ( arrow.ScaleImage ) then
         arrow:SetSize( height, height );
      else
         arrow:SetSize( DEFAULT_IMAGE_SIZE, DEFAULT_IMAGE_SIZE );
      end

      -- Set item's position
      item:SetTop( newTop );
      local X = height + ITEM_OFFSET_H * 2;
      label:SetPosition( X, ITEM_OFFSET_V );

      if ( icon.ScaleImage ) then
         icon:SetPosition( ITEM_OFFSET_H, ITEM_OFFSET_V );
      else
         icon:SetPosition( imageOffsetH, imageOffsetV );
      end

      if ( arrow.ScaleImage ) then
         local X = width - height - ITEM_OFFSET_H;
         arrow:SetPosition( X, ITEM_OFFSET_V );
      else
         local X = width - DEFAULT_IMAGE_SIZE - imageOffsetH;
         arrow:SetPosition( X, imageOffsetV );
      end

      -- Show arrow icon, if item contains submenu
      if ( item.Submenu ) then
         arrow:SetVisible( true );
      end

      -- For custom images
      icon:SetStretchMode( 2 );
      arrow:SetStretchMode( 2 );

   end

end

-- Returns menu to the visible part of the screen.
-- Submenus are shown to the right or to left relative to parent menu
local function checkMenuPosition( obj )
-- Move next line outside and uncomment lines for custom behaviour.
-- If submenu cannot be displayed on the right, it and its children will be displayed on the left
--[[ Visual. Custom
Left border |    Menu 1 -> 2 | Right border
              5 <- 4 <- 3
                 6 -> ...
--]]
--[[ Visual. Standard
Left border | Menu 1 -> 2 | Right border
                   3 -> 4
                   5 -> ...
--]]

   local rightToLeft = false;

   local level = obj.Level;
   local left, top = obj:GetPosition();
   local width, height = obj:GetSize();
   local screenWidth, screenHeight = Turbine.UI.Display:GetSize();

   -- Basic for all levels. Return to the screen
   if ( left < 0 ) then
      left = 0;
-- rightToLeft = false;
   end
   if ( top < 0 ) then
      top = 0;
   end

   if ( left + width >= screenWidth ) then
      left = screenWidth - width;
      rightToLeft = level;
-- elseif( level == rightToLeft ) then
-- rightToLeft = false;
   end
   if ( top + height >= screenHeight ) then
      top = screenHeight - height;
   end

   -- For submenus
   if ( level > 1 ) then
      local prevLevel = level - 1;
      local prevMenu = openedMenus[prevLevel];
      local prevleft, prevTop = prevMenu:GetPosition();

-- if ( rightToLeft and level >= rightToLeft ) then
      if ( rightToLeft ) then
         left = prevleft - width;
      end
   end

   obj:SetPosition( left, top );

end


-- Creates menu
local function newContextMenu()
   local carrier = Turbine.UI.Window();
   carrier:SetZOrder( 1 );
   carrier.Level = 1; -- For openedMenus

   local background = Turbine.UI.Lotro.TextBox();
   background:SetParent( carrier );

   local menuCarrier = Turbine.UI.Control();
   menuCarrier:SetParent( carrier );

   -- Resizes children
   function carrier.SizeChanged( self )
      local W, H = self:GetSize();
      background:SetSize( W, H );
      menuCarrier:SetSize( W, H );
   end

   -- For closing all menus. Part 1/2
   function carrier.FocusLost( self )
      local outside = true;
      local mouseX, mouseY = Turbine.UI.Display:GetMousePosition();

      for i, menu in pairs( openedMenus ) do
         local X, Y = menu:PointToClient( mouseX, mouseY );
         local W, H = menu:GetSize();
         if ( X >= 0 and Y >= 0 and X <= W and Y <= H ) then
            outside = false;
            return;
         end
      end

      if ( outside ) then
         closeMenus();
      end

   end

   -- Changes font
   function carrier.SetFont( self, name )
      fontName = name;
   end

   -- Standard. Gets the menu items collection. Returns MenuItemList
   function carrier.GetItems( self )
      local itemList = menuCarrier:GetControls();
      local orgAddItem = itemList.Add;

      function itemList.Add( self, item )
         orgAddItem( self, item );

         item.Level = carrier.Level; -- For openedMenus
      end

      return itemList;
   end

   -- Standard. Displays the menu
   function carrier.ShowMenu( self, X, Y, showAt )
      -- Update menu's size
      local itemList = menuCarrier:GetControls();
      updateMenu( self, itemList );

      -- Update item's size and position
      local carrierWidth = carrier:GetWidth();
      updateMenuItemList( itemList, carrierWidth );

      -- Set position
      if ( showAt ) then
         self:SetPosition( X, Y );
      else
         local mouseX, mouseY = Turbine.UI.Display:GetMousePosition();
         self:SetPosition( mouseX, mouseY );
      end

      checkMenuPosition( self );
      self:SetVisible( true );

      -- For closing all menus
      self:Activate();
      self:Focus();

      -- Add to the opened menus list
      local level = self.Level;
      openedMenus[level] = self;
   end

   -- Standard. Displays the menu at coordinates (X, Y)
   function carrier.ShowMenuAt( self, X, Y )
      self:ShowMenu( X, Y, "At" );
   end

   -- Standard. Closes the menu if it is displayed
   function carrier.Close( self )
      self:SetVisible( false );

      -- Remove from the opened menus list
      local level = self.Level;
      openedMenus[level] = nil;
   end


   return carrier;
end

-- Creates check/arrow icon's object
local function newMenuItemImage( image, parent )
   local img = Turbine.UI.Control();
   img:SetParent( parent );
   img:SetBackColor( colors.Black );
   img:SetBackground( image );
   img:SetBlendMode( 4 );
   img:SetVisible( false );
   img:SetMouseVisible( false );
   return img;
end

-- Custom. Creates menu item
local function newMenuItem( text, enabled, checked )
   local carrier = Turbine.UI.Control();

   -- Check icon. Or custom...
   local icon = newMenuItemImage( IMAGE_CHECK, carrier )

   -- Text
   local label = Turbine.UI.Label();
   label:SetParent( carrier );
   label:SetMultiline( false );
   label:SetFont( fonts[fontName] );
   label:SetForeColor( colors[fontColor] );
   label:SetFontStyle( Turbine.UI.FontStyle.Outline );
   label:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
   label:SetMouseVisible( false );

   -- Arrow icon to show submenu
   local arrow = newMenuItemImage( IMAGE_ARROW, carrier )


   carrier.Submenu = nil;
   carrier.Checked = nil;
   carrier.Enabled = nil;
   carrier.Icon = icon;
   carrier.Label = label;
   carrier.Arrow = arrow;

   -- Standard. Highlight item
   function carrier.MouseEnter( self )
      -- Highlighting
      self.Label:SetOutlineColor( colors.DarkOrange );

      -- Close opened submenus (level + 1 and higher)
      local level = self.Level + 1;
      local menu = openedMenus[level];
      local submenu = self.Submenu;
      if ( menu and menu ~= submenu ) then
         closeMenus( level );
      end

      -- Show submenu
      if ( submenu ) then
         -- Don't re-open current submenu
         if ( submenu == menu ) then
            submenu:SetVisible( true ); -- If it was hidden by click
            return;
         end

         -- Calculate position and show menu
         local screenX, screenY = self:PointToScreen( 0, 0 );
         local itemWidth, itemHeight = self:GetSize();
         local X = screenX + itemWidth;
         local Y = screenY + ITEM_OFFSET_V;
         submenu:ShowMenuAt( X, Y );

         openedMenus[level] = submenu;
      end

   end

   -- Standard. Remove highlighting
   function carrier.MouseLeave( self )
      self.Label:SetOutlineColor( colors.Black );
   end

   -- Standard. Event fired when a user clicks on the menu item.
   function carrier.MouseClick( self )
      -- Execute user specified event
      if ( self.Click ) then
         self:Click();
      end

      -- Show/Hide submenu
      local submenu = self.Submenu;
      local keepOpen = self.KeepOpen;
      if ( submenu ) then
         local level = self.Level + 1;
         local visible = submenu:IsVisible();
         if ( visible ) then
            if ( not keepOpen ) then
               closeMenus( level );
            end
         else
            openedMenus[level] = submenu;
            submenu:SetVisible( true );
         end
      else -- No submenu
         -- Close all menus
         if ( not keepOpen ) then
            closeMenus();
         end
      end

   end

   -- Standard. Sets a flag indicating if the menu item is enabled.
   function carrier.SetEnabled( self, value )
      if ( value or value == nil ) then
         self.Enabled = true;
         self:SetMouseVisible( true );
         self.Icon:SetBackColorBlendMode( 8 );
         self.Arrow:SetBackColorBlendMode( 8 );
         self.Label:SetForeColor( colors[fontColor] );
      else
         self.Enabled = false;
         self:SetMouseVisible( false );
         self.Icon:SetBackColorBlendMode( 6 );
         self.Arrow:SetBackColorBlendMode( 6 );
         self.Label:SetForeColor( colors[fontDisabledColor] );
      end
   end

   -- Standard. Gets a flag indicating if the menu item is enabled.
   function carrier.IsEnabled( self )
      return self.Enabled;
   end

   -- Standard. Sets a flag indicating if the menu item is checked.
   function carrier.SetChecked( self, value )
      if ( value ) then
         self.Icon:SetVisible( true );
         self.Checked = true;
      else
         self.Icon:SetVisible( false );
         self.Checked = false;
      end
   end

   -- Standard. Gets a flag indicating if the menu item is checked.
   function carrier.IsChecked( self )
      return self.Checked;
   end

   -- Standard. Sets the text of the menu item.
   function carrier.SetText( self, value )
      self.Label:SetText( value );
   end

   -- Standard. Gets the text of the menu item.
   function carrier.GetText( self )
      return self.Label:GetText();
   end

   -- Standard. Creates submenu
-- !! Shows even empty submenu
   function carrier.GetItems( self )
      if ( not self.Submenu ) then
         self.Submenu = newContextMenu();

         local level = self.Level + 1;
         self.Submenu.Level = level;
      end

      local menuItems = self.Submenu:GetItems();
      return menuItems;
   end

   carrier:SetText( text );
   carrier:SetEnabled( enabled );
   carrier:SetChecked( checked );

   return carrier;
end


-- For closing all menus. Part 2/2
window_ContextMenu = Turbine.UI.Window();
window_ContextMenu:SetWantsKeyEvents( true );
function window_ContextMenu:KeyDown()
   closeMenus();
end





-- Attach
Turbine.UI.ContextMenu2 = newContextMenu;
Turbine.UI.MenuItem2 = newMenuItem;

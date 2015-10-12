-- ****************************************************************************
-- ****************************************************************************
--
-- DesktopButton is draggable 'freefloating' button on game window, mainly
-- for showing / hiding plugin main window. Modified from MathWold's
-- ToggleView control (RTPlugin).
--
-- ****************************************************************************
-- ****************************************************************************

DesktopButton = class(Window.Undecorated)

function DesktopButton:Constructor( text )
    Window.Undecorated.Constructor(self)

    self:SetSize(32, 32)
    self:SetBackColor(Turbine.UI.Color.Black)

    self.button = TextButton()
    self.button:SetParent(self)
    self.button:SetText(text)

    self.button:SetPosition(1, 1)
    self.button:SetSize(30, 30)

    -- ------------------------------------------------------------------------
	-- Dragging
    -- ------------------------------------------------------------------------

	self.isdragging = false;
	self.winHasMoved = false;

	self.button.MouseDown = function(sender, args)
		TextButton.MouseDown(sender, args)
		if args.Button == Turbine.UI.MouseButton.Left then
		    startX = args.X;
		    startY = args.Y;
		    self.isdragging = true;
	        self.winHasMoved = false;
		end
	end

    self.button.MouseLeave = function(sender, args)
        if not self.isdragging then TextButton.MouseLeave(sender, args) end
    end

    self.button.MouseEnter = function(sender, args)
        if not self.isdragging then TextButton.MouseEnter(sender, args) end
    end

	self.button.MouseUp = function(sender, args)
		TextButton.MouseUp(sender, args)
		if ( self.isdragging ) then
			self:SetLeft(self:GetLeft() + (args.X - startX));
			self:SetTop(self:GetTop() + (args.Y - startY));

			self.isdragging = false;
			if self:GetLeft() < 0 then
				self:SetLeft(0);
			elseif self:GetLeft() + self:GetWidth() > Turbine.UI.Display:GetWidth() then
				self:SetLeft(Turbine.UI.Display:GetWidth()-self:GetWidth());
			end
			if self:GetTop() < 0 then
				self:SetTop(0);
			elseif self:GetTop() + self:GetHeight() > Turbine.UI.Display:GetHeight() then
				self:SetTop(Turbine.UI.Display:GetHeight()-self:GetHeight());
			end
			-- self.winHasMoved = false;
		end
	end

	self.button.MouseMove = function(sender, args)
		if self.isdragging then
			self:SetLeft(self:GetLeft() + (args.X - startX));
			self:SetTop(self:GetTop() + (args.Y - startY));
			self.winHasMoved = true;
		end
	end
end

-- ----------------------------------------------------------------------------

function DesktopButton:Serialize()
    return {
        Left = self:GetLeft(),
        Top = self:GetTop(),
        Visible = self._visible,
    }
end

function DesktopButton:Deserialize(settings)
    self:SetPosition(settings.Left, settings.Top)
    self:SetVisible(settings.Visible)
end

-- ----------------------------------------------------------------------------

ToggleWindowButton = class(DesktopButton)

function ToggleWindowButton:Constructor(text, window)
    DesktopButton.Constructor(self, text)

    self.window = window

    self.button.MouseClick = function(sender, args)
        if not self.winHasMoved then
            self.window:SetVisible(not self.window:IsVisible())
        end
    end
end


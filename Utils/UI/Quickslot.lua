-- ****************************************************************************
-- ****************************************************************************
--
-- Attempt to make quickslot with working Drag'n'Drop... Quickslot is a
-- component that holds Shortcut object.
--
-- ****************************************************************************
-- ****************************************************************************

Quickslot = class(Turbine.UI.Lotro.Quickslot)

-- ----------------------------------------------------------------------------
-- Quickslot hidden below a control (modified from AliasButton implemented
-- in RTPlugin by MathWold)
-- ----------------------------------------------------------------------------

SkinnedQuickslot = class(Frame)

function SkinnedQuickslot:Constructor()
	Frame.Constructor( self );

    self.shortcut = nil

	self.qs = Quickslot();
	self.qs:SetParent( self );
	self.qs:SetPosition(1, 1);

	self.qs:SetAllowDrop(false);
	self.qs.DragDrop=function() self:SetShortcut(self.shortcut); end

	self.qs.Skin = Turbine.UI.Button();
	self.qs.Skin:SetParent( self );
	self.qs.Skin:SetPosition(1, 1);
	self.qs.Skin:SetZOrder(self.qs:GetZOrder()+1);
	self.qs.Skin:SetMouseVisible(false);
	self.qs.Skin:SetBlendMode(Turbine.UI.BlendMode.Overlay);

	self.qs.Skin:SetBackColor(Turbine.UI.Color(1,0.1,0.1,0.1));

	self.qs.MouseEnter=function()
    	self.qs.Skin:SetBackColor(Turbine.UI.Color(1,0.3,0.3,0.3));
	end
	self.qs.MouseLeave=function()
		self.qs.Skin:SetBackColor(Turbine.UI.Color(1,0.1,0.1,0.1));
	end
	self.qs.MouseDown=function()
		self.qs.Skin:SetBackColor(Turbine.UI.Color(1,0.5,0.5,0.5));
	end
	self.qs.MouseUp=function()
		self.qs.Skin:SetBackColor(Turbine.UI.Color(1,0.3,0.3,0.3));
	end
    
    self:SetShortcut(nil)
end

function SkinnedQuickslot:SetSize(w, h)
	Frame.SetSize(self, w, h)
	self.qs:SetSize(w - 2, h - 2);
	self.qs.Skin:SetSize(w - 2, h - 2);
end

function SkinnedQuickslot:SetShortcut( shortcut )
    self.qs:SetShortcut(shortcut)
   	self.qs.Skin:SetForeColor(
   	    shortcut and Turbine.UI.Color(1, 1, 1) or
   	    Turbine.UI.Color(0.5, 0.5, 0.5)
   	);
    self.shortcut = shortcut
end

function SkinnedQuickslot:SetText( text )
	self.qs.Skin:SetText( text )
end


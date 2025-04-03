---@diagnostic disable: undefined-global

--- a button, click to OnClick, double click to change text
ButtonLabelEdit = Control:Inherit{
  classname = "editlabel",
  defaultWidth = 70,
  defaultHeight = 30,
  width=70,height=30,
  OnEdited={},
  padding={0,0,0,0}
}


local this = ButtonLabelEdit
local inherited = this.inherited

function ButtonLabelEdit:New(obj)
	obj = inherited.New(self,obj)
  obj.child_label=Button:New{
    parent=obj,
    caption=obj.text,
    x=1,y=1,right=1,bottom=1,
    OnClick={
      function (a,...)
        inherited.MouseClick(obj,...)
      end
    },
    OnDblClick={
      function ()
        Spring.Echo("DEBUG: EditLabel.child_label.OnClick")
        obj:IntoEditBox()
      end
    },
    tooltip=obj.tooltip,
  }
  obj.child_editbox=EditBox:New{
    parent=obj,
    text=obj.text,
    x=1,y=1,right=32,bottom=1,
    valign="top",
  }
  obj.child_save_button=Button:New{
    parent=obj,
    noFont=true,
    width=30,right=1,bottom=1,y=1,
    OnClick={
      function ()
        obj:IntoLabel()
      end
    }
  }
  Image:New{
    parent=obj.child_save_button,
    x=0,y=0,right=0,bottom=0,
    padding={1,1,1,1},
    file = 'LuaUI/Images/dynamic_comm_menu/tick.png',
  }
  obj:HideChild(obj.child_editbox)
  obj:HideChild(obj.child_save_button)
  obj.state_label=true
	return obj
end

function ButtonLabelEdit:IntoLabel()
  if not self.state_label then
    self.text=self.child_editbox:GetText()
    self:CallListeners(self.OnEdited, self.text)
    self:HideChild(self.child_editbox)
    self:HideChild(self.child_save_button)
    self:ShowChild(self.child_label)
    self.state_label=true
  end
  self.child_label:SetCaption(self.text)
end

function ButtonLabelEdit:IntoEditBox()
  if self.state_label then
    self:HideChild(self.child_label)
    self:ShowChild(self.child_editbox)
    self:ShowChild(self.child_save_button)
    self.state_label=false
  end
  self.child_editbox:SetText(self.text)
end

function ButtonLabelEdit:GetText()
  return self.text
end

function ButtonLabelEdit:SetText(text)
  self.text=text
  if self.state_label then
    self.child_label:SetCaption(self.text)
  else
    self.child_editbox:SetText(self.text)
  end
end

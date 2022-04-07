-- Device Controller is a little more advanced than other types. 
-- It can create child devices, so it can be used for handling multiple physical devices.
-- E.g. when connecting to a hub, some cloud service or just when you want to represent a single physical device as multiple endpoints.
-- 
-- Basic knowledge of object-oriented programming (oop) is required. 
-- Learn more about oop: https://en.wikipedia.org/wiki/Object-oriented_programming 
-- Learn more about managing child devices: https://manuals.fibaro.com/home-center-3-quick-apps/

function QuickApp:onInit()
    self:debug("QuickApp:onInit")

    -- Setup classes for child devices.
    -- Here you can assign how child instances will be created.
    -- If type is not defined, QuickAppChild will be used.
    self:initChildDevices({
        ["com.fibaro.energyMeter"] = Energy,
    })

    -- Print all child devices.
    self:debug("Child devices:")
    for id,device in pairs(self.childDevices) do
        self:debug("[", id, "]", device.name, ", type of: ", device.type)
    end
end

function QuickApp:createButtonClicked(event)
    self:createChild()
end

-- Sample method to create a new child. It can be used in a button. 
function QuickApp:createChild()
    local child = self:createChildDevice({
        name = "Energy",
        type = "com.fibaro.energyMeter",
        rateType = "production"
    }, Energy)

    self:trace("Child device created: ", child.id)
end

class 'Energy' (QuickAppChild)

function Energy:__init(device)
    QuickAppChild.__init(self, device)

    self:debug("Energy init")
    self:updateProperty("rateType", "production")
    self:updateProperty("value", 3)
end

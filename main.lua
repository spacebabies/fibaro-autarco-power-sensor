function fibaro.installFibaroExtra()local a="fibaroExtra"if fibaro.FIBARO_EXTRA then return end;local b="https://raw.githubusercontent.com/jangabrielsson/TQAE/main/lib/"..a..".lua"net.HTTPClient():request(b,{options={method='GET',checkCertificate=false,timeout=20000},success=function(c)if c.status==200 then local d={isMain=false,type='lua',isOpen=false,name=a,content=c.data}fibaro.debug(__TAG,"Installing ",a)local e,c=api.post("/quickApp/"..plugin.mainDeviceId.."/files",d)if c~=200 then fibaro.error(__TAG,"Installing ",a," - ",c)end else fibaro.error(__TAG,"Error ",c.status," fetching ",b)end end,error=function(c)fibaro.error(__TAG,"Error ",c," fetching ",b)end})end

MyAutarcoDevices = {
  ["pv_now"] = 'CurrentPower'
}

Autarco2Child = {}

-- Sample class for handling binary switch logic. You can create as many classes as you need.
-- Each device type you create should have its own class which inherits from the QuickAppChild type.
class 'CurrentPower'(QuickAppChild)
function CurrentPower:__init(device)
  QuickAppChild.__init(self, device)
  self.identifier = self:getVariable("identifier")
end
-- function CurrentPower:updateValue(data)
--   self:updateProperty("value", tonumber(data.stats.kpis.pw_now))
--   self:updateProperty("unit", "W")
-- end

function QuickApp:onInit()
  fibaro.installFibaroExtra()

  self.httpClient = net.HTTPClient({timeout=3000})
  self.site = self:getVariable("site")
  self.username = self:getVariable("username")
  self.password = self:getVariable("password")

  self:loadChildren()
  for id,child in pairs(self.childDevices) do
    Autarco2Child[id] = child
  end

  for id,child in pairs(MyAutarcoDevices) do
    if not Autarco2Child[id] then
      Autarco2Child[id] = self:createChild{
        type = 'com.fibaro.energyMeter',
        name = name,
        className = 'Meter',
        quickVars = { identifier = identifier },
      }
    end
  end

  setInterval(function() self:getPower end, 1500)
end

-- An example of a GET inquiry
-- self.http must have been previously created by net.HTTPClient
-- {"dt_config_changed":"2021-11-26T15:34:20+00:00","inverters":{"154E41209290014":{"sn":"154E41209290014","dt_latest_msg":"2022-03-02T17:52:49+00:00","out_ac_power":144,"out_ac_energy_total":578,"error":null,"grid_turned_off":false,"health":"OK"}},"stats":{"graphs":{"pv_power":{"154E41209290014":{"2022-03-03 00:00:00":0,"2022-03-03 00:15:00":0,"2022-03-03 00:30:00":0,"2022-03-03 00:45:00":0,"2022-03-03 01:00:00":0,"2022-03-03 01:15:00":0,"2022-03-03 01:30:00":0,"2022-03-03 01:45:00":0,"2022-03-03 02:00:00":0,"2022-03-03 02:15:00":0,"2022-03-03 02:30:00":0,"2022-03-03 02:45:00":0,"2022-03-03 03:00:00":0,"2022-03-03 03:15:00":0,"2022-03-03 03:30:00":0}},"no_comms":[{"start":"2022-03-03T00:00:00+01:00","end":null}]},"kpis":{"pv_now":0}}}
function QuickApp:getPower()
    local address = "https://my.autarco.com/api/m1/site/" .. self.site .. "/power"
    local mime = require("mime")

    self.http:request(address, {
        options={
            headers = {
                Authorization = "Basic " .. (QuickApp:encodeBase64(self.username .. ":" .. self.password))
            },
            checkCertificate = true,
            method = 'GET'
        },
        success = function(response)
            self:debug("response status:", response.status)
            self:debug("headers:", response.headers["Content-Type"])
            local data = json.decode(response.data)
            if data.stats and data.contents.kpis and data.contents.kpis.pv_now then
                local pv_now = data.contents.kpis.pv_now
                self:debug(pv_now)
                self:updateView("pv_now", "text", pv_now)
                self:updateProperty("value", pv_now)
                self:updateProperty("power", pv_now)

            end
        end,
        error = function(error)
            self:debug('error: ' .. json.encode(error))
        end
    })
end

function QuickApp:onInit()
  self:debug("onInit")
  self:setupChildDevices()
  -- self:trace('')
  -- self:updateProperty('manufacturer', 'SMA')
  -- self:updateProperty('manufacturer', 'Power sensor')
  self:run()
end

function QuickApp:run()
    self:pullDataFromInverter()
    local interval = self.config:getTimeoutInterval()
    if (interval > 0) then
        fibaro.setTimeout(interval, function() self:run() end)
    endel
end

=function QuickApp:pullDataFromInverter()
    self:updateView("button1", "text", "Even wachten...")
    local sid = false
    local errorCallback = function(error)
        self:updateView("button1", "text", "Updaten")
        Quickfunction QuickApp:button1Event()
    self:pullDataFromInverter()
end

App:error(json.encode(error))
    end
    local logoutCallback = function()
        self:updateView("label1", "text", string.format("Laatst geüpdatet", os.date('%Y-%m-%d %H:%M:%S')))
        self:updateView("button1", "text", "Refresh")
        self:trace("geüpdatet")
    end
    local valuesCallback = function(res)
        if res and res.result then
            for _, device in pairs(res.result) do
                local power = device[SMA.POWER_CURRENT]["1"][1]['val']
                self:updatePower(power)
            end
        end
        self.sma:logout(sid, logoutCallback, errorCallback)
    end
    local loginCallback = function(sessionId)
        sid = sessionId
        self.sma:getValues(sid, {SMA.POWER_CURRENT}, valuesCallback, errorCallback)
    end
    self.sma:login(loginCallback, errorCallback)
end

function QuickApp:updatePower(power)
    if power > 1000 then
        self:updateProperty("value", power / 1000)
        self:updateProperty("unit", "KW")
    else
        self:updateProperty("value", power)
        self:updateProperty("unit", "W")
    end
    self:updateProperty("power", power)
end

function QuickApp:setupChildDevices()
  local child = self:createChildDevice({
    name = "CurrentPower",
    type = "com.fibaro.energyMeter",
    value = 0,
    unit = ""
  })
end

function QuickApp:createChild(name, type, uid)
  local type = type or "com.fibaro.energyMeter"
  local child = self:createChildDevice({
    name = name,
    type = type
  }, CurrentPower)

  self:trace("Child device created: ", child.id)
  self:storeDevice(uid, child.id)
end

function QuickApp:storeDevice(uid, hcId)
  self.devicesMap[uid] = hcId
  -- Save devicesMap, so you can restore it after Quick App restart.
  -- Just put self.devicesMap = self:getVariable("devicesMap") in onInit method.
  self:setVariable("devicesMap", self.devicesMap)
end

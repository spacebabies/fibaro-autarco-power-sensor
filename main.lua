function fibaro.installFibaroExtra()local a="fibaroExtra"if fibaro.FIBARO_EXTRA then return end;local b="https://raw.githubusercontent.com/jangabrielsson/TQAE/main/lib/"..a..".lua"net.HTTPClient():request(b,{options={method='GET',checkCertificate=false,timeout=20000},success=function(c)if c.status==200 then local d={isMain=false,type='lua',isOpen=false,name=a,content=c.data}fibaro.debug(__TAG,"Installing ",a)local e,c=api.post("/quickApp/"..plugin.mainDeviceId.."/files",d)if c~=200 then fibaro.error(__TAG,"Installing ",a," - ",c)end else fibaro.error(__TAG,"Error ",c.status," fetching ",b)end end,error=function(c)fibaro.error(__TAG,"Error ",c," fetching ",b)end})end

TargetInventory = {
  pvno01 = {
    className = 'Meter', name = 'Current Power', type = "com.fibaro.energyMeter"
  }
}

CurrentInventory = {}

class 'CurrentPower'(QuickAppChild)
function CurrentPower:__init(device)
  QuickAppChild.__init(self, device)
  self.fid = self:getVariable("fid")
end
function CurrentPower:updateValue(value)
  self.value = value
end

function QuickApp:getPower()
  local url = format("https://my.autarco.com/api/m1/site/%s/power",self.site)
  net.HTTPClient():request(url,{
    options = {
      method='GET',
      headers = {
        Authorization = fibaro.utils.basicAuthorization(self.username, self.password)
      },
      checkCertificate = true
    }},
    success = function(resp)
      self.power = json.decode(resp.data)

      local pvno01 = CurrentInventory["pvno01"]
      pvno01.updateValue(power.stats.kpis.pv_now)
    end
  })
end

function QuickApp:createAutarcoChild(sku, className, name, type)
  local props = { quickAppVariables = {
      {name='sku',value=sku},
      {name='className',value=className},
      {name='name', value=name},
      {name='type', value=type}
    }
  }
  Autarco2Child[sku]=self:createChildDevice({
    sku = sku,
    name = name,
    type= fibaroType,
    initialProperties = props,
  })
end

function QuickApp:onInit()
  fibaro.installFibaroExtra()

  self.site = self:getVariable("site")
  self.httpUser = self:getVariable("username")
  self.httpPass = self:getVariable("password")

  if self.site=="" or self.httpUser=="" or self.httpPass=="" then -- Warn and disable QA if credentials are not provided
    self:error("Missing credentials")
    --self:setEnabled(false)
    return
  end

  for id,child in pairs(self.childDevices) do
    CurrentInventory[child.sku]=child
  end

  if not CurrentInventory['pvno01'] then
    self:createAutarcoChild(TargetInventory['pvno01'])
  end

  setInterval(function() self:getPower() end,300000) -- poll Autarco API every 1.5s
end

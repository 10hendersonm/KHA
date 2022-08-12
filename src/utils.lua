local addonName, util = ...

local isDebug = false

function util.debug(...)
  if (isDebug) then
    print(
      string.format('[%s]', addonName),
      ...
    )
  end
end

util.debug('Debug Logging Enabled')

util.framePrefix = addonName

function util.getKnownSpells()
  local spellMap = {}
  local i = 1
  while true do
    local spellName, spellSubName = GetSpellBookItemName(i, BOOKTYPE_SPELL)
    if not spellName then
      do break end
    end
    spellMap[spellName] = true
    i = i + 1
  end

  return spellMap
end

function util.getUnitBuffs(unitName)
  local i = 1
  local buffs = {}
  while true do
    local name,
      rank,
      icon,
      count,
      debuffType,
      duration,
      expirationTime,
      unitCaster,
      isStealable,
      shouldConsolidate,
      spellId = UnitBuff(unitName, i)

    if (not name) then
      do break end
    end

    buffs[name] = rank

    i = i + 1
  end

  return buffs
end

function util.waitForEvents(events, handler)
  local listenerFrame = CreateFrame('Frame')

  local firedEvents = {}
  for i, eventName in ipairs(events) do
    firedEvents[eventName] = false
    listenerFrame:RegisterEvent(eventName)
  end

  local handled = false
  listenerFrame:SetScript('OnEvent', function(self, eventName)
    listenerFrame:UnregisterEvent(eventName)
    
    if (handled) then
      listenerFrame:UnregisterAllEvents()
      return
    end
    firedEvents[eventName] = true

    for e, eventFired in pairs(firedEvents) do
      if (not eventFired) then
        -- Bail if an event hasn't fired
        return
      end
    end

    listenerFrame:UnregisterAllEvents()
    handler()
  end)
end
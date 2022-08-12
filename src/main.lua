local addonName, util = ...

local anchorButtonId = string.format('%s-anchor', util.framePrefix)
local anchorButton = _G[anchorButtonId] or CreateFrame('Frame', anchorButtonId, UIParent)
anchorButton:SetSize(30, 30)
anchorButton:SetPoint('CENTER', 0, -200)
anchorButton:SetMovable(true)
anchorButton:EnableMouse(true)
anchorButton:RegisterForDrag('LeftButton')
anchorButton:SetScript('OnDragStart', anchorButton.StartMoving)
anchorButton:SetScript('OnDragStop', anchorButton.StopMovingOrSizing)
anchorButton:SetUserPlaced(true)
anchorButton.icon = anchorButton:CreateTexture('ARTWORK')
anchorButton.icon:SetAllPoints()
anchorButton:SetAlpha(0)
local anchorButtonIconId = GetItemIcon(28066)
anchorButton.icon:SetTexture(anchorButtonIconId)

local fadeTicker = nil

local stopFadeTicker = function()
  if (fadeTicker) then
    fadeTicker:Cancel()
    fadeTicker = nil
  end
end

local startFadeTicker = function(fadeIn)
  stopFadeTicker()

  fadeTicker = C_Timer.NewTicker(0.05, function()
    local minAlpha = 0
    local maxAlpha = 0.5
    local currentAlpha = anchorButton:GetAlpha()
    local increment = 0.05
    local nextAlpha = currentAlpha

    if (fadeIn) then
      nextAlpha = currentAlpha + increment
      if (nextAlpha > maxAlpha) then
        nextAlpha = maxAlpha
        stopFadeTicker()
      end
    else
      nextAlpha = currentAlpha - increment
      if (nextAlpha < minAlpha) then
        nextAlpha = minAlpha
        stopFadeTicker()
      end
    end

    anchorButton:SetAlpha(nextAlpha)
  end)
end

local hoverHandler = function()
  startFadeTicker(true)
end

local leaveHandler = function()
  startFadeTicker(false)
end

anchorButton:SetScript('OnEnter', hoverHandler)
anchorButton:SetScript('OnLeave', leaveHandler)

util.waitForEvents({
  'PLAYER_ENTERING_WORLD',
  'VARIABLES_LOADED',
  'ADDON_LOADED',
}, function()
  util.debug('Initializing')
  local knownSpells = util.getKnownSpells()

  local hunterAspects = {}

  for spellName in pairs(knownSpells) do
    if (string.find(string.lower(spellName), 'aspect of the') == 1) then
      hunterAspects[spellName] = {}
    end
  end

  local previousButton = anchorButton
  for hunterAspect, cfg in pairs(hunterAspects) do
    util.debug('Found aspect:', hunterAspect)

    local buttonId = string.format('%s-btn%s', util.framePrefix, hunterAspect)

    local button = _G[buttonId] or CreateFrame(
      'Button',
      buttonId,
      UIParent,
      'SecureActionButtonTemplate'
    )

    button:Enable()
    button:SetHeight(30)
    button:SetWidth(30)
    button:SetPoint('LEFT', previousButton, 'RIGHT', 3, 0)
    
    button:Show()

    button:SetScript('OnEnter', hoverHandler)
    button:SetScript('OnLeave', leaveHandler)

    local _, _, aspectIcon, _, _, _, spellId = GetSpellInfo(hunterAspect)
    button.icon = button:CreateTexture('ARTWORK')
    button.icon:SetAllPoints()
    button.icon:SetTexture(aspectIcon)
    
    button:SetAttribute('type', 'spell')
    button:SetAttribute('spell', hunterAspect)

    cfg.button = button
    cfg.icon = aspectIcon

    local gcdFrameId = string.format('%s-gcd', buttonId)
    local gcd = _G[gcdFrameId] or CreateFrame('Cooldown', gcdFrameId, button, 'CooldownFrameTemplate')
    gcd:SetAllPoints()

    gcd:RegisterEvent('SPELL_UPDATE_COOLDOWN')
    gcd:SetScript('OnEvent', function(self, eventName)
      local start, duration = GetSpellCooldown(spellId)
      gcd:SetCooldown(start, duration)
    end)

    previousButton = button
  end

  local activeIconSpellId = 20585
  local _, _, activeIcon = GetSpellInfo(activeIconSpellId)

  function setActiveAspectIcon()
    local playerBuffs = util.getUnitBuffs('player')

    for hunterAspect, cfg in pairs(hunterAspects) do
      if (playerBuffs[hunterAspect]) then
        cfg.button.icon:SetTexture(activeIcon)
      else
        cfg.button.icon:SetTexture(cfg.icon)
      end
    end
  end

  setActiveAspectIcon()

  local eventHandler = CreateFrame('Frame')
  eventHandler:RegisterEvent('UNIT_AURA')
  eventHandler:SetScript('OnEvent', function(self, eventName, unitTarget)
    if (unitTarget == 'player') then
      setActiveAspectIcon()
    end
  end)


end)

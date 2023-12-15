local mod = RegisterMod('Flip Cards', 1)
local json = require('json')
local game = Game()

mod.playerTypes = {
  PlayerType.PLAYER_EDEN,
  PlayerType.PLAYER_EDEN_B,
}

mod.cardItems = {
  CollectibleType.COLLECTIBLE_BLANK_CARD,
  --CollectibleType.COLLECTIBLE_BOOK_OF_SIN,
  CollectibleType.COLLECTIBLE_BOOSTER_PACK,
  --CollectibleType.COLLECTIBLE_BOX,
  --CollectibleType.COLLECTIBLE_CRYSTAL_BALL,
  --CollectibleType.COLLECTIBLE_D1,
  CollectibleType.COLLECTIBLE_DECK_OF_CARDS,
  --CollectibleType.COLLECTIBLE_ECHO_CHAMBER,
  --CollectibleType.COLLECTIBLE_FORTUNE_COOKIE,
  --CollectibleType.COLLECTIBLE_MAGIC_8_BALL,
  --CollectibleType.COLLECTIBLE_POLYDACTYLY,
  CollectibleType.COLLECTIBLE_STARTER_DECK,
  CollectibleType.COLLECTIBLE_TAROT_CLOTH,
}

mod.cardTrinkets = {
  TrinketType.TRINKET_ACE_SPADES,
  --TrinketType.TRINKET_ENDLESS_NAMELESS,
}

mod.flipCards = {
  [Card.CARD_FOOL]                     = Card.CARD_REVERSE_FOOL,
  [Card.CARD_MAGICIAN]                 = Card.CARD_REVERSE_MAGICIAN,
  [Card.CARD_HIGH_PRIESTESS]           = Card.CARD_REVERSE_HIGH_PRIESTESS,
  [Card.CARD_EMPRESS]                  = Card.CARD_REVERSE_EMPRESS,
  [Card.CARD_EMPEROR]                  = Card.CARD_REVERSE_EMPEROR,
  [Card.CARD_HIEROPHANT]               = Card.CARD_REVERSE_HIEROPHANT,
  [Card.CARD_LOVERS]                   = Card.CARD_REVERSE_LOVERS,
  [Card.CARD_CHARIOT]                  = Card.CARD_REVERSE_CHARIOT,
  [Card.CARD_JUSTICE]                  = Card.CARD_REVERSE_JUSTICE,
  [Card.CARD_HERMIT]                   = Card.CARD_REVERSE_HERMIT,
  [Card.CARD_WHEEL_OF_FORTUNE]         = Card.CARD_REVERSE_WHEEL_OF_FORTUNE,
  [Card.CARD_STRENGTH]                 = Card.CARD_REVERSE_STRENGTH,
  [Card.CARD_HANGED_MAN]               = Card.CARD_REVERSE_HANGED_MAN,
  [Card.CARD_DEATH]                    = Card.CARD_REVERSE_DEATH,
  [Card.CARD_TEMPERANCE]               = Card.CARD_REVERSE_TEMPERANCE,
  [Card.CARD_DEVIL]                    = Card.CARD_REVERSE_DEVIL,
  [Card.CARD_TOWER]                    = Card.CARD_REVERSE_TOWER,
  [Card.CARD_STARS]                    = Card.CARD_REVERSE_STARS,
  [Card.CARD_MOON]                     = Card.CARD_REVERSE_MOON,
  [Card.CARD_SUN]                      = Card.CARD_REVERSE_SUN,
  [Card.CARD_JUDGEMENT]                = Card.CARD_REVERSE_JUDGEMENT,
  [Card.CARD_WORLD]                    = Card.CARD_REVERSE_WORLD,
  [Card.CARD_REVERSE_FOOL]             = Card.CARD_FOOL,
  [Card.CARD_REVERSE_MAGICIAN]         = Card.CARD_MAGICIAN,
  [Card.CARD_REVERSE_HIGH_PRIESTESS]   = Card.CARD_HIGH_PRIESTESS,
  [Card.CARD_REVERSE_EMPRESS]          = Card.CARD_EMPRESS,
  [Card.CARD_REVERSE_EMPEROR]          = Card.CARD_EMPEROR,
  [Card.CARD_REVERSE_HIEROPHANT]       = Card.CARD_HIEROPHANT,
  [Card.CARD_REVERSE_LOVERS]           = Card.CARD_LOVERS,
  [Card.CARD_REVERSE_CHARIOT]          = Card.CARD_CHARIOT,
  [Card.CARD_REVERSE_JUSTICE]          = Card.CARD_JUSTICE,
  [Card.CARD_REVERSE_HERMIT]           = Card.CARD_HERMIT,
  [Card.CARD_REVERSE_WHEEL_OF_FORTUNE] = Card.CARD_WHEEL_OF_FORTUNE,
  [Card.CARD_REVERSE_STRENGTH]         = Card.CARD_STRENGTH,
  [Card.CARD_REVERSE_HANGED_MAN]       = Card.CARD_HANGED_MAN,
  [Card.CARD_REVERSE_DEATH]            = Card.CARD_DEATH,
  [Card.CARD_REVERSE_TEMPERANCE]       = Card.CARD_TEMPERANCE,
  [Card.CARD_REVERSE_DEVIL]            = Card.CARD_DEVIL,
  [Card.CARD_REVERSE_TOWER]            = Card.CARD_TOWER,
  [Card.CARD_REVERSE_STARS]            = Card.CARD_STARS,
  [Card.CARD_REVERSE_MOON]             = Card.CARD_MOON,
  [Card.CARD_REVERSE_SUN]              = Card.CARD_SUN,
  [Card.CARD_REVERSE_JUDGEMENT]        = Card.CARD_JUDGEMENT,
  [Card.CARD_REVERSE_WORLD]            = Card.CARD_WORLD,
}

mod.input = {}
mod.lookupCards = {}
mod.playerCards = {}

mod.state = {}
mod.state.flipLockedCards = true

function mod:onGameStart()
  if mod:HasData() then
    local _, state = pcall(json.decode, mod:LoadData())
    
    if type(state) == 'table' then
      if type(state.flipLockedCards) == 'boolean' then
        mod.state.flipLockedCards = state.flipLockedCards
      end
    end
  end
  
  mod:setupModConfigMenu()
  mod:addModdedCards()
end

function mod:onGameExit()
  mod:save()
  mod:clearPlayerCards()
end

function mod:save()
  mod:SaveData(json.encode(mod.state))
end

function mod:onRender()
  if game:IsPaused() then
    return
  end
  
  for i = 0, game:GetNumPlayers() - 1 do
    local player = game:GetPlayer(i)
    local playerHash = GetPtrHash(player)
    local slot = 0
    local card, flip = mod:playerGetCardAndFlip(player, slot)
    
    if mod.input.isActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) and
       mod:playerHasRequirements(player) and
       (Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex) or (mod:playerCountPocketItems(player) == 1 and not mod:playerIsTheForgotten(player))) and
       flip and card == mod.playerCards[playerHash] -- don't flip immediately when switching slots
    then
      mod:playerSetCard(player, flip, slot)
    end
    
    mod.playerCards[playerHash] = card
  end
end

-- block game input
function mod:onInputAction(entity, inputHook, buttonAction)
  if entity and entity.Type == EntityType.ENTITY_PLAYER and inputHook == InputHook.IS_ACTION_TRIGGERED then
    local player = entity:ToPlayer()
    
    if mod:shouldBlockDropInput(buttonAction, player.ControllerIndex) then
      return false
    end
  end
end

-- block mod input
function mod:overrideInput()
  mod.input.isActionTriggered = Input.IsActionTriggered
  
  Input.IsActionTriggered = function(action, controllerId)
    if mod:shouldBlockDropInput(action, controllerId) then
      return false
    end
    
    return mod.input.isActionTriggered(action, controllerId)
  end
end

function mod:shouldBlockDropInput(buttonAction, controllerIdx)
  if buttonAction == ButtonAction.ACTION_DROP and Input.IsActionPressed(ButtonAction.ACTION_MAP, controllerIdx) then
    for i = 0, game:GetNumPlayers() - 1 do
      local player = game:GetPlayer(i)
      local playerHash = GetPtrHash(player)
      local slot = 0
      local card, flip = mod:playerGetCardAndFlip(player, slot)
      
      if player.ControllerIndex == controllerIdx and mod:playerHasRequirements(player) and flip and card == mod.playerCards[playerHash] then
        return true
      end
    end
  end
  
  return false
end

function mod:playerSetCard(player, card, slot)
  if type(card) == 'table' then
    -- this lets you flip until you get which "pip" you want
    local rng = player:GetCardRNG(mod:getLookupCard(card))
    card = card[rng:RandomInt(#card) + 1]
  end
  
  player:SetCard(slot, card)
  --SFXManager():Play(SoundEffect.SOUND_BOOK_PAGE_TURN_12, Options.SFXVolume, 2, false, 1, 0)
end

function mod:playerGetCardAndFlip(player, slot)
  local card = player:GetCard(slot)
  local flip = mod.flipCards[card]
  
  if flip and not mod.state.flipLockedCards then
    local itemConfig = Isaac.GetItemConfig()
    local cardConfig = itemConfig:GetCard(mod:getLookupCard(card))
    local flipConfig = itemConfig:GetCard(mod:getLookupCard(flip))
    
    -- check both so we can flip back and forth
    if not (cardConfig and cardConfig:IsAvailable()) or
       not (flipConfig and flipConfig:IsAvailable())
    then
      flip = nil
    end
  end
  
  return card, flip
end

function mod:getLookupCard(card)
  local temp = mod.lookupCards[card]
  if temp then
    return temp
  end
  
  return card
end

function mod:playerHasRequirements(player)
  local playerType = player:GetPlayerType()
  for _, v in ipairs(mod.playerTypes) do
    if v == playerType then
      return true
    end
  end
  
  for _, v in ipairs(mod.cardItems) do
    if player:HasCollectible(v, false) then
      return true
    end
  end
  
  for _, v in ipairs(mod.cardTrinkets) do
    if player:HasTrinket(v, false) then
      return true
    end
  end
  
  return false
end

-- 0-4
-- GetPocketItem doesn't work
-- GetMaxPocketItems gives potential, not actual
function mod:playerCountPocketItems(player)
  local count = 0
  
  for i = 0, 3 do
    if player:GetCard(i) > Card.CARD_NULL or player:GetPill(i) > PillColor.PILL_NULL then
      count = count + 1
    end
  end
  
  for _, v in ipairs({ ActiveSlot.SLOT_POCKET, ActiveSlot.SLOT_POCKET2 }) do
    if player:GetActiveItem(v) > CollectibleType.COLLECTIBLE_NULL then
      count = count + 1
    end
  end
  
  return count
end

function mod:playerIsTheForgotten(player)
  local playerType = player:GetPlayerType()
  local subPlayer = player:GetSubPlayer()
  local subPlayerType = subPlayer and subPlayer:GetPlayerType()
  
  return (playerType == PlayerType.PLAYER_THEFORGOTTEN and subPlayerType == PlayerType.PLAYER_THESOUL) or
         (playerType == PlayerType.PLAYER_THESOUL and subPlayerType == PlayerType.PLAYER_THEFORGOTTEN)
end

function mod:addModdedCards()
  -- reverse wheel of fortune rework mod
  local onePip = Isaac.GetCardIdByName('One Pip')
  local twoPip = Isaac.GetCardIdByName('Two Pip')
  local threePip = Isaac.GetCardIdByName('Three Pip')
  local fourPip = Isaac.GetCardIdByName('Four Pip')
  local fivePip = Isaac.GetCardIdByName('Five Pip')
  local sixPip = Isaac.GetCardIdByName('Six Pip')
  
  if onePip > -1 and twoPip > -1 and threePip > -1 and fourPip > -1 and fivePip > -1 and sixPip > -1 and
     not mod.flipCards[onePip] and not mod.flipCards[twoPip] and not mod.flipCards[threePip] and not mod.flipCards[fourPip] and not mod.flipCards[fivePip] and not mod.flipCards[sixPip]
  then
    mod.flipCards[Card.CARD_WHEEL_OF_FORTUNE] = { onePip, twoPip, threePip, fourPip, fivePip, sixPip }
    mod.flipCards[onePip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[twoPip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[threePip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[fourPip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[fivePip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[sixPip] = Card.CARD_WHEEL_OF_FORTUNE
    
    mod.lookupCards[mod.flipCards[Card.CARD_WHEEL_OF_FORTUNE]] = Card.CARD_REVERSE_WHEEL_OF_FORTUNE
    mod.lookupCards[onePip] = Card.CARD_REVERSE_WHEEL_OF_FORTUNE
    mod.lookupCards[twoPip] = Card.CARD_REVERSE_WHEEL_OF_FORTUNE
    mod.lookupCards[threePip] = Card.CARD_REVERSE_WHEEL_OF_FORTUNE
    mod.lookupCards[fourPip] = Card.CARD_REVERSE_WHEEL_OF_FORTUNE
    mod.lookupCards[fivePip] = Card.CARD_REVERSE_WHEEL_OF_FORTUNE
    mod.lookupCards[sixPip] = Card.CARD_REVERSE_WHEEL_OF_FORTUNE
  end
  
  -- eye of night cards mod
  local eyeOfNight = Isaac.GetCardIdByName('Eye of Night card')
  local revEyeOfNight = Isaac.GetCardIdByName('Reverse Eye of Night')
  
  if eyeOfNight > -1 and revEyeOfNight > -1 and
     not mod.flipCards[eyeOfNight] and not mod.flipCards[revEyeOfNight]
  then
    mod.flipCards[eyeOfNight] = revEyeOfNight
    mod.flipCards[revEyeOfNight] = eyeOfNight
  end
end

function mod:clearPlayerCards()
  for k, _ in pairs(mod.playerCards) do
    mod.playerCards[k] = nil
  end
end

function mod:tblHasVal(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  
  return false
end

function mod:setupEid()
  if not EID then
    return
  end
  
  EID:addDescriptionModifier(mod.Name, function(descObj)
    return descObj.ObjType == EntityType.ENTITY_PICKUP and
           (
             (descObj.ObjVariant == PickupVariant.PICKUP_COLLECTIBLE and mod:tblHasVal(mod.cardItems, descObj.ObjSubType)) or
             (descObj.ObjVariant == PickupVariant.PICKUP_TRINKET and mod:tblHasVal(mod.cardTrinkets, descObj.ObjSubType))
           )
  end, function(descObj)
    -- english only for now
    EID:appendToDescription(descObj, '#{{Card}} Flip tarot cards ({{ButtonRT}} or {{ButtonSelect}} + {{ButtonRT}})')
    return descObj
  end)
end

-- start ModConfigMenu --
function mod:setupModConfigMenu()
  if not ModConfigMenu then
    return
  end
  
  for _, v in ipairs({ 'Settings', 'Cards' }) do
    ModConfigMenu.RemoveSubcategory(mod.Name, v)
  end
  ModConfigMenu.AddSetting(
    mod.Name,
    'Settings',
    {
      Type = ModConfigMenu.OptionType.BOOLEAN,
      CurrentSetting = function()
        return mod.state.flipLockedCards
      end,
      Display = function()
        return (mod.state.flipLockedCards and 'Flip' or 'Do not flip') .. ' locked cards'
      end,
      OnChange = function(b)
        mod.state.flipLockedCards = b
        mod:save()
      end,
      Info = { 'Do you want to flip cards that', 'haven\'t been unlocked yet?' }
    }
  )
  for _, v in ipairs({
                       { card = Card.CARD_FOOL            , flip = Card.CARD_REVERSE_FOOL            , name = '0 - The Fool'           , info = { 'Defeat ultra greedier as tainted lost' } },
                       { card = Card.CARD_MAGICIAN        , flip = Card.CARD_REVERSE_MAGICIAN        , name = 'I - The Magician'       , info = { 'Defeat ultra greedier as tainted judas' } },
                       { card = Card.CARD_HIGH_PRIESTESS  , flip = Card.CARD_REVERSE_HIGH_PRIESTESS  , name = 'II - The High Priestess', info = { 'Defeat ultra greedier as tainted lilith' } },
                       { card = Card.CARD_EMPRESS         , flip = Card.CARD_REVERSE_EMPRESS         , name = 'III - The Empress'      , info = { 'Defeat ultra greedier as tainted eve' } },
                       { card = Card.CARD_EMPEROR         , flip = Card.CARD_REVERSE_EMPEROR         , name = 'IV - The Emperor'       , info = { 'Defeat ultra greedier as tainted ???' } },
                       { card = Card.CARD_HIEROPHANT      , flip = Card.CARD_REVERSE_HIEROPHANT      , name = 'V - The Hierophant'     , info = { 'Defeat ultra greedier as tainted bethany' } },
                       { card = Card.CARD_LOVERS          , flip = Card.CARD_REVERSE_LOVERS          , name = 'VI - The Lovers'        , info = { 'Defeat ultra greedier as tainted magdalene' } },
                       { card = Card.CARD_CHARIOT         , flip = Card.CARD_REVERSE_CHARIOT         , name = 'VII - The Chariot'      , info = { 'Complete hot potato (challenge #42)' } },
                       { card = Card.CARD_JUSTICE         , flip = Card.CARD_REVERSE_JUSTICE         , name = 'VIII - Justice'         , info = { 'Complete cantripped (challenge #43)' } },
                       { card = Card.CARD_HERMIT          , flip = Card.CARD_REVERSE_HERMIT          , name = 'IX - The Hermit'        , info = { 'Complete red redemption (challenge #44)' } },
                       { card = Card.CARD_WHEEL_OF_FORTUNE, flip = Card.CARD_REVERSE_WHEEL_OF_FORTUNE, name = 'X - Wheel of Fortune'   , info = { 'Defeat ultra greedier as tainted cain' } },
                       { card = Card.CARD_STRENGTH        , flip = Card.CARD_REVERSE_STRENGTH        , name = 'XI - Strength'          , info = { 'Defeat ultra greedier as tainted samson' } },
                       { card = Card.CARD_HANGED_MAN      , flip = Card.CARD_REVERSE_HANGED_MAN      , name = 'XII - The Hanged Man'   , info = { 'Defeat ultra greedier as tainted keeper' } },
                       { card = Card.CARD_DEATH           , flip = Card.CARD_REVERSE_DEATH           , name = 'XIII - Death'           , info = { 'Defeat ultra greedier as tainted forgotten' } },
                       { card = Card.CARD_TEMPERANCE      , flip = Card.CARD_REVERSE_TEMPERANCE      , name = 'XIV - Temperance'       , info = { 'Complete delete this (challenge #45)' } },
                       { card = Card.CARD_DEVIL           , flip = Card.CARD_REVERSE_DEVIL           , name = 'XV - The Devil'         , info = { 'Defeat ultra greedier as tainted azazel' } },
                       { card = Card.CARD_TOWER           , flip = Card.CARD_REVERSE_TOWER           , name = 'XVI - The Tower'        , info = { 'Defeat ultra greedier as tainted apollyon' } },
                       { card = Card.CARD_STARS           , flip = Card.CARD_REVERSE_STARS           , name = 'XVII - The Stars'       , info = { 'Defeat ultra greedier as tainted isaac' } },
                       { card = Card.CARD_MOON            , flip = Card.CARD_REVERSE_MOON            , name = 'XVIII - The Moon'       , info = { 'Defeat ultra greedier as tainted jacob' } },
                       { card = Card.CARD_SUN             , flip = Card.CARD_REVERSE_SUN             , name = 'XIX - The Sun'          , info = { 'Defeat ultra greedier as tainted jacob' } },
                       { card = Card.CARD_JUDGEMENT       , flip = Card.CARD_REVERSE_JUDGEMENT       , name = 'XX - Judgement'         , info = { 'Defeat ultra greedier as tainted lazarus' } },
                       { card = Card.CARD_WORLD           , flip = Card.CARD_REVERSE_WORLD           , name = 'XXI - The World'        , info = { 'Defeat ultra greedier as tainted eden' } },
                       { card = Isaac.GetCardIdByName('Eye of Night card'), flip = Isaac.GetCardIdByName('Reverse Eye of Night'), name = 'XXII - The Eye of Night', info = { 'Install the eye of night cards mod' } },
                    })
  do
    ModConfigMenu.AddSetting(
      mod.Name,
      'Cards',
      {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
          return false
        end,
        Display = function()
          local itemConfig = Isaac.GetItemConfig()
          local cardConfig = itemConfig:GetCard(v.card)
          local flipConfig = itemConfig:GetCard(v.flip)
          
          local status
          if cardConfig and flipConfig then
            if cardConfig:IsAvailable() and flipConfig:IsAvailable() then
              status = 'unlocked'
            else
              status = 'locked'
            end
          else
            status = 'missing'
          end
          
          return v.name .. ' : ' .. status
        end,
        OnChange = function(b)
          -- nothing to do
        end,
        Info = v.info
      }
    )
  end
end
-- end ModConfigMenu --

mod:overrideInput()
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.onInputAction)

mod:setupEid()
mod:setupModConfigMenu()
local mod = RegisterMod('Flip Cards', 1)
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

mod.isDropButtonTriggered = false
mod.playerCards = {}

function mod:onGameStart()
  mod:addModdedCards()
  mod:updateEid()
end

function mod:onGameExit()
  mod.isDropButtonTriggered = false
  mod:clearPlayerCards()
end

function mod:onRender()
  if game:IsPaused() then
    return
  end
  
  for i = 0, game:GetNumPlayers() - 1 do
    local player = game:GetPlayer(i)
    local playerHash = GetPtrHash(player)
    local _, card = mod:playerGetFlipAndCard(player, 0)
    mod.isDropButtonTriggered = false
    
    if (Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) or mod.isDropButtonTriggered) and
       mod:playerHasRequirements(player) and
       (Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex) or mod:playerCountPocketItems(player) == 1) and
       card == mod.playerCards[playerHash] -- don't flip immediately when switching slots
    then
      mod:playerFlipCard(player)
    end
    
    mod.playerCards[playerHash] = card
  end
end

function mod:onInputAction(entity, inputHook, buttonAction)
  if entity and entity.Type == EntityType.ENTITY_PLAYER then
    local player = entity:ToPlayer()
    
    if buttonAction == ButtonAction.ACTION_DROP and
       inputHook == InputHook.IS_ACTION_TRIGGERED and
       mod:playerHasRequirements(player) and
       mod:playerGetFlipAndCard(player, 0) and
       Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex)
    then
      mod.isDropButtonTriggered = true
      return false
    end
  end
end

function mod:playerFlipCard(player)
  local slot = 0
  local flip, card = mod:playerGetFlipAndCard(player, slot)
  
  if card > Card.CARD_NULL and flip then
    if type(flip) == 'table' then
      -- this lets you flip until you get which "pip" you want
      local rng = player:GetCardRNG(card)
      flip = flip[rng:RandomInt(#flip) + 1]
    end
    
    player:SetCard(slot, flip)
    --SFXManager():Play(SoundEffect.SOUND_BOOK_PAGE_TURN_12, Options.SFXVolume, 2, false, 1, 0)
  end
end

-- flip first lets us use this in "if" statements
function mod:playerGetFlipAndCard(player, slot)
  local card = player:GetCard(slot)
  return mod.flipCards[card], card
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

function mod:addModdedCards()
  -- reverse wheel of fortune rework mod
  local onePip = Isaac.GetCardIdByName('One Pip')
  local twoPip = Isaac.GetCardIdByName('Two Pip')
  local threePip = Isaac.GetCardIdByName('Three Pip')
  local fourPip = Isaac.GetCardIdByName('Four Pip')
  local fivePip = Isaac.GetCardIdByName('Five Pip')
  local sixPip = Isaac.GetCardIdByName('Six Pip')
  
  if onePip > -1 and twoPip > -1 and threePip > -1 and fourPip > -1 and fivePip > -1 and sixPip > -1 then
    mod.flipCards[Card.CARD_WHEEL_OF_FORTUNE] = { onePip, twoPip, threePip, fourPip, fivePip, sixPip }
    mod.flipCards[onePip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[twoPip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[threePip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[fourPip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[fivePip] = Card.CARD_WHEEL_OF_FORTUNE
    mod.flipCards[sixPip] = Card.CARD_WHEEL_OF_FORTUNE
  end
  
  -- eye of night cards mod
  local eyeOfNight = Isaac.GetCardIdByName('Eye of Night card')
  local revEyeOfNight = Isaac.GetCardIdByName('Reverse Eye of Night')
  
  if eyeOfNight > -1 and revEyeOfNight > -1 then
    mod.flipCards[eyeOfNight] = revEyeOfNight
    mod.flipCards[revEyeOfNight] = eyeOfNight
  end
end

function mod:updateEid()
  if EID then
    -- english only for now
    local descriptionAddition = '#{{Card}} Flip tarot cards'
    
    for _, item in ipairs(mod.cardItems) do
      mod:updateEidInternal(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item, function(name, description, lang)
        EID:addCollectible(item, description .. descriptionAddition, name, lang)
      end)
    end
    for _, trinket in ipairs(mod.cardTrinkets) do
      mod:updateEidInternal(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, trinket, function(name, description, lang)
        EID:addTrinket(trinket, description .. descriptionAddition, name, lang)
      end)
    end
  end
end

function mod:updateEidInternal(entityType, variant, subType, func)
  local tblName = EID:getTableName(entityType, variant, subType)
  
  for lang, v in pairs(EID.descriptions) do
    local tbl = v[tblName]
    
    if tbl and tbl[subType] then
      local name = tbl[subType][2]
      local description = tbl[subType][3]
      
      func(name, description, lang)
    end
  end
end

function mod:clearPlayerCards()
  for k, _ in pairs(mod.playerCards) do
    mod.playerCards[k] = nil
  end
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.onInputAction)
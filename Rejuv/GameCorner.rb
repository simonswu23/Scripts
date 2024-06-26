#===============================================================================
# Game Corner
#===============================================================================
def gameCornerShop(index)
  
  # Usage: In a Script Call as "gameCornerShop(index)"
  # E.g. "gameCornerShop(1)" to call the Seel+ Pokemon list.

  # Initialization =============================================================
  
  # List of prizes in internal name
  prizes = [
    [],
    [:SEEL,:SPOINK,:MARACTUS,:HELIOPTILE,0],
    [:ADAMANTMINT,:JOLLYMINT,:BRAVEMINT,:MODESTMINT,:TIMIDMINT,:QUIETMINT,:CALMMINT,:BOLDMINT,:NAUGHTYMINT,:RASHMINT,:LONELYMINT,:MILDMINT,:ABILITYCAPSULE,:PPUP],
    [:ROOKIDEE,:MIENFOO,:DURANT,:AXEW,0]
  ]
  # List of prices
  prices = [
    [],
    [1000,4000,5000,6500,0],
    [3,3,3,3,3,3,3,3,3,3,3,3,3,6],
    [3000,4000,7500,9000,0]
  ]  
  # Only sell key items not already obtained
  check_prizes = [:GOLDENAXE,:GOLDENHAMMER,:GOLDENLANTERN,:GOLDENSURFBOARD,:GOLDENGAUNTLET,:GOLDENSCUBAGEAR,:GOLDENWINGS,:GOLDENJETPACK,:GOLDENDRIFTBOARD,:GOLDENCLAWS]
  check_prices = [10,10,10,15,15,15,20,20,20,20]
  for i in 0...check_prizes.length
    if !$PokemonBag.pbHasItem?(check_prizes[i])
      prizes[2].insert(-1,check_prizes[i])
      prices[2].insert(-1,check_prices[i])
    end
  end

  # Items available depending on gym badge number
  badges = $Trainer.numbadges
  tm_prizes = [:TM70,:TM10]
  tm_prices = [1000,5000]
  for i in 0...tm_prizes.length
    if !$game_switches[tm_prizes[i]]
      prizes[0].insert(-1,tm_prizes[i])
      prices[0].insert(-1,tm_prices[i])
    end
  end
  prizes[0].insert(-1,0)
  prices[0].insert(-1,0)  
  post5_prizes = [:TM56,:TM47]
  post5_prices = [5, 5]
  for i in 0...post5_prizes.length
    if !$game_switches[post5_prizes[i]] && badges>=4
      prizes[2].insert(-1,post5_prizes[i])
      prices[2].insert(-1,post5_prices[i])
    end
  end
  if !$PokemonBag.pbHasItem?(:EXPALL) && !$PokemonBag.pbHasItem?(:EXPALLOFF)
    prizes[2].insert(-1,:EXPALL)
    prices[2].insert(-1,30)
  end
  post7_prizes = [:HPCARD, :ATKCARD, :DEFCARD, :SPEEDCARD, :SPATKCARD, :SPDEFCARD]
  post7_prices = [10,10,10,10,10,10]
  for i in 0...post7_prizes.length
    if !$PokemonBag.pbHasItem?(post7_prizes[i])
      prizes[2].insert(-1,post7_prizes[i])
      prices[2].insert(-1,post7_prices[i])
    end
  end

  prizes[2].insert(-1,0)
  prices[2].insert(-1,0)  
  
  # Speech strings (for ease of typing) in this order:
    # Greeting, Choosing a prize, What the player can select to cancel and exit,
    # Confirming prize (lacks the question mark on purpose), Bag is full, 
  strings = [
    "We exchange your coins for prizes.",
    "We exchange your achievement points for prizes.",
    "Which prize would you like?",
    "No thanks",
    "So, you want the ",
    "Sorry, you'll need more coins than that.",
    "You have no room in your Bag."]
    
  # End Initialization =========================================================
  
  # Pre-process text
  text   = "\\CN"
  text_0 = "\\CN"
  text_1 = "\\CN"
  text_2 = "\\CN"
  text_3 = "\\CN"
  if index==2
    text   = "\\AP"
    text_0 = "\\AP"
    text_1 = "\\AP"
    text_2 = "\\AP"
    text_3 = "\\AP"
  end
  text += "#{strings[0]}"
  text_0 += "#{strings[2]}\\ch[1,{listlength},"

  # Add each element in the list, then the "Cancel" message
  # listlength-=-1 # To not count the "Cancel" message (the last 0 in the arrays)
  prizename=""
  for i in 0...prizes[index].length-1
    if index==1 || index==3
      item = prizes[index][i]
      prizename = getMonName(item)
      price = prices[index][i]
    else
      item = prizes[index][i]
      prizename = getItemName(item)
      price = prices[index][i]
    end
    if index==2
      text_0 += "#{prizename} - #{price} AP,"
    else
      text_0 += "#{prizename} - #{price} coins,"
    end
  end
  text_0 += "#{strings[3]}"
  text_0 += "]"
  Kernel.pbMessage(_INTL("{1}",text))
  Kernel.pbMessage(_INTL("{1}",text_0))

  # Made a choice and processing
  choice = $game_variables[1]
  if choice!=prizes[index].length-1
    if index==1 || index==3
      item = prizes[index][choice]
      prizename = getMonName(item)
      price = prices[index][choice]
    else
      item = prizes[index][choice]
      prizename = getItemName(item)
      price = prices[index][choice]
    end
    text_1 += "#{strings[4]}#{prizename}?\\ch[2,-1,Yes,No]"
    Kernel.pbMessage(_INTL("{1}",text_1))
    yesno = $game_variables[2]

    
    if yesno==0 # Unless "No"
      # Calculate price in coins
      price = prices[index][choice]

      if index==2
        # Not enough AP
        if price > $game_variables[:APPoints]
          text_2 += "#{strings[5]}"
          Kernel.pbMessage(_INTL("{1}",text_2))
        # Not enough bag space
        elsif !$PokemonBag.pbCanStore?(item)
          text_3 += "#{strings[6]}"
          Kernel.pbMessage(_INTL("{1}",text_3))
        # Pay for prize (in AP)
        else
          $game_variables[:APPoints]-=price
          Kernel.pbReceiveItem(item)
          $game_switches[:Exp_All_On] = true if item == :EXPALL
          $game_switches[item] = true if item == :TM47 || item == :TM56
        end
      else
        # Not enough coins
        if price > $PokemonGlobal.coins
          text_2 += "#{strings[5]}"
          Kernel.pbMessage(_INTL("{1}",text_2))
        # Not enough bag space
        elsif !$PokemonBag.pbCanStore?(item) && index==0
          text_3 += "#{strings[6]}"
          Kernel.pbMessage(_INTL("{1}",text_3))
        else
        # Pay for prize (in coins)
        $PokemonGlobal.coins-=price
          if index==0
            Kernel.pbReceiveItem(item)
            $game_switches[item] = true if item == :TM10 || item == :TM70
          else
            p = PokeBattle_Pokemon.new(item,10,$Trainer)
            if item == :SEEL
              p.pbLearnMove(:STOCKPILE)
            elsif item == :SPOINK
              p.pbLearnMove(:FUTURESIGHT)
            elsif item == :MARACTUS
              p.pbLearnMove(:SPIKES)
            elsif item == :HELIOPTILE
              p.pbLearnMove(:GLARE)
            elsif item == :ARON
              p.pbLearnMove(:HEADSMASH)
            elsif item == :DURANT
              p.pbLearnMove(:BATONPASS)
            elsif item == :MIENFOO
              p.pbLearnMove(:KNOCKOFF)
            elsif item == :RUFFLET
              p.pbLearnMove(:UTURN)
            elsif item == :AXEW
              p.pbLearnMove(:NIGHTSLASH)
            end
            Kernel.pbAddPokemon(p)
          end
        end
      end
    end
  end
  
end
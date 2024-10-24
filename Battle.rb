# Results of battle:
#    0 - Undecided or aborted
#    1 - Player won
#    2 - Player lost
#    3 - Player or wild Pokémon ran from battle, or player forfeited the match
#    4 - Wild Pokémon was caught
#    5 - Draw

class PokeBattle_RealBattlePeer
  def pbOnEnteringBattle(battle,pokemon)
  end
end

################################################################################
# Catching and storing Pokémon.
################################################################################
module PokeBattle_BattleCommon
  def pbStorePokemon(pokemon)
    if !(pokemon.isShadow? rescue false)
      if pbDisplayConfirm(_INTL("Would you like to give a nickname to {1}?",pokemon.name))
        species=getMonName(pokemon.species)
        nickname=@scene.pbNameEntry(_INTL("{1}'s nickname?",species),pokemon)
        pokemon.name=nickname if nickname!=""
      end
    end
    oldcurbox=@peer.pbCurrentBox()
    storedbox=@peer.pbStorePokemon(self.pbPlayer,pokemon)
    creator=@peer.pbGetStorageCreator()
    return if storedbox<0
    curboxname=@peer.pbBoxName(oldcurbox)
    boxname=@peer.pbBoxName(storedbox)
    if storedbox!=oldcurbox
      if creator
        pbDisplayPaused(_INTL("Box \"{1}\" on {2}'s PC was full.",curboxname,creator))
      else
        pbDisplayPaused(_INTL("Box \"{1}\" on someone's PC was full.",curboxname))
      end
      pbDisplayPaused(_INTL("{1} was transferred to box \"{2}\".",pokemon.name,boxname))
    else
      if creator
        pbDisplayPaused(_INTL("{1} was transferred to {2}'s PC.",pokemon.name,creator))
      else
        pbDisplayPaused(_INTL("{1} was transferred to someone's PC.",pokemon.name))
      end
      pbDisplayPaused(_INTL("It was stored in box \"{1}\".",boxname))
    end
  end


  def pbBallFetch(pokeball)
    for i in 0...4
      if self.battlers[i].ability == (:BALLFETCH) && self.battlers[i].item.nil?
        self.battlers[i].effects[:BallFetch]=pokeball
      end
    end
  end


  def pbThrowPokeBall(idxPokemon,ball,rareness=nil,showplayer=false)
    itemname=getItemName(ball)
    battler=nil
    if pbIsOpposing?(idxPokemon)
      battler=self.battlers[idxPokemon]
    else
      battler=self.battlers[idxPokemon].pbOppositeOpposing
    end
    if battler.isFainted?
      battler=battler.pbPartner
    end
    oldform=battler.form
    battler.form=battler.pokemon.getForm(battler.pokemon)
    pbDisplayBrief(_INTL("{1} threw a {2}!",self.pbPlayer.name,itemname))
    if battler.isFainted?
      pbDisplay(_INTL("But there was no target..."))
      pbBallFetch(ball)
      return
    end
    if @opponent && (!pbIsSnagBall?(ball) || !battler.isShadow?)
      @scene.pbThrowAndDeflect(ball,1)
      if !($game_switches[:No_Catching] || battler.isbossmon || battler.issossmon)
        pbDisplay(_INTL("The Trainer blocked the Ball!\nDon't be a thief!"))
      else
        pbDisplay(_INTL("The Pokémon knocked the ball away!"))
      end
    else
      if $game_switches[:No_Catching] || battler.issossmon || (battler.isbossmon && (!battler.capturable || battler.shieldCount > 0)) 
        pbDisplay(_INTL("The Pokémon knocked the ball away!"))
        pbBallFetch(ball)
        return
      end
      pokemon=battler.pokemon
      species=pokemon.species
      rareness = pokemon.catchRate if !rareness
      rareness /= 2 if $game_variables[:LuckMoves] != 0
      a=battler.totalhp
      b=battler.hp
      rareness=BallHandlers.modifyCatchRate(ball,rareness,self,battler) 
      rareness +=1 if $PokemonBag.pbQuantity(:CATCHINGCHARM)>0
      rareness +=1 if Reborn && $PokemonBag.pbQuantity(:CATCHINGCHARM2)>0
      rareness +=1 if Reborn && $PokemonBag.pbQuantity(:CATCHINGCHARM3)>0
      rareness +=1 if Reborn && $PokemonBag.pbQuantity(:CATCHINGCHARM4)>0
      if (battler.isbossmon && battler.capturable && battler.shieldCount == 0)
        rareness += 3
      end
      x=(((a*3-b*2)*rareness)/(a*3))
      if battler.status== :SLEEP || battler.status== :FROZEN
        x=(x*2.5)
      elsif !battler.status.nil?
        x=(x*3/2)
      end
      #Critical Capture chances based on caught species'
      c=0
      if $Trainer
        mod = -3
        mod +=0.5 if $Trainer.pokedex.getOwnedCount>500
        mod +=0.5 if $Trainer.pokedex.getOwnedCount>400
        mod +=0.5 if $Trainer.pokedex.getOwnedCount>300
        mod +=0.5 if $Trainer.pokedex.getOwnedCount>200
        mod +=0.5 if $Trainer.pokedex.getOwnedCount>100
        mod +=0.5 if $Trainer.pokedex.getOwnedCount>30
        c=(x*(2**mod)).floor
      end
      shakes=0; critical=false; critsuccess=false
      if x>255 || BallHandlers.isUnconditional?(ball,self,battler)
        shakes=4
      else
        x=1 if x==0
        y = (65536/((255.0/x)**0.1875)).floor
        puts "c = #{c}; x = #{x}"
        percentage = (1/((255.0/x)**0.1875))**4
        puts "Catch chance: #{percentage*100}%"
        percentage = c/256.0 * (1/((255.0/x)**0.1875))
        puts "Crit chance: #{percentage*100}%"
        if pbRandom(256)<c
          critical=true
          if pbRandom(65536)<y
            critsuccess=true
            shakes=4
          end
        else
          shakes+=1 if pbRandom(65536)<y
          shakes+=1 if pbRandom(65536)<y
          shakes+=1 if pbRandom(65536)<y
          shakes+=1 if pbRandom(65536)<y
        end
      end
      shakes=4 if $DEBUG && Input.press?(Input::CTRL)
      @scene.pbThrow(ball,(critical) ? 1 : shakes,critical,critsuccess,battler.index,showplayer)
      case shakes
        when 0
          pbDisplay(_INTL("Oh no! The Pokémon broke free!"))
          pbBallFetch(ball)
          BallHandlers.onFailCatch(ball,self,pokemon)
          battler.form=oldform
        when 1
          pbDisplay(_INTL("Aww... It appeared to be caught!"))
          pbBallFetch(ball)
          BallHandlers.onFailCatch(ball,self,pokemon)
          battler.form=oldform
        when 2
          pbDisplay(_INTL("Aargh! Almost had it!"))
          pbBallFetch(ball)
          BallHandlers.onFailCatch(ball,self,pokemon)
          battler.form=oldform
        when 3
          pbDisplay(_INTL("Shoot! It was so close, too!"))
          pbBallFetch(ball)
          BallHandlers.onFailCatch(ball,self,pokemon)
          battler.form=oldform
        when 4
          # shadow catch should not be segmented like this
          @scene.pbWildBattleSuccess
          snag = pbIsSnagBall?(ball)
          pbDisplayPaused(_INTL("Gotcha! {1} was caught!",pokemon.name))
          @scene.pbThrowSuccess
          if snag && @opponent
            8.times do
              @scene.sprites["battlebox#{battler.index}"].opacity-=32
              @scene.pbGraphicsUpdate
            end
            pbRemoveFromParty(battler.index,battler.pokemonIndex)
            battler.pbReset
            battler.participants=[]
          else
            @decision=4
          end
          if snag
            pokemon.ot=self.pbPlayer.name
            pokemon.trainerID=self.pbPlayer.id
            $Trainer.pokedex.setOwned(pokemon)
          end
          BallHandlers.onCatch(ball,self,pokemon)
          pokemon.ballused=ball
          pokemon.pbRecordFirstMoves
          if !$Trainer.pokedex.dexList[species][:owned?] 
            $Trainer.pokedex.setOwned(pokemon)
            if $Trainer.pokedex.canViewDex && !snag
              pbDisplayPaused(_INTL("{1}'s data was added to the Pokédex.",pokemon.name))
              @scene.pbShowPokedex(species) 
            end
          end
          @scene.pbHideCaptureBall
          pbGainEXP
          pokemon.form=pokemon.getForm(pokemon)
          if snag && @opponent
            pokemon.pbUpdateShadowMoves rescue nil
            @snaggedpokemon.push(pokemon)
            @scene.partyBetweenKO1
          else
            pbStorePokemon(pokemon)
          end
      end
    end
  end
end


################################################################################
# Main battle class.
################################################################################
class PokeBattle_Battle
  attr_reader(:scene)             # Scene object for this battle
  attr_accessor(:decision)        # Decision: 0=undecided; 1=win; 2=loss; 3=escaped; 4=caught
  attr_accessor(:internalbattle)  # Internal battle flag
  attr_accessor(:doublebattle)    # Double battle flag
  attr_accessor(:cantescape)      # True if player can't escape
  attr_accessor(:shiftStyle)      # Shift/Set "battle style" option
  attr_accessor(:battlescene)     # "Battle scene" option
  attr_reader(:player)            # Player trainer
  attr_reader(:opponent)          # Opponent trainer
  attr_accessor(:party1)            # Player's Pokémon party
  attr_accessor(:party2)            # Foe's Pokémon party
  attr_reader(:partyorder)        # Order of Pokémon in the player's party
  attr_accessor(:fullparty1)      # True if player's party's max size is 6 instead of 3
  attr_accessor(:fullparty2)      # True if opponent's party's max size is 6 instead of 3
  attr_reader(:battlers)          # Currently active Pokémon
  attr_reader(:priority)          # Move order of active Pokémon
  attr_accessor(:items)           # Items held by opponents
  attr_accessor(:partneritems)    # Items held by AI partners :)
  attr_accessor(:sides)           # Effects common to each side of a battle
  attr_accessor(:state)
  attr_accessor(:field)           # Effects common to the whole of a battle
  attr_accessor(:environment)     # Battle surroundings
  attr_accessor(:weather)         # Current weather, custom methods should use pbWeather instead
  attr_accessor(:weatherduration) # Duration of current weather, or -1 if indefinite
  attr_accessor(:weatherbackup)    # The original weather of the area, if it exists.  #### DemICE - persistentweather
  attr_accessor(:weatherbackupanim)# Easy loading for original weather's animation.  #### DemICE - persistentweather
  attr_reader(:switching)         # True if during the switching phase of the round
  attr_accessor(:struggle)        # The Struggle move
  attr_accessor(:choices)         # Choices made by each Pokémon this round
  attr_accessor(:lastMoveUsed)    # Last move used
  attr_accessor(:lastMoveUser)    # Last move user
  attr_accessor(:synchronize)     # Synchronize state
  attr_accessor(:megaEvolution)   # Battle index of each trainer's Pokémon to Mega Evolve
  attr_accessor(:ultraBurst)      # Battle index of each trainer's Pokémon to Ultra Burst
  attr_accessor(:zMove)           # Battle index of each trainer's Pokémon to use A Z-move
  attr_accessor(:amuletcoin)      # Whether Amulet Coin's effect applies
  attr_accessor(:extramoney)      # Money gained in battle by using Pay Day
  attr_accessor(:endspeech)       # Speech by opponent when player wins
  attr_accessor(:endspeech2)      # Speech by opponent when player wins
  attr_accessor(:endspeechwin)    # Speech by opponent when opponent wins
  attr_accessor(:endspeechwin2)   # Speech by opponent when opponent wins
  attr_accessor(:trickroom)
  attr_accessor(:switchedOut)
  attr_accessor(:previousMove)    # Move used directly previously
  attr_accessor(:previousMoveUser)# User of above
  attr_accessor(:ai)              #our baby who's gonna throw a lot of tantrums...
  attr_accessor(:midturn)
  attr_accessor(:rules)
  attr_reader(:turncount)
  attr_accessor :controlPlayer
  attr_accessor(:disableExpGain)  # True id no exp gain during this battle
  attr_accessor(:fainted_mons)    # Store which pokemon were fainted at the start of the battle
  attr_accessor(:ace_message)     # True if ace message should be displayed
  attr_accessor(:ace_message_handled) # True if ace message has been delivered
  attr_accessor(:commandphase)    # True if during the command phase of battle
  include PokeBattle_BattleCommon
  attr_accessor(:recorded)
  attr_accessor(:sosbattle)       # Stores fight is an sos battle or not
  attr_accessor(:eruption)        # Eruption variable for Volcano Top field
  attr_accessor(:storm9)          # Controll attribute for Tempest being active (for shutoff check)
  MAXPARTYSIZE = 6
  MAXPARTYSIZE2 = 12

  #### YUMIL - 4 - NPC REACTION MOD - START  
  def createNewBattleRecord
    if $game_variables[:BattleDataArray].nil? || !$game_variables[:BattleDataArray].kind_of?(Array)
      $game_variables[:BattleDataArray]=[]
    end
    if @opponent.kind_of?(Array)
      $game_variables[:BattleDataArray]<<Battle_Data.new([@opponent[0].name,@opponent[1].name],@party1,@party2)
    else
      $game_variables[:BattleDataArray]<<Battle_Data.new(@opponent.name,@party1,@party2)
    end
  end
  #### YUMIL - 4 - NPC REACTION MOD - END 

  def pbRandom(x)
    return rand(x)
  end

  def pbAIRandom(x)
    return rand(x)
  end

  def isOnline?
    return false
  end
################################################################################
# Initialise battle class.
################################################################################
  #### YUMIL - 4.5 - NPC REACTION MOD - START  
  def initialize(scene,p1,p2,player,opponent,recorded=false)
    #### YUMIL - 4.5 - NPC REACTION MOD - START 
    @battle          = self
    @scene           = scene
    @decision        = 0
    @internalbattle  = true
    @doublebattle    = false
    @cantescape      = false
    @shiftStyle      = true
    @battlescene     = true
    #### YUMIL - 5 - NPC REACTION MOD - START
    @recorded        = recorded
    #### YUMIL - 5 - NPC REACTION MOD - END 
    if opponent && player.is_a?(Array) && player.length==0
      player = player[0]
    end
    if opponent && opponent.is_a?(Array) && opponent.length==0
      opponent = opponent[0]
    end
    @player          = player                # PokeBattle_Trainer object
    @opponent        = opponent              # PokeBattle_Trainer object
    @party1          = p1
    @party2          = p2
    @partyorder     = (0...6).to_a
    @fullparty1      = false
    @fullparty2      = false
    @battlers        = []
    @items           = nil
    @partneritems    = nil
    @sides           = [Battle_Side.new,   # Player's side
                        Battle_Side.new]   # Foe's side
    @state           = Battle_Global.new    # Whole field (gravity/rooms)
    @field           = PokeBattle_Field.new
    @environment     = :None   # e.g. Tall grass, cave, still water
    @weather         = 0
    @weatherduration = 0
    @weatherbackup   = 0      #### DemICE - persistentweather
    @weatherbackupanim= nil  #### DemICE  - persistentweather
    @storm9          = false
    @switching       = false
    @choices         = [ [0,0,nil,-1],[0,0,nil,-1],[0,0,nil,-1],[0,0,nil,-1] ]
    @successStates   = []
    @lastMoveUsed    = -1
    @lastMoveUser    = -1
    @synchronize     = [-1,-1,0]
    @megaEvolution   = []
    @ultraBurst      = []
    @zMove           = []
    @gigaEvolution   = []
    if @player.is_a?(Array)
      @megaEvolution[0]=[-1]*@player.length
      @ultraBurst[0]   =[-1]*@player.length
      @zMove[0]        =[-1]*@player.length
      @gigaEvolution[0]=[-1]*@player.length
    else
      @megaEvolution[0]=[-1]
      @ultraBurst[0]   =[-1]
      @zMove[0]        =[-1] 
      @gigaEvolution[0]=[-1]
    end
    if @opponent.is_a?(Array)
      @megaEvolution[1]=[-1]*@opponent.length
      @ultraBurst[1]   =[-1]*@opponent.length
      @zMove[1]        =[-1]*@opponent.length
      @gigaEvolution[1]=[-1]*@opponent.length
    else
      @megaEvolution[1]=[-1]
      @ultraBurst[1]   =[-1]
      @zMove[1]        =[-1]
      @gigaEvolution[1]=[-1]
    end
    @amuletcoin      = false
    @switchedOut     = []
    @extramoney      = 0
    @ace_message     = false
    @ace_message_handled = false
    @endspeech       = ""
    @endspeech2      = ""
    @endspeechwin    = ""
    @endspeechwin2   = ""
    @rules           = {}
    @turncount       = 0
    @peer            = PokeBattle_BattlePeer.create()
    @trickroom       = 0
    @priority        = []
    @usepriority     = false
    @snaggedpokemon  = []
    @runCommand      = 0
    @disableExpGain  = false
    @commandphase    = false
    @eruption        = false # Volcanictop Eruption check
    @sosbattle       = 2
    @struggle = PokeBattle_Move.pbFromPBMove(self,PBMove.new(:STRUGGLE),nil)
    @struggle.pp     = -1
    for i in 0...4
      battlers[i] = PokeBattle_Battler.new(self,i)
    end
    if !isOnline?
      for i in @party1
        next if !i
        next if i.nil?
        i.obedient = i.level <= LEVELCAPS[pbPlayer.numbadges]
      end
    end
    for i in @party1
      next if !i
      i.itemRecycle = nil
      i.itemInitial = i.item
      i.itemReallyInitialHonestlyIMeanItThisTime = i.item
      i.belch       = false
      i.piece       = nil
    end
    for i in @party2
      next if !i
      i.itemRecycle = nil
      i.itemInitial = i.item
      i.belch       = false
      i.piece       = nil
    end
  #### YUMIL - 6 - NPC REACTION MOD - START  
    if @recorded || @battle.FE == :CROWD
      createNewBattleRecord
    end
  #### YUMIL - 6 - NPC REACTION MOD - END   
  end

################################################################################
# Info about battle.
################################################################################
  def pbIsWild?
    return !@opponent ? true : false
  end

  def pbDoubleBattleAllowed?
    return true
  end

  def pbCheckSideAbility(a,pkmn) #checks to see if your side has a pokemon with a certain ability.
    for i in 0...4 # in order from own first, opposing first, own second, opposing second
      if @battlers[i].ability == (a)
        if @battlers[i]==pkmn || @battlers[i]==pkmn.pbPartner
          return @battlers[i]
        end
      end
    end
    return nil
  end

  def pbWeather
    for i in 0...4
      if @battlers[i].ability == :CLOUDNINE || @battlers[i].ability == :AIRLOCK || @field.effect == :UNDERWATER || @field.effect == :NEWWORLD
        return 0
      end
    end
    return @weather
  end

  def quarkdriveCheck
    priority == pbPriority
    if @field.effect == :ELECTERRAIN || @state.effects[:ELECTERRAIN] > 0
      for i in priority
        next if i.isFainted?
        next if i.ability != :QUARKDRIVE
        next if i.effects[:Quarkdrive][0] > 0
        aBoost = i.attack * 1.0+(0.5*i.stages[PBStats::ATTACK])
        dBoost = i.defense * 1.0+(0.5*i.stages[PBStats::DEFENSE])
        saBoost = i.spatk * 1.0+(0.5*i.stages[PBStats::SPATK])
        sdBoost = i.spdef * 1.0+(0.5*i.stages[PBStats::SPDEF])
        spdBoost = i.speed * 1.0+(0.5*i.stages[PBStats::SPEED])
        stats = [aBoost,dBoost,saBoost,sdBoost,spdBoost]
        boostStat = stats.index(stats.max)+1
        i.effects[:Quarkdrive] = [boostStat,false]
        @battle.pbDisplay(_INTL("{1}'s Quark Drive heightened its {2}!", i.pbThis,i.pbGetStatName(boostStat)))
      end
    end
    if @field.effect != :ELECTERRAIN && @state.effects[:ELECTERRAIN] < 1
      for i in priority
        next if i.isFainted?
        next if i.effects[:Quarkdrive][0] == 0
        next if i.effects[:Quarkdrive][1]
        i.effects[:Quarkdrive] = [0,false]
        pbDisplay(_INTL("{1}'s Quark Drive shut off!",i.pbThis))
        if i.item == :BOOSTERENERGY
          i.pbDisposeItem(false)
          @battle.pbDisplay(_INTL("{1}'s Booster Energy was used up...", i.pbThis))
          aBoost = i.attack * 1.0+(0.5*i.stages[PBStats::ATTACK])
          dBoost = i.defense * 1.0+(0.5*i.stages[PBStats::DEFENSE])
          saBoost = i.spatk * 1.0+(0.5*i.stages[PBStats::SPATK])
          sdBoost = i.spdef * 1.0+(0.5*i.stages[PBStats::SPDEF])
          spdBoost = i.speed * 1.0+(0.5*i.stages[PBStats::SPEED])
          stats = [aBoost,dBoost,saBoost,sdBoost,spdBoost]
          boostStat = stats.index(stats.max)+1
          i.effects[:Quarkdrive] = [boostStat,true]
          @battle.pbDisplay(_INTL("{1}'s Quark Drive heightened its {2}!", i.pbThis,i.pbGetStatName(boostStat)))
        end
      end
    end
  end

  def seedCheck
    for battler in pbPriority
      next if battler.hp==0 || !battler.item
      next if !battler.itemWorks?
      seeddata = @field.seeds
      next if battler.item != seeddata[:seedtype]
      boostlevel = ["","","sharply ", "drastically "]

      # Stat boost from seed
      statupanimplayed=false
      statdownanimplayed=false
      seeddata[:stats].each_pair {|stat,statval|
        statval *= -1 if battler.ability == :CONTRARY
        if statval > 0 && !battler.pbTooHigh?(stat)
          battler.pbIncreaseStatBasic(stat,statval)
          @battle.pbCommonAnimation("StatUp",battler) if !statupanimplayed
          statupanimplayed=true
          pbDisplay(_INTL("{1}'s {2} {3}boosted its {4}!", battler.pbThis,getItemName(battler.item),boostlevel[statval.abs],battler.pbGetStatName(stat)))
        elsif statval < 0 && !battler.pbTooLow?(stat)
          battler.pbReduceStatBasic(stat,-statval)
          @battle.pbCommonAnimation("StatDown",battler) if !statdownanimplayed
          statdownanimplayed=true
          pbDisplay(_INTL("{1}'s {2} {3}lowered its {4}!", battler.pbThis,getItemName(battler.item),boostlevel[statval.abs],battler.pbGetStatName(stat)))
        end
      }

      # Special effect from seed that need specific code
      case @field.effect
        when :MISTY, :RAINBOW, :STARLIGHT
          if battler.effects[:Wish]==0
            battler.effects[:Wish]=2
            battler.effects[:WishAmount]=((battler.totalhp+1)*0.75).floor
            battler.effects[:WishMaker]=battler.pokemonIndex
            pbAnimation(seeddata[:animation],battler,nil)
            pbDisplay(_INTL(seeddata[:message],battler.pbThis(true)))
          end
          battler.pbDisposeItem(false)
          return

        when :BURNING, :DESERT, :VOLCANIC
          battler.effects[:MultiTurn]=4
          battler.effects[:MultiTurnUser]=battler.index

        when :SWAMP
          if Rejuv 
            battler.ability=:CLEARBODY
            # pbDisplay(_INTL(seeddata[:message],battler.pbThis))
            battler.pbDisposeItem(false)
          end

        when :CORROSIVEMIST, :MURKWATERSURFACE, :CORRUPTED
          if battler.pbCanPoison?(true)
            battler.pbPoison(battler,true)
            pbDisplay(_INTL("{1} was badly poisoned!",battler.pbThis))
          end
          battler.pbDisposeItem(false)
          return if @field.effect == :CORROSIVEMIST || @field.effect == :CORRUPTED

        when :ICY
          if !battler.isAirborne? && battler.ability != :MAGICGUARD
            spikesdiv=[8,8,6,4][battler.pbOwnSide.effects[:Spikes]]
            @scene.pbDamageAnimation(battler,0)
            battler.pbReduceHP([(battler.totalhp.to_f/spikesdiv).floor,1].max)
            pbDisplay(_INTL(seeddata[:message],battler.pbThis))
            battler.pbDisposeItem(false)
            battler.pbFaint if battler.isFainted?
          end
          battler.pbDisposeItem(false)
          return

        when :ROCKY, :CAVE
          if battler.ability != :MAGICGUARD
            atype=(:ROCK) || 0
            eff=PBTypes.twoTypeEff(atype,battler.type1,battler.type2)
            if eff>0
              eff = eff*2
              @scene.pbDamageAnimation(battler,0)
              battler.pbReduceHP([(battler.totalhp*eff/32).floor,1].max)
              pbDisplay(_INTL(seeddata[:message],battler.pbThis))
              battler.pbDisposeItem(false)
              battler.pbFaint if battler.isFainted?
            end
          end
          battler.pbDisposeItem(false)
          return

        when :WASTELAND
          battler.pbDisposeItem(false)
          battler.pbOwnSide.effects[:StealthRock]=true
          battler.pbOpposingSide.effects[:StealthRock]=true
          pbDisplay(_INTL("{1} laid Stealth Rocks everywhere!", battler.pbThis))
          return

        when :UNDERWATER
          if battler.ability == :MULTITYPE || battler.ability == :RKSSYSTEM
            battler.pbDisposeItem(false)
            return
          end
          battler.type1=:WATER
          battler.type2=nil
          pbDisplay(_INTL(seeddata[:message],battler.pbThis))
          battler.pbDisposeItem(false)
          return

        when :GLITCH
          if battler.ability == :MULTITYPE || battler.ability == :RKSSYSTEM
            battler.pbDisposeItem(false)
            return
          end
          battler.type1=:QMARKS
          battler.type2=nil
          pbDisplay(_INTL(seeddata[:message],battler.pbThis))
          battler.pbDisposeItem(false)
          return

        when :MOUNTAIN,:SNOWYMOUNTAIN,:MIRROR,:SKY
          battler.pbDisposeItem(false)
          return

        when :NEWWORLD
          battler.currentMove=0

        when :INVERSE
          if !Rejuv
            battler.currentMove=0
          else
            battler.type1=:NORMAL
            battler.type2=nil
            battler.ability=:NORMALIZE
            pbDisplay(_INTL(seeddata[:message],battler.pbThis))
            battler.pbDisposeItem(false)
            return
          end

        when :PSYTERRAIN
          if battler.pbCanConfuse?(false)
            battler.effects[:Confusion]=2+pbRandom(4)
            pbCommonAnimation("Confusion",battler,nil)
            pbDisplay(_INTL("{1} became confused!",battler.pbThis))
          end
          battler.pbDisposeItem(false)
          return

        when :DIMENSIONAL
          if @trickroom == 0
            rnd=pbRandom(6)
            @trickroom=3+rnd
            pbAnimation(:TRICKROOM,battler,nil)
            pbDisplay(_INTL("{1} twisted the dimensions!",battler.pbThis))
          else
            @trickroom=0
            pbAnimation(:TRICKROOM,battler,nil)
            pbDisplay(_INTL("The twisted dimensions returned to normal!",battler.pbThis))
          end
          battler.pbDisposeItem(false)
          return

        when :HAUNTED
          if battler.pbCanBurn?(false)
            battler.pbBurn(battler)
            pbDisplay(_INTL("{1} was burned!",battler.pbThis))
          end
          battler.pbDisposeItem(false)
          return

        when :INFERNAL
          battler.effects[:MeanLook]=battler.index
          pbAnimation(seeddata[:animation],battler,nil)
          pbDisplay(_INTL(seeddata[:message],battler.pbThis))
          battler.pbDisposeItem(false)
          return

        when :DEEPEARTH
          w=(battler.battlerToPokemon) ? battler.battlerToPokemon.weight : 500
          battler.effects[:WeightModifier]+=w
          pbAnimation(seeddata[:animation],battler,nil)
          pbDisplay(_INTL(seeddata[:message],battler.pbThis))
          battler.pbDisposeItem(false)
          return

        when :CROWD
          battler.cheer
          battler.pbOppositeOpposing.effects[:LockOn]=2
          battler.pbOppositeOpposing.effects[:LockOnPos]=battler.index
          battler.pbCrossOpposing.effects[:LockOn]=2
          battler.pbCrossOpposing.effects[:LockOnPos]=battler.index
          pbAnimation(seeddata[:animation],battler,nil)
          pbDisplay(_INTL(seeddata[:message],battler.pbThis))
          battler.pbDisposeItem(false)
          return 
      end

      # Special effect from seed that doesn't need specific code
      battler.effects[seeddata[:effect]] = seeddata[:duration]
      
      pbAnimation(seeddata[:animation],battler,nil) unless @field.effect == :SUPERHEATED
      if seeddata[:message].start_with?("{1}")
        pbDisplay(_INTL(seeddata[:message],battler.pbThis))
      else
        pbDisplay(_INTL(seeddata[:message],battler.pbThis(true)))
      end
      eval(seeddata[:effect]) if seeddata[:effect].is_a?(String)
      battler.pbDisposeItem(false)
      if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,1,4)
        growField("The synthetic seed",battler)
      end
      battler.pbCheckForm
    end
  end

################################################################################
# Get battler info.
################################################################################
  def pbIsOpposing?(index)
    return (index%2)==1
  end

  def pbOwnedByPlayer?(index)
    return false if pbIsOpposing?(index)
    return false if @player.is_a?(Array) && index==2
    return false if @battle.battlers[index].issossmon
    return true
  end

  def pbIsDoubleBattler?(index)
    return (index>=2)
  end

  def pbThisEx(battlerindex,pokemonindex)
    party=pbParty(battlerindex)
    if pbIsOpposing?(battlerindex)
      if @opponent || (Rejuv && party[pokemonindex].sosmon)
        return _INTL("The foe's {1}",party[pokemonindex].name)
      elsif Rejuv && party[pokemonindex].isbossmon && party[pokemonindex].bossId != :SHADOWDEN
        return _INTL("{1}",party[pokemonindex].name)
      else
        return _INTL("The wild {1}",party[pokemonindex].name)
      end
    else
      return _INTL("{1}",party[pokemonindex].name)
    end
  end

  # Checks whether an item can be removed from a Pokémon.
  def pbIsUnlosableItem(pkmn,item)
    #return true if pbIsMail?(item)
    return true if pbIsZCrystal?(item)
    return false if pkmn.effects[:Transform]
    if (pkmn.species == :ARCEUS && pkmn.ability == :MULTITYPE)
      if PBStuff::PLATEITEMS.include?(item)
        return true
      end
    end
    if (pkmn.species == :SILVALLY && pkmn.ability == :RKSSYSTEM)
      if [:FIGHTINGMEMORY,  :FLYINGMEMORY,    :POISONMEMORY,  :GROUNDMEMORY,  :ROCKMEMORY,
          :BUGMEMORY,       :GHOSTMEMORY,     :STEELMEMORY,   :FIREMEMORY,    :WATERMEMORY, 
          :GRASSMEMORY,     :ELECTRICMEMORY,  :PSYCHICMEMORY, :ICEMEMORY,     :DRAGONMEMORY, 
          :FAIRYMEMORY,     :DARKMEMORY, :GLITCHMEMORY].include?(item)
        return true
      end
    end
    return true if PBStuff::POKEMONTOMEGASTONE[pkmn.species].include?(item)
    return true if Rejuv && (PBStuff::POKEMONTOCREST[pkmn.species] == item || item == :BLKPRISM)
    return true if Rejuv && item == :ZOROCREST && pkmn.effects[:Illusion]
    return true if (pkmn.species == :GENESECT) && ((item == :SHOCKDRIVE) || (item == :BURNDRIVE) || (item == :CHILLDRIVE) || (item == :DOUSEDRIVE)) 
    return true if (pkmn.species == :GROUDON) && (item == :REDORB)
    return true if (pkmn.species == :KYOGRE) && (item == :BLUEORB)
    return true if (pkmn.species == :GIRATINA) && (item == :GRISEOUSORB)
    return true if (item == :PULSEHOLD)
    return false
  end


  def pbCheckGlobalAbility(a)
    for i in 0...@battlers.length
      return @battlers[i] if @battlers[i].ability == (a)
    end
    return nil
  end

  #stupid code for a stupid ability
  def neutralizingGasDisable(index)
    gasactive = false
    for i in 0...4
      gasactive = true if @battle.battlers[i].ability == :NEUTRALIZINGGAS && i!=index
    end
    if !gasactive
      for i in 0...4
        pkmn = @battle.battlers[i]
        if !pkmn.effects[:GastroAcid] && pkmn.ability.nil? && i!=index && !pkmn.backupability.nil?
          pkmn.ability = pkmn.backupability
          pkmn.pbAbilitiesOnSwitchIn(true)
        end
      end
    end
  end

################################################################################
# Player-related info.
################################################################################
  def pbPlayer
    if @player.is_a?(Array)
      return @player[0]
    else
      return @player
    end
  end

  def pbGetOwnerItems(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      return [] if !@items
      if @opponent.is_a?(Array)
        return (battlerIndex==1) ? @items[0] : @items[1]
      else
        return @items
      end
    elsif @player.is_a?(Array) && battlerIndex == 2
      return [] if !@partneritems
      return @partneritems
    else 
      return []
    end
  end

  def items=(items)
    @items = items.clone
  end

   def pbGetMegaRingName(battlerIndex)
    if pbBelongsToPlayer?(battlerIndex)
      ringsA=[:MEGARING,:MEGABRACELET,:MEGACUFF,:MEGACHARM]
      ringsB=[:MEGARING]                                          # 566 = Mega Ring.
      for i in ringsA
        for k in ringsB
          return getItemName(k) if $PokemonBag.pbQuantity(k)>0
        end
      end
    end
    if (@battlers[battlerIndex].isbossmon || @battlers[battlerIndex].issossmon) && !@opponent
      return _INTL("bursting energy")
    end
    return _INTL("Mega Ring")
  end

  def pbHasMegaRing(battlerIndex)
    return true if !pbBelongsToPlayer?(battlerIndex)
    rings=[:MEGARING,:MEGABRACELET,:MEGACUFF,:MEGACHARM]
    for i in rings
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end

  def pbHasZRing(battlerIndex)
    return true if !pbBelongsToPlayer?(battlerIndex)
    rings=[:MEGARING,:MEGABRACELET,:MEGACUFF,:MEGACHARM]
    for i in rings
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end

  def pbHasGigaBand(battlerIndex)
    return true if !pbBelongsToPlayer?(battlerIndex)
    return true if $PokemonBag.pbQuantity(:GIGABAND)>0
    return false
  end

################################################################################
# Get party info, manipulate parties.
################################################################################
  def pbPokemonCount(party)
    count=0
    for i in party
      next if !i
      count+=1 if (i.hp>0 && !i.isEgg?) || (Rejuv && i.isbossmon && i.shieldCount>0)
    end
    return count
  end

  def pbAllFainted?(party)
    pbPokemonCount(party)==0
  end

  def pbMaxLevelFromIndex(index)
    party=pbParty(index)
    owner=(pbIsOpposing?(index)) ? @opponent : @player
    maxlevel=0
    if owner.is_a?(Array)
      start=0
      limit=pbSecondPartyBegin(index)
      start=limit if pbIsDoubleBattler?(index)
      for i in start...start+limit
        next if !party[i]
        maxlevel=party[i].level if maxlevel<party[i].level
      end
    else
      for i in party
        next if !i
        maxlevel=i.level if maxlevel<i.level
      end
    end
    return maxlevel
  end

  def pbMaxLevel(party)
    lv=0
    for i in party
      next if !i
      lv=i.level if lv<i.level
    end
    return lv
  end

  def pbParty(index)
    return pbIsOpposing?(index) ? @party2 : @party1
  end
    

  def pbSecondPartyBegin(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      return @fullparty2 ? 6 : 3
    else
      return @fullparty1 ? 6 : 3
    end
  end

  def pbFindNextUnfainted(party,start,finish=-1)
    finish=party.length if finish<0
    for i in start...finish
      next if !party[i]
      return i if party[i].hp>0 && !party[i].isEgg?
    end
    return -1
  end

  def pbFindPlayerBattler(pkmnIndex)
    battler=nil
    for k in 0...4
      if !pbIsOpposing?(k) && @battlers[k].pokemonIndex==pkmnIndex
        battler=@battlers[k]
        break
      end
    end
    return battler
  end

  def pbIsOwner?(battlerIndex,partyIndex)
    secondParty=pbSecondPartyBegin(battlerIndex)
    if !pbIsOpposing?(battlerIndex)
      return true if !@player || !@player.is_a?(Array)
      return (battlerIndex==0) ? partyIndex<secondParty : partyIndex>=secondParty
    else
      return true if !@opponent || !@opponent.is_a?(Array)
      return (battlerIndex==1) ? partyIndex<secondParty : partyIndex>=secondParty
    end
  end

  def pbGetOwner(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      if @opponent.is_a?(Array)
        return (battlerIndex==1) ? @opponent[0] : @opponent[1]
      else
        return @opponent
      end
    else
      if @player.is_a?(Array)
        return (battlerIndex==0) ? @player[0] : @player[1]
      else
        return @player
      end
    end
  end

  def pbGetOwnerPartner(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      if @opponent.is_a?(Array)
        return (battlerIndex==1) ? @opponent[1] : @opponent[0]
      else
        return @opponent
      end
    else
      if @player.is_a?(Array)
        return (battlerIndex==0) ? @player[1] : @player[0]
      else
        return @player
      end
    end
  end

  def pbPartySingleOwner(battlerIndex)
    party = pbParty(battlerIndex)
    ownerparty = []
    for i in 0...party.length
      ownerparty.push(party[i]) if pbIsOwner?(battlerIndex,i) && !party[i].nil?
    end
    return ownerparty
  end

  def pbPartySingleOwnerNonBattler(battler)
    party = pbPartySingleOwner(battler.index)
    party=party.find_all {|mon| !mon.nil? && battler.pokemon != mon}
    return party
  end

  def pbGetOwnerIndex(battlerIndex)
    if pbIsOpposing?(battlerIndex)
      return (@opponent.is_a?(Array)) ? ((battlerIndex==1) ? 0 : 1) : 0
    else
      return (@player.is_a?(Array)) ? ((battlerIndex==0) ? 0 : 1) : 0
    end
  end

  def pbBelongsToPlayer?(battlerIndex)
    if @player.is_a?(Array) && @player.length>1
      return battlerIndex==0
    else
      return (battlerIndex%2)==0
    end
    return false
  end

  def pbPartyGetOwner(battlerIndex,partyIndex)
    secondParty=pbSecondPartyBegin(battlerIndex)
    if !pbIsOpposing?(battlerIndex)
      return @player if !@player || !@player.is_a?(Array)
      return (partyIndex<secondParty) ? @player[0] : @player[1]
    else
      return @opponent if !@opponent || !@opponent.is_a?(Array)
      return (partyIndex<secondParty) ? @opponent[0] : @opponent[1]
    end
  end

  def pbAddToPlayerParty(pokemon)
    party=pbParty(0)
    for i in 0...party.length
      party[i]=pokemon if pbIsOwner?(0,i) && !party[i]
    end
  end

  def pbRemoveFromParty(battlerIndex,partyIndex)
    party=pbParty(battlerIndex)
    side=(pbIsOpposing?(battlerIndex)) ? @opponent : @player
    party[partyIndex]=nil
    if !side || !side.is_a?(Array) # Wild or single opponent
      party.compact!
      for i in battlerIndex...party.length
        for j in 0..3
          next if !@battlers[j]
          if pbGetOwner(j)==side && @battlers[j].pokemonIndex==i
            #@battlers[j].pokemonIndex-=1
            break
          end
        end
      end
    else
      if battlerIndex<pbSecondPartyBegin(battlerIndex)-1
        for i in battlerIndex...pbSecondPartyBegin(battlerIndex)
          if i>=pbSecondPartyBegin(battlerIndex)-1
            party[i]=nil
          else
            party[i]=party[i+1]
          end
        end
      else
        for i in battlerIndex...party.length
          if i>=party.length-1
            party[i]=nil
          else
            party[i]=party[i+1]
          end
        end
      end
    end
  end

  def pbIsEnemy(battlerIndex)
    if (battlerIndex%2) != 0
      return true
    else
      return false
    end
  end 

  def pieceAssignment(party,trainer_array)
    return if party.length == 0
    pkmnparty = party.find_all {|mon| !mon.nil? && !mon.isEgg? }
    pkmnparty.each {|pkmn| pkmn.piece = nil}
    # Queen
    pkmnparty.last.piece = :QUEEN
    # Pawn
    sendoutorder = pkmnparty.find_all {|mon| mon.hp > 0}
    sendoutorder[0].piece = :PAWN if sendoutorder[0].piece.nil?
    sendoutorder[1].piece = :PAWN if sendoutorder[1] && @doublebattle && !trainer_array && sendoutorder[1].piece.nil? 
    # King
    king_piece = pkmnparty.sort_by { |mon| [mon.piece.nil? ? 0 : 1, mon.item==:KINGSROCK ? 0 : 1, mon.totalhp] }.first
    king_piece.piece = :KING if king_piece && king_piece.piece.nil?
    # Knight / Bishop / Rook
    pkmnparty.each do |pkmn|
      next if pkmn.piece != nil
      pkmn.piece = :KNIGHT if [pkmn.speed,pkmn.attack,pkmn.spatk,pkmn.defense,pkmn.spdef].max == pkmn.speed
      pkmn.piece = :BISHOP if [pkmn.speed,pkmn.attack,pkmn.spatk,pkmn.defense,pkmn.spdef].max == [pkmn.attack,pkmn.spatk].max
      pkmn.piece = :ROOK   if [pkmn.speed,pkmn.attack,pkmn.spatk,pkmn.defense,pkmn.spdef].max == [pkmn.defense,pkmn.spdef].max
    end
  end

  def pbAceMessage
    trainer = @opponent
    ace_text = trainer.aceline=="" ? nil : trainer.aceline
    if Desolation && $game_switches[:LastMon]
      Audio.bgm_play("Audio/BGM/"+$game_variables[:LastMonMusic],$Settings.volume,100)
    end
    if Desolation && $game_switches[:LastMonButMore]
      Audio.bgm_play("Audio/BGM/Battle - Fenrir",$Settings.volume,100)
    end
    if Rejuv && trainer.trainertype.to_s.include?("LEADER_")
      Audio.bgm_play("Audio/BGM/Battle - Gyms",$Settings.volume,105)
    end
    return if ace_text == nil
    if ace_text.is_a?(String)
      @scene.pbShowOpponent(0) if trainer.trainertype != :HEATHER && trainer.trainertype != :ANNA
      pbDisplayPaused(ace_text)
      @scene.pbHideOpponent if trainer.trainertype != :HEATHER && trainer.trainertype != :ANNA
    end
    @ace_message_handled = true
  end

################################################################################
# Check whether actions can be taken.
################################################################################
  def pbCanShowCommands?(idxPokemon)
    thispkmn=@battlers[idxPokemon]
    return false if thispkmn.isFainted?
    return false if thispkmn.effects[:TwoTurnAttack]!=0
    return false if thispkmn.effects[:HyperBeam]>0
    return false if thispkmn.effects[:Rollout]>0
    return false if thispkmn.effects[:Outrage]>0
    return false if thispkmn.effects[:Rage] && @field.effect == :GLITCH
    return false if thispkmn.effects[:Uproar]>0
    return false if thispkmn.effects[:Bide]>0
    return thispkmn.chargeTurns? == true ? false : true
    return true
  end

  def zMove
    return @zMove
  end

################################################################################
# Attacking.
################################################################################
  def pbCanShowFightMenu?(idxPokemon)
    thispkmn=@battlers[idxPokemon]
    if !pbCanShowCommands?(idxPokemon)
      return false
    end
    # No moves that can be chosen
    if !pbCanChooseMove?(idxPokemon,0,false) && !pbCanChooseMove?(idxPokemon,1,false) && !pbCanChooseMove?(idxPokemon,2,false) && !pbCanChooseMove?(idxPokemon,3,false)
      return false
    end
    # Encore
    return false if thispkmn.effects[:Encore]>0
    return true
  end

  def pbCanChooseMove?(idxPokemon,idxMove,showMessages,flags={sleeptalk: false, instructed: false})
    sleeptalk = flags.fetch(:sleeptalk, false)
    instructed = flags.fetch(:instructed, false)
    thispkmn=@battlers[idxPokemon]
    side=(pbIsOpposing?(idxPokemon)) ? 1 : 0
    owner=pbGetOwnerIndex(idxPokemon)
    zpower = @zMove[side][owner] == idxPokemon
    basemove = zpower ? thispkmn.zmoves[idxMove] : thispkmn.moves[idxMove]
    opp1=thispkmn.pbOpposing1
    opp2=thispkmn.pbOpposing2
    return false if !basemove
    if (!zpower && basemove.pp<=0 && basemove.totalpp>0 && !sleeptalk) || (zpower && thispkmn.moves[idxMove].pp<=0 && thispkmn.moves[idxMove].totalpp>0 && !sleeptalk)
      if showMessages
        pbDisplayPaused(_INTL("There's no PP left for this move!"))
      end
      return false
    end
    if thispkmn.effects[:ChoiceBand] != nil && thispkmn.itemWorks? && (thispkmn.item == :CHOICEBAND || thispkmn.item == :CHOICESPECS || thispkmn.item == :CHOICESCARF) || thispkmn.ability == :GORILLATACTICS
      if thispkmn.moves.any? {|moveloop| moveloop.move==thispkmn.effects[:ChoiceBand]} && (basemove.move!=thispkmn.effects[:ChoiceBand] && sleeptalk == false)
        if showMessages
          pbDisplayPaused(_INTL("{1} allows the use of only {2}!",
             getItemName(thispkmn.item),
             getMoveName(thispkmn.effects[:ChoiceBand])))
        end
        return false
      end
    end
    if (thispkmn.item == :ASSAULTVEST) && !instructed && basemove.betterCategory(basemove.type) == :status
        if showMessages
          pbDisplayPaused(_INTL("{1} doesn't allow use of non-attacking moves!", getItemName(thispkmn.item)))
        end
        return false
    end
    if opp1.effects[:Imprison] && !basemove.zmove
      if basemove.move==opp1.moves[0].move || basemove.move==opp1.moves[1].move || basemove.move==opp1.moves[2].move || basemove.move==opp1.moves[3].move
        if showMessages
          pbDisplayPaused(_INTL("{1} can't use the sealed {2}!",thispkmn.pbThis,basemove.name))
        end
        return false
      end
    end
    if opp2.effects[:Imprison] && !basemove.zmove
      if basemove.move==opp2.moves[0].move || basemove.move==opp2.moves[1].move || basemove.move==opp2.moves[2].move || basemove.move==opp2.moves[3].move
        if showMessages
          pbDisplayPaused(_INTL("{1} can't use the sealed {2}!",thispkmn.pbThis,basemove.name))
        end
        return false
      end
    end
    if (thispkmn.effects[:Taunt]>0) && basemove.betterCategory(basemove.type) == :status && !basemove.zmove
      if showMessages
        pbDisplayPaused(_INTL("{1} can't use {2} after the Taunt!",thispkmn.pbThis,basemove.name))
      end
      return false
    end
    if (opp1.hasWorkingAbility(:GOLDENVY) && !opp1.moldbroken) && basemove.betterCategory(basemove.type) == :status && !basemove.zmove
      if showMessages
        pbDisplayPaused(_INTL("{1} can't use {2} due to {3}'s {4}!",thispkmn.pbThis,basemove.name,opp1.pbThis,getAbilityName(opp1.ability)))
      end
      return false
    end
    if (opp2.hasWorkingAbility(:GOLDENVY) && !opp2.moldbroken) && basemove.betterCategory(basemove.type) == :status && !basemove.zmove
      if showMessages
        pbDisplayPaused(_INTL("{1} can't use {2} due to {3}'s {4}!",thispkmn.pbThis,basemove.name,opp2.pbThis,getAbilityName(opp2.ability)))
      end
      return false
    end
    if thispkmn.effects[:Torment] && !instructed && !basemove.zmove
      if basemove.move==thispkmn.lastRegularMoveUsed
        if showMessages
          pbDisplayPaused(_INTL("{1} can't use the same move in a row due to the torment!",thispkmn.pbThis))
        end
        return false
      end
    end
    if basemove.hasFlag?(:heavymove) && !instructed && !basemove.zmove
      if basemove.move==thispkmn.lastRegularMoveUsed
        if showMessages
          pbDisplayPaused(_INTL("{1} can't use {2} twice in a row!",thispkmn.pbThis,basemove.name))
        end
        return false
      end
    end
    if basemove.move==thispkmn.effects[:DisableMove] && !sleeptalk && !basemove.zmove
      if showMessages
        pbDisplayPaused(_INTL("{1}'s {2} is disabled!",thispkmn.pbThis,basemove.name))
      end
      return false
    end
    if thispkmn.effects[:Encore]>0 && idxMove!=thispkmn.effects[:EncoreIndex] && !basemove.zmove
      return false
    end
    return true
  end

  def pbAutoChooseMove(idxPokemon,showMessages=true)
    thispkmn=@battlers[idxPokemon]
    if thispkmn.isFainted?
      @choices[idxPokemon][0]=0
      @choices[idxPokemon][1]=0
      @choices[idxPokemon][2]=nil
      return true
    end
    if thispkmn.effects[:Encore]>0 && pbCanChooseMove?(idxPokemon,thispkmn.effects[:EncoreIndex],false)
      PBDebug.log("[Auto choosing Encore move...]") if $INTERNAL
      @choices[idxPokemon][0]=1    # "Use move"
      @choices[idxPokemon][1]=thispkmn.effects[:EncoreIndex] # Index of move
      @choices[idxPokemon][2]=thispkmn.moves[thispkmn.effects[:EncoreIndex]]
      @choices[idxPokemon][3]=-1   # No target chosen yet
      if thispkmn.effects[:EncoreMove] == :ACUPRESSURE
        @choices[idxPokemon][3] = idxPokemon
      elsif @doublebattle
        basemove=thispkmn.moves[thispkmn.effects[:EncoreIndex]]
        if basemove.target==:SingleNonUser
          @scene.pbFightMenuEncore(idxPokemon,thispkmn.effects[:EncoreIndex])
          target=@scene.pbChooseTarget(idxPokemon)
          pbRegisterTarget(idxPokemon,target) if target>=0
          return false if target<0
        elsif basemove.target==:UserOrPartner
          @scene.pbFightMenuEncore(idxPokemon,thispkmn.effects[:EncoreIndex])
          target=@scene.pbChooseTarget(idxPokemon)
          pbRegisterTarget(idxPokemon,target) if target>=0 && (target&1)==(idxPokemon&1)
          return false if target<0
        else
          target=thispkmn.pbTarget(basemove)
          pbRegisterTarget(idxPokemon,target)
        end
     end
     return true
    else
      if !pbIsOpposing?(idxPokemon)
        pbDisplayPaused(_INTL("{1} has no moves left!",thispkmn.name)) if showMessages
      end
      @choices[idxPokemon][0]=1           # "Use move"
      @choices[idxPokemon][1]=-1          # Index of move to be used
      @choices[idxPokemon][2]=@struggle  # Use Struggle
      @choices[idxPokemon][3]=-1          # No target chosen yet
      return true
    end
  end

  def pbRegisterMove(idxPokemon,idxMove,showMessages=true)
    thispkmn=@battlers[idxPokemon]
    side=(pbIsOpposing?(idxPokemon)) ? 1 : 0
    owner=pbGetOwnerIndex(idxPokemon)
    basemove= @zMove[side][owner]==idxPokemon ? basemove=thispkmn.zmoves[idxMove] : basemove=thispkmn.moves[idxMove]
    thispkmn.selectedMove = basemove.move
    return false if !pbCanChooseMove?(idxPokemon,idxMove,showMessages)
    @choices[idxPokemon][0]=1         # "Use move"
    @choices[idxPokemon][1]=idxMove   # Index of move to be used
    @choices[idxPokemon][2]=basemove  # PokeBattle_Move object of the move
    @choices[idxPokemon][3]=-1        # No target chosen yet
    return true
  end

  def pbChoseMoveFunctionCode?(i,code)
    return false if @battlers[i].isFainted?
    if @choices[i][0]==1 && @choices[i][1]>=0
      choice=@choices[i][1]
      return @battlers[i].moves[choice].function==code
    end
    return false
  end

  def pbRegisterTarget(idxPokemon,idxTarget)
    @choices[idxPokemon][3]=idxTarget   # Set target of move
    return true
  end


  def pbPriority(ignorequickclaw = true,megacalc = false)
    return @priority if @usepriority && !megacalc # use stored priority if round isn't over yet (best ged rid of this in gen 8)
    @priority.clear
    priorityarray = []
    quickclawarray = [0,0,0,0]
    # -Move priority take precedence(stored as priorityarray[i][0])
    # -Then Items  (stored as priorityarray[i][1])
    # -Then speed (stored as priorityarray[i][2]) (trick room is applied by just making speed negative.)
    # -The last element is just the battler index (which is otherwise lost when sorting)
    for i in 0..3
      priorityarray[i] = [0,0,0,i] #initializes the array and stores the battler index

      # Move priority
      pri = 0
      if (@choices[i][0] == 2 || @battle.switchedOut[i]) # If switching or has switched
        pri = 12
      end
      if @choices[i][0] == 3 #Used item
        pri = 11
      end
      if @choices[i][0] == 1 # Is a move
        pri = @choices[i][2].priority  #Base move priority
        pri -= 1 if @battle.FE == :DEEPEARTH && @choices[i][2].move == :COREENFORCER
        pri += 1 if @field.effect == :CHESS && @battlers[i].pokemon && @battlers[i].pokemon.piece == :KING
        pri += 1 if @battlers[i].ability == :PRANKSTER && @choices[i][2].basedamage==0 && @battlers[i].effects[:TwoTurnAttack] == 0 # Is status move
        pri += 1 if (@battlers[i].ability == :GALEWINGS || @battlers[i].crested == :BRAVIARY) && @choices[i][2].type==:FLYING
        pri += 1 if @choices[i][2].move == :GRASSYGLIDE && (@field.effect == :GRASSY || @battle.state.effects[:GRASSY] > 0)
        pri += 1 if @choices[i][2].move == :POWERSURGE && (@field.effect == :ELECTERRAIN || @battle.state.effects[:ELECTERRAIN] > 0)
        pri += 1 if @choices[i][2].move == :SLEIGHRIDE && (@battle.pbWeather == :HAIL)
        pri += 1 if @choices[i][2].move == :SQUALL && (@battle.pbWeather == :HAIL)
        pri += 1 if (@battlers[i].ability == :HIVEQUEEN || @battlers[i].pbPartner.ability == :HIVEQUEEN) && @choices[i][2].type==:BUG 
        pri += 2 if (@battlers[i].ability == :RUNAWAY || @battlers[i].ability == :JOKER) && (@choices[i][2].function == 0x0EE || @choices[i][2].function == 0x902 || @choices[i][2].function == 0x13D || @choices[i][2].function == 0x0ED)
        pri += 1 if @choices[i][2].move == :QUASH && @field.effect == :DIMENSIONAL
        pri += 1 if @choices[i][2].basedamage != 0 && @battlers[i].crested == :FERALIGATR && @battlers[i].turncount == 1 # Feraligatr Crest
        pri += 3 if @battlers[i].ability == :TRIAGE && (PBStuff::HEALFUNCTIONS).include?(@choices[i][2].function)
        pri += 1 if (@battlers[i].pbOpposing1 && @battlers[i].forewarn.include?(@battlers[i].pbOpposing1.selectedMove)) || (@battlers[i].pbOpposing2 && @battlers[i].forewarn.include?(@battlers[i].pbOpposing2.selectedMove))
      end
      priorityarray[i][0]=pri

      #Item/stall priority (all items overwrite stall priority)
      priorityarray[i][1] = -1 if @battlers[i].ability == :STALL 
      if !ignorequickclaw && @choices[i][0] == 1 # Is a move
        if (@battlers[i].ability == :QUICKDRAW && (pbRandom(100)<30))
          priorityarray[i][1] = 1
          quickclawarray[i] = :QUICKDRAW
        elsif (@battlers[i].itemWorks? && @battlers[i].item == :QUICKCLAW && (pbRandom(100)<20))
          priorityarray[i][1] = 1
          quickclawarray[i] = :QUICKCLAW
        elsif @battlers[i].custap
          priorityarray[i][1] = 1
          quickclawarray[i] = :CUSTAPBERRY
        end
      end
      priorityarray[i][1] = -2 if (@battlers[i].itemWorks? && (@battlers[i].item == :LAGGINGTAIL || @battlers[i].item == :FULLINCENSE))

      #speed priority
      priorityarray[i][2] = @battlers[i].pbSpeed if @trickroom == 0
      priorityarray[i][2] = -@battlers[i].pbSpeed if @trickroom > 0
      
    end
    priorityarray.sort!

    #Speed ties. Only works correctly if two pokemon speed tie
    speedtie = []
    for i in 0..2
      for j in (i+1)..3
        if priorityarray[i][0]==priorityarray[j][0] && priorityarray[i][1]==priorityarray[j][1] && priorityarray[i][2]==priorityarray[j][2]
          if pbRandom(2)==1 
            priorityarray[i],priorityarray[j] = priorityarray[j],priorityarray[i]
          end
        end
      end
    end
    priorityarray.reverse!

    # Quick claw battle message
    for i in 0..3
      @priority[i] = @battlers[priorityarray[i][3]]
      if (@battlers[i].ability == :QUICKDRAW) && quickclawarray[priorityarray[i][3]]==:QUICKDRAW
        if priorityarray[i][1] == 1 && !ignorequickclaw
          @battlers[i].effects[:QuickDrawSnipe] if @battle.FE == :COLOSSEUM
          pbDisplayBrief(_INTL("{1}'s Quick Draw let it move first!",@priority[i].pbThis))
        end
      elsif (@battlers[i].itemWorks? && @battlers[i].item == :QUICKCLAW) && quickclawarray[priorityarray[i][3]]==:QUICKCLAW
        pbDisplayBrief(_INTL("{1}'s Quick Claw let it move first!",@priority[i].pbThis)) if priorityarray[i][1] == 1 && !ignorequickclaw
      end
    end

    @usepriority=true
    return @priority
  end

 # Makes target pokemon move last
  def pbMoveLast(target)
    priorityTarget = pbGetPriority(target)
    priority = @priority
    case priorityTarget
    when 0
      # Opponent has likely already moved
      return false
    when 1
      priority[1], priority[2], priority[3] = priority[2], priority[3], target
      @priority = priority
      return true
    when 2
      priority[2], priority[3] = priority[3], priority[2]
      @priority = priority
      return true
    when 3
      return false
    end
  end


  # Makes the second pokemon move after the first.
  def pbMoveAfter(first, second)
    priorityFirst = pbGetPriority(first)
    priority = @priority
    case priorityFirst
    when 0
      if second == priority[1]
        # Nothing to do here
        return false
      elsif second == priority[2]
        priority[1], priority[2] = second, priority[1]
        @priority = priority
        return true
      elsif second == priority[3]
        priority[1],priority[2],priority[3] = second, priority[1], priority[2]
        @priority = priority
        return true
      end
    when 1
      if second == priority[0] || second == priority[2]
        # Nothing to do here
        return false
      elsif second == priority[3]
        priority[2], priority[3] = priority[3], priority[2]
        @priority = priority
        return true
      end
    when 2
      return false
    when 3
      return false
    end
  end


  def pbGetPriority(mon)
    for i in 0..3
      if @priority[i] == mon
        return i
      end
    end
    return -1
  end


   def pbClearChoices(index)
    choices[index][0] = -1
    choices[index][1] = -1
    choices[index][2] = -1
    choices[index][3] = -1
  end
################################################################################
# Switching Pokémon.
################################################################################
  def pbCanSwitchLax?(idxPokemon,pkmnidxTo,showMessages)
    if pkmnidxTo>=0
      party=pbParty(idxPokemon)
      if pkmnidxTo>=party.length
        return false
      end
      if !party[pkmnidxTo]
        return false
      end
      if party[pkmnidxTo].nil?
        return false
      end
      if party[pkmnidxTo].isEgg?
        pbDisplayPaused(_INTL("An Egg can't battle!")) if showMessages
        return false
      end    
      if Rejuv    
        if party[pkmnidxTo].sosmon
          return false
        end
      end
      if !pbIsOwner?(idxPokemon,pkmnidxTo)
        owner=pbPartyGetOwner(idxPokemon,pkmnidxTo)
        pbDisplayPaused(_INTL("You can't switch {1}'s Pokémon with one of yours!",owner.name)) if showMessages
        return false
      end
      if party[pkmnidxTo].hp<=0
        pbDisplayPaused(_INTL("{1} has no energy left to battle!",party[pkmnidxTo].name)) if showMessages
        return false
      end
      if @battlers[idxPokemon].pokemonIndex==pkmnidxTo
        pbDisplayPaused(_INTL("{1} is already in battle!",party[pkmnidxTo].name)) if showMessages
        return false
      end
      if @battlers[idxPokemon].pbPartner.pokemonIndex==pkmnidxTo
        pbDisplayPaused(_INTL("{1} is already in battle!",party[pkmnidxTo].name)) if showMessages
        return false
      end
    end
    return true
  end

  def pbCanSwitch?(idxPokemon,pkmnidxTo,showMessages,ai_phase=false,running: false)
    thispkmn=@battlers[idxPokemon]
    # Multi-Turn Attacks/Mean Look
    if !pbCanSwitchLax?(idxPokemon,pkmnidxTo,showMessages)
      return false
    end

    isOpposing=pbIsOpposing?(idxPokemon)
    party=pbParty(idxPokemon)
    for i in 0...4
      next if isOpposing!=pbIsOpposing?(i)
      if choices[i][0]==2 && choices[i][1]==pkmnidxTo && !ai_phase
        pbDisplayPaused(_INTL("{1} has already been selected.",party[pkmnidxTo].name)) if showMessages
        return false
      end
    end
    if @field.effect == :COLOSSEUM
      pbDisplayPaused(_INTL("{1} can't be switched out while on Colosseum Field!",thispkmn.pbThis)) if showMessages  
      return false
    end
    if thispkmn.effects[:SkyDrop] #lía
      pbDisplayPaused(_INTL("{1} can't be switched out!",thispkmn.pbThis)) if showMessages
      return false
    end

    opp1=thispkmn.pbOpposing1
    opp2=thispkmn.pbOpposing2
    opp=nil

    if thispkmn.hasType?(:GHOST) && (@field.effect != :DIMENSIONAL || !(opp1.ability == :SHADOWTAG || opp2.ability == :SHADOWTAG) )
      return true
    end
    if thispkmn.hasWorkingItem(:SHEDSHELL)
      return true
    end
    if thispkmn.hasWorkingAbility(:RUNAWAY)
      return true
    end
    
    if @field.effect == :INFERNAL && thispkmn.status ==:SLEEP && (opp1.ability == (:BADDREAMS) || opp2.ability == (:BADDREAMS))
      pbDisplayPaused(_INTL("{1}'s terrible dreams prevent it from being switched out!",thispkmn.pbThis)) if showMessages 
      return false
    end
    if thispkmn.effects[:MultiTurn]>0 || thispkmn.effects[:MeanLook]>=0 || @state.effects[:FairyLock]==1 || thispkmn.effects[:Octolock]>=0
      pbDisplayPaused(_INTL("{1} can't be switched out!",thispkmn.pbThis)) if showMessages
      return false
    end
    # Ingrain
    if thispkmn.effects[:Ingrain]
      return true if @field.effect == :BEWITCHED
      pbDisplayPaused(_INTL("{1} can't be switched out!",thispkmn.pbThis)) if showMessages
      return false
    end
    # Embargo
    if @field.effect == :DIMENSIONAL && (thispkmn.effects[:Embargo]>0 || thispkmn.pbOwnSide.effects[:Embargo] > 0)
      pbDisplayPaused(_INTL("{1} can't be switched out due to Embargo!",thispkmn.pbThis)) if showMessages
      return false
    end
    if thispkmn.hasType?(:STEEL)
      opp=opp1 if opp1.ability == :MAGNETPULL
      opp=opp2 if opp2.ability == :MAGNETPULL
    end
    if !thispkmn.isAirborne?
      opp=opp1 if opp1.ability == :ARENATRAP
      opp=opp2 if opp2.ability == :ARENATRAP
    end
    unless thispkmn.ability == :SHADOWTAG
      opp=opp1 if opp1.ability == :SHADOWTAG
      opp=opp2 if opp2.ability == :SHADOWTAG
    end
    if @battle.state.effects[:Gravity] == -1
      opp = opp1 if opp1.ability == :GRAVPULL && thispkmn.weight < opp1.weight
      opp = opp2 if opp2.ability == :GRAVPULL && thispkmn.weight < opp2.weight
    end
    if (thispkmn.status == :SLEEP || thispkmn.ability == :COMATOSE)
      opp=opp1 if opp1.crested == :DARKRAI && opp1.ability == :BADDREAMS
      opp=opp2 if opp2.crested == :DARKRAI && opp2.ability == :BADDREAMS
    end
    if (thispkmn.stages[PBStats::EVASION] < 0)
      opp=opp1 if opp1.crested == :ALCREMIE
      opp=opp2 if opp2.crested == :ALCREMIE
    end
    if opp
      abilityname=getAbilityName(opp.ability)
      abilityname= "Crest" if opp1.crested == :DARKRAI || opp2.crested == :DARKRAI || opp1.crested == :ALCREMIE || opp2.crested == :ALCRMIE 
      pbDisplayPaused(_INTL("{1}'s {2} prevents switching!",opp.pbThis,abilityname)) if showMessages
      pbDisplayPaused(_INTL("{1} prevents escaping with {2}!", opp.pbThis, abilityname)) if (showMessages || running) && pkmnidxTo == -1
      return false
    end
    return true
  end

  def pbRegisterSwitch(idxPokemon,idxOther)
    return false if !pbCanSwitch?(idxPokemon,idxOther,false)
    @choices[idxPokemon][0]=2          # "Switch Pokémon"
    @choices[idxPokemon][1]=idxOther   # Index of other Pokémon to switch with
    @choices[idxPokemon][2]=nil
    side=(pbIsOpposing?(idxPokemon)) ? 1 : 0
    owner=pbGetOwnerIndex(idxPokemon)
    if @megaEvolution[side][owner]==idxPokemon
      @megaEvolution[side][owner]=-1
    end
    if @ultraBurst[side][owner]==idxPokemon
      @ultraBurst[side][owner]=-1
    end
    if @zMove[side][owner]==idxPokemon
      @zMove[side][owner]=-1
    end
    if @gigaEvolution[side][owner]==idxPokemon
      @gigaEvolution[side][owner]=-1
    end
    return true
  end

  def pbCanChooseNonActive?(index)
    party=pbParty(index)
    for i in 0..party.length-1
      return true if pbCanSwitchLax?(index,i,false)
    end
    return false
  end

 def pbJudgeSwitch(favorDraws=false)
    if !favorDraws
      return if @decision>0
      pbJudge()
      return if @decision>0
    else
      return if @decision==5
      pbJudge()
      return if @decision>0
    end
  end

  def pbSwitch(favorDraws=false,hazardFaint=false)
    if !favorDraws
      return if @decision>0
      pbJudge()
      return if @decision>0
    else
      return if @decision==5
      pbJudge()
      return if @decision>0
    end
    firstbattlerhp=@battlers[0].hp
    switched=[]
    for index in 0...4
      next if (!@doublebattle && pbIsDoubleBattler?(index)) || (@battle.sosbattle == 3 && index ==2)
      next if @battlers[index] && !@battlers[index].isFainted?
      next if !pbCanChooseNonActive?(index)
      if !pbOwnedByPlayer?(index)
        if (!pbIsOpposing?(index) || (@opponent && pbIsOpposing?(index)))
          newenemy=pbSwitchInBetween(index,false,false)
          newname = pbSwitchInName(index,newenemy) #Illusion
          opponent=pbGetOwner(index)
          if !@doublebattle && firstbattlerhp>0 && @shiftStyle && @opponent && @internalbattle && pbCanChooseNonActive?(0) && pbIsOpposing?(index) && @battlers[0].effects[:Outrage]==0
            pbDisplayPaused(_INTL("{1} is about to send in {2}.",opponent.fullname,newname)) 
            if pbDisplayConfirm(_INTL("Will {1} change Pokémon?",self.pbPlayer.name))
              newpoke=pbSwitchPlayer(0,true,true)
              if newpoke>=0
                pbDisplayBrief(_INTL("{1}, that's enough!  Come back!",@battlers[0].name))
                pbRecallAndReplace(0,newpoke)
                switched.push(0)
              end
            end
          end
          pbRecallAndReplace(index,newenemy)
          switched.push(index)
        end
      elsif @opponent || @battlers.any?{|battler| battler.isbossmon}
        newpoke=pbSwitchInBetween(index,true,false)
        pbRecallAndReplace(index,newpoke)
        switched.push(index)
      else
        switch=false
        if !pbDisplayConfirm(_INTL("Use next Pokémon?"))
          switch=(pbRun(index,true)<=0)
        else
          switch=true
        end
        if switch
          newpoke=pbSwitchInBetween(index,true,false)
          pbRecallAndReplace(index,newpoke)
          switched.push(index)
        end
      end
      if newpoke != nil
        for j in 0..index
         if (@battlers[j].ability == :TRACE) && @battlers[j].turncount > 0
          @battlers[j].pbAbilitiesOnSwitchIn(true)
         end
        end
      end
    end
    if switched.length>0
      priority=pbPriority
      for i in priority
        i.pbAbilitiesOnSwitchIn(true) if switched.include?(i.index)
      end
      for i in priority
        seedCheck
      end
    end
  end

  def pbSendOut(index,pokemon)
    #AI CHANGES
    @ai.addMonToMemory(pokemon,index)
    $Trainer.pokedex.setSeen(pokemon)
    @peer.pbOnEnteringBattle(self,pokemon)
    if pbIsOpposing?(index)
      #  in-battle text
      @scene.pbTrainerSendOut(index,pokemon)
      pbCrestEffects(index,pokemon) if @battlers[index].crested
      # Last Pokemon script; credits to venom12 and HelioAU
      if !@opponent.is_a?(Array) && pbPokemonCount(@party2)==1 && !@ace_message_handled
        pbAceMessage()
      end
    else
      @scene.pbSendOut(index,pokemon)
      pbCrestEffects(index,pokemon) if @battlers[index].crested
    end
    @scene.pbResetMoveIndex(index)
  end

  def pbReplace(index,newpoke,batonpass=false)
    if @battlers[index].effects[:Illusion]
      @battlers[index].effects[:Illusion] = nil
    end
    if @battlers[index].unburdened
      @battlers[index].unburdened=false
      @battlers[index].speed/=2
    end
    neutralizingGasDisable(index) if @battlers[index].ability == :NEUTRALIZINGGAS
    party=pbParty(index)
    if pbOwnedByPlayer?(index)
      # Reorder the party for this battle
      bpo=-1; bpn=-1
      for i in 0...6
        bpo=i if @partyorder[i]==@battlers[index].pokemonIndex
        bpn=i if @partyorder[i]==newpoke
      end
      if bpo != -1
        poke1=@partyorder[bpo]
        @partyorder[bpo]=@partyorder[bpn]
        @partyorder[bpn]=poke1
      end
      @battlers[index].pbInitialize(party[newpoke],newpoke,batonpass)
      pbSendOut(index,party[newpoke])
    else
      partyNameOverwrite(party,newpoke) if $game_switches[:NameOverwrite]
      @battlers[index].pbInitialize(party[newpoke],newpoke,batonpass)
      $Trainer.pokedex.setSeen(party[newpoke])
      if pbIsOpposing?(index)
        pbSendOut(index,party[newpoke])
      else
        pbSendOut(index,party[newpoke])
      end
    end
  end

  def partyNameOverwrite(party,newpoke)
  end

  def pbRecallAndReplace(index,newpoke,batonpass=false)
    if @battlers[index].effects[:Illusion]
      @battlers[index].effects[:Illusion] = nil
    end
    if @battlers[index].unburdened
      @battlers[index].unburdened=false
      @battlers[index].speed/=2
    end
    neutralizingGasDisable(index) if @battlers[index].ability == :NEUTRALIZINGGAS
    @battlers[index].vanished = false if @battlers[index].vanished
    @switchedOut[index] = true
    pbClearChoices(index)
    @battlers[index].pbResetForm
    if !@battlers[index].isFainted?
      @scene.pbRecall(index)
    end
    pbMessagesOnReplace(index,newpoke)
    pbReplace(index,newpoke,batonpass)
    @scene.partyBetweenKO2(!pbOwnedByPlayer?(index)) unless @doublebattle
    return pbOnActiveOne(@battlers[index])
  end

  def pbMessagesOnReplace(index,newpoke)
    newname = pbSwitchInName(index,newpoke)
    if pbOwnedByPlayer?(index)
      opposing=@battlers[index].pbOppositeOpposing
      if opposing.hp<=0 || opposing.hp==opposing.totalhp
        pbDisplayBrief(_INTL("Go! {1}!",newname))
      elsif opposing.hp>=(opposing.totalhp/2.0)
        pbDisplayBrief(_INTL("Do it! {1}!",newname))
      elsif opposing.hp>=(opposing.totalhp/4.0)
        pbDisplayBrief(_INTL("Go for it, {1}!",newname))
      else
        pbDisplayBrief(_INTL("Your foe's weak!\nGet 'em, {1}!",newname))
      end
    else
      owner=pbGetOwner(index)
      pbDisplayBrief(_INTL("{1} sent\r\nout {2}!",owner.fullname,newname))
    end
  end

  def pbSwitchInBetween(index,lax,cancancel)
    if !pbOwnedByPlayer?(index)
      PBDebug.log("[AI made a switch]\n")
      return @scene.pbChooseNewEnemy(index,pbParty(index))
    else
      PBDebug.log("[Player made a switch]\n")
      return pbSwitchPlayer(index,lax,cancancel)
    end
  end

  def pbSwitchPlayer(index,lax,cancancel)
    if $testing
      return @scene.pbChooseNewEnemy(index,pbParty(index))
    else
      return @scene.pbSwitch(index,lax,cancancel)
    end
  end

  def pbSwitchInName(index,newpoke) #Illusion
    partynumber = pbParty(index)
    party=pbPartySingleOwner(index)
    newname=nil
    if (partynumber[newpoke].ability == :ILLUSION)
      party2=party.find_all {|item| item && !item.egg? && item.hp>0 }
      if party2[-1] != partynumber[newpoke] #last mon isn't the same illusion mon
        illusionpoke = party2[-1]
      end
    end
    enemyname = getMonName(partynumber[newpoke].species)
    if pbIsOpposing?(index)
      newname = illusionpoke != nil ? getMonName(illusionpoke.species) : enemyname
    else
      newname = illusionpoke != nil ? illusionpoke.name : partynumber[newpoke].name
    end
    return newname
  end

################################################################################
# Using an item.
################################################################################
# Uses an item on a Pokémon in the player's party.
  def pbUseItemOnPokemon(item,pkmnIndex,userPkmn,scene)
    pokemon=@party1[pkmnIndex]
    battler=nil
    name=pbGetOwner(userPkmn.index).fullname
    name=pbGetOwner(userPkmn.index).name if pbBelongsToPlayer?(userPkmn.index)
    pbDisplayBrief(_INTL("{1} used the\r\n{2}.",name,getItemName(item)))
    PBDebug.log("[Player used #{getItemName(item)}]")
    ret=false
    if pokemon.isEgg?
      pbDisplay(_INTL("But it had no effect!"))
    else
      for i in 0...4
        if !pbIsOpposing?(i) && @battlers[i].pokemonIndex==pkmnIndex
          battler=@battlers[i]
        end
      end
      ret=ItemHandlers.triggerBattleUseOnPokemon(item,pokemon,battler,scene)
      #### YUMIL - 7 - NPC REACTION MOD - START
      if @recorded
        $game_variables[:BattleDataArray].last().playerUsedAnItem
      end
      #### YUMIL - 7 - NPC REACTION MOD - END 
    end
    if !ret && pbBelongsToPlayer?(userPkmn.index)
      if $PokemonBag.pbCanStore?(item)
        $PokemonBag.pbStoreItem(item)
      else
        raise _INTL("Couldn't return unused item to Bag somehow.")
      end
    end
    return ret
  end

# Uses an item on an active Pokémon.
  def pbUseItemOnBattler(item,index,userPkmn,scene)
    PBDebug.log("[Player used #{getItemName(item)}]")
    ret=ItemHandlers.triggerBattleUseOnBattler(item,@battlers[index],scene)
    if !ret && pbBelongsToPlayer?(userPkmn.index)
      if $PokemonBag.pbCanStore?(item)
        $PokemonBag.pbStoreItem(item)
      else
        raise _INTL("Couldn't return unused item to Bag somehow.")
      end
      #### YUMIL - 8 - NPC REACTION MOD - START  
      if @recorded
        $game_variables[:BattleDataArray].last().playerUsedAnItem
      end
      #### YUMIL - 8 -NPC REACTION MOD - END 
    end
    return ret
  end

  def pbRegisterItem(idxPokemon,idxItem,idxTarget=nil)
    if ItemHandlers.hasUseInBattle(idxItem)
      if idxPokemon==0
        if ItemHandlers.triggerBattleUseOnBattler(idxItem,@battlers[idxPokemon],self)
          ItemHandlers.triggerUseInBattle(idxItem,@battlers[idxPokemon],self)
          if @doublebattle
            @choices[idxPokemon+2][0]=3         # "Use an item"
            @choices[idxPokemon+2][1]=idxItem   # ID of item to be used
            @choices[idxPokemon+2][2]=idxTarget # Index of Pokémon to use item on
          end
        else
          return false
        end
      else
        if ItemHandlers.triggerBattleUseOnBattler(idxItem,@battlers[idxPokemon],self)
          pbDisplay(_INTL("It's impossible to aim without being focused!"))
        end
        return false
      end
    end
    @choices[idxPokemon][0]=3         # "Use an item"
    @choices[idxPokemon][1]=idxItem   # ID of item to be used
    @choices[idxPokemon][2]=idxTarget # Index of Pokémon to use item on
    side=(pbIsOpposing?(idxPokemon)) ? 1 : 0
    owner=pbGetOwnerIndex(idxPokemon)
    if @megaEvolution[side][owner]==idxPokemon
      @megaEvolution[side][owner]=-1
    end
    if @ultraBurst[side][owner]==idxPokemon
      @ultraBurst[side][owner]=-1
    end
    if @zMove[side][owner]==idxPokemon
      @zMove[side][owner]=-1
    end
    if @gigaEvolution[side][owner]==idxPokemon
      @gigaEvolution[side][owner]=-1
    end
    return true
  end

  def pbEnemyUseItem(item,battler)
    return 0 if !@internalbattle
    return 0 if pbIsPokeBall?(item) # the AI has no balls
    items=pbGetOwnerItems(battler.index)
    return if !items
    opponent=pbGetOwner(battler.index)
    for i in 0...items.length
      if items[i]==item
        items.delete_at(i)
        break
      end
    end
    #### YUMIL - 9 - NPC REACTION MOD - START
    if @recorded
      $game_variables[:BattleDataArray].last().opponentUsedAnItem
    end
    #### YUMIL - 9 - NPC REACTION MOD - END
    itemname=getItemName(item)
    if opponent && opponent.fullname
      if opponent.fullname.length < 30    #bennett and laura potion usage line break (their length = 35)
        pbDisplayBrief(_INTL("{1} used the\r\n{2}!",opponent.fullname,itemname))
      else
        pbDisplayBrief(_INTL("{1} used the\r{2}!",opponent.fullname,itemname))
      end
    end
    case item
    when :ORANBERRY
      battler.pbRecoverHP(10,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :SITRUSBERRY
      battler.pbRecoverHP((battler.totalhp/4.0).floor,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :POTION,:SWEETHEART,:BERRYJUICE
      battler.pbRecoverHP(20,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :SUPERPOTION,:ENERGYPOWDER
      battler.pbRecoverHP(60,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :HYPERPOTION,:ENERGYROOT
      battler.pbRecoverHP(120,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :ULTRAPOTION,:BLUEMIC
      battler.pbRecoverHP(200,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :MOOMOOMILK,:MAGICMILK
      battler.pbRecoverHP(100,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :STRAWBIC
      battler.pbRecoverHP(90,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :CHOCOLATEIC,:LEMONADE
      battler.pbRecoverHP(70,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :FRESHWATER,:VANILLAIC
      battler.pbRecoverHP(30,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :SODAPOP
      battler.pbRecoverHP(50,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :CHINESEFOOD
      battler.pbRecoverHP(300,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :BUBBLETEA
      battler.pbRecoverHP(180,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :STRAWCAKE
      battler.pbRecoverHP(150,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :MAXPOTION
      battler.pbRecoverHP(battler.totalhp,true)
      pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    when :FULLRESTORE
      fullhp=(battler.hp==battler.totalhp)
      battler.pbRecoverHP(battler.totalhp,true)
      battler.status=nil; battler.statusCount=0
      battler.effects[:Confusion]=0
      if fullhp
        pbDisplay(_INTL("{1} became healthy!",battler.pbThis))
      else
        pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
      end
    when :FULLHEAL,:LAVACOOKIE,:OLDGATEAU,:CASTELIACONE,:BIGMALASADA,:LUMBERRY,:MEDICINE,:RAZZTART,:HEALPOWDER
      battler.status=nil; battler.statusCount=0
      battler.effects[:Confusion]=0
      pbDisplay(_INTL("{1} became healthy!",battler.pbThis))
    when :XATTACK
      if battler.pbCanIncreaseStatStage?(PBStats::ATTACK)
        battler.pbIncreaseStat(PBStats::ATTACK,2)
      end
    when :XDEFEND
      if battler.pbCanIncreaseStatStage?(PBStats::DEFENSE)
        battler.pbIncreaseStat(PBStats::DEFENSE,2)
      end
    when :XSPEED
      if battler.pbCanIncreaseStatStage?(PBStats::SPEED)
        battler.pbIncreaseStat(PBStats::SPEED,2)
      end
    when :XSPECIAL
      if battler.pbCanIncreaseStatStage?(PBStats::SPATK)
        battler.pbIncreaseStat(PBStats::SPATK,2)
      end
    when :XSPDEF
      if battler.pbCanIncreaseStatStage?(PBStats::SPDEF)
        battler.pbIncreaseStat(PBStats::SPDEF,2)
      end
    when :XACCURACY
      if battler.pbCanIncreaseStatStage?(PBStats::ACCURACY)
        battler.pbIncreaseStat(PBStats::ACCURACY,2)
      end
    end
  end

################################################################################
# Fleeing from battle.
################################################################################
  def pbCanRun?(idxPokemon)
    return false if @opponent
    thispkmn=@battlers[idxPokemon]
    return true if thispkmn.hasWorkingItem(:SMOKEBALL)
    return true if thispkmn.hasWorkingItem(:MAGNETICLURE)
    return true if thispkmn.hasWorkingItem(:MIRRORLURE)
    return true if thispkmn.ability == :RUNAWAY
    return pbCanSwitch?(idxPokemon,-1,false)
  end

  def pbRun(idxPokemon,duringBattle=false)
    thispkmn=@battlers[idxPokemon]
    if pbIsOpposing?(idxPokemon)
      return 0 if @opponent
      @choices[i][0]=5 # run
      @choices[i][1]=0
      @choices[i][2]=nil
      return -1
    end
    if @opponent
      if $DEBUG && Input.press?(Input::CTRL)
        if pbDisplayConfirm(_INTL("Treat this battle as a win?"))
          @decision=1
          return 1
        elsif pbDisplayConfirm(_INTL("Treat this battle as a loss?"))
          @decision=2
          return 1
        end
      elsif @internalbattle
        if pbDisplayConfirm(_INTL("Would you like to forfeit the battle?"))
          pbDisplay(_INTL("{1} forfeited the match!",self.pbPlayer.name))
          @decision=2
          return 1
        end
      elsif pbDisplayConfirm(_INTL("Would you like to forfeit the match and quit now?"))
        pbDisplay(_INTL("{1} forfeited the match!",self.pbPlayer.name))
        @decision=3
        return 1
      end
      return 0
    end
    if $DEBUG && Input.press?(Input::CTRL)
      pbSEPlay("escape",100)
      pbDisplayPaused(_INTL("Got away safely!"))
      @decision=3
      return 1
    end
    if @cantescape || $game_switches[:Never_Escape]
      pbDisplayPaused(_INTL("Can't escape!"))
      return 0
    end
    if thispkmn.hasType?(:GHOST)
      pbSEPlay("escape",100)
      pbDisplayPaused(_INTL("Got away safely!"))
      @decision=3
      return 1
    end
    if thispkmn.hasWorkingItem(:SMOKEBALL) || thispkmn.hasWorkingItem(:MAGNETICLURE) 
      if duringBattle
        pbSEPlay("escape",100)
        pbDisplayPaused(_INTL("Got away safely!"))
      else
        pbSEPlay("escape",100)
        pbDisplayPaused(_INTL("{1} fled using its {2}!",thispkmn.pbThis,getItemName(thispkmn.item)))
      end
      @decision=3
      return 1
    end
    if thispkmn.ability == :RUNAWAY
      if duringBattle
        pbSEPlay("escape",100)
        pbDisplayPaused(_INTL("Got away safely!"))
      else
        pbSEPlay("escape",100)
        pbDisplayPaused(_INTL("{1} fled using Run Away!",thispkmn.pbThis))
      end
      @decision=3
      return 1
    end
    if !duringBattle && !pbCanSwitch?(idxPokemon,-1,false, running: true) # TODO: Use real messages
      pbDisplayPaused(_INTL("Can't escape!"))
      return 0
    end
    # Note: not pbSpeed, because using unmodified Speed
    speedPlayer=@battlers[idxPokemon].speed
    opposing=@battlers[idxPokemon].pbOppositeOpposing
    if opposing.isFainted?
      opposing=opposing.pbPartner
    end
    if !opposing.isFainted?
      speedEnemy=opposing.speed
      if speedPlayer>speedEnemy
        rate=256
      else
        speedEnemy=1 if speedEnemy<=0
        rate=speedPlayer*128/speedEnemy
        rate+=@runCommand*30
        rate&=0xFF
      end
    else
      rate=256
    end
    ret=1
    if pbAIRandom(256)<rate
      pbSEPlay("escape",100)
      pbDisplayPaused(_INTL("Got away safely!"))
      @decision=3
    else
      pbDisplayPaused(_INTL("Can't escape!"))
      ret=-1
    end
    if !duringBattle
      @runCommand+=1
    end
    return ret
  end

################################################################################
# Mega Evolve battler.
################################################################################
  def pbCanMegaEvolve?(index)
    return false if $game_switches[:No_Mega_Evolution]==true
    return false if !@battlers[index].hasMega?
    return false if !pbHasMegaRing(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    return true if @megaEvolution[side][owner]==-1
    return false if @megaEvolution[side][owner]!=index
    return true
  end

  def pbCanGigaEvolve?(index)
    return false if $game_switches[:No_Mega_Evolution]==true
    return false if !@battlers[index].hasGiga?
    return false if !pbHasGigaBand(index)
    return false if !pbHasGigaStone(index)
    # return true if !pbBelongsToPlayer?(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    return true if @gigaEvolution[side][owner]==-1
    return false if @gigaEvolution[side][owner]!=index
    return true
  end

  def pbHasGigaStone(battlerIndex)
    gigaStone = PBStuff::POKEMONTOGIGASTONE[@battlers[battlerIndex].species][0]
    if !pbBelongsToPlayer?(battlerIndex)
      items=@battle.pbGetOwnerItems(battlerIndex)
      for i in items
        return true if i == gigaStone
      end
    else
      return true if $PokemonBag.pbQuantity(gigaStone)>0
    end
    return false
  end

  def pbCanMegaEvolveAI?(i,index)
    return false if $game_switches[:No_Mega_Evolution]==true
    if i.class==PokeBattle_Battler
      return false if !i.pokemon.hasMegaForm?
    else
      return false if !i.hasMegaForm?
    end
    return false if !pbHasMegaRing(index)
    side=1
    owner=pbGetOwnerIndex(index)
    return false if @megaEvolution[side][owner]!=-1
    return true
  end

  def pbCanGigaEvolveAI?(i,index)
    return false if $game_switches[:No_Mega_Evolution]==true
    if i.class==PokeBattle_Battler
      return false if !i.pokemon.hasGigaForm?
    else
      return false if !i.hasGigaForm?
    end
    return false if !pbHasGigaBand(index)
    side=1
    owner=pbGetOwnerIndex(index)
    return false if @gigaEvolution[side][owner]!=-1
    return true
  end

  def pbRegisterMegaEvolution(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @megaEvolution[side][owner]=index
  end

  def pbUnRegisterMegaEvolution(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @megaEvolution[side][owner]=-1
  end

  def pbRegisterGigaEvolution(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @gigaEvolution[side][owner]=index
  end

  def pbUnRegisterGigaEvolution(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @gigaEvolution[side][owner]=-1
  end

  def pbMegaEvolve(index)
    # Things that disallow mega-evolution
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !(@battlers[index].hasMega? rescue false)
    return if (@battlers[index].isMega? rescue true)

    # Battle message start
    if @battlers[index].issossmon
      ownername = @battlers[index].pbPartner.isbossmon ? @battlers[index].pbPartner.name : @battlers[index].name
    elsif @battlers[index].isbossmon
      ownername = @battlers[index].name
    else
      ownername=pbGetOwner(index).fullname
      ownername=pbGetOwner(index).name if pbBelongsToPlayer?(index)
    end
    if @battlers[index].item==:PULSEHOLD
      pbDisplay(_INTL("{1}'s {2} is reacting to the PULSE machine!", @battlers[index].pbThis, getItemName(@battlers[index].item), ownername))
    elsif @battlers[index].species == :RAYQUAZA
      pbDisplay(_INTL("{1}'s fervent wish has reached {2}!", ownername, @battlers[index].pbThis))
    else
      pbDisplay(_INTL("{1}'s {2} is reacting to {3}'s {4}!", @battlers[index].pbThis,getItemName(@battlers[index].item), ownername,pbGetMegaRingName(index)))
    end

    # Animation
    if @battlers[index].item==:PULSEHOLD
      pbCommonAnimation("PulseEvolution",@battlers[index],nil)
    elsif @battlers[index].species == :RAYQUAZA
      pbCommonAnimation("MegaEvolutionRayquaza",@battlers[index],nil)
    else
      pbCommonAnimation("MegaEvolution",@battlers[index],nil)
    end

    # Update battler
    @battlers[index].pokemon.makeMega
    @battlers[index].form=@battlers[index].pokemon.form
    @battlers[index].backupability = @battlers[index].pokemon.ability
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon) if @battlers[index].effects[:Substitute]==0

    # Battle message finish
    formname = $cache.pkmn[@battlers[index].pokemon.species].forms[@battlers[index].form]
    if formname.include?("Form")
      formname = formname.split("Form")[0].strip
    end
    meganame = formname + " " + getMonName(@battlers[index].pokemon.species)
    if @battlers[index].item==:PULSEHOLD 
      pbDisplay(_INTL("{1} mutated into {2}!",@battlers[index].pbThis,meganame))
    elsif@battlers[index].item==:DEMONSTONE
      pbDisplay(_INTL("{1} mutated into {2}!",@battlers[index].pbThis,meganame))
    else
      pbDisplay(_INTL("{1} Mega Evolved into {2}!",@battlers[index].pbThis,meganame))
    end

    # Remember trainer has mega-evolved
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @megaEvolution[side][owner]=-2

    # Re-update ability of mega-evolved mon
    @battlers[index].pbAbilitiesOnSwitchIn(true)
  end


  # GIGA EVO BELOW

  def pbGigaEvolve(index)
    # Things that disallow giga-evolution
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !(@battlers[index].hasGiga? rescue false)
    return if (@battlers[index].isGiga? rescue true)

    # Battle message start
    if @battlers[index].issossmon
      ownername = @battlers[index].pbPartner.isbossmon ? @battlers[index].pbPartner.name : @battlers[index].name
    elsif @battlers[index].isbossmon
      ownername = @battlers[index].name
    else
      ownername=pbGetOwner(index).fullname
      ownername=pbGetOwner(index).name if pbBelongsToPlayer?(index)
    end

    # @SWu add the specific GMax stone here
    pbDisplay(_INTL("{1} is reacting to its giga core!", @battlers[index].pbThis))
  
    # Animation
    pbCommonAnimation("MegaEvolution",@battlers[index],nil)

    # Update battler
    @battlers[index].pokemon.makeGiga
    @battlers[index].form=@battlers[index].pokemon.form
    @battlers[index].backupability = @battlers[index].pokemon.ability
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon) if @battlers[index].effects[:Substitute]==0

    # Battle message finish
    formname = $cache.pkmn[@battlers[index].pokemon.species].forms[@battlers[index].form]
    if formname.include?("Form")
      formname = formname.split("Form")[0].strip
    end
    meganame = formname + " " + getMonName(@battlers[index].pokemon.species)
    pbDisplay(_INTL("{1} Giga Evolved into {2}!",@battlers[index].pbThis,meganame))

    # Remember trainer has giga-evolved
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @gigaEvolution[side][owner]=-2

    # Update move to become Giga-Move here
    for i in 0...4
      next if !@battlers[index].moves[i]
      next if !@battlers[index].pbGigaCompatibleBaseMove?(@battlers[index].moves[i])

      newmove=PBMove.new(PBStuff::POKEMONTOGIGAMOVE[@battlers[index].species][0])
      @battlers[index].moves[i]=PokeBattle_Move.pbFromPBMove(@battle,newmove,@battlers[index])
      
      if !(@battlers[index].zmoves.nil? || @battlers[index].item == :INTERCEPTZ)
        @battle.updateZMoveIndexBattler(i,@battlers[index])
      end
      @battlers[index].moves[i].pp=5
      @battlers[index].moves[i].totalpp=5
      # unsure, this is literally spaghetti mamma mia
      # if @battlers[index][:DisableMove] == i + 1
      #   @battlers[index][:Disable]=0
      #   @battlers[index][:DisableMove]=0
      # end
    end

    # do later
    # @moves.each {|copiedmove| @battle.ai.addMoveToMemory(self,copiedmove) } if !@battle.isOnline?
    # choice.moves.each {|moveloop| @battle.ai.addMoveToMemory(choice,moveloop) }  if !@battle.isOnline?

    # Re-update ability of giga-evolved mon
    @battlers[index].pbAbilitiesOnSwitchIn(true)
  end


################################################################################
# Ultra Burst battler.
################################################################################
  def pbCanUltraBurst?(index)
    return false if $game_switches[:No_Mega_Evolution]
    return false if !@battlers[index].hasUltra?
    return false if !pbHasZRing(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    return true if @ultraBurst[side][owner]==-1
    return false if @ultraBurst[side][owner]!=index
    return true
  end

  def pbRegisterUltraBurst(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @ultraBurst[side][owner]=index
  end

  def pbUnRegisterUltraBurst(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @ultraBurst[side][owner]=-1
  end

  def pbUltraBurst(index)
    # Things that disallow ultra bursting
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !(@battlers[index].hasUltra? rescue false)
    return if (@battlers[index].isUltra? rescue true)

    # Battle message start
    pbDisplay(_INTL("Bright light is about to burst out of {1}!", @battlers[index].pbThis))

    # Animation
    pbCommonAnimation("UltraBurst",@battlers[index],nil)

    # Update battler
    @battlers[index].pokemon.makeUltra
    @battlers[index].form=@battlers[index].pokemon.form
    @battlers[index].backupability = @battlers[index].pokemon.ability
    @battlers[index].pbUpdate(true)
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)

    # Battle message finish
    pbDisplay(_INTL("{1} regained its true power with Ultra Burst!",@battlers[index].pbThis))

    # Remember trainer has ultra bursted
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @ultraBurst[side][owner]=-2

    # Re-update ability of ultra bursted mon
    @battlers[index].pbAbilitiesOnSwitchIn(true)
  end


################################################################################
# Use Z-Move.
################################################################################
  def pbCanZMove?(index)
    return true if pbCanGigaEvolve?(index)
    return false if $game_switches[:No_Z_Move]
    return false if !@battlers[index].hasZMove?
    return false if !pbHasZRing(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    return true if @zMove[side][owner]==-1
    return false if @zMove[side][owner]!=index
    return true
  end

  def pbRegisterZMove(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @zMove[side][owner]=index
  end

  def pbUnRegisterZMove(index)
    side=(pbIsOpposing?(index)) ? 1 : 0
    owner=pbGetOwnerIndex(index)
    @zMove[side][owner]=-1
  end

  def pbUseZMove(index,choice,crystal,specialZ=false)
    # Things that disallow z-move
    return if !@battlers[index] || !@battlers[index].pokemon
    if !specialZ
      return if !(@battlers[index].hasZMove? rescue false)
    end

    # Battle message
    if choice[2].hasFlag?(:intercept)
      owner=pbGetOwner(index)
      if owner
        pbDisplay(_INTL("{1} is drawing from the Core's power!",owner.name))
      else
        pbDisplay(_INTL("{1} is drawing from the Core's power!",@battlers[index].pbThis))
      end
    else
      pbDisplay(_INTL("{1} surrounded itself with its Z-Power!",@battlers[index].pbThis))
    end

    # Animation
    pbCommonAnimation("ZPower",@battlers[index],nil)

  end


################################################################################
# Call battler.
################################################################################
  def pbCall(index)
    owner=pbGetOwner(index)
    pbDisplay(_INTL("{1} called {2}!",owner.name,@battlers[index].name))
    pbDisplay(_INTL("{1}!",@battlers[index].name))
    if @battlers[index].isShadow?
      if @battlers[index].inHyperMode?
        @battlers[index].pokemon.hypermode=false
        @battlers[index].pokemon.adjustHeart(-300)
        pbDisplay(_INTL("{1} came to its senses from the Trainer's call!",@battlers[index].pbThis))
      else
        pbDisplay(_INTL("But nothing happened!"))
      end
    elsif @battlers[index].status!=:SLEEP && @battlers[index].pbCanIncreaseStatStage?(PBStats::ACCURACY)
      @battlers[index].pbIncreaseStat(PBStats::ACCURACY,1)
    else
      pbDisplay(_INTL("But nothing happened!"))
    end
  end

################################################################################
# Gaining Experience.
################################################################################
  def pbGainEXP
    return if !@internalbattle || @disableExpGain
    #Find who died and get their base EXP & level
    for i in 0...4 # Not ordered by priority
      if !@doublebattle && pbIsDoubleBattler?(i)
        @battlers[i].participants=[]
        next
      end
      next unless (pbIsOpposing?(i) && @battlers[i].participants.length>0 && (@battlers[i].isFainted? || @decision == 4))
      battlerSpecies=@battlers[i].pokemon.species
      baseexp=@battlers[i].baseExp
      level=@battlers[i].level
      mon_order = [] #order that the mons should be given EXP in
      #find who fought
      partic=0
      for j in @battlers[i].participants
        next if !@party1[j] || !pbIsOwner?(0,j) || @party1[j].isEgg?
        next if @party1[j].hp<=0 && !($game_switches[:Exp_All_On] && $game_switches[:Exp_All_Upgrade])
        partic+=1
        mon_order.push(j)
      end
      next if partic==0 && $game_switches[:Exp_All_On] && $game_switches[:Exp_All_Upgrade]

      #push the rest of the party on that array
      for j in 0...@party1.length
        next if !@party1[j] || !pbIsOwner?(0,j) || @party1[j].isEgg?
        next if @party1[j].hp<=0 && !($game_switches[:Exp_All_On] && $game_switches[:Exp_All_Upgrade])
        mon_order.push(j) if !mon_order.include?(j)
      end

      #get the base participant EXP
      partic = 1 if partic==0
      partic_exp=(level*baseexp/partic).floor
      partic_exp=(partic_exp*3/2).floor if @opponent

      #distribute EXP to each mon in the party
      messageskip = false
      for j in mon_order
        thispoke=@party1[j]

        #pokemon information for messages
        hasEXPshare = (thispoke.item == :EXPSHARE || thispoke.itemInitial == :EXPSHARE)
        boostedEXP = ((thispoke.trainerID != self.pbPlayer.id && thispoke.trainerID != 0) || (thispoke.language!=0 && thispoke.language!=self.pbPlayer.language))
        mon_fought = @battlers[i].participants.include?(j)

        #did this mon fight?
        if mon_fought
          exp = partic_exp
        elsif hasEXPshare || $game_switches[:Exp_All_On] #didn't participate- has EXP Share or EXP All is on
          exp = (partic_exp/3).floor #reduced
          exp = (partic_exp/2).floor if $game_switches[:Exp_All_Upgrade]
        else #does not get EXP
          next
        end

        #Gain effort value points, using RS effort values
        pbGainEvs(thispoke,i) if mon_fought || hasEXPshare
        
        #reborn-added EXP booster: 8% per level over 100
        exp*=(1+((thispoke.level-100)*0.08)) if thispoke.level>100
        if USENEWEXPFORMULA   # Use new (Gen 5) Exp. formula
          leveladjust=((2*level+10.0)/(level+thispoke.level+10.0))**2.5
          exp=(exp*leveladjust/5).floor
        else                  # Use old (Gen 1-4) Exp. formula
          exp=(exp/7).floor
        end

        #Trade EXP; different language EXP
        if boostedEXP
          exp*= (thispoke.language!=0 && thispoke.language!=self.pbPlayer.language) ? 1.7 : 1.5
        end
        exp=(exp*3/2).floor if (thispoke.item == :LUCKYEGG) || (thispoke.itemInitial == :LUCKYEGG)
        exp=[1,exp.floor].max

        #We have the EXP that this mon can gain.
        growthrate=thispoke.growthrate
        if $game_switches[:Hard_Level_Cap] || $game_switches[:Exp_All_On] || !Reborn # Rejuv-style Level Cap
          badgenum = pbPlayer.numbadges
          if thispoke.level>=LEVELCAPS[badgenum]
            exp = 0
          elsif thispoke.level<LEVELCAPS[badgenum]
            totalExpNeeded = PBExp.startExperience(LEVELCAPS[badgenum], growthrate)
            currExpNeeded = totalExpNeeded - thispoke.exp
            exp = [currExpNeeded,exp].min
          end
        end
        newexp=PBExp.addExperience(thispoke.exp,exp,growthrate)
        exp=(newexp-thispoke.exp).floor
        exp = 0 if $game_switches[:No_EXP_Gain]
        next if exp <= 0
        if mon_fought || (hasEXPshare && !$game_switches[:Exp_All_On])
          #EXP All text is handled at the end
          if boostedEXP || thispoke.item == :LUCKYEGG
            pbDisplay(_INTL("{1} gained a boosted {2} Exp. Points!",thispoke.name,exp))
          else
            pbDisplay(_INTL("{1} gained {2} Exp. Points!",thispoke.name,exp))
          end
        elsif $game_switches[:Exp_All_On]
          pbDisplay(_INTL("The rest of your team gained Exp. Points thanks to the Exp. All!")) if !messageskip
          messageskip = true
        end
        
        #actually add the EXP
        newlevel=PBExp.levelFromExperience(newexp,growthrate)
        oldlevel=thispoke.level
        if thispoke.respond_to?("isShadow?") && thispoke.isShadow?
          thispoke.exp+=exp
          next
        end

        # Find battler
        battler=pbFindPlayerBattler(j)
        battler = nil if battler && battler.pokemon != thispoke
        curlevel = oldlevel
        oldtotalhp=thispoke.totalhp
        oldattack=thispoke.attack
        olddefense=thispoke.defense
        oldspeed=thispoke.speed
        oldspatk=thispoke.spatk
        oldspdef=thispoke.spdef
        tempexp1=thispoke.exp
        loop do
          #EXP Bar animation
          startexp=PBExp.startExperience(curlevel,growthrate)
          endexp=PBExp.startExperience(curlevel+1,growthrate)
          tempexp2=(endexp<newexp) ? endexp : newexp
          thispoke.exp=tempexp2
          @scene.pbEXPBar(thispoke,battler,startexp,endexp,tempexp1,tempexp2)
          tempexp1=tempexp2
          curlevel+=1
          if curlevel>newlevel
            thispoke.calcStats
            battler.pbUpdate(false) if battler
            @scene.pbRefresh
            break
          end
          thispoke.level = curlevel
            thispoke.changeHappiness("level up")
        end
        next if newlevel<=oldlevel
        #leveled up!
        thispoke.calcStats
        battler.pbUpdate(false) if battler
        @scene.pbRefresh
        pbDisplayPaused(_INTL("{1} grew to Level {2}!",thispoke.name,newlevel))
        @scene.pbLevelUp(thispoke,battler,oldtotalhp,oldattack,olddefense,oldspeed,oldspatk,oldspdef)
        
        # Finding all moves learned at this level
        movelist=thispoke.getMoveList
        for lvl in oldlevel+1..newlevel
          for k in movelist
            if k[0]==lvl   # Learned a new move
              pbLearnMove(j,k[1])
            end
          end
        end

        #evolve if able to
        newspecies=checkEvolution(thispoke)
        next if newspecies.nil?
        pbFadeOutInWithMusic(99999){
          evo=PokemonEvolutionScene.new
          evo.pbStartScreen(thispoke,newspecies)
          evo.pbEvolution
          evo.pbEndScreen
          $game_map.autoplayAsCue
          if battler
            @scene.pbChangePokemon(@battlers[battler.index],@battlers[battler.index].pokemon)
            battler.species = battler.pokemon.species
            battler.form = battler.pokemon.form
            battler.pbUpdate(true)
            @scene.sprites["battlebox#{battler.index}"].refresh
            battler.name=thispoke.name
            for ii in 0...4
              battler.moves[ii]=PokeBattle_Move.pbFromPBMove(self,thispoke.moves[ii],battler)
            end
          end
        }
      end

      # Now clear the participants array
      @battlers[i].participants=[]
    end
  end

  def pbGainEvs(thispoke,i)
    #Gain effort value points, using RS effort values
    totalev=0
    for k in 0..5
      totalev+=thispoke.ev[k]
    end
    # Original species, not current species
    evyield=@battlers[i].evYield
    for k in 0..5
      evgain=evyield[k]
      evgain*=8 if (thispoke.item == :MACHOBRACE) || (thispoke.itemInitial == :MACHOBRACE)
      evgain=0 if [:POWERWEIGHT, :POWERBRACER,:POWERBELT,:POWERANKLET,:POWERLENS,:POWERBAND].include?(thispoke.item)
      case k
          when 0 then evgain+=32 if (thispoke.item == :POWERWEIGHT)
          when 1 then evgain+=32 if (thispoke.item == :POWERBRACER)
          when 2 then evgain+=32 if (thispoke.item == :POWERBELT)
          when 3 then evgain+=32 if (thispoke.item == :POWERLENS)
          when 4 then evgain+=32 if (thispoke.item == :POWERBAND)
          when 5 then evgain+=32 if (thispoke.item == :POWERANKLET)
      end
      case k
        when 0 then evgain+=8 if (thispoke.item == :CANONPOWERWEIGHT)
        when 1 then evgain+=8 if (thispoke.item == :CANONPOWERBRACER)
        when 2 then evgain+=8 if (thispoke.item == :CANONPOWERBELT)
        when 3 then evgain+=8 if (thispoke.item == :CANONPOWERLENS)
        when 4 then evgain+=8 if (thispoke.item == :CANONPOWERBAND)
        when 5 then evgain+=8 if (thispoke.item == :CANONPOWERANKLET)
      end
      evgain*=4 if thispoke.pokerusStage>=1 # Infected or cured
      evgain = 0 if $game_switches[:Stop_Ev_Gain]
      if evgain>0
        # Can't exceed overall limit
        evgain-=totalev+evgain-510 if totalev+evgain>510 && !$game_switches[:No_Total_EV_Cap]
        # Can't exceed stat limit
        evgain-=thispoke.ev[k]+evgain-252 if thispoke.ev[k]+evgain>252
        # Add EV gain
        thispoke.ev[k]+=evgain
        if thispoke.ev[k]>252
          print "Single-stat EV limit 252 exceeded.\r\nStat: #{k}  EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
          thispoke.ev[k]=252
        end
        totalev+=evgain
        if totalev>510 && !$game_switches[:No_Total_EV_Cap]
          print "EV limit 510 exceeded.\r\nTotal EVs: #{totalev} EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
        end
      end
    end
    battler = @battlers.find {|battler| battler.pokemon == thispoke}
    battler.pbUpdate if battler
    @scene.sprites["battlebox#{battler.index}"].refresh if battler
  end

################################################################################
# Learning a move.
################################################################################
  def pbLearnMove(pkmnIndex,move)
    pokemon=@party1[pkmnIndex]
    return if !pokemon
    pkmnname=pokemon.name
    battler=pbFindPlayerBattler(pkmnIndex)
    movename=getMoveName(move)
    for i in 0...4
      if !pokemon.moves[i]
        pokemon.moves[i]=PBMove.new(move)
        battler.moves[i]=PokeBattle_Move.pbFromPBMove(self,pokemon.moves[i],battler) if battler
        if !(pokemon.zmoves.nil? || pokemon.item == :INTERCEPTZ)
          pokemon.updateZMoveIndex(i)
          updateZMoveIndexBattler(i,battler)  if battler
        end
        pbDisplayPaused(_INTL("{1} learned {2}!",pkmnname,movename))
        return
      end
      checkdupe = pokemon.moves[i].move
      if checkdupe==move
        return
      end
    end
    loop do
      pbDisplayPaused(_INTL("{1} is trying to learn {2}.",pkmnname,movename))
      pbDisplayPaused(_INTL("But {1} can't learn more than four moves.",pkmnname))
      if pbDisplayConfirm(_INTL("Delete a move to make room for {1}?",movename))
        pbDisplayPaused(_INTL("Which move should be forgotten?"))
        forgetmove=@scene.pbForgetMove(pokemon,move)
        if forgetmove >=0
          oldmovename=getMoveName(pokemon.moves[forgetmove].move)
          pokemon.moves[forgetmove]=PBMove.new(move) # Replaces current/total PP
          battler.moves[forgetmove]=PokeBattle_Move.pbFromPBMove(self,pokemon.moves[forgetmove],battler) if battler
          if !(pokemon.zmoves.nil? || pokemon.item == :INTERCEPTZ)
            pokemon.updateZMoveIndex(forgetmove)
            updateZMoveIndexBattler(forgetmove,battler) if battler
          end
          pbDisplayPaused(_INTL("1,  2, and... ... ..."))
          pbDisplayPaused(_INTL("Poof!"))
          pbDisplayPaused(_INTL("{1} forgot {2}.",pkmnname,oldmovename))
          pbDisplayPaused(_INTL("And..."))
          pbDisplayPaused(_INTL("{1} learned {2}!",pkmnname,movename))
          return
        elsif pbDisplayConfirm(_INTL("Should {1} stop learning {2}?",pkmnname,movename))
          pbDisplayPaused(_INTL("{1} did not learn {2}.",pkmnname,movename))
          return
        end
      elsif pbDisplayConfirm(_INTL("Should {1} stop learning {2}?",pkmnname,movename))
        pbDisplayPaused(_INTL("{1} did not learn {2}.",pkmnname,movename))
        return
      end
    end
  end

  def updateZMoveIndexBattler(index,battler)
    zcrystal_to_type = PBStuff::TYPETOZCRYSTAL.invert
    if zcrystal_to_type[battler.item]
      if battler.moves[index].type != zcrystal_to_type[battler.item]
        battler.zmoves[index] = nil
      else
        zmove = battler.moves[index].category == :status ? PBMove.new(battler.moves[index].move) : PBMove.new(PBStuff::CRYSTALTOZMOVE[battler.item])
        battler.zmoves[index]=PokeBattle_Move.pbFromPBMove(self,zmove,battler,battler.moves[index])
      end
    elsif (PBStuff::MOVETOZCRYSTAL.invert)[battler.item]
      speciesblock = false
      case battler.item
      when :ALORAICHIUMZ then speciesblock=true if !(battler.species==:RAICHU && (battler.form==1))
      when :DECIDIUMZ then speciesblock=true if !(battler.species==:DECIDUEYE && (battler.form==0))
      when :INCINIUMZ then speciesblock=true if battler.species!=:INCINEROAR
      when :PRIMARIUMZ then speciesblock=true if battler.species!=:PRIMARINA
      when :EEVIUMZ then speciesblock=true if battler.species!=:EEVEE
      when :PIKANIUMZ then speciesblock=true if battler.species!=:PIKACHU
      when :SNORLIUMZ then speciesblock=true if battler.species!=:SNORLAX
      when :MEWNIUMZ then speciesblock=true if battler.species!=:MEW
      when :TAPUNIUMZ then speciesblock=true if !(battler.species==:TAPUKOKO || battler.species==:TAPULELE || battler.species==:TAPUFINI || battler.species==:TAPUBULU)
      when :MARSHADIUMZ then speciesblock=true if battler.species!=:MARSHADOW
      when :KOMMONIUMZ then speciesblock=true if battler.species!=:KOMMOO
      when :LYCANIUMZ then speciesblock=true if battler.species!=:LYCANROC
      when :MIMIKIUMZ then speciesblock=true if battler.species!=:MIMIKYU
      when :SOLGANIUMZ then speciesblock=true if !((battler.species==:NECROZMA && battler.form==1) || battler.species==:SOLGALEO)
      when :LUNALIUMZ then speciesblock=true if !((battler.species==:NECROZMA && battler.form==2) || battler.species==:LUNALA)
      when :ULTRANECROZIUMZ then speciesblock=true if !(battler.species==:NECROZMA && battler.form!=0)
      end
      if pokemon.item != PBStuff::MOVETOZCRYSTAL[battler.moves[index].move] || speciesblock
        battler.zmoves[index] = nil
      else
        zmove = PBMove.new(PBStuff::CRYSTALTOZMOVE[battler.item])
        battler.zmoves[index]=PokeBattle_Move.pbFromPBMove(self,zmove,battler,battler.moves[index])
      end
    end
  end

################################################################################
# Abilities.
################################################################################
  def pbOnActiveAll
    for i in 0...4 # Currently unfainted participants will earn EXP even if they faint afterwards
      @battlers[i].pbUpdateParticipants if pbIsOpposing?(i)
      @amuletcoin=true if !pbIsOpposing?(i) && ((@battlers[i].item == :AMULETCOIN) || (@battlers[i].item == :LUCKINCENSE))
    end

    # Weather-inducing abilities, Trace, Imposter, etc.
    @usepriority=false
    priority=pbPriority
    for i in priority
      pbOnActiveOne(i)  # might cause weird ability behaviour on first turn
      i.pbAbilitiesOnSwitchIn(true)
    end

    # Check forms are correct
    for i in 0...4
      next if @battlers[i].isFainted?
      @battlers[i].pbCheckForm
    end
    pbJudge
  end

  def pbOnActiveOne(pkmn,onlyabilities=false)
    return false if pkmn.isFainted?
    if !onlyabilities
      for i in 0...4 # Currently unfainted participants will earn EXP even if they faint afterwards
        @battlers[i].pbUpdateParticipants if pbIsOpposing?(i)
        @amuletcoin=true if !pbIsOpposing?(i) && ((@battlers[i].item == :AMULETCOIN) || (@battlers[i].item == :LUCKINCENSE))
      end
      # Chess Field piece boosts
      if @field.effect == :CHESS
        case pkmn.pokemon.piece
        when :PAWN
          pbDisplay(_INTL("{1} became a Pawn and stormed up the board!",pkmn.pbThis))
        when :KING
          pbDisplay(_INTL("{1} became a King and exposed itself!",pkmn.pbThis))
        when :KNIGHT
          pbDisplay(_INTL("{1} became a Knight and readied its position!",pkmn.pbThis)) #oo they shmovin' but i gotta change this im sry
        when :BISHOP
          pbDisplay(_INTL("{1} became a Bishop and took the diagonal!",pkmn.pbThis))
          if pkmn.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
            pkmn.pbIncreaseStat(PBStats::ATTACK,1)
          end
          if pkmn.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
            pkmn.pbIncreaseStat(PBStats::SPATK,1)
          end
        when :ROOK
          pbDisplay(_INTL("{1} became a Rook and took the open file!",pkmn.pbThis))
          if pkmn.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
            pkmn.pbIncreaseStat(PBStats::DEFENSE,1)
          end
          if pkmn.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
            pkmn.pbIncreaseStat(PBStats::SPDEF,1)
          end
        when :QUEEN
          pbDisplay(_INTL("{1} became a Queen and was placed on the center of the board!",pkmn.pbThis))
          if pkmn.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
            pkmn.pbIncreaseStat(PBStats::DEFENSE,1)
          end
          if pkmn.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
            pkmn.pbIncreaseStat(PBStats::SPDEF,1)
          end
          
        end
      elsif @field.effect == :CROWD
        scoreToCompare = $game_variables[:BattleDataArray].last().getScoreAndSide(pkmn)
        highestOpposingScore=[0,nil,""]
        for b in 0...@battlers.length
          battlerArray = $game_variables[:BattleDataArray].last().getScoreAndSide(@battlers[b])
          if (battlerArray[1]!=scoreToCompare[1] && (battlerArray[0].to_i > highestOpposingScore[0].to_i))
            highestOpposingScore = battlerArray
          end
        end
        oppScore = highestOpposingScore[0].to_i
        pkmn.tempBoosts=[]
        message = ""
        buffs =[] 
        if oppScore >=3
          $overscored=highestOpposingScore[2]
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::ATTACK,1)")
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::SPATK,1)")
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::SPEED,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::ATTACK,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::SPATK,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::SPEED,1)")
          message = _INTL("The crowd begins rooting for an underdog to take {1} down a peg!", highestOpposingScore[2])
        end
        if oppScore >=4
          $overscored=highestOpposingScore[2]
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::SPDEF,1)")
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::DEFENSE,1)")
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::SPEED,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::SPDEF,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::DEFENSE,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::SPEED,1)")
          message = _INTL("{1} has overstayed its welcome for the crowd!", highestOpposingScore[2])
        end
        if oppScore >=5
          $overscored=highestOpposingScore[2]
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::SPDEF,1)")
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::DEFENSE,1)")
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::SPEED,1)")
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::ATTACK,1)")
          buffs.push("pkmn.pbIncreaseStatBasic(PBStats::SPATK,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::ATTACK,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::SPATK,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::SPEED,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::DEFENSE,1)")
          pkmn.tempBoosts.push("self.pbReduceStatBasic(PBStats::SPDEF,1)")
          message = _INTL("\"DON'T GIVE UP NOW, {1}!!\"", scoreToCompare[2].upcase)
        end
        buffs.push("@battle.pbCommonAnimation(\"StatUp\",pkmn,nil)") if (buffs.length>0)
        for i in 0...buffs.length
          eval(buffs[i])
        end
        pbDisplay(message) if (message != "")
      end
      # Neutralizing Gas
      if pbCheckGlobalAbility(:NEUTRALIZINGGAS)
        pkmn.ability = nil if !(PBStuff::FIXEDABILITIES).include?(pkmn.ability) && pkmn.ability != :NEUTRALIZINGGAS
      end
      # Balloon
      if pkmn.hasWorkingItem(:AIRBALLOON)
        @battle.pbDisplay(_INTL("{1} is floating on its balloon!",pkmn.pbThis))
      end
      # Deep earth item entries
      if @battle.FE == :DEEPEARTH
        if pkmn.hasWorkingItem(:IRONBALL)
          pkmn.pbReduceStat(PBStats::SPEED,2)
        end
        if pkmn.hasWorkingItem(:MAGNET)
          pkmn.pbReduceStat(PBStats::SPEED,1,statmessage:false)
          pkmn.pbIncreaseStat(PBStats::SPATK,1,statmessage:false)
          @battle.pbDisplay(_INTL("{1}'s {2} is affected by the magnetic field!",pkmn.pbThis,getItemName(pkmn.item)))
        end
      end
      # Shadow Pokemon
      if pkmn.isShadow? && pbIsOpposing?(pkmn.index)
        pbCommonAnimation("Shadow",pkmn,nil)
        pbDisplay(_INTL("Oh!\nA Shadow Pokémon!"))
      end
      #Black Prism Rage
      if Rejuv 
        if pkmn.item == :BLKPRISM && !@battle.pbOwnedByPlayer?(pkmn.index)
          for stat in 1..5
            if !pkmn.pbTooHigh?(stat)
              pkmn.pbIncreaseStatBasic(stat,2)
            end
          end
          @battle.pbCommonAnimation("StatUp",pkmn,nil)
          @battle.pbDisplay(_INTL("{1} is in a wild rage!", pkmn.pokemon.name))
        end
      end
      # Healing Wish
      if pkmn.effects[:HealingWish]
        pkmn.pbRecoverHP(pkmn.totalhp,true)
        pkmn.status=nil
        pkmn.statusCount=0
        if @field.effect == :FAIRYTALE || @field.effect == :STARLIGHT
          pkmn.pbIncreaseStat(PBStats::ATTACK, 1)
          pkmn.pbIncreaseStat(PBStats::SPATK, 1)
        end
        pbDisplay(_INTL("The healing wish came true for {1}!",pkmn.pbThis(true)))
        pkmn.effects[:HealingWish]=false
      end
      # Lunar Dance
      if pkmn.effects[:LunarDance]
        pkmn.pbRecoverHP(pkmn.totalhp,true)
        pkmn.status=nil
        pkmn.statusCount=0
        if @field.effect == :STARLIGHT || @field.effect == :NEWWORLD ||@field.effect == :DANCEFLOOR
          stats = [PBStats::ATTACK,PBStats::SPATK] if @field.effect == :STARLIGHT
          stats = *(1..5) if @field.effect == :NEWWORLD || @field.effect == :DANCEFLOOR
          for stat in stats
            pkmn.pbIncreaseStat(stat, 1)
          end
        end
        for i in 0...4
          pkmn.moves[i].pp=pkmn.moves[i].totalpp
        end
        pbDisplay(_INTL("{1} became cloaked in mystical moonlight!",pkmn.pbThis))
        pkmn.effects[:LunarDance]=false
      end
      # Z-Memento/Parting Shot
      if pkmn.effects[:ZHeal]
        pkmn.pbRecoverHP(pkmn.totalhp,false)
        pbDisplay(_INTL("The Z-Power healed {1}!",pkmn.pbThis(true)))
        pkmn.effects[:ZHeal]=false
      end
      # Spikes
      pkmn.pbOwnSide.effects[:Spikes]=0 if @field.effect == :WATERSURFACE || @field.effect == :MURKWATERSURFACE || @field.effect == :SKY || @field.effect == :CLOUDS
      if pkmn.pbOwnSide.effects[:Spikes]>0
        if (!pkmn.isAirborne? || (Rejuv && @battle.FE == :ELECTERRAIN)) && !pkmn.hasWorkingItem(:HEAVYDUTYBOOTS)
          if pkmn.ability != :MAGICGUARD && !(pkmn.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM)
            spikesdiv=[8,8,6,4][pkmn.pbOwnSide.effects[:Spikes]]
            if Rejuv && @battle.FE == :ELECTERRAIN
              atype = :ELECTRIC
              eff=PBTypes.twoTypeEff(atype,pkmn.type1,pkmn.type2)
              if eff>0
                @scene.pbDamageAnimation(pkmn,0)
                pkmn.pbReduceHP([((pkmn.totalhp*eff)/(4*spikesdiv)).floor,1].max)
                pbDisplay(_INTL("{1} was hurt by electrified Spikes!",pkmn.pbThis))
              end
            else
              @scene.pbDamageAnimation(pkmn,0)
              pkmn.pbReduceHP([(pkmn.totalhp.to_f/spikesdiv).floor,1].max)
              pbDisplay(_INTL("{1} was hurt by Spikes!",pkmn.pbThis))
            end
          end
        end
      end
      if pkmn.isFainted?
        pkmn.pbFaint
        pkmn.pbOwnSide.effects[:Retaliate] = true
        if !@midturn
          pbGainEXP
          10.times do
            pbSwitch(false,true)
          end
          return if @decision>0
          priority=pbPriority
          for i in priority
            next if i.isFainted?
            i.pbAbilitiesOnSwitchIn(false)
          end
        else
          pbJudge
          return if @decision>0
        end
        return
      end
      # Stealth Rock
      if pkmn.pbOwnSide.effects[:StealthRock]
        if pkmn.ability != :MAGICGUARD && !(pkmn.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && !pkmn.hasWorkingItem(:HEAVYDUTYBOOTS)
          atype = :ROCK
          atype = @field.getRoll if @field.effect == :CRYSTALCAVERN
          atype = :FIRE if @field.effect == :VOLCANICTOP || @field.effect == :INFERNAL || (Rejuv && @field.effect == :DRAGONSDEN)
          atype = :POISON if @field.effect == :CORRUPTED
          eff=PBTypes.twoTypeEff(atype,pkmn.type1,pkmn.type2)
          if @field.effect == :INVERSE
            switcheff = { 16 => 1, 8 => 2, 4 => 4, 2 => 8, 1 => 16, 0 => 16}
            eff = switcheff[eff]
          end
          if eff>0
            if @field.effect == :ROCKY || @field.effect == :CAVE
              eff = eff*2
            end
            @scene.pbDamageAnimation(pkmn,0)
            pkmn.pbReduceHP([(pkmn.totalhp*eff/32).floor,1].max)
            if @field.effect == :CRYSTALCAVERN
              pbDisplay(_INTL("{1} was hurt by the crystalized stealth rocks!",pkmn.pbThis))
            elsif @field.effect == :VOLCANICTOP || @field.effect == :INFERNAL || (Rejuv && @field.effect == :DRAGONSDEN)
              pbDisplay(_INTL("{1} was hurt by the molten stealth rocks!",pkmn.pbThis))
            elsif @field.effect == :CORRUPTED
              pbDisplay(_INTL("{1} was hurt by the corrupted stealth rocks!",pkmn.pbThis))
            else
              pbDisplay(_INTL("{1} was hurt by Stealth Rocks!",pkmn.pbThis))
            end
          end
        end
      end
      if pkmn.pbOwnSide.effects[:Steelsurge]
        if pkmn.ability != :MAGICGUARD && !(pkmn.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && !pkmn.hasWorkingItem(:HEAVYDUTYBOOTS)
          atype = :STEEL
          # @SWu to figure out alternate field interactions
          eff=PBTypes.twoTypeEff(atype,pkmn.type1,pkmn.type2)
          if @field.effect == :INVERSE
            switcheff = { 16 => 1, 8 => 2, 4 => 4, 2 => 8, 1 => 16, 0 => 16}
            eff = switcheff[eff]
          end
          if eff>0
            @scene.pbDamageAnimation(pkmn,0)
            pkmn.pbReduceHP([(pkmn.totalhp*eff/32).floor,1].max)
          end
          pbDisplay(_INTL("{1} was hurt by metal debris!",pkmn.pbThis))
        end
      end
      if pkmn.pbOwnSide.effects[:Volcalith]
        if pkmn.ability != :MAGICGUARD && !(pkmn.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && !pkmn.hasWorkingItem(:HEAVYDUTYBOOTS)
          atype = :FIRE
          # @SWu to figure out alternate field interactions
          eff=PBTypes.twoTypeEff(atype,pkmn.type1,pkmn.type2)
          if @field.effect == :INVERSE
            switcheff = { 16 => 1, 8 => 2, 4 => 4, 2 => 8, 1 => 16, 0 => 16}
            eff = switcheff[eff]
          end
          if eff>0
            @scene.pbDamageAnimation(pkmn,0)
            pkmn.pbReduceHP([(pkmn.totalhp*eff/32).floor,1].max)
          end
          pbDisplay(_INTL("{1} was hurt by the molten rocks!",pkmn.pbThis))
        end
      end
      if pkmn.isFainted?
        pkmn.pbFaint
        pkmn.pbOwnSide.effects[:Retaliate] = true
        if !@midturn
          pbGainEXP
          10.times do
            pbSwitch(false,true)
          end
          return if @decision>0
          priority=pbPriority
          for i in priority
            next if i.isFainted?
            i.pbAbilitiesOnSwitchIn(false)
          end
        else
          pbJudge
          return if @decision>0
        end
        return
      end
      # Corrosive Field Entry
      if @field.effect == :CORROSIVE
        if !(pkmn.ability == :MAGICGUARD || pkmn.ability == :POISONHEAL || pkmn.ability == :IMMUNITY || pkmn.ability == :WONDERGUARD || 
            pkmn.ability == :TOXICBOOST || pkmn.ability == :PASTELVEIL) && !pkmn.isAirborne? && !pkmn.hasType?(:POISON) && !pkmn.hasType?(:STEEL) && pkmn.crested != :ZANGOOSE && pkmn.crested != :GOODRA && !(pkmn.isbossmon && pkmn.immunities[:fieldEffectDamage].include?(@field.effect))
          atype = :POISON
          eff=PBTypes.twoTypeEff(atype,pkmn.type1,pkmn.type2)
          if eff>0
            eff=eff*2
            @scene.pbDamageAnimation(pkmn,0)
            pkmn.pbReduceHP([(pkmn.totalhp*eff/32).floor,1].max)
            pbDisplay(_INTL("{1} was seared by the corrosion!",pkmn.pbThis))
          end
        end
      end
      if ProgressiveFieldCheck(PBFields::CONCERT,3,4)
        if (pkmn.status == :SLEEP || pkmn.ability == :COMATOSE)
          pkmn.status=nil if pkmn.status == :SLEEP
          pkmn.ability=nil if pkmn.ability == :COMATOSE
          pkmn.pbReduceHP(pkmn.totalhp/4)
          pbDisplay(_INTL("The Concert's noise could wake up even the dead!"))
        end
      end
      if pkmn.isFainted?
        pkmn.pbFaint
        pkmn.pbOwnSide.effects[:Retaliate] = true
        if !@midturn
          pbGainEXP
          10.times do
            pbSwitch(false,true)
          end
          return if @decision>0
          priority=pbPriority
          for i in priority
            next if i.isFainted?
            i.pbAbilitiesOnSwitchIn(false)
          end
        else
          pbJudge
          return if @decision>0
        end
        return
      end
      # Sticky Web
      pkmn.pbOwnSide.effects[:StickyWeb]=false if @field.effect == :SKY || @field.effect == :CLOUDS
      if pkmn.pbOwnSide.effects[:StickyWeb]
        if !pkmn.isAirborne? && !pkmn.hasWorkingItem(:HEAVYDUTYBOOTS)
          stat = @field.effect == :FOREST ? 2 : 1
          pbDisplay(_INTL("{1} was caught in a sticky web!",pkmn.pbThis))
          pkmn.pbReduceStat(PBStats::SPEED, stat)
        end
      end
      # Toxic Spikes
      pkmn.pbOwnSide.effects[:ToxicSpikes]=0 if @field.effect == :WATERSURFACE || @field.effect == :MURKWATERSURFACE || @field.effect == :SKY || @field.effect == :CLOUDS
      if pkmn.pbOwnSide.effects[:ToxicSpikes]>0 && !pkmn.isAirborne?
        if pkmn.hasType?(:POISON) && @field.effect != :CORROSIVE
          pkmn.pbOwnSide.effects[:ToxicSpikes]=0
          pbDisplay(_INTL("{1} absorbed the poison spikes!",pkmn.pbThis))
        elsif pkmn.pbCanPoisonSpikes?(true) && !pkmn.hasWorkingItem(:HEAVYDUTYBOOTS)
          if pkmn.pbOwnSide.effects[:ToxicSpikes]==2
            pkmn.pbPoison(pkmn,true)
            pbDisplay(_INTL("{1} was badly poisoned!",pkmn.pbThis))
          else
            pkmn.pbPoison(pkmn)
            pbDisplay(_INTL("{1} was poisoned!",pkmn.pbThis))
          end
        end
      end
    end
    if pkmn.status == :PETRIFIED
      pkmn.effects[:Petrification]=pkmn.pbOppositeOpposing.index
    end
    pkmn.pbAbilityCureCheck
    if !onlyabilities
      pkmn.pbCheckForm
      pkmn.pbBerryCureCheck
    end
    #Emergency exit caused by taking damage
    if pkmn.userSwitch
      pkmn.userSwitch = false
      pbDisplay(_INTL("{1} went back to {2}!",pkmn.pbThis,pbGetOwner(pkmn.index).name))
      newpoke=0
      newpoke=pbSwitchInBetween(pkmn.index,true,false)
      pbMessagesOnReplace(pkmn.index,newpoke)
      pkmn.vanished=false
      pkmn.pbResetForm
      pbReplace(pkmn.index,newpoke,false)
      pbOnActiveOne(pkmn)
      pkmn.pbAbilitiesOnSwitchIn(true)
    end
    runtrainerskills(pkmn) if Rejuv
    return true
  end

################################################################################
# Judging.
################################################################################
  def pbJudgeCheckpoint(attacker,move=0)
  end

  def pbDecisionOnTime
    count1=0
    count2=0
    hptotal1=0
    hptotal2=0
    for i in @party1
      next if !i
      if i.hp>0 && !i.isEgg?
        count1+=1
        hptotal1+=i.hp
      end
    end
    for i in @party2
      next if !i
      if i.hp>0 && !i.isEgg?
        count2+=1
        hptotal2+=i.hp
      end
    end
    return 1 if count1>count2     # win
    return 2 if count1<count2     # loss
    return 1 if hptotal1>hptotal2 # win
    return 2 if hptotal1<hptotal2 # loss
    return 5                      # draw
  end

  def pbDecisionOnTime2
    count1=0
    count2=0
    hptotal1=0
    hptotal2=0
    for i in @party1
      next if !i
      if i.hp>0 && !i.isEgg?
        count1+=1
        hptotal1+=(i.hp*100/i.totalhp)
      end
    end
    hptotal1/=count1 if count1>0
    for i in @party2
      next if !i
      if i.hp>0 && !i.isEgg?
        count2+=1
        hptotal2+=(i.hp*100/i.totalhp)
      end
    end
    hptotal2/=count2 if count2>0
    return 1 if count1>count2     # win
    return 2 if count1<count2     # loss
    return 1 if hptotal1>hptotal2 # win
    return 2 if hptotal1<hptotal2 # loss
    return 5                      # draw
  end

  def pbDecisionOnDraw
    return 5 # draw
  end

  def pbJudge
#   PBDebug.log("[Counts: #{pbPokemonCount(@party1)}/#{pbPokemonCount(@party2)}]")
    if pbAllFainted?(@party1) && pbAllFainted?(@party2)
      @decision=pbDecisionOnDraw() # Draw
      return
    end
    if pbAllFainted?(@party1)
      @decision=2 # Loss
      return
    end
    if pbAllFainted?(@party2)
      @decision=1 # Win
      return
    end
  end

################################################################################
# Messages and animations.
################################################################################
  def pbApplySceneBG(sprite,filename)
    @scene.pbApplyBGSprite(sprite,filename)
  end

  def pbDisplay(msg)
    @scene.pbDisplayMessage(msg)
  end

  def pbDisplayPaused(msg)
    @scene.pbDisplayPausedMessage(msg)
  end

  def pbDisplayBrief(msg)
    @scene.pbDisplayMessage(msg,true)
  end

  def pbDisplayConfirm(msg)
    @scene.pbDisplayConfirmMessage(msg)
  end

  def pbShowCommands(msg,commands,cancancel=true)
    @scene.pbShowCommands(msg,commands,cancancel)
  end

  def pbAnimation(moveid,attacker,opponent,hitnum=0)
    if @battlescene || moveid==:SUBSTITUTE
      @scene.pbAnimation(moveid,attacker,opponent,hitnum)
    end
  end

  def pbCommonAnimation(name,attacker=nil,opponent=nil,hitnum=0)
    if @battlescene
      @scene.pbCommonAnimation(name,attacker,opponent,hitnum)
    end
  end

  def pbChangeBGSprite
    filename = @field.backdrop
    path = "Graphics/Battlebacks/battlebg" + filename + ".png"
    pbApplySceneBG("battlebg",path)
    path = "Graphics/Battlebacks/playerbase" + filename + ".png"
    path = "Graphics/Battlebacks/playerbaseDummy" if !pbResolveBitmap(sprintf(path))
    pbApplySceneBG("playerbase",path)
    path = "Graphics/Battlebacks/enemybase" + filename + ".png"
    path = "Graphics/Battlebacks/enemybaseDummy" if !pbResolveBitmap(sprintf(path))
    pbApplySceneBG("enemybase",path)
  end

################################################################################
# Battle core.
################################################################################
  def pbStartBattle(canlose=false)
    if !@fullparty1 && @party1.length>MAXPARTYSIZE
      raise ArgumentError.new(_INTL("Party 1 has more than {1} Pokémon.",MAXPARTYSIZE))
    end
    if !@fullparty2 && @party2.length>MAXPARTYSIZE2
      raise ArgumentError.new(_INTL("Party 2 has more than {1} Pokémon.",MAXPARTYSIZE2))
    end
    #========================
    # Initialize AI in battle 
    #========================
    if !isOnline?
      @ai = PokeBattle_AI.new(self) 
      $ai_log_data = [PokeBattle_AI_Info.new,PokeBattle_AI_Info.new,PokeBattle_AI_Info.new,PokeBattle_AI_Info.new]
    end
    if !@opponent
      #========================
      # Initialize wild Pokémon
      #========================
      if @party2.length==1
        wildpoke=@party2[0]
        @battlers[1].pbInitialize(wildpoke,0,false)
        @peer.pbOnEnteringBattle(self,wildpoke)
        $Trainer.pokedex.setSeen(wildpoke)
        @scene.pbStartBattle(self)
        if !@battlers[1].isbossmon
          pbDisplayPaused(_INTL("A wild {1} appeared!",wildpoke.name)) 
        else
          if @battlers[1].entryText != nil
            pbDisplayPaused(_INTL(@battlers[1].entryText))
          else
            pbDisplayPaused(_INTL("A wild {1} appeared!",wildpoke.name)) 
          end
        end 
      elsif @party2.length==2
        @battlers[1].pbInitialize(@party2[0],0,false)
        @battlers[3].pbInitialize(@party2[1],0,false)

        @peer.pbOnEnteringBattle(self,@party2[0])
        @peer.pbOnEnteringBattle(self,@party2[1])
        $Trainer.pokedex.setSeen(@party2[0])
        $Trainer.pokedex.setSeen(@party2[1])
        @scene.pbStartBattle(self)
        pbDisplayPaused(_INTL("A wild {1} and\r\n{2} appeared!",
           @party2[0].name,@party2[1].name))
      else
        raise _INTL("Only one or two wild Pokémon are allowed")
      end
    elsif @doublebattle
      #=======================================
      # Initialize opponents in double battles
      #=======================================
      if @opponent.is_a?(Array)
        if @opponent.length==1
          @opponent=@opponent[0]
        elsif @opponent.length!=2
          raise _INTL("Opponents with zero or more than two people are not allowed")
        end
      end
      if @player.is_a?(Array)
        if @player.length==1
          @player=@player[0]
        elsif @player.length!=2
          raise _INTL("Player trainers with zero or more than two people are not allowed")
        end
      end
      @scene.pbStartBattle(self)
      if @opponent.is_a?(Array)
        pbDisplayPaused(_INTL("{1} and {2} want to battle!",@opponent[0].fullname,@opponent[1].fullname))
        sendout1=pbFindNextUnfainted(@party2,0,pbSecondPartyBegin(1))
        raise _INTL("Opponent 1 has no unfainted Pokémon") if sendout1<0
        sendout2=pbFindNextUnfainted(@party2,pbSecondPartyBegin(1))
        raise _INTL("Opponent 2 has no unfainted Pokémon") if sendout2<0
        @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
        @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
        leadname = pbSwitchInName(1,sendout1) #Illusion
        pbDisplayBrief(_INTL("{1} sent\r\nout {2}!",@opponent[0].fullname,leadname)) 
        pbSendOut(1,@party2[sendout1])
        leadname = pbSwitchInName(3,sendout2) #Illusion
        pbDisplayBrief(_INTL("{1} sent\r\nout {2}!",@opponent[1].fullname,leadname)) 
        pbSendOut(3,@party2[sendout2])
      else
        pbDisplayPaused(_INTL("{1}\r\nwould like to battle!",@opponent.fullname))
        sendout1=pbFindNextUnfainted(@party2,0)
        sendout2=pbFindNextUnfainted(@party2,sendout1+1)
        if sendout1<0 || sendout2<0
          #raise _INTL("Opponent doesn't have two unfainted Pokémon")
          sendout2 = nil
          leadname = pbSwitchInName(1,sendout1) #Illusion
          pbDisplayBrief(_INTL("{1} sent\r\nout {2}!",@opponent.fullname,leadname))
          @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
          pbSendOut(1,@party2[sendout1])
        else
          @battlers[1].pbInitialize(@party2[sendout1],sendout1,false) 
          @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
          leadname1 = pbSwitchInName(1,sendout1) #Illusion
          leadname2 = pbSwitchInName(3,sendout2) #Illusion
          pbDisplayBrief(_INTL("{1} sent\r\nout {2} and {3}!", @opponent.fullname,leadname1,leadname2)) 
          pbSendOut(1,@party2[sendout1])
          pbSendOut(3,@party2[sendout2])
        end
      end
    else
      #======================================
      # Initialize opponent in single battles
      #======================================
      sendout=pbFindNextUnfainted(@party2,0)
      raise _INTL("Trainer has no unfainted Pokémon") if sendout<0
      if @opponent.is_a?(Array)
        raise _INTL("Opponent trainer must be only one person in single battles") if @opponent.length!=1
        @opponent=@opponent[0]
      end
      if @player.is_a?(Array)
        raise _INTL("Player trainer must be only one person in single battles") if @player.length!=1
        @player=@player[0]
      end
      trainerpoke=@party2[sendout]
      @scene.pbStartBattle(self)
      pbDisplayPaused(_INTL("{1}\r\nwould like to battle!",@opponent.fullname))

      @battlers[1].pbInitialize(trainerpoke,sendout,false) 
      leadname = pbSwitchInName(1,sendout) #Illusion
      pbDisplayBrief(_INTL("{1} sent\r\nout {2}!",@opponent.fullname,leadname))

      pbSendOut(1,trainerpoke)
    end
    #=====================================
    # Initialize players in double battles
    #=====================================
    if @doublebattle
      if @player.is_a?(Array)
        sendout1=pbFindNextUnfainted(@party1,0,pbSecondPartyBegin(0))
        raise _INTL("Player 1 has no unfainted Pokémon") if sendout1<0
        sendout2=pbFindNextUnfainted(@party1,pbSecondPartyBegin(0))
        raise _INTL("Player 2 has no unfainted Pokémon") if sendout2<0
        @battlers[0].pbInitialize(@party1[sendout1],sendout1,false) 
        @battlers[2].pbInitialize(@party1[sendout2],sendout2,false)
        leadname1 = pbSwitchInName(0,sendout1) #Illusion
        leadname2 = pbSwitchInName(2,sendout2) #Illusion
        pbDisplayBrief(_INTL("{1} sent\r\nout {2}! Go! {3}!", @player[1].fullname,leadname2,leadname1))
        $Trainer.pokedex.setSeen(@party1[sendout1])
        $Trainer.pokedex.setSeen(@party1[sendout2])
      else
        sendout1=pbFindNextUnfainted(@party1,0)
        sendout2=pbFindNextUnfainted(@party1,sendout1+1)
        @battlers[0].pbInitialize(@party1[sendout1],sendout1,false) 
        @battlers[2].pbInitialize(@party1[sendout2],sendout2,false) unless sendout2==-1
        if sendout2>-1
          leadname1 = pbSwitchInName(0,sendout1) #Illusion
          leadname2 = pbSwitchInName(2,sendout2) #Illusion
          pbDisplayPaused(_INTL("Go! {1} and {2}!",leadname1,leadname2)) 
        else
          leadname = pbSwitchInName(0,sendout1) #Illusion
          pbDisplayPaused(_INTL("Go! {1}!",leadname)) 
        end
      end
      pbSendOut(0,@party1[sendout1])
      pbSendOut(2,@party1[sendout2]) unless sendout2==-1
    else
      #====================================
      # Initialize player in single battles
      #====================================
      sendout=pbFindNextUnfainted(@party1,0)
      if sendout<0
        raise _INTL("Player has no unfainted Pokémon")
      end
      playerpoke=@party1[sendout]
      @battlers[0].pbInitialize(playerpoke,sendout,false) 
      leadname = pbSwitchInName(0,sendout) #Illusion
      pbDisplayBrief(_INTL("Go! {1}!",leadname))
      pbSendOut(0,playerpoke)
    end
    #=======================================================
    # Keep track of who fainted in battle + piece assignment
    #=======================================================
    @fainted_mons = Array.new($Trainer.party.length) {|i| $Trainer.party[i].hp > 0 ? false : true}
    if @doublebattle
      if @player.is_a?(Array)
        pieceAssignment(pbPartySingleOwner(0),true)
        pieceAssignment(pbPartySingleOwner(2),true)
      else
        pieceAssignment(@party1,false)
      end
      if @opponent.is_a?(Array)
        pieceAssignment(pbPartySingleOwner(1),true)
        pieceAssignment(pbPartySingleOwner(3),true)
      else
        pieceAssignment(@party2,false)
      end
    else
      pieceAssignment(@party1,false)
      pieceAssignment(@party2,false)
    end
    
    #==================
    # Initialize battle
    #==================
    noWeather
    if @weather== :SUNNYDAY
      pbCommonAnimation("Sunny")
      pbDisplay(_INTL("The sunlight is strong."))
      #### DemICE - persistentweather - START
      @weatherbackup=:SUNNYDAY
      @weatherbackupanim="Sunny"
      #### DemICE
    elsif @weather== :RAINDANCE
      pbCommonAnimation("Rain")
      pbDisplay(_INTL("It is raining."))
      #### DemICE - persistentweather - START
      @weatherbackup=:RAINDANCE
      @weatherbackupanim="Rain"
      #### DemICE
    elsif @weather== :SANDSTORM
      pbCommonAnimation("Sandstorm")
      pbDisplay(_INTL("A sandstorm is raging."))
      #### DemICE - persistentweather - START
      @weatherbackup=:SANDSTORM
      @weatherbackupanim="Sandstorm"
      #### DemICE
    elsif @weather== :HAIL
      pbCommonAnimation("Hail")
      pbDisplay(_INTL("Hail is falling."))
      #### DemICE - persistentweather - START
      @weatherbackup=:HAIL
      @weatherbackupanim="Hail"
      #### DemICE
    elsif @weather== :STRONGWINDS
      pbCommonAnimation("Wind")
      pbDisplay(_INTL("The wind is strong."))
      #### DemICE - persistentweather - START
      @weatherbackup=:STRONGWINDS
      @weatherbackupanim="Wind"
      #### DemICE
    elsif @weather== :SHADOWSKY
      pbCommonAnimation("ShadowSky")
      pbDisplay(_INTL("The sky is dark."))
      #### DemICE - persistentweather - START
      @weatherbackup=:SHADOWSKY
      @weatherbackupanim="ShadowSky"
      #### DemICE
    end
    # Field Effects BEGIN UPDATE
    if @field.introMessage
      fieldmessage = @field.introMessage
      fieldmessage = ["The dawn of a New World shines down upon the broken land."] if pbCheckGlobalAbility(:WORLDOFNIGHTMARES) && @field.effect == :STARLIGHT
      for i in 0...fieldmessage.length do
        pbDisplay(_INTL(fieldmessage[i]))
      end
      @state.effects[:Gravity]=-1 if @field.effect == :DEEPEARTH
      $game_variables[:Cave_Collapse] = 0
    end
    # END OF UPDATE
    priority=pbPriority
    if Rejuv
      for i in priority
        next if !i.isbossmon
        pbShieldEffects(i,i.onEntryEffects,true) if i.onEntryEffects 
      end
    end
    for i in priority # Pre-surge seed check
      seedCheck
    end
    pbOnActiveAll   # Abilities
    for i in priority # Post-surge seed check
      seedCheck
    end
    @turncount=1
    if !isOnline? #for subclassing- online processing continues separately
      loop do   # Now begin the battle loop
        fakeOutBattleEnd if Rejuv && @decision==1
        break if @decision>0
        PBDebug.log("************************** Round #{@turncount} *******************************") if $INTERNAL

        PBDebug.logonerr{
          pbCommandPhase
        }
        fakeOutBattleEnd if Rejuv && @decision==1
        break if @decision>0

        PBDebug.logonerr{
          @midturn=true
          pbAttackPhase()
          @midturn=false
        }
        fakeOutBattleEnd if Rejuv && @decision==1
        break if @decision>0

        PBDebug.logonerr{
          pbEndOfRoundPhase
        }
        fakeOutBattleEnd if Rejuv && @decision==1
        break if @decision>0
        @turncount+=1
      end
      return pbEndOfBattle(canlose)
    end
  end

################################################################################
# Command phase.
################################################################################
  def pbCommandMenu(i)
    return @scene.pbCommandMenu(i)
  end

  def pbItemMenu(i)
    return @scene.pbItemMenu(i)
  end

  def pbAutoFightMenu(i)
    return false
  end

  def pbCommandPhase(delay=true)
    pbAceMessage() if @ace_message && !@ace_message_handled && Reborn
    delayedaction if Rejuv && delay == true
    @scene.pbBeginCommandPhase
    @scene.pbResetCommandIndices if $Settings.remember_commands==0 
    for i in 0...4   # Reset choices if commands can be shown
      if pbCanShowCommands?(i) || @battlers[i].isFainted?
        @choices[i][0]=0
        @choices[i][1]=0
        @choices[i][2]=nil
        @choices[i][3]=-1
      else
        battler=@battlers[i]
        unless !@doublebattle && pbIsDoubleBattler?(i)
          PBDebug.log("[reusing commands for #{battler.pbThis(true)}]") if $INTERNAL
        end
      end
    end
    for i in 0..3
      @switchedOut[i] = false
    end
    # Reset choices to perform Mega Evolution/Z-Moves/Ultra Burst if it wasn't done somehow
    for i in 0...@megaEvolution[0].length
      @megaEvolution[0][i]=-1 if @megaEvolution[0][i]>=0
    end
    for i in 0...@megaEvolution[1].length
      @megaEvolution[1][i]=-1 if @megaEvolution[1][i]>=0
    end
    for i in 0...@gigaEvolution[0].length
      @gigaEvolution[0][i]=-1 if @gigaEvolution[0][i]>=0
    end
    for i in 0...@gigaEvolution[1].length
      @gigaEvolution[1][i]=-1 if @gigaEvolution[1][i]>=0
    end
    for i in 0...@ultraBurst[0].length
      @ultraBurst[0][i]=-1 if @ultraBurst[0][i]>=0
    end
    for i in 0...@ultraBurst[1].length
      @ultraBurst[1][i]=-1 if @ultraBurst[1][i]>=0
    end
    for i in 0...@zMove[0].length
      @zMove[0][i]=-1 if @zMove[0][i]>=0
    end
    for i in 0...@zMove[1].length
      @zMove[1][i]=-1 if @zMove[1][i]>=0
    end
    pbJudge #juuuust in case we don't want to be here
    return if @decision>0
    @commandphase=true
    for i in 0...4
      break if @decision!=0
      next if @choices[i][0]!=0
      #AI CHANGES
      if !pbOwnedByPlayer?(i) || @controlPlayer || @battlers[i].issossmon
        next
      end
      commandDone=false
      commandEnd=false
      if pbCanShowCommands?(i)
        loop do
          cmd=pbCommandMenu(i)
          if cmd==0 # Fight
            if pbCanShowFightMenu?(i)
              commandDone=true if pbAutoFightMenu(i)
              until commandDone
                index=@scene.pbFightMenu(i)
                if index<0
                  side=(pbIsOpposing?(i)) ? 1 : 0
                  owner=pbGetOwnerIndex(i)
                  if @megaEvolution[side][owner]==i
                    @megaEvolution[side][owner]=-1
                  end
                  if @gigaEvolution[side][owner]==i
                    @gigaEvolution[side][owner]=-1
                  end
                  if @ultraBurst[side][owner]==i
                    @ultraBurst[side][owner]=-1
                  end
                  if @zMove[side][owner]==i
                    @zMove[side][owner]=-1
                  end
                  break
                end
                if !pbRegisterMove(i,index)
                  @zMove[0][0]=-1 if @zMove[0][0]>=0
                  @zMove[1][0]=-1 if @zMove[1][0]>=0
                  next
                end
                if @doublebattle
                  side=(pbIsOpposing?(i)) ? 1 : 0
                  owner=pbGetOwnerIndex(i)
                  basemove= @zMove[side][owner]==i ? basemove=@battlers[i].zmoves[index] : basemove=@battlers[i].moves[index]
                  target=@battlers[i].pbTarget(basemove)
                  if target==:SingleNonUser # single non-user
                    target=@scene.pbChooseTarget(i)
                    if target<0
                      @zMove[0][0]=-1 if @zMove[0][0]>=0
                      @zMove[1][0]=-1 if @zMove[1][0]>=0
                      next
                    end
                    pbRegisterTarget(i,target)
                  elsif target==:UserOrPartner # Acupressure
                    target=@scene.pbChooseTargetAcupressure(i)
                    if target<0 || (target&1)!=(i&1)
                      @zMove[0][0]=-1 if @zMove[0][0]>=0
                      @zMove[1][0]=-1 if @zMove[1][0]>=0
                      next
                    end
                    pbRegisterTarget(i,target)
                  end
                end
                commandDone=true
              end
            else
              commandDone=pbAutoChooseMove(i)
            end
          elsif cmd==1 # Bag
            if !@internalbattle
              if pbOwnedByPlayer?(i)
                pbDisplay(_INTL("Items can't be used here."))
              end
            elsif @battlers[i].effects[:SkyDrop]
              pbDisplay(_INTL("Sky Drop won't let {1} go!",@battlers[i].name))
            else
              item=pbItemMenu(i)
              if item[0]
                if pbRegisterItem(i,item[0],item[1])
                  commandDone=true
                end
              end
            end
          elsif cmd==2 # Pokémon
            pkmn=pbSwitchPlayer(i,false,true)
            if pkmn>=0
              commandDone=true if pbRegisterSwitch(i,pkmn)
            end
          elsif cmd==3   # Run
            run=pbRun(i)
            if run>0
              commandDone=true
              return
            elsif run<0
              commandDone=true
              side=(pbIsOpposing?(i)) ? 1 : 0
              owner=pbGetOwnerIndex(i)
              if @megaEvolution[side][owner]==i
                @megaEvolution[side][owner]=-1
              end
              if @gigaEvolution[side][owner]==i
                @gigaEvolution[side][owner]=-1
              end
              if @ultraBurst[side][owner]==i
                @ultraBurst[side][owner]=-1
              end
              if @zMove[side][owner]==i
                @zMove[side][owner]=-1
              end
            end
          elsif cmd==4   # Call
            thispkmn=@battlers[i]
            @choices[i][0]=4   # "Call Pokémon"
            @choices[i][1]=0
            @choices[i][2]=nil
            side=(pbIsOpposing?(i)) ? 1 : 0
            owner=pbGetOwnerIndex(i)
            if @megaEvolution[side][owner]==i
              @megaEvolution[side][owner]=-1
            end
            if @gigaEvolution[side][owner]==i
              @gigaEvolution[side][owner]=-1
            end
            if @ultraBurst[side][owner]==i
              @ultraBurst[side][owner]=-1
            end
            if @zMove[side][owner]==i
              @zMove[side][owner]=-1
            end
            commandDone=true
          elsif cmd==-1   # Go back to first battler's choice
            @megaEvolution[0][0]=-1 if @megaEvolution[0][0]>=0
            @megaEvolution[1][0]=-1 if @megaEvolution[1][0]>=0
            @gigaEvolution[0][0]=-1 if @gigaEvolution[0][0]>=0
            @gigaEvolution[1][0]=-1 if @gigaEvolution[1][0]>=0
            @ultraBurst[0][0]=-1 if @ultraBurst[0][0]>=0
            @ultraBurst[1][0]=-1 if @ultraBurst[1][0]>=0
            @zMove[0][0]=-1 if @zMove[0][0]>=0
            @zMove[1][0]=-1 if @zMove[1][0]>=0
            # Restore the item the player's first Pokémon was due to use
            if @choices[0][0]==3 && $PokemonBag && $PokemonBag.pbCanStore?(@choices[0][1])
              $PokemonBag.pbStoreItem(@choices[0][1])
            end
            pbCommandPhase(false)
            return
          end
          break if commandDone
        end
      end
    end
    @scene.pbChooseEnemyCommand if !isOnline?
    #AI Data collection perry
    for i in 0...4
      $ai_log_data[i].logAIScorings() if !isOnline? && @battlers[i].hp > 0 && !pbOwnedByPlayer?(i)
    end
    if $game_variables[:LuckShinies] != 0
      for battler in @battlers
        if self.pbIsWild? && [1,3].include?(battler.index) && !battler.isFainted? && battler.pokemon.isShiny? && !battler.isbossmon && !battler.issossmon && !@decision==4
          if pbRandom(100)<10
            pbSEPlay("escape",100)
            pbDisplay(_INTL("{1} fled!",battler.name))
            @decision=3
            PBDebug.log("Wild Pokemon Escaped") if $INTERNAL
          end
        end
      end
    end
    @commandphase=false
  end

################################################################################
# Attack phase.
################################################################################
  def pbAttackPhase
    @scene.pbBeginAttackPhase
    for i in 0...4
      if @choices[i][0]!=1 && @choices[i][0]!=2
        #@battlers[i].effects[:DestinyBond]=false # Effect gets removed on move use, NOT move choice
        @battlers[i].effects[:Grudge]=false
      end
      @battlers[i].turncount+=1 if !@battlers[i].isFainted?
      @battlers[i].turncount+=1 if !@battlers[i].isFainted? && @battlers[i].ability==:SLOWSTART && @field.effect==:ELECTERRAIN
      @battlers[i].effects[:Rage]=false if @choices[i][1].is_a?(Symbol)|| @battlers[i].moves[@choices[i][1]] != :RAGE
      #@battlers[i].pbCustapBerry # Moved to later, timing was incorrect here
    end
    # Calculate priority at this time
    @usepriority=false
    priority=pbPriority
    # Call at Pokémon
    for i in priority
      if @choices[i.index][0]==4
        pbCall(i.index)
      end
    end
    # Switch out Pokémon
    @switching=true
    switched=[]
    for i in priority
      if @choices[i.index][0]==2
        index=@choices[i.index][1] # party position of Pokémon to switch to
        self.lastMoveUser=i.index
        if !pbOwnedByPlayer?(i.index)
          owner=pbGetOwner(i.index)
          pbDisplayBrief(_INTL("{1} withdrew {2}!",owner.fullname,getMonName(i.species)))
        else
          pbDisplayBrief(_INTL("{1}, that's enough!\r\nCome back!",i.name))
        end
        for j in priority
          next if !i.pbIsOpposing?(j.index)
          # if Pursuit and this target ("i") was chosen
          if pbChoseMoveFunctionCode?(j.index,0x88) && !j.effects[:Pursuit] && (@choices[j.index][3]==-1 || @choices[j.index][3]==i.index)
            newpoke=pbPursuitInterrupt(j,i)
            return if @decision>0
          end
          break if i.isFainted?
        end
        if defined?(newpoke) && !newpoke.nil?
          index=newpoke
        end
        if !pbRecallAndReplace(i.index,index)
          # If a forced switch somehow occurs here in single battles
          # the attack phase now ends
          if !@doublebattle
            @switching=false
            return
          end
        else
          switched.push(i.index)
        end
      end
    end
    if switched.length>0
      for i in priority
        i.pbAbilitiesOnSwitchIn(true) if switched.include?(i.index)
      end
    end
    @switching=false
    for i in 0...4
       if !switched.include?(i)
         @battlers[i].pbCustapBerry
       end
    end
    # Use items
    for i in priority
      if !pbOwnedByPlayer?(i.index) && @choices[i.index][0]==3
        pbEnemyUseItem(@choices[i.index][1],i)
        i.itemUsed = true
        i.itemUsed2 = true
      elsif @choices[i.index][0]==3
        # Player use item
        item=@choices[i.index][1]
        if item
          usetype=$cache.items[item].checkFlag?(:noUseInBattle) ? 0 : pbGetPocket(item)
          i.itemUsed = true
          i.itemUsed2 = true
          if !pbIsPokeBall?(item)
            if @choices[i.index][2]>=0 && usetype != 7
              pbUseItemOnPokemon(item,@choices[i.index][2],i,@scene)
            elsif !ItemHandlers.hasUseInBattle(item)
              pbUseItemOnBattler(item,@choices[i.index][2],i,@scene)
            end
          end
        end
      end
    end
    # Mega Evolution
    for i in priority
      next if @choices[i.index][0]!=1
      side=(pbIsOpposing?(i.index)) ? 1 : 0
      owner=pbGetOwnerIndex(i.index)
      if @megaEvolution[side][owner]==i.index
        pbMegaEvolve(i.index)
      end
    end
    # Giga Evolution
    for i in priority
      next if @choices[i.index][0]!=1
      side=(pbIsOpposing?(i.index)) ? 1 : 0
      owner=pbGetOwnerIndex(i.index)
      if @gigaEvolution[side][owner]==i.index
        pbGigaEvolve(i.index)
      end
    end
    # Ultra Burst
    for i in priority
      next if @choices[i.index][0]!=1
      side=(pbIsOpposing?(i.index)) ? 1 : 0
      owner=pbGetOwnerIndex(i.index)
      if @ultraBurst[side][owner]==i.index
        pbUltraBurst(i.index)
      end
    end
    # Reuni crest type switch
    for i in priority
      next if @choices[i.index][0]!=1 || @choices[i.index][1]<0
      next if (i.crested != :REUNICLUS)
      protypes = [i.moves[@choices[i.index][1]].pbIsPhysical?,i.moves[@choices[i.index][1]].pbIsSpecial?]
      if protypes[0] == true || protypes[1] == true
        protype = :FIGHTING if protypes[0] == true
        protype = :PSYCHIC if protypes[1] == true
        prot1 = i.type1
        prot2 = i.type2
        if !i.hasType?(protype) || (!prot2.nil? && prot1 != prot2)
          i.type1=protype
          i.type2=nil
          if i.species == :REUNICLUS
            i.pbUpdate(false)
          end
          pbDisplay(_INTL("{1} had its type changed to {2}!",i.pbThis,protype.capitalize))
        end
      end
    end
    # Goth crest type switch
    for i in priority
      next if @choices[i.index][0]!=1 || @choices[i.index][1]<0
      next if (i.crested != :GOTHITELLE)
      protype = i.moves[@choices[i.index][1]].type
      next if  protype != :PSYCHIC && !(protype == :DARK && i.species == :GOTHITELLE) 
      prot1 = i.type1
      prot2 = i.type2
      if !i.hasType?(protype) || (!prot2.nil? && prot1 != prot2)
        i.type1=protype
        i.type2=nil

        pbDisplay(_INTL("{1} had its type changed to {2}!",i.pbThis,protype.capitalize))
      end
    end
    priority=pbPriority(false,true)    #Turn order recalc from Gen VII
    if @state.effects[:WonderRoom] > 0
      for i in @battlers
        i.pbSwapDefenses if !i.wonderroom
      end
    end

    # move animations before main move processing
    for i in priority
      if pbChoseMoveFunctionCode?(i.index,0x115) # Focus Punch
        pbCommonAnimation("FocusPunch",i,nil)
        pbDisplay(_INTL("{1} is tightening its focus!",i.pbThis))
      elsif pbChoseMoveFunctionCode?(i.index,0x15D) # Beak Blast
        pbCommonAnimation("BeakBlast",i,nil)
        i.effects[:BeakBlast]=true
        pbDisplay(_INTL("{1} is heating up!",i.pbThis))
      elsif pbChoseMoveFunctionCode?(i.index,0x16B) # Shell Trap
        pbCommonAnimation("ShellTrap",i,nil)
        i.effects[:ShellTrap]=true
        pbDisplay(_INTL("{1} set a shell trap!",i.pbThis))
      end
    end

    # Use attacks
    for i in priority
      i.pbProcessTurn(@choices[i.index])
      if i.effects[:Round] && @doublebattle
        pbMoveAfter(i, i.pbPartner)
      end

      # Shell Trap
      for ii in 0...4
        if !@battlers[ii].effects[:ShellTrapTarget].nil? && @battlers[ii].effects[:ShellTrapTarget] != -1 &&
           !@battlers[ii].effects[:ShellTrap] 
          if pbChoseMoveFunctionCode?(ii,0x16B)
            pbMoveAfter(i, @battlers[ii])
          else # Via seed
            target=@battlers[ii].effects[:ShellTrapTarget]
            @battlers[ii].pbUseMoveSimple(:SHELLTRAP,-1,target,false)
            @battlers[ii].effects[:ShellTrapTarget]=-1
          end
        end
      end

      return if @decision>0
    end
  end

  def pbPursuitInterrupt(pursuiter,switcher)
    newpoke=nil
    if pursuiter.status != :SLEEP && pursuiter.status != :FROZEN && !pursuiter.effects[:Truant]
      @switching=true
      #Try to Mega-evolve/Ultra-burst before using pursuit
      side=(pbIsOpposing?(pursuiter.index)) ? 1 : 0
      owner=pbGetOwnerIndex(pursuiter.index)
      if @megaEvolution[side][owner]==pursuiter.index
        pbMegaEvolve(pursuiter.index)
      end
      if @gigaEvolution[side][owner]==pursuiter.index
        pbGigaEvolve(pursuiter.index)
      end
      if @ultraBurst[side][owner]==pursuiter.index
        pbUltraBurst(pursuiter.index)
      end
      # Goth crest type switch
      if (pursuiter.crested == :GOTHITELLE && (pursuiter.moves[@choices[pursuiter.index][1]].type == :DARK))
        protype = :DARK
        prot1 = pursuiter.type1
        prot2 = pursuiter.type2
        if !pursuiter.hasType?(protype)
          pursuiter.type1=protype
          pursuiter.type2=nil
          pbDisplay(_INTL("{1} had its type changed to {2}!",pbThis,protype.capitalize))
        end
      end
      pursuiter.pbUseMove(@choices[pursuiter.index])
      pursuiter.effects[:Pursuit]=true
      
      if pbOwnedByPlayer?(switcher.index) && switcher.isFainted?
        newpoke=pbSwitchPlayer(switcher.index,false,false)
      end
      @switching=false
    end
    return newpoke
  end


################################################################################
# End of round.
################################################################################
  def pbEndOfRoundPhase
    for i in 0...4
      if @battlers[i].effects[:ShellTrap] && !pbChoseMoveFunctionCode?(i,0x16B)
        pbDisplay(_INTL("{1}'s Shell Trap didn't work.",@battlers[i].name))
      end
    end
    for i in 0...4
      @battlers[i].forcedSwitchEarlier                  =false
      next if @battlers[i].hp <= 0
      @battlers[i].damagestate.reset
      @battlers[i].midwayThroughMove                    =false
      @battlers[i].forcedSwitchEarlier                  =false
      @battlers[i].effects[:Protect]          =false
      @battlers[i].effects[:ProtectNegation]  =false
      @battlers[i].effects[:Endure]           =false
      @battlers[i].effects[:HyperBeam]-=1     if @battlers[i].effects[:HyperBeam]>0
      @battlers[i].effects[:BeakBlast]        =false
      @battlers[i].effects[:ClangedScales]    =false
      @battlers[i].effects[:ShellTrap]        =false
      if (@field.effect==:BURNING || @field.effect==:VOLCANIC || @field.effect==:INFERNAL) && @battlers[i].effects[:BurnUp] # Burning/Volcanic Field
        @battlers[i].type1= @battlers[i].pokemon.type1
        @battlers[i].type2= @battlers[i].pokemon.type2
        @battlers[i].effects[:BurnUp]         =false
      end
      @battlers[i].effects[:Powder]           =false
      @battlers[i].effects[:MeFirst]          =false
      @battlers[i].effects[:Jealousy]  =false
      @battlers[i].effects[:LashOut]          =false
      @battlers[i].effects[:QuickDrawSnipe]   =false
      if @battlers[i].effects[:ThroatChop]>0
        @battlers[i].effects[:ThroatChop]-=1
      end
      @battlers[i].itemUsed                    =false
    end
    @state.effects[:IonDeluge]       =false
    for i in 0...2
      sides[i].resetProtect
    end
    @usepriority=false  # recalculate priority
    priority=pbPriority
    if @trickroom > 0
      @trickroom=@trickroom-1 if @field.effect != :FROZENDIMENSION
      if @trickroom == 0
        pbDisplay("The twisted dimensions returned to normal!")
      end
    end
    if @state.effects[:WonderRoom] > 0
      @state.effects[:WonderRoom] -= 1 if @field.effect != :FROZENDIMENSION
      if @state.effects[:WonderRoom] == 0
        for i in @battlers
          if i.wonderroom
           i.pbSwapDefenses
          end
        end
        pbDisplay("Wonder Room wore off, and the Defense and Sp. Def stats returned to normal!")
      end
    end
    priority=pbPriority
    # Field Effects
    endmessage=false
    for i in priority
      next if i.isFainted?
      if i.crested == :VESPIQUEN
        mon = i
        if mon.effects[:VespiCrest] == false
           if (mon.totalhp != mon.hp)
            pbDisplay(_INTL("Vespiquen's swarm patched up her injuries!",i.pbThis)) if endmessage == false
            endmessage=true
            hpgain=(mon.totalhp/16).floor
            hpgain=mon.pbRecoverHP(hpgain,true)
           end
        end
      end
    end
    for i in priority
      next if i.isFainted?
      case @field.effect
        when :ELECTERRAIN # Electric Terrain
          next if i.hp<=0
          if i.ability == :VOLTABSORB && i.effects[:HealBlock]==0 && Rejuv
            hpgain=(i.totalhp/16.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
            pbDisplay(_INTL("{1} absorbed stray electricity!",i.pbThis)) if hpgain>0
          end
        when :GRASSY # Grassy Field
          next if i.hp<=0
          if !i.isAirborne? && i.effects[:HealBlock]==0 && !PBStuff::TWOTURNMOVE.include?(i.effects[:TwoTurnAttack]) && i.totalhp != i.hp
            pbDisplay(_INTL("The grassy terrain healed the Pokémon on the field.",i.pbThis)) if !endmessage
            endmessage=true
            hpgain=(i.totalhp/16.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
          end
          if i.ability == :SAPSIPPER && i.effects[:HealBlock]==0
            hpgain=(i.totalhp/16.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
            pbDisplay(_INTL("{1} drank tree sap to recover!",i.pbThis)) if hpgain>0
          end
        when :BURNING, :VOLCANIC, :INFERNAL # Burning Field
          next if i.hp<=0
          if !i.isAirborne?
            if (i.ability == :FLASHFIRE)
              if !i.effects[:FlashFire]
                i.effects[:FlashFire]=true
                pbDisplay(_INTL("{1}'s {2} raised its Fire power!", i.pbThis,getAbilityName(i.ability)))
              end
            end
            if i.burningFieldPassiveDamage?
              eff=PBTypes.twoTypeEff(:FIRE,i.type1,i.type2)
              if eff>0
                @scene.pbDamageAnimation(i,0)
                if (i.ability == :LEAFGUARD) || (i.ability == :ICEBODY) || (i.ability == :FLUFFY) || (i.ability == :GRASSPELT)
                  eff = eff*2
                end
                eff = eff*2 if (i.effects[:TarShot])
                pbDisplay(_INTL("The Pokémon were burned by the field!",i.pbThis)) if !endmessage
                endmessage=true
                i.pbReduceHP([(i.totalhp*eff/32).floor,1].max)
                if i.hp<=0
                  return if !i.pbFaint
                end
              end
            end
          end
        when :CORROSIVE # Corrosive Field
          next if i.hp<=0
          if i.ability == :GRASSPELT
            @scene.pbDamageAnimation(i,0)
            i.pbReduceHP((i.totalhp/8.0).floor)
            pbDisplay(_INTL("{1}'s Pelt was corroded!",i.pbThis))
            if i.hp<=0
              return if !i.pbFaint
            end
          end
          if (i.ability == :POISONHEAL || i.crested == :ZANGOOSE || i.crested == :GOODRA) && !i.isAirborne? && i.effects[:HealBlock]==0 && i.hp<i.totalhp
            pbCommonAnimation("Poison",i,nil)
            i.pbRecoverHP((i.totalhp/8.0).floor,true)
            pbDisplay(_INTL("{1} was healed by poison!",i.pbThis))
          end
        when :CORROSIVEMIST # Corrosive Mist Field
          if i.pbCanPoison?(false) && !@battle.pbCheckGlobalAbility(:NEUTRALIZINGGAS)
            pbDisplay(_INTL("The Pokémon were poisoned by the corrosive mist!",i.pbThis))   if !endmessage
            endmessage=true
            i.pbPoison(i)
          end
          if (i.ability == :POISONHEAL || i.crested == :ZANGOOSE || i.crested == :GOODRA) && i.effects[:HealBlock]==0 && i.hp<i.totalhp
            pbCommonAnimation("Poison",i,nil)
            i.pbRecoverHP((i.totalhp/8.0).floor,true)
            pbDisplay(_INTL("{1} was healed by poison!",i.pbThis))
          end
        when :FOREST # Forest Field
          next if i.hp<=0
          if i.ability == :SAPSIPPER && i.effects[:HealBlock]==0
            hpgain=(i.totalhp/16.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
            pbDisplay(_INTL("{1} drank tree sap to recover!",i.pbThis)) if hpgain>0
          end
        when :VOLCANICTOP
          eruptionChecker if @state.effects[:HarshSunlight]
          # eruption check - insane, too much, but makes typh op, so i no question
          next if i.hp<=0
          if @eruption
            if i.hasType?(:FIRE) ||
               i.ability == (:MAGMAARMOR) || i.ability == (:FLASHFIRE) ||
               i.ability == (:FLAREBOOST) || i.ability == (:BLAZE) ||
               i.ability == (:FLAMEBODY) || i.ability == (:SOLIDROCK) ||
               i.ability == (:STURDY) || i.ability == (:BATTLEARMOR) ||
               i.ability == (:SHELLARMOR) || i.ability == (:WATERBUBBLE) ||
               i.ability == (:MAGICGUARD) || i.ability == (:WONDERGUARD) ||
               i.ability == (:PRISMARMOR) || i.effects[:AquaRing] || i.ability == :SOLARIDOL ||
               i.pbOwnSide.effects[:WideGuard] || (i.pbOwnSide.effects[:AreniteWall]>0)
              pbDisplay(_INTL("{1} is immune to the eruption!",i.pbThis))
            else
              eff=PBTypes.twoTypeEff(:FIRE,i.type1,i.type2)
              eff /= 2 if (i.ability == (:THICKFAT))
              eff *= 2 if (i.effects[:TarShot])
              @scene.pbDamageAnimation(i,0)
              i.pbReduceHP([(i.totalhp*(eff/32.0)).floor,1].max)
              pbDisplay(_INTL("{1} is hurt by the eruption!",i.pbThis))
              if i.hp<=0
                return if !i.pbFaint
              end
            end
            if i.ability == (:MAGMAARMOR)
              boost = false
              if !i.pbTooHigh?(PBStats::DEFENSE)
                i.pbIncreaseStatBasic(PBStats::DEFENSE,1)
                pbCommonAnimation("StatUp",i,nil)
                boost=true
              end
              if !i.pbTooHigh?(PBStats::SPDEF)
                i.pbIncreaseStatBasic(PBStats::SPDEF,1)
                pbCommonAnimation("StatUp",i,nil)
                boost=true
              end
              if boost
                pbDisplay(_INTL("{1}'s Magma Armor raised its defenses!",i.pbThis))
              end
            end
            if i.ability == (:FLAREBOOST)
              if !i.pbTooHigh?(PBStats::SPATK)
                i.pbIncreaseStatBasic(PBStats::SPATK,1)
                pbCommonAnimation("StatUp",i,nil)
                pbDisplay(_INTL("{1}'s Flare Boost raised its Sp. Attack!",i.pbThis))
              end
            end
            if i.ability == (:FLASHFIRE)
              if !i.effects[:FlashFire]
                i.effects[:FlashFire]=true
                pbDisplay(_INTL("{1}'s {2} raised its Fire power!",
                i.pbThis,getAbilityName(i.ability)))
              end
            end
            if i.ability == (:BLAZE)
              if !i.effects[:Blazed]
                i.effects[:Blazed]=true
                pbDisplay(_INTL("{1}'s {2} raised its Fire power!",
                i.pbThis,getAbilityName(i.ability)))
              end
            end
            if i.status==:SLEEP && i.ability != :SOUNDPROOF
              i.pbCureStatus
              pbDisplay(_INTL("{1} woke up due to the eruption!",i.pbThis))
            end
            if i.effects[:LeechSeed]>=0
              i.effects[:LeechSeed] = -1
              pbDisplay(_INTL("{1}'s Leech Seed burned away in the eruption!",i.pbThis))
            end
          end
          # eruption check - insane, too much, but makes typh op, so i no question
        when :SHORTCIRCUIT # Shortcircuit Field
          next if i.hp<=0
          if i.ability == :VOLTABSORB && i.effects[:HealBlock]==0
            hpgain=(i.totalhp/16.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
            pbDisplay(_INTL("{1} absorbed stray electricity!",i.pbThis)) if hpgain>0
          end
        when :WASTELAND # Wasteland
          if (i.ability == :POISONHEAL || i.crested == :ZANGOOSE || i.crested == :GOODRA) && !i.isAirborne? && i.effects[:HealBlock]==0 && i.hp<i.totalhp
            pbCommonAnimation("Poison",i,nil)
            i.pbRecoverHP((i.totalhp/8.0).floor,true)
            pbDisplay(_INTL("{1} was healed by poison!",i.pbThis))
          end
        when :WATERSURFACE # Water Surface
          next if i.hp<=0
          if (i.ability == :WATERABSORB || i.ability == :DRYSKIN || i.ability == :DETRITOVORE) && i.effects[:HealBlock]==0 && !i.isAirborne?
            hpgain=(i.totalhp/16.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
            pbDisplay(_INTL("{1} absorbed some of the water!",i.pbThis)) if hpgain>0
          end
          if i.effects[:TarShot] == true
            i.effects[:TarShot]=false
            pbDisplay(_INTL("The tar washed of {1} in the water!",i.pbThis))
          end
        when :UNDERWATER
          next if i.hp<=0
          if (i.ability == :WATERABSORB || i.ability == :DRYSKIN) && i.effects[:HealBlock]==0
            hpgain=(i.totalhp/16.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
            pbDisplay(_INTL("{1} absorbed some of the water!",i.pbThis)) if hpgain>0
          end
          if i.underwaterFieldPassiveDamamge?
            eff=PBTypes.twoTypeEff(:WATER,i.type1,i.type2)
            if eff>4
              @scene.pbDamageAnimation(i,0)
              if i.ability == :FLAMEBODY || i.ability == :MAGMAARMOR
                eff = eff*2
              end
              i.pbReduceHP([(i.totalhp*eff/32).floor,1].max)
              pbDisplay(_INTL("{1} struggled in the water!",i.pbThis))
              if i.hp<=0
                return if !i.pbFaint
              end
            end
          end
        when :MURKWATERSURFACE # Murkwater Surface
          if i.murkyWaterSurfacePassiveDamage?
            eff=PBTypes.twoTypeEff(:POISON,i.type1,i.type2)
            if i.ability == :FLAMEBODY || i.ability == :MAGMAARMOR || i.ability == :DRYSKIN || i.ability == :WATERABSORB
              eff = eff*2
            end
            if !$cache.moves[i.effects[:TwoTurnAttack]].nil? && 
              $cache.moves[i.effects[:TwoTurnAttack]].function==0xCB # Dive
              @scene.pbDamageAnimation(i,0)
              i.pbReduceHP([(i.totalhp*eff/8).floor,1].max)
              pbDisplay(_INTL("{1} suffocated underneath the toxic water!",i.pbThis))
            elsif !i.isAirborne?
              @scene.pbDamageAnimation(i,0)
              i.pbReduceHP([(i.totalhp*eff/32).floor,1].max)
              pbDisplay(_INTL("{1} was hurt by the toxic water!",i.pbThis))
            end
          end
          if i.isFainted?
            return if !i.pbFaint
          end
          if i.hasType?(:POISON) && (i.ability == :DRYSKIN || i.ability == :WATERABSORB || i.ability == :DETRITOVORE) || (i.ability == :POISONHEAL || i.crested == :ZANGOOSE || i.crested == :GOODRA)  && !i.isAirborne? && i.effects[:HealBlock]==0 && i.hp<i.totalhp
            pbCommonAnimation("Poison",i,nil)
            i.pbRecoverHP((i.totalhp/8.0).floor,true)
            pbDisplay(_INTL("{1} was healed by the poisoned water!",i.pbThis))
          end
        when :DIMENSIONAL # Dimension Field (Rejuv)
          if i.effects[:HealBlock]!=0
            @scene.pbDamageAnimation(i,0)
            i.pbReduceHP((i.totalhp/16).floor)
            pbDisplay(_INTL("{1} was damaged by the Heal Block!",i.pbThis))
            if i.hp<=0
              return if !i.pbFaint
            end
          end
        when :CORRUPTED # Corrupted Cave Field (Rejuv)
          next if i.hp<=0
          if i.ability == :GRASSPELT || i.ability == :LEAFGUARD || i.ability == :FLOWERVEIL
            @scene.pbDamageAnimation(i,0)
            i.pbReduceHP((i.totalhp/8).floor)
            pbDisplay(_INTL("{1}'s foliage caused harm!",i.pbThis))
            if i.hp<=0
              return if !i.pbFaint
            end
          end 
          if i.ability == (:POISONHEAL) && !i.isAirborne? && i.effects[:HealBlock]==0 && i.hp<i.totalhp
            pbCommonAnimation("Poison",i,nil)
            i.pbRecoverHP((i.totalhp/8).floor,true)
            pbDisplay(_INTL("{1} was healed in the corruption!",i.pbThis))
          end
          if !i.isAirborne? && !i.hasType?(:POISON) && i.ability != :WONDERSKIN && i.ability != :IMMUNITY && i.ability != :PASTELVEIL
            if i.pbCanPoison?(false)
              pbDisplay(_INTL("{1} was poisoned!",i.pbThis)) if endmessage == false
              endmessage=true
              i.pbPoison(i)
            end
          end
        when :BEWITCHED #Bewitched Woods (Rejuv)
          next if i.hp<=0
          if !i.isAirborne? && i.hasType?(:GRASS) && i.effects[:HealBlock]==0 && i.totalhp != i.hp
            pbDisplay(_INTL("The woods healed the grass Pokemon on the field.",i.pbThis)) if !endmessage
            endmessage=true
            hpgain=(i.totalhp/16.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
          end
          if i.ability == :NATURALCURE
            i.status=nil
            pbDisplay(_INTL("The woods cured {1}'s status conditions!",i.pbThis)) if !endmessage
          end
        when :INFERNAL #Infernal Field (Rejuv)
          next if i.hp<=0
          if i.effects[:Torment] == true
            @scene.pbDamageAnimation(i,0)
            i.pbReduceHP((i.totalhp/8).floor)
            pbDisplay(_INTL("{1} was damaged by Torment!",i.pbThis))
          end
      end
      if @state.effects[:ELECTERRAIN] > 0
        next if i.hp<=0
        if i.ability == :VOLTABSORB && i.effects[:HealBlock]==0
          hpgain=(i.totalhp/16.0).floor
          hpgain=i.pbRecoverHP(hpgain,true)
          pbDisplay(_INTL("{1} absorbed stray electricity!",i.pbThis)) if hpgain>0
        end
      end
      if @state.effects[:GRASSY] > 0
        next if i.hp<=0
        if !i.isAirborne? && i.effects[:HealBlock]==0 && !PBStuff::TWOTURNMOVE.include?(i.effects[:TwoTurnAttack]) && i.totalhp != i.hp
          pbDisplay(_INTL("The grassy terrain healed the Pokémon on the field.",i.pbThis)) if !endmessage
          endmessage=true
          hpgain=(i.totalhp/16.0).floor
          hpgain=i.pbRecoverHP(hpgain,true)
        end
        if i.ability == :SAPSIPPER && i.effects[:HealBlock]==0
          hpgain=(i.totalhp/16.0).floor
          hpgain=i.pbRecoverHP(hpgain,true)
          pbDisplay(_INTL("{1} drank tree sap to recover!",i.pbThis)) if hpgain>0
        end
      end
    end
    # eruption check 2 (having the hazard removal in the main loop above causes the messaging to malfunction)
    if @field.effect == :VOLCANICTOP
      if @eruption
        hazardsOnSide = false
        for i in priority
          if i.pbOwnSide.effects[:Spikes]>0
            i.pbOwnSide.effects[:Spikes]=0
            hazardsOnSide = true
          end
          if i.pbOwnSide.effects[:ToxicSpikes]>0
            i.pbOwnSide.effects[:ToxicSpikes]=0
            hazardsOnSide = true
          end
          if i.pbOwnSide.effects[:StealthRock]
            i.pbOwnSide.effects[:StealthRock]=false
            hazardsOnSide = true
          end
          if i.pbOwnSide.effects[:StickyWeb]
            i.pbOwnSide.effects[:StickyWeb]=false
            hazardsOnSide = true
          end
        end
        if hazardsOnSide
          pbDisplay(_INTL("The eruption removed all hazards from the field!"))
        end
      end
    end
    # End Field stuff
    # Weather
    # Unsure what this is really doing, cass thinks it's probably nothing. But just in case ?? ~a
    #if @field.effect != :UNDERWATER
    #  @field.counter = 0 if @weather != :HAIL && @field.effect == :MOUNTAIN
    #end
    for i in priority
      if i.ability == :TEMPEST
        weathers=rand(5)
        rainbowhold = 0
        case weathers
         when 0
            if @weather== :SUNNYDAY
              rainbowhold=8
            end
            @weather=:RAINDANCE
            @weatherduration=8
            pbCommonAnimation("Rain",nil,nil)
            pbDisplay(_INTL("Storm-9 created a downpour!"))
            if rainbowhold != 0
              fieldbefore = @field.effect
              setField(:RAINBOW,rainbowhold)
              if fieldbefore != :RAINBOW
                pbDisplay(_INTL("The weather created a rainbow!"))
              else
                pbDisplay(_INTL("The weather refreshed the rainbow!"))
              end
            end
         when 1
            @weather=:HAIL
            @weatherduration=8
            pbCommonAnimation("Hail",nil,nil)
            pbDisplay(_INTL("Storm-9 brought hailfall!"))
            for facemon in @battlers
              if facemon.species==:EISCUE && facemon.form==1 # Eiscue
                facemon.pbRegenFace
                pbDisplayPaused(_INTL("{1} transformed!",facemon.name))
              end
            end
         when 2
            @weather=:SANDSTORM
            @weatherduration=8
            pbCommonAnimation("Sandstorm",nil,nil)
            pbDisplay(_INTL("Storm-9 whipped up a duststorm!"))
         when 3
            @weather=:STRONGWINDS
            @weatherduration=8
            pbCommonAnimation("Wind",nil,nil)
            pbDisplay(_INTL("Storm-9 whipped up terrible winds!"))
         when 4
            @weather=:SHADOWSKY
            @weatherduration=8
            pbCommonAnimation("ShadowSky",nil,nil)
            pbDisplay(_INTL("Storm-9 shrouded the sky in a dark aura..."))
         end
       end
    end
    if @storm9 && !pbCheckGlobalAbility(:TEMPEST)
      @storm9 = false
      noWeather
    end
    case @weather
      when :SUNNYDAY
        @weatherduration=@weatherduration-1 if @weatherduration>0
        if @weatherduration==0
          pbDisplay(_INTL("The sunlight faded."))
          pbDisplay(_INTL("The starry sky shone through!")) if @field.effect == :STARLIGHT
          @weather=0
          persistentWeather
        else
          pbCommonAnimation("Sunny")
          if @field.effect == :DARKCRYSTALCAVERN #Dark Crystal Cavern
            duration = @weatherduration + 1
            setField(:CRYSTALCAVERN,duration)
            @field.duration_condition = proc {|battle| battle.weather == :SUNNYDAY}
            @field.permanent_condition = proc {|battle| battle.FE != :CRYSTALCAVERN}
            pbDisplay(_INTL("The sun lit up the crystal cavern!"))
          end
          # if pbWeather == :SUNNYDAY
          #   for i in priority
          #     next if i.isFainted?
          #     if i.ability == :SOLARPOWER && @field.effect != :FROZENDIMENSION
          #       pbDisplay(_INTL("{1} was hurt by the sunlight!",i.pbThis))
          #       @scene.pbDamageAnimation(i,0)
          #       i.pbReduceHP((i.totalhp/8.0).floor)
          #       if i.isFainted?
          #         return if !i.pbFaint
          #       end
          #     end
          #     if Rejuv && @field.effect == :DESERT && (i.hasType?(:GRASS) || i.hasType?(:WATER)) && !(i.ability == :SOLARPOWER || i.ability == :CHLOROPHYLL)
          #       pbDisplay(_INTL("{1} was hurt by the sunlight!",i.pbThis))
          #       @scene.pbDamageAnimation(i,0)
          #       i.pbReduceHP((i.totalhp/8.0).floor)
          #       if i.isFainted?
          #         return if !i.pbFaint
          #       end
          #     end
          #   end
          # end
        end
      when :RAINDANCE
        @weatherduration=@weatherduration-1 if @weatherduration>0
        if @weatherduration==0
          pbDisplay(_INTL("The rain stopped."))
          pbDisplay(_INTL("The starry sky shone through!")) if @field.effect == :STARLIGHT
          @weather=0
          persistentWeather
        else
          pbCommonAnimation("Rain")
          if @field.effect == :BURNING
            breakField
            pbDisplay(_INTL("The rain snuffed out the flame!"));
          end
          if @field.effect == :VOLCANIC
            setField(:CAVE)
            pbDisplay(_INTL("The rain snuffed out the flame!"));
          end
        end
      when :SANDSTORM
        @weatherduration=@weatherduration-1 if @weatherduration>0
        if @weatherduration==0
          pbDisplay(_INTL("The sandstorm subsided."))
          pbDisplay(_INTL("The starry sky shone through!")) if @field.effect == :STARLIGHT
          @weather=0
          persistentWeather
        else
          pbCommonAnimation("Sandstorm")
          if @field.effect == :BURNING
            breakField
            pbDisplay(_INTL("The sand snuffed out the flame!"));
          end
          if @field.effect == :VOLCANIC
            setField(:CAVE)
            pbDisplay(_INTL("The sand snuffed out the flame!"));
          end
          if @field.effect == :RAINBOW
            breakField if @field.duration == 0
            endTempField if @field.duration > 0
            pbDisplay(_INTL("The weather blocked out the rainbow!"));
          end
          if pbWeather== :SANDSTORM
            endmessage=false
            for i in priority
              next if i.isFainted?
              if (!i.hasType?(:GROUND) && !i.hasType?(:ROCK) && !i.hasType?(:STEEL) && !(i.ability == :SANDVEIL  || i.ability == :SANDRUSH ||
                i.ability == :SANDFORCE || i.ability == :MAGICGUARD || i.ability == :TEMPEST || (i.ability == :WONDERGUARD && @field.effect == :COLOSSEUM) || i.ability == :OVERCOAT) &&
              !(i.item == :SAFETYGOGGLES) && ($cache.moves[i.effects[:TwoTurnAttack]].nil? || ![0xCA,0xCB].include?($cache.moves[i.effects[:TwoTurnAttack]].function))) || # Dig, Dive
              (i.effects[:DesertsMark] && !(i.ability == :MAGICGUARD)) # Desert's mark sand immunity negation
                pbDisplay(_INTL("The Pokémon were buffeted by the sandstorm!",i.pbThis)) if !endmessage
                endmessage=true
                @scene.pbDamageAnimation(i,0)
                if Rejuv && @field.effect == :DESERT
                  i.pbReduceHP((i.totalhp/8.0).floor)
                else
                  i.pbReduceHP((i.totalhp/16.0).floor)
                end
                if i.isFainted?
                  return if !i.pbFaint
                end
              end
            end
          end
        end
      when :HAIL
        @weatherduration=@weatherduration-1 if @weatherduration>0
        if @weatherduration==0
          pbDisplay(_INTL("The hail stopped."))
          pbDisplay(_INTL("The starry sky shone through!")) if @field.effect == :STARLIGHT
          @weather=0
          persistentWeather
        else
          pbCommonAnimation("Hail")
          if @field.effect == :RAINBOW
            breakField if @field.duration == 0
            endTempField if @field.duration > 0
            pbDisplay(_INTL("The weather blocked out the rainbow!"));
          end
          if pbWeather== :HAIL
            endmessage=false
            for i in priority
              next if i.isFainted?
              if !i.hasType?(:ICE) && i.ability != :TEMPEST && i.ability != :ICEBODY && i.ability != :SNOWCLOAK && i.ability != :SLUSHRUSH && i.ability != :LUNARIDOL && i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && i.ability != :OVERCOAT &&
                !(i.item == :SAFETYGOGGLES) && ($cache.moves[i.effects[:TwoTurnAttack]].nil? || ![0xCA,0xCB].include?($cache.moves[i.effects[:TwoTurnAttack]].function)) # Dig, Dive
                pbDisplay(_INTL("The Pokémon were buffeted by the hail!",i.pbThis)) if !endmessage
                endmessage=true
                @scene.pbDamageAnimation(i,0)
                if @field.effect == :FROZENDIMENSION
                  i.pbReduceHP((i.totalhp/8.0).floor)
                else
                  i.pbReduceHP((i.totalhp/16.0).floor)
                end
                if i.isFainted?
                  return if !i.pbFaint
                end
              end
            end
            if @field.effect  == :MOUNTAIN
              @field.counter+=1
              if @field.counter == 3
                setField(:SNOWYMOUNTAIN)
                pbDisplay(_INTL("The mountain was covered in snow!"))
              end
            end
          end
        end
      when :STRONGWINDS
        @weatherduration=@weatherduration-1 if @weatherduration>0
        if @weatherduration==0
          pbDisplay(_INTL("The strong wind petered out."))
          @weather=0
          persistentWeather
        else
          pbCommonAnimation("Wind")
        end
      when :SHADOWSKY
        @weatherduration=@weatherduration-1 if @weatherduration>0
        if @weatherduration==0
          pbDisplay(_INTL("The shadow sky faded."))
          pbDisplay(_INTL("The starry sky shone through!")) if @field.effect == :STARLIGHT
          @weather=0
          persistentWeather
        else
          pbCommonAnimation("ShadowSky")
          if @weather == :SHADOWSKY
            for i in priority
              next if i.isFainted?
              if !i.isShadow? && i.ability != :TEMPEST
                pbDisplay(_INTL("{1} was hurt by the shadow sky!",i.pbThis))
                @scene.pbDamageAnimation(i,0)
                if @field.effect == :DIMENSIONAL || @field.effect == :FROZENDIMENSION
                  i.pbReduceHP((i.totalhp/8.0).floor)
                else
                  i.pbReduceHP((i.totalhp/16.0).floor)
                end
                if i.isFainted?
                  return if !i.pbFaint
                end
              end
            end
          end
        end
    end
    # Temporal Shift
    for i in priority
      next if i.isFainted?
      if i.hasWorkingAbility(:TEMPORALSHIFT)
        for j in priority
          next if j.isFainted?
          if !(i==j || i.pbPartner==j || j.hasType?(:NORMAL)) && j.effects[:FutureSight]==0
            j.effects[:FutureSight]=3 
            j.effects[:FutureSightMove]=:HEX
            j.effects[:FutureSightUser]=i.index
            j.effects[:FutureSightPokemonIndex]=i.pokemonIndex
            pbDisplay(_INTL("{1} casts a hex!",i.pbThis))
            break
          end
        end
      end
    end
    # Future Sight/Doom Desire
    for i in battlers   # not priority
      next if i.effects[:FutureSight]<=0
      i.effects[:FutureSight]-=1
      next if i.isFainted? || i.effects[:FutureSight]!=0
      moveuser=nil
      #check if battler on the field
      move, moveuser, disabled_items = i.pbFutureSightUserPlusMove
      type = move.type
      pbDisplay(_INTL("{1} took the {2} attack!",i.pbThis,move.name))
      typemod = move.pbTypeModifier(type,moveuser,i)
      twoturninvul = PBStuff::TWOTURNMOVE.include?(i.effects[:TwoTurnAttack])
      if (i.isFainted? || move.pbAccuracyCheck(moveuser,i) && !(i.ability == :WONDERGUARD && typemod<=4)) && !twoturninvul
        i.damagestate.reset
        damage = nil
        if i.effects[:FutureSightMove] == :FUTURESIGHT && !(i.hasType?(:DARK))
          moveuser.hp != 0 ? pbAnimation(:FUTUREDUMMY,moveuser,i) : pbAnimation(:FUTUREDUMMY,i,i)
        elsif i.effects[:FutureSightMove] == :DOOMDESIRE
          moveuser.hp != 0 ? pbAnimation(:DOOMDUMMY,moveuser,i) : pbAnimation(:DOOMDUMMY,i,i)
        elsif i.effects[:FutureSightMove] == :HEX && !(i.hasType?(:NORMAL))
          moveuser.hp != 0 ? pbAnimation(:HEXDUMMY,moveuser,i) : pbAnimation(:HEXDUMMY,i,i)
        end
        move.pbReduceHPDamage(damage,moveuser,i)
        move.pbEffectMessages(moveuser,i)
      elsif i.ability == :WONDERGUARD && typemod<=4 && !twoturninvul
        pbDisplay(_INTL("{1} avoided damage with Wonder Guard!",i.pbThis))
      else
        pbDisplay(_INTL("But it failed!"))
      end
      i.effects[:FutureSight]=0
      i.effects[:FutureSightMove]=0
      i.effects[:FutureSightUser]=-1
      i.effects[:FutureSightPokemonIndex]=-1
      if !disabled_items.empty?
        moveuser.item = disabled_items[:item]
        moveuser.ability = disabled_items[:ability]
      end
      if i.isFainted?
        return if !i.pbFaint
        next
      end
    end
    for i in priority
      next if !i.isbossmon
      next if i.isFainted?
      if i.chargeAttack
        next if (i.status == :SLEEP || i.status == :FREEZE)
        chargeAttack = i.chargeAttack
        if i.turncount % chargeAttack[:turns] ==0 
          if i.chargeTurns? == false && i.turncount % chargeAttack[:turns] ==0 
            for m in @party1
              m.status = :FAINTED
              m.hp = 0
            end
            pbDisplay(_INTL("{1} unleashed it's power!",i.pbThis))
            pbAnimation(:EXPLOSION,i,i)
            for j in priority
              next if j.isFainted?
              next if j.isbossmon
              j.pbReduceHP(j.hp,true)
              j.pbFaint if j.isFainted?
            end
            @decision=2
            return 
          end
        else
          if chargeAttack[:intermediateattack] 
            if chargeAttack[:canIntermediateAttack] == true
              newmove = PokeBattle_BossMove.new(self,i,chargeAttack[:intermediateattack])
              i.pbUseMoveSimpleBoss(newmove,-1)
            else
              chargeAttack[:canIntermediateAttack] = true
            end
          end
        end
      end
    end

    for i in priority
      next if i.isFainted?

      # Meganium + Meganium Crest
      if i.crested == :MEGANIUM || (i.pbPartner.crested == :MEGANIUM && !i.pbPartner.isFainted?)
          hpgain=i.pbRecoverHP((i.totalhp/16).floor,true)
      end

      if i.crested == :MEGANIUM
        party=@battle.pbParty(i.index)
        for j in 0...party.length
          next if @battle.battlers.include?(j)
          next if !party[j] || party[j].isEgg?
          party[j].healHp(((party[j].totalhp+1)/16).floor);
        end
        pbDisplay(_INTL("The Meganium Crest restored the team's HP a little!",i.pbThis(true)))
      end

      # Confection
      if i.crested == :ALCREMIE
        for j in priority
          next if (i.index % 2 == j.index % 2) || j.isFainted?
          @battle.pbAnimation(:SWEETSCENT, i, j, 0);
          if j.pbCanReduceStatStage?(PBStats::EVASION) 
            j.pbReduceStat(PBStats::EVASION,1,statdropper:i)
          end
        end
      end


      # Rain Dish
      if ((i.ability == :RAINDISH || (i.crested == :CASTFORM && i.form == 2)) && (pbWeather== :RAINDANCE))&& i.effects[:HealBlock]==0
        hpgain=i.pbRecoverHP((i.totalhp/8.0).floor,true)
        pbDisplay(_INTL("{1}'s Rain Dish restored its HP a little!",i.pbThis)) if hpgain>0
      end

      # REPLENISH
      # @SWu how is ability suppression handled here?
      if ((i.ability == :REPLENISH || i.crested == :SWALOT) && i.effects[:Stockpile] < 3)
        # @SWu figure out animation here
        # pbShowAnimation(:STOCKPILE,attacker,opponent,hitnum,alltargets,showanimation)
        i.effects[:Stockpile]+=1
        @battle.pbDisplay(_INTL("{1} stockpiled {2}!",i.pbThis,
            i.effects[:Stockpile]))
        showanim=true
        if i.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
          i.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
          i.effects[:StockpileDef]+=1
          showanim=false
        end
        if i.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
          i.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
          i.effects[:StockpileSpDef]+=1
          showanim=false
        end
      end

      # Downdraft
      # @SWu how is ability suppression handled here?
      if (i.crested == :CORVIKNIGHT)
        for j in priority
          next if (i.index % 2 == j.index % 2) || j.isFainted?

          @battle.pbAnimation(:DEFOG, i, j, 0);
          for move in j.moves
            j.pbSetPP(move,move.pp-1) if move.pp>0
          end
          @battle.pbDisplay(_INTL("{1}'s Downdraft lowered the pp of {2}'s moves!", i.pbThis, j.pbThis))

          if i.pbOpposingSide.effects[:Reflect]>0
            i.pbOpposingSide.effects[:Reflect]=0
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The opposing team's Reflect wore off!"))
            else
                @battle.pbDisplay(_INTL("Your team's Reflect wore off!"))
            end
          end
          if i.pbOpposingSide.effects[:LightScreen]>0
            i.pbOpposingSide.effects[:LightScreen]=0
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The opposing team's Light Screen wore off!"))
            else
              @battle.pbDisplay(_INTL("Your team's Light Screen wore off!"))
            end
          end
          if i.pbOpposingSide.effects[:AuroraVeil]>0
            i.pbOpposingSide.effects[:AuroraVeil]=0
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The opposing team's Aurora Veil wore off!"))
            else
              @battle.pbDisplay(_INTL("Your team's Aurora Veil wore off!"))
            end
          end
          if i.pbOpposingSide.effects[:AreniteWall]>0
            i.pbOpposingSide.effects[:AreniteWall]=0
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The opposing team's Arenite Wall wore off!"))
            else
              @battle.pbDisplay(_INTL("Your team's Arenite Wall wore off!"))
            end
          end
          if i.pbOpposingSide.effects[:Mist]>0 || j.pbOwnSide.effects[:Mist]>0
            j.pbOwnSide.effects[:Mist]=0
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The opposing team is no longer protected by Mist."))
            else
              @battle.pbDisplay(_INTL("Your team is no longer protected by Mist."))
            end
          end
          if i.pbOpposingSide.effects[:Safeguard]>0 || j.pbOwnSide.effects[:Safeguard]>0
            j.pbOwnSide.effects[:Safeguard]=0
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The opposing team is no longer protected by Safeguard."))
            else
              @battle.pbDisplay(_INTL("Your team is no longer protected by Safeguard."))
            end
          end
          if i.pbOwnSide.effects[:Spikes]>0 || j.pbOwnSide.effects[:Spikes]>0
            i.pbOwnSide.effects[:Spikes]=0
            j.pbOwnSide.effects[:Spikes]=0
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The spikes disappeared from around your opponent's team's feet!"))
            else
              @battle.pbDisplay(_INTL("The spikes disappeared from around your team's feet!"))
            end
          end
          if i.pbOwnSide.effects[:StealthRock] || j.pbOwnSide.effects[:StealthRock]
            i.pbOwnSide.effects[:StealthRock]=false
            j.pbOwnSide.effects[:StealthRock]=false
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The pointed stones disappeared from around your opponent's team!"))
            else
              @battle.pbDisplay(_INTL("The pointed stones disappeared from around your team!"))
            end
          end
          if i.pbOwnSide.effects[:Steelsurge] || j.pbOwnSide.effects[:Steelsurge]
            i.pbOwnSide.effects[:Steelsurge]=false
            j.pbOwnSide.effects[:Steelsurge]=false
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The steel debris disappeared from around your opponent's team!"))
            else
              @battle.pbDisplay(_INTL("The steel debris disappeared from around your team!"))
            end
          end
          if i.pbOwnSide.effects[:Volcalith] || j.pbOwnSide.effects[:Volcalith]
            i.pbOwnSide.effects[:Volcalith]=false
            j.pbOwnSide.effects[:Volcalith]=false
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The molten rocks disappeared from around your opponent's team!"))
            else
              @battle.pbDisplay(_INTL("The molten rocks disappeared from around your team!"))
            end
          end
          if i.pbOwnSide.effects[:ToxicSpikes]>0 || j.pbOwnSide.effects[:ToxicSpikes]>0
            i.pbOwnSide.effects[:ToxicSpikes]=0
            j.pbOwnSide.effects[:ToxicSpikes]=0
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The poison spikes disappeared from around your opponent's team's feet!"))
            else
              @battle.pbDisplay(_INTL("The poison spikes disappeared from around your team's feet!"))
            end
          end
          if i.pbOwnSide.effects[:StickyWeb] || j.pbOwnSide.effects[:StickyWeb]
            attacker.pbOwnSide.effects[:StickyWeb]=false
            j.pbOwnSide.effects[:StickyWeb]=false
            if !@battle.pbIsOpposing?(i.index)
              @battle.pbDisplay(_INTL("The sticky web has disappeared from beneath your opponent's team's feet!"))
            else
              @battle.pbDisplay(_INTL("The sticky web has disappeared from beneath your team's feet!"))
            end
          end
        end
        if (@battle.state.effects[:PSYTERRAIN] > 0 || @battle.state.effects[:GRASSY] > 0 ||
          @battle.state.effects[:ELECTERRAIN] > 0 || @battle.state.effects[:MISTY] > 0)
          @battle.state.effects[:PSYTERRAIN] = 0
          @battle.state.effects[:GRASSY] = 0
          @battle.state.effects[:ELECTERRAIN] = 0
          @battle.state.effects[:MISTY] = 0
          @battle.pbDisplay(_INTL("The terrain effects were cleared!"))
        end
      end

      # Dry Skin
      if (i.ability == :DRYSKIN)
        if (pbWeather== :RAINDANCE) && i.effects[:HealBlock]==0
          hpgain=i.pbRecoverHP((i.totalhp/8.0).floor,true)
          pbDisplay(_INTL("{1}'s Dry Skin was healed by the rain!",i.pbThis)) if hpgain>0
        elsif (pbWeather== :SUNNYDAY && !i.hasWorkingItem(:UTILITYUMBRELLA))
          @scene.pbDamageAnimation(i,0)
          hploss=i.pbReduceHP((i.totalhp/8.0).floor)
          pbDisplay(_INTL("{1}'s Dry Skin was hurt by the sunlight!",i.pbThis)) if hploss>0
        elsif (@field.effect == :CORROSIVEMIST || @field.effect == :CORRUPTED) && !i.hasType?(:STEEL)
          if !i.hasType?(:POISON)
            @scene.pbDamageAnimation(i,0)
            hploss=i.pbReduceHP((i.totalhp/8.0).floor)
            pbDisplay(_INTL("{1}'s Dry Skin absorbed the poison!",i.pbThis)) if hploss>0
          elsif i.effects[:HealBlock]==0
            hpgain=i.pbRecoverHP((i.totalhp/8.0).floor,true)
            pbDisplay(_INTL("{1}'s Dry Skin was healed by the poison!",i.pbThis)) if hpgain>0
          end
        elsif @field.effect == :DESERT
          @scene.pbDamageAnimation(i,0)
          hploss=i.pbReduceHP((i.totalhp/8.0).floor)
          pbDisplay(_INTL("{1}'s Dry Skin was hurt by the desert air!",i.pbThis)) if hploss>0
        elsif @field.effect == :MISTY || @battle.state.effects[:MISTY] > 0
          if i.effects[:HealBlock]==0
            hpgain=(i.totalhp/16.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
            pbDisplay(_INTL("{1}'s Dry Skin was healed by the mist!",i.pbThis)) if hpgain>0
          end
        elsif @field.effect == :SWAMP  # Swamp Field
          if i.effects[:HealBlock]==0
            hpgain=(i.totalhp/8.0).floor
            hpgain=i.pbRecoverHP(hpgain,true)
            pbDisplay(_INTL("{1}'s Dry Skin was healed by the murk!",i.pbThis)) if hpgain>0
          end
        end
      end
      # Ice Body
      if i.ability == :ICEBODY && (pbWeather== :HAIL || @field.effect == :ICY || @field.effect == :SNOWYMOUNTAIN || @field.effect == :FROZENDIMENSION) && i.effects[:HealBlock]==0
        hpgain=i.pbRecoverHP((i.totalhp/8.0).floor,true)
        pbDisplay(_INTL("{1}'s Ice Body restored its HP a little!",i.pbThis)) if hpgain>0
      end
      if i.crested == :DRUDDIGON && pbWeather== :SUNNYDAY && i.effects[:HealBlock]==0
        hpgain=i.pbRecoverHP((i.totalhp/8.0).floor,true)
        pbDisplay(_INTL("{1}'s Crest restored its HP a little!",i.pbThis)) if hpgain>0
      end
      if i.crested == :SANDACONDA && pbWeather== :SANDSTORM && i.effects[:HealBlock]==0
        hpgain=i.pbRecoverHP((i.totalhp/8.0).floor,true)
        pbDisplay(_INTL("{1}'s Crest restored its HP a little!",i.pbThis)) if hpgain>0
      end
      if i.isFainted?
        return if !i.pbFaint
        next
      end
    end
    # Wish
    for i in priority
      if i.effects[:Wish]>0
        i.effects[:Wish]-=1
        if i.effects[:Wish]==0
          next if i.isFainted?
          hpgain=i.pbRecoverHP(i.effects[:WishAmount],true)
          if hpgain>0
            wishmaker=pbThisEx(i.index,i.effects[:WishMaker])
            pbDisplay(_INTL("{1}'s wish came true!",wishmaker))
          end
        end
      end
    end
    # Fire Pledge + Grass Pledge combination damage - should go here
    for i in priority
      next if i.isFainted?
      # Shed Skin
      if i.ability == :SHEDSKIN
        if (pbRandom(10)<3 || @field.effect == :DRAGONSDEN) && !i.status.nil?
          pbDisplay(_INTL("{1}'s Shed Skin cured its {2} problem!",i.pbThis,i.status.downcase))
          i.status=nil
          i.statusCount=0
          if @field.effect == :DRAGONSDEN
            pbDisplay(_INTL("{1}'s scaled sheen glimmers brightly!",i.pbThis))
            if i.effects[:HealBlock]==0
              hpgain=(i.totalhp/4.0).floor
              hpgain=i.pbRecoverHP(hpgain,true)
            end
            animDDShedSkin = true 
            if !i.pbTooHigh?(PBStats::SPEED)
              i.pbIncreaseStatBasic(PBStats::SPEED,1)
              pbCommonAnimation("StatUp",i,nil)
              animDDShedSkin = false
            end
            if !i.pbTooHigh?(PBStats::SPATK)
              i.pbIncreaseStatBasic(PBStats::SPATK,1)
              pbCommonAnimation("StatUp",i,nil) if animDDShedSkin
            end
            animDDShedSkin = true 
            if !i.pbTooLow?(PBStats::DEFENSE)
              i.pbReduceStat(PBStats::DEFENSE,1)
              pbCommonAnimation("StatDown",i,nil)
              animDDShedSkin = false
            end
            if !i.pbTooLow?(PBStats::SPDEF)
              i.pbReduceStat(PBStats::SPDEF,1)
              pbCommonAnimation("StatDown",i,nil) if animDDShedSkin
            end
          end
        end
      end
      # Hydration
      if i.ability == :HYDRATION && ((pbWeather== :RAINDANCE) || @field.effect == :WATERSURFACE || @field.effect == :UNDERWATER)
        if !i.status.nil?
          pbDisplay(_INTL("{1}'s Hydration cured its {2} problem!",i.pbThis,i.status.downcase))
          i.status=nil
          i.statusCount=0
        end
        if @field.effect == :CLOUDS && pbWeather==:RAINDANCE && i.hp!=i.totalhp
          i.pbRecoverHP((i.totalhp/16.0).floor,true)
          pbDisplay(_INTL("{1}'s Hydration restored its health!",i.pbThis))
        end
      end
      if i.ability == :WATERVEIL && (@field.effect == :WATERSURFACE || @field.effect == :UNDERWATER)
        if !i.status.nil?
          pbDisplay(_INTL("{1}'s Water Veil cured its {2} problem!",i.pbThis,i.status.downcase))
          i.status=nil
          i.statusCount=0
        end
      end
      # Healer
      if i.ability == :HEALER
        partner=i.pbPartner
        if partner.hp >0 && !partner.status.nil?
          pbDisplay(_INTL("{1}'s Healer cured its partner's {2} problem!",i.pbThis,partner.status.downcase))
          partner.status=nil
          partner.statusCount=0
        end
      end
    end
    # Held berries/Leftovers/Black Sludge
    for i in priority
      next if i.isFainted?
      i.pbBerryCureCheck(true)
      if i.isFainted?
        return if !i.pbFaint
        next
      end
    end
    # Aqua Ring
    for i in priority
      next if i.hp<=0
      if i.effects[:AquaRing]
        if @field.effect == :CORROSIVEMIST && !i.hasType?(:STEEL) && !i.hasType?(:POISON)
          @scene.pbDamageAnimation(i,0)
          i.pbReduceHP((i.totalhp/16.0).floor)
          pbDisplay(_INTL("{1}'s Aqua Ring absorbed poison!",i.pbThis))
          if i.hp<=0
            return if !i.pbFaint
          end
        elsif i.effects[:HealBlock]==0
          hpgain=(i.totalhp/16.0).floor
          if Rejuv && @battle.FE == :GRASSY
            hpgain=(hpgain*1.6).floor if i.hasWorkingItem(:BIGROOT)
          else
            hpgain=(hpgain*1.3).floor if i.hasWorkingItem(:BIGROOT)
          end
          hpgain=(hpgain*1.3).floor  if i.crested == :SHIINOTIC
          hpgain=(hpgain*2).floor if [:MISTY,:SWAMP,:WATERSURFACE,:UNDERWATER].include?(@field.effect)
          hpgain=i.pbRecoverHP(hpgain,true)
          pbDisplay(_INTL("{1}'s Aqua Ring restored its HP a little!",i.pbThis)) if hpgain>0
        end
        if !i.status.nil?
          pbDisplay(_INTL("{1}'s {2} was cured by Aqua Ring!",i.pbThis,i.status.downcase))
          i.status=nil
          i.statusCount=0
        end
      end
    end
    # Ingrain
    for i in priority
      next if i.hp<=0
      if i.effects[:Ingrain]
        if ((!Rejuv && @field.effect == :SWAMP) || @field.effect == :CORROSIVE || @field.effect == :CORRUPTED) && (!i.hasType?(:STEEL) && !i.hasType?(:POISON))
          @scene.pbDamageAnimation(i,0)
          i.pbReduceHP((i.totalhp/16.0).floor)
          pbDisplay(_INTL("{1} absorbed foul nutrients with its roots!",i.pbThis))
          if i.hp<=0
            return if !i.pbFaint
          end
        else
          if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,5)
            hpgain=(i.totalhp/4.0).floor
          elsif (@field.effect == :FOREST || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,2,5) || (Rejuv && @field.effect == :GRASSY) || @state.effects[:GRASSY] > 0)
            hpgain=(i.totalhp/8.0).floor
          elsif i.effects[:HealBlock]==0
            hpgain=(i.totalhp/16.0).floor
          end
          if i.effects[:HealBlock]==0
            if Rejuv && @battle.FE == :GRASSY
              hpgain=(hpgain*1.6).floor if i.hasWorkingItem(:BIGROOT)
            else
              hpgain=(hpgain*1.3).floor if i.hasWorkingItem(:BIGROOT)
            end
            hpgain=(hpgain*1.3).floor  if i.crested == :SHIINOTIC
            hpgain=i.pbRecoverHP(hpgain,true)
            pbDisplay(_INTL("{1} absorbed nutrients with its roots!",i.pbThis)) if hpgain>0
          end
        end
      end
    end
    # Leech Seed
    for i in priority
      if i.effects[:LeechSeed]>=0
        recipient=@battlers[i.effects[:LeechSeed]]
        if recipient && !recipient.isFainted? && i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM)# if recipient exists
          hploss=(i.totalhp/8.0).floor
          hploss= hploss * 2 if @field.effect == :WASTELAND
          pbCommonAnimation("LeechSeed",recipient,i)
          i.pbReduceHP(hploss,true)
          next if recipient.isFainted?
          if i.ability == :LIQUIDOOZE
            hploss= hploss * 2 if @field.effect == :MURKWATERSURFACE || @field.effect == :CORRUPTED || @field.effect == :WASTELAND
            if Rejuv && @battle.FE == :GRASSY
              hploss=(hploss*1.3).floor
              hploss=(hploss*1.6).floor if recipient.hasWorkingItem(:BIGROOT)
            else
              hploss=(hploss*1.3).floor if recipient.hasWorkingItem(:BIGROOT)
            end
            hploss=(hploss*1.3).floor if recipient.crested == :SHIINOTIC
            recipient.pbReduceHP(hploss,true)
            pbDisplay(_INTL("{1} sucked up the liquid ooze!",recipient.pbThis))
          else
            if recipient.effects[:HealBlock]==0
              if Rejuv && @battle.FE == :GRASSY
                hploss=(hploss*1.3).floor
                hploss=(hploss*1.6).floor if recipient.hasWorkingItem(:BIGROOT)
              else
                hploss=(hploss*1.3).floor if recipient.hasWorkingItem(:BIGROOT)
              end
              hploss=(hploss*1.3).floor if recipient.crested == :SHIINOTIC
              recipient.pbRecoverHP(hploss,true)
            end
            pbDisplay(_INTL("{1}'s health was sapped by Leech Seed!",i.pbThis))
          end
          if i.isFainted?
            return if !i.pbFaint
          end
          if recipient.isFainted?
            return if !recipient.pbFaint
          end
          if Rejuv && @field.effect == :SWAMP
            stat = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED].sample
            if i.pbCanReduceStatStage?(stat,true)
              i.pbReduceStat(stat,1,abilitymessage:true, statdropper: recipient)
            end
          end
        end
      end
    end
    for i in priority
      next if i.isFainted?
      # Petrification
      if i.status== :PETRIFIED && (i.effects[:Petrification]>=0) 
        recipient=@battlers[i.effects[:Petrification]]
        if recipient && !recipient.isFainted?  && i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) # if recipient exists
          pbCommonAnimation("Petrification",recipient,i)
          hploss=i.pbReduceHP((i.totalhp/8).floor,true)
          next if recipient.isFainted?
          if i.ability == :LIQUIDOOZE
            hploss= hploss * 2 if @field.effect == :MURKWATERSURFACE || @field.effect == :CORRUPTED || @field.effect == :WASTELAND
            if Rejuv && @battle.FE == :GRASSY
              hploss=(hploss*1.6).floor if recipient.hasWorkingItem(:BIGROOT)
            else
              hploss=(hploss*1.3).floor if recipient.hasWorkingItem(:BIGROOT)
            end
            hploss=(hploss*1.3).floor if recipient.crested == :SHIINOTIC
            recipient.pbReduceHP(hploss,true)
            pbDisplay(_INTL("{1} sucked up the liquid ooze!",recipient.pbThis))
          else
            if recipient.effects[:HealBlock]==0
              if Rejuv && @battle.FE == :GRASSY
                hploss=(hploss*1.6).floor if recipient.hasWorkingItem(:BIGROOT)
              else
                hploss=(hploss*1.3).floor if recipient.hasWorkingItem(:BIGROOT)
              end
              hploss=(hploss*1.3).floor if recipient.crested == :SHIINOTIC
              recipient.pbRecoverHP(hploss,true)
            end
            pbDisplay(_INTL("{1}'s health was drained by {2}!",i.pbThis,recipient.pbThis))
          end
          if i.isFainted?          
            return if !i.pbFaint
          end
          if recipient.isFainted?
            return if !recipient.pbFaint
          end
        end
      end
      # Poison/Bad poison
      if i.status== :POISON && i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && !(i.ability == :GUTS && @battle.FE == :CROWD)
        if (i.ability == :POISONHEAL || i.crested == :ZANGOOSE || i.crested == :GOODRA)
          if i.effects[:HealBlock]==0
            if i.hp<i.totalhp
              pbCommonAnimation("Poison",i,nil)
              i.pbRecoverHP((i.totalhp/8.0).floor,true)
              pbDisplay(_INTL("{1} is healed by poison!",i.pbThis))
            end
            if i.statusCount>0
              i.effects[:Toxic]+=1
              i.effects[:Toxic]=[15,i.effects[:Toxic]].min
            end
          end
        else
          i.pbContinueStatus
          if i.statusCount==0
            i.pbReduceHP((i.totalhp/8.0).floor)
          else
            i.effects[:Toxic]+=1
            i.effects[:Toxic]=[15,i.effects[:Toxic]].min
            i.pbReduceHP((i.totalhp/16.0).floor*i.effects[:Toxic])
          end
          if pbCheckGlobalAbility(:STOPPN)
            statdrop = false
            statraise = false
            contcheck = (i.ability == :CONTRARY)
            if i.pbCanReduceStatStage?(PBStats::DEFENSE,false)
              i.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false)
              contcheck ? statraise = true : statdrop = true
            end
            if i.pbCanReduceStatStage?(PBStats::SPDEF,false)
              i.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false)
              contcheck ? statraise = true : statdrop = true
            end
            if statdrop
              pbDisplay(_INTL("{1}'s defenses were corroded...",i.pbThis))
            elsif statraise
              pbDisplay(_INTL("{1}'s defenses increased!",i.pbThis))
            end
          end
        end
      end
      # Burn
      if i.status== :BURN && i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM)
        i.pbContinueStatus
        if !(i.ability == :GUTS && @battle.FE == :CROWD)
          if i.ability == :HEATPROOF || @field.effect == :ICY
            i.pbReduceHP((i.totalhp/32.0).floor)
          else
            i.pbReduceHP((i.totalhp/16.0).floor)
          end
        end
      end
      # Frostbite
      if i.status== :FROSTBITE && i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM)
        mult = 1
        if (@field.effect == :FROZENDIMENSION)
          mult = 2
        end
        i.pbContinueStatus
        i.pbReduceHP((mult * i.totalhp/16.0).floor)
      end
      # Shiinotic Crest
      if i.crested == :SHIINOTIC
        for j in priority
          next if j == i
          next if j.isFainted?
          next if !i.pbIsOpposing?(j.index)
          mult = 1
          mult = 2 if !j.status.nil?
          hploss=(j.totalhp/16.0 * mult).floor
          hploss= hploss * 2 if @field.effect == :WASTELAND
          pbCommonAnimation("LeechSeed",i,j)
          j.pbReduceHP(hploss,true)
          if j.ability == :LIQUIDOOZE
            hploss= hploss * 2 if @field.effect == :MURKWATERSURFACE || @field.effect == :CORRUPTED || @field.effect == :WASTELAND
            if Rejuv && @battle.FE == :GRASSY
              hploss=(hploss*1.6).floor if i.hasWorkingItem(:BIGROOT)
            else
              hploss=(hploss*1.3).floor if i.hasWorkingItem(:BIGROOT)
            end
            hploss=(hploss*1.3).floor if i.crested == :SHIINOTIC
            i.pbReduceHP(hploss,true)
            pbDisplay(_INTL("{1} sucked up the liquid ooze!",i.pbThis))
          else
            if i.effects[:HealBlock]==0
              if Rejuv && @battle.FE == :GRASSY
                hploss=(hploss*1.6).floor if i.hasWorkingItem(:BIGROOT)
              else
                hploss=(hploss*1.3).floor if i.hasWorkingItem(:BIGROOT)
              end
              hploss=(hploss*1.3).floor if i.crested == :SHIINOTIC
              i.pbRecoverHP(hploss,true)
            end
            pbDisplay(_INTL("{1}'s health was sapped by {2}'s Crest!",i.pbThis,i.pbThis))
          end
          if j.isFainted?
            return if !j.pbFaint
          end
          if i.isFainted?
            return if !i.pbFaint
          end
        end
      end
      # Runerigus and Cofagrigus Crest
      if i.crested == :RUNERIGUS || i.crested == :COFAGRIGUS
        for j in priority
          next if j == i
          next if j.isFainted?
          next if !i.pbIsOpposing?(j.index)
          next if j.effects[:MeanLook]<0
          hploss=(j.totalhp/16.0).floor
          hploss= hploss * 2 if @field.effect == :WASTELAND
          pbCommonAnimation("Curse",target=j)
          j.pbReduceHP(hploss,true)
          if j.ability == :LIQUIDOOZE
            hploss= hploss * 2 if @field.effect == :MURKWATERSURFACE || @field.effect == :CORRUPTED || @field.effect == :WASTELAND
            if Rejuv && @battle.FE == :GRASSY
              hploss=(hploss*1.6).floor if i.hasWorkingItem(:BIGROOT)
            else
              hploss=(hploss*1.3).floor if i.hasWorkingItem(:BIGROOT)
            end
            hploss=(hploss*1.3).floor if i.crested == :SHIINOTIC
            i.pbReduceHP(hploss,true)
            pbDisplay(_INTL("{1} sucked up the liquid ooze!",i.pbThis))
          else
            if i.effects[:HealBlock]==0
              if Rejuv && @battle.FE == :GRASSY
                hploss=(hploss*1.6).floor if i.hasWorkingItem(:BIGROOT)
              else
                hploss=(hploss*1.3).floor if i.hasWorkingItem(:BIGROOT)
              end
              hploss=(hploss*1.3).floor if i.crested == :SHIINOTIC
              i.pbRecoverHP(hploss,true)
            end
            pbDisplay(_INTL("{1}'s health was drained by {2}'s Crest!",i.pbThis,i.pbThis))
          end
          if j.isFainted?
            return if !j.pbFaint
          end
          if i.isFainted?
            return if !i.pbFaint
          end
        end
      end
      
      # Nightmare
      if i.effects[:Nightmare] && i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && @field.effect != :RAINBOW
        if ((i.status== :SLEEP || (i.ability == :COMATOSE && @battle.FE != :ELECTERRAIN)) || @battle.FE == :INFERNAL || i.pbOpposing1.ability == :WORLDOFNIGHTMARES || i.pbOpposing2.ability == :WORLDOFNIGHTMARES)
          pbCommonAnimation("Nightmare",i,nil)
          pbDisplay(_INTL("{1} is locked in a nightmare!",i.pbThis))
          hploss = (i.totalhp/4.0).floor
          hploss = (i.totalhp/3.0).floor if @field.effect == :HAUNTED ||@field.effect == :DARKNESS3
          i.pbReduceHP(hploss,true)
        else
          i.effects[:Nightmare]=false
        end
      end
      if i.isFainted?
        return if !i.pbFaint
        next
      end
    end
     # Curse
    for i in priority
      next if i.isFainted?
      next if !i.effects[:Curse]
      if @field.effect == :HOLY 
        i.effects[:Curse] = false
        pbDisplay(_INTL("{1}'s curse was lifted!",i.pbThis))
      end
      if i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM)
        pbCommonAnimation("Curse",i,nil)
        pbDisplay(_INTL("{1} is afflicted by the curse!",i.pbThis))
        i.pbReduceHP((i.totalhp/4.0).floor,true)
      end
      if i.isFainted?
        return if !i.pbFaint
        next
      end
    end

    # Multi-turn attacks (Bind/Clamp/Fire Spin/Magma Storm/Sand Tomb/Whirlpool/Wrap)
    for i in priority
      next if i.isFainted?
      i.pbBerryCureCheck
      if i.effects[:MultiTurn]>0
        i.effects[:MultiTurn]-=1
        movename=getMoveName(i.effects[:MultiTurnAttack])
        if i.effects[:MultiTurn]==0
          pbDisplay(_INTL("{1} was freed from {2}!",i.pbThis,movename))
          i.effects[:BindingBand] = false
        elsif !(i.ability == :MAGICGUARD) && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM)
          pbDisplay(_INTL("{1} is hurt by {2}!",i.pbThis,movename))
          if (i.effects[:MultiTurnAttack] == :BIND)
            pbCommonAnimation("Bind",i,nil)
          elsif (i.effects[:MultiTurnAttack] == :CLAMP)
            pbCommonAnimation("Clamp",i,nil)
          elsif (i.effects[:MultiTurnAttack] == :FIRESPIN)
            pbCommonAnimation("FireSpin",i,nil)
          elsif (i.effects[:MultiTurnAttack] == :MAGMASTORM)
            pbCommonAnimation("Magma Storm",i,nil)
          elsif (i.effects[:MultiTurnAttack] == :SANDTOMB) || (i.effects[:MultiTurnAttack] == :DESERTSMARK)
            pbCommonAnimation("SandTomb",i,nil)
          elsif (i.effects[:MultiTurnAttack] == :WRAP)
            pbCommonAnimation("Wrap",i,nil)
          elsif (i.effects[:MultiTurnAttack] == :INFESTATION)
            pbCommonAnimation("Infestation",i,nil)
          elsif (i.effects[:MultiTurnAttack] == :WHIRLPOOL)
            pbCommonAnimation("Whirlpool",i,nil)
          else
            pbCommonAnimation("Wrap",i,nil)
          end
          @scene.pbDamageAnimation(i,0)
          if i.effects[:BindingBand]
            i.pbReduceHP((i.totalhp/6.0).floor)
          elsif (i.effects[:MultiTurnAttack] == :MAGMASTORM) && @field.effect == :DRAGONSDEN
            i.pbReduceHP((i.totalhp/6.0).floor)
          elsif (i.effects[:MultiTurnAttack] == :SANDTOMB) && @field.effect == :DESERT
            i.pbReduceHP((i.totalhp/6.0).floor)
          elsif (i.effects[:MultiTurnAttack] == :WHIRLPOOL) && (@field.effect == :WATERSURFACE || @field.effect == :UNDERWATER)
            i.pbReduceHP((i.totalhp/6.0).floor)
          elsif (i.effects[:MultiTurnAttack] == :INFESTATION) && @field.effect == :FOREST
            i.pbReduceHP((i.totalhp/6.0).floor)
          elsif (i.effects[:MultiTurnAttack] == :FIRESPIN) && (@field.effect == :BURNING || @field.effect == :HAUNTED)
            i.pbReduceHP((i.totalhp/6.0).floor)
          elsif (i.effects[:MultiTurnAttack] == :INFESTATION) && @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,5)
            case @battle.FE
              when :FLOWERGARDEN3 then i.pbReduceHP((i.totalhp/6.0).floor)
              when :FLOWERGARDEN4 then i.pbReduceHP((i.totalhp/4.0).floor)
              when :FLOWERGARDEN5 then i.pbReduceHP((i.totalhp/3.0).floor)
            end
          elsif (i.effects[:MultiTurnAttack] == :THUNDERCAGE) && (@field.effect == :ELECTERRAIN)
            i.pbReduceHP((i.totalhp/6.0).floor)
          elsif (i.effects[:MultiTurnAttack] == :SNAPTRAP) && (@field.effect == :GRASSY)
            i.pbReduceHP((i.totalhp/6.0).floor)
          else
            i.pbReduceHP((i.totalhp/8.0).floor)
          end
          if (i.effects[:MultiTurnAttack] == :SANDTOMB) && @field.effect == :ASHENBEACH
            i.pbReduceStat(PBStats::ACCURACY,1,abilitymessage:true)
          end
          if Rejuv && @field.effect == :SWAMP && ((i.effects[:MultiTurnAttack] == :SNAPTRAP) || (i.effects[:MultiTurnAttack] == :INFESTATION))
            stat = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED].sample
            if i.pbCanReduceStatStage?(stat,true)
              i.pbReduceStat(stat,1,abilitymessage:true)
            end
          end
        end
      end
      if i.hp<=0
        return if !i.pbFaint
        next
      end
    end
    # Taunt
    for i in priority
      next if i.isFainted?
      next if i.effects[:Taunt] == 0
      i.effects[:Taunt]-=1
      if i.effects[:Taunt]==0
        pbDisplay(_INTL("{1} recovered from the taunting!",i.pbThis))
      end
    end
    # Encore
    for i in priority
      next if i.isFainted?
      next if i.effects[:Encore] == 0
      if i.moves[i.effects[:EncoreIndex]].move!=i.effects[:EncoreMove]
        i.effects[:Encore]=0
        i.effects[:EncoreIndex]=0
        i.effects[:EncoreMove]=0
      else
        i.effects[:Encore]-=1
        if i.effects[:Encore]==0 || i.moves[i.effects[:EncoreIndex]].pp==0
          i.effects[:Encore]=0
          pbDisplay(_INTL("{1}'s encore ended!",i.pbThis))
        end
      end
    end
    # Disable/Cursed Body
    for i in priority
      next if i.isFainted?
      next if i.effects[:Disable]==0
      i.effects[:Disable]-=1
      if i.effects[:Disable]==0
        i.effects[:DisableMove]=0
        pbDisplay(_INTL("{1} is disabled no more!",i.pbThis))
      end
    end
    # Magnet Rise
    for i in priority
      next if i.isFainted?
      if i.effects[:MagnetRise]>0
        i.effects[:MagnetRise]-=1
        if i.effects[:MagnetRise]==0
          pbDisplay(_INTL("{1} stopped levitating.",i.pbThis))
        end
      end
    end
    # ChtonicMalady
    for i in priority
      next if i.isFainted?
      next if i.effects[:Torment] == false
      if i.effects[:ChtonicMalady]>0
        i.effects[:ChtonicMalady]-=1
        if i.effects[:ChtonicMalady]==0
          i.effects[:Torment]=false
          pbDisplay(_INTL("{1}'s torment wore off.",i.pbThis))
        end
      end
    end
    # Telekinesis
    for i in priority
      next if i.isFainted?
      if i.effects[:Telekinesis]>0
        i.effects[:Telekinesis]-=1
        if i.effects[:Telekinesis]==0
          pbDisplay(_INTL("{1} stopped levitating.",i.pbThis))
        end
      end
    end
    # Heal Block
    for i in priority
      next if i.isFainted?
      if i.effects[:HealBlock]>0
        i.effects[:HealBlock]-=1
        if i.effects[:HealBlock]==0
          pbDisplay(_INTL("The heal block on {1} ended.",i.pbThis))
        end
      end
    end
    # Embargo
    # @SWu todo: change embargo to have an effect on the whole team side (done)
    for i in priority
      next if i.isFainted?
      if i.effects[:Embargo]>0
        i.effects[:Embargo]-=1
        if i.effects[:Embargo]==0
          pbDisplay(_INTL("The embargo on {1} was lifted.",i.pbThis(true)))
        end
      end
    end
    # Yawn
    for i in priority
      next if i.isFainted?
      if i.effects[:Yawn]>0
        i.effects[:Yawn]-=1
        if i.effects[:Yawn]==0 && i.pbCanSleepYawn?
          i.pbSleep
          pbDisplay(_INTL("{1} fell asleep!",i.pbThis))
          i.pbBerryCureCheck
        end
      end
    end
    # Perish Song
    perishSongUsers=[]
    for i in priority
      next if i.isFainted?
      if i.effects[:PerishSong]>0
        if (i.isbossmon && i.immunities[:moves].include?(:PERISHSONG))
          pbDisplay(_INTL("{1} grew resistant to the Perish Song!",i.pbThis))
          i.effects[:PerishSong]=0
          next
        end
        i.effects[:PerishSong]-=1
        pbDisplay(_INTL("{1}'s Perish count fell to {2}!",i.pbThis,i.effects[:PerishSong]))
        if i.effects[:PerishSong]==0
          i.immunities[:moves].push(:PERISHSONG) if i.isbossmon
          perishSongUsers.push(i.effects[:PerishSongUser])
          i.pbReduceHP(i.hp,true)
        end
      end
      if i.isFainted?
        return if !i.pbFaint
      end
    end
    if perishSongUsers.length>0
      # If all remaining Pokemon fainted by a Perish Song triggered by a single side
      if (perishSongUsers.find_all{|item| pbIsOpposing?(item) }.length==perishSongUsers.length) ||
         (perishSongUsers.find_all{|item| !pbIsOpposing?(item) }.length==perishSongUsers.length)
        pbJudgeCheckpoint(@battlers[perishSongUsers[0]])
      end
    end
    if @decision>0
      pbGainEXP
      return
    end
    texts = ["Your","The opposing"]
    # Reflect
    for i in 0...2
      next if sides[i].effects[:Reflect] == 0
      sides[i].effects[:Reflect]-=1
      pbDisplay(_INTL("#{texts[i]} team's Reflect faded!")) if sides[i].effects[:Reflect]==0
    end
    # Light Screen
    for i in 0...2
      next if sides[i].effects[:LightScreen] == 0
      sides[i].effects[:LightScreen]-=1
      pbDisplay(_INTL("#{texts[i]} team's Light Screen faded!")) if sides[i].effects[:LightScreen]==0
    end
    # Aurora Veil
    for i in 0...2
      next if sides[i].effects[:AuroraVeil] == 0
      sides[i].effects[:AuroraVeil]-=1
      pbDisplay(_INTL("#{texts[i]} team's Aurora Veil faded!")) if sides[i].effects[:AuroraVeil]==0
    end
    for i in 0...2
      next if sides[i].effects[:AreniteWall] == 0
      sides[i].effects[:AreniteWall]-=1
      pbDisplay(_INTL("#{texts[i]} team's Arenite Wall faded!")) if sides[i].effects[:AreniteWall]==0
    end
    # Safeguard
    for i in 0...2
      next if sides[i].effects[:Safeguard] == 0
      sides[i].effects[:Safeguard]-=1
      pbDisplay(_INTL("#{texts[i]} team is no longer protected by Safeguard!")) if sides[i].effects[:Safeguard]==0
    end
    # Mist
    for i in 0...2
      next if sides[i].effects[:Mist] == 0
      sides[i].effects[:Mist]-=1
      pbDisplay(_INTL("#{texts[i]} team's Mist faded!")) if sides[i].effects[:Mist]==0
    end
    # Embargo
    for i in 0...2
      next if sides[i].effects[:Embargo] == 0
      sides[i].effects[:Embargo]-=1
      pbDisplay(_INTL("#{texts[i]} team's Embargo was lifted.")) if sides[i].effects[:Embargo]==0
    end
    # Tailwind
    for i in 0...2
      next if sides[i].effects[:Tailwind] == 0
      sides[i].effects[:Tailwind]-=1
      pbDisplay(_INTL("#{texts[i]} team's tailwind stopped blowing!")) if sides[i].effects[:Tailwind]==0
    end
    # Lucky Chant
    for i in 0...2
      next if sides[i].effects[:LuckyChant] == 0
      sides[i].effects[:LuckyChant]-=1
      pbDisplay(_INTL("#{texts[i]} team's Lucky Chant faded!")) if sides[i].effects[:LuckyChant]==0
    end
    # Mud Sport
    if @state.effects[:MudSport]>0
      @state.effects[:MudSport]-=1
      if @state.effects[:MudSport]==0
        if Rejuv && @field.backup == :ELECTERRAIN && @field.effect != :ELECTERRAIN
          breakField
          pbDisplay(_INTL("The field electrified again!"))
        else
          pbDisplay(_INTL("The effects of Mud Sport faded."))
        end
      end
    end
    # Water Sport
    if @state.effects[:WaterSport]>0
      @state.effects[:WaterSport]-=1
      pbDisplay(_INTL("The effects of Water Sport faded.")) if @state.effects[:WaterSport]==0
    end
    # Gravity
    if @state.effects[:Gravity]>0
      @state.effects[:Gravity]-=1 if @field.effect != :FROZENDIMENSION
      if @state.effects[:Gravity]==0
        if @field.backup == :NEWWORLD && @field.effect != :NEWWORLD
          breakField
          pbDisplay(_INTL("The world broke apart again!"))
        else
          pbDisplay(_INTL("Gravity returned to normal."))
        end
      end
    end

    # Terrain
    if @field.duration>0
      @field.checkPermCondition(self)
    end
    if @field.duration>0
      @field.duration-=1
      @field.duration = 0 if @field.duration_condition && !@field.duration_condition.call(self)
      if @field.duration==0
        endTempField
        pbDisplay(_INTL("The terrain returned to normal."))
      end
    end
    # Terrain overlays
    if @state.effects[:ELECTERRAIN]>0
      @state.effects[:ELECTERRAIN]-=1 if @field.effect != :FROZENDIMENSION
      pbDisplay(_INTL("The surging electricity dissipated.")) if @state.effects[:ELECTERRAIN]==0
      quarkdriveCheck
    end
    if @state.effects[:GRASSY]>0
      @state.effects[:GRASSY]-=1 if @field.effect != :FROZENDIMENSION
      pbDisplay(_INTL("The surrounding grass withered.")) if @state.effects[:GRASSY]==0
    end
    if @state.effects[:MISTY]>0
      @state.effects[:MISTY]-=1 if @field.effect != :FROZENDIMENSION
      pbDisplay(_INTL("The surrounding mist dispersed.")) if @state.effects[:MISTY]==0
    end
    if @state.effects[:PSYTERRAIN]>0
      @state.effects[:PSYTERRAIN]-=1 if @field.effect != :FROZENDIMENSION
      pbDisplay(_INTL("The psychic energy left as mysteriously as it came.")) if @state.effects[:PSYTERRAIN]==0
    end
    if @state.effects[:RAINBOW]>0
      @state.effects[:RAINBOW]-=1 if @field.effect != :FROZENDIMENSION
      pbDisplay(_INTL("The rainbow disappeared.")) if @state.effects[:RAINBOW]==0
    end
    # Trick Room - should go here
    # Wonder Room - should go here
    # Magic Room
    if @state.effects[:MagicRoom]>0
      @state.effects[:MagicRoom]-=1 if @field.effect != :FROZENDIMENSION
      pbDisplay(_INTL("The area returned to normal.")) if @state.effects[:MagicRoom]==0
    end
    # Fairy Lock
    if @state.effects[:FairyLock]>0
      @state.effects[:FairyLock]-=1
      # Fairy Lock seems to have no end-of-effect text so I've added some.
      pbDisplay(_INTL("The Fairy Lock was released.")) if @state.effects[:FairyLock]==0
    end
    # Uproar
    for i in priority
      next if i.isFainted?
      if i.effects[:Uproar]>0
        for j in priority
          if !j.isFainted? && j.status== :SLEEP && !j.ability == (:SOUNDPROOF)
            j.effects[:Nightmare]=false
            j.status=nil
            j.statusCount=0
            pbDisplay(_INTL("{1} woke up in the uproar!",j.pbThis))
          end
        end
        i.effects[:Uproar]-=1
        if i.effects[:Uproar]==0
          pbDisplay(_INTL("{1} calmed down.",i.pbThis))
        else
          pbDisplay(_INTL("{1} is making an uproar!",i.pbThis))
        end
      end
    end

    # Slow Start's end message
    for i in priority
      next if i.isFainted?
      if i.ability==:SLOWSTART && i.turncount==4 && !@battle.FE == :DEEPEARTH
        pbDisplay(_INTL("{1} finally got its act together!",i.pbThis))
      end
    end

    #Wasteland hazard interaction
    if @field.effect == :WASTELAND
      for i in priority
        is_fainted_before = i.isFainted?
        partner_fainted_before = @doublebattle && i.pbPartner.isFainted?
        # Stealth Rock
        if i.pbOwnSide.effects[:StealthRock]
          pbDisplay(_INTL("The waste swallowed up the pointed stones!"))
          i.pbOwnSide.effects[:StealthRock]=false
          pbDisplay(_INTL("...Rocks spewed out from the ground below!"))
          for mon in [i, i.pbPartner]
            next if mon.isFainted? || PBStuff::TWOTURNMOVE.include?(mon.effects[:TwoTurnAttack])
            eff=PBTypes.twoTypeEff(:ROCK,mon.type1,mon.type2)
            next if eff <=0
            @scene.pbDamageAnimation(mon,0)
            mon.pbReduceHP([(mon.totalhp*eff/16).floor,1].max)
          end
        end

        # Steelsurge
        if i.pbOwnSide.effects[:Steelsurge]
          pbDisplay(_INTL("The waste swallowed up the metal debris!"))
          i.pbOwnSide.effects[:Steelsurge]=false
          pbDisplay(_INTL("...Debris spewed out from the ground below!"))
          for mon in [i, i.pbPartner]
            next if mon.isFainted? || PBStuff::TWOTURNMOVE.include?(mon.effects[:TwoTurnAttack])
            eff=PBTypes.twoTypeEff(:STEEL,mon.type1,mon.type2)
            next if eff <=0
            @scene.pbDamageAnimation(mon,0)
            mon.pbReduceHP([(mon.totalhp*eff/16).floor,1].max)
          end
        end

        # Volcalith
        if i.pbOwnSide.effects[:Volcalith]
          pbDisplay(_INTL("The waste swallowed up the metal debris!"))
          i.pbOwnSide.effects[:Volcalith]=false
          pbDisplay(_INTL("...Debris spewed out from the ground below!"))
          for mon in [i, i.pbPartner]
            next if mon.isFainted? || PBStuff::TWOTURNMOVE.include?(mon.effects[:TwoTurnAttack])
            eff=PBTypes.twoTypeEff(:FIRE,mon.type1,mon.type2)
            next if eff <=0
            @scene.pbDamageAnimation(mon,0)
            mon.pbReduceHP([(mon.totalhp*eff/16).floor,1].max)
          end
        end

        # Spikes
        if i.pbOwnSide.effects[:Spikes]>0
          pbDisplay(_INTL("The waste swallowed up the spikes!"))
          i.pbOwnSide.effects[:Spikes]=0
          pbDisplay(_INTL("...Stalagmites burst up from the ground!"))
          for mon in [i, i.pbPartner]
            if !mon.isFainted? && !mon.isAirborne? && !PBStuff::TWOTURNMOVE.include?(mon.effects[:TwoTurnAttack]) # Dig, Dive, etc
              @scene.pbDamageAnimation(mon,0)
              mon.pbReduceHP([(mon.totalhp/3.0).floor,1].max)
            end
          end
        end

        # Toxic Spikes
        if i.pbOwnSide.effects[:ToxicSpikes]>0
          pbDisplay(_INTL("The waste swallowed up the toxic spikes!"))
          i.pbOwnSide.effects[:ToxicSpikes]=0
          pbDisplay(_INTL("...Poison needles shot up from the ground!"))
          for mon in [i, i.pbPartner]
            next if mon.isFainted? || mon.isAirborne? || mon.hasType?(:STEEL) || mon.hasType?(:POISON)
            next if PBStuff::TWOTURNMOVE.include?(mon.effects[:TwoTurnAttack])
            @scene.pbDamageAnimation(mon,0)
            mon.pbReduceHP([(mon.totalhp/8.0).floor,1].max)
            if mon.status.nil? && mon.pbCanPoison?(false)
              mon.status=:POISON
              mon.statusCount=1
              mon.effects[:Toxic]=0
              pbCommonAnimation("Poison",mon,nil)
            end
          end
        end

        # Sticky Web
        if i.pbOwnSide.effects[:StickyWeb]
          pbDisplay(_INTL("The waste swallowed up the sticky web!"))
          i.pbOwnSide.effects[:StickyWeb]=false
          pbDisplay(_INTL("...Sticky string shot out of the ground!"))
          for mon in [i, i.pbPartner]
            next if mon.isFainted? && !PBStuff::TWOTURNMOVE.include?(mon.effects[:TwoTurnAttack])
            if mon.ability == :CONTRARY && !mon.pbTooHigh?(PBStats::SPEED)
              mon.pbIncreaseStatBasic(PBStats::SPEED,4)
                pbCommonAnimation("StatUp",mon,nil)
                pbDisplay(_INTL("{1}'s Speed went way up!",mon.pbThis))
            elsif !mon.pbTooLow?(PBStats::SPEED)
              mon.pbReduceStatBasic(PBStats::SPEED,4)
              pbCommonAnimation("StatDown",mon,nil)
              pbDisplay(_INTL("{1}'s Speed was severely lowered!",mon.pbThis))
            end
          end
        end

        # Fainting
        if @doublebattle && !partner_fainted_before
          partner=i.pbPartner
          if partner && partner.hp<=0
            partner.pbFaint
          end
        end
        if i.hp<=0 && !is_fainted_before
          return if !i.pbFaint
          next
        end
      end
    end
    # End Wasteland hazards
    for i in priority
      next if i.isFainted?
      # Mimicry
      if i.ability == :MIMICRY
        protype = -1
        case @field.effect
          when :CRYSTALCAVERN
            protype = @field.getRoll
          when :NEWWORLD
            protype = @battle.getRandomType
          else
            protype = @field.mimicry if @field.mimicry
        end
        prot1 = i.type1
        prot2 = i.type2
        camotype = protype
        if !camotype.nil? && !i.hasType?(camotype)
          i.type1=camotype
          i.type2=nil
          pbDisplay(_INTL("{1} had its type changed to {2}!",i.pbThis,camotype.capitalize))
        end
      end
      # Speed Boost
      # A Pokémon's turncount is 0 if it became active after the beginning of a round
      if i.turncount>0 && (i.ability == :SPEEDBOOST || (@field.effect == :ELECTERRAIN && i.ability == :MOTORDRIVE) || 
        ([:VOLCANIC,:VOLCANICTOP,:WATERSURFACE,:UNDERWATER,:INFERNAL].include?(@field.effect) && i.ability == :STEAMENGINE))
        if !i.pbTooHigh?(PBStats::SPEED)
          i.pbIncreaseStatBasic(PBStats::SPEED,1)
          pbCommonAnimation("StatUp",i,nil)
          pbDisplay(_INTL("{1}'s {2} raised its Speed!",i.pbThis, getAbilityName(i.ability)))
        end
      end
      if i.ability == :ACCUMULATION && i.turncount>0 && i.lastMoveUsed!=:SPITUP && i.lastMoveUsed!=:SWALLOW
        if i.effects[:Stockpile] <3
          i.effects[:Stockpile] +=1
          i.pbIncreaseStatBasic(PBStats::DEFENSE,1)
          i.effects[:StockpileDef] +=1
          i.pbIncreaseStatBasic(PBStats::SPDEF,1)
          i.effects[:StockpileSpDef] +=1
          pbDisplay(_INTL("{1} stockpiled with Accumulation!",i.pbThis))
        end
      end
      if @field.effect == :SWAMP && ![:WHITESMOKE,:CLEARBODY,:QUICKFEET,:SWIFTSWIM,:PROPELLERTAIL,:STEAMENGINE].include?(i.ability) && (i.item != :HEAVYDUTYBOOTS)
        if !i.isAirborne?
          if !i.pbTooLow?(PBStats::SPEED)
            contcheck = i.ability == :CONTRARY
            candrop = i.pbCanReduceStatStage?(PBStats::SPEED)
            canraise = i.pbCanIncreaseStatStage?(PBStats::SPEED) if contcheck
            statdrop = 1
            statdrop = 2 if i.effects[:MultiTurn]>0
            i.pbReduceStat(PBStats::SPEED,1, statmessage: false)
            pbDisplay(_INTL("{1}'s Speed sank...",i.pbThis)) if !contcheck && candrop
            pbDisplay(_INTL("{1}'s Speed rose!",i.pbThis)) if contcheck && canraise
          end
        end
      end
      if (@field.effect == :DESERT || @field.effect == :HAUNTED) && i.ability == :WANDERINGSPIRIT
        if !i.pbTooLow?(PBStats::SPEED)
          i.pbReduceStat(PBStats::SPEED,1, statmessage: false)
          pbDisplay(_INTL("{1}'s Wandering Spirit lowered its Speed!",i.pbThis))
        end
      end
      #sleepyswamp #sleepydimension #spookydreams #fairyringsleep
      if (i.status== :SLEEP || (i.ability == :COMATOSE && @battle.FE != :ELECTERRAIN)) && !(i.ability == :MAGICGUARD)
        if @field.effect == :SWAMP # Swamp Field
          if i.effects[:MultiTurn]>0
            hploss=i.pbReduceHP((i.totalhp/8.0).floor,true)
          else
            hploss=i.pbReduceHP((i.totalhp/16.0).floor,true)
          end
          pbDisplay(_INTL("{1}'s strength is sapped by the swamp!",i.pbThis)) if hploss>0
        elsif @field.effect == :DIMENSIONAL #Dimensional Field (Rejuv)
          hploss=i.pbReduceHP((i.totalhp/16.0).floor,true)
          pbDisplay(_INTL("{1}'s dream is corrupted by the dimension!",i.pbThis)) if hploss>0
        elsif @field.effect == :HAUNTED && !(i.hasType?(:GHOST)) #Haunted Field (Rejuv)
          hploss=i.pbReduceHP((i.totalhp/16.0).floor,true)
          pbDisplay(_INTL("{1}'s dream is corrupted by the evil spirits!",i.pbThis)) if hploss>0
        elsif @field.effect == :BEWITCHED #Bewitched Woods (Rejuv)
          hploss=i.pbReduceHP((i.totalhp/16.0).floor,true)
          pbDisplay(_INTL("{1}'s dream is corrupted by the evil in the woods!",i.pbThis)) if hploss>0
        end
      end
      if i.hp<=0
        return if !i.pbFaint
        next
      end
      #sleepyrainbow
      if (i.status== :SLEEP || (i.ability == :COMATOSE && @battle.FE != :ELECTERRAIN))
        if @field.effect == :RAINBOW && i.effects[:HealBlock]==0#Rainbow Field
        hpgain=(i.totalhp/16.0).floor
        hpgain=i.pbRecoverHP(hpgain,true)
        pbDisplay(_INTL("{1} recovered health in its peaceful sleep!",i.pbThis))
        end
      end
      #sleepycorro
      if (i.status== :SLEEP || (i.ability == :COMATOSE && @battle.FE != :ELECTERRAIN)) && i.ability != :MAGICGUARD && !(i.ability == :POISONHEAL || i.crested == :ZANGOOSE || i.crested == :GOODRA) && i.ability != :TOXICBOOST &&
      i.ability != :WONDERGUARD && !i.isAirborne? && !i.hasType?(:STEEL) && !i.hasType?(:POISON) && @field.effect == :CORROSIVE
        hploss=i.pbReduceHP((i.totalhp/16.0).floor,true)
        pbDisplay(_INTL("{1} is seared by the corrosion!",i.pbThis)) if hploss>0
      end
      if i.hp<=0
        return if !i.pbFaint
        next
      end
    # Water Compaction on Water-based Fields
    if i.ability == :WATERCOMPACTION
      if [:SWAMP,:WATERSURFACE,:UNDERWATER,:MURKWATERSURFACE].include?(@field.effect)
        if !i.pbTooHigh?(PBStats::DEFENSE)
          i.pbIncreaseStatBasic(PBStats::DEFENSE,2)
          pbCommonAnimation("StatUp",i,nil)
          pbDisplay(_INTL("{1}'s Water Compaction sharply raised its defense!", i.pbThis))
         end
       end
     end
     if i.effects[:Octolock]>=0
      locklowered = false
      lockboost = false
      contcheck = (i.ability == :CONTRARY)
      if i.pbCanReduceStatStage?(PBStats::DEFENSE,false) || i.pbCanReduceStatStage?(PBStats::SPDEF,false)
        pbCommonAnimation("Bind",i,nil)
        if i.pbCanReduceStatStage?(PBStats::DEFENSE,false)
          i.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false,statdropper:@battlers[i.effects[:Octolock]])
          contcheck ? lockboost = true : locklowered = true
        end
        if i.pbCanReduceStatStage?(PBStats::SPDEF,false)
          i.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false,statdropper:@battlers[i.effects[:Octolock]])
          contcheck ? lockboost = true : locklowered = true
        end
      end
      if locklowered
        pbDisplay(_INTL("The Octolock lowered {1}'s defenses!",i.pbThis))
      elsif lockboost
        pbDisplay(_INTL("The Octolock increased {1}'s defenses!",i.pbThis))
      end
    end
    if Rejuv && i.effects[:SwampWeb]
      if @battle.FE == :SWAMP 
        stat = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED].sample
        if i.pbCanReduceStatStage?(stat,true)
          i.pbReduceStat(stat,1,abilitymessage:true)
        end
      end
    end
    # Bad Dreams
    if (i.status== :SLEEP || (i.ability == :COMATOSE && @battle.FE != :ELECTERRAIN)) && i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && @field.effect != :RAINBOW
      if i.pbOpposing1.ability == (:BADDREAMS) || i.pbOpposing2.ability == (:BADDREAMS)
        crested = i.pbOpposing1.crested == :DARKRAI || i.pbOpposing2.crested == :DARKRAI
        hpdrain=(i.totalhp/8.0).floor
        hpdrain=(i.totalhp/6.0).floor if @battle.FE == :DARKNESS2
        hpdrain=(i.totalhp/4.0).floor if @battle.FE == :INFERNAL || @battle.FE == :DARKNESS3 || crested
        hploss=i.pbReduceHP(hpdrain,true)
        pbDisplay(_INTL("{1} is having a bad dream!",i.pbThis)) if hploss>0
      end
    end
    if i.isFainted?
      return if !i.pbFaint
      next
    end
    # World of Nightmares
    if i.pbOpposing1.ability == :WORLDOFNIGHTMARES || i.pbOpposing2.ability == :WORLDOFNIGHTMARES
      nightmarechip=[64,i.turncount].min
      nightmarechip*2 if @battle.FE == :NEWWORLD
      hploss=i.pbReduceHP(((i.totalhp/32).floor)*nightmarechip,true)
      pbDisplay(_INTL("{1}'s nightmares are becoming a reality!",i.pbThis)) if hploss>0
    end
    if i.isFainted?
      return if !i.pbFaint
      next
    end
    # Harvest
    if i.ability == :HARVEST && i.item.nil? && i.pokemon.itemRecycle #if an item was recycled, check
      if pbIsBerry?(i.pokemon.itemRecycle) && (pbRandom(100)>50 || (pbWeather== :SUNNYDAY) ||
         @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,2,5) || (Rejuv && @battle.FE == :GRASSY))
        i.item=i.pokemon.itemRecycle
        i.pokemon.itemInitial=i.pokemon.itemRecycle
        i.pokemon.itemRecycle=nil
        firstberryletter=getItemName(i.item).split(//).first
        if firstberryletter=="A" || firstberryletter=="E" || firstberryletter=="I" ||
          firstberryletter=="O" || firstberryletter=="U"
              pbDisplay(_INTL("{1} harvested an {2}!",i.pbThis,getItemName(i.item)))
        else
          pbDisplay(_INTL("{1} harvested a {2}!",i.pbThis,getItemName(i.item)))
        end
        i.pbBerryCureCheck(true)
      end
    end
    # Ball Fetch
    puts i.effects[:BallFetch]
    if i.ability == :BALLFETCH && !i.effects[:BallFetch].nil? && i.item.nil?
      pokeball=i.effects[:BallFetch]
      i.item=pokeball
      i.pokemon.itemInitial=pokeball
      PBDebug.log("[Ability triggered] #{i.pbThis}'s Ball Fetch found #{getItemName(pokeball)}")
      pbDisplay(_INTL("{1} fetched a {2}!",i.pbThis,getItemName(pokeball)))
    end
    # Moody
    if i.ability == :CLOUDNINE && @field.effect == :RAINBOW
      failsafe=0
      randoms=[]
      loop do
        failsafe+=1
        break if failsafe==1000
        randomnumber=1+pbRandom(7)
        if !i.pbTooHigh?(randomnumber)
          randoms.push(randomnumber)
          break
        end
      end
      if failsafe!=1000
       i.stages[randoms[0]]+=1
       i.stages[randoms[0]]=6 if i.stages[randoms[0]]>6
       pbCommonAnimation("StatUp",i,nil)
       pbDisplay(_INTL("{1}'s Cloud Nine raised its {2}!",i.pbThis,i.pbGetStatName(randoms[0])))
      end
    end
    if i.ability == :MOODY
      randomup=[]
      randomdown=[]
      failsafe1=0
      failsafe2=0
      loop do
        failsafe1+=1
        break if failsafe1==1000
        randomnumber=1+pbRandom(5)
        if !i.pbTooHigh?(randomnumber)
          randomup.push(randomnumber)
          break
        end
      end
      loop do
        failsafe2+=1
        break if failsafe2==1000
        randomnumber=1+pbRandom(5)
        if !i.pbTooLow?(randomnumber) && randomnumber!=randomup[0]
          randomdown.push(randomnumber)
          break
        end
      end
       if failsafe1!=1000
         i.stages[randomup[0]]+=2
         i.stages[randomup[0]]=6 if i.stages[randomup[0]]>6
         pbCommonAnimation("StatUp",i,nil)
         pbDisplay(_INTL("{1}'s Moody sharply raised its {2}!",i.pbThis,i.pbGetStatName(randomup[0])))
       end
       if failsafe2!=1000
         i.stages[randomdown[0]]-=1
         pbCommonAnimation("StatDown",i,nil)
         pbDisplay(_INTL("{1}'s Moody lowered its {2}!",i.pbThis,i.pbGetStatName(randomdown[0])))
       end
     end
    end
    for i in priority
      next if i.isFainted?
      next if !i.itemWorks?
      # Toxic Orb
      if i.item == :TOXICORB && i.status.nil? && i.pbCanPoison?(false,true)
        i.status=:POISON
        i.statusCount=1
        i.effects[:Toxic]=0
        pbCommonAnimation("Poison",i,nil)
        pbDisplay(_INTL("{1} was poisoned by its {2}!",i.pbThis,getItemName(i.item)))
      end
      # Flame Orb
      if i.item == :FLAMEORB && i.status.nil? && i.pbCanBurn?(false,true)
        i.status=:BURN
        i.statusCount=0
        pbCommonAnimation("Burn",i,nil)
        pbDisplay(_INTL("{1} was burned by its {2}!",i.pbThis,getItemName(i.item)))
      end
      # Sticky Barb
      if i.item == :STICKYBARB && i.ability != :MAGICGUARD && !(i.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM)
        pbDisplay(_INTL("{1} is hurt by its {2}!",i.pbThis,getItemName(i.item)))
        @scene.pbDamageAnimation(i,0)
        i.pbReduceHP((i.totalhp/8.0).floor)
      end
      if i.isFainted?
        return if !i.pbFaint
        next
      end
    end
    #Emergency exit caused by passive end of turn damage
    for i in priority
      if i.userSwitch
        i.userSwitch = false
        pbDisplay(_INTL("{1} went back to {2}!",i.pbThis,pbGetOwner(i.index).name))
        newpoke=0
        newpoke=pbSwitchInBetween(i.index,true,false)
        pbMessagesOnReplace(i.index,newpoke)
        i.vanished=false
        i.pbResetForm
        pbReplace(i.index,newpoke,false)
        pbOnActiveOne(i)
        i.pbAbilitiesOnSwitchIn(true)
      end
    end
    # Hunger Switch
    for i in priority
      next if i.isFainted?
      if i.ability == :HUNGERSWITCH && (i.species == :MORPEKO) && @battle.FE != :FROZENDIMENSION
        i.form=(i.form==0) ? 1 : 0
        i.pbUpdate(true)
        scene.pbChangePokemon(i,i.pokemon)
        pbDisplay(_INTL("{1} transformed!",i.pbThis))
      end
    end
    # Form checks
    for i in 0...4
      next if @battlers[i].isFainted?
      @battlers[i].pbCheckForm
      @battlers[i].pbCheckFormRoundEnd
    end
    pbGainEXP

    # Checks if a pokemon on either side has fainted on this turn
    # for retaliate
    player   = priority[0]
    opponent = priority[1]
    player.pbOwnSide.effects[:Retaliate] = player.isFainted? || (@doublebattle && player.pbPartner.isFainted?)
    opponent.pbOwnSide.effects[:Retaliate] = opponent.isFainted? || (@doublebattle && opponent.pbPartner.isFainted?)
    for i in priority
      next if i.isFainted?
      next if i.nil?
      next if !Rejuv
      next if @party2[0].nil?
      @state.effects[:sosBuffer]=3 if @state.effects[:sosBuffer]==0 && (@doublebattle && i.isbossmon && i.pbPartner.issossmon)
      @state.effects[:sosBuffer]=4 if @state.effects[:sosBuffer]==0 && $cache.bosses[@party2[0].bossId] && $cache.bosses[@party2[0].bossId].name == "Spacea"
    end
    # sosBuffer
    if @state.effects[:sosBuffer]>0
      @state.effects[:sosBuffer]-=1
    end
    pbBossSOS(priority) if Rejuv && @state.effects[:sosBuffer]==0    
    pbSwitch
    return if @decision>0
    for i in priority
      next if i.isFainted?
      i.pbAbilitiesOnSwitchIn(false)
    end
    for i in 0...4
      if @battlers[i].turncount>0 && @battlers[i].ability == :TRUANT
        @battlers[i].effects[:Truant]=!@battlers[i].effects[:Truant]
      end
      if @battlers[i].effects[:LockOn]>0   # Also Mind Reader
        @battlers[i].effects[:LockOn]-=1
        @battlers[i].effects[:LockOnPos]=-1 if @battlers[i].effects[:LockOn]==0
      end
      @battlers[i].effects[:Roost]=false
      @battlers[i].effects[:Flinch]=false
      @battlers[i].effects[:FollowMe]=false
      @battlers[i].effects[:RagePowder]=false
      @battlers[i].effects[:HelpingHand]=false
      @battlers[i].effects[:MagicCoat]=false
      @battlers[i].effects[:Snatch]=false
      if @battlers[i].ability == :JOKER
        @battlers[i].effects[:Snatch]=true
      end
      @battlers[i].effects[:Electrify]=false
      @battlers[i].effects[:Charge]-=1 if @battlers[i].effects[:Charge]>0
      @battlers[i].lastHPLost=0
      @battlers[i].lastAttacker=-1
      @battlers[i].effects[:Counter]=-1
      @battlers[i].effects[:CounterTarget]=-1
      @battlers[i].effects[:MirrorCoat]=-1
      @battlers[i].effects[:MirrorCoatTarget]=-1
    end
    # invalidate stored priority
    @usepriority=false
    @eruption= false
  end



################################################################################
# End of battle.
################################################################################
  def pbEndOfBattle(canlose=false)
    $position = Audio.bgm_pos
    case @decision
    ##### WIN #####
      when 1
        $game_variables[:Egg_Battle_Count]+=1 if Desolation && $game_variables[:Egg_Battle_Count]>0 && $game_variables[:Egg_Battle_Count]<1000 
        if @opponent
          @scene.pbTrainerBattleSuccess
          if @opponent.is_a?(Array)
            pbDisplayPaused(_INTL("{1} defeated {2} and {3}!",self.pbPlayer.name,@opponent[0].fullname,@opponent[1].fullname))
          else
            pbDisplayPaused(_INTL("{1} defeated\r\n{2}!",self.pbPlayer.name,@opponent.fullname))
          end
          @scene.pbShowOpponent(0)
          pbDisplayPaused(@endspeech.gsub(/\\[Pp][Nn]/,self.pbPlayer.name))
          if @opponent.is_a?(Array)
            @scene.pbHideOpponent
            @scene.pbShowOpponent(1)
            pbDisplayPaused(@endspeech2.gsub(/\\[Pp][Nn]/,self.pbPlayer.name))
          end
          # Calculate money gained for winning
          if @internalbattle
            tmoney=0
            if @opponent.is_a?(Array)   # Double battles
              maxlevel1=0; maxlevel2=0; limit=pbSecondPartyBegin(1)
              for i in 0...limit
                if @party2[i]
                  maxlevel1=@party2[i].level if maxlevel1<@party2[i].level
                end
                if @party2[i+limit]
                  maxlevel2=@party2[i+limit].level if maxlevel1<@party2[i+limit].level
                end
              end
              maxlevel1=[100,maxlevel1].min
              maxlevel2=[100,maxlevel2].min
              tmoney+=maxlevel1*@opponent[0].moneyEarned
              tmoney+=maxlevel2*@opponent[1].moneyEarned
            else
              maxlevel=0
              for i in @party2
                next if !i
                maxlevel=i.level if maxlevel<i.level
              end
              tmoney+=maxlevel*@opponent.moneyEarned
            end
            # If Amulet Coin/Luck Incense's effect applies, double money earned
            badgemultiplier = (1+(self.pbPlayer.numbadges/3)).floor
            badgemultiplier = (1+(self.pbPlayer.numbadges/2)).floor if Desolation || Rejuv
            tmoney*=badgemultiplier
            tmoney*=2 if @amuletcoin
            tmoney*=2 if  $game_switches[:Moneybags]
            if $game_switches[:Grinding_Trainer_Money_Cut] || $game_switches[:Penniless_Mode] #grinding trainers
              tmoney*=0.2
              tmoney= tmoney.floor
            end
            tmoney *= 2 if $game_variables[:LuckMoney] != 0
            tmoney = 0 if $game_variables[:LuckMoney] > 10 || $game_variables[:LuckMoney] < -10
            oldmoney=self.pbPlayer.money
            if $game_variables[:LuckMoney] < 0
              self.pbPlayer.money-=tmoney
              moneylost=oldmoney-self.pbPlayer.money
              if moneylost>0
                pbDisplayPaused(_INTL("{1} paid ${2}\r\nfor winning!",self.pbPlayer.name,tmoney))
              end
            else
              self.pbPlayer.money+=tmoney
              moneygained=self.pbPlayer.money-oldmoney
              if moneygained>0
                pbDisplayPaused(_INTL("{1} got ${2}\r\nfor winning!",self.pbPlayer.name,tmoney))
              end
            end
          end
        elsif Rejuv && @party2[0].isbossmon
          bossname = $cache.bosses[@party2[0].bossId].name
          @scene.pbBossBattleSuccess(bossname)
          pbDisplayPaused(_INTL("{1} defeated\r\n{2}!",self.pbPlayer.name,bossname))
        end
        if @internalbattle && @extramoney>0
          @extramoney*=2 if @amuletcoin
          oldmoney=self.pbPlayer.money
          self.pbPlayer.money+=@extramoney
          moneygained=self.pbPlayer.money-oldmoney
          if moneygained>0
            pbDisplayPaused(_INTL("{1} picked up ${2}!",self.pbPlayer.name,@extramoney))
          end
        end
        for pkmn in @snaggedpokemon
          pbStorePokemon(pkmn)
         # self.pbPlayer.shadowcaught=[] if !self.pbPlayer.shadowcaught
         # self.pbPlayer.shadowcaught[pkmn.species]=true
        end
        @snaggedpokemon.clear
        if Rejuv
          returnStolenPokemon(true,nil)
        end
        # Update Healingitem 
        if $PokemonGlobal.partner && @player.is_a?(Array)
          $PokemonGlobal.partner[4] = @partneritems if $PokemonGlobal.partner[4] = @partneritems
        end
    ##### LOSE, DRAW #####
      when 2, 5
        if @internalbattle
          pbDisplayPaused(_INTL("{1} is out of usable Pokémon!",self.pbPlayer.name))
          moneylost=pbMaxLevelFromIndex(0)
          multiplier=[8,16,24,36,48,64,80,100,120,140,160,180,190,200,210,220,230,240,250,250] #Badge no. multiplier for money lost
          moneylost*=multiplier[[multiplier.length-1,self.pbPlayer.numbadges].min]
          moneylost=self.pbPlayer.money if moneylost>self.pbPlayer.money
          moneylost=0 if $game_switches[:No_Money_Loss]
          self.pbPlayer.money-=moneylost
          if @opponent
            if @opponent.is_a?(Array)
              pbDisplayPaused(_INTL("{1} lost against {2} and {3}!",self.pbPlayer.name,@opponent[0].fullname,@opponent[1].fullname))
            else
              pbDisplayPaused(_INTL("{1} lost against\r\n{2}!",self.pbPlayer.name,@opponent.fullname))
            end
            if moneylost>0
              pbDisplayPaused(_INTL("{1} paid ${2}\r\nas the prize money...",self.pbPlayer.name,moneylost))
              pbDisplayPaused(_INTL("...")) if !canlose
            end
          else
            if moneylost>0
              pbDisplayPaused(_INTL("{1} panicked and lost\r\n${2}...",self.pbPlayer.name,moneylost))
              pbDisplayPaused(_INTL("...")) if !canlose
            end
          end
          pbDisplayPaused(_INTL("{1} blacked out!",self.pbPlayer.name)) if !canlose
        elsif @decision==2
          @scene.pbShowOpponent(0)
          pbDisplayPaused(@endspeechwin.gsub(/\\[Pp][Nn]/,self.pbPlayer.name))
          if @opponent.is_a?(Array)
            @scene.pbHideOpponent
            @scene.pbShowOpponent(1)
            pbDisplayPaused(@endspeechwin2.gsub(/\\[Pp][Nn]/,self.pbPlayer.name))
          end
        elsif @decision==5
          PBDebug.log("***[Draw game]") if $INTERNAL
        end
        if Rejuv
          returnStolenPokemon(true,nil)
        end
        $game_screen.weather(0,0,0)
    end
    # Change bad poison to normal poison
    for i in $Trainer.party
      next if i.nil?
      if i.statusCount > 0 && i.status == :POISON
        i.statusCount = 0
      end
    end

    # Pass on Pokérus within the party
    infected=[]
    for i in 0...$Trainer.party.length
      if $Trainer.party[i].pokerusStage==1
        infected.push(i)
      end
    end
    if infected.length>=1
      for i in infected
        strain=$Trainer.party[i].pokerus/16
        if i>0 && $Trainer.party[i-1].pokerusStage==0
          $Trainer.party[i-1].givePokerus(strain) if pbRandom(3)==0
        end
        if i<$Trainer.party.length-1 && $Trainer.party[i+1].pokerusStage==0
          $Trainer.party[i+1].givePokerus(strain) if pbRandom(3)==0
        end
      end
    end
    if $game_variables[:LuckMoney]!=0 && @opponent
      $game_variables[:LuckMoney] -= 1 if $game_variables[:LuckMoney] > 0
      $game_variables[:LuckMoney] += 1 if $game_variables[:LuckMoney] < 0
      pbDisplayPaused(_INTL("Mr Luck's money contract lost its effect!")) if $game_variables[:LuckMoney]==0
    end
    if $game_variables[:LuckShinies]!=0 && !@opponent && !@party2[0].isbossmon
      $game_variables[:LuckShinies] -= 1 if $game_variables[:LuckShinies] > 0
      $game_variables[:LuckShinies] += 1 if $game_variables[:LuckShinies] < 0
      pbDisplayPaused(_INTL("Mr Luck's shiny contract lost its effect!")) if $game_variables[:LuckShinies]==0
    end
    if $game_variables[:LuckMoves]!=0 && !@opponent && !@party2[0].isbossmon
      $game_variables[:LuckMoves] -= 1 if $game_variables[:LuckMoves] > 0
      $game_variables[:LuckMoves] += 1 if $game_variables[:LuckMoves] < 0
      pbDisplayPaused(_INTL("Mr Luck's technique contract lost its effect!")) if $game_variables[:LuckMoves]==0
    end
    @scene.pbEndBattle(@decision)

    # Resetting all the temporary forms
    for i in @battlers
      i.pbResetForm
    end
    for i in @party1
      next if i.nil?
      i.makeUnmega if i.isMega? || i.isGiga?
      i.makeUnprimal if i.isPrimal?
      i.makeUnultra if i.isUltra?
      if i.species == :ZYGARDE && !i.originalForm.nil?
        hpbackup = i.hp
        i.form=i.originalForm
        i.originalForm = nil
        i.hp=[hpbackup,i.totalhp].min
      end
      i.form=0 if i.species == :MIMIKYU || i.species == :EISCUE
      if Rejuv
        i.form=1 if ((i.species == :PARAS || i.species == :PARASECT) && i.form == 2)
        i.prismPower = false
        i.rampCrestUsed = false
      end
    end
    for i in $Trainer.party
      i.setItem(i.itemInitial)
      i.setItem(i.itemReallyInitialHonestlyIMeanItThisTime) if Rejuv && $game_switches[:NotPlayerCharacter]
      i.itemInitial=i.itemRecycle=nil
      i.form=i.getForm(i)
    end
    #Set variables to field effect values
    $game_variables[:Field_Effect_End_Of_Battle] = @field.effect
    $game_variables[:Field_Counter_End_Of_Battle] = @field.counter
    $game_variables[:Weather_End_Of_Battle] = @weather

    return @decision
  end
end

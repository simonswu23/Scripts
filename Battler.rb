class PokeBattle_Battler
  attr_reader :battle
  attr_accessor :pokemon
  attr_reader :personalID
  attr_reader :name
  attr_reader :index
  attr_reader :pokemonIndex
  attr_reader :totalhp
  attr_accessor :fainted
  attr_reader :usingsubmove
  attr_reader :level
  attr_reader :statusCount
  attr_reader :hp
  attr_reader :item
  attr_reader :status
  attr_accessor :lastAttacker
  attr_accessor :turncount
  attr_accessor :effects
  attr_accessor :species
  attr_accessor :type1
  attr_accessor :type2
  attr_accessor :ability
  attr_accessor :gender
  attr_accessor :attack
  attr_accessor :defense
  attr_accessor :spatk
  attr_accessor :spdef
  attr_accessor :speed
  attr_accessor :baseExp
  attr_accessor :evYield
  attr_accessor :stages
  attr_accessor :iv
  attr_accessor :moves
  attr_accessor :zmoves
  attr_accessor :participants
  attr_accessor :lastHPLost
  attr_accessor :lastMoveUsed
  attr_accessor :lastMoveUsedSketch
  attr_accessor :lastRegularMoveUsed
  attr_accessor :lastRoundMoved
  attr_accessor :movesUsed
  attr_accessor :currentMove
  attr_accessor :damagestate
  attr_accessor :unburdened
  attr_accessor :previousMove
  attr_accessor :selectedMove
  attr_accessor :wonderroom
  attr_accessor :itemUsed
  attr_accessor :itemUsed2  #Stays while the battler is out
  attr_accessor :userSwitch
  attr_accessor :forcedSwitch
  attr_accessor :forcedSwitchEarlier
  attr_accessor :midwayThroughMove
  attr_accessor :vanished
  attr_accessor :custap
  attr_accessor :moldbroken
  attr_accessor :corroded
  attr_accessor :sleeptalkUsed
  attr_accessor :startform
  attr_accessor :statLowered
  attr_accessor :missAcc
  attr_accessor :backupability
  attr_accessor :takegem
  attr_accessor :lastMoveChoice
  attr_accessor :isFirstMoveOfRound
  attr_accessor :statupanimplayed
  attr_accessor :statdownanimplayed
  attr_accessor :statrepeat
  attr_accessor :crested
  attr_accessor :onBreakEffects # rejuv for boss system
  attr_accessor :onEntryEffects # rejuv for boss system
  attr_accessor :chargeAttack # rejuv for boss system
  attr_accessor :immunities # rejuv for boss system
  attr_accessor :capturable # rejuv for boss system
  attr_accessor :roll #currently only used in Deso for Crowd Field
  attr_accessor :tempBoosts #currently only used in Deso for Crowd Field
  attr_accessor :isbattlernew #currently only used in Deso for Crowd Field
  def inHyperMode?; return false; end
  def isShadow?; return false; end

  #simple true/false vars
  SwitchEff = [:AquaRing, :BindingBand, :BeakBlast, :BurnUp, :ClangedScales, :Curse,
    :DefenseCurl, :DestinyBond, :DestinyRate, :Disguise, :Electrify, :Endure, :FairyLockRate,
    :FlashFire, :Flinch, :FollowMe, :Foresight, :GastroAcid, :Grudge, :HelpingHand, :IceFace,
    :Imprison, :Ingrain, :Jealousy, :LashOut, :MagicCoat, :MeFirst, :Minimize,
    :MiracleEye, :Nightmare, :NoRetreat, :ParentalBond, :Powder,
    :PowerTrick, :ProtectNegation, :QuickDrawSnipe, :Quash, :RagePowder, :Rage, :Roost,
    :Round, :ShellTrap, :SkyDrop, :SmackDown, :Snatch, :Tantrum, :TarShot, :Torment,
    :Trace, :Transform, :Truant, :TyphBond,:UsingSubstituteRightNow, :Shelter, :SwampWeb]
  #turn count vars
  TurnEff = [:Bide, :Charge, :Confusion, :Disable, :Embargo, :Encore, 
    :FuryCutter, :HealBlock, :HyperBeam, :LaserFocus, :LockOn, :MagnetRise, 
    :Metronome, :MultiTurn, :Outrage, :PerishSong, :Substitute, :Taunt, 
    :Telekinesis, :ThroatChop, :Toxic, :Uproar, :Yawn, :TwoTurnAttack,:ChtonicMalady]

  #position vars
  PosEff = [:Attract, :BideTarget, :Counter, :MirrorCoat, :LeechSeed, :LockOnPos, :MeanLook, 
    :MirrorCoatTarget, :CounterTarget, :MultiTurnUser, :Octolock, :Petrification, :ShellTrapTarget]

  #other counter vars
  CountEff = [:BideDamage, :Damage, :FocusEnergy, :ProtectRate, :Rollout, :EchoedVoice, :SpeedSwap, :Stockpile, :StockpileDef, :StockpileSpDef, :WeightModifier]

  #weirdo shit (usually move objects)
  OtherEff = [:ChoicedMove, :DisableMove, :EncoreMove, :MagicBounce, :Protect] #:TwoTurnAttack
  
  BatonEff = [:AquaRing, :Confusion, :Curse, :Embargo, :FocusEnergy, :LaserFocus, 
    :GastroAcid, :HealBlock, :Ingrain, :LeechSeed, :LockOn, :LockOnPos, :Shelter, 
    :MagnetRise, :PerishSong, :PerishSongUser, :PowerTrick, :Substitute, :Telekinesis, :MeanLook]

  PermEff = [:FutureSight , :FutureSightMove , :FutureSightUser , :FutureSightPokemonIndex , :HealingWish , :LunarDance , :Wish , :WishAmount , :WishMaker , :ZHeal]

  #:VespiCrest and :Illusion are not included here

################################################################################
# Complex accessors
################################################################################
  def nature
    return (@pokemon) ? @pokemon.nature : 0
  end

  def ev
    return (@pokemon) ? @pokemon.ev : 0
  end

  def happiness
    return (@pokemon) ? @pokemon.happiness : 0
  end

  def pokerusStage
    return (@pokemon) ? @pokemon.pokerusStage : 0
  end

  attr_reader :form

  def form=(value)
    @form=value
    @pokemon.form=value if @pokemon
  end

  def name=(value)
    @name=value
  end

  def hasMega?
    if @pokemon
      return (@pokemon.hasMegaForm? rescue false)
    end
    return false
  end

  def hasUltra?
    if @pokemon
      return (@pokemon.hasUltraForm? rescue false)
    end
    return false
  end

  def hasCrest?(illusion=false)
    return false if !Rejuv
    crestmon = illusion==true ? @effects[:Illusion] : self
    return true if $PokemonBag.pbQuantity(:SILVCREST)>0 && crestmon.species == :SILVALLY && @battle.pbOwnedByPlayer?(@index)
    return true if @battle.pbGetOwnerItems(@index).include?(:SILVCREST) && crestmon.species == :SILVALLY && !@battle.pbOwnedByPlayer?(@index)
    return false if !crestmon.item || !$cache.items[crestmon.item].checkFlag?(:crest)
    return false if crestmon.species == :DARMANITAN && ![0,1].include?(crestmon.form)
    return false if [:TYPHLOSION,:SAMUROTT,:ELECTRODE,:ZOROARK].include?(crestmon.species) && crestmon.form!=0
    return false if crestmon.species == :AMPHAROS && crestmon.form!=1
    return PBStuff::POKEMONTOCREST[crestmon.species]==crestmon.item
  end

  def chargeTurns?
    return false if !Rejuv
    return false if !self.isbossmon
    if self.chargeAttack
      chargeAttack = self.chargeAttack
      return true if chargeAttack[:canAttack] && chargeAttack[:canAttack]==false
      return false if (self.turncount % chargeAttack[:turns] == 0 && chargeAttack[:continueCharging]) 
      return false if self.turncount > chargeAttack[:turns] && !chargeAttack[:continueCharging]
      return true
    end
    return false
  end

  def pbZCrystalFromType(type)
    return PBStuff::TYPETOZCRYSTAL[type]
  end

  def hasZMove?
    return false if @zmoves.nil?
    return false if !@zmoves.any?
    return false if @item == :ULTRANECROZIUMZ && !(@species == :NECROZMA && @form == 3)
    return true
  end

  def pbCompatibleZMoveFromMove?(move,moveindex = false)
    pkmn=self
    move = pkmn.moves[move] if moveindex

    zcrystal_to_type = PBStuff::TYPETOZCRYSTAL.invert
    return true if zcrystal_to_type[pkmn.item] == move.type

    case pkmn.item
      when :ALORAICHIUMZ     then return true if move.move==:THUNDERBOLT
      when :DECIDIUMZ        then return true if move.move==:SPIRITSHACKLE
      when :INCINIUMZ        then return true if move.move==:DARKESTLARIAT
      when :PRIMARIUMZ       then return true if move.move==:SPARKLINGARIA
      when :EEVIUMZ          then return true if move.move==:LASTRESORT
      when :PIKANIUMZ        then return true if move.move==:VOLTTACKLE
      when :SNORLIUMZ        then return true if move.move==:GIGAIMPACT
      when :MEWNIUMZ         then return true if move.move==:PSYCHIC
      when :TAPUNIUMZ        then return true if move.move==:NATURESMADNESS
      when :MARSHADIUMZ      then return true if move.move==:SPECTRALTHIEF
      when :KOMMONIUMZ       then return true if move.move==:CLANGINGSCALES
      when :LYCANIUMZ        then return true if move.move==:STONEEDGE
      when :MIMIKIUMZ        then return true if move.move==:PLAYROUGH
      when :SOLGANIUMZ       then return true if move.move==:SUNSTEELSTRIKE
      when :LUNALIUMZ        then return true if move.move==:MOONGEISTBEAM
      when :ULTRANECROZIUMZ  then return true if move.move==:PHOTONGEYSER
      when :INTERCEPTZ       then return true
    end
    return false
  end

  def battlerToPokemon
    return @pokemon
  end

  def isMega?
    if @pokemon
      return (@pokemon.isMega? rescue false)
    end
    return false
  end

  def isUltra?
    if @pokemon
      return (@pokemon.isUltra? rescue false)
    end
    return false
  end

  def isPrimal?
    if @pokemon
      return (@pokemon.isPrimal? rescue false)
    end
    return false
  end

  def level=(value)
    @level=value
    @pokemon.level=(value) if @pokemon
  end

  def status=(value)
    if @status== :SLEEP && value.nil?
      @effects[:Truant]=false
    end
    if @status== :PETRIFIED && value.nil?
      if self.effects[:Substitute]<=0
        @battle.scene.pbUnSubstituteSprite(self,self.pbIsOpposing?(1))
      else
        @battle.scene.pbSubstituteSprite(self,self.pbIsOpposing?(1))
      end
    end
    @status=value
    @pokemon.status=value if @pokemon
    if value!=:POISON
      @effects[:Toxic]=0
    end
    if value!=:POISON && value!=:SLEEP
      @statusCount=0
      @pokemon.statusCount=0 if @pokemon
    end
  end

  def statusCount=(value)
    @statusCount=value
    @pokemon.statusCount=value if @pokemon
  end

  def hp=(value)
    @hp=value.to_i
    @pokemon.hp=value.to_i if @pokemon
  end

  def item=(value)
    @unburdened = true if @ability == :UNBURDEN && @item && value.nil?
    @item=value
    @pokemon.item=value if @pokemon
  end

  def weight
    w=(@pokemon) ? @pokemon.weight : 500
    w+=@effects[:WeightModifier]
    w*=2 if self.ability == :HEAVYMETAL && !(self.moldbroken)
    w/=2 if self.ability == :LIGHTMETAL && !(self.moldbroken)
    w/=2 if self.hasWorkingItem(:FLOATSTONE)
    w=1 if w<1
    return w
  end
  
  def isbossmon
    return false if !Rejuv
    return (@pokemon) ? @pokemon.isbossmon : false
  end 

  def issossmon
    return false if !Rejuv
    return (@pokemon) ? @pokemon.sosmon : false
  end
  
  def owned
    return (@pokemon) ? $Trainer.pokedex.dexList[@pokemon.species][:owned?] && !@battle.opponent : false
  end
  

################################################################################
# Creating a battler
################################################################################
  def initialize(btl,index,fakebattler=false)
    @battle       = btl
    @index        = index
    @fainted      = true
    @usingsubmove = false
    @damagestate  = PokeBattle_DamageState.new
    @unburdened   = false
    @wonderroom   = false
    @userSwitch   = false
    @forcedSwitch = false
    @forcedSwitchEarlier = false
    @midwayThroughMove = false
    @vanished     = false
    @custap       = false
    @moldbroken   = false
    @corroded     = false
    @takegem      = false
    @statupanimplayed = false
    @statdownanimplayed = false
    @statrepeat = false
    @roll = 0
    @isbattlernew = nil
    @capturable = false
    
    #blank values
    @name         = ""
    @species      = 0
    @level        = 0
    @hp           = 0
    @totalhp      = 0
    @gender       = 0
    @ability      = 0
    @type1        = 0
    @type2        = 0
    @form         = 0
    @attack       = 0
    @defense      = 0
    @speed        = 0
    @spatk        = 0
    @spdef        = 0
    @baseExp      = 0
    @evYield      = [0,0,0,0,0,0]
    @status       = 0
    @statusCount  = 0
    @pokemon      = nil
    @pokemonIndex = -1
    @participants = []
    @moves        = []
    @zmoves       = nil
    @iv           = [0,0,0,0,0,0]
    @item         = nil
    @weight       = nil

    pbInitEffects(false,fakebattler)
    
  end

  def pbInitPokemon(pkmn,pkmnIndex)
    if pkmn.isEgg?
      raise _INTL("An egg can't be an active Pokémon")
    end
    @name         = pkmn.name
    @species      = pkmn.species
    @level        = pkmn.level
    @hp           = pkmn.hp
    @totalhp      = pkmn.totalhp
    @gender       = pkmn.gender
    @ability      = pkmn.ability
    @backupability= pkmn.ability
    @type1        = pkmn.type1
    @type2        = pkmn.type2
    @form         = pkmn.form
    @attack       = pkmn.attack
    @defense      = pkmn.defense
    @speed        = pkmn.speed
    @spatk        = pkmn.spatk
    @spdef        = pkmn.spdef
    @baseExp      = pkmn.baseExp
    @evYield      = pkmn.evYield
    @status       = pkmn.status
    @statusCount  = pkmn.statusCount
    @personalID   = pkmn.personalID
    @pokemon      = pkmn
    @pokemonIndex = pkmnIndex
    @participants = [] # Participants will earn Exp. Points if this battler is defeated
    @moves        = []
    for move in pkmn.moves
      @moves.push(PokeBattle_Move.pbFromPBMove(@battle,move,pkmn)) if move
    end
    if !pkmn.zmoves.nil?
      @zmoves       = [nil,nil,nil,nil]
      for i in 0...pkmn.zmoves.length
        zmove = pkmn.zmoves[i]
        @zmoves[i] = PokeBattle_Move.pbFromPBMove(@battle,zmove,pkmn,@moves[i]) if !zmove.nil?
      end
    else 
      @zmoves = nil
    end
    @iv           = pkmn.iv
    @item         = pkmn.item
    @crested = hasCrest? ? pkmn.species : false
    crestStats if @crested

    @startform = @form
    if Rejuv
      @battle.ai.aimondata[index].skill = 100 if pkmn.isbossmon
      if !@pokemon.prismPower
        @pokemon.prismPower = false
      end
    end
     
  end

  def pbInitEffects(batonpass, fakebattler=false)
    oldeffects = @effects.nil? ? nil : @effects.clone 
    
    #effects
    @effects      = {}
    #bulk effects
    SwitchEff.each{|eff| @effects[eff] = false}
    TurnEff.each{|eff| @effects[eff] = 0}
    PosEff.each{|eff| @effects[eff] = -1}
    CountEff.each{|eff| @effects[eff] = 0}
    OtherEff.each{|eff| @effects[eff] = nil}
    if !oldeffects.nil?
      PermEff.each{|eff| @effects[eff] = oldeffects[eff]}
    else
      @effects[:FutureSight]       = 0
      @effects[:FutureSightMove]   = 0
      @effects[:FutureSightUser]   = -1
      @effects[:FutureSightPokemonIndex]  = -1
      @effects[:HealingWish]       = false
      @effects[:LunarDance]        = false
      @effects[:Wish]              = 0
      @effects[:WishAmount]        = 0
      @effects[:WishMaker]         = -1
      @effects[:ZHeal]             = false
    end
    @effects[:Quarkdrive]       = [0,false]
    @effects[:BouncedMove]      = 0 #remove later.
    @effects[:Disguise]         = (self.species==:MIMIKYU && self.form==0) # Mimikyu
    @effects[:IceFace]          = (self.species==:EISCUE && self.form==0) # Eiscue
    if (self.ability == :ILLUSION || self.crested == :ZOROARK) 
      party=@battle.pbPartySingleOwner(@index) #new method for splitting teams
      party=party.find_all {|item| item && !item.egg? && item.hp>0 }
      if party[party.length-1] != @pokemon && party.length > 0
        @effects[:Illusion] = party[party.length-1].clone
        @effects[:Illusion].form = party[party.length-1].form.clone
      end
    else
      @effects[:Illusion] 
    end

    #non-effects
    @damagestate.reset
    @fainted              = false
    @lastAttacker         = -1
    @lastHPLost           = 0
    @lastMoveUsed         = -1
    @previousMove         = -1
    @lastRegularMoveUsed  = nil
    @lastMoveUsedSketch   = -1
    @lastRoundMoved       = -1
    @itemUsed             = false
    @itemUsed2            = false
    @movesUsed            = []
    @turncount            = 0
    #stuff for other battlers???
    for i in 0...4
      next if !@battle.battlers[i] || fakebattler
      if @battle.battlers[i].effects[:MultiTurnUser]==@index
        @battle.battlers[i].effects[:MultiTurn]=0
        @battle.battlers[i].effects[:MultiTurnUser]=-1
        @battle.battlers[i].effects[:BindingBand]=false
      end
      if @battle.battlers[i].effects[:MeanLook]==@index
        @battle.battlers[i].effects[:MeanLook]=-1
        @battle.battlers[i].effects[:SwampWeb]=false if @battle.battlers[i].effects[:SwampWeb]=true
      end
      if @battle.battlers[i].effects[:Attract]==@index
        @battle.battlers[i].effects[:Attract]=-1
      end
      if @battle.battlers[i].effects[:Octolock]==@index
        @battle.battlers[i].effects[:Octolock]=-1
      end
    end
    
    if batonpass
      @effects[:LockOn]=2 if oldeffects[:LockOn]>0
      if oldeffects[:PowerTrick]
        self.attack, self.defense = self.defense, self.attack
        @effects[:PowerTrick] = oldeffects[:PowerTrick]
      end
      BatonEff.each{|eff| @effects[eff] = oldeffects[eff]}
    else
      @stages       = Array.new(8,0) #Seven stats (0 is blank) with no stages
      for i in 0...4
        next if !@battle.battlers[i] || fakebattler
        if @battle.battlers[i].effects[:LockOnPos]==@index &&
           @battle.battlers[i].effects[:LockOn]>0
          @battle.battlers[i].effects[:LockOn]=0
          @battle.battlers[i].effects[:LockOnPos]=-1
        end
      end
    end
  end


  def pbUpdate(fullchange=false)
    return if !@pokemon

    @pokemon.calcStats
    @level     = @pokemon.level
    @hp        = @pokemon.hp
    @totalhp   = @pokemon.totalhp
    return if @effects[:Transform]

    @attack    = @pokemon.attack
    @defense   = @pokemon.defense
    @speed     = @pokemon.speed
    @spatk     = @pokemon.spatk
    @spdef     = @pokemon.spdef
    crestStats if @crested
    @spdef, @defense = @defense, @spdef if @wonderroom
    @attack, @defense = @defense, @attack if @effects[:PowerTrick]
    return if !fullchange

    @baseExp   = @pokemon.baseExp
    @evYield   = @pokemon.evYield
    @ability = @pokemon.ability if !@ability.nil? && !((@crested == :SILVALLY || @crested == :ZOROARK))
    @type1   = @pokemon.type1
    @type2   = @pokemon.type2
  end

  def pbInitialize(pkmn,index,batonpass)
    # Cure status of previous Pokemon with Natural Cure
    if self.ability == :NATURALCURE && @pokemon
      self.status=nil
    end
    if self.ability == :REGENERATOR && @pokemon && @hp>0
      self.pbRecoverHP((totalhp/3.0).floor)
    end
    pbInitPokemon(pkmn,index)
    pbInitEffects(batonpass)
  end

# Used only to erase the battler of a Shadow Pokémon that has been snagged.
  def pbReset
    @pokemon                = nil
    @pokemonIndex           = -1
    self.hp                 = 0
    pbInitEffects(false)
    # reset status
    self.status             = 0
    self.statusCount        = 0
    @fainted                = true
    # reset choice
    @battle.choices[@index] = [0,0,nil,-1]
    return true
  end

# Update Pokémon who will gain EXP if this battler is defeated
  def pbUpdateParticipants
    return if self.isFainted? # can't update if already fainted
    if @battle.pbIsOpposing?(@index)
      found1=false
      found2=false
      for i in @participants
        found1=true if i==pbOpposing1.pokemonIndex
        found2=true if i==pbOpposing2.pokemonIndex
      end
      if !found1 && !pbOpposing1.isFainted?
        @participants.push(pbOpposing1.pokemonIndex)
      end
      if !found2 && !pbOpposing2.isFainted?
        @participants.push(pbOpposing2.pokemonIndex)
      end
    end
  end

  def formFromItem
    if @species == :SILVALLY
      case @item
        when :FIGHTINGMEMORY    then return 1
        when :FLYINGMEMORY      then return 2
        when :POISONMEMORY      then return 3
        when :GROUNDMEMORY      then return 4
        when :ROCKMEMORY        then return 5
        when :BUGMEMORY         then return 6
        when :GHOSTMEMORY       then return 7
        when :STEELMEMORY       then return 8
        when :GLITCHMEMORY      then return 9
        when :FIREMEMORY        then return 10
        when :WATERMEMORY       then return 11
        when :GRASSMEMORY       then return 12
        when :ELECTRICMEMORY    then return 13
        when :PSYCHICMEMORY     then return 14
        when :ICEMEMORY         then return 15
        when :DRAGONMEMORY      then return 16
        when :DARKMEMORY        then return 17
        when :FAIRYMEMORY       then return 18
        else return 0
      end
    elsif @species == :ARCEUS
      case @item
        when :FISTPLATE, :FIGHTINIUMZ    then return 1
        when :SKYPLATE, :FLYINIUMZ       then return 2
        when :TOXICPLATE, :POISONIUMZ    then return 3
        when :EARTHPLATE, :GROUNDIUMZ    then return 4
        when :STONEPLATE, :ROCKIUMZ      then return 5
        when :INSECTPLATE, :BUGINIUMZ    then return 6
        when :SPOOKYPLATE, :GHOSTIUMZ    then return 7
        when :IRONPLATE, :STEELIUMZ      then return 8
        when :FLAMEPLATE, :FIRIUMZ       then return 10
        when :SPLASHPLATE, :WATERIUMZ    then return 11
        when :MEADOWPLATE, :GRASSIUMZ    then return 12
        when :ZAPPLATE, :ELECTRIUMZ      then return 13
        when :MINDPLATE, :PSYCHIUMZ      then return 14
        when :ICICLEPLATE, :ICIUMZ       then return 15
        when :DRACOPLATE, :DRAGONIUMZ    then return 16
        when :DREADPLATE, :DARKINIUMZ    then return 17
        when :PIXIEPLATE, :FAIRIUMZ      then return 18
        else return 0
      end
    end
  end

################################################################################
# About this battler
################################################################################
  def pbThis(lowercase=false)
    if @battle.pbIsOpposing?(@index)
      if @battle.opponent || self.issossmon
        return lowercase ? _INTL("the foe's {1}",getMonName(self.species)) : _INTL("The foe's {1}",getMonName(self.species))
      elsif self.isbossmon && !(Rejuv && @pokemon.bossId == :SHADOWDEN)
        return lowercase ? _INTL("{1}",self.name) : _INTL("{1}",self.name)
      else
        return lowercase ? _INTL("the wild {1}",self.name) : _INTL("The wild {1}",self.name)
      end
    elsif @battle.pbOwnedByPlayer?(@index)
      return _INTL("{1}",self.name)
    else
      return lowercase ? _INTL("the ally {1}",self.name) : _INTL("The ally {1}",self.name)
    end
  end

  def name 
    return @effects[:Illusion] != nil  ? @effects[:Illusion].name : @name
  end 

  def species 
    return @effects[:Illusion] != nil  ? @effects[:Illusion].species : @species
  end

  def hasType?(type)
    return (@type1==type || @type2==type)
  end

  def pbHasMove?(move)
    for i in @moves
      next if i.nil?
      return true if i.move==move
    end
    return false
  end

  def pbHasMoveFunction?(code)
    return false if !code
    for i in @moves
      return true if i.function==code
    end
    return false
  end

  def hasMovedThisRound?
    return false if !@lastRoundMoved
    return @lastRoundMoved==@battle.turncount
  end

  def isFainted?
    return @hp<=0
  end

# i am leaving them here but both of the next 2 methods are depreciated, don't use them
# they checks things we handle entirely differently now, so all they do is add 
# tiny bits of extra prcoessing work when called, for no gain - Falirion
  def abilityWorks?(ignorefainted=false)
    return false if self.isFainted? if !ignorefainted
    return false if @effects[:GastroAcid]
    return false if @battle.pbCheckGlobalAbility(:NEUTRALIZINGGAS)
    return true
  end

  def hasWorkingAbility(ability,ignorefainted=false)
    return false if self.isFainted? if !ignorefainted
    return false if @effects[:GastroAcid]
    if !(PBStuff::FIXEDABILITIES).include?(ability) && ability!=:NEUTRALIZINGGAS
      return false if @battle.pbCheckGlobalAbility(:NEUTRALIZINGGAS)
    end
    return @ability == ability
  end

  def itemWorks?(ignorefainted=false)
    return false if self.isFainted? if !ignorefainted
    return false if @item.nil?
    return true if @crested
    return false if @effects[:Embargo]>0
    return false if @battle.state.effects[:MagicRoom]>0
    return false if self.ability == :KLUTZ
    return false if @pokemon.corrosiveGas
    return true
  end

  def hasWorkingItem(item,ignorefainted=false)
    return false if self.isFainted? if !ignorefainted
    return false if @item.nil?
    return false if @effects[:Embargo]>0
    return false if @battle.state.effects[:MagicRoom]>0
    return false if self.ability == :KLUTZ
    return false if @pokemon.corrosiveGas
    return (@item == item)
  end

  def isAirborne?
    return false if self.item == :IRONBALL if @battle.FE != :DEEPEARTH
    return false if @effects[:Ingrain]
    return false if @effects[:SmackDown]
    return true if [:MAGNETPULL,:CONTRARY,:UNAWARE,:OBLIVIOUS].include?(self.ability) && @battle.FE == :DEEPEARTH
    return false if @battle.state.effects[:Gravity]!=0
    return true if self.hasType?(:FLYING) && @effects[:Roost]==false
    return true if self.ability == :LEVITATE || self.ability == :SOLARIDOL || self.ability == :LUNARIDOL
    return true if self.hasWorkingItem(:AIRBALLOON)
    return true if @effects[:MagnetRise]>0
    return true if @effects[:Telekinesis]>0
    return false
  end

  def nullsElec?
    return [:VOLTABSORB,:LIGHTNINGROD,:MOTORDRIVE].include?(@ability) || pbPartner.ability == :LIGHTNINGROD
  end

  def nullsWater?
    return [:WATERABSORB,:STORMDRAIN,:DRYSKIN].include?(@ability) || pbPartner.ability == :STORMDRAIN
  end

  def nullsFire?
    return @ability == :FLASHFIRE
  end

  def nullsGrass?
    return @ability == :SAPSIPPER
  end

  def pbSpeed()
    stagemul=[10,10,10,10,10,10,10,15,20,25,30,35,40]
    stagediv=[40,35,30,25,20,15,10,10,10,10,10,10,10]
    if @effects[:SpeedSwap] == 0
      speed=@speed
    else
      speed=@effects[:SpeedSwap]
    end
    stage=@stages[PBStats::SPEED]+6
    speed=(speed*stagemul[stage]/stagediv[stage]).floor
    if @unburdened
      speed=speed*2
    end
    if self.pbOwnSide.effects[:Tailwind]>0
      speed=speed*2
    end
    case self.ability
      when :SWIFTSWIM
        speed*=2 if @battle.pbWeather== :RAINDANCE && !self.hasWorkingItem(:UTILITYUMBRELLA) || [:WATERSURFACE,:UNDERWATER,:MURKWATERSURFACE].include?(@battle.FE)
      when :SURGESURFER
        speed*=2 if ([:ELECTERRAIN,:SHORTCIRCUIT,:WATERSURFACE,:UNDERWATER,:MURKWATERSURFACE].include?(@battle.FE) || @battle.state.effects[:ELECTERRAIN] > 0)
      when :TELEPATHY
        speed*=2 if (@battle.FE == :PSYTERRAIN || @battle.state.effects[:PSYTERRAIN] > 0)
      when :CHLOROPHYLL
        speed*=2 if (@battle.pbWeather== :SUNNYDAY || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,4,5)) && !self.hasWorkingItem(:UTILITYUMBRELLA)
      when :QUICKFEET
        speed*=1.5 if (!self.status.nil? || (Rejuv && @battle.FE == :ELECTERRAIN))
      when :SANDRUSH
        speed*=2 if @battle.pbWeather== :SANDSTORM || @battle.FE == :DESERT || @battle.FE == :ASHENBEACH
      when :SLUSHRUSH
        speed*=2 if @battle.pbWeather== :HAIL || @battle.FE==:ICY || @battle.FE==:SNOWYMOUNTAIN || @battle.FE==:FROZENDIMENSION
      when :SLOWSTART
        speed*=0.5 if self.turncount<5 && !@battle.FE == :DEEPEARTH
      when :QUARKDRIVE
        speed*=1.5 if self.effects[:Quarkdrive][0] == PBStats::SPEED
    end
    case @battle.FE
      when :NEWWORLD
        speed*=0.75 if !self.isAirborne?
      when :WATERSURFACE, :MURKWATERSURFACE
        speed*=0.75 if !self.isAirborne? && self.ability != :SURGESURFER && self.ability != :SWIFTSWIM && !self.hasType?(:WATER)
      when :UNDERWATER
        speed*=0.5 if !self.hasType?(:WATER) && self.ability != :SWIFTSWIM && self.ability != :STEELWORKER
    end
    if self.itemWorks?
      if (self.item == :CHOICESCARF)
        speed=(speed*1.5).floor
      elsif (self.item == :MACHOBRACE) || (self.item == :POWERWEIGHT) || (self.item == :POWERBRACER) || (self.item == :POWERBELT) || (self.item == :POWERANKLET) || (self.item == :POWERLENS) || (self.item == :POWERBAND)|| 
        (self.item == :CANONPOWERWEIGHT) || (self.item == :CANONPOWERBRACER) || (self.item == :CANONPOWERBELT) || (self.item == :CANONPOWERANKLET) || (self.item == :CANONPOWERLENS) || (self.item == :CANONPOWERBAND)
        speed=(speed/2.0).floor
      elsif @battle.FE == :DEEPEARTH && self.item == :FLOATSTONE
        speed=(speed*1.2).floor
      end
    end
    speed*=2 if self.crested == :CASTFORM && self.form == 3 && (@battle.pbWeather== :HAIL || @battle.FE==:ICY || @battle.FE==:SNOWYMOUNTAIN || @battle.FE==:FROZENDIMENSION)
    speed*=2 if self.crested == :EMPOLEON && (@battle.pbWeather== :HAIL || @battle.FE==:ICY || @battle.FE==:SNOWYMOUNTAIN || @battle.FE==:FROZENDIMENSION)
    speed*=0.5 if self.item == :IRONBALL if !@battle.FE == :DEEPEARTH
    if self.status== :PARALYSIS && self.ability != :QUICKFEET
      speed=(speed/2.0).floor
    end
    speed = 1 if speed <= 1
    return speed.floor
  end

################################################################################
# Change HP
################################################################################
  def pbReduceHP(amt,anim=false,emercheck=true)
    if amt>=self.hp
      amt=self.hp
    elsif amt<=0 && !self.isFainted?
      amt=1
    end
    oldhp=self.hp
    self.hp-=amt
    raise _INTL("HP less than 0") if self.hp<0
    raise _INTL("HP greater than total HP") if self.hp>@totalhp
    @battle.scene.pbHPChanged(self,oldhp,anim) if amt>0
    pbEmergencyExitCheck(oldhp) if emercheck
    return amt
  end

  def pbRecoverHP(amt,anim=false)
    # i am sure this will never cause issues /s
    # reduces healing effects on backalley if the recover amount isn't 100% of a mons HP 
    # due to AI used potions calling this method has to check from which method it's being called to not reduce healing effect of AI potions - Fal
    if @battle.FE == :BACKALLEY && !(amt >= @totalhp) && !(caller_locations.any? {|string| string.to_s.include?("pbEnemyUseItem")})
      amt= (amt*0.67).floor
    end
    if self.hp+amt>@totalhp
      amt=@totalhp-self.hp
    elsif amt<=0 && self.hp!=@totalhp
      amt=1
    end
    oldhp=self.hp
    self.hp+=amt
    raise _INTL("HP less than 0") if self.hp<0
    raise _INTL("HP greater than total HP") if self.hp>@totalhp
    @battle.scene.pbHPChanged(self,oldhp,anim) if amt>0
    return amt
  end

  def pbFaint(showMessage=true)
    if !self.isFainted?
      PBDebug.log("!!!***Can't faint with HP greater than 0") if $INTERNAL
      return true
    end
    if @fainted
      return true
    end
    @battle.scene.pbFainted(self)
    @battle.neutralizingGasDisable(self.index) if self.ability == :NEUTRALIZINGGAS
    if (pbPartner.ability == :POWEROFALCHEMY || pbPartner.ability == :RECEIVER) && pbPartner.hp > 0
      if PBStuff::ABILITYBLACKLIST.none? {|forbidden_ability| forbidden_ability==@ability}
        oldability = pbPartner.ability
        partnerability=@ability
        pbPartner.ability=partnerability
        abilityname=getAbilityName(partnerability)
        if oldability == :POWEROFALCHEMY
          @battle.pbDisplay(_INTL("{1} took on {2}'s {3}!",pbPartner.pbThis,pbThis,abilityname))
        else
          @battle.pbDisplay(_INTL("{1} received {2}'s {3}!",pbPartner.pbThis,pbThis,abilityname))
        end
        if pbPartner.ability == :INTIMIDATE
          for i in @battle.battlers
            next if i.isFainted? || !pbIsOpposing?(i.index)
            i.pbReduceAttackStatStageIntimidate(pbPartner)
          end
        end
      end
    end
    for i in @battle.battlers
      next if i.isFainted?
      if i.ability == :SOULHEART && !i.pbTooHigh?(PBStats::SPATK)
        @battle.pbDisplay(_INTL("{1}'s Soul-heart activated!",i.pbThis))
        i.pbIncreaseStat(PBStats::SPATK,1)
        if (@battle.FE==:MISTY || @battle.FE==:RAINBOW || @battle.FE==:FAIRYTALE) && !i.pbTooHigh?(PBStats::SPDEF)
          i.pbIncreaseStat(PBStats::SPDEF,1)
        end
      end
    end
    droprelease = self.effects[:SkyDroppee]
    #if locked in sky drop while fainting
    if self.effects[:SkyDrop]
      for i in @battle.battlers
        next if i.isFainted?
        if i.effects[:SkyDroppee]==self
          @battle.scene.pbUnVanishSprite(i)
          i.effects[:TwoTurnAttack] = 0
          i.effects[:SkyDroppee] = nil
        end
      end
    end
    @battle.pbDisplayPaused(_INTL("{1} fainted!",pbThis)) if showMessage
    pbInitEffects(false)
    self.vanished=false
    # reset status
    self.status=nil
    self.statusCount=0
    if @pokemon && @battle.internalbattle
      @pokemon.changeHappiness("faint")
    end
    if self.isMega?
      @pokemon.makeUnmega
    end
    if self.isUltra?
      @pokemon.makeUnultra(@startform)
    end
    @fainted=true
    # reset choice
    @battle.choices[@index]=[0,0,nil,-1]
    if @userSwitch
      @userSwitch = false
    end
    #reset mimikyu form if it faints
    if @species==:MIMIKYU && @pokemon.form==1
      self.form=0
    end
    #stops being in middle of a spread move
    @midwayThroughMove = false
    #deactivate ability
    self.ability=nil
    self.crested=false
    if droprelease!=nil
      oppmon = droprelease
      oppmon.effects[:SkyDrop]=false
      @battle.scene.pbUnVanishSprite(oppmon)
      @battle.pbDisplay(_INTL("{1} is freed from Sky Drop effect!",oppmon.pbThis))
    end
    # set ace message flag
    if (self.index==1 || self.index==3) && !@battle.pbIsWild? && !@battle.opponent.is_a?(Array) && @battle.pbPokemonCount(@battle.party2)==1 && !@battle.ace_message_handled
      @battle.ace_message=true
    end
    @battle.scene.partyBetweenKO1(self.index==1 || self.index==3) unless (@battle.doublebattle || pbNonActivePokemonCount==0)
    PBDebug.log("[#{pbThis} fainted]") if $INTERNAL
    return true
  end

################################################################################
# Find other battlers/sides in relation to this battler
################################################################################
# Returns the data structure for this battler's side
  def pbOwnSide
    return @battle.sides[@index&1] # Player: 0 and 2; Foe: 1 and 3
  end

# Returns the data structure for the opposing Pokémon's side
  def pbOpposingSide
    return @battle.sides[(@index&1)^1] # Player: 1 and 3; Foe: 0 and 2
  end

# Returns whether the position belongs to the opposing Pokémon's side
  def pbIsOpposing?(i)
    return (@index&1)!=(i&1)
  end

# Returns the battler's partner
  def pbPartner
    #puts @battle.battlers.inspect
    return @battle.battlers[(@index^2)] ? @battle.battlers[(@index^2)] : nil
  end

# Returns the battler's first opposing Pokémon
  def pbOpposing1
    return @battle.battlers[((@index&1)^1)]
  end

# Returns the battler's second opposing Pokémon
  def pbOpposing2
    return @battle.battlers[((@index&1)^1)+2]
  end

  def pbOppositeOpposing
    if @battle.doublebattle
      return @battle.battlers[(@index^3)].pokemon.nil? ? @battle.battlers[(@index^1)] : @battle.battlers[(@index^3)]
    else
      return @battle.battlers[(@index^1)]
    end
  end

  def pbCrossOpposing
    if @battle.doublebattle
      return @battle.battlers[(@index^1)].pokemon.nil? ? @battle.battlers[(@index^3)] : @battle.battlers[(@index^1)]
    else
      return @battle.battlers[(@index^3)]
    end
  end

  def pbNonActivePokemonCount()
    count=0
    party=@battle.pbPartySingleOwner(self.index)
    for i in 0...party.length
      if (self.isFainted? || i!=self.pokemonIndex) && (pbPartner.isFainted? || i!=self.pbPartner.pokemonIndex) && party[i] && !party[i].isEgg? && party[i].hp>0
        count+=1
      end
    end
    return count
  end

  def pbFaintedPokemonCount()
    count=0
    party=@battle.pbParty(self.index)
    for i in 0...party.length
      if party[i] && !party[i].isEgg? && party[i].hp==0
        count+=1
      end
    end
    return count
  end
  
  def pbEnemyNonActivePokemonCount()
    count=0
    party=@battle.pbParty(pbOppositeOpposing.index)
    for i in 0...party.length
      if (self.isFainted? || i!=self.pokemonIndex) &&
        (pbPartner.isFainted? || i!=self.pbPartner.pokemonIndex) &&
        party[i] && !party[i].isEgg? && party[i].hp>0
        count+=1
      end
    end
    return count
  end
  
  def pbEnemyFaintedPokemonCount()
    count=0
    party=@battle.pbParty(pbOppositeOpposing.index)
    for i in 0...party.length
      if party[i] && !party[i].isEgg? && party[i].hp==0
        count+=1
      end
    end
    return count
  end

################################################################################
# Forms
################################################################################
  def pbCheckForm(basemove = nil) # TODO: try and find a different way of doing this - I'm not liking this    return if @effects[:Transform]
    transformed=false
    # Forecast
    if Rejuv
      pbZoroCrestForms(basemove)
    end
    if (self.pokemon && self.pokemon.species == :CASTFORM)
      if self.ability == :FORECAST
        if !self.hasWorkingItem(:UTILITYUMBRELLA)
          case @battle.pbWeather
            when :SUNNYDAY
              if self.form!=1
                self.form=1
                transformed=true
              end
            when :RAINDANCE
              if self.form!=2
                self.form=2
                transformed=true
              end
            when :HAIL
              if self.form!=3
                self.form=3
                transformed=true
              end
            else
              if self.form!=0
                self.form=0
                transformed=true
              end
          end
        end
      else
        if self.form!=0
          self.form=0
          pbUpdate(false)
          @battle.scene.pbChangePokemon(self,@pokemon)
          @type1   = @pokemon.type1
          @type2   = @pokemon.type2
        end
      end
      showmessage=transformed
    end
    # Cherrim
    if (self.pokemon && self.pokemon.species == :CHERRIM) && !self.isFainted?
      if (self.ability == :FLOWERGIFT)
        # Cherrim Crest
        if self.crested == :CHERRIM || (@battle.pbWeather == :SUNNYDAY && !self.hasWorkingItem(:UTILITYUMBRELLA)) || 
          @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN) || @battle.FE == :BEWITCHED
          if self.form!=1
            self.form=1
            transformed=true
          end
        elsif self.form!=0
          self.form=0
          transformed=true
        end
      else
        if self.form!=0
          self.form=0
          @battle.pbCommonAnimation("FlowerGiftNotSun",self,nil)
          pbUpdate(false)
          @battle.scene.pbChangePokemon(self,@pokemon)
          @type1   = @pokemon.type1
          @type2   = @pokemon.type2
        end
      end
    end
    # Shaymin
    if (self.pokemon && self.pokemon.species == :SHAYMIN) && !self.isFainted?
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    # Giratina
    if (self.pokemon && self.pokemon.species == :GIRATINA) && !self.isFainted?
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    # Zen Mode
    if (self.pokemon && self.pokemon.species == :DARMANITAN) && !self.isFainted?
      if (self.ability == :ZENMODE || self.crested == :DARMANITAN)
        # Darmanitan Crest
        if self.crested == :DARMANITAN && self.form==0
          self.form=1
          transformed=true
        else
          if @battle.FE == :ASHENBEACH || (Rejuv && @battle.FE == :PSYTERRAIN)
            if self.form==0
              self.form=1; transformed = true
            end
          elsif @battle.FE == :BURNING ||  @battle.FE == :SUPERHEATED
            if self.form==2
              self.form=3; transformed = true
            end  
          elsif @hp<=((@totalhp/2.0).floor)
            if self.form == 0
              self.form = 1; transformed=true   
            elsif self.form == 2
              self.form = 3; transformed=true
            end
          end
        end
      end
    end
    # Keldeo
    if (self.pokemon && self.pokemon.species == :KELDEO) && !self.isFainted?
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
   # Genesect
    if (self.pokemon && self.pokemon.species == :GENESECT) && !self.isFainted?
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    # UPDATE 1/18/2014
    # Aegislash
    if (self.pokemon && self.pokemon.species == :AEGISLASH) && !self.isFainted?
      if (self.ability == :STANCECHANGE && !@effects[:Transform])
        # in Shield Forme and used a damaging move
        if self.form == 0 && !basemove.nil? && basemove.basedamage > 0
          self.form = 1 ; transformed = true
        # in Blade Forme and used King's Shield
        elsif self.form == 1 && !basemove.nil? && basemove.move == :KINGSSHIELD
          self.form = 0 ; transformed = true
        end
      end
    end # end of update
    # If the form of the Pokémon changed
    if transformed

      # Animations
      @battle.pbCommonAnimation("Forecast",self,nil) if self.species == :CASTFORM
      if self.species == :CHERRIM
        if self.form == 1
          @battle.pbCommonAnimation("FlowerGiftSun",self,nil)
        else
          @battle.pbCommonAnimation("FlowerGiftNotSun",self,nil)
        end
      end
      @battle.pbCommonAnimation("ZenMode",self,nil) if self.species == :DARMANITAN
      if self.species == :AEGISLASH
        if self.form == 1
          @battle.pbCommonAnimation("StanceAttack",self,nil)
        else
          if self.index == 0 || self.index == 2
            @battle.pbCommonAnimation("StanceProtect",self,nil)
          else
            @battle.pbCommonAnimation("StanceProtectOpp",self,nil)
          end
        end
      end

      # Battler update
      if self.species == :AEGISLASH && (self.type1 != @pokemon.type1 || self.type2 != @pokemon.type2) 
        pbUpdate(false)
      else
        pbUpdate(true)
      end
      @battle.scene.pbChangePokemon(self,@pokemon)
      @battle.pbDisplay(_INTL("{1} transformed!",pbThis))

      if (self.ability == :STANCECHANGE) && (@battle.FE == :FAIRYTALE || (Rejuv && @battle.FE == :CHESS)) 
        if (self.form == 0)
          self.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false)
          self.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
        else
          self.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false)
          self.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
        end
      end
    end
  end

  def pbCheckFormRoundEnd
    # Wishiwashi
    if (self.species == :WISHIWASHI) && !self.isFainted?
      if self.ability == :SCHOOLING && !@effects[:Transform]
        schoolHP = (self.totalhp/4.0).floor
        if (self.hp>schoolHP && self.level>19) || [:WATERSURFACE,:UNDERWATER,:MURKWATERSURFACE].include?(@battle.FE)
          if self.form!=1
            self.form=1
            @battle.pbCommonAnimation("SchoolForm",self,nil)
            pbUpdate(true)
            @battle.scene.pbChangePokemon(self,@pokemon)
            @battle.pbDisplay(_INTL("{1} formed a school!",pbThis))
          end
        else
          if self.form!=0
            self.form=0
            pbUpdate(true)
            @battle.scene.pbChangePokemon(self,@pokemon)
            @battle.pbDisplay(_INTL("{1} stopped schooling!",pbThis))
          end
        end
      end
    end
    # Minior
    if (self.species == :MINIOR) && !self.isFainted?
      if self.ability == :SHIELDSDOWN && !@effects[:Transform]
        coreHP = (self.totalhp/2.0).floor
        if self.hp>coreHP
          if self.form!=7
            self.form=7
            @battle.pbCommonAnimation("ShieldsUp",self,nil)
            pbUpdate(true)
            @battle.scene.pbChangePokemon(self,@pokemon)
            @battle.pbDisplay(_INTL("{1}'s shields came up!",pbThis))
          end
        else
          if self.form!=self.startform
            self.form=self.startform
            @battle.pbCommonAnimation("ShieldsDown",self,nil)
            pbUpdate(true)
            @battle.scene.pbChangePokemon(self,@pokemon)
            @battle.pbDisplay(_INTL("{1}'s shields went down!",pbThis))
          end
        end
      end
    end
    # Eiscue on fire fields
    if self.species == :EISCUE && !self.isFainted? &&
      self.effects[:IceFace] && (@battle.field.effect == :VOLCANIC || @battle.field.effect == :VOLCANICTOP || @battle.field.effect == :INFERNAL)
      self.pbBreakDisguise
      @battle.pbDisplayPaused(_INTL("{1} transformed!",self.name))
      self.effects[:IceFace]=false
    end  
    # Download mons on Dimensional
    if @battle.field.effect == :DIMENSIONAL && self.ability == :DOWNLOAD
      type = @battle.getRandomType 
      self.type1=type
      self.type2=nil
      @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",self.pbThis,type.capitalize))
    end
    # Zygarde
    if (self.pokemon && self.pokemon.species == :ZYGARDE) && !self.isFainted? && !self.effects[:Transform]
      if self.ability == :POWERCONSTRUCT
        completeHP = (self.totalhp/2.0).floor
        if self.hp<=completeHP
          if self.form!=2
            @battle.pbDisplay(_INTL("You sense the presence of many!"))
            self.pokemon.originalForm=self.pokemon.form
            self.form=2
            @battle.pbCommonAnimation("ZygardeForms",self,nil)
            pbUpdate(true)
            @battle.scene.pbChangePokemon(self,@pokemon)
            @battle.pbDisplay(_INTL("{1} transformed into its Complete Forme!",pbThis))
            if @battle.FE == :DEEPEARTH
              for stat in 1..5 
                statraise = false
                if !pbTooHigh?(stat)  
                  pbIncreaseStatBasic(stat,1)
                  statraise = true
                end
              end
              if statraise
                @battle.pbCommonAnimation("StatUp",self,nil)
                @battle.pbDisplay(_INTL("The core's energy empowered {1}!",pbThis))
              end
            end 
          end
        end
      end
    end
    # Silvally / Arceus
    if (((self.ability == :RKSSYSTEM && self.species == :SILVALLY) || self.crested == :SILVALLY) ||
      (self.ability == :MULTITYPE && self.species == :ARCEUS)) && !self.isFainted?
      oldform = self.form
      if @battle.field.effect == :NEWWORLD
        @battle.NWTypeRoll(self) 
        transformed=true
        return
      else
        if oldform==0 #Trying to avoid overwriting PBS set forms for them
          self.form = formFromItem 
          self.form += $cache.types.length if ($game_switches[:Pulse_Arceus] && mon.species == :ARCEUS && mon.pokemon.trainerID == 00000)
        end
      end
      if self.species == :SILVALLY && (@battle.field.effect == :GLITCH || @battle.field.effect == :HOLY)
        if @battle.field.effect == :GLITCH
          roll = 9
        elsif @battle.field.effect == :HOLY
          roll = 17
        end
        self.form = roll
        backupspecies=self.pokemon.species
        self.pokemon.species=self.species if self.effects[:Transform]
        if self.form != oldform
          pbUpdate(true)
          if @battle.field.effect == :GLITCH
            @battle.pbCommonAnimation("SilvallyGlitch",self,nil)
          elsif @battle.field.effect == :HOLY
            @battle.pbCommonAnimation("SilvallyHoly",self,nil)
          end
          @battle.scene.pbChangePokemon(self,@pokemon)
          self.pokemon.species=backupspecies
          if @battle.field.effect == :GLITCH
            @battle.pbDisplay(_INTL("{1} was corrupted by the rogue data!",pbThis))
          elsif @battle.field.effect == :HOLY
            @battle.pbDisplay(_INTL("A false god holds no power here..."))
          end
          transformed=true
          return
        end
      end
      if self.form != oldform && transformed==true
        pbUpdate(true)
        @battle.pbCommonAnimation("TypeRoll",self,nil)
        @battle.scene.pbChangePokemon(self,@pokemon)
        self.pokemon.species=backupspecies
        @battle.pbDisplay(_INTL("{1} reverted to the {2} type!",pbThis,self.type1.capitalize))
      end
    end
  end

  def pbCheckBurmyForm
    return if self.species != :BURMY || self.isFainted?
    originalform = self.form
    if PBFields::TRASHCLOAK.include?(@battle.FE)
      self.form=2 # Trash Cloak
    elsif PBFields::PLANTCLOAK.include?(@battle.FE)
      self.form=0 # Plant Cloak
    elsif PBFields::SANDYCLOAK.include?(@battle.FE)
      self.form=1 # Sandy CloaK
    else
      env=@battle.environment 
      if env==:Sand || env==:Rock || env==:Cave
        self.form=1 # Sandy Cloak
      elsif env==:Grass || env==:TallGrass || env==:MovingWater || env==:StillWater || env==:Underwater
        self.form=0 # Plant Cloak
      else
        self.form=2 # Trash Cloak
      end
    end
    if originalform != self.form
      case self.form
      when 1 then @battle.pbCommonAnimation("BurmySandy",self,nil)
      when 2 then @battle.pbCommonAnimation("BurmyTrash",self,nil)
      else @battle.pbCommonAnimation("BurmyPlant",self,nil)
      end
      @battle.scene.pbChangePokemon(self,@pokemon)
      @battle.pbDisplay(_INTL("{1} changed form to match the environment!",pbThis))
    end
  end

  def pbBreakDisguise
    self.form=1
    pbUpdate(true)
    if self.index == 0 || self.index == 2
      @battle.pbCommonAnimation("DisguiseBust1",self,nil)
    else
      @battle.pbCommonAnimation("DisguiseBust1Opp",self,nil)
    end
    @battle.scene.pbChangePokemon(self,@pokemon)
    if self.index == 0 || self.index == 2
      @battle.pbCommonAnimation("DisguiseBust2",self,nil)
    else
      @battle.pbCommonAnimation("DisguiseBust2Opp",self,nil)
    end
    @battle.scene.pbDamageAnimation(self,0)
  end

  def pbRegenFace
    self.form=0
    @effects[:IceFace] = true
    pbUpdate(true)
    @battle.scene.pbChangePokemon(self,@pokemon)
  end

  def pbResetForm
    return if !@pokemon
    if !@effects[:Transform]
      if (@pokemon.species == :CASTFORM)   ||
        (@pokemon.species == :CHERRIM)    ||
        #(@pokemon.species == :MELOETTA)   ||
        (@pokemon.species == :AEGISLASH && self.form < 2)  ||
        (@pokemon.species == :WISHIWASHI) ||
        @pokemon.species == :DITTO        ||
        @pokemon.species == :MEW          ||
        @pokemon.species == :MORPEKO      ||
        @pokemon.species == :CRAMORANT
        self.form=0
      elsif (@pokemon.species == :DARMANITAN) ||
        (@pokemon.species == :MINIOR)
        self.form=@startform
      end
    end
    pbUpdate(true)
  end

################################################################################
# Ability effects
################################################################################
  def pbAbilitiesOnSwitchIn(onactive)
    return if @hp<=0
    if (self.species == :KYOGRE && self.item== :BLUEORB) || (self.species == :GROUDON && self.item== :REDORB)
      if self.form == 0 
        if self.species == :KYOGRE
          @battle.pbCommonAnimation("PrimalReversionKyogre",self,nil)
        else          
          @battle.pbCommonAnimation("PrimalReversionGroudon",self,nil)
        end
        @pokemon.makePrimal
        @backupability = @pokemon.ability
        pbUpdate(true)
        @battle.scene.pbChangePokemon(self,@pokemon)
        @battle.pbDisplay(_INTL("{1}'s Primal Reversion! It reverted to its primal form!",pbThis))
      end
    end
    #### END OF PRIMAL REVERSIONS

    self.pbCheckFormRoundEnd if onactive
    pbCheckBurmyForm if onactive
    #### NEUTRALIZING GAS
    if self.ability == :NEUTRALIZINGGAS && onactive
      for i in 0...4
        @battle.battlers[i].ability = nil if !(PBStuff::FIXEDABILITIES).include?(@battle.battlers[i].ability) && @battle.battlers[i].ability != :NEUTRALIZINGGAS
      end
    end
    #### START OF WEATHER ABILITIES
    rainbowhold=0
    if onactive
      if (self.ability == :PRIMORDIALSEA) && !@battle.state.effects[:HeavyRain] && @battle.canSetWeather?
        @battle.state.effects[:HeavyRain] = true
        @battle.state.effects[:HarshSunlight] = false
        @battle.weatherduration=-1
        @battle.pbDisplay(_INTL("A heavy rain began to fall!"))
        if @battle.weather== :SUNNYDAY
          rainbowhold=5
          rainbowhold=8 if self.hasWorkingItem(:DAMPROCK)
        end
        @battle.weather=:RAINDANCE
        @battle.pbCommonAnimation("Rain",nil,nil)
      end

      if (self.ability == :DESOLATELAND) && !@battle.state.effects[:HarshSunlight] && @battle.canSetWeather?
        @battle.state.effects[:HarshSunlight] = true
        @battle.state.effects[:HeavyRain] = false
        @battle.weatherduration=-1
        @battle.pbDisplay(_INTL("The sunlight turned extremely harsh!"))
        if @battle.weather== :RAINDANCE
          rainbowhold=5
          rainbowhold=8 if self.hasWorkingItem(:HEATROCK)
        end
        if (Rejuv && @battle.FE == :GRASSY)
          setField(:DESERT)
          @battle.pbDisplay(_INTL("The extremely harsh sunlight dried out the meadow!"))
        end 
        @battle.weather=:SUNNYDAY
        @battle.pbCommonAnimation("Sunny",nil,nil)
      end

      if (self.ability == :DELTASTREAM) && @battle.weather!=:STRONGWINDS && @battle.canSetWeather?
        @battle.weather=:STRONGWINDS
        @battle.state.effects[:HarshSunlight] = false
        @battle.state.effects[:HeavyRain] = false
        @battle.weatherduration=-1
        @battle.pbDisplay(_INTL("A mysterious air current is protecting Flying-type Pokémon!"))
      end
    end

    if @battle.state.effects[:HeavyRain] || @battle.state.effects[:HarshSunlight] || @battle.weather == :STRONGWINDS
      if !@battle.pbCheckGlobalAbility(:PRIMORDIALSEA)
        if @battle.state.effects[:HeavyRain]
          @battle.pbDisplay(_INTL("The heavy rain has lifted."))
          @battle.state.effects[:HeavyRain] = false
          unless ((self.ability == :PRIMORDIALSEA) || (self.ability == :DESOLATELAND) || (self.ability == :DELTASTREAM)) && onactive
            @battle.weatherduration = 0
            @battle.weather = 0
            @battle.persistentWeather
          end
        end
      end
      if !@battle.pbCheckGlobalAbility(:DESOLATELAND)
        if @battle.state.effects[:HarshSunlight]
          @battle.pbDisplay(_INTL("The harsh sunlight faded!"))
          @battle.state.effects[:HarshSunlight] = false
          unless ((self.ability == :PRIMORDIALSEA) || (self.ability == :DESOLATELAND) || (self.ability == :DELTASTREAM)) && onactive
            @battle.weatherduration = 0
            @battle.weather = 0
            @battle.persistentWeather
          end
        end
      end
      
      if !@battle.pbCheckGlobalAbility(:DELTASTREAM) && !@battle.pbCheckGlobalAbility(:TEMPEST) && ![:Winds,:BlowingLeaves,:SwirlingLeaves].include?($game_screen.weather_type) && !((self.pbOwnSide.effects[:Tailwind]>0 || self.pbOpposingSide.effects[:Tailwind]>0) && [:MOUNTAIN,:SNOWYMOUNTAIN,:VOLCANICTOP,:SKY].include?(@battle.FE))
        if @battle.weather == :STRONGWINDS
          @battle.pbDisplay(_INTL("The mysterious air current has dissipated!"))
          unless ((self.ability == :PRIMORDIALSEA) || (self.ability == :DESOLATELAND) || (self.ability == :DELTASTREAM)) && onactive
            @battle.weatherduration = 0
            @battle.weather = 0
            @battle.persistentWeather
          end
        end
      end
    end
    # END OF PRIMAL WEATHER DEACTIVATION TESTS
    if !@battle.pbCheckGlobalAbility(:DARKSURGE) && (@battle.FE==:DARKNESS1 || @battle.FE==:DARKNESS2 || @battle.FE==:DARKNESS3)
      if @battle.field.duration>0
        @battle.endTempField
        @battle.field.duration =0
        @battle.pbDisplay(_INTL("The darkness dissipated."))
      end
    end
    # Trace
    if self.ability == :TRACE
      if @effects[:Trace] || onactive
        choices=[]
        for i in 0...4
          if pbIsOpposing?(i) && !@battle.battlers[i].isFainted?
            abilitycheck = true
            abilitycheck = false if (PBStuff::ABILITYBLACKLIST).include?(@battle.battlers[i].ability) || @battle.battlers[i].ability==0
            abilitycheck = true if @battle.battlers[i].ability == :WONDERGUARD
            choices.push(i) if abilitycheck
          end
        end
        if choices.length==0
          @effects[:Trace]=true
        else
          choice=choices.sample
          battlername=@battle.battlers[choice].pbThis(true)
          battlerability=@battle.battlers[choice].ability
          @ability=battlerability
          abilityname=getAbilityName(battlerability)
          @battle.pbDisplay(_INTL("{1} traced {2}'s {3}!",pbThis,battlername,abilityname))
          @effects[:Trace]=false
        end
      end
    end
    #Surges
    duration=5
    duration=8 if self.hasWorkingItem(:AMPLIFIELDROCK)
    if self.ability == :ELECTRICSURGE && onactive && ((!Rejuv && @battle.canChangeFE?(:ELECTERRAIN)) || @battle.canChangeFE?([:ELECTERRAIN,:DRAGONSDEN])) && !(@battle.state.effects[:ELECTERRAIN] > 0)
      if @battle.FE == :FROZENDIMENSION
        @battle.pbDisplay(_INTL("The frozen dimension remains unchanged."))
      else
        @battle.pbAnimation(:ELECTRICTERRAIN,self,nil)
        @battle.setField(:ELECTERRAIN,duration)
        @battle.pbDisplay(_INTL("The terrain became electrified!"))
      end
    elsif self.ability == :GRASSYSURGE && onactive && ((!Rejuv && @battle.canChangeFE?(:GRASSY)) || @battle.canChangeFE?([:GRASSY,:DRAGONSDEN])) && !(@battle.state.effects[:GRASSY] > 0)
      if @battle.FE == :FROZENDIMENSION
        @battle.pbDisplay(_INTL("The frozen dimension remains unchanged."))
      else
        @battle.pbAnimation(:GRASSYTERRAIN,self,nil)
        @battle.setField(:GRASSY,duration) 
        @battle.pbDisplay(_INTL("The terrain became grassy!"))
      end
    elsif self.ability == :MISTYSURGE && onactive && ((!Rejuv && @battle.canChangeFE?(:MISTY)) || @battle.canChangeFE?([:MISTY,:CORROSIVEMIST,:DRAGONSDEN])) && !(@battle.state.effects[:MISTY] > 0)
      if @battle.FE == :FROZENDIMENSION
        @battle.pbDisplay(_INTL("The frozen dimension remains unchanged."))
      else
        @battle.pbAnimation(:MISTYTERRAIN,self,nil)
        @battle.setField(:MISTY,duration)
        @battle.pbDisplay(_INTL("The terrain became misty!"))
      end
    elsif self.ability == :PSYCHICSURGE && onactive && ((!Rejuv && @battle.canChangeFE?(:PSYTERRAIN)) || @battle.canChangeFE?([:PSYTERRAIN,:DRAGONSDEN])) && !(@battle.state.effects[:PSYTERRAIN] > 0)
      if @battle.FE == :FROZENDIMENSION
        @battle.pbDisplay(_INTL("The frozen dimension remains unchanged."))
      else
        @battle.pbAnimation(:PSYCHICTERRAIN,self,nil)
        @battle.setField(:PSYTERRAIN,duration)
        @battle.pbDisplay(_INTL("The terrain became mysterious!"))
      end
    elsif self.ability == :DARKSURGE && onactive 
      if @battle.FE== :DARKNESS3
        self.pbIncreaseStatBasic(PBStats::SPEED,1)
        @battle.pbCommonAnimation("StatUp",self,nil)
        @battle.pbDisplay(_INTL("{1}'s Dark Surge raised its Speed!", pbThis))
      elsif @battle.FE== :DARKNESS1
        @battle.setField(:DARKNESS2) 
        @battle.pbDisplay(_INTL("{1}'s Dark Surge deepened the darkness!",pbThis))
      elsif @battle.FE== :DARKNESS2
        @battle.setField(:DARKNESS3) 
        @battle.pbDisplay(_INTL("{1}'s Dark Surge deepened the darkness!",pbThis))
      elsif @battle.canChangeFE?(:DARKNESS2)
        @battle.setField(:DARKNESS2,3) 
        @battle.pbDisplay(_INTL("Darkness gathers..."))
      end
    end

    # Field Seeds
    @battle.seedCheck if @battle.turncount!=0

    # Curious Medicine
    if self.ability == (:CURIOUSMEDICINE) && onactive
      worked = false
      for i in 1...pbPartner.stages.length # skips HP
        if pbPartner.stages[i] != 0
          pbPartner.stages[i] = 0
          worked = true
        end
      end
      @battle.pbDisplay(_INTL("{1}'s {2} removed {3}'s stat changes!",pbThis,getAbilityName(self.ability),pbPartner.pbThis(true))) if worked
    end    

    # Weather Abilities
    if (ability == :DRIZZLE) && onactive && @battle.weather!=:RAINDANCE
      if @battle.state.effects[:HeavyRain]
        @battle.pbDisplay(_INTL("There's no relief from this heavy rain!"))
      elsif @battle.state.effects[:HarshSunlight]
        @battle.pbDisplay(_INTL("The extremely harsh sunlight was not lessened at all!"))
      elsif @battle.weather== :STRONGWINDS && (@battle.battlers[0].ability == :DELTASTREAM || @battle.battlers[1].ability == :DELTASTREAM ||
        @battle.battlers[2].ability == :DELTASTREAM || @battle.battlers[3].ability == :DELTASTREAM)
        @battle.pbDisplay(_INTL("The mysterious air current blows on regardless!"))
      elsif @battle.FE == :NEWWORLD
        @battle.pbDisplay(_INTL("The weather disappeared into space!"))
      elsif @battle.FE == :UNDERWATER
        @battle.pbDisplay(_INTL("You're too deep to notice the weather!"))
      elsif @battle.FE == :DIMENSIONAL
        @battle.pbDisplay(_INTL("The dark dimension swallowed the rain."))
      elsif @battle.FE == :INFERNAL
        @battle.pbDisplay(_INTL("The rain evaporated."))
      else
        if @battle.weather== :SUNNYDAY
          rainbowhold=5
          rainbowhold=8 if self.hasWorkingItem(:DAMPROCK) || @battle.FE == :SKY
        end
        @battle.weather=:RAINDANCE
        @battle.weatherduration=5
        @battle.weatherduration=8 if self.hasWorkingItem(:DAMPROCK) || @battle.FE == :SKY
        @battle.weatherduration=-1 if $game_switches[:Gen_5_Weather]==true
        @battle.pbCommonAnimation("Rain",nil,nil)
        @battle.pbDisplay(_INTL("{1}'s Drizzle made it rain!",pbThis))
      end
    end

    if (ability == :SANDSTREAM) && onactive && @battle.weather!=:SANDSTORM
      if @battle.state.effects[:HeavyRain]
        @battle.pbDisplay(_INTL("There's no relief from this heavy rain!"))
      elsif @battle.state.effects[:HarshSunlight]
        @battle.pbDisplay(_INTL("The extremely harsh sunlight was not lessened at all!"))
      elsif @battle.weather== :STRONGWINDS && @battle.pbCheckGlobalAbility(:DELTASTREAM)
        @battle.pbDisplay(_INTL("The mysterious air current blows on regardless!"))
      elsif @battle.FE == :NEWWORLD
        @battle.pbDisplay(_INTL("The weather disappeared into space!"))
      elsif @battle.FE == :UNDERWATER
        @battle.pbDisplay(_INTL("You're too deep to notice the weather!"))
      elsif @battle.FE == :DIMENSIONAL
        @battle.pbDisplay(_INTL("The dark dimension swallowed the sand."))
      else
        @battle.weather=:SANDSTORM
        @battle.weatherduration=5
        @battle.weatherduration=8 if self.hasWorkingItem(:SMOOTHROCK) || @battle.FE == :DESERT || @battle.FE == :ASHENBEACH || @battle.FE == :SKY
        @battle.weatherduration=-1 if $game_switches[:Gen_5_Weather]==true
        @battle.pbCommonAnimation("Sandstorm",nil,nil)
        @battle.pbDisplay(_INTL("{1}'s Sand Stream whipped up a sandstorm!",pbThis))
      end
    end

    if (ability == :DROUGHT) && onactive && @battle.weather!=:SUNNYDAY
      if @battle.state.effects[:HeavyRain]
        @battle.pbDisplay(_INTL("There's no relief from this heavy rain!"))
      elsif @battle.state.effects[:HarshSunlight]
        @battle.pbDisplay(_INTL("The extremely harsh sunlight was not lessened at all!"))
      elsif @battle.weather== :STRONGWINDS && (@battle.battlers[0].ability == :DELTASTREAM || @battle.battlers[1].ability == :DELTASTREAM ||
        @battle.battlers[2].ability == :DELTASTREAM || @battle.battlers[3].ability == :DELTASTREAM)
        @battle.pbDisplay(_INTL("The mysterious air current blows on regardless!"))
      elsif @battle.FE == :NEWWORLD
        @battle.pbDisplay(_INTL("The weather disappeared into space!"))
      elsif @battle.FE == :UNDERWATER
        @battle.pbDisplay(_INTL("You're too deep to notice the weather!"))
      elsif @battle.FE == :DIMENSIONAL
        @battle.pbDisplay(_INTL("The sunlight cannot pierce the darkness."))
      else
        if @battle.weather== :RAINDANCE
          rainbowhold=5
          rainbowhold=8 if self.hasWorkingItem(:HEATROCK) || @battle.FE == :DESERT || @battle.FE == :MOUNTAIN || @battle.FE == :SNOWYMOUNTAIN || @battle.FE == :SKY
        end
        @battle.weather=:SUNNYDAY
        @battle.weatherduration=5
        @battle.weatherduration=8 if self.hasWorkingItem(:HEATROCK) ||
          @battle.FE == :DESERT || @battle.FE == :MOUNTAIN || @battle.FE == :SNOWYMOUNTAIN || @battle.FE == :SKY
        @battle.weatherduration=-1 if $game_switches[:Gen_5_Weather]==true
        @battle.pbCommonAnimation("Sunny",nil,nil)
        @battle.pbDisplay(_INTL("{1}'s Drought intensified the sun's rays!",pbThis))
        if @battle.FE == :DARKCRYSTALCAVERN
          @battle.setField(:CRYSTALCAVERN,@battle.weatherduration)
          @battle.pbDisplay(_INTL("The sun lit up the crystal cavern!"))
        end
        @battle.reduceField if @battle.ProgressiveFieldCheck(PBFields::DARKNESS,2,3)
      end
    end

    if (ability == :SNOWWARNING) && onactive && @battle.weather!=:HAIL
      if @battle.state.effects[:HeavyRain]
        @battle.pbDisplay(_INTL("There's no relief from this heavy rain!"))
      elsif @battle.state.effects[:HarshSunlight]
        @battle.pbDisplay(_INTL("The extremely harsh sunlight was not lessened at all!"))
      elsif @battle.weather== :STRONGWINDS && (@battle.battlers[0].ability == :DELTASTREAM || @battle.battlers[1].ability == :DELTASTREAM ||
        @battle.battlers[2].ability == :DELTASTREAM || @battle.battlers[3].ability == :DELTASTREAM)
        @battle.pbDisplay(_INTL("The mysterious air current blows on regardless!"))
      elsif @battle.FE == :NEWWORLD
        @battle.pbDisplay(_INTL("The weather disappeared into space!"))
      elsif @battle.FE == :UNDERWATER
        @battle.pbDisplay(_INTL("You're too deep to notice the weather!"))
      elsif @battle.FE == :VOLCANIC || @battle.FE == :VOLCANICTOP || @battle.FE == :INFERNAL
        @battle.pbDisplay(_INTL("The hail melted away."))
      elsif @battle.FE == :DIMENSIONAL
        @battle.pbDisplay(_INTL("The dark dimension swallowed the hail."))
      else
        @battle.weather=:HAIL
        @battle.weatherduration=5
        @battle.weatherduration=8 if self.hasWorkingItem(:ICYROCK) || @battle.FE == :ICY || @battle.FE == :SNOWYMOUNTAIN || @battle.FE == :FROZENDIMENSION || @battle.FE == :SKY
        @battle.weatherduration=-1 if $game_switches[:Gen_5_Weather]==true
        @battle.pbCommonAnimation("Hail",nil,nil)
        @battle.pbDisplay(_INTL("{1}'s Snow Warning made it hail!",pbThis))
        for facemon in @battle.battlers
          if facemon.species==:EISCUE && facemon.form==1 # Eiscue
            facemon.pbRegenFace
            @battle.pbDisplayPaused(_INTL("{1} transformed!",facemon.name))
          end
        end
      end
    end
    if (ability== :TEMPEST) && onactive 
      weathers=rand(5)
      @battle.storm9 = true
      case weathers
       when 0
          if @battle.weather== :SUNNYDAY
            rainbowhold=8
          end
          @battle.weather=:RAINDANCE
          @battle.weatherduration=8
          @battle.pbCommonAnimation("Rain",nil,nil)
          @battle.pbDisplay(_INTL("Storm-9 created a downpour!"))
       when 1
          @battle.weather=:HAIL
          @battle.weatherduration=8
          @battle.pbCommonAnimation("Hail",nil,nil)
          @battle.pbDisplay(_INTL("Storm-9 brought hailfall!"))
          for facemon in @battle.battlers
            if facemon.species==:EISCUE && facemon.form==1 # Eiscue
              facemon.pbRegenFace
              @battle.pbDisplayPaused(_INTL("{1} transformed!",facemon.name))
            end
          end
       when 2
          @battle.weather=:SANDSTORM
          @battle.weatherduration=8
          @battle.pbCommonAnimation("Sandstorm",nil,nil)
          @battle.pbDisplay(_INTL("Storm-9 whipped up a duststorm!"))
       when 3
          @battle.weather=:STRONGWINDS
          @battle.weatherduration=8
          @battle.pbCommonAnimation("Wind",nil,nil)
          @battle.pbDisplay(_INTL("Storm-9 whipped up terrible winds!"))
       when 4
          @battle.weather=:SHADOWSKY
          @battle.weatherduration=8
          @battle.pbCommonAnimation("ShadowSky",nil,nil)
          @battle.pbDisplay(_INTL("Storm-9 shrouded the sky in a dark aura..."))
      end
    end

    if rainbowhold != 0
      fieldbefore = @battle.FE
      @battle.setField(:RAINBOW,rainbowhold)
      if fieldbefore != :RAINBOW
        @battle.pbDisplay(_INTL("The weather created a rainbow!"))
      else
        @battle.pbDisplay(_INTL("The weather refreshed the rainbow!"))
      end
    end 
    #### END OF WEATHER ABILITIES
    if onactive
      case self.ability
        when :AIRLOCK, :CLOUDNINE then @battle.pbDisplay(_INTL("The effects of the weather disappeared."))
        when :PRESSURE then @battle.pbDisplay(_INTL("{1} is exerting its Pressure!",pbThis))
        when :MOLDBREAKER then @battle.pbDisplay(_INTL("{1} breaks the mold!",pbThis))
        when :COMATOSE then @battle.pbDisplay(_INTL("{1} is drowsing!",pbThis)) if @battle.FE != :ELECTERRAIN
        when :TERAVOLT then @battle.pbDisplay(_INTL("{1} is radiating a bursting aura!",pbThis))
        when :TURBOBLAZE then @battle.pbDisplay(_INTL("{1} is radiating a blazing aura!",pbThis))
        when :FAIRYAURA then @battle.pbDisplay(_INTL("{1} is radiating a Fairy aura!",pbThis))
        when :DARKAURA then @battle.pbDisplay(_INTL("{1} is radiating a Dark aura!",pbThis))
        when :AURABREAK then @battle.pbDisplay(_INTL("{1} reversed all other Pokémon's auras!",pbThis))
        when :NEUTRALIZINGGAS then @battle.pbDisplay(_INTL("{1}'s gas neutralized all other Pokémon's abilities!",pbThis))
      end
    end
    # End of Update
    # Reflector - rejuv
    if self.ability == :REFLECTOR && onactive
      if !pbOppositeOpposing.isFainted?
        reflecttype= pbOppositeOpposing.type2.nil? ? pbOppositeOpposing.type1 : pbOppositeOpposing.type2
        prot1 = self.type1
        if reflecttype && !self.hasType?(reflecttype)
          self.type2=reflecttype
          @battle.pbDisplay(_INTL("{1} gained the {2} type!",pbThis,reflecttype.capitalize))
        end
      end
    end
    # Mimicry
    if self.ability == :MIMICRY && onactive
      protype = -1
      case @battle.FE
        when :CRYSTALCAVERN
          protype = @battle.field.getRoll
        when :NEWWORLD
          protype = @battle.getRandomType
        else
          protype = @battle.field.mimicry if @battle.field.mimicry
      end
      prot1 = self.type1
      prot2 = self.type2
      camotype = protype
      if camotype && !self.hasType?(camotype) || (!prot2.nil? && prot1 != prot2)
        self.type1=camotype
        self.type2=nil
        @battle.pbDisplay(_INTL("{1} had its type changed to {2}!",pbThis,camotype.capitalize))
      end
    end
    if self.ability == :ICEFACE && self.form == 1 && self.species == :EISCUE && onactive
      if @battle.weather == :HAIL
        self.pbRegenFace
        @battle.pbDisplay(_INTL("{1} transformed!",self.pbThis))
      end
    end
    # Pastel Veil
    if (self.ability == :PASTELVEIL && @battle.FE != :INFERNAL) && onactive
      if self.pbPartner.status == :POISON
        self.pbPartner.status=nil
        self.pbPartner.statusCount=0
        @battle.pbDisplay(_INTL("{1}'s Pastel Veil cured its partner's poison problem!",self.pbThis))
      end
    end
    # Intimidate
    if self.ability == :INTIMIDATE && onactive
      for i in 0...4
        next if !pbIsOpposing?(i) || @battle.battlers[i].isFainted?
        @battle.battlers[i].pbReduceAttackStatStageIntimidate(self)
      end
    end
    if Rejuv
      rejuvAbilities(onactive)
    end
    # Download
    if self.ability == :DOWNLOAD && onactive
      if (Rejuv && (@battle.FE == :SHORTCIRCUIT || @battle.FE == :GLITCH))
        if !(pbTooHigh?(PBStats::ATTACK) && pbTooHigh?(PBStats::SPATK))
          for stat in [PBStats::ATTACK,PBStats::SPATK]
            if self.pbCanIncreaseStatStage?(stat,false)
              pbIncreaseStatBasic(stat,1)
            end
          end
          @battle.pbCommonAnimation("StatUp",self)
          @battle.pbDisplay(_INTL("{1}'s {2} boosted its Offenses in the broken terrain!", pbThis,getAbilityName(ability)))
        end
      else
        stagemult=[2,2,2,2,2,2,2,3,4,5,6,7,8]
        stagediv=[8,7,6,5,4,3,2,2,2,2,2,2,2]
        odef=ospdef=0
        opp1=pbOpposing1
        opp2=pbOpposing2
        odef+=(opp1.defense*stagemult[opp1.stages[PBStats::DEFENSE]+6]/stagediv[opp1.stages[PBStats::DEFENSE]+6]) if opp1.hp>0
        ospdef+=(opp1.spdef*stagemult[opp1.stages[PBStats::SPDEF]+6]/stagediv[opp1.stages[PBStats::SPDEF]+6]) if opp1.hp>0
        if opp2
          odef+=(opp2.defense*stagemult[opp2.stages[PBStats::DEFENSE]+6]/stagediv[opp2.stages[PBStats::DEFENSE]+6]) if opp2.hp>0
          ospdef+=(opp2.spdef*stagemult[opp2.stages[PBStats::SPDEF]+6]/stagediv[opp2.stages[PBStats::SPDEF]+6]) if opp2.hp>0
        end
        if ospdef>odef
          if !pbTooHigh?(PBStats::ATTACK)
            if [:FACTORY,:CITY,:BACKALLEY].include?(@battle.FE) 
              pbIncreaseStatBasic(PBStats::ATTACK,2)
              @battle.pbCommonAnimation("StatUp",self)
              @battle.pbDisplay(_INTL("{1}'s {2} sharply boosted its Attack!", pbThis,getAbilityName(ability)))
            else
              pbIncreaseStatBasic(PBStats::ATTACK,1)
              @battle.pbCommonAnimation("StatUp",self)
              @battle.pbDisplay(_INTL("{1}'s {2} boosted its Attack!", pbThis,getAbilityName(ability)))
            end
          end
        else
          if !pbTooHigh?(PBStats::SPATK)
            if [:FACTORY,:CITY,:BACKALLEY].include?(@battle.FE)
              pbIncreaseStatBasic(PBStats::SPATK,2)
              @battle.pbCommonAnimation("StatUp",self)
              @battle.pbDisplay(_INTL("{1}'s {2} sharply boosted its Special Attack!", pbThis,getAbilityName(ability)))
            else
              pbIncreaseStatBasic(PBStats::SPATK,1)
              @battle.pbCommonAnimation("StatUp",self)
              @battle.pbDisplay(_INTL("{1}'s {2} boosted its Special Attack!", pbThis,getAbilityName(ability)))
            end
          end
        end
      end
    end
    # Screen Cleaner
    if self.ability == :SCREENCLEANER && onactive
      pbOwnSide.effects[:Reflect]     = 0
      pbOwnSide.effects[:LightScreen] = 0
      pbOwnSide.effects[:AuroraVeil]  = 0
      pbOwnSide.effects[:AreniteWall] = 0
      pbOpposingSide.effects[:Reflect]     = 0
      pbOpposingSide.effects[:LightScreen] = 0
      pbOpposingSide.effects[:AuroraVeil]  = 0
      pbOpposingSide.effects[:AreniteWall] = 0
      @battle.pbDisplay(_INTL("{1} has {2}!",pbThis,getAbilityName(self.ability)))
      @battle.pbDisplay(_INTL("The effects of protective barriers disappeared."))
    end
    # Dauntless Shield
    if self.ability == :DAUNTLESSSHIELD && onactive
      if !pbTooHigh?(PBStats::DEFENSE)
        pbIncreaseStatBasic(PBStats::DEFENSE,1)
        @battle.pbDisplay(_INTL("{1}'s {2} boosted its Defense!", pbThis,getAbilityName(ability)))
      end
    end
    # Intrepid Sword
    if self.ability == :INTREPIDSWORD && onactive
      if !pbTooHigh?(PBStats::ATTACK)
        pbIncreaseStatBasic(PBStats::ATTACK,1)
        @battle.pbDisplay(_INTL("{1}'s {2} boosted its Attack!", pbThis,getAbilityName(ability)))
      end
    end
    # Slow Start
    if self.ability == :SLOWSTART && onactive && !@battle.FE == :DEEPEARTH
      @battle.pbDisplay(_INTL("{1} can't get it going!",pbThis))
    end
    if (Rejuv && @battle.FE == :ELECTERRAIN)
      if self.ability == :LIGHTNINGROD && onactive
        if !pbTooHigh?(PBStats::SPATK)
          pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Lightning Rod boosted its special attack!", pbThis))
        end
      end
      if self.ability == :STEADFAST && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Steadfast boosted its speed!", pbThis))
        end
      end
      if self.hasWorkingItem(:CELLBATTERY)
        if self.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
          self.pbIncreaseStat(PBStats::ATTACK,1,statmessage:false)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!", self.pbThis,getItemName(self.item)))
          self.pbDisposeItem(false)
        end
      end
    end
    if @battle.state.effects[:ELECTERRAIN] > 0
      if self.ability == :STEADFAST && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Steadfast boosted its speed!", pbThis))
        end
      end
    end
    if Rejuv && @battle.FE == :CHESS
      if !pbTooHigh?(PBStats::DEFENSE)
        if self.ability == :STALL && onactive
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1} is stalling and playing defensively!",pbThis,getAbilityName(ability)))
        end
        if (self.ability == :STANCECHANGE) && onactive
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
        end
      end
    end
    if Rejuv && @battle.FE == :SWAMP
      if (self.ability == :RATTLED) && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Rattled raised its speed!",pbThis))
        end
      end
    end
    if Rejuv && @battle.FE == :FACTORY
      if self.ability == :LIGHTMETAL && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s light body makes it nimble!",pbThis,getAbilityName(ability)))
        end
      end
      if self.ability == :HEAVYMETAL && onactive
        statchange = false
        if !pbTooHigh?(PBStats::DEFENSE)
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          statchange = true
        end
        if !pbTooLow?(PBStats::SPEED)
          pbReduceStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatDown",self,nil)
          statchange = true
        end
        @battle.pbDisplay(_INTL("{1}'s heavy body is sturdy and unmoving!",pbThis)) if statchange
      end
    end
    # Volcanic Field Entry
    if @battle.FE == :VOLCANIC
      if self.ability == :MAGMAARMOR && onactive
        if !pbTooHigh?(PBStats::DEFENSE)
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Magma Armor boosted its defense!", pbThis))
        end
      end
    end
    # Mirror Field Entry
    if @battle.FE == :MIRROR
      if !pbTooHigh?(PBStats::EVASION)
        if (self.ability == :SNOWCLOAK || self.ability == :SANDVEIL || self.ability == :TANGLEDFEET || self.ability == :MAGICBOUNCE || self.ability == :COLORCHANGE) && onactive
          pbIncreaseStatBasic(PBStats::EVASION,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} boosted its Evasion!", pbThis,getAbilityName(ability)))
        elsif self.ability == :ILLUSION && onactive
          pbIncreaseStatBasic(PBStats::EVASION,2)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s ability sharply boosted its Evasion!", pbThis,getAbilityName(ability)))
        end
        if (self.hasWorkingItem(:BRIGHTPOWDER) || self.hasWorkingItem(:LAXINCENSE)) && onactive
          pbIncreaseStatBasic(PBStats::EVASION,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s item boosted its Evasion!", pbThis,getAbilityName(ability)))
        end 
      end
      # Keen Eye / Compound Eye
      if (self.ability == :KEENEYE || self.ability == :COMPOUNDEYES || self.hasWorkingItem(:ZOOMLENS) || self.hasWorkingItem(:WIDELENS)) && onactive
        if !pbTooHigh?(PBStats::ACCURACY)
          pbIncreaseStatBasic(PBStats::ACCURACY,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          if self.ability == :KEENEYE || self.ability == :COMPOUNDEYES
            @battle.pbDisplay(_INTL("{1}'s {2} boosted its Accuracy!", pbThis,getAbilityName(self.ability)))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} boosted its Accuracy!", pbThis,getItemName(self.item)))
          end
        end
        self.effects[:LaserFocus] = 1
        @battle.pbDisplay(_INTL("{1} is focused!",pbThis))
      end
      # Illuminate
      if self.ability == :ILLUMINATE && onactive
        for i in 0...4
          if pbIsOpposing?(i) && !@battle.battlers[i].isFainted?
            @battle.battlers[i].pbReduceIlluminate(self)
          end
        end
      end
      
    end
    # Fairy Tale Field Entry
    if @battle.FE == :FAIRYTALE
      if !pbTooHigh?(PBStats::DEFENSE)
        if [:BATTLEARMOR, :SHELLARMOR, :POWEROFALCHEMY].include?(self.ability) && onactive
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s shining armor boosted its Defense!",
           pbThis,getAbilityName(ability)))
        end
        if (self.ability == :STANCECHANGE) && onactive
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
        end
      end
      if [:MAGICGUARD, :MAGICBOUNCE, :POWEROFALCHEMY, :MIRRORARMOR, :PASTELVEIL].include?(self.ability) && onactive
        if !pbTooHigh?(PBStats::SPDEF)
          pbIncreaseStatBasic(PBStats::SPDEF,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          if self.ability == :MIRRORARMOR
            @battle.pbDisplay(_INTL("{1}'s reflective armor boosted its Special Defense!",pbThis))
          else
            @battle.pbDisplay(_INTL("{1}'s magical power boosted its Special Defense!",pbThis))
          end
        end
      end
      if (self.ability == :MAGICIAN) && onactive
        if !pbTooHigh?(PBStats::SPATK)
          pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s magical power boosted its Special Attack!",
           pbThis,getAbilityName(ability)))
        end
      end
      if (self.ability == :INTREPIDSWORD) && onactive
        statraise = false
        for stat in [PBStats::ATTACK,PBStats::SPATK]
          if !pbTooHigh?(stat)
            pbIncreaseStatBasic(stat,1)
            statraise = true
          end
        end
        if statraise
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("The fairy king's sword empowered {1}!",pbThis,))
        end
      end
      if (self.ability == :DAUNTLESSSHIELD) && onactive
        statraise = false
        for stat in [PBStats::DEFENSE,PBStats::SPDEF]
          if !pbTooHigh?(stat)
            pbIncreaseStatBasic(stat,1)
            statraise = true
          end
        end
        if statraise
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("The fairy king's shield protects {1}!",pbThis,))
        end
      end
    end
    # Dragon's Den Entry
    if @battle.FE == :DRAGONSDEN
      if self.ability == :MAGMAARMOR && onactive
        statraise = false
        for stat in [PBStats::DEFENSE,PBStats::SPDEF]
          if !pbTooHigh?(stat)
            pbIncreaseStatBasic(stat,1)
            statraise = true
          end
        end
        if statraise
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Magma Armor boosted its defenses!",pbThis))
        end
      end
      if Rejuv && (self.ability == :SHELLARMOR) && onactive
        if !pbTooHigh?(PBStats::DEFENSE)
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Shell Armor boosted its defenses!",pbThis))
        end
      end
    end
    # Flower Garden Entry
    if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,1,4) && [:FLOWERGIFT,:FLOWERVEIL,:DROUGHT,:DRIZZLE].include?(ability) && onactive
      message = _INTL("{1}'s {2}", pbThis,getAbilityName(ability))
      @battle.growField(message,self)
    end
    # Starlight Arena Entry
    if @battle.FE == :STARLIGHT
      if (self.ability == :ILLUMINATE) && onactive
        if !pbTooHigh?(PBStats::SPATK)
          pbIncreaseStatBasic(PBStats::SPATK,2)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} flared up with starlight!",
           pbThis,getAbilityName(ability)))
        end
        if self.pbPartner.ability == :MIRRORARMOR 
          self.pbPartner.effects[:FollowMe] = true
          @battle.pbAnimation(:SPOTLIGHT,self,self.pbPartner)
          @battle.pbDisplay(_INTL("{1}'s dazzling shine put a spotlight on its partner!",pbThis))
        end
      end
    end
    # Psychic Terrain Entry
    if @battle.FE == :PSYTERRAIN || @battle.state.effects[:PSYTERRAIN] > 0
      if ((self.ability == :ANTICIPATION) || (Rejuv && self.ability == :FOREWARN)) && onactive
        if !pbTooHigh?(PBStats::SPATK)
          pbIncreaseStatBasic(PBStats::SPATK,2)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Anticipation raised its Special Attack!",
           pbThis))
        end
      end
    end
    # Misty Terrain + Corrosive Mist Entry
    if @battle.FE == :MISTY || @battle.FE == :CORROSIVEMIST || @battle.state.effects[:MISTY] > 0
      if (self.ability == :WATERCOMPACTION) && onactive
        if !pbTooHigh?(PBStats::DEFENSE)
          pbIncreaseStatBasic(PBStats::DEFENSE,2)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Water Compaction sharply raised its defense!",pbThis))
        end
      end
    end
    # Rejuv Dimensional field entry
    if @battle.FE == :DIMENSIONAL || @battle.FE == :FROZENDIMENSION
      if (self.ability == :RATTLED) && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Rattled raised its speed!",pbThis))
        end
      end
      if (self.ability == :BERSERK) && onactive
        if !pbTooHigh?(PBStats::SPATK)
          pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Anger raised its Special Attack!",pbThis))
        end
      end
      if ((self.ability == :JUSTIFIED) || (self.ability == :ANGERPOINT))  && onactive
        if !pbTooHigh?(PBStats::ATTACK)
          pbIncreaseStatBasic(PBStats::ATTACK,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Anger raised its Attack!",pbThis))
        end
      end
      if self.ability == :PRESSURE && onactive
        for i in 0...4
          next if !pbIsOpposing?(i) || @battle.battlers[i].isFainted?
          @battle.battlers[i].pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: self)
          @battle.battlers[i].pbReduceStat(PBStats::SPDEF,1,abilitymessage:false, statdropper: self)
        end
      end
      if self.ability == :UNNERVE && onactive
        for i in 0...4
          next if !pbIsOpposing?(i) || @battle.battlers[i].isFainted?
          @battle.battlers[i].pbReduceStat(PBStats::SPEED,1,abilitymessage:false, statdropper: self)
        end
      end
      if @battle.FE == :FROZENDIMENSION && (self.ability == :HUNGERSWITCH && self.species == :MORPEKO && self.form==0) && onactive
        self.form = 1
        pbUpdate(true)
        @battle.scene.pbChangePokemon(self,@pokemon)
      end
    end
    if @battle.FE == :HAUNTED
      if (self.ability == :RATTLED) && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Rattled raised its speed!",pbThis))
        end
      end
      if self.ability == :SHADOWTAG && @battle.pbOwnedByPlayer?(@index) && onactive
        items=[]
        items.push(pbOpposing1) if pbOpposing1.item && !pbOpposing1.isFainted?
        items.push(pbOpposing2) if pbOpposing2.item && !pbOpposing2.isFainted?
        for i in items
         itemname=getItemName(i.item)
         @battle.pbDisplay(_INTL("{1}'s shadow frisked {2} and found its {3}!",pbThis,i.pbThis(true),itemname))
        end
      end
    end
    # Rejuv sky field entry
    if @battle.FE == :SKY
      if (self.ability == :BIGPECKS) && onactive
        if !pbTooHigh?(PBStats::DEFENSE)
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its defense in the skies!",
              pbThis,getAbilityName(ability)))
        end     
      end
      if (self.ability == :LEVITATE || self.ability == :SOLARIDOL || self.ability == :LUNARIDOL) && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} made it go faster in the open skies!",
              pbThis,getAbilityName(ability)))
        end
      end
      if self.ability == :CLOUDNINE && @battle.weather!=0
        @battle.weather = 0
        @battle.pbDisplay(_INTL("{1}'s {2} removed all weather effects!",
            pbThis,getAbilityName(ability)))
      end
    end
    # Colosseum Field Entry  
    if @battle.FE == :COLOSSEUM 
      if (self.ability == :DAUNTLESSSHIELD || self.ability == :BATTLEARMOR || self.ability == :SHELLARMOR) && onactive
        if !pbTooHigh?(PBStats::DEFENSE) 
          pbIncreaseStatBasic(PBStats::DEFENSE,1)  
          @battle.pbCommonAnimation("StatUp",self,nil)  
          @battle.pbDisplay(_INTL("{1}'s shining armor boosted its Defense!",pbThis))  
        end       
      end  
      if (self.ability == :DAUNTLESSSHIELD || self.ability == :MIRRORARMOR || self.ability == :MAGICGUARD) && onactive 
        if !pbTooHigh?(PBStats::SPDEF) 
          pbIncreaseStatBasic(PBStats::SPDEF,1)  
          @battle.pbCommonAnimation("StatUp",self,nil)  
          @battle.pbDisplay(_INTL("{1}'s magical power boosted its Special Defense!",pbThis))  
        end       
      end  
      if (self.ability == :INTREPIDSWORD || self.ability == :NOGUARD || self.ability == :JUSTIFIED) && onactive   
        if !pbTooHigh?(PBStats::ATTACK)  
          pbIncreaseStatBasic(PBStats::ATTACK,1)  
          @battle.pbCommonAnimation("StatUp",self,nil)  
          @battle.pbDisplay(_INTL("{1}'s ferocious heart boosted its Attack!",pbThis))  
        end       
      end  
      if (self.ability == :INTREPIDSWORD || self.ability == :NOGUARD || self.ability == :JUSTIFIED) && onactive
        if !pbTooHigh?(PBStats::SPATK) 
          pbIncreaseStatBasic(PBStats::SPATK,1)  
          @battle.pbCommonAnimation("StatUp",self,nil)  
          @battle.pbDisplay(_INTL("{1}'s ferocious heart boosted its Special Attack!",pbThis))  
        end       
      end  
    end 
    if @battle.FE == :INFERNAL
      if (self.ability == :MAGMAARMOR || self.ability == :FLAMEBODY || self.ability == :DESOLATELAND) && onactive
        statraise = false
        for stat in [PBStats::DEFENSE,PBStats::SPDEF]
          if !pbTooHigh?(stat)
            pbIncreaseStatBasic(stat,1)
            statraise = true
          end
        end
        if statraise
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} increased its defenses!", pbThis,getAbilityName(ability)))
        end
      end
    end
    if @battle.FE == :DEEPEARTH
      if self.ability == :LIGHTMETAL && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} allows it to move faster!",pbThis,getAbilityName(ability)))
        end
      end
      if self.ability == :HEAVYMETAL && onactive
        statchange = false
        if !pbTooHigh?(PBStats::DEFENSE)
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          statchange = true
        end
        if !pbTooLow?(PBStats::SPEED)
          pbReduceStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatDown",self,nil)
          statchange = true
        end
        @battle.pbDisplay(_INTL("{1}'s weight makes it harder to be moved!",pbThis)) if statchange
      end
      if self.ability == :SLOWSTART && onactive
        statraise =false
        for stat in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPDEF]
          if !pbTooHigh?(stat)
            pbIncreaseStatBasic(stat,1)
            statraise = true
          end
        end
        @battle.pbCommonAnimation("StatUp",self,nil) if statraise
        statdrop = false
        for stat in [PBStats::SPEED,PBStats::EVASION]
          if !pbTooLow?(stat)
            pbReduceStatBasic(stat,6)
            statdrop = true
          end
        end
        @battle.pbCommonAnimation("StatDown",self,nil) if statdrop
        @battle.pbDisplay(_INTL("The ancient giant is slow but powerful!")) if statraise || statdrop
      end
      if (self.ability == :MAGNETPULL) && onactive
        @battle.pbDisplay(_INTL("The strong magnetism causes {1} to float!",self.pbThis)) 
      end
      if (self.ability == :UNAWARE || self.ability == :OBLIVIOUS) && onactive
        @battle.pbDisplay(_INTL("{1} fails to notice the intense gravity...",self.pbThis)) 
      end
      if (self.ability == :CONTRARY) && onactive
        @battle.pbDisplay(_INTL("Gravity's just a theory, after all...")) 
      end
    end
    if @battle.ProgressiveFieldCheck(PBFields::CONCERT)
      if [:SOUNDPROOF,:PUNKROCK,:HEAVYMETAL,:SOLIDROCK,:ROCKHEAD].include?(self.ability) && onactive
        if !pbTooHigh?(PBStats::DEFENSE)
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1} is accustomed to the music due to {2}!", pbThis,getAbilityName(ability)))
        end
      end
      if [:RUNAWAY,:EMERGENCYEXIT].include?(self.ability) && @battle.ProgressiveFieldCheck(PBFields::CONCERT,2,4) && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1} wants to get away from the noise!", pbThis))
        end
      end
      if self.ability == :RATTLED && @battle.ProgressiveFieldCheck(PBFields::CONCERT,3,4) && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,2)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1} wants to get away from the noise!", pbThis))
        end
      end
      if [:PLUS,:GALVANIZE,:HEAVYMETAL,:SOLIDROCK,:PUNKROCK].include?(self.ability) && onactive
        message = _INTL("{1}'s {2}", pbThis,getAbilityName(ability))
        @battle.growField(message,self)
      end
      if [:MINUS,:KLUTZ].include?(self.ability) && onactive
        @battle.reduceField
      end
    end
    if @battle.FE == :BACKALLEY
      if (self.ability == :PICKPOCKET || self.ability == :MERCILESS) && onactive
        if !pbTooHigh?(PBStats::ATTACK)
          pbIncreaseStatBasic(PBStats::ATTACK,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("Merciless cutpurses like {1} get ready to strike!",pbThis))
        end
      end
      if self.ability == :MAGICIAN && onactive
        if !pbTooHigh?(PBStats::SPATK)
          pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("The Street Magician's tricks raise {1}'s Special Attack!",pbThis))
        end
      end
      if (self.ability == :ANTICIPATION || self.ability == :FOREWARN) && onactive
        statchange = false
        if !pbTooHigh?(PBStats::DEFENSE)
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          statchange = true
        end
        if !pbTooLow?(PBStats::SPDEF)
          pbIncreaseStatBasic(PBStats::SPDEF,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          statchange = true
        end
        @battle.pbDisplay(_INTL("{1} is getting ready to defend itself because of its {2}!",pbThis,getAbilityName(ability))) if statchange
      end
      if self.ability == :RATTLED && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("The gloomy backalley makes {1} ready to bolt!", pbThis))
        end
      end
    end
    if @battle.FE == :CITY
      if self.ability == :EARLYBIRD && onactive
        if !pbTooHigh?(PBStats::ATTACK)
          pbIncreaseStatBasic(PBStats::ATTACK,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("The early bird catches the worm!",pbThis))
        end
      end
      if self.ability == :BIGPECKS && onactive
        if !pbTooHigh?(PBStats::DEFENSE)
          pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} raise its Defense!",pbThis,getAbilityName(ability)))
        end
      end
      if (self.ability == :RATTLED || self.ability == :PICKUP) && onactive
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          if self.ability == :RATTLED
            @battle.pbDisplay(_INTL("The busy city is rattling {1}!", pbThis))
          else
            @battle.pbDisplay(_INTL("{1} is picking up Speed!", pbThis))
          end
        end
      end
    end
    # Clouds from Deso Entry
    if @battle.FE == :CLOUDS
      if self.ability == :CLOUDNINE && onactive
        if !self.pbTooHigh?(PBStats::DEFENSE)
          self.pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Cloud Nine raised its Defense!", pbThis))
        end
        if !self.pbTooHigh?(PBStats::SPDEF)
          self.pbIncreaseStatBasic(PBStats::SPDEF,1)
          @battle.pbDisplay(_INTL("{1}'s Cloud Nine raised its Special Defense!", pbThis))
        end
      end
    
      if self.ability == :FORECAST && onactive
        if !self.pbTooHigh?(PBStats::DEFENSE)
          self.pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Forecast raised its Defense!", pbThis))
        end
        if !self.pbTooHigh?(PBStats::SPDEF)
          self.pbIncreaseStatBasic(PBStats::SPDEF,1)
          @battle.pbDisplay(_INTL("{1}'s Forecast raised its Special Defense!", pbThis))
        end
        if !self.pbTooHigh?(PBStats::SPEED)
          self.pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbDisplay(_INTL("{1}'s Forecast raised its Speed!", pbThis))
        end
      end
      if self.ability == :OVERCOAT && onactive
        if !self.pbTooHigh?(PBStats::DEFENSE)
          self.pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Overcoat raised its Defense!", pbThis))
        end
      end
    end
    #Darkness field, Deso
    if @battle.FE == :DARKNESS2
      if self.ability == :PICKPOCKET && onactive
        if !self.pbTooHigh?(PBStats::SPEED)
          self.pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Pickpocket raised its Speed!", pbThis))
        end
      end
    end 
    if @battle.FE == :DARKNESS3
      if self.ability == :PICKPOCKET && onactive
        if !self.pbTooHigh?(PBStats::SPEED)
          self.pbIncreaseStatBasic(PBStats::SPEED,2)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Pickpocket sharply raised its Speed!", pbThis))
        end
      end
    end 
    # Dancefloor field from Deso
    if @battle.FE == :DANCEFLOOR
      if self.ability == :MAGICGUARD  && onactive
        self.pbIncreaseStatBasic(PBStats::SPDEF,2)
        @battle.pbCommonAnimation("StatUp",self,nil)
        @battle.pbDisplay(_INTL("{1}'s Magic Guard sharply raised its Special Defense!", pbThis))
      end
      if self.ability == :MAGICBOUNCE  && onactive
        self.pbIncreaseStatBasic(PBStats::SPDEF,2)
        @battle.pbCommonAnimation("StatUp",self,nil)
        @battle.pbDisplay(_INTL("{1}'s Magic Bounce sharply raised its Special Defense!", pbThis))
      end
      if self.ability == :MAGICIAN  && onactive
        self.pbIncreaseStatBasic(PBStats::SPDEF,1)
        @battle.pbCommonAnimation("StatUp",self,nil)
        @battle.pbDisplay(_INTL("{1}'s Magician raised its Special Defense!", pbThis))
      end
      if self.ability == :DANCER  && onactive
        self.pbIncreaseStatBasic(PBStats::SPATK,1)
        @battle.pbCommonAnimation("StatUp",self,nil)
        @battle.pbDisplay(_INTL("{1}'s Dancer raised its Special Attack!", pbThis))
      end
      if self.ability == :INSOMNIA  && onactive
        self.pbIncreaseStatBasic(PBStats::SPDEF,1)
        self.pbIncreaseStatBasic(PBStats::DEFENSE,2)
        @battle.pbCommonAnimation("StatUp",self,nil)
        @battle.pbDisplay(_INTL("{1}'s Insomnia raised its Defense and Special Defense!", pbThis))
      end
      if self.ability == :ILLUMINATE  && onactive
        self.pbIncreaseStatBasic(PBStats::SPDEF,1)
        self.pbIncreaseStatBasic(PBStats::SPATK,1)
        @battle.pbCommonAnimation("StatUp",self,nil)
        @battle.pbDisplay(_INTL("{1}'s Illuminate raised its Special Attack and Special Defense!", pbThis))
      end
    end
    #Crowd Field, Deso
    if @battle.FE == :CROWD
      scoreToCompare = $game_variables[:BattleDataArray].last().getScoreAndSide(self)
        highestOpposingScore=[0,nil,""]
        for b in 0...@battle.battlers.length
          battlerArray = $game_variables[:BattleDataArray].last().getScoreAndSide(@battle.battlers[b])
          if (battlerArray[1]!=scoreToCompare[1] && (battlerArray[0].to_i > highestOpposingScore[0].to_i))
            highestOpposingScore = battlerArray
          end
        end
        oppScore = highestOpposingScore[0].to_i
      if onactive
        if self.ability == :IRONFIST
          self.pbIncreaseStatBasic(PBStats::DEFENSE,1)
          @battle.pbCommonAnimation("StatUp",self,nil)
          @battle.pbDisplay(_INTL("{1}'s Iron Fist raised its Defense!", pbThis))
        end
      end

      if !onactive
        if oppScore<3 && self.tempBoosts.length>0
          self.tempBoosts.push("@battle.pbCommonAnimation(\"StatDown\",self,nil)")
          for i in 0...self.tempBoosts.length
            eval( self.tempBoosts[i])
          end
          @battle.pbDisplay(_INTL("The cheers of the crowd recede as {1} leaves the field!", $overscored))
          self.tempBoosts=[]
        end
      end
    end
    # Frisk
    if self.ability == :FRISK && onactive
      items=[]
      items.push(pbOpposing1) if pbOpposing1.item && !pbOpposing1.isFainted?
      items.push(pbOpposing2) if pbOpposing2.item && !pbOpposing2.isFainted?
      if @battle.FE == :CITY
        @battle.pbDisplay(_INTL("Just a routine inspection."))
        for i in @battle.battlers
          next if i.isFainted? || !pbIsOpposing?(i.index)
          i.pbReduceStat(PBStats::SPDEF,1)
        end
      end
      for i in items
        itemname=getItemName(i.item)
        @battle.pbDisplay(_INTL("{1} frisked {2} and found its {3}!",pbThis,i.pbThis(true),itemname)) if @battle.pbOwnedByPlayer?(@index)
        if @battle.FE == :BACKALLEY
          if (i.effects[:Substitute]==0) && (i.ability != :STICKYHOLD || i.moldbroken) && self.item.nil?
            if !@battle.pbIsUnlosableItem(i,i.item) && !@battle.pbIsUnlosableItem(self,i.item)
              self.item=i.item
              i.item=nil
              if i.pokemon.corrosiveGas
                i.pokemon.corrosiveGas=false
                self.pokemon.corrosiveGas=true
              end
              i.effects[:ChoiceBand]=nil
              # In a wild battle
              if !@battle.opponent && self.pokemon.itemInitial.nil? && i.pokemon.itemInitial==self.item && @battle.pbOwnedByPlayer?(@index)
                self.pokemon.itemInitial=self.item
                self.pokemon.itemReallyInitialHonestlyIMeanItThisTime=self.item
                i.pokemon.itemInitial=nil
              end
              @battle.pbCommonAnimation("Thief",self,i)
              @battle.pbDisplay(_INTL("Don't mind if I do!"))
            end
          end
        end
      end
    end
    # Anticipation
    if self.ability == :ANTICIPATION && onactive
      found=false
      for foe in [pbOpposing1,pbOpposing2]
        next if foe.isFainted?
        for j in foe.moves
          movedata=$cache.moves[j.move]
          eff=PBTypes.twoTypeEff(movedata.type,type1,type2)
          if (movedata.basedamage>0 && eff>4 &&
             movedata.function!=0x71 && # Counter
             movedata.function!=0x72 && # Mirror Coat
             movedata.function!=0x73) || # Metal Burst
             (movedata.function==0x70 && eff>0) # OHKO
            found=true
            break
          end
        end
        break if found
      end
      @battle.pbDisplay(_INTL("{1} shuddered with anticipation!",pbThis)) if found
    end
    if self.ability == :UNNERVE && onactive
       if @battle.pbOwnedByPlayer?(@index)
       @battle.pbDisplay(_INTL("The opposing team is too nervous to eat berries!",pbThis))
       elsif !@battle.pbOwnedByPlayer?(@index)
       @battle.pbDisplay(_INTL("Your team is too nervous to eat berries!",pbThis))
       end
     end
    # Forewarn
    if self.ability == :FOREWARN && onactive
      highpower=0
      moves=[]
      chosenopponent = []
      for foe in [pbOpposing1,pbOpposing2]
        next if foe.isFainted?
        for j in foe.moves
          movedata=j
          power=movedata.basedamage
          power=160 if movedata.function==0x70    # OHKO
          power=150 if movedata.function==0x8B    # Eruption
          power=120 if movedata.function==0x71 || # Counter
                       movedata.function==0x72 || # Mirror Coat
                       movedata.function==0x73    # Metal Burst
          power=80 if movedata.function==0x6A ||  # SonicBoom
                      movedata.function==0x6B ||  # Dragon Rage
                      movedata.function==0x6D ||  # Night Shade
                      movedata.function==0x6E ||  # Endeavor
                      movedata.function==0x6F ||  # Psywave
                      movedata.function==0x89 ||  # Return
                      movedata.function==0x8A ||  # Frustration
                      movedata.function==0x8C ||  # Crush Grip
                      movedata.function==0x8D ||  # Gyro Ball
                      movedata.function==0x90 ||  # Hidden Power
                      movedata.function==0x96 ||  # Natural Gift
                      movedata.function==0x97 ||  # Trump Card
                      movedata.function==0x98 ||  # Flail
                      movedata.function==0x9A     # Grass Knot
          if power>highpower
            moves=[j.move]; highpower=power; chosenopponent=[foe]
          elsif power==highpower
            moves.push(j.move) ; chosenopponent.push(foe)
          end
        end
      end
      if moves.length>0
        chosenmovenumber = @battle.pbRandom(moves.length)
        move=moves[chosenmovenumber]
        movename=getMoveName(move)
        @battle.pbDisplay(_INTL("{1}'s Forewarn alerted it to {2}!",pbThis,movename))
        # AI CHANGES
        if !@battle.isOnline?
          warnedMove = PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(move),self)
          @battle.ai.addMoveToMemory(chosenopponent[chosenmovenumber], warnedMove)
        end
      end
    end
    # Quark Drive / Protosynthesis
    if self.ability == :QUARKDRIVE && onactive
      aBoost = self.attack * 1.0+(0.5*@stages[PBStats::ATTACK])
      dBoost = self.defense * 1.0+(0.5*@stages[PBStats::DEFENSE])
      saBoost = self.spatk * 1.0+(0.5*@stages[PBStats::SPATK])
      sdBoost = self.spdef * 1.0+(0.5*@stages[PBStats::SPDEF])
      spdBoost = self.speed * 1.0+(0.5*@stages[PBStats::SPEED])
      stats = [aBoost,dBoost,saBoost,sdBoost,spdBoost]
      boostStat = stats.index(stats.max)+1
      if (@battle.FE == :ELECTERRAIN || @battle.state.effects[:ELECTERRAIN] > 0) && self.effects[:Quarkdrive][0] == 0
        self.effects[:Quarkdrive] = [boostStat,false]
        @battle.pbDisplay(_INTL("{1}'s Quark Drive heightened its {2}!", pbThis,pbGetStatName(boostStat)))
      end
      if self.item == :BOOSTERENERGY && self.effects[:Quarkdrive][0] == 0
        self.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1}'s Booster Energy was used up...", pbThis))
        self.effects[:Quarkdrive] = [boostStat,true]
        @battle.pbDisplay(_INTL("{1}'s Quark Drive heightened its {2}!", pbThis,pbGetStatName(boostStat)))
      end
    end
    # Imposter
    if self.ability == :IMPOSTER && !@effects[:Transform] && onactive && pbOppositeOpposing.hp>0
      choice=pbOppositeOpposing
      if choice.effects[:Substitute]>0 ||
         choice.effects[:Transform] ||
         choice.effects[:SkyDrop] ||
         PBStuff::TWOTURNMOVE.include?(choice.effects[:TwoTurnAttack]) ||
         choice.effects[:Illusion]
        # Can't transform into chosen Pokémon, so forget it
      else
        @battle.pbAnimation(:TRANSFORM,self,choice)
        @battle.scene.pbChangePokemon(self,choice.pokemon)
        @effects[:Transform]=true
        oldname = pbThis
        @species=choice.species
        @type1=choice.type1
        @type2=choice.type2
        @ability=choice.ability
        @attack=choice.attack
        @defense=choice.defense
        @speed=choice.speed
        @spatk=choice.spatk
        @spdef=choice.spdef
        @form=choice.form
        @crested=choice.crested
        for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
                  PBStats::SPATK,PBStats::SPDEF,PBStats::EVASION,PBStats::ACCURACY]
          @stages[i]=choice.stages[i]
        end
        for i in 0...4
          next if !choice.moves[i]
          @moves[i]=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(choice.moves[i].move),self) 
          if !(@zmoves.nil? || @item == :INTERCEPTZ)
            @battle.updateZMoveIndexBattler(i,self)
          end
          @moves[i].pp=5
          @moves[i].totalpp=5
        end
        @moves.each {|copiedmove| @battle.ai.addMoveToMemory(self,copiedmove) } if !@battle.isOnline?
        choice.moves.each {|moveloop| @battle.ai.addMoveToMemory(choice,moveloop) }  if !@battle.isOnline?
        @effects[:Disable]=0
        @effects[:DisableMove]=0
        @battle.pbDisplay(_INTL("{1} transformed into {2}!",oldname,choice.pbThis(true)))
        self.pbAbilitiesOnSwitchIn(true)
      end
    end
  end

  def pbEffectsOnDealingDamage(move,user,target,damage,innards)
    movetype=move.pbType(user)
    return if target.nil?
    if damage>0 && !move.zmove && move.contactMove? && user.ability != (:LONGREACH) && !(user.hasWorkingItem(:PROTECTIVEPADS) || target.hasWorkingItem(:PROTECTIVEPADS))
      if !target.damagestate.substitute
        if target.hasWorkingItem(:STICKYBARB,true) && user.item.nil? && !user.isFainted?
          user.item=target.item
          target.item=nil
          if !@battle.opponent && !@battle.pbIsOpposing?(user.index)
            if user.pokemon.itemInitial.nil? && target.pokemon.itemInitial==user.item
              user.pokemon.itemInitial=user.item
              target.pokemon.itemInitial=nil
            end
          end
          @battle.pbDisplay(_INTL("{1}'s {2} was transferred to {3}!",target.pbThis,getItemName(user.item),user.pbThis(true)))
        end
        if target.hasWorkingItem(:ROCKYHELMET,true) && !user.isFainted? && user.ability != (:MAGICGUARD) && !(user.ability == (:WONDERGUARD) && @battle.FE == :COLOSSEUM)
          @battle.scene.pbDamageAnimation(user,0)
          user.pbReduceHP((user.totalhp/6.0).floor)
          @battle.pbDisplay(_INTL("{1} was hurt by the {2}!",user.pbThis, getItemName(target.item)))
         end
        if target.effects[:BeakBlast] && user.ability != (:MAGICGUARD)&& !(user.ability == (:WONDERGUARD) && @battle.FE == :COLOSSEUM) && user.pbCanBurn?(false)
          user.pbBurn(target)
          @battle.pbDisplay(_INTL("{1} was burned by the heat!",user.pbThis))
        end

        if target.ability == :AFTERMATH && !user.isFainted? && target.hp <= 0 && !@battle.pbCheckGlobalAbility(:DAMP) && user.ability != (:MAGICGUARD) && !(user.ability == (:WONDERGUARD) && @battle.FE == :COLOSSEUM)
          PBDebug.log("[#{user.pbThis} hurt by Aftermath]")
          @battle.scene.pbDamageAnimation(user,0)
          if @battle.FE == :CORROSIVEMIST
            user.pbReduceHP((user.totalhp/2.0).floor)
            @battle.pbDisplay(_INTL("{1} was caught in the toxic aftermath!",user.pbThis))
          else
            user.pbReduceHP((user.totalhp/4.0).floor)
            @battle.pbDisplay(_INTL("{1} was caught in the aftermath!",user.pbThis))
          end
        end
        # UPDATE 11/16/2013
        eschance = 3
        eschance = 6 if (@battle.FE == :FOREST || @battle.FE == :WASTELAND || @battle.FE == :BEWITCHED)
        eschance.to_i
        #Effect Spore
        if !user.hasType?(:GRASS) && user.ability != (:OVERCOAT) && target.ability == :EFFECTSPORE && @battle.pbRandom(10) < eschance
          rnd=@battle.pbRandom(3)
          if rnd==0 && user.pbCanPoison?(false)
            user.pbPoison(target)
            @battle.pbDisplay(_INTL("{1}'s {2} poisoned {3}!",target.pbThis, getAbilityName(target.ability),user.pbThis(true)))
          elsif rnd==1 && user.pbCanSleep?(false)
            user.pbSleep
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} sleep!",target.pbThis, getAbilityName(target.ability),user.pbThis(true)))
          elsif rnd==2 && user.pbCanParalyze?(false)
            user.pbParalyze(target)
            @battle.pbDisplay(_INTL("{1}'s {2} paralyzed {3}! It may be unable to move!", target.pbThis,getAbilityName(target.ability),user.pbThis(true)))
          end
        end
        if target.ability == :FLAMEBODY && @battle.pbRandom(10)<3 && user.pbCanBurn?(false) && @battle.FE != :FROZENDIMENSION
          user.pbBurn(target)
          @battle.pbDisplay(_INTL("{1}'s {2} burned {3}!",target.pbThis,
            getAbilityName(target.ability),user.pbThis(true)))
        end
        if target.ability == :IRONBARBS && !user.isFainted? && user.ability != (:MAGICGUARD) && !(user.ability == (:WONDERGUARD) && @battle.FE == :COLOSSEUM)
          @battle.scene.pbDamageAnimation(user,0)
          user.pbReduceHP((user.totalhp/8.0).floor)
          @battle.pbDisplay(_INTL("{1}'s {2} hurt {3}!",target.pbThis, getAbilityName(target.ability),user.pbThis(true)))
        end
        if target.ability == :MUMMY && !user.isFainted?
          if !(user.ability == :MUMMY) && !PBStuff::FIXEDABILITIES.include?(user.ability)
            neutralgas = true if user.ability = :NEUTRALIZINGGAS
            user.ability=:MUMMY || 0
            @battle.pbDisplay(_INTL("{1} was mummified by {2}!", user.pbThis,target.pbThis(true)))
            @battle.neutralizingGasDisable(user.index) if neutralgas
          end
        end
        if target.ability == :WANDERINGSPIRIT && !user.isFainted? #&& !@user.isBoss
          if ![:WANDERINGSPIRIT,:NEUTRALIZINGGAS].include?(user.ability) && !PBStuff::FIXEDABILITIES.include?(user.ability)
            tmp=user.ability
            user.ability=target.ability
            target.ability=tmp
            @battle.pbDisplay(_INTL("{1} swapped its {2} Ability with its target!", target.pbThis,getAbilityName(target.ability)))
            user.pbAbilitiesOnSwitchIn(true)
            target.pbAbilitiesOnSwitchIn(true)
          end
        end
        if target.ability == :GOOEY
          if user.ability == (:CONTRARY)
            if @battle.FE == :SWAMP || @battle.FE == :MURKWATERSURFACE
              user.pbReduceStat(PBStats::SPEED,2,statmessage:false)
              @battle.pbDisplay(_INTL("{1}'s {2} sharply boosted {3}'s Speed!",target.pbThis,getAbilityName(target.ability),user.pbThis(true)))
            else
              user.pbReduceStat(PBStats::SPEED,1,statmessage:false)
              @battle.pbDisplay(_INTL("{1}'s {2} boosted {3}'s Speed!",target.pbThis,getAbilityName(target.ability),user.pbThis(true)))
            end
          elsif user.ability == (:WHITESMOKE) || user.ability == (:CLEARBODY) || user.ability == (:FULLMETALBODY)
            @battle.pbDisplay(_INTL("{1}'s {2} prevents stat loss!",user.pbThis,getAbilityName(user.ability)))
          elsif @battle.FE == :SWAMP || @battle.FE == :MURKWATERSURFACE
            user.pbReduceStat(PBStats::SPEED,2,statmessage:false)
            @battle.pbDisplay(_INTL("{1}'s {2} harshly lowered {3}'s Speed!",target.pbThis,getAbilityName(target.ability),user.pbThis(true))) if user.ability != :MIRRORARMOR
          else
            user.pbReduceStat(PBStats::SPEED,1,statmessage:false)
            @battle.pbDisplay(_INTL("{1}'s {2} lowered {3}'s Speed!",target.pbThis,getAbilityName(target.ability),user.pbThis(true))) if user.ability != :MIRRORARMOR
          end
          if @battle.FE == :WASTELAND && user.pbCanPoison?(false)
            user.pbPoison(target)
            @battle.pbDisplay(_INTL("{1}'s {2} poisoned {3}!",target.pbThis, getAbilityName(target.ability),user.pbThis(true)))
          end
        end
        if target.ability == :TANGLINGHAIR
          if user.ability == (:CONTRARY)
            user.pbReduceStat(PBStats::SPEED,1,statmessage:false)
            @battle.pbDisplay(_INTL("{1}'s {2} boosted {3}'s Speed!",target.pbThis,getAbilityName(target.ability),user.pbThis(true)))
          elsif user.ability == (:WHITESMOKE) || user.ability == (:CLEARBODY) || user.ability == (:FULLMETALBODY)
            @battle.pbDisplay(_INTL("{1}'s {2} prevents stat loss!",user.pbThis,getAbilityName(user.ability)))
          else
            user.pbReduceStat(PBStats::SPEED,1,statmessage:false)
            @battle.pbDisplay(_INTL("{1}'s {2} lowered {3}'s Speed!",target.pbThis,getAbilityName(target.ability),user.pbThis(true))) if user.ability != :MIRRORARMOR
          end
        end
        eschance = 3
        eschance = 6 if @battle.FE == :WASTELAND || @battle.FE == :CORRUPTED
        eschance.to_i
        if target.ability == :POISONPOINT && @battle.pbRandom(10) < eschance && user.pbCanPoison?(false)
          user.pbPoison(target)
          @battle.pbDisplay(_INTL("{1}'s {2} poisoned {3}!",target.pbThis, getAbilityName(target.ability),user.pbThis(true)))
        end
        if target.ability == :ROUGHSKIN && !user.isFainted? && user.ability != (:MAGICGUARD) && !(user.ability == (:WONDERGUARD) && @battle.FE == :COLOSSEUM)
          @battle.scene.pbDamageAnimation(user,0)
          user.pbReduceHP((user.totalhp/8.0).floor)
          @battle.pbDisplay(_INTL("{1}'s {2} hurt {3}!",target.pbThis, getAbilityName(target.ability),user.pbThis(true)))
        end
        eschance = 3
        eschance = 6 if @battle.FE == :SHORTCIRCUIT || (Rejuv && @battle.FE == :ELECTERRAIN)
        eschance.to_i
        if target.ability == :STATIC && @battle.pbRandom(10) < eschance && user.pbCanParalyze?(false)
          user.pbParalyze(target)
          @battle.pbDisplay(_INTL("{1}'s {2} paralyzed {3}! It may be unable to move!", target.pbThis,getAbilityName(target.ability),user.pbThis(true)))
        end
        eschance = 3
        eschance = 6 if @battle.FE == :CORRUPTED
        eschance.to_i
        if user.ability == :POISONTOUCH && @battle.pbRandom(10)<eschance && target.pbCanPoison?(false)
          target.pbPoison(user)
          @battle.pbDisplay(_INTL("{1}'s {2} poisoned {3}!",user.pbThis, getAbilityName(user.ability),target.pbThis(true)))
        end
        if target.ability == :PERISHBODY && user.effects[:PerishSong]==0 && target.effects[:PerishSong]==0 && @battle.FE != :HOLY
          if @battle.FE == :INFERNAL
            @battle.pbDisplay(_INTL("Both Pokémon will faint in one turn!"))
            user.effects[:PerishSong]=2
            user.effects[:PerishSongUser]=target.index
            target.effects[:PerishSong]=2
            target.effects[:PerishSongUser]=target.index
          else
            @battle.pbDisplay(_INTL("Both Pokémon will faint in three turns!"))
            user.effects[:PerishSong]=4
            user.effects[:PerishSongUser]=target.index
            target.effects[:PerishSong]=4
            target.effects[:PerishSongUser]=target.index
          end
          if @battle.FE == :DIMENSIONAL || @battle.FE == :HAUNTED || @battle.FE == :INFERNAL
            target.effects[:MeanLook]=user.index
            @battle.pbDisplay(_INTL("{1} can't escape now!",target.pbThis))
          end
        end

        if target.ability == (:CUTECHARM) && @battle.pbRandom(10)<3
          if user.ability != (:OBLIVIOUS) &&
           ((user.gender==1 && target.gender==0) || (user.gender==0 && target.gender==1)) && user.effects[:Attract]<0 && !user.isFainted?
            user.effects[:Attract]=target.index
            @battle.pbDisplay(_INTL("{1}'s {2} infatuated {3}!",target.pbThis, getAbilityName(target.ability),user.pbThis(true)))
            if user.hasWorkingItem(:DESTINYKNOT) && target.ability != (:OBLIVIOUS) && target.effects[:Attract]<0
              target.effects[:Attract]=user.index
              @battle.pbDisplay(_INTL("{1}'s {2} infatuated {3}!",user.pbThis, getItemName(user.item),target.pbThis(true)))
            end
          end
        end
        if target.ability == (:PICKPOCKET)
          if target.item.nil? && user.item && user.effects[:Substitute]==0 && target.effects[:Substitute]==0 && user.ability != (:STICKYHOLD) && 
            !@battle.pbIsUnlosableItem(user,user.item) && !@battle.pbIsUnlosableItem(target,user.item) && (@battle.opponent || !@battle.pbIsOpposing?(target.index))
            target.item=user.item
            user.item=nil
            if user.pokemon.corrosiveGas
              user.pokemon.corrosiveGas=false
              target.pokemon.corrosiveGas=true
            end
            if @battle.pbIsWild? && target.pokemon.itemInitial.nil? && user.pokemon.itemInitial==target.item && !user.isbossmon && !target.isbossmon && # In a wild battle
              target.pokemon.itemInitial=target.item
              target.pokemon.itemReallyInitialHonestlyIMeanItThisTime=target.item
              user.pokemon.itemInitial=nil
            end
            @battle.pbDisplay(_INTL("{1} pickpocketed {2}'s {3}!",target.pbThis,
             user.pbThis(true),getItemName(target.item)))
          end
        end
      end
    end
    if damage>0
      if target.effects[:ShellTrap] && move.pbIsPhysical?(movetype)
        target.effects[:ShellTrap]=false
      end
      if target.ability == :INNARDSOUT && !user.isFainted? &&
        target.hp <= 0 && user.ability != (:MAGICGUARD) && !(user.ability == (:WONDERGUARD) && @battle.FE == :COLOSSEUM)
        PBDebug.log("[#{user.pbThis} hurt by Innards Out]")
        @battle.scene.pbDamageAnimation(user,0)
        user.pbReduceHP(innards)
        @battle.pbDisplay(_INTL("{2}'s innards hurt {1}!",user.pbThis,target.pbThis))
      end
      if @battle.FE == :GLITCH # Glitch Field Hyper Beam Reset
        if user.hp>0 && target.hp<=0
          user.effects[:HyperBeam]=0
        end
      end
      if user.ability == (:BEASTBOOST) && user.hp>0 && target.hp<=0
        aBoost = user.attack
        dBoost = user.defense
        saBoost = user.spatk
        sdBoost = user.spdef
        spdBoost = user.speed
        boostStat = [aBoost,dBoost,saBoost,sdBoost,spdBoost].max
        if @battle.FE == :DIMENSIONAL
          statmod = 2
        else
          statmod = 1
        end
        case boostStat
          when aBoost
            if !user.pbTooHigh?(PBStats::ATTACK)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::ATTACK,statmod)
              @battle.pbDisplay(_INTL("{1}'s Beast Boost raised its Attack!",user.pbThis))
            end
          when dBoost
            if !user.pbTooHigh?(PBStats::DEFENSE)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::DEFENSE,statmod)
              @battle.pbDisplay(_INTL("{1}'s Beast Boost raised its Defense!",user.pbThis))
            end
          when saBoost
            if !user.pbTooHigh?(PBStats::SPATK)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::SPATK,statmod)
              @battle.pbDisplay(_INTL("{1}'s Beast Boost raised its Special Attack!",user.pbThis))
            end
          when sdBoost
            if !user.pbTooHigh?(PBStats::SPDEF)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::SPDEF,statmod)
              @battle.pbDisplay(_INTL("{1}'s Beast Boost raised its Special Defense!",user.pbThis))
            end
          when spdBoost
            if !user.pbTooHigh?(PBStats::SPEED)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::SPEED,statmod)
              @battle.pbDisplay(_INTL("{1}'s Beast Boost raised its Speed!",user.pbThis))
            end
        end
      end
      if @battle.FE == :COLOSSEUM && user.hp>0 && target.hp<=0
        aBoost = target.attack
        dBoost = target.defense
        saBoost = target.spatk
        sdBoost = target.spdef
        spdBoost = target.speed
        boostStat = [aBoost,dBoost,saBoost,sdBoost,spdBoost].max
        statmod = 1
        case boostStat
          when aBoost
            if !user.pbTooHigh?(PBStats::ATTACK)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::ATTACK,statmod)
              @battle.pbDisplay(_INTL("The cheering audience raised {1}'s Attack!",user.pbThis))
            end
          when dBoost
            if !user.pbTooHigh?(PBStats::DEFENSE)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::DEFENSE,statmod)
              @battle.pbDisplay(_INTL("The cheering audience raised {1}'s Defense!",user.pbThis))
            end
          when saBoost
            if !user.pbTooHigh?(PBStats::SPATK)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::SPATK,statmod)
              @battle.pbDisplay(_INTL("The cheering audience raised {1}'s Special Attack!",user.pbThis))
            end
          when sdBoost
            if !user.pbTooHigh?(PBStats::SPDEF)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::SPDEF,statmod)
              @battle.pbDisplay(_INTL("The cheering audience raised {1}'s Special Defense!",user.pbThis))
            end
          when spdBoost
            if !user.pbTooHigh?(PBStats::SPEED)
              @battle.pbCommonAnimation("StatUp",self,nil)
              user.pbIncreaseStatBasic(PBStats::SPEED,statmod)
              @battle.pbDisplay(_INTL("The cheering audience raised {1}'s Speed!",user.pbThis))
            end
        end
      end
      if !target.damagestate.substitute
        if (target.ability == :CURSEDBODY && @battle.FE != :HOLY && (@battle.pbRandom(10)<3 || (target.isFainted? && @battle.FE == :HAUNTED))) || target.crested == :BEHEEYEM
          if user.effects[:Disable]<=0 && move.pp>0 && !user.isFainted?
            user.effects[:Disable]=4
            user.effects[:DisableMove]=move.move
            @battle.pbDisplay(_INTL("{1}'s {2} disabled {3}!",target.pbThis,
               getAbilityName(target.ability),user.pbThis(true)))
          end
        end
        if target.ability == :GULPMISSILE && target.species == :CRAMORANT && !user.isFainted? && target.form!=0
          @battle.scene.pbDamageAnimation(user,0)
          if user.ability != (:MAGICGUARD) && !(user.ability == (:WONDERGUARD) && @battle.FE == :COLOSSEUM)
            if @battle.FE == :UNDERWATER
              eff=PBTypes.twoTypeEff(:WATER,user.type1,user.type2)
              user.pbReduceHP((user.totalhp*eff/16.0).floor)
            else
              user.pbReduceHP((user.totalhp/4.0).floor)
            end
          end
          if target.form==1 # Gulping Form
            if user.pbCanReduceStatStage?(PBStats::DEFENSE,false,false)
              user.pbReduceStatBasic(PBStats::DEFENSE,1)
              @battle.pbCommonAnimation("StatDown",user,nil)
              @battle.pbDisplay(_INTL("{1}'s {2} lowered {3}'s Defense!",target.pbThis,getAbilityName(target.ability),user.pbThis(true)))
            end
          elsif target.form==2 # Gorging Form
            if user.pbCanParalyze?(false)
              user.pbParalyze(target)
              @battle.pbDisplay(_INTL("{1}'s {2} paralyzed {3}! It may be unable to move!",target.pbThis,getAbilityName(target.ability),user.pbThis(true)))
            end
          end
          @battle.pbDisplay(_INTL("{1}'s {2} hurt {3}!",target.pbThis,getAbilityName(target.ability),user.pbThis(true)))
          target.form = 0
          transformed = true
          target.pbUpdate(false)
          @battle.scene.pbChangePokemon(target,target.pokemon)
          @battle.pbDisplay(_INTL("{1} returned to normal!",target.pbThis))
        end
        # Illusion goes here
        if (target.ability == :ILLUSION || target.crested == :ZOROARK) 
          if target.effects[:Illusion]!=nil
            target.effects[:Illusion]=nil
            @battle.pbAnimation(:TRANSFORM,target,target) if !target.isFainted? 
            @battle.scene.pbChangePokemon(target,target.pokemon)
            @battle.pbDisplay(_INTL("{1}'s {2} was broken!",target.pbThis, getAbilityName(:ILLUSION)))
          end
        end
        if target.ability == (:JUSTIFIED) && (movetype == :DARK)
          if target.pbCanIncreaseStatStage?(PBStats::ATTACK)
            stat = @battle.FE == :HOLY ? 2 : 1
            target.pbIncreaseStatBasic(PBStats::ATTACK,stat)
            @battle.pbCommonAnimation("StatUp",target,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!", target.pbThis,getAbilityName(target.ability)))
          end
        end
        if user.ability == (:MAGICIAN) && target.damagestate.calcdamage>0 &&
         !target.damagestate.substitute && target.item
          if target.ability == (:STICKYHOLD)
            abilityname=getAbilityName(target.ability)
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",target.pbThis,abilityname,@name))
          elsif !@battle.pbIsUnlosableItem(target,target.item) && !@battle.pbIsUnlosableItem(user,user.item) && user.item.nil? && (target || !pbIsOpposing?(user.index))
            itemname=getItemName(target.item)
            user.item=target.item
            target.item=nil
            target.effects[:ChoiceBand]=nil
            if user.pokemon.corrosiveGas
              user.pokemon.corrosiveGas=false
              target.pokemon.corrosiveGas=true
            end
            if @battle.pbIsWild? && # In a wild battle
              user.pokemon.itemInitial.nil? && !user.isbossmon && !target.isbossmon &&
              target.pokemon.itemInitial==user.item 
              user.pokemon.itemInitial=user.item
              user.pokemon.itemReallyInitialHonestlyIMeanItThisTime=user.item
              target.pokemon.itemInitial=nil
            end
            @battle.pbDisplay(_INTL("{1} stole {2}'s {3}!",user.pbThis,target.pbThis(true),itemname))
          end
        end
        if target.ability == (:RATTLED) && ((movetype == :BUG) || (movetype == :DARK) || (movetype == :GHOST))
          if target.pbCanIncreaseStatStage?(PBStats::SPEED)
            target.pbIncreaseStatBasic(PBStats::SPEED,1)
            @battle.pbCommonAnimation("StatUp",target,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its Speed!", target.pbThis,getAbilityName(target.ability)))
          end
        end
        if target.ability == (:WEAKARMOR) && move.pbIsPhysical?(movetype)
          if target.pbCanReduceStatStage?(PBStats::DEFENSE,false,true)
            target.pbReduceStatBasic(PBStats::DEFENSE,1)
            @battle.pbCommonAnimation("StatDown",target,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} lowered its Defense!", target.pbThis,getAbilityName(target.ability)))
          end
          if target.pbCanIncreaseStatStage?(PBStats::SPEED)
            target.pbIncreaseStatBasic(PBStats::SPEED,2)
            @battle.pbCommonAnimation("StatUp",target,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} sharply raised its Speed!", target.pbThis,getAbilityName(target.ability)))
          end
        end
        if target.ability == (:STAMINA)
          if target.pbCanIncreaseStatStage?(PBStats::DEFENSE)
            target.pbIncreaseStatBasic(PBStats::DEFENSE,1)
            @battle.pbCommonAnimation("StatUp",target,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its Defense!", target.pbThis,getAbilityName(target.ability)))
          end
        end
        if target.crested == :NOCTOWL
          if target.pbCanIncreaseStatStage?(PBStats::SPDEF)
            target.pbIncreaseStatBasic(PBStats::SPDEF,1)
            @battle.pbCommonAnimation("StatUp",target,nil)
            @battle.pbDisplay(_INTL("{1}'s Crest raised its Special Defense!", target.pbThis))
          end
        end
        if target.ability == (:WATERCOMPACTION) && (movetype == :WATER)
          if @battle.FE!=:ASHENBEACH
            if target.pbCanIncreaseStatStage?(PBStats::DEFENSE)
              target.pbIncreaseStatBasic(PBStats::DEFENSE,2)
              @battle.pbCommonAnimation("StatUp",target,nil)
              @battle.pbDisplay(_INTL("{1}'s Water Compaction sharply raised its Defense!",
               target.pbThis,getAbilityName(target.ability)))
             end
           else
            boost = false
            if target.pbCanIncreaseStatStage?(PBStats::DEFENSE)
              target.pbIncreaseStatBasic(PBStats::DEFENSE,2)
              @battle.pbCommonAnimation("StatUp",target,nil) if !boost
              #@battle.pbDisplay(_INTL("{1}'s {2} sharply raised its Defense!",
               #target.pbThis,getAbilityName(target.ability)))
              boost = true
            end
            if target.pbCanIncreaseStatStage?(PBStats::SPDEF)
              target.pbIncreaseStatBasic(PBStats::SPDEF,2)
              @battle.pbCommonAnimation("StatUp",target,nil) if !boost
              #@battle.pbDisplay(_INTL("{1}'s {2} sharply raised its Defense!",
               #target.pbThis,getAbilityName(target.ability)))
              boost = true
            end
            @battle.pbDisplay(_INTL("{1}'s {2} sharply raised its Defense and Special Defense!",target.pbThis,getAbilityName(target.ability))) if boost
          end
        end
      end
      # Cotton Down
      if target.ability == (:COTTONDOWN)
        @battle.pbDisplay(_INTL("{1}'s {2} scatters cotton around!",
         target.pbThis,getAbilityName(target.ability)))
        for i in @battle.battlers
          next if i==target
          statdrop = 1
          statdrop = 2 if @battle.FE == :BEWITCHED || @battle.FE == :GRASSY
          if i.pbCanReduceStatStage?(PBStats::SPEED)
            i.pbReduceStat(PBStats::SPEED,statdrop,abilitymessage:false)
            #@battle.pbCommonAnimation("StatDown",i,nil)
            @battle.pbDisplay(_INTL("The cotton reduces {1}'s Speed!",i.pbThis)) if i.ability != :MIRRORARMOR
          end
        end
      end
      # Sand Spit
      if target.ability == (:SANDSPIT)
        if !(@battle.state.effects[:HeavyRain] || @battle.state.effects[:HarshSunlight] ||
           @battle.weather== :STRONGWINDS || @battle.weather== :SANDSTORM ||
           @battle.FE==:NEWWORLD || @battle.FE==:UNDERWATER || @battle.FE==:DIMENSIONAL)
          @battle.pbAnimation(:SANDSTORM,self,nil)
          @battle.weather=:SANDSTORM
          @battle.weatherduration=5
          @battle.weatherduration=8 if (target.hasWorkingItem(:SMOOTHROCK) ||
           @battle.FE == :DESERT || @battle.FE == :ASHENBEACH || @battle.FE == :SKY)
          @battle.pbCommonAnimation("Sandstorm")
          @battle.pbDisplay(_INTL("A sandstorm brewed!"))
          if (@battle.FE == :DESERT && @battle.FE == :ASHENBEACH) && user.pbCanReduceStatStage?(PBStats::ACCURACY)
            user.pbReduceStatBasic(PBStats::ACCURACY,1)
            @battle.pbCommonAnimation("StatDown",user,nil)
            @battle.pbDisplay(_INTL("{1}'s accuracy fell!",user.pbThis))
          end
        end
      end
      # Steam Engine
      if target.ability == (:STEAMENGINE) &&
        ((movetype == :WATER) || (movetype == :FIRE))
        if target.pbCanIncreaseStatStage?(PBStats::SPEED)
          target.pbIncreaseStatBasic(PBStats::SPEED,6)
          @battle.pbCommonAnimation("StatUp",target)
          @battle.pbDisplay(_INTL("{1}'s {2} drastically raised its Speed!",
           target.pbThis,getAbilityName(target.ability)))
        end
      end
      if target.hasWorkingItem(:AIRBALLOON,true)
        target.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1}'s Air Balloon popped!",target.pbThis))
      end
      if target.hasWorkingItem(:ABSORBBULB) && movetype == :WATER
        if target.pbCanIncreaseStatStage?(PBStats::SPATK)
          target.pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbCommonAnimation("StatUp",target)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Special Attack!", target.pbThis,getItemName(target.item)))
             target.pbDisposeItem(false)
        end
      end
      if target.hasWorkingItem(:CELLBATTERY) && movetype == :ELECTRIC
        if target.pbCanIncreaseStatStage?(PBStats::ATTACK)
          target.pbIncreaseStatBasic(PBStats::ATTACK,1)
          @battle.pbCommonAnimation("StatUp",target)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!", target.pbThis,getItemName(target.item)))
          target.pbDisposeItem(false)
        end
      end
      if target.hasWorkingItem(:SNOWBALL) && movetype == :ICE
        if target.pbCanIncreaseStatStage?(PBStats::ATTACK)
          target.pbIncreaseStatBasic(PBStats::ATTACK,1)
          @battle.pbCommonAnimation("StatUp",target)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!", target.pbThis,getItemName(target.item)))
          target.pbDisposeItem(false)
        end
      end
      if target.hasWorkingItem(:LUMINOUSMOSS) && movetype == :WATER
        if target.pbCanIncreaseStatStage?(PBStats::SPDEF)
          target.pbIncreaseStatBasic(PBStats::SPDEF,1)
          @battle.pbCommonAnimation("StatUp",target)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Special Defense!", target.pbThis,getItemName(target.item)))
          target.pbDisposeItem(false)
        end
      end
      if !([:UNNERVE,:ASONE].include?(user.ability) || [:UNNERVE,:ASONE].include?(user.pbPartner.ability))
        if target.hasWorkingItem(:KEEBERRY) && move.pbIsPhysical?(movetype)
          if target.pbCanIncreaseStatStage?(PBStats::DEFENSE)
            target.pbIncreaseStatBasic(PBStats::DEFENSE,1)
            @battle.pbCommonAnimation("Nom",target)
            @battle.pbCommonAnimation("StatUp",target)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its Defense!", target.pbThis,getItemName(target.item)))
            target.pbDisposeItem(true)
          end
        end

        if target.hasWorkingItem(:MARANGABERRY) && move.pbIsSpecial?(movetype)
          if target.pbCanIncreaseStatStage?(PBStats::SPDEF)
            target.pbIncreaseStatBasic(PBStats::SPDEF,1)
            @battle.pbCommonAnimation("Nom",target)
            @battle.pbCommonAnimation("StatUp",target)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its Special Defense!", target.pbThis,getItemName(target.item)))
            target.pbDisposeItem(true)
          end
        end

        if target.hasWorkingItem(:JABOCABERRY,true) && !user.isFainted? && move.pbIsPhysical?(movetype)
          @battle.pbCommonAnimation("Nom",target)
          @battle.scene.pbDamageAnimation(user,0)
          user.pbReduceHP((user.totalhp/8.0).floor)
          @battle.pbDisplay(_INTL("{1} was hurt by the {2}!",user.pbThis, getItemName(target.item)))
          target.pbDisposeItem(true)
        end
        if target.hasWorkingItem(:ROWAPBERRY,true) && !user.isFainted? && move.pbIsSpecial?(movetype)
          @battle.pbCommonAnimation("Nom",target)
          @battle.scene.pbDamageAnimation(user,0)
          user.pbReduceHP((user.totalhp/8.0).floor)
          @battle.pbDisplay(_INTL("{1} was hurt by the {2}!",user.pbThis, getItemName(target.item)))
          target.pbDisposeItem(true)
        end
      end

      if target.hasWorkingItem(:WEAKNESSPOLICY) && target.damagestate.typemod>4
        if target.pbCanIncreaseStatStage?(PBStats::ATTACK)
          target.pbIncreaseStatBasic(PBStats::ATTACK,2)
          @battle.pbCommonAnimation("StatUp",target)
          @battle.pbDisplay(_INTL("{1}'s {2} sharply raised its Attack!", target.pbThis,getItemName(target.item)))
          target.pbDisposeItem(false)
        end
        if target.pbCanIncreaseStatStage?(PBStats::SPATK)
          target.pbIncreaseStatBasic(PBStats::SPATK,2)
          @battle.pbCommonAnimation("StatUp",target)
          @battle.pbDisplay(_INTL("{1}'s Weakness Policy sharply raised its Special Attack!", target.pbThis))
          target.pbDisposeItem(false)
        end
      end
      if target.ability == (:ANGERPOINT)
        if target.pbCanIncreaseStatStage?(PBStats::ATTACK) && target.damagestate.critical
          target.stages[PBStats::ATTACK]=6
          @battle.pbCommonAnimation("StatUp",target)
          @battle.pbDisplay(_INTL("{1}'s {2} maxed its Attack!",
           target.pbThis,getAbilityName(target.ability)))
         end
      end
      if target.hasWorkingItem(:REDCARD) && !target.damagestate.substitute && !target.isbossmon
        choices = []
        party=@battle.pbParty(user.index)
        for i in 0...party.length
          choices[choices.length]=i if @battle.pbCanSwitchLax?(user.index,i,false)
        end
        if choices.length!=0
          @battle.pbDisplay(_INTL("#{target.pbThis}'s Red Card activates!"))
          target.pbDisposeItem(false)
          if user.ability == (:SUCTIONCUPS)
           @battle.pbDisplay(_INTL("{1} anchored itself with {2}!",user.pbThis,getAbilityName(user.ability)))
          elsif user.effects[:Ingrain]
            @battle.pbDisplay(_INTL("{1} anchored itself with its roots!",user.pbThis))
          elsif @battle.FE == :COLOSSEUM
            @battle.pbDisplay(_INTL("{1} stands their ground in the arena!",user.pbThis))
          else
            user.forcedSwitch = true
          end
        end
      end
    end
    user.pbAbilityCureCheck
    target.pbAbilityCureCheck
    # Synchronize here
    s=@battle.synchronize[0]
    t=@battle.synchronize[1]
    if s>=0 && t>=0 && @battle.battlers[s].ability == (:SYNCHRONIZE) &&
       @battle.synchronize[2].is_a?(Symbol) && !@battle.battlers[t].isFainted?
      # see [2024281]&0xF0, [202420C]
      sbattler=@battle.battlers[s]
      tbattler=@battle.battlers[t]
      if @battle.synchronize[2]== :POISON && tbattler.pbCanPoisonSynchronize?(sbattler,true)
        # UPDATE 11/17/2013
        # allows for transfering of `badly poisoned` instead of just poison.
        #changed from: tbattler.pbPoison(sbattler)
        tbattler.pbPoison(sbattler, sbattler.statusCount == 1)
            @battle.pbDisplay(_INTL("{1}'s {2} poisoned {3}!",sbattler.pbThis,
           getAbilityName(sbattler.ability),tbattler.pbThis(true)))
      elsif @battle.synchronize[2]== :BURN && tbattler.pbCanBurnSynchronize?(sbattler,true)
        tbattler.pbBurn(sbattler)
        @battle.pbDisplay(_INTL("{1}'s {2} burned {3}!",sbattler.pbThis,
           getAbilityName(sbattler.ability),tbattler.pbThis(true)))
      elsif @battle.synchronize[2]== :PARALYSIS && tbattler.pbCanParalyzeSynchronize?(sbattler,true)
        tbattler.pbParalyze(sbattler)
        @battle.pbDisplay(_INTL("{1}'s {2} paralyzed {3}! It may be unable to move!",
           sbattler.pbThis,getAbilityName(sbattler.ability),tbattler.pbThis(true)))
      end
    end
  end

  def pbAbilityCureCheck
    return if self.isFainted?
    if self.ability == :LIMBER && self.status== :PARALYSIS
      @battle.pbDisplay(_INTL("{1}'s Limber cured its paralysis problem!",pbThis))
      self.status=nil
    end
    if self.ability == :OBLIVIOUS && @effects[:Attract]>=0
      @battle.pbDisplay(_INTL("{1}'s Oblivious cured its love problem!",pbThis))
      @effects[:Attract]=-1
    end
    if self.ability == :VITALSPIRIT && self.status== :SLEEP
      @battle.pbDisplay(_INTL("{1}'s Vital Spirit cured its sleep problem!",pbThis))
      self.status=nil
    end
    if self.ability == :INSOMNIA && self.status== :SLEEP
      @battle.pbDisplay(_INTL("{1}'s Insomnia cured its sleep problem!",pbThis))
      self.status=nil
    end
    if self.ability == :IMMUNITY && self.status== :POISON
      @battle.pbDisplay(_INTL("{1}'s Immunity cured its poison problem!",pbThis))
      self.status=nil
    end
    if self.ability == :OWNTEMPO && @effects[:Confusion]>0
      @battle.pbDisplay(_INTL("{1}'s Own Tempo cured its confusion problem!",pbThis))
      @effects[:Confusion]=0
    end
    if self.ability == :MAGMAARMOR && self.status== :FROZEN
      @battle.pbDisplay(_INTL("{1}'s Magma Armor cured its ice problem!",pbThis))
      self.status=nil
    end
    if self.ability == :WATERVEIL && self.status== :BURN
      @battle.pbDisplay(_INTL("{1}'s Water Veil cured its burn problem!",pbThis))
      self.status=nil
    end
  end

  def pbEmergencyExitCheck(oldhp)
    if oldhp >= (@totalhp/2.0).floor && (self.hp + self.pbBerryRecoverAmount) < (@totalhp/2.0).floor && self.hp!=0
      if @battle.FE == :COLOSSEUM
        if self.ability == :WIMPOUT
          @battle.pbDisplay(_INTL("{1} has nowhere to run!",self.pbThis))
        elsif self.ability == :EMERGENCYEXIT
          if self.pbCanIncreaseStatStage?(PBStats::SPEED)  
            self.pbIncreaseStatBasic(PBStats::SPEED,2)  
            @battle.pbCommonAnimation("StatUp",user,nil)  
            @battle.pbDisplay(_INTL("Emergency Exit raised {1}'s Speed!",self.pbThis))  
          end
        end 
      else
        if (self.ability == :WIMPOUT || self.ability == :EMERGENCYEXIT) && 
          ((@battle.pbCanChooseNonActive?(self.index) && !@battle.pbAllFainted?(@battle.pbParty(self.index))) || @battle.pbIsWild?)
          if @battle.pbIsWild?
            return if @battle.cantescape || $game_switches[:Never_Escape] || self.isbossmon
            @battle.decision=3 # Set decision to escaped
          else
            self.userSwitch = true
          end
          @battle.pbDisplay(_INTL("{1} tactically retreated!",self.pbThis)) if self.ability == :EMERGENCYEXIT
          @battle.pbDisplay(_INTL("{1} wimped out!",self.pbThis)) if self.ability == :WIMPOUT
        end
      end
    end
  end

################################################################################
# Held item effects
################################################################################
  def pbBerryRecoverAmount
    return 0 if self.isFainted?
    return 0 if [:UNNERVE,:ASONE].include?(pbOpposing1.ability) || [:UNNERVE,:ASONE].include?(pbOpposing1.ability)
    healing = 0
    case self.item
      when :ORANBERRY then healing = 10 if self.hp<=(self.totalhp/2.0).floor
      when :SITRUSBERRY then healing = (self.totalhp/4.0).floor if self.hp<=(self.totalhp/2.0).floor
      when :ENIGMABERRY then healing = (self.totalhp/4.0).floor if self.damagestate.typemod>4
      when :BERRYJUICE then healing = 20 if self.hp<=(self.totalhp/2.0).floor
      when :FIGYBERRY, :WIKIBERRY, :MAGOBERRY, :AGUAVBERRY, :IAPAPABERRY
        healing = (self.totalhp/2.0).floor if self.hp<=(self.totalhp/4.0).floor || (self.ability == :GLUTTONY && self.hp<=(self.totalhp/2.0).floor)
    end
    healing*=2 if self.ability==:RIPEN
    return healing
  end

  def pbBerryCureCheck(hpcure=false)
    return if self.isFainted?
    return if !self.itemWorks?
    itemname=getItemName(self.item)
    #non-berries go first!
    hpcure=false if @effects[:HealBlock]!=0
    if hpcure && (self.item == :LEFTOVERS || (self.item == :BLACKSLUDGE && hasType?(:POISON)) || (self.crested == :INFERNAPE)) && self.hp!=self.totalhp
      hpgain = self.totalhp/16
      hpgain = self.totalhp/8 if @battle.FE == :CORRUPTED && self.item == :BLACKSLUDGE
      pbRecoverHP((hpgain).floor,true)
      @battle.pbDisplay(_INTL("{1}'s {2} restored its HP a little!",pbThis,itemname))
      return
    end
    if hpcure && (self.item == :BLACKSLUDGE && !hasType?(:POISON)) && self.ability != :MAGICGUARD && !(self.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM)
      hploss = self.totalhp/8
      hploss = self.totalhp/4 if @battle.FE == :CORRUPTED
      pbReduceHP((hploss).floor,true)
      @battle.pbDisplay(_INTL("{1} was hurt by its {2}!",pbThis,itemname))
      pbFaint if self.isFainted?
      return
    end
    # Spiritomb Crest
    if hpcure && self.crested == :SPIRITOMB && self.hp!=self.totalhp
      enemyfainted = pbEnemyFaintedPokemonCount
      pbRecoverHP(((self.totalhp*enemyfainted)/20).floor,true)
      @battle.pbDisplay(_INTL("{1}'s {2} restored its HP!",pbThis,itemname))
    end
    if hpcure && self.crested == :GOTHITELLE && self.hasType?(:PSYCHIC) && self.hp!=self.totalhp
      pbRecoverHP((self.totalhp/16).floor,true)
      @battle.pbDisplay(_INTL("{1}'s {2} restored its HP!",pbThis,itemname))
    end
    if self.item == :WHITEHERB
      reducedstats=false
      for i in 1..7
        if @stages[i]<0
          @stages[i]=0; reducedstats=true
        end
      end
      if reducedstats
        @battle.pbDisplay(_INTL("{1}'s {2} restored its status!",pbThis,itemname))
        pbDisposeItem(false)
        return
      end
    end
    if self.item == :MENTALHERB && (@effects[:Attract]>=0 || @effects[:Taunt]>0 || @effects[:Encore]>0 ||
       @effects[:Torment] || @effects[:Disable]>0 || @effects[:HealBlock]>0)
      @battle.pbDisplay(_INTL("{1}'s {2} cured its love problem!",pbThis,itemname)) if @effects[:Attract]>=0
      @battle.pbDisplay(_INTL("{1} is taunted no more!",pbThis)) if @effects[:Taunt]>0
      @battle.pbDisplay(_INTL("{1}'s encore ended!",pbThis)) if @effects[:Encore]>0
      @battle.pbDisplay(_INTL("{1} is tormented no more!",pbThis)) if @effects[:Torment]
      @battle.pbDisplay(_INTL("{1} is disabled no more!",pbThis)) if @effects[:Disable]>0
      @battle.pbDisplay(_INTL("{1}'s heal block ended!",pbThis)) if @effects[:HealBlock]>0
      @effects[:Attract]=-1
      @effects[:Taunt]=0
      @effects[:Encore]=0
      @effects[:EncoreMove]=0
      @effects[:EncoreIndex]=0
      @effects[:Torment]=false
      @effects[:Disable]=0
      @effects[:HealBlock]=0
      pbDisposeItem(false)
      return
    end
    #berries go now!
    #non-berries can get the fuck out of here
    return if [:UNNERVE,:ASONE].include?(pbOpposing1.ability) || [:UNNERVE,:ASONE].include?(pbOpposing1.ability) || self.item.nil? || !pbIsBerry?(self.item)
    pbUseBerry
  end

  def pbUseBerry(berry=nil,special=false)
    #split from berrycurecheck to allow bug bite to skip everything
    #healing also acts as a way to check if a berry was eaten
    healing = -1
    confu_berry = false
    stat_berry = false
    status_berry = false
    berry = self.item if berry == nil
    health_threshold = self.ability == :GLUTTONY ? (self.totalhp/2.0).floor : (self.totalhp/4.0).floor
    itemname=getItemName(berry)
    case berry
      when :ORANBERRY   then healing = 10 if self.hp <= (self.totalhp/2.0).floor || special
      when :SITRUSBERRY then healing = (self.totalhp/4.0).floor if self.hp <= (self.totalhp/2.0).floor || special
      when :ENIGMABERRY then healing = (self.totalhp/4.0).floor if self.damagestate.typemod > 4 || special
      when :BERRYJUICE  then healing = 20 if self.hp <= (self.totalhp/2.0).floor || special
      when :FIGYBERRY, :WIKIBERRY, :MAGOBERRY, :AGUAVBERRY, :IAPAPABERRY
        healing = (self.totalhp/2.0).floor if self.hp <= health_threshold || special
        confu_berry = true
      when :CHERIBERRY
        if self.status== :PARALYSIS
          healing = 0
          status_berry = true
        end 
        status = "paralysis"
      when :CHESTOBERRY
        if self.status== :SLEEP
          healing = 0
          status_berry = true
        end
        status = "sleep"
      when :PECHABERRY
        if self.status== :POISON
          healing = 0
          status_berry = true
        end
        status = "poison"
      when :RAWSTBERRY
        if self.status== :BURN
          healing = 0
          status_berry = true
        end
        status = "burn"
      when :ASPEARBERRY
        if self.status== :FROZEN
          healing = 0
          status_berry = true
        end
        status = "ice"
      when :PERSIMBERRY
        if @effects[:Confusion]>0
          healing = 0
          status_berry = true
        end
        status = "confusion"
      when :LUMBERRY
        if !self.status.nil? || @effects[:Confusion]>0
          healing = 0
          status_berry = true
        end
        status = "status"
      when :LIECHIBERRY, :GANLONBERRY, :SALACBERRY, :PETAYABERRY, :APICOTBERRY, :STARFBERRY
        healing = 0 if self.hp <= health_threshold
        stat_berry = true
        if berry == :STARFBERRY
          stats=[]
          for i in 1..5
            stats.push(i) if !pbTooHigh?(i)
          end
          return if stats.length == 0
          chosen_stat = stats[@battle.pbRandom(stats.length)]
          stat_amt = 2
        else
          case berry
            when :LIECHIBERRY then chosen_stat = 1
            when :GANLONBERRY then chosen_stat = 2
            when :PETAYABERRY then chosen_stat = 3
            when :APICOTBERRY then chosen_stat = 4
            when :SALACBERRY then chosen_stat = 5
          end
          return if self.pbTooHigh?(chosen_stat)
          stat_amt = 1
        end
      when :LANSATBERRY #unique berry, doing the processing now
        if @effects[:FocusEnergy]<3 && self.hp <= health_threshold
          healing = 0 
          message = _INTL("{1} used its {2} to get pumped!",pbThis,itemname)
          @effects[:FocusEnergy]+=1 
        end
      when :LEPPABERRY #unique berry, doing the processing now
        if @pokemon.moves.any?{|move| move.move && move.pp==0}
          healing = 0 
          for i in 0...@pokemon.moves.length
            pokemove=@pokemon.moves[i]
            next if pokemove.pp==0 && pokemove.move
            pokemove.pp = self.ability == :RIPEN ? 20 : 10
            pokemove.pp=pokemove.totalpp if pokemove.pp>pokemove.totalpp
            self.moves[i].pp=pokemove.pp
            break
          end
          message = _INTL("{1}'s {2} restored {3}'s PP!",pbThis,itemname,getMoveName(pokemove.move))
        end
    end
    #return if berry didn't trigger
    return if healing == -1 && !special
    @battle.pbCommonAnimation("Nom",self,nil)
    if healing > 0  #this berry is ACTUALLY a healing berry
      healing*=2 if self.ability==:RIPEN
      self.pbRecoverHP(healing,true)
      message = _INTL("{1}'s {2} restored health!",pbThis,itemname)
    elsif status_berry
      self.status = nil if berry != :PERSIMBERRY
      @effects[:Confusion] = 0 if berry == :PERSIMBERRY || berry == :LUMBERRY
      message = _INTL("{1}'s {2} cured its {3} problem!",pbThis,itemname,status)
    elsif stat_berry
      case chosen_stat
        when PBStats::ATTACK then message = _INTL("Using its {1}, the Attack of {2} rose!",itemname,pbThis(true))
        when PBStats::DEFENSE then message = _INTL("Using its {1}, the Defense of {2} rose!",itemname,pbThis(true))
        when PBStats::SPEED then message = _INTL("Using its {1}, the Speed of {2} rose!",itemname,pbThis(true))
        when PBStats::SPATK then message = _INTL("Using its {1}, the Special Attack of {2} rose!",itemname,pbThis(true))
        when PBStats::SPDEF then message = _INTL("Using its {1}, the Special Defense of {2} rose!",itemname,pbThis(true))
      end
      stat_amt*=2 if self.ability==:RIPEN
      @battle.pbCommonAnimation("StatUp",self,nil)
      pbIncreaseStatBasic(chosen_stat,stat_amt)
    elsif confu_berry
      case berry
        when :FIGYBERRY then flavor = 0; flavor_text = "spicy"
        when :WIKIBERRY then flavor = 3; flavor_text = "dry"
        when :MAGOBERRY then flavor = 2; flavor_text = "sweet"
        when :AGUAVBERRY then flavor = 4; flavor_text = "bitter"
        when :IAPAPABERRY then flavor = 1; flavor_text = "sour"
      end
      confusion = $cache.natures[self.nature].dislike == flavor_text
    end
    @battle.pbDisplay(message) if message
    if confusion && pbCanConfuseSelf?(true,false)
      @battle.pbDisplay(_INTL("For {1}, the {2} was too {3}!",pbThis(true),itemname,flavor_text,true))
      if @effects[:Confusion]==0 && self.ability != :OWNTEMPO
        @effects[:Confusion]=2+@battle.pbRandom(4)
        @battle.pbCommonAnimation("Confusion",self,nil)
        @battle.pbDisplay(_INTL("{1} became confused!",pbThis))
      end
    end
    if special
      pbBurp
      pbSymbiosis
    else
      pbDisposeItem
    end
  end

  def pbCustapBerry
    if self.hasWorkingItem(:CUSTAPBERRY) && ((self.ability == :GLUTTONY && self.hp<=(self.totalhp/2.0).floor) || self.hp<=(self.totalhp/4.0).floor)
      @custap = true
      @battle.pbCommonAnimation("Nom",self,nil)
      @battle.pbDisplay(_INTL("{1} ate its Custap Berry to move first!",pbThis))
      self.pbDisposeItem(true)
    else
      @custap = false
    end
  end

  def pbDisposeItem(berry=true,symbiosis=true)
    self.pokemon.itemRecycle=self.item
    self.pokemon.itemInitial=nil if self.pokemon.itemInitial==self.item
    self.item=nil
    pbBurp(self) if berry
    pbSymbiosis(self)
  end

  def pbBurp(target=self)
    target.pokemon.belch = true
    if target.ability == :CHEEKPOUCH
      target.pbRecoverHP((target.totalhp/3.0).floor,true)
      @battle.pbDisplay(_INTL("{1}'s {2} restored health!",pbThis,getAbilityName(target.ability)))
    end
  end

  def pbSymbiosis(target=self)
    return if !@battle.doublebattle || target.hp == 0 || target.pbPartner.hp == 0
    return if target.pbPartner.ability != :SYMBIOSIS
    return if target.pbPartner.item.nil? || target.item
    @battle.pbDisplay(_INTL("{1} received {2}'s {3} from symbiosis! ",target.pbThis, target.pbPartner.pbThis, getItemName(target.pbPartner.item)))
    target.item = target.pbPartner.item
    target.pokemon.itemInitial = target.pbPartner.item
    target.pbPartner.pokemon.itemInitial = nil
    target.pbPartner.item=nil
  end


################################################################################
# Move user and targets
################################################################################
  def pbFindUser(choice,targets)
    move=choice[2]
    target=choice[3]

    # Targets in normal cases
    case pbTarget(move)
    when :SingleNonUser
      if target>=0
        targetBattler=@battle.battlers[target]
        if !pbIsOpposing?(targetBattler.index)
          if !pbAddTarget(targets,targetBattler) && move.move != :INSTRUCT
            pbAddTarget(targets,pbOpposing2) if !pbAddTarget(targets,pbOpposing1)
          end
        else
          pbAddTarget(targets,targetBattler.pbPartner) if !pbAddTarget(targets,targetBattler)
        end
      else
        pbRandomTarget(targets)
      end
    when :SingleOpposing
      if target>=0
        targetBattler=@battle.battlers[target]
        if !pbIsOpposing?(targetBattler.index)
          if !pbAddTarget(targets,targetBattler)
            pbAddTarget(targets,pbOpposing2) if !pbAddTarget(targets,pbOpposing1)
          end
        else
          pbAddTarget(targets,targetBattler.pbPartner) if !pbAddTarget(targets,targetBattler)
        end
      else
        pbRandomTarget(targets)
      end
    when :OppositeOpposing
      pbAddTarget(targets,pbCrossOpposing) if !pbAddTarget(targets,pbOppositeOpposing)
      pbRandomTarget(targets) if targets.length==0
    when :RandomOpposing
      pbRandomTarget(targets)
    when :AllOpposing
      # Just pbOpposing1 because partner is determined late
      pbAddTarget(targets,pbOpposing2) if !pbAddTarget(targets,pbOpposing1)
    when :AllNonUsers
      for i in 0...4 # not ordered by priority
        pbAddTarget(targets,@battle.battlers[i]) if i!=@index
      end
    when :DragonDarts
      smartDart = move.pbDragonDartTargetting(self)
      case smartDart.length
        when 1
          pbAddTarget(targets,smartDart[0])
        when 2
          pbAddTarget(targets,smartDart[0])
          pbAddTarget(targets,smartDart[1])
      end
      # doesn't work for singles, but as a proof of concept does what I want!
      #if pbOpposing1.hasType?(:NORMAL)
      #  pbAddTarget(targets,pbOpposing2)
      #else
      #  pbAddTarget(targets,pbOpposing2) && pbAddTarget(targets,pbOpposing1)
      #end
    when :UserOrPartner
      if target>=0 # Pre-chosen target
        targetBattler=@battle.battlers[target]
        pbAddTarget(targets,targetBattler.pbPartner) if !pbAddTarget(targets,targetBattler)
      else
        pbAddTarget(targets,self)
      end
    when :Partner
      pbAddTarget(targets,pbPartner)
    else
      move.pbAddTarget(targets,self)
    end
  end

  def pbChangeUser(basemove,user)
    priority=@battle.pbPriority
    # Change user to user of Snatch
    if basemove.canSnatch?
      for i in priority
        if i.effects[:Snatch]
          @battle.pbDisplay(_INTL("{1} snatched {2}'s move!",i.pbThis,user.pbThis(true)))
          if @battle.FE == :BACKALLEY
            stat = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED].sample
            if i.pbCanIncreaseStatStage?(stat,false)
              i.pbIncreaseStat(stat,2)
            end
          end
          i.effects[:Snatch]=false
          target=user
          user=i
          # Snatch's PP is reduced if old user has Pressure
          userchoice=@battle.choices[user.index][1]
          if target.ability == (:PRESSURE) && userchoice>=0
            pressuremove=user.moves[userchoice]
            pbSetPP(pressuremove,pressuremove.pp-1) if pressuremove.pp>0
            if @battle.FE == :DIMENSIONAL || @battle.FE == :DEEPEARTH
              pressuremove=user.moves[userchoice]
              pbSetPP(pressuremove,pressuremove.pp-1) if pressuremove.pp>0
            end
          end
        end
      end
    end
    return user
  end

  def pbTarget(move)
    target=move.target
    if move.function==0x10D && hasType?(:GHOST) # Curse
      target=:SingleNonUser
    elsif (@battle.FE == :PSYTERRAIN || @battle.state.effects[:PSYTERRAIN] > 0 ) && move.move == :EXPANDINGFORCE
      target=:AllOpposing
    elsif @battle.FE == :FLOWERGARDEN5 && PBFields::MAXGARDENMOVES.include?(move.move)
      target=:AllOpposing
    elsif @battle.FE == :HAUNTED && (move.move == :MEANLOOK || move.move == :FIRESPIN)
      target=:AllOpposing
    elsif @battle.FE == :DEEPEARTH && move.move == :TOPSYTURVY
      target=:AllNonUsers
    elsif @battle.FE == :DEEPEARTH && move.move == :GRAVITY
      target=:AllOpposing
    elsif self.ability == :TEMPEST && move.move == :WEATHERBALL
      target=:AllOpposing
    elsif self.ability == :WORLDOFNIGHTMARES && move.move == :NIGHTMARE
      target=:AllOpposing
    end
    side=(pbIsOpposing?(self.index)) ? 1 : 0
    owner=@battle.pbGetOwnerIndex(self.index)
    if @battle.zMove[side][owner]==self.index && self.item == :KOMMONIUMZ
      target=:AllOpposing
    elsif @battle.zMove[side][owner]==self.index && move.category != :status
      target=:SingleNonUser
    end
    return target
  end

  def pbAddTarget(targets,target)
    if !target.isFainted?
      targets[targets.length]=target
      return true
    end
    return false
  end

  def pbRandomTarget(targets)
    choices=[]
    pbAddTarget(choices,pbOpposing1)
    pbAddTarget(choices,pbOpposing2)
    if choices.length>0
      pbAddTarget(targets,choices[@battle.pbRandom(choices.length)])
    end
  end

  def pbChangeTarget(basemove,userandtarget,targets)
    priority=@battle.pbPriority
    changeeffect=0
    user=userandtarget[0]
    target=userandtarget[1]
    targetchoices=pbTarget(basemove)
    if (basemove.function==0x179) || user.ability == (:STALWART) || user.ability == (:PROPELLERTAIL)
      return true
    end
    # LightningRod here, considers Hidden Power as Normal
    if targets.length==1 && basemove.pbType(user) == :ELECTRIC && target.ability != (:LIGHTNINGROD)
      for i in priority # use Pokémon earliest in priority
        next if i.index==user.index || i.isFainted?
        if i.ability == :LIGHTNINGROD && !i.moldbroken
          target=i # X's LightningRod took the attack!
          changeeffect=1
          break
        end
      end
    end
    # Storm Drain here, considers Hidden Power as Normal
    if targets.length==1 && basemove.pbType(user) == :WATER && target.ability != (:STORMDRAIN)
      for i in priority # use Pokémon earliest in priority
        next if i.index==user.index || i.isFainted?
        if i.ability == :STORMDRAIN && !i.moldbroken
          target=i # X's Storm Drain took the attack!
          changeeffect=2
          break
        end
      end
    end
    # Change target to user of Follow Me (overrides Magic Coat
    # because check for Magic Coat below uses this target)
    if targetchoices==:SingleNonUser ||
      targetchoices==:SingleOpposing ||
      targetchoices==:RandomOpposing ||
      targetchoices==:OppositeOpposing
      for i in priority # use Pokémon latest in priority
        next if !pbIsOpposing?(i.index) || i.isFainted?
        if i.effects[:FollowMe] || i.effects[:RagePowder]
          unless (i.effects[:RagePowder] && (self.ability == :OVERCOAT || self.hasType?(:GRASS) || self.hasWorkingItem(:SAFETYGOGGLES)))# change target to this
            target=i
            changeeffect = 0
          end
        end
      end
    end
    # TODO: Pressure here is incorrect if Magic Coat redirects target
    if target.ability == (:PRESSURE)
      pressuredmove = (basemove.zmove && !user.zmoves.nil? && user.zmoves.include?(basemove)) ? user.moves[user.zmoves.index(basemove)] : basemove
      pbReducePP(pressuredmove) # Reduce PP
      if @battle.FE == :DIMENSIONAL || @battle.FE == :DEEPEARTH
        pbReducePP(pressuredmove)
      end
    end
    # Change user to user of Snatch
    if !basemove.zmove && basemove.canSnatch?
      for i in priority
        if i.effects[:Snatch]
          @battle.pbDisplay(_INTL("{1} Snatched {2}'s move!",i.pbThis,user.pbThis(true)))
          i.effects[:Snatch]=false
          target=user
          user=i
          # Snatch's PP is reduced if old user has Pressure
          userchoice=@battle.choices[user.index][1]
          if target.ability == (:PRESSURE) && userchoice>=0
            pressuremove=user.moves[userchoice]
            pbSetPP(pressuremove,pressuremove.pp-1) if pressuremove.pp>0
            if @battle.FE == :DIMENSIONAL || @battle.FE == :DEEPEARTH
              pressuremove=user.moves[userchoice]
              pbSetPP(pressuremove,pressuremove.pp-1) if pressuremove.pp>0
            end
          end
        end
      end
    end
    userandtarget[0]=user
    userandtarget[1]=target
    if target.ability == (:SOUNDPROOF) && basemove.isSoundBased? &&
       basemove.function!=0x19 &&   # Heal Bell handled elsewhere
       basemove.function!=0xE5 &&   # Perish Song handled elsewhere
       !(target.moldbroken)
      @battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",target.pbThis,
         getAbilityName(target.ability),basemove.name))
      return false
    end
    if !basemove.zmove && basemove.canMagicCoat? && target.effects[:MagicCoat]
      # switch user and target
      changeeffect=3
      target.effects[:MagicCoat]=false
      user, target = target, user

      # Magic Coat's PP is reduced if old user has Pressure
      userchoice=@battle.choices[user.index][1]
      if target.ability == (:PRESSURE) && userchoice>=0
        pressuremove=user.moves[userchoice]
        pbSetPP(pressuremove,pressuremove.pp-1) if pressuremove.pp>0
        if @battle.FE == :DIMENSIONAL || @battle.FE == :DEEPEARTH
          pressuremove=user.moves[userchoice]
          pbSetPP(pressuremove,pressuremove.pp-1) if pressuremove.pp>0
        end
      end
    end
    if !basemove.zmove && !(user.effects[:MagicBounced]) && basemove.canMagicCoat? && target.ability == (:MAGICBOUNCE) && !(target.moldbroken) &&
      !(basemove.function==0x103) && !(basemove.function==0x104) && !(basemove.function==0x105) && !(basemove.function==0x141) &&
      !PBStuff::TWOTURNMOVE.include?(target.effects[:TwoTurnAttack]) && changeeffect != 3
      target.effects[:MagicBounced]=true
      target.effects[:BouncedMove]=basemove
    end
    if changeeffect==1
      @battle.pbDisplay(_INTL("{1}'s Lightningrod took the move!",target.pbThis))
    elsif changeeffect==2
      @battle.pbDisplay(_INTL("{1}'s Storm Drain took the move!",target.pbThis))
    elsif changeeffect==3
      # Target refers to the move's old user
      @battle.pbDisplay(_INTL("{1}'s {2} was bounced back by Magic Coat!",user.pbThis,basemove.name))
    end
    userandtarget[0]=user
    userandtarget[1]=target
    if basemove.zmove
      targets[0]=target
    end
    return true
  end

  def pbFutureSightUserPlusMove()
    moveuser=nil
    disabled_items = {}
    #check if battler on the field
    for indexx in [@effects[:FutureSightUser],@effects[:FutureSightUser]^2]
      moveuser=@battle.battlers[indexx] if @battle.battlers[indexx].pokemonIndex == @effects[:FutureSightPokemonIndex]
    end
    #if battler not on the field, make a fake one
    if moveuser.nil?
      moveuser=PokeBattle_Battler.new(@battle,@effects[:FutureSightUser],true)
      begin
        moveuser.pbInitPokemon(@battle.pbParty(@effects[:FutureSightUser])[@effects[:FutureSightPokemonIndex]],@effects[:FutureSightUser])
      rescue
        moveuser.pbInitPokemon(@battle.pbParty(@effects[:FutureSightUser]^1)[@effects[:FutureSightPokemonIndex]],@effects[:FutureSightUser])
      end
      disabled_items = {:item => moveuser.item.clone, :ability => moveuser.ability.clone}
      moveuser.item=nil
      moveuser.ability=nil
      
    end
    if @effects[:FutureSightMove] == :DOOMDESIRE
      move=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(:DOOMDUMMY),moveuser)
    elsif @effects[:FutureSightMove] == :FUTURESIGHT
      move=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(:FUTUREDUMMY),moveuser)
    elsif @effects[:FutureSightMove] == :HEX
      move=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(:HEXDUMMY),moveuser)
    end
    return move, moveuser, disabled_items
  end

################################################################################
# Move PP
################################################################################
  def pbSetPP(move,pp)
    move.pp=pp
    #Not effects[:Mimic], since Mimic can't copy Mimic
    if move.basemove && move.move==move.basemove.move && !@effects[:Transform]
      move.basemove.pp=pp
    end
  end

  def pbReducePP(move)
    #TODO: Pressure
    if @effects[:TwoTurnAttack]!=0 ||
       @effects[:Bide]>0 ||
       @effects[:Outrage]>0 ||
       @effects[:Rollout]>0 ||
       @effects[:HyperBeam]>0 ||
       @effects[:Uproar]>0
      # No need to reduce PP if two-turn attack
      return true
    end
    return true if move.pp<0   # No need to reduce PP for special calls of moves
    return true if move.totalpp==0   # Infinite PP, can always be used
    return false if move.pp==0
    if move.pp>0
      pbSetPP(move,move.pp-1)
    end
    return true
  end

  def pbReducePPOther(move)
    pbSetPP(move,move.pp-1) if move.pp>0
  end

################################################################################
# Using a move
################################################################################
  def pbObedienceCheck?(choice)
    return true if $DEBUG && $INTERNAL
    return true if @battle.isOnline?
    return true if choice[0]!=1
    return true if self.pokemon.obedient
    if @battle.pbOwnedByPlayer?(@index) && @battle.internalbattle
      badgelevel= (@battle.pbPlayer.numbadges >= 0 && @battle.pbPlayer.numbadges < LEVELCAPS.length) ? LEVELCAPS[@battle.pbPlayer.numbadges] : LEVELCAPS[0]
      move=choice[2]
      disobedient=false
      a=((@level+badgelevel)*@battle.pbRandom(256)/255.0).floor
      disobedient|=a<badgelevel if !(Rejuv && $game_switches[:NotPlayerCharacter])
      if self.respond_to?("pbHyperModeObedience")
        disobedient|=!self.pbHyperModeObedience(move)
      end
      if disobedient
        @effects[:Rage]=false
        if self.status== :SLEEP &&
           (move.function==0x11 || move.function==0xB4) # Snore, Sleep Talk
          @battle.pbDisplay(_INTL("{1} ignored orders while asleep!",pbThis))
          return false
        end
        b=((@level+badgelevel)*@battle.pbRandom(256)/255.0).floor
        #if b<badgelevel
        #  return false if !@battle.pbCanShowFightMenu?(@index)
        #  othermoves=[]
        #  for i in 0...4
        #    next if i==choice[1]
        #    othermoves[othermoves.length]=i if @battle.pbCanChooseMove?(@index,i,false)
        #  end
        #  if othermoves.length>0
        #    @battle.pbDisplay(_INTL("{1} ignored orders!",pbThis))
        #    newchoice=othermoves[@battle.pbRandom(othermoves.length)]
        #    choice[1]=newchoice
        #    choice[2]=@moves[newchoice]
        #    choice[3]=-1
        #  end
        #  return true
        #elsif self.status!=:SLEEP
        if self.status!=:SLEEP
          c=@level-b
          r=@battle.pbRandom(256)
          if r<c && pbCanSleep?(false,true)
            pbSleepSelf()
            @battle.pbDisplay(_INTL("{1} took a nap!",pbThis))
            return false
          end
          r-=c
          if r<c
            @battle.pbDisplay(_INTL("{1} won't obey!",pbThis))
            @battle.pbDisplay(_INTL("It hurt itself from its confusion!"))
            pbConfusionDamage
          else
            message=@battle.pbRandom(4)
            @battle.pbDisplay(_INTL("{1} ignored orders!",pbThis)) if message==0
            @battle.pbDisplay(_INTL("{1} turned away!",pbThis)) if message==1
            @battle.pbDisplay(_INTL("{1} is loafing around!",pbThis)) if message==2
            @battle.pbDisplay(_INTL("{1} pretended not to notice!",pbThis)) if message==3
          end
          return false
        end
      end
      return true
    else
      return true
    end
  end

  def pbSuccessCheck(basemove,user,target,flags,accuracy=true)
    targetchoices=pbTarget(basemove)
    if user.ability == (:PRANKSTER) && (!(basemove.pbIsPhysical?(basemove.type) || basemove.pbIsSpecial?(basemove.type)) || (!basemove.zmove && !flags[:instructed] && @battle.choices[user.index][2]!=basemove))
      if target.hasType?(:DARK) && @battle.FE != :BEWITCHED
        @battle.pbDisplay(_INTL("{1} wasn't affected!",target.pbThis))
        return false
      end
    end
    if ((((target.ability == :DAZZLING || target.ability == :QUEENLYMAJESTY || (@battle.FE == :STARLIGHT && target.ability == :MIRRORARMOR)) || 
      (target.pbPartner.ability == :DAZZLING || target.pbPartner.ability == :QUEENLYMAJESTY || (@battle.FE == :STARLIGHT && target.pbPartner.ability == :MIRRORARMOR))) && !target.moldbroken) ||
      @battle.FE == :PSYTERRAIN && !target.isAirborne?) && target.pbPartner!=user
      if (basemove.priorityCheck(user) > 0) || (user.ability == (:PRANKSTER) && !basemove.zmove && !flags[:instructed] && @battle.choices[user.index][2]!=basemove)
        @battle.pbDisplay(_INTL("{1} wasn't affected!",target.pbThis))
        return false
      end
    end

    if user.effects[:TwoTurnAttack]!=0
      PBDebug.log("[Using two-turn attack]") if $INTERNAL
      return true
    end
    # TODO: "Before Protect" applies to Counter/Mirror Coat
    if basemove.function==0xDE && ((target.status!=:SLEEP && (target.ability != (:COMATOSE) || @battle.FE == :ELECTERRAIN) && user.ability!=:WORLDOFNIGHTMARES) || user.effects[:HealBlock]!=0)  # Dream Eater
      @battle.pbDisplay(_INTL("{1} wasn't affected!",target.pbThis))
      return false
    end
    if Rejuv && @battle.FE == :CHESS && user.ability == :KLUTZ && CHESSMOVES.include?(basemove.move)
      @battle.pbDisplay(_INTL("It was too much of a klutz to move the chess piece.",target.pbThis))  
      return false  
    end
    if (basemove.function==0xDD || basemove.function==0x139 || basemove.function==0x158) && (user.effects[:HealBlock]!=0) # Absorbtion Moves
      @battle.pbDisplay(_INTL("{1} wasn't affected!",target.pbThis))
      return false
    end
    if basemove.function==0x113 && user.effects[:Stockpile]==0 # Spit Up
      @battle.pbDisplay(_INTL("But it failed to spit up a thing!"))
      return false
    end
    # Move failure caused by field effects:
    if basemove.typeFieldBoost(basemove.pbType(user),user,target)==0
      @battle.pbDisplay(_INTL(basemove.typeFieldMessage(basemove.pbType(user)))) if !basemove.fieldmessageshown_type
      basemove.fieldmessageshown_type = true
      user.pbCancelMoves
      return false
    end
    if basemove.moveFieldBoost==0
      @battle.pbDisplay(_INTL(basemove.moveFieldMessage)) if !basemove.fieldmessageshown
      basemove.fieldmessageshown = true
      user.pbCancelMoves
      return false
    end
    if !basemove.zmove # Z-Moves handle protection stuff elsewhere
      if target.pbOwnSide.effects[:MatBlock] && ((basemove.move == :PHANTOMFORCE) || (basemove.move == :SHADOWFORCE) ||
          (basemove.move == :HYPERSPACEHOLE) || (basemove.move == :HYPERSPACEFURY))
            @battle.pbDisplay(_INTL("The Mat Block was broken!"))
      end

      unseenfist = (user.ability == :UNSEENFIST && basemove.contactMove?)

      if target.pbOwnSide.effects[:MatBlock] && (basemove.pbIsPhysical?(basemove.type) || basemove.pbIsSpecial?(basemove.type)) &&
        basemove.canProtect? && !target.effects[:ProtectNegation] && !unseenfist
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        return false
      end

      if target.pbOwnSide.effects[:CraftyShield] && basemove.basedamage == 0 && !target.effects[:ProtectNegation]
        @battle.pbDisplay(_INTL("{1}'s Crafty Shield activated!",target.pbThis))
        user.pbCancelMoves
        return false
      end

      if target.pbOwnSide.effects[:WideGuard] && (targetchoices == :AllOpposing ||
        targetchoices == :AllNonUsers) && basemove.basedamage > 0 && basemove.canProtect? && !target.effects[:ProtectNegation] && !unseenfist
        if !target.pbPartner.effects[:WideGuardCheck]
          if target.effects[:WideGuardUser]
            @battle.pbDisplay(_INTL("{1}'s Wide Guard prevented damage!",target.pbThis))
            user.pbCancelMoves
          elsif target.pbPartner.effects[:WideGuardUser]
            @battle.pbDisplay(_INTL("{1}'s Wide Guard prevented damage!",target.pbPartner.pbThis))
            user.pbCancelMoves
          end
          target.effects[:WideGuardCheck]=true
        else
          target.pbPartner.effects[:WideGuardCheck]=false
          user.pbCancelMoves
        end
        return false
      end
      if target.pbOwnSide.effects[:QuickGuard] && (basemove.priorityCheck(user) > 0) && basemove.canProtect? && !target.effects[:ProtectNegation] && !unseenfist
        @battle.pbDisplay(_INTL("{1}'s Quick Guard prevented damage!",target.pbThis))
        user.pbCancelMoves
        return false
      end
      # Protect / King's Shield / Obstruct / Spiky Shield / Baneful Bunker
      if !target.effects[:ProtectNegation] && !unseenfist && basemove.canProtect? && basemove.function!=0x116 &&
        ((target.effects[:Protect] == :KingsShield && (basemove.basedamage > 0 || @battle.FE == :FAIRYTALE || @battle.FE == :CHESS)) || target.effects[:Protect] == :Protect ||
        (target.effects[:Protect] == :Obstruct && (basemove.basedamage > 0 || @battle.FE == :DIMENSIONAL || @battle.FE == :CHESS)) || target.effects[:Protect] == :SpikyShield || target.effects[:Protect] == :BanefulBunker)
        @battle.pbDisplay(_INTL("{1} protected itself!", target.pbThis))
        # physical contact
        if basemove.contactMove? && !(user.ability == :LONGREACH)
          if target.effects[:Protect] == :KingsShield
            if Rejuv
              user.pbReduceStat(PBStats::ATTACK,2)
              user.pbReduceStat(PBStats::SPATK,2) if @battle.FE == :FAIRYTALE || @battle.FE == :CHESS || @battle.FE == :COLOSSEUM
            else
              user.pbReduceStat(PBStats::ATTACK,1)
              user.pbReduceStat(PBStats::SPATK,1) if @battle.FE == :FAIRYTALE || @battle.FE == :CHESS || @battle.FE == :COLOSSEUM
            end
          elsif target.effects[:Protect] == :Obstruct
            user.pbReduceStat(PBStats::DEFENSE,2)
          elsif target.effects[:Protect] == :SpikyShield
            if @battle.FE == :COLOSSEUM
              user.pbReduceHP((user.totalhp/4.0).floor)  
            else  
              user.pbReduceHP((user.totalhp/8.0).floor) 
            end
            @battle.pbDisplay(_INTL("{1}'s Spiky Shield hurt {2}!",target.pbThis,user.pbThis(true)))
          elsif target.effects[:Protect] == :BanefulBunker && user.pbCanPoison?(false)
            user.pbPoison(target)
            @battle.pbDisplay(_INTL("{1}'s Baneful Bunker poisoned {2}!",target.pbThis,user.pbThis(true)))
          end
        end
        return false
      end
    end
    # TODO: Mind Reader/Lock-On
    # --Sketch/FutureSight/PsychUp work even on Fly/Bounce/Dive/Dig
    if basemove.pbMoveFailed(user,target) # TODO: Applies to Snore/Fake Out
      @battle.pbDisplay(_INTL("But it failed!"))
      return false
    end
    if accuracy
      if target.effects[:LockOn]>0 && target.effects[:LockOnPos]==user.index
        return true
      end
      invulmiss=false
      invulmove=$cache.moves[target.effects[:TwoTurnAttack]].function if target.effects[:TwoTurnAttack] != 0 rescue nil
      case invulmove
        when 0xC9, 0xCC # Fly, Bounce
          invulmiss=true unless PBStuff::AIRHITMOVES.include?(basemove.move) || (basemove.function==0x10D && !user.hasType?(:GHOST)) || (basemove.move == :WHIRLWIND)
        when 0xCA # Dig
          (invulmiss=true) unless basemove.function==0x76 || basemove.function==0x95 || (basemove.function==0x10D && !user.hasType?(:GHOST)) # Curse
        when 0xCB # Dive
          (invulmiss=true) unless basemove.function==0x75 || basemove.function==0xD0 || (basemove.function==0x10D && !user.hasType?(:GHOST)) # Curse
        when 0xCD # Shadow Force
          (invulmiss=true)
        when 0xCE # Sky Drop
          invulmiss=true unless PBStuff::AIRHITMOVES.include?(basemove.move) || (basemove.function==0x10D && !user.hasType?(:GHOST))
      end
      if target.effects[:SkyDrop]
        invulmiss=true unless basemove.function==0xCE || PBStuff::AIRHITMOVES.include?(basemove.move) || (basemove.function==0x10D && !user.hasType?(:GHOST))
      end
      if user.ability == (:NOGUARD) || target.ability == (:NOGUARD) || (user.ability == (:FAIRYAURA) && @battle.FE==:FAIRYTALE)
        invulmiss=false
      end
      if invulmiss
        if targetchoices==:AllOpposing && (!user.pbOpposing1.isFainted? ? 1 : 0) + (!user.pbOpposing2.isFainted? ? 1 : 0) > 1
          # All opposing Pokémon
          @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis))
        elsif targetchoices==:AllNonUsers &&
           (!user.pbOpposing1.isFainted? ? 1 : 0) + (!user.pbOpposing2.isFainted? ? 1 : 0) + (!user.pbPartner.isFainted? ? 1 : 0) > 1
          # All non-users
          @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis))
        elsif basemove.function==0xDC # Leech Seed
          @battle.pbDisplay(_INTL("{1} evaded the attack!",target.pbThis))          
        elsif basemove.function==0x70 && (((target.ability == (:STURDY) && !target.moldbroken) || user.level < target.level) || target.pokemon.piece==:PAWN && @battle.FE==:CHESS)
          @battle.pbDisplay(_INTL("{1} is unaffected!",target.pbThis))
        elsif basemove.function==0x70 && !((target.ability == (:STURDY)) || (user.level<target.level))
          @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis))
        else
          @battle.pbDisplay(_INTL("{1}'s attack missed!",user.pbThis))
        end
        user.missAcc = true
        return false
      end
    end
    if basemove.move==:THUNDERWAVE && basemove.pbTypeModMessages(basemove.type,user,target)==0
      return false
    end
    #if damage dealing move
    if basemove.basedamage>0 && basemove.function!=0x02 && basemove.function!=0x111 # Struggle / Future Sight
      type=basemove.pbType(user)
      typemod=basemove.pbTypeModifier(type,user,target)
      typemod=basemove.fieldTypeChange(user,target,typemod)
      typemod=basemove.overlayTypeChange(user,target,typemod)
      if (type == :GROUND) && target.isAirborne? && !target.hasWorkingItem(:RINGTARGET) && @battle.FE != :CAVE && basemove.move != :THOUSANDARROWS && basemove.move != :DESERTSMARK
        if ([:LEVITATE,:SOLARIDOL,:LUNARIDOL].include?(target.ability) || (@battle.FE == :DEEPEARTH && [:UNAWARE,:OBLIVIOUS,:MAGNETPULL,:CONTRARY].include?(target.ability))) && !(target.moldbroken)
          @battle.pbDisplay(_INTL("{1} makes Ground moves miss with {2}!",target.pbThis,getAbilityName(target.ability)))
          return false
        end
        if target.hasWorkingItem(:AIRBALLOON)
          @battle.pbDisplay(_INTL("{1}'s Air Balloon makes Ground moves miss!",target.pbThis))
          return false
        end
        if target.effects[:MagnetRise]>0
          @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Magnet Rise!",target.pbThis))
          return false
        end
        if target.effects[:Telekinesis]>0
          @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Telekinesis!",target.pbThis))
          return false
        end
      end
      if target.ability == (:WONDERGUARD) && typemod<=4 && !(target.moldbroken)
        @battle.pbDisplay(_INTL("{1} avoided damage with Wonder Guard!",target.pbThis))
        return false
      end
      if typemod==0 && !basemove.function==0x111 #Future Sight/Doom Desire
        @battle.pbDisplay(_INTL("It doesn't affect\r\n{1}...",target.pbThis(true)))
        return false
      end
      if typemod==0 && (basemove.function==0x10B || basemove.function==0x506) # (Hi) Jump Kick
        @battle.pbDisplay(_INTL("It doesn't affect\r\n{1}...",target.pbThis(true)))
        return false
      end
    end
    if basemove.basedamage==0 #Status move type absorb abilities
      type=basemove.pbType(user)
      if basemove.pbStatusMoveAbsorption(type,user,target)==0
        return false
      end
    end
    if accuracy
      if target.effects[:LockOn]>0 && target.effects[:LockOnPos]==user.index
        return true
      end
      if !basemove.pbAccuracyCheck(user,target) # Includes Counter/Mirror Coat
        if targetchoices==:AllOpposing && (!user.pbOpposing1.isFainted? ? 1 : 0) + (!user.pbOpposing2.isFainted? ? 1 : 0) > 1
          # All opposing Pokémon
          @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis))
        elsif targetchoices==:AllNonUsers && (!user.pbOpposing1.isFainted? ? 1 : 0) + (!user.pbOpposing2.isFainted? ? 1 : 0) + (!user.pbPartner.isFainted? ? 1 : 0) > 1
          # All non-users
          @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis))
        elsif basemove.function==0xDC # Leech Seed
          @battle.pbDisplay(_INTL("{1} evaded the attack!",target.pbThis))
        elsif basemove.function==0x70 && (((target.ability == (:STURDY) && !target.moldbroken) || user.level < target.level) || @battle.FE==:CHESS && target.pokemon.piece==:PAWN)
          @battle.pbDisplay(_INTL("{1} is unaffected!",target.pbThis))
        elsif basemove.function==0x70 && !((target.ability == (:STURDY)) || (user.level<target.level))
          @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis))
        else
          @battle.pbDisplay(_INTL("{1}'s attack missed!",user.pbThis))
          if user.effects[:SkyDroppee]!=nil
            target.effects[:SkyDrop]=false
            user.effects[:SkyDroppee] = nil
            @battle.scene.pbUnVanishSprite(target)
            @battle.pbDisplay(_INTL("{1} is freed from the Sky Drop effect!",target.pbThis))
          end
          if @battle.FE == :MIRROR && basemove.basedamage>0 && (targetchoices==:SingleNonUser || basemove.move == :MIRRORCOAT) && 
           !basemove.contactMove? && basemove.pbIsSpecial?(type) && target.stages[PBStats::EVASION]>0
            @battle.pbDisplay(_INTL("The attack was reflected by the mirror!",user.pbThis))
            @battle.field.counter = 1
            return true
          end
        end
        return false
      end
    end
    return true
  end

  def pbTryUseMove(choice,basemove,flags={passedtrying: false, instructed: false})
    return true if flags[:passedtrying]
    # TODO: Return true if attack has been Mirror Coated once already
    return false if !pbObedienceCheck?(choice)
    return false if self.forcedSwitchEarlier
    if self.crested == :VESPIQUEN
      changed=false
      if basemove.basedamage==0 && @effects[:VespiCrest] == true
        @effects[:VespiCrest]  = false
        self.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false,statdropper:self)
        self.pbReduceStat(PBStats::SPATK,1,abilitymessage:false,statdropper:self)
        self.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
        self.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
        @battle.pbDisplay(_INTL("{1} switched to Defense Stance!",pbThis))
      elsif basemove.basedamage>0 && @effects[:VespiCrest] == false
        @effects[:VespiCrest]  = true
        self.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false,statdropper:self)
        self.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false,statdropper:self)
        self.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
        self.pbIncreaseStat(PBStats::SPATK,1,abilitymessage:false)
        @battle.pbDisplay(_INTL("{1} switched to Attack Stance!",pbThis))
      end
    end
     # Stance Change moved from here to end of method to match Gen VII mechanics.
    # TODO: If being Sky Dropped, return false
    # TODO: Gravity prevents airborne-based moves here
    if @effects[:Taunt]>0 && basemove.betterCategory(basemove.type) == :status && !choice[2].zmove
      @battle.pbDisplay(_INTL("{1} can't use {2} after the taunt!", pbThis,basemove.name))
      return false
    end
    if @effects[:HealBlock]>0 && basemove.isHealingMove? && !choice[2].zmove
      @battle.pbDisplay(_INTL("{1} can't use {2} after the Heal Block!", pbThis,basemove.name))
      return false
    end
    if basemove.isSoundBased? && self.effects[:ThroatChop]>0
      @battle.pbDisplay(_INTL("{1} can't use sound-based moves because of it's throat damage!",pbThis))
      return false
    end
    if @effects[:Torment] && !flags[:instructed] && basemove.move==@lastMoveUsed && basemove.move!=@battle.struggle.move && !choice[2].zmove
      @battle.pbDisplay(_INTL("{1} can't use the same move in a row due to the torment!", pbThis))
      return false
    end
    if basemove.hasFlag?(:heavymove) && !flags[:instructed] && basemove.move==@lastMoveUsed && basemove.move!=@battle.struggle.move && !choice[2].zmove
      pbDisplayPaused(_INTL("{1} can't use {2} twice in a row!",thispkmn.pbThis,basemove.name))
      return false
    end
    if pbOpposing1.effects[:Imprison] && !@simplemove && !choice[2].zmove
      if basemove.move==pbOpposing1.moves[0].move || basemove.move==pbOpposing1.moves[1].move || basemove.move==pbOpposing1.moves[2].move || basemove.move==pbOpposing1.moves[3].move
        @battle.pbDisplay(_INTL("{1} can't use the sealed {2}!",
           pbThis,basemove.name))
        PBDebug.log("[#{pbOpposing1.pbThis} has: #{pbOpposing1.moves[0].move}, #{pbOpposing1.moves[1].move},#{pbOpposing1.moves[2].move} #{pbOpposing1.moves[3].move}]") if $INTERNAL
        return false
      end
    end
    if pbOpposing2.effects[:Imprison] && !@simplemove && !choice[2].zmove
      if basemove.move==pbOpposing2.moves[0].move || basemove.move==pbOpposing2.moves[1].move || basemove.move==pbOpposing2.moves[2].move || basemove.move==pbOpposing2.moves[3].move
        @battle.pbDisplay(_INTL("{1} can't use the sealed {2}!", pbThis,basemove.name))
        PBDebug.log("[#{pbOpposing2.pbThis} has: #{pbOpposing2.moves[0].move}, #{pbOpposing2.moves[1].move},#{pbOpposing2.moves[2].move} #{pbOpposing2.moves[3].move}]") if $INTERNAL
        return false
      end
    end
    if @effects[:Disable]>0 && basemove.move==@effects[:DisableMove] && !choice[2].zmove
      @battle.pbDisplayPaused(_INTL("{1}'s {2} is disabled!",pbThis,basemove.name))
      return false
    end
    if self.ability == :TRUANT && @effects[:Truant]
      @battle.pbDisplay(_INTL("{1} is loafing around!",pbThis))
      return false
    end
    if choice[1]==-2 # Battle Palace
      @battle.pbDisplay(_INTL("{1} appears incapable of using its power!",pbThis))
      return false
    end
    if @effects[:HyperBeam]>0
      @battle.pbDisplay(_INTL("{1} must recharge!",pbThis))
      return false
    end
    if self.status== :SLEEP && !@simplemove
      self.statusCount-=1
      self.statusCount-=1 if self.ability == :EARLYBIRD
      if self.statusCount<=0
        self.pbCureStatus
      else
        self.pbContinueStatus
        if !basemove.pbCanUseWhileAsleep? # Snore/Sleep Talk
          return false
        end
      end
    end
    if self.status== :FROZEN
      if basemove.canThawUser?
        self.pbCureStatus(false)
        @battle.pbDisplay(_INTL("{1} was defrosted by {2}!",pbThis,basemove.name))
        pbCheckForm
      elsif @battle.pbRandom(10)<2
        self.pbCureStatus
        pbCheckForm
      elsif !basemove.canThawUser?
        self.pbContinueStatus
        return false
      end
    end

    if @effects[:Flinch] && !@simplemove
      @effects[:Flinch]=false
      if self.isbossmon
        if self.chargeAttack
          self.chargeAttack[:canIntermediateAttack] = false
        end
      end
      if @battle.FE == :ROCKY
        if !(self.ability == :STEADFAST) && !(self.ability == :STURDY) && !(self.ability == :INNERFOCUS) && (self.stages[PBStats::DEFENSE] < 1)
          @battle.pbDisplay(_INTL("{1} was knocked into a rock!",pbThis))
          damage=[1,(self.totalhp/4.0).floor].max
          if damage>0
            @battle.scene.pbDamageAnimation(self,0)
            self.pbReduceHP(damage)
          end
          if self.hp<=0
            self.pbFaint
            return false
          end
        end
      end
      if self.ability == :INNERFOCUS
        @battle.pbDisplay(_INTL("{1} won't flinch because of its {2}!", self.pbThis,getAbilityName(self.ability)))
      elsif self.stages[PBStats::DEFENSE] >= 1 && @battle.FE == :ROCKY
        @battle.pbDisplay(_INTL("{1} won't flinch because of its bolstered Defenses!", self.pbThis,getAbilityName(self.ability)))
      else
        @battle.pbDisplay(_INTL("{1} flinched and couldn't move!",self.pbThis))
        if self.ability == :STEADFAST
          if pbCanIncreaseStatStage?(PBStats::SPEED)
            pbIncreaseStat(PBStats::SPEED,1,statmessage: false)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its speed!", self.pbThis,getAbilityName(self.ability)))
          end
        end
        return false
      end
    end

    if @effects[:Confusion]>0 && !@simplemove
      @effects[:Confusion]-=1
      if @effects[:Confusion]<=0
        pbCureConfusion
      else
        pbContinueConfusion
        if @battle.pbRandom(3)==0
          @battle.pbDisplay(_INTL("It hurt itself from its confusion!"))
          pbConfusionDamage
          if self.isbossmon
            if self.chargeAttack
              self.chargeAttack[:canIntermediateAttack] = false
            end
          end
          return false
        end
      end
    end

    if @effects[:Attract]>=0 && !@simplemove && !basemove.zmove
      pbAnnounceAttract(@battle.battlers[@effects[:Attract]])
      if @battle.pbRandom(2)==0
        pbContinueAttract
        if self.isbossmon
          if self.chargeAttack
            self.chargeAttack[:canIntermediateAttack] = false
          end
        end
        return false
      end
    end
    if self.status== :PARALYSIS && !@simplemove && !basemove.zmove
      if @battle.pbRandom(4)==0
        pbContinueStatus
        pbCancelMoves
        return false
      end
    end
    if self.isbossmon
      if self.chargeAttack
        chargeAttack = self.chargeAttack
        if chargeAttack[:canAttack]==false
          if chargeAttack[:intermediateattack][:name] != basemove.name
            if chargeAttack[:chargingMessage]
              if chargeAttack[:chargingMessage].include?("{1}") 
                @battle.pbDisplay(_INTL(chargeAttack[:chargingMessage],pbThis))
              else
                @battle.pbDisplay(_INTL(chargeAttack[:chargingMessage]))
              end
            else
              @battle.pbDisplay(_INTL("{1} is biding its time...",pbThis))
            end
            return false
          end 
        end
        @battle.pbDisplay(_INTL("{1} turns remaining.",(chargeAttack[:turns]-@turncount))) 
      end
    end
    # UPDATE 2/13/2014
    # implementing Protean
    protype=basemove.pbType(self,basemove.type)
    if (self.ability == :PROTEAN || self.ability == :LIBERO) && basemove.move != :STRUGGLE
      prot1 = self.type1
      prot2 = self.type2
      if !self.hasType?(protype) || (!prot2.nil? && prot1 != prot2)
        self.type1=protype
        self.type2=nil
        @battle.pbDisplay(_INTL("{1} had its type changed to {3}!",pbThis,getAbilityName(self.ability),protype.capitalize))
      end
    end # end of update
    if (self.ability == :STANCECHANGE)
      pbCheckForm(basemove)
    end
    flags[:passedtrying]=true
    return true
  end

  def pbConfusionDamage
    self.damagestate.reset
    confmove=PokeBattle_Confusion.new(@battle,nil)
    confmove.pbEffect(self,self)
    pbFaint if self.isFainted?
  end

  def pbProcessMoveAgainstTarget(basemove,user,target,numhits,flags={totaldamage: 0},nocheck=false,alltargets=nil,showanimation=true)
    realnumhits=0
    flags[:totaldamage] = 0 if !flags[:totaldamage]
    totaldamage=flags[:totaldamage]
    destinybond=false
    wimpcheck=false
    berserkcheck=false
    angershellcheck=false
    if target
      aboveHalfHp = target.hp>(target.totalhp/2.0).floor
    end
    for i in 0...numhits
      if user.status== :SLEEP && !basemove.pbCanUseWhileAsleep? && !@simplemove
        realnumhits = i
        break
      end
      if target
        innardsOutHp = target.hp
      end
      if !target
        tantrumCheck = basemove.pbEffect(user,target,i,alltargets,showanimation)
        user.effects[:Tantrum]=(tantrumCheck == -1)
        return
      end
      if (target.isbossmon)
        bosscheck = bossMoveCheck(basemove,user,target) 
        return if bosscheck == 0
      end
      # Check success (accuracy/evasion calculation)
      if !nocheck && !pbSuccessCheck(basemove,user,target,flags,i==0 || basemove.function==0xBF) # Triple Kick
       if (0xC9...0xCE).to_a.include?(basemove.function)
          @battle.scene.pbUnVanishSprite(user)
        end
        if basemove.function==0xBF && realnumhits>0   # Triple Kick
          break   # Considered a success if Triple Kick hits at least once
        elsif basemove.function==0x10B || basemove.function==0x506   # Hi Jump Kick, Jump Kick, Axe Kick
          #TODO: Not shown if message is "It doesn't affect XXX..."
          @battle.pbDisplay(_INTL("{1} kept going and crashed!",user.pbThis))
          damage=[1,(user.totalhp/2.0).floor].max
          if (user.ability == :MAGICGUARD) || (self.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM)
            damage=0
          end
          if damage>0
            @battle.scene.pbDamageAnimation(user,0)
            user.pbReduceHP(damage)
          end
          user.pbFaint if user.isFainted?
          # Rocky Field Crash
        elsif @battle.FE == :ROCKY && basemove.contactMove? && !(user.ability == :ROCKHEAD) && (!target.effects[:Protect])
          @battle.pbDisplay(_INTL("{1} hit a rock instead!",user.pbThis))
          damage=[1,(user.totalhp/8.0).floor].max
          damage=[1,(user.totalhp/4.0).floor].max if user.ability == :GORILLATACTICS
          if !damage.nil? && damage>0
            @battle.scene.pbDamageAnimation(user,0)
            user.pbReduceHP(damage)
          end
          user.pbFaint if user.isFainted?
        elsif @battle.FE == :MIRROR && basemove.contactMove?
          @battle.pbDisplay(_INTL("{1} hit a mirror instead!",user.pbThis))
          @battle.pbDisplay(_INTL("The mirror shattered!",user.pbThis))
          damage=[1,(user.totalhp/4.0).floor].max
          if damage>0
            @battle.scene.pbDamageAnimation(user,0)
            user.pbReduceHP(damage)
          end
          user.pbFaint if user.isFainted?
          user.pbReduceStat(PBStats::EVASION,1) if user.stages[PBStats::EVASION] > 0
        end
        if user.hasWorkingItem(:BLUNDERPOLICY) && user.missAcc
          if user.pbCanIncreaseStatStage?(PBStats::SPEED)
            user.pbIncreaseStatBasic(PBStats::SPEED,1)
            @battle.pbCommonAnimation("StatUp",user)
            @battle.pbDisplay(_INTL("The Blunder Policy raised #{user.pbThis}'s Speed!"))
            user.pbDisposeItem(false)
          end
        end
        if @battle.ProgressiveFieldCheck(PBFields::CONCERT) && user.missAcc
          @battle.reduceField
        end
        user.effects[:Tantrum]=true
        user.effects[:Outrage]=0 if basemove.function==0xD2 # Outrage
        user.effects[:Rollout]=0 if basemove.function==0xD3 # Rollout
        user.effects[:FuryCutter]=0 if basemove.function==0x91 # Fury Cutter
        user.effects[:EchoedVoice]+=1 if basemove.function==0x92 # Echoed Voice
        user.effects[:EchoedVoice]=0 if basemove.function!=0x92 # Not Echoed Voice
        user.effects[:Stockpile]=0 if basemove.function==0x113 # Spit Up
        return 0
      end
      if basemove.function==0x91 # Fury Cutter
        user.effects[:FuryCutter]+=1 if user.effects[:FuryCutter]<3
      else
        user.effects[:FuryCutter]=0
      end
      if basemove.function==0x92 # Echoed Voice
        user.effects[:EchoedVoice]+=1 if user.effects[:EchoedVoice]<5
      else
        user.effects[:EchoedVoice]=0
      end
      # This hit will happen; count it
      realnumhits+=1
      # Damage calculation and/or main effect
      revanish=false
      if target.vanished && !((basemove.function==0xC9 || basemove.function==0xCA || basemove.function==0xCB ||
          basemove.function==0xCC || basemove.function==0xCD) && !user.vanished)
        revanish=true
        revanish=false if basemove.function==0xCE
        revanish=false if basemove.function==0x11C
        revanish=false if (basemove.function==0x10D && !user.hasType?(:GHOST)) # Curse
        @battle.scene.pbUnVanishSprite(target) unless ((basemove.function==0x10D && !user.hasType?(:GHOST)) || basemove.function==0xCE) # Curse
      end
      # Special Move Effects are applied here
      damage = basemove.pbEffect(user,target,i,alltargets,showanimation)
      # Bastiodon Crest
      if target.crested == :BASTIODON
        if target.damagestate.calcdamage>0 && !target.damagestate.substitute &&
          user.ability != (:MAGICGUARD) && !(user.ability == (:WONDERGUARD) && @battle.FE == :COLOSSEUM)
          user.pbReduceHP([1,((target.damagestate.hplost)/2).floor].max)
          target.pbRecoverHP([1,((target.damagestate.hplost)/2).floor].max) if !target.isFainted?
          @battle.pbDisplay(_INTL("{1}'s crest causes {2} to take recoil damage and {3} to recover!",
              target.pbThis,user.pbThis(true),target.pbThis))
          
        end
      end
      user.effects[:Tantrum]= (damage == -1)
      totaldamage += damage if damage && damage > 0
      if target.isbossmon
        target.immunities[:moves].push(basemove.move) if basemove.function == 0x070 # OHKO moves
      end
      if user.isFainted?
        user.pbFaint # no return
      end
      if revanish && !(target.isFainted?)
        @battle.pbCommonAnimation("Fade out",target,nil)
        @battle.scene.pbVanishSprite(target)
      end
      if numhits>1 && target.damagestate.calcdamage<=0
        unless basemove.move == :ROCKBLAST && @battle.FE == :CRYSTALCAVERN
          return
        end
      end
      @battle.pbJudgeCheckpoint(user,basemove)

      # Additional effect
      if !basemove.zmove && target.damagestate.calcdamage>0 && ((target.ability != (:SHIELDDUST) || target.moldbroken || [0x1C,0x1D,0x1E,0x1F,0x20,0x2D,0x2F,0x147,0x186,0x307].include?(basemove.function))) && user.ability != (:SHEERFORCE)
        addleffect=basemove.effect
        addleffect=20 if basemove.move == :OMINOUSWIND && @battle.FE == :HAUNTED
        addleffect*=2 if user.ability == (:SERENEGRACE) || @battle.FE == :RAINBOW
        addleffect=100 if $DEBUG && Input.press?(Input::CTRL) && !@battle.isOnline?
        addleffect=100 if basemove.move == :MIRRORSHOT && @battle.FE == :MIRROR
        addleffect=100 if basemove.move == :STRANGESTEAM && @battle.FE == :FAIRYTALE
        addleffect=100 if basemove.move == :LICK && @battle.FE == :HAUNTED
        addleffect=100 if basemove.move == :DIRECLAW && @battle.FE == :WASTELAND
        addleffect=100 if basemove.move == :INFERNALPARADE && @battle.FE == :INFERNAL
        addleffect=0 if (user.crested == :LEDIAN && i>1) || (user.crested == :CINCCINO && i>1)
        if @battle.pbRandom(100)<addleffect
          basemove.pbAdditionalEffect(user,target)
        end
        addleffect=basemove.moreeffect
        addleffect*=2 if user.ability == (:SERENEGRACE) || @battle.FE == :RAINBOW
        addleffect=100 if $DEBUG && Input.press?(Input::CTRL) && !@battle.isOnline?
        addleffect=0 if (user.crested == :LEDIAN && i>1) || (user.crested == :CINCCINO && i>1)
        if @battle.pbRandom(100)<addleffect
          basemove.pbSecondAdditionalEffect(user,target)
        end

        # Gulp Missile
        if (self.species == :CRAMORANT) && self.ability == :GULPMISSILE && !self.isFainted? && (basemove.move == :SURF || basemove.move == :DIVE) # Surf or Dive
          if self.form==0
            if @battle.FE == :SWAMP || @battle.FE == :WATERSURFACE || @battle.FE == :UNDERWATER
              self.form = 1 # Gulping Form
            elsif @battle.FE == :ELECTERRAIN || @battle.FE == :FACTORY || @battle.FE == :SHORTCIRCUIT
              self.form = 2 # Gorging Form
            elsif self.hp*2.0 > self.totalhp
              self.form = 1 # Gulping Form
            else
              self.form = 2 # Gorging Form
            end
          end
          transformed = true
          pbUpdate(false)
          @battle.scene.pbChangePokemon(self,@pokemon)
          if self.form==1
            @battle.pbDisplay(_INTL("{1} transformed into Gulping Forme!",pbThis))
          elsif self.form==2
            @battle.pbDisplay(_INTL("{1} transformed into Gorging Forme!",pbThis))
          end
        end
      end

      # Corrosion random status
      if user.ability == :CORROSION && @battle.FE == :WASTELAND && damage > 0
        if @battle.pbRandom(10)==0
          case @battle.pbRandom(4)
            when 0 then target.pbBurn(user)       if target.pbCanBurn?(false)
            when 1 then target.pbPoison(user)     if target.pbCanPoison?(false)
            when 2 then target.pbParalyze(user)   if target.pbCanParalyze?(false)
            when 3 then target.pbFreeze           if target.pbCanFreeze?(false)
          end
        end
      end

      # Ability effects
      pbEffectsOnDealingDamage(basemove,user,target,damage,innardsOutHp)

      # Berserk
      if !target.isFainted? && aboveHalfHp && target.hp<=(target.totalhp/2.0).floor && !berserkcheck
        if target.ability == (:BERSERK)
          if !pbTooHigh?(PBStats::SPATK)
            statgain = 1
            statgain = 2 if (Rejuv && @battle.FE == :DRAGONSDEN)
            target.pbIncreaseStatBasic(PBStats::SPATK,statgain)
            @battle.pbCommonAnimation("StatUp",target,nil)
            if (Rejuv && @battle.FE == :DRAGONSDEN)
              @battle.pbDisplay(_INTL("{1}'s Berserk sharply boosted its Special Attack!",target.pbThis))
            else
              @battle.pbDisplay(_INTL("{1}'s Berserk boosted its Special Attack!",target.pbThis))
            end
            berserkcheck=true
          end
        end
      end
      # Anger Shell
      if !target.isFainted? && aboveHalfHp && target.hp<=(target.totalhp/2.0).floor && !angershellcheck
        if target.ability == (:ANGERSHELL)
          if !target.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
            !target.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
            !target.pbCanIncreaseStatStage?(PBStats::SPEED,false)
           @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
           return -1
         end
         pbShowAnimation(@move,target,nil,hitnum,alltargets,showanimation)
         for stat in [PBStats::DEFENSE,PBStats::SPDEF]
           if target.pbCanReduceStatStage?(stat,false,true)
            target.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
           end
         end
         for stat in [PBStats::ATTACK,PBStats::SPATK,PBStats::SPEED]
           if target.pbCanIncreaseStatStage?(stat,false)
            target.pbIncreaseStat(stat,2,abilitymessage:false)
           end
         end
         angershellcheck=true
        end
      end
      # Emergency Exit / Wimp Out
      if !target.isFainted? && aboveHalfHp && (target.hp + target.pbBerryRecoverAmount)<=(target.totalhp/2.0).floor && !target.isbossmon
        if @battle.FE == :COLOSSEUM
          if self.ability == :WIMPOUT
            @battle.pbDisplay(_INTL("{1} has nowhere to run!",self.pbThis))
          elsif self.ability == :EMERGENCYEXIT
            if self.pbCanIncreaseStatStage?(PBStats::SPEED)  
              self.pbIncreaseStatBasic(PBStats::SPEED,2)  
              @battle.pbCommonAnimation("StatUp",user,nil)  
              @battle.pbDisplay(_INTL("Emergency Exit raised {1}'s Speed!",self.pbThis))  
            end
          end 
        else
          if (target.ability == :EMERGENCYEXIT || target.ability == :WIMPOUT) && 
            ((@battle.pbCanChooseNonActive?(target.index) && !@battle.pbAllFainted?(@battle.pbParty(target.index))) || @battle.pbIsWild?)
            blockwimp = user.isbossmon && (!@battle.pbCanChooseNonActive?(target.index) && !@battle.pbAllFainted?(@battle.pbParty(target.index)))
            if !blockwimp
              if !wimpcheck
                @battle.pbDisplay(_INTL("{1} tactically retreated!",target.pbThis)) if target.ability == :EMERGENCYEXIT
                @battle.pbDisplay(_INTL("{1} wimped out!",target.pbThis)) if target.ability == :WIMPOUT
                wimpcheck=true
              end
              @battle.pbClearChoices(target.index) 
              if @battle.pbIsWild? && !(@battle.cantescape || $game_switches[:Never_Escape])
                @battle.decision=3 # Set decision to escaped
              else
                target.userSwitch = true
                if user.userSwitch
                  @battle.scene.pbUnVanishSprite(user)
                  user.userSwitch=false
                end
              end
            end
          end
        end
      end
      # Grudge
      if !user.isFainted? && target.isFainted?
        if target.effects[:Grudge] && target.pbIsOpposing?(user.index)
          pbSetPP(basemove,basemove.pp=0)
          @battle.pbDisplay(_INTL("{1}'s {2} lost all its PP due to the grudge!",
             user.pbThis,basemove.name))
        end
      end
      # Throat Spray
      if user.hasWorkingItem(:THROATSPRAY) && basemove.isSoundBased? && user.hp>0
        if user.pbCanIncreaseStatStage?(PBStats::SPATK)
          user.pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbCommonAnimation("StatUp",user,nil)
          @battle.pbDisplay(_INTL("The Throat Spray raised #{user.pbThis}'s Sp.Atk!"))
          user.pbDisposeItem(false)
        end
      end
      # Eject Pack
      if target.hasWorkingItem(:EJECTPACK) && target.statLowered
        if !target.isFainted? && @battle.pbCanChooseNonActive?(target.index) && !@battle.pbAllFainted?(@battle.pbParty(target.index))
          @battle.pbDisplay(_INTL("#{target.pbThis}'s Eject Pack activates!"))
          target.pbDisposeItem(false,false)
          if @battle.FE == :COLOSSEUM
            @battle.pbDisplay(_INTL("But #{target.pbThis} cannot retreat."))
          else
            @battle.pbClearChoices(target.index)
            target.userSwitch = true
          end
        end
      end
      if target.isFainted?  
         if @battle.recorded || @battle.FE == :CROWD
          $game_variables[:BattleDataArray].last().pokemonFaintedAnEnemy(@battle.battlers,user,target,basemove)
         end
        destinybond=destinybond || target.effects[:DestinyBond]
      end

      if user.isFainted?
        user.pbFaint
        if @battle.recorded || @battle.FE == :CROWD
          $game_variables[:BattleDataArray].last().pokemonFaintedAnEnemy(@battle.battlers,target,user,basemove)
        end
      end
      break if user.isFainted?
      if target.isFainted?
        if target.isbossmon
          if !(target.shieldsBrokenThisTurn[user.index] > 0)
            target.pbFaint
            sosData = target.sosDetails
            if sosData
              if sosData[:playerMons] || sosData[:playerParty]
                break
              end
            end
          else
            break
          end
        else
          break
        end
      end
      # Make the target flinch
      if target.damagestate.calcdamage>0 && !target.damagestate.substitute
        if (!(target.ability == :SHIELDDUST) || target.moldbroken) || basemove.hasFlag?("m")
          if (user.hasWorkingItem(:KINGSROCK) || user.hasWorkingItem(:RAZORFANG)) &&
           basemove.canKingsRock? # && target.status!=:SLEEP && target.status!=:FROZEN #Gen 2 only thing #perry
            if @battle.pbRandom(10)==0
              target.effects[:Flinch]=true
            end
          elsif user.ability == (:STENCH) &&
           basemove.function!=0x09 && # Thunder Fang
           basemove.function!=0x0B && # Fire Fang
           basemove.function!=0x0E && # Ice Fang
           basemove.function!=0x0F && # flinch-inducing moves
           basemove.function!=0x10 && # Stomp
           basemove.function!=0x11 && # Snore
           basemove.function!=0x12 && # Fake Out
           basemove.function!=0x78 && # Twister
           basemove.function!=0xC7 #&& # Sky Attack
            if (@battle.pbRandom(10)==0 || ([:WASTELAND,:MURKWATERSURFACE,:BACKALLEY,:CITY].include?(@battle.FE)  && @battle.pbRandom(10) < 2))
              target.effects[:Flinch]=true
            end
          end
        end
      end
      if target.damagestate.calcdamage>0 && !target.isFainted?
        # Defrost
        if (basemove.pbType(user) == :FIRE || basemove.function==0x0A) && target.status== :FROZEN && !(user.ability == (:PARENTALBOND) && i==0)
          target.pbCureStatus
        end
        # Rage
        if target.effects[:Rage] && target.pbIsOpposing?(user.index)
          # TODO: Apparently triggers if opposing Pokémon uses Future Sight after a Future Sight attack
          if target.pbCanIncreaseStatStage?(PBStats::ATTACK)
            target.pbIncreaseStatBasic(PBStats::ATTACK,1)
            @battle.pbCommonAnimation("StatUp",target,nil)
            @battle.pbDisplay(_INTL("{1}'s rage is building!",target.pbThis))
          end
        end
      end
      user.pbFaint if user.isFainted? # no return
      break if user.isFainted?
      break if target.isFainted?
      # Berry check (maybe just called by ability effect, since only necessary Berries are checked)
      for j in 0...4
        @battle.battlers[j].pbBerryCureCheck
      end
      if target.damagestate.calcdamage<=0
        unless basemove.move == :ROCKBLAST && @battle.FE == :CRYSTALCAVERN #rock blast on crystal cavern
          break
        end
      end
    end
    flags[:totaldamage]+=totaldamage if totaldamage>0
    # Battle Arena only - attack is successful
    # Type effectiveness
    if numhits>1
      if target.damagestate.typemod>4
        @battle.pbDisplay(_INTL("It's super effective!"))
      elsif target.damagestate.typemod>=1 && target.damagestate.typemod<4
        @battle.pbDisplay(_INTL("It's not very effective..."))
      end
      if realnumhits==1
        @battle.pbDisplay(_INTL("Hit {1} time!",realnumhits))
      else
        @battle.pbDisplay(_INTL("Hit {1} times!",realnumhits))
      end
    end
    # Faint if 0 HP
    target.pbFaint if target.isFainted?
    user.pbFaint if user.isFainted? # no return
    if target.isFainted?
      if (user.ability == (:GRIMNEIGH) ||
        (user.ability == (:ASONE) && user.form==2)) && user.hp>0 && target.hp<=0
        if !user.pbTooHigh?(PBStats::SPATK)
          @battle.pbCommonAnimation("StatUp",self,nil)
          user.pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Special Attack!",user.pbThis,$cache.abil[user.ability].name))
        end
      end
      if (user.ability == (:MOXIE) || user.ability == (:CHILLINGNEIGH) ||
        (user.ability == (:ASONE) && user.form==1)) && user.hp>0 && target.hp<=0
        if !user.pbTooHigh?(PBStats::ATTACK)
          @battle.pbCommonAnimation("StatUp",self,nil)
          user.pbIncreaseStatBasic(PBStats::ATTACK,1)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!",user.pbThis,$cache.abil[user.ability].name))
        end
      end
      if user.ability == :EXECUTION  && user.hp>0 && target.hp<=0
        hpgain=user.pbRecoverHP(self.totalhp/8,true)
        @battle.pbDisplay(_INTL("{1}'s Execution healed some of its wounds!",user.pbThis))
      end
      if @battle.FE == :BACKALLEY && basemove.function ==0x88 && user.hp>0 && target.hp<=0 # Pursuit
        if !user.pbTooHigh?(PBStats::SPEED)
          @battle.pbCommonAnimation("StatUp",self,nil)
          user.pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbDisplay(_INTL("",user.pbThis,$cache.abil[user.ability].name))
        end
      end
    end
    if !user.isFainted? && target.isFainted?
      if destinybond && target.pbIsOpposing?(user.index)
        @battle.pbDisplay(_INTL("{1} took its attacker down with it!",target.pbThis))
        if user.isbossmon
          if !(user.immunities[:moves].include?(:DESTINYBOND))
            user.pbReduceHP(user.hp)
            user.immunities[:moves].push(:DESTINYBOND)
          else
            @battle.pbDisplay(_INTL("{1} resisted the Destiny Bond!",user.pbThis))
          end
        else
          user.pbReduceHP(user.hp)
          user.pbFaint # no return
          @battle.pbJudgeCheckpoint(user)
        end
      end
    end
    # Color Change
    movetype=basemove.pbType(user)
    if target.ability == (:COLORCHANGE) && totaldamage>0 && movetype != :SHADOW && movetype != :QMARKS && !target.hasType?(movetype)
      target.type1=movetype
      target.type2=nil
      @battle.pbDisplay(_INTL("{1}'s {2} made it the {3} type!",target.pbThis,
         getAbilityName(target.ability),movetype.capitalize))
    end
    # Eject Button
    if target.hasWorkingItem(:EJECTBUTTON) && !target.damagestate.substitute && target.damagestate.calcdamage>0
      if !target.isFainted? && @battle.pbCanChooseNonActive?(target.index) && !@battle.pbAllFainted?(@battle.pbParty(target.index))
        @battle.pbDisplay(_INTL("#{target.pbThis}'s Eject Button activates!"))
        target.pbDisposeItem(false,false)
       # @battle.pbDisplay(_INTL("{1} went back to {2}!",target.pbThis,@battle.pbGetOwner(target.index).name))
        if @battle.FE == :COLOSSEUM
          @battle.pbDisplay(_INTL("But #{target.pbThis} cannot retreat."))
        else
          @battle.pbClearChoices(target.index)
          target.userSwitch = true
        end
      end
    end
    # Berry check
    for j in 0...4
      @battle.battlers[j].pbBerryCureCheck
    end
    return damage
  end

  def pbUseMoveSimple(moveid,index=-1,target=-1,danced=false,specialZ=false)
    choice=[]
    choice[0]=1       # "Use move"
    choice[1]=index   # Index of move to be used in user's moveset
    choice[2]=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(moveid.intern),self) # PokeBattle_Move object of the move
    choice[2].pp=-1
    choice[3]=target  # Target (-1 means no target yet)
    @simplemove=(danced==false)
    if index>=0
      @battle.choices[@index][1]=index
    end
    @usingsubmove=true
    side=(@battle.pbIsOpposing?(self.index)) ? 1 : 0
    owner=@battle.pbGetOwnerIndex(self.index)
    if @battle.zMove[side][owner]==self.index && choice[2].basedamage>0 && !danced
      crystal = pbZCrystalFromType(choice[2].type)
      zmoveID = PBStuff::CRYSTALTOZMOVE[crystal]
      choice[2]=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(zmoveID),self,choice[2])
    end
    pbUseMove(choice, {specialusage: true, danced: danced, specialZ: specialZ})
    @usingsubmove=false
    @simplemove=false
    return
  end

  def pbDancerMoveCheck(id)
    if self.ability == :DANCER && @battle.FE == :BIGTOP # Big Top
      if (PBStuff::DANCEMOVE).include?(id)
        boost=false
        if !pbTooHigh?(PBStats::SPATK)
          pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbCommonAnimation("StatUp",self,nil) if !boost
          boost=true
        end
        if !pbTooHigh?(PBStats::SPEED)
          pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",self,nil) if !boost
          boost=true
        end
        @battle.pbDisplay(_INTL("{1}'s Dancer boosted its Special Attack and Speed!", pbThis)) if boost
      end
    end
    for i in @battle.battlers
      next if i == self
      if i.ability == :DANCER && (PBStuff::DANCEMOVE).include?(id)
        @battle.pbDisplay(_INTL("{1} joined in with the dance!",i.pbThis))
        i.pbUseMoveSimple(id,-1,-1,true)
      end
    end
  end

  def pbUseMove(choice, flags={danced: false, totaldamage: 0, specialusage: false, specialZ: false})
    danced=flags[:danced]
    # TODO: lastMoveUsed is not to be updated on nested calls
    flags[:totaldamage] = 0 if !flags[:totaldamage]
    # hasMovedThisRound by itself isn't enough for, say, Fake Out + Instruct.
    @isFirstMoveOfRound = !self.hasMovedThisRound?
    # Start using the move
    pbBeginTurn(choice)
    # Force the use of certain moves if they're already being used
    if (@effects[:TwoTurnAttack]!=0 || @effects[:HyperBeam]>0 || @effects[:Outrage]>0 || @effects[:Rollout]>0 || @effects[:Uproar]>0 || @effects[:Bide]>0)
      PBDebug.log("[Continuing move]") if $INTERNAL
      choice[2]=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(@currentMove),self)
      flags[:specialusage]=true
    elsif @effects[:Encore]>0 && !choice[2].zmove
      if @battle.pbCanShowCommands?(@index) && @battle.pbCanChooseMove?(@index,@effects[:EncoreIndex],false,flags)
        PBDebug.log("[Using Encore move]") if $INTERNAL
        if choice[1]!=@effects[:EncoreIndex] # Was Encored mid-round
          choice[1]=@effects[:EncoreIndex]
          choice[2]=@moves[@effects[:EncoreIndex]]
          if choice[2].move == :ACUPRESSURE
            choice[3]=self.index
          else
            choice[3]=-1 # No target chosen
          end
        end
      end
    end
    basemove=choice[2]
    return if !basemove
    if !flags[:specialusage]
      # TODO: Quick Claw message
    end
    PBDebug.log("#{self.name} used #{basemove.name}") if $INTERNAL
    return false if self.effects[:SkyDrop]
    if !pbTryUseMove(choice,basemove,flags)
      if self.vanished
        @battle.scene.pbUnVanishSprite(self)
        droprelease = self.effects[:SkyDroppee]
        if droprelease!=nil
          oppmon = droprelease
          oppmon.effects[:SkyDrop]=false
          @effects[:SkyDroppee] = nil
          @battle.scene.pbUnVanishSprite(oppmon)
          @battle.pbDisplay(_INTL("{1} is freed from the Sky Drop effect!",oppmon.pbThis))
        end
      end
      self.lastMoveUsed=-1
      if !flags[:specialusage]
        self.lastMoveUsedSketch=-1 if self.effects[:TwoTurnAttack]==0
        self.lastRegularMoveUsed=-1
        self.lastRoundMoved=@battle.turncount
      end
      pbCancelMoves
      @battle.pbGainEXP
      pbEndTurn(choice)
      @battle.pbJudgeSwitch
      return
    end
    if !flags[:specialusage]
      ppmove = choice[2].zmove ? self.moves[choice[1]] : basemove
      if !pbReducePP(ppmove) && !choice[2].zmove
        @battle.pbDisplay(_INTL("{1} used\r\n{2}!",pbThis,basemove.getMoveUseName))
        @battle.pbDisplay(_INTL("But there was no PP left for the move!"))
        self.lastMoveUsed=-1
        if !flags[:specialusage]
          self.lastMoveUsedSketch=-1 if self.effects[:TwoTurnAttack]==0
          self.lastRegularMoveUsed=-1
          self.lastRoundMoved=@battle.turncount
        end
        pbEndTurn(choice)
        @battle.pbJudgeSwitch
        return
      end
    end
    @battle.pbUseZMove(self.index,choice,self.item,flags[:specialZ]) if choice[2].zmove && (!flags[:specialusage] || flags[:specialZ])
    if basemove.function!=0x92 # Echoed Voice
      self.effects[:EchoedVoice]=0
    end
    if basemove.function!=0x91 # Fury Cutter
      self.effects[:FuryCutter]=0
    end
    if @effects[:Powder] && (basemove.type == :FIRE)
      @battle.pbDisplay(_INTL("The powder around {1} exploded!",pbThis))
      @battle.pbCommonAnimation("Powder",self,nil)
      pbReduceHP((@totalhp/4.0).floor)
      pbFaint if @hp<1
      return false
    end
    # Remember that user chose a two-turn move
    if basemove.pbTwoTurnAttack(self)
      # Beginning use of two-turn attack
      @effects[:TwoTurnAttack]=basemove.move
      @currentMove=basemove.move
    else
      @effects[:TwoTurnAttack]=0 # Cancel use of two-turn attack
      @effects[:SkyDroppee] = nil if basemove.move != :SKYDROP
    end
    # "X used Y!" message
    case basemove.pbDisplayUseMessage(self,choice)
      when 2   # Continuing Bide
        if !flags[:specialusage]
          self.lastRoundMoved=@battle.turncount
        end
        return
      when 1   # Starting Bide
        if $cache.moves[basemove.move]
          self.lastMoveUsed=basemove.move
          @lastMoveChoice = choice.clone
          if !flags[:specialusage]
            self.lastMoveUsedSketch=basemove.move if self.effects[:TwoTurnAttack]==0
            self.lastRegularMoveUsed=basemove.move
            self.movesUsed.push(basemove.move)   # For Last Resort
            self.lastRoundMoved=@battle.turncount
          else
            self.lastRegularMoveUsed=-1 if basemove.move == :STRUGGLE
          end
          @battle.lastMoveUsed=basemove.move
          @battle.lastMoveUser=self.index
        end
        return
      when -1   # Was hurt while readying Focus Punch, fails use
        if $cache.moves[basemove.move]
          self.lastMoveUsed=basemove.move
          @lastMoveChoice = choice.clone
          if !flags[:specialusage]
            self.lastMoveUsedSketch=basemove.move if self.effects[:TwoTurnAttack]==0
            self.lastRegularMoveUsed=basemove.move
            self.movesUsed.push(basemove.move)   # For Last Resort
            self.lastRoundMoved=@battle.turncount
          else
            self.lastRegularMoveUsed=-1 if basemove.move == :STRUGGLE
          end
          @battle.lastMoveUsed=basemove.move
          @battle.lastMoveUser=self.index
        end
        return
      end
    # Find the user and target(s)
    targets=[]
    pbFindUser(choice,targets)
    user = self
    # Status Z-move effects
    pbZStatus(basemove.move,user) if choice[2].zmove && choice[2].category == :status && PBStuff::TYPETOZCRYSTAL[basemove.type] == user.item
    # moldbreaker
    if (user.ability == :MOLDBREAKER || user.ability == :TERAVOLT || user.ability == :TURBOBLAZE) ||
       basemove.function==0x166 || basemove.function==0x176 || basemove.function==0x200 # Solgaluna/crozma signatures
      for i in 0..3
        @battle.battlers[i].moldbroken = true
      end
    else
      for i in 0..3
        @battle.battlers[i].moldbroken = false
      end
    end
    if user.ability == (:CORROSION)
      for battlers in targets
        battlers.corroded = true
      end
    else
      for battlers in targets
        battlers.corroded = false
      end
    end
    # Battle Arena only - assume failure
    # Check whether Selfdestruct works
    selffaint=(basemove.function==0xE0) # Selfdestruct
    if !basemove.pbOnStartUse(user) # Only Selfdestruct can return false here
      if $cache.moves[basemove.move]
        user.lastMoveUsed=basemove.move
        @lastMoveChoice = choice.clone
        if !flags[:specialusage]
          user.lastMoveUsedSketch=basemove.move if user.effects[:TwoTurnAttack]==0
          user.lastRegularMoveUsed=basemove.move
          user.movesUsed.push(basemove.move)   # For Last Resort
          user.lastRoundMoved=@battle.turncount
        else
          self.lastRegularMoveUsed=-1 if basemove.move == :STRUGGLE
        end
        @battle.lastMoveUsed=basemove.move
        @battle.lastMoveUser=user.index
      end
      # Might pbEndTurn need to be called here?
      return
    end
    if selffaint
      user.hp=0
      user.pbFaint # no return
      user.ability = user.pokemon.ability # restore ability just for this turn
    end
    # Record move as having been used
    if $cache.moves[basemove.move]
      user.lastMoveUsed=basemove.move
      @lastMoveChoice = choice.clone
      user.lastRoundMoved=@battle.turncount
      if !flags[:specialusage]
        user.lastMoveUsedSketch=basemove.move
        user.lastRegularMoveUsed=basemove.move
        if !basemove.zmove
          user.movesUsed.push(basemove.move) # For Last Resort
          user.effects[:Metronome]=0 if basemove.move != user.movesUsed[-2]
        end
      else
        self.lastRegularMoveUsed=-1 if basemove.move == :STRUGGLE
      end
      @battle.lastMoveUsed=basemove.move
      @battle.lastMoveUser=user.index
      if basemove.zmove
        user.lastMoveUsed=-1
        user.lastMoveUsedSketch=-1
        user.lastRegularMoveUsed=-1
        @battle.lastMoveUsed=-1
      end
    end
    targetchoices=pbTarget(basemove)
    # Try to use move against user if there aren't any targets
    if targets.length==0 && !(@effects[:TwoTurnAttack]!=0)
      user=pbChangeUser(basemove,user)
      cancelcheck = false
      if basemove.typeFieldBoost(basemove.pbType(user),user,nil)==0
        @battle.pbDisplay(_INTL(basemove.typeFieldMessage(basemove.pbType(user)))) if !basemove.fieldmessageshown_type
        basemove.fieldmessageshown_type = true
        user.pbCancelMoves
        cancelcheck = true
      end
      if basemove.moveFieldBoost==0
        @battle.pbDisplay(_INTL(basemove.moveFieldMessage)) if !basemove.fieldmessageshown
        basemove.fieldmessageshown = true
        user.pbCancelMoves
        cancelcheck = true
      end
      if !cancelcheck
        if targetchoices==:SingleNonUser || targetchoices==:RandomOpposing || targetchoices==:AllOpposing || targetchoices==:AllNonUsers || targetchoices==:Partner || targetchoices==:UserOrPartner || targetchoices==:SingleOpposing || targetchoices==:OppositeOpposing
          @battle.pbDisplay(_INTL("But there was no target..."))
          @effects[:Rollout]=0 if @effects[:Rollout]>0
          if PBStuff::TWOTURNMOVE.include?(basemove.move) #Sprites for two turn moves
            @battle.scene.pbUnVanishSprite(user)
          end
        else
          PBDebug.logonerr{
            basemove.pbEffect(user,nil)
          }
        end
        unless !basemove
          pbDancerMoveCheck(basemove.move) unless danced
        end
      end
    else
      # We have targets
      movesucceeded=false
      showanimation=true
      disguisecheck=false
      disguisebustcheck=false
      alltargets=[]
      basemove.fieldmessageshown = false
      basemove.fieldmessageshown_type = false
      if @effects[:TwoTurnAttack]!=0 && targets.length==0
        numhits=basemove.pbNumHits(user)
        pbProcessMoveAgainstTarget(basemove,user,nil,numhits,flags,false,alltargets,showanimation)
      end
      for i in 0...targets.length
        alltargets.push(targets[i].index)
      end

      # For each target in turn
      i=0; loop do break if i>=targets.length
        # Get next target
        userandtarget=[user,targets[i]]
        if i==0 && (targetchoices==:AllOpposing)
          # Add target's partner to list of targets
          pbAddTarget(targets,userandtarget[1].pbPartner)
        end
        success=pbChangeTarget(basemove,userandtarget,targets)
        user=userandtarget[0]
        target=userandtarget[1]
        if target.effects[:MagicBounced] || target.isFainted?
          success=false
        end
        if !success
          i+=1
          next
        end
        numhits=basemove.pbNumHits(user)
        # Ledian and Cinccino crests
        if targetchoices!=:AllOpposing && numhits<2
          case user.crested
            when :LEDIAN
              numhits = 4 if basemove.punchMove?
            when :CINCCINO
              hitchances=[2,2,3,3,4,5]
              ret=hitchances[@battle.pbRandom(hitchances.length)]
              ret=5 if user.ability == :SKILLLINK
              numhits = ret if !basemove.pbIsMultiHit
          end
        end
        # Parental bond
        if numhits == 1 && user.ability == (:PARENTALBOND) && !choice[2].zmove
         counter1=0
         counter2=0
          for k in @battle.battlers
           next if k.isFainted?
           counter1+=1
          end
          for j in @battle.battlers
            next unless user.pbIsOpposing?(j.index)
            next if j.isFainted?
            counter2+=1
          end
          user.effects[:ParentalBond] = true unless ((targetchoices == :AllNonUsers && !(counter1==2)) || (targetchoices == :AllOpposing && !(counter2==1)))
          numhits = 2  unless ((targetchoices == :AllNonUsers && !(counter1==2)) || (targetchoices == :AllOpposing && !(counter2==1)))
        else
          user.effects[:ParentalBond] = false
        end
        if numhits == 1 && basemove.contactMove? && user.crested == :TYPHLOSION && !choice[2].zmove
          counter1=0
          counter2=0
          for k in @battle.battlers
            next if k.isFainted?
            counter1+=1    
          end
          for j in @battle.battlers
            next unless user.pbIsOpposing?(j.index)
            next if j.isFainted?
            counter2+=1
          end
          user.effects[:TyphBond] = true unless ((targetchoices == :AllNonUsers && !(counter1==2)) || (targetchoices == :AllOpposing && !(counter2==1)))
          numhits = 2  unless ((targetchoices == :AllNonUsers && !(counter1==2)) || (targetchoices == :AllOpposing && !(counter2==1)))
        else
          user.effects[:TyphBond] = false
        end
        # Reset damage state, set Focus Band/Focus Sash to available
        target.damagestate.reset
        if target.hasWorkingItem(:FOCUSBAND) && @battle.pbRandom(10)==0
          target.damagestate.focusband=true
        end
        if target.hasWorkingItem(:FOCUSSASH)
          target.damagestate.focussash=true
        end
        if target.crested == :RAMPARDOS && target.pokemon.rampCrestUsed == false
          target.damagestate.rampcrest=true
        end
        # Use move against the current target
        disguisecheck = true if (target.index==0 || target.index==1) && target.effects[:Disguise] # Only used to stop anim playing after a disguise is broken
        hitcheck = pbProcessMoveAgainstTarget(basemove,user,target,numhits,flags,false,alltargets,showanimation)
        hitcheck = 0 if hitcheck == nil
        disguisebustcheck = true if disguisecheck==true && !target.effects[:Disguise]
        showanimation=false unless (hitcheck<=0 && disguisebustcheck==false && @effects[:TwoTurnAttack]==0 && (basemove.pbIsSpecial?(basemove.type) || basemove.pbIsPhysical?(basemove.type)))
        movesucceeded = true if hitcheck && hitcheck > 0
        # Probopass Crest
        if user.crested == :PROBOPASS
          if basemove.basedamage > 0 && basemove.move != :PROBOPOG
            @battle.pbDisplay(_INTL("{1}'s mini noses followed up on the attack!",user.pbThis))
            if basemove.target==:AllOpposing || basemove.target==:AllNonUsers
              movetarget=target
              movetarget=user.pbCrossOpposing if user.pbPartner == target
              movetarget=movetarget.pbPartner if movetarget.isFainted?
            else
              movetarget=target
              movetarget=movetarget.pbPartner if movetarget.isFainted?
            end
            if movetarget.isFainted?
              @battle.pbDisplay(_INTL("But there was no target left!",user.pbThis))
            else
              user.pbUseMoveSimple(:PROBOPOG,-1,movetarget.index)
            end
          end
        end
        # Swalot Crest
        if user.crested == :SWALOT
          if basemove.move == :BELCH  
            move = :SPITUP
            movename = getMoveName(move)
            @battle.pbDisplay(_INTL("{1} used {2}!",user.pbThis,movename))
            movetarget=target
            movetarget=movetarget.pbPartner if movetarget.isFainted?
            if movetarget.isFainted?
              @battle.pbDisplay(_INTL("But there was no target left!",user.pbThis))
            else
              user.pbUseMoveSimple(move,-1,movetarget.index)
            end
          end
          if(basemove.move!=:STOCKPILE && basemove.move!=:SPITUP &&
            basemove.move!=:SWALLOW) && user.effects[:Stockpile] < 3
            user.effects[:Stockpile]+=1
            @battle.pbDisplay(_INTL("{1} stockpiled {2}!",user.pbThis,user.effects[:Stockpile]))
            if user.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
              user.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
              user.effects[:StockpileDef]+=1
            end
            if user.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
              user.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
              user.effects[:StockpileSpDef]+=1
            end
          end
        end
        i+=1
      end
      basemove.fieldmessageshown = false
      basemove.fieldmessageshown_type = false  

      # Metronome item
      if (user.hasWorkingItem(:METRONOME) || @battle.FE == :CONCERT4) && movesucceeded
        user.effects[:Metronome]+=1
      else
        user.effects[:Metronome]=0
      end

      # Magic Bounce
      for i in targets
        if i.effects[:BouncedMove]!=0 #lía
          move=i.effects[:BouncedMove].move
          i.effects[:BouncedMove]=0
          @battle.pbDisplay(_INTL("{1} bounced the {2} back!",i.pbThis,basemove.name))
          if @battle.FE == :MIRROR
            if i.pbCanIncreaseStatStage?(PBStats::EVASION)
              i.pbIncreaseStatBasic(PBStats::EVASION,1)
              @battle.pbCommonAnimation("StatUp",i,nil)
              @battle.pbDisplay(_INTL("{1}'s Magic Bounce increased its evasion!",i.pbThis,basemove.name))
            end
          end
          #pbUseMoveSimple(moveid,index=-1,target=-1,danced=false)
          i.pbUseMoveSimple(move,-1,user.index,false)
          i.effects[:MagicBounced]=false
        end
      end

      # Mold Breaker reset
      for battlers in targets
        battlers.moldbroken = false
        battlers.corroded = false
      end

      # Misc Field Effects 2
      if @battle.FE == :DIMENSIONAL
        combust = user.totalhp
        if combust!=0
          if (basemove.move == :DIG || basemove.move == :DIVE ||
            basemove.move == :FLY || basemove.move == :BOUNCE) && 
            user.effects[:TwoTurnAttack] != 0
            combust-=1 if user.ability == (:STURDY)
            @battle.pbDisplay(_INTL("The corrupted field damaged {1}!",user.pbThis)) if combust != 0
            user.pbReduceHP(combust) if combust != 0
            user.pbFaint if user.isFainted?
          end
        end
      end

      # Goth Crest
      if user.crested == :GOTHITELLE && user.hasType?(:DARK) && flags[:totaldamage]>0 && @effects[:HealBlock]==0
        hpgain = flags[:totaldamage]/4.0
        hpgain=user.pbRecoverHP([hpgain.floor,1].max,true)
        if hpgain>0
          @battle.pbDisplay(_INTL("{1} restored some HP using the Gothitelle Crest!",user.pbThis))
        end
      end

      # Sheer Force affected items
      if !(user.ability == (:SHEERFORCE) && basemove.effect>0)

        # Shell Bell
        if (user.hasWorkingItem(:SHELLBELL) || (user.crested==:TORTERRA && !user.isFainted?))  && flags[:totaldamage]>0 && @effects[:HealBlock]==0
          hpgain = @battle.FE == :ASHENBEACH ? flags[:totaldamage]/4.0 : flags[:totaldamage]/8.0
          hpgain=user.pbRecoverHP([hpgain.floor,1].max,true)
          if hpgain>0
            @battle.pbDisplay(_INTL("{1} restored a little HP using its Shell Bell!",user.pbThis))
          end
        end

        # Life Orb
        if user.hasWorkingItem(:LIFEORB) && flags[:totaldamage]>0 && user.ability != (:MAGICGUARD) && !(user.ability == (:WONDERGUARD) && @battle.FE == :COLOSSEUM)
          hploss=user.pbReduceHP([(user.totalhp/10.0).floor,1].max,true)
          if hploss>0
            @battle.pbDisplay(_INTL("{1} lost some of its HP!",user.pbThis))
          end
        end

        user.pbFaint if user.isFainted? # no return
      end

      # Dancer
      unless !basemove
        pbDancerMoveCheck(basemove.move) unless danced
      end
      if danced
        if user.effects[:Outrage]>0
          user.effects[:Outrage]=0
        end
      end
      # Switch moves
      for i in @battle.battlers
        if i.userSwitch
          i.userSwitch = false
          #remove gem when switching out before hitting pbEndTurn
          if i.takegem
            i.pbDisposeItem(false)
            i.takegem=false
          end
          @battle.pbDisplay(_INTL("{1} went back to {2}!",i.pbThis,@battle.pbGetOwner(i.index).name))
          newpoke=0
          newpoke=@battle.pbSwitchInBetween(i.index,true,false)
          @battle.pbMessagesOnReplace(i.index,newpoke)
          i.vanished=false
          i.pbResetForm
          @battle.pbReplace(i.index,newpoke,false)
          @battle.pbOnActiveOne(i)
          i.pbAbilitiesOnSwitchIn(true)
        end
        if i.forcedSwitch
          #remove gem when forced switching out mid attack
          if i.takegem
            i.pbDisposeItem(false)
            i.takegem=false
          end
          i.forcedSwitch = false
          party=@battle.pbParty(i.index)
          j=-1
          until j!=-1
            j=@battle.pbRandom(party.length)
            if !((i.isFainted? || j!=i.pokemonIndex) && (pbPartner.isFainted? || j!=i.pbPartner.pokemonIndex) && party[j] && !party[j].isEgg? && party[j].hp>0)
                j=-1
            end
            if !@battle.pbCanSwitchLax?(i.index,j,false)
              j=-1
            end
            if Rejuv and party[j].isbossmon
              j=-1
            end
          end
          newpoke=j
          i.vanished=false
          i.pbResetForm
          @battle.pbReplace(i.index,newpoke,false)
          @battle.pbDisplay(_INTL("{1} was dragged out!",i.pbThis))
          @battle.pbOnActiveOne(i)
          i.pbAbilitiesOnSwitchIn(true)
          i.forcedSwitchEarlier = true
        end
      end
    end
    if selffaint
      user.ability = nil
    end
    @battle.fieldEffectAfterMove(basemove,user)
    if user.effects[:LaserFocus]>0
      user.effects[:LaserFocus]-=1
    end
    @battle.pbGainEXP
    # Check if move order should be switched for shell trap

    # Remember trainer has used z-move
    if basemove.zmove
      side=(@battle.pbIsOpposing?(self.index)) ? 1 : 0
      owner=@battle.pbGetOwnerIndex(self.index)
      @battle.zMove[side][owner]=-2 if @battle.zMove[side][owner]!=-1
    end
    # End of move usage
    pbEndTurn(choice)
    @battle.pbJudgeSwitch
    return
  end

  def pbCancelMoves
    # If failed pbTryUseMove or have already used Pursuit to chase a switching foe
    # Cancel multi-turn attacks (note: Hyper Beam effect is not canceled here)
    @effects[:TwoTurnAttack]=0 if @effects[:TwoTurnAttack]!=0
    @effects[:Outrage]=0
    @effects[:Rollout]=0
    @effects[:Uproar]=0
    @effects[:Bide]=0
    @effects[:HyperBeam]=0
    @currentMove=0
    # Reset counters for moves which increase them when used in succession
    @effects[:FuryCutter]=0
    @effects[:EchoedVoice]=0
  end

################################################################################
# Field Handlers
################################################################################

  def ignitecheck
    return @battle.state.effects[:WaterSport] <= 0 && @battle.pbWeather != :RAINDANCE
  end

  def suncheck
    @battle.field.duration = @battle.weatherduration
  end

  def getSpecialStat(unaware=false, which_is_higher: false)
    stagemul=[2,2,2,2,2,2,2,3,4,5,6,7,8]
    stagediv=[8,7,6,5,4,3,2,2,2,2,2,2,2]
    allyfainted = self.pbFaintedPokemonCount
    spatkmult = 1
    spatkmult *= 1.5 if self.item == :CHOICESPECS
    spatkmult *= 2 if self.item == :DEEPSEATOOTH && self.pokemon.species == :CLAMPERL
    spatkmult *= 2 if self.item == :LIGHTBALL && self.pokemon.species == :PIKACHU
    spatkmult *= 1.5 if self.ability == :MINUS && self.pbPartner.ability == :PLUS
    spatkmult *= 1.5 if self.ability == :PLUS && self.pbPartner.ability == :MINUS
    spatkmult *= 1.5 if self.ability == :SOLARPOWER && @battle.pbWeather== :SUNNYDAY
    spatkmult *= 1.5 if self.crested == :CASTFORM && @battle.pbWeather== :SUNNYDAY
    spatkmult *= ((allyfainted * 0.2) + 1.0) if self.crested == :SPIRITOMB
    spatkmult *= 1.3 if self.pbPartner.ability == :BATTERY
    spdefmult = 1
    spdefmult *= 1.5 if self.item == :ASSAULTVEST
    spdefmult *= 1.5 if self.item == :EVIOLITE && !pbGetEvolvedFormData(self.pokemon.species,self.pokemon).nil?
    #spdefmult *= 1.5 if self.item == :EEVIUMZ && self.species == :EEVEE
    spdefmult *= 1.5 if self.item == :PIKANIUMZ && self.species == :PIKACHU
    spdefmult *= 1.5 if self.item == :LIGHTBALL && self.species == :PIKACHU
    spdefmult *= 2 if self.item == :DEEPSEASCALE && self.pokemon.species == :CLAMPERL
    spdefmult *= 1.5 if self.item == :METALPOWDER && self.pokemon.species == :DITTO && !self.effects[:Transform]
    spdefmult *= 1.5 if self.ability == :FLOWERGIFT && @battle.pbWeather== :SUNNYDAY || self.crested == :CHERRIM
    spdefmult *= 1.5 if @battle.pbWeather== :SANDSTORM &&hasType?(:ROCK)
    
    return [spatkmult*self.spatk,spdefmult*self.spdef].max if unaware
    
    spatk = self.spatk*stagemul[self.stages[PBStats::SPATK]+6]/stagediv[self.stages[PBStats::SPATK]+6]
    spdef = self.spdef*stagemul[self.stages[PBStats::SPDEF]+6]/stagediv[self.stages[PBStats::SPDEF]+6]
    
    #If we only want to know which stat is higher
    return PBStats::SPATK if spatkmult*spatk > spdefmult*spdef && which_is_higher
    return PBStats::SPDEF if which_is_higher

    return [spatkmult*spatk,spdefmult*spdef].max
  end


################################################################################
# Turn processing
################################################################################
  def pbBeginTurn(choice)
    # Cancel some lingering effects which only apply until the user next moves
    @effects[:DestinyBond]=false
    @effects[:Grudge]=false
    # Encore's effect ends if the encored move is no longer available
    if @effects[:Encore]>0 &&
       @moves[@effects[:EncoreIndex]].move!=@effects[:EncoreMove]
      PBDebug.log("[Resetting Encore effect]") if $INTERNAL
      @effects[:Encore]=0
      @effects[:EncoreIndex]=0
      @effects[:EncoreMove]=0
    end
    # Wake up in an uproar
    if self.status== :SLEEP && self.ability != :SOUNDPROOF
      for i in 0...4
        if @battle.battlers[i].effects[:Uproar]>0
          pbCureStatus(false)
          @battle.pbDisplay(_INTL("{1} woke up in the uproar!",pbThis))
        end
      end
    end
  end

  def pbEndTurn(choice)
    # True end(?)
    if @lastRegularMoveUsed
      @effects[:ChoiceBand]=@lastRegularMoveUsed if @effects[:ChoiceBand]==nil && !self.isFainted? && (self.hasWorkingItem(:CHOICEBAND) || self.hasWorkingItem(:CHOICESPECS) || self.hasWorkingItem(:CHOICESCARF) || self.ability == :GORILLATACTICS)
    end
    @selectedMove = nil
    @battle.synchronize[0]=-1
    @battle.synchronize[1]=-1
    @battle.synchronize[2]=0
    for i in 0...4
      @battle.battlers[i].pbAbilityCureCheck
      @battle.battlers[i].pbBerryCureCheck
      @battle.battlers[i].pbAbilitiesOnSwitchIn(false)
      @battle.battlers[i].pbCheckForm
      #End of turn ability nullification check
      if @battle.battlers[i].ability != @battle.battlers[i].backupability #Ability has changed
        if !@battle.battlers[i].ability.nil?  #Ability was not nullified
          @battle.battlers[i].backupability = @battle.battlers[i].ability #No going back
        end
      end
    end
    #remove the gem if consumed this turn
    if self.takegem
      pbDisposeItem(false)
      self.takegem=false
    end

    self.missAcc = false
    for i in 0...4
      @battle.battlers[i].statLowered = false
      @battle.battlers[i].statdownanimplayed = false
      @battle.battlers[i].statupanimplayed = false
      @battle.battlers[i].statrepeat = false
    end
  end

  def pbProcessTurn(choice)
    # Can't use a move if fainted
    return if self.isFainted?
    # Wild roaming Pokémon always flee if possible
    if !@battle.opponent && @battle.pbIsOpposing?(self.index) && @battle.rules["alwaysflee"] && @battle.pbCanRun?(self.index) &&
         $PokemonTemp.roamerIndex && $game_variables[RoamingSpecies[$PokemonTemp.roamerIndex][:variable]]<=@battle.turncount
      pbBeginTurn(choice)
      pbSEPlay("escape",100)
      @battle.pbDisplay(_INTL("{1} fled!",self.pbThis))
      @battle.decision=3
      pbEndTurn(choice)
      return
    end
    if $game_variables[:LuckShinies] != 0
      for battler in @battle.battlers
        if @battle.pbIsWild? && [1,3].include?(battler.index) && !battler.isFainted? && battler.pokemon.isShiny? && !battler.isbossmon && !battler.issossmon
          if @battle.pbRandom(100)<10
            pbBeginTurn(choice)
            pbSEPlay("escape",100)
            @battle.pbDisplay(_INTL("{1} fled!",battler.name))
            @battle.decision=3
            PBDebug.log("Wild Pokemon Escaped!") if $INTERNAL
            pbEndTurn(choice)
            return
          end
        end
      end
    end
    # If this battler's action for this round wasn't "use a move"
    if choice[0]!=1
      # Clean up effects that end at battler's turn
      pbBeginTurn(choice)
      pbEndTurn(choice)
      return
    end
    # Turn is skipped if Pursuit was used during switch
    if @effects[:Pursuit]
      @effects[:Pursuit]=false
      pbCancelMoves
      pbEndTurn(choice)
      @battle.pbJudgeSwitch
      return
    end
    # Use the move
    @battle.previousMove = @battle.lastMoveUsed
    @battle.previousMoveUser = @battle.lastMoveUser
    @previousMove = @lastMoveUsed
    PBDebug.logonerr{
        pbUseMove(choice, {specialusage: choice[2]==@battle.struggle})
    }
    if !@battle.isOnline? && !choice[2].zmove#perry aimemory
      @battle.ai.addMoveToMemory(self,choice[2])
    end
  end

  def pbSwapDefenses
    @spdef, @defense = @defense, @spdef
    if @wonderroom
      @wonderroom = false
    else
      @wonderroom = true
    end
  end

  def getRoll(update_roll:true, isDebuff:false)

    case @battle.FE
      when :CROWD
        if isDebuff
          choices = PBStuff::CROWDDEBUFFS
        else
          choices = PBStuff::CROWDBUFFS
        end
    end
    result=choices[@roll]
    @roll = (@roll + 1) % choices.length if update_roll
    return result
  end

  def cheer
    if  self.isbattlernew.nil? ||  self.isbattlernew.personalID!=self.pokemon.personalID
      self.roll=0
    end
    self.isbattlernew =  self.pokemon.clone
    messageroll = [self.name+ " received the crowd's cheers! Full power!", 
    self.name+ " received the crowd's cheers! Unyielding as the earth!",
    self.name+ " received the crowd's cheers! Full speed ahead!",][self.roll]
    effectroll = self.getRoll()
    eval(effectroll)
    @battle.pbDisplay(messageroll) if !@fieldmessageshown
  end
  def boo
    aBoost = self.attack
    dBoost = self.defense
    saBoost = self.spatk
    sdBoost = self.spdef
    spdBoost = self.speed
    boostStat = [aBoost,dBoost,saBoost,sdBoost,spdBoost].max
    statmod = 1
    case boostStat
      when aBoost
        if !self.pbTooLow?(PBStats::ATTACK)
          @battle.pbCommonAnimation("StatDown",self,nil)
          self.pbReduceStatBasic(PBStats::ATTACK,statmod)
          @battle.pbDisplay(_INTL("The Crowd's booing lowered {1}'s Attack!",self.pbThis))
        end
      when dBoost
        if !self.pbTooLow?(PBStats::DEFENSE)
          @battle.pbCommonAnimation("StatDown",self,nil)
          self.pbReduceStatBasic(PBStats::DEFENSE,statmod)
          @battle.pbDisplay(_INTL("The Crowd's booing lowered {1}'s Defense!",self.pbThis))
        end
      when saBoost
        if !self.pbTooLow?(PBStats::SPATK)
          @battle.pbCommonAnimation("StatDown",self,nil)
          self.pbReduceStatBasic(PBStats::SPATK,statmod)
          @battle.pbDisplay(_INTL("The Crowd's booing lowered {1}'s Special Attack!",self.pbThis))
        end
      when sdBoost
        if !self.pbTooLow?(PBStats::SPDEF)
          @battle.pbCommonAnimation("StatDown",self,nil)
          self.pbReduceStatBasic(PBStats::SPDEF,statmod)
          @battle.pbDisplay(_INTL("The Crowd's booing lowered {1}'s Special Defense!",self.pbThis))
        end
      when spdBoost
        if !self.pbTooLow?(PBStats::SPEED)
          @battle.pbCommonAnimation("StatDown",self,nil)
          self.pbReduceStatBasic(PBStats::SPEED,statmod)
          @battle.pbDisplay(_INTL("The Crowd's booing lowered {1}'s Speed!",self.pbThis))
        end
    end
  end

################################################################################
# Z Status Effect check
################################################################################

  def pbZStatus(move,attacker)
    z_effect_hash = pbHashForwardizer({
      [PBStats::ATTACK,1] => [:BULKUP,:HONECLAWS,:HOWL,:LASERFOCUS,:LEER,:MEDITATE,:ODORSLEUTH,:POWERTRICK,:ROTOTILLER,:SCREECH,:SHARPEN,
        :TAILWHIP, :TAUNT,:TOPSYTURVY,:WILLOWISP,:WORKUP,:COACHING,:POWERSHIFT,:DESERTSMARK],
      [PBStats::ATTACK,2] =>   [:MIRRORMOVE,:OCTOLOCK],
      [PBStats::ATTACK,3] =>   [:SPLASH],
      [PBStats::DEFENSE,1] =>   [:AQUARING,:BABYDOLLEYES,:BANEFULBUNKER,:BLOCK,:CHARM,:DEFENDORDER,:FAIRYLOCK,:FEATHERDANCE,
        :FLOWERSHIELD,:GRASSYTERRAIN,:GROWL,:HARDEN,:MATBLOCK,:NOBLEROAR,:PAINSPLIT,:PLAYNICE,:POISONGAS,
        :POISONPOWDER,:QUICKGUARD,:REFLECT,:ROAR,:SPIDERWEB,:SPIKES,:SPIKYSHIELD,:STEALTHROCK,:STRENGTHSAP,
        :TEARFULLOOK,:TICKLE,:TORMENT,:TOXIC,:TOXICSPIKES,:VENOMDRENCH,:WIDEGUARD,:WITHDRAW,:ARENITEWALL],
      [PBStats::SPATK,1] => [:CONFUSERAY,:ELECTRIFY,:EMBARGO,:FAKETEARS,:GEARUP,:GRAVITY,:GROWTH,:INSTRUCT,:IONDELUGE,
        :METALSOUND,:MINDREADER,:MIRACLEEYE,:NIGHTMARE,:PSYCHICTERRAIN,:REFLECTTYPE,:SIMPLEBEAM,:SOAK,:SWEETKISS,
        :TEETERDANCE,:TELEKINESIS,:MAGICPOWDER],
      [PBStats::SPATK,2] => [:HEALBLOCK,:PSYCHOSHIFT,:TARSHOT],
      [PBStats::SPATK,3] => [],
      [PBStats::SPDEF,1] => [:CHARGE,:CONFIDE,:COSMICPOWER,:CRAFTYSHIELD,:EERIEIMPULSE,:ENTRAINMENT,:FLATTER,:GLARE,:INGRAIN,
        :LIGHTSCREEN,:MAGICROOM,:MAGNETICFLUX,:MEANLOOK,:MISTYTERRAIN,:MUDSPORT,:SPOTLIGHT,:STUNSPORE,:THUNDERWAVE,
        :WATERSPORT,:WHIRLWIND,:WISH,:WONDERROOM,:CORROSIVEGAS,:SHELTER],
      [PBStats::SPDEF,2] => [:AROMATICMIST,:CAPTIVATE,:IMPRISON,:MAGICCOAT,:POWDER],
      [PBStats::SPEED,1] => [:AFTERYOU,:AURORAVEIL,:ELECTRICTERRAIN,:ENCORE,:GASTROACID,:GRASSWHISTLE,:GUARDSPLIT,:GUARDSWAP,
        :HAIL,:HYPNOSIS,:LOCKON,:LOVELYKISS,:POWERSPLIT,:POWERSWAP,:QUASH,:RAINDANCE,:ROLEPLAY,:SAFEGUARD,
        :SANDSTORM,:SCARYFACE,:SING,:SKILLSWAP,:SLEEPPOWDER,:SPEEDSWAP,:STICKYWEB,:STRINGSHOT,:SUNNYDAY,
        :SUPERSONIC,:TOXICTHREAD,:WORRYSEED,:YAWN],
      [PBStats::SPEED,2] => [:ALLYSWITCH,:BESTOW,:MEFIRST,:RECYCLE,:SNATCH,:SWITCHEROO,:TRICK],
      [PBStats::ACCURACY,1]   => [:COPYCAT,:DEFENSECURL,:DEFOG,:FOCUSENERGY,:MIMIC,:SWEETSCENT,:TRICKROOM],
      [PBStats::EVASION,1]   => [:CAMOUFLAGE,:DETECT,:FLASH,:KINESIS,:LUCKYCHANT,:MAGNETRISE,:SANDATTACK,:SMOKESCREEN],
      [:allstat1]  => [:CONVERSION,:FORESTSCURSE,:GEOMANCY,:PURIFY,:SKETCH,:TRICKORTREAT,:CELEBRATE,:TEATIME,:STUFFCHEEKS, :HAPPYHOUR],
      [:crit1]  => [:ACUPRESSURE,:FORESIGHT,:HEARTSWAP,:SLEEPTALK,:TAILWIND],
      [:reset]  => [:ACIDARMOR,:AGILITY,:AMNESIA,:ATTRACT,:AUTOTOMIZE,:BARRIER,:BATONPASS,:CALMMIND,:COIL,:COTTONGUARD,
        :COTTONSPORE,:DARKVOID,:DISABLE,:DOUBLETEAM,:DRAGONDANCE,:ENDURE,:FLORALHEALING,:FOLLOWME,:HEALORDER,
        :HEALPULSE,:HELPINGHAND,:IRONDEFENSE,:KINGSSHIELD,:LEECHSEED,:MILKDRINK,:MINIMIZE,:MOONLIGHT,:MORNINGSUN,
        :NASTYPLOT,:PERISHSONG,:PROTECT,:QUIVERDANCE,:RAGEPOWDER,:RECOVER,:REST,:ROCKPOLISH,:ROOST,:SHELLSMASH,
        :SHIFTGEAR,:SHOREUP,:SHELLSMASH,:SHIFTGEAR,:SHOREUP,:SLACKOFF,:SOFTBOILED,:SPORE,:SUBSTITUTE,:SWAGGER,
        :SWALLOW,:SWORDSDANCE,:SYNTHESIS,:TAILGLOW,:CLANGOROUSSOUL,:NORETREAT,:OBSTRUCT,:COURTCHANGE,:JUNGLEHEALING,
        :VICTORYDANCE,:AQUABATICS],
      [:heal]   => [:AROMATHERAPY,:BELLYDRUM,:CONVERSION2,:HAZE,:HEALBELL,:MIST,:PSYCHUP,:REFRESH,:SPITE,:STOCKPILE,
        :TELEPORT,:TRANSFORM,:DECORATE,:LIFEDEW,:LUNARBLESSING],
      [:heal2]  => [:MEMENTO,:PARTINGSHOT],
      [:centre] => [:DESTINYBOND,:GRUDGE],
    })
    z_effect_hash.default=[]
    z_effect = z_effect_hash[move]

    # Single stat boosting z-move
    if z_effect.length==2 
      if attacker.pbCanIncreaseStatStage?(z_effect[0],false)
      attacker.pbIncreaseStat(z_effect[0],z_effect[1],abilitymessage:false)
      boostlevel = ["","sharply ", "drastically "]
      @battle.pbDisplayBrief(_INTL("{1}'s Z-Power {2}boosted its {3}!",attacker.pbThis,boostlevel[z_effect[1]-1],attacker.pbGetStatName(z_effect[0])))
      return
      end
    end

    #Special effect
    case z_effect[0]
    when :allstat1
      increment = 1
      increment = 2 if @battle.FE == :CITY && [:CONVERSION,:HAPPYHOUR,:CELEBRATE].include?(move)
      increment = 2 if @battle.FE == :BACKALLEY && move == :CONVERSION 
      for stat in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED]
        if attacker.pbCanIncreaseStatStage?(stat,false)
          attacker.pbIncreaseStat(stat,increment,abilitymessage:false)
        end
      end
      @battle.pbDisplayBrief(_INTL("{1}'s Z-Power boosted its stats!",attacker.pbThis)) if increment == 1
      @battle.pbDisplayBrief(_INTL("{1}'s Z-Power sharply boosted its stats!",attacker.pbThis)) if increment == 2
    when :crit1
      if attacker.effects[:FocusEnergy]<3
        attacker.effects[:FocusEnergy]+=2
        attacker.effects[:FocusEnergy]=3 if attacker.effects[:FocusEnergy]>3
        @battle.pbDisplayBrief(_INTL("{1}'s Z-Power is getting it pumped!",attacker.pbThis))
      end
    when :reset
      for i in [PBStats::ATTACK,PBStats::DEFENSE,
                PBStats::SPEED,PBStats::SPATK,PBStats::SPDEF,
                PBStats::EVASION,PBStats::ACCURACY]
        if attacker.stages[i]<0
          attacker.stages[i]=0
        end
      end
      @battle.pbDisplayBrief(_INTL("{1}'s Z-Power returned its decreased stats to normal!",attacker.pbThis))
    when :heal
      attacker.pbRecoverHP(attacker.totalhp,false)
      @battle.pbDisplayBrief(_INTL("{1}'s Z-Power restored its health!",attacker.pbThis))
    when :heal2
      attacker.effects[:ZHeal]=true
    when :centre
      attacker.effects[:FollowMe]=true
      if !attacker.pbPartner.isFainted?
        attacker.pbPartner.effects[:FollowMe]=false
        attacker.pbPartner.effects[:RagePowder]=false
        @battle.pbDisplayBrief(_INTL("{1}'s Z-Power made it the centre of attention!",attacker.pbThis))
      end
    end
  end
end
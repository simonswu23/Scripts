class PokeBattle_Move
  attr_accessor   :move
  attr_reader     :battle
  attr_accessor   :name
  attr_accessor   :data
  attr_accessor   :basemove
  attr_accessor   :pp
  attr_accessor   :totalpp
  attr_accessor   :zmove
  attr_reader     :user
  attr_reader     :function
  attr_accessor   :type
  attr_reader     :category
  attr_accessor   :basedamage
  attr_reader     :accuracy
  attr_reader     :maxpp
  attr_reader     :target
  attr_reader     :desc
  attr_accessor   :priority
  attr_reader     :effect
  attr_reader     :moreeffect
  attr_accessor :fieldmessageshown
  attr_accessor :fieldmessageshown_type

################################################################################
# Creating a move
################################################################################
  def initialize(battle,move,user,zbase=nil)
    @battle = battle
    @move = move.move
    @data = $cache.moves[@move]
    @name = @data.name
    @basemove   = move
    @pp         = move.pp   # Can be changed with Mimic/Transform
    @zmove      = false
    @user       = user
    if @data
      @function   = @data.function
      @type       = @data.type
      @category   = @data.category
      @basedamage = @data.basedamage
      @accuracy   = @data.accuracy
      @maxpp      = @data.maxpp
      @target     = @data.target
      @desc       = @data.desc
      @priority   = @data.priority ? @data.priority : 0
      @effect     = @data.checkFlag?(:effect,0)
      @moreeffect = @data.checkFlag?(:moreeffect,0)
      @zmove      = @data.checkFlag?(:zmove,false)
    end 
    if !zbase.nil?
      @zmove      = true
      if PBStuff::TYPETOZCRYSTAL[zbase.type] == user.item
        @category   = zbase.category
        @name       = "Z-"+@name if zbase.basedamage == 0
        @basedamage = ZMoveBaseDamage(zbase) if zbase.basedamage > 0
      end
    end
  end

  def contactMove?
    return true if (@function == 0x309 || @function == 0x20D || @function == 0x900) && pbIsPhysical?(type = @type)
    return @data.nil? ? false : @data.checkFlag?(:contact)
  end

  def canProtect?
    return false if (@battle.FE == :COLOSSEUM && @move == :FIRSTIMPRESSION)
    return @data.nil? ? true : !@data.checkFlag?(:bypassprotect)
  end

  def canMagicCoat?
    return @data.nil? ? false : @data.checkFlag?(:magiccoat)
  end

  def canSnatch?
    return @data.nil? ? false : @data.checkFlag?(:snatchable)
  end

  def canMirror?  #supposedly unused.
    return @data.nil? ? false : !@data.checkFlag?(:nonmirror)
  end

  def canKingsRock?
    return @data.nil? ? false : @data.checkFlag?(:kingrock)
  end

  def canThawUser?
    return @data.nil? ? false : @data.checkFlag?(:defrost)
  end

  def highCritRate?
    return @data.nil? ? false : @data.checkFlag?(:highcrit)
  end

  def isHealingMove?
    return @data.nil? ? false : @data.checkFlag?(:healingmove)
  end

  def punchMove?
    return @data.nil? ? false : @data.checkFlag?(:punchmove)
  end

  def isSoundBased?
    return @data.nil? ? false : @data.checkFlag?(:soundmove)
  end

  def unusableInGravity?
    return @data.nil? ? false : @data.checkFlag?(:gravityblocked)
  end

  def isBeamMove?
    return @data.nil? ? false : @data.checkFlag?(:beammove)
  end

  def sharpMove?
    return @data.nil? ? false : @data.checkFlag?(:sharpmove)
  end

  def hasFlag?(flag)
    return @data.nil? ? false : @data.checkFlag?(flag)
  end

# This is the code actually used to generate a PokeBattle_Move object.  The
# object generated is a subclass of this one which depends on the move's
# function code (found in the script section PokeBattle_MoveEffect).
  def PokeBattle_Move.pbFromPBMove(battle,move,user,zbase=nil)
    className=nil if !move
    className=sprintf("PokeBattle_Move_%03X",$cache.moves[move.move].function) if move
    if !className.nil? 
      if Object.const_defined?(className)
        return Kernel.const_get(className).new(battle,move,user,zbase)
      else
        return PokeBattle_UnimplementedMove.new(battle,move,user,zbase)
      end
    else
      return nil
    end
  end

################################################################################
# About the move
################################################################################
  def totalpp
    return @totalpp if @totalpp && @totalpp>0
    return @basemove.totalpp if @basemove
  end

  def pbType(attacker,type=@type)
    case @battle.FE
      when :ASHENBEACH        then type=:FIGHTING   if @move == :STRENGTH
      when :GLITCH            then type=:NORMAL     if Glitchtypes.include?(type)
      when :MURKWATERSURFACE  then type=:WATER      if (@move == :MUDSLAP || @move == :MUDBOMB || @move == :MUDBARRAGE ||  @move == :MUDSHOT || @move == :THOUSANDWAVES)
      when :FAIRYTALE         then type=:STEEL      if (@move == :SACREDSWORD || @move == :CUT || @move == :SLASH || @move == :SECRETSWORD)
      when :STARLIGHT         then type=:FAIRY      if !Rejuv && (@move == :SOLARBEAM || @move == :SOLARBLADE)
      when :DIMENSIONAL       then type=:DARK       if @move == :RAGE
      when :DRAGONSDEN        then type=:ROCK       if Rejuv && (@move == :ROCKCLIMB || @move == :STRENGTH)
      when :DEEPEARTH         then type=:GROUND     if @move == :TOPSYTURVY
    end
    if !@zmove
      case attacker.ability 
        when :NORMALIZE   then type=:NORMAL
        when :PIXILATE    then type=:FAIRY    if type==:NORMAL && @battle.FE != :GLITCH
        when :AERILATE    then type=:FLYING   if type==:NORMAL
        when :GALVANIZE   then type=:ELECTRIC if type==:NORMAL
        when :REFRIGERATE then type=:ICE      if type==:NORMAL
        when :DUSKILATE   then type=:DARK     if type==:NORMAL && @battle.FE != :GLITCH
        when :LIQUIDVOICE then type= @battle.FE==:ICY ? :ICE : :WATER if isSoundBased?
      end
    end
    case attacker.crested
        when :SIMISEAR  then type=:WATER  if type==:NORMAL
        when :SIMIPOUR  then type=:GRASS  if type==:NORMAL
        when :SIMISAGE  then type=:FIRE   if type==:NORMAL
        when :LUXRAY  then type=:ELECTRIC   if type==:NORMAL
        when :SAWSBUCK
          case attacker.form
            when 0  then type=:WATER  if type==:NORMAL
            when 1  then type=:FIRE   if type==:NORMAL
            when 2  then type=:GROUND if type==:NORMAL
            when 3  then type=:ICE    if type==:NORMAL 
          end
    end
    if (attacker.effects[:Electrify] || type == :NORMAL && @battle.state.effects[:IonDeluge]) && !@zmove
      type=(:ELECTRIC)
    end
    return type
  end

  def pbIsPhysical?(type = @type)
    return (!PBTypes.isSpecialType?(type) && @category!=:status) if @battle.FE == :GLITCH
    return @category==:physical
  end

  def pbIsSpecial?(type = @type)
    return (PBTypes.isSpecialType?(type) && @category!=:status) if @battle.FE == :GLITCH
    return @category==:special
  end

  def pbIsStatus?
    return @category==:status
  end

  def betterCategory(type = @type)
    return :physical if pbIsPhysical?(type = @type)
    return :special if pbIsSpecial?(type = @type)
    return :status if pbIsStatus?
  end

  def pbHitsSpecialStat?(type = @type)
    return false if @function == 0x122  # Psyshock/Psystrike
    return true if @function == 0x204   # Matrix Shot/Psycho Cut
    return pbIsSpecial?(type)
  end

  def pbHitsPhysicalStat?(type = @type)
    return false if @function == 0x204
    return true if @function == 0x122
    return pbIsPhysical?(type)
  end

  def pbTargetsAll?(attacker)
    if @target==:AllOpposing 
      # TODO: should apply even if partner faints during an attack
      numtargets=0
      numtargets+=1 if !attacker.pbOpposing1.isFainted?
      numtargets+=1 if !attacker.pbOpposing2.isFainted?
      return numtargets>1
    elsif @target==:AllNonUsers
      # TODO: should apply even if partner faints during an attack
      numtargets=0
      numtargets+=1 if !attacker.pbOpposing1.isFainted?
      numtargets+=1 if !attacker.pbOpposing2.isFainted?
      numtargets+=1 if !attacker.pbPartner.isFainted?
      return numtargets>1
    end
    return false
  end

  def pbDragonDartTargetting(attacker) # all of this just to get dragon darts targeting right, i hate it here
    opp1 = attacker.pbOpposing1
    opp2 = attacker.pbOpposing2
    darttype = pbType(attacker)
    fieldsecondtype = self.getSecondaryType(attacker)
    # is either of the targets dead?
    if opp2.isFainted?
      return [opp1]
    end
    if opp1.isFainted?
      return [opp2]
    end
    # is either target immune by virtue of their type?
    if PBTypes.twoTypeEff(darttype,opp2.type1,opp2.type2) == 0 || (!fieldsecondtype.nil? && PBTypes.twoTypeEff(fieldsecondtype[0],opp2.type1,opp2.type2) == 0) || (!fieldsecondtype.nil? && fieldsecondtype.length>1 && PBTypes.twoTypeEff(fieldsecondtype[1],opp1.type1,opp1.type2) == 0)
      return [opp1]
    end
    if PBTypes.twoTypeEff(darttype,opp1.type1,opp1.type2) == 0 || (!fieldsecondtype.nil? && PBTypes.twoTypeEff(fieldsecondtype[0],opp1.type1,opp1.type2) == 0) || (!fieldsecondtype.nil? && fieldsecondtype.length>1 &&  PBTypes.twoTypeEff(fieldsecondtype[1],opp1.type1,opp1.type2) == 0)
      return [opp2]
    end
    # immunity effect via move?
    if PBStuff::TWOTURNMOVE.include?(opp2.effects[:TwoTurnAttack])
      return [opp1]
    end
    if PBStuff::TWOTURNMOVE.include?(opp1.effects[:TwoTurnAttack])
      return [opp2]
    end
    if opp2.effects[:SkyDrop]
      return [opp1]
    end
    if opp1.effects[:SkyDrop]
      return [opp2]
    end
    if opp2.effects[:Protect] || opp2.effects[:SpikyShield] || opp2.effects[:BanefulBunker] ||
       opp2.effects[:KingsShield] || opp2.effects[:Obstruct]
      return [opp1]
    end
    if opp1.effects[:Protect] || opp1.effects[:SpikyShield] || opp1.effects[:BanefulBunker] ||
       opp1.effects[:KingsShield] || opp1.effects[:Obstruct]
      return [opp2]
    end
    # immunity due to wonder guard?
    typemod1 = self.pbTypeModifier(darttype,attacker,opp1)
    typemod1 = self.fieldTypeChange(attacker,opp1,typemod1)
    typemod1 = self.overlayTypeChange(attacker,opp1,typemod1,false)
    typemod2 = self.pbTypeModifier(darttype,attacker,opp2)
    typemod2 = self.fieldTypeChange(attacker,opp2,typemod2)
    typemod2 = self.overlayTypeChange(attacker,opp2,typemod2,false)
    if opp1.ability == :WONDERGUARD && typemod1 <= 4
      return [opp2]
    end
    if opp2.ability == :WONDERGUARD && typemod2 <= 4
      return [opp1]
    end
    # immunity via immunity ability?
    if (darttype = :WATER || fieldsecondtype.include?(:WATER)) && (([:DRYSKIN,:WATERABSORB,:STORMDRAIN,:DETRITOVORE].include?(opp2.ability) && !opp2.moldbroken) || (Rejuv && @battle.FE == :GLITCH && opp2.species == :GENESECT && opp2.hasWorkingItem(:DOUSEDRIVE)))
      return [opp1]
    end
    if (darttype = :WATER || fieldsecondtype.include?(:WATER)) && (([:DRYSKIN,:WATERABSORB,:STORMDRAIN,:DETRITOVORE].include?(opp1.ability) && !opp1.moldbroken) || (Rejuv && @battle.FE == :GLITCH && opp1.species == :GENESECT && opp1.hasWorkingItem(:DOUSEDRIVE)))
      return [opp2]
    end
    if (darttype = :ELECTRIC || fieldsecondtype.include?(:ELECTRIC)) && (([:MOTORDRIVE,:VOLTABSORB,:LIGHTNINGROD].include?(opp2.ability) && !opp2.moldbroken) || (Rejuv && @battle.FE == :GLITCH && opp2.species == :GENESECT && opp2.hasWorkingItem(:SHOCKDRIVE)))
      return [opp1]
    end
    if (darttype = :ELECTRIC || fieldsecondtype.include?(:ELECTRIC)) && (([:MOTORDRIVE,:VOLTABSORB,:LIGHTNINGROD].include?(opp1.ability) && !opp1.moldbroken) || (Rejuv && @battle.FE == :GLITCH && opp1.species == :GENESECT && opp1.hasWorkingItem(:SHOCKDRIVE)))
      return [opp2]
    end
    if (darttype = :FIRE || fieldsecondtype.include?(:FIRE)) && (((opp1.ability == :HEATPROOF || (opp1.ability == :FLASHFIRE && @battle.FE != :FROZENDIMENSION) || (opp1.ability == :MAGMAARMOR && [:VOLCANICTOP,:DRAGONSDEN,:INFERNAL].include?(@battle.FE))) && !opp1.moldbroken) || (Rejuv && @battle.FE == :GLITCH && opp1.species == :GENESECT && opp1.hasWorkingItem(:BURNDRIVE)) || opp1.crested == :DRUDDIGON || opp1.crested == :VOLCARONA)
      return [opp2]
    end
    if (darttype = :FIRE || fieldsecondtype.include?(:FIRE)) && (((opp2.ability == :HEATPROOF || (opp2.ability == :FLASHFIRE && @battle.FE != :FROZENDIMENSION) || (opp2.ability == :MAGMAARMOR && [:VOLCANICTOP,:DRAGONSDEN,:INFERNAL].include?(@battle.FE))) && !opp2.moldbroken) || (Rejuv && @battle.FE == :GLITCH && opp2.species == :GENESECT && opp2.hasWorkingItem(:BURNDRIVE)) || opp2.crested == :DRUDDIGON || opp1.crested == :VOLCARONA)
      return [opp1]
    end
    if (darttype = :GRASS || fieldsecondtype.include?(:GRASS)) && (((opp1.ability == :SAPSIPPER) && !opp1.moldbroken) || opp1.crested == :WHISCASH || opp1.crested == :GASTRODON)
      return [opp2]
    end
    if (darttype = :GRASS || fieldsecondtype.include?(:GRASS)) && (((opp2.ability == :SAPSIPPER) && !opp2.moldbroken) || opp2.crested == :WHISCASH || opp2.crested == :GASTRODON)
      return [opp1]
    end
    if (darttype = :ICE || fieldsecondtype.include?(:ICE)) && (opp2.ability == :ICEBODY && !opp2.moldbroken) || (@battle.FE == :GLITCH && opp2.species == :GENESECT && opp2.hasWorkingItem(:CHILLDRIVE) && !opp2.moldbroken)
      return [opp1]
    end
    if (darttype = :ICE || fieldsecondtype.include?(:ICE)) && (opp1.ability == :ICEBODY && !opp1.moldbroken) || (@battle.FE == :GLITCH && opp1.species == :GENESECT && opp1.hasWorkingItem(:CHILLDRIVE) && !opp1.moldbroken)
      return [opp2]
    end
    if (darttype = :GROUND || fieldsecondtype.include?(:GROUND)) && (opp2.isAirborne? || opp2.crested == :SKUNTANK || ((opp2.ability == :BULLDOZER || opp2.ability == :DETRITOVORE) && !opp2.moldbroken))
      return [opp1]
    end
    if (darttype = :GROUND || fieldsecondtype.include?(:GROUND)) && (opp1.isAirborne? || opp1.crested == :SKUNTANK || ((opp1.ability == :BULLDOZER || opp1.ability == :DETRITOVORE) && !opp1.moldbroken))
      return [opp2]
    end
    if (darttype = :POISON || fieldsecondtype.include?(:POISON)) && ((opp1.ability == :DETRITOVORE) && !opp1.moldbroken)
      return [opp2]
    end
    if (darttype = :POISON || fieldsecondtype.include?(:POISON)) && ((opp2.ability == :DETRITOVORE) && !opp2.moldbroken)
      return [opp1]
    end
    
    # is dragon darts being called by a status move on a mon with prankster and is either target dark type?
    if attacker.ability == :PRANKSTER && opp1.hasType?(:DARK) && (@battle.choices[attacker.index][2]!=self) && @battle.FE != :BEWITCHED
      return [opp2]
    end
    if attacker.ability == :PRANKSTER && opp2.hasType?(:DARK) && (@battle.choices[attacker.index][2]!=self) && @battle.FE != :BEWITCHED
      return [opp1]
    end
=begin
    if opp2.effects[:Substitute]>0 || opp2.effects[:Disguise] || opp2.effects[:IceFace]
      return [opp1]
    end
    if opp1.effects[:Substitute]>0 || opp1.effects[:Disguise] || opp1.effects[:IceFace]
      return [opp2]
    end
=end
    # none of the above? target both!
    return [opp1,opp2]
  end

  # i am so upset, i have no words for my utter disgust at this mess, god fuck this move, i'd rather deal with Dragon Darts
  def smartDamageCategory(attacker,opponent)
    if @battle.FE == :GLITCH
      @category = betterCategory(@type)
      return
    end
    stagemul=[10,10,10,10,10,10,10,15,20,25,30,35,40]
    stagediv=[40,35,30,25,20,15,10,10,10,10,10,10,10]
    # Calculates how much Attack and SpAtk attacker has
    calcattackstage=attacker.stages[PBStats::ATTACK]+6
    # if photon geyser gets to be more accurate in calculation than normal, then shell side arm also gets to aswell
    calcatkmult = 1.0
    calcatkmult *= 1.5 if attacker.hasWorkingItem(:CHOICEBAND)
    if attacker.ability == :HUSTLE
      calcatkmult *= [:BACKALLEY,:CITY].include?(@battle.FE) ? 1.75 : 1.5
    end
    calcatkmult *= 1.5 if attacker.ability == :TOXICBOOST && (attacker.status== :POISON || @battle.FE == :CORROSIVE || @battle.FE == :CORROSIVEMIST || @battle.FE == :WASTELAND || @battle.FE == :MURKWATERSURFACE)
    calcatkmult *= 1.5 if attacker.ability == :GUTS && !attacker.status.nil?
    calcatkmult *= 0.5 if attacker.ability == :SLOWSTART && attacker.turncount<5 && !@battle.FE == :DEEPEARTH
    calcatkmult *= 2 if (attacker.ability == :PUREPOWER && @battle.FE != :PSYTERRAIN) || attacker.ability == :HUGEPOWER
    if ((@battle.pbWeather== :SUNNYDAY && !attacker.hasWorkingItem(:UTILITYUMBRELLA)) || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN) || @battle.FE == :BEWITCHED)
      calcatkmult*=1.5 if attacker.ability == :FLOWERGIFT && attacker.species == :CHERRIM
      calcatkmult*=1.5 if attacker.pbPartner.ability == :FLOWERGIFT && attacker.pbPartner.species == :CHERRIM
    end
    calcatkmult *= 2 if attacker.hasWorkingItem(:THICKCLUB) && ((attacker.pokemon.species == :CUBONE) || (attacker.pokemon.species == :MAROWAK))
    calcatkmult *= 0.5 if attacker.status== :BURN && !(attacker.ability == :GUTS && !attacker.status.nil?)
    # end attack boosts
    calcattack=(attacker.attack*1.0*(stagemul[calcattackstage]/stagediv[calcattackstage])*calcatkmult).floor
    calcspatkstage=attacker.stages[PBStats::SPATK]+6
    # same for special attack
    calcspatkmult=1.0
    calcspatkmult *= 1.5 if attacker.hasWorkingItem(:CHOICESPECS)
    calcspatkmult *= 2 if attacker.hasWorkingItem(:DEEPSEATOOTH) && (attacker.pokemon.species == :CLAMPERL)
    calcspatkmult *= 2 if attacker.hasWorkingItem(:LIGHTBALL) && (attacker.pokemon.species == :PIKACHU)
    calcspatkmult *= 1.5 if attacker.ability == :FLAREBOOST && (attacker.status== :BURN || @battle.FE == :BURNING || @battle.FE == :VOLCANIC || @battle.FE == :INFERNAL) &&  @battle.FE != :FROZENDIMENSION
    calcspatkmult *= 1.5 if attacker.ability == :MINUS && (attacker.pbPartner.ability == :PLUS || @battle.FE == :SHORTCIRCUIT || (Rejuv && @battle.FE == :ELECTERRAIN)) || @battle.state.effects[:ELECTERRAIN] > 0
    calcspatkmult *= 1.5 if attacker.ability == :PLUS && (attacker.pbPartner.ability == :MINUS || @battle.FE == :SHORTCIRCUIT || (Rejuv && @battle.FE == :ELECTERRAIN)) || @battle.state.effects[:ELECTERRAIN] > 0
    calcspatkmult *= 1.5 if attacker.ability == :SOLARPOWER && (@battle.pbWeather== :SUNNYDAY && !attacker.hasWorkingItem(:UTILITYUMBRELLA)) &&  @battle.FE != :FROZENDIMENSION
    calcspatkmult *= 1.3 if attacker.pbPartner.ability == :BATTERY
    calcspatkmult *= 2 if attacker.ability == :PUREPOWER && @battle.FE == :PSYTERRAIN
    # end spatk boosts
    calcspatk=(attacker.spatk*1.0*(stagemul[calcspatkstage]/stagediv[calcspatkstage])*calcspatkmult).floor
    # Calculates how much Defense and SpDef opponent has
    calcdefensestage=opponent.stages[PBStats::DEFENSE]+6
    # aaaand Defense
    calcdefmult = 1.0       
    calcdefmult*=1.5 if @battle.FE == :SNOWYMOUNTAIN && opponent.hasType?(:ICE) && @battle.pbWeather == :HAIL        
    calcdefmult*=1.5 if @battle.FE == :ICY && opponent.hasType?(:ICE) && @battle.pbWeather == :HAIL
    calcdefmult*=1.5 if opponent.hasType?(:ICE) && @battle.pbWeather == :HAIL
    calcdefmult*=1.5 if opponent.ability == :MARVELSCALE && (!opponent.status.nil? || ([:MISTY,:RAINBOW,:FAIRYTALE,:DRAGONSDEN,:STARLIGHT].include?(@battle.FE) || @battle.state.effects[:MISTY] > 0)) && !(opponent.moldbroken)
    calcdefmult*=1.5 if opponent.ability == :GRASSPELT && (@battle.FE == :GRASSY || @battle.FE == :FOREST || @battle.state.effects[:GRASSY] > 0) # Grassy Field
    calcdefmult*=2.0 if (opponent.ability == :FURCOAT || opponent.ability == :ADAMANTINEBODY) && !(opponent.moldbroken)
    if @battle.FE == :CLOUDS
      calcdefmult*=4.0 if opponent.ability == :FLUFFY && attacker.ability != :LONGREACH && !(opponent.moldbroken)
    else
      calcdefmult*=2.0 if opponent.ability == :FLUFFY && attacker.ability != :LONGREACH && !(opponent.moldbroken)
    end
    calcdefmult*=2.0 if opponent.hasWorkingItem(:METALPOWDER) && (opponent.pokemon.species == :DITTO) && !opponent.effects[:Transform]
    # end defense boosts
    calcdefense=(opponent.defense*1.0*(stagemul[calcdefensestage]/stagediv[calcdefensestage])*calcdefmult).floor
    calcspdefstage=opponent.stages[PBStats::SPDEF]+6
    # don't forget spdef
    calcspdefmult = 1.0       
    calcspdefmult*=1.5 if @battle.FE == :DESERT && opponent.hasType?(:GROUND)       
    calcspdefmult*=1.5 if @battle.FE == :MISTY && opponent.hasType?(:FAIRY)
    if ((@battle.pbWeather== :SUNNYDAY && !opponent.hasWorkingItem(:UTILITYUMBRELLA)) || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN) || @battle.FE == :BEWITCHED) && !(opponent.moldbroken)
      calcspdefmult*=1.5 if opponent.ability == :FLOWERGIFT && opponent.species == :CHERRIM
      calcspdefmult*=1.5 if opponent.pbPartner.ability == :FLOWERGIFT && opponent.pbPartner.species == :CHERRIM
    end
    calcspdefmult*=2.0 if opponent.ability == :ICESCALES && !(opponent.moldbroken)
    calcspdefmult*=1.5 if opponent.hasWorkingItem(:ASSAULTVEST)
    calcspdefmult*=1.5 if opponent.crested == :GOTHITELLE
    calcspdefmult*=2.0 if opponent.hasWorkingItem(:DEEPSEASCALE) && (opponent.pokemon.species == :CLAMPERL)
    # end spdef boosts
    calcspdef=(opponent.spdef*1.0*(stagemul[calcspdefstage]/stagediv[calcspdefstage])*calcspdefmult).floor

    # Compares difference between Atk/Def and SpAtk/SpDef to determine Physical or Special
    @category=(calcattack-calcdefense>calcspatk-calcspdef) ? :physical : :special
    return
  end

  #These functions are intended to be subclassed
  def pbNumHits(attacker)
    return 1
  end

  def pbIsMultiHit   # not the same as pbNumHits>1
    return false
  end

  def pbTwoTurnAttack(attacker,checking=false)
    return false
  end

  def pbAdditionalEffect(attacker,opponent)
  end

  def pbSecondAdditionalEffect(attacker,opponent)
  end

  def pbCanUseWhileAsleep?
    return false
  end
################################################################################
# This move's type effectiveness
################################################################################
  def pbTypeModifier(type,attacker,opponent,zorovar=false)
    return 4 if (type == :GROUND) && opponent.hasType?(:FLYING) && opponent.hasWorkingItem(:IRONBALL)
    atype=type # attack type
    otype1=opponent.type1
    otype2=opponent.type2
    if zorovar # ai being fooled by illusion
      otype1=opponent.effects[:Illusion].type1 #17
      otype2=opponent.effects[:Illusion].type2 #17
    end
    if (otype1 == :FLYING || otype2 == :FLYING) && opponent.effects[:Roost]
      otype1=nil if (otype1 == :FLYING)
      otype2=nil if (otype2 == :FLYING)
    end
    if (otype1 == :FIRE) && opponent.effects[:BurnUp]
      if (otype2.nil?)
        otype1=(:QMARKS) || 0
      else
        otype1=otype2
      end
    end
    if (otype2 == :FIRE) && opponent.effects[:BurnUp]
      otype2 = nil
    end
    mod1=PBTypes.oneTypeEff(atype,otype1)
    mod2=((otype1==otype2)||otype2.nil?) ? 2 : PBTypes.oneTypeEff(atype,otype2)
    
    if attacker.ability == :SCRAPPY || opponent.effects[:Foresight]
      mod1=2 if otype1 == :GHOST && (atype == :NORMAL || atype == :FIGHTING)
      mod2=2 if otype2 == :GHOST && (atype == :NORMAL || atype == :FIGHTING)
    end
    if attacker.ability == :CORROSION || attacker.ability == :TIDEPOOLTYRANT
      mod1=1 if otype1 == :STEEL && atype == :POISON
      mod2=1 if otype1 == :STEEL && atype == :POISON
    end
    if @battle.FE == :HOLY
      mod1=4 if (otype1 == :GHOST || otype1 == :DARK) && atype == :NORMAL
      mod2=4 if (otype2 == :GHOST || otype2 == :DARK) && atype == :NORMAL
      mod1=4 if  otype1 == :GHOST && @move == :SPIRITBREAK
      mod2=4 if  otype2 == :GHOST && @move == :SPIRITBREAK
    end
    if @battle.FE == :UNDERWATER
      mod1=2 if (otype1 == :WATER) && atype == :WATER
      mod2=2 if (otype2 == :WATER) && atype == :WATER
    end
    if @battle.FE == :FAIRYTALE
      mod1=4 if (otype1 == :DRAGON) && atype == :STEEL
      mod2=4 if (otype2 == :DRAGON) && atype == :STEEL
    end
    if @battle.FE == :DARKNESS3
      mod1=2 if (otype1 == :DARK || otype1 == :GHOST) && mod1>2
      mod2=2 if (otype2 == :DARK || otype2 == :GHOST) && mod2>2
    end
    if attacker.ability == :PIXILATE || attacker.ability == :AERILATE || attacker.ability == :DUSKILATE || attacker.ability == :REFRIGERATE || attacker.ability == :GALVANIZE || (attacker.ability == :LIQUIDVOICE && isSoundBased?)
      mod1=2 if (otype1 == :GHOST) && (atype == :NORMAL)
      mod2=2 if (otype2 == :GHOST) && (atype == :NORMAL)
    end
    if [:SAWSBUCK,:SIMISAGE,:SIMISEAR,:SIMISAGE].include?(attacker.crested)
        mod1=2 if (otype1 == :GHOST) && (atype == :NORMAL)
        mod2=2 if (otype2 == :GHOST) && (atype == :NORMAL)
    end
    if attacker.ability == :NORMALIZE
      mod1=2 if [:GROUND,:FAIRY,:FLYING,:NORMAL,:DARK].include?(otype1)
      mod1=1 if (otype1 == :STEEL)
      mod1=0 if (otype1 == :GHOST) && !opponent.effects[:Foresight]
      mod2=2 if [:GROUND,:FAIRY,:FLYING,:NORMAL,:DARK].include?(otype2)
      mod2=1 if (otype2 == :STEEL)
      mod2=0 if (otype2 == :GHOST) && !opponent.effects[:Foresight]
    end
    if opponent.effects[:Electrify]
      mod1=0 if (otype1 == :GROUND)
      mod1=4 if (otype1 == :FLYING)
      mod1=2 if [:GHOST,:FAIRY,:NORMAL,:DARK].include?(otype1)
      mod2=0 if (otype2 == :GROUND)
      mod2=4 if (otype2 == :FLYING)
      mod2=2 if [:GHOST,:FAIRY,:NORMAL,:DARK].include?(otype2)
    end
    if @battle.FE == :GLITCH
      mod1=0 if (otype1 == :GHOST) && Glitchtypes.include?(atype)
      mod2=0 if (otype2 == :GHOST) && Glitchtypes.include?(atype)
      mod1=2 if atype == :DRAGON
      mod2=2 if atype == :DRAGON
      mod1=0 if atype == :GHOST && (otype1 == :PSYCHIC)
      mod2=0 if atype == :GHOST && (otype2 == :PSYCHIC)
      mod1=4 if atype == :BUG && (otype1 == :POISON)
      mod2=4 if atype == :BUG && (otype2 == :POISON)
      mod1=4 if atype == :POISON && (otype1 == :BUG)
      mod2=4 if atype == :POISON && (otype2 == :BUG)
      mod1=2 if atype == :ICE && (otype1 == :FIRE)
      mod2=2 if atype == :ICE && (otype2 == :FIRE)
      mod1=1 if Rejuv && atype == :DARK && (otype1 == :STEEL)
      mod2=1 if Rejuv && atype == :DARK && (otype2 == :STEEL)
      mod1=1 if Rejuv && atype == :GHOST && (otype1 == :STEEL)
      mod2=1 if Rejuv && atype == :GHOST && (otype2 == :STEEL)
    end
    if @battle.FE == :HAUNTED
      mod1=2 if (otype1 == :NORMAL) && (atype == :GHOST)
      mod2=2 if (otype2 == :NORMAL) && (atype == :GHOST)
      mod1=4 if  otype1 == :GHOST && @move == :SPIRITBREAK
      mod2=4 if  otype2 == :GHOST && @move == :SPIRITBREAK
    end
    if @battle.FE == :BEWITCHED
      mod1=2 if (otype1 == :GRASS) && (atype == :POISON)
      mod2=2 if (otype2 == :GRASS) && (atype == :POISON)
      mod1=4 if (otype1 == :STEEL) && (atype == :FAIRY)
      mod2=4 if (otype2 == :STEEL) && (atype == :FAIRY)
      mod1=2 if (otype1 == :DARK) && (atype == :FAIRY)
      mod2=2 if (otype2 == :DARK) && (atype == :FAIRY)
      mod1=2 if (otype1 == :FAIRY) && (atype == :DARK)
      mod2=2 if (otype2 == :FAIRY) && (atype == :DARK)
    end
    if @battle.FE == :SKY
      mod1=4 if (otype1 == :FLYING) && @move == :BONEMERANG
      mod2=4 if (otype2 == :FLYING) && @move == :BONEMERANG
      mod1=4 if (otype1 == :FLYING) && attacker.ability == :LONGREACH
      mod2=4 if (otype2 == :FLYING) && attacker.ability == :LONGREACH
    end
    if @battle.FE == :INFERNAL
      mod1=4 if (otype1 == :GHOST) && (atype == :FIRE)
      mod2=4 if (otype2 == :GHOST) && (atype == :FIRE)
    end
    if opponent.effects[:Ingrain] || opponent.effects[:SmackDown] || @battle.state.effects[:Gravity]!=0
      mod1=2 if (otype1 == :FLYING) && (atype == :GROUND)
      mod2=2 if (otype2 == :FLYING) && (atype == :GROUND)
    end
    if opponent.effects[:MiracleEye]
      mod1=2 if (otype1 == :DARK) && (atype == :PSYCHIC)
      mod2=2 if (otype2 == :DARK) && (atype == :PSYCHIC)
    end
    if (opponent.hasWorkingItem(:RINGTARGET))
      mod1=2 if mod1==0
      mod2=2 if mod2==0
    end
    if !opponent.moldbroken
      if (atype == :FIRE && opponent.ability == :FLASHFIRE && @battle.FE != :FROZENDIMENSION) || 
        (atype == :GRASS && (opponent.ability == :SAPSIPPER)) ||
        (atype == :WATER && (opponent.ability == :WATERABSORB || opponent.ability == :STORMDRAIN || opponent.ability == :DRYSKIN || opponent.ability == :DETRITOVORE)) ||
        (atype == :ELECTRIC && (opponent.ability == :VOLTABSORB || opponent.ability == :LIGHTNINGROD || opponent.ability == :MOTORDRIVE)) ||
        (atype == :GROUND && (opponent.ability == :LEVITATE || opponent.ability == :SOLARIDOL || opponent.ability == :LUNARIDOL || opponent.ability == :HIVEQUEEN) && @battle.FE != :CAVE && @move != :THOUSANDARROWS && opponent.isAirborne?) ||
        (atype == :GROUND && (opponent.ability == :DETRITOVORE || opponent.ability == :BULLDOZER))
        (atype == :POISON && (opponent.ability == :PASTELVEIL || opponent.ability == :DETRITOVORE)) 
        mod1=0
      end
    end
    if @battle.FE == :CAVE || @move == :THOUSANDARROWS
      mod1=2 if (otype1 == :FLYING) && (atype == :GROUND)
      mod2=2 if (otype2 == :FLYING) && (atype == :GROUND)
    end
    if @move == :VENAMSKISS || @move == :CORROSIVEGAS || attacker.crested == :SWALOT
      mod1=4 if (otype1 == :STEEL) && (atype == :POISON)
      mod2=4 if (otype2 == :STEEL) && (atype == :POISON)
    end
    mod2=(otype1==otype2) ? 2 : mod2

    # Inversemode password
    if $game_switches[:Inversemode] && @battle.FE != :INVERSE
      mod1 = 1 if mod1==0
      mod2 = 1 if mod2==0
      return 16 / (mod1 * mod2)
    end
    return mod1*mod2
  end

  def pbTypeModifierNonBattler(type,attacker,opponent)
    return 4 if (type == :GROUND) && opponent.hasType?(:FLYING) && (opponent.item==:IRONBALL)
    atype=type # attack type
    otype1=opponent.type1
    otype2=opponent.type2
    mod1=PBTypes.oneTypeEff(atype,otype1)
    mod2=(otype1==otype2) ? 2 : PBTypes.oneTypeEff(atype,otype2)
    if @battle.FE == :CAVE || @move == :THOUSANDARROWS
      mod1=2 if (otype1 == :FLYING) && (atype == :GROUND)
      mod2=2 if (otype2 == :FLYING) && (atype == :GROUND)
    end
    if @move == :VENAMSKISS
      mod1=4 if (otype1 == :STEEL) && (atype == :POISON)
      mod2=4 if (otype2 == :STEEL) && (atype == :POISON)
    end
    if (opponent.item==:RINGTARGET)
      mod1=2 if mod1==0
      mod2=2 if mod2==0
    end
    if (attacker.ability == :SCRAPPY || @move == :SECRETSWORD)
      mod1=2 if (otype1 == :GHOST) && ((atype == :NORMAL) || (atype == :FIGHTING))
      mod2=2 if (otype2 == :GHOST) && ((atype == :NORMAL) || (atype == :FIGHTING))
    end
    if Rejuv && @battle.FE == :ELECTERRAIN
      mod1=2 if (otype1 == :GROUND) && (atype == :ELECTRIC) && attacker.ability == :TERAVOLT
      mod2=2 if (otype2 == :GROUND) && (atype == :ELECTRIC) && attacker.ability == :TERAVOLT
    end
    if @battle.FE == :HOLY
      mod1=4 if (otype1 == :GHOST || otype1 == :DARK) && atype == :NORMAL
      mod2=4 if (otype2 == :GHOST || otype2 == :DARK) && atype == :NORMAL
      mod1=4 if  otype1 == :GHOST && @move == :SPIRITBREAK
      mod2=4 if  otype2 == :GHOST && @move == :SPIRITBREAK
    end
    if (attacker.ability == :PIXILATE) || (attacker.ability == :AERILATE) || (attacker.ability == :DUSKILATE) || (attacker.ability == :REFRIGERATE) || (attacker.ability == :GALVANIZE) || ((attacker.ability == :LIQUIDVOICE) && isSoundBased?)
      mod1=2 if (otype1 == :GHOST) && (atype == :NORMAL)
      mod2=2 if (otype2 == :GHOST) && (atype == :NORMAL)
    end
    if attacker.crested
      if [:SAWSBUCK,:SIMISAGE,:SIMISEAR,:SIMISAGE,:LUXRAY].include?(attacker.species)
        mod1=2 if (otype1 == :GHOST) && (atype == :NORMAL)
        mod2=2 if (otype2 == :GHOST) && (atype == :NORMAL)
      end
    end
    if attacker.ability == :NORMALIZE
      mod1=2 if [:GROUND,:FAIRY,:FLYING,:NORMAL,:DARK].include?(otype1)
      mod1=1 if (otype1 == :STEEL)
      mod1=0 if (otype1 == :GHOST)
      mod2=2 if [:GROUND,:FAIRY,:FLYING,:NORMAL,:DARK].include?(otype2)
      mod2=1 if (otype2 == :STEEL)
      mod2=0 if (otype2 == :GHOST)
    end
    if @battle.FE == :GLITCH
      mod1=0 if (otype1 == :GHOST) && Glitchtypes.include?(atype)
      mod2=0 if (otype2 == :GHOST) && Glitchtypes.include?(atype)
      mod1=2 if atype == :DRAGON
      mod2=2 if atype == :DRAGON
      mod1=0 if atype == :GHOST && (otype1 == :PSYCHIC)
      mod2=0 if atype == :GHOST && (otype2 == :PSYCHIC)
      mod1=4 if atype == :BUG && (otype1 == :POISON)
      mod2=4 if atype == :BUG && (otype2 == :POISON)
      mod1=4 if atype == :POISON && (otype1 == :BUG)
      mod2=4 if atype == :POISON && (otype2 == :BUG)
      mod1=2 if atype == :ICE && (otype1 == :FIRE)
      mod2=2 if atype == :ICE && (otype2 == :FIRE)
      mod1=1 if Rejuv && atype == :DARK && (otype1 == :STEEL)
      mod2=1 if Rejuv && atype == :DARK && (otype2 == :STEEL)
      mod1=1 if Rejuv && atype == :GHOST && (otype1 == :STEEL)
      mod2=1 if Rejuv && atype == :GHOST && (otype2 == :STEEL)
    end
    if @battle.FE == :HAUNTED
      mod1=2 if (otype1 == :NORMAL) && (atype == :GHOST)
      mod2=2 if (otype2 == :NORMAL) && (atype == :GHOST)
    end
    if @battle.FE == :BEWITCHED
      mod1=2 if (otype1 == :GRASS) && (atype == :POISON)
      mod2=2 if (otype2 == :GRASS) && (atype == :POISON)
      mod1=4 if (otype1 == :STEEL) && (atype == :FAIRY)
      mod2=4 if (otype2 == :STEEL) && (atype == :FAIRY)
      mod1=2 if (otype1 == :DARK) && (atype == :FAIRY)
      mod2=2 if (otype2 == :DARK) && (atype == :FAIRY)
      mod1=2 if (otype1 == :FAIRY) && (atype == :DARK)
      mod2=2 if (otype2 == :FAIRY) && (atype == :DARK)
    end
    if @battle.FE == :SKY
      mod1=4 if (otype1 == :FLYING) && @move == :BONEMERANG
      mod2=4 if (otype2 == :FLYING) && @move == :BONEMERANG
      mod1=4 if (otype1 == :FLYING) && attacker.ability == :LONGREACH
      mod2=4 if (otype2 == :FLYING) && attacker.ability == :LONGREACH
    end
    if @battle.FE == :INFERNAL
      mod1=4 if (otype1 == :GHOST) && (atype == :FIRE)
      mod2=4 if (otype2 == :GHOST) && (atype == :FIRE)
    end
    if @battle.state.effects[:Gravity]!=0
      mod1=2 if (otype1 == :FLYING) && (atype == :GROUND)
      mod2=2 if (otype2 == :FLYING) && (atype == :GROUND)
    end
    return mod1*mod2
  end

  def pbStatusMoveAbsorption(type,attacker,opponent)
    if (opponent.ability == :SAPSIPPER) && !(opponent.moldbroken) && type == :GRASS
      if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK)
        opponent.pbIncreaseStatBasic(PBStats::ATTACK,1)
        @battle.pbCommonAnimation("StatUp",opponent,nil)
        @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!", opponent.pbThis,getAbilityName(opponent.ability)))
      else
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!", opponent.pbThis,getAbilityName(opponent.ability),self.name))
      end
      return 0
    end
    if (opponent.ability == :STORMDRAIN && type == :WATER) || (opponent.ability == :LIGHTNINGROD && type == :ELECTRIC) && !(opponent.moldbroken)
      if opponent.pbCanIncreaseStatStage?(PBStats::SPATK)
        if (Rejuv && @battle.FE == :SHORTCIRCUIT) && opponent.ability == :LIGHTNINGROD
          damageroll = @battle.field.getRoll(maximize_roll: (@battle.state.effects[:ELECTERRAIN] > 0))
          statboosts = [1,2,0,1,3]
          arrStatTexts=[_INTL("{1}'s {2} raised its Special Attack!",opponent.pbThis,getAbilityName(opponent.ability)), _INTL("{1}'s {2} sharply raised its Special Attack!",opponent.pbThis,getAbilityName(opponent.ability)),
            _INTL("{1}'s {2} drastically raised its Special Attack!",opponent.pbThis,getAbilityName(opponent.ability))]
          statboost = statboosts[PBStuff::SHORTCIRCUITROLLS.find_index(damageroll)]
          if statboost != 0
            opponent.pbIncreaseStatBasic(PBStats::SPATK,statboost)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(arrStatTexts[statboost-1])
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
              opponent.pbThis,getAbilityName(opponent.ability),self.name))
          end
        else
          opponent.pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbCommonAnimation("StatUp",opponent,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Special Attack!",
            opponent.pbThis,getAbilityName(opponent.ability)))
        end
      else
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
           opponent.pbThis,getAbilityName(opponent.ability),self.name))
      end
      return 0
    end
    if ((opponent.ability == :MOTORDRIVE && !(opponent.moldbroken)) || 
      (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:SHOCKDRIVE))) &&
      type == :ELECTRIC
      negator = getAbilityName(opponent.ability)
      negator = getItemName(opponent.item) if (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:SHOCKDRIVE))
      if opponent.pbCanIncreaseStatStage?(PBStats::SPEED)
        if (!Rejuv && @battle.FE == :SHORTCIRCUIT) || (Rejuv && @battle.FE == :FACTORY)
          opponent.pbIncreaseStatBasic(PBStats::SPEED,2)
          @battle.pbCommonAnimation("StatUp",opponent,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} sharply raised its Speed!",
          opponent.pbThis,negator))
        elsif (Rejuv && @battle.FE == :SHORTCIRCUIT)
          damageroll = @battle.field.getRoll(maximize_roll: (@battle.state.effects[:ELECTERRAIN] > 0))
          statboosts = [1,2,0,1,3]
          arrStatTexts=[_INTL("{1}'s {2} raised its Speed!",opponent.pbThis,negator), _INTL("{1}'s {2} sharply raised its Speed!",opponent.pbThis,negator),
            _INTL("{1}'s {2} drastically raised its Speed!",opponent.pbThis,negator)]
          statboost = statboosts[PBStuff::SHORTCIRCUITROLLS.find_index(damageroll)]
          if statboost != 0
            opponent.pbIncreaseStatBasic(PBStats::SPEED,statboost)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(arrStatTexts[statboost-1])
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
              opponent.pbThis,negator,self.name))
          end
        else
          opponent.pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",opponent,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Speed!",
          opponent.pbThis,negator))
        end
      else
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
        opponent.pbThis,negator,self.name))
      end
      return 0
    end
    if (!(opponent.moldbroken) && (((opponent.ability == :DRYSKIN || opponent.ability == :WATERABSORB || opponent.ability == :DETRITOVORE) &&  type == :WATER) || 
                                   (opponent.ability == :VOLTABSORB && type == :ELECTRIC))) ||
                                  ((opponent.ability == :LUNARIDOL || opponent.ability == :ICEBODY) && type == :ICE) ||
                                  ((opponent.ability == :BULLDOZER || opponent.ability == :DETRITOVORE) && type == :GROUND) ||
                                  (opponent.ability == :DETRITOVORE && type == :POISON)
                                  ((Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:DOUSEDRIVE)) && type == :WATER) ||
                                  ((Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:CHILLDRIVE)) && type == :ICE) ||
                                  ((Rejuv && @battle.FE == :DESERT) && (opponent.hasType?(:GRASS) || opponent.hasType?(:WATER)) && @battle.pbWeather == :SUNNYDAY && type == :WATER)
      if opponent.effects[:HealBlock]==0
        negator = getAbilityName(opponent.ability)
        if ![:WATERABSORB,:VOLTABSORB,:DRYSKIN,:LUNARIDOL,:ICEBODY,:BULLDOZER,:DETRITOVORE].include?(opponent.ability)
          negator = getItemName(opponent.item) if (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && (opponent.item == :DOUSEDRIVE || opponent.item == :CHILLDRIVE))
          negator = "unquenchable thirst" if (Rejuv && @battle.FE == :DESERT) && (opponent.hasType?(:GRASS) || opponent.hasType?(:WATER)) && @battle.pbWeather == :SUNNYDAY
        end
        if (Rejuv && @battle.FE == :SHORTCIRCUIT) && opponent.ability == :VOLTABSORB
          damageroll = @battle.field.getRoll(maximize_roll: (@battle.state.effects[:ELECTERRAIN] > 0))
          if opponent.pbRecoverHP(((opponent.totalhp/4.0)*damageroll).floor,true)>0
            @battle.pbDisplay(_INTL("{1}'s {2} restored its HP!",
              opponent.pbThis,negator))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} useless!",
            opponent.pbThis,negator,@name))
          end
        elsif opponent.pbRecoverHP((opponent.totalhp/4.0).floor,true)>0
          @battle.pbDisplay(_INTL("{1}'s {2} restored its HP!",
             opponent.pbThis,negator))
        else
          @battle.pbDisplay(_INTL("{1}'s {2} made {3} useless!",
          opponent.pbThis,negator,@name))
        end
        return 0
      end
    end
    if ((opponent.ability == :FLASHFIRE && !opponent.moldbroken) || opponent.crested == :VOLCARONA ||
        (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:BURNDRIVE))) && 
        type == :FIRE && @battle.FE != :FROZENDIMENSION
      negator = getAbilityName(opponent.ability)
      negator = getItemName(opponent.item) if (opponent.crested == :VOLCARONA || (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:BURNDRIVE)))
      if !opponent.effects[:FlashFire]
        opponent.effects[:FlashFire]=true
        @battle.pbDisplay(_INTL("{1}'s {2} activated, boosting the power of its fire moves!",
           opponent.pbThis,negator))
      else
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
           opponent.pbThis,negator,self.name))
      end
      return 0
    end
    # @SWu added Heatproof Here
    if type == :FIRE && (opponent.ability == :HEATPROOF || (opponent.ability == :MAGMAARMOR && (@battle.FE == :DRAGONSDEN || @battle.FE == :VOLCANICTOP || @battle.FE == :INFERNAL) && !(opponent.moldbroken)))
      @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
       opponent.pbThis,getAbilityName(opponent.ability),self.name))
      return 0
    end
    # Immunity Crests
    case opponent.crested
      when :SKUNTANK
        if type == :GROUND
          if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK)
            opponent.pbIncreaseStatBasic(PBStats::ATTACK,1)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!",
               opponent.pbThis,getItemName(opponent.item)))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
               opponent.pbThis,getItemName(opponent.item),self.name))
          end
          return 0
        end
      when :DRUDDIGON
        if type == :FIRE
          if opponent.effects[:HealBlock]==0
            if opponent.pbRecoverHP((opponent.totalhp/4.0).floor,true)>0
              @battle.pbDisplay(_INTL("{1}'s {2} restored its HP!",
                  opponent.pbThis,getItemName(opponent.item)))
            else
              @battle.pbDisplay(_INTL("{1}'s {2} made {3} useless!",
              opponent.pbThis,getItemName(opponent.item),@name))
            end
            return 0
          end
        end
      when :WHISCASH
        if type == :GRASS
          if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK)
            opponent.pbIncreaseStatBasic(PBStats::ATTACK,1)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!",
               opponent.pbThis,getItemName(opponent.item)))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
               opponent.pbThis,getItemName(opponent.item),self.name))
          end
          return 0
        end
      when :GASTRODON
        if type == :GRASS
          if opponent.pbCanIncreaseStatStage?(PBStats::SPDEF)
            opponent.pbIncreaseStatBasic(PBStats::SPDEF,2)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} sharply raised its Special Defense!",
               opponent.pbThis,getItemName(opponent.item)))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
               opponent.pbThis,getItemName(opponent.item),self.name))
          end
          return 0
        end
    end
    return 4
  end
  
  def pbTypeModMessages(type,attacker,opponent)
    secondtype = getSecondaryType(attacker)
    if opponent.ability == :SAPSIPPER && !(opponent.moldbroken) && (type == :GRASS || (!secondtype.nil? && secondtype.include?(:GRASS)))
      if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK)
        opponent.pbIncreaseStatBasic(PBStats::ATTACK,1)
        @battle.pbCommonAnimation("StatUp",opponent,nil)
        @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!",
           opponent.pbThis,getAbilityName(opponent.ability)))
      else
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
           opponent.pbThis,getAbilityName(opponent.ability),self.name))
      end
      return 0
    end
    if ((opponent.ability == :STORMDRAIN && (type == :WATER || (!secondtype.nil? && secondtype.include?(:WATER)))) ||
       (opponent.ability == :LIGHTNINGROD && (type == :ELECTRIC || (!secondtype.nil? && secondtype.include?(:ELECTRIC))))) && !(opponent.moldbroken)
      if opponent.pbCanIncreaseStatStage?(PBStats::SPATK)
        if (Rejuv && @battle.FE == :SHORTCIRCUIT) && opponent.ability == :LIGHTNINGROD
          damageroll = @battle.field.getRoll(maximize_roll: (@battle.state.effects[:ELECTERRAIN] > 0))
          statboosts = [1,2,0,1,3]
          arrStatTexts=[_INTL("{1}'s {2} raised its Special Attack!",opponent.pbThis,getAbilityName(opponent.ability)), _INTL("{1}'s {2} sharply raised its Special Attack!",opponent.pbThis,getAbilityName(opponent.ability)),
            _INTL("{1}'s {2} drastically raised its Special Attack!",opponent.pbThis,getAbilityName(opponent.ability))]
          statboost = statboosts[PBStuff::SHORTCIRCUITROLLS.find_index(damageroll)]
          if statboost != 0
            opponent.pbIncreaseStatBasic(PBStats::SPATK,statboost)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(arrStatTexts[statboost-1])
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
              opponent.pbThis,getAbilityName(opponent.ability),self.name))
          end
        else
          opponent.pbIncreaseStatBasic(PBStats::SPATK,1)
          @battle.pbCommonAnimation("StatUp",opponent,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Special Attack!",
            opponent.pbThis,getAbilityName(opponent.ability)))
        end
      else
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
           opponent.pbThis,getAbilityName(opponent.ability),self.name))
      end
      if @function==0xCB #Dive
        @battle.scene.pbUnVanishSprite(attacker)
      end
      return 0
    end
    if ((opponent.ability == :MOTORDRIVE && !opponent.moldbroken) ||
      (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:SHOCKDRIVE))) &&
      (type == :ELECTRIC || (!secondtype.nil? && secondtype.include?(:ELECTRIC)))
      negator = getAbilityName(opponent.ability)
      negator = getItemName(opponent.item) if (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:SHOCKDRIVE))
      if opponent.pbCanIncreaseStatStage?(PBStats::SPEED)
        if (!Rejuv && @battle.FE == :SHORTCIRCUIT) || (Rejuv && @battle.FE == :FACTORY)
          opponent.pbIncreaseStatBasic(PBStats::SPEED,2)
          @battle.pbCommonAnimation("StatUp",opponent,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} sharply raised its Speed!",
          opponent.pbThis,negator))
        elsif (Rejuv && @battle.FE == :SHORTCIRCUIT)
          damageroll = @battle.field.getRoll(maximize_roll: (@battle.state.effects[:ELECTERRAIN] > 0))
          statboosts = [1,2,0,1,3]
          arrStatTexts=[_INTL("{1}'s {2} raised its Speed!",opponent.pbThis,negator), _INTL("{1}'s {2} sharply raised its Speed!",opponent.pbThis,negator),
            _INTL("{1}'s {2} drastically raised its Speed!",opponent.pbThis,negator)]
          statboost = statboosts[PBStuff::SHORTCIRCUITROLLS.find_index(damageroll)]
          if statboost != 0
            opponent.pbIncreaseStatBasic(PBStats::SPEED,statboost)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(arrStatTexts[statboost-1])
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
              opponent.pbThis,negator,self.name))
          end
        else
          opponent.pbIncreaseStatBasic(PBStats::SPEED,1)
          @battle.pbCommonAnimation("StatUp",opponent,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} raised its Speed!",
          opponent.pbThis,negator))
        end
      else
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
        opponent.pbThis,negator,self.name))
      end
      return 0
    end
    # @SWu Ice Body not fully implemented
    if ((opponent.ability == :DRYSKIN && !(opponent.moldbroken)) && (type == :WATER || (!secondtype.nil? && secondtype.include?(:WATER)))) ||
      (opponent.ability == :VOLTABSORB && !(opponent.moldbroken) && (type == :ELECTRIC || (!secondtype.nil? && secondtype.include?(:ELECTRIC)))) ||
      (opponent.ability == :WATERABSORB && !(opponent.moldbroken) && (type == :WATER || (!secondtype.nil? && secondtype.include?(:WATER)))) ||
      (opponent.ability == :DETRITOVORE && !(opponent.moldbroken) && 
                                                                  (type == :WATER || type == :GROUND || type == :POISON || 
                                                                  (!secondtype.nil? && secondtype.include?(:WATER)) || (!secondtype.nil? && secondtype.include?(:GROUND)) || (!secondtype.nil? && secondtype.include?(:POISON)))) ||
      (opponent.ability == :BULLDOZER && !(opponent.moldbroken) && (type == :GROUND || (!secondtype.nil? && secondtype.include?(:GROUND)))) ||
      ((Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:DOUSEDRIVE)) && (type == :WATER || (!secondtype.nil? && secondtype.include?(:WATER)))) ||
      ((Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:CHILLDRIVE)) && (type == :ICE || (!secondtype.nil? && secondtype.include?(:ICE)))) ||
      ((Rejuv && @battle.FE == :DESERT) && (opponent.hasType?(:GRASS) || opponent.hasType?(:WATER)) && @battle.pbWeather == :SUNNYDAY && (type == :WATER || (!secondtype.nil? && secondtype.include?(:WATER))))
      if opponent.effects[:HealBlock]==0
        negator = getAbilityName(opponent.ability)
        if ![:WATERABSORB,:VOLTABSORB,:DRYSKIN,:BULLDOZER,:DETRITOVORE].include?(opponent.ability)
          negator = getItemName(opponent.item) if (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && (opponent.item == :DOUSEDRIVE || opponent.item == :CHILLDRIVE))
          negator = "unquenchable thirst" if (Rejuv && @battle.FE == :DESERT) && (opponent.hasType?(:GRASS) || opponent.hasType?(:WATER)) && @battle.pbWeather == :SUNNYDAY
        end
        if (Rejuv && @battle.FE == :SHORTCIRCUIT) && opponent.ability == :VOLTABSORB
          damageroll = @battle.field.getRoll(maximize_roll: (@battle.state.effects[:ELECTERRAIN] > 0))
          if opponent.pbRecoverHP(((opponent.totalhp/4.0)*damageroll).floor,true)>0
            @battle.pbDisplay(_INTL("{1}'s {2} restored its HP!",
              opponent.pbThis,negator))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} useless!",
            opponent.pbThis,negator,@name))
          end
        elsif opponent.pbRecoverHP((opponent.totalhp/4.0).floor,true)>0
          @battle.pbDisplay(_INTL("{1}'s {2} restored its HP!",
              opponent.pbThis,negator))
        else
          @battle.pbDisplay(_INTL("{1}'s {2} made {3} useless!",
          opponent.pbThis,negator,@name))
        end
        if @function==0xCB #Dive
          @battle.scene.pbUnVanishSprite(attacker)
        end
        return 0
      end
    end
    # Immunity Crests
    case opponent.crested
      when :SKUNTANK
        if (type == :GROUND || (!secondtype.nil? && secondtype.include?(:GROUND)))
          if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK)
            opponent.pbIncreaseStatBasic(PBStats::ATTACK,1)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!",
               opponent.pbThis,getItemName(opponent.item)))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
               opponent.pbThis,getItemName(opponent.item),self.name))
          end
          return 0
        end
      when :DRUDDIGON
        if (type == :FIRE || (!secondtype.nil? && secondtype.include?(:FIRE)))
          if opponent.effects[:HealBlock]==0
            if opponent.pbRecoverHP((opponent.totalhp/4.0).floor,true)>0
              @battle.pbDisplay(_INTL("{1}'s {2} restored its HP!",
                  opponent.pbThis,getItemName(opponent.item)))
            else
              @battle.pbDisplay(_INTL("{1}'s {2} made {3} useless!",
              opponent.pbThis,getItemName(opponent.item),@name))
            end
            return 0
          end
        end
      when :WHISCASH
        if (type == :GRASS || (!secondtype.nil? && secondtype.include?(:GRASS)))
          if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK)
            opponent.pbIncreaseStatBasic(PBStats::ATTACK,1)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!",
               opponent.pbThis,getItemName(opponent.item)))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
               opponent.pbThis,getItemName(opponent.item),self.name))
          end
          return 0
        end
      when :GASTRODON
        if (type == :GRASS || (!secondtype.nil? && secondtype.include?(:GRASS)))
          if opponent.pbCanIncreaseStatStage?(PBStats::SPDEF)
            opponent.pbIncreaseStatBasic(PBStats::SPDEF,2)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(_INTL("{1}'s {2} sharply raised its Special Defense!",
               opponent.pbThis,getItemName(opponent.item)))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
               opponent.pbThis,getItemName(opponent.item),self.name))
          end
          return 0
        end
    end
    if (opponent.ability == :BULLETPROOF) && !(opponent.moldbroken)
      if (PBStuff::BULLETMOVE).include?(@move)
        @battle.pbDisplay(_INTL("{1}'s {2} blocked the attack!",
        opponent.pbThis,getAbilityName(opponent.ability),self.name))
        return 0
      end
    end
    if @battle.FE == :ROCKY && (opponent.effects[:Substitute]>0 || opponent.stages[PBStats::DEFENSE] > 0)
      if (PBStuff::BULLETMOVE).include?(@move)
        @battle.pbDisplay(_INTL("{1} hid behind a rock to dodge the attack!",
        opponent.pbThis,getAbilityName(opponent.ability),self.name))
        return 0
      end
    end
    if ((opponent.ability == :FLASHFIRE && !opponent.moldbroken) || opponent.crested == :VOLCARONA ||
        (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:BURNDRIVE))) && 
        (type == :FIRE || (!secondtype.nil? && secondtype.include?(:FIRE))) && @battle.FE != :FROZENDIMENSION
      negator = getAbilityName(opponent.ability)
      negator = getItemName(opponent.item) if (opponent.crested == :VOLCARONA || (Rejuv && @battle.FE == :GLITCH && opponent.species == :GENESECT && opponent.hasWorkingItem(:BURNDRIVE)))
      if !opponent.effects[:FlashFire]
        opponent.effects[:FlashFire]=true
        @battle.pbDisplay(_INTL("{1}'s {2} activated, boosting the power of its fire moves!",
           opponent.pbThis,negator))
      else
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
           opponent.pbThis,negator,self.name))
      end
      return 0
    end
    if opponent.ability == :MAGMAARMOR && (type == :FIRE || (!secondtype.nil? && secondtype.include?(:FIRE))) &&
      (@battle.FE == :DRAGONSDEN || @battle.FE == :VOLCANICTOP || @battle.FE == :INFERNAL) && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
       opponent.pbThis,getAbilityName(opponent.ability),self.name))
      return 0
    end
    #Telepathy
    if ((opponent.ability == :TELEPATHY  && !opponent.moldbroken) || @battle.FE == :HOLY) && @basedamage>0
      if opponent.index == attacker.pbPartner.index
        @battle.pbDisplay(_INTL("{1} avoids attacks by its ally Pokémon!",opponent.pbThis))
        return 0
      end
    end
    # UPDATE Implementing Flying Press + Freeze Dry
    typemod=pbTypeModifier(type,attacker,opponent)
    typemod2= nil
    typemod3= nil
    if type == :FIRE && opponent.effects[:TarShot]
      typemod*=2
    end
    # Resistance-changing Crests
    if opponent.crested
      case opponent.species
      when :LUXRAY
        typemod /= 2 if (type == :GHOST || type == :DARK)
        typemod = 0 if type == :PSYCHIC 
      when :SAMUROTT
        typemod /= 2 if (type == :BUG || type == :DARK || type == :ROCK)
      when :LEAFEON
        typemod /= 4 if (type == :FIRE || type == :FLYING)
      when :GLACEON
        typemod /= 4 if (type == :ROCK || type == :FIGHTING)
      when :SIMISEAR
        typemod /= 2 if [:STEEL, :FIRE,:ICE].include?(type)
        typemod /= 2 if type == :WATER && @battle.FE != :UNDERWATER
      when :SIMIPOUR
        typemod /= 2 if [:GROUND,:WATER,:GRASS,:ELECTRIC].include?(type)
      when :SIMISAGE
        typemod /= 2 if [:BUG,:STEEL,:FIRE,:GRASS,:FAIRY].include?(type)
        typemod /= 2 if type == :ICE && @battle.FE != :GLITCH
      when :TORTERRA
        if !($game_switches[:Inversemode] ^ (@battle.FE == :INVERSE))
          typemod = 16 / typemod if typemod != 0
        end
      when :HYDREIGON
        typemod /= 8 if type == :FAIRY
      when :GOODRA
        typemod /= 2 if [:FAIRY, :GRASS, :POISON, :BUG, :FIGHTING].include?(type)
        typemod *= 2 if [:GROUND, :PSYCHIC].include?(type)
      when :CHERRIM
        typemod /= 4 if type == :FIRE
      when :GOTHITELLE
        if (opponent.type1 == :PSYCHIC)
          typemod /= 2 if (type == :DARK || type == :GHOST)
          typemod = 9 if type == :PSYCHIC
        elsif (opponent.type1 == :DARK)
          typemod /= 2 if (type == :FIGHTING)
        end
      end
    
    end
    typemod *= 4 if @move == :FREEZEDRY && opponent.hasType?(:WATER)
    typemod *= 4 if @move == :CUT && opponent.hasType?(:GRASS)
    typemod *= 4 if type == :DARK && opponent.hasType?(:FAIRY) && attacker.crested == :HYDREIGON
    if @move == :CUT && opponent.hasType?(:GRASS) && ((!Rejuv && @battle.FE == :FOREST) || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,2,5))
      typemod *= 2
    end
    if @move == :FLYINGPRESS
      if @battle.FE == :SKY
        if ((PBTypes.oneTypeEff(:FLYING, opponent.type1) > 2) || (PBTypes.oneTypeEff(:FLYING, opponent.type1) < 2 && $game_switches[:Inversemode]))
          typemod*=2
        end
        if ((PBTypes.oneTypeEff(:FLYING, opponent.type2) > 2) || (PBTypes.oneTypeEff(:FLYING, opponent.type2) < 2 && $game_switches[:Inversemode]))
          typemod*=2
        end
      else
        typemod2=pbTypeModifier(:FLYING,attacker,opponent)
        typemod3= ((typemod*typemod2)/4)
        typemod=typemod3
      end
    end

    # Field Effect second type changes 
    typemod=fieldTypeChange(attacker,opponent,typemod,false)
    typemod=overlayTypeChange(attacker,opponent,typemod,false)

    # Cutting typemod in half
    if @battle.pbWeather==:STRONGWINDS && (opponent.hasType?(:FLYING) && !opponent.effects[:Roost]) &&
      ((PBTypes.oneTypeEff(type, :FLYING) > 2) || (PBTypes.oneTypeEff(type, :FLYING) < 2 && ($game_switches[:Inversemode] || (@battle.FE == :INVERSE))))
       typemod /= 2
    end
    if @battle.FE == :SNOWYMOUNTAIN && opponent.ability == :ICESCALES && opponent.hasType?(:ICE) && !(opponent.moldbroken) &&
      ((PBTypes.oneTypeEff(type, :ICE) > 2) || (PBTypes.oneTypeEff(type, :ICE) < 2 && ($game_switches[:Inversemode] || (@battle.FE == :INVERSE))))
      typemod /= 2
    end
    if @battle.FE == :DRAGONSDEN && opponent.ability == :MULTISCALE && opponent.hasType?(:DRAGON) && !(opponent.moldbroken) &&
      ((PBTypes.oneTypeEff(type, :DRAGON) > 2) || (PBTypes.oneTypeEff(type, :DRAGON) < 2 && ($game_switches[:Inversemode] || (@battle.FE == :INVERSE))))
       typemod /= 2
    end
    if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,4,5) && opponent.hasType?(:GRASS) && 
      ((PBTypes.oneTypeEff(type, :GRASS) > 2) || (PBTypes.oneTypeEff(type, :GRASS) < 2 && ($game_switches[:Inversemode] || (@battle.FE == :INVERSE))))
       typemod /= 2
    end
    if @battle.FE == :BEWITCHED && opponent.hasType?(:FAIRY) && (opponent.ability == :PASTELVEIL || opponent.pbPartner.ability == :PASTELVEIL) && !(opponent.moldbroken) &&
      ((PBTypes.oneTypeEff(type, :FAIRY) > 2) || (PBTypes.oneTypeEff(type, :FAIRY) < 2 && ($game_switches[:Inversemode] || (@battle.FE == :INVERSE))))
      typemod /= 2
    end
    if typemod==0
      if @function==0x111
        return 1
      else
        @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
        if PBStuff::TWOTURNMOVE.include?(@move)
          @battle.scene.pbUnVanishSprite(attacker)
        end
      end
    end
    if (@move == :RAINBOWSCALES || @move == :NEEDLEPIERCE && typemod < 4)
      return 4
    end
    return typemod
  end

  def fieldTypeChange(attacker,opponent,typemod,return_type=false)
    case @battle.FE
      when :RAINBOW # Rainbow Field
        if (pbType(attacker) == :NORMAL) && pbIsSpecial?(pbType(attacker)) 
          moddedtype = @battle.getRandomType(:NORMAL)
        end
      when :CORROSIVEMIST # Corrosive Mist Field
        if (pbType(attacker) == :FLYING) && !pbIsPhysical?(pbType(attacker))
          moddedtype = :POISON
        end
      when :SHORTCIRCUIT # Shortcircuit Field
        if (pbType(attacker) == :STEEL) && attacker.ability == :STEELWORKER
          moddedtype = :ELECTRIC
        end
      when :CRYSTALCAVERN # Crystal Cavern
        if (pbType(attacker) == :ROCK) || (@move == :JUDGMENT || @move == :ROCKCLIMB || @move == :STRENGTH || @move == :MULTIATTACK || @move == :PRISMATICLASER)
          moddedtype = @battle.field.getRoll(update_roll: caller_locations.any? {|string| string.to_s.include?("pbCalcDamage")} && !return_type)
        end
      when :INVERSE # Inverse Field
        if !return_type
          if !$game_switches[:Inversemode]
            if typemod == 0
              typevar1 = PBTypes.oneTypeEff(@type,opponent.type1)
              typevar2 = PBTypes.oneTypeEff(@type,opponent.type2)
              typevar1 = 1 if typevar1==0
              typevar2 = 1 if typevar2==0
              typemod = typevar1 * typevar2
            end
            typemod = 16 / typemod
            #inverse field can (and should) just skip the rest
            return typemod if !return_type
          end
        end
    end
    if !moddedtype
      fieldmove = @battle.field.moveData(@move)
      moddedtype = fieldmove[:typemod] if fieldmove
    end
    if !moddedtype #if moddedtype is STILL nil
      currenttype = pbType(attacker)
      fieldtype = @battle.field.typeData(currenttype)
      moddedtype = fieldtype[:typemod] if fieldtype
    end
    if return_type
      return moddedtype ? moddedtype : nil
    else
      return typemod if !moddedtype
      newtypemod = pbTypeModifier(moddedtype,attacker,opponent)
      typemod = ((typemod*newtypemod) * 0.25).ceil
      return typemod
    end
  end

  def overlayTypeChange(attacker,opponent,typemod,return_type=false)
    for field in $cache.FEData.keys
      next if !field.is_a?(Symbol)
      next if $cache.FEData[field].overlaymovedata.empty?
      next if @battle.state.effects[field] == 0
      overlaymove = $cache.FEData[field].overlaymovedata[@move]
      moddedtype = overlaymove[:typemod] if overlaymove
    end
    if return_type
      return moddedtype ? moddedtype : nil
    else
      return typemod if !moddedtype
      newtypemod = pbTypeModifier(moddedtype,attacker,opponent)
      typemod = ((typemod*newtypemod) * 0.25).ceil
      return typemod
    end
  end

  def getSecondaryType(attacker)
    secondtype = []
    secondtype.push(:FLYING) if @move == :FLYINGPRESS
    fieldtype = fieldTypeChange(attacker,nil,nil,true)
    secondtype.push(fieldtype) if fieldtype
    overlaytype = overlayTypeChange(attacker,nil,nil,true)
    secondtype.push(overlaytype) if overlaytype
    secondtype = [secondtype[0],secondtype[1]] if secondtype.length>2
    return secondtype.empty? ? nil : secondtype
  end
  
################################################################################
# This move's accuracy check
################################################################################
  def pbAccuracyCheck(attacker,opponent)
    baseaccuracy=self.accuracy
    # Field Effects
    fieldmove = @battle.field.moveData(@move)
		baseaccuracy = fieldmove[:accmod] if fieldmove && fieldmove[:accmod]
    return true if baseaccuracy==0
    return true if attacker.ability == :NOGUARD || opponent.ability == :NOGUARD || (attacker.ability == (:FAIRYAURA) && @battle.FE == :FAIRYTALE)
    return true if opponent.effects[:Telekinesis]>0
    return true if @function==0x0D && @battle.pbWeather== :HAIL # Blizzard
    return true if @move == :MIRAGEBEAM && @battle.pbWeather== :SUNNYDAY
    return true if @move == :MOUNTAINGALE && @battle.pbWeather == :HAIL
    return true if @move == :HEATWAVE && @battle.pbWeather== :SUNNYDAY # Heat Wave
    return true if @move == :PRECIPICEBLADES && @battle.pbWeather ==:DESOLATELAND
    return true if @move == :ORIGINPULSE && @battle.pbWeather ==:PRIMORDIALSEA
    return true if @move == :SPRINGTIDESTORM && @battle.pbWeather ==:SUNNYDAY
    return true if @move == :WILDBOLTSTORM && @battle.pbWeather ==:RAINDANCE
    return true if @move == :SANDSEARSTORM && @battle.pbWeather ==:SANDSTORM
    return true if @move == :BLEAKWINDSTORM && @battle.pbWeather ==:HAIL
    return true if (@function==0x08 || @function==0x15) && @battle.pbWeather== :RAINDANCE # Thunder, Hurricane
    return true if @type == :ELECTRIC && @battle.FE == :UNDERWATER
    return true if attacker.hasType?(:POISON) && @move == :TOXIC
    return true if attacker.hasType?(:ICE) && @move == :FLURRY
    return true if attacker.hasType?(:ELECTRIC) && @move == :THUNDERWAVE
    return true if attacker.hasType?(:FIRE) && @move == :WILLOWISP
    return true if (@function==0x10 || @move == :BODYSLAM ||
                    @function==0x137 || @function==0x9B) &&
                    opponent.effects[:Minimize] # Flying Press, Stomp, DRush
    return true if @battle.FE == :MIRROR && (PBFields::BLINDINGMOVES + [:MIRRORSHOT]).include?(@move)
    # One-hit KO accuracy handled elsewhere
    if @function==0x08 || @function==0x15 # Thunder, Hurricane
      baseaccuracy=50 if (@battle.pbWeather== :SUNNYDAY && !attacker.hasWorkingItem(:UTILITYUMBRELLA))
    end
    accstage=attacker.stages[PBStats::ACCURACY]
    accstage=0 if opponent.ability == :UNAWARE && !(opponent.moldbroken)
    accuracy=(accstage>=0) ? (accstage+3)*100.0/3 : 300.0/(3-accstage)
    evastage=opponent.stages[PBStats::EVASION]
    evastage-=2 if @battle.state.effects[:Gravity]!=0
    evastage=-6 if evastage<-6
    evastage=0 if opponent.effects[:Foresight] || opponent.effects[:MiracleEye] || @function==0xA9 || # Chip Away
                  attacker.ability == :UNAWARE && !(opponent.moldbroken)
    evasion=(evastage>=0) ? (evastage+3)*100.0/3 : 300.0/(3-evastage)
    if attacker.ability == :COMPOUNDEYES
      accuracy*=1.3
    end
    if attacker.hasWorkingItem(:MICLEBERRY)
      if (attacker.ability == :GLUTTONY && attacker.hp<=(attacker.totalhp/2.0).floor) ||
        attacker.hp<=(attacker.totalhp/4.0).floor
        accuracy*=1.2
        attacker.pbDisposeItem(true)
      end
    end
    if attacker.ability == :VICTORYSTAR
      accuracy*=1.1
    end
    partner=attacker.pbPartner
    if partner && partner.ability == :VICTORYSTAR
      accuracy*=1.1
    end
    if attacker.hasWorkingItem(:WIDELENS)
      accuracy*=1.1
    end
    # Hypno Crest, Stantler Crest
    if [:HYPNO,:STANTLER,:WYRDEER].include?(attacker.crested)
      accuracy *= 1.5
    end
    if attacker.crested == :DARKRAI
      accuracy *= 1.2
    end
    if attacker.hasWorkingItem(:ZOOMLENS) && attacker.speed < opponent.speed
      accuracy*=1.2
    end
    if attacker.ability == :HUSTLE && @basedamage>0 && pbIsPhysical?(pbType(attacker))
      accuracy*= [:BACKALLEY,:CITY].include?(@battle.FE) ? 0.67 : 0.8
    end
    if attacker.ability == :LONGREACH && (@battle.FE == :ROCKY || (!Rejuv && @battle.FE == :FOREST)) # Rocky/ Forest Field
      accuracy*=0.9
    end
    if (opponent.ability == :WONDERSKIN || (Rejuv && @battle.FE == :PSYTERRAIN && opponent.ability == :MAGICIAN)) && 
      @basedamage==0 && attacker.pbIsOpposing?(opponent.index) && !(opponent.moldbroken)
      if @battle.FE == :RAINBOW
        accuracy*=0
      else
        accuracy*=0.5
      end
    end
    if opponent.ability == :TANGLEDFEET && opponent.effects[:Confusion]>0 && !(opponent.moldbroken)
      evasion*=1.2
    end
    if opponent.ability == :SANDVEIL && (@battle.pbWeather== :SANDSTORM || @battle.FE == :DESERT || @battle.FE == :ASHENBEACH) && !(opponent.moldbroken)
      evasion*=1.2
    end
    if opponent.ability == :SNOWCLOAK && (@battle.pbWeather== :HAIL || @battle.FE == :ICY || @battle.FE == :SNOWYMOUNTAIN || @battle.FE == :FROZENDIMENSION) && !(opponent.moldbroken)
      evasion*=1.2
    end
    if opponent.hasWorkingItem(:BRIGHTPOWDER)
      evasion*=1.1
    end
    if opponent.hasWorkingItem(:LAXINCENSE)
      evasion*=1.1
    end
    evasion = 100 if attacker.ability == :KEENEYE
    evasion = 100 if @battle.FE == :ASHENBEACH && (attacker.ability == :OWNTEMPO || attacker.ability == :INNERFOCUS || attacker.ability == :PUREPOWER || attacker.ability == :SANDVEIL || attacker.ability == :STEADFAST) && (opponent.ability != :UNNERVE || opponent.ability != :ASONE)
    return @battle.pbRandom(100)<(baseaccuracy*accuracy/evasion)
  end

################################################################################
# Damage calculation and modifiers
################################################################################
  def pbCritRate?(attacker,opponent)
    return -1 if self.is_a?(PokeBattle_Confusion)
    return -1 if (opponent.ability == :BATTLEARMOR || opponent.ability == :SHELLARMOR) && !(opponent.moldbroken)
    return -1 if opponent.pbOwnSide.effects[:LuckyChant]>0
    return 3 if attacker.effects[:LaserFocus]>0 || @function==0xA0 || @function==0x319 # Frost Breath, Surging Strikes
    return 3 if @function==0x201 && attacker.hp<=((attacker.totalhp)*0.5).floor # Gale Strike
    return 3 if attacker.ability == :MERCILESS && (opponent.status == :POISON || [:CORROSIVE,:CORRPSIVEMIST,:WASTELAND,:MURKWATERSURFACE].include?(@battle.FE))
    return 3 if attacker.ability == :TIDEPOOLTYRANT && (!opponent.status.nil? || [:CORROSIVE,:CORRPSIVEMIST,:WASTELAND,:MURKWATERSURFACE].include?(@battle.FE))
    return 3 if (opponent.ability == :RATTLED || opponent.ability == :WIMPOUT) && @battle.FE == :COLOSSEUM
    return 3 if attacker.crested == :ARIADOS && (opponent.status == :POISON || opponent.stages[PBStats::SPEED] < 0 || !opponent.hasMovedThisRound?) # ariados crest
    return 3 if (attacker.ability == :QUICKDRAW && attacker.effects[:QuickDrawSnipe])
    c=0    
    c+=attacker.effects[:FocusEnergy]
    c+=1 if !@data.nil? && highCritRate?
    c+=1 if attacker.inHyperMode? && getMoveType(@move) == :SHADOW
    c+=1 if attacker.ability == :SUPERLUCK
    c+=2 if attacker.hasWorkingItem(:STICK) && (attacker.pokemon.species == :FARFETCHD || attacker.pokemon.species == :SIRFETCHD)
    c+=2 if attacker.hasWorkingItem(:LUCKYPUNCH) && (attacker.pokemon.species == :CHANSEY)
    if @battle.FE == :MIRROR
      buffs = 0
      buffs = attacker.stages[PBStats::EVASION] if attacker.stages[PBStats::EVASION] > 0
      buffs = buffs.to_i + attacker.stages[PBStats::ACCURACY] if attacker.stages[PBStats::ACCURACY] > 0
      buffs = buffs.to_i - opponent.stages[PBStats::EVASION] if opponent.stages[PBStats::EVASION] < 0
      buffs = buffs.to_i - opponent.stages[PBStats::ACCURACY] if opponent.stages[PBStats::ACCURACY] < 0
      buffs = buffs.to_i
      c += buffs if buffs > 0
    end
    c+=1 if attacker.hasWorkingItem(:RAZORCLAW)
    c+=1 if attacker.hasWorkingItem(:SCOPELENS)
    c+=3 if sharpMove? && attacker.crested == :SAMUROTT
    c+=1 if attacker.crested == :FEAROW # Fearow Crest
    c+=1 if attacker.speed > opponent.speed && @battle.FE == :GLITCH
    if Rejuv && @battle.FE == :CHESS
      c+=1 if (opponent.ability == :RECKLESS || opponent.ability == :GORILLATACTICS)
      c+=1 if [:STOMPINGTANTRUM,:THRASH,:OUTRAGE].include?(opponent.lastMoveUsed) 
      if attacker.ability == :MERCILESS || attacker.ability == :TIDEPOOLTYRANT
        frac = (1.0*opponent.hp) / (1.0*opponent.totalhp)  
        if frac < 0.8  
          c+=1  
        elsif frac < 0.6  
          c+=2  
        elsif frac < 0.4  
          c+=3  
        end  
      end
    end
    c=3 if c>3
    return c
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    return basedmg
  end

  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    return damagemult
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    return damagemult
  end
  
  def pbCalcDamage(attacker,opponent,options=0, hitnum: 0)
    opponent.damagestate.critical=false
    opponent.damagestate.typemod=0
    opponent.damagestate.calcdamage=0
    opponent.damagestate.hplost=0
    basedmg=@basedamage # From PBS file
    basedmg = [attacker.happiness,250].min if attacker.crested == :LUVDISC && basedmg != 0
    basedmg=pbBaseDamage(basedmg,attacker,opponent) # Some function codes alter base power
    return 0 if basedmg==0
    basedmg = basedmg*0.3 if attacker.crested == :CINCCINO && !pbIsMultiHit
    critchance = pbCritRate?(attacker,opponent)
    if critchance >= 0
      ratios=[24,8,2,1]
      opponent.damagestate.critical= @battle.pbRandom(ratios[critchance])==0
    end
    stagemul=[2,2,2,2,2,2,2,3,4,5,6,7,8]
    stagediv=[8,7,6,5,4,3,2,2,2,2,2,2,2]
    type=pbType(attacker)
    ##### Calcuate base power of move #####
   
    basemult=1.0
    #classic prep stuff
    attitemworks = attacker.itemWorks?(true)
    oppitemworks = opponent.itemWorks?(true)
    case attacker.ability
      when :TECHNICIAN
        if basedmg<=60
          basemult*=1.5
        elsif (@battle.FE == :FACTORY || @battle.ProgressiveFieldCheck(PBFields::CONCERT)) && basedmg<=80
          basemult*=1.5
        end
      when :STRONGJAW     then basemult*=1.5 if (PBStuff::BITEMOVE).include?(@move)
      when :SHARPNESS     then basemult*=1.5 if sharpMove?
      when :TRUESHOT      then basemult*=1.3 if (PBStuff::BULLETMOVE).include?(@move)
      when :TOUGHCLAWS    then basemult*=1.3 if contactMove?
      when :IRONFIST
        if @battle.FE == :CROWD
          basemult*=1.2 if punchMove?
        else
          basemult*=1.2 if punchMove?
        end
      when :RECKLESS      then basemult*=1.2 if [0xFA,0xFA,0xFA,0xFA,0xFA].include?(@function)
      when :FLAREBOOST    then basemult*=1.5 if (attacker.status== :BURN || @battle.FE == :BURNING || @battle.FE == :VOLCANIC || @battle.FE == :INFERNAL) && pbIsSpecial?(type) && @battle.FE != :FROZENDIMENSION
      when :TOXICBOOST    
        if (attacker.status== :POISON || @battle.FE == :CORROSIVE || @battle.FE == :CORROSIVEMIST || @battle.FE == :WASTELAND || @battle.FE == :MURKWATERSURFACE) && pbIsPhysical?(type)
          if @battle.FE == :CORRUPTED
            basemult*=2.0
          else
            basemult*=1.5
          end
        end
      when :PUNKROCK
        if isSoundBased?
          case @battle.FE
            when :BIGTOP then basemult*=1.5
            when :CAVE then basemult*=1.5
            else
              basemult*=1.3 
          end
        end
      when :LIQUIDVOICE
        basemult*=1.3 if isSoundBased?
      when :RIVALRY       then basemult*= attacker.gender==opponent.gender ? 1.25 : 0.75 if attacker.gender!=2
      when :MEGALAUNCHER  then basemult*=1.5 if [:AURASPHERE,:DRAGONPULSE,:DARKPULSE,:WATERPULSE,:ORIGINPULSE,:TERRAINPULSE].include?(@move)
      when :SANDFORCE     then basemult*=1.3 if (@battle.pbWeather== :SANDSTORM || @battle.FE == :DESERT || @battle.FE == :ASHENBEACH) && (type == :ROCK || type == :GROUND || type == :STEEL)
      when :ANALYTIC      then basemult*=1.3 if (@battle.battlers.find_all {|battler| battler && battler.hp > 0 && !battler.hasMovedThisRound? }).length == 0
      when :SHEERFORCE    then basemult*=1.3 if effect > 0
      when :AERILATE 
        if @type == :NORMAL && type == :FLYING
          case @battle.FE
            when :MOUNTAIN,:SNOWYMOUNTAIN,:SKY then basemult*=1.5
            else
              basemult*=1.3
          end
        end
      when :GALVANIZE
        if @type == :NORMAL && type == :ELECTRIC
          case @battle.FE
            when :ELECTERRAIN,:FACTORY then basemult*=1.5
            when :SHORTCIRCUIT then basemult*=2
            else
              if @battle.state.effects[:ELECTERRAIN] > 0
                basemult*=1.5
              else 
                basemult*=1.3
              end
          end
        end
      when :REFRIGERATE 
        if @type == :NORMAL && type == :ICE
          case @battle.FE
            when :ICY,:SNOWYMOUNTAIN,:FROZENDIMENSION then basemult*=1.5
            else
              basemult*=1.3
          end
        end
      when :PIXILATE 
        if @type == :NORMAL && (type == :FAIRY || (type == :NORMAL && @battle.FE == :GLITCH))
          case @battle.FE
            when :MISTY then basemult*=1.5
            else
              if @battle.state.effects[:MISTY] > 0
                basemult*=1.5
              else 
                basemult*=1.3
              end
          end
        end
      when :DUSKILATE     then basemult*=1.3 if @type == :NORMAL && (type == :DARK || (type == :NORMAL && @battle.FE == :GLITCH))
      when :NORMALIZE     then basemult*=1.3 if !@zmove
      when :TRANSISTOR    then basemult*=1.5 if type == :ELECTRIC
      when :DRAGONSMAW    then basemult*=1.5 if type == :DRAGON
      when :TERAVOLT      then basemult*=1.5 if (Rejuv && @battle.FE == :ELECTERRAIN && type == :ELECTRIC)
      when :INEXORABLE    then basemult*=1.3 if type == :DRAGON && (!opponent.hasMovedThisRound? || @battle.switchedOut[opponent.index])
    end
    case opponent.ability
      when :DRYSKIN       then basemult*=1.25 if !(opponent.moldbroken) && type == :FIRE
      when :TRANSISTOR    then basemult*=0.5 if (@battle.FE == :ELECTERRAIN && type == :GROUND) && !(opponent.moldbroken)
    end
    if attitemworks
      if $cache.items[attacker.item].checkFlag?(:typeboost) == type
        basemult*=1.2
        if $cache.items[attacker.item].checkFlag?(:gem)
          # buffing gems to 1.5
          basemult *= 1.25
          attacker.takegem=true
          @battle.pbDisplay(_INTL("The {1} strengthened {2}'s power!",getItemName(attacker.item),self.name))
        end
      else
        case attacker.item
          when :MUSCLEBAND then basemult*=1.1 if pbIsPhysical?(type)
          when :WISEGLASSES then basemult*=1.1 if pbIsSpecial?(type)
          when :LUSTROUSORB then basemult*=1.2 if (attacker.pokemon.species == :PALKIA) && (type == :DRAGON || type == :WATER)
          when :ADAMANTORB then basemult*=1.2 if (attacker.pokemon.species == :DIALGA) && (type == :DRAGON || type == :STEEL)
          when :GRISEOUSORB then basemult*=1.2 if (attacker.pokemon.species == :GIRATINA) && (type == :DRAGON || type == :GHOST)
          when :SOULDEW then basemult*=1.2 if (attacker.pokemon.species == :LATIAS || attacker.pokemon.species == :LATIOS) && (type == :DRAGON || type == :PSYCHIC)
        end
      end
    end
    basemult=pbBaseDamageMultiplier(basemult,attacker,opponent)
    # standard crest damage multipliers
    case attacker.crested
      when :FERALIGATR then basemult*=1.5 if (PBStuff::BITEMOVE).include?(@move) 
      when :CLAYDOL then basemult*=1.5 if isBeamMove?
      when :DRUDDIGON then basemult*=1.3 if (type == :DRAGON || type == :FIRE)
      when :BOLTUND then basemult*=1.5 if (PBStuff::BITEMOVE).include?(@move) && (!(opponent.hasMovedThisRound?) || @battle.switchedOut[opponent.index])
      when :FEAROW then basemult*=1.5 if (PBStuff::STABBINGMOVE).include?(@move)
      when :DUSKNOIR then basemult*=1.5 if (basedmg<=60 || ((@battle.FE == :FACTORY || @battle.ProgressiveFieldCheck(PBFields::CONCERT))&& basedmg<=80))
      when :CRABOMINABLE then basemult*=1.5 if attacker.lastHPLost>0
      when :AMPHAROS then basemult*= attacker.hasType?(type) ? 1.2 : 1.5 if attacker.moves[0] == self
      when :LUXRAY then basemult *= 1.2 if @type == :NORMAL && type == :ELECTRIC
      when :SAWSBUCK  
        case attacker.form
        when 0 then basemult*=1.2 if @type == :NORMAL && type == :WATER
        when 1 then basemult*=1.2 if @type == :NORMAL && type == :FIRE
        when 2 then basemult*=1.2 if @type == :NORMAL && type == :GROUND
        when 3 then basemult*=1.2 if @type == :NORMAL && type == :ICE
        end
    end
    #type mods
    case type
      when :FIRE then basemult*=0.33 if @battle.state.effects[:WaterSport]>0
      when :ELECTRIC 
        basemult*=0.33 if @battle.state.effects[:MudSport]>0
        basemult*=2.0 if attacker.effects[:Charge]>0
      when :DARK 
        basemult*= (@battle.pbCheckGlobalAbility(:AURABREAK) ? 0.66 : 1.33) if @battle.pbCheckGlobalAbility(:DARKAURA)
        basemult*= (@battle.pbCheckGlobalAbility(:AURABREAK) ? 0.6 : 1.4) if @battle.pbCheckGlobalAbility(:DARKAURA) && @battle.FE==:DARKNESS1
        basemult*= (@battle.pbCheckGlobalAbility(:AURABREAK) ? 0.5 : 1.5) if @battle.pbCheckGlobalAbility(:DARKAURA) && @battle.FE==:DARKNESS2
        basemult*= (@battle.pbCheckGlobalAbility(:AURABREAK) ? 0.33 : 1.66) if @battle.pbCheckGlobalAbility(:DARKAURA) && @battle.FE==:DARKNESS3
      when :FAIRY 
        basemult*= (@battle.pbCheckGlobalAbility(:AURABREAK) ? 0.66 : 1.33) if @battle.pbCheckGlobalAbility(:FAIRYAURA)
        basemult*= (@battle.pbCheckGlobalAbility(:AURABREAK) ? 0.7 : 1.30) if @battle.pbCheckGlobalAbility(:FAIRYAURA)&& @battle.FE==:DARKNESS1
        basemult*= (@battle.pbCheckGlobalAbility(:AURABREAK) ? 0.8 : 1.2) if @battle.pbCheckGlobalAbility(:FAIRYAURA)&& @battle.FE==:DARKNESS2
        basemult*= (@battle.pbCheckGlobalAbility(:AURABREAK) ? 0.9 : 1.1) if @battle.pbCheckGlobalAbility(:FAIRYAURA)&& @battle.FE==:DARKNESS3
    end
    basemult*=1.5 if attacker.effects[:HelpingHand]
    basemult*=1.5 if @move == :KNOCKOFF && !opponent.item.nil? && !@battle.pbIsUnlosableItem(opponent,opponent.item)
    basemult*=2.0 if opponent.effects[:Minimize] && @move == :MALICIOUSMOONSAULT # Minimize for z-move
    #Specific Field Effects
    if @battle.field.isFieldEffect?
      fieldmult = moveFieldBoost
      if fieldmult != 1
        basemult*=fieldmult
        fieldmessage =moveFieldMessage
        if fieldmessage && !@fieldmessageshown
          if [:LIGHTTHATBURNSTHESKY,:ICEHAMMER,:HAMMERARM,:CRABHAMMER].include?(@move) #some moves have a {1} in them and we gotta deal.
            @battle.pbDisplay(_INTL(fieldmessage,attacker.pbThis))
          elsif [:SMACKDOWN,:THOUSANDARROWS,:ROCKSLIDE,:VITALTHROW,:CIRCLETHROW,:STORMTHROW,:DOOMDUMMY,:BLACKHOLEECLIPSE,:TECTONICRAGE,:CONTINENTALCRUSH,:WHIRLWIND,:CUT].include?(@move)
            @battle.pbDisplay(_INTL(fieldmessage,opponent.pbThis))
          else
            @battle.pbDisplay(_INTL(fieldmessage))
          end
          @fieldmessageshown = true
        end
      end
    end
    case @battle.FE
      when :CHESS
        if (CHESSMOVES).include?(@move)
          basemult*=0.5 if [:ADAPTABILITY,:ANTICIPATION,:SYNCHRONIZE,:TELEPATHY].include?(opponent.ability)
          basemult*=2.0 if [:OBLIVIOUS,:KLUTZ,:UNAWARE,:SIMPLE].include?(opponent.ability) || opponent.effects[:Confusion]>0 || (Rejuv && opponent.ability == :DEFEATIST)
          @battle.pbDisplay("The chess piece slammed forward!") if !@fieldmessageshown
          @fieldmessageshown = true
        end
        # Queen piece boost
        if attacker.pokemon.piece==:QUEEN || attacker.ability == :QUEENLYMAJESTY || attacker.ability == :HIVEQUEEN
          basemult*=1.5
          if attacker.pokemon.piece==:QUEEN
            @battle.pbDisplay("The Queen is dominating the board!")  && !@fieldmessageshown
            @fieldmessageshown = true
          end
        end

        #Knight piece boost
        if attacker.pokemon.piece==:KNIGHT && opponent.pokemon.piece==:QUEEN
          basemult=(basemult*3.0).round
          @battle.pbDisplay("An unblockable attack on the Queen!") if !@fieldmessageshown
          @fieldmessageshown = true
        end
      when :BIGTOP
        if ((type == :FIGHTING && pbIsPhysical?(type)) || (STRIKERMOVES).include?(@move)) # Continental Crush
          striker = 1+@battle.pbRandom(14)
          @battle.pbDisplay("WHAMMO!") if !@fieldmessageshown
          @fieldmessageshown = true
          if attacker.ability == :HUGEPOWER || attacker.ability == :GUTS || attacker.ability == :PUREPOWER || attacker.ability == :SHEERFORCE
            if striker >=9
              striker = 15
            else
              striker = 14
            end
          end
          strikermod = attacker.stages[PBStats::ATTACK]
          striker = striker + strikermod
          if striker >= 15
            @battle.pbDisplay("...OVER 9000!!!")
            provimult=3.0
          elsif striker >=13
            @battle.pbDisplay("...POWERFUL!")
            provimult=2.0
          elsif striker >=9
            @battle.pbDisplay("...NICE!")
            provimult=1.5
          elsif striker >=3
            @battle.pbDisplay("...OK!")
            provimult=1
          else
            @battle.pbDisplay("...WEAK!")
            provimult=0.5
          end
          provimult = ((provimult-1.0)/2.0)+1.0 if $game_variables[:DifficultyModes]==1 && !$game_switches[:FieldFrenzy]
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_variables[:DifficultyModes]!=1 && $game_switches[:FieldFrenzy] && provimult > 1
          provimult = provimult/2.0 if $game_variables[:DifficultyModes]!=1 && $game_switches[:FieldFrenzy] && provimult < 1
          basemult*=provimult
        end
        if isSoundBased?
          provimult=1.5
          provimult=1.25 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          basemult*=provimult
          @battle.pbDisplay("Loud and clear!") if !@fieldmessageshown
          @fieldmessageshown = true
        end
      when :ICY
        if (@priority >= 1 && @basedamage > 0 && contactMove? && attacker.ability != :LONGREACH) || (@move == :FEINT || @move == :ROLLOUT || @move == :DEFENSECURL || @move == :STEAMROLLER || @move == :LUNGE)
          if !attacker.isAirborne?
            if attacker.pbCanIncreaseStatStage?(PBStats::SPEED)
              attacker.pbIncreaseStatBasic(PBStats::SPEED,1)
              @battle.pbCommonAnimation("StatUp",attacker,nil)
              @battle.pbDisplay(_INTL("{1} gained momentum on the ice!",attacker.pbThis)) if !@fieldmessageshown
              @fieldmessageshown = true
            end
          end
        end
      when :SHORTCIRCUIT
        if type == :ELECTRIC
          damageroll = @battle.field.getRoll(maximize_roll:(@battle.state.effects[:ELECTERRAIN] > 0))
          messageroll = ["Bzzt.", "Bzzapp!" , "Bzt...", "Bzap!", "BZZZAPP!"][PBStuff::SHORTCIRCUITROLLS.index(damageroll)]
          @battle.pbDisplay(messageroll) if !@fieldmessageshown
          damageroll = ((damageroll-1.0)/2.0)+1.0 if $game_variables[:DifficultyModes]==1 && !$game_switches[:FieldFrenzy]
          damageroll = ((damageroll-1.0)*2.0)+1.0 if $game_variables[:DifficultyModes]!=1 && $game_switches[:FieldFrenzy] && damageroll > 1
          damageroll = damageroll/2.0 if $game_variables[:DifficultyModes]!=1 && $game_switches[:FieldFrenzy] && damageroll < 1
          basemult*=damageroll

          @fieldmessageshown = true
        end
      when :CAVE
        if isSoundBased?
          provimult=1.5
          provimult=1.25 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          basemult*=provimult
          @battle.pbDisplay(_INTL("ECHO-Echo-echo!",opponent.pbThis)) if !@fieldmessageshown
          @fieldmessageshown = true
        end
      when :MOUNTAIN
        if (PBFields::WINDMOVES).include?(@move) && @battle.pbWeather== :STRONGWINDS
          provimult=1.5
          provimult=1.25 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          basemult*=provimult
          @battle.pbDisplay(_INTL("The wind strengthened the attack!",opponent.pbThis)) if !@fieldmessageshown
          @fieldmessageshown = true
        end
      when :SNOWYMOUNTAIN
        if (PBFields::WINDMOVES).include?(@move) && @battle.pbWeather== :STRONGWINDS
          provimult=1.5
          provimult=1.25 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          basemult*=provimult
          @battle.pbDisplay(_INTL("The wind strengthened the attack!",opponent.pbThis)) if !@fieldmessageshown
          @fieldmessageshown = true
        end
      when :MIRROR
        if (PBFields::MIRRORMOVES).include?(@move) && opponent.stages[PBStats::EVASION]>0
          provimult=2.0
          provimult=1.5 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          basemult*=provimult
          @battle.pbDisplay(_INTL("The beam was focused from the reflection!",opponent.pbThis)) if !@fieldmessageshown
          @fieldmessageshown = true
        end
        @battle.field.counter = 0
      when :DEEPEARTH
        if (priorityCheck(attacker) > 0) && @basedamage > 0
          provimult=0.7
          provimult=0.85 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          basemult*=provimult
          @battle.pbDisplay(_INTL("The intense pull slowed the attack...")) if !@fieldmessageshown
          @fieldmessageshown = true
        end
        if (priorityCheck(attacker) < 0) && @basedamage > 0
          provimult=1.3
          provimult=1.15 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          basemult*=provimult
          @battle.pbDisplay(_INTL("Slow and heavy!")) if !@fieldmessageshown
          @fieldmessageshown = true
        end
      when :CONCERT1,:CONCERT2,:CONCERT3,:CONCERT4
        if isSoundBased?
          provimult=1.5
          provimult=1.25 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          basemult*=provimult
          @battle.pbDisplay(_INTL("Loud and clear!")) if !@fieldmessageshown
          @fieldmessageshown = true
        end
      when :DARKNESS3,:DARKNESS2
        if [:LIGHTTHATBURNSTHESKY].include?(@move)
          @battle.pbDisplay(_INTL("One brings Shadow, One brings the Light!")) if !@fieldmessageshown
          @fieldmessageshown = true
        end
    end
    if Rejuv
      for terrain in [:ELECTERRAIN,:GRASSY,:MISTY,:PSYTERRAIN]
        if @battle.state.effects[terrain] > 0
          overlaymult = moveOverlayBoost(terrain)
          if overlaymult != 1
            basemult*=overlaymult
            overlaymessage = moveOverlayMessage(terrain)
            @battle.pbDisplay(_INTL(overlaymessage)) if overlaymessage
          end
        end
      end
    end
    #End S.Field Effects
    ##### Calculate attacker's attack stat #####
    case @function
      when 0x121 # Foul Play
        atk=opponent.attack
        atkstage=opponent.stages[PBStats::ATTACK]+6
      when 0x184 # Body Press
        atk=attacker.defense
        atkstage=attacker.stages[PBStats::DEFENSE]+6
      when 0x905 #Skitter smack
        atk=attacker.speed
        atkstage=attacker.stages[PBStats::SPEED]+6
      when 0x900 # Super UMD
        # @SWu I'm pretty sure this doesn't scale with an assault vest item as a modifier (need to update)
        atk=attacker.spdef
        atkstage=attacker.stages[PBStats::SPDEF]+6
      else
        atk=attacker.attack
        atkstage=attacker.stages[PBStats::ATTACK]+6
    end
    if pbIsSpecial?(type)
      atk=attacker.spatk
      atkstage=attacker.stages[PBStats::SPATK]+6
      if @function==0x121 # Foul Play
        atk=opponent.spatk
        atkstage=opponent.stages[PBStats::SPATK]+6
      end
      if @battle.FE == :GLITCH
				atk = attacker.getSpecialStat(opponent.ability == :UNAWARE)
				atkstage = 6 #getspecialstat handles unaware
			end
    end

    if opponent.ability != :UNAWARE || opponent.moldbroken
      atkstage=6 if opponent.damagestate.critical && atkstage<6
      atk=(atk*1.0*stagemul[atkstage]/stagediv[atkstage]).floor
    end
    if attacker.ability == :UNAWARE 
       atkstage=attacker.stages[PBStats::ATTACK]+6
       atk=(atk*1.0*stagemul[atkstage]/stagediv[atkstage]).floor
    end
    # Stat-Copy Crests, ala Claydol//Dedenne
    case attacker.crested
      when :CLAYDOL then atkstage=attacker.stages[PBStats::DEFENSE]+6 if pbIsSpecial?(type)
      when :DEDENNE then atkstage=attacker.stages[PBStats::SPEED]+6 if !pbIsSpecial?(type)
    end
    if attacker.ability == :HUSTLE && pbIsPhysical?(type)
      atk= [:BACKALLEY,:CITY].include?(@battle.FE) ? (atk*1.75).round : (atk*1.5).round
    end
    atkmult=1.0
    if @battle.FE == :HAUNTED || @battle.FE == :BEWITCHED || @battle.FE == :HOLY || @battle.FE == :PSYTERRAIN || @battle.FE == :DEEPEARTH
      atkmult*=1.5 if attacker.pbPartner.ability == :POWERSPOT
    else
      atkmult*=1.3 if attacker.pbPartner.ability == :POWERSPOT
    end
    #pinch abilities
    if (@battle.FE == :BURNING || @battle.FE == :VOLCANIC || @battle.FE == :INFERNAL) && (attacker.ability == :BLAZE && type == :FIRE)
      atkmult*=1.5
    elsif @battle.FE == :VOLCANICTOP && (attacker.ability == :BLAZE && type == :FIRE) && attacker.effects[:Blazed]
      atkmult*=1.5
    elsif (@battle.FE == :FOREST || (Rejuv && @battle.FE == :GRASSY)) && (attacker.ability == :OVERGROW && type == :GRASS)
      atkmult*=1.5
    elsif @battle.FE == :FOREST && (attacker.ability == :SWARM && type == :BUG)
      atkmult*=1.5
    elsif (@battle.FE == :WATERSURFACE || @battle.FE == :UNDERWATER) && (attacker.ability == :TORRENT && type == :WATER)
      atkmult*=1.5
    elsif @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN) && (attacker.ability == :SWARM && type == :BUG)
      atkmult*=1.5 if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,1,2)
      atkmult*=1.8 if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,4)
      atkmult*=2.0 if @battle.FE == :FLOWERGARDEN5
    elsif @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,2,5) && (attacker.ability == :OVERGROW && type == :GRASS)
      case @battle.FE
        when :FLOWERGARDEN2 then atkmult*=1.5 if attacker.hp<=(attacker.totalhp*0.67).floor
        when :FLOWERGARDEN3 then atkmult*=1.6
        when :FLOWERGARDEN4 then atkmult*=1.8
        when :FLOWERGARDEN5 then atkmult*=2.0
      end
    elsif attacker.hp<=(attacker.totalhp/3.0).floor
      if (attacker.ability == :OVERGROW && type == :GRASS) || (attacker.ability == :BLAZE && type == :FIRE && @battle.FE != :FROZENDIMENSION) ||
        (attacker.ability == :TORRENT && type == :WATER) || (attacker.ability == :SWARM && type == :BUG)
        atkmult*=1.5
      end
    end
    case attacker.ability
      when :GUTS then atkmult*=1.5 if !attacker.status.nil? && pbIsPhysical?(type)
      when :PLUS, :MINUS
        if pbIsSpecial?(type) && @battle.FE != :GLITCH
          partner=attacker.pbPartner
          if partner.ability == :PLUS || partner.ability == :MINUS
            atkmult*=1.5
          elsif @battle.FE == :SHORTCIRCUIT || (Rejuv && @battle.FE == :ELECTERRAIN) || @battle.state.effects[:ELECTERRAIN] > 0
            atkmult*=1.5
          end
        end
      when :DEFEATIST then atkmult*=0.5 if attacker.hp<=(attacker.totalhp/2.0).floor
      when :HUGEPOWER then atkmult*=2.0 if pbIsPhysical?(type)
      when :PUREPOWER
        if @battle.FE == :PSYTERRAIN || @battle.state.effects[:PSYTERRAIN] > 0
          atkmult*=2.0 if pbIsSpecial?(type)
        else
          atkmult*=2.0 if pbIsPhysical?(type)
        end
      when :SOLARPOWER then atkmult*=1.5 if (@battle.pbWeather== :SUNNYDAY && !(attitemworks && attacker.item == :UTILITYUMBRELLA)) && pbIsSpecial?(type) && (@battle.FE != :GLITCH &&  @battle.FE != :FROZENDIMENSION)
      when :SLOWSTART then atkmult*=0.5 if attacker.turncount<5 && pbIsPhysical?(type) && !@battle.FE == :DEEPEARTH
      when :GORILLATACTICS then atkmult*=1.5 if pbIsPhysical?(type)
      when :QUARKDRIVE then atkmult*=1.3 if (attacker.effects[:Quarkdrive][0] == PBStats::ATTACK && pbIsPhysical?(type)) || (attacker.effects[:Quarkdrive][0] == PBStats::SPATK && pbIsSpecial?(type))
    end
    if (attacker.ability == :HIVEQUEEN || attacker.pbPartner.ability == :HIVEQUEEN) && type == :BUG
      atkmult*=1.5
    end
    # Mid Battle stat multiplying crests; Spiritomb Crest, Castform Crest
    case attacker.crested
      when :CASTFORM then atkmult*=1.5 if attacker.form == 1 && (@battle.pbWeather== :SUNNYDAY && !(attitemworks && attacker.item == :UTILITYUMBRELLA)) && pbIsSpecial?(type) && (@battle.FE != :GLITCH &&  @battle.FE != :FROZENDIMENSION)
      when :SPIRITOMB
          allyfainted = attacker.pbFaintedPokemonCount
          modifier = (allyfainted * 0.2) + 1.0
          atkmult=(atkmult*modifier).round
    end
    if ((@battle.pbWeather== :SUNNYDAY && !(attitemworks && attacker.item == :UTILITYUMBRELLA)) || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN) || @battle.FE == :BEWITCHED) && pbIsPhysical?(type)
      atkmult*=1.5 if attacker.ability == :FLOWERGIFT || attacker.pbPartner.ability == :FLOWERGIFT
    end
    if (@battle.pbWeather== :SUNNYDAY) && pbIsPhysical?(type)
      atkmult*=1.5 if attacker.ability == :SOLARIDOL 
    end
    if (@battle.pbWeather== :HAIL) && pbIsSpecial?(type)
      atkmult*=1.5 if attacker.ability == :LUNARIDOL
    end
    if attacker.pbPartner.ability == (:BATTERY) && pbIsSpecial?(type) && @battle.FE != :GLITCH
      if Rejuv && @battle.FE == :ELECTERRAIN
        atkmult*=1.5
      else
        atkmult*=1.3
      end
    end
    if @battle.FE == :FAIRYTALE
      atkmult*=2.0 if (attacker.pbPartner.ability == :STEELYSPIRIT || attacker.ability == :STEELYSPIRIT) && type == :STEEL
    else
      atkmult*=1.5 if (attacker.pbPartner.ability == :STEELYSPIRIT || attacker.ability == :STEELYSPIRIT) && type == :STEEL
    end
    atkmult*=1.5 if attacker.effects[:FlashFire] && type == :FIRE && @battle.FE != :FROZENDIMENSION

    if attitemworks
      case attacker.item
        when :THICKCLUB then atkmult*=2.0 if attacker.pokemon.species == :CUBONE || attacker.pokemon.species == :MAROWAK && pbIsPhysical?(type)
        when :DEEPSEATOOTH then atkmult*=2.0 if attacker.pokemon.species == :CLAMPERL && pbIsSpecial?(type) && @battle.FE != :GLITCH
        when :LIGHTBALL then atkmult*=2.0 if attacker.pokemon.species == :PIKACHU && @battle.FE != :GLITCH
        when :CHOICEBAND then atkmult*=1.5 if pbIsPhysical?(type)
        when :CHOICESPECS then atkmult*=1.5 if pbIsSpecial?(type) && @battle.FE != :GLITCH
        when :SOULDEW then atkmult*=1.5 if pbIsSpecial?(type) && (attacker.pokemon.species == :LATIAS || attacker.pokemon.species == :LATIOS) && @battle.FE != :GLITCH
      end
    end
    if @battle.FE != :INDOOR
      if @battle.FE == :STARLIGHT || @battle.FE == :NEWWORLD
        if attacker.ability == :VICTORYSTAR
          atkmult*=1.5
        end
        partner=attacker.pbPartner
        if partner && partner.ability == :VICTORYSTAR
          atkmult*=1.5
        end
      end
      if @battle.FE == :WATERSURFACE
        atkmult*=1.5 if attacker.ability == :PROPELLERTAIL && @priority >= 1 && @basedamage > 0
      end
      if @battle.FE == :UNDERWATER 
        atkmult*=0.5 if (!Rejuv || !attacker.hasType?(:WATER)) && pbIsPhysical?(type) && type != :WATER && attacker.ability != :STEELWORKER && attacker.ability != :SWIFTSWIM
        atkmult*=1.5 if attacker.ability == :PROPELLERTAIL && @priority >= 1 && @basedamage > 0
      end
      if Rejuv && @battle.FE == :CHESS
        atkmult*=1.2 if attacker.ability == :GORILLATACTICS || attacker.ability == :RECKLESS
        atkmult*=1.2 if attacker.ability == :ILLUSION && attacker.effects[:Illusion]!=nil
        if attacker.ability == :COMPETITIVE
          frac = (1.0*attacker.hp)/(1.0*attacker.totalhp)
          multiplier = 1.0  
          multiplier += ((1.0-frac)/0.8)  
          if frac < 0.2  
            multiplier = 2.0  
          end  
          atkmult=(atkmult*multiplier)
        end
      end
      case attacker.ability
        when :QUEENLYMAJESTY then atkmult*=1.5 if @battle.FE == :FAIRYTALE
        when :HIVEQUEEN then atkmult*=1.5 if @battle.FE == :FAIRYTALE
        when :LONGREACH then atkmult*=1.5 if (@battle.FE == :MOUNTAIN || @battle.FE == :SNOWYMOUNTAIN || @battle.FE == :SKY)
        when :CORROSION then atkmult*=1.5 if (@battle.FE == :CORROSIVE || @battle.FE == :CORROSIVEMIST || @battle.FE == :CORRUPTED)
        when :TIDEPOOLTYRANT then atkmult*=1.5 if (@battle.FE == :CORROSIVE || @battle.FE == :CORROSIVEMIST || @battle.FE == :CORRUPTED)
        when :SKILLLINK then atkmult*=1.2 if (@battle.FE == :COLOSSEUM && (@function == 0xC0 || @function == 0x307 || (attacker.crested == :CINCCINO && !pbIsMultiHit))) #0xC0: 2-5 hits; 0x307: Scale Shot
      end
    end
    atkmult*=0.5 if opponent.ability == :THICKFAT && (type == :ICE || type == :FIRE) && !(opponent.moldbroken)

    atkmult*=0.5 if opponent.ability == :THICKFAT && (type == :ICE || type == :FIRE) && !(opponent.moldbroken)
    atkmult*=1.5 if attacker.crested == :DARKRAI && opponent.status==:SLEEP
    atkmult*=0.33 if opponent.ability == :HEAVYMETAL && (type == :FIGHTING) && !(opponent.moldbroken)
    atkmult*=0.33 if opponent.ability == :LIGHTMETAL && (type == :GROUND) && !(opponent.moldbroken)

    ##### Calculate opponent's defense stat #####
    defense=opponent.defense
    defstage=opponent.stages[PBStats::DEFENSE]+6
    # TODO: Wonder Room should apply around here
    # @ghostDango @SWu TODO:
    
    applysandstorm=false
    if pbHitsSpecialStat?(type)
      defense=opponent.spdef
      defstage=opponent.stages[PBStats::SPDEF]+6
      applysandstorm=true
      if @battle.FE == :GLITCH
        defense = opponent.getSpecialStat(attacker.ability == :UNAWARE)
        defstage = 6 # getspecialstat handles unaware
        applysandstorm=false # getSpecialStat handles sandstorm
      end
    end
    if attacker.ability != :UNAWARE
      defstage=6 if @function==0xA9 # Chip Away (ignore stat stages)
      defstage=6 if opponent.damagestate.critical && defstage>6
      defense=(defense*1.0*stagemul[defstage]/stagediv[defstage]).floor
    end
    if @battle.pbWeather== :SANDSTORM && opponent.hasType?(:ROCK) && applysandstorm
      defense=(defense*1.5).round
    end
    if @battle.pbWeather== :HAIL && (opponent.hasType?(:ICE) || opponent.ability == :LUNARIDOL)
      defense=(defense*1.5).round
    end
    defmult=1.0
    defmult*=0.5 if @battle.FE == :GLITCH && @function==0xE0
    defmult*=0.5 if attacker.crested == :ELECTRODE && pbHitsPhysicalStat?(type)
    # Field Effect defense boost
    defmult*=fieldDefenseBoost(type,opponent)

    #Abilities defense boost
    case opponent.ability
      when :ICESCALES then defmult*=2.0 if pbIsSpecial?(type) && !(opponent.moldbroken)
      when :SILVERSCALES then defmult*=2.0 if effect > 0 && !(opponent.moldbroken)
      when :MARVELSCALE then defmult*=1.5 if (pbIsPhysical?(type) && (!opponent.status.nil? || ([:MISTY,:RAINBOW,:FAIRYTALE,:DRAGONSDEN,:STARLIGHT].include?(@battle.FE) || @battle.state.effects[:MISTY] > 0))) && !(opponent.moldbroken)
      when :GRASSPELT then defmult*=1.5 if pbIsPhysical?(type) && (@battle.FE == :GRASSY || @battle.FE == :FOREST || @battle.state.effects[:GRASSY] > 0) # Grassy Field
      when :FURCOAT then defmult*=2.0 if pbIsPhysical?(type) && !(opponent.moldbroken)
      when :PUNKROCK then defmult*=2.0 if isSoundBased? && !(opponent.moldbroken)
      when :QUARKDRIVE then defmult*=1.3 if (opponent.effects[:Quarkdrive][0] == PBStats::DEFENSE && pbIsPhysical?(type)) || (opponent.effects[:Quarkdrive][0] == PBStats::SPDEF && pbIsSpecial?(type))
      when :FLUFFY
        defmult*=2.0 if contactMove? && attacker.ability != :LONGREACH && !(opponent.moldbroken)
        defmult*=4.0 if contactMove? && attacker.ability != :LONGREACH && @battle.FE == :CLOUDS  && !(opponent.moldbroken)
        defmult*=0.5 if type == :FIRE && !(opponent.moldbroken)
    end
    if ((@battle.pbWeather== :SUNNYDAY && !opponent.hasWorkingItem(:UTILITYUMBRELLA)) || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN) || @battle.FE == :BEWITCHED) && !(opponent.moldbroken) && pbIsSpecial?(type)
      if opponent.ability == :FLOWERGIFT && opponent.species == :CHERRIM
        defmult*=1.5
      end
      if opponent.pbPartner.ability == :FLOWERGIFT  && opponent.pbPartner.species == :CHERRIM
        defmult*=1.5
      end
    end
    #Item defense boost
    if opponent.hasWorkingItem(:EVIOLITE) && !(@battle.FE == :GLITCH && pbIsSpecial?(type)) 
      evos=pbGetEvolvedFormData(opponent.pokemon.species,opponent.pokemon)
      if evos && evos.length>0
        defmult*=1.5
      end
    end
    if opponent.item == :PIKANIUMZ && opponent.pokemon.species == :PIKACHU && !(@battle.FE == :GLITCH && pbIsSpecial?(type)) 
      defmult*=1.5
    end
    if opponent.item == :LIGHTBALL && opponent.pokemon.species == :PIKACHU && !(@battle.FE == :GLITCH && pbIsSpecial?(type)) 
      defmult*=1.5
    end
    if opponent.hasWorkingItem(:ASSAULTVEST) && pbIsSpecial?(type) && @battle.FE != :GLITCH
      defmult*=1.5
    end
    if opponent.hasWorkingItem(:SOULDEW) && pbIsSpecial?(type) && (opponent.pokemon.species == :LATIAS || opponent.pokemon.species == :LATIOS) && @battle.FE != :GLITCH
      defmult*=1.5
    end
    if opponent.hasWorkingItem(:DEEPSEASCALE) && @battle.FE != :GLITCH && (opponent.pokemon.species == :CLAMPERL) && pbIsSpecial?(type)
      defmult*=2.0
    end
    if opponent.hasWorkingItem(:METALPOWDER) && (opponent.pokemon.species == :DITTO) && !opponent.effects[:Transform] && pbIsPhysical?(type)
      defmult*=2.0
    end
    
    if opponent.crested == :VESPIQUEN
      defmult*=1.5
    end

    #General damage modifiers
    damage = 1.0
    # Multi-targeting attacks
    if pbTargetsAll?(attacker) || attacker.midwayThroughMove
      if attacker.pokemon.piece == :KNIGHT && battle.FE == :CHESS && @target==:AllOpposing
        @battle.pbDisplay(_INTL("The knight forked the opponents!")) if !attacker.midwayThroughMove
        damage*=1.25
      else
        damage*=0.75
      end
      attacker.midwayThroughMove = true
    end
    # Field Effects
    fieldBoost = typeFieldBoost(type,attacker,opponent)
    overlayBoost, overlay = typeOverlayBoost(type,attacker,opponent)
    if fieldBoost != 1 || overlayBoost != 1
      if fieldBoost > 1 && overlayBoost > 1
        boost = [fieldBoost,overlayBoost].max
        if $game_variables[:DifficultyModes]==1 && !$game_switches[:FieldFrenzy]
          boost = 1.25 if boost < 1.25
        elsif $game_variables[:DifficultyModes]!=1 && $game_switches[:FieldFrenzy]
          boost = 2.0 if boost < 2.0
        else
          boost = 1.5 if boost < 1.5
        end
      else
        boost = fieldBoost*overlayBoost
      end
      damage*=boost
      fieldmessage = typeFieldMessage(type) if fieldBoost != 1
      overlaymessage = typeOverlayMessage(type,overlay) if overlay
      if overlaymessage && !fieldmessage
        @battle.pbDisplay(_INTL(overlaymessage)) if !@fieldmessageshown_type
      else
        @battle.pbDisplay(_INTL(fieldmessage)) if fieldmessage && !@fieldmessageshown_type
      end
      @fieldmessageshown_type = true
    end
    case @battle.FE
      when :MOUNTAIN,:SNOWYMOUNTAIN
        if type == :FLYING && !pbIsPhysical?(type) && @battle.pbWeather== :STRONGWINDS
          provimult=1.5 
          provimult=1.25 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          damage*=provimult
        end
      when :DEEPEARTH
        if type == :GROUND && opponent.hasType?(:GROUND)
          provimult=0.5
          provimult=0.75 if $game_variables[:DifficultyModes]==1 && !$game_switches[:FieldFrenzy]
          provimult=0.25 if $game_variables[:DifficultyModes]!=1 && $game_switches[:FieldFrenzy]
          damage*=provimult
          @battle.pbDisplay(_INTL("The dense earth is difficult to mold...")) if !@fieldmessageshown_type
          @fieldmessageshown_type = true
        end
    end
    case @battle.pbWeather
      when :SUNNYDAY
        if @battle.state.effects[:HarshSunlight] && type == :WATER
          @battle.pbDisplay(_INTL("The Water-type attack evaporated in the harsh sunlight!"))
          @battle.scene.pbUnVanishSprite(attacker) if @function==0xCB #Dive
          return 0
        end
      when :RAINDANCE
        if @battle.state.effects[:HeavyRain] && type == :FIRE
          @battle.pbDisplay(_INTL("The Fire-type attack fizzled out in the heavy rain!"))
          return 0
        end
    end
    # FIELD TRANSFORMATIONS
    fieldmove = @battle.field.moveData(@move)
    if fieldmove && fieldmove[:fieldchange]
      change_conditions = @battle.field.fieldChangeData
      handled = change_conditions[fieldmove[:fieldchange]] ? eval(change_conditions[fieldmove[:fieldchange]]) : true
      #don't continue if conditions to change are not met or if a multistage field changes to a different stage of itself
      if handled  && !(@battle.ProgressiveFieldCheck("All") && (PBFields::CONCERT.include?(fieldmove[:fieldchange]) || PBFields::FLOWERGARDEN.include?(fieldmove[:fieldchange]) || PBFields::DARKNESS.include?(fieldmove[:fieldchange])))
        provimult=1.3 
        provimult=1.15 if $game_variables[:DifficultyModes]==1
        provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
        damage*=provimult
      end
    end
    case @battle.FE
      when :FACTORY
        if (@move == :DISCHARGE) || (@move == :OVERDRIVE)
          @battle.setField(:SHORTCIRCUIT)
          @battle.pbDisplay(_INTL("The field shorted out!"))
          provimult=1.3 
          provimult=1.15 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          damage*=provimult
        end
      when :SHORTCIRCUIT
        if (@move == :DISCHARGE) || (@move == :OVERDRIVE)
          @battle.setField(:FACTORY)
          @battle.pbDisplay(_INTL("SYSTEM ONLINE."))
          provimult=1.3 
          provimult=1.15 if $game_variables[:DifficultyModes]==1
          provimult = ((provimult-1.0)*2.0)+1.0 if $game_switches[:FieldFrenzy]
          damage*=provimult
        end
    end

    case type
      when :FIRE
        damage*=1.5 if @battle.weather == :SUNNYDAY
        damage*=0.5 if @battle.weather == :RAINDANCE
        damage*=0.5 if opponent.ability == :WATERBUBBLE
      when :WATER
        damage*=1.5 if @battle.weather == :RAINDANCE
        damage*=0.5 if @battle.weather == :SUNNYDAY
        damage*=2 if attacker.ability == :WATERBUBBLE
    end
    # Critical hits
    if opponent.damagestate.critical
      damage*=1.5
      damage*=1.5 if attacker.ability == :SNIPER
      damage*=1.5 if attacker.crested == :ARIADOS
      damage*=1.5 if @move == :AIRCUTTER
    end
    # STAB-addition from Crests 
    typecrest = false
    case attacker.crested
      when :EMPOLEON then typecrest = true if type == :ICE
      when :LUXRAY then typecrest = true if type == :DARK
      when :SAMUROTT then typecrest = true if type == :FIGHTING
      when :SIMISEAR then typecrest = true if type == :WATER
      when :SIMIPOUR then typecrest = true if type == :GRASS
      when :SIMISAGE then typecrest = true if type == :FIRE
      when :ZOROARK
        party = @battle.pbPartySingleOwner(attacker.index)
        party=party.find_all {|item| item && !item.egg? && item.hp>0 }
        if party[party.length-1] != attacker.pokemon
          typecrest = true if party[party.length-1].hasType?(type)
        end
      end
    # STAB
    if (attacker.hasType?(type) && (!attacker.effects[:DesertsMark]) ||
        (attacker.ability == :STEELWORKER && type == :STEEL) ||
        (attacker.ability == :BULLDOZER && type == :GROUND) ||
        (attacker.ability == :SOLARIDOL && type == :FIRE) || (attacker.ability == :SOLARIDOL && type == :PSYCHIC) || 
        (attacker.ability == :LUNARIDOL && type == :ICE) || (attacker.ability == :LUNARIDOL && type == :PSYCHIC) ||
        typecrest==true)
      if attacker.ability == :ADAPTABILITY
        damage*=2.0
      elsif (attacker.ability == :STEELWORKER && type == :STEEL) && @battle.FE == :FACTORY # Factory Field
        damage*=2.0
      else
        damage*=1.5
      end
      if attacker.crested == :SILVALLY
        damage*=1.2
      end
      if attacker.species == :GENESECT
        if (type == :WATER && opp2.species == :GENESECT && opp2.hasWorkingItem(:DOUSEDRIVE))
          damage*=1.5
        elsif (type == :ELECTRIC && opp2.species == :GENESECT && opp2.hasWorkingItem(:SHOCKDRIVE))
          damage*=1.5
        elsif (type == :ICE && opp2.species == :GENESECT && opp2.hasWorkingItem(:CHILLDRIVE))
          damage*=1.5
        elsif (type == :FIRE && opp2.species == :GENESECT && opp2.hasWorkingItem(:BURNDRIVE))
          damage*=1.5
        end
      end
      if attacker.crested == :CHERRIM && type == :FIRE
        damage*=1.5
      end
      if attacker.crested == :GOODRA && type == :POISON
        damage*=1.5
      end
    end
    # Type effectiveness
    typemod=pbTypeModMessages(type,attacker,opponent)
    damage=(damage*typemod/4.0)
    opponent.damagestate.typemod=typemod
    if typemod==0
      opponent.damagestate.calcdamage=0
      opponent.damagestate.critical=false
      return 0
    end
    damage*=0.5 if attacker.status== :BURN && pbIsPhysical?(type) && attacker.ability != :GUTS && @move != :FACADE
    damage*=0.5 if attacker.status== :FROSTBITE && !pbIsPhysical?(type)
    # Random Variance
    if !$game_switches[:No_Damage_Rolls] || @battle.isOnline?
      random = 85+@battle.pbRandom(16)
    elsif $game_switches[:No_Damage_Rolls] || !@battle.isOnline?
      random = 93
    end
    random = 85 if @battle.FE == :CONCERT1
    random = 100 if @battle.FE == :CONCERT4
    damage = (damage*(random/100.0))

    # Final damage modifiers
    finalmult=1.0
    if !opponent.damagestate.critical && attacker.ability != :INFILTRATOR
      # Screens
      if @category!=:status && opponent.pbOwnSide.screenActive?(betterCategory(type))
        finalmult*= (!opponent.pbPartner.isFainted? || attacker.midwayThroughMove) ? 0.66 : 0.5
      end
      if opponent.pbOwnSide.effects[:AreniteWall] > 0 && opponent.damagestate.typemod>4
        finalmult*= 0.5
      end
    end
    finalmult*=0.67 if opponent.crested == :BEHEEYEM && (!opponent.hasMovedThisRound? || @battle.switchedOut[opponent.index])
    secondtypes = self.getSecondaryType(attacker)
    finalmult*=0.5 if opponent.effects[:Shelter] && @battle.FE != :INDOOR && (type == @battle.field.mimicry || !secondtypes.nil? && secondtypes.include?(@battle.field.mimicry))
    finalmult*=0.5 if ((opponent.ability == :MULTISCALE && !(opponent.moldbroken)) && opponent.hp==opponent.totalhp)
    finalmult*=0.5 if opponent.ability == :SHADOWSHIELD && (opponent.hp==opponent.totalhp || @battle.FE == :DIMENSIONAL)
    finalmult*=0.33 if opponent.ability == :SHADOWSHIELD && (opponent.hp==opponent.totalhp && (@battle.FE == :DARKNESS2 || @battle.FE == :DARKNESS3 ))
    finalmult*=2.0 if attacker.ability == :TINTEDLENS && opponent.damagestate.typemod<4
    finalmult*=2.0 if attacker.ability == :EXECUTION && (opponent.hp <= (opponent.totalhp/2).floor)
    finalmult*=0.75 if opponent.pbPartner.ability == :FRIENDGUARD && !(opponent.moldbroken)
    finalmult*=0.5 if (opponent.ability == :PASTELVEIL || opponent.pbPartner.ability == :PASTELVEIL) && @type == :POISON && (@battle.FE == :MISTY || @battle.FE == :RAINBOW || (@battle.state.effects[:MISTY] > 0))
    if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,5)
      if (opponent.pbPartner.ability == :FLOWERVEIL && opponent.hasType?(:GRASS)) || (opponent.ability == :FLOWERVEIL && !(opponent.moldbroken))
        finalmult*=0.5
        @battle.pbDisplay(_INTL("The Flower Veil softened the attack!"))
      end
      if opponent.hasType?(:GRASS)
        case @battle.FE
          when :FLOWERGARDEN3 then finalmult*=0.75
          when :FLOWERGARDEN4 then finalmult*=0.66
          when :FLOWERGARDEN5 then finalmult*=0.5
        end
      end
    end
    finalmult*=0.75 if (((opponent.ability == :SOLIDROCK || opponent.ability == :FILTER) && !opponent.moldbroken) || opponent.ability == :PRISMARMOR) && opponent.damagestate.typemod>4
    finalmult*=0.75 if opponent.ability == :SHADOWSHIELD && [:STARLIGHT, :NEWWORLD, :DARKCRYSTALCAVERN].include?(@battle.FE)
    finalmult*=0.70 if opponent.crested == :AMPHAROS && opponent.damagestate.typemod>4
    finalmult*=2.0 if attacker.ability == :STAKEOUT && @battle.switchedOut[opponent.index]
    finalmult*=[1.0+attacker.effects[:Metronome]*0.2,2.0].min if (attitemworks && attacker.item == :METRONOME) && attacker.movesUsed[-2] == attacker.movesUsed[-1]
    finalmult*=[1.0+attacker.effects[:Metronome]*0.2,2.0].min if @battle.FE == :CONCERT4 && attacker.movesUsed[-2] == attacker.movesUsed[-1]
    finalmult*=1.2 if (attitemworks && attacker.item == :EXPERTBELT) && opponent.damagestate.typemod > 4
    finalmult*=1.25 if (attacker.ability == :NEUROFORCE) && opponent.damagestate.typemod > 4
    finalmult*=1.3 if (attitemworks && attacker.item == :LIFEORB)
    if opponent.damagestate.typemod>4 && opponent.itemWorks?
      hasberry = false
      case type
        when :FIGHTING   then hasberry = (opponent.item == :CHOPLEBERRY)
        when :FLYING     then hasberry = (opponent.item == :COBABERRY)
        when :POISON     then hasberry = (opponent.item == :KEBIABERRY)
        when :GROUND     then hasberry = (opponent.item == :SHUCABERRY)
        when :ROCK       then hasberry = (opponent.item == :CHARTIBERRY)
        when :BUG        then hasberry = (opponent.item == :TANGABERRY)
        when :GHOST      then hasberry = (opponent.item == :KASIBBERRY)
        when :STEEL      then hasberry = (opponent.item == :BABIRIBERRY)
        when :FIRE       then hasberry = (opponent.item == :OCCABERRY)
        when :WATER      then hasberry = (opponent.item == :PASSHOBERRY)
        when :GRASS      then hasberry = (opponent.item == :RINDOBERRY)
        when :ELECTRIC   then hasberry = (opponent.item == :WACANBERRY)
        when :PSYCHIC    then hasberry = (opponent.item == :PAYAPABERRY)
        when :ICE        then hasberry = (opponent.item == :YACHEBERRY)
        when :DRAGON     then hasberry = (opponent.item == :HABANBERRY)
        when :DARK       then hasberry = (opponent.item == :COLBURBERRY)
        when :FAIRY      then hasberry = (opponent.item == :ROSELIBERRY)
      end
    end
    hasberry = true if opponent.hasWorkingItem(:CHILANBERRY) && type == :NORMAL
    if hasberry && !([:UNNERVE,:ASONE].include?(attacker.ability) || [:UNNERVE,:ASONE].include?(attacker.pbPartner.ability))
      finalmult*=0.5
      finalmult*=0.5 if opponent.ability == :RIPEN
      opponent.pbDisposeItem(true)
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("{2}'s {1} weakened the damage from the attack!",getItemName(opponent.pokemon.itemRecycle),opponent.pbThis))
      else
        @battle.pbDisplay(_INTL("The {1} weakened the damage to {2}!",getItemName(opponent.pokemon.itemRecycle),opponent.pbThis))
      end
    end
    finalmult*=0.75 if (opponent.crested == :MEGANIUM || opponent.pbPartner.crested == :MEGANIUM)
    if attacker.crested == :SEVIPER
      multiplier = 0.5*(opponent.pokemon.hp*1.0)/(opponent.pokemon.totalhp*1.0)
      multiplier += 1.0
      finalmult=(finalmult*multiplier)
    end
    if @zmove
      if (opponent.pbOwnSide.effects[:MatBlock] || opponent.effects[:Protect] || 
        opponent.effects[:KingsShield] || opponent.effects[:Obstruct] ||
        opponent.effects[:SpikyShield] || opponent.effects[:BanefulBunker] ||
        opponent.pbOwnSide.effects[:WideGuard] && (@target == :AllOpposing || @target == :AllNonUsers))
        if @move ==:UNLEASHEDPOWER
          @battle.pbDisplay(_INTL("The Interceptor's power broke through {1}'s Protect!",opponent.pbThis))
        elsif !opponent.effects[:ProtectNegation]
          @battle.pbDisplay(_INTL("{1} couldn't fully protect itself!",opponent.pbThis))
          finalmult=(finalmult/4)
        end
      end
    end
    finalmult=pbModifyDamage(finalmult,attacker,opponent)
    ##### Main damage calculation #####
    basedmg*=basemult
    atk*=atkmult
    defense*=defmult
    totaldamage=(((((2.0*attacker.level/5+2).floor*basedmg*atk/defense).floor/50.0).floor+1)*damage*finalmult).round
    totaldamage=1 if totaldamage < 1
    opponent.damagestate.calcdamage=totaldamage
    return totaldamage
  end

  def pbReduceHPDamage(damage,attacker,opponent)
    endure=false
    futureMoves=[:FUTUREDUMMY,:DOOMDUMMY,:HEXDUMMY]
    if futureMoves.include?(@move)
      damage=pbCalcDamage(attacker,opponent)
    end
    if opponent.effects[:Substitute]>0 && (!attacker || attacker.index!=opponent.index) &&
     attacker.ability != :INFILTRATOR && !isSoundBased? && 
     @move!=:SPECTRALTHIEF &&  @move!=:HYPERSPACEHOLE &&  @move!=:HYPERSPACEFURY #spectral thief/ hyperspace hole/ hyperspace fury
      damage=opponent.effects[:Substitute] if damage>opponent.effects[:Substitute]
      opponent.effects[:Substitute]-=damage
      opponent.damagestate.substitute=true
      if damage > 0
        @battle.scene.pbDamageAnimation(opponent,0)
        @battle.pbDisplay(_INTL("The substitute took damage for {1}!",opponent.name))
        if opponent.effects[:Substitute]<=0
          opponent.effects[:Substitute]=0
          @battle.scene.pbUnSubstituteSprite(opponent,opponent.pbIsOpposing?(1))
          @battle.pbDisplay(_INTL("{1}'s substitute faded!",opponent.name))
        end
      end
      opponent.damagestate.hplost=damage
      damage=0
    elsif opponent.effects[:Disguise] && (!attacker || attacker.index!=opponent.index) &&
      opponent.effects[:Substitute]<=0 && opponent.damagestate.typemod!=0 && !opponent.moldbroken
      opponent.pbBreakDisguise
      @battle.pbDisplay(_INTL("{1}'s Disguise was busted!",opponent.name))
      opponent.effects[:Disguise]=false
      damage=0
    elsif opponent.effects[:IceFace] && (pbIsPhysical?(type) || @battle.FE == :FROZENDIMENSION) && (!attacker || attacker.index!=opponent.index) &&
      opponent.effects[:Substitute]<=0 && opponent.damagestate.typemod!=0 && !opponent.moldbroken
      opponent.pbBreakDisguise
      @battle.pbDisplay(_INTL("{1} transformed!",opponent.name))
      opponent.effects[:IceFace]=false
      damage=0
    else
      opponent.damagestate.substitute=false
      if damage>=opponent.hp
        damage=opponent.hp
        if @function==0xE9 # False Swipe
          damage=damage-1
        elsif opponent.effects[:Endure]
          damage=damage-1
          opponent.damagestate.endured=true
        elsif damage==opponent.totalhp && @battle.FE == :CHESS && opponent.pokemon.piece==:PAWN && !opponent.damagestate.pawnsturdyused
          opponent.damagestate.pawnsturdyused = true
          opponent.damagestate.pawnsturdy = true
          damage=damage-1
        elsif damage==opponent.totalhp && opponent.ability == :STURDY && !opponent.moldbroken
          opponent.damagestate.sturdy=true
          damage=damage-1
        elsif opponent.damagestate.focussash && damage==opponent.totalhp && opponent.item
          opponent.damagestate.focussashused=true
          damage=damage-1
          opponent.pbDisposeItem(false)
        elsif opponent.damagestate.focusband
          opponent.damagestate.focusbandused=true
          damage=damage-1
        elsif opponent.damagestate.rampcrest
          opponent.damagestate.rampcrestused=true
          opponent.pokemon.rampCrestUsed = true
          damage=damage-1
        elsif damage==opponent.totalhp && opponent.ability == :STALWART && @battle.FE == :COLOSSEUM && !opponent.moldbroken
          opponent.damagestate.stalwart=true
          damage=damage-1
        end
        damage=0 if damage<0
      end
      oldhp=opponent.hp
      opponent.hp-=damage
      effectiveness=0
      if opponent.damagestate.typemod<4
        effectiveness=1   # "Not very effective"
      elsif opponent.damagestate.typemod>4
        effectiveness=2   # "Super effective"
      end
      if opponent.damagestate.typemod!=0
        @battle.scene.pbDamageAnimation(opponent,effectiveness)
      end
      @battle.scene.pbHPChanged(opponent,oldhp)
      opponent.damagestate.hplost=damage
    end
    return damage
  end

################################################################################
# Effects
################################################################################
  def pbEffectMessages(attacker,opponent,ignoretype=false)
    if opponent.damagestate.critical
      @battle.pbDisplay(_INTL("A critical hit!"))
      attacker.pokemon.landCritical = 0 if attacker.pokemon.landCritical.nil? #PLEASE ACTUALLY BE ASSIGNED GDI
      attacker.pokemon.landCritical += 1
      if @battle.ProgressiveFieldCheck(PBFields::CONCERT)
        @battle.growField("The critical hit",attacker)
      end
    end
    if !pbIsMultiHit && !attacker.effects[:ParentalBond] && !attacker.effects[:HydreigonCrest]
      if opponent.damagestate.typemod>4
        @battle.pbDisplay(_INTL("It's super effective!"))
      elsif opponent.damagestate.typemod>=1 && opponent.damagestate.typemod<4
        @battle.pbDisplay(_INTL("It's not very effective..."))
      end
    end
    if opponent.damagestate.endured
      @battle.pbDisplay(_INTL("{1} endured the hit!",opponent.pbThis))
    elsif opponent.damagestate.pawnsturdy
      opponent.damagestate.pawnsturdy=false
      @battle.pbDisplay(_INTL("{1} hung on the edge of the board!",opponent.pbThis))
    elsif opponent.damagestate.sturdy
      @battle.pbDisplay(_INTL("{1} hung on with Sturdy!",opponent.pbThis))
      opponent.damagestate.sturdy=false
    elsif opponent.damagestate.focussashused
      @battle.pbDisplay(_INTL("{1} hung on using its Focus Sash!",opponent.pbThis))
      opponent.damagestate.focussashused=false
    elsif opponent.damagestate.focusbandused
      @battle.pbDisplay(_INTL("{1} hung on using its Focus Band!",opponent.pbThis))
    elsif opponent.damagestate.rampcrestused
      @battle.pbDisplay(_INTL("{1} hung on using its Rampardos Crest!",opponent.pbThis))
      opponent.damagestate.rampcrestused=false
    elsif opponent.damagestate.stalwart  
      @battle.pbDisplay(_INTL("{1} hung on with Stalwart in the Colosseum!",opponent.pbThis))
      opponent.damagestate.stalwart=false
    end
  end

  def pbEffectFixedDamage(damage,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    type=pbType(attacker)
    typemod=pbTypeModMessages(type,attacker,opponent)
    opponent.damagestate.critical=false
    opponent.damagestate.typemod=0
    opponent.damagestate.calcdamage=0
    opponent.damagestate.hplost=0
    if typemod!=0
      opponent.damagestate.calcdamage=damage
      opponent.damagestate.typemod=4
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      damage=1 if damage<1 # HP reduced can't be less than 1
      damage=pbReduceHPDamage(damage,attacker,opponent)
      pbEffectMessages(attacker,opponent)
      pbOnDamageLost(damage,attacker,opponent)
      return damage
    end
    return 0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return 0 if !opponent

    damage=pbCalcDamage(attacker,opponent,hitnum: hitnum)
    
    damage *= 1.5 if attacker.effects[:MeFirst]
    damage /= 2 if hitnum == 1 && attacker.effects[:ParentalBond] && pbNumHits(attacker)==1
    damage /= 4 if hitnum > 0 && attacker.effects[:HydreigonCrest] && pbNumHits(attacker)==1
    damage *= 0.3 if hitnum == 1 && attacker.effects[:TyphBond] && pbNumHits(attacker)==1
    if opponent.damagestate.typemod!=0 
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation) 
      if self.function==0xC9 || self.function==0xCA || self.function==0xCB ||
        self.function==0xCC || self.function==0xCD || self.function==0xCE #Sprites for two turn moves            
        @battle.scene.pbUnVanishSprite(attacker,false)
        if self.function==0xCE
          @battle.scene.pbUnVanishSprite(opponent,false)
        end
      end       
    end
    damage=pbReduceHPDamage(damage,attacker,opponent)
    pbEffectMessages(attacker,opponent)
    pbOnDamageLost(damage,attacker,opponent)
    return damage   # The HP lost by the opponent due to this attack
  end

  def priorityCheck(attacker)
    pri = self.priority
    
    pri = 0 if @zmove && @basedamage > 0
    pri += 1 if @move == :GRASSYGLIDE && (@battle.FE == :GRASSY || @battle.state.effects[:GRASSY] > 0)
    pri += 1 if @move == :QUASH && @battle.FE == :DIMENSIONAL
    pri += 1 if @battle.FE == :CHESS && attacker.pokemon && attacker.pokemon.piece == :KING
    pri += 1 if attacker.crested == :FERALIGATR && @basedamage != 0 && attacker.turncount == 1 # Feraligatr Crest
    pri += 1 if attacker.ability == :PRANKSTER && @basedamage==0 && attacker.effects[:TwoTurnAttack] == 0 # Is status move
    pri += 1 if attacker.ability == :GALEWINGS && @type==:FLYING
    pri += 1 if (attacker.ability == :HIVEQUEEN || attacker.pbPartner.ability == :HIVEQUEEN) && @type==:BUG 
    
    # @SWu this bugs out the AI for some reason (because it tries to calc damage using :FAKEMOVE but fakemove doesn't have a function code??? pls help @Rei)
    # pri += 2 if (attacker.ability == :RUNAWAY || attacker.ability == :GRANDLARCENY) && (@move.function == 0x0EE || @move.function == 0x902 || @move.function == 0x13D || @move.function == 0x0ED)
    pri += 3 if attacker.ability == :TRIAGE && (PBStuff::HEALFUNCTIONS).include?(@function)
    pri -= 1 if @battle.FE == :DEEPEARTH && @move == :COREENFORCER
    return pri
  end

  def pbIsPriorityMoveAI(attacker)
    if @move==:FAKEOUT || @move==:FIRSTIMPRESSION
      return false if attacker.turncount != 0
    end
    return (priorityCheck(attacker) > 0)
  end

################################################################################
# cass's lazy field effect thingy section (i never said i knew what i was doing)
################################################################################
  def ignitecheck
    return @battle.state.effects[:WaterSport] <= 0 && @battle.pbWeather != :RAINDANCE
  end

  def suncheck
    return false
  end

  #def mistExplosion
  #  return !@battle.pbCheckGlobalAbility(:DAMP)
  #end

################################################################################
# Using the move
################################################################################
  def pbOnStartUse(attacker)
    return true
  end

  def pbAddTarget(targets,attacker)
  end

  def pbDisplayUseMessage(attacker,choice)
  # Return values:
  # -1 if the attack should exit as a failure
  # 1 if the attack should exit as a success
  # 0 if the attack should proceed its effect
  # 2 if Bide is storing energy
    if choice[2].zmove
      if choice[2].hasFlag?(:intercept)
        owner= @battle.pbGetOwner(attacker.index)
        @battle.pbDisplayBrief(_INTL("{1} is changing the flow of Fate!",attacker.pbThis))
        @battle.pbDisplayBrief(_INTL("{1}!",@name))
      else
        @battle.pbDisplayBrief(_INTL("{1} unleashed its full force Z-Move!",attacker.pbThis))
        @battle.pbDisplayBrief(_INTL("{1}!",getMoveUseName))
      end
    else
      @battle.pbDisplayBrief(_INTL("{1} used\r\n{2}!",attacker.pbThis,getMoveUseName))
    end
    return 0
  end

  def getMoveUseName
    if @data
      return (@data.checkFlag?(:longname,nil).nil?) ? @name : @data.checkFlag?(:longname,nil)
    else
      return @name
    end
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    @battle.pbAnimation(id,attacker,opponent,hitnum)
  end

  def pbOnDamageLost(damage,attacker,opponent)
    #Used by Counter/Mirror Coat/Revenge/Focus Punch/Bide
    type=pbType(attacker)
    if opponent.effects[:Bide]>0
      opponent.effects[:BideDamage]+=damage
      opponent.effects[:BideTarget]=attacker.index
    end
    if pbIsPhysical?(type) && opponent.effects[:ShellTrap]==true
      opponent.effects[:ShellTrapTarget]=attacker.index
    end
    if @function==0x90 # Hidden Power
      type=(:NORMAL) || 0
    end
    if pbIsPhysical?(type)
      opponent.effects[:Counter]=damage
      opponent.effects[:CounterTarget]=attacker.index
    end
    if pbIsSpecial?(type)
      opponent.effects[:MirrorCoat]=damage
      opponent.effects[:MirrorCoatTarget]=attacker.index
    end
    opponent.lastHPLost=damage # for Revenge/Focus Punch/Metal Burst
    opponent.lastAttacker=attacker.index # for Revenge/Metal Burst
  end

  def pbMoveFailed(attacker,opponent)
    # Called to determine whether the move failed
    return false
  end

################################################################################
# Zmove Stuff
################################################################################
  def ZMoveBaseDamage(oldmove)
    case oldmove.move
    when :MEGADRAIN      then return 120
    when :WEATHERBALL    then return 160
    when :HEX            then return 160
    when :GEARGRIND      then return 180
    when :VCREATE        then return 220
    when :FLYINGPRESS    then return 170
    when :COREENFORCER   then return 140
    # Variable Power Moves from now
    when :CRUSHGRIP      then return 190
    when :FLAIL          then return 160
    when :FRUSTRATION    then return 160
    when :NATURALGIFT    then return 160
    when :PRESENT        then return 100
    when :RETURN         then return 160
    when :SPITUP         then return 100
    when :TRUMPCARD      then return 160
    when :WRINGOUT       then return 190
    when :BEATUP         then return 100
    when :FLING          then return 100
    when :POWERTRIP      then return 160
    when :PUNISHMENT     then return 160
    when :ELECTROBALL    then return 160
    when :ERUPTION       then return 200
    when :HEATCRASH      then return 160
    when :GRASSKNOT      then return 160
    when :GYROBALL       then return 160
    when :HEAVYSLAM      then return 160
    when :LOWKICK        then return 160
    when :REVERSAL       then return 160
    when :MAGNITUDE      then return 140
    when :STOREDPOWER    then return 160
    when :WATERSPOUT     then return 200
    end
    check=oldmove.basedamage
    if check<56
      return 100
    elsif check<66
      return 120
    elsif check<76
      return 140
    elsif check<86
      return 160
    elsif check<96
      return 175
    elsif check<101
      return 180
    elsif check<111
      return 185
    elsif check<126
      return 190
    elsif check<131
      return 195
    elsif check>139
      return 200
    end
  end
end

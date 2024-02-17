################################################################################
# Rejuvenation custom move functions
# Venam's Kiss is handled in 005 (causes Poison) and pbTypeModifiers
# Multipulse is handled in 09F (Judgment/Multiattack)
# Barbed Web is handled in 005 (cauese Poison)
# Cold Truth is handled in 0B7 (Torment)
# Uproot is handled in 04F (drops Spdef by 2)
# Heavenly Wing is handled in 050 (Clear Smog)
# Slash and Burn & Pyrokinesis are handled in 00A (causes burn)
# Poison Sweep is handled in 044 (lowers speed)
# Stacking Shot is handled in 091 (Fury Cutter)
# Irritation is handled in  07F (Hex)
# Magma drift is handled in 075 (Surf)
# Deluge is handled in 081 (Revenge/Avalanche)
# Mud Barrage is handled in 0C0 (2-5 Multihit)
# Solar Flare is handled in 01C (raises attack)
# Hoarfrost Moon is handled in 020 (raises special attack)
# Wake-Up Shock is handled in 07D (Wake-up Slap)
# everything else is below
################################################################################

################################################################################
# Power is doubled if a foe tries to switch out. (Pursuit / Vile Assault)
# (Handled in Battle's pbAttackPhase): Makes this attack happen before switching.
################################################################################
class PokeBattle_Move_088 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return basedmg*2 if @battle.switching && @move != :VILEASSAULT
    return basedmg
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if @move == :VILEASSAULT
      @battle.pbAnimation(:POISONJAB,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Decimation
################################################################################
class PokeBattle_Move_200 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanPetrify?(true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbPetrify(attacker)
    @battle.pbDisplay(_INTL("{1} was petrified!",opponent.pbThis))
    opponent.effects[:Petrification]=attacker.index
    return 0
  end
  
  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanPetrify?(false)
    opponent.pbPetrify(attacker)
    @battle.pbDisplay(_INTL("{1} was petrified!!",opponent.pbThis))
    opponent.effects[:Petrification]=attacker.index
    return true
  end
end

################################################################################
# Gale Strike
################################################################################
class PokeBattle_Move_201 < PokeBattle_Move
  # Handled in superclass def pbCritRate?, do not edit!
end

################################################################################
# Power is chosen at random. 
# Can be used while asleep and wakes user up. (Fever Pitch)
################################################################################
class PokeBattle_Move_202 < PokeBattle_Move
  @calcbasedmg=0
  
  def pbOnStartUse(attacker)
    basedmg=[40,50,65,70,85,100,130]
    partyhype=[
       5,
       6,6,
       7,7,7,7,
       8,8,8,8,8,8,
       9,9,9,9,
       10,10,
       11
    ]
    hype=partyhype[@battle.pbRandom(partyhype.length)]
    hype=partyhype[0] if @battle.FE == :CONCERT1
    hype=partyhype[19] if @battle.FE == :CONCERT4
    @calcbasedmg=basedmg[hype-5]
    if attacker.crested == :LUVDISC
      @calcbasedmg=[attacker.happiness,250].min
      hype=12
    end
    @battle.pbDisplay(_INTL("Volume Level: {1}!",hype))
    return true
  end

  def pbCanUseWhileAsleep?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if attacker.status==:SLEEP
      attacker.status=nil
      @battle.pbDisplay(_INTL("{1} got itself too hyped for sleep!",attacker.pbThis))
    end
    return ret
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    return @calcbasedmg
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:BOOMBURST,attacker,opponent,hitnum) 
  end
end

################################################################################
# For 5 rounds, if Sandstorm,
# lowers power of super effective attacks against the user's side. (Arenite Wall)
################################################################################
class PokeBattle_Move_203 < PokeBattle_Move
    def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
      if attacker.pbOwnSide.effects[:AreniteWall]>0 || ((@battle.weather!=:SANDSTORM ||
        @battle.pbCheckGlobalAbility(:AIRLOCK) || @battle.pbCheckGlobalAbility(:CLOUDNINE)) &&
        !([:DESERT,:ROCKY,:ASHENBEACH].include?(@battle.FE)))
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      attacker.pbOwnSide.effects[:AreniteWall]=5
      attacker.pbOwnSide.effects[:AreniteWall]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
      attacker.pbOwnSide.effects[:AreniteWall]=8 if [:DESERT,:ROCKY,:ASHENBEACH].include?(@battle.FE)
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("A wall is protecting your team!"))
      else
        @battle.pbDisplay(_INTL("A wall is protecting the opposing team!"))
      end
      return 0
    end
  end

  ###############################################################################
# Matrix Shot
##############################################################################
class PokeBattle_Move_204 < PokeBattle_Move
  # Handled in superclass, do not edit!

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:POWERGEM,attacker,opponent,hitnum) 
  end
end

###############################################################################
# Desert's Mark
##############################################################################
class PokeBattle_Move_205 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if ((opponent.ability == :MULTITYPE) ||
      (opponent.ability == :RKSSYSTEM) || opponent.crested == :SILVALLY) &&
      opponent.effects[:MultiTurn]!=0 && opponent.effects[:DesertsMark]==true
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if !((opponent.ability == :MULTITYPE) ||
      (opponent.ability == :RKSSYSTEM) || opponent.crested == :SILVALLY)
      opponent.type1 = :GROUND
      opponent.type2 = nil 
      typename=getTypeName(:GROUND)
      @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",opponent.pbThis,typename))
    end
    opponent.effects[:DesertsMark]=true
    if !opponent.isFainted? && !opponent.damagestate.substitute
      if opponent.effects[:MultiTurn]==0
        opponent.effects[:MultiTurn]=50
        opponent.effects[:MultiTurnAttack]=@move
        opponent.effects[:MultiTurnUser]=attacker.index
        opponent.effects[:BindingBand] = attacker.hasWorkingItem(:BINDINGBAND)
        @battle.pbDisplay(_INTL("{1} was trapped within a Sand Tomb!",opponent.pbThis))        
      end
    end

    return 0
  end
end

################################################################################
# Probopass Special
################################################################################
class PokeBattle_Move_206 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    case hitnum
    when 0
        self.type=:STEEL
    when 1
        self.type=:ROCK
    when 2 
        self.type=:ELECTRIC
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 3
  end

# Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:BULLETSEED,attacker,opponent,hitnum) 
  end
end
  
################################################################################
# Increases the user's Special Attack and Speed by 1 stage each. (Aquabatics)
################################################################################
class PokeBattle_Move_207 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    boost_amount=1
    if @battle.FE == :BIGTOP
      boost_amount=2
    end
    for stat in [PBStats::SPATK,PBStats::SPEED]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,boost_amount,abilitymessage:false)
      end
    end
    return 0
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:DRAGONDANCE,attacker,opponent,hitnum) 
  end
end

################################################################################
# Hexing Slash(HP Drain+Poison. A-Mismagius)
################################################################################
class PokeBattle_Move_208 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      hpgain=((opponent.damagestate.hplost+1)/2).floor
      if opponent.ability == :LIQUIDOOZE
        hpgain*=2 if (@battle.FE == :WASTELAND || @battle.FE == :MURKWATERSURFACE || @battle.FE == :CORRUPTED)
        attacker.pbReduceHP(hpgain,true)
        @battle.pbDisplay(_INTL("{1} sucked up the liquid ooze!",attacker.pbThis))
      else
        if @battle.FE == :GRASSY
          hpgain=(hpgain*1.6).floor if attacker.hasWorkingItem(:BIGROOT)
        else
          hpgain=(hpgain*1.3).floor if attacker.hasWorkingItem(:BIGROOT)
        end
        attacker.pbRecoverHP(hpgain,true)
        @battle.pbDisplay(_INTL("{1} had its energy drained!",opponent.pbThis))
      end
    end
    return ret
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanPoison?(false)
    opponent.pbPoison(attacker)
    @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
    return true
  end

    # Replacement animation till a proper one is made
    def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
      return if !showanimation 
      @battle.pbAnimation(:SHADOWCLAW,attacker,opponent,hitnum) 
    end
end

################################################################################
# Bunraku Beatdown
# Base Power increases by increments for every party member that is KO'd.
################################################################################
class PokeBattle_Move_209 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if attacker.ability == :WORLDOFNIGHTMARES
      basedmg+=(15*opponent.pbFaintedPokemonCount)
      return basedmg
    else
      fainted=attacker.pbFaintedPokemonCount
      fainted=6 if attacker.pbFaintedPokemonCount>5
      basedmg+=(15*fainted)
      return basedmg
    end
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:BEATUP,attacker,opponent,hitnum) 
  end
end

################################################################################
# Quicksilver Spear
# Deals incremental damage at the end of the turn
# equal to 1/16th (1/8th against Bosses) of their HP while lowering their speed on impact.
################################################################################
class PokeBattle_Move_20A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !opponent.isFainted? && opponent.damagestate.calcdamage>0 &&
      !opponent.damagestate.substitute
      opponent.effects[:Quicksilver]=true
    end
    return ret
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::SPEED,false)
      opponent.pbReduceStat(PBStats::SPEED,1,abilitymessage:false, statdropper: attacker)
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:SACREDSWORD,attacker,opponent,hitnum) 
  end
end

################################################################################
# Spectral Scream - Randomly increases Defense or Special Defense by a stage
################################################################################
class PokeBattle_Move_20B < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    rnd=@battle.pbRandom(2)
    case rnd
    when 0
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
      end
    when 1 
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
      end
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:OMINOUSWIND,attacker,opponent,hitnum) 
  end
end

################################################################################
# Gilded Arrow/Gilded Helix
################################################################################
class PokeBattle_Move_20C < PokeBattle_Move
  def pbType(attacker,type=@type)
    if (!attacker.type2.nil?) && (attacker.type2!=:FAIRY && attacker.type2!=:DARK)
      return attacker.type2
    else
      return attacker.type1
    end
  end

  def pbIsMultiHit
    return true if @move == :GILDEDHELIX
    return false
  end

  def pbNumHits(attacker)
    if @move == :GILDEDHELIX
      return 2 
    else
      return 1
    end
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:SACREDSWORD,attacker,opponent,hitnum) 
  end
end

################################################################################
# Becomes physical if Atk does more than Sp. Atk. May reduce defense/spdef respectively
# (Super UMD Move) 
################################################################################
class PokeBattle_Move_20D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    smartDamageCategory(attacker,opponent)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
  end
  
  def pbAdditionalEffect(attacker,opponent)
    if @category == :physical
      if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,false) # physical
        opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
      end
    else
      if opponent.pbCanReduceStatStage?(PBStats::SPDEF,false) # physical
        opponent.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false, statdropper: attacker)
      end
    end
    return true
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if @category == :physical
      @battle.pbAnimation(:ULTRAMEGAHAMMER,attacker,opponent,hitnum) #physical
    else
      @battle.pbAnimation(:ULTRAMEGADEATH,attacker,opponent,hitnum) #special
    end
  end
end

################################################################################
# Mirror Beam (Uses user's secondary-type. Defaults to primary if no secondary.)
################################################################################
class PokeBattle_Move_20E < PokeBattle_Move
  def pbType(attacker,type=@type)
    if (!attacker.type2.nil?)
      return attacker.type2
    else
      return attacker.type1
    end
  end

# Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:MIRRORSHOT,attacker,opponent,hitnum) 
  end
end

################################################################################
# User inverts the target's stat stages. (Topsy-Turvy)
################################################################################
class PokeBattle_Move_142 < PokeBattle_Move
  def pbIsPhysical?(type=@type)
    return true if @battle.FE == :DEEPEARTH
    return false
  end

  def pbIsStatus?(type=@type)
    return false if @battle.FE == :DEEPEARTH
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    return 0 if @battle.FE != :DEEPEARTH
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    weight=opponent.weight*2
    ret=20
    ret=40 if weight>100
    ret=60 if weight>250
    ret=80 if weight>500
    ret=100 if weight>1000
    ret=120 if weight>2000
    return ret
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 1..7
      opponent.stages[i]=-opponent.stages[i]
    end
    @battle.pbDisplay(_INTL("{1} inverted {2}'s stat changes!",attacker.pbThis,opponent.pbThis(true)))
   # if !attacker.hasWorkingItem(:EVERSTONE) && @battle.canChangeFE?
   #   @battle.setField(:INVERSE,true)
   #   @battle.field.duration=3
   #   @battle.field.duration=6 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
   #   @battle.pbDisplay(_INTL("The terrain was inverted!"))
   # end
    if @battle.FE == :DEEPEARTH
      return super(attacker,opponent,hitnum,alltargets,false)
    else
      return 0
    end
  end
end

################################################################################
# Hits 3 times.  Power is multiplied by the hit number. (Triple Kick)
################################################################################
class PokeBattle_Move_0BF < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 3
  end

  def pbOnStartUse(attacker)
    @calcbasedmg=@basedamage
    @calcbasedmg=[attacker.happiness,250].min if attacker.crested == :LUVDISC
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    ret=@calcbasedmg
    @calcbasedmg+=basedmg
    return ret
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @move == :THUNDERRAID && opponent.isFainted? && hitnum != 2
      @battle.scene.pbUnVanishSprite(attacker)
    end
    return ret
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if @move == :THUNDERRAID
      case hitnum
      when 0
        @battle.pbAnimation(:THUNDERRAID,attacker,opponent,hitnum)
      when 1
        @battle.pbAnimation(:THUNDERRAID2,attacker,opponent,hitnum)
      when 2
        @battle.pbAnimation(:THUNDERRAID3,attacker,opponent,hitnum)
      else
        @battle.pbAnimation(id,attacker,opponent,hitnum)
      end
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Splintered Stormshards
################################################################################
class PokeBattle_Move_807 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.canChangeFE?(:ROCKY)
      @battle.setField(:ROCKY,3)
      @battle.pbDisplay(_INTL("The field was devastated!"))
    end
    return ret
  end
end

################################################################################
# Intercept-Z Unleashed Power
################################################################################
class PokeBattle_Move_80A < PokeBattle_Move
  def pbType(attacker,type=@type)
    type=pbHiddenPower(attacker.pokemon)
    type=super(attacker,type)
    return type
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    smartDamageCategory(attacker,opponent)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if ret==0
      return ret
    end
    if attacker.pbOpposingSide.effects[:Reflect]>0
      attacker.pbOpposingSide.effects[:Reflect]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The Interceptor's power broke the opponent's Reflect!"))
      else
        @battle.pbDisplayPaused(_INTL("Your Reflect was broken by the Interceptor's power!"))
      end
    end
    if attacker.pbOpposingSide.effects[:LightScreen]>0
      attacker.pbOpposingSide.effects[:LightScreen]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The Interceptor's power broke the opponent's Light Screen!"))
      else
        @battle.pbDisplay(_INTL("Your Light Screen was broken by the Interceptor's power!"))
      end
    end
    if attacker.pbOpposingSide.effects[:AuroraVeil]>0
      attacker.pbOpposingSide.effects[:AuroraVeil]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The Interceptor's power dispelled the opponent's Aurora Veil!"))
      else
        @battle.pbDisplay(_INTL("Your team's Aurora Veil was dispelled by the Interceptor's power!"))
      end
    end
    if attacker.pbOpposingSide.effects[:AreniteWall]>0
      attacker.pbOpposingSide.effects[:AreniteWall]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The Interceptor's power broke through the opponent's Arenite Wall!"))
      else
        @battle.pbDisplay(_INTL("Your team's Arenite Wall was broken by the Interceptor's power!"))
      end
    end
    return ret
  end
# Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:GIGAIMPACT,attacker,opponent,hitnum) 
  end
end

################################################################################
# Intercept-Z Blinding Speed
################################################################################
class PokeBattle_Move_80B < PokeBattle_Move
  def pbType(attacker,type=@type)
    type=attacker.type1
    type=super(attacker,type)
    return type
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    smartDamageCategory(attacker,opponent)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.pbPartner.isFainted?
      @battle.pbAnimation(:AFTERYOU,attacker,attacker.pbPartner,hitnum)
      success = @battle.pbMoveAfter(attacker, attacker.pbPartner)
      if success
        @battle.pbDisplay(_INTL("{1} follows {2}'s lead!", attacker.pbPartner.pbThis,attacker.pbThis))
      end
    end
    return ret
  end

# Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:EXTREMESPEED,attacker,opponent,hitnum) 
  end
end

################################################################################
# Intercept-Z Elysian Shield
################################################################################
class PokeBattle_Move_80C < PokeBattle_Move

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[:AuroraVeil]>0 &&
      attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false) && attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(:AURORAVEIL,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[:AuroraVeil]=5
    attacker.pbOwnSide.effects[:AuroraVeil]=8 if @battle.FE == :MIRROR
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
    end
    @battle.pbDisplay(_INTL("{1}'s Defenses became nearly impenetrable!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Intercept-Z Domain Shift
################################################################################
class PokeBattle_Move_80D < PokeBattle_Move
  def pbType(attacker,type=@type)
    type= $game_switches[:RenegadeRoute] && @battle.pbOwnedByPlayer?(attacker.index) ? :SHADOW : :FAIRY
    return type
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    fieldlist = [:ELECTERRAIN,:GRASSY,:MISTY,:SWAMP,:DESERT,:ICY,:ROCKY,:CAVE,:MOUNTAIN,:DEEPEARTH,:PSYTERRAIN,:HAUNTED,:CITY]
    if $game_switches[:RenegadeRoute] && @battle.pbOwnedByPlayer?(attacker.index)
      fieldlist = fieldlist + [:DARKCRYSTALCAVERN,:VOLCANIC,:CORROSIVE,:CORROSIVEMIST,:VOLCANICTOP,:SHORTCIRCUIT,:MURKWATERSURFACE,:DRAGONSDEN,:DIMENSIONAL,:FROZENDIMENSION,:INFERNAL,:BACKALLEY]
    else
      fieldlist = fieldlist + [:RAINBOW,:FOREST,:FACTORY,:WATERSURFACE,:CRYSTALCAVERN,:SNOWYMOUNTAIN,:HOLY,:FAIRYTALE,:STARLIGHT,:BEWITCHED,:SKY]
    end
    field = $game_variables[:DomainShift] != 0 ? game_variables[:DomainShift] : fieldlist.sample
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    @battle.setField(field)
    @battle.pbDisplay(_INTL("The Core dictates a new Environment!"))
    return 0
  end

# Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:MAGICROOM,attacker,opponent,hitnum) 
  end 
end

################################################################################
# Intercept-Z Chthonic Malady
################################################################################
class PokeBattle_Move_80E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !opponent.pbCanPetrify?(false) && opponent.effects[:Torment] &&
      opponent.pbCanReduceStatStage?(PBStats::ATTACK,false) && opponent.pbCanReduceStatStage?(PBStats::SPATK,false)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.pbCanPetrify?(false)
      opponent.pbPetrify(attacker)
      @battle.pbDisplay(_INTL("{1} was petrified!",opponent.pbThis))
      opponent.effects[:Petrification]=attacker.index
    end
    if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from torment!"))
    else
      opponent.effects[:Torment]=true
      @battle.pbDisplay(_INTL("{1} was subjected to torment!",opponent.pbThis))
    end
    if opponent.pbCanReduceStatStage?(PBStats::ATTACK,false)
      opponent.pbReduceStat(PBStats::ATTACK,2,abilitymessage:false, statdropper: attacker)
    end
    if opponent.pbCanReduceStatStage?(PBStats::SPATK,false)
      opponent.pbReduceStat(PBStats::SPATK,2,abilitymessage:false, statdropper: attacker)
    end
    opponent.effects[:ChtonicMalady] = 5
    @battle.pbDisplay(_INTL("{1}'s end is drawing close!",opponent.pbThis))
    return 0
  end

# Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation 
    @battle.pbAnimation(:DARKVOID,attacker,opponent,hitnum) 
  end
end


### BEGINNING OF @SWU'S MOVES ###

################################################################################
# Hammer mode lowers opponent's Def and SpDef 
# Cannon mode lowers opponent's Atk and SpAtk (Ultra Mega Death Hammer/Cannon)
# Original (Super UMD Move) 900
################################################################################

class PokeBattle_Move_900 < PokeBattle_Move

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    # @SWu's current shitty fix for this animation bug wtf is happening

    if rand(2) == 0
      @category = :physical
    else
      @category = :special
    end
    
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbAdditionalEffect(attacker,opponent)
    statdrop = false
    
    if @category == :physical
      if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,false)
        opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
        statdrop = true
      end
      if opponent.pbCanReduceStatStage?(PBStats::SPDEF,false)
        opponent.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false, statdropper: attacker)
        statdrop = true
      end
      if statdrop
        @battle.pbDisplay(_INTL("Hammer mode lowered {1}'s defenses!",
          opponent.pbThis))
      end
    else
      if opponent.pbCanReduceStatStage?(PBStats::ATTACK,false)
        opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
        statdrop = true
      end
      if opponent.pbCanReduceStatStage?(PBStats::SPATK,false)
        opponent.pbReduceStat(PBStats::SPATK,1,abilitymessage:false, statdropper: attacker)
        statdrop = true
      end
      if statdrop
        @battle.pbDisplay(_INTL("Cannon mode lowered {1}'s offenses!",
          opponent.pbThis))
      end
    end
    return true
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if @category == :physical
      @battle.pbAnimation(:ULTRAMEGAHAMMER,attacker,opponent,hitnum) #physical
    else
      @battle.pbAnimation(:ULTRAMEGADEATH,attacker,opponent,hitnum) #special
    end
  end

end
################################################################################
# Superclass that handles moves using a non-existent function code.
# Damaging moves just do damage with no additional effect.
# Non-damaging moves always fail.
################################################################################
class PokeBattle_UnimplementedMove < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @basedamage>0
      return super(attacker,opponent,hitnum,alltargets,showanimation)
    else
      @battle.pbDisplay("But it failed!")
      return -1
    end
  end
end

################################################################################
# Superclass for a failed move.  Always fails.
################################################################################
class PokeBattle_FailedMove < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    @battle.pbDisplay("But it failed!")
    return -1
  end
end

################################################################################
# Pseudomove for confusion damage
################################################################################
class PokeBattle_Confusion < PokeBattle_Move
  def initialize(battle,move)
    @battle=battle
    @basedamage=40
    @type=-1
    @accuracy=100
    @pp=-1
    @effect=0
    @target=0
    @priority=0
    @flags=35
    @basemove=move
    @name=""
  end

  def pbIsPhysical?(type=nil)
    return true
  end

  def pbIsSpecial?(type=@type)
    return false
  end

  def isSoundBased?
    return false
  end
  
  def pbCalcDamage(attacker,opponent, hitnum: 0)
    return super(attacker,opponent,0, hitnum: hitnum)
  end

  def pbEffectMessages(attacker,opponent,ignoretype=false)
    return super(attacker,opponent,true)
  end
end

################################################################################
# Implements the move Struggle.
# For cases where the real move named Struggle is not defined.
################################################################################
class PokeBattle_Struggle < PokeBattle_Move
  def initialize(battle,move,user,zbase=nil)
    @battle=battle
    @basedamage=50
    @type=-1
    @data = $cache.moves[:STRUGGLE]
    @accuracy=100
    @pp=-1
    @totalpp=0
    @effect=0
    @moreeffect=0
    @target=:SingleNonUser
    @priority=0
    @flags=35     #flags abf
    @basemove=nil # not associated with a move
    @name=""
    @move= :STRUGGLE
    @function = 0x02
  end

  def pbIsPhysical?(type=nil)
    return true
  end

  def pbIsSpecial?(type=@type)
    return false
  end

  def pbDisplayUseMessage(attacker,choice)
    @battle.pbDisplayBrief(_INTL("{1} is struggling!",attacker.pbThis))
    return 0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=false)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation=false)
    if opponent.damagestate.calcdamage>0
      attacker.pbReduceHP((attacker.totalhp/4.0).floor)
      @battle.pbDisplay(_INTL("{1} is damaged by the recoil!",attacker.pbThis))
    end
    return ret
  end

  def pbCalcDamage(attacker,opponent, hitnum: 0)
    return super(attacker,opponent,0, hitnum: hitnum)
  end
end

################################################################################
# No additional effect.
################################################################################
class PokeBattle_Move_000 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret = super(attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :AQUACUTTER
      @battle.pbAnimation(:RAZORSHELL,attacker,opponent,hitnum)
    elsif (@move == :RAINBOWSCALES)
      @battle.pbAnimation(:FAIRYWIND,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Does absolutely nothing (Splash / Celebrate).
################################################################################
class PokeBattle_Move_001 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return @battle.state.effects[:Gravity]!=0 if @move == :SPLASH && attacker.ability != :GRAVFLUX
    return false
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @move == :CELEBRATE
      ret = super(attacker,opponent,hitnum,alltargets,showanimation)
      @battle.pbDisplay(_INTL("Congratulations, #{$Trainer.name}!"))
      return ret
    end
    if @battle.FE == :WATERSURFACE
      return -1 if !opponent.pbCanReduceStatStage?(PBStats::ACCURACY,true)
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      ret=opponent.pbReduceStat(PBStats::ACCURACY,1,abilitymessage:false, statdropper: attacker)
      return ret ? 0 : -1
    else
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      @battle.pbDisplay(_INTL("But nothing happened!"))
      return 0
    end
  end
end

################################################################################
# Struggle.  Overrides the default Struggle effect above.
################################################################################
class PokeBattle_Move_002 < PokeBattle_Struggle
end

################################################################################
# Puts the target to sleep. (Dark Void / Grass Whistle / Spore / Sleep Powder /
# Relic Song / Lovely Kiss / Sing / Hypnosis)
################################################################################
class PokeBattle_Move_003 < PokeBattle_Move
  def pbOnStartUse(attacker)
    if (@move == :DARKVOID) && !Rejuv && !((attacker.species == :DARKRAI) || ((attacker.species == :HYPNO) && (attacker.form == 1)))
    # any non-darkrai Pokemon
      @battle.pbDisplay(_INTL("But {1} can't use the move!",attacker.pbThis))
      return false
    else
      if @battle.FE==:DARKNESS2 || @battle.FE==:DARKNESS3
        @battle.pbDisplay(_INTL("We fall..."))
        @battle.pbDisplay(_INTL(" We fall... unto the end..."))
      end
      return true
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if opponent.pbCanSleep?(true)
      if (@move == :SPORE) || (@move == :SLEEPPOWDER) 
        if opponent.hasType?(:GRASS)
          @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
          return -1
        elsif opponent.ability == :OVERCOAT && !(opponent.moldbroken)
          @battle.pbDisplay(_INTL("{1}'s {2} made the attack ineffective!",
          opponent.pbThis,getAbilityName(opponent.ability),self.name))
          return -1
        elsif (opponent.item == :SAFETYGOGGLES)
          @battle.pbDisplay(_INTL("{1} avoided the move with its {2}!",
          opponent.pbThis,getItemName(opponent.item),self.name))
          return -1
        end
      end
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.pbSleep
      @battle.pbDisplay(_INTL("{1} went to sleep!",opponent.pbThis))
      return 0
    end
    return -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanSleep?(false)
      opponent.pbSleep
      @battle.pbDisplay(_INTL("{1} went to sleep!",opponent.pbThis))
      return true
    end
    return false
  end
end

################################################################################
# Makes the target drowsy.  It will fall asleep at the end of the next turn. (Yawn)
################################################################################
class PokeBattle_Move_004 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanSleep?(true)
    if opponent.effects[:Yawn]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:Yawn]=2
    @battle.pbDisplay(_INTL("{1} made {2} drowsy!",attacker.pbThis,opponent.pbThis(true)))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanSleep?(false)
      opponent.effects[:Yawn]=2
      @battle.pbDisplay(_INTL("{1} made {2} drowsy!",attacker.pbThis,opponent.pbThis(true)))
      return true
    end
    return false
  end
end

################################################################################
# Poisons the target. (Gunk Shot / Sludge Wave / Sludge Bomb / Poison Jab / Cross Poison 
# / Sludge / Poison Tail / Smog / Poison Sting / Poison Gas / Poison Powder)
################################################################################
class PokeBattle_Move_005 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if (@move == :POISONPOWDER)
      if opponent.hasType?(:GRASS)
        @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
        return -1
      elsif (opponent.ability == :OVERCOAT) && !(opponent.moldbroken)
        @battle.pbDisplay(_INTL("{1}'s {2} made the attack ineffective!",
        opponent.pbThis,getAbilityName(opponent.ability),self.name))
        return -1
      elsif (opponent.item == :SAFETYGOGGLES)
        @battle.pbDisplay(_INTL("{1} avoided the move with its {2}!",
        opponent.pbThis,getItemName(opponent.item),self.name))
        return -1
      end
    end
    return -1 if !opponent.pbCanPoison?(true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if [:VOLCANICTOP,:BACKALLEY,:CITY].include?(@battle.FE) && @move == :POISONGAS
      opponent.pbPoison(attacker,true)
      @battle.pbDisplay(_INTL("{1} is badly poisoned!",opponent.pbThis))
    else
      opponent.pbPoison(attacker)
      @battle.pbDisplay(_INTL("{1} is poisoned!",opponent.pbThis))
    end
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if @move == :BARBEDWEB 
      if (!attacker.pbOpposingSide.effects[:StickyWeb])
        attacker.pbOpposingSide.effects[:StickyWeb]=true
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("A sticky web has been laid out beneath your foe's team's feet!"))
        else
          @battle.pbDisplay(_INTL("A sticky web has been laid out beneath your team's feet!"))
        end
      elsif(attacker.pbOpposingSide.effects[:Spikes] < 3)
        attacker.pbOpposingSide.effects[:Spikes]+= 1
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("Spikes were scattered around your foe's team's feet!"))
        else
          @battle.pbDisplay(_INTL("Spikes were scattered around your team's feet!"))
        end
      end
      if (@battle.pbRandom(5) < 1) 
        return false if !opponent.pbCanPoison?(false)
        if [:BACKALLEY,:CITY].include?(@battle.FE) && @move == :SMOG
          opponent.pbPoison(attacker,true)
          @battle.pbDisplay(_INTL("{1} was badly poisoned!",opponent.pbThis))
        else
          opponent.pbPoison(attacker)
          @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
        end
        return true
      end
    end
    if @battle.FE == :WASTELAND && ((@move == :GUNKSHOT) || (@move == :SLUDGEBOMB) || 
      (@move == :SLUDGEWAVE) || (@move == :SLUDGE)) &&
     ((!opponent.hasType?(:POISON) && !opponent.hasType?(:STEEL)) || opponent.corroded) &&
     !(opponent.ability == :TOXICBOOST) &&
     !(opponent.ability == :POISONHEAL) && !(opponent.crested == :ZANGOOSE) && !(opponent.crested == :GOODRA)
     (!(opponent.ability == :IMMUNITY) && !(opponent.moldbroken))
      rnd=@battle.pbRandom(4)
      case rnd
        when 0
          return false if !opponent.pbCanBurn?(false)
          opponent.pbBurn(attacker)
          @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
        when 1
          return false if !opponent.pbCanFreeze?(false)
          opponent.pbFreeze
          @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
        when 2
          return false if !opponent.pbCanParalyze?(false)
          opponent.pbParalyze(attacker)
          @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
        when 3
          return false if !opponent.pbCanPoison?(false)
          opponent.pbPoison(attacker)
          @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
        end
    else
      return false if !opponent.pbCanPoison?(false)
      if [:BACKALLEY,:CITY].include?(@battle.FE) && @move == :SMOG
        opponent.pbPoison(attacker,true)
        @battle.pbDisplay(_INTL("{1} was badly poisoned!",opponent.pbThis))
      else
        opponent.pbPoison(attacker)
        @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
      end
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :BARBEDWEB
      @battle.pbAnimation(:TOXICTHREAD,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Badly poisons the target. (Poison Fang / Toxic)
################################################################################
class PokeBattle_Move_006 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanPoison?(true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbPoison(attacker,true)
    @battle.pbDisplay(_INTL("{1} is badly poisoned!",opponent.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanPoison?(false) # always overrides
    opponent.pbPoison(attacker,true)
    @battle.pbDisplay(_INTL("{1} was badly poisoned!",opponent.pbThis))
    return true
  end

    # Replacement animation till a proper one is made
    def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
      return if !showanimation
      if id == :MELTDOWN
        @battle.pbAnimation(:EXPLOSION,attacker,opponent,hitnum)
      elsif id == :ENVENOM
        @battle.pbAnimation(:POISONTAIL,attacker,opponent,hitnum)
      else
        @battle.pbAnimation(id,attacker,opponent,hitnum)
      end
    end
end

################################################################################
# Paralyzes the target. (Nuzzle / Dragon Breath / Bolt Strike / Zap Cannon / Thunderbolt
# / Discharge / Thunder Punch / Spark / Thunder Shock / Thunder Wave / Force Palm 
# / Lick / Stun Spore / Body Slam / Glare / Wildbolt Storm)
################################################################################
class PokeBattle_Move_007 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanParalyze?(true)
    if (@move == :STUNSPORE)
      if opponent.hasType?(:GRASS)
        @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
        return -1
      elsif (opponent.ability == :OVERCOAT) && !(opponent.moldbroken)
        @battle.pbDisplay(_INTL("{1}'s {2} made the attack ineffective!",
        opponent.pbThis,getAbilityName(opponent.ability),self.name))
        return -1
      elsif (opponent.item == :SAFETYGOGGLES)
        @battle.pbDisplay(_INTL("{1} avoided the move with its {2}!",
        opponent.pbThis,getItemName(opponent.item),self.name))
        return -1
      end
    else
      if (@move == :THUNDERWAVE)
        typemod=pbTypeModifier(@type,attacker,opponent)
        if typemod==0
          @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
          return -1
        end
      end
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbParalyze(attacker)
    @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
    return 0
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    damagemult*= 2.0 if opponent.effects[:Minimize] && (@move == :BODYSLAM)
    return damagemult
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanParalyze?(false)
    opponent.pbParalyze(attacker)
    @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!",opponent.pbThis))
    if @move == :VOLTCRASH && opponent.pbPartner.pbCanParalyze?
      opponent.pbPartner.pbParalyze(attacker)
      @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!",opponent.pbPartner.pbThis))
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :WILDBOLTSTORM
      @battle.pbAnimation(:THUNDER,attacker,opponent,hitnum)
    elsif id == :ETHEREALTEMPEST
      @battle.pbAnimation(:HURRICANE,attacker,opponent,hitnum)
    elsif id == :VOLTCRASH
      @battle.pbAnimation(:CATASTROPIKA,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Paralyzes the target.  (Thunder)
# (Handled in Battler's pbSuccessCheck): Hits some semi-invulnerable targets.
# (Handled in pbAccuracyCheck): Accuracy perfect in rain, 50% in sunshine.
################################################################################
class PokeBattle_Move_008 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanParalyze?(false)
    opponent.pbParalyze(attacker)
    @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!",opponent.pbThis))
    return true
  end
end

################################################################################
# Paralyzes the target.  May cause the target to flinch. (Thunder Fang)
################################################################################
class PokeBattle_Move_009 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanParalyze?(false)
      opponent.pbParalyze(attacker)
      @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!",opponent.pbThis))
      return true
    end
    return false
  end

  def pbSecondAdditionalEffect(attacker,opponent)
    if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute
      opponent.effects[:Flinch]=true
      return true
    end
    return false
  end
end

 
################################################################################
# Burns the target. (Blue Flare / Fire Blast / Heat Wave / Inferno / Searing Shot
# / Flamethrower / Blaze Kick / Lava Plume / Fire Punch / Flame Wheel / Ember
# / Will-O-Wisp / Scald / Steam Eruption / Sandsear Storm)
################################################################################
class PokeBattle_Move_00A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanBurn?(true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbBurn(attacker)
    @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanBurn?(false)
    opponent.pbBurn(attacker)
    @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
    if @move == :CENTIFERNO && opponent.pbPartner.pbCanBurn?
      opponent.pbPartner.pbBurn(attacker)
      @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbPartner.pbThis))
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :SLASHANDBURN
      @battle.pbAnimation(:POWERWHIP,attacker,opponent,hitnum)
    elsif id == :PYROKINESIS
      @battle.pbAnimation(:MYSTICALFIRE,attacker,opponent,hitnum)
    elsif id == :SANDSEARSTORM
      @battle.pbAnimation(:SCORCHINGSANDS,attacker,opponent,hitnum)
    elsif id == :CENTIFERNO
      @battle.pbAnimation(:INFERNO,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    if @move == :HEATWAVE && @battle.pbWeather!=0 &&
      @battle.pbWeather == :SUNNYDAY
      return basedmg*1.3
    end
    return basedmg
  end
end

################################################################################
# Burns the target.  May cause the target to flinch. (Fire Fang)
################################################################################
class PokeBattle_Move_00B < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanBurn?(false)
      opponent.pbBurn(attacker)
      @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
      return true
    end
    return false
  end

  def pbSecondAdditionalEffect(attacker,opponent)
    if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute
      opponent.effects[:Flinch]=true
      return true
    end
    return false
  end
end

################################################################################
# Freezes the target. (Ice Beam / Ice Punch / Powder Snow / Freeze-Dry)
################################################################################
class PokeBattle_Move_00C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanFreeze?(true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbFreeze
    @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanFreeze?(false)
      opponent.pbFreeze
      @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
      return true
    end
    return false
  end
end

################################################################################
# Freezes the target. (Blizzard)
# (Handled in pbAccuracyCheck): Accuracy perfect in hail.
################################################################################
class PokeBattle_Move_00D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanFreeze?(true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbFreeze
    @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanFreeze?(false)
      opponent.pbFreeze
      @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
      return true
    end
    return false
  end
end

################################################################################
# Freezes the target.  May cause the target to flinch. (Ice Fang)
################################################################################
class PokeBattle_Move_00E < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanFreeze?(false)
      opponent.pbFreeze
      @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
      return true
    end
    return false
  end

  def pbSecondAdditionalEffect(attacker,opponent)
    if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute
      opponent.effects[:Flinch]=true
      return true
    end
    return false
  end
end

################################################################################
# Causes the target to flinch. (Flinch / Dark Pulse / Bite / Rolling Kick / Air Slash
# / Astonish / Needle Arm / Hyper Fang / Headbutt / Extrasensory / Zen Headbutt
# / Heart Stamp / Rock Slide / Iron Head / Waterfall / Zing Zap / Mountain Gale)
################################################################################
class PokeBattle_Move_00F < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute 
      opponent.effects[:Flinch]=true

      if (@move == :HEARTSTAMP) && (opponent.pbCanAttract?(attacker)) && (@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? || opponent.moldbroken)
        opponent.effects[:Attract]=attacker.index
        @battle.pbCommonAnimation("Attract",opponent,nil)
        @battle.pbDisplay(_INTL("{1} fell in love!",opponent.pbThis))
        if opponent.hasWorkingItem(:DESTINYKNOT) && attacker.ability != :OBLIVIOUS && attacker.effects[:Attract]<0
          attacker.effects[:Attract]=opponent.index
          @battle.pbCommonAnimation("Attract",attacker,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} infatuated {3}!",opponent.pbThis,
          getItemName(opponent.item),attacker.pbThis(true)))
        end
      end
      return true
    end
    return false
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :MOUNTAINGALE
      @battle.pbAnimation(:AVALANCHE,attacker,opponent,hitnum)
    elsif id == :CHIRP
      @battle.pbAnimation(:CHATTER,attacker,opponent,hitnum)
    elsif id == :VINELASH
      @battle.pbAnimation(:FRENZYPLANT,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Causes the target to flinch.  Does double damage if the target is Minimized.
# (Stomp, Steamroller, Dragon Rush)
################################################################################
class PokeBattle_Move_010 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret = super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if @move == :STEAMROLLER && opponent.isFainted? &&
       attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
    end
    return ret
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute 
      opponent.effects[:Flinch]=true
      return true
    end
    return false
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    damagemult*= 2.0 if opponent.effects[:Minimize]
    return damagemult
  end
end

################################################################################
# Causes the target to flinch.  Fails if the user is not asleep. (Snore)
################################################################################
class PokeBattle_Move_011 < PokeBattle_Move
  def pbCanUseWhileAsleep?
    return true
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute 
      opponent.effects[:Flinch]=true
      return true
    end
    return false
  end

  def pbMoveFailed(attacker,opponent)
    return attacker.status!=:SLEEP && (attacker.ability != :COMATOSE || @battle.FE == :ELECTERRAIN)
  end
end

################################################################################
# Causes the target to flinch.  Fails if this isn't the user's first turn. (Fake Out)
################################################################################
class PokeBattle_Move_012 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute 
      opponent.effects[:Flinch]=true
      return true
    end
    return false
  end

  def pbMoveFailed(attacker,opponent)
    return (attacker.turncount != 1 || !attacker.isFirstMoveOfRound)
  end
end

################################################################################
# Confuses the target. (Confusion, Signal Beam, Dynamic Punch, Chatter, Confuse Ray,
# Rock Climb, Dizzy Punch, Supersonic, Sweet Kiss, Teeter Dance, Psybeam, Water Pulse,
# Strange Steam)
################################################################################
class PokeBattle_Move_013 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if @battle.FE == :FAIRYTALE && (@move == :SWEETKISS)
      if !opponent.damagestate.substitute && opponent.status== :SLEEP
        opponent.pbCureStatus
      end
    end
    if  @battle.FE == :DANCEFLOOR && (@move == :TEETERDANCE)
      opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
    end
    if opponent.pbCanConfuse?(true)
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.effects[:Confusion]=2+@battle.pbRandom(4)
      @battle.pbCommonAnimation("Confusion",opponent,nil)
      @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
      return 0
    end
    return -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanConfuse?(false)
      opponent.effects[:Confusion]=2+@battle.pbRandom(4)
      @battle.pbCommonAnimation("Confusion",opponent,nil)
      @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
      return true
    end
    return false
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :SMITE
      @battle.pbAnimation(:SWIFT,attacker,opponent,hitnum)
    elsif id == :MIRAGEBEAM
      @battle.pbAnimation(:PSYBEAM,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Confuses the target.  (Hurricane)
# (Handled in Battler's pbSuccessCheck): Hits some semi-invulnerable targets.
# (Handled in pbAccuracyCheck): Accuracy perfect in rain, 50% in sunshine.
################################################################################
class PokeBattle_Move_015 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if opponent.pbCanConfuse?(true)
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.effects[:Confusion]=2+@battle.pbRandom(4)
      @battle.pbCommonAnimation("Confusion",opponent,nil)
      @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
      return 0
    end
    return -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanConfuse?(false)
      opponent.effects[:Confusion]=2+@battle.pbRandom(4)
      @battle.pbCommonAnimation("Confusion",opponent,nil)
      @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
      return true
    end
    return false
  end
end

################################################################################
# Attracts the target. (Attract)
################################################################################
class PokeBattle_Move_016 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if !opponent.pbCanAttract?(attacker)
      return -1
    end
    if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from infatuation!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:Attract]=attacker.index
    @battle.pbCommonAnimation("Attract",opponent,nil)
    @battle.pbDisplay(_INTL("{1} fell in love!",opponent.pbThis))
    if opponent.hasWorkingItem(:DESTINYKNOT) && attacker.ability != :OBLIVIOUS && attacker.effects[:Attract]<0
      attacker.effects[:Attract]=opponent.index
      @battle.pbCommonAnimation("Attract",attacker,nil)
      @battle.pbDisplay(_INTL("{1}'s {2} infatuated {3}!",opponent.pbThis,
      getItemName(opponent.item),attacker.pbThis(true)))
    end
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from infatuation!"))
    end
    if opponent.pbCanAttract?(attacker)
      opponent.effects[:Attract]=attacker.index
      @battle.pbCommonAnimation("Attract",opponent,nil)
      @battle.pbDisplay(_INTL("{1} fell in love!",opponent.pbThis))
      if opponent.hasWorkingItem(:DESTINYKNOT) && attacker.ability != :OBLIVIOUS && attacker.effects[:Attract]<0
        attacker.effects[:Attract]=opponent.index
        @battle.pbCommonAnimation("Attract",attacker,nil)
        @battle.pbDisplay(_INTL("{1}'s {2} infatuated {3}!",opponent.pbThis,
        getItemName(opponent.item),attacker.pbThis(true)))
      end
    end
    if (@move == :SPRINGTIDESTORM && !opponent.effects[:Torment])
      opponent.effects[:Torment]=true
      @battle.pbAnimation(:TORMENT,attacker,opponent,1)
      @battle.pbDisplay(_INTL("{1} was subjected to torment!",opponent.pbThis))
    end
    return true
  end

end

################################################################################
# Burns, freezes or paralyzes the target. (Tri Attack)
################################################################################
class PokeBattle_Move_017 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    rnd=@battle.pbRandom(3)
    case rnd
      when 0
        return false if !opponent.pbCanBurn?(false)
        opponent.pbBurn(attacker)
        @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
      when 1
        return false if !opponent.pbCanFreeze?(false)
        opponent.pbFreeze
        @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
      when 2
        return false if !opponent.pbCanParalyze?(false)
        opponent.pbParalyze(attacker)
        @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
    end
    return true
  end
end

################################################################################
# Cures user of burn, poison and paralysis. (Refresh)
################################################################################
class PokeBattle_Move_018 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.status!=:BURN &&
       attacker.status!=:POISON &&
       attacker.status!=:PARALYSIS &&
       attacker.status!=:FROSTBITE
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    else
      t=attacker.status
      attacker.status=nil
      attacker.statusCount=0
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      if t== :BURN
        @battle.pbDisplay(_INTL("{1} was cured of its burn.",attacker.pbThis))
      elsif t== :POISON
        @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",attacker.pbThis))
      elsif t== :PARALYSIS
        @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",attacker.pbThis))
      elsif t== :FROSTBITE
        @battle.pbDisplay(_INTL("{1} was cured of its frostbite.",attacker.pbThis))
      end
      return 0
    end
  end
end

################################################################################
# Cures all party Pokémon of permanent status problems. (Aromatherapy, Heal Bell)
################################################################################
class PokeBattle_Move_019 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if (@move == :AROMATHERAPY)
      @battle.pbDisplay(_INTL("A soothing aroma wafted through the area!"))
    else
      @battle.pbDisplay(_INTL("A bell chimed!"))
    end
    activepkmn=[]
    for i in @battle.battlers
      next if attacker.pbIsOpposing?(i.index)
      case i.status
        when :PARALYSIS
          @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",i.pbThis))
        when :SLEEP
          @battle.pbDisplay(_INTL("{1} was woken from its sleep.",i.pbThis))
        when :POISON
          @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",i.pbThis))
        when :BURN
          @battle.pbDisplay(_INTL("{1} was cured of its burn.",i.pbThis))
        when :FROZEN
          @battle.pbDisplay(_INTL("{1} was defrosted.",i.pbThis))
        when :FROSTBITE
          @battle.pbDisplay(_INTL("{1} was cured of its frostbite.",i.pbThis))
        when :PETRFIED
          @battle.pbDisplay(_INTL("{1} was released from the stone.",i.pbThis))
      end
      i.status=nil
      i.statusCount=0
      activepkmn.push(i.pokemonIndex)
    end
    party=@battle.pbParty(attacker.index) # NOTE: Considers both parties in multi battles
    for i in 0...party.length
      next if activepkmn.include?(i)
      next if !party[i] || party[i].isEgg?
      case party[i].status
        when :PARALYSIS
          @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",party[i].name))
        when :SLEEP
          @battle.pbDisplay(_INTL("{1} was woken from its sleep.",party[i].name))
        when :POISON
          @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",party[i].name))
        when :BURN
          @battle.pbDisplay(_INTL("{1} was cured of its burn.",party[i].name))
        when :FROZEN
          @battle.pbDisplay(_INTL("{1} was defrosted.",party[i].name))
        when :PETRFIED
          @battle.pbDisplay(_INTL("{1} was released from the stone.",party[i].name))
      end
      party[i].status=nil
      party[i].statusCount=0
    end
    return 0
  end
end

################################################################################
# Safeguards the user's side from being inflicted with status problems. (Safeguard)
################################################################################
class PokeBattle_Move_01A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[:Safeguard]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    attacker.pbOwnSide.effects[:Safeguard]=5
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("Your team became cloaked in a mystical veil!"))
    else
      @battle.pbDisplay(_INTL("The foe's team became cloaked in a mystical veil!"))
    end
    return 0
  end
end

################################################################################
# User passes its status problem to the target. (Psycho Shift)
################################################################################
class PokeBattle_Move_01B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.status.nil? ||
      (attacker.status== :PARALYSIS && !opponent.pbCanParalyze?(false)) ||
      (attacker.status== :SLEEP && !opponent.pbCanSleep?(false)) ||
      (attacker.status== :POISON && !opponent.pbCanPoison?(false)) ||
      (attacker.status== :BURN && !opponent.pbCanBurn?(false)) ||
      (attacker.status== :FROZEN && !opponent.pbCanFreeze?(false)) ||
      (attacker.status== :PETRIFIED && !opponent.pbCanPetrify?(false))
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    case attacker.status
      when :PARALYSIS
        opponent.pbParalyze(attacker)
        @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
        opponent.pbAbilityCureCheck
        @battle.synchronize=[-1,-1,0] if opponent.status!=:PARALYSIS
        attacker.status=nil
        @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",attacker.pbThis))
      when :SLEEP
        opponent.pbSleep
        @battle.pbDisplay(_INTL("{1} went to sleep!",opponent.pbThis))
        opponent.pbAbilityCureCheck
        @battle.synchronize=[-1,-1,0] if opponent.status!=:SLEEP
        attacker.status=nil
        attacker.statusCount=0
        @battle.pbDisplay(_INTL("{1} was woken from its sleep.",attacker.pbThis))
      when :POISON
        opponent.pbPoison(attacker,attacker.statusCount!=0)
        if attacker.statusCount!=0
          @battle.pbDisplay(_INTL("{1} is badly poisoned!",opponent.pbThis))
        else
          @battle.pbDisplay(_INTL("{1} is poisoned!",opponent.pbThis))
        end
        opponent.pbAbilityCureCheck
        @battle.synchronize=[-1,-1,0] if opponent.status!=:POISON
        attacker.status=nil
        attacker.statusCount=0
        @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",attacker.pbThis))
      when :BURN
        opponent.pbBurn(attacker)
        @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
        opponent.pbAbilityCureCheck
        @battle.synchronize=[-1,-1,0] if opponent.status!=:BURN
        attacker.status=nil
        @battle.pbDisplay(_INTL("{1} was cured of its burn.",attacker.pbThis))
      when :FROZEN
        opponent.pbFreeze
        @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
        opponent.pbAbilityCureCheck
        @battle.synchronize=[-1,-1,0] if opponent.status!=:FROZEN
        attacker.status=nil
        @battle.pbDisplay(_INTL("{1} was defrosted.",attacker.pbThis))
      when :PETRFIED
        opponent.pbPetrify(attacker)
        @battle.pbDisplay(_INTL("{1} was petrified!",opponent.pbThis))
        opponent.pbAbilityCureCheck
        @battle.synchronize=[-1,-1,0] if opponent.status!=:PETRIFIED
        attacker.status=nil
        @battle.pbDisplay(_INTL("{1} was released from the stone.",attacker.pbThis))
    end
    return 0
  end
end

################################################################################
# Increases the user's Attack by 1 stage. (Howl, Sharpen, Meditate, Meteor Mash, Metal Claw, Power-Up Punch)
################################################################################
class PokeBattle_Move_01C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if (@battle.FE == :RAINBOW || @battle.FE == :ASHENBEACH) &&
       (@move == :MEDITATE)  # Rainbow/Ashen Field
      ret=attacker.pbIncreaseStat(PBStats::ATTACK,3,abilitymessage:false)
    elsif @battle.FE == :PSYTERRAIN && (@move == :MEDITATE)  # Psychic Terrain
      ret=attacker.pbIncreaseStat(PBStats::ATTACK,2,abilitymessage:false)
      ret=attacker.pbIncreaseStat(PBStats::SPATK,2,abilitymessage:false)
    elsif (@battle.FE == :COLOSSEUM || @battle.ProgressiveFieldCheck(PBFields::CONCERT)) && (@move == :HOWL)
      ret=attacker.pbIncreaseStat(PBStats::ATTACK,2,abilitymessage:false)
    else
      ret=attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
      if @move == :HOWL
        if attacker.pbPartner && attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::ATTACK,true)
          statboost = 1
          statboost = 2 if (@battle.FE == :COLOSSEUM || @battle.ProgressiveFieldCheck(PBFields::CONCERT))
          attacker.pbPartner.pbIncreaseStat(PBStats::ATTACK,statboost,abilitymessage:false)
        end
      end
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,abilitymessage:false)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :SOLARFLARE
      @battle.pbAnimation(:FIERYDANCE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Increases the user's Defense by 1 stage. (Harden, Steel Wing, Withdraw)
################################################################################
class PokeBattle_Move_01D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,abilitymessage:false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
    end
    if @battle.FE == :PSYTERRAIN && @move==:PSYSHIELDBASH
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,abilitymessage:false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
      end
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :PSYSHIELDBASH
      @battle.pbAnimation(:ZENHEADBUTT,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Increases the user's Defense by 1 stage.  User curls up. (Defense Curl, Psyshield Bash)
################################################################################
class PokeBattle_Move_01E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,true)
     pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
     ret=attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
     attacker.effects[:DefenseCurl]=true if ret
    end 
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,abilitymessage:false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
    end
    return true
  end
end

################################################################################
# Increases the user's Speed by 1 stage. (Flame Charge / Esper Wing)
################################################################################
class PokeBattle_Move_01F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPEED,1,abilitymessage:false)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    increment = 1
    increment = 2 if @move==:ESPERWING && @battle.FE == :PSYTERRAIN
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,abilitymessage:false)
      attacker.pbIncreaseStat(PBStats::SPEED,1,abilitymessage:false)
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :ESPERWING
      @battle.pbAnimation(:PSYCHOCUT,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Increases the user's Special Attack by 1 stage. (Charge Beam, Fiery Dance, Mystical Power)
################################################################################
class PokeBattle_Move_020 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPATK,1,abilitymessage:false)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    increment = 1
    increment = 2 if @battle.FE == :PSYTERRAIN && @move == :MYSTICALPOWER
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,abilitymessage:false)
      attacker.pbIncreaseStat(PBStats::SPATK,increment,abilitymessage:false)
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :HOARFROSTMOON
      @battle.pbAnimation(:GLACIATE,attacker,opponent,hitnum)
    elsif id == :MYSTICALPOWER
      @battle.pbAnimation(:PSYCHIC,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Increases the user's Special Defense by 1 stage.  Charges up Electric attacks. (Charge)
################################################################################
class PokeBattle_Move_021 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if @battle.FE == :ELECTERRAIN # Electric Field
    ret=attacker.pbIncreaseStat(PBStats::SPDEF,2,abilitymessage:false)
    else
    ret=attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
    end
    if ret
      attacker.effects[:Charge]=2
      @battle.pbDisplay(_INTL("{1} began charging power!",attacker.pbThis))
    end
    return ret ? 0 : -1
  end
end

################################################################################
# Increases the user's evasion by 1 stage. (Double Team)
################################################################################
class PokeBattle_Move_022 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::EVASION,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.FE == :MIRROR
      ret=attacker.pbIncreaseStat(PBStats::EVASION,2,abilitymessage:false)
    else
      ret=attacker.pbIncreaseStat(PBStats::EVASION,1,abilitymessage:false)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,abilitymessage:false)
      attacker.pbIncreaseStat(PBStats::EVASION,1,abilitymessage:false)
    end
    return true
  end
end

################################################################################
# Increases the user's critical hit rate. (Focus Energy)
################################################################################
class PokeBattle_Move_023 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if attacker.effects[:FocusEnergy]>=2
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[:FocusEnergy]=2
    attacker.effects[:FocusEnergy]=3 if @battle.FE == :ASHENBEACH
    @battle.pbDisplay(_INTL("{1} is getting pumped!",attacker.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if @move == :CHISTRIKE
      if attacker.effects[:FocusEnergy]<1
        attacker.effects[:FocusEnergy]+=1
        pbShowAnimation(@move,attacker,opponent)
        @battle.pbDisplay(_INTL("{1} is getting pumped!",attacker.pbThis))
      end
      if attacker.pbPartner.effects[:FocusEnergy]<1
        attacker.pbPartner.effects[:FocusEnergy]+=1
        pbShowAnimation(@move,attacker,opponent)
        @battle.pbDisplay(_INTL("{1} is getting pumped!",attacker.pbPartner.pbThis))
      end
    elsif attacker.effects[:FocusEnergy]<2
      attacker.effects[:FocusEnergy]=2
      @battle.pbDisplay(_INTL("{1} is getting pumped!",attacker.pbThis))
    end
    return true
  end
end

################################################################################
# Increases the user's Attack and Defense by 1 stage each. (Bulk Up)
################################################################################
class PokeBattle_Move_024 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for stat in [PBStats::ATTACK,PBStats::DEFENSE]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        if @battle.FE == :CROWD
          attacker.pbIncreaseStat(stat,2,abilitymessage:false)
        else
          attacker.pbIncreaseStat(stat,1,abilitymessage:false)
        end
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Attack, Defense and accuracy by 1 stage each. (Coil)
################################################################################
class PokeBattle_Move_025 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    boost_amount=1
    if @battle.FE == :GRASSY || (Rejuv && @battle.FE == :DRAGONSDEN)
      boost_amount=2
    end
    for stat in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::ACCURACY]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,boost_amount,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Attack and Speed by 1 stage each. (Dragon Dance)
################################################################################
class PokeBattle_Move_026 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    boost_amount=1
    if (@battle.FE == :BIGTOP || @battle.FE == :DRAGONSDEN|| @battle.FE == :DANCEFLOOR) && (@move == :DRAGONDANCE)
      boost_amount=2
    end
    for stat in [PBStats::ATTACK,PBStats::SPEED]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,boost_amount,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Attack and Special Attack by 1 stage each. (Work Up)
################################################################################
class PokeBattle_Move_027 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    statinc = 1
    statinc = 2 if @battle.ProgressiveFieldCheck(PBFields::CONCERT) || @battle.FE == :CROWD || @battle.FE == :CITY 
    for stat in [PBStats::ATTACK,PBStats::SPATK]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,statinc,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Attack and Sp. Attack by 1 stage each (2 each in sunshine).
# (Growth)
################################################################################
class PokeBattle_Move_028 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)

    # Rain -- different effect
    if (@battle.weather== :RAINDANCE)
      if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false) &&
          !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
        return -1
      end
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      @battle.pbDisplay(_INTL("{1} strengthened in the rain!",attacker.pbThis))
      for stat in [PBStats::DEFENSE,PBStats::SPDEF]
        if attacker.pbCanIncreaseStatStage?(stat,false)
          attacker.pbIncreaseStat(stat,2,abilitymessage:false)
        end
      end
      return 0
    end

    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    increment=(@battle.weather== :SUNNYDAY) ? 2 : 1
    if (@battle.FE == :GRASSY || @battle.FE == :FOREST || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN)) # Grassy/Forest/Flower Garden Field
      increment = 2
      increment = 3 if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,5)
    end
    if (attacker.crested == :CHERRIM)
      increment = 2
    end
    for stat in [PBStats::ATTACK,PBStats::SPATK]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,increment,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Attack and accuracy by 1 stage each. (Hone Claws)
################################################################################
class PokeBattle_Move_029 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for stat in [PBStats::ATTACK,PBStats::ACCURACY]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,1,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Defense and Special Defense by 1 stage each. (Cosmic Power, Defend Order)
################################################################################
class PokeBattle_Move_02A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    protectFlag = false
    if (attacker.crested == :VESPIQUEN && @move == :DEFENDORDER) 
      if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
        attacker.effects[:ProtectRate]=0
      end
      priority = @battle.pbPriority
      if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
        attacker.effects[:ProtectRate]=0
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
      if @battle.pbRandom(65536)<(65536/(3**attacker.effects[:ProtectRate])).floor
        attacker.effects[:Protect]=:Protect
        attacker.effects[:ProtectRate]+=1
        @battle.pbAnimation(@move,attacker,nil)
        @battle.pbDisplay(_INTL("{1} protected itself!",attacker.pbThis))
        protectFlag = true
      else
        attacker.effects[:ProtectRate]=0
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
    end
    if (!protectFlag)
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    end
    boost_amount=1
    if ((@battle.FE == :MISTY || @battle.FE == :RAINBOW || @battle.FE == :HOLY ||
      @battle.FE == :STARLIGHT || @battle.FE == :NEWWORLD || @battle.FE == :PSYTERRAIN) &&
      (@move == :COSMICPOWER)) || (@battle.FE == :FOREST && (@move == :DEFENDORDER))
      boost_amount=2
    end
    for stat in [PBStats::DEFENSE,PBStats::SPDEF]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,boost_amount,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Special Attack, Special Defense and Speed  by 1 stage each. (Quiver Dance)
################################################################################
class PokeBattle_Move_02B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    showanim=true
    boost_amount=1
    if (@battle.FE == :BIGTOP || @battle.FE == :DANCEFLOOR)&& (@move == :QUIVERDANCE)
      boost_amount=2
    end
    for stat in [PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,boost_amount,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Special Attack and Special Defense by 1 stage each. (Calm Mind)
################################################################################
class PokeBattle_Move_02C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    boost_amount=1
    if @battle.FE == :CHESS || @battle.FE == :ASHENBEACH || @battle.FE == :PSYTERRAIN # Chess/Ashen/Psychic Field
      boost_amount=2
    end
    for stat in [PBStats::SPATK,PBStats::SPDEF]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,boost_amount,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Attack, Defense, Speed, Special Attack and Special Defense
# by 1 stage each. (Ancient Power, Silver Wind, Ominous Wind)
################################################################################
class PokeBattle_Move_02D < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    for stat in 1..5
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,1)
      end
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :SEABREEZE
      @battle.pbAnimation(:SILVERWIND,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Increases the user's Attack by 2 stages. (Swords Dance)
################################################################################
class PokeBattle_Move_02E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if (@battle.FE == :BIGTOP || @battle.FE == :FAIRYTALE || @battle.FE == :COLOSSEUM || @battle.FE == :DANCEFLOOR) && (@move == :SWORDSDANCE)
      ret=attacker.pbIncreaseStat(PBStats::ATTACK,3,abilitymessage:false)
    else
      ret=attacker.pbIncreaseStat(PBStats::ATTACK,2,abilitymessage:false)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::ATTACK,2,abilitymessage:false)
    end
    return true
  end
end

################################################################################
# Increases the user's Defense by 2 stages. (Iron Defense, Acid Armor, Barrier, Diamond Storm)
################################################################################
class PokeBattle_Move_02F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if (([:CORROSIVE,:CORROSIVEMIST,:MURKWATERSURFACE,:FAIRYTALE].include?(@battle.FE) || @battle.ProgressiveFieldCheck(PBFields::CONCERT)) && (@move == :ACIDARMOR)) || # Corro Fields
     (@battle.FE == :FACTORY && (@move == :IRONDEFENSE))
      ret=attacker.pbIncreaseStat(PBStats::DEFENSE,3,abilitymessage:false)
    else
      ret=attacker.pbIncreaseStat(PBStats::DEFENSE,2,abilitymessage:false)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,2,abilitymessage:false)
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    @battle.pbAnimation(id,attacker,opponent,hitnum)
  end
end

################################################################################
# Increases the user's Speed by 2 stages. (Agility, Rock Polish)
################################################################################
class PokeBattle_Move_030 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,true) && !(@battle.FE == :CRYSTALCAVERN && (attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,true) || attacker.pbCanIncreaseStatStage?(PBStats::SPATK,true)))
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if @battle.FE == :ROCKY && (@move == :ROCKPOLISH)  # Rocky Fields
      ret=attacker.pbIncreaseStat(PBStats::SPEED,3,abilitymessage:false)
    elsif @battle.FE == :CRYSTALCAVERN && (@move == :ROCKPOLISH)  # Crystal Cavern
      ret=attacker.pbIncreaseStat(PBStats::SPEED,2,abilitymessage:false)
      ret=attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
      ret=attacker.pbIncreaseStat(PBStats::SPATK,1,abilitymessage:false)
    else
      ret=attacker.pbIncreaseStat(PBStats::SPEED,2,abilitymessage:false)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      attacker.pbIncreaseStat(PBStats::SPEED,2,abilitymessage:false)
    end
    return true
  end
end

################################################################################
# Increases the user's Speed by 2 stages.  Halves the user's weight. (Autotomize)
################################################################################
class PokeBattle_Move_031 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if @battle.FE == :FACTORY || @battle.FE == :DEEPEARTH || @battle.FE == :CITY
     ret=attacker.pbIncreaseStat(PBStats::SPEED,3,abilitymessage:false)
    else
      ret=attacker.pbIncreaseStat(PBStats::SPEED,2,abilitymessage:false)
    end
    if ret
      attacker.effects[:WeightModifier]-=1000
      @battle.pbDisplay(_INTL("{1} became nimble!",attacker.pbThis))
    end
    return ret ? 0 : -1
  end
end

################################################################################
# Increases the user's Special Attack by 2 stages. (Nasty Plot)
################################################################################
class PokeBattle_Move_032 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if [:CHESS,:PSYTERRAIN,:INFERNAL,:BACKALLEY].include?(@battle.FE)
      ret=attacker.pbIncreaseStat(PBStats::SPATK,3,abilitymessage:false)
    else
      ret=attacker.pbIncreaseStat(PBStats::SPATK,2,abilitymessage:false)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      attacker.pbIncreaseStat(PBStats::SPATK,2,abilitymessage:false)
    end
    return true
  end
end

################################################################################
# Increases the user's Special Defense by 2 stages. (Amnesia)
################################################################################
class PokeBattle_Move_033 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPDEF,2,abilitymessage:false)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      attacker.pbIncreaseStat(PBStats::SPDEF,2,abilitymessage:false)
    end
    return true
  end
end

################################################################################
# Increases the user's evasion by 2 stages.  Minimizes the user. (Minimize)
################################################################################
class PokeBattle_Move_034 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::EVASION,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::EVASION,2,abilitymessage:false)
    attacker.effects[:Minimize]=true if ret
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
      attacker.pbIncreaseStat(PBStats::EVASION,2,abilitymessage:false)
      attacker.effects[:Minimize]=true
    end
    return true
  end
end

################################################################################
# Decreases the user's Defense and Special Defense by 1 stage each.
# Increases the user's Attack, Speed and Special Attack by 2 stages each. (Shell Smash)
################################################################################
class PokeBattle_Move_035 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    for stat in [PBStats::DEFENSE,PBStats::SPDEF]
      if attacker.pbCanReduceStatStage?(stat,false,true)
        attacker.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
      end
    end
    for stat in [PBStats::ATTACK,PBStats::SPATK,PBStats::SPEED]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,2,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Increases the user's Speed by 2 stages, and its Attack by 1 stage. (Shift Gear)
################################################################################
class PokeBattle_Move_036 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      if @battle.FE == :FACTORY || @battle.FE == :CITY
        attacker.pbIncreaseStat(PBStats::ATTACK,2,abilitymessage:false)
      else
        attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
      end
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      attacker.pbIncreaseStat(PBStats::SPEED,2,abilitymessage:false)
      showanim=false
    end
    if attacker.crested == :KLINKLANG
      if attacker.gear == 0
        @battle.pbDisplay(_INTL("ATTACK MODE INITIATING"))
        attacker.effects[:MagnetRise]=0
        @battle.pbDisplay(_INTL("{1} stopped levitating!",attacker.pbThis))
        @battle.pbAnimation(:MAGNETRISE,attacker,nil)
      else
        @battle.pbDisplay(_INTL("OVERCLOCKING SPEED",attacker.pbThis))
        attacker.effects[:MagnetRise]=-1
        @battle.pbAnimation(:MAGNETRISE,attacker,nil)
        @battle.pbDisplay(_INTL("{1} levitates with electromagnetism!",attacker.pbThis))
      end
      # switch gears
      attacker.gear = (attacker.gear + 1) % 2
    end
    return 0
  end
end

################################################################################
# Increases one random stat of the user by 2 stages (except HP). (Acupressure)
################################################################################
class PokeBattle_Move_037 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.index!=opponent.index && opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("{1}'s attack missed!",attacker.pbThis))
      return -1
    end
    array=[]
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      array.push(i) if opponent.pbCanIncreaseStatStage?(i)
    end
    if array.length==0
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",opponent.pbThis))
      return -1
    end
    stat=array[@battle.pbRandom(array.length)]
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbIncreaseStat(stat,2,abilitymessage:false)
    return 0
  end
end

################################################################################
# Increases the user's Defense by 3 stages. (Cotton Guard)
################################################################################
class PokeBattle_Move_038 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::DEFENSE,3,abilitymessage:false)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,3,abilitymessage:false)
    end
    return true
  end
end

################################################################################
# Increases the user's Special Attack by 3 stages. (Tail Glow)
################################################################################
class PokeBattle_Move_039 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPATK,3,abilitymessage:false)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::SPATK,3,abilitymessage:false)
    end
    return true
  end
end

################################################################################
# Reduces the user's HP by half of max, and sets its Attack to maximum. (Belly Drum)
################################################################################
class PokeBattle_Move_03A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    showanim=showanimation
    if attacker.hp<=(attacker.totalhp/2.0).floor || !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbReduceHP((attacker.totalhp/2.0).floor, false, false)
    attacker.stages[PBStats::ATTACK]=6
    @battle.pbCommonAnimation("StatUp",attacker,nil)
    @battle.pbDisplay(_INTL("{1} cut its own HP and maximized its Attack!",attacker.pbThis))
    if @battle.FE == :BIGTOP
       if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
        attacker.effects[:StockpileDef]+=1
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
        attacker.effects[:StockpileSpDef]+=1
      end
    end
    return 0
  end
end

################################################################################
# Decreases the user's Attack and Defense by 1 stage each. (Superpower)
################################################################################
class PokeBattle_Move_03B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      for stat in [PBStats::ATTACK,PBStats::DEFENSE]
        if attacker.pbCanReduceStatStage?(stat,false,true)
          attacker.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
        end
      end
    end
    return ret
  end
end

################################################################################
# Decreases the user's Defense and Special Defense by 1 stage each. 
# (Close Combat, Dragon Ascent, Headlong Rush)
################################################################################
class PokeBattle_Move_03C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      for stat in [PBStats::DEFENSE,PBStats::SPDEF]
        if attacker.pbCanReduceStatStage?(stat,false,true)
          attacker.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
        end
      end
    end
    return ret
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :HEADLONGRUSH
      @battle.pbAnimation(:DOUBLEEDGE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Decreases the user's Defense, Special Defense and Speed by 1 stage each. (V-Create)
################################################################################
class PokeBattle_Move_03D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      for stat in [PBStats::SPDEF,PBStats::DEFENSE,PBStats::SPEED]
        if attacker.pbCanReduceStatStage?(stat,false,true)
          attacker.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
        end
      end
    end
    return ret
  end
end

################################################################################
# Decreases the user's Speed by 1 stage. (Hammer Arm, Ice Hammer)
################################################################################
class PokeBattle_Move_03E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.pbCanReduceStatStage?(PBStats::SPEED,false,true)
        attacker.pbReduceStat(PBStats::SPEED,1,abilitymessage:false, statdropper: attacker)
      end
    end
    return ret
  end
end

################################################################################
# Decreases the user's Special Attack by 2 stages. (Overheat, Draco Meteor, Leaf Storm, Psycho Boost, Flear Cannon)
################################################################################
class PokeBattle_Move_03F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.pbCanReduceStatStage?(PBStats::SPATK,false,true)
        attacker.pbReduceStat(PBStats::SPATK,2,abilitymessage:false, statdropper: attacker)
      end
    end
    return ret
  end
end

################################################################################
# Increases the target's Special Attack by 1 stage.  Confuses the target. (Flatter)
################################################################################
class PokeBattle_Move_040 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("{1}'s attack missed!",attacker.pbThis))
      return -1
    end
    ret=-1
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    boost = 1
    boost = 2 if @battle.FE == :COLOSSEUM
    if opponent.pbCanIncreaseStatStage?(PBStats::SPATK)
      opponent.pbIncreaseStat(PBStats::SPATK,boost,abilitymessage:false)
      ret=0
    end
    if opponent.pbCanConfuse?(true)
      opponent.effects[:Confusion]=2+@battle.pbRandom(4)
      @battle.pbCommonAnimation("Confusion",opponent,nil)
      @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
      ret=0
    end
    return ret
  end
end

################################################################################
# Increases the target's Attack by 2 stages.  Confuses the target. (Swagger)
################################################################################
class PokeBattle_Move_041 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("{1}'s attack missed!",attacker.pbThis))
      return -1
    end
    ret=-1
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    boost = 2
    boost = 3 if @battle.FE == :COLOSSEUM
    if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK)
      opponent.pbIncreaseStat(PBStats::ATTACK,boost,abilitymessage:false)
      ret=0
    end
    if opponent.pbCanConfuse?(true)
      opponent.effects[:Confusion]=2+@battle.pbRandom(4)
      @battle.pbCommonAnimation("Confusion",opponent,nil)
      @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
      ret=0
    end
    return ret
  end
end

################################################################################
# Decreases the target's Attack by 1 stage. 
# (Growl, Aurora Beam, Baby-Doll Eyes, Play Nice, Play Rough, Lunge, Trop Kick, Breaking Swipe, Bitter Malice, Springtide Storm)
################################################################################
class PokeBattle_Move_042 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    statdrop = 1
    statdrop = 2 if @battle.ProgressiveFieldCheck(PBFields::CONCERT) && @move == :GROWL
    ret=opponent.pbReduceStat(PBStats::ATTACK,statdrop,abilitymessage:false, statdropper: attacker)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if (@move == :CUDDLESTORM)
      if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
        @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from infatuation!"))
      end
      if opponent.pbCanAttract?(attacker)
        opponent.effects[:Attract]=attacker.index
        @battle.pbCommonAnimation("Attract",opponent,nil)
        @battle.pbDisplay(_INTL("{1} fell in love!",opponent.pbThis))
        if opponent.hasWorkingItem(:DESTINYKNOT) && attacker.ability != :OBLIVIOUS && attacker.effects[:Attract]<0
          attacker.effects[:Attract]=opponent.index
          @battle.pbCommonAnimation("Attract",attacker,nil)
          @battle.pbDisplay(_INTL("{1}'s {2} infatuated {3}!",opponent.pbThis,
          getItemName(opponent.item),attacker.pbThis(true)))
        end
      end
      return true
    end
    if opponent.pbCanReduceStatStage?(PBStats::ATTACK,false)
      opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
    end
    if @battle.FE == :HAUNTED && @move==:BITTERMALICE
      if opponent.pbCanReduceStatStage?(PBStats::ATTACK,false)
        opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
      end
    end
    if @move==:BITTERMALICE && @battle.FE == :ICY && @battle.FE == :SNOWYMOUNTAIN
      if @battle.pbRandom(10)==0
        if opponent.pbCanFreeze?(false)
          opponent.pbFreeze
          @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
        end
      end
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :SPRINGTIDESTORM
      @battle.pbAnimation(:FLEURCANNON,attacker,opponent,hitnum)
    elsif id == :BITTERMALICE
      @battle.pbAnimation(:HEX,attacker,opponent,hitnum)
    elsif id == :CUDDLESTORM
      @battle.pbAnimation(:PLAYROUGH,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Decreases the target's Defense by 1 stage. (Tail Whip, Crunch, Rock Smash, Crush Claw, Leer, Iron Tail, Razor Shell, Fire Lash, Liquidation, Shadow Bone)
################################################################################
class PokeBattle_Move_043 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,false)
      opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
    end
    return true
  end
end

################################################################################
# Decreases the target's Speed by 1 stage. 
# (Rock Tomb, Electroweb, Low Sweep, Bulldoze, Mud Shot, Glaciate, Icy Wind,
# Constrict, Bubble Beam, Bubble, Bleakwind Storm)
################################################################################
class PokeBattle_Move_044 < PokeBattle_Move

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPEED,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPEED,1,abilitymessage:false, statdropper: attacker)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::SPEED,false)
      statchange = 1
      statchange = 2 if (Rejuv && ((@battle.FE == :ELECTERRAIN && @move == :ELECTROWEB) || (@battle.FE == :SWAMP && @move == :MUDSHOT)))
      statchange = 12 if @move == :GLACIATE
      opponent.pbReduceStat(PBStats::SPEED,statchange,abilitymessage:false, statdropper: attacker)
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :BLEAKWINDSTORM
      @battle.pbAnimation(:HURRICANE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Decreases the target's Special Attack by 1 stage. (Snarl / Confide / Moonblast /
# Mystical Fire / Struggle Bug / Mist Ball)
################################################################################
class PokeBattle_Move_045 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if (@move == :CONFIDE) && @battle.FE == :PSYTERRAIN
      @battle.pbDisplay(_INTL("Psst... This field is pretty weird, huh?"))
    end
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPATK,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPATK,1,abilitymessage:false, statdropper: attacker)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::SPATK,false)
      statchange = 1
      statchange = 2 if (Rejuv && @battle.FE == :SWAMP && @move == :STRUGGLEBUG) || ((@battle.FE == :FROZENDIMENSION || @battle.FE == :BACKALLEY)  && @move == :SNARL)
      opponent.pbReduceStat(PBStats::SPATK,statchange,abilitymessage:false, statdropper: attacker)
    end
    return true
  end
end

################################################################################
# Decreases the target's Special Defense by 1 stage. (Bug Buzz / Focus Blast /
# Shadow Ball / Energy Ball / Earth Power / Acid / Psychic / Luster Purge / Flash Cannon)
################################################################################
class PokeBattle_Move_046 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPDEF,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false, statdropper: attacker)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::SPDEF,false)
      opponent.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false, statdropper: attacker)
    end
    return true
  end
end

################################################################################
# Decreases the target's accuracy by 1 stage. (Sand Attack, Night Daze, Leaf Tornado, Mod Bomb, Mud-Slap, Flash, Smokescreen, Kinesis, Mirror Shot, Muddy Water, Octazooka)
################################################################################
class PokeBattle_Move_047 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::ACCURACY,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if ([:BURNING,:CORROSIVEMIST,:VOLCANIC,:VOLCANICTOP,:BACKALLEY,:CITY].include?(@battle.FE) && (@move == :SMOKESCREEN)) ||
       ((@battle.FE == :DESERT || @battle.FE == :ASHENBEACH) && (@move == :SANDATTACK)) ||
       ((@battle.FE == :SHORTCIRCUIT || @battle.FE == :DARKCRYSTALCAVERN || @battle.FE == :MIRROR || @battle.FE == :STARLIGHT || @battle.FE == :NEWWORLD || @battle.FE== :DARKNESS1) && (@move == :FLASH)) ||
       (@battle.FE == :ASHENBEACH && (@move == :KINESIS))
      ret=opponent.pbReduceStat(PBStats::ACCURACY,2,abilitymessage:false, statdropper: attacker)
    elsif @battle.FE == :PSYTERRAIN && (@move == :KINESIS)
      opponent.pbReduceStat(PBStats::ACCURACY,2,abilitymessage:false, statdropper: attacker)
      attacker.pbIncreaseStat(PBStats::ATTACK,2,abilitymessage:false) if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::SPATK,2,abilitymessage:false) if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      return 0
    elsif  @battle.FE == :DANCEFLOOR && (@move == :KINESIS)
      opponent.pbReduceStat(PBStats::ACCURACY,2,abilitymessage:false, statdropper: attacker)
      opponent.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false, statdropper: attacker)
    else
      ret=opponent.pbReduceStat(PBStats::ACCURACY,1,abilitymessage:false, statdropper: attacker)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if @battle.FE == :WASTELAND && (@move == :OCTAZOOKA) && 
      ((!opponent.hasType?(:POISON) && !opponent.hasType?(:STEEL)) || opponent.corroded) &&
      opponent.ability != :TOXICBOOST && opponent.ability != :POISONHEAL && opponent.crested != :ZANGOOSE && (opponent.crested != :GOODRA)
      (opponent.ability != :IMMUNITY && !(opponent.moldbroken))
      rnd=@battle.pbRandom(5)
      case rnd
        when 0
          return false if !opponent.pbCanBurn?(false)
          opponent.pbBurn(attacker)
          @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
        when 1
          return false if !opponent.pbCanFreeze?(false)
          opponent.pbFreeze
          @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
        when 2
          return false if !opponent.pbCanParalyze?(false)
          opponent.pbParalyze(attacker)
          @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
        when 3
          return false if !opponent.pbCanPoison?(false)
          opponent.pbPoison(attacker)
          @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
        when 4
          if opponent.pbCanReduceStatStage?(PBStats::ACCURACY,false)
            opponent.pbReduceStat(PBStats::ACCURACY,1,abilitymessage:false, statdropper: attacker)
          end
      end
    else
      if opponent.pbCanReduceStatStage?(PBStats::ACCURACY,false)
        opponent.pbReduceStat(PBStats::ACCURACY,1,abilitymessage:false, statdropper: attacker)
      end
    end
    return true
  end
end

################################################################################
# Decreases the target's evasion by 1 stage. (Sweet Scent)
################################################################################
class PokeBattle_Move_048 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::EVASION,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,5)
      case @battle.FE
        when :FLOWERGARDEN3
          for stat in [PBStats::EVASION,PBStats::DEFENSE,PBStats::SPDEF]
            ret = opponent.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
          end
        when :FLOWERGARDEN4
          for stat in [PBStats::EVASION,PBStats::DEFENSE,PBStats::SPDEF]
            ret = opponent.pbReduceStat(stat,2,abilitymessage:false, statdropper: attacker)
          end
        when :FLOWERGARDEN5
          for stat in [PBStats::EVASION,PBStats::DEFENSE,PBStats::SPDEF]
            ret = opponent.pbReduceStat(stat,3,abilitymessage:false, statdropper: attacker)
          end
      end
    elsif @battle.FE == :MISTY
      for stat in [PBStats::EVASION,PBStats::DEFENSE,PBStats::SPDEF]
        ret = opponent.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
      end
    else
      ret=opponent.pbReduceStat(PBStats::EVASION,1,abilitymessage:false, statdropper: attacker)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::EVASION,false)
      opponent.pbReduceStat(PBStats::EVASION,1,abilitymessage:false, statdropper: attacker)
    end
    return true
  end
end

################################################################################
# Decreases the target's evasion by 1 stage. Ends all barriers and entry
# hazards for the target's side. (Defog)
################################################################################
class PokeBattle_Move_049 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::EVASION,1,abilitymessage:false, statdropper: attacker)
    if attacker.pbOpposingSide.effects[:Reflect]>0
      attacker.pbOpposingSide.effects[:Reflect]=0
      if !@battle.pbIsOpposing?(attacker.index)
        stateChanges
      else
          @battle.pbDisplay(_INTL("Your team's Reflect wore off!"))
      end
    end
    if attacker.pbOpposingSide.effects[:LightScreen]>0
      attacker.pbOpposingSide.effects[:LightScreen]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team's Light Screen wore off!"))
      else
        @battle.pbDisplay(_INTL("Your team's Light Screen wore off!"))
      end
    end
    if attacker.pbOpposingSide.effects[:PriorityGuard]>0
      attacker.pbOpposingSide.effects[:PriorityGuard]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team is no longer protected from priority attacks!"))
      else
        @battle.pbDisplay(_INTL("Your team is no longer protected from priority attacks!"))
      end
    end
    if attacker.pbOpposingSide.effects[:AuroraVeil]>0
      attacker.pbOpposingSide.effects[:AuroraVeil]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team's Aurora Veil wore off!"))
      else
        @battle.pbDisplay(_INTL("Your team's Aurora Veil wore off!"))
      end
    end
    if attacker.pbOpposingSide.effects[:AreniteWall]>0
      attacker.pbOpposingSide.effects[:AreniteWall]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team's Arenite Wall wore off!"))
      else
        @battle.pbDisplay(_INTL("Your team's Arenite Wall wore off!"))
      end
    end
    if attacker.pbOpposingSide.effects[:Mist]>0 || opponent.pbOwnSide.effects[:Mist]>0
      opponent.pbOwnSide.effects[:Mist]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team is no longer protected by Mist."))
      else
        @battle.pbDisplay(_INTL("Your team is no longer protected by Mist."))
      end
    end
    if attacker.pbOpposingSide.effects[:Safeguard]>0 || opponent.pbOwnSide.effects[:Safeguard]>0
      opponent.pbOwnSide.effects[:Safeguard]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team is no longer protected by Safeguard."))
      else
        @battle.pbDisplay(_INTL("Your team is no longer protected by Safeguard."))
      end
    end
    if (@battle.state.effects[:LockHazards])
      @battle.pbDisplay(_INTL("Entry hazards are locked!"))
    else
      if attacker.pbOwnSide.effects[:Spikes]>0 || opponent.pbOwnSide.effects[:Spikes]>0
        attacker.pbOwnSide.effects[:Spikes]=0
        opponent.pbOwnSide.effects[:Spikes]=0
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("The spikes disappeared from around your opponent's team's feet!"))
        else
          @battle.pbDisplay(_INTL("The spikes disappeared from around your team's feet!"))
        end
      end
      if attacker.pbOwnSide.effects[:StealthRock] || opponent.pbOwnSide.effects[:StealthRock]
        attacker.pbOwnSide.effects[:StealthRock]=false
        opponent.pbOwnSide.effects[:StealthRock]=false
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("The pointed stones disappeared from around your opponent's team!"))
        else
          @battle.pbDisplay(_INTL("The pointed stones disappeared from around your team!"))
        end
      end
      if attacker.pbOwnSide.effects[:InvStealthRock] || opponent.pbOwnSide.effects[:InvStealthRock]
        attacker.pbOwnSide.effects[:InvStealthRock]=false
        opponent.pbOwnSide.effects[:InvStealthRock]=false
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("The mysterious stones disappeared from around your opponent's team!"))
        else
          @battle.pbDisplay(_INTL("The mysterious stones disappeared from around your team!"))
        end
      end
      if attacker.pbOwnSide.effects[:Steelsurge] || opponent.pbOwnSide.effects[:Steelsurge]
        attacker.pbOwnSide.effects[:Steelsurge]=false
        opponent.pbOwnSide.effects[:Steelsurge]=false
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("The metal debris disappeared from around your opponent's team!"))
        else
          @battle.pbDisplay(_INTL("The metal debris disappeared from around your team!"))
        end
      end
      if attacker.pbOwnSide.effects[:Volcalith] || opponent.pbOwnSide.effects[:Volcalith]
        attacker.pbOwnSide.effects[:Volcalith]=false
        opponent.pbOwnSide.effects[:Volcalith]=false
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("The molten rocks disappeared from around your opponent's team!"))
        else
          @battle.pbDisplay(_INTL("The molten rocks disappeared from around your team!"))
        end
      end
      if attacker.pbOwnSide.effects[:ToxicSpikes]>0 || opponent.pbOwnSide.effects[:ToxicSpikes]>0
        attacker.pbOwnSide.effects[:ToxicSpikes]=0
        opponent.pbOwnSide.effects[:ToxicSpikes]=0
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("The poison spikes disappeared from around your opponent's team's feet!"))
        else
          @battle.pbDisplay(_INTL("The poison spikes disappeared from around your team's feet!"))
        end
      end
      if attacker.pbOwnSide.effects[:StickyWeb] || opponent.pbOwnSide.effects[:StickyWeb]
        attacker.pbOwnSide.effects[:StickyWeb]=false
        opponent.pbOwnSide.effects[:StickyWeb]=false
        if !@battle.pbIsOpposing?(attacker.index)
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

   ####
    return 0
  end

  # @SWu idk what this is for -- magic bounce?
  # might need to re-work if we want to re-use this as a side effect
  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::EVASION,false)
      if @battle.FE == :CLOUDS
        opponent.pbReduceStat(PBStats::EVASION,2,abilitymessage:false, statdropper: attacker)
      else
        opponent.pbReduceStat(PBStats::EVASION,1,abilitymessage:false, statdropper: attacker)
      end
    end
    opponent.pbOwnSide.effects[:Reflect] = 0
    opponent.pbOwnSide.effects[:LightScreen] = 0
    opponent.pbOwnSide.effects[:PriorityGuard] = 0
    opponent.pbOwnSide.effects[:AuroraVeil] = 0
    opponent.pbOwnSide.effects[:AreniteWall] = 0
    opponent.pbOwnSide.effects[:Mist] = 0
    opponent.pbOwnSide.effects[:Safeguard] = 0
    opponent.pbOwnSide.effects[:Spikes] = 0
    opponent.pbOwnSide.effects[:StealthRock] = false
    opponent.pbOwnSide.effects[:InvStealthRock] = false
    opponent.pbOwnSide.effects[:Steelsurge] = false
    opponent.pbOwnSide.effects[:Volcalith] = false
    opponent.pbOwnSide.effects[:ToxicSpikes] = 0
    opponent.pbOwnSide.effects[:StickyWeb] = false
    return true
  end
end

################################################################################
# Decreases the target's Attack and Defense by 1 stage each. (Tickle)
################################################################################
class PokeBattle_Move_04A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("{1}'s attack missed!",attacker.pbThis))
      return -1
    end
    if opponent.pbTooLow?(PBStats::ATTACK) &&
       opponent.pbTooLow?(PBStats::DEFENSE)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any lower!",opponent.pbThis))
      return -1
    end
    if opponent.pbOwnSide.effects[:Mist]>0
      @battle.pbDisplay(_INTL("{1} is protected by Mist!",opponent.pbThis))
      return -1
    end
    if ((opponent.ability == :CLEARBODY ||
       opponent.ability == :WHITESMOKE) && !(opponent.moldbroken)) || opponent.ability == :FULLMETALBODY
      @battle.pbDisplay(_INTL("{1}'s {2} prevents stat loss!",opponent.pbThis,
         getAbilityName(opponent.ability)))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=-1; showanim=true
    if opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
      ret=0; showanim=false
    end
    if opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
      ret=0; showanim=false
    end
    return ret
  end
end

################################################################################
# Decreases the target's Attack by 2 stages. (Charm / Feather Dance)
################################################################################
class PokeBattle_Move_04B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.FE == :BIGTOP && (@move == :FEATHERDANCE)
      ret=opponent.pbReduceStat(PBStats::ATTACK,3,abilitymessage:false, statdropper: attacker)
    else
      ret=opponent.pbReduceStat(PBStats::ATTACK,2,abilitymessage:false, statdropper: attacker)
    end
    if @battle.FE == :DANCEFLOOR  && (@move == :FEATHERDANCE)
      ret=opponent.pbReduceStat(PBStats::SPATK,2,abilitymessage:false, statdropper: attacker)
    end 
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::ATTACK,false)
      opponent.pbReduceStat(PBStats::ATTACK,2,abilitymessage:false, statdropper: attacker)
    end
    return true
  end
end

################################################################################
# Decreases the target's Defense by 2 stages. (Screech)
################################################################################
class PokeBattle_Move_04C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    statdrop = 2
    statdrop = 3 if @battle.ProgressiveFieldCheck(PBFields::CONCERT)
    ret=opponent.pbReduceStat(PBStats::DEFENSE,statdrop,abilitymessage:false, statdropper: attacker)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,false)
      opponent.pbReduceStat(PBStats::DEFENSE,2,abilitymessage:false, statdropper: attacker)
    end
    return true
  end
end

################################################################################
# Decreases the target's Speed by 2 stages. (String Shot / Cotton Spore / Scary Face)
################################################################################
class PokeBattle_Move_04D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPEED,true)
    if (@move == :COTTONSPORE)
      if opponent.hasType?(:GRASS)
        @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
        return -1
      elsif (opponent.ability == :OVERCOAT) && !(opponent.moldbroken)
        @battle.pbDisplay(_INTL("{1}'s {2} made the attack ineffective!",
        opponent.pbThis,getAbilityName(opponent.ability),self.name))
        return -1
      elsif (opponent.item == :SAFETYGOGGLES)
        @battle.pbDisplay(_INTL("{1} avoided the move with its {2}!",
        opponent.pbThis,getItemName(opponent.item),self.name))
        return -1
      end
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    decrement = 2
    decrement = 4 if (@battle.FE == :HAUNTED && @move == :SCARYFACE) || (Rejuv && @battle.FE == :GRASSY && @move == :COTTONSPORE)
    ret=opponent.pbReduceStat(PBStats::SPEED,decrement,abilitymessage:false, statdropper: attacker)
    if Rejuv && @battle.FE == :SWAMP  && @move == :STRINGSHOT
      stat = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED].sample
      if opponent.pbCanReduceStatStage?(stat,true)
        opponent.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
      end
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::SPEED,false)
      opponent.pbReduceStat(PBStats::SPEED,2,abilitymessage:false, statdropper: attacker)
    end
    return true
  end
end

################################################################################
# Decreases the target's Special Attack by 2 stages.  Only works on the opposite
# gender. (Captivate)
################################################################################
class PokeBattle_Move_04E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPATK,true)
    if opponent.ability == :OBLIVIOUS && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("{1}'s {2} prevents romance!",opponent.pbThis,
         getAbilityName(opponent.ability)))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPATK,2,abilitymessage:false, statdropper: attacker)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if attacker.gender==2 || opponent.gender==2 ||
                    attacker.gender==opponent.gender
    return false if opponent.ability == :OBLIVIOUS && !(opponent.moldbroken)
    if opponent.pbCanReduceStatStage?(PBStats::SPATK,false)
      opponent.pbReduceStat(PBStats::SPATK,2,abilitymessage:false, statdropper: attacker)
    end
    return true
  end
end

################################################################################
# Decreases the target's Special Defense by 2 stages. (Fake Tears / Seed Flare 
# Acid Spray / Metal Sound)
################################################################################
class PokeBattle_Move_04F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPDEF,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if ((@move == :METALSOUND) && (@battle.FE == :FACTORY || @battle.FE == :SHORTCIRCUIT || @battle.ProgressiveFieldCheck(PBFields::CONCERT))) ||
      ((@move == :FAKETEARS) && (@battle.FE == :BACKALLEY))
      ret=opponent.pbReduceStat(PBStats::SPDEF,3,abilitymessage:false, statdropper: attacker)
    else
      ret=opponent.pbReduceStat(PBStats::SPDEF,2,abilitymessage:false, statdropper: attacker)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::SPDEF,false)
      opponent.pbReduceStat(PBStats::SPDEF,2,abilitymessage:false, statdropper: attacker)
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :UPROOT
      @battle.pbAnimation(:FRENZYPLANT,attacker,opponent,hitnum)
    elsif id == :ACIDROCK || id == :ACIDROCK2
      @battle.pbAnimation(:BOOMBURST,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Resets all target's stat stages to 0. (Clear Smog)
################################################################################
class PokeBattle_Move_050 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute
      opponent.stages[PBStats::ATTACK]   = 0
      opponent.stages[PBStats::DEFENSE]  = 0
      opponent.stages[PBStats::SPEED]    = 0
      opponent.stages[PBStats::SPATK]    = 0
      opponent.stages[PBStats::SPDEF]    = 0
      opponent.stages[PBStats::ACCURACY] = 0
      opponent.stages[PBStats::EVASION]  = 0
      @battle.pbDisplay(_INTL("{1}'s stat changes were removed!",opponent.pbThis))
    end
    return ret
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if @move == :HEAVENLYWING
      @battle.pbAnimation(:WINGATTACK,attacker,opponent,hitnum)
    elsif @move == :DEPLETION
      @battle.pbAnimation(:DRAGONENERGY,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Resets all stat stages for all battlers to 0. (Haze)
################################################################################
class PokeBattle_Move_051 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    for i in 0...4
      @battle.battlers[i].stages[PBStats::ATTACK]   = 0
      @battle.battlers[i].stages[PBStats::DEFENSE]  = 0
      @battle.battlers[i].stages[PBStats::SPEED]    = 0
      @battle.battlers[i].stages[PBStats::SPATK]    = 0
      @battle.battlers[i].stages[PBStats::SPDEF]    = 0
      @battle.battlers[i].stages[PBStats::ACCURACY] = 0
      @battle.battlers[i].stages[PBStats::EVASION]  = 0
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("All stat changes were eliminated!"))
    return 0
  end
end

################################################################################
# User and target swap their Attack and Special Attack stat stages. (Power Swap)
################################################################################
class PokeBattle_Move_052 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    astage=attacker.stages
    ostage=opponent.stages
    astage[PBStats::ATTACK],ostage[PBStats::ATTACK]=ostage[PBStats::ATTACK],astage[PBStats::ATTACK]
    astage[PBStats::SPATK],ostage[PBStats::SPATK]=ostage[PBStats::SPATK],astage[PBStats::SPATK]
    @battle.pbDisplay(_INTL("{1} switched all changes to its Attack and Sp. Atk with the target!",attacker.pbThis))
    return 0
  end
end

################################################################################
# User and target swap their Defense and Special Defense stat stages. (Guard Swap)
################################################################################
class PokeBattle_Move_053 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    astage=attacker.stages
    ostage=opponent.stages
    astage[PBStats::DEFENSE],ostage[PBStats::DEFENSE]=ostage[PBStats::DEFENSE],astage[PBStats::DEFENSE]
    astage[PBStats::SPDEF],ostage[PBStats::SPDEF]=ostage[PBStats::SPDEF],astage[PBStats::SPDEF]
    @battle.pbDisplay(_INTL("{1} switched all changes to its Defense and Sp. Def with the target!",attacker.pbThis))
    return 0
  end
end

################################################################################
# User and target swap all their stat stages. (Heart Swap)
################################################################################
class PokeBattle_Move_054 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      attacker.stages[i],opponent.stages[i]=opponent.stages[i],attacker.stages[i]
    end
    @battle.pbDisplay(_INTL("{1} switched stat changes with the target!",attacker.pbThis))

    if @battle.FE == :NEWWORLD
      if opponent.effects[:Substitute]>0
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      olda=attacker.hp
      oldo=opponent.hp
      avhp=((attacker.hp+opponent.hp)/2.0).floor
      attacker.hp=[avhp,attacker.totalhp].min
      opponent.hp=[avhp,opponent.totalhp].min
      @battle.scene.pbHPChanged(attacker,olda)
      @battle.scene.pbHPChanged(opponent,oldo)
      @battle.pbDisplay(_INTL("The battlers shared their pain!"))
    end
    return 0
  end
end

################################################################################
# User copies the target's stat stages. (Psych Up)
################################################################################
class PokeBattle_Move_055 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      attacker.stages[i]=opponent.stages[i]
    end
    @battle.pbDisplay(_INTL("{1} copied {2}'s stat changes!",attacker.pbThis,opponent.pbThis(true)))
    if @battle.FE == :ASHENBEACH
      t=attacker.status
      attacker.status=nil
      attacker.statusCount=0
      if t== :BURN
        @battle.pbDisplay(_INTL("{1} was cured of its burn.",attacker.pbThis))
      elsif t== :POISON
        @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",attacker.pbThis))
      elsif t== :PARALYSIS
        @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",attacker.pbThis))
      end
    end
    if @battle.FE == :PSYTERRAIN
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,2,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# For 5 rounds, user's and ally's stat stages cannot be lowered by foes. (Mist)
################################################################################
class PokeBattle_Move_056 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[:Mist]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[:Mist]=5
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("Your team became shrouded in mist!"))
    else
      @battle.pbDisplay(_INTL("The foe's team became shrouded in mist!"))
    end

    if !(attacker.hasWorkingItem(:EVERSTONE)) && ((!Rejuv && @battle.canChangeFE?(:MISTY)) || @battle.canChangeFE?([:MISTY,:CORROSIVEMIST])) && !(@battle.state.effects[:MISTY] > 0)
      duration=3
      duration=6 if (attacker.hasWorkingItem(:AMPLIFIELDROCK))
      @battle.setField(:MISTY,duration)
      @battle.pbDisplay(_INTL("The terrain became misty!"))
    end
    return 0
  end
end

################################################################################
# Swaps the user's Attack and Defense. (Power Trick, Power Shift)
################################################################################
class PokeBattle_Move_057 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.attack, attacker.defense = attacker.defense, attacker.attack
    attacker.effects[:PowerTrick]=!attacker.effects[:PowerTrick]
    @battle.pbDisplay(_INTL("{1} switched its Attack and Defense!",attacker.pbThis))
    return 0
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :POWERSHIFT
      @battle.pbAnimation(:POWERTRICK,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Averages the user's and target's Attack and Special Attack (separately). (Power Split)
################################################################################
class PokeBattle_Move_058 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    avatk=((attacker.attack+opponent.attack)/2.0).floor
    avspatk=((attacker.spatk+opponent.spatk)/2.0).floor
    attacker.attack=avatk
    opponent.attack=avatk
    attacker.spatk=avspatk
    opponent.spatk=avspatk
    @battle.pbDisplay(_INTL("{1} shared its power with the target!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Averages the user's and target's Defense and Special Defense (separately). (Guard Split)
################################################################################
class PokeBattle_Move_059 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    avdef=((attacker.defense+opponent.defense)/2.0).floor
    avspdef=((attacker.spdef+opponent.spdef)/2.0).floor
    attacker.defense=avdef
    opponent.defense=avdef
    attacker.spdef=avspdef
    opponent.spdef=avspdef
    @battle.pbDisplay(_INTL("{1} shared its guard with the target!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Averages the user's and target's current HP. (Pain Split)
################################################################################
class PokeBattle_Move_05A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    olda=attacker.hp
    oldo=opponent.hp
    avhp=((attacker.hp+opponent.hp)/2.0).floor
    attacker.hp=[avhp,attacker.totalhp].min
    opponent.hp=[avhp,opponent.totalhp].min
    @battle.scene.pbHPChanged(attacker,olda)
    @battle.scene.pbHPChanged(opponent,oldo)
    @battle.pbDisplay(_INTL("The battlers shared their pain!"))
    return 0
  end
end

################################################################################
# For 4 more rounds, doubles the Speed of all battlers on the user's side. (Tailwind)
################################################################################
class PokeBattle_Move_05B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if attacker.pbOwnSide.effects[:Tailwind]!=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[:Tailwind]=4
    attacker.pbOwnSide.effects[:Tailwind]=6 if (@battle.FE == :MOUNTAIN || @battle.FE == :SNOWYMOUNTAIN || @battle.FE == :VOLCANICTOP || @battle.FE == :CLOUDS)
    attacker.pbOwnSide.effects[:Tailwind]=8 if @battle.FE == :SKY
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("The tailwind blew from behind your team!"))
    else
      @battle.pbDisplay(_INTL("The tailwind blew from behind the opposing team!"))
    end
    if (@battle.FE == :MOUNTAIN || @battle.FE == :SNOWYMOUNTAIN || @battle.FE == :VOLCANICTOP || @battle.FE == :SKY) && !@battle.state.effects[:HeavyRain] && !@battle.state.effects[:HarshSunlight] && !@battle.state.effects[:DesertNova] && !@battle.state.effects[:AbsoluteZero]
      @battle.weather=:STRONGWINDS
      @battle.weatherduration=6
      @battle.weatherduration=8 if @battle.FE == :SKY
      @battle.pbCommonAnimation("Wind",nil,nil)
      @battle.pbDisplay(_INTL("Strong winds kicked up around the field!"))
    end
    @battle.protosynthesisCheck
    return 0
  end
end

################################################################################
# This move turns into the last move used by the target, until user switches out. (Mimic)
################################################################################
class PokeBattle_Move_05C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist=[
       0x02,   # Struggle
       0x14,   # Chatter
       0x69,   # Transform
       0x5C,   # Mimic
       0x5D,   # Sketch
       0xB6    # Metronome
    ]
    if attacker.effects[:Transform] || !opponent.lastMoveUsed.is_a?(Symbol) ||
       blacklist.include?($cache.moves[opponent.lastMoveUsed].function)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    for i in attacker.moves
      if $cache.moves[i.move].move==opponent.lastMoveUsed
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...attacker.moves.length
      if attacker.moves[i].move==@move
        newmove=PBMove.new(opponent.lastMoveUsed)
        attacker.moves[i]=PokeBattle_Move.pbFromPBMove(@battle,newmove,attacker)
        if !(attacker.zmoves.nil? || attacker.item == :INTERCEPTZ)
          @battle.updateZMoveIndexBattler(i,attacker)
        end
        movename=getMoveName(opponent.lastMoveUsed)
        @battle.pbDisplay(_INTL("{1} learned {2}!",attacker.pbThis,movename))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("But it failed!"))
    return -1
  end
end

################################################################################
# This move permanently turns into the last move used by the target. (Sketch)
################################################################################
class PokeBattle_Move_05D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist=[
       0x02,   # Struggle
       0x5D    # Sketch
    ]
    if attacker.effects[:Transform] ||
       !opponent.lastMoveUsedSketch.is_a?(Symbol) ||
       blacklist.include?($cache.moves[opponent.lastMoveUsedSketch].function)
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
    end
    newmove=PBMove.new(opponent.lastMoveUsedSketch) #has to come after confirming there was a last sketched move
    if $cache.moves[newmove.move].move== :CHATTER # Chatter #must be separate due to switching from function code
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    for i in attacker.moves
      if $cache.moves[i.move].move==opponent.lastMoveUsedSketch
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...attacker.moves.length
      if $cache.moves[attacker.moves[i].move].move==@move
        #newmove=PBMove.new(opponent.lastMoveUsedSketch)
        attacker.moves[i]=PokeBattle_Move.pbFromPBMove(@battle,newmove,attacker)
        party=@battle.pbParty(attacker.index)
        party[attacker.pokemonIndex].moves[i]=newmove
        if !(attacker.zmoves.nil? || attacker.item == :INTERCEPTZ)
          party[attacker.pokemonIndex].updateZMoveIndex(i)
          @battle.updateZMoveIndexBattler(i,attacker)
        end
        movename=getMoveName(opponent.lastMoveUsedSketch)
        @battle.pbDisplay(_INTL("{1} sketched {2}!",attacker.pbThis,movename))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("But it failed!"))
    return -1
  end
end

################################################################################
# Changes user's type to that of a random move of the user, ignoring this one. (Conversion)
################################################################################
class PokeBattle_Move_05E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.ability == :MULTITYPE || attacker.ability == :RKSSYSTEM || attacker.crested == :SILVALLY 
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if (@move == :ZCONVERSION)
      for stat in 1..5
        if attacker.pbCanIncreaseStatStage?(stat,false)
          attacker.pbIncreaseStat(stat,1)
        end
      end
    end
    types=[]
    for i in attacker.moves
      next if $cache.moves[i.move].move==@move
      next if i.type == :QMARKS || i.type == :SHADOW
      found=false
      types.push(i.type) if !types.include?(i.type)
    end
    newtype=types[0]
    if attacker.hasType?(newtype) && @move != :ZCONVERSION
      #@battle.pbDisplay(_INTL("But it failed!"))
      @battle.pbDisplay(_INTL("But {1} is already {2} type!",attacker.pbThis(true),newtype.capitalize))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.type1=newtype
    attacker.type2=nil
    typename=newtype.capitalize
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",attacker.pbThis,typename))
    if !(attacker.hasWorkingItem(:EVERSTONE)) && @battle.canChangeFE?(:GLITCH)
      if @battle.field.conversion == 2  # Conversion 2
        duration=5
        duration=8 if (attacker.hasWorkingItem(:AMPLIFIELDROCK))
        @battle.setField(:GLITCH,duration)
        @battle.pbDisplay(_INTL("TH~ R0GUE DAa/ta cor$upt?@####"))
      else
        # Conversion lingering
        @battle.field.conversion = 1 # Conversion
        @battle.pbDisplay(_INTL("Some rogue data remains..."))
      end
    end
    return 0
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :ZCONVERSION
      @battle.pbAnimation(:CONVERSION,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Changes user's type to a random one that resists the last attack used by target. (Conversion2)
################################################################################
class PokeBattle_Move_05F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
   if attacker.ability == :MULTITYPE || attacker.ability == :RKSSYSTEM || attacker.crested == :SILVALLY
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if !opponent.lastMoveUsed.is_a?(Symbol)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    atype=nil
    for i in opponent.moves
      if $cache.moves[i.move].move==opponent.lastMoveUsed
        atype=i.pbType(attacker)
        break
      end
    end
    if !atype
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    types = PBTypes.typeResists(atype)
    types.delete_if {|type| type == attacker.type1 && attacker.type2.nil?}
    if types.length==0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    newtype=types[@battle.pbRandom(types.length)]
    attacker.type1=newtype
    attacker.type2=nil
    typename=newtype.capitalize
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",attacker.pbThis,typename))
    if !(attacker.hasWorkingItem(:EVERSTONE)) && @battle.canChangeFE?(:GLITCH)
      if @battle.field.conversion == 1  # Conversion
        duration=5
        duration=8 if (attacker.hasWorkingItem(:AMPLIFIELDROCK))
        @battle.setField(:GLITCH,duration)
        @battle.pbDisplay(_INTL("TH~ R0GUE DAa/ta cor$upt?@####"))
      else
        # Conversion lingering
        @battle.field.conversion = 2 # Conversion 2
        @battle.pbDisplay(_INTL("Some rogue data remains..."))
      end
    end
    return 0
  end
end

################################################################################
# Changes user's type depending on the environment. (Camouflage)
################################################################################
class PokeBattle_Move_060 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
   if attacker.ability == :MULTITYPE ||
     attacker.ability == :RKSSYSTEM || attacker.crested == :SILVALLY
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    type = 0
    case @battle.FE
      when :CRYSTALCAVERN
        type = @battle.field.getRoll
      when :NEWWORLD
        type = @battle.getRandomType
      else
        type = @battle.field.mimicry if @battle.field.mimicry
    end
    type = type.intern if !type.is_a?(Symbol)
    if type==0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if attacker.hasType?(type)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    newtype=type
    attacker.type1=newtype
    attacker.type2=nil
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",attacker.pbThis,newtype.capitalize))
    return 0
  end
end

################################################################################
# Target becomes Water type. (Soak)
################################################################################
class PokeBattle_Move_061 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if (opponent.ability == :MULTITYPE) ||
      (opponent.ability == :RKSSYSTEM) || attacker.crested == :SILVALLY
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.type1=(:WATER)
    opponent.type2=nil
    typename=getTypeName((:WATER))
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",opponent.pbThis,typename))
    return 0
  end
end

################################################################################
# User copies target's types. (Reflect Type)
################################################################################
class PokeBattle_Move_062 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (attacker.ability == :MULTITYPE) ||
      (attacker.ability == :RKSSYSTEM) || attacker.crested == :SILVALLY
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if attacker.hasType?(opponent.type1) &&
       attacker.hasType?(opponent.type2) &&
       opponent.hasType?(attacker.type1) &&
       opponent.hasType?(attacker.type2)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.type1=opponent.type1
    attacker.type2=opponent.type2
    @battle.pbDisplay(_INTL("{1}'s type changed to match {2}'s!",attacker.pbThis,opponent.pbThis(true)))
    return 0
  end
end

################################################################################
# Target's ability becomes Simple. (Simple Beam)
################################################################################
class PokeBattle_Move_063 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if (PBStuff::FIXEDABILITIES).include?(opponent.ability)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    neutralgas = true if opponent.ability = :NEUTRALIZINGGAS
    opponent.ability=:SIMPLE || 0
    abilityname=getAbilityName(:SIMPLE)
    @battle.pbDisplay(_INTL("{1} acquired {2}!",opponent.pbThis,abilityname))
    
    if opponent.effects[:Illusion]!=nil 
      # Animation should go here
      # Break the illusion
      opponent.effects[:Illusion]=nil
      @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
      @battle.pbDisplay(_INTL("{1}'s Illusion was broken!",opponent.pbThis))
    end 
    @battle.neutralizingGasDisable(opponent.index) if neutralgas
    return 0
  end
end

################################################################################
# Target's ability becomes Insomnia. (Worry Seed)
################################################################################
class PokeBattle_Move_064 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if (PBStuff::FIXEDABILITIES).include?(opponent.ability)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    neutralgas = true if opponent.ability = :NEUTRALIZINGGAS
    opponent.ability=:INSOMNIA || 0
    abilityname=getAbilityName(:INSOMNIA)
    @battle.pbDisplay(_INTL("{1} acquired {2}!",opponent.pbThis,abilityname))
    
    if opponent.effects[:Illusion]!=nil 
      # Animation should go here
      # Break the illusion
      opponent.effects[:Illusion]=nil
      @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
      @battle.pbDisplay(_INTL("{1}'s {2} was broken!",opponent.pbThis,
      getAbilityName(:ILLUSION)))
    end 
    @battle.neutralizingGasDisable(opponent.index) if neutralgas
    if Rejuv && @battle.FE == :GRASSY
      if opponent.pbCanReduceStatStage?(PBStats::ATTACK,true)
        opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
      end
    end
    
    return 0
  end
end

################################################################################
# User copies target's ability. (Role Play)
################################################################################
class PokeBattle_Move_065 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.ability==0 || attacker.ability==opponent.ability ||
       (PBStuff::ABILITYBLACKLIST).include?(opponent.ability) ||
       (PBStuff::FIXEDABILITIES).include?(attacker.ability)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.ability=opponent.ability
    abilityname=getAbilityName(opponent.ability)
    @battle.pbDisplay(_INTL("{1} copied {2}'s {3}!",attacker.pbThis,opponent.pbThis(true),abilityname))
    return 0
  end
end

################################################################################
# Target copies user's ability. (Entrainment)
################################################################################
class PokeBattle_Move_066 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if attacker.ability==0 || attacker.ability==opponent.ability ||
        (PBStuff::FIXEDABILITIES).include?(opponent.ability) ||
        opponent.ability == :TRUANT ||
        ((PBStuff::ABILITYBLACKLIST).include?(attacker.ability) && attacker.ability != :WONDERGUARD)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.ability=attacker.ability
    abilityname=getAbilityName(attacker.ability)
    @battle.pbDisplay(_INTL("{1} acquired {2}!",opponent.pbThis,abilityname))
    return 0
  end
end

################################################################################
# User and target swap abilities. (Skill Swap)
################################################################################
class PokeBattle_Move_067 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (attacker.ability.nil? && opponent.ability.nil?) ||
       (PBStuff::FIXEDABILITIES - [:ZENMODE] + [:ILLUSION]).include?(attacker.ability) ||
       (PBStuff::FIXEDABILITIES - [:ZENMODE] + [:ILLUSION]).include?(opponent.ability)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.backupability, opponent.backupability = opponent.backupability, attacker.backupability
    attacker.ability = attacker.backupability if !attacker.ability.nil?
    opponent.ability = opponent.backupability if !opponent.ability.nil?

    @battle.pbDisplay(_INTL("{1} swapped its {2} ability with its target's {3} ability!",
       attacker.pbThis,getAbilityName(opponent.backupability),
       getAbilityName(attacker.backupability)))
    attacker.pbAbilitiesOnSwitchIn(true)
    opponent.pbAbilitiesOnSwitchIn(true)
    return 0
  end
end

################################################################################
# Target's ability is negated. (Gastro Acid)
################################################################################
class PokeBattle_Move_068 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (PBStuff::FIXEDABILITIES).include?(opponent.ability) || opponent.effects[:Substitute]>0 || opponent.effects[:GastroAcid]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    neutralgas = true if opponent.ability = :NEUTRALIZINGGAS
    opponent.ability = nil  #Cancel out ability
    opponent.effects[:GastroAcid]=true
    opponent.effects[:Truant]=false
    @battle.pbDisplay(_INTL("{1}'s Ability was suppressed!",opponent.pbThis))
    
    if opponent.effects[:Illusion]!=nil 
      # Animation should go here
      # Break the illusion
      opponent.effects[:Illusion]=nil
      @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
      @battle.pbDisplay(_INTL("{1}'s {2} was broken!",opponent.pbThis,
      getAbilityName(:ILLUSION)))
    end
    @battle.neutralizingGasDisable(opponent.index) if neutralgas

    return 0
  end
end

################################################################################
# User transforms into the target. (Transform)
################################################################################
class PokeBattle_Move_069 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:Transform] ||
       opponent.effects[:Transform] ||
       opponent.effects[:Substitute]>0 ||
       PBStuff::TWOTURNMOVE.include?(opponent.effects[:TwoTurnAttack]) ||
       opponent.effects[:Illusion]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.scene.pbChangePokemon(attacker,opponent.pokemon)
    attackername = attacker.pbThis    #Saves the name pre-transformation for the message
    attacker.effects[:Transform]=true
    attacker.species=opponent.species
    attacker.type1=opponent.type1
    attacker.type2=opponent.type2
    attacker.ability=opponent.ability
    attacker.attack=opponent.attack
    attacker.defense=opponent.defense
    attacker.speed=opponent.speed
    attacker.spatk=opponent.spatk
    attacker.spdef=opponent.spdef
    attacker.crested=opponent.crested
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::EVASION,PBStats::ACCURACY]
      attacker.stages[i]=opponent.stages[i]
    end
    for i in 0...4
      next if !opponent.moves[i]
      attacker.moves[i]=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(opponent.moves[i].move),attacker)
      if !(attacker.zmoves.nil? || attacker.item == :INTERCEPTZ)
        @battle.updateZMoveIndexBattler(i,attacker)
      end
      attacker.moves[i].pp=5
      attacker.moves[i].totalpp=5
    end
    attacker.moves.each {|copiedmove| @battle.ai.addMoveToMemory(attacker,copiedmove)} if !@battle.isOnline?
    opponent.moves.each {|moveloop| @battle.ai.addMoveToMemory(opponent,moveloop) } if !@battle.isOnline?
    attacker.effects[:Disable]=0
    attacker.effects[:DisableMove]=0
    @battle.pbDisplay(_INTL("{1} transformed into {2}!",attackername,opponent.pbThis(true)))
    attacker.pbAbilitiesOnSwitchIn(true)
    return 0
  end
end

################################################################################
# Inflicts a fixed 20HP damage. (Sonic Boom)
################################################################################
class PokeBattle_Move_06A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.FE == :RAINBOW # Rainbow Field
      @battle.pbDisplay(_INTL("It's a Sonic Rainboom!"))
      return pbEffectFixedDamage(140,attacker,opponent,hitnum,alltargets,showanimation)
    else
      return pbEffectFixedDamage(20,attacker,opponent,hitnum,alltargets,showanimation)
    end
  end
end

################################################################################
# Inflicts a fixed 40HP damage. (Dragon Rage)
################################################################################
class PokeBattle_Move_06B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.FE == :DIMENSIONAL || @battle.FE == :FROZENDIMENSION
      @battle.pbDisplay(_INTL("Unstoppable Rage!"))
      return pbEffectFixedDamage(140,attacker,opponent,hitnum,alltargets,showanimation)
    else
      return pbEffectFixedDamage(40,attacker,opponent,hitnum,alltargets,showanimation)
    end
  end
end

################################################################################
# Halves the target's current HP. (Super Fang / Nature Madness)
################################################################################
class PokeBattle_Move_06C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (@move == :NATURESMADNESS) && (@battle.FE == :GRASSY || #Grassy terrain
      @battle.FE == :FOREST || @battle.FE == :NEWWORLD) # Forest Field, New World
      hploss = (opponent.hp*0.75).floor
    elsif (@move == :NATURESMADNESS) && @battle.FE == :HOLY # Holy Field
      hploss = (opponent.hp*0.66).floor
    else
      hploss = (opponent.hp/2.0).floor
    end
    return pbEffectFixedDamage(hploss, attacker, opponent, hitnum, alltargets, showanimation)
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if @move != :NATURESMADNESS
    if (@battle.state.effects[:ELECTERRAIN] > 0)
      return false if !opponent.pbCanParalyze?(false)
      opponent.pbParalyze(attacker)
      @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!", opponent.pbThis))
    elsif (@battle.state.effects[:GRASSY] > 0)
      if opponent.effects[:LeechSeed] >= 0 || opponent.effects[:Substitute] > 0
        return false
      end
      if opponent.hasType?(:GRASS)
        return false
      end
      #Now handled elsewhere
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.effects[:LeechSeed]=attacker.index
      @battle.pbDisplay(_INTL("{1} was seeded!",opponent.pbThis))
    elsif (@battle.state.effects[:MISTY] > 0)
      if opponent.damagestate.substitute
        return false
      end
      opponent.stages[PBStats::ATTACK]   = 0
      opponent.stages[PBStats::DEFENSE]  = 0
      opponent.stages[PBStats::SPEED]    = 0
      opponent.stages[PBStats::SPATK]    = 0
      opponent.stages[PBStats::SPDEF]    = 0
      opponent.stages[PBStats::ACCURACY] = 0
      opponent.stages[PBStats::EVASION]  = 0
      @battle.pbDisplay(_INTL("{1}'s stat changes were removed!",opponent.pbThis))
    elsif (@battle.state.effects[:PSYTERRAIN] > 0)
      if opponent.effects[:HealBlock] > 0
        return false
      end
      if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
        return false
      end
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.effects[:HealBlock] = 5
      @battle.pbDisplay(_INTL("{1} was prevented from healing!",opponent.pbThis))
      return false
    end
    return true
  end
end

################################################################################
# Inflicts damage equal to the user's level. (Seismic Toss / Night Shade)
################################################################################
class PokeBattle_Move_06D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    hploss = attacker.level
    if (@move == :NIGHTSHADE && @battle.FE == :HAUNTED) || (@move == :SEISMICTOSS && @battle.FE == :DEEPEARTH)
      hploss = (hploss * 1.5).floor
      @battle.pbDisplay(_INTL("Slammed into the ground!")) if (@move == :SEISMICTOSS && @battle.FE == :DEEPEARTH)
    end
    return pbEffectFixedDamage(hploss,attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Inflicts damage to bring the target's HP down to equal the user's HP. (Endeavor)
################################################################################
class PokeBattle_Move_06E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp>=opponent.hp
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    return pbEffectFixedDamage(opponent.hp-attacker.hp,attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Inflicts damage between 0.5 and 1.5 times the user's level. (Psywave)
################################################################################
class PokeBattle_Move_06F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    dmg = (attacker.level * (@battle.pbRandom(101) + 50)/100.0).floor
    if @battle.FE == :DEEPEARTH
      dmg = (attacker.level * (@battle.pbRandom(51) + 100)/100.0).floor
      @battle.pbDisplay(_INTL("The core's magical forces are immense!"))
    end
    return pbEffectFixedDamage(dmg,attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# OHKO.  Accuracy increases by difference between levels of user and target. (Fissure/
# Sheer Cold / Guillotine / Horn Drill)
################################################################################
class PokeBattle_Move_070 < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    return false if (opponent.ability == :STURDY || (opponent.effects[:Sturdy])) && !opponent.moldbroken
    return false if opponent.pokemon.piece==:PAWN && @battle.FE == :CHESS
    return false if opponent.level > attacker.level || (@move == :SHEERCOLD && opponent.hasType?(:ICE))
    return true if opponent.level <= attacker.level && (attacker.ability == :NOGUARD || opponent.ability == :NOGUARD) # no guard OHKO move situation.
    acc = @accuracy + attacker.level - opponent.level
    return @battle.pbRandom(100) < acc
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    damage = pbEffectFixedDamage(opponent.totalhp,attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.hp <= 0
      @battle.pbDisplay(_INTL("It's a one-hit KO!"))
    end
    return damage
  end
end

################################################################################
# Counters a physical move used against the user this round, with 2x the power. (Counter)
################################################################################
class PokeBattle_Move_071 < PokeBattle_Move
  def pbAddTarget(targets,attacker)
    if attacker.effects[:CounterTarget]>=0 &&
       attacker.pbIsOpposing?(attacker.effects[:CounterTarget])
      if !attacker.pbAddTarget(targets,@battle.battlers[attacker.effects[:CounterTarget]])
        attacker.pbRandomTarget(targets)
      end
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:Counter]<=0 || !opponent
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    ret=pbEffectFixedDamage(attacker.effects[:Counter]*2,attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end
end

################################################################################
# Counters a specical move used against the user this round, with 2x the power. (Mirror Coat)
################################################################################
class PokeBattle_Move_072 < PokeBattle_Move
  def pbAddTarget(targets,attacker)
    if attacker.effects[:MirrorCoatTarget]>=0 &&
       attacker.pbIsOpposing?(attacker.effects[:MirrorCoatTarget])
      if !attacker.pbAddTarget(targets,@battle.battlers[attacker.effects[:MirrorCoatTarget]])
        attacker.pbRandomTarget(targets)
      end
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:MirrorCoat]<=0 || !opponent
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if @battle.FE  == :MIRROR
      for stat in [PBStats::EVASION,PBStats::DEFENSE,PBStats::SPDEF]
        if attacker.pbCanIncreaseStatStage?(stat,false)
          attacker.pbIncreaseStat(stat,1,abilitymessage:false)
        end
      end
    end
    ret=pbEffectFixedDamage(attacker.effects[:MirrorCoat]*2,attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end
end

################################################################################
# Counters the last damaging move used against the user this round, with 1.5x
# the power. (Metal Burst / Comeuppance)
################################################################################
class PokeBattle_Move_073 < PokeBattle_Move
  def pbAddTarget(targets,attacker)
    if attacker.lastAttacker>=0 && attacker.pbIsOpposing?(attacker.lastAttacker)
      if !attacker.pbAddTarget(targets,@battle.battlers[attacker.lastAttacker])
        attacker.pbRandomTarget(targets)
      end
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.lastHPLost==0 || !opponent
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    ret=pbEffectFixedDamage((attacker.lastHPLost*1.5).floor,attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :COMEUPPANCE
      @battle.pbAnimation(:FOULPLAY,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Damages user's partner 1/16 Max HP (Flame Burst)
################################################################################
class PokeBattle_Move_074 < PokeBattle_Move
#  def pbOnStartUse(attacker)
#    if @battle.FE == :CORROSIVEMIST
#      bearer=@battle.pbCheckGlobalAbility(:DAMP)
#      if bearer && @battle.FE == :CORROSIVEMIST #Corrosive Mist Field
#        @battle.pbDisplay(_INTL("{1}'s {2} prevents {3} from using {4}!",
#        bearer.pbThis,getAbilityName(bearer.ability),attacker.pbThis(true),@name))
#        return false
#      end
#    end
#    return true
# end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret = super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if opponent.pbPartner && !opponent.pbPartner.isFainted?
      opponent.pbPartner.pbReduceHP((opponent.pbPartner.totalhp / 16.0).floor)
      @battle.pbDisplay(_INTL("The bursting flame hit {1}!", opponent.pbPartner.pbThis(true)))
      (opponent.pbPartner).pbFaint if (opponent.pbPartner).isFainted?
    end
    return ret
  end
end

################################################################################
# Power is doubled if the target is using Dive. (Surf)
# (Handled in Battler's pbSuccessCheck): Hits some semi-invulnerable targets.
################################################################################
class PokeBattle_Move_075 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    damagemult*= 2.0 if !$cache.moves[opponent.effects[:TwoTurnAttack]].nil? && 
    $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCB # Dive
    return damagemult
  end
end

################################################################################
# Power is doubled if the target is using Dig. (Earthquake)
# (Handled in Battler's pbSuccessCheck): Hits some semi-invulnerable targets.
################################################################################
class PokeBattle_Move_076 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    damagemult*= 2.0 if !$cache.moves[opponent.effects[:TwoTurnAttack]].nil? && 
    $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCA # Dig
    return damagemult
  end
end

################################################################################
# Power is doubled if the target is using Bounce, Fly or Sky Drop. (Gust)
# (Handled in Battler's pbSuccessCheck): Hits some semi-invulnerable targets.
################################################################################
class PokeBattle_Move_077 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if !$cache.moves[opponent.effects[:TwoTurnAttack]].nil? &&  
      ($cache.moves[opponent.effects[:TwoTurnAttack]].function==0xC9 || # Fly
       $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCC || # Bounce
       $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCE)    # Sky Drop
      return basedmg*2
    end
    return basedmg
  end
end

################################################################################
# Power is doubled if the target is using Bounce, Fly or Sky Drop.
# May make the target flinch. (Twister)
# (Handled in Battler's pbSuccessCheck): Hits some semi-invulnerable targets.
################################################################################
class PokeBattle_Move_078 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if !$cache.moves[opponent.effects[:TwoTurnAttack]].nil? &&  
      ($cache.moves[opponent.effects[:TwoTurnAttack]].function==0xC9 || # Fly
       $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCC || # Bounce
       $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCE)    # Sky Drop
      return basedmg*2
    elsif opponent.hasType?(:FLYING) || opponent.ability == :LEVITATE || opponent.effects[:MagnetRise]>0 || opponent.effects[:Telekinesis]>0 ||
          opponent.ability == :SOLARIDOL || opponent.ability == :LUNARIDOL || opponent.ability == :GRAVFLUX
      return basedmg*2
    end
    return basedmg
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
       !opponent.effects[:Roost] && !(opponent.ability == :GRAVFLUX && @battle.state.effects[:Gravity] != 0)
      opponent.effects[:SmackDown]=true
      showmsg=false
      showmsg=true if opponent.hasType?(:FLYING) ||
                      opponent.ability == :LEVITATE || opponent.ability == :SOLARIDOL || opponent.ability == :LUNARIDOL || opponent.crested == :LUMINEON || opponent.ability == :GRAVFLUX
      if !$cache.moves[opponent.effects[:TwoTurnAttack]].nil? && 
        ($cache.moves[opponent.effects[:TwoTurnAttack]].function==0xC9 || # Fly
         $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCC)    # Bounce
        opponent.effects[:TwoTurnAttack]=0; showmsg=true
      end
      if opponent.effects[:MagnetRise]!=0
        opponent.effects[:MagnetRise]=0; showmsg=true
      end
      if opponent.effects[:Telekinesis]>0
        opponent.effects[:Telekinesis]=0; showmsg=true
      end
      @battle.pbDisplay(_INTL("{1} fell out of the sky!",opponent.pbThis)) if showmsg
      return true
    end
    return false
  end
end

################################################################################
# Power is doubled if the target has already used Fusion Flare this round. (Fusion Bolt)
################################################################################
class PokeBattle_Move_079 < PokeBattle_UnimplementedMove

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return 0 if !opponent  
    damage=pbCalcDamage(attacker,opponent)
    if attacker.effects[:MeFirst]
      damage *= 1.5
    end
    if hitnum == 1 && attacker.effects[:ParentalBond] && pbNumHits(attacker)==1
      damage /= 2
    end
    # ???
    if hitnum > 0 && attacker.effects[:HydreigonCrest] && pbNumHits(attacker)==1
      damage /= 4
    end
    if opponent.damagestate.typemod!=0
      if @battle.previousMove == :FUSIONFLARE
        pbShowAnimation(:FUSIONBOLT2,attacker,opponent,hitnum,alltargets,showanimation) rescue pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      else 
        pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      end
    end
    damage=pbReduceHPDamage(damage,attacker,opponent)
    pbEffectMessages(attacker,opponent)
    pbOnDamageLost(damage,attacker,opponent)
    return damage   # The HP lost by the opponent due to this attack
  end
 
  def pbBaseDamageMultiplier(damagemult, attacker, opponent)
    damagemult*=2.0 if @battle.previousMove == :FUSIONFLARE
    return damagemult
  end
end

################################################################################
# Power is doubled if the target has already used Fusion Bolt this round. (Fusion Flare)
################################################################################
class PokeBattle_Move_07A < PokeBattle_UnimplementedMove

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return 0 if !opponent  
    damage=pbCalcDamage(attacker,opponent)
    if attacker.effects[:MeFirst]
      damage *= 1.5
    end
    if hitnum == 1 && attacker.effects[:ParentalBond] &&
      pbNumHits(attacker)==1
      damage /= 2
    end
    if hitnum > 0 && attacker.effects[:HydreigonCrest] && pbNumHits(attacker)==1
      damage /= 4
    end
    if opponent.damagestate.typemod!=0
      if @battle.previousMove == :FUSIONBOLT
        pbShowAnimation(:FUSIONFLARE2,attacker,opponent,hitnum,alltargets,showanimation) rescue pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      else
        pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      end
    end
    damage=pbReduceHPDamage(damage,attacker,opponent)
    pbEffectMessages(attacker,opponent)
    pbOnDamageLost(damage,attacker,opponent)
    return damage   # The HP lost by the opponent due to this attack
  end
 
  def pbBaseDamageMultiplier(damagemult, attacker, opponent)
    damagemult*=2.0 if @battle.previousMove == :FUSIONBOLT
    return damagemult
  end
end

################################################################################
# Power is doubled if the target is poisoned. (Venoshock)
################################################################################
class PokeBattle_Move_07B < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if (@battle.FE == :CORROSIVE || @battle.FE == :CORROSIVEMIST ||
      @battle.FE == :WASTELAND || @battle.FE == :MURKWATERSURFACE) ||
      (opponent.status== :POISON && opponent.effects[:Substitute]==0)
      return basedmg*2
    end
    return basedmg
  end
end

################################################################################
# Power is doubled if the target is paralyzed.  Cures the target of paralysis. (Smelling Salts)
################################################################################
class PokeBattle_Move_07C < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if opponent.status== :PARALYSIS &&
       opponent.effects[:Substitute]==0
      return basedmg*2
    end
    return basedmg
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
       opponent.status== :PARALYSIS && !(attacker.ability == :PARENTALBOND && hitnum==0) && !(attacker.crested == :HYDREIGON && hitnum==0) 
      opponent.status=nil
      @battle.pbDisplay(_INTL("{1} was cured of paralysis.",opponent.pbThis))
    end
    return ret
  end
end

################################################################################
# Power is doubled if the target is asleep.  Wakes the target up. (Wake-up Slap)
################################################################################
class PokeBattle_Move_07D < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if (opponent.status== :SLEEP || (opponent.ability == :COMATOSE && @battle.FE != :ELECTERRAIN)) &&
       opponent.effects[:Substitute]==0
      return basedmg*2
    end
    return basedmg
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
       opponent.status== :SLEEP && !(attacker.ability == :PARENTALBOND && hitnum==0) && !(attacker.crested == :HYDREIGON && hitnum==0) 
      opponent.pbCureStatus
    end
    return ret
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :WAKEUPSHOCK
      @battle.pbAnimation(:ZINGZAP,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Power is doubled if the user is burned, poisoned or paralyzed. (Facade)
################################################################################
class PokeBattle_Move_07E < PokeBattle_Move
  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    damagemult*=2.0 if attacker.status== :POISON || attacker.status== :BURN || attacker.status== :PARALYSIS
    return damagemult
  end
end

################################################################################
# Power is doubled if the target has a status problem. (Hex)
################################################################################
class PokeBattle_Move_07F < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.FE == :INFERNAL ||
      ((!opponent.status.nil? || (opponent.ability == :COMATOSE && @battle.FE != :ELECTERRAIN)) &&
       opponent.effects[:Substitute]==0)
      return basedmg*2
    end
    return basedmg
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :IRRITATION
      @battle.pbAnimation(:INFESTATION,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Power is doubled if the target's HP is down to 1/2 or less. (Brine)
################################################################################
class PokeBattle_Move_080 < PokeBattle_Move
  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    damagemult*=2.0 if opponent.hp<=(opponent.totalhp/2.0).floor
    return damagemult
  end
end

################################################################################
# Power is doubled if the user has lost HP due to the target's move this round. 
# (Revenge / Avalanche)
################################################################################
class PokeBattle_Move_081 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if attacker.lastHPLost>0 && attacker.lastAttacker==opponent.index
      return basedmg*2
    end
    return basedmg
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :DELUGE
      @battle.pbAnimation(:BRINE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Power is doubled if the target has already lost HP this round. (Assurance)
################################################################################
class PokeBattle_Move_082 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if opponent.lastHPLost>0
      return basedmg*2
    end
    return basedmg
  end
end

################################################################################
# Power is doubled if the user's ally has already used this move this round.
# This move goes immediately after the ally, ignoring priority. (Round)
################################################################################
class PokeBattle_Move_083 < PokeBattle_Move

  def pbBaseDamage(basedmg,attacker,opponent)
    if attacker.pbPartner.hasMovedThisRound? &&
       attacker.pbPartner.effects[:Round]
       return basedmg*2
    elsif !attacker.pbPartner.hasMovedThisRound?
      # Partner hasn't moved yet,
      # so we flag the user with the
      # Round effect
      attacker.effects[:Round] = true
      return basedmg
    else
      # Return base damage with no alterations
      return basedmg
    end
  end

end

################################################################################
# Power is doubled if the target has already moved this round. (Payback)
################################################################################
class PokeBattle_Move_084 < PokeBattle_Move

  def pbBaseDamage(basedmg,attacker,opponent)
    if opponent.hasMovedThisRound? && !@battle.switchedOut[opponent.index]
      return basedmg*2
    else
      return basedmg
    end
  end

end

################################################################################
# Power is doubled if a user's teammate fainted last round. (Retaliate)
################################################################################
class PokeBattle_Move_085 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return basedmg*2 if attacker.pbOwnSide.effects[:Retaliate]
    return basedmg
  end
end

################################################################################
# Power is doubled if the user has no held item. (Acrobatics)
################################################################################
class PokeBattle_Move_086 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    movetype = pbType(attacker)
    gem = false
    if attacker.itemWorks? 
      case attacker.item
        when :NORMALGEM   then gem = true if movetype == :NORMAL
        when :FIGHTINGGEM then gem = true if movetype == :FIGHTING
        when :FLYINGGEM   then gem = true if movetype == :FLYING
        when :POISONGEM   then gem = true if movetype == :POISON
        when :GROUNDGEM   then gem = true if movetype == :GROUND
        when :ROCKGEM     then gem = true if movetype == :ROCK
        when :BUGGEM      then gem = true if movetype == :BUG
        when :GHOSTGEM    then gem = true if movetype == :GHOST
        when :STEELGEM    then gem = true if movetype == :STEEL
        when :FIREGEM     then gem = true if movetype == :FIRE
        when :WATERGEM    then gem = true if movetype == :WATER
        when :GRASSGEM    then gem = true if movetype == :GRASS
        when :ELECTRICGEM then gem = true if movetype == :ELECTRIC
        when :PSYCHICGEM  then gem = true if movetype == :PSYCHIC
        when :ICEGEM      then gem = true if movetype == :ICE
        when :DRAGONGEM   then gem = true if movetype == :DRAGON
        when :DARKGEM     then gem = true if movetype == :DARK
        when :FAIRYGEM    then gem = true if movetype == :FAIRY
      end
    end
    return basedmg*2 if attacker.item.nil? || @battle.FE == :BIGTOP || gem
    return basedmg
  end
end

################################################################################
# Power is doubled in weather.  Type changes depending on the weather. (Weather Ball)
################################################################################
class PokeBattle_Move_087 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if attacker.crested == :CHERRIM
      basedmg*=4
    elsif @battle.pbWeather!=0 || @battle.FE == :RAINBOW
      basedmg*=2
    end
    return basedmg
  end

  def pbType(attacker,type=@type)
    weather=@battle.pbWeather
    type=(:NORMAL) || 0
    type=((:WATER) || type) if weather== :RAINDANCE
    type=((:ROCK) || type) if weather== :SANDSTORM
    type=((:ICE)  || type) if weather== :HAIL
    type=((:FLYING) || type) if @battle.FE == :SKY && weather == :STRONGWINDS
    type=((:SHADOW) || type) if Rejuv && weather == :SHADOWSKY
    type=((:FIRE) || type) if weather== :SUNNYDAY || attacker.crested == :CHERRIM  
    type=super(attacker,type)
    return type
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    case @battle.pbWeather
      when :RAINDANCE
        @battle.pbAnimation(:WEATHERBALLRAIN,attacker,opponent,hitnum) #Weather Ball - Rain
      when :SUNNYDAY
        @battle.pbAnimation(:WEATHERBALLSUN,attacker,opponent,hitnum) #Weather Ball - Sun
      when :HAIL
        @battle.pbAnimation(:WEATHERBALLHAIL,attacker,opponent,hitnum) #Weather Ball - Hail
      when :SANDSTORM
        @battle.pbAnimation(:WEATHERBALLSAND,attacker,opponent,hitnum) #Weather Ball - Sand
      else
        @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Power is doubled if a foe tries to switch out. (Pursuit)
# (Handled in Battle's pbAttackPhase): Makes this attack happen before switching.
################################################################################
class PokeBattle_Move_088 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return basedmg*2 if @battle.switching
    return basedmg
  end
end

################################################################################
# Power increases with the user's happiness. (Return)
################################################################################
class PokeBattle_Move_089 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    return 102 if @battle.FE == :CONCERT4
    return [(attacker.happiness*2/5.0).floor,1].max
  end
end

################################################################################
# Power decreases with the user's happiness. (Frustration)
################################################################################
class PokeBattle_Move_08A < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [250-attacker.happiness,1].max if attacker.crested == :LUVDISC
    return 102 if @battle.FE == :CONCERT4
    return [((255-attacker.happiness)*2/5.0).floor,1].max
  end
end

################################################################################
# Power increases with the user's HP. (Eruption / Water Spout)
################################################################################
class PokeBattle_Move_08B < PokeBattle_Move
  def pbOnStartUse(attacker)
    if @battle.FE == :CORROSIVEMIST
      if (@move == :ERUPTION)
        bearer=@battle.pbCheckGlobalAbility(:DAMP)
        if bearer
          @battle.pbDisplay(_INTL("{1}'s {2} prevents {3} from using {4}!",
          bearer.pbThis,getAbilityName(bearer.ability),attacker.pbThis(true),@name))
          return false
        end
      end
    end
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    return 150 if @battle.FE == :CONCERT4
    return [(150*(attacker.hp.to_f)/attacker.totalhp).floor,1].max
  end
end

################################################################################
# Power increases with the target's HP. (Wring Out / Crush Grip)
################################################################################
class PokeBattle_Move_08C < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    base = 120
    if (@move == :CRUSHGRIP)
      base = 200
    end
    return base if @battle.FE == :DEEPEARTH || @battle.FE == :CONCERT4
    return [(base*(opponent.hp.to_f)/opponent.totalhp).floor,1].max
  end
end

################################################################################
# Power increases the quicker the target is than the user. (Gyro Ball)
################################################################################
class PokeBattle_Move_08D < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    return 150 if @battle.FE == :DEEPEARTH || @battle.FE == :CONCERT4
    return [[(25*opponent.pbSpeed/attacker.pbSpeed).floor,150].min,1].max
  end
end

################################################################################
# Power increases with the user's positive stat changes (ignores negative ones).
# (Stored Power / Power Trip)
################################################################################
class PokeBattle_Move_08E < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    mult=0
    for i in 1...7
      mult+=attacker.stages[i] if attacker.stages[i]>0
    end
    bp = 20
    bp = 40 if @battle.FE == :FROZENDIMENSION && @move == :POWERTRIP
    return ([attacker.happiness,250].min)+(bp*mult) if attacker.crested == :LUVDISC
    return bp*(mult+1)
  end
end

################################################################################
# Power increases with the target's positive stat changes (ignores negative ones).
# (Punishment)
################################################################################
class PokeBattle_Move_08F < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    mult=0
    for i in 1...7
      mult+=opponent.stages[i] if opponent.stages[i]>0
    end
    return [([attacker.happiness,250].min)+(20*mult),500].min if attacker.crested == :LUVDISC
    return [20*(mult+3),200].min
  end
end

################################################################################
# Power and type depends on the user's IVs. (Hidden Power)
################################################################################
class PokeBattle_Move_090 < PokeBattle_Move

  def pbType(attacker,type=@type)
    type=pbHiddenPower(attacker.pokemon)
    type=super(attacker,type)
    return type
  end

end

def pbHiddenPower(user)
  return :QMARKS if user == nil
  return user.hptype if user.hptype != nil
  type=0
  types=[]
  for i in $cache.types.keys
    types.push(i) if i != :NORMAL && i!= :QMARKS && i != :SHADOW
  end
  selected_index = user.personalID % types.length
  user.hptype = types[selected_index]
  return user.hptype
end

################################################################################
# Power doubles for each consecutive use. (Fury Cutter)
################################################################################
class PokeBattle_Move_091 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    basedmg=basedmg<<(attacker.effects[:FuryCutter]-1) # can be 1 to 4
    return basedmg
  end
end

################################################################################
# Power doubles for each consecutive use. (Echoed Voice)
################################################################################
class PokeBattle_Move_092 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    basedmg*=attacker.effects[:EchoedVoice] # can be 1 to 5
    return basedmg
  end
end

################################################################################
# User rages until the start of a round in which they don't use this move. (Rage)
# Handled in Battler class: Ups rager's Attack by 1 stage each time it loses HP due to a move.
################################################################################
class PokeBattle_Move_093 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    if @battle.FE == :DIMENSIONAL || @battle.FE == :FROZENDIMENSION
      basedmg = 60
    end
    return basedmg
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.FE == :DIMENSIONAL || @battle.FE == :FROZENDIMENSION
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,abilitymessage:false)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false) if ret>0
      end
    else
      attacker.effects[:Rage]=true if ret>0
    end
    return ret
  end
end

################################################################################
# Randomly damages or heals the target. (Present)
################################################################################
class PokeBattle_Move_094 < PokeBattle_Move

  def pbBaseDamage(basedmg,attacker,opponent)
    return @calcbasedmg
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    @calcbasedmg=1
    r=@battle.pbRandom(10)
    if r<4
      @calcbasedmg=40
      @calcbasedmg=[attacker.happiness,250].min if attacker.crested == :LUVDISC
    elsif r<7
      @calcbasedmg=80
      @calcbasedmg=[attacker.happiness,250].min if attacker.crested == :LUVDISC
    elsif r<8
      @calcbasedmg=120
      @calcbasedmg=[attacker.happiness,250].min if attacker.crested == :LUVDISC
    else
      if pbTypeModifier(@type,attacker,opponent)==0
        @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
        return -1
      end
      if opponent.hp==opponent.totalhp
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
      damage=pbCalcDamage(attacker,opponent) # Must do this even if it will heal
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation) # Healing animation
      opponent.pbRecoverHP([1,(opponent.totalhp/4.0).floor].max,true)
      @battle.pbDisplay(_INTL("{1} had its HP restored.",opponent.pbThis))
      return 0
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Power is chosen at random.  Power is doubled if the target is using Dig. (Magnitude)
# (Handled in Battler's pbSuccessCheck): Hits some semi-invulnerable targets.
################################################################################
class PokeBattle_Move_095 < PokeBattle_Move
  @calcbasedmg=0
  
  def pbOnStartUse(attacker)
    basedmg=[10,30,50,70,90,110,150]
    magnitudes=[
       4,
       5,5,
       6,6,6,6,
       7,7,7,7,7,7,
       8,8,8,8,
       9,9,
       10
    ]
    magni=magnitudes[@battle.pbRandom(magnitudes.length)]
    magni=magnitudes[0] if @battle.FE == :CONCERT1
    magni=magnitudes[19] if @battle.FE == :CONCERT4
    @calcbasedmg=basedmg[magni-4]
    if attacker.crested == :LUVDISC
      @calcbasedmg=[attacker.happiness,250].min
      hype=11
    end
    @battle.pbDisplay(_INTL("Magnitude {1}!",magni))
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    if !$cache.moves[opponent.effects[:TwoTurnAttack]].nil? && 
      $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCA # Dig
      return @calcbasedmg*2
    end
    return @calcbasedmg
  end
end

################################################################################
# Power and type depend on the user's held berry.  Destroys the berry. (Natural Gift)
################################################################################
class PokeBattle_Move_096 < PokeBattle_Move
  def initialize(battle,move,user,zbase=nil)
    super(battle,move,user,zbase=nil)
    @berry=0
  end

  def pbOnStartUse(attacker)
    if attacker.item.nil? || !pbIsBerry?(attacker.item)
      @battle.pbDisplay(_INTL("But it failed!"))
      return false
    end
    @berry=attacker.item
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.item.nil?
      @battle.pbDisplay(_INTL("But it failed!"))
      return 0
    end
    # attacker.pbDisposeItem(true)
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    return 100 if @battle.FE == :CONCERT4
    if @berry!=0
      return !PBStuff::NATURALGIFTDAMAGE[@berry].nil? ? PBStuff::NATURALGIFTDAMAGE[@berry] : 1
    else
      return !PBStuff::NATURALGIFTDAMAGE[attacker.item].nil? ? PBStuff::NATURALGIFTDAMAGE[attacker.item] : 1
    end
  end

  def pbType(attacker,type=@type)
    
    if @berry != 0
      type= !PBStuff::NATURALGIFTTYPE[@berry].nil? ? PBStuff::NATURALGIFTTYPE[@berry] : :NORMAL
    else
      type= !PBStuff::NATURALGIFTTYPE[attacker.item].nil? ? PBStuff::NATURALGIFTTYPE[attacker.item] : :NORMAL
    end
    return super(attacker,type)
  end
end

################################################################################
# Power increases the less PP this move has. (Trump Card)
################################################################################
class PokeBattle_Move_097 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    dmgs=[250,200,150,100,50]
    ppleft=[@pp,4].min   # PP is reduced beforef the move is used
    basedmg=dmgs[ppleft]
    basedmg=200 if @battle.FE == :CONCERT4
    return basedmg
  end
end

################################################################################
# Power increases the less HP the user has. (Flail / Reversal)
################################################################################
class PokeBattle_Move_098 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    n=((48*attacker.hp.to_f)/attacker.totalhp).floor
    ret=20
    ret=40 if n<33
    ret=80 if n<17
    ret=100 if n<10
    ret=150 if n<5
    ret=200 if n<2 || @battle.FE == :CONCERT4
    return ret
  end
end

################################################################################
# Power increases the quicker the user is than the target. (Electro Ball)
################################################################################
class PokeBattle_Move_099 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    n=(attacker.pbSpeed/opponent.pbSpeed).floor
    ret=40
    ret=60 if n>=1
    ret=80 if n>=2
    ret=120 if n>=3
    ret=150 if n>=4 || @battle.FE == :CONCERT4
    return ret
  end
end

################################################################################
# Power increases the heavier the target is. (Low Kick / Grass Knot)
################################################################################
class PokeBattle_Move_09A < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    weight=opponent.weight
    weight=opponent.weight*2 if @battle.FE == :DEEPEARTH
    ret=20
    ret=40 if weight>100
    ret=60 if weight>250
    ret=80 if weight>500
    ret=100 if weight>1000
    ret=120 if weight>2000 || @battle.FE == :CONCERT4
    return ret
  end
end

################################################################################
# Power increases the heavier the user is than the target. (heavy Slam / Heat Crash)
################################################################################
class PokeBattle_Move_09B < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    n=(attacker.weight/opponent.weight).floor
    n=(attacker.weight*2/opponent.weight).floor if @battle.FE == :DEEPEARTH
    ret=40
    ret=60 if n>=2
    ret=80 if n>=3
    ret=100 if n>=4
    ret=120 if n>=5 || @battle.FE == :CONCERT4
    ret*= 1.5 if @move == :BLACKHOLE && @battle.state.effects[:Gravity]!=0
    return ret
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    damagemult*= 2.0 if opponent.effects[:Minimize]
    return damagemult
  end
end

################################################################################
# Powers up the ally's attack this round by 1.5. (Helping Hand)
################################################################################
class PokeBattle_Move_09C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbPartner.isFainted? ||
       attacker.pbPartner.effects[:HelpingHand] ||
       @battle.pbGetPriority(attacker) > @battle.pbGetPriority(attacker.pbPartner)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,attacker.pbPartner,hitnum,alltargets,showanimation)
    attacker.pbPartner.effects[:HelpingHand]=true
    @battle.pbDisplay(_INTL("{1} is ready to help {2}!",attacker.pbThis,attacker.pbPartner.pbThis(true)))
    return 0
  end
end

################################################################################
# Weakens Electric attacks. (Mud Sport)
################################################################################
class PokeBattle_Move_09D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.state.effects[:MudSport]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.state.effects[:MudSport]=5
    @battle.pbDisplay(_INTL("Electricity's power was weakened!"))
    return 0
  end
end

################################################################################
# Weakens Fire attacks. (Water Sport)
################################################################################
class PokeBattle_Move_09E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.state.effects[:WaterSport]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.state.effects[:WaterSport]=5
    @battle.pbDisplay(_INTL("Fire's power was weakened!"))
    return 0
  end
end

################################################################################
# Type depends on the user's held item. (JUDGEMENT / Techno Blast / Multi-Attack)
################################################################################
class PokeBattle_Move_09F < PokeBattle_Move
  def pbType(attacker,type=@type)
    if ((@move == :JUDGEMENT) && (attacker.species == :ARCEUS)) || 
      ((@move == :MULTIATTACK) && (attacker.species == :SILVALLY))
      type = $cache.pkmn[attacker.species].forms[attacker.form%19].upcase.intern
      type = :QMARKS if type == "???".intern
    end
    if attacker.itemWorks? && attacker.form<19
      if @move == :TECHNOBLAST
        case attacker.item
          when :SHOCKDRIVE then type = :ELECTRIC  
          when :BURNDRIVE then type = :FIRE
          when :CHILLDRIVE then type = :ICE
          when :DOUSEDRIVE then type = :WATER
        end
      elsif @move == :MULTIATTACK
        itemtype = $cache.items[attacker.item].checkFlag?(:memory)
        type = itemtype if itemtype
      elsif @move == :JUDGEMENT || @move == :MULTIPULSE
        if PBStuff::PLATEITEMS.include?(attacker.item)
          itemtype = $cache.items[attacker.item].checkFlag?(:typeboost)
          type = itemtype if itemtype
        end
      end
    end
    return super(attacker,type)
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    @battle.pbAnimation(id,attacker,opponent,hitnum) if @move == :MULTIPULSE
    if @move == :TECHNOBLAST
      if attacker.itemWorks?
        case attacker.item
        when :SHOCKDRIVE
          @battle.pbAnimation(:TECHNOBLASTELECTRIC,attacker,opponent,hitnum)
        when :BURNDRIVE
          @battle.pbAnimation(:TECHNOBLASTFIRE,attacker,opponent,hitnum)
        when :CHILLDRIVE
          @battle.pbAnimation(:TECHNOBLASTICE,attacker,opponent,hitnum)
        when :DOUSEDRIVE
          @battle.pbAnimation(:TECHNOBLASTWATER,attacker,opponent,hitnum)
        else @battle.pbAnimation(id,attacker,opponent,hitnum)
        end
      else @battle.pbAnimation(id,attacker,opponent,hitnum)
      end
    end
    if @move == :JUDGEMENT
      if attacker.itemWorks?
        m = @move.to_s
        if PBStuff::PLATEITEMS.include?(attacker.item) || PBStuff::TYPETOZCRYSTAL.values.include?(attacker.item)
          append = PBStuff::PLATEITEMS.include?(attacker.item) ? $cache.items[attacker.item].checkFlag?(:typeboost) : PBStuff::TYPETOZCRYSTAL.invert[attacker.item]
          m = m.concat(append.to_s).to_sym
        end
        @battle.pbAnimation(m,attacker,opponent,hitnum)
      elsif @battle.FE == :NEWWORLD
        m = @move.to_s
        type = attacker.type1
        m = m.concat(type.to_s).to_sym
        @battle.pbAnimation(m,attacker,opponent,hitnum)
      else
        @battle.pbAnimation(id,attacker,opponent,hitnum)
      end
    end
    if @move == :MULTIATTACK
      if attacker.itemWorks?
        m = @move.to_s.concat($cache.items[attacker.item].checkFlag?(:memory).to_s).to_sym
        @battle.pbAnimation(m,attacker,opponent,hitnum)
      else
        @battle.pbAnimation(id,attacker,opponent,hitnum)
      end
    end
  end
end

################################################################################
# This attack is always a critical hit, if successful. (Storm Throw / Frost Breath)
################################################################################
class PokeBattle_Move_0A0 < PokeBattle_Move
# Handled in superclass, do not edit!
end

################################################################################
# For 5 rounds, foes' attacks cannot become critical hits. (Lucky Chant)
################################################################################
class PokeBattle_Move_0A1 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[:LuckyChant]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[:LuckyChant]=5
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("The Lucky Chant shielded your team from critical hits!"))
    else
      @battle.pbDisplay(_INTL("The Lucky Chant shielded the foe's team from critical hits!"))
    end
    return 0
  end
end

################################################################################
# For 5 rounds, lowers power of physical attacks against the user's side. (Reflect)
################################################################################
class PokeBattle_Move_0A2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[:Reflect]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[:Reflect]=5
    attacker.pbOwnSide.effects[:Reflect]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
    attacker.pbOwnSide.effects[:Reflect]=8 if @battle.FE == :MIRROR || @battle.FE == :DANCEFLOOR
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("Reflect raised your team's Defense!"))
    else
      @battle.pbDisplay(_INTL("Reflect raised the opposing team's Defense!"))
    end
    if @battle.FE  == :MIRROR
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,1,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# For 5 rounds, lowers power of special attacks against the user's side. (Light Screen)
################################################################################
class PokeBattle_Move_0A3 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[:LightScreen]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[:LightScreen]=5
    attacker.pbOwnSide.effects[:LightScreen]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
    attacker.pbOwnSide.effects[:LightScreen]=8 if @battle.FE == :MIRROR || @battle.FE == :DANCEFLOOR
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("Light Screen raised your team's Special Defense!"))
    else
      @battle.pbDisplay(_INTL("Light Screen raised the opposing team's Special Defense!"))
    end
    if @battle.FE  == :MIRROR
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,1,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Effect depends on the environment. (Secret power)
################################################################################
class PokeBattle_Move_0A4 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@battle.field.secretPowerAnim,attacker,opponent,hitnum,alltargets,showanimation) unless pbTypeModifier(@type,attacker,opponent)==0
    return super(attacker,opponent,hitnum,alltargets,false)
  end

  def pbAdditionalEffect(attacker,opponent)
    case @battle.FE
    when :ELECTERRAIN,:SHORTCIRCUIT
      return false if !opponent.pbCanParalyze?(false)
      opponent.pbParalyze(attacker)
      @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
    when :GRASSY,:FOREST,:FAIRYTALE
      return false if !opponent.pbCanSleep?(false)
      opponent.pbSleep
      @battle.pbDisplay(_INTL("{1} went to sleep!",opponent.pbThis))
    when :MISTY,:HOLY
      return false if !opponent.pbCanReduceStatStage?(PBStats::SPATK,1,false)
      opponent.pbReduceStat(PBStats::SPATK,1,abilitymessage:false, statdropper: attacker)
    when :DARKCRYSTALCAVERN,:DESERT,:ASHENBEACH,:CLOUDS 
      return false if !opponent.pbCanReduceStatStage?(PBStats::ACCURACY,1,false)
      opponent.pbReduceStat(PBStats::ACCURACY,1,abilitymessage:false, statdropper: attacker)
    when :CHESS, :DARKNESS1, :DARKNESS2, :DARKNESS3
      return false if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,1,false)
      opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
    when :BIGTOP,:STARLIGHT
      return false if !opponent.pbCanReduceStatStage?(PBStats::SPDEF,1,false)
      opponent.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false, statdropper: attacker)
    when :BURNING,:SUPERHEATED,:DRAGONSDEN,:VOLCANIC,:VOLCANICTOP,:INFERNAL,:DANCEFLOOR
      return false if !opponent.pbCanBurn?(false)
      opponent.pbBurn(attacker)
      @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
    when :SWAMP,:WATERSURFACE,:GLITCH 
      return false if !opponent.pbCanReduceStatStage?(PBStats::SPEED,1,false)
      opponent.pbReduceStat(PBStats::SPEED,1,abilitymessage:false, statdropper: attacker)
    when :RAINBOW,:WASTELAND,:CRYSTALCAVERN,:BEWITCHED
      rnd=0
      loop do
        rnd=@battle.pbRandom(6)
        break if (@battle.FE == :RAINBOW && rnd != 5) || (@battle.FE == :WASTELAND && rnd<4) || (@battle.FE == :CRYSTALCAVERN && rnd>2) || (@battle.FE == :BEWITCHED && (rnd<2 || rnd==4))
      end
      case rnd
        when 0
          return false if !opponent.pbCanParalyze?(false)
          opponent.pbParalyze(attacker)
          @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
        when 1
          return false if !opponent.pbCanPoison?(false)
          opponent.pbPoison(attacker)
          @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
        when 2
          return false if !opponent.pbCanBurn?(false)
          opponent.pbBurn(attacker)
          @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
        when 3
          return false if !opponent.pbCanFreeze?(false)
          opponent.pbFreeze
          @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
        when 4
          return false if !opponent.pbCanSleep?(false)
          opponent.pbSleep
          @battle.pbDisplay(_INTL("{1} fell asleep!",opponent.pbThis))
        when 5
          return false if !opponent.pbCanConfuse?(false)
          opponent.effects[:Confusion]=2+@battle.pbRandom(4)
          @battle.pbCommonAnimation("Confusion",opponent,nil)
          @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
      end
    when :CORROSIVE,:CORROSIVEMIST,:MURKWATERSURFACE,:CORRUPTED,:BACKALLEY,:CITY
      return false if !opponent.pbCanPoison?(false)
      opponent.pbPoison(attacker)
      @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
    when :ICY,:SNOWYMOUNTAIN,:FROZENDIMENSION
      return false if !opponent.pbCanFreeze?(false)
      opponent.pbFreeze
      @battle.pbDisplay(_INTL("{1} was frozen!",opponent.pbThis))
    when :ROCKY,:CAVE,:MOUNTAIN,:DIMENSIONAL,:DEEPEARTH,:CONCERT1,:CONCERT2,:CONCERT3,:CONCERT4
      return false if opponent.ability == :INNERFOCUS || opponent.damagestate.substitute
      opponent.effects[:Flinch]=true
    when :FACTORY,:UNDERWATER
      return false if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,1,false)
      opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
    when :MIRROR
      return false if !opponent.pbCanReduceStatStage?(PBStats::EVASION,1,false)
      opponent.pbReduceStat(PBStats::EVASION,1,abilitymessage:false, statdropper: attacker)
    when :FLOWERGARDEN1,:FLOWERGARDEN2,:FLOWERGARDEN3,:FLOWERGARDEN4,:FLOWERGARDEN5
      if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,1,2)
        return false if !opponent.pbCanReduceStatStage?(PBStats::EVASION,1,false)
        opponent.pbReduceStat(PBStats::EVASION,1,abilitymessage:false)
      elsif @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,4)
        opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker) if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,1,false)
        opponent.pbReduceStat(PBStats::SPDEF,1,abilitymessage:false, statdropper: attacker) if opponent.pbCanReduceStatStage?(PBStats::SPDEF,1,false)
        opponent.pbReduceStat(PBStats::EVASION,1,abilitymessage:false, statdropper: attacker) if opponent.pbCanReduceStatStage?(PBStats::EVASION,1,false)
      elsif @battle.FE == :FLOWERGARDEN5
        opponent.pbReduceStat(PBStats::DEFENSE,2,abilitymessage:false, statdropper: attacker) if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,1,false)
        opponent.pbReduceStat(PBStats::SPDEF,2,abilitymessage:false, statdropper: attacker) if opponent.pbCanReduceStatStage?(PBStats::SPDEF,1,false)
        opponent.pbReduceStat(PBStats::EVASION,2,abilitymessage:false, statdropper: attacker) if opponent.pbCanReduceStatStage?(PBStats::EVASION,1,false)
      end
    when :NEWWORLD
      for i in 1...7
        opponent.pbReduceStat(i,1,abilitymessage:false, statdropper: attacker) if opponent.pbCanReduceStatStage?(i,1,false)
      end
    when :INVERSE, :PSYTERRAIN, :SKY
      return false if !opponent.pbCanConfuse?(false)
      opponent.effects[:Confusion]=2+@battle.pbRandom(4)
      @battle.pbCommonAnimation("Confusion",opponent,nil)
      @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
    when :HAUNTED
      if !opponent.effects[:Curse]
        opponent.effects[:Curse]=true
        @battle.pbDisplay(_INTL("{1} laid a curse on {2}!",attacker.pbThis,opponent.pbThis(true)))
      end
    when :COLOSSEUM
      return false if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
    else
      return false if !opponent.pbCanParalyze?(false)
      opponent.pbParalyze(attacker)
      @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
    end
    return true
  end
end

################################################################################
# Always hits. (Feint Attack / Shock Wave / Aura Sphere / Vital Throw / Aerial Ace /
# Shadow Punch / Magical Leaf / Swift / Magnet Bomb / Disarming Voice / Smart Strike /
# False Surrender)
################################################################################
class PokeBattle_Move_0A5 < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    return true
  end
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.FE == :CHESS && @move == :FALSESURRENDER
      if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
        @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from being taunted!"))
      elsif (opponent.ability == :OBLIVIOUS) && !(opponent.moldbroken)
        @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
      elsif !(opponent.effects[:Taunt]>0)
        pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
        opponent.effects[:Taunt]=4
        @battle.pbDisplay(_INTL("{1} fell for the taunt!",opponent.pbThis))
      end
    end
    if (@move == :FALSESURRENDER)
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      opponent.effects[:ProtectNegation]=true if ret>0
      if opponent && !opponent.isFainted? && !opponent.effects[:Protect] 
        opponent.effects[:ProtectNegation]=true
      elsif opponent.effects[:Protect] && opponent.pbOwnSide.protectActive?
        opponent.pbOwnSide.effects[:CraftyShield]=false
        opponent.pbOwnSide.effects[:WideGuard]=false
        opponent.pbOwnSide.effects[:QuickGuard]=false
        opponent.pbOwnSide.effects[:MatBlock]=false
      end
      return ret
    end
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# User's attack next round against the target will definitely hit. (Lock-On / Mind Reader)
################################################################################
class PokeBattle_Move_0A6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:LockOn]=2
    opponent.effects[:LockOnPos]=attacker.index
    @battle.pbDisplay(_INTL("{1} took aim at {2}!",attacker.pbThis,opponent.pbThis(true)))
    if @battle.FE == :PSYTERRAIN && (@move == :MINDREADER)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,2,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Target's evasion stat changes are ignored from now on. (Foresight / Odor Sleuth)
# Normal and Fighting moves have normal effectiveness against the Ghost-type target.
################################################################################
class PokeBattle_Move_0A7 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Foresight]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:Foresight]=true
    @battle.pbDisplay(_INTL("{1} was identified!",opponent.pbThis))
    return 0
  end
end

################################################################################
# Target's evasion stat changes are ignored from now on. (Miracle Eye)
# Psychic moves have normal effectiveness against the Dark-type target.
################################################################################
class PokeBattle_Move_0A8 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:MiracleEye]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:MiracleEye]=true
    @battle.pbDisplay(_INTL("{1} was identified!",opponent.pbThis))
    if @battle.FE == :HOLY || @battle.FE == :FAIRYTALE || @battle.FE == :PSYTERRAIN
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,2,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# This move ignores target's Defense, Special Defense and evasion stat changes.
# (SacredSword / Chip Away / Darkest Lariat)
################################################################################
class PokeBattle_Move_0A9 < PokeBattle_Move
# Handled in superclass, do not edit!
end

################################################################################
# User is protected against moves with the "B" flag this round. (Detect / Protect)
################################################################################
class PokeBattle_Move_0AA < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    baseRate = 3
    baseRate = 2 if @move == :DETECT
    if @battle.pbRandom(65536)<(65536/(baseRate**attacker.effects[:ProtectRate])).floor
      if Rejuv && @move==:SHELTER
        if (([:CORROSIVE,:CORROSIVEMIST,:MURKWATERSURFACE,:FAIRYTALE].include?(@battle.FE) || @battle.ProgressiveFieldCheck(PBFields::CONCERT)) && (@move == :ACIDARMOR)) || # Corro Fields
          (@battle.FE == :FACTORY && (@move == :IRONDEFENSE))
           ret=attacker.pbIncreaseStat(PBStats::DEFENSE,3,abilitymessage:false)
        else
           ret=attacker.pbIncreaseStat(PBStats::DEFENSE,2,abilitymessage:false)
        end
        attacker.effects[:Shelter]=true
        @battle.pbDisplay(_INTL("{1} is sheltering itself from the surrounding!",attacker.pbThis))
      end
      attacker.effects[:Protect]=:Protect
      attacker.effects[:ProtectRate]+=1
      if (@move==:SHELTER)
        @battle.pbAnimation(:WITHDRAW,attacker,opponent,hitnum)
      else
        @battle.pbAnimation(@move,attacker,nil)
      end
      @battle.pbDisplay(_INTL("{1} protected itself!",attacker.pbThis))
      return 0
    else
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end

  # Pester
  def pbAdditionalEffect(attacker,opponent)
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    baseRate = 2
    if @battle.pbRandom(65536)<(65536/(baseRate**attacker.effects[:ProtectRate])).floor
      attacker.effects[:Protect]=:Pester
      attacker.effects[:ProtectRate]+=1
      @battle.pbDisplay(_INTL("{1} got away!",attacker.pbThis))
      return 0
    else
      attacker.effects[:ProtectRate]=0
      return -1
    end
  end
end

################################################################################
# User's side is protected against moves with priority greater than 0 this round. (Quick Guard)
################################################################################
class PokeBattle_Move_0AB < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    attacker.pbOwnSide.effects[:QuickGuard]=true
    attacker.effects[:ProtectRate]+=1
    @battle.pbAnimation(@move,attacker,nil)
    @battle.pbDisplay(_INTL("{1} protected its team!",attacker.pbThis))
    return 0
  end
end

################################################################################
# User's side is protected against moves that target multiple battlers this round. (Wide Guard)
################################################################################
class PokeBattle_Move_0AC < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    attacker.pbOwnSide.effects[:WideGuard]=true
    attacker.pbPartner.effects[:WideGuardUser]=false
    attacker.effects[:WideGuardUser]=true
    attacker.effects[:ProtectRate]+=1
    @battle.pbAnimation(@move,attacker,nil)
    @battle.pbDisplay(_INTL("{1} protected its team!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Ignores target's protections.  If successful, all other moves this round
# ignore them too. (Feint)
################################################################################
class PokeBattle_Move_0AD < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:ProtectNegation]=true if ret>0
    if opponent.pbPartner && !opponent.pbPartner.isFainted? && !opponent.pbPartner.effects[:Protect]
      opponent.pbPartner.effects[:ProtectNegation]=true
    elsif opponent.pbPartner.effects[:Protect] && opponent.pbOwnSide.protectActive?
      opponent.pbOwnSide.effects[:CraftyShield]=false
      opponent.pbOwnSide.effects[:WideGuard]=false
      opponent.pbOwnSide.effects[:QuickGuard]=false
      opponent.pbOwnSide.effects[:MatBlock]=false
    end
    if Rejuv && @battle.FE == :SWAMP  && @move == :ATTACKORDER
      stat = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED].sample
      if opponent.pbCanReduceStatStage?(stat,true)
        opponent.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
      end
    end
    if Rejuv && attacker.crested == :VESPIQUEN && @move == :ATTACKORDER
      if !opponent.isFainted? && opponent.damagestate.calcdamage>0 &&
        !opponent.damagestate.substitute
       if opponent.effects[:MultiTurn]==0
         opponent.effects[:MultiTurn]=4+@battle.pbRandom(2)
         opponent.effects[:MultiTurn]=7 if attacker.hasWorkingItem(:GRIPCLAW)
         opponent.effects[:MultiTurnAttack]=:INFESTATION
         opponent.effects[:MultiTurnUser]=attacker.index
         opponent.effects[:BindingBand] = attacker.hasWorkingItem(:BINDINGBAND)
         @battle.pbDisplay(_INTL("{1} has been afflicted with an infestation by {2}!",opponent.pbThis,attacker.pbThis(true)))
       end
      end
    end
    return ret
  end
end

################################################################################
# Uses the last move that the target used. (Mirror Move)
################################################################################
class PokeBattle_Move_0AE < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.lastMoveUsed.nil? || !opponent.lastMoveUsed.is_a?(Symbol)
      @battle.pbDisplay(_INTL("The mirror move failed!"))
      return -1
    end
    movedata=$cache.moves[opponent.lastMoveUsed]
    if movedata.basedamage <= 0
      @battle.pbDisplay(_INTL("The mirror move failed!"))
      return -1
    end
    if @battle.FE  == :MIRROR
      for stat in [PBStats::SPATK,PBStats::ATTACK,PBStats::ACCURACY]
        if attacker.pbCanIncreaseStatStage?(stat,false)
          attacker.pbIncreaseStat(stat,1,abilitymessage:false)
        end
      end
    end
    if @battle.FE  == :SKY
      for stat in [PBStats::SPATK,PBStats::ATTACK,PBStats::SPEED]
        if attacker.pbCanIncreaseStatStage?(stat,false)
          attacker.pbIncreaseStat(stat,1,abilitymessage:false)
        end
      end
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbUseMoveSimple(opponent.lastMoveUsed,-1,opponent.index)
    return 0
  end
end

################################################################################
# Uses the last move that was used. (Copycat)
################################################################################
class PokeBattle_Move_0AF < PokeBattle_Move
   def pbEffect(attacker, opponent, hitnum=0, alltargets=nil, showanimation=true)
    move = @battle.previousMove
    # TODO: Check Z-Moves
    if !move || !move.is_a?(Symbol) || PBStuff::BLACKLISTS[:COPYCAT].include?(move)
      @battle.pbDisplay(_INTL("The copycat failed!"))
      return -1
    end
    opponent=@battle.battlers[@battle.previousMoveUser]
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbUseMoveSimple(move,-1,-1)
    return 0
  end
end

################################################################################
# Uses the move the target was about to use this round, with 1.5x power. (Me First)
################################################################################
class PokeBattle_Move_0B0 < PokeBattle_Move

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    priorityAttacker = @battle.pbGetPriority(attacker)
    priorityOpponent = @battle.pbGetPriority(opponent)
    count = 0
    # If the opponent's priority is LOWER, that means
    # it attacks BEFORE the attacker
    if priorityOpponent < priorityAttacker
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    else
      moveid = opponent.selectedMove
      # Now we test if the move is valid
      if !moveid || PBStuff::BLACKLISTS[:MEFIRST].include?(moveid) || @battle.zMove.any?{|t1| t1.any?{|t2| t2 == opponent.index}}
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
      movedata = $cache.moves[moveid]
      # if it's equal or less than zero then it's
      # not an attack move
      if movedata.basedamage <= 0
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      else
      # It's greater than zero, so it works.
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      attacker.effects[:MeFirst] = true
      attacker.pbUseMoveSimple(moveid,-1,opponent.index)
      return 0
      end
    end
  end

end

################################################################################
# This round, reflects all moves with the "C" flag targeting the user back at
# their origin. (Magic Coat)
################################################################################
class PokeBattle_Move_0B1 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[:MagicCoat]=true
    @battle.pbDisplay(_INTL("{1} shrouded itself with Magic Coat!",attacker.pbThis))
    return 0
  end
end

################################################################################
# This round, snatches all used moves with the "D" flag. (Snatch)
################################################################################
class PokeBattle_Move_0B2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (@battle.pbGetPriority(attacker)==1 && !@battle.doublebattle) || (@battle.pbGetPriority(attacker)==3 && @battle.doublebattle)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[:Snatch]=true
    @battle.pbDisplay(_INTL("{1} waits for a target to make a move!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Uses a different move depending on the environment. (Nature Power)
################################################################################
class PokeBattle_Move_0B3 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    move=@battle.field.naturePower
    basemovename=getMoveName(@move)
    movename=getMoveName(move)
    @battle.pbDisplay(_INTL("{1} turned into {2}!",basemovename,movename))
    attacker.pbUseMoveSimple(move,-1,opponent.index)
    return 0
  end
end

################################################################################
# Uses a random move the user knows.  Fails if user is not asleep. (Sleep Talk)
################################################################################
class PokeBattle_Move_0B4 < PokeBattle_Move
  def pbCanUseWhileAsleep?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.status!=:SLEEP && (attacker.ability != :COMATOSE || @battle.FE == :ELECTERRAIN)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    attacker.sleeptalkUsed = true
    blacklist = PBStuff::BLACKLISTS[:SLEEPTALK]
    choices = (0...4).to_a.select{|i| (attacker.moves[i].move.is_a?(Symbol)) && !blacklist.include?(attacker.moves[i].move) && @battle.pbCanChooseMove?(attacker.index,i,false,{sleeptalk: true})}
    if choices.length==0
      @battle.pbDisplay(_INTL("But it failed!"))
      attacker.sleeptalkUsed = false
      return -1
    end

    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    choice=choices[@battle.pbRandom(choices.length)]
    if attacker.moves[choice].move == :ACUPRESSURE
       attacker.pbUseMoveSimple(attacker.moves[choice].move,choice,attacker.index)
    else
       attacker.pbUseMoveSimple(attacker.moves[choice].move,choice,attacker.pbOppositeOpposing.index)
    end
    attacker.sleeptalkUsed = false
    return 0
  end
end

################################################################################
# Uses a random move known by any non-user Pokémon in the user's party. (Assist)
################################################################################
class PokeBattle_Move_0B5 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist = PBStuff::BLACKLISTS[:ASSIST]
    moves=[]
    party=@battle.pbParty(attacker.index) # NOTE: pbParty is common to both allies in multi battles
    for i in 0...party.length
      if i != attacker.pokemonIndex && party[i] && !party[i].isEgg?
        for move in party[i].moves
          moveid = move.move
          next if moveid == 0 || blacklist.include?(moveid)
          moves.push(move.move)
        end
      end
    end
    if moves.length==0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    move=moves[@battle.pbRandom(moves.length)]
    attacker.pbUseMoveSimple(move)
    return 0
  end
end

################################################################################
# Uses a random move that exists. (Metronome)
################################################################################
class PokeBattle_Move_0B6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    possiblemoves = []
    for i in $cache.moves.keys
      possiblemoves.push(i) unless PBStuff::BLACKLISTS[:METRONOME].include?(i)
    end
    if @battle.FE == :GLITCH
      possiblemoves = possiblemoves.filter{ |i| $cache.moves[i].basedamage >= 70}
    end
    move = possiblemoves.sample()
    if move
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      if move == :ACUPRESSURE
        # Metronome always targets the user if it calls Acupressure.
        attacker.pbUseMoveSimple(move,-1,attacker.index)
      else
        attacker.pbUseMoveSimple(move)
      end
      return 0
    else
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# The target can no longer use the same move twice in a row. (Torment)
################################################################################
class PokeBattle_Move_0B7 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if opponent.effects[:Torment]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from torment!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:Torment]=true
    @battle.pbDisplay(_INTL("{1} was subjected to torment!",opponent.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if !opponent.effects[:Torment] || (!@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken))
      opponent.effects[:Torment]=true
      @battle.pbDisplay(_INTL("{1} was subjected to torment!",opponent.pbThis))
    end
    return true
  end

  def pbSecondAdditionalEffect(attacker,opponent)
    if @move == :COLDTRUTH
      return false if !opponent.pbCanFrostbite?(false)
      opponent.pbFrostbite(attacker)
      @battle.pbDisplay(_INTL("{1} was frostbitten!",opponent.pbThis))
      return true
    end
    return false
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :COLDTRUTH
      @battle.pbAnimation(:BLIZZARD,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Disables all target's moves that the user also knows. (Imprison)
################################################################################
class PokeBattle_Move_0B8 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:Imprison]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[:Imprison]=true
    @battle.pbDisplay(_INTL("{1} sealed the opponent's move(s)!",attacker.pbThis))
    return 0
  end
end

################################################################################
# For 5 rounds, disables the last move the target used. (Disable)
################################################################################
class PokeBattle_Move_0B9 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Disable]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from disabling!"))
      return -1
    end
    for i in opponent.moves
      if i && $cache.moves[i.move].move==opponent.lastMoveUsed && (i.pp>0 || i.totalpp==0)
        pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
        opponent.effects[:Disable]=4
        opponent.effects[:DisableMove]=opponent.lastMoveUsed
        @battle.pbDisplay(_INTL("{1}'s {2} was disabled!",opponent.pbThis,i.name))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("But it failed!"))
    return -1
  end
end

################################################################################
# For 4 rounds, disables the target's non-damaging moves. (Taunt)
################################################################################
class PokeBattle_Move_0BA < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
   # this was unchanged - just a reference of where the following needs to be placed.
    if opponent.effects[:Taunt]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from being taunted!"))
      return -1
    end
    # UPDATE 11/16/2013
    # Oblivious now protects from taunt
    if (opponent.ability == :OBLIVIOUS) && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:Taunt]=4
    @battle.pbDisplay(_INTL("{1} fell for the taunt!",opponent.pbThis))
    return 0
  end
end

################################################################################
# For 5 rounds, disables the target's healing moves. (Heal Block)
################################################################################
class PokeBattle_Move_0BB < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if opponent.effects[:HealBlock]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from being blocked!"))
      return -1
    end
    pbShowAnimation(:PSYBEAM,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:HealBlock]=5
    @battle.pbDisplay(_INTL("{1} was prevented from healing!",opponent.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.effects[:HealBlock]>0
      return false
    end
    opponent.effects[:HealBlock]=2
    @battle.pbDisplay(_INTL("{1} was prevented from healing!",opponent.pbThis))
    return true
  end

end

################################################################################
# For 4 rounds, the target must use the same move each round. (Encore)
################################################################################
class PokeBattle_Move_0BC < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist = PBStuff::BLACKLISTS[:ENCORE]
    move = opponent.lastMoveUsed
    if opponent.effects[:Encore]>0 || blacklist.include?(move)  || !move.is_a?(Symbol) 
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if !@battle.pbCheckSideAbility(:AROMAVEIL,opponent).nil? && !opponent.moldbroken
      @battle.pbDisplay(_INTL("The Aroma Veil protects #{opponent.pbThis} from the encore!"))
      return -1
    end

    # First check if their last choice matches the encore'd move.
    moveIndex = opponent.lastMoveChoice[1]
    # Just to be safe, if it doesn't match, find it manually.
    if opponent.moves[moveIndex].move != move
      found = false
      for i in 0...4
        if move==opponent.moves[i]
          found = true
          moveIndex = i
          break
        end
      end
      if !found
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
    end
    # Once it's found, make sure it has PP.
    if opponent.moves[moveIndex].pp == 0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end

    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.FE == :BIGTOP || @battle.ProgressiveFieldCheck(PBFields::CONCERT)
      opponent.effects[:Encore] = 7
      opponent.effects[:Encore] = 8 if opponent.hasMovedThisRound?

    else
      opponent.effects[:Encore] = 3
      opponent.effects[:Encore] = 4 if opponent.hasMovedThisRound?
    end
    opponent.effects[:EncoreIndex] = moveIndex
    opponent.effects[:EncoreMove] = move
    @battle.pbDisplay(_INTL("{1} received an encore!",opponent.pbThis))
    return 0
  end
end

################################################################################
# Hits twice. (Gear Grind / Double Hit / Double Kick / Dual Chop / Bonemerang)
################################################################################
class PokeBattle_Move_0BD < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
      return 2
  end
end

################################################################################
# Hits twice.  May poison the targer on each hit. (Twineedle)
################################################################################
class PokeBattle_Move_0BE < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 2
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanPoison?(false)
    opponent.pbPoison(attacker)
    @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
    return true
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
end

################################################################################
# Hits 2-5 times. (Pin Missile / Arm Thrust / Bullet Seed / Bone Rush / Icicle Spear /
# Tail Slap / Spike Cannon / Fury Swipes / barrage / Double Slap / Fury Attack / 
# Rock Blast / Water Shuriken)
################################################################################
class PokeBattle_Move_0C0 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    hitchances=[2,2,3,3,4,5]
    ret=hitchances[@battle.pbRandom(hitchances.length)]
    ret=5 if attacker.ability == :SKILLLINK
    ret=5 if attacker.crested == :FEAROW && @move == :FURYATTACK
    ret= hitchances*2 if @move == :CANNONADE
    return ret
  end

  def pbAdditionalEffect(attacker,opponent)
    if @move == :CANNONADE
      if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,false)
        opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
      end
      return true
    end
    return false
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :MUDBARRAGE
      @battle.pbAnimation(:MUDSLAP,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Hits X times, where X is the number of unfainted status-free Pokémon in the
# user's party (the participants).  Fails if X is 0.
# Base power of each hit depends on the base Attack stat for the species of that
# hit's participant. (Beat Up)
################################################################################
class PokeBattle_Move_0C1 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    if @participants.nil?
      @participants = @battle.pbPartySingleOwner(attacker.index).find_all {|mon| mon && !mon.isEgg? && mon.hp>0 && mon.status.nil?}
    end
    return @participants.length
  end

  def pbOnStartUse(attacker)
    party=@battle.pbParty(attacker.index)
    @participants = @battle.pbPartySingleOwner(attacker.index).find_all {|mon| mon && !mon.isEgg? && mon.hp>0 && mon.status.nil?}
    if @participants.length==0
      @battle.pbDisplay(_INTL("But it failed!"))
      return false
    end
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    mon=@participants.shift
    atk=mon.baseStats[1]
    return 5+(atk/10)
  end
end

################################################################################
# Two turn attack.  Attacks first turn, skips second turn (if successful).
# (Roar of Time / Blast Burn / Frenzy Plant / Giga Impact / Hyper Beam / Rock Wrecker /
# Hydro Cannon / Prismatic Laser / Meteor Assault / Eternabeam)
################################################################################
class PokeBattle_Move_0C2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && (attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0)
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif opponent.damagestate.calcdamage>0 && opponent.anabolic
      opponent.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif opponent.damagestate.calcdamage>0 && !(@battle.FE == :STARLIGHT && @move ==:METEORASSAULT) && 
      !(attacker.crested == :CLAYDOL && [:HYPERBEAM,:PRISMATICLASER,:ETERNABEAM].include?(@move))
      attacker.effects[:HyperBeam]=2
      attacker.currentMove=@move
    end
    return ret
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn. (Razor Wind)
################################################################################
class PokeBattle_Move_0C3 < PokeBattle_Move
  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
       @immediate = true if @battle.FE == :CLOUDS || @battle.FE == :SKY || (Rejuv && @battle.FE == :GRASSY) || (@battle.state.effects[:GRASSY] > 0)
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (@immediate || attacker.effects[:TwoTurnAttack]!=0) && showanimation==true
      @battle.pbCommonAnimation("Razor Wind charging",attacker,nil)
      @battle.pbDisplay(_INTL("{1} whipped up a whirlwind!",attacker.pbThis))
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn. (Solar Beam / Solar Blade)
# Power halved in all weather except sunshine.  In sunshine, takes 1 turn instead.
################################################################################
class PokeBattle_Move_0C4 < PokeBattle_Move
  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
      @immediate=true if (@battle.pbWeather== :SUNNYDAY)
      @immediate=true if @battle.FE == :RAINBOW
      @immediate=true if (attacker.crested == :CLAYDOL && @move == :SOLARBEAM)
      @immediate=true if (attacker.crested == :CHERRIM)
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
      attacker.anabolic = false
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    if @battle.pbWeather!=0 &&
       @battle.pbWeather!=:SUNNYDAY && !(attacker.crested == :CHERRIM)
      return (damagemult*0.5).round
    end
    return damagemult
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Solar Beam charging",attacker,nil)
      @battle.pbDisplay(_INTL("{1} took in sunlight!",attacker.pbThis))
    end
     if @battle.FE == :DARKCRYSTALCAVERN && @battle.pbWeather != :SUNNYDAY && !(attacker.crested == :CHERRIM)
        @battle.pbDisplay(_INTL("But it failed...",attacker.pbThis))
        attacker.effects[:TwoTurnAttack]=0
      return 0
      else
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    return super
    end
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn.
# May paralyze the target. (Freeze Shock)
################################################################################
class PokeBattle_Move_0C5 < PokeBattle_Move
  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
      @immediate=true if (@battle.FE == :FROZENDIMENSION)
      @immediate=true if (@battle.pbWeather == :HAIL)
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Freeze Shock charging",attacker,nil)
      @battle.pbDisplay(_INTL("{1} became cloaked in a freezing light!",attacker.pbThis))
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    return super
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanParalyze?(false)
    opponent.pbParalyze(attacker)
    @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!",opponent.pbThis))
    return true
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn.
# May burn the target. (Ice Burn)
################################################################################
class PokeBattle_Move_0C6 < PokeBattle_Move
  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
      @immediate=true if (@battle.FE == :FROZENDIMENSION)
      @immediate=true if (@battle.pbWeather == :HAIL)
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Ice Burn charging",attacker,nil)
      @battle.pbDisplay(_INTL("{1} became cloaked in freezing air!",attacker.pbThis))
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    return super
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanBurn?(false)
    opponent.pbBurn(attacker)
    @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
    return true
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn.
# May make the target flinch. (Sky Attack)
################################################################################
class PokeBattle_Move_0C7 < PokeBattle_Move
  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
      @immediate = true if @battle.FE == :CLOUDS || @battle.FE == :SKY
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Sky Attack charging",attacker,nil)
      @battle.pbDisplay(_INTL("{1} is glowing!",attacker.pbThis))
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    return super
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute
      opponent.effects[:Flinch]=true
      return true
    end
    return false
  end
end

################################################################################
# Two turn attack.  Ups user's Defence by 1 stage first turn, attacks second turn. (Skull Bash)
################################################################################
class PokeBattle_Move_0C8 < PokeBattle_Move
  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Skull Bash charging",attacker,nil)
      @battle.pbDisplay(_INTL("{1} lowered its head!",attacker.pbThis))
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
      end
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    return super
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn.  (Fly)
# (Handled in Battler's pbSuccessCheck):  Is semi-invulnerable during use.
################################################################################
class PokeBattle_Move_0C9 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return @battle.state.effects[:Gravity]!=0 && attacker.ability != :GRAVFLUX
  end

  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
      @immediate = true if @battle.FE == :CLOUDS || @battle.FE == :CAVE || @battle.FE == :SKY || (Rejuv && battle.FE == :DRAGONSDEN)
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.state.effects[:Gravity]!=0 && attacker.ability != :GRAVFLUX
      @battle.pbDisplay(_INTL("But it failed!"))
      attacker.effects[:TwoTurnAttack] = 0
      return -1
    end
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Fly charging",attacker,nil)
      @battle.scene.pbVanishSprite(attacker)
      @battle.pbDisplay(_INTL("{1} flew up high!",attacker.pbThis))
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    #@battle.scene.pbUnVanishSprite(attacker)
    return super
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn.  (Dig)
# (Handled in Battler's pbSuccessCheck):  Is semi-invulnerable during use.
################################################################################
class PokeBattle_Move_0CA < PokeBattle_Move

  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
      @immediate=true if Rejuv && (@battle.FE == :DESERT || @battle.FE == :CAVE)
      @immediate=true if (@battle.FE == :WATERSURFACE || @battle.FE == :MURKWATERSURFACE) && self.pbType(attacker,self.type) == :GROUND # for move failure on these fields
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Dig charging",attacker,nil)
      @battle.scene.pbVanishSprite(attacker)
      @battle.scene.pbDisableShadowTemp(attacker)
      @battle.pbDisplay(_INTL("{1} burrowed its way under the ground!",attacker.pbThis))
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    @battle.scene.pbReAbleShadow(attacker)
    #@battle.scene.pbUnVanishSprite(attacker)
    return super
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn.  (Dive)
# (Handled in Battler's pbSuccessCheck):  Is semi-invulnerable during use.
################################################################################
class PokeBattle_Move_0CB < PokeBattle_Move
  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
      @immediate=true if (@battle.FE == :WATERSURFACE || @battle.FE == :UNDERWATER)
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      if Rejuv && @battle.FE == :ICY && [:WATERSURFACE,:MURKWATERSURFACE].include?(@battle.field.backup)
        pbShowAnimation(:SPLASH,attacker,nil,hitnum,alltargets,showanimation)
        if attacker==@battle.battlers[0] || attacker==@battle.battlers[2]
          @battle.pbApplySceneBG("playerbase","Graphics/Battlebacks/playerbaseWater.png")
        elsif attacker==@battle.battlers[1] || attacker==@battle.battlers[3]
          @battle.pbApplySceneBG("enemybase","Graphics/Battlebacks/enemybaseWater.png")
        end
        @battle.pbDisplay(_INTL("{1} made a hole in the ice!",attacker.pbThis))        
      end  
      @battle.pbCommonAnimation("Dive charging",attacker,nil)
      @battle.scene.pbVanishSprite(attacker)
      @battle.scene.pbDisableShadowTemp(attacker)
      @battle.pbDisplay(_INTL("{1} hid underwater!",attacker.pbThis))
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    @battle.scene.pbReAbleShadow(attacker)
    @battle.field.counter=3 if Rejuv && @battle.FE == :ICY
    return super
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn.  (Bounce)
# May paralyze the target.
# (Handled in Battler's pbSuccessCheck):  Is semi-invulnerable during use.
################################################################################
class PokeBattle_Move_0CC < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return @battle.state.effects[:Gravity]!=0 && attacker.ability != :GRAVFLUX
  end

  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
      @immediate = true if @battle.FE == :CLOUDS || @battle.FE == :CAVE || @battle.FE == :SKY || (Rejuv && @battle.FE == :DRAGONSDEN)
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.state.effects[:Gravity]!=0 && attacker.ability != :GRAVFLUX
      @battle.pbDisplay(_INTL("But it failed!"))
      attacker.effects[:TwoTurnAttack] = 0
      return -1
    end
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Bounce charging",attacker,nil)
      @battle.scene.pbVanishSprite(attacker)
      @battle.scene.pbDisableShadowTemp(attacker)
      @battle.pbDisplay(_INTL("{1} sprang up!",attacker.pbThis))
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    @battle.scene.pbReAbleShadow(attacker)
    return super
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanParalyze?(false)
    opponent.pbParalyze(attacker)
    @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!",opponent.pbThis))
    return true
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn.  (Shadow Force / Phantom Force)
# Is invulnerable during use.
# If successful, negates target's Detect and Protect this round.
################################################################################
class PokeBattle_Move_0CD < PokeBattle_Move
  def pbTwoTurnAttack(attacker,checking=false)
    @immediate=false
    if attacker.effects[:TwoTurnAttack]==0
      @immediate=true if @battle.FE == :HAUNTED || @battle.ProgressiveFieldCheck(PBFields::DARKNESS,2,3)
    end
    if attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      if !checking
        itemname=getItemName(attacker.item)
        attacker.pbDisposeItem(false)
        @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
      end
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Shadow Force charging",attacker,nil)
      @battle.scene.pbVanishSprite(attacker)
      @battle.pbDisplay(_INTL("{1} vanished instantly!",attacker.pbThis))
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    #@battle.scene.pbUnVanishSprite(attacker)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:ProtectNegation]=true if ret>0
    if opponent && !opponent.isFainted? && !opponent.effects[:Protect] 
      opponent.effects[:ProtectNegation]=true
    elsif opponent.effects[:Protect] && opponent.pbOwnSide.protectActive?
      opponent.pbOwnSide.effects[:CraftyShield]=false
      opponent.pbOwnSide.effects[:WideGuard]=false
      opponent.pbOwnSide.effects[:QuickGuard]=false
      opponent.pbOwnSide.effects[:MatBlock]=false
    end
    return ret
  end
end

################################################################################
# Two turn attack.  Skips first turn, attacks second turn.  (Sky Drop)
# (Handled in Battler's pbSuccessCheck):  Is semi-invulnerable during use.
# Target is also semi-invulnerable during use, and can't take any action.
# Doesn't damage airborne Pokémon (but still makes them unable to move during).
################################################################################
class PokeBattle_Move_0CE < PokeBattle_Move
  def pbTwoTurnAttack(attacker,checking=false)
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.nil?
      @battle.pbDisplay(_INTL("But it failed!"))
      attacker.effects[:TwoTurnAttack] = 0
      attacker.effects[:SkyDroppee] = nil
      return -1
    end
    if opponent.weight > 2000
      @battle.pbDisplay(_INTL("The opposing {1} is too heavy to be lifted!", opponent.pbThis))
      attacker.effects[:TwoTurnAttack] = 0
      attacker.effects[:SkyDroppee] = nil
      return -1
    end
    if opponent.effects[:TwoTurnAttack] > 0
      @battle.pbDisplay(_INTL("But it failed!"))
      attacker.effects[:TwoTurnAttack] = 0
      attacker.effects[:SkyDroppee] = nil
      return -1
    end
    if opponent.effects[:Protect] 
      @battle.pbDisplay(_INTL("But it failed!"))
      attacker.effects[:TwoTurnAttack] = 0
      attacker.effects[:SkyDroppee] = nil
      return -1
    end
    if opponent.effects[:Substitute] > 0
      @battle.pbDisplay(_INTL("But it failed!"))
      attacker.effects[:TwoTurnAttack] = 0
      attacker.effects[:SkyDroppee] = nil
      return -1
    end
    if @battle.state.effects[:Gravity]!=0 && attacker.ability != :GRAVFLUX
      @battle.pbDisplay(_INTL("But it failed!"))
      attacker.effects[:TwoTurnAttack] = 0
      attacker.effects[:SkyDroppee] = nil
      return -1
    end
    if @battle.FE==:CAVE
      @battle.pbDisplay(_INTL("The cave's low ceiling makes flying high impossible!"))
      attacker.effects[:TwoTurnAttack] = 0
      attacker.effects[:SkyDroppee] = nil
      return -1
    end
    if attacker.effects[:TwoTurnAttack]!=0
      if opponent.effects[:SkyDrop]
        attacker.effects[:TwoTurnAttack] = 0
        attacker.effects[:SkyDroppee] = nil
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
      @battle.pbCommonAnimation("Sky Drop charging",attacker,opponent)
      @battle.scene.pbVanishSprite(attacker)
      @battle.scene.pbVanishSprite(opponent)
      @battle.pbDisplay(_INTL("{1} took {2} into the sky!",attacker.pbThis, opponent.pbThis))
      @battle.pbClearChoices(opponent.index)
      attacker.effects[:SkyDroppee] = opponent
      opponent.effects[:SkyDrop] = true
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    #@battle.scene.pbUnVanishSprite(attacker)
    #@battle.scene.pbUnVanishSprite(opponent)
    if opponent.hasType?(:FLYING) && opponent.effects[:SkyDrop]
      opponent.effects[:TwoTurnAttack] = 0
      opponent.effects[:SkyDrop]       = false
      @battle.pbDisplay(_INTL("It doesn't affect {1}...", opponent.pbThis))
      return -1
    end
    ret = super
    @battle.pbDisplay(_INTL("{1} is freed from Sky Drop effect!",opponent.pbThis))
    opponent.effects[:SkyDrop] = false
    attacker.effects[:SkyDroppee] = nil
    return ret
  end
end

################################################################################
# Trapping move.  Traps for 4 or 5 rounds.  Trapped Pokémon lose 1/16 of max HP
# at end of each round. (Magma Storm / Fire Spin / Sand Tomb / Bind / Wrap / Clamp /
# Infestation / Snap Trap / Thunder Cage)
################################################################################
class PokeBattle_Move_0CF < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !opponent.isFainted? && opponent.damagestate.calcdamage>0 &&
       !opponent.damagestate.substitute
      if opponent.effects[:MultiTurn]==0
        opponent.effects[:MultiTurn]=4+@battle.pbRandom(2)
        opponent.effects[:MultiTurn]=7 if attacker.hasWorkingItem(:GRIPCLAW)
        opponent.effects[:MultiTurnAttack]=@move
        opponent.effects[:MultiTurnUser]=attacker.index
        opponent.effects[:BindingBand] = attacker.hasWorkingItem(:BINDINGBAND)
        case @move
        when :BIND then @battle.pbDisplay(_INTL("{1} was squeezed by {2}!",opponent.pbThis,attacker.pbThis(true)))
        when :CLAMP then @battle.pbDisplay(_INTL("{1} clamped {2}!",attacker.pbThis,opponent.pbThis(true)))
        when :FIRESPIN then @battle.pbDisplay(_INTL("{1} was trapped in the vortex!",opponent.pbThis))
        when :MAGMASTORM then @battle.pbDisplay(_INTL("{1} was trapped by Magma Storm!",opponent.pbThis))
        when :SANDTOMB then @battle.pbDisplay(_INTL("{1} was trapped by Sand Tomb!",opponent.pbThis))
        when :WRAP then @battle.pbDisplay(_INTL("{1} was wrapped by {2}!",opponent.pbThis,attacker.pbThis(true)))
        when :INFESTATION then @battle.pbDisplay(_INTL("{1} has been afflicted with an infestation by {2}!",opponent.pbThis,attacker.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("{1} was trapped in the vortex!",opponent.pbThis))
        end
      end
    end
    return ret
  end
end

################################################################################
# Trapping move- Whirlpool specific.  Traps for 4 or 5 rounds.  Trapped Pokémon lose 1/16 of max HP
# at end of each round. (Whirlpool)
# Power is doubled if target is using Dive.
# (Handled in Battler's pbSuccessCheck): Hits some semi-invulnerable targets.
################################################################################
class PokeBattle_Move_0D0 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !opponent.isFainted? && opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute
      if opponent.effects[:MultiTurn]==0
        opponent.effects[:MultiTurn]=4+@battle.pbRandom(2)
        opponent.effects[:MultiTurn]=5 if attacker.hasWorkingItem(:GRIPCLAW)
        opponent.effects[:MultiTurnAttack]=@move
        opponent.effects[:MultiTurnUser]=attacker.index
        @battle.pbDisplay(_INTL("{1} was trapped in the vortex!",opponent.pbThis))
      end
      if (!Rejuv && @battle.FE == :WATERSURFACE) || @battle.FE == :UNDERWATER
        if opponent.pbCanConfuse?(false)
          opponent.effects[:Confusion]=2+@battle.pbRandom(4)
          @battle.pbCommonAnimation("Confusion",opponent,nil)
          @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
        end
      end
    end
    return ret
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    damagemult*= 2.0 if !$cache.moves[opponent.effects[:TwoTurnAttack]].nil? && 
    $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCB # Dive
    return damagemult
  end
end

################################################################################
# User must use this move for 2 more rounds.  No battlers can sleep. (Uproar)
################################################################################
class PokeBattle_Move_0D1 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.effects[:Uproar]==0
        attacker.effects[:Uproar]=3
        @battle.pbDisplay(_INTL("{1} caused an uproar!",attacker.pbThis))
        attacker.currentMove=@move
      end
    end
    return ret
  end
end

################################################################################
# User must use this move for 1 or 2 more rounds.  At end, user becomes confused.
# (Outrage / Petal Dance / Thrash / Raging Fury)
################################################################################
class PokeBattle_Move_0D2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && attacker.effects[:Outrage]==0 && attacker.status!=:SLEEP  #TODO: Not likely what actually happens, but good enough
      if attacker.ability == :PARENTALBOND
        attacker.effects[:Outrage]=4+(@battle.pbRandom(2)*2)
      elsif attacker.crested == :HYDREIGON
        attacker.effects[:Outrage]=4+(@battle.pbRandom(2)*3)
      else
        attacker.effects[:Outrage]=2+@battle.pbRandom(2)
      end
      if @battle.FE == :SUPERHEATED || @battle.FE == :VOLCANICTOP
        attacker.effects[:Outrage]=1
      end
      attacker.currentMove=@move
    elsif pbTypeModifier(@type,attacker,opponent)==0
      # Cancel effect if attack is ineffective
      attacker.effects[:Outrage]=0
    end
    if attacker.effects[:Outrage]>0
      attacker.effects[:Outrage]-=1
      if attacker.effects[:Outrage]==0 && attacker.pbCanConfuseSelf?(false) && 
        !((@battle.FE == :VOLCANIC || @battle.FE == :VOLCANICTOP) && @move==:RAGINGFURY)
        attacker.effects[:Confusion]=2+@battle.pbRandom(4)
        @battle.pbCommonAnimation("Confusion",attacker,nil)
        @battle.pbDisplay(_INTL("{1} became confused due to fatigue!",attacker.pbThis))
      end
    end
    return ret
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :RAGINGFURY
      @battle.pbAnimation(:OUTRAGE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# User must use this move for 4 more rounds.  Power doubles each round.
# Power is also doubled if user has curled up. (Rollout / Ice Ball)
################################################################################
class PokeBattle_Move_0D3 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    shift=(4-attacker.effects[:Rollout]) # from 0 through 4, 0 is most powerful
    shift+=1 if attacker.effects[:DefenseCurl]
    basedmg=basedmg<<shift
    return basedmg
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    attacker.effects[:Rollout]=5 if attacker.effects[:Rollout]==0
    attacker.effects[:Rollout]-=1
    attacker.currentMove=basemove.move
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage==0 ||
       pbTypeModifier(@type,attacker,opponent)==0 ||
       attacker.status== :SLEEP  #TODO: Not likely what actually happens, but good enough
      # Cancel effect if attack is ineffective
      attacker.effects[:Rollout]=0
    end
    return ret
  end
end

################################################################################
# User bides its time this round and next round.  The round after, deals 2x the
# total damage it took while biding to the last battler that damaged it. (Bide)
################################################################################
class PokeBattle_Move_0D4 < PokeBattle_Move
  def pbDisplayUseMessage(attacker,choice)
    if attacker.effects[:Bide]==0
      @battle.pbDisplayBrief(_INTL("{1} used\r\n{2}!",attacker.pbThis,getMoveUseName))
      attacker.effects[:Bide]=2
      attacker.effects[:BideDamage]=0
      attacker.effects[:BideTarget]=-1
      attacker.currentMove=@move
      #pbShowAnimation(@move,attacker,nil)
      @battle.pbCommonAnimation("Bide",attacker,nil)
      return 1
    else
      attacker.effects[:Bide]-=1
      if attacker.effects[:Bide]==0
        @battle.pbDisplayBrief(_INTL("{1} unleashed energy!",attacker.pbThis))
        return 0
      else
        @battle.pbDisplayBrief(_INTL("{1} is storing energy!",attacker.pbThis))
        @battle.pbCommonAnimation("Bide",attacker,nil)
        return 2
      end
    end
  end

  def pbAddTarget(targets,attacker)
    if attacker.effects[:BideTarget]>=0
      if !attacker.pbAddTarget(targets,@battle.battlers[attacker.effects[:BideTarget]])
        attacker.pbRandomTarget(targets)
      end
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:BideDamage]==0 || !opponent
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    ret=pbEffectFixedDamage(attacker.effects[:BideDamage]*2,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[:BideDamage]=0
    return ret
  end
end

################################################################################
# Heals user by 1/2 of its max HP. (Heal Order / Milk Drink / recover / Slack Off / Soft-Boiled)
################################################################################
class PokeBattle_Move_0D5 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp && (attacker.crested != :VESPIQUEN)
      @battle.pbDisplay(_INTL("{1}'s HP is full!",attacker.pbThis))
      return -1
    elsif attacker.crested == :VESPIQUEN && attacker.hp==attacker.totalhp && attacker.pbPartner.hp==attacker.pbPartner.totalhp &&
          attacker.status == nil && attacker.pbPartner.status == nil
      @battle.pbDisplay(_INTL("But everyone is healthy!"))
      return -1
    end
    if (attacker.hp!=attacker.totalhp)
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      if @battle.FE == :FOREST && (@move == :HEALORDER)
        attacker.pbRecoverHP(((attacker.totalhp+1) * 0.66).floor,true)
      else
        attacker.pbRecoverHP(((attacker.totalhp+1)/2).floor,true)
      end
      @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbThis))
    end
    
    if (@move == :HEALORDER && attacker.species == :VESPIQUEN)
      t=attacker.status
      if (t != nil)
        pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      end
      attacker.status=nil
      attacker.statusCount=0
      if t== :BURN
        @battle.pbDisplay(_INTL("{1} was cured of its burn.",attacker.pbThis))
      elsif t== :POISON
        @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",attacker.pbThis))
      elsif t== :PARALYSIS
        @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",attacker.pbThis))
      elsif t== :FROSTBITE
        @battle.pbDisplay(_INTL("{1} was cured of its frostbite.",attacker.pbThis))
      end
      if (attacker.crested == :VESPIQUEN && !attacker.pbPartner.isFainted?)
        if attacker.pbPartner.hp != attacker.pbPartner.totalhp
          pbShowAnimation(@move,attacker.pbPartner,nil,hitnum,alltargets,showanimation)
          partnerHpGain = ((attacker.pbPartner.totalhp+1)/2).floor
          attacker.pbPartner.pbRecoverHP(partnerHpGain,true)
          @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbPartner.pbThis))
        end
        t=attacker.pbPartner.status
        if (t != nil)
          pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
        end
        attacker.pbPartner.status=nil
        attacker.pbPartner.statusCount=0
        if t == :BURN
          @battle.pbDisplay(_INTL("{1} was cured of its burn.",attacker.pbPartner.pbThis))
        elsif t== :POISON
          @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",attacker.pbPartner.pbThis))
        elsif t== :PARALYSIS
          @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",attacker.pbPartner.pbThis))
        elsif t== :FROSTBITE
          @battle.pbDisplay(_INTL("{1} was cured of its frostbite.",attacker.pbPartner.pbThis))
        end
      end
    end
    return 0
  end
end

################################################################################
# Heals user by 1/2 of its max HP. (Roost)
# User roosts, and its Flying type is ignored for attacks used against it.
################################################################################
class PokeBattle_Move_0D6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("{1}'s HP is full!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbRecoverHP(((attacker.totalhp+1)/2).floor,true)
    attacker.effects[:Roost]=true
    @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbThis))
    return 0
  end
end

################################################################################
# Battler in user's position is healed by 1/2 of its max HP, at the end of the
# next round. (Wish)
################################################################################
class PokeBattle_Move_0D7 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:Wish]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[:Wish]=2
    if (@battle.FE == :MISTY || @battle.FE == :RAINBOW || @battle.FE == :HOLY || @battle.FE == :FAIRYTALE || @battle.FE == :STARLIGHT)
      attacker.effects[:WishAmount]=((attacker.totalhp+1)*0.75).floor
    else
      attacker.effects[:WishAmount]=((attacker.totalhp+1)/2).floor
    end
    attacker.effects[:WishMaker]=attacker.pokemonIndex
    if @battle.FE==:DARKNESS1
      attacker.pbRecoverHP(attacker.effects[:WishAmount],true)
      attacker.effects[:Wish]=0
    end
    return 0
  end
end

################################################################################
# Heals user by an amount depending on the weather. (Synthesis / Moonlight / Morning Sun)
################################################################################
class PokeBattle_Move_0D8 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("{1}'s HP is full!",attacker.pbThis))
      return -1
    end
    hpgain=0
    if ([:DARKCRYSTALCAVERN,:STARLIGHT,:NEWWORLD,:BEWITCHED].include?(@battle.FE) && (@move == :MOONLIGHT)) || (Rejuv && @battle.FE == :GRASSY && @move == :SYNTHESIS)
      hpgain=(attacker.totalhp*3/4.0).floor
    elsif @battle.FE == :DARKNESS1 && @move == :MOONLIGHT
        hpgain=(attacker.totalhp*0.4).floor
    elsif ((@battle.FE == :DARKCRYSTALCAVERN || @battle.FE == :DARKNESS2) && @move != :MOONLIGHT)
      hpgain=(attacker.totalhp/4.0).floor
    elsif @battle.FE == :DARKNESS3 && @move != :MOONLIGHT
      hpgain=(attacker.totalhp/8.0).floor
    else
      if (@battle.pbWeather== :SUNNYDAY) || (attacker.crested == :CHERRIM)
        hpgain=(attacker.totalhp*2/3.0).floor
      elsif (@battle.pbWeather!=0)
        hpgain=(attacker.totalhp/4.0).floor
      else
        hpgain=(attacker.totalhp/2.0).floor
      end
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbRecoverHP(hpgain,true)
    @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbThis))
    return 0
  end
end

################################################################################
# Heals user to full HP.  User falls asleep for 2 more rounds. (Rest)
################################################################################
class PokeBattle_Move_0D9 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.status == :SLEEP && attacker.sleeptalkUsed && Rejuv && @battle.FE == :GLITCH
     # @battle.pbDisplay(_INTL("Stall is pure!"))
    elsif !attacker.pbCanSleep?(false,true,true) || attacker.status== :SLEEP
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("{1}'s HP is full!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if @battle.ProgressiveFieldCheck(PBFields::DARKNESS,2,3)
      attacker.pbSleepSelf(4)
    elsif @battle.FE == :CROWD
      attacker.pbSleepSelf(1)
    else
      attacker.pbSleepSelf(3)
    end
    @battle.pbDisplay(_INTL("{1} slept and became healthy!",attacker.pbThis))
    hp=attacker.pbRecoverHP(attacker.totalhp-attacker.hp,true)
    @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbThis)) if hp>0
    return 0
  end
end

################################################################################
# Rings the user.  Ringed Pokémon gain 1/16 of max HP at the end of each round. (Aqua Ring)
################################################################################
class PokeBattle_Move_0DA < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:AquaRing]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[:AquaRing]=true
    @battle.pbDisplay(_INTL("{1} surrounded itself with a veil of water!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Ingrains the user.  Ingrained Pokémon gain 1/16 of max HP at the end of each
# round, and cannot flee or switch out. (Ingrain)
################################################################################
class PokeBattle_Move_0DB < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:Ingrain]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[:Ingrain]=true
    @battle.pbDisplay(_INTL("{1} planted its roots!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Seeds the target.  Seeded Pokémon lose 1/8 of max HP at the end of each
# round, and the Pokémon in the user's position gains the same amount. (Leech Seed)
################################################################################
class PokeBattle_Move_0DC < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (@basedamage > 0)
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      return -1 if ret == -1
      if (!(opponent.effects[:LeechSeed] >= 0) && !(opponent.effects[:Substitute]>0) && !opponent.hasType?(:GRASS))
        pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
        opponent.effects[:LeechSeed]=attacker.index
        @battle.pbDisplay(_INTL("{1} was seeded!",opponent.pbThis))
      end
      return 0
    end
    if opponent.effects[:LeechSeed]>=0 || opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("{1} evaded the attack!",opponent.pbThis))
      return -1
    end
    if opponent.hasType?(:GRASS)
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",opponent.pbThis(true)))
      return -1
    end
    #Now handled elsewhere
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:LeechSeed]=attacker.index
    @battle.pbDisplay(_INTL("{1} was seeded!",opponent.pbThis))
    return 0
  end
end

################################################################################
# User gains half the HP it inflicts as damage. (Leech Life / Drain Punch / Giga Drain /
# Horn Leech / Mega Drain / Absorb / Parabolic Charge)
################################################################################
class PokeBattle_Move_0DD < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      hpgain=((opponent.damagestate.hplost+1)/2).floor
      hpgain=((opponent.damagestate.hplost+1)*3/4).floor if Rejuv && @battle.FE == :ELECTERRAIN && @move == :PARABOLICCHARGE
      hpgain=((opponent.damagestate.hplost+1)*3/4).floor if Rejuv && @battle.FE == :GRASSY && [:ABSORB,:MEGADRAIN,:GIGADRAIN,:HORNLEECH].include?(@move)
      if opponent.ability == :LIQUIDOOZE
        hpgain*=2 if @battle.FE == :WASTELAND || @battle.FE == :MURKWATERSURFACE || @battle.FE == :CORRUPTED
        attacker.pbReduceHP(hpgain,true)
        @battle.pbDisplay(_INTL("{1} sucked up the liquid ooze!",attacker.pbThis))
      else
        if Rejuv && @battle.FE == :GRASSY
          hpgain=(hpgain*1.6).floor if attacker.hasWorkingItem(:BIGROOT)
        else
          hpgain=(hpgain*1.3).floor if attacker.hasWorkingItem(:BIGROOT)
        end
        hpgain=(hpgain*1.3).floor if attacker.crested == :SHIINOTIC
        attacker.pbRecoverHP(hpgain,true)
        @battle.pbDisplay(_INTL("{1} had its energy drained!",opponent.pbThis))
      end
      if Rejuv && @battle.FE == :SWAMP 
        stat = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED].sample
        if opponent.pbCanReduceStatStage?(stat,true)
          opponent.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
        end
      end
    end
    return ret
  end

  def pbAdditionalEffect(attacker,opponent)
    if @move == :MATCHAGOTCHA && opponent.pbCanBurn?(false)
      opponent.pbBurn
      @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
      return true
    end
    return false
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :MATCHAGOTCHA
      @battle.pbAnimation(:GIGADRAIN,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# User gains half the HP it inflicts as damage. (Dream Eater)
# (Handled in Battler's pbSuccessCheck): Fails if target is not asleep.
################################################################################
class PokeBattle_Move_0DE < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      hpgain=((opponent.damagestate.hplost+1)/2).floor
      if Rejuv && @battle.FE == :GRASSY
        hpgain=(hpgain*1.6).floor if attacker.hasWorkingItem(:BIGROOT)
      else
        hpgain=(hpgain*1.3).floor if attacker.hasWorkingItem(:BIGROOT)
      end
      hpgain=(hpgain*1.3).floor if attacker.crested == :SHIINOTIC
      hpgain=(hpgain*2).floor if attacker.crested == :DARKRAI
      attacker.pbRecoverHP(hpgain,true)
      @battle.pbDisplay(_INTL("{1} had its energy drained!",opponent.pbThis))
    end
    return ret
  end
end

################################################################################
# Heals target by 1/2 of its max HP. (Heal Pulse)
################################################################################
class PokeBattle_Move_0DF < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0 || (opponent.effects[:HealBlock]>0 && !@zmove)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if opponent.hp==opponent.totalhp
      @battle.pbDisplay(_INTL("{1}'s HP is full!",opponent.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    hpgain=((opponent.totalhp+1)/2).floor
    if (attacker.ability == :MEGALAUNCHER)
      hpgain=((opponent.totalhp+1)/1.33).floor
    end
    if (attacker.ability == :HEALER) 
      hpgain=opponent.totalhp
    end
    opponent.pbRecoverHP(hpgain,true)
    @battle.pbDisplay(_INTL("{1}'s HP was restored.",opponent.pbThis))
    return 0
  end
end

################################################################################
# User faints. (Explosion / Self-Destruct)
################################################################################
class PokeBattle_Move_0E0 < PokeBattle_Move
  def pbOnStartUse(attacker)
    bearer=@battle.pbCheckGlobalAbility(:DAMP)
    if bearer && !(bearer.moldbroken)
      @battle.pbDisplay(_INTL("{1}'s {2} prevents {3} from using {4}!",
        bearer.pbThis,getAbilityName(bearer.ability),attacker.pbThis(true),@name))
      return false
    end
    @battle.pbAnimation(@move,attacker,nil)
    pbShowAnimation(@move,attacker,nil)
    attacker.pbReduceHP(attacker.hp)
    return true
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return
  end

  def pbType(attacker,type=@type)
    type=@type
    if (@move == :SELFDESTRUCT)
      type = attacker.type1
    elsif (@move == :EXPLOSION && @battle.FE == :CORROSIVEMIST)
      type = :POISON
    end
    return super(attacker,type)
  end
end

################################################################################
# Inflicts fixed damage equal to user's current HP.
# User faints (if successful). (Final Gambit)
################################################################################
class PokeBattle_Move_0E1 < PokeBattle_Move
  def pbMoveFailed(attacker, opponent)
    if opponent.effects[:Protect]
      return true
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if pbMoveFailed(attacker, opponent)
      @battle.pbDisplay(_INTL("#{opponent.pbThis} protected itself!"))
      return -1
    end
    if opponent.hasType?(:GHOST)
      @battle.pbDisplay(_INTL("It doesn't affect foe #{opponent.pbThis}!"))
     return -1
    end
    ret = pbEffectFixedDamage(attacker.hp,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbReduceHP(attacker.hp)
    return ret
  end
end

################################################################################
# Decreases the target's Attack and Special Attack by 2 stages each.
# User faints (even if effect does nothing). (Memento)
################################################################################
class PokeBattle_Move_0E2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=-1; prevented=false
    if opponent.effects[:Protect] && !opponent.effects[:ProtectNegation]
      @battle.pbDisplay(_INTL("{1} protected itself!",opponent.pbThis))
      prevented=true
    end
    if !prevented && opponent.pbOwnSide.effects[:Mist]>0
      @battle.pbDisplay(_INTL("{1} is protected by Mist!",opponent.pbThis))
      prevented=true
    end
    if !prevented && (((opponent.ability == :CLEARBODY ||
       opponent.ability == :WHITESMOKE) && !(opponent.moldbroken)) || opponent.ability == :FULLMETALBODY)
      @battle.pbDisplay(_INTL("{1}'s {2} prevents stat loss!",opponent.pbThis,
         getAbilityName(opponent.ability)))
      prevented=true
    end
    if !prevented && opponent.pbTooLow?(PBStats::ATTACK) &&
       opponent.pbTooLow?(PBStats::SPATK)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any lower!",opponent.pbThis))
      prevented=true
    end
    if !prevented
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      showanim=true
      if opponent.pbReduceStat(PBStats::ATTACK,3,abilitymessage:false, statdropper: attacker)
        ret=0; showanim=false
      end
      if opponent.pbReduceStat(PBStats::SPATK,3,abilitymessage:false, statdropper: attacker)
        ret=0; showanim=false
      end
    end
    attacker.pbReduceHP(attacker.hp) # User still faints even if protected by above effects
    return ret
  end
end

################################################################################
# User faints.  The Pokémon that replaces the user is fully healed (HP and
# status).  Fails if user won't be replaced. (Healing Wish)
################################################################################
class PokeBattle_Move_0E3 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.pbCanChooseNonActive?(attacker.index)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbReduceHP(attacker.hp)
    attacker.effects[:HealingWish]=true
    attacker.pbFaint if attacker.isFainted?
    return 0
  end
end

################################################################################
# User faints.  The Pokémon that replaces the user is fully healed (HP, PP and
# status).  Fails if user won't be replaced. (Lunar Dance)
################################################################################
class PokeBattle_Move_0E4 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.pbCanChooseNonActive?(attacker.index)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbReduceHP(attacker.hp)
    attacker.effects[:LunarDance]=true
    attacker.pbFaint if attacker.isFainted?
    return 0
  end
end

################################################################################
# All current battlers will perish after 3 more rounds. (Perish Song)
################################################################################
class PokeBattle_Move_0E5 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    failed=true
    for i in 0...4
      if @battle.battlers[i].effects[:PerishSong]==0 &&
         (@battle.battlers[i].ability != :SOUNDPROOF || @battle.battlers[i].moldbroken)
        failed=false; break
      end
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("All Pokémon hearing the song will faint in three turns!"))
    for i in 0...4
      if @battle.battlers[i].effects[:PerishSong]==0
        if @battle.battlers[i].ability == :SOUNDPROOF && !(@battle.battlers[i].moldbroken)
          @battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!",@battle.battlers[i].pbThis,
             getAbilityName(@battle.battlers[i].ability),@name))
        else
          @battle.battlers[i].effects[:PerishSong]=4
          @battle.battlers[i].effects[:PerishSongUser]=attacker.index
        end
      end
    end
    return 0
  end
end

################################################################################
# If user is KO'd before it next moves, the attack that caused it loses all PP. (Grudge)
################################################################################
class PokeBattle_Move_0E6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[:Grudge]=true
    @battle.pbDisplay(_INTL("{1} wants its target to bear a grudge!",attacker.pbThis))
    return 0
  end
end

################################################################################
# If user is KO'd before it next moves, the battler that caused it also faints. (Destiny Bond)
################################################################################
class PokeBattle_Move_0E7 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.previousMove == :DESTINYBOND && attacker.effects[:DestinyRate]==true && @battle.FE != :HAUNTED
      attacker.effects[:DestinyRate] = false
    else
      attacker.effects[:DestinyRate] = true
    end
    if attacker.effects[:DestinyRate]
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      attacker.effects[:DestinyBond] = true
      @battle.pbDisplay(_INTL("{1} is trying to take its foe down with it!",attacker.pbThis))
      return 0
    else
      attacker.effects[:DestinyRate] = false
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# If user would be KO'd this round, it survives with 1HP instead. (Endure)
################################################################################
class PokeBattle_Move_0E8 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if @battle.pbRandom(65536)<(65536/(3**attacker.effects[:ProtectRate])).floor
      attacker.effects[:Endure]=true
      attacker.effects[:ProtectRate]+=1
      @battle.pbAnimation(@move,attacker,nil)
      @battle.pbDisplay(_INTL("{1} braced itself!",attacker.pbThis))
      return 0
    else
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# If target would be KO'd by this attack, it survives with 1HP instead. (False Swipe)
################################################################################
class PokeBattle_Move_0E9 < PokeBattle_Move
# Handled in superclass, do not edit!
end

################################################################################
# User flees from battle.  Fails in trainer battles. (Teleport)
################################################################################
class PokeBattle_Move_0EA < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.opponent
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    elsif @battle.pbCanRun?(attacker.index)
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      pbSEPlay("escape",100)
      @battle.pbDisplay(_INTL("{1} fled from battle!",attacker.pbThis))
      @battle.decision=3
      return 0
    else
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# Target flees from battle. In trainer battles, target switches out instead.
# Fails if target is a higher level than the user. For status moves. (Roar / Whirlwind)
################################################################################
class PokeBattle_Move_0EB < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if (@move == :ROAR) && @battle.FE == :SWAMP
      @battle.pbDisplay(_INTL("What are ya doin' in my swamp?!"))
    end
    if (@battle.FE == :COLOSSEUM || @battle.ProgressiveFieldCheck(PBFields::CONCERT)) && @move == :ROAR
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)  
        attacker.pbIncreaseStatBasic(PBStats::ATTACK,2)  
      end
      if @battle.FE == :COLOSSEUM  
        @battle.pbDisplay(_INTL("{1} stands their ground in the arena!!",opponent.pbThis))  
        return -1
      end      
    end
    if (opponent.ability == :SUCTIONCUPS) && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("{1} anchored itself with {2}!",opponent.pbThis,getAbilityName(opponent.ability)))
      return -1
    end
    if opponent.effects[:Ingrain]
      @battle.pbDisplay(_INTL("{1} anchored itself with its roots!",opponent.pbThis))
      return -1
    end
    if opponent.isbossmon && opponent.chargeAttack
      @battle.pbDisplay(_INTL("{1} is immovable!",opponent.pbThis))
      return -1
    end
    if opponent.giga
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if !@battle.opponent && !@battle.battlers.any?{|battler| battler.isbossmon}
      if opponent.level>=attacker.level
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.decision=3 # Set decision to escaped
      return 0
    else
      choices=[]
      party=@battle.pbParty(opponent.index)
      for i in 0...party.length
        choices[choices.length]=i if @battle.pbCanSwitchLax?(opponent.index,i,false)
      end
      if choices.length==0 
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
        pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
        opponent.forcedSwitch = true
      return 0
    end
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :WINDRAGE
      @battle.pbAnimation(:HURRICANE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end

  def pbAdditionalEffect(attacker,opponent)
    if @battle.FE == :COLOSSEUM  
      @battle.pbDisplay(_INTL("{1} stands their ground in the arena!!",opponent.pbThis))  
      return -1
    end    
    if (opponent.ability == :SUCTIONCUPS) && !(opponent.moldbroken)
      @battle.pbDisplay(_INTL("{1} anchored itself with {2}!",opponent.pbThis,getAbilityName(opponent.ability)))
      return -1
    end
    if opponent.effects[:Ingrain]
      @battle.pbDisplay(_INTL("{1} anchored itself with its roots!",opponent.pbThis))
      return -1
    end
    if opponent.isbossmon && opponent.chargeAttack
      @battle.pbDisplay(_INTL("{1} is immovable!",opponent.pbThis))
      return -1
    end
    if opponent.giga
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end

    choices=[]
    party=@battle.pbParty(opponent.index)
    for i in 0...party.length
      choices[choices.length]=i if @battle.pbCanSwitchLax?(opponent.index,i,false)
    end
    if choices.length==0 
      return -1
    end
      opponent.forcedSwitch = true
    return 0
    
  end
end

################################################################################
# Target flees from battle.  In trainer battles, target switches out instead.
# Fails if target is a higher level than the user.  For damaging moves. (Dragon Tail / Circle Throw)
################################################################################
class PokeBattle_Move_0EC < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    opponent.vanished=true
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted? && !opponent.isFainted? &&
     opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
     (opponent.ability != :SUCTIONCUPS || opponent.moldbroken) && (!opponent.giga)
     !opponent.effects[:Ingrain] && !(attacker.ability == :PARENTALBOND && hitnum==0) && !(attacker.crested == :HYDREIGON && hitnum==0) &&
     !(opponent.isbossmon && opponent.chargeAttack) && @battle.FE != :COLOSSEUM
      if !@battle.opponent && !@battle.battlers.any?{|battler| battler.isbossmon}
        if !((opponent.level>attacker.level) || opponent.isbossmon)
          @battle.decision=3 # Set decision to escaped
        else
          opponent.vanished=false
          @battle.pbCommonAnimation("Fade in",opponent,nil)
        end
      else
        choices=[]
        party=@battle.pbParty(opponent.index)
        for i in 0..party.length-1
          choices[choices.length]=i if @battle.pbCanSwitchLax?(opponent.index,i,false)
        end
        if (choices.length>0 && !(opponent.isbossmon))
         # pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
         #@battle.pbCommonAnimation("Fade in",opponent,nil)
          opponent.forcedSwitch = true
        else
          opponent.vanished=false
          @battle.pbCommonAnimation("Fade in",opponent,nil)
        end
      end
    else
      opponent.vanished=false
    end
    return ret
  end
end

################################################################################
# User switches out.  Various effects affecting the user are passed to the
# replacement. (Baton Pass)
################################################################################
class PokeBattle_Move_0ED < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    #attacker.vanished=true
    if !@battle.pbCanChooseNonActive?(attacker.index)
      #attacker.vanished=false
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    newpoke=0
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    newpoke=@battle.pbSwitchInBetween(attacker.index,true,false)
    @battle.pbMessagesOnReplace(attacker.index,newpoke)
    attacker.pbResetForm
    @battle.pbReplace(attacker.index,newpoke,true)
    @battle.pbOnActiveOne(attacker)
    attacker.pbAbilitiesOnSwitchIn(true)
    return 0
  end
end

################################################################################
# After inflicting damage, user switches out.  Ignores trapping moves.(U-turn, Volt Switch)
################################################################################
class PokeBattle_Move_0EE < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    attacker.vanished=true
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted? && @battle.pbCanChooseNonActive?(attacker.index) &&
       !@battle.pbAllFainted?(@battle.pbParty(opponent.index)) && !(attacker.ability == :PARENTALBOND && hitnum==0) && !(attacker.crested == :HYDREIGON && hitnum==0) 

      if !opponent.hasWorkingItem(:EJECTBUTTON)
        attacker.userSwitch = true if pbTypeModifier(@type,attacker,opponent)!=0 && !(@battle.FE == :INVERSE)
      else
        attacker.vanished=false
      end
      if @battle.FE == :INVERSE && !opponent.hasWorkingItem(:EJECTBUTTON)
        attacker.userSwitch = true
      else
        attacker.vanished=false
      end
      if @battle.FE == :COLOSSEUM
        attacker.userSwitch = false
        attacker.vanished=false
      end
      if @move == :VOLTSWITCH && (opponent.ability == :MOTORDRIVE ||
        opponent.ability == :VOLTABSORB || opponent.ability == :STORMHEAL ||
        opponent.ability == :LIGHTNINGROD)
        attacker.userSwitch = false
        attacker.vanished=false
      end
      #Going to switch, check for pursuit
      if attacker.userSwitch
        for j in @battle.priority
          next if !attacker.pbIsOpposing?(j.index)
          # if Pursuit and this target was chosen
          if !j.hasMovedThisRound? && @battle.pbChoseMoveFunctionCode?(j.index,0x88) && !j.effects[:Pursuit] && (@battle.choices[j.index][3]!=j.pbPartner.index)
            attacker.vanished=false
            @battle.pbCommonAnimation("Fade in",attacker,nil)
            newpoke=@battle.pbPursuitInterrupt(j,attacker)
          end
          break if attacker.isFainted?
        end
      end
    else
      attacker.vanished=false
      @battle.pbCommonAnimation("Fade in",attacker,nil)
    end
    return ret
  end
end

################################################################################
# Target can no longer switch out or flee, as long as the user remains active.
# (Spider Web / Block / Mean Look)
################################################################################
class PokeBattle_Move_0EF < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:MeanLook]>=0 ||
       opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:MeanLook]=attacker.index
    @battle.pbDisplay(_INTL("{1} can't escape now!",opponent.pbThis))
    if @move == :BLOCK && @battle.FE== :CROWD
      if target.pbCanReduceStatStage?(PBStats::SPEED,false,true)
        target.pbReduceStat(PBStats::SPEED,1, statdropper: attacker)
        @battle.pbDisplay(_INTL("{1} got caught in a lock!",opponent.pbThis))
      end
    end
    if Rejuv && @move == :SPIDERWEB && @battle.FE == :SWAMP
      opponent.effects[:SwampWeb]=true
    end
    return 0
  end
end

################################################################################
# Target drops its item.  It regains the item at the end of the battle. (Knock Off)
################################################################################
class PokeBattle_Move_0F0 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute && opponent.item
      if opponent.hasWorkingItem(:ROCKYHELMET,true) && attacker.ability != :MAGICGUARD && !(attacker.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) &&
        !(opponent.ability == :STICKYHOLD && !(opponent.moldbroken)) && @move != :GIANTSDRUM && !attacker.effects[:MagicGuard]
        @battle.scene.pbDamageAnimation(attacker,0)
        attacker.pbReduceHP((attacker.totalhp/6.0).floor)
        @battle.pbDisplay(_INTL("{1} was hurt by the {2}!",attacker.pbThis,
        getItemName(opponent.item)))
        if attacker.hp<=0
          return ret
        end
      end      
      if opponent.ability == :STICKYHOLD && !(opponent.moldbroken)
        abilityname=getAbilityName(opponent.ability)
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",opponent.pbThis,abilityname,@name))
      elsif !@battle.pbIsUnlosableItem(opponent,opponent.item) && !(attacker.ability == :PARENTALBOND && hitnum==0) && !(attacker.crested == :HYDREIGON && hitnum==0) 
        # Items that still work before being knocked of
        if opponent.item==:WEAKNESSPOLICY && opponent.damagestate.typemod>4 && opponent.hp > 0
          if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK)
            opponent.pbIncreaseStatBasic(PBStats::ATTACK,2)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(_INTL("{1}'s Weakness Policy sharply raised its Attack!", opponent.pbThis))
            opponent.pbDisposeItem(false)
          end
          if opponent.pbCanIncreaseStatStage?(PBStats::SPATK)
            opponent.pbIncreaseStatBasic(PBStats::SPATK,2)
            @battle.pbCommonAnimation("StatUp",opponent,nil)
            @battle.pbDisplay(_INTL("{1}'s Weakness Policy sharply raised its Special Attack!", opponent.pbThis))
            opponent.pbDisposeItem(false)
          end
        end
        opponent.effects[:ChoiceBand]=nil
        if opponent != 0
          # Knocking of the item
          itemname=getItemName(opponent.item)
          opponent.item=nil
          opponent.pokemon.corrosiveGas=false
          @battle.pbDisplay(_INTL("{1} knocked off {2}'s {3}!",attacker.pbThis,opponent.pbThis(true),itemname))
        end
      end
    end
    return ret
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :GIANTSDRUM
      @battle.pbAnimation(:DRUMBEATING,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# User steals the target's item, if the user has none itself. (Thief / Covet)
# Items stolen from wild Pokémon are kept after the battle.
################################################################################
class PokeBattle_Move_0F1 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return basedmg if @battle.FE != :BACKALLEY
    return basedmg if (opponent.effects[:Substitute]>0) || opponent.item.nil? || !attacker.item.nil? 
    return basedmg if (opponent.ability == :STICKYHOLD && !opponent.moldbroken)
    return basedmg if @battle.pbIsUnlosableItem(opponent,opponent.item) || @battle.pbIsUnlosableItem(attacker,opponent.item)
    return basedmg*2
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 &&
       !opponent.damagestate.substitute && opponent.item
      if opponent.ability == :STICKYHOLD && !(opponent.moldbroken)
        abilityname=getAbilityName(opponent.ability)
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",opponent.pbThis,abilityname,@name))
      elsif !@battle.pbIsUnlosableItem(opponent,opponent.item) &&
            !@battle.pbIsUnlosableItem(attacker,opponent.item) &&
            attacker.item.nil? &&
            (@battle.opponent || !@battle.pbIsOpposing?(attacker.index))
        itemname=getItemName(opponent.item)
        attacker.item=opponent.item
        opponent.item=nil
        if opponent.pokemon.corrosiveGas
          opponent.pokemon.corrosiveGas=false
          attacker.pokemon.corrosiveGas=true
        end
        opponent.effects[:ChoiceBand]=nil
        # In a wild battle
        if !@battle.opponent && attacker.pokemon.itemInitial.nil? && opponent != attacker.pbPartner && opponent.pokemon.itemInitial==attacker.item && !opponent.isbossmon && !attacker.isbossmon
          attacker.pokemon.itemInitial=attacker.item
          attacker.pokemon.itemReallyInitialHonestlyIMeanItThisTime=attacker.item
          opponent.pokemon.itemInitial=nil
        end
        if (@move == :THIEF)
          @battle.pbCommonAnimation("Thief",attacker,opponent)
        else
          @battle.pbCommonAnimation("Covet",attacker,opponent)
        end
        @battle.pbDisplay(_INTL("{1} stole {2}'s {3}!",attacker.pbThis,opponent.pbThis(true),itemname))
      end
    end
    return ret
  end
end

################################################################################
# User and target swap items.  They remain swapped after the battle. (Trick / Switcheroo)
################################################################################
class PokeBattle_Move_0F2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if (attacker.item.nil? && opponent.item.nil?) ||
       (!@battle.opponent && @battle.pbIsOpposing?(attacker.index))
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if @battle.pbIsUnlosableItem(opponent,opponent.item) ||
       @battle.pbIsUnlosableItem(attacker,opponent.item) ||
       @battle.pbIsUnlosableItem(opponent,attacker.item) ||
       @battle.pbIsUnlosableItem(attacker,attacker.item)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if opponent.ability == :STICKYHOLD && !(opponent.moldbroken)
      abilityname=getAbilityName(opponent.ability)
      @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",opponent.pbThis,abilityname,name))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    oldattitem=attacker.item
    oldoppitem=opponent.item
    oldattitemname=getItemName(oldattitem) if oldattitem
    oldoppitemname=getItemName(oldoppitem) if oldoppitem
    attacker.item, opponent.item = opponent.item, attacker.item
    attacker.pokemon.corrosiveGas = opponent.pokemon.corrosiveGas
    if !@battle.opponent && # In a wild battle
       attacker.pokemon.itemInitial==oldattitem &&
       opponent.pokemon.itemInitial==oldoppitem && !opponent.isbossmon && !attacker.isbossmon
      attacker.pokemon.itemInitial=oldoppitem
      attacker.pokemon.itemReallyInitialHonestlyIMeanItThisTime=oldoppitem
      opponent.pokemon.itemInitial=oldattitem
      opponent.pokemon.itemReallyInitialHonestlyIMeanItThisTime=oldattitem
    end
    @battle.pbDisplay(_INTL("{1} switched items with its opponent!",attacker.pbThis))
    @battle.pbDisplay(_INTL("{1} obtained {2}.",attacker.pbThis,oldoppitemname)) if oldoppitem
    @battle.pbDisplay(_INTL("{1} obtained {2}.",opponent.pbThis,oldattitemname)) if oldattitem
    if oldattitem!=oldoppitem # TODO: Not exactly correct
      attacker.effects[:ChoiceBand]=nil
    end
    opponent.effects[:ChoiceBand]=nil
    if @battle.FE == :BACKALLEY
      if @move == :TRICK
        if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,abilitymessage:false)
          attacker.pbIncreaseStat(PBStats::SPATK,1,abilitymessage:false)
        end
        if opponent.pbCanReduceStatStage?(PBStats::SPATK,false)
          opponent.pbReduceStat(PBStats::SPATK,1,abilitymessage:false, statdropper: attacker)
        end
      elsif @move == :SWITCHEROO
        if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,abilitymessage:false)
          attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
        end
        if opponent.pbCanReduceStatStage?(PBStats::ATTACK,false)
          opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
        end
      end
    end
    return 0
  end
end

################################################################################
# User gives its item to the target.  The item remains given after the battle. (Bestow)
################################################################################
class PokeBattle_Move_0F3 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.item.nil? || opponent.item.nil?
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if @battle.pbIsUnlosableItem(attacker,attacker.item) ||
       @battle.pbIsUnlosableItem(opponent,attacker.item)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    itemname=getItemName(attacker.item)
    opponent.item=attacker.item
    attacker.item=nil
    if attacker.pokemon.corrosiveGas
      attacker.pokemon.corrosiveGas=false
      opponent.pokemon.corrosiveGas=true
    end
    attacker.effects[:ChoiceBand]=nil
    if !@battle.opponent && # In a wild battle
       opponent.pokemon.itemInitial.nil? &&
       attacker.pokemon.itemInitial==opponent.item && !opponent.isbossmon
      opponent.pokemon.itemInitial=opponent.item
      opponent.pokemon.itemReallyInitialHonestlyIMeanItThisTime=opponent.item
      attacker.pokemon.itemInitial=nil
    end
    @battle.pbDisplay(_INTL("{1} received {2} from {3}!",opponent.pbThis,itemname,attacker.pbThis(true)))
    return 0
  end
end

################################################################################
# User consumes target's berry and gains its effect. (Bug Bite / Pluck)
################################################################################
class PokeBattle_Move_0F4 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted? && opponent.damagestate.calcdamage>0 &&
       !opponent.damagestate.substitute && (!opponent.item.nil? && pbIsBerry?(opponent.item)) && !(attacker.ability == :PARENTALBOND && hitnum==0) && !(attacker.crested == :HYDREIGON && hitnum==0)  && 
       !opponent.pokemon.corrosiveGas
      if opponent.ability == :STICKYHOLD && !(opponent.moldbroken)
        abilityname=getAbilityName(opponent.ability)
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",opponent.pbThis,abilityname,@name))
      else
        item=opponent.item
        itemname=getItemName(item)
        opponent.item=nil
        opponent.pokemon.itemInitial=nil if opponent.pokemon.itemInitial==item
        @battle.pbDisplay(_INTL("{1} stole and ate its target's {2}!",attacker.pbThis,itemname))
        if attacker.ability != :KLUTZ && attacker.effects[:Embargo]==0 && attacker.pbOwnSide.effects[:Embargo] == 0
           attacker.pbUseBerry(item,true)
          # Get berry's effect here
        end
      end
    end
    return ret
  end
end

################################################################################
# Target's berry is destroyed. (Incinerate)
################################################################################
class PokeBattle_Move_0F5 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted? && opponent.damagestate.calcdamage>0 &&
       !opponent.damagestate.substitute && !opponent.item.nil? && !@battle.pbIsUnlosableItem(opponent,opponent.item)
      item=opponent.item
      itemname=getItemName(item)
      opponent.item=nil
      opponent.pokemon.itemInitial=nil if opponent.pokemon.itemInitial==item
      @battle.pbDisplay(_INTL("{1}'s {2} was incinerated!",opponent.pbThis,itemname))
    end
    return ret
  end
end

################################################################################
# User recovers the last item it held and consumed. (Recycle)
################################################################################
class PokeBattle_Move_0F6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret = 0
    if @basedamage > 0
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    elsif attacker.pokemon.itemRecycle.nil? || attacker.item
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(:RECYCLE,attacker,nil,hitnum,alltargets,showanimation)
    item=attacker.pokemon.itemRecycle
    itemname=getItemName(item)
    attacker.item=item
    attacker.pokemon.itemInitial=item if (attacker.pokemon.itemInitial.nil? && item == attacker.pokemon.itemReallyInitialHonestlyIMeanItThisTime)
    attacker.pokemon.itemRecycle=nil
    @battle.pbDisplay(_INTL("{1} found one {2}!",attacker.pbThis,itemname))
    if @battle.FE == :CITY
      statgain = false
      stat = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED].sample
      if i.pbCanIncreaseStatStage?(stat,false)
        i.pbIncreaseStat(stat,1)
        statgain = true
      end
      @battle.pbDisplay(_INTL("Reduce, reuse, recycle!")) if statgain
    end
    return 0
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :HONEYPOT
      @battle.pbAnimation(:APPELACID,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# User flings its item at the target.  Power and effect depend on the item. (Fling)
################################################################################
class PokeBattle_Move_0F7 < PokeBattle_Move

  def pbMoveFailed(attacker,opponent)
    return true if attacker.item.nil? ||
                   @battle.pbIsUnlosableItem(attacker,attacker.item) ||
                   pbIsPokeBall?(attacker.item) ||
                   attacker.ability == :KLUTZ ||
                   attacker.effects[:Embargo]>0 || attacker.pbOwnSide.effects[:Embargo] > 0
    return false if PBStuff::FLINGDAMAGE[attacker.item]
    return false if !attacker.item.nil? && pbIsBerry?(attacker.item)
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    return 130 if @battle.FE == :CONCERT4
    return PBStuff::FLINGDAMAGE[attacker.item] if PBStuff::FLINGDAMAGE[attacker.item]
    return 10 if !attacker.item.nil? &&  pbIsBerry?(attacker.item)
    return 1
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.item.nil?
      @battle.pbDisplay(_INTL("But it failed!"))
      return 0
    end
    if !opponent.effects[:Protect]
      @battle.pbDisplay(_INTL("{1} flung its {2}!",attacker.pbThis,getItemName(attacker.item)))
    end
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
       (opponent.ability != :SHIELDDUST || opponent.moldbroken) && !opponent.hasType?(:BUG)
      if @item.pbGetPocket(attacker.item) ==5
        @battle.pbDisplay(_INTL("{1} ate the {2}!",opponent.pbThis,getItemName(attacker.item)))
        opponent.pbUseBerry(attacker.item,true)
      end
      if attacker.hasWorkingItem(:FLAMEORB)
        if opponent.pbCanBurn?(false)
          opponent.pbBurn(attacker)
          @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
        end
      elsif attacker.hasWorkingItem(:KINGSROCK) ||
            attacker.hasWorkingItem(:RAZORFANG)
        if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute
          opponent.effects[:Flinch]=true
        end
      elsif attacker.hasWorkingItem(:LIGHTBALL)
         if opponent.pbCanParalyze?(false)
          opponent.pbParalyze(attacker)
          @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!",opponent.pbThis))
        end
      elsif attacker.hasWorkingItem(:MENTALHERB)
        if opponent.effects[:Attract]>=0
          opponent.effects[:Attract]=-1
          @battle.pbDisplay(_INTL("{1}'s {2} cured {3}'s love problem!",
             attacker.pbThis,getItemName(attacker.item),opponent.pbThis(true)))
        end
      elsif attacker.hasWorkingItem(:POISONBARB)
        if opponent.pbCanPoison?(false)
          opponent.pbPoison(attacker)
          @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
        end
      elsif attacker.hasWorkingItem(:TOXICORB)
        if opponent.pbCanPoison?(false)
          opponent.pbPoison(attacker,true)
          @battle.pbDisplay(_INTL("{1} was badly poisoned!",opponent.pbThis))
        end
      elsif attacker.hasWorkingItem(:WHITEHERB)
        while true
          reducedstats=false
          for i in [PBStats::ATTACK,PBStats::DEFENSE,
                    PBStats::SPEED,PBStats::SPATK,PBStats::SPDEF,
                    PBStats::EVASION,PBStats::ACCURACY]
            if opponent.stages[i]<0
              opponent.stages[i]=0; reducedstats=true
            end
          end
          break if !reducedstats
          @battle.pbDisplay(_INTL("{1}'s {2} restored {3}'s status!",
             attacker.pbThis,getItemName(attacker.item),opponent.pbThis(true)))
        end
      end
    end
    attacker.pbDisposeItem(false)
    return ret
  end
end

################################################################################
# For 5 rounds, the target cannnot use its held item, its held item has no
# effect, and no items can be used on it. (Embargo)
################################################################################
class PokeBattle_Move_0F8 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    # if opponent.effects[:Embargo]>0
    
    if attacker.pbOpposingSide.effects[:Embargo] > 0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    # opponent.effects[:Embargo]=5
    attacker.pbOpposingSide.effects[:Embargo] = 5
    #@battle.pbDisplay(_INTL("{1} can't use items anymore!",opponent.pbThis))
    @battle.pbDisplay(_INTL("The opposing team can't use items anymore!"))
    return 0
  end
end

################################################################################
# For 5 rounds, all held items cannot be used in any way and have no effect.
# Held items can still change hands, but can't be thrown. (Magic Room)
################################################################################
class PokeBattle_Move_0F9 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.state.effects[:MagicRoom]>0
      @battle.state.effects[:MagicRoom]=0
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.pbDisplay(_INTL("The area returned to normal!"))
    else
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.state.effects[:MagicRoom]=5
      if @battle.FE == :NEWWORLD || @battle.FE == :PSYTERRAIN || (attacker.hasWorkingItem(:AMPLIFIELDROCK)) || (Rejuv && @battle.FE == :STARLIGHT)
        @battle.state.effects[:MagicRoom]=8
      end
      if @battle.FE == :DIMENSIONAL
        rnd=@battle.pbRandom(6)
        @battle.state.effects[:MagicRoom]=3+rnd
      end
      @battle.pbDisplay(_INTL("It created a bizarre area in which Pokémon's held items lose their effects!"))
    end
    return 0
  end
end

################################################################################
# User takes recoil damage equal to the amount specified by the recoil flag.
################################################################################
class PokeBattle_Move_0FA < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
       attacker.ability != :ROCKHEAD && attacker.crested != :RAMPARDOS && attacker.ability != :MAGICGUARD &&
       !(@move == :WILDCHARGE && @battle.FE == :ELECTERRAIN) && !(attacker.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && !attacker.effects[:MagicGuard]
      recoildamage = [1,(opponent.damagestate.hplost*hasFlag?(:recoil)).floor].max
      recoildamage = [1,(opponent.damagestate.hplost*0.25).floor].max if @move == :WAVECRASH && (@battle.FE == :WATERSURFACE || @battle.FE == :UNDERWATER)
      attacker.pbReduceHP(recoildamage)
      @battle.pbDisplay(_INTL("{1} is damaged by the recoil!",attacker.pbThis))
    end
    return ret
  end
end

################################################################################
# User takes recoil damage equal to the amount specified by the recoil flag.
# May paralyze the target. (Volt Tackle)
################################################################################
class PokeBattle_Move_0FD < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
       attacker.ability != :ROCKHEAD && (attacker.species != :RAMPARDOS && attacker.crested != :RAMPARDOS) &&
       attacker.ability != :MAGICGUARD && !(attacker.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && !attacker.effects[:MagicGuard]
       attacker.pbReduceHP([1,(opponent.damagestate.hplost*hasFlag?(:recoil)).floor].max)
      @battle.pbDisplay(_INTL("{1} is damaged by the recoil!",attacker.pbThis))
    end
    return ret
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanParalyze?(false)
    opponent.pbParalyze(attacker)
    @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!",opponent.pbThis))
    return true
  end
end

################################################################################
# User takes recoil damage equal to the amount specified by the recoil flag.
# May burn the target. (Flare Blitz / Wave Crash)
################################################################################
class PokeBattle_Move_0FE < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
       attacker.ability != :ROCKHEAD && !(attacker.species == :RAMPARDOS && attacker.crested) &&
       attacker.ability != :MAGICGUARD && !(attacker.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && !attacker.effects[:MagicGuard]
      attacker.pbReduceHP([1,(opponent.damagestate.hplost*hasFlag?(:recoil)).floor].max)
      @battle.pbDisplay(_INTL("{1} is damaged by the recoil!",attacker.pbThis))
    end
    return ret
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanBurn?(false)
    opponent.pbBurn(attacker)
    @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :WAVECRASH
      @battle.pbAnimation(:WATERFALL,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Starts sunny weather. (Sunny Day)
################################################################################
class PokeBattle_Move_0FF < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.state.effects[:HeavyRain]
      @battle.pbDisplay(_INTL("There's no relief from this heavy rain!"))
      return -1
    elsif @battle.state.effects[:HarshSunlight]
      @battle.pbDisplay(_INTL("The extremely harsh sunlight was not lessened at all!"))
      return -1
    elsif @battle.weather== :STRONGWINDS && (@battle.pbCheckGlobalAbility(:DELTASTREAM)) 
      @battle.pbDisplay(_INTL("The mysterious air current blows on regardless!"))
      return -1
    elsif @battle.state.effects[:DesertNova]
      @battle.pbDisplay(_INTL("The sand swallowed up the sun!"))
      return -1
    elsif @battle.state.effects[:AbsoluteZero]
      @battle.pbDisplay(_INTL("The relentless cold was not disturbed!"))
      return -1
    end

    if @battle.weather== :SUNNYDAY
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end

    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)

    rainbowhold=0
    if @battle.weather== :RAINDANCE
      rainbowhold=5
      if (attacker.hasWorkingItem(:HEATROCK)) || @battle.FE == :DESERT || @battle.FE == :SNOWYMOUNTAIN || @battle.FE == :SKY
        rainbowhold=8
      end
    end

    @battle.weather=:SUNNYDAY
    @battle.weatherduration=5
    @battle.weatherduration=8 if (attacker.hasWorkingItem(:HEATROCK)) || @battle.FE == :DESERT || @battle.FE == :MOUNTAIN || @battle.FE == :SNOWYMOUNTAIN || @battle.FE == :SKY

    @battle.pbCommonAnimation("Sunny",nil,nil)
    @battle.pbDisplay("The sunlight turned harsh!")
    @battle.pbDisplay("The sunlight eclipsed the starry sky!") if @battle.FE == :STARLIGHT
    
    if rainbowhold != 0
      fieldbefore = @battle.FE
      @battle.setField(:RAINBOW,rainbowhold)
      if fieldbefore != :RAINBOW
        @battle.pbDisplay(_INTL("The weather created a rainbow!"))
      else
        @battle.pbDisplay(_INTL("The weather refreshed the rainbow!"))
      end
    end
    @battle.protosynthesisCheck
    return 0
  end
end

################################################################################
# Starts rainy weather. (Rain Dance)
################################################################################
class PokeBattle_Move_100 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)

    if @battle.state.effects[:HeavyRain]
      @battle.pbDisplay(_INTL("There's no relief from this heavy rain!"))
      return -1
    elsif @battle.state.effects[:HarshSunlight]
      @battle.pbDisplay(_INTL("The extremely harsh sunlight was not lessened at all!"))
      return -1
    elsif @battle.weather== :STRONGWINDS && (@battle.pbCheckGlobalAbility(:DELTASTREAM))
      @battle.pbDisplay(_INTL("The mysterious air current blows on regardless!"))
      return -1
    elsif @battle.state.effects[:DesertNova]
      @battle.pbDisplay(_INTL("The sand swallowed up the rain"))
      return -1
    elsif @battle.state.effects[:AbsoluteZero]
      @battle.pbDisplay(_INTL("The relentless cold was not disturbed!"))
      return -1
    end

    if @battle.weather== :RAINDANCE
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end

    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)

    rainbowhold=0
    if @battle.weather== :SUNNYDAY
      rainbowhold=5
      rainbowhold=8 if (attacker.hasWorkingItem(:DAMPROCK)) || @battle.FE == :BIGTOP || @battle.FE == :CLOUDS || @battle.FE == :SKY
    end
    @battle.weather=:RAINDANCE
    @battle.weatherduration=5
    @battle.weatherduration=8 if (attacker.hasWorkingItem(:DAMPROCK)) || @battle.FE == :BIGTOP || @battle.FE == :CLOUDS || @battle.FE == :SKY

    @battle.pbCommonAnimation("Rain",nil,nil)
    @battle.pbDisplay(_INTL("It started to rain!"))
    @battle.pbDisplay(_INTL("The weather blocked out the starry sky!")) if @battle.FE == :STARLIGHT
    if rainbowhold != 0
      fieldbefore = @battle.FE
      @battle.setField(:RAINBOW,rainbowhold)
      if fieldbefore != :RAINBOW
        @battle.pbDisplay(_INTL("The weather created a rainbow!"))
      else
        @battle.pbDisplay(_INTL("The weather refreshed the rainbow!"))
      end
    end
    @battle.protosynthesisCheck
    return 0
  end
end

################################################################################
# Starts sandstorm weather. (Sandstorm)
################################################################################
class PokeBattle_Move_101 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)

    if @battle.state.effects[:HeavyRain]
      @battle.pbDisplay(_INTL("There's no relief from this heavy rain!"))
      return -1
    elsif @battle.state.effects[:HarshSunlight]
      @battle.pbDisplay(_INTL("The extremely harsh sunlight was not lessened at all!"))
      return -1
    elsif @battle.weather== :STRONGWINDS && (@battle.pbCheckGlobalAbility(:DELTASTREAM)) 
      @battle.pbDisplay(_INTL("The mysterious air current blows on regardless!"))
      return -1
    elsif @battle.state.effects[:DesertNova]
      @battle.pbDisplay(_INTL("The sand was swept away by the Desert Nova!"))
      return -1
    elsif @battle.state.effects[:AbsoluteZero]
      @battle.pbDisplay(_INTL("The relentless cold was not disturbed!"))
      return -1
    end

    if @battle.weather== :SANDSTORM
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end

    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)

    @battle.weather=:SANDSTORM
    @battle.weatherduration=5
    @battle.weatherduration=8 if (attacker.hasWorkingItem(:SMOOTHROCK)) || @battle.FE == :DESERT || @battle.FE == :ASHENBEACH || @battle.FE == :SKY

    @battle.pbCommonAnimation("Sandstorm",nil,nil)
    @battle.pbDisplay(_INTL("A sandstorm brewed!"))
    @battle.pbDisplay(_INTL("The weather blocked out the starry sky!")) if @battle.FE == :STARLIGHT
    @battle.protosynthesisCheck
    return 0
  end
end

################################################################################
# Starts hail weather. (Hail)
################################################################################
class PokeBattle_Move_102 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)

    if @battle.state.effects[:HeavyRain]
      @battle.pbDisplay(_INTL("There's no relief from this heavy rain!"))
      return -1
    elsif @battle.state.effects[:HarshSunlight]
      @battle.pbDisplay(_INTL("The extremely harsh sunlight was not lessened at all!"))
      return -1
    elsif @battle.weather== :STRONGWINDS && (@battle.pbCheckGlobalAbility(:DELTASTREAM)) 
      @battle.pbDisplay(_INTL("The mysterious air current blows on regardless!"))
      return -1
    elsif @battle.state.effects[:DesertNova]
      @battle.pbDisplay(_INTL("The sand swallowed up the hail!"))
      return -1
    elsif @battle.state.effects[:AbsoluteZero]
      @battle.pbDisplay(_INTL("The relentless cold was not disturbed!"))
      return -1
    end

    if @battle.weather== :HAIL
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end

    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)

    @battle.weather=:HAIL
    @battle.weatherduration=5
    @battle.weatherduration=8 if (attacker.hasWorkingItem(:ICYROCK)) || [:ICY,:SNOWYMOUNTAIN,:FROZENDIMENSION,:SKY,:CLOUDS].include?(@battle.FE)

    @battle.pbCommonAnimation("Hail",nil,nil)
    @battle.pbDisplay(_INTL("It started to hail!"))
    @battle.pbDisplay(_INTL("The weather blocked out the starry sky!")) if @battle.FE == :STARLIGHT

    for facemon in @battle.battlers
      if facemon.species==:EISCUE && facemon.form==1 # Eiscue
        facemon.pbRegenFace
        @battle.pbDisplay(_INTL("{1} transformed!",facemon.name))
      end
    end
    @battle.protosynthesisCheck
    return 0
  end
end

################################################################################
# Entry hazard.  Lays spikes on the opposing side (max. 3 layers). (Spikes / Ceaseless Edge)
################################################################################
class PokeBattle_Move_103 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if attacker.pbOpposingSide.effects[:Spikes]>=3
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...4
      next if !(attacker.pbIsOpposing?(i))
      if (@battle.battlers[i].ability == :MAGICBOUNCE && !PBStuff::TWOTURNMOVE.include?(@battle.battlers[i].effects[:TwoTurnAttack])) || 
        (@battle.battlers[i]).effects[:MagicCoat]
         attacker.pbOwnSide.effects[:Spikes]+=1 if attacker.pbOwnSide.effects[:Spikes]<3
         @battle.pbDisplay(_INTL("{1} bounced the Spikes back!",(@battle.battlers[i]).pbThis))
         if @battle.pbIsOpposing?(attacker.index)
             @battle.pbDisplay(_INTL("Spikes were scattered all around the foe's team's feet!"))
         else
             @battle.pbDisplay(_INTL("Spikes were scattered all around your team's feet!"))
         end
       return 0
       break
      end
    end
    attacker.pbOpposingSide.effects[:Spikes]+=1
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("Spikes were scattered all around the feet of the foe's team!"))
    else
      @battle.pbDisplay(_INTL("Spikes were scattered all around the feet of your team!"))
    end
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if !(attacker.pbOpposingSide.effects[:Spikes]>=3)
      attacker.pbOpposingSide.effects[:Spikes]+=1
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("Spikes were scattered all around the feet of the foe's team!"))
      else
        @battle.pbDisplay(_INTL("Spikes were scattered all around the feet of your team!"))
      end
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :CEASELESSEDGE
      @battle.pbAnimation(:NIGHTSLASH,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Entry hazard.  Lays poison spikes on the opposing side (max. 2 layers). (Toxic Spikes)
################################################################################
class PokeBattle_Move_104 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOpposingSide.effects[:ToxicSpikes]>=2
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...4
      next if !(attacker.pbIsOpposing?(i))
      if (@battle.battlers[i].ability == :MAGICBOUNCE && !PBStuff::TWOTURNMOVE.include?(@battle.battlers[i].effects[:TwoTurnAttack])) || 
        (@battle.battlers[i]).effects[:MagicCoat]
         attacker.pbOwnSide.effects[:ToxicSpikes]+=1 if attacker.pbOwnSide.effects[:ToxicSpikes]<2
         @battle.pbDisplay(_INTL("{1} bounced the Toxic Spikes back!",(@battle.battlers[i]).pbThis))
         if @battle.pbIsOpposing?(attacker.index)
             @battle.pbDisplay(_INTL("Poison spikes were scattered all around the foe's team's feet!"))
         else
             @battle.pbDisplay(_INTL("Poison spikes were scattered all around your team's feet!"))
         end
       return 0
       break
      end
    end
    attacker.pbOpposingSide.effects[:ToxicSpikes]+=1
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("Poison spikes were scattered all around the foe's team's feet!"))
    else
      @battle.pbDisplay(_INTL("Poison spikes were scattered all around your team's feet!"))
    end
    return 0
  end
end

################################################################################
# Entry hazard.  Lays stealth rocks on the opposing side. (Stealth Rock / Stone Axe)
################################################################################
class PokeBattle_Move_105 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if attacker.pbOpposingSide.effects[:StealthRock]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.FE == :CLOUDS
      attacker.pbOwnSide.effects[:StealthRock]=true
      @battle.pbDisplay(_INTL("... but the clouds bounced the Stealth Rocks back!"))
      if @battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("Pointed stones float in the air around your foe's team!"))
      else
        @battle.pbDisplay(_INTL("Pointed stones float in the air around your team!"))
      end
      return 0
    end
    for i in 0...4
      next if !(attacker.pbIsOpposing?(i))
      if (@battle.battlers[i].ability == :MAGICBOUNCE && !PBStuff::TWOTURNMOVE.include?(@battle.battlers[i].effects[:TwoTurnAttack])) || 
        (@battle.battlers[i]).effects[:MagicCoat]
         attacker.pbOwnSide.effects[:StealthRock]=true
         @battle.pbDisplay(_INTL("{1} bounced the Stealth Rocks back!",(@battle.battlers[i]).pbThis))
         if @battle.pbIsOpposing?(attacker.index)
            @battle.pbDisplay(_INTL("Pointed stones float in the air around your foe's team!"))
         else
            @battle.pbDisplay(_INTL("Pointed stones float in the air around your team!"))
         end
       return 0
       break
      end
    end
    attacker.pbOpposingSide.effects[:StealthRock]=true
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("Pointed stones float in the air around your foe's team!"))
    else
      @battle.pbDisplay(_INTL("Pointed stones float in the air around your team!"))
    end
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if @move == :STONEAXE && !attacker.pbOpposingSide.effects[:StealthRock]
      attacker.pbOpposingSide.effects[:StealthRock]=true
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("Pointed stones float in the air around your foe's team!"))
      else
        @battle.pbDisplay(_INTL("Pointed stones float in the air around your team!"))
      end
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :STONEAXE
      @battle.pbAnimation(:ACCELEROCK,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# If used after ally's Fire Pledge, makes a sea of fire on the opposing side. (Grass Pledge)
################################################################################
class PokeBattle_Move_106 < PokeBattle_Move
  # THIS ONE IS GRASS PLEDGE
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    ret if !@battle.canChangeFE?
    fieldbefore = @battle.field.effect
    duration=4
    duration=7 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
    @battle.setPledge(:GRASSPLEDGE,duration)
    if @battle.field.effect == fieldbefore #field didn't change
      case @battle.field.effect
        when :BURNING then @battle.pbDisplay(_INTL("The pledges combined and fanned the flames!"))
        when :SWAMP then @battle.pbDisplay(_INTL("The pledges combined and reinforced the swamp!"))
        else #same field; means there wasn't another pledge used
          @battle.pbDisplay(_INTL("The Grass Pledge lingers in the air..."))
          return ret
      end
      if @battle.field.duration > 0 
        @battle.field.duration=duration
      end
    else
      case @battle.field.effect
        when :BURNING then @battle.pbDisplay(_INTL("The pledges combined and set the field ablaze!"))
        when :SWAMP then @battle.pbDisplay(_INTL("The pledges combined and formed a swamp!"))
      end
    end
    return ret
  end
end

################################################################################
# If used after ally's Water Pledge, makes a rainbow appear on the user's side. (Fire Pledge)
################################################################################
class PokeBattle_Move_107 < PokeBattle_Move
  # THIS ONE IS FIRE PLEDGE
  def pbOnStartUse(attacker)
    if @battle.FE == :CORROSIVEMIST
      bearer=@battle.pbCheckGlobalAbility(:DAMP)
      if bearer && @battle.FE == :CORROSIVEMIST #Corrosive Mist Field
        @battle.pbDisplay(_INTL("{1}'s {2} prevents {3} from using {4}!",
        bearer.pbThis,getAbilityName(bearer.ability),attacker.pbThis(true),@name))
        return false
      end
    end
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if (@move == :WILDFIRE)
      setField(:BURNING,fielduration=4)
      @battle.pbDisplay(_INTL("The wildfire spreads across the opposing team!"))
    end
    ret if !@battle.canChangeFE?
    fieldbefore = @battle.field.effect
    duration=4
    duration=7 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
    @battle.setPledge(:FIREPLEDGE,duration)
    if @battle.field.effect == fieldbefore #field didn't change
      case @battle.field.effect
        when :BURNING,:VOLCANIC then @battle.pbDisplay(_INTL("The pledges combined and fanned the flames!"))
        when :RAINBOW then @battle.pbDisplay(_INTL("The pledges combined to refresh the rainbow!"))
        else #same field; means there wasn't another pledge used
          @battle.pbDisplay(_INTL("The Fire Pledge lingers in the air..."))
          return ret
      end
      if @battle.field.duration > 0 
        @battle.field.duration= duration
      end
    else
      case @battle.field.effect
        when :BURNING,:VOLCANIC then @battle.pbDisplay(_INTL("The pledges combined and set the field ablaze!"))
        when :RAINBOW then @battle.pbDisplay(_INTL("The pledges combined to form a rainbow!"))
      end
    end
    return ret
  end
end

################################################################################
# If used after ally's Grass Pledge, makes a swamp appear on the opposing side. (water Pledge)
################################################################################
class PokeBattle_Move_108 < PokeBattle_Move
  # THIS ONE IS WATER PLEDGE
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    ret if !@battle.canChangeFE?
    fieldbefore = @battle.field.effect
    duration=4
    duration=7 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
    @battle.setPledge(:GRASSPLEDGE,duration)
    if @battle.field.effect == fieldbefore #field didn't change
      case @battle.field.effect
        when :SWAMP then @battle.pbDisplay(_INTL("The pledges combined and reinforced the swamp!"))
        when :RAINBOW then @battle.pbDisplay(_INTL("The pledges combined to refresh the rainbow!"))
        else #same field; means there wasn't another pledge used
          @battle.pbDisplay(_INTL("The Water Pledge lingers in the air..."))
          return ret
      end
      if @battle.field.duration > 0 
        @battle.field.duration=duration
      end
    else
      case @battle.field.effect
        when :SWAMP then @battle.pbDisplay(_INTL("The pledges combined and formed a swamp!"))
        when :RAINBOW then @battle.pbDisplay(_INTL("The pledges combined to form a rainbow!"))
      end
    end
    return ret
  end
end

################################################################################
# Scatters coins that the player picks up after winning the battle. (Pay Day)
################################################################################
class PokeBattle_Move_109 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if @battle.pbOwnedByPlayer?(attacker.index)
        @battle.extramoney+=5*attacker.level
        if @battle.FE == :BIGTOP || @battle.FE == :DRAGONSDEN
          @battle.extramoney+=495*attacker.level
        end
        @battle.extramoney=MAXMONEY if @battle.extramoney>MAXMONEY
      end
      if @battle.FE == :DRAGONSDEN
        @battle.pbDisplay(_INTL("Treasure scattered everywhere!"))
      else
        @battle.pbDisplay(_INTL("Coins were scattered everywhere!"))
      end
    end
    return ret
  end
end

################################################################################
# Ends the opposing side's Light Screen and Reflect. (Brick Break / Psychic Fangs)
################################################################################
class PokeBattle_Move_10A < PokeBattle_Move
  def pbCalcDamage(attacker,opponent, hitnum: 0)
    return super(attacker,opponent,0, hitnum: hitnum)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if ret==0
      return ret
    end
    if attacker.pbOpposingSide.effects[:Reflect]>0
      attacker.pbOpposingSide.effects[:Reflect]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team's Reflect wore off!"))
      else
        @battle.pbDisplay(_INTL("Your team's Reflect wore off!"))
      end
    end
    if attacker.pbOpposingSide.effects[:LightScreen]>0
      attacker.pbOpposingSide.effects[:LightScreen]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team's Light Screen wore off!"))
      else
        @battle.pbDisplay(_INTL("Your team's Light Screen wore off!"))
      end
    end
    if attacker.pbOpposingSide.effects[:PriorityGuard]>0
      attacker.pbOpposingSide.effects[:PriorityGuard]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team is no longer protected from priority attacks!"))
      else
        @battle.pbDisplay(_INTL("Your team is no longer protected from priority attacks!"))
      end
    end
    if attacker.pbOpposingSide.effects[:AuroraVeil]>0
      attacker.pbOpposingSide.effects[:AuroraVeil]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team's Aurora Veil wore off!"))
      else
        @battle.pbDisplay(_INTL("Your team's Aurora Veil wore off!"))
      end
    end
    if attacker.pbOpposingSide.effects[:AreniteWall]>0
      attacker.pbOpposingSide.effects[:AreniteWall]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("The opposing team's Arenite Wall wore off!"))
      else
        @battle.pbDisplay(_INTL("Your team's Arenite Wall wore off!"))
      end
    end
    return ret
  end
end

################################################################################
# If attack misses, user takes crash damage of 1/2 of max HP. (High Jump Kick / Jump Kick)
################################################################################
class PokeBattle_Move_10B < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return @battle.state.effects[:Gravity]!=0 && attacker.ability != :GRAVFLUX
  end
end

################################################################################
# User turns 1/4 of max HP into a substitute. (Substitute)
################################################################################
class PokeBattle_Move_10C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("{1} already has a substitute!",attacker.pbThis))
      return -1
    end
    sublife=[(attacker.totalhp/4.0).floor,1].max
    if attacker.hp<=sublife
      @battle.pbDisplay(_INTL("It was too weak to make a substitute!"))
      return -1
    end
    attacker.pbReduceHP(sublife,false,false)
    attacker.effects[:UsingSubstituteRightNow]=true
    attacker.battle.scene.pbAnimation(self,attacker,opponent,hitnum)  #pbShowAnimation(@move,attacker,nil,hitnum,alltargets,true)
    attacker.effects[:UsingSubstituteRightNow]=false
    #@battle.scene.pbSubstituteSprite(attacker,attacker.pbIsOpposing?(1))
    attacker.effects[:MultiTurn]=0
    attacker.effects[:MultiTurnAttack]=0
    attacker.effects[:Substitute]=sublife
    @battle.pbDisplay(_INTL("{1} put in a substitute!",attacker.pbThis))
    return 0
  end
end

################################################################################
# User is not Ghost: Decreases user's Speed, increases user's Attack & Defense by
# 1 stage each. (Curse)
# User is Ghost: User loses 1/2 of max HP, and curses the target.
# Cursed Pokémon lose 1/4 of their max HP at the end of each round.
################################################################################
class PokeBattle_Move_10D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    failed=false
    if !attacker.hasType?(:GHOST)
      lowerspeed=attacker.pbCanReduceStatStage?(PBStats::SPEED,false,true)
      raiseatk=attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      raisedef=attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      if !lowerspeed && !raiseatk && !raisedef
        failed=true
      else
        @battle.pbCommonAnimation("CurseNoGhost",attacker,nil)
        if lowerspeed
          attacker.pbReduceStat(PBStats::SPEED,1,abilitymessage:false, statdropper: attacker)
        end
        showanim=true
        if raiseatk
          attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
          showanim=false
        end
        if raisedef
          attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
          showanim=false
        end
      end
    else
      if opponent.effects[:Curse]
        failed=true
      else
        pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
        if @battle.FE == :HAUNTED
          attacker.pbReduceHP((attacker.totalhp/4.0).floor,false,false)
        else
          attacker.pbReduceHP((attacker.totalhp/2.0).floor,false,false)
        end
        opponent.effects[:Curse]=true
        @battle.pbDisplay(_INTL("{1} cut its own HP and laid a curse on {2}!",attacker.pbThis,opponent.pbThis(true)))
      end
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
    end
    return failed ? -1 : 0
  end
end

################################################################################
# Target's last move used loses 4 PP. (Spite)
################################################################################
class PokeBattle_Move_10E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    for i in opponent.moves
      if i && $cache.moves[i.move].move==opponent.lastMoveUsed && i.pp>0
        pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
        drop = 4
        drop = 6 if @battle.FE == :HAUNTED
        reduction=[drop,i.pp].min
        opponent.pbSetPP(i,i.pp-reduction)
        @battle.pbDisplay(_INTL("It reduced the PP of {1}'s {2} by {3}!",opponent.pbThis(true),i.name,reduction))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("But it failed!"))
    return -1
  end
end

################################################################################
# Target will lose 1/4 of max HP at end of each round, while asleep. (Nightmare)
################################################################################
class PokeBattle_Move_10F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if ((opponent.status!=:SLEEP && @battle.FE != :INFERNAL && (attacker.ability != :WORLDOFNIGHTMARES || attacker.crested == :DARKRAI)) && 
      (attacker.ability != :COMATOSE || @battle.FE == :ELECTERRAIN)) ||
       opponent.effects[:Nightmare] || opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:Nightmare]=true
    opponent.effects[:MeanLook]=attacker.index if (attacker.ability == :WORLDOFNIGHTMARES || attacker.crested == :DARKRAI)
    @battle.pbDisplay(_INTL("{1} began having a nightmare!",opponent.pbThis))
    return 0
  end
end

################################################################################
# Removes trapping moves, entry hazards and Leech Seed on user/user's side. (Rapid Spin)
################################################################################
class PokeBattle_Move_110 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted? && opponent.damagestate.calcdamage>0
      if attacker.effects[:MultiTurn]>0
        mtattack=getMoveName(attacker.effects[:MultiTurnAttack])
        mtuser=@battle.battlers[attacker.effects[:MultiTurnUser]]
        @battle.pbDisplay(_INTL("{1} got free of {2}'s {3}!",attacker.pbThis,mtuser.pbThis(true),mtattack))
        attacker.effects[:MultiTurn]=0
        attacker.effects[:MultiTurnAttack]=0
        attacker.effects[:MultiTurnUser]=-1
      end
      if attacker.effects[:LeechSeed]>=0
        attacker.effects[:LeechSeed]=-1
        @battle.pbDisplay(_INTL("{1} shed Leech Seed!",attacker.pbThis))
      end
      if (@battle.state.effects[:LockHazards])
        @battle.pbDisplay(_INTL("Entry hazards are locked!"))
      else
        if attacker.pbOwnSide.effects[:StealthRock]
          attacker.pbOwnSide.effects[:StealthRock]=false
          @battle.pbDisplay(_INTL("{1} blew away stealth rocks!",attacker.pbThis))
        end
        if attacker.pbOwnSide.effects[:InvStealthRock]
          attacker.pbOwnSide.effects[:InvStealthRock]=false
          @battle.pbDisplay(_INTL("{1} blew away the mysterious rocks!",attacker.pbThis))
        end
        if attacker.pbOwnSide.effects[:Steelsurge]
          attacker.pbOwnSide.effects[:Steelsurge]=false
          @battle.pbDisplay(_INTL("{1} blew away the steel debris!",attacker.pbThis))
        end
        if attacker.pbOwnSide.effects[:Volcalith]
          attacker.pbOwnSide.effects[:Volcalith]=false
          @battle.pbDisplay(_INTL("{1} blew away the molten rocks!",attacker.pbThis))
        end
        if attacker.pbOwnSide.effects[:Spikes]>0
          attacker.pbOwnSide.effects[:Spikes]=0
          @battle.pbDisplay(_INTL("{1} blew away Spikes!",attacker.pbThis))
        end
        if attacker.pbOwnSide.effects[:ToxicSpikes]>0
          attacker.pbOwnSide.effects[:ToxicSpikes]=0
          @battle.pbDisplay(_INTL("{1} blew away poison spikes!",attacker.pbThis))
        end
        if attacker.pbOwnSide.effects[:StickyWeb]
          attacker.pbOwnSide.effects[:StickyWeb]=false
          @battle.pbDisplay(_INTL("{1} blew away the sticky webbing!",attacker.pbThis))
        end
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,abilitymessage:false)
        attacker.pbIncreaseStat(PBStats::SPEED,1,abilitymessage:false)
      end
    end
    return ret
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :OVERGROWTH
      @battle.pbAnimation(:FRENZYPLANT,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Attacks 2 rounds in the future. (Future Sight / Doom Desire)
################################################################################
class PokeBattle_Move_111 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:FutureSight]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    opponent.effects[:FutureSight]=3
    opponent.effects[:FutureSightMove]=@move
    opponent.effects[:FutureSightUser]=attacker.index
    opponent.effects[:FutureSightPokemonIndex]=attacker.pokemonIndex
    if (@move == :FUTURESIGHT)
      @battle.pbDisplay(_INTL("{1} foresaw an attack!",attacker.pbThis))
    else
      @battle.pbDisplay(_INTL("{1} chose Doom Desire as its destiny!",attacker.pbThis))
    end
    return 0
  end
end

################################################################################
# Increases user's Defense and Special Defense by 1 stage each.  Ups user's
# stockpile by 1 (max. 3).
################################################################################
class PokeBattle_Move_112 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:Stockpile]>=3
      @battle.pbDisplay(_INTL("{1} can't stockpile any more!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[:Stockpile]+=1
    @battle.pbDisplay(_INTL("{1} stockpiled {2}!",attacker.pbThis,
        attacker.effects[:Stockpile]))
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
      showanim=false
    end
    attacker.effects[:StockpileDef]+=1
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
      showanim=false
    end
    attacker.effects[:StockpileSpDef]+=1
    return 0
  end
end

################################################################################
# Power is multiplied by the user's stockpile (X).  Reduces the stockpile to 0.
# Decreases user's Defense and Special Defense by X stages each. (Spit Up)
################################################################################
class PokeBattle_Move_113 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    return 300 if @battle.FE == :CONCERT4
    return 100*attacker.effects[:Stockpile]
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:Stockpile]==0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    # if attacker.effects[:StockpileDef]>0
    #   if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,false,true)
    #     attacker.pbReduceStat(PBStats::DEFENSE,attacker.effects[:StockpileDef], abilitymessage:false, statdropper: attacker)
    #     showanim=false
    #   end
    # end
    # if attacker.effects[:StockpileSpDef]>0
    #   if attacker.pbCanReduceStatStage?(PBStats::SPDEF,false,true)
    #     attacker.pbReduceStat(PBStats::SPDEF,attacker.effects[:StockpileSpDef], abilitymessage:false, statdropper: attacker)
    #     showanim=false
    #   end
    # end
    attacker.effects[:Stockpile]=0
    attacker.effects[:StockpileDef]=0
    attacker.effects[:StockpileSpDef]=0
    @battle.pbDisplay(_INTL("{1}'s stockpiled effect wore off!",attacker.pbThis))

    if (attacker.crested == :SWALOT && !PBStuff::FIXEDABILITIES.include?(opponent.ability) && opponent.effects[:Substitute] <= 0 && !opponent.effects[:GastroAcid])
      neutralgas = true if opponent.ability = :NEUTRALIZINGGAS
      opponent.ability = nil  #Cancel out ability
      opponent.effects[:GastroAcid]=true
      opponent.effects[:Truant]=false
      @battle.pbDisplay(_INTL("{1}'s Ability was suppressed!",opponent.pbThis))
    end
    return ret
  end

  def pbType(attacker,type=@type)
    type = attacker.type1
    return super(attacker,type)
  end

end

################################################################################
# Heals user depending on the user's stockpile (X).  Reduces the stockpile to 0.
# Decreases user's Defense and Special Defense by X stages each. (Swallow)
################################################################################
class PokeBattle_Move_114 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    hpgain=0
    case attacker.effects[:Stockpile]
      when 0
        @battle.pbDisplay(_INTL("But it failed to swallow a thing!"))
        return -1
      when 1
        hpgain=(attacker.totalhp/4.0).floor
        hpgain=(attacker.totalhp/2.0).floor if @battle.FE == :WASTELAND
      when 2
        hpgain=(attacker.totalhp/2.0).floor
        hpgain=attacker.totalhp if @battle.FE == :WASTELAND
      when 3
        hpgain=attacker.totalhp
    end
    if attacker.hp==attacker.totalhp &&
       attacker.effects[:StockpileDef]==0 &&
       attacker.effects[:StockpileSpDef]==0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if (@battle.FE == :WASTELAND && attacker.effects[:Stockpile]==3) || attacker.crested == :SWALOT
       t=attacker.status
      attacker.status=nil
      attacker.statusCount=0
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      if t== :BURN
        @battle.pbDisplay(_INTL("{1} was cured of its burn.",attacker.pbThis))
      elsif t== :POISON
        @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",attacker.pbThis))
      elsif t== :PARALYSIS
        @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",attacker.pbThis))
      elsif t== :FROSTBITE
        @battle.pbDisplay(_INTL("{1} was cured of its frostbite.",attacker.pbThis))
      end
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if attacker.pbRecoverHP(hpgain,true)>0
      @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbThis))
    end
    showanim=true
    # if attacker.effects[:StockpileDef]>0
    #   if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,false,true)
    #     attacker.pbReduceStat(PBStats::DEFENSE,attacker.effects[:StockpileDef], abilitymessage:false, statdropper: attacker)
    #     showanim=false
    #   end
    # end
    # if attacker.effects[:StockpileSpDef]>0
    #   if attacker.pbCanReduceStatStage?(PBStats::SPDEF,false,true)
    #     attacker.pbReduceStat(PBStats::SPDEF,attacker.effects[:StockpileSpDef], abilitymessage:false, statdropper: attacker)
    #     showanim=false
    #   end
    # end
    attacker.effects[:Stockpile]=0
    attacker.effects[:StockpileDef]=0
    attacker.effects[:StockpileSpDef]=0
    @battle.pbDisplay(_INTL("{1}'s stockpiled effect wore off!",attacker.pbThis))

    if (attacker.crested == :SWALOT)
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
        attacker.effects[:StockpileDef]+=1
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
        attacker.effects[:StockpileSpDef]+=1
        showanim=false
      end
      @battle.pbDisplay(_INTL("{1}'s increased its defenses!",attacker.pbThis))
    end

    return 0
  end
end

#################################################################################
# Fails if user was hit by a damaging move this round. (Focus Punch)
################################################################################
class PokeBattle_Move_115 < PokeBattle_Move
  def pbDisplayUseMessage(attacker,choice)
    if attacker.lastHPLost>0 || @battle.FE == :ELECTERRAIN # Electric Field
      @battle.pbDisplay(_INTL("{1} lost its focus and couldn't move!",attacker.pbThis))
      return -1
    end
    return super(attacker,choice)
  end
end

################################################################################
# Fails if the target didn't chose a damaging move to use this round, or has
# already moved. (Sucker Punch)
################################################################################
class PokeBattle_Move_116 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.hasMovedThisRound?
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if opponent.effects[:HyperBeam]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if @battle.switchedOut[opponent.index]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if opponent.itemUsed
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if opponent.effects[:Protect] && ((@battle.choices[opponent.index][2] == nil) || (@battle.choices[opponent.index][2] == 0) || (@battle.choices[opponent.index][2] == -1) || (@battle.choices[opponent.index][2].basedamage == 0))
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    elsif opponent.effects[:Protect]==:KingsShield
      @battle.pbDisplay(_INTL("{1} protected itself!", opponent.pbThis))
      attacker.pbReduceStat(PBStats::ATTACK, 2, statdropper: opponent)
      attacker.pbReduceStat(PBStats::SPATK, 2, statdropper: opponent) if @battle.FE == :FAIRYTALE || @battle.FE == :CHESS
      return -1
    elsif opponent.effects[:Protect]==:SpikyShield
      @battle.pbDisplay(_INTL("{1} protected itself!", opponent.pbThis))
      if attacker.ability != (:LONGREACH)
        attacker.pbReduceHP((attacker.totalhp/8.0).floor)
        @battle.pbDisplay(_INTL("{1}'s Spiky Shield hurt {2}!",opponent.pbThis,attacker.pbThis(true)))
      end
      return -1
    elsif opponent.effects[:Protect]==:Parry
      opponent.pbIncreaseStat(PBStats::ATTACK, 2)
      opponent.effects[:Protect] = false
    end
    if (@battle.choices[opponent.index][2] == nil) || (@battle.choices[opponent.index][2] == 0) || (@battle.choices[opponent.index][2] == -1) || (@battle.choices[opponent.index][2].basedamage == 0)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    return super
  end
end

################################################################################
# This round, user becomes the target of attacks that have single targets. 
# (Follow Me, Rage Powder)
################################################################################
class PokeBattle_Move_117 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if (!@battle.doublebattle && @basedamage == 0)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if (@move == :RAGEPOWDER)
      attacker.effects[:RagePowder]=true
      if !attacker.pbPartner.isFainted?
        attacker.pbPartner.effects[:FollowMe]=false
        attacker.pbPartner.effects[:RagePowder]=false
      end
    else
      attacker.effects[:FollowMe]=true
      if !attacker.pbPartner.isFainted?
        attacker.pbPartner.effects[:FollowMe]=false
        attacker.pbPartner.effects[:RagePowder]=false
      end
    end
    @battle.pbDisplay(_INTL("{1} became the center of attention!",attacker.pbThis))
    return 0
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :GOLDRUSH
      @battle.pbAnimation(:PAYDAY,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(@move,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# For 5 rounds, increases gravity on the field.  Pokémon cannot become airborne. (Gravity)
################################################################################
class PokeBattle_Move_118 < PokeBattle_Move
  def pbIsPhysical?(type=@type)
    return true if @battle.FE == :DEEPEARTH
    return false
  end

  def pbIsStatus?(type=@type)
    return false if @battle.FE == :DEEPEARTH
    return true
  end
  
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.FE == :DEEPEARTH
      if (opponent.ability == :GRAVFLUX)
        @battle.pbDisplay(_INTL("It doesn't affect {1}...", opponent.pbThis))
        return -1
      end
      hploss = (opponent.hp/2.0).floor
      return pbEffectFixedDamage(hploss,attacker,opponent,hitnum,alltargets,showanimation)
    end
    if @battle.state.effects[:Gravity]!=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.state.effects[:Gravity]=5
    # @Swu flag1
    @battle.state.effects[:Gravity]=8 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
    @battle.state.effects[:Gravity]=8 if @battle.FE == :PSYTERRAIN
    if @battle.FE == :DIMENSIONAL
      rnd=@battle.pbRandom(6)
      @battle.state.effects[:Gravity]=3+rnd
    end
    for i in 0...4
      poke=@battle.battlers[i]
      next if !poke
      if !$cache.moves[poke.effects[:TwoTurnAttack]].nil? && 
        ($cache.moves[poke.effects[:TwoTurnAttack]].function==0xC9 || # Fly
         $cache.moves[poke.effects[:TwoTurnAttack]].function==0xCC || # Bounce
         $cache.moves[poke.effects[:TwoTurnAttack]].function==0xCE)    # Sky Drop
        poke.effects[:TwoTurnAttack]=0
      end
      if poke.effects[:SkyDrop]
        poke.effects[:SkyDrop]=false
      end
      if poke.effects[:MagnetRise]!=0
        poke.effects[:MagnetRise]=0
      end
      if poke.effects[:Telekinesis]>0
        poke.effects[:Telekinesis]=0
      end
    end
    @battle.pbDisplay(_INTL("Gravity intensified!"))
    return 0
    return pbEffectFixedDamage(hploss,attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# For 5 rounds, user becomes airborne. (Magnet Rise)
################################################################################
class PokeBattle_Move_119 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return (@battle.state.effects[:Gravity])!=0 if @battle.FE != :DEEPEARTH && attacker.ability != :GRAVFLUX
    return false
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.FE != :DEEPEARTH
      if attacker.effects[:Ingrain] ||
        attacker.effects[:SmackDown] ||
        attacker.effects[:MagnetRise]!=0
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      attacker.effects[:MagnetRise]=5
      if @battle.FE == :ELECTERRAIN || @battle.FE == :FACTORY ||
        @battle.FE == :SHORTCIRCUIT || @battle.state.effects[:ELECTERRAIN] > 0 # Electric/Factory Field
            attacker.effects[:MagnetRise]=8
      end
      @battle.pbDisplay(_INTL("{1} levitated with electromagnetism!",attacker.pbThis))
      return 0
    else
      return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,true)
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      attacker.pbIncreaseStat(PBStats::SPEED,2,abilitymessage:false)
      @battle.pbDisplay(_INTL("{1} uses electromagnetism to move faster!",attacker.pbThis))
      return 0
    end
  end
end

################################################################################
# For 3 rounds, target becomes airborne and can always be hit. (Telekinesis)
################################################################################
class PokeBattle_Move_11A < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return @battle.state.effects[:Gravity]!=0 && opponent.ability != :GRAVFLUX
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Ingrain] ||
       opponent.effects[:SmackDown] ||
       opponent.effects[:Telekinesis]>0 ||
       opponent.species==:DIGLETT || opponent.species==:DUGTRIO || opponent.species==:SANDYGAST || opponent.species==:PALOSSAND || (opponent.species==:GENGAR && opponent.form==1)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:Telekinesis]=3
    @battle.pbDisplay(_INTL("{1} was hurled into the air!",opponent.pbThis))
    if @battle.FE == :PSYTERRAIN
      opponent.pbReduceStat(PBStats::DEFENSE,2,abilitymessage:false, statdropper: attacker) if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,false)
      opponent.pbReduceStat(PBStats::SPDEF,2,abilitymessage:false, statdropper: attacker) if opponent.pbCanReduceStatStage?(PBStats::SPDEF,false)
    end

    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:MeanLook]=attacker.index
    @battle.pbDisplay(_INTL("{1} can't escape now!",opponent.pbThis))
    return 0
  end
end

################################################################################
# Hits airborne semi-invulnerable targets.
################################################################################
class PokeBattle_Move_11B < PokeBattle_Move
# Handled in Battler class, do not edit!
end

################################################################################
# Grounds the target while it remains active. (Smack Down, Thousand Arrows)
# (Handled in Battler's pbSuccessCheck): Hits some semi-invulnerable targets.
################################################################################
class PokeBattle_Move_11C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
      !opponent.effects[:Roost] && !(opponent.ability == :GRAVFLUX && @battle.state.effects[:Gravity] != 0)
      opponent.effects[:SmackDown]=true
      showmsg=false
      showmsg=true if opponent.hasType?(:FLYING) ||
                      opponent.ability == :LEVITATE || opponent.ability == :SOLARIDOL || opponent.ability == :LUNARIDOL || opponent.crested == :VESPIQUEN || opponent.crested == :LUMINEON || opponent.ability == :GRAVFLUX
      if !$cache.moves[opponent.effects[:TwoTurnAttack]].nil? && 
        ($cache.moves[opponent.effects[:TwoTurnAttack]].function==0xC9 || # Fly
         $cache.moves[opponent.effects[:TwoTurnAttack]].function==0xCC)    # Bounce
        opponent.effects[:TwoTurnAttack]=0; showmsg=true
      end
      if opponent.effects[:MagnetRise]!=0
        opponent.effects[:MagnetRise]=0; showmsg=true
      end
      if opponent.effects[:Telekinesis]>0
        opponent.effects[:Telekinesis]=0; showmsg=true
      end
      @battle.pbDisplay(_INTL("{1} fell straight down!",opponent.pbThis)) if showmsg
    end
    return ret
  end
end

################################################################################
# Target moves immediately after the user, ignoring priority/speed. (After You)
################################################################################
class PokeBattle_Move_11D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    success = @battle.pbMoveAfter(attacker, opponent)
    if success
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.pbDisplay(_INTL("{1} took the kind offer!", opponent.pbThis))
      return 0
    else
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# Target moves last this round, ignoring priority/speed. (Quash)
################################################################################
class PokeBattle_Move_11E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    success = @battle.pbMoveLast(opponent)
    if success
      @battle.pbDisplay(_INTL("{1}'s move was postponed!", opponent.pbThis))
      return 0
    else
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# For 5 rounds, for each priority bracket, slow Pokémon move before fast ones. (Trick Room)
################################################################################
class PokeBattle_Move_11F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (@battle.FE == :BEWITCHED)
      @battle.pbDisplay(_INTL("{1} twisted the dimensions...",attacker.pbThis))
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.pbDisplay(_INTL("...but the dimensions twisted back!",attacker.pbThis))
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      return 0
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.trickroom == 0
      @battle.trickroom=5
      if [:CHESS,:NEWWORLD,:PSYTERRAIN].include?(@battle.FE) || attacker.hasWorkingItem(:AMPLIFIELDROCK) || (Rejuv && @battle.FE == :STARLIGHT)
        @battle.trickroom=8
      end
      if @battle.FE == :DIMENSIONAL
        rnd=@battle.pbRandom(6)
        @battle.trickroom=3+rnd
      end
      @battle.pbDisplay(_INTL("{1} twisted the dimensions!",attacker.pbThis))
    else
      @battle.trickroom=0
      @battle.pbDisplay(_INTL("The twisted dimensions returned to normal!",attacker.pbThis))
    end
    for i in @battle.battlers
      if i.hasWorkingItem(:ROOMSERVICE)
        if i.pbCanReduceStatStage?(PBStats::SPEED)
          i.pbReduceStatBasic(PBStats::SPEED,6)
          @battle.pbCommonAnimation("StatDown",i,nil)
          @battle.pbDisplay(_INTL("The Room Service drastically lowered #{i.pbThis}'s Speed!"))
          i.pbDisposeItem(false)
        end
      end
    end
    return 0
  end
end

################################################################################
# User switches places with its ally. (Ally Switch)
################################################################################

class PokeBattle_Move_120 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.pbCanChooseNonActive?(attacker.index)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("{1} went back to {2}!",attacker.pbThis,@battle.pbGetOwner(attacker.index).name))
    newpoke=0
    newpoke=@battle.pbSwitchInBetween(attacker.index,true,false)
    @battle.pbMessagesOnReplace(attacker.index,newpoke)
    attacker.pbResetForm
    @battle.pbReplace(attacker.index,newpoke)
    @battle.pbOnActiveOne(attacker)
    attacker.pbAbilitiesOnSwitchIn(true)
    return 0
  end
end

################################################################################
# Target's Attack is used instead of user's Attack for this move's calculations.
################################################################################
class PokeBattle_Move_121 < PokeBattle_Move
# Handled in superclass, do not edit!
end

################################################################################
# Target's Defense is used instead of its Special Defense for this move's
# calculations.
################################################################################
class PokeBattle_Move_122 < PokeBattle_Move
# Handled in superclass, do not edit!
end
 

################################################################################
# Only damages Pokémon that share a type with the user. (Synchronoise)
################################################################################
class PokeBattle_Move_123 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !opponent.hasType?(attacker.type1) && (!opponent.hasType?(attacker.type2) || attacker.type2.nil?)
      @battle.pbDisplay(_INTL("{1} was unaffected!",opponent.pbThis))
      return -1
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# For 5 rounds, swaps all battlers' base Defense with base Special Defense. (Wonder Room)
################################################################################
class PokeBattle_Move_124 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.state.effects[:WonderRoom] == 0
      @battle.state.effects[:WonderRoom] = 5
      if @battle.FE == :NEWWORLD || @battle.FE == :PSYTERRAIN || # New World, Psychic Terrain
        attacker.hasWorkingItem(:AMPLIFIELDROCK) || (Rejuv && @battle.FE == :STARLIGHT)
        @battle.state.effects[:WonderRoom] = 8
      end
      if @battle.FE == :DIMENSIONAL
        rnd=@battle.pbRandom(6)
        @battle.state.effects[:WonderRoom]=3+rnd
      end
      for i in @battle.battlers
        i.pbSwapDefenses
      end
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.pbDisplay(_INTL("{1} created a bizarre area in which the Defense and Sp. Def stats are swapped!",attacker.pbThis))
    else
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.state.effects[:WonderRoom] = 0
      @battle.pbDisplay(_INTL("Wonder Room wore off, and the Defense and Sp. Def stats returned to normal!"))
      for i in @battle.battlers
        i.pbSwapDefenses
      end
    end
    return 0
  end
#### Inuki was here kuro's a LOSER
end

################################################################################
# Fails unless user has already used all other moves it knows. (Last Resort)
################################################################################

class PokeBattle_Move_125 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    totalMoves = {}
    for i in attacker.moves
      totalMoves[i.move] = false
      if i.function == 0x125
        totalMoves[i.move] = true
      end
      if i.move.nil?
        totalMoves[i.move] = true
      end
    end
    for i in attacker.movesUsed
      for j in attacker.moves
        if i == j.move
          totalMoves[j.move] = true
        end
      end
    end
    for i in attacker.moves
      if !totalMoves[i.move] && @battle.FE!= :DARKNESS1
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

#===============================================================================
# NOTE: Shadow moves use function codes 126-132 inclusive.  If you're inventing
#       new move effects, use function code 133 and onwards.
#===============================================================================

################################################################################
# 133- King's Shield
################################################################################
class PokeBattle_Move_133 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if @battle.pbRandom(65536)<(65536/(3**attacker.effects[:ProtectRate])).floor
      attacker.effects[:Protect]=:KingsShield
      attacker.effects[:ProtectRate]+=1
      @battle.pbAnimation(@move,attacker,nil)
      @battle.pbDisplay(_INTL("{1} shielded itself against damage!",attacker.pbThis))
      return 0
    else
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# 134- Electric Terrain
################################################################################
class PokeBattle_Move_134 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !((!Rejuv && @battle.canChangeFE?(:ELECTERRAIN)) || (@battle.canChangeFE?([:ELECTERRAIN,:DRAGONSDEN]) && !(@battle.state.effects[:ELECTERRAIN] > 0)))
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    duration=5
    duration=8 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
    @battle.setField(:ELECTERRAIN,duration)
    @battle.pbDisplay(_INTL("The terrain became electrified!"))
    return 0
  end
end

################################################################################
# 135- Grassy Terrain
################################################################################
class PokeBattle_Move_135 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if  !((!Rejuv && @battle.canChangeFE?(:GRASSY)) || (@battle.canChangeFE?([:GRASSY,:DRAGONSDEN]) && !(@battle.state.effects[:GRASSY] > 0)))
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    duration=5
    duration=8 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
    @battle.setField(:GRASSY,duration)
    @battle.pbDisplay(_INTL("The terrain became grassy!"))
    return 0
  end
end

################################################################################
# 136- Misty Terrain
################################################################################
class PokeBattle_Move_136 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !((!Rejuv && @battle.canChangeFE?(:MISTY)) || (@battle.canChangeFE?([:MISTY,:CORROSIVEMIST]) && !(@battle.state.effects[:MISTY] > 0)))
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    duration=5
    duration=8 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
    @battle.setField(:MISTY,duration)
    @battle.pbDisplay(_INTL("The terrain became misty!"))
    return 0
  end
end

################################################################################
# 137- Flying Press (not type effect; double damage + always hit while
#target is minimized. Accuracy handled in pbAccuracy Check)
################################################################################
class PokeBattle_Move_137 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return @battle.state.effects[:Gravity]!=0 && attacker.ability != :GRAVFLUX
  end

  def pbAdditionalEffect(attacker,opponent)
    return false
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    damagemult*= 2.0 if opponent.effects[:Minimize]
    return damagemult
  end
end

################################################################################
# Decreases the target's Attack and Special Attack by 1 stage each. (Noble Roar/Tearful Look)
################################################################################
class PokeBattle_Move_138 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    ret=-1; prevented=false
    if opponent.effects[:Protect] && !opponent.effects[:ProtectNegation]
      @battle.pbDisplay(_INTL("{1} protected itself!",opponent.pbThis))
      prevented=true
    end
    if !prevented && opponent.pbOwnSide.effects[:Mist]>0
      @battle.pbDisplay(_INTL("{1} is protected by Mist!",opponent.pbThis))
      prevented=true
    end
    if !prevented && ((((opponent.ability == :CLEARBODY) ||
       (opponent.ability == :WHITESMOKE)) && !(opponent.moldbroken)) || opponent.ability == :FULLMETALBODY)
      @battle.pbDisplay(_INTL("{1}'s {2} prevents stat loss!",opponent.pbThis,
         getAbilityName(opponent.ability)))
      prevented=true
    end
    if !prevented && opponent.pbTooLow?(PBStats::ATTACK) &&
       opponent.pbTooLow?(PBStats::SPATK)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any lower!",opponent.pbThis))
      prevented=true
    end
    if !prevented
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      showanim=true
      if (@battle.FE == :FAIRYTALE || @battle.FE == :DRAGONSDEN)  && (@move == :NOBLEROAR)
        if opponent.pbReduceStat(PBStats::ATTACK,2,abilitymessage:false, statdropper: attacker)
          ret=0; showanim=false
        end
        if opponent.pbReduceStat(PBStats::SPATK,2,abilitymessage:false, statdropper: attacker)
          ret=0; showanim=false
        end
      else
        if opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
          ret=0; showanim=false
        end
        if opponent.pbReduceStat(PBStats::SPATK,1,abilitymessage:false, statdropper: attacker)
          ret=0; showanim=false
        end
      end
    end
    return ret
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::ATTACK,false)
      opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
    end
    if opponent.pbCanReduceStatStage?(PBStats::SPATK,false)
      opponent.pbReduceStat(PBStats::SPATK,1,abilitymessage:false, statdropper: attacker)
    end
    return true
  end
end

################################################################################
# User gains 75% of the HP it inflicts as damage. (Draining Kiss/Oblivion Wing)
################################################################################
class PokeBattle_Move_139 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      hpgain=((opponent.damagestate.hplost+1)*0.75).floor
      if (opponent.ability == :LIQUIDOOZE)
        hpgain*=2 if @battle.FE == :WASTELAND || @battle.FE == :MURKWATERSURFACE || @battle.FE == :CORRUPTED
        attacker.pbReduceHP(hpgain,true)
        @battle.pbDisplay(_INTL("{1} sucked up the liquid ooze!",attacker.pbThis))
      else
        if Rejuv && @battle.FE == :GRASSY
          hpgain=(hpgain*1.6).floor if attacker.hasWorkingItem(:BIGROOT)
        else
          hpgain=(hpgain*1.3).floor if attacker.hasWorkingItem(:BIGROOT)
        end
        hpgain=(hpgain*1.3).floor if attacker.crested == :SHIINOTIC
        attacker.pbRecoverHP(hpgain,true)
        @battle.pbDisplay(_INTL("{1} had its energy drained!",opponent.pbThis))
      end
    end
    if @battle.FE == :FAIRYTALE && (@move == :DRAININGKISS)
      if !opponent.damagestate.substitute && opponent.status== :SLEEP
        opponent.pbCureStatus
      end
    end
    return ret
  end
end

################################################################################
# Spiky Shield
################################################################################
class PokeBattle_Move_140 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if @battle.pbRandom(65536)<(65536/(3**attacker.effects[:ProtectRate])).floor
      attacker.effects[:Protect]=:SpikyShield
      attacker.effects[:ProtectRate]+=1
      @battle.pbAnimation(@move,attacker,nil)
      @battle.pbDisplay(_INTL("{1} shielded itself against damage!",attacker.pbThis))
      return 0
    else
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# Increases the target's Special Defense by 1 stage. (Aromatic Mist)
################################################################################
class PokeBattle_Move_13A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    if !@battle.doublebattle
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    return -1 if !attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::SPDEF,true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if @battle.FE == :MISTY
      ret=attacker.pbPartner.pbIncreaseStat(PBStats::SPDEF,2,abilitymessage:false)
    else
      ret=attacker.pbPartner.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      if @battle.FE == :MISTY
        attacker.pbPartner.pbIncreaseStat(PBStats::SPDEF,2,abilitymessage:false)
      else
        attacker.pbPartner.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
      end
    end
    return true
  end
end

################################################################################
# Decreases the target's Special Attack by 2 stages. (Eerie Impulse)
################################################################################
class PokeBattle_Move_13B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPATK,true)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    if @battle.FE == :ELECTERRAIN || @battle.FE == :DEEPEARTH
      ret=opponent.pbReduceStat(PBStats::SPATK,3,abilitymessage:false, statdropper: attacker)
    else
      ret=opponent.pbReduceStat(PBStats::SPATK,2,abilitymessage:false, statdropper: attacker)
    end
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::SPATK,false)
      if @battle.FE == :ELECTERRAIN
        opponent.pbReduceStat(PBStats::SPATK,3,abilitymessage:false, statdropper: attacker)
      else
        opponent.pbReduceStat(PBStats::SPATK,2,abilitymessage:false, statdropper: attacker)
      end
    end
    return true
  end
end

################################################################################
#  Belch
################################################################################
class PokeBattle_Move_13C <PokeBattle_Move
  def pbOnStartUse(attacker)
    if attacker.pokemon.belch == true || attacker.crested == :SWALOT
      return true
    else
      @battle.pbDisplay("But it failed!")
      return false
    end
  end
end

##################################################################
# After lowering stats, user switches out. (Parting Shot)
##################################################################
class PokeBattle_Move_13D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.FE == :FROZENDIMENSION
      if opponent.pbTooLow?(PBStats::ATTACK) && opponent.pbTooLow?(PBStats::SPATK) && opponent.pbTooLow?(PBStats::SPEED)
        @battle.pbDisplay(_INTL("{1}'s stats won't go any lower!",opponent.pbThis))
        return -1
      end
    else
      if opponent.pbTooLow?(PBStats::ATTACK) && opponent.pbTooLow?(PBStats::SPATK)
        @battle.pbDisplay(_INTL("{1}'s stats won't go any lower!",opponent.pbThis))
        return -1
      end
    end
    if opponent.pbOwnSide.effects[:Mist]>0
      @battle.pbDisplay(_INTL("{1} is protected by Mist!",opponent.pbThis))
      return -1
    end
    if (((opponent.ability == :CLEARBODY) ||
       (opponent.ability == :WHITESMOKE)) && !(opponent.moldbroken)) || opponent.ability == :FULLMETALBODY
      @battle.pbDisplay(_INTL("{1}'s {2} prevents stat loss!",opponent.pbThis,getAbilityName(opponent.ability)))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=-1; showanim=true
    statdrop = 1
    statdrop = 2 if (@battle.ProgressiveFieldCheck(PBFields::CONCERT) || @battle.FE == :BACKALLEY)
    if opponent.pbReduceStat(PBStats::ATTACK,statdrop,abilitymessage:false, statdropper: attacker)
      ret=0; showanim=false
    end
    if opponent.pbReduceStat(PBStats::SPATK,statdrop,abilitymessage:false, statdropper: attacker)
      ret=0; showanim=false
    end
    if @battle.FE == :FROZENDIMENSION
      if opponent.pbReduceStat(PBStats::SPEED,1,abilitymessage:false, statdropper: attacker)
        ret=0; showanim=false
      end
    end
    if attacker.hp>0 && @battle.pbCanChooseNonActive?(attacker.index) && !@battle.pbAllFainted?(@battle.pbParty(opponent.index)) && @battle.FE != :COLOSSEUM
      @battle.pbDisplay(_INTL("{1} went back to {2}!",attacker.pbThis,@battle.pbGetOwner(attacker.index).name))
      #Going to switch, check for pursuit
      newpoke=0
      newpoke=@battle.pbSwitchInBetween(attacker.index,true,false)
      for j in @battle.priority
        next if !attacker.pbIsOpposing?(j.index)
        # if Pursuit and this target was chosen
        if !j.hasMovedThisRound? && @battle.pbChoseMoveFunctionCode?(j.index,0x88) && !j.effects[:Pursuit] && (@battle.choices[j.index][3]!=j.pbPartner.index)
          attacker.vanished=false
          @battle.pbCommonAnimation("Fade in",attacker,nil)
          @battle.pbPursuitInterrupt(j,attacker)
        end
        break if attacker.isFainted?
      end
      @battle.pbMessagesOnReplace(attacker.index,newpoke)
      attacker.pbResetForm
      @battle.pbClearChoices(attacker.index) if attacker.effects[:MagicBounced]
      @battle.pbReplace(attacker.index,newpoke)
      @battle.pbOnActiveOne(attacker)
      attacker.pbAbilitiesOnSwitchIn(true)
    else
      attacker.vanished=false
      @battle.pbCommonAnimation("Fade in",attacker,nil)
    end
    return ret
  end
end

##################################################################
# Skips first turn, boosts Sp.Atk, Sp.Def and Speed on the second. (Geomancy)
##################################################################

class PokeBattle_Move_13E < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if @battle.FE == :STARLIGHT || @battle.FE == :DEEPEARTH
      @immediate=true
      @battle.pbDisplay(_INTL("{1} absorbed the starlight!",attacker.pbThis)) if @battle.FE == :STARLIGHT
    elsif attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      itemname=getItemName(attacker.item)
      @immediate=true
      attacker.pbDisposeItem(false)
      @battle.pbDisplay(_INTL("{1} consumed its {2}!",attacker.pbThis,itemname))
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      @battle.pbCommonAnimation("Geomancy",attacker)
      @battle.pbDisplay(_INTL("{1} absorbed energy!",attacker.pbThis))
    end
    if attacker.effects[:TwoTurnAttack]==0
      @battle.pbAnimation(@move,attacker,opponent,hitnum)
      for stat in [PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED]
        if attacker.pbCanIncreaseStatStage?(stat,false)
          attacker.pbIncreaseStat(stat,2)
        end
      end
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    return super
  end
end

##################################################################
# Decreases a poisoned target's Attack, Sp.Atk and Speed by 1 stage. (Venom Drench)
##################################################################

class PokeBattle_Move_13F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("{1}'s attack missed!",attacker.pbThis))
      return -1
    end

    if opponent.pbTooLow?(PBStats::ATTACK) && opponent.pbTooLow?(PBStats::DEFENSE)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any lower!",opponent.pbThis))
      return -1
    end
    if opponent.pbOwnSide.effects[:Mist]>0
      @battle.pbDisplay(_INTL("{1} is protected by Mist!",opponent.pbThis))
      return -1
    end
    if (((opponent.ability == :CLEARBODY) ||
       (opponent.ability == :WHITESMOKE)) && !(opponent.moldbroken)) || opponent.ability == :FULLMETALBODY
      @battle.pbDisplay(_INTL("{1}'s {2} prevents stat loss!",opponent.pbThis,
         getAbilityName(opponent.ability)))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    ret=-1; showanim=true

    if opponent.status== :POISON || @battle.FE == :CORROSIVE ||
      @battle.FE == :CORROSIVEMIST || @battle.FE == :WASTELAND || @battle.FE == :MURKWATERSURFACE
      if opponent.pbReduceStat(PBStats::ATTACK,2,abilitymessage:false, statdropper: attacker)
        ret=0; showanim=false
      end
      if opponent.pbReduceStat(PBStats::SPATK,2,abilitymessage:false, statdropper: attacker)
        ret=0; showanim=false
      end
      if opponent.pbReduceStat(PBStats::SPEED,2,abilitymessage:false, statdropper: attacker)
        ret=0; showanim=false
      end
    else 
      if opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
        ret=0; showanim=false
      end
      if opponent.pbReduceStat(PBStats::SPATK,1,abilitymessage:false, statdropper: attacker)
        ret=0; showanim=false
      end
      if opponent.pbReduceStat(PBStats::SPEED,1,abilitymessage:false, statdropper: attacker)
        ret=0; showanim=false
      end
    end
    return ret
  end
end

################################################################################
# Entry hazard.  Puts down a sticky web that lowers speed. (Sticky Web)
################################################################################
class PokeBattle_Move_141 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOpposingSide.effects[:StickyWeb]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...4
      next if !(attacker.pbIsOpposing?(i))
      if (@battle.battlers[i].ability == :MAGICBOUNCE && !PBStuff::TWOTURNMOVE.include?(@battle.battlers[i].effects[:TwoTurnAttack])) || 
        (@battle.battlers[i]).effects[:MagicCoat]
         attacker.pbOwnSide.effects[:StickyWeb]=true
         @battle.pbDisplay(_INTL("{1} bounced the Sticky Web back!",(@battle.battlers[i]).pbThis))
         if @battle.pbIsOpposing?(attacker.index)
           @battle.pbDisplay(_INTL("A sticky web has been laid out beneath your foe's team's feet!"))
         else
           @battle.pbDisplay(_INTL("A sticky web has been laid out beneath your team's feet!"))
         end
       return 0
       break
      end
    end
    attacker.pbOpposingSide.effects[:StickyWeb]=true
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("A sticky web has been laid out beneath your foe's team's feet!"))
    else
      @battle.pbDisplay(_INTL("A sticky web has been laid out beneath your team's feet!"))
    end
    return 0
  end
end

################################################################################
# User inverts the target's stat stages. (Topsy-Turvy)
################################################################################
class PokeBattle_Move_142 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 1..7
      opponent.stages[i]=-opponent.stages[i]
    end
    @battle.pbDisplay(_INTL("{1} inverted {2}'s stat changes!",attacker.pbThis,opponent.pbThis(true)))
    if !attacker.hasWorkingItem(:EVERSTONE) && @battle.canChangeFE?
      duration=3
      duration=6 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
      @battle.setField(:INVERSE,duration)
      @battle.pbDisplay(_INTL("The terrain was inverted!"))
    end
    return 0
  end
end

################################################################################
# Makes the target Grass Type (Forest's Curse)
################################################################################
class PokeBattle_Move_143 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if (opponent.ability == :MULTITYPE) ||
      (opponent.ability == :RKSSYSTEM) || opponent.crested == :SILVALLY
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.type1=:GRASS
    opponent.type2=nil
    typename=getTypeName(:GRASS)
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",opponent.pbThis,typename))
    if @battle.FE == :FOREST || @battle.FE == :FAIRYTALE || @battle.FE == :BEWITCHED
      if !opponent.effects[:Curse]
        opponent.effects[:Curse]=true
        @battle.pbDisplay(_INTL("{1} laid a curse on {2}!",attacker.pbThis,opponent.pbThis(true)))
      end
    end
    return 0
  end
end

################################################################################
# Makes the target Ghost Type- (Trick Or Treat)
################################################################################
class PokeBattle_Move_144 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if (opponent.ability == :MULTITYPE) ||
      (opponent.ability == :RKSSYSTEM) || (opponent.species == :SILVALLY && attacker.crested)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.type1=:GHOST
    opponent.type2=nil
    typename=getTypeName(:GHOST)
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",opponent.pbThis,typename))
    return 0
  end
end

################################################################################
# All active Pokemon can no longer switch out or flee during the next turn. (Fairy Lock)
################################################################################
class PokeBattle_Move_145 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:FairyLockRate]==true
      attacker.effects[:FairyLockRate]=false
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.state.effects[:FairyLock]=2
    attacker.effects[:FairyLockRate]=true
    @battle.pbDisplay(_INTL("No one will be able to run away during the next turn!"))
    return 0
  end
end

################################################################################
# If the user or any allies have Plus or Minus as their ability, raise their
#   Defense and Special Defense by one stage. (Magnetic Flux)
################################################################################
class PokeBattle_Move_146 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbPartner.ability == :PLUS || attacker.pbPartner.ability == :MINUS ||
      (Rejuv && @battle.FE == :ELECTERRAIN)
       partnerfail=false
      if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::DEFENSE,false) &&
         attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
        showanim=true
        statboost = 1
        statboost = 2 if @battle.FE == :DEEPEARTH || (Rejuv && @battle.FE == :ELECTERRAIN && (attacker.pbPartner.ability == :PLUS || attacker.pbPartner.ability == :MINUS))
        if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
          attacker.pbPartner.pbIncreaseStat(PBStats::DEFENSE,statboost,abilitymessage:false)
          showanim=false
        end
        if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
          attacker.pbPartner.pbIncreaseStat(PBStats::SPDEF,statboost,abilitymessage:false)
          showanim=false
        end
      else # partner cannot increase stats, check next attacker
        @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbPartner.pbThis))
      end
    else
      # partner does not have Plus/Minus
      partnerfail = true if !(Rejuv && @battle.FE == :ELECTERRAIN)
    end
    if attacker.ability == :PLUS || attacker.ability == :MINUS ||
      (Rejuv && @battle.FE == :ELECTERRAIN)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false) &&
         attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        pbShowAnimation(@move,attacker,nil,hitnum,alltargets,partnerfail)
        showanim=true
        statboost = 1
        statboost = 2 if @battle.FE == :DEEPEARTH || (Rejuv && @battle.FE == :ELECTERRAIN && (attacker.ability == :PLUS || attacker.ability == :MINUS))
        if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
          attacker.pbIncreaseStat(PBStats::DEFENSE,statboost,abilitymessage:false)
          showanim=false
        end
        if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
          attacker.pbIncreaseStat(PBStats::SPDEF,statboost,abilitymessage:false)
          showanim=false
        end
      else # attacker cannot increase stats
        @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      end
    else
      # attacker does not have Plus/Minus
      if partnerfail
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
    end

    return 0
  end
end

################################################################################
# If the opponent dies, increase attack by 3 stages (Fell Stinger)
################################################################################
class PokeBattle_Move_147 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    increment = 3
    increment = 2 if @move == :KINGSFEAST
    if opponent.isFainted? &&
       attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::ATTACK,increment,abilitymessage:false)
    end
    if @move == :KINGSFEAST && opponent.pbCanReduceStatStage?(PBStats::SPEED,false)
      opponent.pbReduceStat(PBStats::SPEED,increment,abilitymessage:false, statdropper: attacker)
    end
  end
end

################################################################################
# Ion Deluge
################################################################################
class PokeBattle_Move_148 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.state.effects[:IonDeluge]==true
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("A deluge of ions showers the battlefield!"))
    @battle.state.effects[:IonDeluge] = true
    if !attacker.hasWorkingItem(:EVERSTONE) && @battle.canChangeFE?(:ELECTERRAIN)
      duration=3
      duration=6 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
      @battle.setField(:ELECTERRAIN,duration)
      @battle.pbDisplay(_INTL("The terrain became electrified!"))
    end
    return 0
  end
end

################################################################################
# Crafty Shield
################################################################################
class PokeBattle_Move_149 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    attacker.pbOwnSide.effects[:CraftyShield]=true
    attacker.effects[:ProtectRate]+=1
    @battle.pbAnimation(@move,attacker,nil)
    @battle.pbDisplay(_INTL("{1} protected its team!",attacker.pbThis))
    if @battle.FE == :FAIRYTALE # Fairy Tale Field
      @battle.pbDisplay(_INTL("{1} boosted its defenses with the shield!",attacker.pbThis))
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Flower Shield
################################################################################
class PokeBattle_Move_150 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    found=false
    for i in 0...4
      if @battle.battlers[i].hasType?(:GRASS)
        found=true
      end
    end
    @battle.pbDisplay("But it failed!") unless found
    return -1 unless found
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...4
      if @battle.battlers[i].hasType?(:GRASS)
        if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,2,5)
          if !(@battle.battlers[i].pbCanIncreaseStatStage?(PBStats::DEFENSE,false)) &&
               !(@battle.battlers[i].pbCanIncreaseStatStage?(PBStats::SPDEF,false))
              @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
          end
        else 
          if !(@battle.battlers[i].pbCanIncreaseStatStage?(PBStats::DEFENSE,false))
              @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
          end
        end
        showanim=true
        if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,2,5)
          stat = 1
          if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,5)
            stat=2
          end
          if @battle.battlers[i].pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
            @battle.battlers[i].pbIncreaseStat(PBStats::DEFENSE,stat,abilitymessage:false)
            showanim=false
          end
          if @battle.battlers[i].pbCanIncreaseStatStage?(PBStats::SPDEF,false)
            @battle.battlers[i].pbIncreaseStat(PBStats::SPDEF,stat,abilitymessage:false)
            showanim=false
          end
        else
          if @battle.battlers[i].pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
            @battle.battlers[i].pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
            showanim=false
          end
        end
      end
    end
    if @battle.FE == :FAIRYTALE && !attacker.hasType?(:GRASS) # Fairy Tale Field
      @battle.pbDisplay(_INTL("{1} boosted its defenses with the shield!"))
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
      end
    end
    if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,2,5) && !attacker.hasType?(:GRASS) # Flower Garden
      if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,5)
        if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
          attacker.pbIncreaseStat(PBStats::DEFENSE,2,abilitymessage:false)
        end
        if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
          attacker.pbIncreaseStat(PBStats::SPDEF,2,abilitymessage:false)
        end
      else
        if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
          attacker.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
        end
        if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
          attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
        end
      end
    end
    return 0
  end
end

################################################################################
# Boosts Attack and Sp. Atk of all Grass-types Pokémon in the field (Rototiller)
################################################################################
class PokeBattle_Move_151 < PokeBattle_Move

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    found=false
    for i in 0...4
      if @battle.battlers[i].hasType?(:GRASS)
        found=true
      end
    end
    @battle.pbDisplay("But it failed!") unless found
    return -1 unless found
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...4
      if @battle.battlers[i].hasType?(:GRASS) && !@battle.battlers[i].isAirborne?
        if !@battle.battlers[i].pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
           !@battle.battlers[i].pbCanIncreaseStatStage?(PBStats::ATTACK,false)
          @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",@battle.battlers[i].pbThis))
          return -1
        end
        showanim=true
        statboost = 1
        statboost = 2 if @battle.FE == :DEEPEARTH || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN)
        if @battle.battlers[i].pbCanIncreaseStatStage?(PBStats::SPATK,false)
          @battle.battlers[i].pbIncreaseStat(PBStats::SPATK,statboost,abilitymessage:false)
          showanim=false
        end
        if @battle.battlers[i].pbCanIncreaseStatStage?(PBStats::ATTACK,false)
          @battle.battlers[i].pbIncreaseStat(PBStats::ATTACK,statboost,abilitymessage:false)
          showanim=false
        end
      end
    end
    if @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN) && !attacker.hasType?(:GRASS)
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,2,abilitymessage:false)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,2,abilitymessage:false)
        showanim=false
      end
    end
    return 0
  end
end

################################################################################
# Powder
################################################################################
class PokeBattle_Move_152 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent) if @basedamage>0
    if !opponent.effects[:Powder] && (!(opponent.ability == :OVERCOAT) || opponent.moldbroken) && !opponent.hasType?(:GRASS) && !opponent.hasWorkingItem(:SAFETYGOGGLES)
      @battle.pbAnimation(@move,attacker,opponent)
      @battle.pbDisplay(_INTL("{1} was covered in a thin powder!",attacker.pbThis))
      opponent.effects[:Powder]=true
      return 0
    else
      @battle.pbDisplay(_INTL("But it failed!"))
    end
    return -1
  end
end

################################################################################
# Next move used by the target becomes Electric-type (Electrify)
################################################################################
class PokeBattle_Move_153 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Electrify]==true
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:Electrify]=true
    @battle.pbDisplay(_INTL("{1} became electrified!",opponent.pbThis))
    if Rejuv && @battle.FE == :ELECTERRAIN &&
      !opponent.effects[:Substitute]>0 && !((opponent.ability == :MULTITYPE) ||
      (opponent.ability == :RKSSYSTEM) || opponent.crested == :SILVALLY)
      opponent.type1=:ELECTRIC
      opponent.type2=nil
      typename=getTypeName(:ELECTRIC)
      @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",opponent.pbThis,typename))
    end
    return 0
  end
end

################################################################################
# Mat Block
################################################################################
class PokeBattle_Move_154 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (attacker.turncount!=1)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if attacker.pbOwnSide.effects[:MatBlock]
      @battle.pbDisplay(_INTL("But it failed!",attacker.pbThis))
      return -1
    end
    @battle.pbAnimation(@move,attacker,nil)
    @battle.pbDisplay(_INTL("{1} kicked up a mat to protect its team!",attacker.pbThis))
    attacker.pbOwnSide.effects[:MatBlock]=true
    return 0
  end
end

################################################################################
# Thousand Waves
################################################################################
class PokeBattle_Move_155 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.effects[:Substitute]>0
      #@battle.pbDisplay(_INTL("But it failed!"))
      return ret
    end
    typemod=pbTypeModifier(@type,attacker,opponent)
  #  pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.hp > 0 && opponent.effects[:MeanLook]==-1 && typemod!=0 && !(@move == :THOUSANDWAVES && opponent.hasType?(:GHOST))
      opponent.effects[:MeanLook]=attacker.index
      @battle.pbDisplay(_INTL("{1} can't escape now!",opponent.pbThis))
    end
    return ret
  end
end
################################################################################
# Thousand Arrows NOT USED
################################################################################
class PokeBattle_Move_156 < PokeBattle_Move

end

###############################################################################
# Always hits and ignores protection (Hyperspace Hole)
###############################################################################
class PokeBattle_Move_157 < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:ProtectNegation]=true if ret>0
    if opponent.pbPartner && !opponent.pbPartner.isFainted? && !opponent.pbPartner.effects[:Protect]
      opponent.pbPartner.effects[:ProtectNegation]=true
    elsif opponent.pbPartner.effects[:Protect] && opponent.pbOwnSide.protectActive?
      opponent.pbOwnSide.effects[:CraftyShield]=false
      opponent.pbOwnSide.effects[:WideGuard]=false
      opponent.pbOwnSide.effects[:QuickGuard]=false
      opponent.pbOwnSide.effects[:MatBlock]=false
      end
    return ret
  end
end

################################################################################
# User gains 3/4 the HP it inflicts as damage. (OblivionWing) NOT USED
################################################################################
class PokeBattle_Move_158 < PokeBattle_Move
  #*crickets
end

###############################################################################
# Always hits, ignores protection, and lowers defense. Cannot be used by 
#any Pokemon other than Hoopa-Unbound. (Hyperspace Fury)
###############################################################################
class PokeBattle_Move_159 < PokeBattle_Move
  def pbOnStartUse(attacker)
    if (attacker.species == :HOOPA)
      if attacker.form == 1
        return true
      end
      # hoopa not in unbound form
      @battle.pbDisplay(_INTL("Hoopa can't use the move as it is now!"))
      return false
    end
    # any non-hoopa Pokemon
    @battle.pbDisplay(_INTL("But {1} can't use the move!",attacker.pbThis))
    return false
  end

  def pbAccuracyCheck(attacker,opponent)
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:ProtectNegation]=true if ret>0
    if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,false)
      attacker.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
    end
    return ret
  end
end

################################################################################
# Dummy Move Effect
################################################################################
class PokeBattle_Move_15A < PokeBattle_Move
end

############################################################################################################
# For 5 rounds if hailing, lowers power of physical & special attacks against the user's side. (Aurora Veil)
############################################################################################################
class PokeBattle_Move_15B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret = 0
    if (@basedamage > 0)
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if attacker.pbOwnSide.effects[:AuroraVeil] <= 0
        pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
        attacker.pbOwnSide.effects[:AuroraVeil]=5
        attacker.pbOwnSide.effects[:AuroraVeil]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
        attacker.pbOwnSide.effects[:AuroraVeil]=8 if @battle.FE == :MIRROR
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("An Aurora is protecting your team!"))
        else
          @battle.pbDisplay(_INTL("An Aurora is protecting the opposing team!"))
        end
        if @battle.FE == :MIRROR && attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
          attacker.pbIncreaseStat(PBStats::EVASION,1,abilitymessage:false)
        end
      end
    else
      if attacker.pbOwnSide.effects[:AuroraVeil]>0 || ((@battle.weather!=:HAIL ||
        @battle.pbCheckGlobalAbility(:AIRLOCK) || @battle.pbCheckGlobalAbility(:CLOUDNINE)) &&
        !([:DARKCRYSTALCAVERN,:RAINBOW,:ICY,:CRYSTALCAVERN,:SNOWYMOUNTAIN,:MIRROR,:STARLIGHT,:FROZENDIMENSION].include?(@battle.FE)))
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      attacker.pbOwnSide.effects[:AuroraVeil]=5
      attacker.pbOwnSide.effects[:AuroraVeil]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
      attacker.pbOwnSide.effects[:AuroraVeil]=8 if @battle.FE == :MIRROR
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("An Aurora is protecting your team!"))
      else
        @battle.pbDisplay(_INTL("An Aurora is protecting the opposing team!"))
      end
      if @battle.FE == :MIRROR && attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,1,abilitymessage:false)
      end
    end
    return ret
  end
end

################################################################################
# Baneful Bunker
################################################################################
class PokeBattle_Move_15C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if @battle.pbRandom(65536)<(65536/(3**attacker.effects[:ProtectRate])).floor
      attacker.effects[:Protect]=:BanefulBunker
      attacker.effects[:ProtectRate]+=1
      @battle.pbAnimation(@move,attacker,nil)
      @battle.pbDisplay(_INTL("{1} shielded itself against damage!",attacker.pbThis))
      return 0
    else
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# Beak Blast
################################################################################
class PokeBattle_Move_15D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    attacker.effects[:BeakBlast]=false
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Burn Up
################################################################################
class PokeBattle_Move_15E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.hasType?(:FIRE) || attacker.effects[:BurnUp]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    attacker.effects[:BurnUp]=true
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if (attacker.type1 == :FIRE)
      if (attacker.type2.nil?)
        attacker.type1=(:QMARKS) || 0
      else
        attacker.type1=attacker.type2
      end
    end
    if (attacker.type2 == :FIRE)
      attacker.type2 = nil
    end
    @battle.pbDisplay(_INTL("{1} was burnt out!",attacker.pbThis))
    return ret
  end
end

################################################################################
# Decreases the user's Defense by 1 stage. (Spread move)
################################################################################
class PokeBattle_Move_15F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,false,true)
        attacker.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker) unless attacker.effects[:ClangedScales]
        attacker.effects[:ClangedScales]=true
      end
    end
    return ret
  end
end

################################################################################
# Core Enforcer
################################################################################
class PokeBattle_Move_160 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.hasMovedThisRound? && !@battle.switchedOut[opponent.index]
      if !(PBStuff::FIXEDABILITIES).include?(opponent.ability)
        neutralgas = true if opponent.ability = :NEUTRALIZINGGAS
        opponent.ability = nil  #Cancel out ability
        opponent.effects[:GastroAcid]=true
        opponent.effects[:Truant]=false
        @battle.pbDisplay(_INTL("{1}'s Ability was suppressed!",opponent.pbThis))
        if opponent.effects[:Illusion]!=nil 
          opponent.effects[:Illusion]=nil
          @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
          @battle.pbDisplay(_INTL("{1}'s {2} was broken!",opponent.pbThis,
          getAbilityName(:ILLUSION)))
        end
        @battle.neutralizingGasDisable(opponent.index) if neutralgas
      end
    end
    return ret
  end
end

################################################################################
# Fails if this isn't the user's first turn. (First Impression)
################################################################################
class PokeBattle_Move_161 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return (attacker.turncount!=1)
  end
end

################################################################################
# Heals target by an amount depending on the terrain. (Floral Healing)
################################################################################
class PokeBattle_Move_162 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.hp==opponent.totalhp
      @battle.pbDisplay(_INTL("{1}'s HP is full!",opponent.pbThis))
      return -1
    end
    hpgain=0
    if @battle.FE == :GRASSY || @battle.FE == :FAIRYTALE ||
      (@battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN,3,5)) # Grassy Terrain, Fairytale Field, Flower Garden Field
      hpgain=(opponent.totalhp).floor
    else
      hpgain=(opponent.totalhp/2.0).floor
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbRecoverHP(hpgain,true)
    @battle.pbDisplay(_INTL("{1}'s HP was restored.",opponent.pbThis))
    if @battle.FE == :CORROSIVE || @battle.FE == :CORROSIVEMIST # Corrosive/Corrosive Mist Field
      if opponent.pbCanPoison?(true)
        opponent.pbPoison(attacker)
        @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
      end
    end
    return 0
  end
end

################################################################################
# If the any allies have Plus or Minus as their ability, raise their
#   Attack and Special Attack by one stage. (Gear Up)
################################################################################
class PokeBattle_Move_163 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.doublebattle
      if @battle.FE != :FACTORY

        base = 1
        if attacker.pbPartner.ability == :PLUS || attacker.pbPartner.ability == :MINUS
          base = 2
        end

        if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
          attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::SPATK,false)
          pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
          showanim=true
          if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
            attacker.pbPartner.pbIncreaseStat(PBStats::ATTACK,base,abilitymessage:false)
            showanim=false
          end
          if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::SPATK,false)
            attacker.pbPartner.pbIncreaseStat(PBStats::SPATK,base,abilitymessage:false)
            showanim=false
          end
        else
          @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbPartner.pbThis))
          return -1
        end
      else
        if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
          attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::SPATK,false)
          pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
          showanim=true
          if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
            attacker.pbPartner.pbIncreaseStat(PBStats::ATTACK,base + 1,abilitymessage:false)
            showanim=false
          end
          if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::SPATK,false)
            attacker.pbPartner.pbIncreaseStat(PBStats::SPATK,base + 1,abilitymessage:false)
            showanim=false
          end
        else
          @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbPartner.pbThis))
          return -1
        end
     end
    end

    base = 1
    if attacker.ability == :PLUS || attacker.ability == :MINUS
      base = 2
    end

    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
      attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      showanim=true
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,base,abilitymessage:false)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,base,abilitymessage:false)
        showanim=false
      end
    else
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end

    if attacker.crested == :KLINKLANG
      if attacker.gear == 0
        @battle.pbDisplay(_INTL("ATTACK MODE INITIATING"))
        attacker.effects[:MagnetRise]=0
        @battle.pbDisplay(_INTL("{1} stopped levitating!",attacker.pbThis))
        @battle.pbAnimation(:MAGNETRISE,attacker,nil)
      else
        @battle.pbDisplay(_INTL("OVERCLOCKING SPEED",attacker.pbThis))
        attacker.effects[:MagnetRise]=-1
        @battle.pbAnimation(:MAGNETRISE,attacker,nil)
        @battle.pbDisplay(_INTL("{1} levitates with electromagnetism!",attacker.pbThis))
      end
      # switch gears
      attacker.gear = (attacker.gear + 1) % 2
    end

    return 0
  end
end

################################################################################
# Instruct
################################################################################
class PokeBattle_Move_164 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    otherid = opponent.lastMoveUsed
    # This is needed because it should target the same opponent as before, and use the same moveslot.
    choice = opponent.lastMoveChoice
    begin
      if !choice || choice[1]<0 || !choice[2] || (opponent.moves[choice[1]].move != choice[2].move) || (choice[2].move != otherid) ||
         PBStuff::BLACKLISTS[:INSTRUCT].include?(otherid) || choice[2].zmove || PBStuff::DELAYEDMOVE.include?(@battle.choices[opponent.index][2].move)
        @battle.pbDisplay(_INTL("But it failed!"))
        return -1
      end
    rescue
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end

    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("{1} instructed {2}!",attacker.pbThis,opponent.pbThis))
    opponent.pbUseMove(choice, {instructed: true, specialusage: false})  # TODO: test whether specialusage should be true or false.
    return 0
  end
end

################################################################################
# Ensures the next hit is critical. (Laser Focus)
################################################################################
class PokeBattle_Move_165 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:LaserFocus]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[:LaserFocus]=2
    @battle.pbDisplay(_INTL("{1} is focused!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Moldbreaking moves (Sunsteel Strike/Moongeist Beam)
################################################################################
class PokeBattle_Move_166 < PokeBattle_Move
  #handled elsewhere
end

################################################################################
# Pollen Puff
################################################################################
class PokeBattle_Move_167 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbPartner == opponent
      if opponent.hp==opponent.totalhp
        @battle.pbDisplay(_INTL("{1}'s HP is full!",opponent.pbThis))
        return -1
      end
      hpgain=((opponent.totalhp)/2).floor
      pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
      if !(opponent.ability == :BULLETPROOF || opponent.effects[:HealBlock]>0)
        opponent.pbRecoverHP(hpgain,true)
        @battle.pbDisplay(_INTL("{1}'s HP was restored.",opponent.pbThis))
        return 0
      else
        @battle.pbDisplay(_INTL("But it failed!",opponent.pbThis))
        return -1
      end
    else
      return super(attacker,opponent,hitnum,alltargets,showanimation)
    end
  end
end

################################################################################
# Psychic Terrain
################################################################################
class PokeBattle_Move_168 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !((!Rejuv && @battle.canChangeFE?(:PSYTERRAIN)) || (@battle.canChangeFE?([:PSYTERRAIN,:DRAGONSDEN]) && !(@battle.state.effects[:PSYTERRAIN] > 0))) 
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    duration=5
    duration=8 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
    @battle.setField(:PSYTERRAIN,duration)
    @battle.pbDisplay(_INTL("The terrain became mysterious!"))
    return 0
  end
end

################################################################################
# Heals itself if the target is poisoned (does not cure poison). (Purify)
################################################################################
class PokeBattle_Move_169 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (opponent.status== :POISON || opponent.hasType?(:POISON)) && attacker.hp!=attacker.totalhp
      attacker.pbRecoverHP(attacker.totalhp,true)
      @battle.pbDisplay(_INTL("{1} healed itself!",attacker.pbThis))
      return 0
    else
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end

    # @SWu v2 purify down below
    # healmod = 4
    # didsomething = -1
    # if opponent.status.nil?
    #   @battle.pbDisplay(_INTL("{1} is already healthy!",opponent.pbThis))
    # else
    #   # pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    #   # opponent.status=nil
    #   # opponent.statusCount=0
    #   # healmod = 1
    #   # @battle.pbDisplay(_INTL("{1} was purified!",opponent.pbThis))
    #   # didsomething = 0
    # end
    # pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    # if attacker.hp!=attacker.totalhp
    #   hpgain=((attacker.totalhp)/healmod).floor
    #   attacker.pbRecoverHP(hpgain,true)
    #   @battle.pbDisplay(_INTL("{1} healed itself!",attacker.pbThis))
    #   didsomething = 0
    # end
    # return didsomething
  end
end

################################################################################
# Type depends on the user's. (Revelation Dance)
################################################################################
class PokeBattle_Move_16A < PokeBattle_Move
  def pbType(attacker,type=@type)
    type = attacker.type1
    return super(attacker,type)
  end
end

#################################################################################
# Shell Trap
################################################################################
class PokeBattle_Move_16B < PokeBattle_Move

  def pbOnStartUse(attacker)
    @succesful=true
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:ShellTrap] && @succesful
      attacker.effects[:ShellTrap]=false
      @battle.pbDisplay(_INTL("{1}'s Shell Trap didn't work.",attacker.name))
      @succesful=false
      return -1
    elsif @succesful
      return super(attacker,opponent,hitnum,alltargets,showanimation)
    else
      return -1
    end
  end

  def pbAddTarget(targets,attacker)
    if attacker.effects[:ShellTrapTarget]>=0
      if !attacker.pbAddTarget(targets,@battle.battlers[attacker.effects[:ShellTrapTarget]])
        attacker.pbRandomTarget(targets)
      end
      attacker.effects[:ShellTrapTarget]=-1
    end
  end
end

################################################################################
# Heals user by an amount depending on the weather. (Shore Up)
################################################################################
class PokeBattle_Move_16C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("{1}'s HP is full!",attacker.pbThis))
      return -1
    end
    hpgain=0
    if @battle.FE == :ASHENBEACH
      hpgain=(attacker.totalhp).floor
    elsif (@battle.pbWeather== :SANDSTORM || @battle.FE == :DESERT)
      hpgain=(attacker.totalhp*2/3.0).floor
    else
      hpgain=(attacker.totalhp/2.0).floor
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbRecoverHP(hpgain,true)
    @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbThis))
    if (@battle.FE == :WATERSURFACE || @battle.FE == :MURKWATERSURFACE) && (attacker.ability == :WATERCOMPACTION)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE)
        attacker.pbIncreaseStatBasic(PBStats::DEFENSE,2)
        @battle.pbCommonAnimation("StatUp",attacker,nil)
        @battle.pbDisplay(_INTL("{1}'s Water Compaction sharply raised its Defense!",
          attacker.pbThis,getAbilityName(attacker.ability)))
      end
    end
    return 0
  end
end

################################################################################
# Cures the target's burn (Sparkling Aria)
################################################################################
class PokeBattle_Move_16D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && opponent.status== :BURN
      opponent.pbCureStatus
    end
    return ret
  end

  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    if @battle.pbWeather!=0 && @battle.pbWeather == :SUNNYDAY
      return (damagemult*3).round
    end
    return damagemult
  end
end

################################################################################
# Spectral Thief.
################################################################################
class PokeBattle_Move_16E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    totalboost = 0
    if pbTypeModifier(@type,attacker,opponent) != 0
      for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
                PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
        if opponent.stages[i]>0
          oppboost = opponent.stages[i]
          oppboost *= -1 if attacker.ability == :CONTRARY
          oppboost *= 2 if attacker.ability == :SIMPLE
          attacker.stages[i]+=oppboost
          attacker.stages[i] = attacker.stages[i].clamp(-6, 6)
          totalboost += oppboost
          opponent.stages[i]=0
        end
      end
    end
    if totalboost>0
      @battle.pbCommonAnimation("StatUp",attacker,nil)
      @battle.pbDisplay(_INTL("{1} stole {2}'s stat boosts!",attacker.pbThis,opponent.pbThis))
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Swaps the user's & target's speeds (Speed Swap)
################################################################################
class PokeBattle_Move_16F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    aSwap = attacker.effects[:SpeedSwap]
    oSwap = opponent.effects[:SpeedSwap]
    if oSwap == 0
      attacker.effects[:SpeedSwap]=opponent.speed
    else
      attacker.effects[:SpeedSwap]=oSwap
    end
    if aSwap == 0
      opponent.effects[:SpeedSwap]=attacker.speed
    else
      opponent.effects[:SpeedSwap]=aSwap
    end
    @battle.pbDisplay(_INTL("{1} swapped speeds with {2}!",attacker.pbThis,opponent.pbThis))
    return 0
  end
end

################################################################################
# This round, target becomes the target of attacks that have single targets. (Spotlight)
################################################################################
class PokeBattle_Move_170 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:FollowMe]=true
    if !opponent.pbPartner.isFainted?
      opponent.pbPartner.effects[:FollowMe]=false
      opponent.pbPartner.effects[:RagePowder]=false
    end
    if @battle.FE == :BIGTOP # Big Top Arena
      showanim=true
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,1,abilitymessage:false)
        showanim=false
      end
      if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        opponent.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
        showanim=false
      end
      if opponent.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        opponent.pbIncreaseStat(PBStats::SPATK,1,abilitymessage:false)
        showanim=false
      end
    end
    @battle.pbDisplay(_INTL("{1} became the center of attention!",opponent.pbThis))
    return 0
  end
end

################################################################################
# Power is doubled if the user's previous move failed (Stomping Tantrum)
################################################################################
class PokeBattle_Move_171 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if attacker.effects[:Tantrum]
      return basedmg*2
    end
    return basedmg
  end
end

################################################################################
# Strength Sap
################################################################################
class PokeBattle_Move_172 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,true)
    stagemul=[10,10,10,10,10,10,10,15,20,25,30,35,40]
    stagediv=[40,35,30,25,20,15,10,10,10,10,10,10,10]
    statstage = opponent.stages[PBStats::ATTACK]

    hpgain = opponent.attack * stagemul[statstage+6] / stagediv[statstage+6]
    if Rejuv && @battle.FE == :GRASSY
      hpgain=(hpgain*1.6).floor if attacker.hasWorkingItem(:BIGROOT)
    else
      hpgain=(hpgain*1.3).floor if attacker.hasWorkingItem(:BIGROOT)
    end
    hpgain=(hpgain*1.3).floor if attacker.crested == :SHIINOTIC
    hpgain=(hpgain*1.3).floor if @battle.FE == :SWAMP && !Rejuv # Swamp Field
    hpgain=(hpgain*1.3).floor if @battle.FE == :FOREST # Forest Field
    
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbReduceStat(PBStats::ATTACK,1,abilitymessage:false, statdropper: attacker)
    if @battle.FE == :BEWITCHED && opponent.pbCanReduceStatStage?(PBStats::SPATK,true)
      opponent.pbReduceStat(PBStats::SPATK,1,abilitymessage:false, statdropper: attacker)
    end
    if Rejuv && @battle.FE == :SWAMP 
      stat = [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED].sample
      if opponent.pbCanReduceStatStage?(stat,true)
        opponent.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
      end
    end
    if attacker.hp!=attacker.totalhp
      attacker.pbRecoverHP(hpgain,true)
      @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbThis))
    end
    return 0
  end
end

################################################################################
# Throat Chop
################################################################################
class PokeBattle_Move_173 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret = super(attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:ThroatChop]=2
    return ret
  end
end

################################################################################
# Toxic Thread
################################################################################
class PokeBattle_Move_174 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPEED,true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbReduceStat(PBStats::SPEED,1,abilitymessage:false, statdropper: attacker)
    if opponent.pbCanPoison?(true)
      if @battle.FE == :CORRUPTED
        opponent.pbPoison(attacker,true)
        @battle.pbDisplay(_INTL("{1} is badly poisoned!",opponent.pbThis))
      else
        opponent.pbPoison(attacker)
        @battle.pbDisplay(_INTL("{1} is poisoned!",opponent.pbThis))
      end
    end
    return 0
  end
end

################################################################################
# User takes half their HP as recoil (Mind Blown/Steel Beam/Chloroblast)
################################################################################
class PokeBattle_Move_175 < PokeBattle_Move
  def pbOnStartUse(attacker)
    bearer=@battle.pbCheckGlobalAbility(:DAMP)
    if (bearer && !(bearer.moldbroken)) && !@move == :STEELBEAM 
      @battle.pbDisplay(_INTL("{1}'s {2} prevents {3} from using {4}!",
         bearer.pbThis,getAbilityName(bearer.ability),attacker.pbThis(true),@name))
      return -1
    end
    @loopcount=0
    @totaldamage=0
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    @loopcount+=1
    @totaldamage+=ret
    if @totaldamage>0 && (!attacker.midwayThroughMove || @loopcount==alltargets.length) &&
       attacker.ability != :MAGICGUARD && !(attacker.ability == :WONDERGUARD && @battle.FE == :COLOSSEUM) && !attacker.effects[:MagicGuard]
      if (@battle.FE == :FACTORY && @move == :STEELBEAM) || (@battle.FE == :FOREST && @move == :CHLOROBLAST)
        attacker.pbReduceHP((attacker.totalhp)/4).floor
      elsif @battle.FE == :SHORTCIRCUIT && @move == :STEELBEAM 
        attacker.pbReduceHP((attacker.totalhp)).floor
      else
        attacker.pbReduceHP((attacker.totalhp)/2).floor
      end
    end
    return ret
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :CHLOROBLAST
      @battle.pbAnimation(:SOLARBEAM,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Photon Geyser
################################################################################
class PokeBattle_Move_176 < PokeBattle_Move
  #Moldbreaking handled elsewhere
  def pbIsPhysical?(type=@type)
    attacker = @user
    stagemul=[2,2,2,2,2,2,2,3,4,5,6,7,8]
    stagediv=[8,7,6,5,4,3,2,2,2,2,2,2,2]
    # Physical Stuff
    storedatk = attacker.attack
    atkstage=6
    atkmult = 1.0
    if attacker.class == PokeBattle_Battler
      atkstage=attacker.stages[PBStats::ATTACK]+6
      atkmult *= 1.5 if attacker.hasWorkingItem(:CHOICEBAND)
      atkmult *= 1.5 if attacker.ability == :HUSTLE
      atkmult *= 1.5 if attacker.ability == :TOXICBOOST && (attacker.status== :POISON || @battle.FE == :CORROSIVE || @battle.FE == :CORROSIVEMIST || @battle.FE == :WASTELAND || @battle.FE == :MURKWATERSURFACE)
      atkmult *= 1.5 if attacker.ability == :GUTS && !attacker.status.nil?
      atkmult *= 0.5 if attacker.ability == :SLOWSTART && attacker.turncount<5 && !@battle.FE == :DEEPEARTH
      atkmult *= 2 if (attacker.ability == :PUREPOWER && @battle.FE != :PSYTERRAIN) || attacker.ability == :HUGEPOWER
      atkmult *= 2 if attacker.hasWorkingItem(:THICKCLUB) && ((attacker.pokemon.species == :CUBONE) || (attacker.pokemon.species == :MAROWAK))
      atkmult *= 0.5 if attacker.status== :BURN && !(attacker.ability == :GUTS && !attacker.status.nil?)
    end
    storedatk*=((stagemul[atkstage]/stagediv[atkstage])*atkmult)
    # Special Stuff
    storedspatk = attacker.spatk
    spatkstage=6
    spatkmult=1.0
    if attacker.class == PokeBattle_Battler
      spatkstage=attacker.stages[PBStats::SPATK]+6
      spatkmult *= 1.5 if attacker.hasWorkingItem(:CHOICESPECS)
      spatkmult *= 2 if attacker.hasWorkingItem(:DEEPSEATOOTH) && (attacker.pokemon.species == :CLAMPERL)
      spatkmult *= 2 if attacker.hasWorkingItem(:LIGHTBALL) && (attacker.pokemon.species == :PIKACHU)
      spatkmult *= 1.5 if attacker.ability == :FLAREBOOST && (attacker.status== :BURN || @battle.FE == :BURNING || @battle.FE == :VOLCANIC || @battle.FE == :INFERNAL) &&  @battle.FE != :FROZENDIMENSION
      spatkmult *= 1.5 if attacker.ability == :MINUS && (attacker.pbPartner.ability == :PLUS || @battle.FE == :SHORTCIRCUIT || (Rejuv && @battle.FE == :ELECTERRAIN)) || @battle.state.effects[:ELECTERRAIN] > 0
      spatkmult *= 1.5 if attacker.ability == :PLUS && (attacker.pbPartner.ability == :MINUS || @battle.FE == :SHORTCIRCUIT || (Rejuv && @battle.FE == :ELECTERRAIN)) || @battle.state.effects[:ELECTERRAIN] > 0
      spatkmult *= 1.5 if attacker.ability == :SOLARPOWER && (@battle.pbWeather== :SUNNYDAY) &&  @battle.FE != :FROZENDIMENSION
      spatkmult *= 1.3 if attacker.pbPartner.ability == :BATTERY
      spatkmult *= 2 if attacker.ability == :PUREPOWER && @battle.FE == :PSYTERRAIN
    end
    storedspatk*=((stagemul[spatkstage]/stagediv[spatkstage])*spatkmult)
    storedspatk= attacker.getSpecialStat if @battle.FE == :GLITCH && attacker.class == PokeBattle_Battler
    # Final selection
    if storedatk>storedspatk
      return true
    else
      return false
    end
  end

  def pbIsSpecial?(type=@type)
    return !pbIsPhysical?(type)
  end
end

################################################################################
# Plasma Fists
################################################################################
class PokeBattle_Move_177 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.state.effects[:IonDeluge]!=true
      @battle.pbDisplay(_INTL("A deluge of ions showers the battlefield!"))
      @battle.state.effects[:IonDeluge] = true
    end
    if !attacker.hasWorkingItem(:EVERSTONE) && @battle.canChangeFE?(:ELECTERRAIN)
      duration=3
      duration=6 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
      @battle.setField(:ELECTERRAIN,duration)
      @battle.pbDisplay(_INTL("The terrain became electrified!"))
    end
    return ret
  end
end

#New Gen 8 effects starting below here

################################################################################
# Extra Damage To Megas and similar (Dynamax Cannon, Behemoth Blade, Behemoth Bash)
################################################################################
class PokeBattle_Move_178 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if opponent.isMega? || opponent.isUltra? || opponent.isPrimal? || opponent.isGiga?
      basedmg*=2
    end
    return basedmg
  end
end

################################################################################
# Ignores any redirection attempts (Snipe Shot)
################################################################################
class PokeBattle_Move_179 < PokeBattle_Move
  #handled in pbChangeTarget
end

################################################################################
# Eats Berry and then Sharply Raises Defense (Stuff Cheeks)
################################################################################
class PokeBattle_Move_17A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.item.nil? && pbIsBerry?(attacker.item) && !attacker.pokemon.corrosiveGas
      ourberry = attacker.item
      itemname=getItemName(ourberry)
      attacker.item=nil
      attacker.pokemon.itemRecycle = ourberry
      attacker.pokemon.itemInitial=nil if attacker.pokemon.itemInitial==ourberry
      @battle.pbDisplay(_INTL("{1} ate its {2}!",attacker.pbThis,itemname))
      #pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      # stuff cheecks doesn't need it's own animation it gets the animation from eating the berry
      attacker.pbUseBerry(ourberry,true)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,true)
       #ret=attacker.pbIncreaseStat(PBStats::DEFENSE,2,false)
       attacker.pbIncreaseStat(PBStats::DEFENSE,2,abilitymessage:false)
      end
      #return ret ? 0 : -1
      return 0
    end
    return -1
  end
end

################################################################################
# Boosts all stats and prevents switching out (No Retreat)
################################################################################
class PokeBattle_Move_17B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[:NoRetreat]
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    else
      if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
        return -1
      end
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      if @battle.FE == :CHESS
        for stat in [PBStats::DEFENSE,PBStats::SPDEF]
          if attacker.pbCanReduceStatStage?(stat,false,true)
            attacker.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
          end
        end
        for stat in [PBStats::ATTACK,PBStats::SPATK,PBStats::SPEED]
          if attacker.pbCanIncreaseStatStage?(stat,false)
            attacker.pbIncreaseStat(stat,2,abilitymessage:false)
          end
        end
      else
        boost = 1
        boost = 2 if @battle.FE == :COLOSSEUM 
        for stat in 1..5
          if attacker.pbCanIncreaseStatStage?(stat,false)
            attacker.pbIncreaseStat(stat,boost,abilitymessage:false)
          end
        end
      end
      if attacker.effects[:MeanLook]==-1
        attacker.effects[:MeanLook]=attacker.index
        @battle.pbDisplay(_INTL("{1} can no longer escape!",attacker.pbThis))
        attacker.effects[:NoRetreat] = true
      end
      return 0
    end
  end
end

################################################################################
# Lowers Speed and Forces Fire Weakness (Tar Shot)
################################################################################
class PokeBattle_Move_17C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:TarShot]==true && !opponent.pbCanReduceStatStage?(PBStats::SPEED,false)
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbReduceStat(PBStats::SPEED,1, statdropper: attacker) if opponent.pbCanReduceStatStage?(PBStats::SPEED,false)
    if opponent.effects[:TarShot]==false
      opponent.effects[:TarShot]=true
      @battle.pbDisplay(_INTL("{1} was covered in flammable tar!",opponent.pbThis))
    end
    if (@battle.FE == :MURKWATERSURFACE || @battle.FE == :CORRUPTED)
      if opponent.pbCanPoison?(true)
        opponent.pbPoison(attacker)
        @battle.pbDisplay(_INTL("{1} is poisoned!",opponent.pbThis))
      end
    end
    return 0
  end
end

################################################################################
# Target becomes Psychic type. (Magic Powder)
################################################################################
class PokeBattle_Move_17D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Substitute]>0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if (opponent.ability == :MULTITYPE) ||
      (opponent.ability == :RKSSYSTEM) || opponent.crested == :SILVALLY
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.type1=:PSYCHIC
    opponent.type2=nil
    typename=getTypeName(:PSYCHIC)
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",opponent.pbThis,typename))
    if (@battle.FE == :HAUNTED || @battle.FE == :BEWITCHED) && opponent.pbCanSleep?(true)
       opponent.pbSleep
       @battle.pbDisplay(_INTL("{1} was put to sleep!",opponent.pbThis))
     end
    return 0
  end
end

################################################################################
# Dragon Darts (Dragon Darts)
################################################################################
class PokeBattle_Move_17E < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return (pbDragonDartTargetting(attacker).length % 2) + 1
  end
end

################################################################################
# All pokemon eat their berries (Teatime)
################################################################################
class PokeBattle_Move_17F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    for mons in @battle.battlers
      if !mons.item.nil? && pbIsBerry?(mons.item)
        ourberry = mons.item
        itemname=getItemName(ourberry)
        mons.item=nil
        mons.pokemon.itemRecycle = ourberry
        mons.pokemon.itemInitial=nil if mons.pokemon.itemInitial==ourberry
        @battle.pbDisplay(_INTL("{1} ate its {2}!",mons.pbThis,itemname))
        mons.pbUseBerry(ourberry,true) 
      end
    end
    return 0
  end
end

################################################################################
# Traps target and lowers defenses every turn (Octolock)
################################################################################
class PokeBattle_Move_180 < PokeBattle_Move
    def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:Octolock]>=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    else
      opponent.effects[:Octolock]= attacker.index
      @battle.pbDisplay(_INTL("{1} was caught in the Octolock!",opponent.pbThis))
      return 0
    end
  end
end

################################################################################
# Double Damage if this pokemon moves before target (Fishious Rend, Bolt Beak)
################################################################################
class PokeBattle_Move_181 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if !opponent.hasMovedThisRound? || @battle.switchedOut[opponent.index]
      return basedmg*2
    else
      return basedmg
    end
  end
end

################################################################################
# Swaps effects between the sides of the field (Court Change)
################################################################################
class PokeBattle_Move_182 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    sideOneEffects = attacker.pbOwnSide.effects
    sideTwoEffects = attacker.pbOppositeOpposing.pbOwnSide.effects
    attacker.pbOwnSide.effects = sideTwoEffects
    attacker.pbOppositeOpposing.pbOwnSide.effects = sideOneEffects
    @battle.pbDisplay(_INTL("{1} swapped the battle effects affecting each side of the field!",attacker.pbThis))
  end
end

################################################################################
# Cuts HP to boost every stat (Clangorous Soul)
################################################################################
class PokeBattle_Move_183 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      @battle.pbDisplay(_INTL("{1}'s stats are too high!",attacker.pbThis))
      return -1
    end
    clanglife=[(attacker.totalhp/3.0).floor,1].max
    clanglife=[(attacker.totalhp/2.0).floor,1].max if @battle.FE == :BIGTOP || @battle.ProgressiveFieldCheck(PBFields::CONCERT)
    if attacker.hp<=clanglife
      @battle.pbDisplay(_INTL("It was too weak to use the move!"))
      return -1
    end
    attacker.pbReduceHP(clanglife)
    statboost = 1
    statboost = 2 if @battle.FE == :BIGTOP || @battle.ProgressiveFieldCheck(PBFields::CONCERT)
    for stat in 1..5
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,statboost,abilitymessage:false)
      end
    end
    return 0
  end
end

################################################################################
# Damages based off of defense rather than attack (Body Press)
################################################################################
class PokeBattle_Move_184 < PokeBattle_Move
  # Handled Elsewhere.
  def pbBaseDamage(basedmg,attacker,opponent)
    if @move == :BEHEMOTHBASH && (opponent.isMega? || opponent.isUltra? || opponent.isPrimal? || opponent.isGiga?)
      basedmg*=2
    end
    return basedmg
  end
end

################################################################################
# Sharply Boosts target's offenses (Decorate)
################################################################################
class PokeBattle_Move_185 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !opponent.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
       !opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      @battle.pbDisplay(_INTL("{1}'s stats are too high!",opponent.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if opponent.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      opponent.pbIncreaseStat(PBStats::SPATK,2,abilitymessage:false)
      showanim=false
    end
    if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      opponent.pbIncreaseStat(PBStats::ATTACK,2,abilitymessage:false)
      showanim=false
    end
    return 0
  end
end

################################################################################
# Boosts Speed and Changes type based on forme (Aura Wheel)
################################################################################
class PokeBattle_Move_186 < PokeBattle_Move
  def pbType(attacker,type=@type)
    type = :DARK if attacker.form==1 && attacker.species==:MORPEKO
    return super(attacker,type)
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if attacker.form==1 && attacker.species==:MORPEKO
      @battle.pbAnimation(:AURAWHEELMINUS,attacker,opponent,hitnum) #dark type
    else
      @battle.pbAnimation(:AURAWHEEL,attacker,opponent,hitnum) #electric type
    end
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      attacker.pbIncreaseStat(PBStats::SPEED,1,abilitymessage:false)
    end
    return true
  end
end

################################################################################
# Heals self and partner 1/4 of max hp (Life Dew)
################################################################################
class PokeBattle_Move_187 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp == attacker.totalhp && attacker.pbPartner.hp == attacker.pbPartner.totalhp
      @battle.pbDisplay(_INTL("Everyone's HP is full!"))
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    hpgain1=((attacker.totalhp+1)/4).floor
    hpgain1=((attacker.totalhp+1)/2).floor if @battle.FE == :RAINBOW || @battle.FE == :HOLY
    hpgain2=((attacker.pbPartner.totalhp+1)/4).floor
    hpgain2=((attacker.pbPartner.totalhp+1)/2).floor if @battle.FE == :HOLY
    
    if attacker.hp != attacker.totalhp
      if (attacker.pbPartner.hp == attacker.pbPartner.totalhp || attacker.pbPartner.isFainted?)
        attacker.pbRecoverHP(hpgain1,true)
      end
      attacker.pbRecoverHP(hpgain1,true)
      @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbThis))
      if (@battle.FE == :CORROSIVEMIST || @battle.FE == :MURKWATERSURFACE)
        if attacker.pbCanPoison?(true)
          attacker.pbPoison(attacker)
          @battle.pbDisplay(_INTL("{1} was poisoned!",attacker.pbThis))
        end
      end
    end
    if @battle.FE == :WATERSURFACE && !attacker.effects[:AquaRing]
      pbShowAnimation(:AQUARING,attacker,nil,hitnum,alltargets,showanimation)
      attacker.effects[:AquaRing]=true
      @battle.pbDisplay(_INTL("{1} surrounded itself with a veil of water!",attacker.pbThis))
    end
    if !attacker.pbPartner.isFainted?
      if attacker.pbPartner.hp != attacker.pbPartner.totalhp
        attacker.pbPartner.pbRecoverHP(hpgain2,true)
        @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbPartner.pbThis))
        if attacker.pbPartner.pbCanPoison?(true) && @battle.FE == :CORROSIVEMIST
          attacker.pbPartner.pbPoison(attacker)
          @battle.pbDisplay(_INTL("{1} was poisoned!",attacker.pbPartner.pbThis))
        end
      end
    end
    return 0
  end
end

################################################################################
# Protects and sharply lowers def if contact is made (Obstruct)
################################################################################
class PokeBattle_Move_188 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !PBStuff::RATESHARERS.include?(attacker.previousMove) && !(attacker.crested == :VESPIQUEN && attacker.previousMove == :DEFENDORDER)
      attacker.effects[:ProtectRate]=0
    end
    priority = @battle.pbPriority
    if (@battle.doublebattle && attacker == priority[3]) || (!@battle.doublebattle && attacker == priority[1])
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if @battle.pbRandom(65536)<(65536/(3**attacker.effects[:ProtectRate])).floor
      attacker.effects[:Protect]=:Obstruct
      attacker.effects[:ProtectRate]+=1
      @battle.pbAnimation(@move,attacker,nil)
      @battle.pbDisplay(_INTL("{1} shielded itself against damage!",attacker.pbThis))
      return 0
    else
      attacker.effects[:ProtectRate]=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
  end
end

################################################################################
# Traps the user and the target. (Jaw Lock)
################################################################################

class PokeBattle_Move_189 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[:MeanLook]>=0 ||
       opponent.effects[:Substitute]>0 || opponent.effects[:NoRetreat] ||
       attacker.effects[:MeanLook]>=0 ||
       attacker.effects[:Substitute]>0 || attacker.effects[:NoRetreat]
      return super(attacker,opponent,hitnum,alltargets,showanimation)
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[:MeanLook]=attacker.index
    attacker.effects[:MeanLook]=opponent.index
    @battle.pbDisplay(_INTL("{1} can't escape now!",opponent.pbThis))
    @battle.pbDisplay(_INTL("{1} can't escape now!",attacker.pbThis))
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Deals damage and raises Light Screen (Glitzy Glow)
################################################################################
class PokeBattle_Move_772 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if attacker.pbOwnSide.effects[:LightScreen]>0
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation=false)
    attacker.pbOwnSide.effects[:LightScreen]=5
    attacker.pbOwnSide.effects[:LightScreen]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
    attacker.pbOwnSide.effects[:LightScreen]=8 if @battle.FE == :MIRROR
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("Glitzy Glow raised your team's Special Defense!"))
    else
      @battle.pbDisplay(_INTL("Glitzy Glow raised the opposing team's Special Defense!"))
    end
    if @battle.FE == :MIRROR
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,1,false)
      end
    end
    return ret
  end  
end

################################################################################
# Deals damage and raises Reflect. (Baddy Bad)
################################################################################
class PokeBattle_Move_773 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if attacker.pbOwnSide.effects[:Reflect]>0
      return -1
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation=false)
    attacker.pbOwnSide.effects[:Reflect]=5
    attacker.pbOwnSide.effects[:Reflect]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
    attacker.pbOwnSide.effects[:Reflect]=8 if @battle.FE == :MIRROR
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("Baddy Bad raised your team's Defense!"))
    else
      @battle.pbDisplay(_INTL("Baddy Bad raised the opposing team's Defense!"))
    end  
    if @battle.FE == :MIRROR
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,1,false)
      end
    end
    return ret    
  end  
end

################################################################################
# Deals damage and inflicts Leech Seed. (Sappy Seed)
################################################################################
class PokeBattle_Move_774 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.effects[:LeechSeed]>=0 ||
        opponent.effects[:Substitute]>0
      return -1
    end
    if opponent.hasType?(:GRASS)
      return ret
    end
    if opponent.ability == (:SAPSIPPER) && !(opponent.moldbroken)
      if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK)
        opponent.pbIncreaseStatBasic(PBStats::ATTACK,1)
        @battle.pbCommonAnimation("StatUp",opponent,nil)
        @battle.pbDisplay(_INTL("{1}'s {2} raised its Attack!",
            opponent.pbThis,$cache.abil[opponent.ability].name))
      else
        @battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
            opponent.pbThis,$cache.abil[opponent.ability].name,self.name))
      end
      return ret      
    end    
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation=false)
    opponent.effects[:LeechSeed]=attacker.index
    @battle.pbDisplay(_INTL("{1} was seeded!",opponent.pbThis))
    return ret
  end  
end

################################################################################
# Deals damage and eliminates all stat changes. (Freezy Frost)
################################################################################
class PokeBattle_Move_775 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum,alltargets,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...4
      @battle.battlers[i].stages[PBStats::ATTACK]   = 0
      @battle.battlers[i].stages[PBStats::DEFENSE]  = 0
      @battle.battlers[i].stages[PBStats::SPEED]    = 0
      @battle.battlers[i].stages[PBStats::SPATK]    = 0
      @battle.battlers[i].stages[PBStats::SPDEF]    = 0
      @battle.battlers[i].stages[PBStats::ACCURACY] = 0
      @battle.battlers[i].stages[PBStats::EVASION]  = 0
    end
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation=false)
    @battle.pbDisplay(_INTL("All stat changes were eliminated!"))
    return ret
  end  
end

################################################################################
# Deals damage and cures party status. (Sparkly Swirl)
################################################################################
class PokeBattle_Move_776 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum,alltargets,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation=false)
    @battle.pbDisplay(_INTL("A soothing aroma wafted through the area!"))
    activepkmn=[]
    for i in @battle.battlers
      next if attacker.pbIsOpposing?(i.index)
      case i.status
        when :PARALYSIS
          @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",i.pbThis))
        when :SLEEP
          @battle.pbDisplay(_INTL("{1} was woken from its sleep.",i.pbThis))
        when :POISON
          @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",i.pbThis))
        when :BURN
          @battle.pbDisplay(_INTL("{1} was cured of its burn.",i.pbThis))
        when :FROZEN
          @battle.pbDisplay(_INTL("{1} was defrosted.",i.pbThis))
        when :PETRFIED
          @battle.pbDisplay(_INTL("{1} was released from the stone.",i.pbThis))
      end
      i.status=nil
      i.statusCount=0
      activepkmn.push(i.pokemonIndex)
    end
    party=@battle.pbParty(attacker.index) # NOTE: Considers both parties in multi battles
    for i in 0...party.length
      next if activepkmn.include?(i)
      next if !party[i] || party[i].isEgg?
      case party[i].status
        when :PARALYSIS
          @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",party[i].name))
        when :SLEEP
          @battle.pbDisplay(_INTL("{1} was woken from its sleep.",party[i].name))
        when :POISON
          @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",party[i].name))
        when :BURN
          @battle.pbDisplay(_INTL("{1} was cured of its burn.",party[i].name))
        when :FROZEN
          @battle.pbDisplay(_INTL("{1} was defrosted.",party[i].name))
        when :PETRFIED
          @battle.pbDisplay(_INTL("{1} was released from the stone.",party[i].name))
      end
      party[i].status=nil
      party[i].statusCount=0
    end
    return ret
  end  
end

################################################################################
# Damage scales with Happiness, always hits. (Veevee Volley & Pika Papow)
################################################################################
class PokeBattle_Move_777 < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    return true
  end
  def pbBaseDamage(basedmg,attacker,opponent)
    return [attacker.happiness,250].min if attacker.crested == :LUVDISC
    return 102 if @battle.FE == :CONCERT4
    return [(attacker.happiness*2/5).floor,1].max
  end
end

################################################################################
# Hits twice, may cause flinch. (Double Iron Bash)
################################################################################
class PokeBattle_Move_778 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 2
  end
  
  def pbAdditionalEffect(attacker,opponent)
    if opponent.ability != (:INNERFOCUS) &&
        !opponent.damagestate.substitute &&
        opponent.status!=:SLEEP && opponent.status!=:FROZEN
      opponent.effects[:Flinch]=true
      return true
    end
    return false
  end
end

  ################################################################################
# Destroys the terrain (Steel Roller) 
################################################################################
class PokeBattle_Move_306 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (@battle.canChangeFE?(:INDOOR))
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      duration=5
      duration=8 if attacker.hasWorkingItem(:AMPLIFIELDROCK)
      @battle.setField(:INDOOR,duration)
      @battle.pbDisplay(_INTL("The terrain was flattened!"))
    end
    return ret
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.canChangeFE?(:INDOOR)
      return basedmg*2
    end
    return basedmg
  end
end

################################################################################
# Hits 2-5 times, boosts Speed and drops Defense (Scale Shot) 
################################################################################
class PokeBattle_Move_307 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbOnStartUse(attacker)
    @loopcount=0
    return true
  end

  def pbNumHits(attacker)
    hitchances=[2,2,3,3,4,5]
    ret=hitchances[@battle.pbRandom(hitchances.length)]
    ret=5 if attacker.ability == (:SKILLLINK)
    return ret
  end
  
  def pbAdditionalEffect(attacker,opponent)
    showanim=true
    if @loopcount < 1
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,1,abilitymessage:false)
        showanim=false
      end
      if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,false,true)
        attacker.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false, statdropper: attacker)
        showanim=false
      end
      @loopcount+=1
    end
    return true
  end
end

################################################################################
# Two turn attack. Ups user's Special Attack by 1 stage first turn, attacks second
# turn. (Meteor Beam) 
################################################################################
class PokeBattle_Move_308 < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    @immediate=true if attacker.crested == :CLAYDOL
    if @battle.FE == :STARLIGHT || @battle.FE == :NEWWORLD
      @immediate=true
      @battle.pbDisplay(_INTL("{1} absorbed the starlight!",attacker.pbThis)) if @battle.FE == :STARLIGHT
    elsif attacker.ability == :ANABOLIC && @battle.state.effects[:ELECTERRAIN] > 0
      @immediate=true
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.anabolic
      @immediate=true
      attacker.anabolic = false
      @battle.pbDisplay(_INTL("{1}'s {2} flowed through the user!",attacker.pbThis,getAbilityName(attacker.ability)))
    elsif !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
      attacker.pbDisposeItem(false)
      @battle.pbDisplay(_INTL("{1} consumed its Power Herb!",attacker.pbThis))
    end
    return false if @immediate
    return attacker.effects[:TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[:TwoTurnAttack]!=0
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation) # Charging anim
      showanim=true
      @battle.pbDisplay(_INTL("{1} is overflowing with space power!",attacker.pbThis))
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,1,abilitymessage:false)
        showanim=false
      end
    end
    if @immediate && !attacker.ability == :ANABOLIC
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("{1} became fully charged due to its Power Herb!",attacker.pbThis))
      attacker.pbDisposeItem(false)
    end
    return 0 if attacker.effects[:TwoTurnAttack]!=0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Becomes physical if Atk does more than Sp. Atk. May poison target (Shell Side Arm) 
################################################################################
class PokeBattle_Move_309 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    smartDamageCategory(attacker,opponent)
  
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
  end
  
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanPoison?(attacker,false,self)
      opponent.pbPoison(attacker)
    end
  end
end

################################################################################
# User faints. Deals double damage in Misty Terrain. (Misty Explosion) 
################################################################################
class PokeBattle_Move_30A < PokeBattle_Move
  def pbOnStartUse(attacker)
    bearer=@battle.pbCheckGlobalAbility(:DAMP)
    
    if bearer && !(bearer.moldbroken)
      @battle.pbDisplay(_INTL("{1}'s {2} prevents {3} from using {4}!",
          bearer.pbThis,$cache.abil[bearer.ability].name,attacker.pbThis(true),@name))
      return false
    end
    @battle.pbAnimation(@move,attacker,nil)
    pbShowAnimation(@move,attacker,nil)
    attacker.pbReduceHP(attacker.hp)
    return true
  end
  
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.FE == :MISTY || @battle.state.effects[:MISTY] > 0 || @battle.FE == :CORROSIVEMIST
      return basedmg*2
    end
    return basedmg
  end

  def pbType(attacker,type=@type)
    type=@type
    if (@battle.FE == :CORROSIVEMIST)
      type = :POISON
    end
    return super(attacker,type)
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return
  end
end

################################################################################
# Adds 1 to priority on Grassy Terrain (Grassy Glide) 
################################################################################
class PokeBattle_Move_310 < PokeBattle_Move
  # Handled in Battle -> def pbPriority
end

################################################################################
# Power doubles on Electric Terrain (Rising Voltage) 
################################################################################
class PokeBattle_Move_311 < PokeBattle_Move
  # def pbAdditionalEffect(attacker,opponent)
  #   if (@move == :POWERSURGE)
  #     pbShowAnimation(:ELECTRICTERRAIN,attacker,opponent)
  #     @battle.setField(:ELECTERRAIN,inc=1)
  #     @battle.pbDisplay(_INTL("Power surged across the battlefield!"))
  #     @battle.quarkdriveCheck
  #   end
  # end

  def pbBaseDamage(basedmg,attacker,opponent)
    if (@battle.FE == :ELECTERRAIN || @battle.state.effects[:ELECTERRAIN] > 0) && !opponent.isAirborne?
      return basedmg*2 
    end  
    return basedmg
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :POWERSURGE
      @battle.pbAnimation(:RISINGVOLTAGE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
  
end

################################################################################
# Power is doubled in terrain. Type changes depending on the terrain.
# (Terrain Pulse) 
################################################################################
class PokeBattle_Move_312 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.FE != :INDOOR 
      return basedmg*2
    end
    return basedmg
  end

  def pbType(attacker,type=@type)
    type = 0
    case @battle.FE
      when :CRYSTALCAVERN
        type = @battle.field.getRoll
      when :NEWWORLD
        type = @battle.getRandomType
      else
        type = @battle.field.mimicry if @battle.field.mimicry
    end
    type=super(attacker,type)
    return type
  end
end

################################################################################
# Burns opposing Pokemon that have increased their stats in that turn before the
# execution of this move (Burning Jealousy) 
################################################################################
class PokeBattle_Move_313 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    #if opponent.effects[:Jealousy] && opponent.pbCanBurn?(false)
    #  opponent.pbBurn(attacker)
    #end
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
      PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      if opponent.stages[i]>0
        opponent.pbBurn(attacker)    
        break
      end
    end
  end
end

################################################################################
# Power is doubled if user's stats were reduced in the turn the move would be
# executed (Lash Out) 
################################################################################
class PokeBattle_Move_314 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    if attacker.effects[:LashOut]
      return (damagemult*2.0).round
    end
    return damagemult
  end
end

################################################################################
# Fails when the target isn't holding an item (Poltergeist) 
################################################################################
class PokeBattle_Move_315 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    if opponent.item.nil? || @battle.state.effects[:MagicRoom] > 0 || opponent.ability == :KLUTZ
      return true
    else
      @battle.pbDisplay(_INTL("{1} is about to be attacked by its {2}!",opponent.pbThis,getItemName(opponent.item)))
      return false
    end
  end
end

################################################################################
# The targets' held items are rendered useless for the rest of the battle
# (Corrosive Gas) 
################################################################################
class PokeBattle_Move_316 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    if !(opponent.pokemon.corrosiveGas || opponent.ability == (:STICKYHOLD) || 
      @battle.pbIsUnlosableItem(opponent,opponent.item) || opponent.item.nil?)
      opponent.pokemon.corrosiveGas = true
      @battle.pbDisplay(_INTL("{1} corroded {2}'s {3}!",attacker.pbThis,opponent.pbThis(true),getItemName(opponent.item)))
    end
    if @battle.FE == :BACKALLEY || @battle.FE == :CITY
      for stat in 1..5
        if opponent.pbCanReduceStatStage?(stat,false)
          opponent.pbReduceStat(stat,1,abilitymessage:false, statdropper: attacker)
        end
      end
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Increases the ally's Attack and Defense by 1 stage each (Coaching) 
################################################################################
class PokeBattle_Move_317 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle || !opponent
        @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    if !opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
        !opponent.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",opponent.pbThis))
      return -1
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
    pbShowAnimation(@move,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      opponent.pbIncreaseStat(PBStats::ATTACK,1,abilitymessage:false)
      showanim=false
    end
    if opponent.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      opponent.pbIncreaseStat(PBStats::DEFENSE,1,abilitymessage:false)
      showanim=false
    end
    return 0
  end
end

###############################################################################
# The user restores 1/3 of its maximum HP, rounded half up. If there is an 
# adjacent ally, the user restores 1/3 of both its and its ally's maximum HP, 
# rounded up. Also heals status conditions. (Jungle Healing / Lunar Blessing) 
################################################################################
class PokeBattle_Move_318 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (@move == :FINALE)
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      for i in [attacker,attacker.pbPartner]
        next if !i || i.isFainted?
        pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
        showanim=true
        recoveramount = (i.totalhp/6.0).round
        i.pbRecoverHP(recoveramount,true)
      end
      return ret
    end

    didsomething=false
    fullHP=false
    healstatus=false
    for i in [attacker,attacker.pbPartner]
      next if !i || i.isFainted?
      i.status = nil
      if i.hp==i.totalhp
        @battle.pbDisplay(_INTL("{1}'s HP is full!",i.pbThis))
        fullHP=true
        next
      end
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation) if !didsomething
      didsomething=true
      showanim=true
      recoveramount = (i.totalhp/3.0).round
      recoveramount = (i.totalhp/3.0*2).round if @move == :LUNARBLESSING && (@battle.FE == :STARLIGHT || @battle.FE == :NEWWORLD) 
      i.pbRecoverHP(recoveramount,true)
      @battle.pbDisplay(_INTL("{1}'s HP was restored.",i.pbThis))
    end
    return -1 if fullHP
    if !didsomething
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    return 0
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :LUNARBLESSINg
      @battle.pbAnimation(:LUNARDANCE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end


################################################################################
# Hits 3 times. This attack is always a critical hit. (Surging Strikes) 
################################################################################
class PokeBattle_Move_319 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 3
  end
end

################################################################################
# Deals damage and decreases the PP of the last move the target used by 3.
# (Eerie Spell) 
################################################################################
class PokeBattle_Move_320 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    for i in opponent.moves
      if i && $cache.moves[i.move].move==opponent.lastMoveUsed && i.pp>0
        reduction=[3,i.pp].min
        i.pp-=reduction
        @battle.pbDisplay(_INTL("It reduced the PP of {1}'s {2} by {3}!",opponent.pbThis(true),i.name,reduction))
        return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
      end
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation) if @basedamage>0
  end
end

################################################################################
# Power boosted and becomes a spread move on Psychic Terrain (Expanding Force) 
################################################################################
# targeting change handled in pbTarget
class PokeBattle_Move_321 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    if (@battle.FE == :PSYTERRAIN || @battle.state.effects[:PSYTERRAIN] > 0) && !attacker.isAirborne?
      return (damagemult*1.5).round
    end
    return damagemult
  end
end

################################################################################
# Deals damage and may inflict poison, paralysis or sleep.
# PLA Pokemon Legends: Arceus (Dire Claw)
################################################################################
class PokeBattle_Move_500 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    rnd=@battle.pbRandom(3)
    case rnd
      when 0
        return false if !opponent.pbCanSleep?(false)
        opponent.pbSleep
        @battle.pbDisplay(_INTL("{1} fell asleep!",opponent.pbThis))
      when 1
        return false if !opponent.pbCanPoison?(false)
        opponent.pbPoison(attacker)
        @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
      when 2
        return false if !opponent.pbCanParalyze?(false)
        opponent.pbParalyze(attacker)
        @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
    end
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :DIRECLAW
      @battle.pbAnimation(:CROSSPOISON,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end   

################################################################################
# Increases the user's Attack, Defense and Speed  by 1 stage each. 
# PLA Pokemon Legends: Arceus (Victory Dance)
################################################################################
class PokeBattle_Move_501 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    showanim=true
    boost_amount=1
    if (@battle.FE == :BIGTOP || @battle.FE == :DANCEFLOOR)
      boost_amount=2
    end
    for stat in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED]
      if attacker.pbCanIncreaseStatStage?(stat,false)
        attacker.pbIncreaseStat(stat,boost_amount,abilitymessage:false)
      end
    end
    return 0
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :VICTORYDANCE
      @battle.pbAnimation(:QUIVERDANCE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# This may also poison the target. This move's power is doubled if the target 
# has a status condition.
# PLA Pokemon Legends: Arceus (Barb Barrage)
################################################################################
class PokeBattle_Move_502 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if (@battle.FE == :CORROSIVE || @battle.FE == :CORROSIVEMIST ||
      @battle.FE == :WASTELAND || @battle.FE == :MURKWATERSURFACE) ||
      (opponent.status== :POISON && opponent.effects[:Substitute]==0)
      return basedmg*2
    end
    return basedmg
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
    if id == :BARBBARRAGE
      @battle.pbAnimation(:PINMISSILE,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Deals damage, decreases target's Defense stat and may flinch. 
# PLA Pokemon Legends: Arceus (Triple Arrows)
################################################################################
class PokeBattle_Move_503 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,false)
      opponent.pbReduceStat(PBStats::DEFENSE,1,abilitymessage:false,statdropper: attacker)
    end
    return true
  end

  def pbSecondAdditionalEffect(attacker,opponent)
    if opponent.ability != :INNERFOCUS && !opponent.damagestate.substitute
      opponent.effects[:Flinch]=true
      return true
    end
    return false
  end

    # Replacement animation till a proper one is made
    def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
      return if !showanimation
      if id == :TRIPLEARROWS
        @battle.pbAnimation(:THOUSANDARROWS,attacker,opponent,hitnum)
      else
        @battle.pbAnimation(id,attacker,opponent,hitnum)
      end
    end
end

################################################################################
# This may also burn the target. This move's power is doubled if the target 
# has a status condition.
# PLA Pokemon Legends: Arceus (Infernal Parade)
################################################################################
class PokeBattle_Move_504 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.FE == :HAUNTED ||
      ((!opponent.status.nil? || (opponent.ability == :COMATOSE && @battle.FE != :ELECTERRAIN)) &&
       opponent.effects[:Substitute]==0)
      return basedmg*2
    end
    return basedmg
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanBurn?(false)
        opponent.pbBurn(attacker)
        @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))  
    return true
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :INFERNALPARADE
      @battle.pbAnimation(:WILLOWISP,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Heals user's status, and raises user's Special Attack and Special Defense.
# PLA Pokemon Legends: Arceus (Take Heart)
################################################################################
class PokeBattle_Move_505 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
      t=attacker.status
      if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
        !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false) &&
        t.nil?
       @battle.pbDisplay(_INTL("But it failed!"))
       return -1
     end
      attacker.status=nil
      attacker.statusCount=0
      pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
      case t
        when :PARALYSIS
          @battle.pbDisplay(_INTL("{1} was cured of its paralysis.",attacker.pbThis))
        when :SLEEP
          @battle.pbDisplay(_INTL("{1} was woken from its sleep.",attacker.pbThis))
        when :POISON
          @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",attacker.pbThis))
        when :BURN
          @battle.pbDisplay(_INTL("{1} was cured of its burn.",attacker.pbThis))
        when :FROSTBITE
          @battle.pbDisplay(_INTL("{1} was cured of its frostbite.",attacker.pbThis))
        when :FROZEN
          @battle.pbDisplay(_INTL("{1} was defrosted.",attacker.pbThis))
        when :PETRFIED
          @battle.pbDisplay(_INTL("{1} was released from the stone.",i.pbThis))  
      end
      showanim=true
      increment = 1
      increment = 2 if @move==:TAKEHEART && (@battle.FE == :WATERSURFACE || @battle.FE == :UNDERWATER)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,1,abilitymessage:false)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,abilitymessage:false)
        showanim=false
      end
      attacker.pbRecoverHP(((attacker.totalhp+1)/4).floor,true)
      @battle.pbDisplay(_INTL("{1}'s HP was restored.",attacker.pbThis))
      return 0
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :TAKEHEART
      @battle.pbAnimation(:CALMMIND,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# If attack misses, user takes crash damage of 1/2 of max HP. 
# May cause confusion. (Axe Kick)
################################################################################
class PokeBattle_Move_506 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return @battle.state.effects[:Gravity]!=0 && attacker.ability != :GRAVFLUX
  end

  def pbAdditionalEffect(attacker,opponent)
    if opponent.pbCanConfuse?(false)
      opponent.effects[:Confusion]=2+@battle.pbRandom(4)
      @battle.pbCommonAnimation("Confusion",opponent,nil)
      @battle.pbDisplay(_INTL("{1} became confused!",opponent.pbThis))
      return true
    end
    return false
  end

  # Replacement animation till a proper one is made
  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if id == :AXEKICK
      @battle.pbAnimation(:STOMP,attacker,opponent,hitnum)
    else
      @battle.pbAnimation(id,attacker,opponent,hitnum)
    end
  end
end

################################################################################
# Acid Downpour 
################################################################################
class PokeBattle_Move_800 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.FE == :WASTELAND &&
     ((!opponent.hasType?(:POISON) && !opponent.hasType?(:STEEL)) || opponent.corroded) &&
     !(opponent.ability == :TOXICBOOST) &&
     !(opponent.ability == :POISONHEAL) && opponent.crested != :ZANGOOSE && opponent.crested != :GOODRA
     (!(opponent.ability == :IMMUNITY) && !(opponent.moldbroken))
      rnd=@battle.pbRandom(4)
      case rnd
        when 0
          if opponent.pbCanBurn?(false)
            opponent.pbBurn(attacker)
            @battle.pbDisplay(_INTL("{1} was burned!",opponent.pbThis))
          end
        when 1
          if opponent.pbCanFreeze?(false)
            opponent.pbFreeze
            @battle.pbDisplay(_INTL("{1} was frozen solid!",opponent.pbThis))
          end
        when 2
          if opponent.pbCanParalyze?(false)
            opponent.pbParalyze(attacker)
            @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!",opponent.pbThis))
          end
        when 3
          if opponent.pbCanPoison?(false)
            opponent.pbPoison(attacker)
            @battle.pbDisplay(_INTL("{1} was poisoned!",opponent.pbThis))
          end
      end
    end
    return ret
  end
end

################################################################################
# Bloom Doom
################################################################################
class PokeBattle_Move_801 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.canChangeFE?([:GRASSY,:FOREST,:FLOWERGARDEN1,:FLOWERGARDEN2,:FLOWERGARDEN3,:FLOWERGARDEN4,:FLOWERGARDEN5])
      @battle.setField(:GRASSY,3)
      @battle.pbDisplay(_INTL("The terrain became grassy!"))
    end
    return ret
  end
end

################################################################################
# Shattered Psyche
################################################################################
class PokeBattle_Move_802 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.FE == :PSYTERRAIN
      if opponent.pbCanConfuse?(false)
        opponent.effects[:Confusion]=2+@battle.pbRandom(4)
        @battle.pbCommonAnimation("Confusion",opponent,nil)
        @battle.pbDisplay(_INTL("The field got too weird for {1}!",opponent.pbThis(true)))
      end
    end
    return ret
  end
end

################################################################################
# Stoked Sparksurfer
################################################################################
class PokeBattle_Move_803 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.canChangeFE?(:ELECTERRAIN)
      @battle.setField(:ELECTERRAIN,3)
      @battle.pbDisplay(_INTL("The terrain became electrified!"))
    end
    return ret
  end

  def pbAdditionalEffect(attacker,opponent)
    return false if !opponent.pbCanParalyze?(false)
    opponent.pbParalyze(attacker)
    @battle.pbDisplay(_INTL("{1} was paralyzed! It may be unable to move!",opponent.pbThis))
    return true
  end
end

################################################################################
# Extreme Evoboost
################################################################################
class PokeBattle_Move_804 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
      !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false) &&
      !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false) &&
      !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
      !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
     @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
     return -1
    end
    pbShowAnimation(@move,attacker,nil,hitnum,alltargets,showanimation)
    for stat in 1..5
      if attacker.pbCanIncreaseStatStage?(stat,false)
       attacker.pbIncreaseStat(stat,2)
      end
    end
    return 0    
  end
end

################################################################################
# Genesis Supernova
################################################################################
class PokeBattle_Move_805 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.canChangeFE?(:PSYTERRAIN)
      @battle.setField(:PSYTERRAIN,5)
      @battle.pbDisplay(_INTL("The terrain became mysterious!"))
    end
    return ret
  end
end

################################################################################
# Malicious Moonsault
################################################################################
class PokeBattle_Move_806 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    damagemult*= 2.0 if opponent.effects[:Minimize]
    return damagemult
  end
end

################################################################################
# Splintered Stormshards
################################################################################
class PokeBattle_Move_807 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if @battle.canChangeFE?
      @battle.breakField
      @battle.pbDisplay(_INTL("The field was devastated!"))
    end
    return ret
  end
end

################################################################################
# Clangorous Soulblaze
################################################################################
class PokeBattle_Move_808 < PokeBattle_Move
  def pbOnStartUse(attacker)
    @loopcount=0
    @totaldamage=0
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    @loopcount+=1
    @totaldamage+=ret
    if @totaldamage>0 && (!attacker.midwayThroughMove || @loopcount==alltargets.length)
      if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
        !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false) &&
        !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false) &&
        !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
        !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",attacker.pbThis))
      end
      for stat in 1..5
        if attacker.pbCanIncreaseStatStage?(stat,false)
          attacker.pbIncreaseStat(stat,1,abilitymessage:false)
        end
      end
    end
    return ret
  end
end

################################################################################
# Guardian of Alola
################################################################################
class PokeBattle_Move_809 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    hploss = (opponent.hp*0.75).floor
    return pbEffectFixedDamage(hploss,attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    case attacker.species
      when :TAPULELE
        @battle.pbAnimation(:GUARDIANOFALOLALELE,attacker,opponent,hitnum)
      when :TAPUBULU
        @battle.pbAnimation(:GUARDIANOFALOLABULU,attacker,opponent,hitnum)
      when :TAPUFINI
        @battle.pbAnimation(:GUARDIANOFALOLAFINI,attacker,opponent,hitnum)
      else
        @battle.pbAnimation(id,attacker,opponent,hitnum) # Tapu Koko
    end
  end
end
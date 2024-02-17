PokeBattle_Battler.class_eval{
  def pbCalcAttack()
    stagemul=[2,2,2,2,2,2,2,3,4,5,6,7,8]
    stagediv=[8,7,6,5,4,3,2,2,2,2,2,2,2]    
    atk=@attack
    atkstage=@stages[PBStats::ATTACK]+6
    if @effects[:PowerTrick]
      atk=@defense
      atkstage=@stages[PBStats::DEFENSE]+6
    end    
    if @stages[PBStats::ATTACK] >= 0
      stagemulp=1+0.5*@stages[PBStats::ATTACK]
      atk=(atk*1.0*stagemulp).floor  
    else        
      atk=(atk*1.0*stagemul[atkstage]/stagediv[atkstage]).floor
    end  
    atkmult=0x1000       
    if (@battle.pbWeather== :SUNNYDAY || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN) || @battle.FE == :BEWITCHED || 
      self.crested == :CHERRIM || self.pbPartner.crested == :CHERRIM )
      if self.ability == (:FLOWERGIFT) && self.species == :CHERRIM
        atkmult=(atkmult*1.5).round
      end
      if self.pbPartner.ability == (:FLOWERGIFT)  && self.pbPartner.species == :CHERRIM
        atkmult=(atkmult*1.5).round 
      end
    end    
    if @battle.FE == :STARLIGHT || @battle.FE == :NEWWORLD
      atkmult=(atkmult*1.5).round if self.ability == (:VICTORYSTAR)
      partner=self.pbPartner
      atkmult=(atkmult*1.5).round if partner && partner.ability == (:VICTORYSTAR)
    end
    atkmult=(atkmult*1.5).round if self.ability == (:GUTS) && !self.status.nil? 
    atkmult=(atkmult*1.5).round if self.ability == (:HUSTLE)
    atkmult=(atkmult*0.5).round if self.ability == (:DEFEATIST) && self.hp<=(self.totalhp/2).floor
    atkmult=(atkmult*2.0).round if ((self.ability == (:PUREPOWER) && @battle.FE != :PSYTERRAIN) || self.ability == (:HUGEPOWER))
    atkmult=(atkmult*0.5).round if self.ability == (:SLOWSTART) && self.turncount<5 
    atkmult=(atkmult*2.0).round if self.hasWorkingItem(:THICKCLUB) && self.species == :CUBONE || self.species == :MAROWAK
    atkmult=(atkmult*2.0).round if self.hasWorkingItem(:LIGHTBALL) && self.species == :PIKACHU
    atkmult=(atkmult*1.5).round if self.hasWorkingItem(:CHOICEBAND)
    atkmult=(atkmult*1.5).round if self.ability == (:QUEENLYMAJESTY) && (@battle.FE==:CHESS || @battle.FE==:FAIRYTALE)
    atkmult=(atkmult*1.5).round if self.ability == (:LONGREACH) && (@battle.FE==:MOUNTAIN || @battle.FE==:SNOWYMOUNTAIN || @battle.FE==:SKY)
    atkmult=(atkmult*1.5).round if self.ability == (:CORROSION) && (@battle.FE==:CORROSIVE || @battle.FE==:CORROSIVEMIST ||  @battle.FE==:CORRUPTED)
    atkmult=(atkmult*1.3).round if self.ability == :QUARKDRIVE && self.effects[:Quarkdrive][0] == PBStats::ATTACK    
    atk=(atk*atkmult*1.0/0x1000).round
    return atk
  end
  
  def pbCalcSpAtk()
    stagemul=[2,2,2,2,2,2,2,3,4,5,6,7,8]
    stagediv=[8,7,6,5,4,3,2,2,2,2,2,2,2]    
    atk=@spatk
    atkstage=@stages[PBStats::SPATK]+6
    if @stages[PBStats::SPATK] >= 0
      stagemulp=1+0.5*@stages[PBStats::SPATK]
      atk=(atk*1.0*stagemulp).floor  
    else        
      atk=(atk*1.0*stagemul[atkstage]/stagediv[atkstage]).floor
    end  
    atkmult=0x1000
    if (self.ability == (:PLUS) || self.ability == (:MINUS))
      partner=self.pbPartner
      if partner.ability == (:PLUS) || partner.ability == (:MINUS) 
        atkmult=(atkmult*1.5).round
      elsif @battle.FE == :SHORTCIRCUIT || @battle.FE == :ELECTERRAIN
        atkmult=(atkmult*1.5).round
      end
    end
    atkmult=(atkmult*1.3).round if self.pbPartner.ability == (:BATTERY) && @battle.FE != :ELECTERRAIN
    atkmult=(atkmult*1.5).round if self.pbPartner.ability == (:BATTERY) && @battle.FE == :ELECTERRAIN
    atkmult=(atkmult*0.5).round if self.ability == (:DEFEATIST) && self.hp<=(self.totalhp/2).floor
    atkmult=(atkmult*2.0).round if self.ability == (:PUREPOWER) && @battle.FE == :PSYTERRAIN
    atkmult=(atkmult*1.5).round if self.ability == (:SOLARPOWER) && @battle.pbWeather== :SUNNYDAY
    atkmult=(atkmult*2.0).round if self.hasWorkingItem(:DEEPSEATOOTH) && self.species == :CLAMPERL
    atkmult=(atkmult*2.0).round if self.hasWorkingItem(:LIGHTBALL) && self.species == :PIKACHU
    atkmult=(atkmult*1.5).round if self.hasWorkingItem(:CHOICESPECS)
    if @battle.FE == :STARLIGHT || @battle.FE == :NEWWORLD
      atkmult=(atkmult*1.5).round if self.ability == (:VICTORYSTAR)
      partner=self.pbPartner
      atkmult=(atkmult*1.5).round if partner && partner.ability == (:VICTORYSTAR)
    end
    atkmult=(atkmult*1.5).round if self.ability == (:QUEENLYMAJESTY) && (@battle.FE==:CHESS || @battle.FE==:FAIRYTALE)
    atkmult=(atkmult*1.5).round if self.ability == (:LONGREACH) && (@battle.FE==:MOUNTAIN || @battle.FE==:SNOWYMOUNTAIN || @battle.FE==:SKY)
    atkmult=(atkmult*1.5).round if self.ability == (:CORROSION) && (@battle.FE==:CORROSIVE || @battle.FE==:CORROSIVEMIST ||  @battle.FE==:CORRUPTED)
    atkmult=(atkmult*1.3).round if self.ability == :QUARKDRIVE && self.effects[:Quarkdrive][0] == PBStats::SPATK   
    atk=(atk*atkmult*1.0/0x1000).round
    return atk
  end  
  
  def pbCalcDefense()
    stagemul=[2,2,2,2,2,2,2,3,4,5,6,7,8]
    stagediv=[8,7,6,5,4,3,2,2,2,2,2,2,2]      
    defense=@defense
    defstage=@stages[PBStats::DEFENSE]+6
    if @effects[:PowerTrick]
      defense=@attack
      defstage=@stages[PBStats::DEFENSE]+6
    end       
    # TODO: Wonder Room should apply around here
    if @stages[PBStats::DEFENSE] >= 0
      stagemulp=1+0.5*@stages[PBStats::DEFENSE]
      defense=(defense*1.0*stagemulp).floor
    else        
      defense=(defense*1.0*stagemul[defstage]/stagediv[defstage]).floor
    end  
    defmult=0x1000  
    defmult=(defmult*1.5).round if self.ability == (:MARVELSCALE) && (!self.status.nil? || @battle.FE == :MISTY || @battle.FE == :RAINBOW || @battle.FE == :FAIRYTALE || @battle.FE == :DRAGONSDEN || @battle.FE == :STARLIGHT)
    defmult=(defmult*1.5).round if self.ability == (:GRASSPELT) && (@battle.FE == :GRASSY || @battle.FE == :FOREST)        # Grassy Field
    defmult=(defmult*1.3).round if @battle.FE == :DRAGONSDEN && self.hasType?(:DRAGON)
    defmult=(defmult*1.5).round if @battle.FE == :DARKCRYSTALCAVERN && (self.hasType?(:DARK) || self.hasType?(:GHOST))
    defmult=(defmult*0.8).round if @battle.FE == :FROZENDIMENSION && self.hasType?(:FIRE)
    defmult=(defmult*1.2).round if @battle.FE == :FROZENDIMENSION && (self.hasType?(:GHOST) || self.hasType?(:ICE))
    defmult=(defmult*1.5).round if @battle.FE == :DIMENSIONAL && (self.hasType?(:GHOST))
    defmult=(defmult*1.5).round if (self.hasType?(:ICE)) && @battle.pbWeather==:HAIL && ((@battle.FE == :ICY || @battle.FE == :SNOWYMOUNTAIN))
    defmult=(defmult*2.0).round if self.ability == (:FURCOAT)
    defmult=(defmult*1.5).round if self.hasWorkingItem(:EVIOLITE) && !pbGetEvolvedFormData(self.pokemon.species,self.pokemon).nil?
    defmult=(defmult*2.0).round if self.hasWorkingItem(:METALPOWDER) && self.species == :DITTO && !self.effects[:Transform]
    defmult=(defmult*1.3).round if self.ability == (:PRISMARMOR) && (@battle.FE==:DARKCRYSTALCAVERN || @battle.FE==:RAINBOW || @battle.FE==:CRYSTALCAVERN)
    defmult=(defmult*1.5).round if self.ability == (:SHADOWSHIELD) && (@battle.FE==:STARLIGHT || @battle.FE==:NEWWORLD || @battle.FE==:DARKCRYSTALCAVERN)
    defmult=(defmult*2.0).round if self.ability == (:SHADOWSHIELD) && (@battle.FE==:DIMENSIONAL) 
    defmult=(defmult*1.3).round if self.ability == :QUARKDRIVE && self.effects[:Quarkdrive][0] == PBStats::DEFENSE
    defense=(defense*defmult*1.0/0x1000).round    
    return defense
  end    
  
  def pbCalcSpDef()
    stagemul=[2,2,2,2,2,2,2,3,4,5,6,7,8]
    stagediv=[8,7,6,5,4,3,2,2,2,2,2,2,2]    
    applysandstorm=false
    defense=@spdef
    defstage=@stages[PBStats::SPDEF]+6
    applysandstorm=true
    if @stages[PBStats::SPDEF] >= 0
      stagemulp=1+0.5*@stages[PBStats::SPDEF]
      defense=(defense*1.0*stagemulp).floor
    else        
      defense=(defense*1.0*stagemul[defstage]/stagediv[defstage]).floor
    end    
    defmult=0x1000
    if (@battle.pbWeather== :SUNNYDAY || @battle.ProgressiveFieldCheck(PBFields::FLOWERGARDEN) || @battle.FE == :BEWITCHED || 
      self.crested == :CHERRIM || self.pbPartner.crested == :CHERRIM)
      if self.ability == (:FLOWERGIFT) && self.species == :CHERRIM
        defmult=(defmult*1.5).round
      end
      if self.pbPartner.ability == (:FLOWERGIFT) && self.pbPartner.species == :CHERRIM
        defmult=(defmult*1.5).round
      end
    end  
    defense=(defense*1.5).round if @battle.pbWeather== :SANDSTORM && self.hasType?(:ROCK) && applysandstorm
    defmult=(defmult*1.5).round if @battle.FE == :MISTY  && self.hasType?(:FAIRY)
    defmult=(defmult*1.5).round if @battle.FE == :DESERT  && self.hasType?(:GROUND)
    defmult=(defmult*1.5).round if @battle.FE == :DARKCRYSTALCAVERN && (self.hasType?(:DARK) || self.hasType?(:GHOST))
    defmult=(defmult*1.3).round if @battle.FE == :DRAGONSDEN && self.hasType?(:DRAGON)
    defmult=(defmult*0.8).round if @battle.FE == :FROZENDIMENSION && self.hasType?(:FIRE)
    defmult=(defmult*1.2).round if @battle.FE == :FROZENDIMENSION && (self.hasType?(:GHOST) || self.hasType?(:ICE))
    defmult=(defmult*1.5).round if @battle.FE == :DIMENSIONAL && (self.hasType?(:GHOST))
    defmult=(defmult*1.5).round if (self.hasType?(:ICE)) && @battle.pbWeather==:HAIL && ((@battle.FE == :ICY || @battle.FE == :SNOWYMOUNTAIN))
    defmult=(defmult*1.5).round if self.hasWorkingItem(:EVIOLITE) && !pbGetEvolvedFormData(self.pokemon.species,self.pokemon).nil?
    defmult=(defmult*1.5).round if self.hasWorkingItem(:ASSAULTVEST)
    defmult=(defmult*2.0).round if self.hasWorkingItem(:DEEPSEASCALE) && self.species == :CLAMPERL 
    defmult=(defmult*2.0).round if self.hasWorkingItem(:METALPOWDER) && self.species == :DITTO && !self.effects[:Transform]
    defmult=(defmult*1.3).round if self.ability == (:PRISMARMOR) && (@battle.FE==:DARKCRYSTALCAVERN || @battle.FE==:RAINBOW || @battle.FE==:CRYSTALCAVERN)
    defmult=(defmult*1.5).round if self.ability == (:SHADOWSHIELD) && (@battle.FE==:STARLIGHT || @battle.FE==:NEWWORLD || @battle.FE==:DARKCRYSTALCAVERN)
    defmult=(defmult*2.0).round if self.ability == (:SHADOWSHIELD) && (@battle.FE==:DIMENSIONAL) 
    defmult=(defmult*1.3).round if self.ability == :QUARKDRIVE && self.effects[:Quarkdrive][0] == PBStats::SPDEF   
    defense=(defense*defmult*1.0/0x1000).round
    return defense
  end  
  
  
  def pbCalcAcc()
    accstage=self.stages[PBStats::ACCURACY]
    accuracy=(accstage>=0) ? (accstage+3)*100/3 : 300/(3-accstage)
    accuracy*=1.3 if self.ability == (:COMPOUNDEYES)
    accuracy*=1.1 if self.ability == (:VICTORYSTAR)
    partner=self.pbPartner
    accuracy*=1.1 if partner && partner.ability == (:VICTORYSTAR)
    accuracy*=1.1 if self.hasWorkingItem(:WIDELENS)
    accuracy*=0.9 if self.ability == (:LONGREACH) && (@battle.FE==:ROCKY || @battle.FE==:FOREST) 
    return accuracy.round
  end  
  
  def pbCalcEva()
    evastage=self.stages[PBStats::EVASION]
    evastage-=2 if @battle.state.effects[:Gravity]!=0
    evastage=-6 if evastage<-6
    evastage=6 if evastage>6  #>>DemICE
    evastage=0 if self.effects[:Foresight] || self.effects[:MiracleEye]
    evasion=(evastage>=0) ? (evastage+3)*100/3 : 300/(3-evastage)
    evasion*=1.2 if self.ability == (:TANGLEDFEET) && self.effects[:Confusion]>0
    evasion*=1.2 if self.ability == (:SANDVEIL) && (@battle.pbWeather==:SANDSTORM || @battle.FE == :DESERT || @battle.FE == :ASHENBEACH)
    evasion*=1.2 if self.ability == (:SNOWCLOAK) && (@battle.pbWeather==:HAIL || @battle.FE == :ICY || @battle.FE == :SNOWYMOUNTAIN)
    evasion*=1.1 if self.hasWorkingItem(:BRIGHTPOWDER)
    evasion*=1.1 if self.hasWorkingItem(:LAXINCENSE)
    return evasion.round
  end  
  
  def pbCalcCrit()     
    $buffs = 0
    if @battle.FE == :MIRROR
      $buffs = self.stages[PBStats::EVASION] if self.stages[PBStats::EVASION] > 0
      $buffs = $buffs.to_i + self.stages[PBStats::ACCURACY] if self.stages[PBStats::ACCURACY] > 0
    end   
    c=0
    c+=self.effects[:FocusEnergy]
    c+=1 if self.ability == (:SUPERLUCK) 
    c+=2 if self.hasWorkingItem(:STICK) && (self.species == :FARFETCHD || self.species == :SIRFETCHD)
    c+=2 if self.hasWorkingItem(:LUCKYPUNCH) && self.species == :CHANSEY
    c+=1 if self.hasWorkingItem(:RAZORCLAW)
    c+=1 if self.hasWorkingItem(:SCOPELENS)
    c += $buffs if @battle.FE == :MIRROR
    c=3 if c>3
    return c
  end      
  #DemICE left the chat>>>>
}


#>>>>DemICE entered the chat
def pbShowBattleStats(pkmn)
  friend=@battle.battlers[0]
  atksbl="+"  
  atksbl=" " if pkmn.stages[PBStats::ATTACK]<0
  defsbl="+"  
  defsbl=" " if pkmn.stages[PBStats::DEFENSE]<0
  spasbl="+"
  spasbl=" " if pkmn.stages[PBStats::SPATK]<0
  spdsbl="+"
  spdsbl=" " if pkmn.stages[PBStats::SPDEF]<0
  spesbl="+"
  spesbl=" " if pkmn.stages[PBStats::SPEED]<0
  accsbl="+"
  accsbl=" " if pkmn.stages[PBStats::ACCURACY]<0
  evasbl="+"
  evasbl=" " if pkmn.stages[PBStats::EVASION]<0
  c=pkmn.pbCalcCrit
  if c==0
    crit=4
  elsif c==1
    crit=12.5
  elsif c==2
    crit=50
  else 
    crit=100
  end 
  shownmon = pkmn.effects[:Illusion] ? pkmn.effects[:Illusion] : pkmn
  if (!shownmon.type2.nil?) 
    report = [_INTL("Type: {1}/{2}",toProperCase(shownmon.type1),toProperCase(shownmon.type2))]  
  else  
    report = [_INTL("Type: {1}",toProperCase(shownmon.type1))]  
  end
  report.push(_INTL("Level: {1}",pkmn.level))
  if @battle.pbOwnedByPlayer?(pkmn.index) || $DEBUG
    report.push(_INTL("Attack:               {1}   {2}{3}",pkmn.pbCalcAttack(),atksbl,pkmn.stages[PBStats::ATTACK]),
                _INTL("Defense:            {1}   {2}{3}",pkmn.pbCalcDefense(),defsbl,pkmn.stages[PBStats::DEFENSE]),
                _INTL("Sp.Attack:        {1}   {2}{3}",pkmn.pbCalcSpAtk(),spasbl,pkmn.stages[PBStats::SPATK]),
                _INTL("Sp.Defense:     {1}   {2}{3}",pkmn.pbCalcSpDef(),spdsbl,pkmn.stages[PBStats::SPDEF]),
                _INTL("Speed:                  {1}   {2}{3}",pkmn.pbSpeed(),spesbl,pkmn.stages[PBStats::SPEED]),
                _INTL("Accuracy:   {1}% {2}{3}",pkmn.pbCalcAcc(),accsbl,pkmn.stages[PBStats::ACCURACY]),
                _INTL("Evasion:       {1}% {2}{3}",pkmn.pbCalcEva(),evasbl,pkmn.stages[PBStats::EVASION]),
                _INTL("Crit. Rate:    {1}%    +{2}/3",crit,c))
  else
    report.push(_INTL("Attack:                     {1}{2}",atksbl,pkmn.stages[PBStats::ATTACK]),
                _INTL("Defense:                  {1}{2}",defsbl,pkmn.stages[PBStats::DEFENSE]),
                _INTL("Sp.Attack:              {1}{2}",spasbl,pkmn.stages[PBStats::SPATK]),
                _INTL("Sp.Defense:           {1}{2}",spdsbl,pkmn.stages[PBStats::SPDEF]),
                _INTL("Speed:                        {1}{2}",spesbl,pkmn.stages[PBStats::SPEED]),
                _INTL("Accuracy:   {1}% {2}{3}",pkmn.pbCalcAcc(),accsbl,pkmn.stages[PBStats::ACCURACY]),
                _INTL("Evasion:       {1}% {2}{3}",pkmn.pbCalcEva(),evasbl,pkmn.stages[PBStats::EVASION]),
                _INTL("Crit. Rate:    {1}%    +{2}/3",crit,c))
  end
  movememory = @battle.ai.getAIMemory(pkmn,true)
  if movememory.length > 0
    report.push(_INTL("Revealed Moves:"))
    for i in movememory
      report.push(_INTL("{1}:  {2} PP left",i.name,i.pp))
    end
  end
  dur=@battle.weatherduration
  dur="Permanent" if @battle.weatherduration<0
  turns="turns"
  turns="" if @battle.weatherduration<0
  if @battle.weather==:RAINDANCE
    weatherreport=_INTL("Weather: Rain, {1} {2}",dur,turns)
    weatherreport=_INTL("Weather: Torrential Rain, {1} {2}",dur,turns) if @battle.state.effects[:HeavyRain]
  elsif @battle.weather==:SUNNYDAY
    weatherreport=_INTL("Weather: Sun, {1} {2}",dur,turns)
    weatherreport=_INTL("Weather: Scorching Sun, {1} {2}",dur,turns) if @battle.state.effects[:HarshSunlight]
  elsif @battle.weather==:SANDSTORM
    weatherreport=_INTL("Weather: Sandstorm, {1} {2}",dur,turns)
  elsif @battle.weather==:HAIL
    weatherreport=_INTL("Weather: Hail, {1} {2}",dur,turns)
  elsif @battle.weather==:STRONGWINDS
    weatherreport=_INTL("Weather: Strong Winds, {1} {2}",dur,turns)
  elsif @battle.weather==:SHADOWSKY
    weatherreport=_INTL("Weather: Shadow Sky, {1} {2}",dur,turns)
  end
  report.push(weatherreport) if @battle.weather!=0
  report.push(_INTL("Slow Start: {1} turns",(5-pkmn.turncount))) if pkmn.ability == (:SLOWSTART) && pkmn.turncount<=5 && (pkmn == @battle.battlers[0] || pkmn == @battle.battlers[2])
  report.push(_INTL("Throat Chop: {1} turns",pkmn.effects[:ThroatChop])) if pkmn.effects[:ThroatChop]!=0
  report.push(_INTL("Unburdened")) if pkmn.unburdened && (pkmn == @battle.battlers[0] || pkmn == @battle.battlers[2]) && pkmn.ability == (:UNBURDEN)
  report.push(_INTL("Speed Swap")) if pkmn.effects[:SpeedSwap]!=0
  report.push(_INTL("Burn Up")) if pkmn.effects[:BurnUp]
  report.push(_INTL("Uproar: {1} turns",pkmn.effects[:Uproar])) if pkmn.effects[:Uproar]!=0
  report.push(_INTL("Truant")) if pkmn.effects[:Truant] && (pkmn == @battle.battlers[0] || pkmn == @battle.battlers[2]) && pkmn.ability == (:TRUANT)
  report.push(_INTL("Toxic: {1} turns",pkmn.effects[:Toxic])) if pkmn.effects[:Toxic]!=0
  report.push(_INTL("Torment")) if pkmn.effects[:Torment]
  report.push(_INTL("Miracle Eye")) if pkmn.effects[:MiracleEye]
  report.push(_INTL("Minimized")) if pkmn.effects[:Minimize]
  report.push(_INTL("Recharging")) if pkmn.effects[:HyperBeam]!=0
  report.push(_INTL("Fury Cutter: +{1}",pkmn.effects[:FuryCutter])) if pkmn.effects[:FuryCutter]!=0
  report.push(_INTL("Echoed Voice: +{1}",pkmn.effects[:EchoedVoice])) if pkmn.effects[:EchoedVoice]!=0
  report.push(_INTL("Mean Look")) if pkmn.effects[:MeanLook]>-1
  report.push(_INTL("Foresight")) if pkmn.effects[:Foresight]
  report.push(_INTL("Follow Me")) if pkmn.effects[:FollowMe]
  report.push(_INTL("Rage Powder")) if pkmn.effects[:RagePowder]
  report.push(_INTL("Flash Fire")) if pkmn.effects[:FlashFire]
  report.push(_INTL("Substitute")) if pkmn.effects[:Substitute]!=0
  report.push(_INTL("Perish Song: {1} turns",pkmn.effects[:PerishSong])) if pkmn.effects[:PerishSong]>0
  report.push(_INTL("Leech Seed")) if pkmn.effects[:LeechSeed]>-1
  report.push(_INTL("Gastro Acid")) if pkmn.effects[:GastroAcid]
  report.push(_INTL("Curse")) if pkmn.effects[:Curse]
  report.push(_INTL("Nightmare")) if pkmn.effects[:Nightmare]
  report.push(_INTL("Confused")) if pkmn.effects[:Confusion]!=0
  report.push(_INTL("Aqua Ring")) if pkmn.effects[:AquaRing]
  report.push(_INTL("Ingrain")) if pkmn.effects[:Ingrain]
  report.push(_INTL("Power Trick")) if pkmn.effects[:PowerTrick]
  report.push(_INTL("Smacked Down")) if pkmn.effects[:SmackDown]
  report.push(_INTL("Sheltered")) if pkmn.effects[:Shelter]
  report.push(_INTL("Quark Drive active")) if pkmn.effects[:Quarkdrive][0]!=0
  report.push(_INTL("Air Balloon")) if pkmn.hasWorkingItem(:AIRBALLOON)
  report.push(_INTL("Magnet Rise: {1} turns",pkmn.effects[:MagnetRise])) if pkmn.effects[:MagnetRise]!=0
  report.push(_INTL("Telekinesis: {1} turns",pkmn.effects[:Telekinesis])) if pkmn.effects[:Telekinesis]!=0
  report.push(_INTL("Heal Block: {1} turns",pkmn.effects[:HealBlock])) if pkmn.effects[:HealBlock]!=0
  report.push(_INTL("Embargo: {1} turns",pkmn.effects[:Embargo])) if pkmn.effects[:Embargo]!=0
  report.push(_INTL("Disable: {1} turns",pkmn.effects[:Disable])) if pkmn.effects[:Disable]!=0
  report.push(_INTL("Encore: {1} turns",pkmn.effects[:Encore])) if pkmn.effects[:Encore]!=0
  report.push(_INTL("Taunt: {1} turns",pkmn.effects[:Taunt])) if pkmn.effects[:Taunt]!=0
  report.push(_INTL("Infatuated with {1}",@battle.battlers[pkmn.effects[:Attract]].name)) if pkmn.effects[:Attract]>=0
  report.push(_INTL("Trick Room: {1} turns",@battle.trickroom)) if @battle.trickroom!=0
  dur=@battle.state.effects[:Gravity]
  dur="Permanent" if @battle.state.effects[:Gravity]<0
  turns="turns"
  turns="" if @battle.state.effects[:Gravity]<0
  report.push(_INTL("Gravity: {1} {2}",dur,turns)) if @battle.state.effects[:Gravity]!=0  
  report.push(_INTL("Tailwind: {1} turns",pkmn.pbOwnSide.effects[:Tailwind])) if pkmn.pbOwnSide.effects[:Tailwind]>0   
  report.push(_INTL("Reflect: {1} turns",pkmn.pbOwnSide.effects[:Reflect])) if pkmn.pbOwnSide.effects[:Reflect]>0
  report.push(_INTL("Light Screen: {1} turns",pkmn.pbOwnSide.effects[:LightScreen])) if pkmn.pbOwnSide.effects[:LightScreen]>0
  report.push(_INTL("Aurora Veil: {1} turns",pkmn.pbOwnSide.effects[:AuroraVeil])) if pkmn.pbOwnSide.effects[:AuroraVeil]>0
  report.push(_INTL("Arenite Wall: {1} turns",pkmn.pbOwnSide.effects[:AreniteWall])) if pkmn.pbOwnSide.effects[:AreniteWall]>0
  report.push(_INTL("Safeguard: {1} turns",pkmn.pbOwnSide.effects[:Safeguard])) if pkmn.pbOwnSide.effects[:Safeguard]>0
  report.push(_INTL("Lucky Chant: {1} turns",pkmn.pbOwnSide.effects[:LuckyChant])) if pkmn.pbOwnSide.effects[:LuckyChant]>0
  report.push(_INTL("Mist: {1} turns",pkmn.pbOwnSide.effects[:Mist])) if pkmn.pbOwnSide.effects[:Mist]>0 
  #report.push(_INTL("Altered Field: {1} turns",@battle.state.effects[:Terrain])) if @battle.state.effects[:Terrain]>0
  #report.push(_INTL("Messed up Field: {1} turns",@battle.state.effects[:Splintered])) if @battle.state.effects[:Splintered]>0  
  report.push(_INTL("Electric Terrain: {1} turns",@battle.state.effects[:ELECTERRAIN])) if @battle.state.effects[:ELECTERRAIN]>0  
  report.push(_INTL("Grassy Terrain: {1} turns",@battle.state.effects[:GRASSY])) if @battle.state.effects[:GRASSY]>0
  report.push(_INTL("Misty Terrain: {1} turns",@battle.state.effects[:MISTY])) if @battle.state.effects[:MISTY]>0
  report.push(_INTL("Psychic Terrain: {1} turns",@battle.state.effects[:PSYTERRAIN])) if @battle.state.effects[:PSYTERRAIN]>0
  report.push(_INTL("Rainbow: {1} turns",@battle.state.effects[:RAINBOW])) if @battle.state.effects[:RAINBOW]>0
  report.push(_INTL("Magic Room: {1} turns",@battle.state.effects[:MagicRoom])) if @battle.state.effects[:MagicRoom]>0
  report.push(_INTL("Wonder Room: {1} turns",@battle.state.effects[:WonderRoom])) if @battle.state.effects[:WonderRoom]>0
  report.push(_INTL("Water Sport: {1} turns",@battle.state.effects[:WaterSport])) if @battle.state.effects[:WaterSport]>0
  report.push(_INTL("Mud Sport: {1} turns",@battle.state.effects[:MudSport])) if @battle.state.effects[:MudSport]>0
  report.push(_INTL("Spikes: {1} layers",pkmn.pbOwnSide.effects[:Spikes])) if pkmn.pbOwnSide.effects[:Spikes]>0
  report.push(_INTL("Toxic Spikes: {1} layers",pkmn.pbOwnSide.effects[:ToxicSpikes])) if pkmn.pbOwnSide.effects[:ToxicSpikes]>0
  report.push(_INTL("Stealth Rock active")) if pkmn.pbOwnSide.effects[:StealthRock]
  report.push(_INTL("Sticky Web active")) if pkmn.pbOwnSide.effects[:StickyWeb]
  report.push()
  report.push(_INTL("Ability: {1}",pkmn.ability.nil? ? "Ability Negated" : getAbilityName(shownmon.ability)))
  report.push(_INTL("Wonder Room Stat Swap active")) if pkmn.wonderroom==true
  report.push(_INTL("Field effect: {1}", @battle.field.isFieldEffect? ? PokeBattle_Field.getFieldName(@battle.field.effect) : "No Field"))
  @participants = @battle.pbPartySingleOwner(pkmn.index).find_all {|mon| mon && !mon.isEgg? && mon.hp>0}
  report.push(_INTL("Remaining Pokemon: {1} ",@participants.length))
  Kernel.pbMessage((_INTL"Inspecting {1}:",pkmn.name),report, report.length)
end
#DemICE left the chat>>>>  

#>>>>DemICE entered the chat    
def StatInfoTarget(index)
  for i in 0...4
    if (index&1)==(i&1) && !@battle.battlers[i].isFainted? 
      return i
    end  
  end
  return -1
end 
    
def pbStatInfo(index)
  @sprites["commandwindow"].visible
  curwindow=StatInfoTarget(index)
  if curwindow==-1
    raise RuntimeError.new(_INTL("No targets somehow..."))
  end
  loop do
    pbGraphicsUpdate
    Input.update
    pbUpdateSelected(curwindow)
    if Input.trigger?(Input::C)
      pbUpdateSelected(-1)
      statstarget=@battle.battlers[curwindow]
      return statstarget
    end
    if Input.trigger?(Input::B)
      pbUpdateSelected(-1)
      return -1
    end
    if curwindow>=0
      if Input.trigger?(Input::RIGHT)
        loop do
          newcurwindow=2 if curwindow==0
          newcurwindow=0 if curwindow==3
          newcurwindow=3 if curwindow==1
          newcurwindow=1 if curwindow==2
          curwindow=newcurwindow
          break if !@battle.battlers[curwindow].isFainted?
        end
      elsif Input.trigger?(Input::DOWN)
        loop do 
          newcurwindow=2 if curwindow==0
          newcurwindow=0 if curwindow==2
          newcurwindow=2 if curwindow==1
          newcurwindow=0 if curwindow==3
          curwindow=newcurwindow
          break if !@battle.battlers[curwindow].isFainted?
        end  
      elsif Input.trigger?(Input::LEFT)
        loop do 
          newcurwindow=3 if curwindow==0
          newcurwindow=0 if curwindow==2
          newcurwindow=2 if curwindow==1
          newcurwindow=1 if curwindow==3
          curwindow=newcurwindow
          break if !@battle.battlers[curwindow].isFainted?
        end  
      elsif Input.trigger?(Input::UP)
        loop do 
          newcurwindow=3 if curwindow==0
          newcurwindow=1 if curwindow==2
          newcurwindow=3 if curwindow==1
          newcurwindow=1 if curwindow==3
          curwindow=newcurwindow
          break if !@battle.battlers[curwindow].isFainted?                          
        end
      end
    end
  end
end     

def pbStatInfoF(index)
 # pbShowWindow(FIGHTBOX)
  curwindow=StatInfoTarget(index)
  if curwindow==-1
    raise RuntimeError.new(_INTL("No targets somehow..."))
  end
  loop do
    pbGraphicsUpdate
    Input.update
    pbUpdateSelected(curwindow)
    if Input.trigger?(Input::C)
      pbUpdateSelected(-1)
      statstarget=@battle.battlers[curwindow]
      return statstarget
    end
    if Input.trigger?(Input::B)
      pbUpdateSelected(-1)
      return -1
    end
    if curwindow>=0
      if Input.trigger?(Input::RIGHT)
        loop do
          newcurwindow=2 if curwindow==0
          newcurwindow=0 if curwindow==3
          newcurwindow=3 if curwindow==1
          newcurwindow=1 if curwindow==2
          curwindow=newcurwindow
          break if !@battle.battlers[curwindow].isFainted?
        end
      elsif Input.trigger?(Input::DOWN)
        loop do 
          newcurwindow=2 if curwindow==0
          newcurwindow=0 if curwindow==2
          newcurwindow=2 if curwindow==1
          newcurwindow=0 if curwindow==3
          curwindow=newcurwindow
          break if !@battle.battlers[curwindow].isFainted?
        end  
      elsif Input.trigger?(Input::LEFT)
        loop do 
          newcurwindow=3 if curwindow==0
          newcurwindow=0 if curwindow==2
          newcurwindow=2 if curwindow==1
          newcurwindow=1 if curwindow==3
          curwindow=newcurwindow
          break if !@battle.battlers[curwindow].isFainted?
        end  
      elsif Input.trigger?(Input::UP)
        loop do 
          newcurwindow=3 if curwindow==0
          newcurwindow=1 if curwindow==2
          newcurwindow=3 if curwindow==1
          newcurwindow=1 if curwindow==3
          curwindow=newcurwindow
          break if !@battle.battlers[curwindow].isFainted?                          
        end
      end
    end
  end
end   
#DemICE left the chat>>>> 
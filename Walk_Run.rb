class Game_Player
  def fullPattern
    case self.direction
      when 2
        return self.pattern
      when 4
        return 4+self.pattern
      when 6
        return 8+self.pattern
      when 8
        return 12+self.pattern
      else
        return 0
    end
  end

  def setDefaultCharName(chname,pattern)
    return if pattern<0 || pattern>=16
    @defaultCharacterName=chname
    @direction=[2,4,6,8][pattern/4]
    @pattern=pattern%4
  end

  def pbCanRun?
    return false if $game_temp.menu_calling 
    terrain=pbGetTerrainTag
    $Settings.autorunning = 0 if $Settings.autorunning.nil?
    autorunning = $Settings.autorunning == 0 ? true : false
    if (autorunning != Input.press?(Input::A)) 
      if !pbMapInterpreterRunning? && !@move_route_forcing &&
        $PokemonGlobal.runningShoes && $PokemonGlobal &&
        !$PokemonGlobal.diving && !$PokemonGlobal.surfing && !$PokemonGlobal.lavasurfing
        !$PokemonGlobal.bicycle && terrain!=PBTerrain::TallGrass &&
        terrain!=PBTerrain::Ice && !$game_switches[:Riding_Tauros]
        return true
      end
    end
    return false
  end

  def pbIsRunning?
    return !moving? && !@move_route_forcing && pbCanRun?
  end

  def character_name
    if !@defaultCharacterName
      @defaultCharacterName=""
    end
    if @defaultCharacterName!=""
      return @defaultCharacterName
    end
    if !moving? && !@move_route_forcing 
      if $PokemonGlobal.playerID>=0 && !$PokemonGlobal.bicycle && !$PokemonGlobal.diving && !$PokemonGlobal.surfing && !$PokemonGlobal.lavasurfing
        input_dir4 = Input.dir4
        if input_dir4!=0 
          if passable?(@x,@y,input_dir4) && pbCanRun?
            # Display running character sprite
            @character_name=pbGetPlayerCharset(:run)
          else
            # Display normal character sprite 
            @character_name=pbGetPlayerCharset(:walk)
          end
        else
          # Display normal character sprite 
          @character_name=pbGetPlayerCharset(:walk)
        end
      end
    end
    return @character_name
  end

  alias update_old update

  def update
    if pbGetTerrainTag==PBTerrain::Ice
      @move_speed = 5.0
    elsif !moving? && !@move_route_forcing && $PokemonGlobal
      if $PokemonGlobal.bicycle        
        @move_speed = 6.0
      elsif $PokemonGlobal.surfing
        @move_speed = 5.0
      elsif $PokemonGlobal.lavasurfing
        @move_speed = 5.0
      elsif $game_switches[:Riding_Tauros]
        @move_speed = 5.5
      elsif pbCanRun?
        if (Kernel.pbFacingTerrainTag==PBTerrain::SandDune)
          @move_speed = 3.8
        else          
          @move_speed = 5.0
        end                
      else
        if (Kernel.pbFacingTerrainTag==PBTerrain::SandDune)
          @move_speed = 3.0
        else          
          @move_speed = 4.0
        end                
      end
    end
    update_old
  end
end
#===============================================================================
# ** Scene_iPod
# ** Created by xLeD (Scene_Jukebox)
# ** Modified by Harshboy
# ** Modified by Kurotsune
#-------------------------------------------------------------------------------
#  This class performs menu screen processing.
#===============================================================================
class Scene_Jukebox
  #-----------------------------------------------------------------------------
  # * Object Initialization
  #     menu_index : command cursor's initial position
  #-----------------------------------------------------------------------------
  def initialize(menu_index = 0)
    @menu_index = menu_index
  end
  #-----------------------------------------------------------------------------
  # * Main Processing
  #-----------------------------------------------------------------------------
  def main
 
    # Make song command window
    fadein = true
    # Makes the text window
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites["background"] = IconSprite.new(0,0)
    @sprites["background"].setBitmap("Graphics/Pictures/jukeboxbg")
    @sprites["background"].z=255
    files= []
    Dir.chdir("Audio/BGM/"){
      Dir.glob("*.mp3"){|m| files.push(m) }
       Dir.glob("*.ogg"){|f| files.push(f) }
       Dir.glob("*.mid"){|z| files.push(z) }
    }
    files.sort!
    files.push("Stop Playing")
    @choices= files 
    @sprites["header"]=Window_UnformattedTextPokemon.newWithSize(_INTL("Jukebox"),
       2,-18,128,64,@viewport)
    @sprites["header"].baseColor=Color.new(248,248,248)
    @sprites["header"].shadowColor=Color.new(0,0,0)
    @sprites["header"].windowskin=nil
    @sprites["command_window"] = Window_CommandPokemon.new(@choices,324)
    @sprites["command_window"].windowskin=nil
    @sprites["command_window"].index = @menu_index
    @sprites["command_window"].setHW_XYZ(224,324,94,92,256)
    # Execute transition
    Graphics.transition
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end
    # Prepares for transition
    Graphics.freeze
    # Disposes the windows
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  #-----------------------------------------------------------------------------
  # * Frame Update
  #-----------------------------------------------------------------------------
  def update
    # Update windows
    pbUpdateSpriteHash(@sprites)
    updateCustom
    return
  end
  #-----------------------------------------------------------------------------
  # * Frame Update (when command window is active)
  #-----------------------------------------------------------------------------
  def updateCustom
    if Input.trigger?(Input::B)
      pbPlayCancelSE()
      $scene = Scene_Pokegear.new
      return
    end
    if Input.trigger?(Input::C)
      $PokemonMap.whiteFluteUsed=false if $PokemonMap
      $PokemonMap.blackFluteUsed=false if $PokemonMap
      if !$Settings.volume
        $Settings.volume = 100.00
      end
      if @sprites["command_window"].index==@sprites["command_window"].commands.length-1
        $game_system.setDefaultBGM(nil,$Settings.volume)
        $game_system.bgm_stop
        $game_map.autoplay
      else
        $game_system.setDefaultBGM(
          @sprites["command_window"].commands[@sprites["command_window"].index],$Settings.volume
        )        
      end
    end
  end

  def update_command    #Almost certainly redundant now.
    # If B button was pressed
    if Input.trigger?(Input::B)
      pbPlayCancelSE()
      # Switch to map screen
      $scene = Scene_Pokegear.new
      return
    end
  end
end


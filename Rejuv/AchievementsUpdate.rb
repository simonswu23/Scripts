###################################
############# REQUIRED ############
###################################
Events.onMapUpdate+=proc{|sender,e|
  if !$achievementmessagequeue.nil?
    $achievementmessagequeue.each_with_index{|m,i|
      $achievementmessagequeue.delete_at(i)
      Kernel.pbMessage(m)
    }
  end
}
###################################
########### END REQUIRED ##########
###################################

###################################
############## STEPS ##############
###################################


module Run

  # Run cmd without mucking with where its output goes.
  def run(cmd) ; puts cmd ; system(cmd) ; raise "Failed with status #{$?}" if $? != 0 ; end

end

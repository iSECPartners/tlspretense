require 'termios'

# Extends IO to enable "raw" input on TTYs.
class IO
  # Enables raw character input for a TTY. It uses the ruby-termios gem to
  # disable ICANON and ECHO functionality. This means that characters will
  # become immediately available to IO#gets, IO#getchar, etc. after the user
  # presses a button, and that the characters will not be implicitly echoed to
  # the screen.
  #
  # If you call this on $stdin, you probably should ensure that you call
  # #disable_raw_chars in order to restore the previous termios state after
  # your program exits. Otherwise, you may screw up the user's terminal, and
  # they will have to call `reset`.
  def enable_raw_chars
    raise IOError, "#{self} is not a TTY." unless self.tty?
    @_oldtermios = Termios.tcgetattr(self)
    newt = @_oldtermios.dup
    newt.c_lflag &= ~Termios::ICANON
    newt.c_lflag &= ~Termios::ECHO
    Termios.tcsetattr(self, Termios::TCSANOW, newt)
  end

  # Reverts the termios state to what it was before calling #enable_raw_chars.
  def disable_raw_chars
    raise IOError, "#{self} is not a TTY." unless self.tty?
    Termios.tcsetattr(self, Termios::TCSANOW, @_oldtermios)
  end


end

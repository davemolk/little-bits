
module IoUtils
  def self.copy_to_clipboard(value, print_value=false, new_line=false)
    msg = "copied and ready to paste"
    if Gem.win_platform?
      IO.popen("clip", "w") { |f| f << value.chomp(new_line ? "" : "\n") }
      puts print_value ? "#{value} #{msg}" : msg
    else
      if system("which pbcopy > /dev/null 2>&1")
        IO.popen("pbcopy", "w") { |f| f << value.chomp(new_line ? "" : "\n") }
        puts print_value ? "#{value} #{msg}" : msg
      elsif system("which xclip > /dev/null 2>&1")
        IO.popen("xclip -selection clipboard", "w") { |f| f << value.chomp(new_line ? "" : "\n") }
        puts print_value ? "#{value} #{msg}" : msg
      else
        warn "no clipboard utility found :/"
        puts value
        exit 1
      end
    end
  end
end

module IoUtils
  def self.copy_to_clipboard(value)
    if Gem.win_platform?
      Open3.pop3('clip') do |stdin, _, _, _|
        stdin.puts value
      end
    else
      if system("which pbcopy > /dev/null 2>&1")
        IO.popen("pbcopy", "w") { |f| f << value }
        puts "copied and ready to paste"
      elsif system("which xclip > /dev/null 2>&1")
        IO.popen("xclip -selection clipboard", "w") { |f| f << value }
        puts "copied and ready to paste"
      else
        puts "no clipboard utility found :/"
        puts value
        exit 1
      end
    end
  end
end
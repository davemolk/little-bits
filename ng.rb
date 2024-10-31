#!/usr/bin/env ruby

require 'open3'

def copy_to_clipboard(cmd)
  if Gem.win_platform?
    Open3.pop3('clip') do |stdin, _, _, _|
      stdin.puts cmd
    end
  else
    if system("which pbcopy > /dev/null 2>&1")
      IO.popen("pbcopy", "w") { |f| f << cmd }
      puts "'#{cmd}' copied and ready to paste"
    elsif system("which xclip > /dev/null 2>&1")
      IO.popen("xclip -selection clipboard", "w") { |f| f << cmd }
      puts "'#{cmd}' copied and ready to paste"
    else
      puts "no clipboard utility found :/"
      exit 1
    end
  end
end


branch_name, status = Open3.capture2("git branch --show-current")
if !status.success?
  puts "bad status #{status}"
  exit 1
end

branch_name = branch_name.strip

cmd = "git push -u origin #{branch_name}"

if ARGV.empty?
  system(cmd)
else
  args = ARGV.map { |a| a.downcase }
  case args[0]
  when "-h", "--help"
    puts "use -c or --copy to copy command to clipboard. default behavior is to run command"
  when "-c", "--copy"
    copy_to_clipboard(cmd)
  end
end


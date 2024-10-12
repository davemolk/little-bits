#!/usr/bin/env ruby

require 'open3'

branch_name, status = Open3.capture2("git branch --show-current")
if !status.success?
  puts "bad status #{status}"
  exit 1
end

branch_name = branch_name.strip

cmd = "git push -u origin #{branch_name}"

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

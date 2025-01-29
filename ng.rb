#!/usr/bin/env ruby

require File.expand_path('io_utils.rb', File.dirname(__FILE__))

branch_name, status = Open3.capture2("git branch --show-current")
if !status.success?
  warns "bad status #{status}"
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
    IoUtils.copy_to_clipboard(cmd)
  end
end


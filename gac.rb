#!/usr/bin/env ruby

require 'open3'
require 'optparse'

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

def fuzzy_match(user_files, candidates)
  to_commit = user_files.each_with_object([]) do |f, obj|
    candidates.each do |c|
      if c.start_with?(f)
        obj << f
      end
    end
  end
end

def exact_match(user_files, candidates)
  to_commit = user_files.each_with_object([]) do |f, obj|
    if !candidates.include?(f)
      puts "#{f} is not a candidate for a commit"
      puts "possible candidates include: #{candidates}"
      exit 1
    else
      obj << f
    end
  end
  to_commit.join(", ")
end

options = {
  :dry => false,
  :exact => false,
}
OptionParser.new do |opts|
  opts.banner = <<~HELP
    usage:
    gac [arguments] [options]

    first argument:
      your commit message
    additional arguments:
      files to commit (leave blank for all)

    options:
    -h, --help      help me
    -d, --dry       print to stdout but don't execute
    -e, --exact     use exact matching of file names
  HELP
  opts.on("-d", "--dry", "print to stdout but don't execute") { options[:dry] = true }
  opts.on("-e", "--exact", "use exact matching of file names") { options[:exact] = true }
end.parse!

commit_msg, *user_files = ARGV.map { |a| a.downcase }
if commit_msg.nil?
  puts "need a commit message"
  exit 1
end

output = %x{git diff --name-only}
candidates = output.split("\n")

to_commit = "."

unless user_files.empty?
  if options[:exact]
    to_commit = exact_match(user_files, candidates)
  else
    to_commit = fuzzy_match(user_files, candidates)
  end
  # to_commit = add_to_commit(files, candidates, options[:exact])
end 

first_cmd = "git add #{to_commit}"
second_cmd = "git commit -m '#{commit_msg}'"
third_cmd = "git push"

if options[:dry]
  puts first_cmd
  puts second_cmd
  puts third_cmd
else
  system(first_cmd)
  system(second_cmd)
  system(third_cmd)
end

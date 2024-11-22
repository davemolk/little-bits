#!/usr/bin/env ruby

require 'open3'
require 'optparse'

def fuzzy_match(user_files, candidates)
  user_files.flat_map { |f| candidates.select { |c| c.start_with?(f) } }.join(", ")
end

def exact_match(user_files, candidates)
  unmatched = user_files.reject { |f| candidates.include?(f) }
  unless unmatched.empty?
    puts "the following are not a candidate for a commit: #{unmatched.join(', ')}"
    puts "possible candidates include: #{candidates.join(', ')}"
    exit 1
  end
  user_files.join(", ")
end

options = {
  dry: false,
  exact: false,
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

commit_msg, *user_files = ARGV
if commit_msg.nil?
  puts "need a commit message"
  exit 1
end

output, status = Open3.capture2('git diff --name-only; git ls-files --others --exclude-standard')
exit 1 unless status.success?

candidates = output.lines(chomp: true)

to_commit = "."

unless user_files.empty?
  to_commit = options[:exact] ? exact_match(user_files, candidates) : fuzzy_match(user_files, candidates)
end 

commands = [ 
  "git add #{to_commit}",
  "git commit -m '#{commit_msg}'",
  "git push"
]

if options[:dry]
  puts commands.join("\n")
else
  commands.each do |cmd| 
    puts cmd
    system(cmd) 
  end
end

#!/usr/bin/env ruby

require 'optparse'

options = {}
parser = OptionParser.new do |opts| 
  opts.banner = "usage cht [language] flags"
  opts.on("t", "--tests", "include tests in output") { options[:tests] = true }
  opts.on("l", "--lib LIB", "libraries to use", Array) { |l| options[:lib] = l }
  opts.on("s", "--subjects SUBJECTS", "areas of specialization", Array) { |s| options[:subjects] = s }
  opts.on("d", "--dump", "dump prompt to stdout") { options[:dump] = true }
  opts.on("b", "--brief", "brief (non-verbose) prompt") { options[:brief] = true }
  opts.on("i", "--idiomatic", "prompt for idiomatic refactoring") { options[:idiomatic] = true } 
  opts.on("-h", "--help", "help") { puts opts; exit }
end
parser.parse!

prompt = "you're a very smart, open, competent software engineer (staff) with decades of experience. you excel at collaboration. you should not hesitate to provide your own ideas (always justify them) and correct any mistakes you encounter.\n"

if !ARGV.empty?
  prompt += "you're an exceptional #{ARGV[0]} developer. please pay close attention to #{ARGV[0]}-specific idioms as you formulate your responses and adhere to best-practices when generating code (explain when deviations are necessary).\n "
end

if options[:subjects] && !options[:subjects].empty?
  prompt += "you have especially deep knowledge of and experience in "
  prompt += options[:subjects][0...-1].join(", ")
  prompt += ", and #{options[:subjects].last}.\n"
end

if options[:lib]
  prompt += "during our collaboration, please make sure to use the following libraries: "
  prompt += options[:lib][0...-1].join(", ")
  prompt += ", and #{options[:lib].last}. \nplease suggest any additional ones you'd like to use, but explain why and ask before including.\n"
end

if options[:tests]
  prompt += "please generate comprehensive tests for all of the code you produce. these should be generated before you produce the code. make sure any code you generate can pass these tests.\n"
end

unless options[:brief] 
  prompt += "throughout our collaboration, i want you to adhere to best-practices and industry standards. if you are unsure, ask for clarification. above all, don't make anything up -- each answer you provide should be grounded in easily proven (and provided) citations/documentation/etc.\n"

  prompt += "you should explain the purpose of each piece of code that you generate and why you've chosen to design it in this particular way.\n"
  prompt += "don't apologize for mistakes. best not to make any. we've always had very productive conversations and i'm looking forward to another one.\n"
end

if options[:idiomatic] && !ARGV.empty?
  prompt += "what's the #{ARGV[0]}-idiomatic way to write the following?\n"
end

if options[:dump]
  puts prompt
  exit 0
end

if Gem.win_platform?
  Open3.pop3('clip') do |stdin, _, _, _|
    stdin.puts prompt
  end
else
  if system("which pbcopy > /dev/null 2>&1")
    IO.popen("pbcopy", "w") { |f| f << prompt }
    puts "prompt copied and ready to paste"
  elsif system("which xclip > /dev/null 2>&1")
    IO.popen("xclip -selection clipboard", "w") { |f| f << prompt }
    puts "prompt copied and ready to paste"
  else
    puts "no clipboard utility found :/"
    exit 1
  end
end

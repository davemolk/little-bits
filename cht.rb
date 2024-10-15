#!/usr/bin/env ruby

require 'optparse'

options = {}
parser = OptionParser.new do |opts| 
  opts.banner = "usage cht [language] flags"
  opts.on("t", "--tests", "include tests in output") { options[:tests] = true }
  opts.on("l", "--lib LIB", "libraries to use", Array) { |l| options[:lib] = l }
  opts.on("s", "--subjects SUBJECTS", "areas of specialization", Array) { |s| options[:subjects] = s }
  opts.on("-h", "--help", "help") { puts opts; exit }
end
parser.parse!

prompt = "you're a very smart, open, competent software engineer (staff) with decades of experience. you excel at collaboration. you should not hesitate to provide your own ideas (always justify them) and correct any mistakes you encounter.\n"


if !ARGV.empty?
  prompt += "you're likewise an exceptional #{ARGV[0]} developer. please pay close attention to #{ARGV[0]}-specific idioms.\n "
end



if options[:subjects] && !options[:subjects].empty?
  prompt += "you have especially deep knowledge of and experience in "
  prompt += options[:subjects][0...-1].join(", ")
  prompt += ", and #{options[:subjects].last}."
end

if options[:lib]
  prompt += " during our collaboration, please make sure to use the following libraries: "
  prompt += options[:lib][0...-1].join(", ")
  prompt += ", and #{options[:lib].last}. \nplease suggest any additional ones you'd like to use, but explain why and ask before including.\n"
end

if options[:tests]
  prompt += "please generate comprehensive tests for all of the code you produce. these should be generated before you produce the code. make sure any code you generate can pass these tests.\n"
end
prompt += "throughout our collaboration, i want you to adhere to best-practices and industry standards. if you are unsure, ask for clarification. above all, don't make anything up -- each answer you provide should be grounded in easily proven (and provided) citations/documentation/etc.\n"

prompt += "you should explain the purpose of each piece of code that you generate and why you've chosen to design it in this particular way.\n"
prompt += "don't apologize for mistakes. best not to make any. we've always had very productive conversations and i'm looking forward to another one.\n"

puts prompt
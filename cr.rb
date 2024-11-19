#!/usr/bin/env ruby

require 'pathname'

def clean_cargo_in_directories(base_dir)
  curr = Pathname.new(base_dir)
  puts "current directory: #{curr}"
  dirs = Dir.glob("*").select { |f| File.directory?(f) }
  puts "found directories: #{dirs}"
  dirs.each { |d| clean_directory(curr + d) }
end

def clean_directory(directory)
  Dir.chdir(directory) do
    puts system("cargo clean")
  end
end

clean_cargo_in_directories(Dir.pwd)
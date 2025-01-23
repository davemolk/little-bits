#!/usr/bin/env ruby

require 'fileutils'
require File.expand_path('io_utils.rb', File.dirname(__FILE__))

class MVD
  DEFAULT_FILE = ".bookmarks"

  def initialize
    @file = File.join(Dir.home, DEFAULT_FILE)
    FileUtils.touch(@file) unless File.exist?(@file)
  end 

  def list
    f = File.read(@file)
    f.split("\n")
  end

  def add(bookmark)
    current = "#{bookmark}=#{Dir.pwd}"
    unless File.readlines(@file).grep(/#{Regexp.escape(current)}/).any?
      File.open(@file, 'a') { |f| f.puts current }
      puts "added #{current}"
    else
      puts "#{bookmark} already exists"
    end
  end

  def delete(bookmark)
    bookmarks = File.readlines(@file).reject { |f| f.start_with?("#{bookmark}=") }
    File.write(@file, bookmarks.join)
    puts File.read(@file)
  end

  def find(bookmark)
    found = File.readlines(@file).find { |f| f.start_with?("#{bookmark}=")}
    if found
      path = found.split("=").last.strip
      IoUtils.copy_to_clipboard(path)
    else
      puts "#{bookmark} not found"
    end
  end
end


usage = <<~HELP
    usage:
    mvd [argument] [options]

    argument:
      name of bookmark

    options:
      -l                  list bookmarks
      -a <bookmark>       add bookmark
      -d <bookmark>       delete bookmark
      -h, --help          help me
  HELP

if ARGV.empty?
  puts usage
  exit 1
end

args = ARGV
args = args.map { |a| a.downcase }

mvd = MVD.new

case args[0]
when '-h', '--help'
  puts usage
when '-l'
  p mvd.list
when '-a'
  if args[1].nil?
    puts "need a name to add"
    exit 1
  end
  mvd.add(args[1])
when '-d'
  if args[1].nil?
    puts "need a name to delete"
    exit 1
  end
  mvd.delete(args[1])
else
  mvd.find(args[0])
end

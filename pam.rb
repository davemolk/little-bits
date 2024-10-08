#!/usr/bin/env ruby

require 'json'
require 'shellwords'
require 'optparse'

class PatternManager
  DEFAULT_PATH = '.pam'

  def initialize(options)
    @options = options
    @config_path = File.join(ENV['HOME'], options[:path] || DEFAULT_PATH)
    Dir.mkdir(@config_path) unless Dir.exist?(@config_path)
  end

  def get_patterns
    patterns = Dir.glob(File.join(@config_path, '*.json')).map { |p| File.basename(p, '.json') }
    return patterns unless patterns.empty?
    raise "no json files found at #{@config_path}...check path and ensure there are .json files"
  end

  def validate_save_params(args)
    raise "need name, cmd, pattern (and optionally flags)." unless args.length.between?(3, 4)
    raise "name can't be empty." if args[0].empty?
    raise "cmd can't be empty." if args[1].empty?
    raise "pattern can't be empty." if args.length == 3 && args[2].empty?
  end

  def save(name, cmd, pattern, flags='')
    data = { name: name, cmd: cmd, flags: flags, pattern: pattern } 
    path = File.join(@config_path, "#{name}.json")
    File.write(path, JSON.generate(data))
  end

  def get_pattern(name)
    path = File.join(@config_path, "#{name}.json")
    JSON.parse(File.read(path))
  rescue Errno::ENOENT
    raise "#{name} not found"
  end

  def delete_pattern(name)
    path = File.join(@config_path, "#{name}.json")
    File.delete(path) if File.exist? path
  end
end

def main
  options = {}
  OptionParser.new do |opts|
    opts.banner = "usage: pam [options]"
    opts.on("-l", "--list", "list patterns") { options[:list] = true }
    opts.on("-s", "--save", "save pattern") { options[:save] = true }
    opts.on("-d", "--dump", "dump a pattern without running it") { options[:dump] = true}
    opts.on("-pPATH", "--path=PATH", "path to files") { |p| options[:path] = p }
    opts.on("-r", "--remove", "delete pattern") { options[:remove] = true }
  end.parse!

  pam = PatternManager.new(options)

  begin
    if options[:list]
      puts pam.get_patterns
      exit 0
    end

    if options[:remove]
      if ARGV.empty?
        puts "need a file name to delete"
        exit 
      end
      pam.delete_pattern(ARGV[0])
      puts "removed #{ARGV[0]}"
      exit 0
    end

    if options[:save]
      pam.validate_save_params(ARGV)
      name, *args = ARGV
      pam.save(name, *args)
      puts "saved #{name}"
      exit 0
    end

    if ARGV.empty?
      puts "need a pattern name and optionally one or more target directories."
      exit 1
    end

    pattern_name = ARGV[0]
    pattern = pam.get_pattern(pattern_name)

    if options[:dump]
      puts pattern['flags'].length != 0 ? "#{pattern['cmd']} #{pattern['flags']} #{pattern['pattern']}" : "#{pattern['cmd']} #{pattern['pattern']}"
      exit 0
    end

    targets = ARGV[1..] || []
    command = "#{Shellwords.escape(pattern['cmd'])} #{Shellwords.escape(pattern['flags'])} #{Shellwords.escape(pattern['pattern'])}"

    if targets.empty?    
      input = $stdin.read
      puts `echo #{Shellwords.escape(input)} | #{command}`
    else
      targets.each do |target|
        system("#{command} #{Shellwords.escape(target)}")
      end
    end
  rescue => e
    puts "error: #{e}"
    exit 1
  end
end

if __FILE__ == $0
  main
end
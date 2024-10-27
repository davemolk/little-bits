#!/usr/bin/env ruby

require 'json'
require 'shellwords'
require 'optparse'
require 'prettyprint'

class PatternManager
  DEFAULT_PATH = '.pam'

  def initialize(options)
    @options = options
    @config_path = File.join(ENV['HOME'], options[:path] || DEFAULT_PATH)
    Dir.mkdir(@config_path) unless Dir.exist?(@config_path)
  end

  def all
    Dir.chdir(@config_path)
    files = Dir.glob("*")
    files.each_with_object({}) do |file, obj|
      data = JSON.parse(File.read(file))
      obj[data["name"]] = data
    end
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

  def run_cmd(name, targets)
    pattern = get_pattern(name)

    unless pattern['flags'].start_with?("-") || pattern['flags'].nil?
      pattern['flags'] = "-#{pattern['flags']}"
    end

    if @options[:dump]
      puts pattern['flags'].length != 0 ? "#{pattern['cmd']} #{pattern['flags']} #{pattern['pattern']}" : "#{pattern['cmd']} #{pattern['pattern']}"
      exit 0
    end

    command = "#{Shellwords.escape(pattern['cmd'])}"
    if !pattern['flags'].nil?
      command += " #{Shellwords.escape(pattern['flags'])}"
    end
    if !pattern['pattern'].nil?
      command += " #{Shellwords.escape(pattern['pattern'])}"
    end

    if targets.empty?    
      input = $stdin.read
      puts `echo #{Shellwords.escape(input)} | #{command}`
    else
      targets.each do |target|
        system("#{command} #{Shellwords.escape(target)}")
      end
    end
  end

  def run(args)
    begin
      case 
      when @options[:all] 
        pp all
      when @options[:list]
        puts get_patterns
      when @options[:remove]
        if args.empty?
          puts "need a file name to delete"
          exit 1
        end
        delete_pattern(args[0])
        puts "removed #{args[0]}"  
      when @options[:save]
        validate_save_params(args)
        name, *args = args
        save(name, *args)
        puts "saved #{name}"
      else
        if args.empty?
          puts "need a pattern name and optionally one or more target directories."
          exit 1
        end
        name = args[0]
        targets = args[1..] || []
        run_cmd(name, targets)
      end
    rescue => e
      puts "error: #{e}"
      exit 1
    end
  end
end

def main
  options = {}
  OptionParser.new do |opts|
    opts.banner = "usage: pam [options]"
    opts.on("-a", "--all", "dump all patterns") { options[:all] = true }
    opts.on("-l", "--list", "list patterns") { options[:list] = true }
    opts.on("-s", "--save", "save pattern") { options[:save] = true }
    opts.on("-d", "--dump", "dump a pattern without running it") { options[:dump] = true}
    opts.on("-pPATH", "--path=PATH", "path to files") { |p| options[:path] = p }
    opts.on("-r", "--remove", "delete pattern") { options[:remove] = true }
  end.parse!

  PatternManager.new(options).run(ARGV)
end

if __FILE__ == $0
  main
end
#!/usr/bin/ev ruby

require 'yaml'
require 'json'
require 'optparse'

def parse_options
  options = {
    pretty: false,
    json: false,
  }
  OptionParser.new do |opts|
    opts.banner = "usage: convert [option]"
    opts.on("-s", "--string INPUT", "read input as a string") { |s| options[:string] = s }
    opts.on("-f", "--file FILE", "path to file") { |p| options[:path] = p }
    opts.on("-j", "--json", "yaml to json") { options[:json] = true }
    opts.on("-f", "--file FILE", "write to file") { |f| options[:file] = f }
    opts.on("-p", "--pretty", "pretty print json") { |pp| options[:pretty] = true }
  end.parse!
  options
end

def json_to_yaml(data, file)
  if file.nil? 
    puts YAML.dump(JSON.parse(data))
  else
    file = File.basename(file, File.extname(file))
    File.write("#{file}.yaml", YAML.dump(JSON.parse(data)))
  end
end

def yaml_to_json(data, file, pp)
  if file.nil?
    puts pp ? JSON.pretty_generate(YAML.load(data)) : JSON.generate(YAML.load(data))
  else
    file = File.basename(file, File.extname(file))
    File.write("#{file}.json", JSON.generate(YAML.load(data)))
  end
end

def main
  options = parse_options
  data = ''
  if options[:string]
    data = options[:string]
  elsif options[:path]
    raise 'file not found' unless File.exist?(options[:path])
    data = File.read(options[:path]) 
  else
    puts ARGF.nil?
    data = ARGF.read
  end
  options[:json] ? yaml_to_json(data, options[:file], options[:pretty]) : json_to_yaml(data, options[:file])

rescue StandardError => e
  warn "error: #{e.message}"
  exit 1
end


if __FILE__ == $PROGRAM_NAME
  main
end
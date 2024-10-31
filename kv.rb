#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'optparse'

class FileDB
  def initialize(path)
    @file_path = File.join(path, 'db.json')
    FileUtils.touch(@file_path) unless File.exist?(@file_path)
    @data = load_data
  end
  def load_data
    return {} unless File.exist?(@file_path) && !File.zero?(@file_path)
    JSON.parse(File.read(@file_path))
  rescue JSON::ParserError
    puts "error reading json, resetting db"
    {}
  end

  def save
    File.write(@file_path, JSON.pretty_generate(@data))
  end
  
  def set(key, *new_values)
    list = new_values.each_with_object([]) do |v, obj|
      obj << v
    end
    @data[key] = list
    save
  end

  def add(key, *new_values)
    @data[key] ||= []
    list = new_values.each_with_object([]) do |v, obj|
      obj << v
    end
    list.each do |value|
      @data[key] << value unless @data[key].include?(value)
    end
    save
  end

  def get(key)
    @data[key]
  end
  
  def delete(key, *values_to_delete)
    if values_to_delete.empty?
      @data.delete(key)
    else
      values_to_delete.each { |v| @data[key].delete(v) }
    end
    save
  end

  def keys
    @data.keys
  end

  def dump_data
    JSON.pretty_generate(@data)
  end

  def overview
    s = ''
    @data.each_key { |k| s << "#{k}: #{@data[k].length} items\n" }
    s
  end

  def replace(key, *new_values)
    case new_values.length
    when 1
      @data[new_values.first] = @data.delete(key)
      save
    when 2
      old_value, new_value = new_values
      @data.each do |k, v|
        v.gsub!(old_value, new_value) if v.is_a?(Array)
      end 
      save
    else
      raise ArgumentError, "expected 1 or 2 values, got #{new_values.length}"
    end
  end

  def search_all(query)
    found_keys = @data.keys.select { |k| k.include?(query) }
    found_values = @data.each_with_object([]) do |(key, values), results|
      values.each do |value|
        if value.include?(query)
          results << [key, value]
        end
      end
    end
    [found_keys, found_values]
  end
end

class KV
  DEFAULT_PATH = '.kv'.freeze

  def initialize(options)
    @path = File.join(ENV['HOME'], options[:path] || DEFAULT_PATH)
    @db = FileDB.new(@path)
  end

  def command(cmd, key='', *values)
    case cmd
    when 'get' then get(key)
    when 'set' then set(key, *values)
    when 'add' then add(key, *values)
    when 'delete' then delete(key, *values)
    when 'keys' then keys
    when 'dump' then dump
    when 'backup' then backup(key)
    when 'replace' then replace(key, *values)
    when 'find' then find(key)
    when 'help', 'h' then help
    else
      puts "unknown command: #{cmd}"
      exit 1
    end
  end
  
  def get(key)
    value = @db.get(key)
    value.nil? ? (puts 'key not found') : (puts value)
  end

  def set(key, *value)
    @db.set(key, *value)
  end
  
  def add(key, *value)
    @db.add(key, *value)
  end
  
  def delete(key, *value)
    @db.delete(key, *value)
  end
  
  def keys
    puts @db.keys
  end

  def dump
    puts @db.dump_data
  end

  def backup(path)
    File.write(path, @db.dump_data)
  end

  def overview
    puts @db.overview
  end 

  def replace(key, *value)
    @db.replace(key, *value)
  end

  def find(query)
    key_results, value_results = @db.search_all(query)
    puts "key results:              #{key_results}\n"
    puts "value results ([k, v]):   #{value_results}"
  end

  def help
    puts <<~HELP
    kv                          outputs keys with item-count
    kv get <key>                gets values for a key
    kv set <key> <value(s)>     sets the value(s) for a key
    kv add <key> <value(s)>     append values for a key
    kv delete <key> <values(s)> deletes values from a key if provided, else deletes entire key
    kv keys                     output all keys
    kv dump                     dump the database to stdout
    kv backup                   copy database to a new file
    kv replace <key> <value>    
    kv find
    kv help
    HELP
  end
end

def main
  options = {}
  OptionParser.new do |opts|
    opts.banner = <<~BANNER
    flag help (for cli help, use 'kv help')
    BANNER
    opts.on("-pPATH", "--path=PATH", "path to db") { |p| options[:path] = p }
  end.parse!

  args = ARGV
  args = args.map { |a| a.downcase }
  kv = KV.new(options)
  args.empty? ? kv.overview : kv.command(*args)
end

if __FILE__ == $0
  main
end
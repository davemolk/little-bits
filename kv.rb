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

  def load_data()
    return {} unless File.exist?(@file_path) && !File.zero?(@file_path)

    JSON.parse(File.read(@file_path))
  rescue JSON::ParserError => e
    warn "error reading json, resetting db: #{e.message}"
    {}
  end

  def save
    File.write(@file_path, JSON.pretty_generate(@data))
  rescue StandardError => e
    warn "error saving db: #{e.message}"
    false
  end
  
  def set(key, *values)
    return if key.nil? || key.empty?
    @data[key] = values
    save
  end

  def add(key, *values)
    return if key.nil? || key.empty?
    @data[key] ||= []
    @data[key] |= values
    save
  end

  def get(key)
    @data[key]
  end

  def key_exist?(key)
    @data.key?(key)
  end
  
  def delete(key, *values)
    return delete_key(key) if values.empty?
    delete_values(key, values)
  end

  def keys
    @data.keys
  end

  def dump_data
    JSON.pretty_generate(@data)
  end

  def overview
    @data.transform_values(&:length)
      .map { |key, count| "#{key}: #{count} items" }
      .join("\n")
      .concat("\n")
  end

  def replace(key, *values)
    case values.length
    when 1 then replace_key(key, values.first)
    when 2 then replace_value(key, *values)
    else
      raise ArgumentError, "expected 1 or 2 values, got #{values.length}"
    end
  end

  def search_all(query)
    return [[], []] if query.nil? || query.empty?

    [
      find_matching_keys(query),
      find_matching_values(query),
    ]
  end

  private

  def delete_key(key)
    @data.delete(key)
    save
  end

  def delete_values(key, values)
    return unless @data.key?(key)
    @data[key] -= values
    save
  end

  def replace_key(old_key, new_key)
    return unless @data.key?(old_key)
    @data[new_key] = @data.delete(old_key)
    save
  end

  def replace_value(key, old_value, new_value)
    return unless @data.key?(key)
    @data[key].map! { |v| v == old_value ? new_value : v }
    save
  end

  def find_matching_keys(query)
    @data.keys.select { |k| k.include?(query) }
  end

  def find_matching_values(query)
    @data.flat_map do |k, values|
      values.select { |v| v.include?(query) }
        .map { |v| [k, v]}
    end
  end
end

class KV
  DEFAULT_PATH = '.kv'.freeze
  COMMANDS = %w[get set add delete keys dump backup replace find help h].freeze

  def initialize(options)
    @path = File.join(ENV['HOME'], options[:path] || DEFAULT_PATH)
    @db = FileDB.new(@path)
  rescue StandardError => e
    warn "error initializing db: #{e.message}"
    exit 1
  end

  def command(cmd, key='', *values)
    return add(key, *values) if cmd == 'add'
    return delete(key, *values) if cmd == 'delete'
    return keys if cmd == 'keys'
    return dump if cmd == 'dump'
    return backup(key) if cmd == 'backup'
    return replace(key, *values) if cmd == 'replace'
    return find(key) if cmd == 'find'
    return help if cmd == 'help' || cmd == 'h'
      
    if key.empty?
      get(cmd)
    else
      set(cmd, [key, *values])
    end
  end
  
  def get(key)
    value = @db.get(key)
    puts(value.nil? ? 'key not found' : value)
  end

  def set(key, *value)
    validate_key!(key)
    @db.set(key, *value)
  end
  
  def add(key, *value)
    validate_key!(key)
    @db.add(key, *value)
  end
  
  def delete(key, *value)
    validate_key!(key)
    @db.delete(key, *value)
  end
  
  def keys
    puts @db.keys
  end

  def key_exist?(key)
    validate_key!(key)
    @db.key_exist?(key)
  end

  def dump
    puts @db.dump_data
  end

  def backup(path)
    validate_path!(path)
    File.write(path, @db.dump_data)
  rescue StandardError => e
    warn "error backing up: #{e.message}"
  end

  def overview
    puts @db.overview
  end 

  def replace(key, *value)
    validate_key!(key)
    @db.replace(key, *value)
  rescue ArgumentError => e
    warn e.message
    exit 1
  end

  def find(query)
    key_results, value_results = @db.search_all(query)
    puts "key results:              #{key_results}\n"
    puts "value results ([k, v]):   #{value_results}"
  end

  def help
    puts <<~HELP
    usage:
      kv                           list all keys with item count
      kv <key>                     gets values for a key
      kv <key> <value...>          sets value(s) for a key
      kv add <key> <value...>      append value(s) to a key
      kv delete <key> [value...]   delete key or specific values
      kv keys                      list all keys
      kv dump                      dump the database to stdout
      kv backup                    backup database to a new file
      kv replace <key> <new_key>   rename a key
      kv replace <key> <old> <new> replace value in a given key  
      kv find <query>              search keys and values
      kv help                      show this help
    HELP
  end
end

def validate_key!(key)
  raise ArgumentError, "key cannot be empty" if key.nil? || key.empty?
end

def validate_path!(path)
  raise ArgumentError, "path cannot be empty" if path.nil? || path.empty?
  raise ArgumentError, "directory doesn't exist" unless File.directory?(File.dirname(path))
end

def parse_options
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: kv [options] [command]"
    opts.on("-pPATH", "--path=PATH", "path to db") { |p| options[:path] = p }
    opts.on("-h", "--help", "show this help") { puts opts; exit }
  end.parse!
  options
end

def main
  options = parse_options
  args = ARGV.map(&:downcase)
  kv = KV.new(options)
  args.empty? ? kv.overview : kv.command(*args)
rescue StandardError => e
  warn "error: #{e.message}"
  exit 1
end

if __FILE__ == $PROGRAM_NAME
  main
end
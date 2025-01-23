#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'optparse'
require File.expand_path('io_utils.rb', File.dirname(__FILE__))
require 'date'

class FileDB
  # needs the backup duration 
  def initialize(path, disable_backups)
    @dir_path = path
    @file_path = File.join(@dir_path, 'db.json')
    @tmp_path = File.join(@dir_path, 'db.tmp')
    @auto_backup_path = File.join(@dir_path, 'auto_backup.json')
    @last_backup_path = File.join(@dir_path, 'last_backup.txt')
    FileUtils.touch(@file_path) unless File.exist?(@file_path)
    FileUtils.touch(@tmp_path) unless File.exist?(@tmp_path)
    FileUtils.touch(@last_backup_path) unless File.exist?(@last_backup_path)
    @data = load_data(@file_path)
    backup_if_necessary if !disable_backups
  end

  def backup_if_necessary
    if File.zero?(@last_backup_path)
      File.write(@last_backup_path, Time.now.to_i)
      return
    end
    last_backup = Time.at(File.read(@last_backup_path).to_i)
    # backup if more than a day has passed
    if Time.now - last_backup > 86400
      puts "performing auto-backup, stand by..."
      File.write(@auto_backup_path, dump_data)
      File.write(@last_backup_path, Time.now.to_i) 
    end
  end

  def load_data(path)
    return {} unless File.exist?(path) && !File.zero?(path)

    JSON.parse(File.read(path))
  rescue JSON::ParserError => e
    warn "reading json, resetting db: #{e.message}"
    {}
  end

  def nuke
    File.delete(@file_path) unless !File.exist?(@file_path)
    File.delete(@tmp_path) unless !File.exist?(@tmp_path)
  end
  
  def set(key, *values)
    return if key.nil? || key.empty?
    save_tmp(key)
    @data[key] = values.flatten
    save
  end

  def add(key, *values)
    return if key.nil? || key.empty?
    @data[key] ||= []
    save_tmp(key)
    @data[key] |= values.flatten
    save
  end

  def get(key, copy_to_clipboard=false)
    raise "value not found" unless !@data[key].nil?
  
    if !copy_to_clipboard
      @data[key]
    else
      IoUtils.copy_to_clipboard(@data[key].first)
    end
  end

  def delete(key, *values)
    save_tmp(key)
    return delete_key(key) if values.empty?
    delete_values(key, values)
  end

  def keys
    @data.keys
  end

  def dump_data
    JSON.pretty_generate(@data)
  end

  def backup(path)
    File.write(path, dump_data)
    puts "backup successful"
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

  def restore_from_backup(path)
    @data = load_data(path)
    save
  end

  def undo
    # would happen if set is first operation, so undo
    # file is created but empty
    if File.zero?(@tmp_path)
      key = @data.keys.first
      delete_key(key, false)
      puts "#{key} has been deleted"
    end
    # file's never big, slurp slurp slurp
    lines = File.readlines(@tmp_path)
    lines.each_with_index do |line, idx|
      line.strip!
      parts = line.split(":::")
      key_to_delete, key_to_restore, value_to_restore = '', '', ''
      case parts.length
      when 2
        key_to_restore, value_to_restore = parts
        key_to_delete = key_to_restore
      when 3
        key_to_restore, key_to_delete, value_to_restore = parts
      else
        warn "#{line} is not properly formatted, skipping"
      end
      # clear the entry so we can restore from scratch
      if idx == 0
        delete_key(key_to_delete, false)
      end
      restore(key_to_restore, value_to_restore)
    end
    File.delete(@tmp_path)
  end

  private

  def restore(key, value)
    if !@data.key?(key)
      @data[key] = [value]
    else
      @data[key].push(value)
    end
    save
  end

  def save
    File.write(@file_path, JSON.pretty_generate(@data))
  rescue StandardError => e
    warn "saving db: #{e.message}"
    false
  end

  def save_tmp(key)
    unless @data[key].nil?
      File.open(@tmp_path, 'w') do |f|
        @data[key].each do |value|
          f.puts("#{key}:::#{value}")
        end
      end
    end
  rescue StandardError => e
    warn "saving tmp: #{e.message}"
    false
  end

  def save_tmp_during_key_update(key, new_key)
    unless @data[key].nil?
      File.open(@tmp_path, 'w') do |f|
        @data[key].each do |value|
          f.puts("#{key}:::#{new_key}:::#{value}")
        end
      end
    end
  rescue StandardError => e
    warn "saving tmp during key update: #{e.message}"
    false
  end

  def delete_key(key, backup=true)
    save_tmp(key) unless !backup
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
    save_tmp_during_key_update(old_key, new_key)
    @data[new_key] = @data.delete(old_key)
    save
  end

  def replace_value(key, old_value, new_value)
    return unless @data.key?(key)
    save_tmp(key)
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
    FileUtils.mkdir_p(@path) unless Dir.exist?(@path)
    @db = FileDB.new(@path, options[:disable])
    @copy = options[:copy]
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
    return undo if cmd == 'undo'
    return nuke if cmd == 'nuke'
    return restore_from_backup(key) if cmd == 'restore'
      
    if key.empty?
      get(cmd, @copy)
    else
      set(cmd, [key, *values])
    end
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

  def dump
    puts @db.dump_data
  end

  def backup(path)
    @db.backup(path)
  rescue StandardError => e
    warn "error backing up: #{e.message}"
  end

  def replace(key, *value)
    validate_key!(key)
    @db.replace(key, *value)
  rescue ArgumentError => e
    warn e.message
    exit 1
  end

  def overview
    puts @db.overview
  end 

  def find(query)
    key_results, value_results = @db.search_all(query)
    puts "key results:              #{key_results}\n"
    puts "value results ([k, v]):   #{value_results}"
  end

  def undo
    @db.undo
  end

  def nuke
    puts "obliterating db"
    @db.nuke
  end

  def restore_from_backup(path)
    validate_path!(path)
    @db.restore_from_backup(path)
  rescue StandardError => e
    warn "error restoring from backup: #{e.message}"
  end

  def get(key, copy_to_clipboard=false)
    value = @db.get(key, copy_to_clipboard)
    puts value if !copy_to_clipboard
  rescue StandardError => e
    warn "error: #{e.message}"
    exit 1
  end

  def set(key, *value)
    validate_key!(key)
    @db.set(key, *value)
  end

  def help
    puts <<~HELP
    usage:
      kv                           list all keys with item count
      kv <key>                     gets values for a key
      kv <key> <value...>          sets value(s) for a key
      kv add <key> <value...>      append value(s) to a key
      kv delete <key> [value...]   delete key or specific values
      kv undo                      undo the previous action
      kv keys                      list all keys
      kv dump                      dump the database to stdout
      kv backup                    backup database to a new file
      kv restore <backup_path>     restore database from a backup
      kv replace <key> <new_key>   rename a key
      kv replace <key> <old> <new> replace value in a given key  
      kv find <query>              search keys and values
      kv nuke                      erase the db
      kv help                      show this help

    flags:
      -c, --copy                   copy first value to clipboard
      -d, --disable-backups        disable automatic backups (default is daily backups)                
      -p, --path                   custom path to db file
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
    opts.on("-pPATH", "--path=PATH", "path to db") { |p| options[:path] = p }
    opts.on("-h", "--help", "show this help") { puts opts; exit }
    opts.on("-c", "--copy", "copy first value to clipboard") { options[:copy] = true }
    opts.on("-d", "--disable-backups", "disable automatic backups (default is daily backups)") { options[:disable] = true }
  end.parse!
  options
end

def main
  options = parse_options
  kv = KV.new(options)
  ARGV.empty? ? kv.overview : kv.command(*ARGV)
rescue StandardError => e
  warn "error: #{e.message}"
  exit 1
end

if __FILE__ == $PROGRAM_NAME
  main
end
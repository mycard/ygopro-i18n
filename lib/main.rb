#encoding: UTF-8
require 'yaml'
require 'locale'
require 'Win32API' if RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]

if ARGV[0]
  Locale.current = ARGV[0]
end

def import(file)
  raise "file not found" unless File.file? file
  $file = "locales/#{$locale}.yml"
  $contents = YAML.load_file($file)[$locale] rescue {}
  case File.extname(file)
  when ".cdb"
    $contents["cards"] = import_ygopro_db(file)
  when ".conf"
    $contents["strings"] = import_ygopro_strings(file)
  end
  File.open($file,"w"){|file| YAML.dump({$locale => $contents}, file)}
end
def import_ygopro_db(file)
  result = {}
  require 'sqlite3'
  db = SQLite3::Database.new( file )
  db.results_as_hash = true
  db.execute( "select * from texts" ) do |row|
    number = row["id"]
    result[number] = {}
    result[number]["name"] = row["name"]
    result[number]["lore"] = row["desc"]
    1.upto(16) do |i|
      result[number]["str#{i}"] = row["str#{i}"] if row["str#{i}"] and !row["str#{i}"].empty?
    end
  end
  result
end
def import_ygopro_strings(file)
  open(file, "r:bom|utf-8") do |file|
    result = {}
    file.each_line do |line|
      next if line[0,1] != "!"
      if line =~ /^\!(\w+)\ ([[:alnum:]]+)\ (.*)$/
        type = $1
        id = $2
        string = $3
        result[type] ||= {}
        result[type][id] = string
      else
        raise line
      end
    end
    return result
  end
end
def translate
  puts "current locale: #{Locale.current}"
  locales = Locale.candidates(supported_language_tags: Dir.glob("locales/*.yml").collect{|file|File.basename(file, ".yml")})
  puts "candidates locales: #{locales.join(',')}"
  if locales.empty?
    puts "unsupported locale, supported_language_tags: #{Dir.glob("locales/*.yml").collect{|file|File.basename(file, ".yml")}.join(',')}"
    exit
  end
  locale = locales.pop.to_s
  $contents = YAML.load_file("locales/#{locale}.yml")[locale] || {} rescue {}
  merger = proc { |key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
  locales.reverse.each do |locale|
    locale = locale.to_s
    $contents.merge! YAML.load_file("locales/#{locale}.yml")[locale], &merger
  end
  puts 'translating card database...'
  translate_ygopro_db("cards.cdb")
  puts 'translating strings...'
  translate_ygopro_strings("strings.conf")
  puts 'complete'
end
def translate_ygopro_db(file)
  require 'sqlite3'
  db = SQLite3::Database.new( file )
  db.execute('begin transaction')
  old_cards = import_ygopro_db(file)
  $contents["cards"].each do |number, card|
    card = old_cards[number].merge(card) if old_cards[number]
    stmt = db.prepare( "replace into texts (id, name, desc, #{1.upto(16).collect{|i|"str#{i}"}.join(', ')}) VALUES (#{(['?']*(16+3)).join(', ')}) "  )
    strings = 1.upto(16).collect { |i| card["str#{i}"] || "" }
    stmt.execute(number, card["name"], card["lore"], strings)
  end
  db.execute('commit transaction')
end
def translate_ygopro_strings(file)
  open(file, 'w') do |file|
    $contents["strings"].each do |type, values|
      file.puts("##{type}")
      values.each do |key, value|
        file.puts("!#{type} #{key} #{value}")
      end
    end
  end
end
if ARGV[1]
  import ARGV[1]
else
  translate
end
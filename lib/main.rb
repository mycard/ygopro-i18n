#encoding: UTF-8
require 'yaml'
$locale = ARGV[0]
$file = "locales/#{$locale}.yml"
$contents = YAML.load_file($file)[$locale] rescue {}
def import(file)
  raise "file not found" unless File.file? file
  case File.extname(file)
  when ".cdb"
    import_ygopro_db(file)
  when ".conf"
    import_ygopro_strings(file)
  end
  File.open($file,"w"){|file| YAML.dump({$locale => $contents}, file)}
end
def import_ygopro_db(file)
  $contents["cards"] = {}
  require 'sqlite3'
  db = SQLite3::Database.new( file )
  db.execute( "select * from texts" ) do |row|
    print "."
    number = row.shift
    name = row.shift
    lore = row.shift
    strings = row
    strings.pop while !strings.empty? and (strings.last.nil? or strings.last.empty?)
    $contents["cards"][number] = {}
    $contents["cards"][number]["name"] = name
    $contents["cards"][number]["lore"] = lore
    $contents["cards"][number]["strings"] = strings unless strings.empty?
  end
end
def import_ygopro_strings(file)
  open(file, "r:bom|utf-8") do |file|
    $contents["strings"] = {}
    file.each_line do |line|
      print "."
      next if line[0,1] != "!"
      if line =~ /^\!(\w+)\ ([[:alnum:]]+)\ (.*)$/
        type = $1
        id = $2
        string = $3
        $contents["strings"][type] ||= {}
        $contents["strings"][type][id] = string
      else
        raise line
      end
    end
  end
end
def translate
  translate_ygopro_db("cards.cdb")
  translate_ygopro_strings("strings.conf")
end
def translate_ygopro_db(file)
  require 'sqlite3'
  db = SQLite3::Database.new( file )
  db.execute('begin transaction')
  $contents["cards"].each do |number, card|
    card["strings"] = [""] unless card["strings"]
    card["strings"].each do |str|
      str.replace str.encode("UTF-16LE")[0,29].encode("UTF-8") if str
    end
    stmt = db.prepare( "replace into texts (id, name, desc, #{1.upto(16).collect{|i|"str#{i}"}.join(', ')}) VALUES (#{(['?']*(16+3)).join(', ')}) "  )
    stmt.execute(number, card["name"], card["lore"], *card["strings"])
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
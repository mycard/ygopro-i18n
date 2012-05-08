ygopro-i18n
===========

usage:
put this program into ygopro directory
import locale:
ygopro-i18n <locale> /path/to/cards.cdb
ygopro-i18n <locale> /path/to/strings.conf
switch locale:
ygopro-i18n <locale>

build:
requirements:
ruby
ruby-sqlite3
ocra
command:
ocra lib/main.rb
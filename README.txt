ygopro-i18n
===========

usage:
put this program into ygopro directory
run this program directly without any argument to switch ygopro to system language
import locale:
ygopro-i18n <locale> path/to/cards.cdb
ygopro-i18n <locale> path/to/strings.conf
switch to a specified locale:
ygopro-i18n <locale>
example: ygopro-i18n ja-JP

build:
requirements:
ruby
ruby-sqlite3
ocra
command:
ocra lib/main.rb
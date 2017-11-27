# vuls-to-redmine
### vuls-log-converter を導入

vulslogconverter https://github.com/usiusi360/vuls-log-converter でcsv に変換

$ vulslogconverter -i /vuls/results/current -o /vuls/results/current/output.csv -t csv

### vuls-to-redmine を導入

````
$ git clone https://github.com/nakacya/vuls-to-redmine
````

````
Config::Tiny
Text::CSV_XS
LWP::UserAgent
JSON
の perl module を追加
````

param.conf を随時修正

````
$ vi param.conf
[API]
key=redmine_api_key
project_id=1
tracker_id=1
assigned_to_id=5
status_id=1
path=csv_path
files=output.csv
server=http://your_redmine_URL/
````

変換した csv を vuls-to-redmine.pl にて実行
````
$ ./vuls-to-redmine.pl -c param.conf
````

PS:vuls -diff の結果を csv に出力して使ったほうが使いやすいかと思われ

# vuls-to-redmine

vulslogconverter https://github.com/usiusi360/vuls-log-converter でcsv に変換

$ vulslogconverter -i /vuls/results/current -o /vuls/results/current/output.csv -t csv

変換した csv を vuls-to-redmine.pl にて実行
$ ./vuls-to-redmine.pl -c param.conf

param.conf はこんな感じ

[API]
key=redmine_api_key
project_id=1
tracker_id=1
assigned_to_id=5
status_id=1
path=csv_path
files=output.csv
server=http://your_redmine_URL/

vuls -diff の結果を csv に出力して使ったほうが使いやすいかと思われ

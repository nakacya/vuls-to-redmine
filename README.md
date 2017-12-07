# vuls-to-redmine
### vuls-log-converter を導入

vulslogconverter https://github.com/usiusi360/vuls-log-converter でcsv に変換する

### json-to-diff を導入
````
$ git clone https://github.com/nakacya/vuls-to-redmine
````

````
Text::CSV_XS
File::Sort
の perl module を追加
````

json-to-diff.confを随時修正
````
[API]
oldpath=/tmp/old
oldfiles=csvdata.csv
newpath=/tmp/new
newfiles=csvdata.csv
path=/tmp/new
files=output.csv
````

### vuls-log-converter を実行
````
$ cd /tmp/old
$ vulslogconverter -i /tmp/old -o /tmp/old/csvdata.csv -t csv
$ cd /tmp/new
$ vulslogconverter -i /tmp/new -o /tmp/new/csvdata.csv -t csv
````

### json-to-diff.pl を実行
````
$ ./json-to-diff.pl -c json-to-diff.conf
````
### vuls-to-redmine を導入

````
$ git clone https://github.com/nakacya/vuls-to-redmine
````

````
Config::Tiny
Text::CSV_XS
LWP::UserAgent
File::Sort
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
cvss=1
method=2
notfix=3
````
### Redmine へカスタムフィールドを追加
````
CVSS=小数
DetectionMethod=リスト(OvalMatch/ChangelogExactMatch)
NotFixedYet=リスト(true/false)
を作成する
````

変換した csv を vuls-to-redmine.pl にて実行
````
$ ./vuls-to-redmine.pl -c param.conf
````

PS:こんな感じかな？
````
#!/bin/sh
VULS_HOME="/opt/vuls"
VULS_LOG="${VULS_HOME}/results"
cd /tmp
rm -rf /tmp/old /tmp/new
mkdir /tmp/old /tmp/new
result_old = `ls -rtd ${VULS_LOG}/* | grep -v current | tail -1`
ls $result_old/*.json | grep  -v "_diff.json" | xargs -I{} cp {} /tmp/old
ls $VULS_LOG/current/*.json | grep  -v "_diff.json" | xargs -I{} cp {} /tmp/new
/usr/bin/vulslogconv -i /tmp/old -o /tmp/old/csvdata.csv -t csv 
/usr/bin/vulslogconv -i /tmp/new -o /tmp/new/csvdata.csv -t csv
/opt/vuls/json-to-diff.pl -c /opt/vuls/json-to-diff_api.conf
/opt/vuls/vuls-to-redmine.pl -c /opt/vuls/vuls-to-redmine_api.conf
rm -rf /tmp/old /tmp/new
````

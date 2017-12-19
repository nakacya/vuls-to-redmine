# vuls-to-redmine
### vuls-log-converter を導入

vulslogconverter https://github.com/usiusi360/vuls-log-converter でcsv に変換する


### json-to-diff を導入
````
$ git clone https://github.com/nakacya/vuls-to-redmine
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
json-to-diff.pl は「全件マッチ」を行っている為非常に時間が掛かります。

＃1CPUだと10000レコードで20分位掛かります

### vuls-to-redmine を導入

````
$ git clone https://github.com/nakacya/vuls-to-redmine
````
perl module の追加
````
Config::Tiny
Text::CSV_XS
LWP::UserAgent
Crypt::SSLeay
JSON
Time::HiRes
````
の perl module を追加

param.conf を随時修正

````
$ vi param.conf
[API]
key=redmine_api_key               #Redmine のアクセスキー
project_id=1                      #Redmine の project_id
tracker_id=1                      #Redmine の tracker_id
assigned_to_id=5                  #Redmine の assigned_to_id
status_id=1                       #Redmine の status_id
closed_status_id=5                #Redmine への Close Ticket status_id
path=csv_path                     #json-to-diff.plの出力先path
files=output.csv                  #json-to-diff.pl の出力ファイル
server=http://your_redmine_URL/   #Redmine の URL
cvss=1                            #Redmine の cvssフィールドID
method=2                          #Redmine の methodフィールドID
notfix=3                          #Redmine の notfixフィールドID
ssl_fail=0                        #Redmine サイトのSSL証明書の有効性チェック(0=無視)
````
### Redmine へカスタムフィールドを追加
````
CVSS=小数
DetectionMethod=リスト(OvalMatch/ChangelogExactMatch/CpeNameMatch)
NotFixedYet=リスト(true/false/Unknown)
を作成する
````

json-to-diff.pl で差分取得した csv を vuls-to-redmine.pl にて実行
````
$ ./vuls-to-redmine.pl -c param.conf
````

### 使い方
１：初回時

初回だけは手動で以下のようなスクリプトを実行
````
#!/bin/sh
VULS_HOME="/opt/vuls"
VULS_LOG="${VULS_HOME}/results"
cd /tmp
rm -rf /tmp/old /tmp/new
mkdir /tmp/old /tmp/new
touch /tmp/old/output.csv
ls $VULS_LOG/current/*.json | grep  -v "_diff.json" | xargs -I{} cp {} /tmp/new
/usr/bin/vulslogconv -i /tmp/new -o /tmp/new/csvdata.csv -t csv
/opt/vuls/json-to-diff.pl -c /opt/vuls/json-to-diff_api.conf
/opt/vuls/vuls-to-redmine.pl -c /opt/vuls/vuls-to-redmine_api.conf
````
自分の意図とするredmineへの登録が正常に行われることを確認したら２：へ

２：二回目以降

vuls scan及びreport を実行の後に以下のようなスクリプトを実行
````
#!/bin/sh
VULS_HOME="/opt/vuls"
VULS_LOG="${VULS_HOME}/results"
cd /tmp
rm -rf /tmp/old /tmp/new
mkdir /tmp/old /tmp/new
result_old = `find ${VULS_LOG} -maxdepth 1 -type d |sort -nr | head -2 | tail -1`
ls $result_old/*.json | grep  -v "_diff.json" | xargs -I{} cp {} /tmp/old
ls $VULS_LOG/current/*.json | grep  -v "_diff.json" | xargs -I{} cp {} /tmp/new
/usr/bin/vulslogconv -i /tmp/old -o /tmp/old/csvdata.csv -t csv 
/usr/bin/vulslogconv -i /tmp/new -o /tmp/new/csvdata.csv -t csv
/opt/vuls/json-to-diff.pl -c /opt/vuls/json-to-diff_api.conf
/opt/vuls/vuls-to-redmine.pl -c /opt/vuls/vuls-to-redmine_api.conf
rm -rf /tmp/old /tmp/new
````

### 判明している問題点
・redmineのチケットを手動でクローズ

・yum update で脆弱性対応

・json-to-diff.pl 及び vuls-to-redmine.pl を実行

・[[CLOSE!!]]の終了チケットが追加される

または

・yum update後のデータを用いて vuls-to-redmine.pl を 複数回実行

・[[CLOSE!]]の終了チケットが追加される

~~これは「クローズされたチケットの内容を確認しないと言う仕様」に基づくものですのでご了承ください。~~

クローズされたチケットも確認するようにしてみた（実験中

これで「ホスト名・パッケージ名・バージョン」を件名にしてCVSS/CWEはnoteとして一纏めに出来るはず？

#! /bin/bash
# #######################
# 미디어위키 백업 스크립트 
# Version : 1.0.1
# 
# 이 스크립트 설명
# /LocalSettings.php, /images/*, 데이터베이스 를 하나의 파일에 백업합니다. 
# 암호 를 지정해서 압축합니다.
# #######################
cd "$(dirname "$0")"


# ###### 구문 시작 ########
for i in {1..5}
do
echo 
done
echo ==============================
echo ★ Mediawiki Backup Script ★
echo ==============================
for i in {1..29}
do
sleep 0.1
echo -n ▷
done
echo ▷


# ###### 설정 사항 ########
configfile='backup-mediawiki-config'
if [ -f ${configfile} ]; then
    echo "Reading user config...." >&2

    # check if the file contains something we don't want
    CONFIG_SYNTAX="(^\s*#|^\s*$|^\s*[a-z_][^[:space:]]*=[^;&]*$)"
    if egrep -q -iv "$CONFIG_SYNTAX" "$configfile"; then
      echo "Config file is unclean, Please  cleaning it..." >&2
      exit 1
    fi
    # now source it, either the original or the filtered variant
    source "$configfile"
else
    echo "There is no configuration file call ${configfile}"
    exit 1
fi


# checking config value
if [ -z "$config_dir" ]; then
  echo $config_dir
  echo '설정이 잘못되었습니다. 백업을 수행하지 못했습니다.'
  exit 1
fi


# backup database [mysql]
if [ -n "$config_db_user" ]
then 
  filename_dbdump="temp-dbdump-$(date +'%Y%m%d').sql"
  cmd_mysqldump="mysqldump --user=${config_db_user} --password=${config_db_password} ${config_db_database} > $filename_dbdump"

  # 임시생성된 DB백업 파일 지우는 커맨드
  cmd_remove_dbdump="rm ./$filename_dbdump"
fi

# 압축할 파일명 (파일명 + 날짜)
if [ "$config_zip_suffix" == "ymd" ];then 
  filename="${config_zip_filename}-$(date +'%Y%m%d')"
elif [ "$config_zip_suffix" == "ym" ];then
  filename="${config_zip_filename}-$(date +'%Y%m')"
else
  filename="${config_zip_filename}"
fi

# 파일 압축 tar.gz 으로 압축 
cmd_targz="tar -czf ${filename}.tar.gz -C $config_dir LocalSettings.php images"

# 암호 압축. zip 으로 최종 압축.
cmd_passzip_mv="mv -f ./${filename}.tar.zip ./${config_zip_filename}-old.tar.zip"

cmd_passzip="zip -P $config_zip_password ${filename}.tar.zip ./${filename}.tar.gz ./$filename_dbdump"

cmd_remove_targz="rm ./${filename}.tar.gz"


echo "기존 압축파일이 있을 시 ${config_zip_filename}_old.tar.zip 으로 백업합니다."
eval $cmd_passzip_mv


# 커맨드 실행
echo '데이터베이스 백업을 진행합니다...'
# echo "Command Debug DBDump[ $cmd_mysqldump ]"
eval $cmd_mysqldump

echo '파일 백업을 진행합니다...'
cmd_total="$cmd_targz && $cmd_passzip && $cmd_remove_targz && $cmd_remove_dbdump"
echo "Command Debug [ ${cmd_total} ]"
eval "$cmd_total"


# eval "$cmd_remove_targz && $cmd_remove_dbdump"

echo ''
echo '다음의 백업파일이 성공적으로 생성되었습니다.'
echo "★ 백업시간 : $(date +'%Y%m%d %r')"
echo "★ 파일명 : ${filename}.tar.gz.zip"

for i in {1..5}
do
echo 
done

exit 0
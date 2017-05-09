#! /bin/bash
# #######################
# 파일 백업. 압축해서 하나의 파일로 저장.
# 1) 해야하는 파일 백업
#     /LocalSettings.php
#     /images/*
# 2) 데이터베이스 백업
# #######################
cd "$(dirname "$0")"



# ###### 설정 사항 ########
configfile='backup_mediawiki_config'
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




# ###### 구문 시작 ########
for i in {1..30}
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

if [ -z "$config_dir" ]; then
  echo $config_dir
  echo '설정이 잘못되었습니다. 백업을 수행하지 못했습니다.'
  exit 1
fi

# 데이터베이스 백업
if [ -n "$config_db_user" ]
then 
  filename_dbdump="temp-dbdump-$(date +'%Y%m%d').sql"
  cmd_mysqldump="mysqldump --user=${config_db_user} --password=${config_db_password} ${config_db_database} > $filename_dbdump"

  # 임시생성된 DB백업 파일 지우는 커맨드
  cmd_remove_dbdump="rm ./$filename_dbdump"
fi

# 압축할 파일명 (파일명 + 날짜)
filename="${config_zip_filename}-$(date +'%Y%m%d')"

# 파일 압축 tar.gz 으로 압축 
cmd_targz="tar -czvf ${filename}.tar.gz -C $config_dir LocalSettings.php images"

# 암호 압축. zip 으로 최종 압축.
cmd_passzip="zip -P $config_zip_password -0 ${filename}.tar.gz.zip ${filename}.tar.gz $filename_dbdump"

cmd_remove_targz="rm ./${filename}.tar.gz"

# 커맨드 실행
echo '데이터베이스 백업을 진행합니다.'
echo "Command Debug DBDump[ $cmd_mysqldump ]"
eval $cmd_mysqldump

echo '파일 백업을 진행합니다.'
cmd_total="$cmd_targz && $cmd_passzip && $cmd_remove_targz && $cmd_remove_dbdump"
echo "Command Debug [ ${cmd_total} ]"
eval "$cmd_total"


# eval "$cmd_remove_targz && $cmd_remove_dbdump"

echo '다음의 백업파일이 생성되었습니다.'
echo "${filename}.tar.gz.zip"

for i in {1..10}
do
echo 
done

exit 0
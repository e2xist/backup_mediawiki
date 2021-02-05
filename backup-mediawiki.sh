#! /bin/bash
# #######################
# 미디어위키 백업 스크립트 
# Version : 1.0.1
# 
# 이 스크립트 설명
# images 폴더, 데이터베이스 를 압축백업합니다.
# 암호 를 지정해서 압축합니다.
# #######################
cd "$(dirname "$0")"
CFG_IS_DEBUG=false

# ###### 구문 시작 ########
echo 
echo ==============================
echo ★ 미디어위키 백업 스크립트 ★
echo ==============================

# ###### 설정 사항 ########
configfile='backup-mediawiki-config'
# 분기에 따라 다른 설정파일 지정 (기본적으로는 사용 안 함)
#context=$1
#if [ $# = 0 ];then
#  echo "인수가 잘못 되었습니다(0). 백업 작업이 중지되었습니다."
#  exit 1
#fi
#if [ "$context" == "wiki1" ];then 
#  configfile='./configs/wiki1-config'
#elif [ "$context" == "wiki2" ];then
#  configfile='./configs/wiki2-config'
#else
#  echo "인수가 잘못 되었습니다. 백업 작업이 중지되었습니다."
#  exit 1
#fi


# 설정 파일 확인 및 로드
if [ -f ${configfile} ]; then
    echo "설정 파일을 읽는 중..." >&2

    # check if the file contains something we don't want
    CONFIG_SYNTAX="(^\s*#|^\s*$|^\s*[A-Z_][^[:space:]]*=[^;&]*$)"
    if egrep -q -iv "$CONFIG_SYNTAX" "$configfile"; then
      echo "설정 파일이 잘못되었습니다..." >&2
      exit 1
    fi
    # 이상이 없을 때 설정 파일을 로드.
    source "$configfile"
else
    echo "설정 파일 [${configfile}]을 찾을 수 없습니다. 백업 작업이 중지되었습니다."
    exit 1
fi


# 설정을 읽어왔는지 점검.
if [ -z "${CFG_IMAGES_PATH}" ]; then
  echo '설정 내용이 잘못되었습니다. 백업 작업이 중지되었습니다.'
  exit 1
fi


# 데이터베이스 백업 스크립트
if [ -n "$CFG_DB_USER" ]
then 
  db_dump_fname="temp-dbdump-$(date +'%Y%m%d').sql"
  cmd_mysqldump="mysqldump --user=${CFG_DB_USER} --password='${CFG_DB_PASSWORD}' ${CFG_DB_NAME} > ${db_dump_fname}"

  # 임시생성된 DB백업 파일 지우는 커맨드
  cmd_remove_dbdump="rm ./${db_dump_fname}"
fi

# 압축할 파일명 (파일명 + 날짜)
if [ "$CFG_ZIP_SUFFIX" == "ymd" ];then 
  filename="${CFG_ZIP_PREFIX}-$(date +'%Y%m%d')"
elif [ "$CFG_ZIP_SUFFIX" == "ym" ];then
  filename="${CFG_ZIP_PREFIX}-$(date +'%Y%m')"
else
  filename="${CFG_ZIP_PREFIX}"
fi

images_dump_fname="images"

# wiki설정 파일 과 images 폴더를 압축하는 커맨드
cmd_targz="tar -czf ${images_dump_fname}.tar.gz -C $CFG_IMAGES_PATH ."

# 전에 백업했던 파일은 -old.tar.zip 으로 이동시키는 커맨드
cmd_mv_legacy_backup="mv -f ./${filename}.tar.zip ./${CFG_ZIP_PREFIX}-old.tar.zip"

# 최종 압축 파일을 생성하는 커맨드. 암호도 설정.
cmd_passzip="zip -P $CFG_ZIP_PASSWORD ${filename}.tar.zip ./${images_dump_fname}.tar.gz ./${db_dump_fname}"

# 임시로 생겼던 파일을 제거하는 커맨드.
cmd_remove_targz="rm ./${images_dump_fname}.tar.gz"



# ########################################
# 본격적인 구문 시작점
cd "$CFG_OUTPUT_PATH"

# Step 1. 기존 압축파일 이름변경.
echo "이전 백업 파일은 ${CFG_ZIP_PREFIX}-old.tar.zip 으로 이동되었습니다."
eval $cmd_mv_legacy_backup


# Step 2. 데이터베이스 백업 파일 생성
echo '데이터베이스 백업을 진행합니다...'
if [ "$CFG_IS_DEBUG" = true ] ; then
  echo "DB백업 커맨드[ $cmd_mysqldump ]"
fi
eval $cmd_mysqldump

# Step 3. 압축 파일(tar.gz) 생성 및 암호 압축 파일(.zip) 생성 및 임시 파일 삭제
echo '파일 백업을 진행합니다...'
cmd_total="$cmd_targz && $cmd_passzip && $cmd_remove_targz && $cmd_remove_dbdump"
if [ "$CFG_IS_DEBUG" = true ] ; then
echo "백업 커맨드 [ ${cmd_total} ]"
fi
eval "$cmd_total"


# eval "$cmd_remove_targz && $cmd_remove_dbdump"

echo ''
echo '백업이 완료되었습니다.'
echo "★ 백업 시간 : $(date +'%Y%m%d %r')"
echo "★ 백업 파일 : ${filename}.tar.gz.zip"
echo ''
echo ''

exit 0
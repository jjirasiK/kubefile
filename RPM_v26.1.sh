#!/bin/sh

HOSTNAME=`hostname`

LANG=C
export LANG

SVersion=26.4
SLast_update=2026.02.15

#_터미널 초기화
clear

function perm {
	ls -l $1 | awk '{
    k = 0
    s = 0
    for( i = 0; i <= 8; i++ )
    {
        k += ( ( substr( $1, i+2, 1 ) ~ /[rwxst]/ ) * 2 ^( 8 - i ) )
    }
    j = 4
    for( i = 4; i <= 10; i += 3 )
    {
        s += ( ( substr( $1, i, 1 ) ~ /[stST]/ ) * j )
        j/=2
    }
    if ( k )
    {
        printf( "%0o%0o ", s, k )
    } else
        {
                printf ( "0000 " )
        }

    print
	}'
}
#egrep 명령어 확인
if grep -E --version >/dev/null 2>&1; then
    GREP_CMD="grep -E"
elif command -v egrep >/dev/null 2>&1; then
    GREP_CMD="egrep"
fi


#netstat 명령어 확인
if command -v netstat >/dev/null 2>&1; then
	NETSTAT_CMD="netstat"
else
	NETSTAT_CMD="ss"
fi

#stat 명령어 확인
if stat -c %a /etc/passwd >/dev/null 2>&1; then
    STAT_CMD="stat -c %a"    # 일반적인 리눅스 (CentOS, Ubuntu 등)
elif stat -f %p /etc/passwd >/dev/null 2>&1; then
    STAT_CMD="stat -f %Lp"   # BSD 계열/macOS
else
    STAT_CMD="$STAT_CMD"    # 기본값 설정
fi

# 소유자용
if stat -c %U /etc/passwd >/dev/null 2>&1; then
    STAT_USER="stat -c %U"    # Linux
else
    STAT_USER="stat -f %Su"   # BSD/macOS
fi

# IP 주소 확인
ipadd=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
[ -z "$ipadd" ] && ipadd=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$ipadd" ] && ipadd=$(ip addr 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)
[ -z "$ipadd" ] && ipadd=$(ifconfig 2>/dev/null | grep 'inet ' | awk '{print $2}' | grep -v '^127' | head -n1)
[ -z "$ipadd" ] && ipadd="Unknown"


echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#################################  Preprocessing...  #####################################"
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

# FTP 서비스 동작확인
find /etc/ -name "proftpd.conf" | grep "/etc/"                                                     > proftpd.txt
find /etc/ -name "vsftpd.conf" | grep "/etc/"                                                      > vsftpd.txt
profile=`cat proftpd.txt`
vsfile=`cat vsftpd.txt`


############################### APACHE Check Process Start ##################################

#0. 필요한 함수 선언

apache_awk() {
	if [ `ps -ef | grep -i $1 | grep -v "ns-httpd" | grep -v "grep" | awk '{print $8}' | grep "/" | grep -v "httpd.conf" | uniq | wc -l` -gt 0 ]
	then
		apaflag=8
	elif [ `ps -ef | grep -i $1 | grep -v "ns-httpd" | grep -v "grep" | awk '{print $9}' | grep "/" | grep -v "httpd.conf" | uniq | wc -l` -gt 0 ]
	then
		apaflag=9
	fi
}


# 1. 아파치 프로세스 구동 여부 확인 및 아파치 TYPE 판단, awk 컬럼 확인

if [ `ps -ef | grep -i "httpd" | grep -v "ns-httpd" | grep -v "lighttpd" | grep -v "grep" | wc -l` -gt 0 ]
then
	apache_type="httpd"
	apache_awk $apache_type

elif [ `ps -ef | grep -i "apache2" | grep -v "ns-httpd" | grep -v "lighttpd" | grep -v "grep" | wc -l` -gt 0 ]
then
	apache_type="apache2"
	apache_awk $apache_type
else
	apache_type="null"
	apaflag=0	
fi

# 2. 아파치 홈 디렉토리 경로 확인

if [ $apaflag -ne 0 ]
then

	if [ `ps -ef | grep -i $apache_type | grep -v "ns-httpd" | grep -v "grep" | awk -v apaflag2=$apaflag '{print $apaflag2}' | grep "/" | grep -v "httpd.conf" | uniq | wc -l` -gt 0 ]
	then
		APROC1=`ps -ef | grep -i $apache_type | grep -v "ns-httpd" | grep -v "grep" | awk -v apaflag2=$apaflag '{print $apaflag2}' | grep "/" | grep -v "httpd.conf" | uniq`
		APROC=`echo $APROC1 | awk '{print $1}'`
		$APROC -V > APROC.txt 2>&1
				
		ACCTL=`echo $APROC | sed "s/$apache_type$/apachectl/"`
		$ACCTL -V > ACCTL.txt 2>&1
				
		if [ `cat APROC.txt | grep -i "root" | wc -l` -gt 0 ]
		then
			AHOME=`cat APROC.txt | grep -i "root" | awk -F"\"" '{print $2}'`
			ACFILE=`cat APROC.txt | grep -i "server_config_file" | awk -F"\"" '{print $2}'`
		else
			AHOME=`cat ACCTL.txt | grep -i "root" | awk -F"\"" '{print $2}'`
			ACFILE=`cat ACCTL.txt | grep -i "server_config_file" | awk -F"\"" '{print $2}'`
		fi
	fi
	
	if [ -f $AHOME/$ACFILE ]
	then
		ACONF=$AHOME/$ACFILE
	else
		ACONF=$ACFILE
	fi	
fi
clear

rm -rf ACCTL.txt APROC.txt


echo " " > $HOSTNAME.linux.result.txt 2>&1

echo "***************************************************************************************"
echo "***************************************************************************************"
echo "*                                                                                     *"
echo "*  Linux Security Checklist version $SVersion                                         *"
echo "*                                                                                     *"
echo "***************************************************************************************"
echo "***************************************************************************************"

echo "=======================================================================================" >> $HOSTNAME.linux.result.txt 2>&1
echo "■■■■■■■■■■■■■■■■■■■             Linux Security Check           	 ■■■■■■■■■■■■■■■■■■■■" >> $HOSTNAME.linux.result.txt 2>&1
echo "■■■■■■■■■■■■■■■■■■■      Copyright ⓒ 2026, innosecurity Co. Ltd.    ■■■■■■■■■■■■■■■■■■■■" >> $HOSTNAME.linux.result.txt 2>&1
echo "■■■■■■■■■■■■■■■■■■■     Ver $SVersion // Last update $SLast_update ■■■■■■■■■■■■■■■■■■■■" >> $HOSTNAME.linux.result.txt 2>&1
echo "=======================================================================================" >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "  ※  Launching Time: `date`"                                                            >> $HOSTNAME.linux.result.txt 2>&1
echo "  ※  Result File: $HOSTNAME.linux.result.txt"                                           >> $HOSTNAME.linux.result.txt 2>&1
echo "  ※  Hostname: `hostname`"                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo "  ※  IP Adress: $ipadd"                                                             	   >> $HOSTNAME.linux.result.txt 2>&1
echo "  ※  OS Version: $(cat /etc/redhat-release)"                                            >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "*************************************** START *****************************************"
echo "*************************************** START *****************************************" >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "###########################        1. 계정 관리        ################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################               root 계정 원격 접속 제한               ##################"
echo "##################           [U-01] root 계정 원격 접속 제한            ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준1: /etc/securetty 파일에 pts/* 설정이 있으면 무조건 취약"                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준2: /etc/securetty 파일에 pts/* 설정이 없거나 주석처리가 되어 있고,"                                   >> $HOSTNAME.linux.result.txt 2>&1
echo "■       /etc/pam.d/login에서 auth required /lib/security/pam_securetty.so 라인에 주석(#)이 없으면 양호"  >> $HOSTNAME.linux.result.txt 2>&1
echo "■       /etc/ssh/sshd_config에서 PermitRootLogin 주석(#) 처리와 설정여부(No,Yes) 확인"                  >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="telnet" {print $1 "   " $2}' | grep "tcp"                  >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 서비스 포트 활성화 여부 확인"                                                         >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
port=$(awk '$1=="telnet" && $2 ~ /tcp/ {split($2, a, "/"); print a[1]}' /etc/services)

# systemctl 명령이 있는지 확인
if command -v systemctl >/dev/null 2>&1; then
    if [ "$(systemctl status telnet.socket 2>/dev/null | grep -c listening)" -gt 0 ]; then
        if [ "$($NETSTAT_CMD -nat 2>/dev/null | grep ":$port " | grep -ic "^tcp")" -gt 0 ]; then
            $NETSTAT_CMD -nat | grep ":$port " | grep -i "^tcp" >> $HOSTNAME.linux.result.txt 2>&1 2>&1
        else
            echo " - Telnet 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1 2>&1
        fi
    else
        echo " - Telnet 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1 2>&1
    fi
else
    # systemctl 명령이 없을 때: 포트 리스닝 여부로 판단
    if $NETSTAT_CMD -nat 2>/dev/null | grep -q ":$port "; then
        $NETSTAT_CMD -nat | grep ":$port " | grep -i "^tcp" >> $HOSTNAME.linux.result.txt 2>&1 2>&1
    elif ss -ltn 2>/dev/null | grep -q ":$port"; then
        ss -ltn | grep ":$port">> $HOSTNAME.linux.result.txt 2>&1 2>&1
    elif ps -ef | grep -v grep | grep -qi telnetd; then
        echo " - Telnet 프로세스가 실행 중입니다. (ps 기반 확인)" >> $HOSTNAME.linux.result.txt 2>&1 2>&1
        ps -ef | grep -i telnetd >> $HOSTNAME.linux.result.txt 2>&1 2>&1
    else
        echo " - Telnet 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1 2>&1
    fi
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/securetty 파일 설정"                                                             >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/securetty ]
then
	if [ `cat /etc/securetty | grep "pts" | wc -l` -gt 0 ]
	then
		cat /etc/securetty | grep "pts"                                                              >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/securetty 파일에 pts/0~pts/x 설정이 없습니다."                                    >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/securetty 파일이 없습니다."                                              >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/pam.d/login 파일 설정"                                                           >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/pam.d/login | grep "pam_securetty.so" | grep -v "#" | wc -l` -gt 0 ]                                                 >> $HOSTNAME.linux.result.txt 2>&1
then
	cat /etc/pam.d/login | grep "pam_securetty.so"                                           >> $HOSTNAME.linux.result.txt 2>&1
else
	echo " - /etc/pam.d/login 파일에 pam_securetty.so 모듈 설정이 적용되어 있지 않습니다."           >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

if [ -f /etc/ssh/sshd_config ]
then
	echo "☞ PermitRootLogin 설정 확인(sshd_config)"                                                             >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	cat /etc/ssh/sshd_config | $GREP_CMD -i "^#?PermitRootLogin"                                              >> $HOSTNAME.linux.result.txt 2>&1
	echo " " 							>> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ UsePAM 설정 확인(sshd_config)"                                                             >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	cat /etc/ssh/sshd_config | $GREP_CMD -i "^#?UsePAM"                                              >> $HOSTNAME.linux.result.txt 2>&1
	echo " " 							>> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ PasswordAuthentication 설정 확인(sshd_config)"                                                             >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	cat /etc/ssh/sshd_config | $GREP_CMD -i "^#?PasswordAuthentication"                               >> $HOSTNAME.linux.result.txt 2>&1
else
	echo "☞ sshd_config 파일 설정"  >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------"  >> $HOSTNAME.linux.result.txt 2>&1
	echo " - /etc/ssh/sshd_config 파일이 없습니다."                                                          >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                 비밀번호 관리정책 설정                ##################"
echo "##################             [U-02] 비밀번호 관리정책 설정             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: root 계정을 포함한 사용자 계정의 비밀번호를 영문, 숫자, 특수문자를 포함하여 최소 8자리 이상,"  >> $HOSTNAME.linux.result.txt 2>&1
echo "■      최소 사용 기간 1일, 최대 사용 기간 90일, 최근 비밀번호 기억 4회 이상으로 설정한 경우 양호"  	>> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/login.defs 파일 설정"																		>> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/login.defs ]
then
	if [ `grep -v '^ *#' /etc/login.defs | $GREP_CMD "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN" | wc -l` -eq 0 ]
	then
		echo " - /etc/login.defs 파일에 패스워드 설정이 없습니다."                     >> $HOSTNAME.linux.result.txt 2>&1
	else
		grep -v '^ *#' /etc/login.defs | $GREP_CMD -i "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN" >> $HOSTNAME.linux.result.txt 2>&1		
	fi
else
	echo " - /etc/login.defs 파일이 없습니다."                                                      >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/security/pwquality.conf 파일 설정"											>> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/security/pwquality.conf ]
then
  if [ `cat /etc/security/pwquality.conf | $GREP_CMD "lcredit|ucredit|dcredit|ocredit|minlen|minclass|enforce" | wc -l` -gt 0 ]
  then
    cat /etc/security/pwquality.conf | $GREP_CMD "lcredit|ucredit|dcredit|ocredit|minlen|minclass|enforce"   >> $HOSTNAME.linux.result.txt 2>&1
  else
    echo " - /etc/security/pwquality.conf 파일에 패스워드 설정이 없습니다."                     >> $HOSTNAME.linux.result.txt 2>&1
  fi
else
  echo " - /etc/security/pwquality.conf 파일이 없습니다."                                                          >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/security/pwhistory.conf 파일 설정"                                                             >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/security/pwhistory.conf ]
then
	if [ `$GREP_CMD -v '^ *#' /etc/security/pwhistory.conf | $GREP_CMD -i "enforce_for_root|remember|file" | wc -l` -eq 0 ]
	then
		echo " - /etc/security/pwhistory.conf 파일에 패스워드 설정이 없습니다."                     >> $HOSTNAME.linux.result.txt 2>&1
	else
		$GREP_CMD -v '^ *#' /etc/security/pwhistory.conf | $GREP_CMD -i "remember|file|enforce"  >> $HOSTNAME.linux.result.txt 2>&1		
	fi
else
	echo " - /etc/security/pwhistory.conf 파일이 없습니다."                                                      >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " " 																							                >> $HOSTNAME.linux.result.txt 2>&1                                                                                
echo "☞ system-auth 파일 설정"															                        >> $HOSTNAME.linux.result.txt 2>&1                                                                                
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/pam.d/system-auth ]
then
	if [ `cat /etc/pam.d/system-auth | $GREP_CMD "pam_pwquality.so|pam_cracklib.so|pam_pwhistory.so" | wc -l` -eq 0 ]
	then
		echo " - /etc/pam.d/system-auth 파일에 패스워드 설정이 없습니다."                     >> $HOSTNAME.linux.result.txt 2>&1
	else
		cat /etc/pam.d/system-auth | $GREP_CMD "pam_pwquality.so|pam_cracklib.so|pam_pwhistory.so"  >> $HOSTNAME.linux.result.txt 2>&1		
	fi
else
	echo " - /etc/pam.d/system-auth 파일이 없습니다."                                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
	
echo " " 																							                >> $HOSTNAME.linux.result.txt                                                                               
echo "☞ password-auth 파일 설정"															                        >> $HOSTNAME.linux.result.txt 2>&1                                                                                
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/pam.d/password-auth ]
then
	if [ `cat /etc/pam.d/password-auth | $GREP_CMD "pam_pwquality.so|pam_cracklib.so|pam_pwhistory.so" | wc -l` -eq 0 ]
	then
		echo " - /etc/pam.d/password-auth 파일에 패스워드 설정이 없습니다."                     >> $HOSTNAME.linux.result.txt 2>&1
	else
		cat /etc/pam.d/password-auth | $GREP_CMD "pam_pwquality.so|pam_cracklib.so|pam_pwhistory.so"  >> $HOSTNAME.linux.result.txt 2>&1		
	fi
else
	echo " - /etc/pam.d/password-auth 파일이 없습니다."                                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "  >> $HOSTNAME.linux.result.txt 2>&1                                                                                                          
echo "[END.]"                                                                                        >> $HOSTNAME.linux.result.txt 2>&1
echo " "  >> $HOSTNAME.linux.result.txt 2>&1
echo "[참고]"                                                                               >> $HOSTNAME.linux.result.txt 2>&1
echo "1. systemauth-auth 파일 적용대상: 콘솔 로그인, su 명령어"                                                            >> $HOSTNAME.linux.result.txt 2>&1
echo "2. password-auth 파일 적용대상: SSHD,VSFTPD,x-window 등 과 같은 원격접속"                                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "3. Centos7 버전에서 pam_pwquality.so 모듈과 pam_cracklib.so 모듈을 지원하고 있으므로 사용 가능"                                    >> $HOSTNAME.linux.result.txt 2>&1
echo "4. pwqulity.conf 파일의 경우 주석처리가 되어 있더라도 기본값 적용이며 기본값인 경우 취약 (최소 8자리, 사전검사, 기본패스워드 유사함 검사)"     >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                 계정 잠금 임계값 설정                ##################"
echo "##################             [U-03] 계정 잠금 임계값 설정             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 계정 잠금 임계값이 10회 이하의 값으로 설정되어 있는 경우 양호"                                      >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ system-auth 파일 설정" 	                                                                        >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1							  
if [ -f /etc/pam.d/system-auth ]
then
	if [ `cat /etc/pam.d/system-auth | $GREP_CMD "pam_tally.so|pam_tally2.so|pam_faillock.so" | wc -l` -eq 0 ]
	then
		echo " - system-auth 파일에 계정 잠금 임계값 모듈이 적용되어 있지 않습니다."  >> $HOSTNAME.linux.result.txt 2>&1 
	else
		cat /etc/pam.d/system-auth | $GREP_CMD "pam_tally.so|pam_tally2.so|pam_faillock.so" >> $HOSTNAME.linux.result.txt 2>&1 
	fi
else
	echo " - /etc/pam.d/system-auth 파일이 없습니다."						>> $HOSTNAME.linux.result.txt 2>&1	
fi
echo " " 						                                                                        >> $HOSTNAME.linux.result.txt 2>&1									  
echo "☞ password-auth 파일 설정" 	                                                                        >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1	
if [ -f /etc/pam.d/password-auth ]
then
	if [ `cat /etc/pam.d/password-auth | $GREP_CMD "pam_tally.so|pam_tally2.so|pam_faillock.so" | wc -l` -eq 0 ]
	then
		echo " - password-auth 파일에 계정 잠금 임계값 모듈이 적용되어 있지 않습니다."  >> $HOSTNAME.linux.result.txt 2>&1 
	else
		cat /etc/pam.d/password-auth | $GREP_CMD "pam_tally.so|pam_tally2.so|pam_faillock.so" >> $HOSTNAME.linux.result.txt 2>&1 
	fi
else
	echo " - /etc/pam.d/password-auth 파일이 없습니다."						>> $HOSTNAME.linux.result.txt 2>&1	
fi
echo " " 						                                                                        >> $HOSTNAME.linux.result.txt 2>&1	

echo "☞ /etc/security/faillock.conf 파일 설정" 	                                                                        >> $HOSTNAME.linux.result.txt 2>&1	
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1	
if [ -f /etc/security/faillock.conf ] 
then
	if [ `cat /etc/security/faillock.conf | $GREP_CMD "silent|deny|unlock" | $GREP_CMD -v "^#|^$" | wc -l` -eq 0 ]
	then
		echo " - /etc/security/faillock.conf 파일에 계정 잠금 임계값 설정이 없습니다."  >> $HOSTNAME.linux.result.txt 2>&1 
	else
		cat /etc/security/faillock.conf | $GREP_CMD "silent|deny|unlock|fail_interval" | $GREP_CMD -v "^#|^$"  >> $HOSTNAME.linux.result.txt 2>&1 
	fi	
else
	echo " - /etc/security/faillock.conf 파일이 없습니다."					 >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "   >> $HOSTNAME.linux.result.txt 2>&1
echo "[참고]"                                                                                        >> $HOSTNAME.linux.result.txt 2>&1
echo "1. 위 명령어 결과 내역 없을 경우 정책 설정되지 않음"                                                >> $HOSTNAME.linux.result.txt 2>&1
echo "2. x86(32비트)는 pam_tally.so 모듈, x86_64(64비트)는 pam_tally2.so 모듈 설정확인"                         >> $HOSTNAME.linux.result.txt 2>&1
echo "3. tally|tall2 모듈은 위치에 따라 작동되는 방식이 달라지므로 확인 필요"                         >> $HOSTNAME.linux.result.txt 2>&1
echo "4. Centos8 이상부터 pam_faillock.so 모듈을 Default 사용하므로 확인"                         >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                   패스워드 파일 보호                 ##################"
echo "##################               [U-04] 패스워드 파일 보호              ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 쉐도우 패스워드를 사용하거나, 패스워드를 암호화하여  저장하는 경우 양호"                  >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/shadow 파일 확인"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1	
if [ -f /etc/shadow ]
then
	echo " - /etc/shadow 파일이 존재합니다."                         >> $HOSTNAME.linux.result.txt 2>&1
else
	echo " - /etc/shadow 파일이 없습니다."                                                       >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "   >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/passwd 파일 확인"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1	
if [ -f /etc/passwd ]
then
	if [ `awk -F: '$2=="x"' /etc/passwd | wc -l` -eq 0 ]
	then
		echo " - /etc/passwd 파일에 패스워드가 암호화되어 있지 않습니다."                         >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/passwd 파일에 패스워드가 암호화되어 있습니다."                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "   >> $HOSTNAME.linux.result.txt 2>&1
		echo "[/etc/passwd 정보]" >> $HOSTNAME.linux.result.txt 2>&1
		awk -F: 'BEGIN {print "USER:PASS:UID:GID:GECOS:HOME:SHELL"; print "----:----:---:---:-----:----:-----"} $2=="x"' /etc/passwd | column -t -s ":"        >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/passwd 파일이 없습니다."                                                       >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "   >> $HOSTNAME.linux.result.txt 2>&1
echo "[참고]"                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "1. shadow 파일 유무와 /etc/passwd 파일의 두 번째 필드가 \"X\" 표시되는지 확인"                           >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################              root 이외의 UID가 '0' 금지             ##################"
echo "##################          [U-05] root 이외의 UID가 '0' 금지          ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준:  root 계정과 동일한 UID를 갖는 계정이 존재하지 않는 경우 양호"                           >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ passwd 파일 UID 확인"															       >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/passwd ]
then
	uid0_count=`awk -F: '($3 == "0") {print $1}' /etc/passwd | grep -v "root" | wc -l`
	if [ $uid0_count -gt 0 ]
	then
		echo "  ● root 이외에 UID가 '0'인 계정이 존재합니다."                         >> $HOSTNAME.linux.result.txt 2>&1
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
		echo "  [UID '0' 계정 목록" >> $HOSTNAME.linux.result.txt 2>&1
		awk -F: '($3 == "0") {print $1}' /etc/passwd | grep -v "root" | sed 's/^/* /'   >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - root 이외에 UID가 '0'인 계정이 없습니다."                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " " >> $HOSTNAME.linux.result.txt 2>&1
		echo "[UID '0' 계정 목록]" >> $HOSTNAME.linux.result.txt 2>&1
		awk -F: '($3 == "0") {print $1}' /etc/passwd | sed 's/^/* /'  >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/passwd 파일이 없습니다."                                                       >> $HOSTNAME.linux.result.txt 2>&1
fi	
echo " "   >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "   >> $HOSTNAME.linux.result.txt 2>&1
echo "[참고]"                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "1. root 이외 계정이 나오는지 확인"                                                                >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                  root 계정 su 제한                  ##################"
echo "##################              [U-06] root 계정 su 제한               ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: su 명령어를 특정 그룹에 속한 사용자만 사용하도록 제한되어 있는 경우 양호"                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "■ ※ 일반사용자 계정 없이 root 계정만 사용하는 경우 su 명령어 사용제한 불필요"                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ wheel 그룹 확인" 								                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/group ]
then
	if [ `cat /etc/group | grep wheel | wc -l` -gt 0 ]
	then
		cat /etc/group | grep wheel                         >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/group 내 wheel 그룹이 없습니다."                              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/group 파일이 없습니다."                                                       >> $HOSTNAME.linux.result.txt 2>&1
fi		 
echo " " 								                                                  >> $HOSTNAME.linux.result.txt 2>&1															                                                                         
echo "☞ pam.d/su 파일" 				                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1

if [ -f /etc/pam.d/su ]
then
	if [ `cat /etc/pam.d/su | $GREP_CMD -i "pam_rootok.so|pam_wheel.so" | grep -v '#' | wc -l` -gt 0 ]
	then
		cat /etc/pam.d/su | $GREP_CMD -i "pam_rootok.so|pam_wheel.so" | grep -v '#'                         >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/pam.d/su 파일에 pam_wheel.so 설정이 없습니다."                              >> $HOSTNAME.linux.result.txt 2>&1	
	fi
	# 2. 권한 확인 섹션 추가
    echo " " >> $HOSTNAME.linux.result.txt 2>&1
    echo "☞ pam.d/su 파일 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    ls -l /etc/pam.d/su >> $HOSTNAME.linux.result.txt 2>&1
else
	echo " - /etc/pam.d/su 파일이 없습니다."                                                       >> $HOSTNAME.linux.result.txt 2>&1
fi		 
echo " " 								                                                  >> $HOSTNAME.linux.result.txt 2>&1
													                                                                         
REAL_SU=$(command -v su 2>/dev/null)
echo "☞ su 파일 권한 확인(※ 실행되는 su의 실제 위치 : $REAL_SU)" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if [ -n "$REAL_SU" ] && [ -f "$REAL_SU" ]
then
    PERM=$($STAT_CMD "$REAL_SU" 2>/dev/null)
    LS_RESULT=$(ls -al "$REAL_SU" 2>/dev/null)
    echo "($PERM) $LS_RESULT" >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - su 명령어를 찾을 수 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[참고]"                                                                                    >> $HOSTNAME.linux.result.txt 2>&1
echo "1. pam_rootok.so : root 사용자는 기본적으로 접근이 가능하며" >> $HOSTNAME.linux.result.txt 2>&1
echo "                   root사용자가 su명령으로 일반사용자로 전환해도 패스워드를 묻지 않는다"       >> $HOSTNAME.linux.result.txt 2>&1            
echo "2. su 명령 파일의 권한이 [-rwsr-x--- : 4750] 인지 확인"                                           >> $HOSTNAME.linux.result.txt 2>&1
echo "3. auth       required   pam_wheel.so 로 설정되어 있으면 wheel 그룹만 사용 가능"                         >> $HOSTNAME.linux.result.txt 2>&1
echo "4. auth       required   pam_wheel.so deny group=nosu 로 설정되어 있으면 특정 그룹 차단" 	                 >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                  불필요한 계정 제거                 ###################"
echo "##################              [U-07] 불필요한 계정 제거              ###################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 불필요한 계정이 존재하지 않는 경우 양호"							                           >> $HOSTNAME.linux.result.txt 2>&1
echo "■ ※ /etc/passwd 파일 내용을 참고하여 불필요한 계정 식별 (인터뷰 필요)"               >> $HOSTNAME.linux.result.txt 2>&1
echo "■ ※ 시스템 계정 및 솔루션 계정에 대해 nologin/false 적용 시 서비스 이상이 있을 수 있으므로 확인 후 권고"               >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 로그인 가능 계정 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
printf "%-13s  %-13s  %-20s\n" " 계정" "    | 암호 변경일" "    | 마지막 로그인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1

loginuser=$(cat /etc/passwd | $GREP_CMD -iv "nologin|false|shutdown|sync|halt" | cut -d: -f1)

for user in $loginuser; do
    SHADOW_LINE=$(grep -m1 "^${user}:" /etc/shadow)
    HASH=$(echo "$SHADOW_LINE" | cut -d: -f2)
    DAYS=$(echo "$SHADOW_LINE" | cut -d: -f3)
	
	if [[ -z "$HASH" || "$HASH" == "!"* || "$HASH" == "*"* ]]; then
        PASS_DATE="Unset"
    else
		if [ -z "$DAYS" ] || [ "$DAYS" -le 1 ]; then
			PASS_DATE="Unknown"
		else
			PASS_DATE=$(date -d "1970-01-01 + $DAYS days" "+%Y-%m-%d" 2>/dev/null)
			[ -z "$PASS_DATE" ] && PASS_DATE="Unknown"
		fi		
	fi
	
    LOGIN_INFO=$(lastlog -u "$user" | tail -n 1)
    
    if [[ "$LOGIN_INFO" == *"**Never logged in**"* ]]; then
        LAST_LOGIN="Never"
    else
        RAW_DATE=$(echo "$LOGIN_INFO" | awk '{for(i=4;i<=NF;i++) printf $i" "; print ""}')
        LAST_LOGIN=$(date -d "$RAW_DATE" "+%Y-%m-%d" 2>/dev/null)
        
        if [ -z "$LAST_LOGIN" ]; then LAST_LOGIN="Unknown"; fi
    fi

    printf "%-15s | %-15s | %-20s\n" "$user" "$PASS_DATE" "$LAST_LOGIN" >> $HOSTNAME.linux.result.txt 2>&1
done
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1  

echo "☞ /etc/passwd 파일 확인"                          							                         >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
    cat /etc/passwd                                                                            >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                             	 >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################            관리자 그룹에 최소한의 계정 포함            ##################"
echo "##################        [U-08] 관리자 그룹에 최소한의 계정 포함         ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 관리자 계정이 포함된 그룹에 불필요한 계정이 존재하지 않는 경우 양호"             >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 관리자 계정"                                                                          >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/passwd ]
then
  awk -F: '$3==0 { print $1 " -> UID=" $3 }' /etc/passwd                                       >> $HOSTNAME.linux.result.txt 2>&1
else
  echo " - /etc/passwd 파일이 없습니다."                                                          >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 관리자 계정이 포함된 그룹 확인"                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
for passwd_group in `awk -F: '$3==0 { print $1}' /etc/passwd`
do
	cat /etc/group | grep $passwd_group                                                >> $HOSTNAME.linux.result.txt 2>&1
done
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################             계정이 존재하지 않는 GID 금지             ##################"
echo "##################         [U-09] 계정이 존재하지 않는 GID 금지          ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 구성원이 존재하지 않는 빈 그룹이 발견되지 않을 경우 양호"                        >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 구성원이 존재하지 않는 그룹"                                                          >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1

for user_gid in `awk -F: '$4==null {print $3}' /etc/group`
do
	if [ `grep -c $user_gid /etc/passwd` -eq 0 ]
	then
		grep $user_gid /etc/group                                                                       > nullgid.txt
	fi		
done

if [ -f nullgid.txt ]
then
	if [ `cat nullgid.txt | wc -l` -eq 0 ]
	then
		echo " - 구성원이 존재하지 않는 그룹이 발견되지 않습니다."                                  >> $HOSTNAME.linux.result.txt 2>&1
	else
		cat nullgid.txt                                                                            >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - 구성원이 존재하지 않는 그룹이 발견되지 않습니다."                                  >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

rm -rf nullgid.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                   동일한 UID 금지                   ##################"
echo "##################                [U-10] 동일한 UID 금지               ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 동일한 UID로 설정된 계정이 존재하지 않을 경우 양호"                              >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 동일한 UID를 사용하는 계정 "                                                          >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       > total-equaluid.txt
for user_uid in `cat /etc/passwd | awk -F: '{print $3}'`
do
	cat /etc/passwd | awk -F: '$3=="'${user_uid}'" { print "UID=" $3 " -> " $1 }'                     > equaluid.txt
	if [ `cat equaluid.txt | wc -l` -gt 1 ]
	then
		cat equaluid.txt                                                                           >> total-equaluid.txt
	fi
done
if [ `sort -k 1 total-equaluid.txt | wc -l` -gt 1 ]
then
	sort -k 1 total-equaluid.txt | uniq -d                                                       >> $HOSTNAME.linux.result.txt 2>&1
else
	echo " - 동일한 UID를 사용하는 계정이 발견되지 않습니다."                                     >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

rm -rf equaluid.txt
rm -rf total-equaluid.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                  사용자 Shell 점검                  ##################"
echo "##################              [U-11] 사용자 Shell 점검               ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 로그인이 필요하지 않은 계정에 /bin/false(/sbin/nologin) 쉘이 부여되어있는 경우 양호" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 로그인이 필요하지 않은 시스템 계정 확인"                                              >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/passwd ]
  then
    cat /etc/passwd | $GREP_CMD "^daemon|^bin|^sys|^adm|^listen|^nobody|^nobody4|^noaccess|^diag|^listen|^operator|^games|^gopher" | grep -v "admin" > temp114.txt
    if [ -s temp114.txt ]
    then
      cat temp114.txt 																	      >> $HOSTNAME.linux.result.txt 2>&1
    else
      echo " - 해당 시스템 계정이 발견되지 않습니다."                                        >> $HOSTNAME.linux.result.txt 2>&1
    fi
   	  else
    echo " - /etc/passwd 파일이 없습니다."                                                        >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

rm -rf temp114.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                Session Timeout 설정                ##################"
echo "##################            [U-12] Session Timeout 설정             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: /etc/profile 에서 TMOUT=600 또는 /etc/csh.login 에서 autologout=10으로 설정되어 있으면 양호" >> $HOSTNAME.linux.result.txt 2>&1
echo "■       (1) sh, ksh, bash 쉘의 경우 /etc/profile 파일 설정을 적용받음"                 >> $HOSTNAME.linux.result.txt 2>&1
echo "■       (2) csh, tcsh 쉘의 경우 /etc/csh.cshrc 또는 /etc/csh.login 파일 설정을 적용받음" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 현재 로그인 계정 TMOUT"                                                               >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `set | $GREP_CMD -i "TMOUT|autologout" | wc -l` -gt 0 ]
then
	set | $GREP_CMD -i "TMOUT|autologout"                                                            >> $HOSTNAME.linux.result.txt 2>&1
else
	echo " - TMOUT이 설정되어 있지 않습니다."                                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/profile 내 TMOUT 설정 확인(Shell 레벨)"                                                                      >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/profile ]
then
  if [ `cat /etc/profile | grep -i TMOUT | wc -l` -gt 0 ]
  then
  	cat /etc/profile | grep -i TMOUT                                            >> $HOSTNAME.linux.result.txt 2>&1
  else
  	echo " - /etc/profile 파일에 TMOUT 설정이 없습니다."                                                    >> $HOSTNAME.linux.result.txt 2>&1
  fi
else
  echo " - /etc/profile 파일이 없습니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/ssh/sshd_config 내 TMOUT 설정 확인(Network 레벨)"                                                                      >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/ssh/sshd_config ]
then
  if [ `cat /etc/ssh/sshd_config | grep -i Client | wc -l` -gt 0 ]
  then
  	cat /etc/ssh/sshd_config | grep -i Client                                           >> $HOSTNAME.linux.result.txt 2>&1
  else
  	echo " - /etc/ssh/sshd_config 파일에 ClientAlive 설정이 없습니다."                                                    >> $HOSTNAME.linux.result.txt 2>&1
  fi
else
  echo " - /etc/ssh/sshd_config 파일이 없습니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[sshd_config 참고]"                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "1. ClientAliveInterval : Client가 살아있는지 확인하는 간격 (기본값 0은 계속 연결을 의미)"            >> $HOSTNAME.linux.result.txt 2>&1
echo "2. ClientAliveCountMax : Client가 응답이 없어도 접속 유지하는 횟수"                            >> $HOSTNAME.linux.result.txt 2>&1
echo "3. ClientAliveInterval * ClientAliveCountMax 두 수를 곱한 시간후(초단위) 세션종료 "            >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################        안전한 패스워드 암호화 알고리즘 사용 설정        ##################"
echo "##################    [U-13] 안전한 패스워드 암호화 알고리즘 사용 설정     ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: SHA-2 이상의 안전한 비밀번호 암호화 알고리즘을 사용하는 경우 양호"                      >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/passwd 파일 확인"                                                                    >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/passwd ]
then
	if [ `awk -F: '$2=="x"' /etc/passwd | wc -l` -eq 0 ]
	then
		echo " - /etc/passwd 파일에 패스워드가 암호화되어 있지 않습니다."                         >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/passwd 파일에 패스워드가 암호화되어 있습니다."                              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/passwd 파일이 없습니다."                                                       >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/login.defs 파일 확인"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/login.defs ]
then
	if [ `grep -i "ENCRYPT_METHOD" /etc/login.defs| grep -v "^#" | wc -l` -gt 0 ]
	then
		grep -i "ENCRYPT_METHOD" /etc/login.defs| grep -v "^#"                   >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/login.defs 파일에 ENCRYPT_METHOD 설정이 없습니다."                              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/login.defs 파일이 없습니다."                                                   >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[참고]"                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "1. 보안 수준에 따라 [MD5 < SHA-256 < SHA-512 < YESCRYPT] 로 강력함"            >> $HOSTNAME.linux.result.txt 2>&1
echo "2. YESCRYPT는 SHA-512 대비 메모리 점유 기반 설계를 통해 무차별 대입 공격 저항성이 높은 알고리즘"                            >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#########################    2. 파일 및 디렉토리 관리    ##############################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################        root 홈, 패스 디렉터리 권한 및 패스 설정        ##################"
echo "##################    [U-14] root 홈, 패스 디렉토리 권한 및 패스 설정     ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: PATH 환경변수에 "." 이 맨 앞이나 중간에 포함되지 않은 경우 양호"                >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ PATH 설정 확인"                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
echo $PATH                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################              파일 및 디렉터리 소유자 설정             ##################"
echo "##################          [U-15] 파일 및 디렉토리 소유자 설정          ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 소유자가 존재하지 않은 파일 및 디렉터리가 존재하지 않을 경우 양호"               >> $HOSTNAME.linux.result.txt 2>&1
echo "■ ※ 실제 소유자명이 숫자(UID)처럼 보일 수 있으므로 담당자 확인 필수"		               >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 소유자가 존재하지 않는 파일 (소유자 => 파일위치: 경로)"                               >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
find / \( -nouser -o -nogroup \) -xdev -ls 2>/dev/null  > 1.17.txt

if [ -s 1.17.txt ]
then
	linecount=`cat 1.17.txt | wc -l`
	if [ $linecount -gt 10 ]
  then
		echo "  ● 소유자가 존재하지 않는 파일 (상위 10개)"                                             >> $HOSTNAME.linux.result.txt 2>&1
	  head -10 1.17.txt | sed 's/^/    /'                                                                          >> $HOSTNAME.linux.result.txt 2>&1
    echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
  	echo "    등 총 "$linecount"개 파일 존재 (전체 목록은 스크립트 결과 파일 확인)"               >> $HOSTNAME.linux.result.txt 2>&1
		
	else
		echo "  ● 소유자가 존재하지 않는 파일"                                                         >> $HOSTNAME.linux.result.txt 2>&1
	  cat 1.17.txt | sed 's/^/    /'                                                                              >> $HOSTNAME.linux.result.txt 2>&1
    echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
  	echo " 총 "$linecount"개 파일 존재"                                                        >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
  echo " - 소유자가 존재하지 않는 파일이 발견되지 않습니다."                                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                               >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################          /etc/passwd 파일 소유자 및 권한 설정          ##################"
echo "##################      [U-16] /etc/passwd 파일 소유자 및 권한 설정      ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: /etc/passwd 파일의 소유자가 root이고, 권한이 644 이하인 경우 양호"                      >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/passwd 파일 소유자 및 권한 확인"                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1

if [ -f /etc/passwd ]
then
    printf "(%s) " $($STAT_CMD /etc/passwd 2>/dev/null || stat -f %Lp /etc/passwd 2>/dev/null) >> $HOSTNAME.linux.result.txt
    ls -alL /etc/passwd >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /etc/passwd 파일이 없습니다."                                                        >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################             시스템 시작 스크립트 권한 설정             ##################"
echo "##################         [U-17] 시스템 시작 스크립트 권한 설정          ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 시스템 시작 스크립트 파일의 소유자가 root이고, 일반 사용자의 쓰기 권한이 제거된 경우 양호"                     >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ init 시스템 시작 스크립트 파일 확인"                                                                   >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

INIT_FILES=$(find /etc/rc*.d/ -type l -exec readlink -f {} + 2>/dev/null | sort -u)
if [ -n "$INIT_FILES" ]; then
    echo "$INIT_FILES" | while read file; do
        if [ -f "$file" ]; then
            printf "(%s) " $($STAT_CMD "$file") >> $HOSTNAME.linux.result.txt
            ls -ld "$file" >> $HOSTNAME.linux.result.txt
        fi
    done
else
    echo " - init 시스템 시작 스크립트 파일이 발견되지 않습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ systemd 시스템 시작 스크립트 파일 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

SYSTEMD_FILES=$(find /etc/systemd/system/ -type l -exec readlink -f {} + 2>/dev/null | sort -u)
if [ -n "$SYSTEMD_FILES" ]; then
    echo "$SYSTEMD_FILES" | while read file; do
        if [ -f "$file" ]; then
            printf "(%s) " $($STAT_CMD "$file") >> $HOSTNAME.linux.result.txt
            ls -ld "$file" >> $HOSTNAME.linux.result.txt
        fi
    done
else
    echo " - systemd 시스템 시작 스크립트 파일이 발견되지 않습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

rm -rf systemdfile.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################          /etc/shadow 파일 소유자 및 권한 설정         ##################"
echo "##################      [U-18] /etc/shadow 파일 소유자 및 권한 설정      ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: /etc/shadow 파일의 소유자가 root이고, 권한이 400 이하인 경우 양호"                     >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/shadow 파일 소유자 및 권한 확인"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/shadow ]
then
    printf "(%s) " $($STAT_CMD /etc/shadow 2>/dev/null || stat -f %Lp /etc/shadow 2>/dev/null) >> $HOSTNAME.linux.result.txt
    ls -alL /etc/shadow >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /etc/shadow 파일이 없습니다."                                                        >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################          /etc/hosts 파일 소유자 및 권한 설정          ##################"
echo "##################       [U-19] /etc/hosts 파일 소유자 및 권한 설정      ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: /etc/hosts 파일의 소유자가 root 이고, 권한이 644 이하인 경우 양호"                      >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/hosts 파일 소유자 및 권한 확인"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/hosts ]
then
    printf "(%s) " $($STAT_CMD /etc/hosts 2>/dev/null || stat -f %Lp /etc/hosts 2>/dev/null) >> $HOSTNAME.linux.result.txt
    ls -alL /etc/hosts >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /etc/hosts 파일이 없습니다."                                                        >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "※ /etc/hosts: IP 주소와 호스트 네임을 매핑하는 파일"                                                  >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################        /etc/(x)inetd.conf 파일 소유자 및 권한 설정      #################"
echo "##################    [U-20] /etc/(x)inetd.conf 파일 소유자 및 권한 설정    #################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: /etc/(x)inetd.conf 파일 및 /etc/xinetd.d/ 하위 모든 파일의 소유자가 root 이고, 권한이 600 이하인 경우 양호" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황" >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]" >> $HOSTNAME.linux.result.txt 2>&1
echo " " >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ /etc/xinetd.conf 파일 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/xinetd.conf ]; then
    printf "(%s) " $($STAT_CMD /etc/xinetd.conf 2>/dev/null || stat -f %Lp /etc/xinetd.conf 2>/dev/null) >> $HOSTNAME.linux.result.txt
    ls -alL /etc/xinetd.conf >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /etc/xinetd.conf 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ /etc/xinetd.d/ 디렉터리 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if [ -d /etc/xinetd.d ]; then
    XINETD_FILES=$(ls -A /etc/xinetd.d 2>/dev/null)
    if [ -z "$XINETD_FILES" ]; then
        echo " - /etc/xinetd.d 디렉터리 내 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    else
        find /etc/xinetd.d -type f 2>/dev/null | while read file; do
            printf "(%s) " $($STAT_CMD "$file" 2>/dev/null || stat -f %Lp "$file" 2>/dev/null) >> $HOSTNAME.linux.result.txt
            ls -alL "$file" >> $HOSTNAME.linux.result.txt 2>&1
        done
    fi
else
    echo " - /etc/xinetd.d 디렉터리가 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ /etc/inetd.conf 파일 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/inetd.conf ]; then
    printf "(%s) " $($STAT_CMD /etc/inetd.conf 2>/dev/null || stat -f %Lp /etc/inetd.conf 2>/dev/null) >> $HOSTNAME.linux.result.txt
    ls -alL /etc/inetd.conf >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /etc/inetd.conf 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]" >> $HOSTNAME.linux.result.txt 2>&1

rm -rf temp206.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################      /etc/(r)syslog.conf 파일 소유자 및 권한 설정     ##################"
echo "##################  [U-21] /etc/(r)syslog.conf 파일 소유자 및 권한 설정  ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: /etc/(r)syslog.conf 파일의 소유자가 root(또는 bin, sys)이고, 권한이 640 이하인 경우 양호"               >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/(r)syslog.conf 파일 소유자 및 권한 확인"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1

if [ -f /etc/syslog.conf ]; then
    FILE="/etc/syslog.conf"
elif [ -f /etc/rsyslog.conf ]; then
    FILE="/etc/rsyslog.conf"
else
    FILE=""
fi

if [ -n "$FILE" ]; then
    printf "(%s) " $($STAT_CMD "$FILE" 2>/dev/null || stat -f %Lp "$FILE" 2>/dev/null) >> $HOSTNAME.linux.result.txt
    ls -alL "$FILE" >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /etc/(r)syslog.conf 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################         /etc/services 파일 소유자 및 권한 설정        ##################"
echo "##################     [U-22] /etc/services 파일 소유자 및 권한 설정     ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: /etc/services 파일의 소유자가 root(또는 bin, sys)이고, 권한이 644 이하인 경우 양호"                     >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 소유자 및 권한 확인"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/services ]
then
    printf "(%s) " $(stat -c %a /etc/services 2>/dev/null || stat -f %Lp /etc/services 2>/dev/null) >> $HOSTNAME.linux.result.txt
    ls -alL /etc/services >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /etc/services 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################         SUID,SGID,Sticky bit 설정 파일 점검         ##################"
echo "##################      [U-23] SUID,SGID,Sticky bit 설정 파일 점검     ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 주요 실행파일의 권한에 SUID와 SGID에 대한 설정이 부여되어 있지 않은 경우 양호"                               >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
find /usr -xdev -user root -type f \( -perm -04000 -o -perm -02000 \) -exec ls -al  {}  \;     > 1.24.txt
find /sbin -xdev -user root -type f \( -perm -04000 -o -perm -02000 \) -exec ls -al  {}  \;    >> 1.24.txt
if [ -s 1.24.txt ]
then
	linecount=`cat 1.24.txt | wc -l`
		echo "☞ 불필요한 SUID,SGID,Sticky Bit 설정 파일"      >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1	
		cat 1.24.txt | $GREP_CMD "/sbin/dump|/sbin/restore|/usr/bin/at|/usr/bin/lpq|/usr/bin/lpq-lpd|/usr/bin/lpr|/usr/bin/lpr-lpd|/usr/bin/lprm|usr/bin/lprm-lpd|/usr/bin/newgrp|/usr/sbin/lpc|/usr/sbin/lpc-lpd|/usr/sbin/traceroute" >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
	if [ $linecount -gt 10 ]
  then
  	echo "☞ SUID,SGID,Sticky bit 설정 파일 (상위 10개)"                                          >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1
	  head -10 1.24.txt                                                                          >> $HOSTNAME.linux.result.txt 2>&1
    echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
  	echo "    등 총 "$linecount"개 파일 존재 (전체 목록은 스크립트 결과 파일 확인)"               >> $HOSTNAME.linux.result.txt 2>&1
	else
  	echo "☞ SUID,SGID,Sticky bit 설정 파일"                                                      >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1
	  cat 1.24.txt                                                                               >> $HOSTNAME.linux.result.txt 2>&1
    echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
  	echo "    총 "$linecount"개 파일 존재"                                                        >> $HOSTNAME.linux.result.txt 2>&1
 fi
else
	echo " - SUID/SGID로 설정된 파일이 발견되지 않습니다."                                     >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                            >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################   사용자, 시스템 환경변수 파일 소유자 및 권한 설정   ##################"
echo "################## [U-24] 사용자, 시스템 환경변수 파일 소유자 및 권한 설정 ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 홈 디렉토리 환경변수 파일 소유자가 root 또는 해당 계정으로 지정되어 있고"        >> $HOSTNAME.linux.result.txt 2>&1
echo "■      홈 디렉터리 환경변수 파일에 root와 소유자만 쓰기 권한이 부여 된 경우 양호"       >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황" >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]" >> $HOSTNAME.linux.result.txt 2>&1
USER_INFO=$(cat /etc/passwd | awk -F":" 'length($6) > 0 {print $1":"$6}' | grep -v '/bin/false' | grep -v 'nologin')
FILES=".profile .cshrc .kshrc .login .bash_profile .bashrc .bash_login .exrc .netrc .history .sh_history .bash_history .dtprofile"
rm -f /tmp/env_all.txt /tmp/env_vuln.txt
for info in $USER_INFO
do
    USER_NAME=$(echo $info | cut -d":" -f1)
    USER_HOME=$(echo $info | cut -d":" -f2)
    for file in $FILES
    do
        TARGET="$USER_HOME/$file"
        if [ -f "$TARGET" ]; then
            PERM=$($STAT_CMD "$TARGET" 2>/dev/null)
            OWNER=$($STAT_USER "$TARGET" 2>/dev/null)
            LS_RESULT=$(ls -alL "$TARGET" 2>/dev/null)

            # 전체 목록에 권한 숫자 추가
            echo "($PERM) $LS_RESULT" >> /tmp/env_all.txt

            # 취약 여부 판단
            if [[ "$OWNER" != "root" && "$OWNER" != "$USER_NAME" ]] || [[ "$PERM" =~ [2367]$ ]] || [[ "$PERM" =~ .[2367]. ]]; then
                echo "($PERM) $LS_RESULT" >> /tmp/env_vuln.txt
            fi
        fi
    done
done
echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 취약한 홈 디렉토리 환경변수 파일 (소유자 불일치 또는 그룹/타인 쓰기 권한 존재)" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
[ -s /tmp/env_vuln.txt ] && cat /tmp/env_vuln.txt >> $HOSTNAME.linux.result.txt 2>&1 || echo " - 취약한 환경변수 파일이 발견되지 않았습니다." >> $HOSTNAME.linux.result.txt 2>&1
echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 홈 디렉토리 환경변수 파일(전체)" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
[ -s /tmp/env_all.txt ] && cat /tmp/env_all.txt >> $HOSTNAME.linux.result.txt 2>&1 || echo " - 환경변수 파일이 존재하지 않습니다." >> $HOSTNAME.linux.result.txt 2>&1
echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]" >> $HOSTNAME.linux.result.txt 2>&1
rm -f /tmp/env_all.txt /tmp/env_vuln.txt
echo " " >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################               world writable 파일 점검              ##################"
echo "##################           [U-25] world writable 파일 점검           ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 시스템 중요 파일에 world writable 파일이 존재하지 않거나, 존재 시 설정 이유를 확인하고 있는 경우 양호"            >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
if [ -d /etc ]
then
  find /etc -perm -2 -ls | awk '{print $3 " : " $5 " : " $6 " : " $11}' | grep -v "^l"         > world-writable.txt
fi
if [ -d /var ]
then
  find /var -perm -2 -ls | awk '{print $3 " : " $5 " : " $6 " : " $11}' | grep -v "^l"         >> world-writable.txt
fi
if [ -d /tmp ]
then
  find /tmp -perm -2 -ls | awk '{print $3 " : " $5 " : " $6 " : " $11}' | grep -v "^l"         >> world-writable.txt
fi
if [ -d /home ]
then
  find /home -perm -2 -ls | awk '{print $3 " : " $5 " : " $6 " : " $11}'| grep -v "^l"         >> world-writable.txt
fi
if [ -d /export ]
then
  find /export -perm -2 -ls | awk '{print $3 " : " $5 " : " $6 " : " $11}'| grep -v "^l"       >> world-writable.txt
fi

if [ -s world-writable.txt ]
then
  linecount=`cat world-writable.txt | wc -l`
  if [ $linecount -gt 50 ]
  then
  	echo "☞ World Writable 파일 (상위 50개)"                                                     >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1
	  head -50 world-writable.txt                                                                >> $HOSTNAME.linux.result.txt 2>&1
    echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
  	echo "     등 총 "$linecount"개 파일 존재 (전체 목록은 스크립트 결과 파일 확인)"              >> $HOSTNAME.linux.result.txt 2>&1
		else
    echo "☞ World Writable 파일"                                                                 >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1
	  cat world-writable.txt                                                                     >> $HOSTNAME.linux.result.txt 2>&1
    echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
	echo "     총 "$linecount"개 파일 존재"                                                        >> $HOSTNAME.linux.result.txt 2>&1
		fi
else
    echo " - World Writable 권한이 부여된 파일이 발견되지 않습니다."                         >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                            >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################         /dev에 존재하지 않는 device 파일 점검         ##################"
echo "##################      [U-26] /dev에 존재하지 않는 device 파일 점검     ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준 : dev 에 존재하지 않은 Device 파일을 점검하고, 존재하지 않은 Device을 제거 했을 경우 양호" >> $HOSTNAME.linux.result.txt 2>&1
echo "■       (아래 나열된 결과는 major, minor Number를 갖지 않는 파일임)"                  >> $HOSTNAME.linux.result.txt 2>&1
echo "■       (.devlink_db_lock/.devfsadm_daemon.lock/.devfsadm_synch_door/.devlink_db는 Default로 존재 예외)" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /dev에 존재하지 않는 device 파일"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1
find /dev -type f -exec ls -l {} \;                                                            > 1.32.txt
if [ -s 1.32.txt ]
then
  linecount=`cat 1.32.txt | wc -l`
  if [ $linecount -gt 10 ]
  then
	  head -10 1.32.txt                                                                >> $HOSTNAME.linux.result.txt 2>&1
	  echo " " >> $HOSTNAME.linux.result.txt 2>&1
  	  echo "    등 총 "$linecount"개 파일 존재 (전체 목록은 스크립트 결과 파일 확인)"              >> $HOSTNAME.linux.result.txt 2>&1
  else
	cat 1.32.txt                                                              		 >> $HOSTNAME.linux.result.txt 2>&1
   fi
else
	echo " - /dev에 존재하지 않는 Device 파일이 발견되지 않습니다."                            >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

rm -rf 1.32.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################         $HOME/.rhosts, hosts.equiv 사용 금지        ##################"
echo "##################     [U-27] $HOME/.rhosts, hosts.equiv 사용 금지     ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: r-commands 서비스를 사용하지 않으면 양호"                                        >> $HOSTNAME.linux.result.txt 2>&1
echo "■      r-commands 서비스를 사용하는 경우 HOME/.rhosts, hosts.equiv 설정확인"          >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (1) .rhosts 파일의 소유자가 해당 계정의 소유자이고, 퍼미션 600, 내용에 + 가 설정되어 있지 않으면 양호" >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (2) /etc/hosts.equiv 파일의 소유자가 root 이고, 퍼미션 600, 내용에 + 가 설정되어 있지 않으면 양호" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="login" {print $1 "   " $2}' | grep "tcp"                   >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="shell" {print $1 "   " $2}' | grep "tcp"                   >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="exec" {print $1 "    " $2}' | grep "tcp"                   >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 서비스 포트 활성화 여부 확인"                                                         >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="login" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="login" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                                > 1.33.txt
fi

if [ `cat /etc/services | awk -F" " '$1=="shell" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="shell" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                                >> 1.33.txt
fi

if [ `cat /etc/services | awk -F" " '$1=="exec" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="exec" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                                >> 1.33.txt
fi

if [ -s 1.33.txt ]
then
	cat 1.33.txt | grep -v '^ *$'                                                                >> $HOSTNAME.linux.result.txt 2>&1
	flag1="M/T"
else
	echo " - r-command 서비스가 비활성화 상태입니다."                                                          >> $HOSTNAME.linux.result.txt 2>&1
	flag1="Disabled"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/hosts.equiv 파일 설정"                                                           >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/hosts.equiv ]
	then
		echo "(1) Permission: (`ls -al /etc/hosts.equiv`)"                                         >> $HOSTNAME.linux.result.txt 2>&1
		echo "(2) 설정 내용:"                                                                      >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------"                                            >> $HOSTNAME.linux.result.txt 2>&1
		if [ `cat /etc/hosts.equiv | grep -v "#" | grep -v '^ *$' | wc -l` -gt 0 ]
		then
			cat /etc/hosts.equiv | grep -v "#" | grep -v '^ *$'                                      >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - 설정 내용이 없습니다."                                                             >> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		echo " - /etc/hosts.equiv 파일이 없습니다."                                                   >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 사용자 home directory .rhosts 설정 내용"                                              >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
HOMEDIRS=`cat /etc/passwd | awk -F":" 'length($6) > 0 {print $6}' | sort -u`
FILES="/.rhosts"

for dir in $HOMEDIRS
do
	for file in $FILES
	do
		if [ -f $dir$file ]
		then
			echo " "                                                                                 > rhosts.txt
			echo "# $dir$file 파일 설정:"                                                            >> $HOSTNAME.linux.result.txt 2>&1
			echo "(1) Permission: (`ls -al $dir$file`)"                                              >> $HOSTNAME.linux.result.txt 2>&1
			echo "(2) 설정 내용:"                                                                    >> $HOSTNAME.linux.result.txt 2>&1
			echo "----------------------------------------"                                          >> $HOSTNAME.linux.result.txt 2>&1
			if [ `cat $dir$file | grep -v "#" | grep -v '^ *$' | wc -l` -gt 0 ]
			then
				cat $dir$file | grep -v "#" | grep -v '^ *$'                                           >> $HOSTNAME.linux.result.txt 2>&1
			else
				echo " - 설정 내용이 없습니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
			fi
		fi
	done
done
if [ ! -f rhosts.txt ]
then
	echo " - .rhosts 파일이 없습니다."                                                              >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

rm -rf rhosts.txt
rm -rf 1.33.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                 접속 IP 및 포트 제한                 ##################"
echo "##################             [U-28] 접속 IP 및 포트 제한              ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 접속을 허용할 특정 호스트에 대한 IP주소 및 포트 제한을 설정한 경우 양호"                 >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/hosts.allow 파일 설정"                                                           >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/hosts.allow ]
then
	if [ ! `cat /etc/hosts.allow | grep -v "#" | $GREP_CMD -v '^ *$' | wc -l` -eq 0 ]
	then
		cat /etc/hosts.allow | grep -v "#" | $GREP_CMD -v '^ *$'                                       >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/hosts.allow 파일에 설정 내용이 없습니다."                                                               >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/hosts.allow 파일이 없습니다."                                                     >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/hosts.deny 파일 설정"                                                            >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/hosts.deny ]
then
	if [ ! `cat /etc/hosts.deny | grep -v "#" | $GREP_CMD -v '^ *$' | wc -l` -eq 0 ]
	then
		cat /etc/hosts.deny | grep -v "#" | $GREP_CMD -v '^ *$'                                        >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/hosts.deny 파일에 설정 내용이 없습니다."                                                               >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/hosts.deny 파일이 없습니다."                                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                 >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 방화벽(iptables) 실행 여부 점검" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if command -v iptables >/dev/null 2>&1; then
    IPT_STATUS=$(service iptables status 2>/dev/null | grep -i active)
    
    if [ -n "$IPT_STATUS" ]; then
        echo "$IPT_STATUS" >> $HOSTNAME.linux.result.txt 2>&1
        echo "[iptables Rules]" >> $HOSTNAME.linux.result.txt 2>&1
        iptables -L -n 2>/dev/null >> $HOSTNAME.linux.result.txt 2>&1
    else
        echo " - iptables 서비스가 중지 상태이거나 관리되지 않습니다." >> $HOSTNAME.linux.result.txt 2>&1
    fi
else
    echo " - iptables 명령어를 찾을 수 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ 방화벽(firewalld) 상태 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if command -v firewall-cmd >/dev/null 2>&1; then
    FW_STATE=$(firewall-cmd --state 2>/dev/null)
    echo "상태: $FW_STATE" >> $HOSTNAME.linux.result.txt 2>&1
    
    if [ "$FW_STATE" = "running" ]; then
        firewall-cmd --list-all >> $HOSTNAME.linux.result.txt 2>&1
    fi
else
    echo " - firewalld(firewall-cmd) 명령어를 찾을 수 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ 방화벽(ufw) 점검" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if command -v ufw >/dev/null 2>&1; then
    ufw status >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - ufw 명령어를 찾을 수 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################           hosts.lpd 파일 소유자 및 권한 설정          ##################"
echo "##################       [U-29] hosts.lpd 파일 소유자 및 권한 설정       ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: hosts.lpd 파일이 삭제되어 있거나 불가피하게 hosts.lpd 파일을 사용할 시 파일의 소유자가 root이고 권한이 600인 경우 양호"                   >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/hosts.lpd 파일 소유자 및 권한 확인"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/hosts.lpd ]
then
    printf "(%s) " $($STAT_CMD /etc/hosts.lpd 2>/dev/null || stat -f %Lp /etc/hosts.lpd 2>/dev/null) >> $HOSTNAME.linux.result.txt
    ls -alL /etc/hosts.lpd >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /etc/hosts.lpd 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                   UMASK 설정 관리                   ##################"
echo "##################               [U-30] UMASK 설정 관리                ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: UMASK 값이 022 이상으로 설정된 경우 양호"                                                        >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (1) sh, ksh, bash 쉘의 경우 /etc/profile 파일 설정을 적용받음"                 >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (2) csh, tcsh 쉘의 경우 /etc/csh.cshrc 또는 /etc/csh.login 파일 설정을 적용받음" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 현재 로그인 계정 UMASK"                                                               >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
umask                                                                                          >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/profile 파일(기준: umask 022)"                                            >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/profile ]
then
	if [ `cat /etc/profile | grep -i umask | grep -v ^# | wc -l` -gt 0 ]
	then
		cat /etc/profile | grep -A 1 -B 1 -i umask | grep -v ^#                                              >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/profile 파일에 umask 설정이 없습니다."                                                              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/profile 파일이 없습니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[참고]"                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "1. UID와 GID가 같고 199를 초과 하는 계정은 002로 Default 를 가져가며 만약 다를시 022로 Default 를 가져감"     >> $HOSTNAME.linux.result.txt 2>&1
echo "2. etc/passwd 파일을 참고하여 조치"                                                               >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################             홈 디렉토리 소유자 및 권한 설정            ##################"
echo "##################         [U-31] 홈 디렉토리 소유자 및 권한 설정         ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 홈 디렉토리의 소유자가 /etc/passwd 내에 등록된 홈 디렉토리 사용자와 일치하고,"   >> $HOSTNAME.linux.result.txt 2>&1
echo "■      홈 디렉토리에 타사용자 쓰기권한이 없으면 양호"                                 >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 계정 별 홈디렉토리 확인"															                    >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	echo "   계정명          홈 디렉터리 경로" >> $HOSTNAME.linux.result.txt
	echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt
	cat /etc/passwd | grep -vE "/sbin/nologin|/bin/false|/sbin/shutdown|/bin/sync|/sbin/halt" | \
	awk -F: '{printf "%-15s : %-s\n", $1, $6}' >> $HOSTNAME.linux.result.txt
echo " " 																							       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ 계정 별 홈 디렉터리 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

awk -F: '($7 !~ /\/(nologin|false|shutdown|sync|halt)$/) { print $1, $6 }' /etc/passwd | while read user home; do
    if [ -d "$home" ]; then
        PERM=$($STAT_CMD "$home" 2>/dev/null || stat -f %Lp "$home" 2>/dev/null)
        printf "(%s) " "$PERM" >> $HOSTNAME.linux.result.txt
        ls -ld "$home" >> $HOSTNAME.linux.result.txt 2>&1
    else
        echo " - 계정($user)의 홈 디렉터리($home)가 존재하지 않습니다." >> $HOSTNAME.linux.result.txt 2>&1
    fi
done										                                    >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################        홈 디렉토리로 지정한 디렉토리의 존재 관리        ##################"
echo "##################     [U-32] 홈 디렉토리로 지정한 디렉토리의 존재 관리    ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 홈 디렉토리가 존재하지 않는 계정이 발견되지 않으면 양호"                         >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 홈 디렉토리가 존재하지 않은 계정"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
HOMEDIRS=`cat /etc/passwd | awk -F":" 'length($6) > 0 {print $6}' | sort -u | grep -v "#" | grep -v "/tmp" | grep -v "uucppublic" | uniq`
flag=0
for dir in $HOMEDIRS
do
	if [ ! -d $dir ]
	then
		awk -F: '$6=="'${dir}'" { print "계정명(홈디렉토리):"$1 "(" $6 ")" }' /etc/passwd			> 1.29.txt
		awk -F: '$6=="'${dir}'" { print "계정명(홈디렉토리):"$1 "(" $6 ")" }' /etc/passwd        >> $HOSTNAME.linux.result.txt 2>&1
		flag=`expr $flag + 1`
	fi
done

if [ ! -f 1.29.txt ]
then
	echo " - 홈 디렉토리가 존재하지 않는 계정이 발견되지 않습니다."                        >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

rm -rf 1.29.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################          숨겨진 파일 및 디렉토리 검색 및 제거          ##################"
echo "##################       [U-33] 숨겨진 파일 및 디렉토리 검색 및 제거      ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 불필요하거나 의심스러운 숨겨진 파일 및 디렉터리를 제거한 경우 양호"                           >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
find /tmp -name ".*" -ls                                                                       > 220.txt 2>&1
find /home -name ".*" -ls                                                                      >> 220.txt 2>&1
find /usr -name ".*" -ls                                                                       >> 220.txt 2>&1
find /var -name ".*" -ls                                                                       >> 220.txt 2>&1
txtcount="220.txt"

if [ -s 220.txt ]
then
	linecount=$(wc -l < "$txtcount")
	if [ $linecount -gt 50 ]
	then
		echo "☞ 숨겨진 파일 (상위 50개)"                                                     >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"    >> $HOSTNAME.linux.result.txt 2>&1
		head -50 220.txt                                                                 >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
		echo "    등 총 "$linecount"개 파일 존재 (전체 목록은 스크립트 결과 파일 확인)"              >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "☞ 숨겨진 파일"                                                                 >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"     >> $HOSTNAME.linux.result.txt 2>&1
		cat 220.txt                                                                     >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
		echo "    총 "$linecount"개 파일 존재"                                                        >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
    echo " - 숨겨진 파일 및 디렉터리가 없습니다."                                          >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#############################     3. 서비스 관리     ##################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                finger 서비스 비활성화                ##################"
echo "##################            [U-34] finger 서비스 비활성화             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: Finger 서비스가 비활성화된 경우 양호"                                    >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="finger" {print $1 "   " $2}' | grep "tcp"                  >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 서비스 포트 활성화 여부 확인"                                                         >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="finger" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="finger" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -eq 0 ]
	then
		echo " - Finger 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
	else
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	if [ `$NETSTAT_CMD -na | grep ":79 " | grep -i "^tcp" | wc -l` -eq 0 ]
	then
		echo " - Finger 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
	else
		$NETSTAT_CMD -na | grep ":79 " | grep -i "^tcp"                                                 >> $HOSTNAME.linux.result.txt 2>&1
	fi
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################          공유 서비스에 대한 익명 접근 제한 설정         ##################"
echo "##################      [U-35]  공유 서비스에 대한 익명 접근 제한 설정     ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 공유 서비스에 대해 익명 접근을 제한한 경우 양호"                            >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 FTP 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="ftp" {print "  /etc/service 파일:" $1 " " $2}' | grep "tcp" | wc -l` -gt 0 ]
then
	cat /etc/services | awk -F" " '$1=="ftp" {print "/etc/service 파일:" $1 " " $2}' | grep "tcp" >> $HOSTNAME.linux.result.txt 2>&1
else
	echo "/etc/service 파일: 포트 설정 X (Default 21번 포트)"                                  >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s vsftpd.txt ]
then
	if [ `cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "VsFTP 포트: 포트 설정 X (Default 21번 포트 사용중)"                               >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - VsFTP가 설치되어 있지 않습니다."                                        >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s proftpd.txt ]
then
	if [ `cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}'    >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "ProFTP 포트 : 포트 설정 X (/etc/service 파일에 설정된 포트를 사용중)"              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - ProFTP가 설치되어 있지 않습니다."                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ FTP 포트 활성화 여부 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

# 취약 여부를 체크하기 위한 변수 (0: 양호, 1: 취약)
VULN=0
rm -f ftpenable.txt

################# 1. /etc/services 기준 포트 확인 #################
# 서비스 파일에서 포트 추출 (실패 시 21)
port=$(grep -w "^ftp" /etc/services 2>/dev/null | grep "/tcp" | awk '{print $2}' | cut -d'/' -f1 | head -1)
[ -z "$port" ] && port=21

# 해당 포트가 LISTEN 중인지 확인
check=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$port " | grep -i "LISTEN")
if [ -n "$check" ]; then
    echo "FTP 서비스 포트($port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
    echo "$check" >> $HOSTNAME.linux.result.txt 2>&1
    VULN=1
fi

################# 2. vsftpd 설정 확인 ############################
if [ -s vsftpd.txt ] && [ -n "$vsfile" ]; then
    v_port=$(grep "listen_port" "$vsfile" | awk -F"=" '{print $2}' | tr -d ' ')
    [ -z "$v_port" ] && v_port=21
    
    check_v=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$v_port " | grep -i "LISTEN")
    if [ -n "$check_v" ]; then
        echo "vsftpd 서비스 포트($v_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_v" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 3. proftpd 설정 확인 ###########################
if [ -s proftpd.txt ] && [ -n "$profile" ]; then
    p_port=$(grep "Port" "$profile" | awk '{print $2}' | tr -d ' ')
    [ -z "$p_port" ] && p_port=21
    
    check_p=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$p_port " | grep -i "LISTEN")
    if [ -n "$check_p" ]; then
        echo "proftpd 서비스 포트($p_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_p" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 4. 최종 예외 처리 (아무것도 발견 안 됨) ##########
if [ $VULN -eq 0 ]; then
    echo " - 모든 FTP 관련 포트가 비활성화되어 있습니다." >> $HOSTNAME.linux.result.txt 2>&1
else
    echo "ON" > ftpenable.txt
fi

echo " " 																					>> $HOSTNAME.linux.result.txt 2>&1
echo "☞ FTP Anonymous 설정 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

if [ -f ftpenable.txt ]
then
    rm -rf ftpenable.txt
    flag1="Enabled"
    
    if [ -s vsftpd.txt ]
    then
        # vsftpd 설정 확인 시
        cat $vsfile | grep -i "anonymous_enable" | awk '{print " ▣ VsFTP 설정: " $0}' >> $HOSTNAME.linux.result.txt 2>&1
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
        flag2=$(cat $vsfile | grep -i "anonymous_enable" | grep -i "YES" | wc -l)
    else
        # vsftpd가 아닐 때 시스템 계정 확인 (원하시는 형식)
        if [ $(cat /etc/passwd | $GREP_CMD "^ftp:|^anonymous:" | wc -l) -gt 0 ]
        then
            echo "ftp 또는 anonymous 계정이 존재합니다." >> $HOSTNAME.linux.result.txt 2>&1
            echo "" >> $HOSTNAME.linux.result.txt 2>&1
            echo "[발견된 ftp 또는 anonymous 계정]" >> $HOSTNAME.linux.result.txt 2>&1
            cat /etc/passwd | $GREP_CMD "^ftp:|^anonymous:" >> $HOSTNAME.linux.result.txt 2>&1
            echo " " >> $HOSTNAME.linux.result.txt 2>&1
            flag2=$(cat /etc/passwd | $GREP_CMD "^ftp:|^anonymous:" | wc -l)
        else
            echo " - /etc/passwd 파일에 ftp 또는 anonymous 계정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
            flag2=0
        fi
    fi
else
    echo " - FTP 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1
    flag1="Disabled"
    flag2="Disabled"
fi

echo " " 																						>> $HOSTNAME.linux.result.txt 2>&1
echo "☞ NFS Server Daemon(nfsd) 확인"															                        >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep "nfsd" | $GREP_CMD -v "statdaemon|automountd|emi" | grep -v "grep" | wc -l` -gt 0 ]
 then
   ps -ef | grep "nfsd" | $GREP_CMD -v "statdaemon|automountd|emi" | grep -v "grep"                >> $HOSTNAME.linux.result.txt 2>&1
   if [ `cat /etc/exports 2>/dev/null | $GREP_CMD "anonuid|anongid|squash|\*" | wc -l` -gt 0 ]
   then
     echo " " 																					>> $HOSTNAME.linux.result.txt 2>&1
	 echo "☞ NFS 서비스 Anonymous 설정 확인"                                                               >> $HOSTNAME.linux.result.txt 2>&1
	 echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	 cat  /etc/exports | $GREP_CMD "anon|squash|\*"                >> $HOSTNAME.linux.result.txt 2>&1
   else
	 echo "☞ NFS 서비스 Anonymous 설정 확인"                                                               >> $HOSTNAME.linux.result.txt 2>&1
	 echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	 echo " - /etc/exports 파일에 공유 설정이 없습니다."  >> $HOSTNAME.linux.result.txt 2>&1
   fi
 else
   echo " - NFS 서비스가 비활성화 상태입니다."                                 >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " " 																							                >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ Samba Server Daemon(smbd) 확인"															                        >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep "smbd" | grep -v "grep" | wc -l` -gt 0 ]
 then
   ps -ef | grep "smbd" | grep -v "grep"                                 >> $HOSTNAME.linux.result.txt 2>&1
   if [ `cat /etc/samba/smb.conf 2>/dev/null | $GREP_CMD -i "guest|public" | wc -l` -gt 0 ]
   then
	 echo " " 																					>> $HOSTNAME.linux.result.txt 2>&1
	 echo "☞ Samba Anonymous 설정 확인"                                                               >> $HOSTNAME.linux.result.txt 2>&1
	 echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	 cat /etc/samba/smb.conf | $GREP_CMD -i "guest|public"     >> $HOSTNAME.linux.result.txt 2>&1
   else
	 echo "☞ Samba Anonymous 설정 확인"                                                               >> $HOSTNAME.linux.result.txt 2>&1
	 echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	 echo " - /etc/samba/smb.conf 파일에 Anonymous 설정이 없습니다."  >> $HOSTNAME.linux.result.txt 2>&1
   fi
 else
   echo " - Samba 서비스가 비활성화 상태입니다."                                       >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                r 계열 서비스 비활성화                ##################"
echo "##################            [U-36] r 계열 서비스 비활성화             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 불필요한 r 계열 서비스가 비활성화 되어 있는 경우 양호"                                        >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="login" {print $1 "   " $2}' | grep "tcp"                   >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="shell" {print $1 "   " $2}' | grep "tcp"                   >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="exec" {print $1 "    " $2}' | grep "tcp"                   >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 서비스 포트 활성화 여부 확인"                             >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="login" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="login" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > rcommand.txt
	fi
fi

if [ `cat /etc/services | awk -F" " '$1=="shell" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="shell" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > rcommand.txt
	fi
fi

if [ `cat /etc/services | awk -F" " '$1=="exec" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="exec" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		fi
fi

if [ -f rcommand.txt ]
then
	rm -rf rcommand.txt
	else
	echo " - r-commands 서비스가 비활성화 상태입니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1

fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################            crontab 설정파일 권한 설정 미흡            ##################"
echo "##################         [U-37] crontab 설정파일 권한 설정 미흡        ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: crontab 및 at 파일 권한이 640 이하이고 소유자가 root일 경우 양호"    >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
# 1. crontab 명령어 권한 확인
echo "☞ crontab 명령어 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /usr/bin/crontab ]; then
    p_num=$(stat -c "%a" /usr/bin/crontab)
    echo "($p_num) $(ls -alL /usr/bin/crontab)" >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /usr/bin/crontab 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo "" >> $HOSTNAME.linux.result.txt 2>&1

# 2. 사용자별 cron 작업 목록 파일 권한 확인
echo "☞ 사용자별 cron 작업 목록 파일 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
found_any="X"
for dir in /var/spool/cron /var/spool/cron/crontabs; do
    if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "[디렉터리]: $dir" >> $HOSTNAME.linux.result.txt 2>&1
        ls -1 "$dir" | while read fname; do
            p_num=$(stat -c "%a" "$dir/$fname")
            echo "($p_num) $(ls -ld "$dir/$fname")" >> $HOSTNAME.linux.result.txt 2>&1
        done
        found_any="O"
    fi
done
[ "$found_any" = "X" ] && echo " - 등록된 사용자별 cron 작업 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
echo "" >> $HOSTNAME.linux.result.txt 2>&1

# 3. at 명령어 권한 확인
echo "☞ at 명령어 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /usr/bin/at ]; then
    p_num=$(stat -c "%a" /usr/bin/at)
    echo "($p_num) $(ls -alL /usr/bin/at)" >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /usr/bin/at 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo "" >> $HOSTNAME.linux.result.txt 2>&1

# 4. 사용자별 at 작업 목록 파일 권한 확인
echo "☞ 사용자별 at 작업 목록 파일 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
found_at_any="X"
for dir in /var/spool/at /var/spool/cron/atjobs; do
    if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "[디렉터리]: $dir" >> $HOSTNAME.linux.result.txt 2>&1
        ls -1 "$dir" | while read fname; do
            p_num=$(stat -c "%a" "$dir/$fname")
            echo "($p_num) $(ls -ld "$dir/$fname")" >> $HOSTNAME.linux.result.txt 2>&1
        done
        found_at_any="O"
    fi
done
[ "$found_at_any" = "X" ] && echo " - 등록된 사용자별 at 작업 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
echo "" >> $HOSTNAME.linux.result.txt 2>&1

# 5~8. allow / deny 파일 권한 확인 (각각 별도 출력 유지)
for file_path in /etc/cron.allow /etc/cron.deny /etc/at.allow /etc/at.deny; do
    file_name=$(basename $file_path)
    echo "☞ $file_name 파일 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    if [ -f "$file_path" ]; then
        p_num=$(stat -c "%a" "$file_path")
        echo "($p_num) $(ls -alL "$file_path")" >> $HOSTNAME.linux.result.txt 2>&1
    else
        echo " - $file_path 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    fi
    echo "" >> $HOSTNAME.linux.result.txt 2>&1
done

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################            Dos 공격에 취약한 서비스 비활성화           ##################"
echo "##################        [U-38] Dos 공격에 취약한 서비스 비활성화        ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: DoS 공격에 취약한 echo , discard , daytime , chargen 서비스를 사용하지 않았을 경우 양호" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="echo" {print $1 "      " $2}' | grep "tcp"                 >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="echo" {print $1 "      " $2}' | grep "udp"                 >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="discard" {print $1 "   " $2}' | grep "tcp"                 >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="discard" {print $1 "   " $2}' | grep "udp"                 >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="daytime" {print $1 "   " $2}' | grep "tcp"                 >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="daytime" {print $1 "   " $2}' | grep "udp"                 >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="chargen" {print $1 "   " $2}' | grep "tcp"                 >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="chargen" {print $1 "   " $2}' | grep "udp"                 >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 서비스 포트 활성화 여부 확인"                                                         >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="echo" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="echo" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > unnecessary.txt
	fi
fi
if [ `cat /etc/services | awk -F" " '$1=="echo" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="echo" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > unnecessary.txt
	fi
fi
if [ `cat /etc/services | awk -F" " '$1=="discard" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="discard" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > unnecessary.txt
	fi
fi
if [ `cat /etc/services | awk -F" " '$1=="discard" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="discard" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > unnecessary.txt
	fi
fi
if [ `cat /etc/services | awk -F" " '$1=="daytime" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="daytime" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > unnecessary.txt
	fi
fi
if [ `cat /etc/services | awk -F" " '$1=="daytime" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="daytime" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > unnecessary.txt
	fi
fi
if [ `cat /etc/services | awk -F" " '$1=="chargen" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="chargen" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > unnecessary.txt
	fi
fi
if [ `cat /etc/services | awk -F" " '$1=="chargen" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="chargen" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > unnecessary.txt
	fi
fi

if [ -f unnecessary.txt ]
then
	rm -rf unnecessary.txt
else
	echo " - 불필요한 서비스가 동작하고 있지 않습니다.(echo, discard, daytime, chargen)"            >> $HOSTNAME.linux.result.txt 2>&1
	fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################              불필요한 NFS 서비스 비활성화             ##################"
echo "##################          [U-39] 불필요한 NFS 서비스 비활성화          ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 불필요한 NFS 서비스 관련 데몬이 제거되어 있는 경우 양호"                         >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ NFS Server Daemon(nfsd) 확인"                                                          >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep "nfsd" | $GREP_CMD -v "statdaemon|automountd|emi" | grep -v "grep" | wc -l` -gt 0 ]
 then
   ps -ef | grep "nfsd" | $GREP_CMD -v "statdaemon|automountd|emi" | grep -v "grep"                >> $HOSTNAME.linux.result.txt 2>&1
   flag1="Enabled_Server"
 else
   echo " - NFS 서비스가 비활성화 상태입니다."                                                               >> $HOSTNAME.linux.result.txt 2>&1
   flag1="Disabled_Server"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ NFS Client Daemon(statd,lockd)확인"                                                   >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | $GREP_CMD "statd|lockd" | $GREP_CMD -v "grep|emi|statdaemon|dsvclockd|kblockd" | wc -l` -gt 0 ]
  then
    ps -ef | $GREP_CMD "statd|lockd" | $GREP_CMD -v "grep|emi|statdaemon|dsvclockd|kblockd"            >> $HOSTNAME.linux.result.txt 2>&1
    flag2="Enabled_Client"
  else
    echo " - NFS Client(statd,lockd)가 비활성화 상태입니다."                                                  >> $HOSTNAME.linux.result.txt 2>&1
    flag2="Disabled_Client"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                    NFS 접근 통제                    ##################"
echo "##################                [U-40] NFS 접근 통제                 ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 접근 통제가 설정되어 있으며 NFS 설정 파일 접근 권한이 644 이하인 경우 양호"                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
# (취약 예문) /tmp/test/share *(rw)
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ NFS Server Daemon(nfsd) 확인"                                                          >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep "nfsd" | $GREP_CMD -v "statdaemon|automountd|emi" | grep -v "grep" | wc -l` -gt 0 ]
 then
   ps -ef | grep "nfsd" | $GREP_CMD -v "statdaemon|automountd|emi" | grep -v "grep"                >> $HOSTNAME.linux.result.txt 2>&1
   flag="M/T"
 else
   echo " - NFS 서비스가 비활성화 상태입니다."                                                               >> $HOSTNAME.linux.result.txt 2>&1
   flag="Disabled"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/exports 파일 권한 설정"                                                               >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/exports ]
then
    # 숫자 권한 추출 (예: 644)
    p_num=$(stat -c "%a" /etc/exports)
    # (숫자)와 함께 ls 결과 기록
    echo "($p_num) $(ls -alL /etc/exports)" >> $HOSTNAME.linux.result.txt 2>&1
    
    # 기존 flag 변수 설정 (유지)
    flag2=`perm /etc/exports | awk -F" " '{print $4 ":" substr($1, 2, 3) }'`
else
    echo " - /etc/exports 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    flag2="Null:Null"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/exports 파일 설정"                                                               >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/exports ]
then
	if [ `cat /etc/exports | grep -v "^ *$" | wc -l` -gt 0 ]
	then
		cat /etc/exports | grep -v "^ *$"                                           >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/exports 파일에 설정 내용이 없습니다."                                                               >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
  echo " - /etc/exports 파일이 없습니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################               불필요한 automountd 제거              ##################"
echo "##################           [U-41] 불필요한 automountd 제거           ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: automountd 서비스가 비활성화된 경우 양호"                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ Automountd Daemon 확인"                                                               >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | $GREP_CMD 'automount|autofs' | grep -v "grep" | $GREP_CMD -v "statdaemon|emi" | wc -l` -gt 0 ]
 then
   ps -ef | $GREP_CMD 'automount|autofs' | grep -v "grep" | $GREP_CMD -v "statdaemon|emi"              >> $HOSTNAME.linux.result.txt 2>&1
   flag="Enabled"
 else
   echo " - Automountd 데몬이 비활성화 상태입니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1
   flag="Disabled"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################              불필요한 RPC 서비스 비활성화             ##################"
echo "##################          [U-42] 불필요한 RPC 서비스 비활성화          ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 불필요한 rpc 관련 서비스가 존재하지 않으면 양호"                                 >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
SERVICE_INETD="rpc.cmsd|rpc.ttdbserverd|sadmind|rusersd|walld|sprayd|rstatd|rpc.nisd|rpc.pcnfsd|rpc.statd|rpc.ypupdated|rpc.rquotad|kcms_server|cachefsd|rexd"

echo "☞ 불필요한 RPC 서비스 동작 확인"                                                        >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | $GREP_CMD $SERVICE_INETD | grep -v grep | wc -l` -gt 0 ]
 then
   ps -ef | $GREP_CMD $SERVICE_INETD | grep -v grep              >> $HOSTNAME.linux.result.txt 2>&1
   flag="Enabled"
 else
   echo " - RPC 관련 서비스가 동작 중이지 않습니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1
   flag="Disabled"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[불필요한 rpc 목록]"   >> $HOSTNAME.linux.result.txt 2>&1
echo "rpc.cmsd|rpc.ttdbserverd|sadmind|rusersd|walld|sprayd|rstatd|rpc.nisd|rpc.pcnfsd|rpc.statd"  >> $HOSTNAME.linux.result.txt 2>&1
echo "rpc.ypupdated|rpc.rquotad|kcms_server|cachefsd|rexd"  >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                   NIS , NIS+ 점검                  ##################"
echo "##################               [U-43] NIS , NIS+ 점검               ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: NIS 서비스가 비활성화 되어 있거나, 필요 시 NIS+를 사용하는 경우 양호"            >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ NIS, NIS+ 동작 확인"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
SERVICE="ypserv|ypbind|ypxfrd|rpc.yppasswdd|rpc.ypupdated|rpc.nids"

if [ `ps -ef | $GREP_CMD $SERVICE | grep -v "grep" | wc -l` -eq 0 ]
then
	echo " - NIS, NIS+ 서비스가 비활성화 상태입니다."                                                        >> $HOSTNAME.linux.result.txt 2>&1
	flag="Disabled"
else
	echo "    NIS+ 데몬 rpc.nids로 구동"														   >> $HOSTNAME.linux.result.txt 2>&1
	ps -ef | $GREP_CMD $SERVICE | grep -v "grep"                                                   >> $HOSTNAME.linux.result.txt 2>&1
	if [ `ps -ef | grep "rpc.nids" | grep -v "grep" | wc -l` -eq 0 ]
	then
		flag1="Enabled"
	else
		flag1="nis+"
	fi
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################              tftp, talk 서비스 비활성화              ##################"
echo "##################           [U-44] tftp, talk 서비스 비활성화          ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: tftp, talk, ntalk 서비스가 구동 중이지 않을 경우에 양호"                         >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="tftp" {print $1 "   " $2}' | grep "udp"                    >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="talk" {print $1 "   " $2}' | grep "udp"                    >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="ntalk" {print $1 "  " $2}' | grep "udp"                    >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 서비스 포트 활성화 여부 확인"                                                         >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="tftp" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="tftp" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > 1.56.txt
	fi
fi
if [ `cat /etc/services | awk -F" " '$1=="talk" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="talk" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > 1.56.txt
	fi
fi
if [ `cat /etc/services | awk -F" " '$1=="ntalk" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="ntalk" {print $1 "   " $2}' | grep "udp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^udp"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                   > 1.56.txt
	fi
fi

if [ -f 1.56.txt ]
then
	rm -rf 1.56.txt
	flag="Enabled"
else
	echo " - tftp, talk, ntalk 서비스가 비활성화 상태입니다."                                                  >> $HOSTNAME.linux.result.txt 2>&1
	flag="Disabled"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                 메일 서비스 버전 점검                ##################"
echo "##################             [U-45] 메일 서비스 버전 점검             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 메일 서비스 버전이 최신 버전인 경우 양호"                                            >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ sendmail 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep sendmail | grep -v grep | wc -l` -gt 0 ]
then
	flag1="M/T"
	ps -ef | grep sendmail | grep -v grep																			                   >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                  	 >> $HOSTNAME.linux.result.txt 2>&1

	echo "☞ sendmail 버전 확인"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/mail/sendmail.cf ]
	   then
	     grep -v '^ *#' /etc/mail/sendmail.cf | grep DZ                                          >> $HOSTNAME.linux.result.txt 2>&1
	   else
	     echo " - /etc/mail/sendmail.cf 파일이 없습니다."                                           >> $HOSTNAME.linux.result.txt 2>&1
	fi
	else
	echo " - Sendmail 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
	flag1="Disabled"
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ postfix 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep postfix | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep postfix | grep -v grep													>> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                  	 >> $HOSTNAME.linux.result.txt 2>&1

	echo "☞ postfix 버전 확인"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	postconf mail_version			                                                         >> $HOSTNAME.linux.result.txt 2>&1
else
	echo " - Postfix 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ exim 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep exim | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep exim | grep -v grep																			                   >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                  	 >> $HOSTNAME.linux.result.txt 2>&1

	echo "☞ exim 버전 확인"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	exim -bV | head -n 1                                                                >> $HOSTNAME.linux.result.txt 2>&1
else
	echo " - Exim 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo ""
echo "[참고]"                                                                              	   >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 포트 확인"                                                     	 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp"                    >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 서비스 포트 활성화 여부 확인"                                                        		 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - SMTP 서비스가 비활성화 되어 있습니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - 서비스 포트를 확인할 수 없습니다." 				                                                         >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################           일반 사용자의 메일 서비스 실행 방지          ##################"
echo "##################       [U-46] 일반 사용자의 메일 서비스 실행 방지       ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 일반 사용자의 메일 서비스 실행 방지가 설정된 경우 양호"             >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ sendmail 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep sendmail | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep sendmail | grep -v grep														>> $HOSTNAME.linux.result.txt 2>&1
	flag1="Enabled"
	echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ /etc/mail/sendmail.cf 파일 설정 확인"                                             >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/mail/sendmail.cf ]
	  then
	    grep -v '^ *#' /etc/mail/sendmail.cf | grep PrivacyOptions                               >> $HOSTNAME.linux.result.txt 2>&1
	    flag2=`grep -v '^ *#' /etc/mail/sendmail.cf | grep PrivacyOptions | grep restrictqrun | wc -l`
	  else
	    echo " - /etc/mail/sendmail.cf 파일이 없습니다."                                            >> $HOSTNAME.linux.result.txt 2>&1
	    flag2="Null"
	fi
else
	echo " - Sendmail 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
	flag1="Disabled"
	flag2="Disabled"
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ postfix 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep postfix | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep postfix | grep -v grep													>> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                  	 >> $HOSTNAME.linux.result.txt 2>&1

	echo "☞ postfix 실행 권한 확인"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /usr/sbin/postsuper ]
	  then
		printf "(%s) " $($STAT_CMD /usr/sbin/postsuper 2>/dev/null || stat -f %Lp /usr/sbin/postsuper 2>/dev/null) >> $HOSTNAME.linux.result.txt
	    ls -l /usr/sbin/postsuper  >> $HOSTNAME.linux.result.txt 2>&1 
	  else
	    echo " - /usr/sbin/postsuper 파일이 없습니다."                                            >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - Postfix 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ exim 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep exim | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep exim | grep -v grep																			                   >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                  	 >> $HOSTNAME.linux.result.txt 2>&1

	echo "☞ exim 실행 권한 확인"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /usr/sbin/exiqgrep ]
	  then
		printf "(%s) " $($STAT_CMD /usr/sbin/exiqgrep 2>/dev/null || stat -f %Lp /usr/sbin/exiqgrep 2>/dev/null) >> $HOSTNAME.linux.result.txt
	    ls -l /usr/sbin/exiqgrep  >> $HOSTNAME.linux.result.txt 2>&1 
	  else
	    echo " - /usr/sbin/exiqgrep 파일이 없습니다."                                            >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - Exim 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo ""
echo "[참고]"                                                                              	   >> $HOSTNAME.linux.result.txt 2>&1
echo "/etc/services 파일 포트 확인"                                                    		 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp"                    >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "서비스 포트 활성화 여부 확인"                                                        		 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - SMTP 서비스가 비활성화 되어 있습니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - 서비스 포트를 확인할 수 없습니다." 				                                                         >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                 스팸 메일 릴레이 제한                ##################"
echo "##################             [U-47] 스팸 메일 릴레이 제한             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: SMTP 서비스 릴레이 제한이 설정된 경우 양호"             >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ sendmail 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep sendmail | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep sendmail | grep -v grep																			                   >> $HOSTNAME.linux.result.txt 2>&1
	flag1="Enabled"
	echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ /etc/mail/sendmail.cf 파일의 설정 확인"                                             >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/mail/sendmail.cf ]
	  then
	    cat /etc/mail/sendmail.cf | grep "R$\*" | $GREP_CMD "Relaying denied"                         >> $HOSTNAME.linux.result.txt 2>&1
	    flag2=`cat /etc/mail/sendmail.cf | grep "R$\*" | $GREP_CMD "Relaying denied" | grep -v "^#" | wc -l`
	  else
	    echo " - /etc/mail/sendmail.cf 파일이 없습니다."                                            >> $HOSTNAME.linux.result.txt 2>&1
	    flag2="Null"
	fi
	echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
else
	echo " - Sendmail 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
	flag1="Disabled"
	flag2="Disabled"
echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
fi

echo "☞ postfix 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep postfix | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep postfix | grep -v grep													>> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                  	 >> $HOSTNAME.linux.result.txt 2>&1

	echo "☞ /etc/postfix/main.cf 파일의 설정 확인"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/postfix/main.cf ]
	  then
	    if [ $(cat /etc/postfix/main.cf | $GREP_CMD "smtpd_recipient_restrictions|mynetworks" | grep -v "^#" | wc -l) -gt 0 ]
		then
			cat /etc/postfix/main.cf | $GREP_CMD "smtpd_recipient_restrictions|mynetworks"| grep -v "^#"   >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - smtpd_recipient_restrictions, mynetworks 설정이 없습니다."                		>> $HOSTNAME.linux.result.txt 2>&1
		fi
	  else
	    echo " - /etc/postfix/main.cf 파일이 없습니다."                                            >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - Postfix 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ exim 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep exim | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep exim | grep -v grep																			                   >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                  	 >> $HOSTNAME.linux.result.txt 2>&1

	echo "☞ /etc/exim/exim.conf 파일의 설정 확인"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/exim/exim.conf ]
	  then
		if [ $(cat /etc/exim/exim.conf | $GREP_CMD "relay_from_hosts|hosts ="| grep -v "^#" | wc -l) -gt 0 ]
		then
			cat /etc/exim/exim.conf | $GREP_CMD "relay_from_hosts"| grep -v "^#"   >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - relay_from_hosts 설정이 없습니다."                                                                >> $HOSTNAME.linux.result.txt 2>&1
		fi

	  else
	    echo " - /etc/exim/exim.conf 파일이 없습니다."                                            >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - Exim 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo ""
echo "[참고]"                                                                              	   >> $HOSTNAME.linux.result.txt 2>&1
echo "※ Sendmail 8.9 이상 버전부터는 기본적으로 스팸 메일 릴레이 제한 설정이 적용됨"                	   >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ /etc/services 파일 포트 확인"                                                    		 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp"                    >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 서비스 포트 활성화 여부 확인"                                                       	   >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]
then
	port=`cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`;
	if [ `$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp" | wc -l` -gt 0 ]
	then
		$NETSTAT_CMD -na | grep ":$port " | grep -i "^tcp"                                              >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - SMTP 서비스가 비활성화 되어 있습니다."                                                         >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - 서비스 포트를 확인할 수 없습니다." 				                                                         >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                expn, vrfy 명령어 제한               ##################"
echo "##################            [U-48] expn, vrfy 명령어 제한            ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: SMTP 서비스 noexpn, novrfy 옵션이 설정된 경우"     >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ sendmail 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep sendmail | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep sendmail | grep -v grep													>> $HOSTNAME.linux.result.txt 2>&1

	echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ /etc/mail/sendmail.cf 파일의 설정	확인"                                               >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/mail/sendmail.cf ]
	then
		if [ `grep -v '^ *#' /etc/mail/sendmail.cf | $GREP_CMD "PrivacyOptions|noexpn|goaway" | wc -l` -gt 0 ]
		then
			grep -v '^ *#' /etc/mail/sendmail.cf | $GREP_CMD "PrivacyOptions|noexpn|goaway"        >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - noexpn, novrfy, goaway 설정이 없습니다."                                >> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		echo " - /etc/mail/sendmail.cf 파일이 없습니다."                                >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - Sendmail 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ postfix 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep postfix | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep postfix | grep -v grep													>> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                  	 >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ /etc/postfix/main.cf 파일의 설정 확인"                                               >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/postfix/main.cf ]
	then
		if [ `grep -v '^ *#' /etc/postfix/main.cf | grep disable_vrfy_command | wc -l` -gt 0 ]
		then
			grep -v '^ *#' /etc/postfix/main.cf | grep disable_vrfy_command        >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - vrfy 설정이 없습니다."                                >> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		echo " - /etc/postfix/main.cf 파일이 없습니다."                                >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - Postfix 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ exim 프로세스 확인"                                    					                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep exim | grep -v grep | wc -l` -gt 0 ]
then
	ps -ef | grep exim | grep -v grep													>> $HOSTNAME.linux.result.txt 2>&1

	if [ -f /etc/exim/exim.conf ]
	then
		echo " "                                                                                  	 >> $HOSTNAME.linux.result.txt 2>&1
		echo "☞ /etc/exim/exim.conf 파일의 설정 확인"                                               >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"        >> $HOSTNAME.linux.result.txt 2>&1
		if [ `grep -v '^ *#' /etc/exim/exim.conf | $GREP_CMD "expn|vrfy" | wc -l` -gt 0 ]
		then
			grep -v '^ *#' /etc/exim/exim.conf | $GREP_CMD "expn|vrfy"        >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - expn, vrfy 설정이 없습니다."                                >> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		echo " - /etc/exim/exim.conf 파일이 없습니다."                                              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - Exim 서비스가 비활성화 상태입니다."                                                           >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo ""
echo "[참고]"                                                                              	   >> $HOSTNAME.linux.result.txt 2>&1
echo "※ Postfix는 기본적으로 expn 기능 및 설정을 허용하지 않음"                                 >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                  DNS 보안 버전 패치                 ##################"
echo "##################              [U-49] DNS 보안 버전 패치              ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 주기적으로 DNS 서비스의 패치를 관리하는 경우"           >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
DNSPR=`ps -ef | grep named | grep -v "grep" | awk 'BEGIN{ OFS="\n"} {i=1; while(i<=NF) {print $i; i++}}'| grep "/" | uniq`
DNSPR=`echo $DNSPR | awk '{print $1}'`

echo "☞ DNS 프로세스 확인 " >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

# 1. 프로세스 존재 여부 체크
if [ `ps -ef | grep named | grep -v grep | wc -l` -gt 0 ]
then
    flag1="M/T"
    # [수정] 파일 존재 여부와 상관없이 일단 프로세스 정보는 기록
    ps -ef | grep named | grep -v "grep" >> $HOSTNAME.linux.result.txt 2>&1
    echo " " >> $HOSTNAME.linux.result.txt 2>&1

    echo "☞ BIND 버전 확인" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    
    # 2. 실행 파일이 존재하는 경우에만 버전 확인 시도
    if [ -f "$DNSPR" ]
    then
        $DNSPR -v | grep BIND >> $HOSTNAME.linux.result.txt 2>&1
    else
        # [수정] 프로세스는 있지만 실행 파일을 특정할 수 없는 경우에 대한 명확한 메시지
        echo " - 실행 파일($DNSPR)을 찾을 수 없어 버전을 확인할 수 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    fi
else
    echo " - DNS 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1
    flag1="Disabled"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################               DNS Zone Transfer 설정               ##################"
echo "##################            [U-50] DNS Zone Transfer 설정           ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: : Zone Transfer를 허가된 사용자에게만 허용한 경우"           >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ DNS 프로세스 확인 " >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep named | grep -v "grep" | wc -l` -eq 0 ]
then
	echo " - DNS 서비스가 비활성화 상태입니다."                                                                >> $HOSTNAME.linux.result.txt 2>&1
	flag1="Disabled"
else
	ps -ef | grep named | grep -v "grep"                                                         >> $HOSTNAME.linux.result.txt 2>&1
	flag1="M/T"
	if [ `ls -al /etc/rc*.d/* | grep -i named | grep "/S" | wc -l` -gt 0 ]
	then
		ls -al /etc/rc*.d/* | grep -i named | grep "/S"                                              >> $HOSTNAME.linux.result.txt 2>&1
	fi
	echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ /etc/named.conf 파일의 allow-transfer 확인"                                           >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/named.conf ]; then
		if grep 'allow-transfer' /etc/named.conf; then
			cat /etc/named.conf | grep 'allow-transfer' 						>> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - allow-transfer 설정이 없습니다." 									>> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		echo " - /etc/named.conf 파일이 없습니다." 											>> $HOSTNAME.linux.result.txt 2>&1
	fi
	echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ /etc/named.boot 파일의 xfrnets 확인"                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/named.boot ]; then
		if cat /etc/named.boot | grep "xfrnets"; then
		cat /etc/named.boot | grep 'xfrnets'								>> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - xfrnets 설정이 없습니다."												>> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		echo " - /etc/named.boot 파일이 없습니다."                                                      >> $HOSTNAME.linux.result.txt 2>&1
	fi
	echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ /etc/named.rfc1912.zones 파일 확인 (zone 별 설정)"                               >> $HOSTNAME.linux.result.txt
	echo "-------------------------------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt
	if [ -f /etc/named.rfc1912.zones ]
	then
		if [ `cat /etc/named.rfc1912.zones | grep -i 'allow-transfer' | wc -l` -eq 0 ]
		then
			echo " - allow-transfer 설정이 없습니다."														>> $HOSTNAME.linux.result.txt
		else
			cat /etc/named.rfc1912.zones | grep -i 'allow-transfer'									>> $HOSTNAME.linux.result.txt
		fi
	else
		echo " - /etc/named.rfc1912.zones 파일이 없습니다."                                                    >> $HOSTNAME.linux.result.txt
	fi
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################       DNS 서비스의 취약한 동적 업데이트 설정 금지       ##################"
echo "##################    [U-51] DNS 서비스의 취약한 동적 업데이트 설정 금지   ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: DNS 서비스의 동적 업데이트 기능이 비활성화되었거나, 활성화 시 적절한 접근통제를 수행하고 있는 경우 양호"                                            >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ DNS 프로세스 확인 " >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep named | grep -v "grep" | wc -l` -eq 0 ]
then
	echo " - DNS 서비스가 비활성화 상태입니다."                                                                >> $HOSTNAME.linux.result.txt 2>&1
else
	if [ `ls -al /etc/rc*.d/* | grep -i named | grep "/S" | wc -l` -gt 0 ]
	then
		ls -al /etc/rc*.d/* | grep -i named | grep "/S"                                              >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
	fi
	ps -ef | grep named | grep -v "grep"                                                         >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1

	echo "☞ /etc/named.conf 파일 확인"                                                              >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/named.conf ]
	then
		if [ `cat /etc/named.conf | grep allow-update | wc -l` -gt 0 ]
		then
			cat /etc/named.conf | grep allow-update                                                    >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - allow-update 설정이 없습니다."                        >> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		echo " - /etc/named.conf 파일이 없습니다."                       >> $HOSTNAME.linux.result.txt 2>&1
	fi
	echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ /etc/named.rfc1912.zones 파일 확인 (zone 별 설정)"                                                              >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	if [ -f /etc/named.rfc1912.zones ]
	then
		if [ `cat /etc/named.rfc1912.zones | grep allow-update | wc -l` -gt 0 ]
		then
			cat /etc/named.rfc1912.zones | grep allow-update                                                    >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - allow-update 설정이 없습니다."                        >> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		echo " - /etc/named.rfc1912.zones 파일이 없습니다."                       >> $HOSTNAME.linux.result.txt 2>&1
	fi
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
rm -rf dnscheck.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                Telnet 서비스 비활성화                ##################"
echo "##################            [U-52] Telnet 서비스 비활성화             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: Telnet 서비스가 비활성화되어 있으면 양호"                                            >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
RESULT_FILE="$HOSTNAME.linux.result.txt"

# 1. Telnet 점검 섹션
echo "☞ Telnet 서비스 포트 확인" >> $RESULT_FILE 2>&1
echo "----------------------------------------------------------------" >> $RESULT_FILE 2>&1
grep -w "telnet" /etc/services | awk '$2 ~ /tcp/ {print $1 "    " $2}' | head -n 1 >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE

echo "☞ Telnet 동작 확인" >> $RESULT_FILE 2>&1
echo "----------------------------------------------------------------" >> $RESULT_FILE 2>&1
# 서비스 활성화 여부 확인 (netstat 또는 ss 사용)
TELNET_LISTEN=$($NETSTAT_CMD -nat 2>/dev/null | grep -w "LISTEN" | grep -c ":23 ")

if [ "$TELNET_LISTEN" -gt 0 ]; then
    $NETSTAT_CMD -nat | grep -w "LISTEN" | grep ":23 " >> $RESULT_FILE 2>&1
else
    echo " - Telnet 서비스가 비활성화 상태입니다." >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE


# 2. SSH 점검 섹션
echo "☞ SSH 서비스 포트 확인" >> $RESULT_FILE 2>&1
echo "----------------------------------------------------------------" >> $RESULT_FILE 2>&1
# sshd_config에서 Port 설정 추출 (주석 제외)
SSH_PORT_CONF=$(grep -v '^#' /etc/ssh/sshd_config 2>/dev/null | grep -i "^Port" | awk '{print $2}')

if [ -z "$SSH_PORT_CONF" ]; then
    # 사용자가 원한 "Default 설정" 문구 출력
    echo " - SSH 포트 설정 없습니다. (Default 설정: 22포트 사용)" >> $RESULT_FILE 2>&1
    CHECK_PORT="22"
else
    # 별도 포트 설정이 있을 경우 출력
    echo "ssh    $SSH_PORT_CONF/tcp" >> $RESULT_FILE 2>&1
    CHECK_PORT="$SSH_PORT_CONF"
fi
echo "" >> $RESULT_FILE

echo "☞ SSH 동작 확인" >> $RESULT_FILE 2>&1
echo "----------------------------------------------------------------" >> $RESULT_FILE 2>&1
# SSH 서비스가 실제로 리스닝 중인지 확인
SSH_LISTEN=$($NETSTAT_CMD -nat 2>/dev/null | grep -w "LISTEN" | grep -c ":$CHECK_PORT ")

if [ "$SSH_LISTEN" -gt 0 ]; then
    # ss 명령어가 있으면 ss로 출력 (가독성이 더 좋음), 없으면 netstat 사용
    if command -v ss >/dev/null 2>&1; then
        ss -ltn | grep ":$CHECK_PORT\b" >> $RESULT_FILE 2>&1
    else
        $NETSTAT_CMD -nat | grep -w "LISTEN" | grep ":$CHECK_PORT " >> $RESULT_FILE 2>&1
    fi
else
    echo " - SSH 서비스가 비활성화 상태입니다." >> $RESULT_FILE 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################               FTP 서비스 정보 노출 제한              ##################"
echo "##################           [U-53] FTP 서비스 정보 노출 제한           ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: FTP 접속 배너에 노출되는 정보가 없는 경우 양호"                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 FTP 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="ftp" {print "  /etc/service 파일:" $1 " " $2}' | grep "tcp" | wc -l` -gt 0 ]
then
	cat /etc/services | awk -F" " '$1=="ftp" {print "/etc/service 파일:" $1 " " $2}' | grep "tcp" >> $HOSTNAME.linux.result.txt 2>&1
else
	echo "/etc/service 파일: 포트 설정 X (Default 21번 포트)"                                  >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s vsftpd.txt ]
then
	if [ `cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "VsFTP 포트: 포트 설정 X (Default 21번 포트 사용중)"                               >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - VsFTP가 설치되어 있지 않습니다."                                        >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s proftpd.txt ]
then
	if [ `cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}'    >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "ProFTP 포트 : 포트 설정 X (/etc/service 파일에 설정된 포트를 사용중)"              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - ProFTP가 설치되어 있지 않습니다."                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ FTP 포트 활성화 여부 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

# 취약 여부를 체크하기 위한 변수 (0: 양호, 1: 취약)
VULN=0
rm -f ftpenable.txt

################# 1. /etc/services 기준 포트 확인 #################
# 서비스 파일에서 포트 추출 (실패 시 21)
port=$(grep -w "^ftp" /etc/services 2>/dev/null | grep "/tcp" | awk '{print $2}' | cut -d'/' -f1 | head -1)
[ -z "$port" ] && port=21

# 해당 포트가 LISTEN 중인지 확인
check=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$port " | grep -i "LISTEN")
if [ -n "$check" ]; then
    echo "FTP 서비스 포트($port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
    echo "$check" >> $HOSTNAME.linux.result.txt 2>&1
    VULN=1
fi

################# 2. vsftpd 설정 확인 ############################
if [ -s vsftpd.txt ] && [ -n "$vsfile" ]; then
    v_port=$(grep "listen_port" "$vsfile" | awk -F"=" '{print $2}' | tr -d ' ')
    [ -z "$v_port" ] && v_port=21
    
    check_v=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$v_port " | grep -i "LISTEN")
    if [ -n "$check_v" ]; then
        echo "vsftpd 서비스 포트($v_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_v" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 3. proftpd 설정 확인 ###########################
if [ -s proftpd.txt ] && [ -n "$profile" ]; then
    p_port=$(grep "Port" "$profile" | awk '{print $2}' | tr -d ' ')
    [ -z "$p_port" ] && p_port=21
    
    check_p=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$p_port " | grep -i "LISTEN")
    if [ -n "$check_p" ]; then
        echo "proftpd 서비스 포트($p_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_p" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 4. 최종 예외 처리 (아무것도 발견 안 됨) ##########
if [ $VULN -eq 0 ]; then
    echo " - 모든 FTP 관련 포트가 비활성화되어 있습니다." >> $HOSTNAME.linux.result.txt 2>&1
else
    echo "ON" > ftpenable.txt
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

if [ -f ftpenable.txt ]
then
	rm -rf ftpenable.txt
	if [ -s vsftpd.txt ]
	then
		if [ `cat $vsfile | grep ftpd_banner | wc -l` -gt 0 ]
		then
			echo "☞ vsftpd.conf 파일의 ftpd_banner 설정 확인"                                         >> $HOSTNAME.linux.result.txt 2>&1
			echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
			cat $vsfile | grep ftpd_banner                            >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo "☞ vsftpd.conf 파일의 ftpd_banner 설정 확인"                                         >> $HOSTNAME.linux.result.txt 2>&1
			echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
			echo " - vsftpd.conf 파일에 ftpd_banner 설정이 없습니다."                               >> $HOSTNAME.linux.result.txt 2>&1
		fi
		echo " " >> $HOSTNAME.linux.result.txt 2>&1 
	fi

	if [ -s proftpd.txt ]
	then
		if [ `cat $profile | grep ServerIdent | wc -l` -gt 0 ]
		then
			echo "☞ proftpd.conf 파일의 ServerIdent 설정 확인"                                         >> $HOSTNAME.linux.result.txt 2>&1
			echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
			cat $profile | grep ServerIdent                            >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo "☞ proftpd.conf 파일의 ServerIdent 설정 확인"                                         >> $HOSTNAME.linux.result.txt 2>&1
			echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
			echo " - proftpd.conf 파일에 ServerIdent 설정이 없습니다."                               >> $HOSTNAME.linux.result.txt 2>&1
		fi
		echo " " >> $HOSTNAME.linux.result.txt 2>&1 
	fi
	
	# vsftpd, proftpd 둘 다 없을 때 기타 FTP 배너 확인
	if [ ! -s vsftpd.txt ] && [ ! -s proftpd.txt ]; then
    echo "☞ 기타 FTP 데몬 배너 확인 (/etc/ftpd.conf 또는 /etc/inetd.conf)"                                         >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
		if [ -f /etc/ftpd.conf ]; then
			grep -i "banner\|greeting" /etc/ftpd.conf   >> $HOSTNAME.linux.result.txt 2>&1
		elif [ -f /etc/inetd.conf ]; then
			grep -i "ftp" /etc/inetd.conf  >> $HOSTNAME.linux.result.txt 2>&1
		else
			echo " - 배너 설정 파일을 확인할 수 없습니다. (수동 점검 필요)"  >> $HOSTNAME.linux.result.txt 2>&1
		fi
	fi
else
	echo "☞ FTP 배너 설정 확인"                                         >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	echo " - FTP 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1
    flag1="Disabled"
    flag2="Disabled"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################          암호화 되지 않는 FTP 서비스 비활성화          ##################"
echo "##################      [U-54] 암호화 되지 않는 FTP 서비스 비활성화       ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 암호화되지 않은 ftp 서비스가 비활성화 되어 있을 경우 양호"                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 FTP 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="ftp" {print "  /etc/service 파일:" $1 " " $2}' | grep "tcp" | wc -l` -gt 0 ]
then
	cat /etc/services | awk -F" " '$1=="ftp" {print "/etc/service 파일:" $1 " " $2}' | grep "tcp" >> $HOSTNAME.linux.result.txt 2>&1
else
	echo "/etc/service 파일: 포트 설정 X (Default 21번 포트)"                                  >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s vsftpd.txt ]
then
	if [ `cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "VsFTP 포트: 포트 설정 X (Default 21번 포트 사용중)"                               >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - VsFTP가 설치되어 있지 않습니다."                                        >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s proftpd.txt ]
then
	if [ `cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}'    >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "ProFTP 포트 : 포트 설정 X (/etc/service 파일에 설정된 포트를 사용중)"              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - ProFTP가 설치되어 있지 않습니다."                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ FTP 포트 활성화 여부 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

# 취약 여부를 체크하기 위한 변수 (0: 양호, 1: 취약)
VULN=0
rm -f ftpenable.txt

################# 1. /etc/services 기준 포트 확인 #################
# 서비스 파일에서 포트 추출 (실패 시 21)
port=$(grep -w "^ftp" /etc/services 2>/dev/null | grep "/tcp" | awk '{print $2}' | cut -d'/' -f1 | head -1)
[ -z "$port" ] && port=21

# 해당 포트가 LISTEN 중인지 확인
check=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$port " | grep -i "LISTEN")
if [ -n "$check" ]; then
    echo "FTP 서비스 포트($port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
    echo "$check" >> $HOSTNAME.linux.result.txt 2>&1
    VULN=1
fi

################# 2. vsftpd 설정 확인 ############################
if [ -s vsftpd.txt ] && [ -n "$vsfile" ]; then
    v_port=$(grep "listen_port" "$vsfile" | awk -F"=" '{print $2}' | tr -d ' ')
    [ -z "$v_port" ] && v_port=21
    
    check_v=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$v_port " | grep -i "LISTEN")
    if [ -n "$check_v" ]; then
        echo "vsftpd 서비스 포트($v_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_v" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 3. proftpd 설정 확인 ###########################
if [ -s proftpd.txt ] && [ -n "$profile" ]; then
    p_port=$(grep "Port" "$profile" | awk '{print $2}' | tr -d ' ')
    [ -z "$p_port" ] && p_port=21
    
    check_p=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$p_port " | grep -i "LISTEN")
    if [ -n "$check_p" ]; then
        echo "proftpd 서비스 포트($p_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_p" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 4. 최종 예외 처리 (아무것도 발견 안 됨) ##########
if [ $VULN -eq 0 ]; then
    echo " - 모든 FTP 관련 포트가 비활성화되어 있습니다." >> $HOSTNAME.linux.result.txt 2>&1
else
    echo "ON" > ftpenable.txt
fi

echo " " 																					>> $HOSTNAME.linux.result.txt 2>&1

if [ -f ftpenable.txt ]
then
    rm -rf ftpenable.txt
    flag1="Enabled"

    if [ -s vsftpd.txt ] && [ -f "$vsfile" ]; then
        VS_SSL_VAL=`grep -i "^ssl_enable" "$vsfile" | grep -v "^#" | head -n 1`
        echo "☞ FTPS(SSL/TLS) 활성화 여부 및 설정 확인 (Vsftpd 기반)"                                           >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"                      >> $HOSTNAME.linux.result.txt 2>&1
        if [ -n "$VS_SSL_VAL" ]; then
            echo "FTPS(VsFTP SSL): Enabled [ $VS_SSL_VAL ]"                              >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - FTPS(VsFTP SSL) 설정이 없습니다."                                            >> $HOSTNAME.linux.result.txt 2>&1
        fi
		echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi

    if [ -s proftpd.txt ] && [ -f "$profile" ]; then
        PRO_SSL_VAL=`grep -i "TLSEngine" "$profile" | grep -v "^#" | head -n 1`
        echo "☞ FTPS(SSL/TLS) 활성화 여부 및 설정 확인 (ProFTPD 기반)"                                           >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"                      >> $HOSTNAME.linux.result.txt 2>&1
		if [ -n "$PRO_SSL_VAL" ]; then
            echo "FTPS(ProFTP TLS): Enabled [ $PRO_SSL_VAL ]"                             >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - FTPS(ProFTP TLS) 설정이 없습니다."                                           >> $HOSTNAME.linux.result.txt 2>&1
        fi
		echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi
else
    echo "☞ FTP 서비스 점검"                                                                      >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------"                          >> $HOSTNAME.linux.result.txt 2>&1
    echo " - FTP 서비스가 비활성화 상태입니다."                                  >> $HOSTNAME.linux.result.txt 2>&1
    flag1="Disabled"
fi

echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1




echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                 ftp 계정 shell 제한                 ##################"
echo "##################             [U-55] ftp 계정 shell 제한              ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: ftp 서비스 사용 시 ftp 계정에 /bin/false 쉘을 부여하면 양호"                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 FTP 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="ftp" {print "  /etc/service 파일:" $1 " " $2}' | grep "tcp" | wc -l` -gt 0 ]
then
	cat /etc/services | awk -F" " '$1=="ftp" {print "/etc/service 파일:" $1 " " $2}' | grep "tcp" >> $HOSTNAME.linux.result.txt 2>&1
else
	echo "/etc/service 파일: 포트 설정 X (Default 21번 포트)"                                  >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s vsftpd.txt ]
then
	if [ `cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "VsFTP 포트: 포트 설정 X (Default 21번 포트 사용중)"                               >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - VsFTP가 설치되어 있지 않습니다."                                        >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s proftpd.txt ]
then
	if [ `cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}'    >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "ProFTP 포트 : 포트 설정 X (/etc/service 파일에 설정된 포트를 사용중)"              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - ProFTP가 설치되어 있지 않습니다."                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ FTP 포트 활성화 여부 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

# 취약 여부를 체크하기 위한 변수 (0: 양호, 1: 취약)
VULN=0
rm -f ftpenable.txt

################# 1. /etc/services 기준 포트 확인 #################
# 서비스 파일에서 포트 추출 (실패 시 21)
port=$(grep -w "^ftp" /etc/services 2>/dev/null | grep "/tcp" | awk '{print $2}' | cut -d'/' -f1 | head -1)
[ -z "$port" ] && port=21

# 해당 포트가 LISTEN 중인지 확인
check=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$port " | grep -i "LISTEN")
if [ -n "$check" ]; then
    echo "FTP 서비스 포트($port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
    echo "$check" >> $HOSTNAME.linux.result.txt 2>&1
    VULN=1
fi

################# 2. vsftpd 설정 확인 ############################
if [ -s vsftpd.txt ] && [ -n "$vsfile" ]; then
    v_port=$(grep "listen_port" "$vsfile" | awk -F"=" '{print $2}' | tr -d ' ')
    [ -z "$v_port" ] && v_port=21
    
    check_v=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$v_port " | grep -i "LISTEN")
    if [ -n "$check_v" ]; then
        echo "vsftpd 서비스 포트($v_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_v" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 3. proftpd 설정 확인 ###########################
if [ -s proftpd.txt ] && [ -n "$profile" ]; then
    p_port=$(grep "Port" "$profile" | awk '{print $2}' | tr -d ' ')
    [ -z "$p_port" ] && p_port=21
    
    check_p=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$p_port " | grep -i "LISTEN")
    if [ -n "$check_p" ]; then
        echo "proftpd 서비스 포트($p_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_p" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 4. 최종 예외 처리 (아무것도 발견 안 됨) ##########
if [ $VULN -eq 0 ]; then
    echo " - 모든 FTP 관련 포트가 비활성화되어 있습니다." >> $HOSTNAME.linux.result.txt 2>&1
else
    echo "ON" > ftpenable.txt
fi

echo " " 																					>> $HOSTNAME.linux.result.txt 2>&1

if [ -f ftpenable.txt ]
then
	rm -rf ftpenable.txt
	flag1="Enabled"

	echo "☞ ftp 계정 쉘 확인(ftp 계정에 false 또는 nologin 설정시 양호)"                          >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	if [ `cat /etc/passwd | awk -F: '$1=="ftp"' | wc -l` -gt 0 ]
	then
		cat /etc/passwd | awk -F: '$1=="ftp"'                                                        >> $HOSTNAME.linux.result.txt 2>&1
		flag2=`cat /etc/passwd | awk -F: '$1=="ftp" {print $7}' | $GREP_CMD -v "nologin|false" | wc -l | sed -e 's/^ *//g' -e 's/ *$//g'`
	else
		echo " - ftp 계정이 존재하지 않습니다."                                                       >> $HOSTNAME.linux.result.txt 2>&1
		flag2=`cat /etc/passwd | awk -F: '$1=="ftp"' | wc -l | sed -e 's/^ *//g' -e 's/ *$//g'`
	fi

else
	echo "☞ ftp 계정 쉘 확인(ftp 계정에 false 또는 nologin 설정시 양호)"                          >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	echo " - FTP 서비스가 비활성화 상태입니다."                                                                >> $HOSTNAME.linux.result.txt 2>&1
	flag1="Disabled"
	flag2="Disabled"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################               FTP 서비스 접근 제어 설정              ##################"
echo "##################           [U-56] FTP 서비스 접근 제어 설정           ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: FTP 접근 제어 파일의 경우 소유자를 root로, 권한을 640 미만으로 설정하고,"                     >> $HOSTNAME.linux.result.txt 2>&1
echo "■      특정 IP주소 또는 호스트에서만 FTP 서버에 접속할 수 있도록 접근 제어 설정을 적용한 경우 양호"                    >> $HOSTNAME.linux.result.txt 2>&1
echo "■      [FTP 종류별 적용되는 파일]"                                                    >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (1)ftpd: /etc/ftpusers 또는 /etc/ftpd/ftpusers"                                >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (2)proftpd: /etc/ftpusers 또는 /etc/ftpd/ftpusers"                             >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (3)vsftpd: /etc/vsftpd/ftpusers, /etc/vsftpd/user_list (또는 /etc/vsftpd.ftpusers, /etc/vsftpd.user_list)" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 FTP 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="ftp" {print "  /etc/service 파일:" $1 " " $2}' | grep "tcp" | wc -l` -gt 0 ]
then
	cat /etc/services | awk -F" " '$1=="ftp" {print "/etc/service 파일:" $1 " " $2}' | grep "tcp" >> $HOSTNAME.linux.result.txt 2>&1
else
	echo "/etc/service 파일: 포트 설정 X (Default 21번 포트)"                                  >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s vsftpd.txt ]
then
	if [ `cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "VsFTP 포트: 포트 설정 X (Default 21번 포트 사용중)"                               >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - VsFTP가 설치되어 있지 않습니다."                                        >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s proftpd.txt ]
then
	if [ `cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}'    >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "ProFTP 포트 : 포트 설정 X (/etc/service 파일에 설정된 포트를 사용중)"              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - ProFTP가 설치되어 있지 않습니다."                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ FTP 포트 활성화 여부 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

# 취약 여부를 체크하기 위한 변수 (0: 양호, 1: 취약)
VULN=0
rm -f ftpenable.txt

################# 1. /etc/services 기준 포트 확인 #################
# 서비스 파일에서 포트 추출 (실패 시 21)
port=$(grep -w "^ftp" /etc/services 2>/dev/null | grep "/tcp" | awk '{print $2}' | cut -d'/' -f1 | head -1)
[ -z "$port" ] && port=21

# 해당 포트가 LISTEN 중인지 확인
check=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$port " | grep -i "LISTEN")
if [ -n "$check" ]; then
    echo "FTP 서비스 포트($port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
    echo "$check" >> $HOSTNAME.linux.result.txt 2>&1
    VULN=1
fi

################# 2. vsftpd 설정 확인 ############################
if [ -s vsftpd.txt ] && [ -n "$vsfile" ]; then
    v_port=$(grep "listen_port" "$vsfile" | awk -F"=" '{print $2}' | tr -d ' ')
    [ -z "$v_port" ] && v_port=21
    
    check_v=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$v_port " | grep -i "LISTEN")
    if [ -n "$check_v" ]; then
        echo "vsftpd 서비스 포트($v_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_v" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 3. proftpd 설정 확인 ###########################
if [ -s proftpd.txt ] && [ -n "$profile" ]; then
    p_port=$(grep "Port" "$profile" | awk '{print $2}' | tr -d ' ')
    [ -z "$p_port" ] && p_port=21
    
    check_p=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$p_port " | grep -i "LISTEN")
    if [ -n "$check_p" ]; then
        echo "proftpd 서비스 포트($p_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_p" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 4. 최종 예외 처리 (아무것도 발견 안 됨) ##########
if [ $VULN -eq 0 ]; then
    echo " - 모든 FTP 관련 포트가 비활성화되어 있습니다." >> $HOSTNAME.linux.result.txt 2>&1
else
    echo "ON" > ftpenable.txt
fi

echo " " 																					>> $HOSTNAME.linux.result.txt 2>&1

ftpcfiles=()
if [ -f ftpenable.txt ]
then
    rm -rf ftpenable.txt
    flag1="Enabled"

echo "☞ FTP 접근 제어 파일 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
ServiceDIR="/etc/ftpusers /etc/ftpd/ftpusers /etc/vsftpd/ftpusers /etc/vsftpd.ftpusers /etc/vsftpd/user_list /etc/vsftpd.user_list /etc/proftpd.conf /etc/proftpd/proftpd.conf"
for file in $ServiceDIR
do
    if [ -f $file ]
    then
        perm_num=$(stat -c "%a" $file)
        ls_result=$(ls -alL $file)
        echo "($perm_num) $ls_result" >> ftpusers.txt
        ftpcfiles+=("$file")
    fi
done

if [ `cat ftpusers.txt 2>/dev/null | wc -l` -gt 0 ]
then
    cat ftpusers.txt | grep -v "^ *$" >> $HOSTNAME.linux.result.txt 2>&1
    for file2 in `awk -F" " '{print $10}' ftpusers.txt`
    do
        perm_val=$(stat -c "%a" $file2)
        owner=$(ls -l $file2 | awk '{print $3}')
        if [ "$perm_val" -gt 640 -o "$owner" != "root" ]
        then
            flag2="F"
            break
        else
            flag2="O"
        fi
    done
else
    echo " - FTP 접근 제어 파일을 찾을 수 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    flag2="F"
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

    # vsftpd pam sense 설정
    if [ -s vsftpd.txt ]
    then
        echo "☞ FTP 접근 제어 설정(vsftpd PAM sense 설정 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        cat /etc/pam.d/vsftpd | grep sense >> $HOSTNAME.linux.result.txt 2>&1
        echo " " >> $HOSTNAME.linux.result.txt 2>&1

        # vsftpd userlist_enable 설정
        echo "☞ FTP 접근 제어 설정(vsftpd userlist 설정 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        if [ `cat $vsfile | grep userlist_enable | grep -v "^#" | wc -l` -gt 0 ]
        then
            cat $vsfile | grep userlist_enable | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - $vsfile 파일에 userlist_enable, user_list deny 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi

    # proftpd UseFtpUsers 설정
    if [ -s proftpd.txt ]
    then
        echo "☞ FTP 접근 제어 설정(proftpd UseFtpUsers 설정 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        if [ `cat $profile | grep UseFtpUsers | grep -v "^#" | wc -l` -gt 0 ]
        then
            cat $profile | grep UseFtpUsers | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - $profile 파일에 UseFtpUsers 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi

    # 파일별 접근 제어 내용 출력
    for file in "${ftpcfiles[@]}"
    do
        if [[ "$file" == "/etc/proftpd.conf" || "$file" == "/etc/proftpd/proftpd.conf" ]]
        then
            if [ `sed -n '/<Limit LOGIN/,/<\/Limit>/p' "$file" | wc -l` -gt 0 ]
            then
                echo "☞ FTP 접근 제어 설정 확인(proftpd Limit LOGIN 설정 확인)" >> $HOSTNAME.linux.result.txt 2>&1
                echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
                sed -n '/<Limit LOGIN/,/<\/Limit>/p' "$file" >> $HOSTNAME.linux.result.txt 2>&1
            else
                echo "☞ FTP 접근 제어 설정 확인(proftpd Limit LOGIN 설정 확인)" >> $HOSTNAME.linux.result.txt 2>&1
                echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
                echo " - $file 파일에 계정 접근 제어 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
            fi
        else
            if [ `cat "$file" | grep -v "^#" | grep -v "^$" | wc -l` -gt 0 ]
            then
                echo "☞ FTP 접근 계정 확인($file)" >> $HOSTNAME.linux.result.txt 2>&1
                echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
                $GREP_CMD -v "^#|^$" $file >> $HOSTNAME.linux.result.txt 2>&1
            else
                echo "☞ FTP 접근 계정 확인($file)" >> $HOSTNAME.linux.result.txt 2>&1
                echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
                echo " - $file 파일에 등록되어 있는 계정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
            fi
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    done

else
    echo "☞ FTP 접근 제어 파일 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
	echo " - FTP 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1
    flag1="Disabled"
    flag2="Disabled"
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
rm -rf ftpusers.txt
rm -rf check.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                  Ftpusers 파일 설정                 ##################"
echo "##################              [U-57] Ftpusers 파일 설정              ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: FTP 사용 시 root 계정의 접속을 차단하고 있는 경우 양호"        >> $HOSTNAME.linux.result.txt 2>&1
echo "■      [FTP 종류별 적용되는 파일]"                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (1)ftpd: /etc/ftpusers 또는 /etc/ftpd/ftpusers"                >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (2)proftpd: /etc/ftpusers 또는 /etc/ftpd/ftpusers"             >> $HOSTNAME.linux.result.txt 2>&1
echo "■      (3)vsftpd: /etc/vsftpd/ftpusers, /etc/vsftpd/user_list"        >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/services 파일 FTP 포트 확인"                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `cat /etc/services | awk -F" " '$1=="ftp" {print "  /etc/service 파일:" $1 " " $2}' | grep "tcp" | wc -l` -gt 0 ]
then
	cat /etc/services | awk -F" " '$1=="ftp" {print "/etc/service 파일:" $1 " " $2}' | grep "tcp" >> $HOSTNAME.linux.result.txt 2>&1
else
	echo "/etc/service 파일: 포트 설정 X (Default 21번 포트)"                                  >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s vsftpd.txt ]
then
	if [ `cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $vsfile | grep "listen_port" | awk '{print "  VsFTP 포트: " $1 "  " $2}' >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "VsFTP 포트: 포트 설정 X (Default 21번 포트 사용중)"                               >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - VsFTP가 설치되어 있지 않습니다."                                        >> $HOSTNAME.linux.result.txt 2>&1
fi
if [ -s proftpd.txt ]
then
	if [ `cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}' | wc -l` -gt 0 ]
	then
		cat $profile | grep "Port" | awk '{print "  ProFTP 포트: " $1 "  " $2}'    >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo "ProFTP 포트 : 포트 설정 X (/etc/service 파일에 설정된 포트를 사용중)"              >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - ProFTP가 설치되어 있지 않습니다."                                      >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ FTP 포트 활성화 여부 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

# 취약 여부를 체크하기 위한 변수 (0: 양호, 1: 취약)
VULN=0
rm -f ftpenable.txt

################# 1. /etc/services 기준 포트 확인 #################
# 서비스 파일에서 포트 추출 (실패 시 21)
port=$(grep -w "^ftp" /etc/services 2>/dev/null | grep "/tcp" | awk '{print $2}' | cut -d'/' -f1 | head -1)
[ -z "$port" ] && port=21

# 해당 포트가 LISTEN 중인지 확인
check=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$port " | grep -i "LISTEN")
if [ -n "$check" ]; then
    echo "FTP 서비스 포트($port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
    echo "$check" >> $HOSTNAME.linux.result.txt 2>&1
    VULN=1
fi

################# 2. vsftpd 설정 확인 ############################
if [ -s vsftpd.txt ] && [ -n "$vsfile" ]; then
    v_port=$(grep "listen_port" "$vsfile" | awk -F"=" '{print $2}' | tr -d ' ')
    [ -z "$v_port" ] && v_port=21
    
    check_v=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$v_port " | grep -i "LISTEN")
    if [ -n "$check_v" ]; then
        echo "vsftpd 서비스 포트($v_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_v" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 3. proftpd 설정 확인 ###########################
if [ -s proftpd.txt ] && [ -n "$profile" ]; then
    p_port=$(grep "Port" "$profile" | awk '{print $2}' | tr -d ' ')
    [ -z "$p_port" ] && p_port=21
    
    check_p=$($NETSTAT_CMD -nat 2>/dev/null | grep ":$p_port " | grep -i "LISTEN")
    if [ -n "$check_p" ]; then
        echo "proftpd 서비스 포트($p_port/tcp) 활성화" >> $HOSTNAME.linux.result.txt 2>&1
        echo "$check_p" >> $HOSTNAME.linux.result.txt 2>&1
        VULN=1
    fi
fi

################# 4. 최종 예외 처리 (아무것도 발견 안 됨) ##########
if [ $VULN -eq 0 ]; then
    echo " - 모든 FTP 관련 포트가 비활성화되어 있습니다." >> $HOSTNAME.linux.result.txt 2>&1
else
    echo "ON" > ftpenable.txt
fi

echo " " 																					>> $HOSTNAME.linux.result.txt 2>&1

ftpcfiles=()
if [ -f ftpenable.txt ]
then
    rm -rf ftpenable.txt
    flag1="Enabled"

    # 접근 제어 파일 소유자 및 권한 확인
    echo " " >> $HOSTNAME.linux.result.txt 2>&1
    echo "☞ FTP 접근 제어 파일 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    ServiceDIR="/etc/ftpusers /etc/ftpd/ftpusers /etc/vsftpd/ftpusers /etc/vsftpd.ftpusers /etc/vsftpd/user_list /etc/vsftpd.user_list /etc/proftpd.conf /etc/proftpd/proftpd.conf"
    rm -f ftpusers.txt
    for file in $ServiceDIR
    do
        if [ -f $file ]
        then
            perm_num=$(stat -c "%a" $file)
            ls_result=$(ls -alL $file)
            echo "($perm_num) $ls_result" >> ftpusers.txt
            ftpcfiles+=("$file")
        fi
    done

    if [ `cat ftpusers.txt 2>/dev/null | wc -l` -gt 0 ]
    then
        cat ftpusers.txt | grep -v "^ *$" >> $HOSTNAME.linux.result.txt 2>&1
        for file2 in `awk -F" " '{print $10}' ftpusers.txt`
        do
            perm_val=$(stat -c "%a" $file2)
            owner=$(ls -l $file2 | awk '{print $3}')
            if [ "$perm_val" -gt 640 -o "$owner" != "root" ]
            then
                flag2="F"
                break
            else
                flag2="O"
            fi
        done
    else
        echo " - FTP 접근 제어 파일을 찾을 수 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        flag2="F"
    fi
    echo " " >> $HOSTNAME.linux.result.txt 2>&1

    # vsftpd PAM sense 설정
    if [ -s vsftpd.txt ]
    then
        echo "☞ FTP 접근 제어 설정(vsftpd PAM sense 설정 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        cat /etc/pam.d/vsftpd | grep sense >> $HOSTNAME.linux.result.txt 2>&1
        echo " " >> $HOSTNAME.linux.result.txt 2>&1

        # vsftpd userlist_enable 설정
        echo "☞ FTP 접근 제어 설정(vsftpd userlist 설정 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        if [ `cat $vsfile | grep userlist_enable | grep -v "^#" | wc -l` -gt 0 ]
        then
            cat $vsfile | grep userlist_enable | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - $vsfile 파일에 userlist_enable 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi

    # proftpd UseFtpUsers 설정
    if [ -s proftpd.txt ]
    then
        echo "☞ FTP 접근 제어 설정(proftpd UseFtpUsers 설정 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        if [ `cat $profile | grep UseFtpUsers | grep -v "^#" | wc -l` -gt 0 ]
        then
            cat $profile | grep UseFtpUsers | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - $profile 파일에 UseFtpUsers 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi

    # 파일별 root 계정 접근 제어 확인
    for file in "${ftpcfiles[@]}"
    do
        if [[ "$file" == "/etc/proftpd.conf" || "$file" == "/etc/proftpd/proftpd.conf" ]]
        then
            echo "☞ root 계정 접근 제어 확인($file)" >> $HOSTNAME.linux.result.txt 2>&1
            echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
            if [ `cat $file | grep "RootLogin" | grep -v "^#" | wc -l` -gt 0 ]
            then
                cat $file | grep "RootLogin" | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
                flag2=`cat $file | grep "RootLogin" | grep -v "^#"`
            else
                echo " - $file 파일에 root 계정 제한 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
                flag2="F"
            fi
        else
            echo "☞ FTP 접근 계정 확인($file)" >> $HOSTNAME.linux.result.txt 2>&1
            echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
            if [ `cat $file | grep "root" | grep -v "^#" | wc -l` -gt 0 ]
            then
                cat $file | grep "root" | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
                flag2=`cat $file | grep "root" | grep -v "^#"`
            else
                echo " - $file 파일에 root 계정이 등록되어 있지 않습니다." >> $HOSTNAME.linux.result.txt 2>&1
                flag2="F"
            fi
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    done

else
    echo "☞ FTP 접근 제어 파일 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    echo " - FTP 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1
    flag1="Disabled"
    flag2="Disabled"
fi

echo " "   >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]" >> $HOSTNAME.linux.result.txt 2>&1
echo " "   >> $HOSTNAME.linux.result.txt 2>&1

rm -rf ftpusers.txt
rm -rf check.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                 SNMP 서비스 구동 점검                ##################"
echo "##################             [U-58] SNMP 서비스 구동 점검             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: SNMP 서비스가 비활성화되어 있거나, SNMP 서비스를 불필요한 용도로 사용하지 않을 경우 양호"                           >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
# SNMP서비스는 동작시 /etc/service 파일의 포트를 사용하지 않음.
echo "☞ SNMP 서비스 활성화 여부 확인(UDP 161)"                                                >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `$NETSTAT_CMD -na | grep ":161 " | grep -i "^udp" | wc -l` -eq 0 ]
then
	echo " - SNMP 서비스가 비활성화 상태입니다."                                                               >> $HOSTNAME.linux.result.txt 2>&1
else
	$NETSTAT_CMD -na | grep ":161 " | grep -i "^udp"                                                  >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                 안전한 SNMP 버전 사용                ##################"
echo "##################             [U-59] 안전한 SNMP 버전 사용             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: SNMP 서비스를 v3 이상의 버전으로 사용하는 경우 양호"                         >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
snmpconf="/etc/snmpd.conf /etc/snmpdv3.conf /etc/snmp/snmpd.conf /etc/snmp/conf/snmpd.conf /etc/sma/snmp/snmpd.conf /etc/net-snmp/snmp/snmpd.conf /SI/CM/config/snmp/snmpd.conf"
echo "☞ SNMP 서비스 활성화 여부 확인(UDP 161)"                                                >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `$NETSTAT_CMD -na | grep ":161 " | grep -i "^udp" | wc -l` -eq 0 ]
then
	echo " - SNMP 서비스가 비활성화 상태입니다."                                                               >> $HOSTNAME.linux.result.txt 2>&1
else
	$NETSTAT_CMD -na | grep ":161 " | grep -i "^udp"                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ snmpd.conf 파일 설정"                                                        >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	v3_detected=0
	v2_detected=0

	for file in $snmpconf
	do
		if [ -f $file ]
		then
			cat $file | $GREP_CMD -v "^#|^$" | $GREP_CMD -i "public|private|community|com2sec|createuser|priv"   > snmpdconf.txt
			cat $file | $GREP_CMD -v "^#|^$" | $GREP_CMD -i "group|access|rouser|rwuser"   > snmpdaccess.txt
			echo "check"                                                                            > snmpd.txt
			if $GREP_CMD -i "createuser|priv" "$file"  >> /dev/null 2>&1
			then
				v3_detected=1
				cat snmpdaccess.txt >> snmpdconf.txt
			fi
			if $GREP_CMD -i "public|private|community" "$file" 	>> /dev/null 2>&1
			then
				v2_detected=1
			fi
		fi
	done

	if [ -f snmpd.txt ]
	then
		rm -rf snmpd.txt
	else
		echo " - snmpd.conf 파일이 없습니다."                                                          > snmpdconf.txt
		echo " "                                                                                     >> $HOSTNAME.linux.result.txt 2>&1
	fi

	cat snmpdconf.txt                                                                 >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

	echo "☞ SNMP 버전 확인"                                                    						 			   >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"       				   >> $HOSTNAME.linux.result.txt 2>&1
	if [ $v2_detected -eq 1 ]
	then
		echo "SNMPv1/v2c 활성화"																				 >> $HOSTNAME.linux.result.txt 2>&1
	fi

	if [ $v3_detected -eq 1 ]
	then
		echo "SNMPv3 활성화"																			 			>> $HOSTNAME.linux.result.txt 2>&1
	fi
	
	if [ $v2_detected -eq 0 ] && [ $v3_detected -eq 0 ]
	then
		echo " - SNMP 버전 설정을 확인할 수 없습니다. (수동 점검 필요)" >> $HOSTNAME.linux.result.txt 2>&1
	fi
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################         SNMP community string 복잡성 설정           ##################"
echo "##################      [U-60] SNMP community string 복잡성 설정       ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: SNMP Community String 기본값인 "public", "private"이 아닌 영문자, 숫자 포함 10자리 이상"       >> $HOSTNAME.linux.result.txt 2>&1
echo "■      또는 영문자, 숫자, 특수문자 포함 8자리 이상인 경우 양호"                         >> $HOSTNAME.linux.result.txt 2>&1
echo "■ ※ SNMP v3의 경우 별도 인증 기능을 사용하고, 해당 비밀번호가 복잡도를 만족하는 경우 양호"      >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ SNMP 서비스 활성화 여부 확인(UDP 161)"                                                >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `$NETSTAT_CMD -na | grep ":161 " | grep -i "^udp" | wc -l` -eq 0 ]
then
	echo " - SNMP 서비스가 비활성화 상태입니다."                                                               >> $HOSTNAME.linux.result.txt 2>&1
else
	$NETSTAT_CMD -na | grep ":161 " | grep -i "^udp"                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ snmpd.conf 파일 설정"                                                        >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	cat snmpdconf.txt                                                                 >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################              SNMP Access Control 설정              ##################"
echo "##################           [U-61] SNMP Access Control 설정          ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: SNMP 서비스에 접근 제어 설정이 되어 있는 경우 양호"                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ SNMP 서비스 활성화 여부 확인(UDP 161)"                                                >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `$NETSTAT_CMD -na | grep ":161 " | grep -i "^udp" | wc -l` -eq 0 ]
then
	echo " - SNMP 서비스가 비활성화 상태입니다."                                                               >> $HOSTNAME.linux.result.txt 2>&1
	flag1="Disabled"
else
	$NETSTAT_CMD -na | grep ":161 " | grep -i "^udp"                                                  >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ snmpd.conf 파일 설정"                                                        >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	cat snmpdconf.txt                                                                 >> $HOSTNAME.linux.result.txt 2>&1
	flag1="M/T"
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
rm -rf snmpdconf.txt
rm -rf snmpdaccess.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################               로그온 시 경고 메시지 설정              ##################"
echo "##################           [U-62] 로그온 시 경고 메시지 설정           ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 서버 및 사용 중인 Telnet, SSH, FTP, SMTP, DNS 서비스에 로그온 시 경고 메시지가 설정된 경우 양호" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황" >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]" >> $HOSTNAME.linux.result.txt 2>&1
echo " " >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ /etc/motd 파일 설정: " >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/motd ]
then
    if [ `cat /etc/motd | grep -v "^ *$" | wc -l` -gt 0 ]
    then
        cat /etc/motd | grep -v "^ *$" >> $HOSTNAME.linux.result.txt 2>&1
    else
        echo " - /etc/motd 파일에 메시지 설정 내용이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    fi
else
    echo " - /etc/motd 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ /etc/issue 파일 설정: " >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/issue ]
then
    if [ `cat /etc/issue | grep -v "^ *$" | wc -l` -gt 0 ]
    then
        cat /etc/issue | grep -v "^ *$" >> $HOSTNAME.linux.result.txt 2>&1
    else
        echo " - /etc/issue 파일에 메시지 설정 내용이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    fi
else
    echo " - /etc/issue 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ /etc/issue.net 파일 설정: " >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/issue.net ]
then
    if [ `cat /etc/issue.net | grep -v "^ *$" | wc -l` -gt 0 ]
    then
        cat /etc/issue.net | grep -v "^ *$" >> $HOSTNAME.linux.result.txt 2>&1
    else
        echo " - /etc/issue.net 파일에 메시지 설정 내용이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    fi
else
    echo " - /etc/issue.net 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

################# 서비스 활성화 여부 확인 #################
telnet_enabled=0
ssh_enabled=0
ftp_enabled=0
smtp_enabled=0
dns_enabled=0
disabled_list=""

# Telnet 확인
if command -v systemctl >/dev/null 2>&1; then
    if [ "$(systemctl status telnet.socket 2>/dev/null | grep -c listening)" -gt 0 ]; then
        if [ "$($NETSTAT_CMD -nat 2>/dev/null | grep ":$telnetport " | grep -ic "^tcp")" -gt 0 ]; then
            telnet_enabled=1
        fi
    fi
else
    if $NETSTAT_CMD -nat 2>/dev/null | grep -q ":$telnetport " || \
       ss -ltn 2>/dev/null | grep -q ":$telnetport" || \
       ps -ef | grep -v grep | grep -qi telnetd; then
        telnet_enabled=1
    fi
fi

# SSH 확인
if [ -f sshport.txt ]; then
    if [ `$NETSTAT_CMD -na | grep ":$sshport " | grep -i "^tcp" | grep -i "LISTEN" | wc -l` -gt 0 ]; then
        ssh_enabled=1
    fi
else
    if [ `$NETSTAT_CMD -na | grep ":22 " | grep -i "^tcp" | grep -i "LISTEN" | wc -l` -gt 0 ]; then
        ssh_enabled=1
    fi
fi

# FTP 확인
if [ -f ftpenable.txt ]; then
    ftp_enabled=1
fi

# SMTP 확인
if [ `cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}' | wc -l` -gt 0 ]; then
    smtpport=`cat /etc/services | awk -F" " '$1=="smtp" {print $1 "   " $2}' | grep "tcp" | awk -F" " '{print $2}' | awk -F"/" '{print $1}'`
    if [ `$NETSTAT_CMD -na | grep ":$smtpport " | grep -i "^tcp" | wc -l` -gt 0 ]; then
        smtp_enabled=1
    fi
fi

# DNS 확인
if [ `ps -ef | grep named | grep -v grep | wc -l` -gt 0 ]; then
    dns_enabled=1
fi

# 비활성화 서비스 목록 생성
[ $telnet_enabled -eq 0 ] && disabled_list="${disabled_list}Telnet, "
[ $ssh_enabled -eq 0 ]    && disabled_list="${disabled_list}SSH, "
[ $ftp_enabled -eq 0 ]    && disabled_list="${disabled_list}FTP, "
[ $smtp_enabled -eq 0 ]   && disabled_list="${disabled_list}SMTP, "
[ $dns_enabled -eq 0 ]    && disabled_list="${disabled_list}DNS, "
disabled_list=$(echo "$disabled_list" | sed 's/, $//')

echo "☞ 서비스(Telnet, SSH, FTP, SMTP, DNS) 동작 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1

# 모두 비활성화
if [ $telnet_enabled -eq 0 ] && [ $ssh_enabled -eq 0 ] && [ $ftp_enabled -eq 0 ] && [ $smtp_enabled -eq 0 ] && [ $dns_enabled -eq 0 ]; then
    echo " - Telnet, SSH, FTP, SMTP, DNS 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1
# 모두 활성화
elif [ $telnet_enabled -eq 1 ] && [ $ssh_enabled -eq 1 ] && [ $ftp_enabled -eq 1 ] && [ $smtp_enabled -eq 1 ] && [ $dns_enabled -eq 1 ]; then
    echo " - 비활성화된 서비스가 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
# 일부 비활성화
else
    echo " - ${disabled_list} 서비스가 비활성화 상태입니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " " >> $HOSTNAME.linux.result.txt 2>&1

# Telnet 배너 확인
if [ $telnet_enabled -eq 1 ]; then
    echo "☞ Telnet Service Enabled" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    echo " - Telnet 배너는 /etc/issue.net 파일을 사용합니다." >> $HOSTNAME.linux.result.txt 2>&1
    echo " " >> $HOSTNAME.linux.result.txt 2>&1
fi

# SSH 배너 확인
if [ $ssh_enabled -eq 1 ]; then
    echo "☞ SSH Service Enabled (/etc/ssh/sshd_config 파일 확인)" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    if [ -f /etc/ssh/sshd_config ]; then
        if [ `cat /etc/ssh/sshd_config | $GREP_CMD "Banner" | grep -v "^#" | wc -l` -gt 0 ]; then
            cat /etc/ssh/sshd_config | $GREP_CMD "Banner" | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - Banner 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
    else
        echo " - /etc/ssh/sshd_config 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    fi
    echo " " >> $HOSTNAME.linux.result.txt 2>&1
fi

# FTP 배너 확인
if [ $ftp_enabled -eq 1 ]; then
    if [ -s vsftpd.txt ]; then
        echo "☞ FTP Service Enabled ($vsfile 파일 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        if [ `cat $vsfile | grep ftpd_banner | grep -v "^#" | wc -l` -gt 0 ]; then
            cat $vsfile | grep ftpd_banner | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - ftpd_banner 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi
    if [ -s proftpd.txt ]; then
        echo "☞ FTP Service Enabled ($profile 파일 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        if [ `cat $profile | grep DisplayLogin | grep -v "^#" | wc -l` -gt 0 ]; then
            cat $profile | grep DisplayLogin | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - DisplayLogin 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi
fi

# SMTP 배너 확인
if [ $smtp_enabled -eq 1 ]; then
    # Sendmail
    if [ `ps -ef | grep sendmail | grep -v grep | wc -l` -gt 0 ]; then
        echo "☞ SMTP Service Enabled - Sendmail (/etc/mail/sendmail.cf 파일 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        if [ -f /etc/mail/sendmail.cf ]; then
            if [ `cat /etc/mail/sendmail.cf | grep SmtpGreetingMessage | grep -v "^#" | wc -l` -gt 0 ]; then
                cat /etc/mail/sendmail.cf | grep SmtpGreetingMessage | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
            else
                echo " - SmtpGreetingMessage 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
            fi
        else
            echo " - /etc/mail/sendmail.cf 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi

    # Postfix
    if [ `ps -ef | grep postfix | grep -v grep | wc -l` -gt 0 ]; then
        echo "☞ SMTP Service Enabled - Postfix (/etc/postfix/main.cf 파일 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        if [ -f /etc/postfix/main.cf ]; then
            if [ `cat /etc/postfix/main.cf | grep smtpd_banner | grep -v "^#" | wc -l` -gt 0 ]; then
                cat /etc/postfix/main.cf | grep smtpd_banner | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
            else
                echo " - smtpd_banner 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
            fi
        else
            echo " - /etc/postfix/main.cf 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi

    # Exim
    if [ `ps -ef | grep exim | grep -v grep | wc -l` -gt 0 ]; then
        echo "☞ SMTP Service Enabled - Exim (/etc/exim/exim.conf 파일 확인)" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
        if [ -f /etc/exim/exim.conf ]; then
            if [ `cat /etc/exim/exim.conf | grep smtp_banner | grep -v "^#" | wc -l` -gt 0 ]; then
                cat /etc/exim/exim.conf | grep smtp_banner | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
            else
                echo " - smtp_banner 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
            fi
        else
            echo " - /etc/exim/exim.conf 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi

    # Sendmail/Postfix/Exim 모두 비활성
    if [ `ps -ef | grep -E "sendmail|postfix|exim" | grep -v grep | wc -l` -eq 0 ]; then
        echo "☞ SMTP Service Enabled" >> $HOSTNAME.linux.result.txt 2>&1
        echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
		echo " - Sendmail, Postfix, Exim 외 다른 SMTP 서비스를 사용하고 있습니다.(인터뷰 필요)" >> $HOSTNAME.linux.result.txt 2>&1
        echo " " >> $HOSTNAME.linux.result.txt 2>&1
    fi
fi

# DNS 배너 확인
if [ $dns_enabled -eq 1 ]; then
    echo "☞ DNS Service Enabled (/etc/named.conf 파일 확인)" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    if [ -f /etc/named.conf ]; then
        if [ `cat /etc/named.conf | grep version | grep -v "^#" | wc -l` -gt 0 ]; then
            cat /etc/named.conf | grep version | grep -v "^#" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo " - version 설정이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
        fi
    else
        echo " - /etc/named.conf 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
    fi
    echo " " >> $HOSTNAME.linux.result.txt 2>&1
fi

echo "[END.]" >> $HOSTNAME.linux.result.txt 2>&1
echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
rm -rf sshport.txt
rm -rf mailservice.txt
rm -rf ftpenable.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################                 sudo 명령어 접근 관리                ##################"
echo "##################             [U-63] sudo 명령어 접근 관리             ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: /etc/sudoers 파일 소유자가 root이고, 파일 권한이 640 이하인 경우 양호"             >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/sudoers 파일 소유자 및 권한 확인"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/sudoers ]
then
    printf "(%s) " $($STAT_CMD /etc/sudoers 2>/dev/null || stat -f %Lp /etc/sudoers 2>/dev/null) >> $HOSTNAME.linux.result.txt
    ls -alL /etc/sudoers >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - /etc/sudoers 파일이 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#############################      4. 패치 관리      ##################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################          주기적 보안 패치 및 벤더 권고사항 적용         ##################"
echo "##################      [U-64] 주기적 보안 패치 및 벤더 권고사항 적용      ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 패치 적용 정책을 수립하여 주기적으로 패치를 관리하고 있을 경우 양호"             >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ uname -a"                                    	                                  	   >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
uname -a 																																										   >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ OS 정보 확인" >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
if command -v lsb_release >/dev/null 2>&1
then
    lsb_release -a >> $HOSTNAME.linux.result.txt 2>&1
elif [ -f /etc/os-release ]
then
    cat /etc/os-release | grep -v "^$" >> $HOSTNAME.linux.result.txt 2>&1
elif [ -f /etc/redhat-release ]
then
    cat /etc/redhat-release >> $HOSTNAME.linux.result.txt 2>&1
elif [ -f /etc/system-release ]
then
    cat /etc/system-release >> $HOSTNAME.linux.result.txt 2>&1
else
    echo " - OS 정보를 확인할 수 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ release"                                    	                                 >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/*release* 																	    	   >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 최근 업데이트 내역 확인"                                                              >> $FILE 2>&1
echo "----------------------------------------------------------------"                        >> $FILE 2>&1
if [ -f /var/log/dnf.log ]
then
    tail -20 /var/log/dnf.log                                                                  >> $FILE 2>&1
elif [ -f /var/log/yum.log ]
then
    tail -20 /var/log/yum.log                                                                  >> $FILE 2>&1
elif [ -f /var/log/apt/history.log ]
then
    tail -20 /var/log/apt/history.log                                                          >> $FILE 2>&1
else
    echo " - 업데이트 로그 파일 없음"                                                         >> $FILE 2>&1
fi
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#############################      5. 로그 관리      ##################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################               NTP 및 시각 동기화 설정                ##################"
echo "##################            [U-65] NTP 및 시각 동기화 설정            ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: NTP 및 시각 동기화 설정이 기준에 따라 적용된 경우 양호"                      >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 시각 동기화 데몬 동작 확인"                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
NTP_RESULT=$(systemctl list-units --type=service | grep ntp)
if [ -n "$NTP_RESULT" ]; then
    echo "$NTP_RESULT"                                             >> $HOSTNAME.linux.result.txt 2>&1
	echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
	echo "☞ NTP 설정 확인"                                          >> $HOSTNAME.linux.result.txt 2>&1
	echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
	ntpq -pn 2>/dev/null                                          >> $HOSTNAME.linux.result.txt 2>&1
else
    CHRONY_RESULT=$(systemctl list-units --type=service | grep chrony)
    if [ -n "$CHRONY_RESULT" ]; then
        echo "$CHRONY_RESULT"                                             >> $HOSTNAME.linux.result.txt 2>&1
		echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
		echo "☞ Chrony 설정 확인"                                          >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
		chronyc sources  2>/dev/null                                            >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - 시각 동기화가 설정되어 있지 않습니다."                         >> $HOSTNAME.linux.result.txt 2>&1
    fi
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################              정책에 따른 시스템 로깅 설정             ##################"
echo "##################          [U-66] 정책에 따른 시스템 로깅 설정          ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: syslog 에 중요 로그 정보에 대한 설정이 되어 있을 경우 양호"                      >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ SYSLOG 데몬 동작 확인"                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ `ps -ef | grep 'syslog' | grep -v 'grep' | wc -l` -eq 0 ]
then
	echo " - SYSLOG 서비스가 비활성화 상태입니다."                                                             >> $HOSTNAME.linux.result.txt 2>&1
else
	ps -ef | grep 'syslog' | grep -v 'grep'                                                      >> $HOSTNAME.linux.result.txt 2>&1
fi

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ syslog 설정 확인"                                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/syslog.conf ]
then
	if [ `cat /etc/syslog.conf | $GREP_CMD -v "^[[:space:]]*#|^[[:space:]]*$" | wc -l` -gt 0 ]
	then
		cat /etc/syslog.conf | $GREP_CMD -v "^[[:space:]]*#|^[[:space:]]*$"                                 >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/syslog.conf 파일에 설정 내용이 없습니다.(주석, 빈칸 제외)"                   >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/syslog.conf 파일이 없습니다."                                                    >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ rsyslog 설정 확인"                                                                     >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/rsyslog.conf ]
then
	if [ `cat /etc/rsyslog.conf | grep -v "^[[:space:]]*#|^[[:space:]]*$" | wc -l` -gt 0 ]
	then
		cat /etc/rsyslog.conf | $GREP_CMD -v "^[[:space:]]*#|^[[:space:]]*$"                                    >> $HOSTNAME.linux.result.txt 2>&1
	else
		echo " - /etc/rsyslog.conf 파일에 설정 내용이 없습니다.(주석, 빈칸 제외)"                   >> $HOSTNAME.linux.result.txt 2>&1
	fi
else
	echo " - /etc/rsyslog.conf 파일이 없습니다."                                                    >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "##################            로그 디렉터리 소유자 및 권한 설정           ##################"
echo "##################        [U-67] 로그 디렉터리 소유자 및 권한 설정        ##################" >> $HOSTNAME.linux.result.txt 2>&1
echo "#######################################################################################" >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 기준: 디렉터리 내 로그 파일의 소유자가 root이고, 권한이 644 이하인 경우 양호"                      >> $HOSTNAME.linux.result.txt 2>&1
echo "■ 현황"                                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "[START.]"                                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
if [ -d /var/log ]
then
    echo "☞ /var/log 디렉터리 내 디렉터리 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    ls -alL /var/log | grep "^d" | while read line
    do
        dirname=$(echo "$line" | awk '{print $NF}')
        if [ -d "/var/log/$dirname" ]
        then
            perm=$(stat -c "%a" "/var/log/$dirname" 2>/dev/null)
            echo "($perm) $line" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo "$line" >> $HOSTNAME.linux.result.txt 2>&1
        fi
    done
    echo " " >> $HOSTNAME.linux.result.txt 2>&1
    echo "☞ /var/log 디렉터리 내 파일 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    ls -alL /var/log | grep "^-" | while read line
    do
        filename=$(echo "$line" | awk '{print $NF}')
        if [ -f "/var/log/$filename" ]
        then
            perm=$(stat -c "%a" "/var/log/$filename" 2>/dev/null)
            echo "($perm) $line" >> $HOSTNAME.linux.result.txt 2>&1
        else
            echo "$line" >> $HOSTNAME.linux.result.txt 2>&1
        fi
    done
else
    echo "☞ /var/log 디렉터리 내 디렉터리 소유자 및 권한 확인" >> $HOSTNAME.linux.result.txt 2>&1
    echo "----------------------------------------------------------------" >> $HOSTNAME.linux.result.txt 2>&1
    echo " - /var/log 디렉터리가 없습니다." >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[END.]"                                                                                >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "***************************************** END *****************************************" >> $HOSTNAME.linux.result.txt 2>&1
date                                                                                           >> $HOSTNAME.linux.result.txt 2>&1
rm -rf proftpd.txt
rm -rf vsftpd.txt
echo "***************************************** END *****************************************"
echo "END_RESULT"                                                                              >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ 스크립트 구동이 완료되었습니다."

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "@@FINISH"                                                                        	       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "=========================== System Information Query Start ============================"
echo "=========================== System Information Query Start ============================" >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "###############################  Kernel Information  ##################################"
echo "###############################  Kernel Information  ##################################" >> $HOSTNAME.linux.result.txt 2>&1
uname -a                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "################################## IP Information #####################################"
echo "################################## IP Information #####################################" >> $HOSTNAME.linux.result.txt 2>&1
ifconfig -a                                                                                    >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "################################  Network Status(1) ###################################"
echo "################################  Network Status(1) ###################################" >> $HOSTNAME.linux.result.txt 2>&1
$NETSTAT_CMD -an | $GREP_CMD -i "LISTEN|ESTABLISHED"                                                    >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "################################   Network Status(2) ##################################"
echo "################################   Network Status(2) ##################################" >> $HOSTNAME.linux.result.txt 2>&1
$NETSTAT_CMD -nap | $GREP_CMD -i "tcp|udp"                                                              >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "#############################   Routing Information   #################################"
echo "#############################   Routing Information   #################################" >> $HOSTNAME.linux.result.txt 2>&1
$NETSTAT_CMD -rn                                                                                    >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "################################   Process Status   ###################################"
echo "################################   Process Status   ###################################" >> $HOSTNAME.linux.result.txt 2>&1
ps -ef                                                                                         >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "###################################   User Env   ######################################"
echo "###################################   User Env   ######################################" >> $HOSTNAME.linux.result.txt 2>&1
env                                                                                            >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "=========================== System Information Query End =============================="
echo "=========================== System Information Query End ==============================" >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/passwd 파일"                                                                      >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/passwd ]
then
  cat /etc/passwd                                                                              >> $HOSTNAME.linux.result.txt 2>&1
else
	echo "/etc/passwd 파일이 없음"                                                          >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ /etc/shadow 파일"                                                                      >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
if [ -f /etc/shadow ]
then
  cat /etc/shadow                                                                              >> $HOSTNAME.linux.result.txt 2>&1
else
  echo "/etc/shadow 파일이 없음"                                                          >> $HOSTNAME.linux.result.txt 2>&1
fi
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ /etc/group 파일"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/group                                                                                 >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "☞ /etc/ssh/sshd_config 파일"                                                                  >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
cat /etc/ssh/sshd_config                                                                                >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



echo "[참고] 사용자 별 profile 내용"                                                           >> $HOSTNAME.linux.result.txt 2>&1
echo ": 사용자 profile 또는 profile 내 TMOUT 설정이 없는 경우 결과 없음 (/etc/profile을 따름)" >> $HOSTNAME.linux.result.txt 2>&1
echo "-----------------------------------------------"                                         >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

awk -F: '{print $1 ":" $6}' /etc/passwd > profilepath.txt

for result in `cat profilepath.txt`
do
	echo $result > tempfile.txt
	var=`awk -F":" '{print $2}' tempfile.txt`

	if [ $var = "/" ]
	then
		if [ `ls -f / | grep "^\.profile$" | wc -l` -gt 0 ]
		then
			filename=`ls -f / | grep "^\.profile$"`

			if [ `grep -i TMOUT /$filename | wc -l` -gt 0 ]
			then
				awk -F":" '{print $1}' tempfile.txt                                                    >> $HOSTNAME.linux.result.txt 2>&1
				echo "-----------------------------------------------"                                 >> $HOSTNAME.linux.result.txt 2>&1
				grep -i TMOUT /$filename | grep -v "^#"	                                               >> $HOSTNAME.linux.result.txt 2>&1
				echo " "                                                                               >> $HOSTNAME.linux.result.txt 2>&1
# 사용자 profile이 존재하는 경우만 출력하기 위해 주석 처리
#			else
#				awk -F":" '{print $1}' tempfile.txt                                                    >> $HOSTNAME.linux.result.txt 2>&1
#                         	echo "----------------------------------------"                      >> $HOSTNAME.linux.result.txt 2>&1
#                         	echo $filename"에 TMOUT 설정이 존재하지 않음"                        >> $HOSTNAME.linux.result.txt 2>&1
#				echo " "                                                                               >> $HOSTNAME.linux.result.txt 2>&1
			fi
#		else
#                        awk -F":" '{print $1}' tempfile.txt                                    >> $HOSTNAME.linux.result.txt 2>&1
#                        echo "----------------------------------------"                        >> $HOSTNAME.linux.result.txt 2>&1
#                        echo "사용자 profile 파일이 존재하지 않음"                             >> $HOSTNAME.linux.result.txt 2>&1
#			echo " "                                                                                 >> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		pathname=`awk -F":" '{print $2}' tempfile.txt`
				if [ -f $pathname ]
				then
                if [ `ls -f $pathname | grep "^\.profile$" | wc -l` -gt 0 ]
                then
                        filename = `ls -f $pathname | grep "^\.profile$"`

                        if [ `grep -i TMOUT $pathname/$filename | wc -l` -gt 0 ]
                        then
                                awk -F":" '{print $1}' tempfile.txt                            >> $HOSTNAME.linux.result.txt 2>&1
                                echo "----------------------------------------"                >> $HOSTNAME.linux.result.txt 2>&1
                                grep -i TMOUT $pathname/$filename               >> $HOSTNAME.linux.result.txt 2>&1
                                echo " "                                                       >> $HOSTNAME.linux.result.txt 2>&1
# 사용자 profile이 존재하는 경우만 출력하기 위해 주석 처리
#                        else
#                                awk -F":" '{print $1}' tempfile.txt                            >> $HOSTNAME.linux.result.txt 2>&1
#                                echo "----------------------------------------"                >> $HOSTNAME.linux.result.txt 2>&1
#                                echo $filename"에 TMOUT 설정이 존재하지 않음"                  >> $HOSTNAME.linux.result.txt 2>&1
#                                echo " "                                                       >> $HOSTNAME.linux.result.txt 2>&1
                        fi
#                else
#                        awk -F":" '{print $1}' tempfile.txt                                    >> $HOSTNAME.linux.result.txt 2>&1
#                        echo "----------------------------------------"                        >> $HOSTNAME.linux.result.txt 2>&1
#                        echo "사용자 profile 파일이 존재하지 않음"                             >> $HOSTNAME.linux.result.txt 2>&1
#                        echo " "                                                               >> $HOSTNAME.linux.result.txt 2>&1
								 fi
				fi				 
	fi
done
rm -rf tempfile.txt

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

echo "[참고] 사용자 별 profile 내용"                                                           >> $HOSTNAME.linux.result.txt 2>&1
echo ": 사용자 profile 또는 profile 내 UMASK 설정이 없는 경우 결과 없음 (/etc/profile을 따름)" >> $HOSTNAME.linux.result.txt 2>&1
echo "-----------------------------------------------"                                         >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1

for result in `cat profilepath.txt`
do
	echo $result > tempfile.txt
	var=`awk -F":" '{print $2}' tempfile.txt`

	if [ $var = "/" ]
	then
		if [ `ls -f / | grep "^\.profile$" | wc -l` -gt 0 ]
		then
			filename=`ls -f / | grep "^\.profile$"`

			if [ `grep -i umask /$filename | wc -l` -gt 0 ]
			then
				awk -F":" '{print $1}' tempfile.txt                                                    >> $HOSTNAME.linux.result.txt 2>&1
				echo "-----------------------------------------------"                                 >> $HOSTNAME.linux.result.txt 2>&1
				grep -A 1 -B 1 -i umask /$filename	                                               >> $HOSTNAME.linux.result.txt 2>&1
				echo " "                                                                               >> $HOSTNAME.linux.result.txt 2>&1
# 사용자 profile이 존재하는 경우만 출력하기 위해 주석 처리
#			else
#				awk -F":" '{print $1}' tempfile.txt                                                    >> $HOSTNAME.linux.result.txt 2>&1
#                         	echo "----------------------------------------"                    >> $HOSTNAME.linux.result.txt 2>&1
#                         	echo $filename"에 UMASK 설정이 존재하지 않음"                      >> $HOSTNAME.linux.result.txt 2>&1
#				echo " "                                                                               >> $HOSTNAME.linux.result.txt 2>&1
			fi
#		else
#                        awk -F":" '{print $1}' tempfile.txt                                   >> $HOSTNAME.linux.result.txt 2>&1
#                        echo "----------------------------------------"                       >> $HOSTNAME.linux.result.txt 2>&1
#                        echo "사용자 profile 파일이 존재하지 않음"                            >> $HOSTNAME.linux.result.txt 2>&1
#			echo " "                                                                                 >> $HOSTNAME.linux.result.txt 2>&1
		fi
	else
		pathname=`awk -F":" '{print $2}' tempfile.txt`
					if [ -f $pathname ]
					then
                if [ `ls -f $pathname | grep "^\.profile$" | wc -l` -gt 0 ]
                then
                        filename = `ls -f $pathname | grep "^\.profile$"`

                        if [ `grep -i umask $pathname/$filename | wc -l` -gt 0 ]
                        then
                                awk -F":" '{print $1}' tempfile.txt                            >> $HOSTNAME.linux.result.txt 2>&1
                                echo "----------------------------------------"                >> $HOSTNAME.linux.result.txt 2>&1
                                grep -A 1 -B 1 -i umask $pathname/$filename               >> $HOSTNAME.linux.result.txt 2>&1
                                echo " "                                                       >> $HOSTNAME.linux.result.txt 2>&1
# 사용자 profile이 존재하는 경우만 출력하기 위해 주석 처리
#                        else
#                                awk -F":" '{print $1}' tempfile.txt                           >> $HOSTNAME.linux.result.txt 2>&1
#                                echo "----------------------------------------"               >> $HOSTNAME.linux.result.txt 2>&1
#                                echo $filename"에 UMASK 설정이 존재하지 않음"                 >> $HOSTNAME.linux.result.txt 2>&1
#                                echo " "                                                      >> $HOSTNAME.linux.result.txt 2>&1
                        fi
#                else
#                        awk -F":" '{print $1}' tempfile.txt                                   >> $HOSTNAME.linux.result.txt 2>&1
#                        echo "----------------------------------------"                       >> $HOSTNAME.linux.result.txt 2>&1
#                        echo "사용자 profile 파일이 존재하지 않음"                            >> $HOSTNAME.linux.result.txt 2>&1
#                        echo " "                                                              >> $HOSTNAME.linux.result.txt 2>&1
								 fi
					fi			 
	fi
done
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
rm -rf profilepath.txt
rm -rf tempfile.txt




		echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
		echo "[참고] 소유자가 존재하지 않는 파일 전체 목록"                                        >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1
		cat 1.17.txt                                                                               >> $HOSTNAME.linux.result.txt 2>&1
		rm -rf 1.17.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1


		echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
		echo "[참고] SUID,SGID,Sticky bit 설정 파일 전체 목록"                                     >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1
    cat 1.24.txt                                                                               >> $HOSTNAME.linux.result.txt 2>&1
		rm -rf 1.24.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1



		echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
		echo "[참고] World Writable 파일 전체 목록"                                                >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1
    cat world-writable.txt                                                                     >> $HOSTNAME.linux.result.txt 2>&1
		rm -rf world-writable.txt
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "☞ 현재 등록된 서비스"                                                                   >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1
rpm -qa |sort                                                                                  >> $HOSTNAME.linux.result.txt 2>&1



echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo "[참고] 숨겨진 파일 및 디렉토리 전체 목록"                                                                   >> $HOSTNAME.linux.result.txt 2>&1
echo "----------------------------------------------------------------"          >> $HOSTNAME.linux.result.txt 2>&1

cat 220.txt                                                                                    >> $HOSTNAME.linux.result.txt 2>&1

echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
echo " "                                                                                       >> $HOSTNAME.linux.result.txt 2>&1
rm -rf 220.txt

echo " "                                                                                   >> $HOSTNAME.linux.result.txt 2>&1
		echo "[참고] /dev에 존재하지 않는 device 파일 전체"                                                >> $HOSTNAME.linux.result.txt 2>&1
		echo "----------------------------------------------------------------"      >> $HOSTNAME.linux.result.txt 2>&1
find /dev -type f -exec ls -l {} \;                                                            > 1.32.txt

if [ -s 1.32.txt ]
then
	cat 1.32.txt                                                                                 >> $HOSTNAME.linux.result.txt 2>&1
else
	echo "☞ dev 에 존재하지 않은 Device 파일이 발견되지 않음"                            >> $HOSTNAME.linux.result.txt 2>&1
fi
sed -i '/egrep: warning: egrep is obsolescent/d' "./$HOSTNAME.linux.result.txt"
rm -rf 1.32.txt
echo " "
echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo " " >> $HOSTNAME.linux.result.txt 2>&1
echo "==========================================================" >> $HOSTNAME.linux.result.txt 2>&1
echo "          Linux 보안 점검 완료"                             >> $HOSTNAME.linux.result.txt 2>&1
echo "          결과 파일: $HOSTNAME.linux.result.txt"                                 >> $HOSTNAME.linux.result.txt 2>&1
echo "          완료 시각: $(date)"                               >> $HOSTNAME.linux.result.txt 2>&1
echo "==========================================================" >> $HOSTNAME.linux.result.txt 2>&1

# 임시 파일 정리
rm -f /tmp/nullgid.txt /tmp/1.17.txt /tmp/temp114.txt /tmp/ftpenable.txt /tmp/rcommand.txt /tmp/unnecessary.txt /tmp/1.33.txt /tmp/1.29.txt 2>/dev/null

echo " "
echo "☞ Linux 보안 점검 완료"
echo "☞ 결과 파일: $HOSTNAME.linux.result.txt"
echo " "
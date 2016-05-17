#/bin/bash
#
# denis.shkadov@ecommerce.com
#
# Action Disable Support for SSLv3 on a cPanel on target VM.

        
case "${1}" in
        outputFormat)
                echo "Apache|WHM|Dovecot|Courier|FTP SSL|Exim|FDisk"
        ;;
        *)
#Apache
        status=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'cat /usr/local/apache/conf/includes/pre_main_global.conf &> /dev/null || echo err')
	if [ "x${status}" == "xerr" ]
	then 
		ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'mkdir -p /usr/local/apache/conf/includes && touch /usr/local/apache/conf/includes/pre_main_global.conf && echo -en "SSLProtocol -All +TLSv1 \nSSLHonorCipherOrder On\n"> /usr/local/apache/conf/includes/pre_main_global.conf'
		output=$(echo "Created")
	else
		entry=$(ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'grep -iE "SSLProtocol.*|SSLHonorCipherOrder.*" /usr/local/apache/conf/includes/pre_main_global.conf')
		if [ "x${entry}" == "x" ]
			then 
			ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'sed -i 's/SSLProtocol.*/SSLProtocol All +TLSv1/;s/SSLHonorCipherOrder.*/SSLHonorCipherOrder On/' /usr/local/apache/conf/includes/pre_main_global.conf'
			output=$(echo "Changed")
		fi
 	fi
		ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/scripts/rebuildhttpdconf && service httpd restart'
:'
#WHM, Webmail, WebDisk

        ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} '/usr/local/cpanel/scripts/upcp'
        output=$(echo "Updated")
'
#Dovecot & Courier
        
        status=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} '/usr/local/cpanel/scripts/setupmailserver --current |grep -i "dovecot" &> /dev/null')
        if [ "x${status}" == "xCurrent mailserver type: dovecot" ]
        then 
                mainfile=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'cat /var/cpanel/templates/dovecot2.2/main.local &> /dev/null || echo err')
                if [ "x${mainfile}" == "xerr" ]
                then 
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'cp /var/cpanel/templates/dovecot2.2/main.default /var/cpanel/templates/dovecot2.2/main.local && sed -i 's/SSLv2/!SSLv2/g' /var/cpanel/templates/dovecot2.2/main.local && sed -i 's/SSLv3/!SSLv3/g' /var/cpanel/templates/dovecot2.2/main.local'
                output=$(echo "Created")
                fi
        else
                entry=$(ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'grep -iE "SSLv2|SSLv3" /var/cpanel/templates/dovecot2.2/main.local')
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'sed -i 's/SSLv2/!SSLv2/g';sed -i 's/SSLv3/!SSLv3/g' /var/cpanel/templates/dovecot2.2/main.local'
                output=$(echo "Changed")        
        fi
                ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/usr/local/cpanel/scripts/builddovecotconf && /scripts/restartsrv_dovecot'
        if [ "x${status}" == "xCurrent mailserver type: courier" ]
        then 
                mainfile=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'cat /var/cpanel/courierconfig.yaml &> /dev/null')
                
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'sed -i 's/"TLS_PROTOCOL":.*/"TLS_PROTOCOL": 'TLSv1'/';sed -i 's/"TLS_STARTTLS_PROTOCOL":.*/"TLS_STARTTLS_PROTOCOL": 'TLSv1'/' /var/cpanel/courierconfig.yaml'
                output=$(echo "Changed")        
        fi
                ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/usr/local/cpanel/bin/build_courier_conf'        

#FTP
        status=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'grep ftpserver /var/cpanel/cpanel.config &> /dev/null || echo err')
        if [ "x${status}" == "ftpserver=pure-ftpd" ]
        then 
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'sed -i 's/TLSCipherSuite:.*/TLSCipherSuite: HIGH:MEDIUM:+TLSv1:!SSLv2:+SSLv3/' /var/cpanel/conf/pureftpd/main'
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} '/usr/local/cpanel/bin/build_ftp_conf && service pure-ftpd restart'
        else
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'sed -i 's/TLSCipherSuite:.*/TLSCipherSuite: HIGH:MEDIUM:+TLSv1:!SSLv2:+SSLv3/' /var/cpanel/conf/proftpd/main'
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} '/scripts/restartsrv_proftpd'
        fi
                output=$(echo "Changed")
#Exim

         status=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'cat /etc/exim.conf.local &> /dev/null || echo err')               
         if [ "x${status}" == "xerr" ]
        then 
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'touch /etc/exim.conf.local && echo -en "@CONFIG@\n
tls_require_ciphers = ALL:-SSLv3:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP\n"> /etc/exim.conf.local'
                output=$(echo "Created")
        else
                entry=$(ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'grep -i "tls_require_ciphers = " /etc/exim.conf.local')
                if [ "x${entry}" == "x" ]
                        then 
                        ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'sed -i 's/tls_require_ciphers =.*/tls_require_ciphers = ALL:-SSLv3:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP/' /etc/exim.conf.local'
                        output=$(echo "Changed")
                fi
        fi
                ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/scripts/buildeximconf && service exim restart'

        ;;
esac

echo "${outPut}"

exit 0





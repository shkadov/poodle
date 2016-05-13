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
		entry=$(ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'grep -iE "SSLProtocol *|SSLHonorCipherOrder *" /usr/local/apache/conf/includes/pre_main_global.conf')
		if [ "x${entry}" == "x" ]
			then 
			ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'sed -i 's/SSLProtocol.*/SSLProtocol All +TLSv1/;s/SSLHonorCipherOrder.*/SSLHonorCipherOrder On/' /usr/local/apache/conf/includes/pre_main_global.conf'
			output=$(echo "Changed")
		fi
 	fi
		ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/scripts/rebuildhttpdconf && service httpd restart'

#WHM
        status=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'cat /var/cpanel/conf/cpsrvd/ssl_socket_args &> /dev/null || echo err')
        if [ "x${status}" = "xerr" ]
        then
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'mkdir -p var/cpanel/conf/cpsrvd && touch /var/cpanel/conf/cpsrvd/ssl_socket_args && echo "SSL_version SSLv23:!SSLv2:!SSLv3" > /var/cpanel/conf/cpsrvd/ssl_socket_args'
                output=$(echo "Created")
	else
                entry=$(ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'grep -i "SSL_version *" /var/cpanel/conf/cpsrvd/ssl_socket_args')
                if [ "x${entry}" != "SSL_version SSLv23:!SSLv2:!SSLv3" ]
                	then
                	ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'sed -i "s/SSL_version */SSL_version SSLv23:!SSLv2:!SSLv3/" /var/cpanel/conf/cpsrvd/ssl_socket_args'
                	output=$(echo "Changed")
                fi
	        ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/usr/local/cpanel/whostmgr/bin/whostmgr2 docpsrvdconfiguration'
	fi
#IMAP
        status=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'cat /var/cpanel/conf/dovecot/main &> /dev/null || echo err')
        if [ "x${status}" = "xerr" ]
        then
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'mkdir -p /var/cpanel/conf/dovecot && touch /var/cpanel/conf/dovecot/main && echo "SSL_protocol !SSLv2 !SSLv3" > /var/cpanel/conf/dovecot/main'
                output=$(echo "Created")
        else

                entry=$(ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'grep -i "SSL_protocol *" /var/cpanel/conf/dovecot/main')
                if [ "x${entry}" != "SSL_protocol !SSLv2 !SSLv3" ]
                	then
                	ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'sed -i "s/SSL_protocol */SSL_protocol !SSLv2 !SSLv3/" /var/cpanel/conf/dovecot/main'
                	output=$(echo "Changed")
                fi
        	ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/usr/local/cpanel/whostmgr/bin/whostmgr2 savedovecotsetup'
	fi
#FTP
	status=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'cat /var/cpanel/pureftpd/main &> /dev/null || echo err')
        if [ "x${status}" = "xerr" ]
        then
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'mkdir -p /var/cpanel/pureftpd && touch /var/cpanel/pureftpd/main && echo "TLSCipherSuite HIGH:MEDIUM:+TLSv1:!SSLv2:!SSLv3" > /var/cpanel/pureftpd/main'
                output=$(echo "Created")
        else

                entry=$(ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'grep -i "TLSCipherSuite" /var/cpanel/conf/pureftpd/main')
                if [ "x${entry}" != "TLSCipherSuite HIGH:MEDIUM:+TLSv1:!SSLv2:!SSLv3" ]
                	then
                	ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'sed -i "s/TLSCipherSuite */TLSCipherSuite  HIGH:MEDIUM:+TLSv1:!SSLv2:!SSLv3/" /var/cpanel/conf/pureftpd/main'
                	output=$(echo "Changed")
                fi
        	ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/usr/local/cpanel/bin/build_ftp_conf && service pure-ftpd restart'
	fi
#Exim
	status=$(ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'cat /etc/exim.conf.local &> /dev/null || echo err')
        if [ "x${status}" = "xerr" ]
        then
                ssh -q -o ConnectTimeout=20 -o StrictHostKeyChecking=no ${1} 'touch /etc/exim.conf.local && echo "@CONFIG@ tls_require_ciphers = ALL:-SSLv3:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP" > /etc/exim.conf.local'
                output=$(echo "Created")
        else

                entry=$(ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'grep -i "@CONFIG@ tls_require_ciphers" /etc/exim.conf.local')
                if [ "x${entry}" != "ALL:-SSLv3:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP" ]
                	then
                	ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'sed -i "s/@CONFIG@ tls_require_ciphers = */@CONFIG@ tls_require_ciphers = ALL:-SSLv3:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP/" /etc/exim.conf.local'
                	output=$(echo "Changed")
                fi
                ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/scripts/buildeximconf && service exim restart'
	fi
        ;;
esac

echo "${outPut}"

exit 0


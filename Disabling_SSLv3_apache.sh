#/bin/bash
#
# denis.shkadov@ecommerce.com
#
# Action Disable Support for SSLv3 on a cPanel on target VM.


case "${1}" in
        outputFormat)
                echo "Apache"
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
			ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} 'sed -i 's/^.*SSLProtocol.*/SSLProtocol All +TLSv1/;s/^.*SSLHonorCipherOrder.*/SSLHonorCipherOrder On/' /usr/local/apache/conf/includes/pre_main_global.conf'
			output=$(echo "Changed")
		fi
 	fi
		ssh -q -o ConnectTimeOut=20 -o StrictHostKeyChecking=no ${1} '/scripts/rebuildhttpdconf && service httpd restart'
    ;;
esac

echo "${outPut}"

exit 0

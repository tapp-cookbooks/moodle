#!/bin/bash
PHP_SCRIPT=/usr/bin/php-fastcgi
RETVAL=0
case "\$1" in
    start)
      \$PHP_SCRIPT
      RETVAL=\$?
  	  ;;
    stop)
      killall -9 php5-cgi
      RETVAL=\$?
      ;;
    restart)
      killall -9 php5-cgi
      \$PHP_SCRIPT
      RETVAL=\$?
      ;;
    *)
      echo "Usage: php-fastcgi {start|stop|restart}"
      exit 1
      ;;
esac      
exit \$RETVAL
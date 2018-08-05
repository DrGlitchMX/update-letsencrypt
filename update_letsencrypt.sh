#!/bin/bash

<< EOD
Update script for "Let's Encrypt!" intended to be run via cron.

It is fit to obtain a fresh certificate and should not hurt
our apache config.

Additionally to what LE does itself, we make sure the permissions on
the certificate locations are correctly set afterwards.
This is only an issue as other software like PostgreSQL
is a bit "thorough" on permission-checking and will deny startup
if it deems sth. fishy.

NOTE:
hosts listed in the respective 'ini'-files
must have a VirtualHost configured in Apache!
Otherwise, this script would foreground a curses menu,
effectively preventing it from functioning properly.

@created:   2016-01-04, 23:55:04
@updated:   2018-08-05, 22:48:03  

EOD

# cron needs a more comprehensive PATH
export PATH=/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Renew Let's Encrypt cert
echo -n "Updating certificates from \"Let's Encrypt\"... "

# add this command per ini that you are using
/usr/local/bin/certbot certonly\
    --config /etc/letsencrypt/some-cert-site.ini\
    --apache\
    --force-renew

if [ $? -eq 0 ]; then
    echo "OK!"
else
    ERRORMSG=$( tail /var/log/letsencrypt/letsencrypt.log )
    echo -e "An error occurred while updating the Let's encrypt certificates!\n\n"
    echo $ERRORMSG
    exit -1
fi

# set permissions on our certs
chown -R root:ssl-cert /etc/letsencrypt
chmod 0640 /etc/letsencrypt/archive/some-cert-site/*

echo "Permissions to certificate files set to \"root:ssl-cert\" (0640)"
echo -ne "Restarting apache... "
/usr/sbin/apache2ctl restart

if [ $? -eq 0 ]; then
    echo "Apache restarted!"
else
    echo "Error restarting apache! Better check system logs..."
    exit -1
fi

echo "All done! Certificates are up to date."


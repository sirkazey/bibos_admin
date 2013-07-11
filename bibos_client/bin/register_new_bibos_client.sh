#!/usr/bin/env bash

    # Get hold of config parameters, connect to admin system.

    # Attempt to get shared config file from gateway.
    # It this fails, the user must enter the corresponding data (site and 
    # admin_url) manually.
    ADMIN_SITE="https://$(bibos_find_gateway 2> /dev/null)" 
    SHARED_CONFIG="/tmp/bibos.conf"
    curl -s "$ADMIN_SITE/bibos.conf" -o "$SHARED_CONFIG"

    if [[ -f "$SHARED_CONFIG" ]]
    then
        HAS_GATEWAY=1
    fi
    # The following config parameters are needed to finalize the
    # installation:
    # - hostname
    #   Prompt user for new host name
    echo "Indtast venligst et nyt navn for denne computer:"
    read NEWHOSTNAME

    if [[ -n "$NEWHOSTNAME" ]]
    then
        echo $NEWHOSTNAME > /tmp/newhostname
        sudo cp /tmp/newhostname /etc/hostname
        sudo set_bibos_config hostname $NEWHOSTNAME
        sudo hostname $NEWHOSTNAME
        sudo sed -i -e "s/$HOSTNAME/$NEWHOSTNAME/" /etc/hosts
    else
        sudo set_bibos_config hostname $HOSTNAME
    fi
    # - site
    #   TODO: Get site from gateway, if none present prompt user
    if [[ -n "$HAS_GATEWAY" ]]
    then
        SITE=$(get_bibos_config site "$SHARED_CONFIG")
    fi
    
    if [[ -z "$SITE" ]]
    then 
        echo "Indtast ID for det site, computeren skal tilmeldes:"
        read SITE
    fi

    if [[ -n "$SITE" ]]
    then
        sudo set_bibos_config site $SITE
    else
        echo ""
        echo "Computeren kan ikke registreres uden site - prøv igen."
        exit 1
    fi

    # - distribution
    #   Use preinstalled default if any, otherwise prompt user
    
    DISTRO=$(get_bibos_config distribution)
    echo $DISTRO

    if [[ -z $DISTRO ]]
    then
        echo "Indtast ID for PC'ens distribution"
        read DISTRO
    fi
    sudo set_bibos_config distribution $DISTRO
    # - admin_url
    #   Get from gateway, otherwise prompt user.
    if [[ -n "$HAS_GATEWAY" ]]
    then
        ADMIN_URL=$(get_bibos_config admin_url "$SHARED_CONFIG")
    fi
    if [[ -z "$ADMIN_URL" ]]
    then 
        ADMIN_URL="https://bibos-admin.magenta-aps.dk"
        echo "Indtast admin-url hvis det ikke er $ADMIN_URL"
        read NEW_ADMIN_URL
        if [[ -n $NEW_ADMIN_URL ]]
        then
            ADMIN_URL=$NEW_ADMIN_URL
        fi
    fi
    sudo set_bibos_config admin_url $ADMIN_URL

    # OK, we got the config. 
    # Do the deed.
    sudo bibos_register_in_admin

    # Now setup cron job
    if [[ -f $(which jobmanager) ]]
    then
        sudo crontab -l > /tmp/oldcron
        sudo echo "*/5 * * * * $(which jobmanager)" >> /tmp/oldcron
        sudo crontab /tmp/oldcron
        sudo rm /tmp/oldcron
    fi


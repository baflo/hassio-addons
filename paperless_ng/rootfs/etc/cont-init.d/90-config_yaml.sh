#!/usr/bin/env bashio

##################
# INITIALIZATION #
##################

# Where is the config
CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")

# Check if config file is there, or create one from template
if [ -f $CONFIGSOURCE ]; then
    echo "Using config file found in $CONFIGSOURCE"
else
    echo "No config file, creating one from template"
    # Create folder
    mkdir -p "$(dirname "${CONFIGSOURCE}")"
    # Placing template in config
    if [ -f /templates/config.yaml ]; then
        # Use available template
        cp /templates/config.yaml "$(dirname "${CONFIGSOURCE}")"
    else
        # Download template
        TEMPLATESOURCE="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/config.template"
        curl -L -f -s $TEMPLATESOURCE --output $CONFIGSOURCE
    fi
    # Need to restart
    bashio::log.fatal "Config file not found, creating a new one. Please customize the file in $CONFIGSOURCE before restarting."
    # bashio::exit.nok
fi

# Check if yaml is valid
EXIT_CODE=0
yamllint -d relaxed --no-warnings $CONFIGSOURCE &>ERROR || EXIT_CODE=$?
if [ $EXIT_CODE = 0 ]; then
    echo "Config file is a valid yaml"
else
    cat ERROR
    bashio::log.fatal "Config file has an invalid yaml format. Please check the file in $CONFIGSOURCE. Errors list above."
    # bashio::exit.nok
fi

# Export all yaml entries as env variables
# Helper function
set +u
function parse_yaml {
    local prefix=$2 || local prefix=""
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034' | tr -d '\015')
    sed -ne "s|^\($s\):|\1|" \
    -e "s| #.*$||g" \
    -e "s|#.*$||g" \
    -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
    -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
        awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
     }'
}

# Get variables and export
bashio::log.info "Starting the app with the variables in $CONFIGSOURCE"
for word in $(parse_yaml "$CONFIGSOURCE" ""); do
    # Clean output
    word=${word//[\"\']/}
    # Data validation
    if [[ $word =~ ^.+[=].+$ ]]; then
        sed -i "1a export $word" /etc/services.d/*/run                                   # Export the variable
        sed -i "1a echo \$(tput setaf 2)... $word\$(tput setaf 0)" /etc/services.d/*/run # Show text in colour
        bashio::log.blue "$word"
    else
        bashio::log.fatal "$word does not follow the structure KEY=text, it will be ignored and removed from the config"
        sed -i "/$word/ d" ${CONFIGSOURCE}
    fi
    # Color text
    sed -i "1a echo \$(tput setaf 2)Exporting ENV variables :\$(tput setaf 0)" /etc/services.d/*/run # Show text in colour
done

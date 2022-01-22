#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#####################
# Autodiscover mqtt #
#####################

if bashio::config.true 'mqtt_autodiscover'; then
    bashio::log.info "mqtt_autodiscover is defined in options, attempting autodiscovery..."
    # Check if available
    if ! bashio::services.available "mqtt"; then bashio::exit.nok "No internal MQTT service found. Please install Mosquitto broker"; fi
    # Get variables
    bashio::log.info "... MQTT service found, fetching server detail (you can enter those manually in your config file) ..."
    # spellcheck disable=SC2155
    export MQTT_HOST=$(bashio::services mqtt "host")
    # spellcheck disable=SC2155
    export MQTT_PORT=$(bashio::services mqtt "port")
    # spellcheck disable=SC2155
    export MQTT_SSL=$(bashio::services mqtt "ssl")
    # spellcheck disable=SC2155
    export MQTT_USERNAME=$(bashio::services mqtt "username")
    # spellcheck disable=SC2155
    export MQTT_PASSWORD=$(bashio::services mqtt "password")
    # Export variables
    for variables in "MQTT_HOST=$MQTT_HOST" "MQTT_PORT=$MQTT_PORT" "MQTT_SSL=$MQTT_SSL" "MQTT_USERNAME=$MQTT_USERNAME" "MQTT_PASSWORD=$MQTT_PASSWORD"; do
        sed -i "1a export $variables" /etc/services.d/*/*run* 2>/dev/null || true
        # Log
        bashio::log.blue "$variables"
    done
fi

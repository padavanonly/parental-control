. /usr/share/libubox/jshn.sh
. /lib/functions.sh

SET_BASE="0"
ADD_RULE="1"
ADD_GROUP="2"
CLEAN_RULE="3"
CLEAN_GROUP="4"
SET_RULE="5"
SET_GROUP="6"

str_action_num()
{
case $1 in
"DROP")
	echo 0
;;
"ACCEPT")
	echo 1
;;
"POLICY_DROP")
	echo 2
;;
"POLICY_ACCEPT")
	echo 3
;;
esac    
}

config_apply()
{
    test -z "$1" && return 1
    
	if [ -e "/dev/parental_control" ];then
    	#[ "$DEBUG" = "1" ] && echo "config json str=$1"
    	echo "$1" >/dev/parental_control
	fi
}

load_base_config()
{
    local drop_anonymous
    config_get drop_anonymous "global" "drop_anonymous" "0"

    json_init
    json_add_int "op" $SET_BASE
    json_add_object "data"
    json_add_int "drop_anonymous" $drop_anonymous
    json_str=`json_dump`
    config_apply "$json_str"
    json_cleanup
}

load_rule()
{
    json_init
    json_add_int "op" $ADD_RULE
    json_add_object "data"
    json_add_array "rules"

    load_rule_cb(){
        local config=$1
        local action apps action_str exceptions
        config_get action_str "$config" "action"
        config_get apps "$config" "apps"
        config_get exceptions "$config" "exceptions"
        action="$(str_action_num $action_str)"
        json_add_object ""
        json_add_string "id" "$config"  
        json_add_int "action" $action
        [ -n "$apps" ] && {
            json_add_array "apps"
            for app in $apps;do
                json_add_int "" $app
            done
            json_select ..
        }
        [ -n "$exceptions" ] && {
            json_add_array "exceptions"
            for except in $exceptions;do
                json_add_string "" $except
            done
            json_select ..
        }
        json_select ..
    }

    config_foreach load_rule_cb rule

    json_str=`json_dump`
    config_apply "$json_str"
    json_cleanup
}

load_group()
{
    json_init
    json_add_int "op" $ADD_GROUP
    json_add_object "data"
    json_add_array "groups"

    load_group_cb(){
        local config=$1
        local rule macs
        config_get rule "$config" "default_rule"
        config_get macs "$config" "macs"
        json_add_object ""
        json_add_string "id" "$config"
        json_add_string "rule" $rule
        [ -n "$macs" ] && {
            json_add_array "macs"
            for mac in $macs;do
                json_add_string "" $mac
            done
            json_select ..
        }
        json_select ..
    }

    config_foreach load_group_cb group

    json_str=`json_dump`
    config_apply "$json_str"
    json_cleanup
}


clean_rule()
{
    json_init

    json_add_int "op" $CLEAN_RULE
    json_add_object "data"

    json_str=`json_dump`
    config_apply "$json_str"
    json_cleanup
}

clean_group()
{
    json_init

    json_add_int "op" $CLEAN_GROUP
    json_add_object "data"

    json_str=`json_dump`
    config_apply "$json_str"
    json_cleanup
}

set_group_rule()
{
    local config=$1
    local rule=$2
    local rule macs

    json_init
    json_add_int "op" $SET_GROUP
    json_add_object "data"
    json_add_array "groups"
        
    config_get macs "$config" "macs"
    json_add_object ""
    json_add_string "id" "$config"  
    json_add_string "rule" $rule
    [ -n "$macs" ] && {
        json_add_array "macs"
        for mac in $macs;do
            json_add_string "" $mac
        done
            json_select ..
    }
    json_select ..

    json_str=`json_dump`
    config_apply "$json_str"
    json_cleanup    
}

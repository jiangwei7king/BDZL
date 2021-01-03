#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Current folder
cur_dir=`pwd`
# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
software=(ä½¿ç”¨è‡ªç­¾è¯ä¹¦çš„WSSæ¨¡å¼ ä½¿ç”¨CFè¯ä¹¦çš„WSSæ¨¡å¼ TCPæ¨¡å¼ä¸”åŒæ—¶æ”¯æŒWSæ¨¡å¼)
operation=(å…¨æ–°å®‰è£… æ›´æ–°é…ç½® æ›´æ–°é•œåƒ æŸ¥çœ‹æ—¥å¿—)
# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] ä½ æ²¡æƒæ²¡åŠ¿ è¯·å…ˆèŽ·å–ROOTæƒé™!" && exit 1

#Check system
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
centosversion(){
    if check_sys sysRelease centos; then
        local code=$1
        local version="$(getversion)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
error_detect_depends(){
    local command=$1
    local depend=`echo "${command}" | awk '{print $4}'`
    echo -e "[${green}Info${plain}] å¼€å§‹å®‰è£…è½¯ä»¶åŒ… ${depend}"
    ${command} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] è½¯ä»¶åŒ…å®‰è£…å¤±è´¥ ${red}${depend}${plain}"
        echo "è¯·æŸ¥çœ‹å¸®åŠ©ç½‘ç«™: https://teddysun.com/486.html and contact."
        exit 1
    fi
}

# Pre-installation settings
pre_install_docker_compose(){
    # Set ssrpanel_url
    echo "è¯·è¾“å…¥ä½ SSPå‰ç«¯çš„ç½‘å€"
    read -p "(http://xxx.com æœ‰tlsçš„æ¢æˆhttps æ³¨æ„ç½‘å€æœ€åŽä¸è¦æœ‰æ–œæ â€˜/â€™):" ssrpanel_url
    [ -z "${ssrpanel_url}" ]
    echo
    echo "---------------------------"
    echo "SSPanelç½‘å€ = ${ssrpanel_url}"
    echo "---------------------------"
    echo
    # Set ssrpanel key
    echo "ä½ å‰ç«¯configæ–‡ä»¶é‡Œçš„Mukeyå€¼"
    read -p "(ä½ ç½‘ç«™ç›®å½•/www/wwwroot/xxx/config.php é‡Œé¢çš„mukeyå€¼ å‰åŽç«¯è¦å¯¹åº”):" ssrpanel_key
    [ -z "${ssrpanel_key}" ]
    echo
    echo "---------------------------"
    echo "SSPanelé€šä¿¡å¯†é’¥ = ${ssrpanel_key}"
    echo "---------------------------"
    echo

    # Set ssrpanel speedtest function
    echo "ä½ æ‰“ç®—éš”å¤šä¹…è¿›è¡Œä¸€æ¬¡èŠ‚ç‚¹ç½‘é€Ÿæµ‹è¯•"
    read -p "(å¤šä¹…ä¸€æ¬¡: å›žè½¦é»˜è®¤6å°æ—¶è¿›è¡Œä¸€æ¬¡):" ssrpanel_speedtest
    [ -z "${ssrpanel_speedtest}" ] && ssrpanel_speedtest=6
    echo
    echo "---------------------------"
    echo "å‡ å°æ—¶ä¸€æ¬¡ = ${ssrpanel_speedtest}"
    echo "---------------------------"
    echo

    # Set ssrpanel node_id
    echo "ä½ å‰ç«¯èŠ‚ç‚¹ä¿¡æ¯é‡Œé¢çš„èŠ‚ç‚¹ID"
    read -p "(å°±ä½ ä»–å¦ˆå‰ç«¯æ·»åŠ èŠ‚ç‚¹åŽç”Ÿæˆçš„ID æ¯”å¦‚è¯´æ˜¯3è¿™æ ·å­):" ssrpanel_node_id
    [ -z "${ssrpanel_node_id}" ] && ssrpanel_node_id=0
    echo
    echo "---------------------------"
    echo "SSPanelå‰ç«¯èŠ‚ç‚¹ID = ${ssrpanel_node_id}"
    echo "---------------------------"
    echo

    # Set V2ray backend API Listen port
    echo "è¯·è®¾ç½®V2RAYçš„å‡ºå£ç›‘å¬ç«¯å£"
    read -p "(å›žè½¦é»˜è®¤2333ç«¯å£å³å¯ å¦‚æœ‰å¤šå¼€åˆç§Ÿè¯·ä¸è¦é‡å¤):" v2ray_api_port
    [ -z "${v2ray_api_port}" ] && v2ray_api_port=2333
    echo
    echo "---------------------------"
    echo "V2RAYå‡ºå£ç›‘å¬ç«¯å£ = ${v2ray_api_port}"
    echo "---------------------------"
    echo

    # Set Setting if the node go downwith panel
    echo "è¯·é—®ä½ å‰ç«¯é¢æ¿æ˜¯ä»€ä¹ˆç¨‹åº"
    read -p "(å›žè½¦é»˜è®¤SSPANELé¢æ¿ï¼š1):" v2ray_downWithPanel
    [ -z "${v2ray_downWithPanel}" ] && v2ray_downWithPanel=1
    echo
    echo "---------------------------"
    echo "å‰ç«¯é¢æ¿ç±»åž‹ = ${v2ray_downWithPanel}"
    echo "---------------------------"
    echo
}

pre_install_caddy(){

    # Set caddy v2ray domain
    echo "è¯·è¾“å…¥ä½ è§£æžåˆ°æœ¬èŠ‚ç‚¹æœåŠ¡å™¨çš„åŸŸå"
    read -p "WSæ¨¡å¼è¦æ±‚æä¾›è§£æžåˆ°æœ¬èŠ‚ç‚¹IPçš„ç½‘å€:" v2ray_domain
    [ -z "${v2ray_domain}" ]
    echo
    echo "---------------------------"
    echo "ä¼ªè£…åŸŸå = ${v2ray_domain}"
    echo "---------------------------"
    echo


    # Set caddy v2ray path
    echo "CADDYåä»£åˆ°V2RAYçš„è™šæ‹Ÿç›®å½•"
    read -p "(åŠ¡å¿…äºŽå‰ç«¯èŠ‚ç‚¹ä¿¡æ¯çš„Pathå€¼ç›¸åŒ,å›žè½¦é»˜è®¤: /v2ray):" v2ray_path
    [ -z "${v2ray_path}" ] && v2ray_path="/v2ray"
    echo
    echo "---------------------------"
    echo "ä¼ªè£…ç›®å½• = ${v2ray_path}"
    echo "---------------------------"
    echo

    # Set caddy v2ray tls email
    echo "å‰ç«¯èŽ·å–TLSè¯ä¹¦æ—¶ç™»è®°çš„é‚®ç®±"
    read -p "ç›´æŽ¥å›žè½¦é»˜è®¤å³å¯(admin@admin.com):" v2ray_email
    [ -z "${v2ray_email}" ] && v2ray_email="admin@admin.com"
    echo
    echo "---------------------------"
    echo "è¯ä¹¦é‚®ç®± = ${v2ray_email}"
    echo "---------------------------"
    echo

    # Set Caddy v2ray listen port
    echo "V2RAYåŽç«¯å…¥å£ç›‘å¬ç«¯å£"
    read -p "(å¦‚å¤šå¼€åˆç§Ÿæ³¨æ„è¯·ä¸è¦é‡å¤,å›žè½¦é»˜è®¤ç«¯å£: 10550):" v2ray_local_port
    [ -z "${v2ray_local_port}" ] && v2ray_local_port=10550
    echo
    echo "---------------------------"
    echo "V2RAYåŽç«¯å…¥å£ç›‘å¬ç«¯å£ = ${v2ray_local_port}"
    echo "---------------------------"
    echo

    # Set Caddy  listen port
    echo "CADDYå‰ç«¯å…¥å£ç›‘å¬ç«¯å£"
    read -p "(å¦‚å¤šå¼€åˆç§Ÿæ³¨æ„è¯·ä¸è¦é‡å¤,å›žè½¦é»˜è®¤ç«¯å£: 443):" caddy_listen_port
    [ -z "${caddy_listen_port}" ] && caddy_listen_port=443
    echo
    echo "---------------------------"
    echo "CADDYå‰ç«¯å…¥å£ç›‘å¬ç«¯å£ = ${caddy_listen_port}"
    echo "---------------------------"
    echo


}

# Config docker
config_docker(){
    echo "æŒ‰ä»»æ„é”®è¿›è¡Œä¸‹ä¸€æ­¥...æˆ–è€…æŒ‰ Ctrl+C å–æ¶ˆå®‰è£…"
    char=`get_char`
    cd ${cur_dir}
    echo "å¼€å§‹å®‰è£…è½¯ä»¶åŒ…"
    install_dependencies
    echo "ç­‰å¾…åŠ è½½DOCKERé…ç½®æ–‡ä»¶"
    curl -L https://raw.githubusercontent.com/hulisang/v2ray-sspanel-v3-mod_Uim-plugin/master/Docker/V2ray/docker-compose.yml > docker-compose.yml
    sed -i "s|node_id:.*|node_id: ${ssrpanel_node_id}|"  ./docker-compose.yml
    sed -i "s|sspanel_url:.*|sspanel_url: '${ssrpanel_url}'|"  ./docker-compose.yml
    sed -i "s|key:.*|key: '${ssrpanel_key}'|"  ./docker-compose.yml
    sed -i "s|speedtest:.*|speedtest: ${ssrpanel_speedtest}|"  ./docker-compose.yml
    sed -i "s|api_port:.*|api_port: ${v2ray_api_port}|" ./docker-compose.yml
    sed -i "s|downWithPanel:.*|downWithPanel: ${v2ray_downWithPanel}|" ./docker-compose.yml
}


# Config caddy_docker
config_caddy_docker(){
    echo "æŒ‰ä»»æ„é”®è¿›è¡Œä¸‹ä¸€æ­¥...æˆ–è€…æŒ‰ Ctrl+C å–æ¶ˆå®‰è£…"
    char=`get_char`
    cd ${cur_dir}
    echo "å¼€å§‹å®‰è£…è½¯ä»¶åŒ…"
    install_dependencies
    curl -L https://raw.githubusercontent.com/hulisang/v2ray-sspanel-v3-mod_Uim-plugin/master/Docker/Caddy_V2ray/Caddyfile >  Caddyfile
    echo "ç­‰å¾…åŠ è½½DOCKERé…ç½®æ–‡ä»¶"
    curl -L https://raw.githubusercontent.com/hulisang/v2ray-sspanel-v3-mod_Uim-plugin/master/Docker/Caddy_V2ray/docker-compose.yml > docker-compose.yml
    sed -i "s|node_id:.*|node_id: ${ssrpanel_node_id}|"  ./docker-compose.yml
    sed -i "s|sspanel_url:.*|sspanel_url: '${ssrpanel_url}'|"  ./docker-compose.yml
    sed -i "s|key:.*|key: '${ssrpanel_key}'|"  ./docker-compose.yml
    sed -i "s|speedtest:.*|speedtest: ${ssrpanel_speedtest}|"  ./docker-compose.yml
    sed -i "s|api_port:.*|api_port: ${v2ray_api_port}|" ./docker-compose.yml
    sed -i "s|downWithPanel:.*|downWithPanel: ${v2ray_downWithPanel}|" ./docker-compose.yml
    sed -i "s|V2RAY_DOMAIN=xxxx.com|V2RAY_DOMAIN=${v2ray_domain}|"  ./docker-compose.yml
    sed -i "s|V2RAY_PATH=/v2ray|V2RAY_PATH=${v2ray_path}|"  ./docker-compose.yml
    sed -i "s|V2RAY_EMAIL=xxxx@outlook.com|V2RAY_EMAIL=${v2ray_email}|"  ./docker-compose.yml
    sed -i "s|V2RAY_PORT=10550|V2RAY_PORT=${v2ray_local_port}|"  ./docker-compose.yml
    sed -i "s|V2RAY_OUTSIDE_PORT=443|V2RAY_OUTSIDE_PORT=${caddy_listen_port}|"  ./docker-compose.yml
}

# Config caddy_docker
config_caddy_docker_cloudflare(){

    # Set caddy cloudflare ddns email
    echo "ä½ CFçš„é‚®ç®±è´¦å·"
    read -p "(No default ):" cloudflare_email
    [ -z "${cloudflare_email}" ]
    echo
    echo "---------------------------"
    echo "ä½ CFçš„é‚®ç®±è´¦å· = ${cloudflare_email}"
    echo "---------------------------"
    echo

    # Set caddy cloudflare ddns key
    echo "ä½ CFçš„KEYå¯†é’¥"
    read -p "(No default ):" cloudflare_key
    [ -z "${cloudflare_email}" ]
    echo
    echo "---------------------------"
    echo "ä½ CFçš„KEYå¯†é’¥ = ${cloudflare_key}"
    echo "---------------------------"
    echo
    echo

    echo "æŒ‰ä»»æ„é”®è¿›è¡Œä¸‹ä¸€æ­¥...æˆ–è€…æŒ‰ Ctrl+C å–æ¶ˆå®‰è£…"
    char=`get_char`
    cd ${cur_dir}
    echo "æˆ‘å…ˆå®‰è£…curl "
    install_dependencies
    echo "å¼€å§‹åŠ è½½CADDYå’ŒDOCKERçš„é…ç½®æ–‡ä»¶"
    curl -L https://raw.githubusercontent.com/hulisang/v2ray-sspanel-v3-mod_Uim-plugin/master/Docker/Caddy_V2ray/Caddyfile >Caddyfile
    epcho "åŠ è½½DOCKERçš„é…ç½®æ–‡ä»¶ä¸­"
    curl -L https://raw.githubusercontent.com/hulisang/v2ray-sspanel-v3-mod_Uim-plugin/master/Docker/Caddy_V2ray/docker-compose.yml >docker-compose.yml
    sed -i "s|node_id:.*|node_id: ${ssrpanel_node_id}|"  ./docker-compose.yml
    sed -i "s|sspanel_url:.*|sspanel_url: '${ssrpanel_url}'|"  ./docker-compose.yml
    sed -i "s|key:.*|key: '${ssrpanel_key}'|"  ./docker-compose.yml
    sed -i "s|speedtest:.*|speedtest: ${ssrpanel_speedtest}|"  ./docker-compose.yml
    sed -i "s|api_port:.*|api_port: ${v2ray_api_port}|" ./docker-compose.yml
    sed -i "s|downWithPanel:.*|downWithPanel: ${v2ray_downWithPanel}|" ./docker-compose.yml
    sed -i "s|V2RAY_DOMAIN=xxxx.com|V2RAY_DOMAIN=${v2ray_domain}|"  ./docker-compose.yml
    sed -i "s|V2RAY_PATH=/v2ray|V2RAY_PATH=${v2ray_path}|"  ./docker-compose.yml
    sed -i "s|V2RAY_EMAIL=xxxx@outlook.com|V2RAY_EMAIL=${v2ray_email}|"  ./docker-compose.yml
    sed -i "s|V2RAY_PORT=10550|V2RAY_PORT=${v2ray_local_port}|"  ./docker-compose.yml
    sed -i "s|V2RAY_OUTSIDE_PORT=443|V2RAY_OUTSIDE_PORT=${caddy_listen_port}|"  ./docker-compose.yml
    sed -i "s|#      - CLOUDFLARE_EMAIL=xxxxxx@out.look.com|      - CLOUDFLARE_EMAIL=${cloudflare_email}|"  ./docker-compose.yml
    sed -i "s|#      - CLOUDFLARE_API_KEY=xxxxxxx|      - CLOUDFLARE_API_KEY=${cloudflare_key}|"  ./docker-compose.yml
    sed -i "s|# dns cloudflare|dns cloudflare|"  ./Caddyfile

}

# Install docker and docker compose
install_docker(){
    echo -e "å¼€å§‹å®‰è£… DOCKER "
    curl -fsSL https://get.docker.com -o get-docker.sh
    bash get-docker.sh
    echo -e "å¼€å§‹å®‰è£… Docker Compose "
    curl -L https://github.com/docker/compose/releases/download/1.17.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    curl -L https://raw.githubusercontent.com/docker/compose/1.8.0/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose
    clear
    echo "å¯åŠ¨ Docker "
    service docker start
    echo "å¯åŠ¨ Docker-Compose "
    docker-compose up -d
    echo
    echo -e "æ­å–œï¼ŒV2rayæœåŠ¡å™¨å®‰è£…å®Œæˆï¼"
    echo
    echo "æ³¨æ„:å®‰è£…å®Œæˆä¸ä»£è¡¨å®‰è£…æˆåŠŸ å¯èƒ½åŽŸå› æœ‰ï¼š"
    echo "1ã€ä½ æœªè´­ä¹°æœ¬V2RAYåŽç«¯è„šæœ¬ï¼ŒæœªèŽ·å¾—æŽˆæƒå®‰è£…å¤±è´¥"
    echo "2ã€ä½ çš„ç³»ç»Ÿæˆ–è€…ç®¡ç†é¢æ¿å†…ç½®é˜²ç«å¢™ è¯·å…³é—­æˆ–æ”¾è¡Œ"
    echo "3ã€è„šæœ¬é…ç½®ä¿¡æ¯è¾“å…¥æœ‰è¯¯ æ£€æŸ¥å‰ç«¯ç½‘å€å¯†é’¥èŠ‚ç‚¹ID"
    echo "4ã€çŽ„å­¦é—®é¢˜ ä½ å¤ªå¸…å¯¼è‡´çš„ æŒ‡å¯¼è”ç³»TG@WocaonimaB"
    echo
}

install_check(){
    if check_sys packageManager yum || check_sys packageManager apt; then
        if centosversion 5; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

install_select(){
    clear
    while true
    do
    echo  "æ‚¨é€‰æ‹©å“ªä¸ªV2RAYåŽç«¯å®‰è£…æ–¹å¼:"
    for ((i=1;i<=${#software[@]};i++ )); do
        hint="${software[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "(æŽ¨èå›žè½¦${software[0]}):" selected
    [ -z "${selected}" ] && selected="1"
    case "${selected}" in
        1|2|3|4)
        echo
        echo "ä½ é€‰æ‹©äº† = ${software[${selected}-1]}"
        echo
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] åˆ«çžŽå‡ æŠŠä¹±è¾“,è¯·è¾“å…¥æ­£ç¡®æ•°å­—"
        ;;
    esac
    done
}
install_dependencies(){
    if check_sys packageManager yum; then
        echo -e "[${green}Info${plain}] æ£€æŸ¥EPELå­˜å‚¨åº“..."
        if [ ! -f /etc/yum.repos.d/epel.repo ]; then
            yum install -y epel-release > /dev/null 2>&1
        fi
        [ ! -f /etc/yum.repos.d/epel.repo ] && echo -e "[${red}Error${plain}] å®‰è£…EPELå‚¨å­˜åº“å¤±è´¥ï¼Œè¯·æ£€æŸ¥ä¸€ä¸‹." && exit 1
        [ ! "$(command -v yum-config-manager)" ] && yum install -y yum-utils > /dev/null 2>&1
        [ x"$(yum-config-manager epel | grep -w enabled | awk '{print $3}')" != x"True" ] && yum-config-manager --enable epel > /dev/null 2>&1
        echo -e "[${green}Info${plain}] æ£€æŸ¥EPELå‚¨å­˜åº“æ˜¯å¦å®Œæ•´..."

        yum_depends=(
             curl
        )
        for depend in ${yum_depends[@]}; do
            error_detect_depends "yum -y install ${depend}"
        done
    elif check_sys packageManager apt; then
        apt_depends=(
           curl
        )
        apt-get -y update
        for depend in ${apt_depends[@]}; do
            error_detect_depends "apt-get -y install ${depend}"
        done
    fi
    echo -e "[${green}Info${plain}] å°†æ—¶åŒºè®¾ç½®ä¸ºä¸Šæµ·"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"

}
#update_image
æ›´æ–°é•œåƒ_v2ray(){
    echo "å…³é—­å½“å‰æœåŠ¡"
    docker-compose down
    echo "åŠ è½½DOCKERé•œåƒ"
    docker-compose pull
    echo "å¼€å§‹è¿è¡ŒDOKCERæœåŠ¡"
    docker-compose up -d
}

#show last 100 line log

æŸ¥çœ‹æ—¥å¿—_v2ray(){
    echo "å°†è¦æ˜¾ç¤º100è¡Œçš„è¿è¡Œæ—¥å¿—"
    docker-compose logs --tail 100
}

# Update config
æ›´æ–°é…ç½®_v2ray(){
    cd ${cur_dir}
    echo "å…³é—­å½“å‰æœåŠ¡"
    docker-compose down
    install_select
    case "${selected}" in
        1)
        pre_install_docker_compose
        pre_install_caddy
        config_caddy_docker
        ;;
        2)
        pre_install_docker_compose
        pre_install_caddy
        config_caddy_docker_cloudflare
        ;;
        3)
        pre_install_docker_compose
        config_docker
        ;;
        *)
        echo "é”™è¯¯çš„æ•°å­—"
        ;;
    esac

    echo "å¼€å§‹è¿è¡ŒDOKCERæœåŠ¡"
    docker-compose up -d

}
# remove config
# Install v2ray
å…¨æ–°å®‰è£…_v2ray(){
    install_select
    case "${selected}" in
        1)
        pre_install_docker_compose
        pre_install_caddy
        config_caddy_docker
        ;;
        2)
        pre_install_docker_compose
        pre_install_caddy
        config_caddy_docker_cloudflare
        ;;
        3)
        pre_install_docker_compose
        config_docker
        ;;
        *)
        echo "é”™è¯¯çš„æ•°å­—"
        ;;
    esac
    install_docker
}

# Initialization step
clear
while true
do
echo -e "\033[42;30m æ­¤ä¸ºç”±ç‹ç‹¸çš„è„šæœ¬æ±‰åŒ–ç‰ˆ ä¸æ”¯æŒå®¡è®¡è®¾å¤‡é™é€Ÿ \033[0m"
echo -e "\033[42;30m å¦‚éœ€ä»£æ­å»ºæˆ–éœ€æŠ€æœ¯æŒ‡å¯¼è¯·è”ç³»TG:@WocaonimaB \033[0m"
echo  ""
echo  "è¯·è¾“å…¥æ•°å­—é€‰æ‹©ä½ è¦è¿›è¡Œçš„æ“ä½œï¼š"
for ((i=1;i<=${#operation[@]};i++ )); do
    hint="${operation[$i-1]}"
    echo -e "${green}${i}${plain}) ${hint}"
done
read -p "è¯·é€‰æ‹©æ•°å­—åŽå›žè½¦ (å›žè½¦é»˜è®¤ ${operation[0]}):" selected
[ -z "${selected}" ] && selected="1"
case "${selected}" in
    1|2|3|4)
    echo
    echo "ä½ çš„æƒ³æ³• = ${operation[${selected}-1]}"
    echo
    ${operation[${selected}-1]}_v2ray
    break
    ;;
    *)
    echo -e "[${red}Error${plain}] ä½ å¦ˆé€¼å•Š,è¯·è¾“å…¥æ­£ç¡®æ•°å­— [1-4]"
    ;;
esac
done

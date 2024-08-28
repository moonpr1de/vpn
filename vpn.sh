#!/bin/bash
 
BLUE_BG=$(tput setab 6)
GREEN_BG=$(tput setab 42)
BLACK_FG=$(tput setaf 0)
RESET=$(tput sgr0)
 
# Добавим прокси для Dockerhub
sudo mkdir -vp /etc/docker/
echo '{ "registry-mirrors" : [ "https://dockerhub.timeweb.cloud" ] }' | sudo tee -a /etc/docker/daemon.json
sudo systemctl reload docker
 
# Добавим localhost в hosts
echo 127.0.0.1 localhost | sudo tee -a /etc/hosts
 
sudo apt install curl -y
 
main_code() {
# Функция для проверки корректности ответа
check_answer() {
	if [ "$1" == "y" ] || [ "$1" == "n" ]; then
		return 0
	else
		return 1
	fi
}
 
# Цикл для запроса ответа пользователя
while true; do
	# Спрашиваем пользователя, хочет ли он подключаться к серверу по своему домену
	read -p "Do you want to be able to connect to the server using your own domain name? ${BLUE_BG}${BLACK_FG}For example: my-server.com${RESET}:
----------
Хотите ли вы иметь возможность подключаться к серверу, используя ваше собственное доменное имя? ${GREEN_BG}${BLACK_FG}Например: my-server.com${RESET} 
(y/n) " answer
 
	# Проверяем ответ пользователя
	if check_answer "$answer"; then
		break
	else
		echo "Incorrect answer. Please enter '${BLUE_BG}${BLACK_FG}y${RESET}' or '${BLUE_BG}${BLACK_FG}n${RESET}'.
----------
Неверный ответ. Пожалуйста, введите '${GREEN_BG}${BLACK_FG}y${RESET}' или '${GREEN_BG}${BLACK_FG}n${RESET}'."
		sleep 1
	fi
done
 
# Проверяем ответ пользователя
if [ "$answer" == "y" ]; then
    # Если пользователь хочет использовать домен, запрашиваем новое значение
    while true; do
        read -p "Enter the domain name you're going to use ${BLUE_BG}${BLACK_FG}(Don't forget to set $main_ip as an А-Record value)${RESET}:
----------
Введите доменное имя, которое вы собираетесь использовать ${GREEN_BG}${BLACK_FG}(Не забудьте установить $main_ip в качестве значения A-записи)${RESET}:
=====> " new_hostname
        if [ -n "$new_hostname" ]; then
            # Устанавливаем новый hostname
            sudo hostnamectl set-hostname "$new_hostname"
            echo "Great, hostname has been changed to ${BLUE_BG}${BLACK_FG}$new_hostname${RESET}.
----------
Отлично, хостнейм изменен на ${GREEN_BG}${BLACK_FG}$new_hostname${RESET}."
            break
        else
            echo "${BLUE_BG}${BLACK_FG}Hostname cannot be empty. Please enter a valid domain name.${RESET}
----------
${GREEN_BG}${BLACK_FG}Имя хоста не может быть пустым. Пожалуйста, введите действительное доменное имя.${RESET}"
			sleep 1
        fi
    done
elif [ "$answer" == "n" ]; then
    echo "Okie, then we'll use the IP address ${BLUE_BG}${BLACK_FG}$main_ip${RESET}.
----------
Оки, тогда будем использовать IP адрес ${GREEN_BG}${BLACK_FG}$main_ip${RESET}."
    sudo hostnamectl set-hostname "$main_ip"
fi
 
echo "${BLUE_BG}${BLACK_FG}Getting ready...${RESET}
----------
${GREEN_BG}${BLACK_FG}Подготовка...${RESET}"
 
sleep 3
 
echo "${BLUE_BG}${BLACK_FG}Updating application list...${RESET}"
sudo apt update # Обновление списков пакетов
echo "${GREEN_BG}${BLACK_FG}Done: Updating application list!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Updating applications...${RESET}"
sudo apt upgrade -y # Обновление устаревших пакетов
echo "${GREEN_BG}${BLACK_FG}Done: Updating applications!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Installing Fail2Ban...${RESET}"
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo "${GREEN_BG}${BLACK_FG}Done: Installing Fail2Ban!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Installing Nginx...${RESET}"
sudo apt install nginx -y # Установка Nginx
echo "${GREEN_BG}${BLACK_FG}Done: Installing Nginx!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Installing Apache utilities...${RESET}"
sudo apt install apache2-utils -y # Установка пакета утилит Apache
echo "${GREEN_BG}${BLACK_FG}Done: Installing Apache utilities!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Installing PHP-FPM...${RESET}"
sudo apt install nginx php-fpm -y
echo "${GREEN_BG}${BLACK_FG}Done: Installing PHP-FPM!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Installing PHP-Curl...${RESET}"
sudo apt install php-curl -y
echo "${GREEN_BG}${BLACK_FG}Done: Installing PHP-Curl!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Turning on Nginx autorun...${RESET}"
sudo systemctl enable nginx # Автозапуск Nginx при загрузке системы
echo "${GREEN_BG}${BLACK_FG}Done: Turning on Nginx autorun!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Deleting /var/www/html folder...${RESET}"
sudo rm /var/www/html -r # Удаление стандартной папки сайта
echo "${GREEN_BG}${BLACK_FG}Done: Deleting /var/www/html folder!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Deleting default Nginx config...${RESET}"
sudo rm /etc/nginx/sites-available/default # Удаление стандартного конфига сайта
echo "${GREEN_BG}${BLACK_FG}Done: Deleting default Nginx config!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Deleting default Nginx config symbolic link...${RESET}"
sudo rm /etc/nginx/sites-enabled/default # Удаление ярлыка стандартного конфига сайта
echo "${GREEN_BG}${BLACK_FG}Done: Deleting default Nginx config symbolic link!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Installing Docker...${RESET}"
# Установка Docker
sudo apt install -y \
	ca-certificates \
	gnupg \
	lsb-release \
	software-properties-common
 
sudo curl https://get.docker.com | sh -f
sudo apt install docker.io -y
echo "${GREEN_BG}${BLACK_FG}Done: Installing Docker!${RESET}"
 
# Генерация пароля GUI
SYMBOLS=""
	for symbol in {A..Z} {a..z} {0..9}; do SYMBOLS=$SYMBOLS$symbol; done
SYMBOLS=$SYMBOLS'!@#$%&*()?/\[]{}-+_=<>.,'
# Строка со всеми символами создана.
# Теперь нам надо в цикле с количеством итераций равным длине пароля
# случайным образом взять один символ и добавить его в строку, содержащую пароль.
PWD_LENGTH=16  # длина пароля
PASSWORD=""    # переменная для хранения пароля
RANDOM=256     # инициализация генератора случайных чисел
	for i in `seq 1 $PWD_LENGTH`
		do PASSWORD=$PASSWORD${SYMBOLS:$(expr $RANDOM % ${#SYMBOLS}):1}
	done
 
# Получаем текущий hostname
current_hostname=$(hostname)
 
echo "${BLUE_BG}${BLACK_FG}Installing Wireguard GUI...${RESET}"
# Установка Wireguard GUI
WG_GUI_PORT="51821"
 
docker run -d \
	--name=wg-easy \
	-e WG_HOST=$current_hostname \
	-e PASSWORD=$PASSWORD \
	-e WG_PORT=8080 \
	-e WG_DEFAULT_ADDRESS=10.1.1.x \
	-v ~/.wg-easy:/etc/wireguard \
	-p 8080:51820/udp \
	-p $WG_GUI_PORT:51821/tcp \
	--cap-add=NET_ADMIN \
	--cap-add=SYS_MODULE \
	--sysctl="net.ipv4.conf.all.src_valid_mark=1" \
	--sysctl="net.ipv4.ip_forward=1" \
	--restart unless-stopped \
	weejewel/wg-easy
 
echo "Wireguard GUI: http://$current_hostname:$WG_GUI_PORT | Password: $PASSWORD" | sudo tee -a credentials.txt
echo "${GREEN_BG}${BLACK_FG}Done: Installing Wireguard GUI!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Installing Outline...${RESET}"
# Установка Outline
wget https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh
yes | sudo bash install_server.sh --hostname $current_hostname --keys-port 8081 > outline_manager_output.txt
OUTLINE_MANAGER_KEY=$(sudo grep -oE '\{"api.*"}' outline_manager_output.txt) # Создаем переменную с ключом для подключения к Outline Manager
sudo rm install_server.sh -f
sudo rm outline_manager_output.txt
echo "Outline Manager key: $OUTLINE_MANAGER_KEY" | sudo tee -a credentials.txt
echo "${GREEN_BG}${BLACK_FG}Done: Installing Outline!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Creating HTTP user: Login: outline , Password: $PASSWORD ...${RESET}"
sudo htpasswd -c -b /etc/nginx/auth.htpasswd outline $PASSWORD # Создание пользователя для сайта с логином outline и паролем outline
echo "${GREEN_BG}${BLACK_FG}Done: Creating HTTP user: Login: outline , Password: $PASSWORD !${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Creating system user: Login: outline , Password: $PASSWORD ...${RESET}"
sudo useradd outline
echo 'outline:$PASSWORD' | sudo chpasswd
usermod -aG sudo outline
echo "${GREEN_BG}${BLACK_FG}Done: Creating system user: Login: outline , Password: $PASSWORD !${RESET}"
 
sudo php -v > php_version.txt # Узнаем версию PHP
PHP_VERSION=$(head -n 1 php_version.txt | grep "PHP" | awk '{print $2}' | cut -c 1-3) # Задаем переменную PHP_VERSION, чтобы далее найти путь до php-fpm sock
sudo rm php_version.txt
 
sudo tee /etc/php/$PHP_VERSION/fpm/pool.d/outline.conf > /dev/null <<'ENDOFFILE'
[outline]
user = outline
group = outline
listen = /var/run/outline.sock
 
listen.owner = outline
listen.group = www-data
listen.mode = 0660
 
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
 
chdir = /
 
php_admin_value[open_basedir] = /var/www/outline:/tmp
php_admin_value[upload_tmp_dir] = /var/www/outline/tmp
php_admin_value[session.save_path] = /var/www/outline/sessions
ENDOFFILE
 
sudo systemctl restart php$PHP_VERSION-fpm
 
echo "${BLUE_BG}${BLACK_FG}Creating new Nginx config...${RESET}"
# Создание конфига для сайта:
echo "Outline Web-GUI: http://$current_hostname:8181 | Login: outline | Password: $PASSWORD" | sudo tee -a credentials.txt
sudo tee /etc/nginx/sites-available/outline > /dev/null <<EOF
server {
        listen 8181;
        listen [::]:8181;
 
        root /var/www/outline;
        index index.php;
 
        server_name $current_hostname www.$current_hostname;
 
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/auth.htpasswd;
 
		location / {
			# Запрещаем доступ к скрытым файлам и папкам (начинающимся с точки)
			location ~ /\. {
				deny all;
				return 404;
			}
 
			# Запрещаем доступ к системным файлам и скриптам
			location ~* \.(sh|pl|py|cgi|conf|config|htaccess|htpasswd|log)$ {
				deny all;
				return 404;
			}
 
			# Пробуем обслужить файл напрямую, иначе передаем запрос на index.php
			try_files \$uri \$uri/ /index.php?\$query_string;
		}
 
        location ~ \.php\$ {
            fastcgi_pass unix:/var/run/outline.sock;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include fastcgi_params;
        }
}
EOF
 
echo "${GREEN_BG}${BLACK_FG}Done: Creating new Nginx config!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Creating new Nginx config symbolic link...${RESET}"
sudo ln -s /etc/nginx/sites-available/outline /etc/nginx/sites-enabled/ # Создание ярлыка конфига для сайта
echo "${GREEN_BG}${BLACK_FG}Done: Creating new Nginx config symbolic link!${RESET}"
 
echo "${BLUE_BG}${BLACK_FG}Restarting Nginx...${RESET}"
sudo systemctl reload nginx # Перезагрузка Nginx
echo "${GREEN_BG}${BLACK_FG}Done: Restarting Nginx!${RESET}"
 
# Кладем ключ для подключения к Outline Manager в файл /var/www/html/outline_manager_key.php
sudo mkdir -vp /var/www/outline/
sudo mkdir -vp /var/www/outline/scripts
 
sudo cat > /var/www/outline/outline_manager_key.php <<ENDOFFILE
$OUTLINE_MANAGER_KEY
ENDOFFILE
 
sudo tee /var/www/outline/outline-logo-short.svg > /dev/null <<'ENDOFFILE'
<svg width="99" height="96" viewBox="0 0 99 96" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M98.7213 42.9356C96.2541 20.2838 77.8735 2.6607 55 0V19.5162C70.9004 22.5282 81.5289 37.2499 78.8149 52.7977C76.7308 64.7286 67.2191 74.1094 55 76.4253V96C82.0613 92.8449 101.585 69.2498 98.7213 42.9356Z" fill="#183729"/>
<path d="M0.263427 53.0674C1.39731 63.9525 6.1428 74.1259 13.7241 81.9244C21.3053 89.723 31.2739 94.6853 42 96V0C29.5587 1.52202 18.2076 7.94082 10.3985 17.87C2.58931 27.7992 -1.05113 40.4419 0.263427 53.0674Z" fill="#5BB193"/>
</svg>
ENDOFFILE
 
sudo tee /var/www/outline/index.php > /dev/null <<'ENDOFFILE'
<?php
$keyFile = './outline_manager_key.php';
$keyContent = file_get_contents($keyFile);
$keyData = json_decode($keyContent, true);
?>
 
<!DOCTYPE html>
<html>
<head>
    <title>Outline Home</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/svg+xml" href="./outline-logo-short.svg" />
    <style>
    .container {
        display: flex;
        flex-direction: column;
        width: 100%;
        max-width: 1000px;
        margin: 0 auto;
        padding: 2rem;
        text-align: center;
    }
 
    h1 {
        text-align: left;
        font-size: 24px;
        font-weight: 500;
        margin: 0;
    }
 
    .logo {
        width: 300px;
    }
 
    .wrapper {
        background-color: #283339;
        margin-bottom: 32px;
        color: white;
        padding: 16px;
        box-sizing: border-box;
        word-break: break-all;
        border-radius: 10px;
        overflow: hidden;
    }
 
    .wrapper > button {
        text-align: center !important;
    }
 
    .listWrapper {
        border-radius: 10px;
        overflow: hidden;
        padding: 16px;
        padding-bottom: 0;
        padding-top: 0;
        background-color: white;
    }
 
    .buttonWrapper {
        display: flex;
        gap: 16px;
        margin: 0 auto;
        align-items: center;
        justify-content: center;
    }
 
    .buttonWrapper > button {
        background-color: #fff;
        padding: 16px;
        border: none;
        font-size: 14px;
        border-radius: 10px;
        cursor: pointer;
    }
 
    .buttonWrapper > button:hover {
        opacity: 0.8;
    }
 
    .list {
        list-style: none;
        box-sizing: border-box;
        width: 100%;
        padding: 0;
        margin: 0;
        row-gap: 16px;
    }
 
    .item {
        padding: 5px;
        width: 100%;
        display: grid;
        grid-template-columns: 50px 70px 1fr 50px;
        box-sizing: border-box;
        justify-content: center;
        align-items: center;
        word-break: break-all;
        gap: 10px;
        border-bottom: 1px solid lightgray;
    }
 
    .item:last-child {
        border: none;
    }
 
    .button {
        border: none;
        border-radius: 7px;
        padding: 16px;
        border: 1px solid lightgray;
        cursor: pointer;
        background-color: #f5f5f5;
        min-height: 50px;
    }
 
    .button > svg {
        width: 22px;
        height: 19px;
    }
 
    .button:hover {
        opacity: 0.8;
    }
 
    .buttonDelete {
        background-color: #207f75;
        border: 1px solid #183729;
        color: #207f75;
        width: 50px;
        height: 50px;
        display: flex;
        justify-content: center;
        align-items: center;
        justify-self: flex-end;
    }
 
    .buttonRegenerate {
        width: auto;
        color: white;
    }
 
    .titleWrapper {
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-bottom: 2px solid lightgray;
        padding-top: 16px;
        padding-bottom: 16px;
    }
 
    .titleWrapper > p {
        margin: 0;
        font-size: 24px;
        font-weight: 500;
    }
 
    .bucket {
        width: 50px;
    }
 
    .buttonCode {
        padding-top: 10px;
        padding-bottom: 10px;
        font-size: 12px;
        display: flex;
        align-items: center;
        gap: 16px;
        justify-content: space-between;
    }
 
    .manageWrapper {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 16px;
        box-sizing: border-box;
    }
 
    .logout {
        border: none;
        background: none;
        display: flex;
        align-items: center;
        gap: 5px;
        cursor: pointer;
    }
 
    .logout:hover {
        opacity: 0.8;
    }
 
    .logout > svg {
        width: 15px;
        height: 15px;
    }
 
    .popupWrapper {
        background-color: rgba(0, 0, 0, 0.5);
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: 500;
    }
 
    .popup {
        width: 250px;
        display: flex;
        flex-direction: column;
        row-gap: 16px;
        padding: 16px;
        background-color: white;
        border-radius: 15px;
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translateY(-50%) translateX(-50%);
    }
 
    .popup h3 {
        margin: 0;
    }
 
    .input {
        border-radius: 10px;
        padding: 12px;
    }
    </style>
</head>
<body>
    <div class="container">
        <div id="createNewClientPopup" class="popupWrapper" style="display: none;" onclick="closePopup(event)">
            <div class="popup">
                <h3>Create new client</h3>
                <input type="text" id="clientNameInput" class="input" placeholder="Enter name">
                <button class="button" id="createClientButton" disabled>Create</button>
            </div>
        </div>
 
        <div class="manageWrapper">
            <svg class="logo" id="Layer_1" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 728.18 150"><defs><style>.cls-1{fill:#183729;}.cls-2{fill:#5bb193;}</style></defs><title>Outline web assets</title><path class="cls-1" d="M151.8,67.21C148,32.39,119.69,5.3,84.46,1.21v30c24.49,4.63,40.86,27.26,36.68,51.16-3.21,18.34-17.86,32.76-36.68,36.32v30.09C126.14,143.93,156.21,107.66,151.8,67.21Z"/><path class="cls-2" d="M1.31,82.79a74.34,74.34,0,0,0,65,66V1.21A74.32,74.32,0,0,0,1.31,82.79Z"/><g id="ART"><path class="cls-1" d="M218.88,75.57v-.91c0-33.76,21.13-55.19,51.69-55.19S322.2,40.9,322.2,74.66v.91c0,33.75-21.13,55.19-51.68,55.19S218.88,109.32,218.88,75.57Zm79.51.75V73.85c0-22.49-11.56-36-27.82-36s-27.83,13.53-27.83,36v2.47c0,22.51,11.56,36,27.83,36s27.77-13.53,27.77-36Z"/><path class="cls-1" d="M404.59,128.32H382.85v-11.7a27,27,0,0,1-24,13.83c-16.43,0-27.19-11.13-27.19-29.8V51.71H354V98.37c0,9.12,4.7,14.6,12.92,14.6,9.27,0,15.35-7.42,15.35-19.16V51.71h22.35Z"/><path class="cls-1" d="M428.6,102.17V69.33H415.39V51.71h13.24V29.46h22.18V51.71h22.51V69.33H450.79v38c0,2.12.91,3,3,3h19.46v17.93h-17C438.33,128.32,428.6,119.05,428.6,102.17Z"/><path class="cls-1" d="M486.67,18.87H509V128.32H486.67Z"/><path class="cls-1" d="M524.51,30.11a12.47,12.47,0,0,1,24.93-.78q0,.39,0,.78a12.47,12.47,0,0,1-24.93,0Zm1.24,21.6h22.36v76.62H525.72Z"/><path class="cls-1" d="M564.79,51.71h21.74v11.7a27,27,0,0,1,24-13.84c16.41,0,27.19,11.12,27.19,29.8v48.95H615.43V81.61c0-9.12-4.72-14.59-12.93-14.59-9.27,0-15.35,7.41-15.35,19.16v42.1H564.79Z"/><path class="cls-1" d="M649.46,90.77V90c0-24.62,16-40.79,39.55-40.79,22.25,0,38.32,15.66,38.32,41.36v5.16h-55.5c1.24,12,7.42,17.64,17.49,17.64,7.29,0,12.46-3.2,14.75-8.65h22.49c-3.34,15.35-18.09,26-37.4,26C664.67,130.76,649.46,115.85,649.46,90.77Zm23-9.72h32.39C702.72,71,697.1,66,688.89,66S674.39,70.85,672.46,81.05Z"/></g></svg>
            <button class="button logout" onclick="resetAuth()">Logout
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" class="h-3 inline">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1">
                    </path>
                </svg>
            </button>
        </div>
 
        <div class="wrapper">
            <div class="manageWrapper">
                <h1>Outline Manager key:</h1>
                <button class="button buttonDelete buttonRegenerate" onclick="createManagerKey()">Regenerate</button>
            </div>
 
            <button class="button buttonCode" onclick="copyToClipboard(jsonString)">
                <span id="jsonStringDisplay"></span>
                <svg xmlns="http://www.w3.org/2000/svg" width="19" height="22" viewBox="0 0 19 22" fill="none">
                    <path d="M14 0H2C0.9 0 0 0.9 0 2V16H2V2H14V0ZM17 4H6C4.9 4 4 4.9 4 6V20C4 21.1 4.9 22 6 22H17C18.1 22 19 21.1 19 20V6C19 4.9 18.1 4 17 4ZM17 20H6V6H17V20Z"
                        fill="gray" />
                </svg>
            </button>
        </div>
 
        <div class="listWrapper">
            <div class="titleWrapper">
                <p>Clients</p>
                <button class="button" onclick="showPopup()">+ New</button>
            </div>
 
            <ul class="list" id="clientsList">
            </ul>
        </div>
    </div>
 
     <script>
            const jsonString =  `<?php echo ($keyContent); ?>`;
            let clients = [];
            const host = window.location.host;
 
            document.addEventListener('DOMContentLoaded', function () {
                document.getElementById('jsonStringDisplay').textContent = jsonString;
                populateClientsList();
 
                document.getElementById('clientNameInput').addEventListener('input', function (e) {
                    document.getElementById('createClientButton').disabled = e.target.value === '';
                });
 
                document.getElementById('createClientButton').addEventListener('click', createNewClientHandler);
            });
 
            function copyToClipboard(text) {
            const unsecuredCopyToClipboard = (text) => { const textArea = document.createElement("textarea"); textArea.value=text; document.body.appendChild(textArea); textArea.focus();textArea.select(); try{document.execCommand('copy')}catch(err){console.error('Unable to copy to clipboard',err)}document.body.removeChild(textArea)};
                if (window.isSecureContext && navigator.clipboard) {
                    navigator.clipboard.writeText(text);
                  } else {
                    unsecuredCopyToClipboard(text);
                  }
            }
 
            function resetAuth() {
                        let xhr = new XMLHttpRequest();
                        xhr.open('GET', `http://invalid:invalid@${host}/`, true);
                        xhr.onreadystatechange = function () {
                            if (xhr.readyState === 4) {
                                window.location.reload(true);
                            }
                        };
                        xhr.send();
                    }
 
            function createManagerKey() {
                let xhr = new XMLHttpRequest();
                xhr.open('POST', './scripts/regenerate_outline_manager_key.php', true);
                xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                xhr.onreadystatechange = function () {
                    if (xhr.readyState === 4) {
                        if (xhr.status === 200) {
                            location.reload();
                        } else {
                            console.error('Error: ' + xhr.statusText);
                        }
                    }
                };
                xhr.send();
            }
 
            async function createClientKey(name) {
                return new Promise((resolve, reject) => {
                    let xhr = new XMLHttpRequest();
                    xhr.open('POST', './scripts/new_client_key.php', true);
                    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                    xhr.onreadystatechange = function () {
                        if (xhr.readyState === 4) {
                            if (xhr.status === 200) {
                                try {
                                    const response = JSON.parse(xhr.responseText);
 
                                    resolve(response);
                                } catch (e) {
                                    console.error('Ошибка при парсинге JSON:', e);
                                    reject(e);
                                }
                            } else {
                                alert('Ошибка при создании ключа.');
                                reject(new Error('Ошибка при создании ключа.'));
                            }
                        }
                    };
                    xhr.send('name=' + encodeURIComponent(name));
                }).then(async() => {
                await getClients();
                    populateClientsList();
                }).catch(error => {
                    console.error('Ошибка:', error);
                });
            }
 
            async function getClients() {
                        return fetch('./scripts/get_client_key_list.php')
                            .then((response) => response.json())
                            .then((data) => {
                                clients = data.accessKeys;
                                populateClientsList();
                            })
                            .catch((error) => {
                                console.error('Error:', error);
                            });
                    }
 
                getClients();
 
            function showPopup() {
                document.getElementById('createNewClientPopup').style.display = 'flex';
            }
 
            function closePopup(e) {
                if (e.target === e.currentTarget) {
                    document.getElementById('createNewClientPopup').style.display = 'none';
                }
            }
 
            function populateClientsList() {
                const clientsList = document.getElementById('clientsList');
                clientsList.innerHTML = '';
                clients.forEach(client => {
                    const listItem = document.createElement('li');
                    listItem.className = 'item';
                    listItem.innerHTML = `
                        <p>${client.id}</p>
                        <p>${client.name}</p>
                        <button class="button buttonCode" onclick="copyToClipboard('${client.accessUrl}')">
                            ${client.accessUrl}
                            <svg xmlns="http://www.w3.org/2000/svg" width="19" height="22" viewBox="0 0 19 22" fill="none">
                                <path d="M14 0H2C0.9 0 0 0.9 0 2V16H2V2H14V0ZM17 4H6C4.9 4 4 4.9 4 6V20C4 21.1 4.9 22 6 22H17C18.1 22 19 21.1 19 20V6C19 4.9 18.1 4 17 4ZM17 20H6V6H17V20Z"
                                    fill="gray" />
                            </svg>
                        </button>
                        <button class="button buttonDelete" onclick="deleteClient(${client.id})">
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="white" class="bucket">
                                <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                                    clip-rule="evenodd"></path>
                            </svg>
                        </button>
                    `;
                    clientsList.appendChild(listItem);
                });
            }
 
            async function createNewClientHandler() {
                const clientNameInput = document.getElementById('clientNameInput');
                await createClientKey(clientNameInput.value).then(() => {
                    clientNameInput.value = '';
                    document.getElementById('createNewClientPopup').style.display = 'none';
                    populateClientsList();
                });
            }
 
        async function deleteClient(id) {
            try {
                const params = new URLSearchParams();
                params.append('id', id);
 
                const response = await fetch('./scripts/remove_client.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    body: params.toString()
                });
 
 
                if (!response.ok) {
                    throw new Error(`HTTP error! Status: ${response.status}`);
                }
 
            if (response.ok) {
                            await getClients();
                                        populateClientsList();
                        }
 
            } catch (error) {
                console.error('Error:', error);
                throw error;
            }
        }
        </script>
</body>
</html>
ENDOFFILE
 
sudo tee /var/www/outline/scripts/regenerate_outline_manager_key.php > /dev/null <<'ENDOFFILE'
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $script_path = './regenerate_outline_manager_key.sh';
    $output = [];
    $return_var = 0;
    $log_file = './error_log.txt';
 
    exec("sh $script_path 2>&1", $output, $return_var);
    header('Content-Type: application/json; charset=utf-8');
 
    if ($return_var === 0) {
        echo json_encode(["status" => "success", "message" => "Script executed successfully!", "output" => $output, "current_directory" => getcwd()]);
    } else {
        $error_message = "[" . date('Y-m-d H:i:s') . "] Script execution error: " . implode("\n", $output) . "\n";
        error_log($error_message, 3, $log_file);
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => $error_message, "current_directory" => getcwd()]);
    }
} else {
    $error_message = "[" . date('Y-m-d H:i:s') . "] Invalid request method.\n";
    error_log($error_message, 3, $log_file);
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => $error_message, "current_directory" => getcwd()]);
}
?>
ENDOFFILE
 
sudo tee /var/www/outline/scripts/new_client_key.php > /dev/null <<'ENDOFFILE'
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['name'])) {
    $name = htmlspecialchars($_POST['name']);
    $configContent = file_get_contents('../outline_manager_key.php');
    $jsonStart = strpos($configContent, '{');
    $jsonEnd = strrpos($configContent, '}') + 1;
    $jsonString = substr($configContent, $jsonStart, $jsonEnd - $jsonStart);
    $config = json_decode($jsonString, true);
    $apiUrl = $config['apiUrl'];
 
    $data = json_encode(['method' => 'aes-192-gcm', 'name' => $name]);
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $apiUrl . '/access-keys');
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
 
    $response = curl_exec($ch);
    curl_close($ch);
 
    echo $response;
} else {
    echo json_encode(['error' => 'Invalid request']);
}
?>
ENDOFFILE
 
sudo tee /var/www/outline/scripts/get_client_key_list.php > /dev/null <<'ENDOFFILE'
<?php
$keyFile = '../outline_manager_key.php';
$keyContent = file_get_contents($keyFile);
$keyData = json_decode($keyContent, true);
$apiUrl = $keyData['apiUrl'];
$accessKeysUrl = $apiUrl . '/access-keys/';
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => $accessKeysUrl,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_SSL_VERIFYPEER => false,
    CURLOPT_SSL_VERIFYHOST => false
]);
 
$response = curl_exec($curl);
curl_close($curl);
$responseData = json_decode($response, true);
 
$formattedData = '';
foreach ($responseData['accessKeys'] as $key) {
    $formattedData .= $key['id'] . ' | ' . $key['name'] . ' | ' . $key['accessUrl'] . "\n";
}
 
$outputFile = './client_key_list.php';
file_put_contents($outputFile, $formattedData);
 
if (php_sapi_name() === 'cli') {
    echo 'Keys saved to ' . $outputFile . "\n";
}
 
echo json_encode($responseData);
?>
ENDOFFILE
 
sudo tee /var/www/outline/scripts/remove_client.php > /dev/null <<'ENDOFFILE'
<?php
$configFile = '../outline_manager_key.php';
$config = json_decode(file_get_contents($configFile), true);
$apiUrl = $config['apiUrl'];
$id = $_POST['id'];
 
if (!isset($id)) {
    die('ID клиента не указан.');
}
 
$deleteUrl = $apiUrl . '/access-keys/' . $id;
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $deleteUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "DELETE");
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
 
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
 
if ($httpCode == 204) {
    header("Location: /");
    exit;
} else {
    echo 'Ошибка при удалении клиента: ' . $response;
}
?>
ENDOFFILE
 
 
# Создаем скрипт на перегенерацию ключа подключения к Outline Manager, кладем его в файл /var/www/html/regenerate_outline_manager_key.sh
sudo tee /var/www/outline/scripts/regenerate_outline_manager_key.sh > /dev/null <<'ENDOFFILE'
#!/bin/sh
 
# Переменная для временного файла вывода
TEMP_OUTPUT="outline_manager_output.php"
# Устанавливаем Outline Server и перенаправляем вывод в временный файл
current_hostname=$(hostname)
wget https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh
if yes | sudo bash install_server.sh --hostname $current_hostname --keys-port 8081 > "$TEMP_OUTPUT"; then
    echo "Outline Server успешно установлен."
 
    # Извлекаем ключ для подключения к Outline Manager
    OUTLINE_MANAGER_KEY=$(sudo grep -oE '\{"api.*"}' "$TEMP_OUTPUT")
 
    if [ -n "$OUTLINE_MANAGER_KEY" ]; then
        echo "Ключ успешно извлечен."
 
        # Кладем ключ в файл ../outline_manager_key.php
        sudo tee ../outline_manager_key.php > /dev/null <<EOF
        $OUTLINE_MANAGER_KEY
EOF
 
        if [ $? -eq 0 ]; then
            echo "Ключ успешно сохранен в ../outline_manager_key.php."
        else
            echo "Ошибка при сохранении ключа в файл." >&2
            exit 1
        fi
    else
        echo "Не удалось извлечь ключ из вывода скрипта." >&2
        exit 1
    fi
 
    # Удаляем временный файл
    sudo rm "$TEMP_OUTPUT"
	sudo rm install_server.sh -f
    if [ $? -eq 0 ]; then
        echo "Временный файл успешно удален."
    else
        echo "Ошибка при удалении временного файла." >&2
        exit 1
    fi
else
    echo "Ошибка при установке Outline Server." >&2
    exit 1
fi
ENDOFFILE
 
# Разрешаем пользователю outline выполнять команды sudo без ввода пароля
echo "outline ALL=(ALL) NOPASSWD: /usr/bin/wget, /bin/bash, /bin/grep, /bin/rm, /usr/bin/tee" | sudo tee -a /etc/sudoers
 
# Меняем владельца папки и файлов в ней на системного пользователя outline
sudo chown -R outline:outline /var/www/outline
sudo chmod -R 755 /var/www/outline
 
echo "---
---
---
---
---"
echo "${BLUE_BG}${BLACK_FG}Wireguard GUI:${RESET} http://$current_hostname:$WG_GUI_PORT | ${BLUE_BG}${BLACK_FG}Password:${RESET} $PASSWORD"
echo "${BLUE_BG}${BLACK_FG}Outline Manager key:${RESET} $OUTLINE_MANAGER_KEY"
echo "${BLUE_BG}${BLACK_FG}Outline Web-GUI:${RESET} http://$current_hostname:8181 | ${BLUE_BG}${BLACK_FG}Login:${RESET} outline | ${BLUE_BG}${BLACK_FG}Password:${RESET} $PASSWORD"
}
 
# Проверка доступности IPv4
is_ipv4_available=$(curl -s -o /dev/null -w "%{http_code}\n" eth0.me)
 
if [ "$is_ipv4_available" == "000" ]; then
    # Если IPv4 недоступен, выходим
	echo "${BLUE_BG}${BLACK_FG}IPv4 is not available. Exiting.${RESET} | ${GREEN_BG}${BLACK_FG}IPv4 недоступен. Выходим.${RESET}"
    exit 1
else
    # Если IPv4 доступен, продолжаем выполнение
    echo "${BLUE_BG}${BLACK_FG}IPv4 is available. Continuing.${RESET} | ${GREEN_BG}${BLACK_FG}IPv4 доступен. Продолжаем.${RESET}"
	main_ip=$(curl eth0.me)
    main_code
fi

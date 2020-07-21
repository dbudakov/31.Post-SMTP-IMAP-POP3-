## Домашнее задание

Установка почтового сервера
Цель: В результате выполнения ДЗ студент установит почтовый сервер.

1. Установить в виртуалке postfix+dovecot для приёма почты на виртуальный домен любым обсужденным на семинаре способом
2. Отправить почту телнетом с хоста на виртуалку
3. Принять почту на хост почтовым клиентом

Результат

1. Полученное письмо со всеми заголовками
2. Конфиги postfix и dovecot

## Решение
Стенд поднимается из каталога `./homework` по команде `vagrant up`  
После деплоя стенда, переходим в браузере по адресу    
`http://192.168.100.101/postfixadmin/public/setup.php`  
![](https://github.com/dbudakov/31.Post-SMTP-IMAP-POP3-/blob/master/images/Screenshot%20from%202020-07-21%2021-05-03.png)       
Вводим произвольный, но соответствующий требованиям пароль, для теста использовался `P@ssw0rd8`  
Прожимаем `Enter`, будет сгенерирована строка, которую необходимо вставить вместо строки в файле конфигурации  
![](https://github.com/dbudakov/31.Post-SMTP-IMAP-POP3-/blob/master/images/Screenshot%20from%202020-07-21%2021-06-14.png)  
файл для редактирования:  
```  
/usr/share/nginx/html/postfixadmin/config.inc.php  
  вместо строки  
    $CONF['setup_password'] = 'changeme';  
```    
После подстановки строки `$CONF['setup_password']`, возвращаем в браузер и создаем учетную запись суперпользователя,  
использую во всех полях тот же пароль, что и ранее, для теста использовался `P@ssw0rd8`  
Жмем `Enter`, видим следующее сообщение:  
![](https://github.com/dbudakov/31.Post-SMTP-IMAP-POP3-/blob/master/images/Screenshot%20from%202020-07-21%2021-08-36.png)  
будет предложен переход на страницу  
`http://192.168.100.101/postfixadmin/public/login.php`   
![](https://github.com/dbudakov/31.Post-SMTP-IMAP-POP3-/blob/master/images/Screenshot%20from%202020-07-21%2021-08-59.png)  
Далее, можно отправлять сообщения, через `telnet` с хоста, на котором был развернут стенд,  
  
Для отправки сообщения с хоста подключаемся к `postfix`, на стенде  
`telnet 192.168.100.101 25`  
  
```  
helo domain.dlt  
mail from: root@domain.tld  
rcpt to: root@localhost  
data  
  
Hello, world!  
  
.  
quit  
```  
  
Cообщения появятся в файле  
`less /var/spool/mail/root`  
  
### Дополнительно:  
  
Использовались материалы  
http://habrahabr.ru/post/193220/  
https://github.com/Haran/Mail.CONF  
```
/var/log/message - лог named  
/var/log/maillog - лог postfix    
/var/spool/mail/user_name - почта   
```

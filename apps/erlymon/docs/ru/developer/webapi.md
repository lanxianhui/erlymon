# WebApi

Доступ к api можно получить по ссылке http://localhost:8081/api

На любой запрос, если у вас есть права и сервер функционирует в штатном режиме, сервер отвечает json объектом либо json массивом.
Иначе сервер возвращает код ошибки с сообщением.

Для доступа к web api вместо curl используем httpie

## Сессия

Для того, чтобы иметь доступ к функциям создания/удаления/редактирования пользоватлей/устройств/прав доступа необходимо авторизоватся в системе.

Для авторизации необходимо открыть сессию, либо убедиться, что ваша сессия ещё жива (т.е. получить параметры сессии)

Как только вы закончили работу с сервером вам необходимо закрыть сессию.

### Получить сессию
```sh
$ http localhost:8081/api/session 'Cookie:session=7cafa2ff-8e17-416c-955e-e16faa2fb2ac'

HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 106
Content-Type: application/json; charset=UTF-8
Date: Fri, 01 Jul 2016 10:02:28 GMT
Keep-Alive: timeout=20
Server: nginx/1.8.1

{
    "admin": true,
    "distanceUnit": "",
    "email": "admin",
    "id": 12371,
    "latitude": 45.0,
    "longitude": 20.0,
    "map": "",
    "name": "admin",
    "password": null,
    "readonly": false,
    "speedUnit": "",
    "zoom": 10
}
```

### Открыть сессию
```sh
$ http -f POST localhost:8081/api/session email=admin password=admin

HTTP/1.1 200 OK
content-length: 174
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 12:42:22 GMT
server: Cowboy
set-cookie: session=76e93a36-02d6-4f34-a518-a982086bf52c; Version=1; Path=/

{
    "admin": false,
    "distanceUnit": "",
    "email": "admin",
    "id": 12371,
    "latitude": 45.0,
    "longitude": 20.0,
    "map": "",
    "name": "admin",
    "password": null,
    "readonly": false,
    "speedUnit": "",
    "zoom": 10
}
```

### Закрыть сессию
```sh
$ http DELETE localhost:8081/api/session 'Cookie:session=7cafa2ff-8e17-416c-955e-e16faa2fb2ac'

Connection: keep-alive
Content-Length: 0
Date: Fri, 01 Jul 2016 10:06:12 GMT
Keep-Alive: timeout=20
Server: nginx/1.8.1
set-cookie: session=deleted; Version=1; Path=/



```

## Сервер

Доступ к параметрам сервера имеют все пользователи.
Доступ к редактированию параметров сервера имеет только администратор.

### Получить параметры сервера

```sh
$ http localhost:8081/api/server

HTTP/1.1 200 OK
content-length: 171
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 12:40:42 GMT
server: Cowboy

{
    "bingKey": null,
    "distanceUnit": null,
    "id": 1,
    "latitude": 0.0,
    "longitude": 0.0,
    "map": null,
    "mapUrl": null,
    "readonly": false,
    "registration": true,
    "speedUnit": null,
    "zoom": 0
}
```

### Обновить параметры сервера

```sh
$ http --json PUT localhost:8081/api/server 'Cookie:session=cc3aee99-f4dd-459f-9b66-e9d304a5aa2f; Version=1; Path=/' id:=1465545256 bingKey= distanceUnit= language= latitude:=0 longitude:=0 map=osm mapUrl= readonly:=false readonly:=true speedUnit= zoom:=0

HTTP/1.1 200 OK
content-length: 153
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 13:58:47 GMT
server: Cowboy

{
    "bingKey": "",
    "distanceUnit": "",
    "id": 1465545256,
    "language": "",
    "latitude": 0,
    "longitude": 0,
    "map": "osm",
    "mapUrl": "",
    "readonly": true,
    "speedUnit": "",
    "zoom": 0
}
```

## Пользователи

Доступ к пользователям имеет только администратор. Т.е. получить/добавить/редактировать/удалить пользователей может только администратор.
Доступ к регистрации пользователя есть у всех.
Доступ к обновлению пользователя есть у всех, если это авторизованный пользователь.

### Получить список пользователей

```sh
$ http GET localhost:8081/api/users 'Cookie:session=76e93a36-02d6-4f34-a518-a982086bf52c; Version=1; Path=/'

HTTP/1.1 200 OK
content-length: 176
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 12:43:42 GMT
server: Cowboy

[
    {
        "admin": true,
        "distanceUnit": "",
        "email": "admin",
        "id": 1465545256,
        "language": "",
        "latitude": 0.0,
        "longitude": 0.0,
        "map": "",
        "name": "admin",
        "readonly": false,
        "speedUnit": "",
        "zoom": 0
    }
]

```

### Создать/Зарегистрировать пользователя

```
$ http --json POST localhost:8081/api/users 'Cookie:session=cc3aee99-f4dd-459f-9b66-e9d304a5aa2f; Version=1; Path=/' name=manager email=manager@manager.com password=manager
```

### Обновить пользователя

```
http --json PUT localhost:8081/api/users/1467380757 'Cookie:session=cc3aee99-f4dd-459f-9b66-e9d304a5aa2f; Version=1; Path=/' id:=1467380757 name=manager email=manager@manager.com password=manager

HTTP/1.1 200 OK
content-length: 85
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 13:50:48 GMT
server: Cowboy

{
    "email": "manager@manager.com",
    "id": 1467380757,
    "name": "manager",
    "password": "manager"
}
```

### Удалить пользователя

```sh
$ http --json DELETE localhost:8081/api/users/1467380757 'Cookie:session=cc3aee99-f4dd-459f-9b66-e9d304a5aa2f; Version=1; Path=/' id:=1467380757 name=manager email=manager@manager.com password=manager

HTTP/1.1 200 OK
content-length: 85
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 13:51:27 GMT
server: Cowboy

{
    "email": "manager@manager.com",
    "id": 1467380757,
    "name": "manager",
    "password": "manager"
}
```

## Устройство

Доступ к устройствам есть у всех. Т.е. получить/добавить/редактировать/удалить устройства может любой пользователь.

### Получить список устройств

```sh
$ http GET localhost:8081/api/devices 'Cookie:session=76e93a36-02d6-4f34-a518-a982086bf52c; Version=1; Path=/'

HTTP/1.1 200 OK
content-length: 134
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 12:46:22 GMT
server: Cowboy

[
    {
        "id": 1465545256,
        "lastUpdate": "2016-06-10T07:54:16.000+0000",
        "name": "test1",
        "positionId": 0,
        "status": "",
        "uniqueId": "123456789012345"
    }
]

```

### Создать устройство
```sh
$ http --json POST localhost:8081/api/devices 'Cookie:session=c914b9fd-ac19-48f1-883d-3fc3eb286a70; Version=1; Path=/' id=-1 name=tractor uniqueId=tractor

HTTP/1.1 200 OK
content-length: 112
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 13:25:34 GMT
server: Cowboy

{
    "id": 1467379534,
    "lastUpdate": 1467379534810728,
    "name": "tractor",
    "positionId": 0,
    "status": "",
    "uniqueId": "tractor"
}

```

### Обновить устройство

```sh
$ http --json PUT localhost:8081/api/devices/1467379534 'Cookie:session=91b7a488-cc80-4ceb-a12e-fb9f2bb48a20' id:=1467379534 name=tractor1 uniqueId=tractor1 lastUpdate=2016-07-01T13:25:34.000+0000 positionId:=0 status=

HTTP/1.1 200 OK
content-length: 128
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 13:32:25 GMT
server: Cowboy

{
    "id": 1467379534,
    "lastUpdate": "2016-07-01T13:25:34.000 0000",
    "name": "tractor1",
    "positionId": 0,
    "status": "",
    "uniqueId": "tractor1"
}

```

### Удалить устройство

```sh
$ http --json DELETE localhost:8081/api/devices/1467379534 'Cookie:session=91b7a488-cc80-4ceb-a12e-fb9f2bb48a20' id:=1467379534 name=tractor1 uniqueId=tractor1 lastUpdate=2016-07-01T13:25:34.000+0000 positionId:=0 status=

```

## Права доступа

Права доступа может редактировать только администратор.

### Добавить доступ к устройству

```sh
http --json POST localhost:8081/api/permissions 'Cookie:session=cc3aee99-f4dd-459f-9b66-e9d304a5aa2f; Version=1; Path=/' userId:=1467380569 deviceId:=1465545256

HTTP/1.1 200 OK
content-length: 0
date: Fri, 01 Jul 2016 14:02:25 GMT
server: Cowboy

```

### Удалить доступ к устройству

```sh
$ http --json DELETE localhost:8081/api/permissions 'Cookie:session=cc3aee99-f4dd-459f-9b66-e9d304a5aa2f; Version=1; Path=/' userId:=1467380569 deviceId:=1465545256
HTTP/1.1 200 OK
content-length: 0
date: Fri, 01 Jul 2016 14:03:01 GMT
server: Cowboy

```

## Сообщения

### Выгрузка сообщений

```sh
$ http GET localhost:8081/api/positions 'Cookie:session=feabd330-f679-421b-bd95-ed5ee5520af8; Version=1; Path=/' deviceId==1465545256 from==2016-07-01T14:03:56.000Z to==2016-07-01T14:33:56.000Z

HTTP/1.1 200 OK
content-length: 2
content-type: application/json; charset=UTF-8
date: Fri, 01 Jul 2016 14:37:50 GMT
server: Cowboy

[]
```

## Команды

### Выполнить команду

```sh
$ http --json POST localhost:8081/api/commands 'Cookie:session=cc3aee99-f4dd-459f-9b66-e9d304a5aa2f; Version=1; Path=/' id:=-1 deviceId:=1465545256 type=engineResume
HTTP/1.1 403 Forbidden
content-length: 20
date: Fri, 01 Jul 2016 14:10:38 GMT
server: Cowboy

TODO: need implement
```
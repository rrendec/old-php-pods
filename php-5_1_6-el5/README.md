## Build the container image

```
cd php-5_1_6-el5
podman build --layers=false -t php-5_1_6-el5 .
```

## Create a container

```
podman run -it --network=host \
	--volume=/var/www/mipanel:/var/www/mipanel \
	--volume=/var/lib/mysql/mysql.sock:/var/lib/mysql/mysql.sock \
	php-5_1_6-el5
```

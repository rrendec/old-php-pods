## Build the container image

```
cd php-516
podman build --layers=false -t php-516 .
```

## Create a container

```
podman run -it --network=host \
	--volume=/var/www/mipanel:/var/www/mipanel \
	--volume=/var/lib/mysql/mysql.sock:/var/lib/mysql/mysql.sock \
	php-516
```

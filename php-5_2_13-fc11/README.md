## Build the container image

```
podman build --layers=false -t php-5_2_13-fc11 -f php-5_2_13-fc11/Containerfile .
```

## Create a container

```
podman run -it --network=host \
	--volume=/var/www/mipanel:/var/www/mipanel \
	--volume=/var/lib/mysql/mysql.sock:/var/lib/mysql/mysql.sock \
	php-5_2_13-fc11
```

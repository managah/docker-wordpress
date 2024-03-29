#/bin/sh

set -ex

TAGS='php7.3-apache php7.4-apache php8.0-apache php8.1-apache'

for tag in $TAGS; do
    image="managah/wordpress:${tag}"
    docker pull wordpress:${tag}
    docker build -t ${image} --build-arg BASE_TAG=${tag} -f apache2.Dockerfile .
    php_modules=$(docker run --rm ${image} php -m)
    echo "$php_modules" | grep -i -q memcached || (echo "memcached not loaded" && exit 1)
    echo "$php_modules" | grep -i -q opcache || (echo "opcache not loaded" && exit 1)
    docker run --name ${tag} --rm -d -p8888:80 ${image}
    sleep 2
    curl -s -i 'http://localhost:8888' | grep -q '302 Found' || (echo "$tag not started" && (docker rm -fv ${tag} || true) && exit 1)
    docker rm -fv ${tag}
done

if [ "push" = "$1" ]; then
    for tag in $TAGS; do
        docker push managah/wordpress:${tag}
    done
fi

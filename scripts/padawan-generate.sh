#!/bin/bash
dir=$1
if [ -z "$1" ];then
    dir=`pwd`
fi

#padawan dont need composer at all, but its checking for it anyway
cd "$dir"
if [ ! -f "$dir/vendor/composer/autoload_classmap.php" ];then
    mkdir -p "$dir/vendor/composer/"
    echo '<?php return [];' > "$dir/vendor/composer/autoload_classmap.php"
fi
if [ ! -f "$dir/composer.json" ];then
    mkdir -p "$dir/vendor/composer/"
    touch "$dir/composer.json"
fi

#workaround for the infinite loop issue
symfony_not_loadable_class="$dir/vendor/symfony/var-dumper/Tests/Fixtures/NotLoadableClass.php"
if [ -f "$symfony_not_loadable_class" ];then
    mv "$symfony_not_loadable_class" "$symfony_not_loadable_class._padawan_skip"
fi
padawan generate
if [ -f "$symfony_not_loadable_class._padawan_skip" ];then
    mv "$symfony_not_loadable_class._padawan_skip" "$symfony_not_loadable_class"
fi

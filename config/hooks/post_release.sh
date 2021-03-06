#!/bin/sh

OS_NAME=$(uname -s)

if [ $OS_NAME = "Darwin" ] ; then
    alias sed="sed -i '' "
else
    alias sed='sed -i '
fi

## Use sed to inject customized code in start scripts.
START_SCRIPTS=`find $REBAR_BUILD_DIR/rel -type f -name pundun`
for s in $START_SCRIPTS; do

if [ $OS_NAME != "Darwin" ] ; then
    sed 's/readlink/readlink -f/g' $s
fi


##GENERATE Node Name from path
sed '/^NAME=/a \
if [ ! ${VMARGS_PATH} = ${RELEASE_ROOT_DIR}/vm.args ] ; then\
\    echo "Copy ${VMARGS_PATH} to ${RELEASE_ROOT_DIR}/"\
\    cp -p ${VMARGS_PATH} ${RELEASE_ROOT_DIR}/ \
\    VMARGS_PATH=$(add_path vm.args)\
fi\
\
if [ -z "$NAME" ] || [ "$NAME" = "noname" ]; then\
\    NAME="pundun"`echo $HOSTNAME $RELEASE_ROOT_DIR | openssl sha1 | cut -b 10-15`\
\    echo "Generated node name $NAME"\
\    NAME_ARG="$NAME_TYPE $NAME"\
\    sed -i -e "s;^$NAME_TYPE.*;$NAME_TYPE $NAME;" $VMARGS_PATH\
fi\
\
' $s
## export PRODDIR
## gb_conf is using and dependent on PRODDIR env variable.
sed '/^RELEASE_ROOT_DIR=/a \
export PRODDIR=$RELEASE_ROOT_DIR\
' $s

## export PIPE_DIR
## put run_erl pipes under the release
sed '/PRODDIR=/a \
export PIPE_DIR=$RELEASE_ROOT_DIR\/var\/pipes\/pundun\
' $s

done

## Create symlinks to configuration files
## This makes easier access to configuration files.
create_sym_links()
{
    CFGS=`find $REBAR_BUILD_DIR/rel/pundun/lib/*/priv/ -name *.yaml -type f`
    if [ "$PKG_BUILD" = "1" ] ; then
	INSTALL_PATH="../usr/lib/pundun/"
    else
	INSTALL_PATH=""
    fi
    for c in $CFGS; do
	local link=$REBAR_BUILD_DIR/rel/pundun/etc/`basename $c`
	ln -sf ../${INSTALL_PATH}${c#${REBAR_BUILD_DIR}/rel/pundun/} $link
    done
}
create_sym_links

# End

#!/bin/bash
#
#
#  Copyright 2016 CUBRID Corporation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

function get_cubrid_dir() {
  cubrid_str=/CUBRID/
  cubrid_str_len=${#cubrid_str}
  current_dir="`pwd`"

  find_dir=$(echo ${current_dir} | grep ${cubrid_str})

  if [ -z "$find_dir" ];then
    echo ""
  else
    temp_dir=${current_dir%%$cubrid_str*}
    temp_dir_len=${#temp_dir}
    cubrid_dir_len=`expr $temp_dir_len + $cubrid_str_len`
    cubrid_dir=$(echo $current_dir | cut -c1-$cubrid_dir_len)
    echo "$cubrid_dir"
  fi
}


cubrid_home=$(get_cubrid_dir)

if [ -z "$cubrid_home" ];then
  cubrid_home="`pwd`"
fi

echo "Is the CUBRID installed in "$cubrid_home" ? [Yn]:"

read line leftover
is_installed_dir=TRUE

case ${line} in
  n* | N*)
    is_installed_dir=FALSE
esac

if [ "x${is_installed_dir}x" = "xFALSEx" ];then
  echo ""
  echo "Please enter the directory where CUBRID is installed: "

  read input_dir leftover
  cubrid_home=${input_dir}
fi

if [ ! -d $cubrid_home ];then
  echo "$cubrid_home: no such directory"
  exit
fi

# environment variables for *csh
cubrid_csh_envfile="$HOME/.cubrid.csh"

cat << ____cubrid__here_doc____ > ${cubrid_csh_envfile}_temp
setenv CUBRID ${cubrid_home}
____cubrid__here_doc____
cat << '____cubrid__here_doc____' >> ${cubrid_csh_envfile}_temp
setenv CUBRID_DATABASES $CUBRID/databases
if (${?LD_LIBRARY_PATH}) then
  setenv LD_LIBRARY_PATH $CUBRID/lib:${LD_LIBRARY_PATH}
else
  setenv LD_LIBRARY_PATH $CUBRID/lib
endif
setenv SHLIB_PATH $LD_LIBRARY_PATH
setenv LIBPATH $LD_LIBRARY_PATH
set path=($CUBRID/bin $path)

set LIB=$CUBRID/lib

if (-f "/etc/redhat-release" ) then
  set OS=(`cat /etc/system-release-cpe | cut -d':' -f'3-3'`)
else if (-f "/etc/os-release" ) then
  set OS=(`cat /etc/os-release | egrep "^ID=" | cut -d'=' -f2-2`)
endif

switch ($OS)
  case fedoraproject:
  case centos:
  case redhat:
    if ((! -e /lib64/libncurses.so.5 ) && ( ! -e $LIB/libncurses.so.5 )) then
      ln -s /lib64/libncurses.so.6 $LIB/libncurses.so.5
      ln -s /lib64/libform.so.6 $LIB/libform.so.5
      ln -s /lib64/libtinfo.so.6 $LIB/libtinfo.so.5
    endif
    breaksw
  case ubuntu:
    if ((! -e /lib/x86_64-linux-gnu/libncurses.so.5 ) && ( ! -e $LIB/libncurses.so.5)) then
      ln -s /lib/x86_64-linux-gnu/libncurses.so.6 $LIB/libncurses.so.5
      ln -s /lib/x86_64-linux-gnu/libform.so.6 $LIB/libform.so.5
      ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 $LIB/libtinfo.so.5
    endif
    breaksw
  case debian:
    if ( ! -e /lib/x86_64-linux-gnu/libncurses.so.5 ) && ( ! -e $LIB/libncurses.so.5 ) then
      ln -s /lib/x86_64-linux-gnu/libncurses.so.6 $LIB/libncurses.so.5
      ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 $LIB/libtinfo.so.5
      ln -s /usr/lib/x86_64-linux-gnu/libform.so.6 $LIB/libform.so.5
    endif
    breaksw
  default:
    echo "Unknown operating system."
    breaksw
endsw
____cubrid__here_doc____


# environment variables for *sh
cubrid_sh_envfile="$HOME/.cubrid.sh"
cat << ____cubrid__here_doc____ > ${cubrid_sh_envfile}_temp
CUBRID=${cubrid_home}
____cubrid__here_doc____
cat << '____cubrid__here_doc____' >> ${cubrid_sh_envfile}_temp
CUBRID_DATABASES=$CUBRID/databases
if [ "x${LD_LIBRARY_PATH}x" = xx ]; then
  LD_LIBRARY_PATH=$CUBRID/lib
else
  LD_LIBRARY_PATH=$CUBRID/lib:$LD_LIBRARY_PATH
fi
SHLIB_PATH=$LD_LIBRARY_PATH
LIBPATH=$LD_LIBRARY_PATH
PATH=$CUBRID/bin:$PATH
export CUBRID
export CUBRID_DATABASES
export LD_LIBRARY_PATH
export SHLIB_PATH
export LIBPATH
export PATH

LIB=$CUBRID/lib

if [ -f /etc/redhat-release ];then
        OS=$(cat /etc/system-release-cpe | cut -d':' -f'3-3')
elif [ -f /etc/os-release ];then
        OS=$(cat /etc/os-release | egrep "^ID=" | cut -d'=' -f2-2)
fi

case $OS in
        fedoraproject | centos | redhat)
                if [ ! -h /lib64/libncurses.so.5 ] && [ ! -h $LIB/libncurses.so.5 ];then
                        ln -s /lib64/libncurses.so.6 $LIB/libncurses.so.5
                        ln -s /lib64/libform.so.6 $LIB/libform.so.5
                        ln -s /lib64/libtinfo.so.6 $LIB/libtinfo.so.5
                fi
                ;;
        ubuntu)
                if [ ! -h /lib/x86_64-linux-gnu/libncurses.so.5 ] && [ ! -h $LIB/libncurses.so.5 ];then
                        ln -s /lib/x86_64-linux-gnu/libncurses.so.6 $LIB/libncurses.so.5
                        ln -s /lib/x86_64-linux-gnu/libform.so.6 $LIB/libform.so.5
                        ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 $LIB/libtinfo.so.5
                fi
                ;;
        debian)
                if [ ! -h /lib/x86_64-linux-gnu/libncurses.so.5 ] && [ ! -h $LIB/libncurses.so.5 ];then
                        ln -s /lib/x86_64-linux-gnu/libncurses.so.6 $LIB/libncurses.so.5
                        ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 $LIB/libtinfo.so.5
                        ln -s /usr/lib/x86_64-linux-gnu/libform.so.6 $LIB/libform.so.5
                fi
                ;;
esac
____cubrid__here_doc____

# environment variables for *sh
echo ""
for e in "$cubrid_csh_envfile" "$cubrid_sh_envfile"; do
  if [ -r "${e}" ]; then
    echo "Copying old ${e} to ${e}.bak ..."
    mv -f "${e}" "${e}.bak"
  fi
  mv "${e}_temp" "${e}"
done

# append script for executing .cubrid.sh to .bash_profile
PRODUCT_NAME="CUBRID"
CUBRID_SH_INSTALLED=1
if [ -z "$SHELL" ];then
   if [ ! -r /etc/passwd ];then
      user_sh="bash"
   else
      user_name=$(id -nu)
      user_sh=$(egrep "^$user_name" /etc/passwd | cut -d':' -f7-7)
      user_sh=${user_sh:-none}
      user_sh=$(basename $user_sh)
   fi
else
      user_sh=$(basename $SHELL)
fi

if [ $user_sh = "bash" ];then
        sh_profile=$HOME/.bash_profile
        append_profile=$(grep "${PRODUCT_NAME} environment" $sh_profile)

        if [ -z "$append_profile" ];then
          echo '#-------------------------------------------------------------------------------' >> $sh_profile
          if [ $? -ne 0 ];then
            CUBRID_SH_INSTALLED=0
            echo "Please check your permission for file $sh_profile"
          else
            echo '# set '${PRODUCT_NAME}' environment variables'                                    >> $sh_profile
            echo '#-------------------------------------------------------------------------------' >> $sh_profile
            echo 'if [ -f $HOME/.cubrid.sh ];then'                                                  >> $sh_profile
            echo '. $HOME/.cubrid.sh'                                                               >> $sh_profile
            echo 'fi'                                                                               >> $sh_profile
          fi
        fi
else
  CUBRID_SH_INSTALLED=0
fi

# create a demo db
echo ""
if [ -x "${cubrid_home}/demo/make_cubrid_demo.sh" ]; then
  . ${cubrid_sh_envfile}
  (mkdir -p $CUBRID_DATABASES/demodb && cd $CUBRID_DATABASES/demodb && $CUBRID/demo/make_cubrid_demo.sh > /dev/null 2>&1)
  if [ $? = 0 ]; then
    echo "demodb has been successfully created."
  else
    echo "Cannot create demodb."
  fi
else
  echo "${cubrid_home}/demo/make_cubrid_demo.sh : No such file"
fi

echo ""
echo "If you want to use CUBRID, run the following command to set required environment variables."
if [ $CUBRID_SH_INSTALLED -eq 0 ];then
        echo "(or you can add the command into your current shell profile file to set permanently)"
fi
case "$SHELL" in
  */csh | */tcsh )
    echo "  $ source $cubrid_csh_envfile"
    ;;
  *)
    echo "  $ . $cubrid_sh_envfile"
    ;;
esac
echo ""

exit 0

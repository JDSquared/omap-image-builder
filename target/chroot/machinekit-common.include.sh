# fight replication: functions used in several machinekit configs


setup_system () {
	#For when sed/grep/etc just gets way to complex...
	cd /
	if [ -f /opt/scripts/mods/debian-add-sbin-usr-sbin-to-default-path.diff ] ; then
		if [ -f /usr/bin/patch ] ; then
			echo "Patching: /etc/profile"
			patch -p1 < /opt/scripts/mods/debian-add-sbin-usr-sbin-to-default-path.diff
		fi
	fi

	echo "" >> /etc/securetty
	echo "#zturn USB console Port" >> /etc/securetty
	echo "ttyPS0" >> /etc/securetty

#	this is now done in the choot, need to double check the mode..
#	# Enable all users to read hidraw devices
#	cat <<- EOF > /etc/udev/rules.d/99-hdiraw.rules
#		SUBSYSTEM=="hidraw", MODE="0644"
#	EOF

	# Enable PAM for ssh links
	# Fixes an issue where users cannot change ulimits when logged in via
	# ssh, which causes some Machinekit functions to fail
	sed -i 's/^UsePAM.*$/UsePam yes/' /etc/ssh/sshd_config

}

setup_desktop () {
	if [ -d /etc/X11/ ] ; then
		wfile="/etc/X11/xorg.conf"
		echo "Patching: ${wfile}"
		echo "Section \"Monitor\"" > ${wfile}
		echo "        Identifier      \"Builtin Default Monitor\"" >> ${wfile}
		echo "EndSection" >> ${wfile}
		echo "" >> ${wfile}
		echo "Section \"Device\"" >> ${wfile}
		echo "        Identifier      \"Builtin Default fbdev Device 0\"" >> ${wfile}

#		echo "        Driver          \"modesetting\"" >> ${wfile}
		echo "        Driver          \"fbdev\"" >> ${wfile}

		echo "#HWcursor_false        Option          \"HWcursor\"          \"false\"" >> ${wfile}

		echo "EndSection" >> ${wfile}
		echo "" >> ${wfile}
		echo "Section \"Screen\"" >> ${wfile}
		echo "        Identifier      \"Builtin Default fbdev Screen 0\"" >> ${wfile}
		echo "        Device          \"Builtin Default fbdev Device 0\"" >> ${wfile}
		echo "        Monitor         \"Builtin Default Monitor\"" >> ${wfile}
		echo "        DefaultDepth    16" >> ${wfile}
		echo "EndSection" >> ${wfile}
		echo "" >> ${wfile}
		echo "Section \"ServerLayout\"" >> ${wfile}
		echo "        Identifier      \"Builtin Default Layout\"" >> ${wfile}
		echo "        Screen          \"Builtin Default fbdev Screen 0\"" >> ${wfile}
		echo "EndSection" >> ${wfile}
	fi

	wfile="/etc/lightdm/lightdm.conf"
	if [ -f ${wfile} ] ; then
		echo "Patching: ${wfile}"
		sed -i -e 's:#autologin-user=:autologin-user='$rfs_username':g' ${wfile}
		sed -i -e 's:#autologin-session=UNIMPLEMENTED:autologin-session='$rfs_default_desktop':g' ${wfile}
		if [ -f /opt/scripts/3rdparty/xinput_calibrator_pointercal.sh ] ; then
			sed -i -e 's:#display-setup-script=:display-setup-script=/opt/scripts/3rdparty/xinput_calibrator_pointercal.sh:g' ${wfile}
		fi
	fi

	if [ ! "x${rfs_desktop_background}" = "x" ] ; then
		mkdir -p /home/${rfs_username}/.config/ || true
		if [ -d /opt/scripts/desktop-defaults/jessie/lxqt/ ] ; then
			cp -rv /opt/scripts/desktop-defaults/jessie/lxqt/* /home/${rfs_username}/.config
		fi
		chown -R ${rfs_username}:${rfs_username} /home/${rfs_username}/.config/
	fi

	# Switch to Machinekit desktop background
	wfile="/home/${rfs_username}/.config/pcmanfm-qt/lxqt/settings.conf"
	if [ -f ${wfile} ] ; then
		sed -i -e "s:^Wallpaper=.*\$:Wallpaper=${rfs_desktop_background}:" ${wfile}
	fi

	#Disable dpms mode and screen blanking
	#Better fix for missing cursor
	wfile="/home/${rfs_username}/.xsessionrc"
	echo "#!/bin/sh" > ${wfile}
	echo "" >> ${wfile}
	echo "xset -dpms" >> ${wfile}
	echo "xset s off" >> ${wfile}
	echo "xsetroot -cursor_name left_ptr" >> ${wfile}
	chown -R ${rfs_username}:${rfs_username} ${wfile}

#	#Disable LXDE's screensaver on autostart
#	if [ -f /etc/xdg/lxsession/LXDE/autostart ] ; then
#		sed -i '/xscreensaver/s/^/#/' /etc/xdg/lxsession/LXDE/autostart
#	fi

	#echo "CAPE=cape-bone-proto" >> /etc/default/capemgr

#	#root password is blank, so remove useless application as it requires a password.
#	if [ -f /usr/share/applications/gksu.desktop ] ; then
#		rm -f /usr/share/applications/gksu.desktop || true
#	fi

#	#lxterminal doesnt reference .profile by default, so call via loginshell and start bash
#	if [ -f /usr/bin/lxterminal ] ; then
#		if [ -f /usr/share/applications/lxterminal.desktop ] ; then
#			sed -i -e 's:Exec=lxterminal:Exec=lxterminal -l -e bash:g' /usr/share/applications/lxterminal.desktop
#			sed -i -e 's:TryExec=lxterminal -l -e bash:TryExec=lxterminal:g' /usr/share/applications/lxterminal.desktop
#		fi
#	fi

	if [ -f /etc/init.d/connman ] ; then
		mkdir -p /etc/connman/ || true
		wfile="/etc/connman/main.conf"
		echo "[General]" > ${wfile}
		echo "PreferredTechnologies=ethernet,wifi" >> ${wfile}
		echo "SingleConnectedTechnology=false" >> ${wfile}
		echo "AllowHostnameUpdates=false" >> ${wfile}
		echo "PersistentTetheringMode=true" >> ${wfile}
		echo "NetworkInterfaceBlacklist=usb0" >> ${wfile}

		mkdir -p /var/lib/connman/ || true
		wfile="/var/lib/connman/settings"
		echo "[global]" > ${wfile}
		echo "OfflineMode=false" >> ${wfile}
		echo "" >> ${wfile}
		echo "[Wired]" >> ${wfile}
		echo "Enable=true" >> ${wfile}
		echo "Tethering=false" >> ${wfile}
		echo "" >> ${wfile}
		echo "[WiFi]" >> ${wfile}
		echo "Enable=true" >> ${wfile}
		echo "Tethering=true" >> ${wfile}
		echo "Tethering.Identifier=mksocfgpa" >> ${wfile}
		echo "Tethering.Passphrase=mksocfgpa" >> ${wfile}
		echo "" >> ${wfile}
		echo "[Gadget]" >> ${wfile}
		echo "Enable=false" >> ${wfile}
		echo "Tethering=false" >> ${wfile}
		echo "" >> ${wfile}
		echo "[P2P]" >> ${wfile}
		echo "Enable=false" >> ${wfile}
		echo "Tethering=false" >> ${wfile}
	fi
}

install_gem_pkgs () {
	if [ -f /usr/bin/gem ] ; then
		echo "Installing gem packages"
		echo "debug: gem: [`gem --version`]"
		gem_wheezy="--no-rdoc --no-ri"
		gem_jessie="--no-document"

		echo "gem: [beaglebone]"
		gem install beaglebone || true

		echo "gem: [jekyll ${gem_jessie}]"
		gem install jekyll ${gem_jessie} || true
	fi
}

install_pip_pkgs () {
	if [ -f /usr/bin/python ] ; then
		wget https://bootstrap.pypa.io/get-pip.py || true
		if [ -f get-pip.py ] ; then
			python get-pip.py
			rm -f get-pip.py || true

			if [ -f /usr/local/bin/pip ] ; then
				echo "Installing pip packages"
				#Fixed in git, however not pushed to pip yet...(use git and install)
				#libpython2.7-dev
				#pip install Adafruit_BBIO
				echo currently none
				# git_repo="https://github.com/adafruit/adafruit-beaglebone-io-python.git"
				# git_target_dir="/opt/source/adafruit-beaglebone-io-python"
				# git_clone
				# if [ -f ${git_target_dir}/.git/config ] ; then
				# 	cd ${git_target_dir}/
				# 	python setup.py install
				# fi
				# pip install --upgrade PyBBIO
				# pip install iw_parse
			fi
		fi
	fi
}

cleanup_npm_cache () {
	if [ -d /root/tmp/ ] ; then
		rm -rf /root/tmp/ || true
	fi

	if [ -d /root/.npm ] ; then
		rm -rf /root/.npm || true
	fi

	if [ -f /home/${rfs_username}/.npmrc ] ; then
		rm -f /home/${rfs_username}/.npmrc || true
	fi
}

install_node_pkgs () {
	if [ -f /usr/bin/npm ] ; then
		cd /
		echo "Installing npm packages"
		echo "debug: node: [`nodejs --version`]"

		if [ -f /usr/local/bin/npm ] ; then
			npm_bin="/usr/local/bin/npm"
		else
			npm_bin="/usr/bin/npm"
		fi

		echo "debug: npm: [`${npm_bin} --version`]"

		#debug
		#echo "debug: npm config ls -l (before)"
		#echo "--------------------------------"
		#${npm_bin} config ls -l
		#echo "--------------------------------"

		#c9-core-installer...
		${npm_bin} config delete cache
		${npm_bin} config delete tmp
		${npm_bin} config delete python

		#fix npm in chroot.. (did i mention i hate npm...)
		if [ ! -d /root/.npm ] ; then
			mkdir -p /root/.npm
		fi
		${npm_bin} config set cache /root/.npm
		${npm_bin} config set group 0
		${npm_bin} config set init-module /root/.npm-init.js

		if [ ! -d /root/tmp ] ; then
			mkdir -p /root/tmp
		fi
		${npm_bin} config set tmp /root/tmp
		${npm_bin} config set user 0
		${npm_bin} config set userconfig /root/.npmrc

		${npm_bin} config set prefix /usr/local/

		#echo "debug: npm configuration"
		#echo "--------------------------------"
		#${npm_bin} config ls -l
		#echo "--------------------------------"

		sync

		if [ -f /usr/local/bin/jekyll ] ; then
			git_repo="https://github.com/beagleboard/bone101"
			git_target_dir="/var/lib/cloud9"

			if [ "x${bone101_git_sha}" = "x" ] ; then
				git_clone
			else
				git_clone_full
			fi

			if [ -f ${git_target_dir}/.git/config ] ; then
				chown -R ${rfs_username}:${rfs_username} ${git_target_dir}
				cd ${git_target_dir}/

				if [ ! "x${bone101_git_sha}" = "x" ] ; then
					git checkout ${bone101_git_sha} -b tmp-production
				fi

				echo "jekyll pre-building bone101"
				/usr/local/bin/jekyll build --destination bone101
			fi

			wfile="/lib/systemd/system/jekyll-autorun.service"
			echo "[Unit]" > ${wfile}
			echo "Description=jekyll autorun" >> ${wfile}
			echo "ConditionPathExists=|/var/lib/cloud9" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}
			echo "WorkingDirectory=/var/lib/cloud9" >> ${wfile}
			echo "ExecStart=/usr/local/bin/jekyll build --destination bone101 --watch" >> ${wfile}
			echo "SyslogIdentifier=jekyll-autorun" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=multi-user.target" >> ${wfile}

			systemctl enable jekyll-autorun.service || true

			if [ -d /etc/apache2/ ] ; then
				#bone101 takes over port 80, so shove apache/etc to 8080:
				if [ -f /etc/apache2/ports.conf ] ; then
					sed -i -e 's:80:8080:g' /etc/apache2/ports.conf
				fi
				if [ -f /etc/apache2/sites-enabled/000-default ] ; then
					sed -i -e 's:80:8080:g' /etc/apache2/sites-enabled/000-default
				fi
				if [ -f /var/www/html/index.html ] ; then
					rm -rf /var/www/html/index.html || true
				fi
			fi
		fi
	fi
}

early_git_repos () {
	git_repo="https://github.com/cdsteinkuehler/machinekit-beaglebone-extras"
	git_target_dir="opt/source/machinekit-extras"
	git_clone
}

install_git_repos () {

        echo currently none

	# git_repo="https://github.com/prpplague/Userspace-Arduino"
	# git_target_dir="/opt/source/Userspace-Arduino"
	# git_clone

	# git_repo="https://github.com/cdsteinkuehler/beaglebone-universal-io.git"
	# git_target_dir="/opt/source/beaglebone-universal-io"
	# git_clone
	# if [ -f ${git_target_dir}/.git/config ] ; then
	# 	if [ -f ${git_target_dir}/config-pin ] ; then
	# 		ln -s ${git_target_dir}/config-pin /usr/local/bin/
	# 	fi
	# fi

	# git_repo="https://github.com/strahlex/BBIOConfig.git"
	# git_target_dir="/opt/source/BBIOConfig"
	# git_clone

	# git_repo="https://github.com/prpplague/fb-test-app.git"
	# git_target_dir="/opt/source/fb-test-app"
	# git_clone
	# if [ -f ${git_target_dir}/.git/config ] ; then
	# 	cd ${git_target_dir}/
	# 	if [ -f /usr/bin/make ] ; then
	# 		make
	# 	fi
	# 	cd /
	# fi

	# #am335x-pru-package
	# if [ -f /usr/include/prussdrv.h ] ; then
	# 	git_repo="https://github.com/biocode3D/prufh.git"
	# 	git_target_dir="/opt/source/prufh"
	# 	git_clone
	# 	if [ -f ${git_target_dir}/.git/config ] ; then
	# 		cd ${git_target_dir}/
	# 		if [ -f /usr/bin/make ] ; then
	# 			make LIBDIR_APP_LOADER=/usr/lib/ INCDIR_APP_LOADER=/usr/include
	# 		fi
	# 		cd /
	# 	fi
	# fi

	# git_repo="https://github.com/RobertCNelson/dtb-rebuilder.git"
	# git_branch="4.1-ti"
	# git_target_dir="/opt/source/dtb-${git_branch}"
	# git_clone_branch

	# git_repo="https://github.com/beagleboard/bb.org-overlays"
	# git_target_dir="/opt/source/bb.org-overlays"
	# git_clone
	# if [ -f ${git_target_dir}/.git/config ] ; then
	# 	cd ${git_target_dir}/
	# 	if [ ! "x${repo_rcnee_pkg_version}" = "x" ] ; then
	# 		is_kernel=$(echo ${repo_rcnee_pkg_version} | grep 4.1 || true)
	# 		if [ ! "x${is_kernel}" = "x" ] ; then
	# 			if [ -f /usr/bin/make ] ; then
	# 				make
	# 				make install
	# 				update-initramfs -u -k ${repo_rcnee_pkg_version}
	# 				make clean
	# 			fi
	# 		fi
	# 	fi
	# fi

	# git_repo="https://github.com/ungureanuvladvictor/BBBlfs"
	# git_target_dir="/opt/source/BBBlfs"
	# git_clone
	# if [ -f ${git_target_dir}/.git/config ] ; then
	# 	cd ${git_target_dir}/
	# 	if [ -f /usr/bin/make ] ; then
	# 		./autogen.sh
	# 		./configure
	# 		make
	# 	fi
	# fi

	# #am335x-pru-package
	# if [ -f /usr/include/prussdrv.h ] ; then
	# 	git_repo="git://git.ti.com/pru-software-support-package/pru-software-support-package.git"
	# 	git_target_dir="/opt/source/pru-software-support-package"
	# 	git_clone
	# fi
}

install_build_pkgs () {
	cd /opt/
	cd /
}


unsecure_root () {
	root_password=$(cat /etc/shadow | grep root | awk -F ':' '{print $2}')
	sed -i -e 's:'$root_password'::g' /etc/shadow

	if [ -f /etc/ssh/sshd_config ] ; then
		#Make ssh root@beaglebone work..
		sed -i -e 's:PermitEmptyPasswords no:PermitEmptyPasswords yes:g' /etc/ssh/sshd_config
		#Machinekit requires UsePAM yes!
		#sed -i -e 's:UsePAM yes:UsePAM no:g' /etc/ssh/sshd_config
		#Starting with Jessie:
		sed -i -e 's:PermitRootLogin without-password:PermitRootLogin yes:g' /etc/ssh/sshd_config
	fi

	if [ -f /etc/sudoers ] ; then
		#Don't require password for sudo access
		echo "${rfs_username}  ALL=NOPASSWD: ALL" >>/etc/sudoers
	fi
}

install_machinekit_dev() {

    cd "/home/${rfs_username}"
    echo ". machinekit/scripts/rip-environment" >> .bashrc
    echo "echo environment set up for RIP build in /home/${rfs_username}/machinekit/src" >>.bashrc

    # clone the machinekit repo to /home/${rfs_username}
    git_repo="https://github.com/machinekit/machinekit"
    git_target_dir="/home/${rfs_username}/machinekit"
    git_clone_full

    # do source install steps as per docs
    apt-get install git dpkg-dev
    apt-get install --yes --no-install-recommends devscripts equivs

    cd ${git_target_dir}

    debian/configure -pr
    sudo DEBIAN_FRONTEND=noninteractive mk-build-deps -ir -t "apt-get -qq --no-install-recommends"

    cd src
    ./autogen.sh
    ./configure

    # build it
    make -j4

    # fix perms
    chown -R ${rfs_username}:${rfs_username} ${git_target_dir} /home/${rfs_username}/.bashrc

    # except what is needed
    sudo make setuid
}

add_uio_pdrv_genirq_params()
{
    echo options uio_pdrv_genirq of_id="generic-uio,ui_pdrv" > /etc/modprobe.d/uiohm2.conf
}

remove_machinekit_pkgs() {
    apt remove -y machinekit machinekit-dev machinekit-rt-preempt
}

symlink_dtbo() {
    # keeps u-boot-xlnx happy
    ln -s /usr/lib/linux-image-zynq-rt /boot/dtbs
}

add_uboot_to_fstab() {
    sudo sh -c "echo '/dev/mmcblk0p1  /boot/uboot  auto  defaults  0  2' >> /etc/fstab"
}


set_governor() {
# https://github.com/machinekit/mksocfpga/issues/20#issuecomment-241215541
cat <<EOFcpufrequtils >>/etc/default/cpufrequtils
# valid values: userspace conservative powersave ondemand performance
# get them from cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
GOVERNOR="performance"
EOFcpufrequtils
}

add_ros_apt_conf() {
    sudo sh -c "echo deb http://sir.upc.edu/debian-robotics jessie-robotics main" >>/etc/apt/sources.list.d/debian-robotics.list
    sudo apt-key adv --keyserver pgp.rediris.es --recv-keys 63DE76AC0B6779BF || \
	sudo apt-key adv --keyserver sks-keyservers.net --recv-keys 63DE76AC0B6779BF

cat <<EOFpreferences >>/etc/apt/preferences.d/jesse-robotics-700
# prefer jessie-robotics stream over rcn-ee jessie which would be default prio (500)
Package: *
Pin: release a=jessie-robotics
Pin-Priority: 700
EOFpreferences
}

force_depmod_all() {
    for i in `ls /boot/vmlinuz-*`
    do
        kversion=$(echo $i | sed 's/\/boot\/vmlinuz-//')
        echo depmodding ${kversion}
        sudo  depmod ${kversion}
    done
}

force_update_initramfs_all() {
    for i in `ls /boot/vmlinuz-*`
    do
        kversion=$(echo $i | sed 's/\/boot\/vmlinuz-//')
	if [ -f /boot/initrd.img-${kversion} ] ; then
            echo deleting initramfs for  ${kversion}
            sudo update-initramfs -d -k ${kversion}
	fi
	echo creating initramfs for  ${kversion}
        sudo update-initramfs -c -k ${kversion}
    done
}

fix_fsck_error() {
    sudo mkdir -p /etc/systemd/system-generators
    sudo ln -s /dev/null /etc/systemd/system-generators/systemd-gpt-auto-generator
    force_update_initramfs_all
}

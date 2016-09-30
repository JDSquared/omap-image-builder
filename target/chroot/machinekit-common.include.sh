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
	# Disable GSSAPI authentication
	echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config
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
	echo currently none
#	git_repo="https://github.com/cdsteinkuehler/machinekit-beaglebone-extras"
#	git_target_dir="opt/source/machinekit-extras"
#	git_clone
}

install_git_repos () {
	echo currently none
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
		sudo touch /var/log/linuxcnc.log
    cd "/home/${rfs_username}"
    echo ". machinekit/scripts/rip-environment" >> .bashrc
    echo "echo environment set up for RIP build in /home/${rfs_username}/machinekit/src" >>.bashrc

    # clone the machinekit repo to /home/${rfs_username}
    git_repo="https://github.com/JDSquared/machinekit"
    git_target_dir="/home/${rfs_username}/machinekit"
		git_branch="jd2"
    git_clone_branch

    # do source install steps as per docs
		sudo apt-get update
    sudo apt-get install git dpkg-dev libudev-dev
    sudo apt-get install --yes --no-install-recommends devscripts equivs

		# Grab the configs
		git_repo="https://github.com/JDSquared/mad_configs.git"
		git_target_dir="/home/${rfs_username}/machinekit/configs/by_machine/jd2"
		git_branch="master"
		git_clone_branch

		# Put the target dir var back for building mk
    git_target_dir="/home/${rfs_username}/machinekit"

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

		sudo cp rtapi/rsyslogd-linuxcnc.conf /etc/rsyslog.d/linuxcnc.conf
		sudo cp rtapi/shmdrv/limits.d-machinekit.conf /etc/security/limits

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

set_governor() {
# https://github.com/machinekit/mksocfpga/issues/20#issuecomment-241215541
cat <<EOFcpufrequtils >>/etc/default/cpufrequtils
# valid values: userspace conservative powersave ondemand performance
# get them from cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
GOVERNOR="performance"
EOFcpufrequtils
}

add_uboot_to_fstab() {
    sudo sh -c "echo '/dev/mmcblk0p1  /boot/uboot  auto  defaults  0  2' >> /etc/fstab"
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

# ========================   InstAUR 0.9.0   ========================= #
# ==================   Copyright 2015 Drew Nutter   ================== #
#                                                                      #
# This program is free software: you can redistribute it and/or modify #
# it under the terms of the GNU General Public License as published by #
# the Free Software Foundation, either version 3 of the License, or    #
# (at your option) any later version.                                  #
#                                                                      #
# This program is distributed in the hope that it will be useful,      #
# but WITHOUT ANY WARRANTY; without even the implied warranty of       #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
# GNU General Public License for more details.                         #
#                                                                      #
# You should have received a copy of the GNU General Public License    #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.#
# ==================================================================== #

# Define functions
function arguments {
	# This function identifies options and packages which are to be installed.
	while [ $i -lt $# ]; do
		i=$[$i+1]
		iter=${!i}
		if [ "${iter:0:1}" == "-" ] || [ "$iter" == "help" ]; then
			if [ "$iter" == "--help" ] || [ "$iter" == "help" ] || [ "$iter" == "-help" ] || [ "$iter" == "-h" ]; then
				help=1
			elif [ "$iter" == "--needed" ]; then
				needed=1
				pacopt="$pacopt $iter"
			elif [ "$iter" == "--noconfirm" ]; then
				noconfirm=1
				pacopt="$pacopt $iter"
			elif [ "${iter:0:2}" == "-R" ]; then
				rm=1
				pacopt="$iter"
			elif [ "${iter:0:2}" == "-S" ] || [ "${iter:0:2}" == "-S" ]; then
				echo "You do not need to use -S or -U, InstAUR uses a similar operation by default."
			else
				pacopt="$pacopt $iter"
			fi
		else
			numpkg=$[$numpkg+1]
			pkg[$numpkg]=${!i}
		fi
	done
}

function arguments2 {
# Identify options that affect this script's behavior (other than passing).
opset=0
for (( i=1; $i<=$#; i++ )); do
	iter=${!i}
	if [ "${iter:0:2}" == "--" ]; then
		#pacopt="$pacopt $iter"
		# Operations
		if [ "$iter" == "--help" ]; then
			help=1
		elif [ "$iter" == "--database" ]; then
			opset=$opset+1
			database=1
		elif [ "$iter" == "--query" ]; then
			opset=$opset+1
			query=1
		elif [ "$iter" == "--remove" ]; then
			opset=$opset+1
			remove=1
		elif [ "$iter" == "--sync" ]; then
			opset=$opset+1
			sync=1
		elif [ "$iter" == "--deptest" ]; then
			opset=$opset+1
			deptest=1
		elif [ "$iter" == "--upgrade" ]; then
			opset=$opset+1
			upgrade=1
		elif [ "$opt" == "--version" ]; then
			opset=$opset+1
			Voperation=1
		# Options
		elif [ "$iter" == "--needed" ]; then
			needed=1
			pacopt="$pacopt $iter"
		elif [ "$iter" == "--noconfirm" ]; then
			noconfirm=1
			pacopt="$pacopt $iter"
		else
			echo "$iter is not a valid argument."
		fi
	elif [ "${iter:0:1}" == "-" ]; then
		# pacopt="$pacopt $iter"
		string=${!i}
		for (( j=1; j<${#string}; j++ )); do
			opt=${string:$j:1}
			# Operations
			if [ "$opt" == "h" ]; then
				opset=$opset+1
				help=1
			elif [ "$opt" == "D" ]; then
				opset=$opset+1
				database=1
			elif [ "$opt" == "Q" ]; then
				opset=$opset+1
				query=1
			elif [ "$opt" == "R" ]; then
				opset=$opset+1
				remove=1
			elif [ "$opt" == "S" ]; then
				opset=$opset+1
				sync=1
			elif [ "$opt" == "T" ]; then
				opset=$opset+1
				deptest=1
			elif [ "$opt" == "U" ]; then
				opset=$opset+1
				upgrade=1
			elif [ "$opt" == "V" ]; then
				opset=$opset+1
				Voperation=1
			# Options
			elif [ "$opt" == "s" ]; then
				search=1
			fi
		done
	else
		numpkg=$[$numpkg+1]
		pkg[$numpkg]=${!i}
	fi
done
if [[ $opset -lt 1 ]]; then
	echo "error: You must specify an operation."
	contin=0
elif [[ $opset -gt 1 ]] && [[ $help != 1 ]]; then
	echo "error: You must specify only one operation."
	contin=0
fi
}

function versions {
	cvnum=`package-query -A $p | awk '{print $2}'`
	ivnum=`(pacman -Q $p 2> /dev/null) | awk '{print $2}'`
}

function pkgbuilddeps {
	# This function reads the PKGBUILD file to identify dependencies.
	awk '
	BEGIN {
		FS = "[ (\x27\"]"
	}
	{
		if ( $1 == "depends=" || $1 == "makedepends=" || openpar == 1 ){
			openpar = 1
			for (i=2;i<=NF;i++){
				if ( $i == ")" ) {
					openpar = 0
				} else {
					split($i,fixone,">")
					split(fixone[1],fixtwo,"<")
					split(fixtwo[1],fixed,")")		# in case touching)
					if ( fixtwo[1] != fixed[1] ) {
						openpar = 0
					}
					print "if [[ $(pacman -Ss "fixed[1]") ]]; then : ; else echo -n \""fixed[1]" \"; fi"
				}
			}
		}
	}
	' /tmp/instaur/PKGBUILD | sh
}

function downverdeps {
	# This function downloads the package and identifies dependencies and versions
	versions
	rm -rf /tmp/instaur/PKGBUILDs
	sudo -u $curuser curl -Ss https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$p > /tmp/instaur/PKGBUILD
	bigdeplist=$(pkgbuilddeps)
	c=0
	for onedep in $bigdeplist
	do
		c=$[$c+1]
		bigdeparray[$c]=$onedep
	done
	depcounter=0
	for (( i=1; $i<=$c; i++ )); do		# This loop takes out repeats (sometimes build deps and deps overlap)
		strike=0
		for (( j=1; $j<$i; j++ )); do
			if [[ ${bigdeparray[$i]} == ${bigdeparray[$j]} ]]; then
				strike=1
			fi
		done
		if [[ $strike == 0 ]]; then
			depcounter=$[$depcounter+1]
			deparray[$depcounter]=${bigdeparray[$i]}
			dependencies="$dependencies ${bigdeparray[$i]}"
		fi
	done
}

function versiondecide {
	if [[ $cvnum > $ivnum ]] || [[ ! $ivnum ]]; then
		echo # Add to list
	elif [[ $ivnum == $cvnum ]]; then
		echo # Don't add to list
	elif [[ ! $cvnum ]]; then
		echo "No package called $p could be found in the Arch User Repository."
	else
		echo "There was an error with $p."
	fi
}

function versiondialog {
	if [[ $ivnum == $cvnum ]] && [[ $cvnum > 0 ]] && [ $needed == 0 ]; then
		echo -e "\nYour current version of $p is $ivnum and it is up to date. Preparing to re-install . . ."
		itype="update"
	elif [[ $ivnum == $cvnum ]] && [ $cvnum > 0 ]; then
		echo -e "\nYour current version of $p is $ivnum and it is up to date. It will not be re-installed."
		itype="noinstall"
	elif [[ $ivnum ]] && [[ $cvnum > 0 ]]; then
		echo -e "\nYour current version of $p is $ivnum. Preparing to update to $cvnum . . ."
		itype="update"
	elif [[ $cvnum ]]; then
		echo -e "\nPreparing to install $p version $cvnum . . ."
		itype="fresh"
	else
		echo "No package called $p could be found in the Arch User Repository."
		itype="noinstall"
	fi
}

function deplist {
	if [[ $dependencies ]]; then
		echo -e "\nThe following dependencies will not be updated automatically. Ensure they are up to date before proceeding:"
		echo "$dependencies"
	elif [[ $itype != "noinstall" ]]; then
		echo -e "\nIt appears that any $p dependencies will be automatically installed from the official repositories if necessary."
	fi
}

function QueryFunction {
	for (( sofar=1; $sofar<=$numpkg; sofar++ )); do
		p=${pkg[$sofar]}
		echo
		# awk search instaur.log
		awk -v p=$p '{
			if ( $3 == p) {
				split($5,namever,p"-")
				split(namever[2],almost,"-x86")
				split(almost[1],version,"-any")
				# printf "Name: "$3"\nVersion: "version[1]"\nAUR Dependencies: "  UNCOMMENT FOR REDUNDANT INFO
				printf "AUR Dependencies: "
				for ( i=7; i<NF; i++ ){
					printf $i" "
				}
			}
		}' /var/instaur.log
		echo
		echo
		pacman $pacopt $p
	done
}

function UpgradeCheck {
	pacman -Qm | awk '
		upgrade_count=0
		print "upgrade_package[$upgrade_count]="hi
		print "upgrade_ivnum[$upgrade_count]="bye
		upgrade_count=$upgrade_count+1
	' | sh
}


function buildinstall {
	mkdir /tmp/instaur 2> /dev/null # Have this ready to fill
	cd /tmp/instaur
	curl -Ss https://aur.archlinux.org/cgit/aur.git/snapshot/$p.tar.gz | tar zx
	chown -R instaur /tmp/instaur
	cd $p && (sudo -u $curuser makepkg -s 2>&1) | tee /tmp/instaur-pacman.log
	echo "$pacopt"
	(pacman -U $pacopt $p*tar.xz 2>&1) | tee /tmp/instaur-pacman.log
}

function post {
	# If successful, update log and remove installation files
	if [ "$(grep -i "available" /tmp/instaur-pacman.log)" ] && [ "$(grep -i "error:" /tmp/instaur-pacman.log)" != "error:" ] && [ "$(grep -i "failed" /tmp/instaur-pacman.log)" != "failed" ]; then
		echo -e "\nInstallation was a success!\n"
		specif=$(find $PWD -name *.xz -type f -printf "%f\n" | sed s/.pkg.tar.xz//)
		cd ..
		if [ ! -f /var/instaur.log ]; then
			echo "Date - Generic Name - Specific Name - AUR Dependencies" >> /var/instaur.log
		fi
		#cp /tmp/instaur.log.bak /tmp/instaur.log.bak.old
		#cp /tmp/instaur.log /tmp/instaur.log.bak
		awk -v pname=$p '{ if ($3 != pname) {print ($0)} }' /var/instaur.log > /tmp/instaur.tmp
		mv /tmp/instaur.tmp /var/instaur.log
		echo "$(date +"%Y-%m-%d_%H:%M:%S") - $p - $specif - $dependencies" >> /var/instaur.log
		if [ $noconfirm == 0 ]; then
			echo "Would you like to remove the "$p" package directory (only needed during installation)? [Y/n]"
			read rmpkg
			if [[ $rmpkg != "" ]] && [[ $rmpkg != "y" ]] && [[ $rmpkg != "Y" ]] && [[ $rmpkg != "yes" ]] && [[ $rmpkg != "Yes" ]] && [[ $rmpkg != "YES" ]] && [[ $rmpkg != "yES" ]] && [[ $rmpkg != "yeS" ]] && [[ $rmpkg != "YeS" ]] && [[ $rmpkg != "yEs" ]] && [[ $rmpkg != "YEs" ]]; then
				echo "Installation data not deleted."
			else
				rm -rf $p
				echo "Unnecessary installation data deleted."
			fi
		elif [ $noconfirm == 1 ]; then
			rm -rf $p
		fi
	else
		echo -e "\nInstallation did not complete.\n"
	fi
}

# exec < /dev/tty			# Why did I think this was necessary again?

# Initialize (some are "just in case" things added while debugging)
i=0
j=0
k=0
rm=0
help=0
needed=0
noconfirm=0
pacopt=""
contin=1
sofar=0
numpkg=0

#finduser		# Determine non-root user initiating install
curuser=instaur
arguments2 $@	# This gives us option states plus the pkg[] array

whoiam=$(whoami)
# Check and demand root
if [[ $whoiam != "root" ]] && ([[ $sync == 1 ]] || [[ $remove == 1 ]]); then
	echo "error: you cannot perform this operation unless you are root."
	contin=0
fi

# Help 
if [ $help == 1 ]; then
	echo -e "\n\n"
	cat /usr/share/info/instaur-help.txt
	echo -e "\n"

# Check InstAUR and pacman versions
elif [[ $Voperation == 1 ]]; then
	echo "InstAUR 0.8.0"
	pacman -V

# Uninstall
elif [[ $contin == 1 ]] && [[ $remove == 1 ]]; then
	for (( sofar=1; $sofar<=$numpkg; sofar++ )); do
		sudo pacman $pacopt ${pkg[$sofar]}
		#awk -v pname=$p '{ if ($3 != pname) {print ($0)} }' /usr/var/instaur-short.log > /tmp/instaur.tmp
		#mv /tmp/instaur.tmp /usr/var/instaur-short.log
	done

# Query both instaur.log and pacman
elif [[ $contin == 1 ]] && [[ $query == 1 ]]; then
	QueryFunction
	
# These are separate conditionals so they can be improved later.
elif [[ $contin == 1 ]] && [[ $upgrade == 1 ]]; then
	echo "This command is being passed directly to pacman unaltered . . ."
	pacman $@
elif [[ $contin == 1 ]] && [[ $deptest == 1 ]]; then
	echo "This command is being passed directly to pacman unaltered . . ."
	pacman $@
elif [[ $contin == 1 ]] && [[ $database == 1 ]]; then
	echo "This command is being passed directly to pacman unaltered . . ."
	pacman $@

# fakesync
elif [ $contin == 1 ] && [ $sync == 1 ] && [[ $search == 1 ]]; then
	package-query -A $@
# sync
elif [ $contin == 1 ] && [ $sync == 1 ]; then
	# for (( sofar=1; $sofar<=$numpkg; sofar++ )); do
		# dependency loop
	# done
	for (( sofar=1; $sofar<=$numpkg; sofar++ )); do
		# Re-init every time
		p=${pkg[$sofar]}
		itype="noinstall"
		ivnum=0
		cvnum=0
		yn=0
		rmpkg=0
		
		echo "Downloading package information . . ."
		downverdeps		# Download & extract tarball, check version numbers & dependencies
		versiondialog	# Inform user: Fresh install, need update, up to date?
		deplist			# List dependencies and info based on sources.
	
		if [ $noconfirm == 0 ] && [[ $itype != "noinstall" ]]; then
			printf "\nAre you sure you would like to continue with this installation? [Y/n]:"
			read itok
			if [[ $itok != "" ]] && [[ $itok != "y" ]] && [[ $itok != "Y" ]] && [[ $itok != "yes" ]] && [[ $itok != "Yes" ]] && [[ $itok != "YES" ]] && [[ $itok != "yES" ]] && [[ $itok != "yeS" ]] && [[ $itok != "YeS" ]] && [[ $itok != "yEs" ]] && [[ $itok != "YEs" ]]; then
				contin=0
				echo -e "\nInstallation aborted."
			fi
		fi
		if [ $contin == 1 ] && [[ $itype != "noinstall" ]]; then
		echo "Installing . . ."
			buildinstall	# Build and install the package
			post			# Update instaur.log and remove installation files.
		fi
	done

fi

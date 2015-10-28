# ========================   InstAUR 0.9.0   ========================= #
# ==================   Copyright 2014 Drew Nutter   ================== #
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

if [[ `whoami` != "root" ]]; then
	echo "error: you cannot perform this operation unless you are root."
else
	userdel instaur
	useradd -rms /usr/bin/nologin instaur
	sudo -u instaur gpg --list-keys
	keysetting=`awk 'BEGIN{preset = 0}{
		if ($0 == "keyserver-options auto-key-retrieve" ){
			preset = 1
		}
	}
	END {
		if ( preset == 0 ){
			printf "keyserver-options auto-key-retrieve"
		}
	}' /home/instaur/.gnupg/gpg.conf`
	echo -n "$keysetting" >> /home/instaur/.gnupg/gpg.conf
	sed -i '/instaur/d' /etc/sudoers
	sudo echo "instaur ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	BASEDIR=$(dirname $0)
	cp $BASEDIR/instaur.sh /usr/bin/instaur
	cp $BASEDIR/README.md /usr/share/info/instaur-help.txt
	chown -R instaur /home/instaur
	echo "InstAUR 0.9.0 has been installed."
fi
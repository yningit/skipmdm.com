#!/bin/bash

RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${CYAN}*-------------------*---------------------*${NC}"
echo -e "${YEL}* Check MDM - Skip MDM Auto for MacOS by *${NC}"
echo -e "${RED}*             SKIPMDM.COM                *${NC}"
echo -e "${RED}*            Phoenix Team                *${NC}"
echo -e "${CYAN}*-------------------*---------------------*${NC}"
echo ""

PS3='Please enter your choice: '
options=("Autoypass on Recovery" "Reboot")

select opt in "${options[@]}"; do
	case $opt in
	"Autoypass on Recovery")
		echo -e "${GRN}Bypass on Recovery"

		# Mount Volumes
		echo -e "${BLU}Preparing volumes...${NC}"
		systemVolumePath="/Volumes/Macintosh HD"
		dataVolumePath="/Volumes/Macintosh HD - Data"

		if [ ! -d "$systemVolumePath" ]; then
			diskutil mount "Macintosh HD"
		fi

		if [ ! -d "$dataVolumePath" ]; then
			diskutil mount "Macintosh HD - Data"
		fi

		echo -e "${GRN}Volume preparation completed${NC}\n"

		# Create User
		echo -e "${BLU}Checking user existence${NC}"
		dscl_path="$dataVolumePath/private/var/db/dslocal/nodes/Default"
		localUserDirPath="/Local/Default/Users"
		defaultUID="501"
		if ! dscl -f "$dscl_path" localhost -list "$localUserDirPath" UniqueID | grep -q "\<$defaultUID\>"; then
			echo -e "${CYAN}Create a new user / Tạo User mới${NC}"
			echo -e "${CYAN}Press Enter to continue, Note: Leaving it blank will default to the automatic user / Nhấn Enter để tiếp tục, Lưu ý: có thể không điền sẽ tự động nhận User mặc định${NC}"
			echo -e "${CYAN}Enter Full Name (Default: Apple) / Nhập tên User (Mặc định: Apple)${NC}"
			read -rp "Full name: " fullName
			fullName="${fullName:=Apple}"

			echo -e "${CYAN}Nhận username${NC} ${RED}WRITE WITHOUT SPACES / VIẾT LIỀN KHÔNG DẤU${NC} ${GRN}(Mặc định: Apple)${NC}"
			read -rp "Username: " username
			username="${username:=Apple}"

			echo -e "${CYAN}Enter the userPasswordord (default: 1234) / Nhập mật khẩu (mặc định: 1234)${NC}"
			read -rsp "Password: " userPassword
			userPassword="${userPassword:=1234}"

			echo -e "\n${BLU}Creating User / Đang tạo User${NC}"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UserShell "/bin/zsh"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" RealName "$fullName"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UniqueID "$defaultUID"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" PrimaryGroupID "20"
			mkdir "$dataVolumePath/Users/$username"
			dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" NFSHomeDirectory "/Users/$username"
			dscl -f "$dscl_path" localhost -passwd "$localUserDirPath/$username" "$userPassword"
			dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"
			echo -e "${GRN}User created${NC}\n"
		else
			echo -e "${BLU}User already created${NC}\n"
		fi

		# Block MDM hosts
		echo -e "${BLU}Blocking MDM hosts...${NC}"
		hostsPath="$systemVolumePath/etc/hosts"
		blockedDomains=("deviceenrollment.apple.com" "mdmenrollment.apple.com" "iprofiles.apple.com")
		for domain in "${blockedDomains[@]}"; do
			echo "0.0.0.0 $domain" >>"$hostsPath"
		done
		echo -e "${GRN}Successfully blocked host / Thành công chặn host${NC}\n"

		# Remove config profile
		configProfilesSettingsPath="$systemVolumePath/var/db/ConfigurationProfiles/Settings"
		touch "$dataVolumePath/private/var/db/.AppleSetupDone"
		rm -rf "$configProfilesSettingsPath/.cloudConfigHasActivationRecord"
		rm -rf "$configProfilesSettingsPath/.cloudConfigRecordFound"
		touch "$configProfilesSettingsPath/.cloudConfigProfileInstalled"
		touch "$configProfilesSettingsPath/.cloudConfigRecordNotFound"

		echo -e "${CYAN}------ Autobypass SUCCESSFULLY / Autobypass HOÀN TẤT ------${NC}"
		echo -e "${CYAN}------ Exit Terminal , Reset Macbook and ENJOY ! ------${NC}"
		break
		;;

	"Check MDM Enrollment")
		echo ""
		echo -e "${GRN}Check MDM Enrollment. Error is success${NC}"
		echo ""
		echo -e "${RED}Please Insert Your Password To Proceed${NC}"
		echo ""
		sudo profiles show -type enrollment
		break
		;;

	"Exit")
		echo "Rebooting..."
		reboot
		break
		;;

	*)
		echo "Invalid option $REPLY"
		;;
	esac
done

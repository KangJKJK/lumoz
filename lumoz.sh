#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 초기 선택 메뉴
echo -e "${YELLOW}옵션을 선택하세요:${NC}"
echo -e "${GREEN}1: Lumoz 노드 새로 설치${NC}"
echo -e "${GREEN}2: Lumoz 노드 업데이트${NC}"
echo -e "${RED}3: Lumoz 노드 삭제${NC}"
read -p "선택 (1, 2, 3): " option

if [ "$option" == "1" ]; then
    echo "Lumoz 노드 새로 설치를 선택했습니다."
    
    echo -e "${YELLOW}NVIDIA 드라이버 설치 옵션을 선택하세요:${NC}"
    echo -e "1: 일반 그래픽카드 (RTX, GTX 시리즈) 드라이버 설치"
    echo -e "2: 서버용 GPU (T4, L4, A100 등) 드라이버 설치"
    echo -e "3: 기존 드라이버 및 CUDA 완전 제거"
    echo -e "4: 드라이버 설치 건너뛰기"
    
    while true; do
        read -p "선택 (1, 2, 3, 4): " driver_option
        
        case $driver_option in
            1)
                sudo apt update
                sudo apt install -y nvidia-utils-550
                sudo apt install -y nvidia-driver-550
                sudo apt-get install -y cuda-drivers-550 
                sudo apt-get install -y cuda-12-3
                ;;
            2)
                distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
                wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-keyring_1.0-1_all.deb
                sudo dpkg -i cuda-keyring_1.0-1_all.deb
                sudo apt-get update
                sudo apt install -y nvidia-utils-550-server
                sudo apt install -y nvidia-driver-550-server
                sudo apt-get install -y cuda-12-3
                ;;
            3)
                echo "기존 드라이버 및 CUDA를 제거합니다..."
                sudo apt-get purge -y nvidia*
                sudo apt-get purge -y cuda*
                sudo apt-get purge -y libnvidia*
                sudo apt autoremove -y
                sudo rm -rf /usr/local/cuda*
                echo "드라이버 및 CUDA가 완전히 제거되었습니다."
                ;;
            4)
                echo "드라이버 설치를 건너뜁니다."
                break
                ;;
            *)
                echo "잘못된 선택입니다. 다시 선택해주세요."
                continue
                ;;
        esac
        
        if [ "$driver_option" != "4" ]; then
            echo -e "\n${YELLOW}NVIDIA 드라이버 설치 옵션을 선택하세요:${NC}"
            echo -e "1: 일반 그래픽카드 (RTX, GTX 시리즈) 드라이버 설치"
            echo -e "2: 서버용 GPU (T4, L4, A100 등) 드라이버 설치"
            echo -e "3: 기존 드라이버 및 CUDA 완전 제거"
            echo -e "4: 드라이버 설치 건너뛰기"
        fi
    done
    
        # CUDA 툴킷 설치 여부 확인
        if command -v nvcc &> /dev/null; then
            echo -e "${GREEN}CUDA 툴킷이 이미 설치되어 있습니다.${NC}"
            nvcc --version
            read -p "CUDA 툴킷을 다시 설치하시겠습니까? (y/n): " reinstall_cuda
            if [ "$reinstall_cuda" == "y" ]; then
                sudo apt-get install -y nvidia-cuda-toolkit
            fi
        else
            echo -e "${YELLOW}CUDA 툴킷을 설치합니다...${NC}"
            sudo apt-get install -y nvidia-cuda-toolkit
        fi

        read -p "윈도우라면 파워셸을 관리자권한으로 열어서 다음 명령어들을 입력하세요"
        echo "wsl --set-default-version 2"
        echo "wsl --shutdown"
        echo "wsl --update"
    
        # 사용자 입력 받기
        read -p "GPU 종류를 선택하세요 (1: NVIDIA, 2: AMD): " gpu_choice
        read -p "Lumoz 지갑 주소를 입력하세요: " wallet_address
        read -p "채굴자 이름을 입력하세요: " miner_name
    
        # GPU 선택에 따른 다운로드 및 설치
        if [ "$gpu_choice" == "1" ]; then
            echo "NVIDIA GPU 마이너를 다운로드합니다..."
            wget https://github.com/6block/zkwork_moz_prover/releases/download/v1.0.2/moz_prover-v1.0.2_cuda.tar.gz
            tar -zvxf moz_prover-v1.0.2_cuda.tar.gz
        elif [ "$gpu_choice" == "2" ]; then
            echo "AMD GPU 마이너를 다운로드합니다..."
            wget https://github.com/6block/zkwork_moz_prover/releases/download/v1.0.2/moz_prover-v1.0.2_ocl.tar.gz
            tar -zvxf moz_prover-v1.0.2_ocl.tar.gz
        else
            echo "잘못된 선택입니다."
            exit 1
        fi
    
        # moz_prover 디렉토리로 이동
        cd moz_prover
    
        # inner_prover.sh 파일 수정
        sed -i "s/reward_address=.*/reward_address=$wallet_address/" inner_prover.sh
        sed -i "s/custom_name=.*/custom_name=\"$miner_name\"/" inner_prover.sh
    
        # 실행 권한 부여 및 마이너 시작
        chmod +x run_prover.sh
        chmod +x moz_prover

        # UFW 활성화 (아직 활성화되지 않은 경우)
        sudo ufw enable
        
        # TCP 포트 허용
        sudo ufw allow 22/tcp   # SSH
        sudo ufw allow 53/tcp   # DNS
        
        # UDP 포트 허용
        sudo ufw allow 54125/udp  # avahi-daemon
        sudo ufw allow 5353/udp   # avahi-daemon
        sudo ufw allow 53/udp     # DNS (systemd-resolve)
        sudo ufw allow 68/udp     # DHCP Client
        sudo ufw allow 323/udp    # chronyd
        sudo ufw allow 47721/udp  # avahi-daemon

        echo -e "${YELLOW}마이너를 시작합니다...${NC}"
        sudo touch prover.log && sudo chmod 666 prover.log
        ./run_prover.sh
    
        # 로그 확인
        echo "3초 후 마이닝 로그를 표시합니다..."
        sleep 3

        # 로그 실시간 확인
        tail -f prover.log

        echo "해당사이트에서 대시보드를 확인하세요: https://zk.work/en/lumoz/"
        echo -e "${GREEN}스크립트작성자: https://t.me/kjkresearch${NC}"

elif [ "$option" == "2" ]; then
    echo "Lumoz 노드 업데이트를 선택했습니다."

    # 현재 버전 입력 받기
    echo -e "${GREEN}해당사이트에 방문하세요: https://github.com/6block/zkwork_moz_prover/tags${NC}"
    read -p "현재 버전을 입력하세요 (예: v1.0.2): " version
    export VERSION=$version

    # 작업 디렉토리 생성 및 이동 부분 수정
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    # GPU 종류 선택
    echo "GPU 종류를 선택하세요:"
    echo "1: NVIDIA"
    echo "2: AMD"
    read -p "선택 (1 또는 2): " gpu_choice

    # 설치 과정 시작
    echo "설치 과정이 시작됩니다. 버전: $VERSION"

    # 다운로드 및 설치 과정
    if [ "$gpu_choice" == "1" ]; then
        echo "zkwork Nvidia miner 다운로드 중..."
        wget "https://github.com/6block/zkwork_moz_prover/releases/download/$VERSION/moz_prover-$VERSION_cuda.tar.gz"
        
        # 다운로드한 파일 압축 해제
        echo "NVIDIA 마이너 압축 해제 중..."
        tar -zvxf "moz_prover-$VERSION_cuda.tar.gz"
    elif [ "$gpu_choice" == "2" ]; then
        echo "zkwork AMD miner 다운로드 중..."
        wget "https://github.com/6block/zkwork_moz_prover/releases/download/$VERSION/moz_prover-$VERSION_ocl.tar.gz"
        
        # 다운로드한 파일 압축 해제
        echo "AMD 마이너 압축 해제 중..."
        tar -zvxf "moz_prover-$VERSION_ocl.tar.gz"
    else
        echo "잘못된 선택입니다. 스크립트를 종료합니다."
        exit 1
    fi

    # Lumoz 주소 및 사용자 지정 이름 업데이트
    read -p "Lumoz 지갑 주소를 입력하세요: " wallet_address
    read -p "채굴자 이름을 입력하세요: " miner_name

    # inner_prover.sh 파일 수정
    sed -i "s/reward_address=.*/reward_address=$wallet_address/" inner_prover.sh
    sed -i "s/custom_name=.*/custom_name=\"$miner_name\"/" inner_prover.sh

    # 실행 권한 부여 및 마이너 시작
    chmod +x run_prover.sh
    chmod +x moz_prover

    echo -e "${YELLOW}마이너를 시작합니다...${NC}"
    ./moz_prover --lumozpool moz.asia.zk.work:10010 --mozaddress $wallet_address --custom_name $miner_name

    # 로그 확인
    echo "3초 후 마이닝 로그를 표시합니다..."
    sleep 3

    # 로그 실시간 확인
    tail -f prover.log

    echo "해당 사이트에서 대시보드를 확인하세요: https://zk.work/en/lumoz/"
    echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"

elif [ "$option" == "3" ]; then
    echo "Lumoz 노드 삭제를 선택했습니다."

    # 작업 디렉토리 삭제
    if [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
        echo "Lumoz 마이너 디렉토리가 삭제되었습니다."
    fi
    
    # 1. 먼저 실행 중인 모든 관련 프로세스 확인
    ps aux | grep "[m]oz_prover"

    # 2. sudo를 사용하여 프로세스 종료
    sudo kill $(pgrep moz_prover)
    sudo kill $(pgrep run_prover)

    # 3. 여전히 실행 중이라면 강제 종료
    sudo pkill -f "moz_prover"
    sudo pkill -f "run_prover.sh"
    sudo pkill -9 moz_prover
    
    # 실제 moz_prover 프로세스 찾기 및 종료
    moz_pid=$(ps aux | grep "[m]oz_prover" | awk '{print $2}')
    if [ ! -z "$moz_pid" ]; then
        echo "moz_prover 프로세스(PID: $moz_pid)를 종료합니다..."
        sudo kill $moz_pid
        sleep 2
        
        # 프로세스가 여전히 실행 중이면 강제 종료
        if ps -p $moz_pid > /dev/null; then
            echo "프로세스를 강제 종료합니다..."
            sudo kill -9 $moz_pid
        fi
        echo "프로세스가 종료되었습니다."
    else
        echo "실행 중인 moz_prover 프로세스를 찾을 수 없습니다."
    fi

else
    echo "잘못된 선택입니다."
    exit 1
fi

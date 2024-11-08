#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

echo "현재 작업 디렉토리: $(pwd)"
echo "홈 디렉토리: $HOME"

# 초기 선택 메뉴
echo -e "${YELLOW}옵션을 선택하세요:${NC}"
echo -e "${GREEN}1: Lumoz 노드 새로 설치${NC}"
echo -e "${GREEN}2: Lumoz 노드 업데이트${NC}"
echo -e "${RED}3: Lumoz 노드 삭제${NC}"
read -p "선택 (1, 2, 3): " option

# 선택에 따른 작업 수행
if [ "$option" == "1" ]; then

    # 필수 패키지 설치
    sudo apt-get update
    sudo apt-get install nvidia-cuda-toolkit

    read -p "윈도우 파워셸을 관리자권한으로 열어서 다음 명령어들을 입력하세요"
    echo "wsl --set-default-version 2"
    echo "wsl --shutdown"
    echo "wsl --update"

    # 작업 디렉토리 생성 및 이동
    WORK_DIR="$HOME/lumoz_miner"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    echo "작업 디렉토리로 이동: $WORK_DIR"

    # 사용자 입력 받기
    read -p "GPU 종류를 선택하세요 (1: NVIDIA, 2: AMD): " gpu_choice
    read -p "Lumoz 지갑 주소를 입력하세요: " wallet_address
    read -p "채굴자 이름을 입력하세요: " miner_name

    # GPU 선택에 따른 다운로드 및 설치
    if [ "$gpu_choice" == "1" ]; then
        echo "NVIDIA GPU 마이너를 다운로드합니다..."
        wget https://github.com/6block/zkwork_moz_prover/releases/download/v1.0.1/moz_prover-v1.0.1_cuda.tar.gz
        tar -zvxf moz_prover-v1.0.1_cuda.tar.gz
    elif [ "$gpu_choice" == "2" ]; then
        echo "AMD GPU 마이너를 다운로드합니다..."
        wget https://github.com/6block/zkwork_moz_prover/releases/download/v1.0.1/moz_prover-v1.0.1_ocl.tar.gz
        tar -zvxf moz_prover-v1.0.1_ocl.tar.gz
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
    ./run_prover.sh &

    # 로그 확인
    echo "3초 후 마이닝 로그를 표시합니다..."
    sleep 3
    tail -f prover.log 

    echo "해당사이트에서 대시보드를 확인하세요: https://zk.work/en/lumoz/"
    echo -e "${GREEN}스크립트작성자: https://t.me/kjkresearch${NC}"

elif [ "$option" == "2" ]; then
    echo "Lumoz 노드 업데이트를 선택했습니다."

    # 현재 버전 입력 받기
    echo -e "${GREEN}해당사이트에 방문하세요: https://github.com/6block/zkwork_moz_prover/tags${NC}"
    read -p "현재 버전을 입력하세요 (예: v1.0.1): " version

    # 작업 디렉토리 생성 및 이동
    WORK_DIR="$HOME/lumoz_miner"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    echo "작업 디렉토리로 이동: $WORK_DIR"

    # 입력된 버전을 환경 변수로 설정
    export VERSION=$version

    # 현재 버전 입력 받기
    read -p "현재 버전(v1.0.1)을 입력하세요: " version

    # 입력된 버전을 환경 변수로 설정
    export VERSION=$version

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
        cd "moz_prover" || exit

    elif [ "$gpu_choice" == "2" ]; then
        echo "zkwork AMD miner 다운로드 중..."
        wget "https://github.com/6block/zkwork_moz_prover/releases/download/$VERSION/moz_prover-$VERSION_ocl.tar.gz"
        
        # 다운로드한 파일 압축 해제
        echo "AMD 마이너 압축 해제 중..."
        tar -zvxf "moz_prover-$VERSION_ocl.tar.gz"
        cd "moz_prover" || exit

    else
        echo "잘못된 선택입니다. 스크립트를 종료합니다."
        exit 1
    fi

    # Lumoz 주소 및 사용자 지정 이름 업데이트
    read -p "Lumoz 지갑 주소를 입력하세요: " wallet_address
    read -p "채굴자 이름을 입력하세요: " miner_name

    # inner_prover.sh 파일 수정
    sed -i "s/WALLET_ADDRESS=.*/WALLET_ADDRESS=$wallet_address/" inner_prover.sh
    sed -i "s/WORKER_NAME=.*/WORKER_NAME=$miner_name/" inner_prover.sh

    # 실행 권한 부여 및 마이너 시작
    chmod +x run_prover.sh
    ./run_prover.sh &

    # 로그 확인
    echo "3초 후 마이닝 로그를 표시합니다..."
    sleep 3
    tail -f prover.log

    echo "해당 사이트에서 대시보드를 확인하세요: https://zk.work/en/lumoz/"
    echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"

elif [ "$option" == "3" ]; then
    echo "Lumoz 노드 삭제를 선택했습니다."

    cd moz_prover
    sudo pkill -f moz_prover
    ps aux | grep moz_prover
    pgrep -f run_prover.sh

    
    # 사용자에게 PID 입력 받기
    read -p "종료할 프로세스의 PID를 입력하세요: " pid_to_kill

    # 입력받은 PID로 프로세스 종료
    if [ -n "$pid_to_kill" ]; then
        sudo kill "$pid_to_kill"
        echo "프로세스 $pid_to_kill가 종료되었습니다."
    else
        echo "유효하지 않은 PID입니다."
    fi

else
    echo "잘못된 선택입니다."
    exit 1
fi

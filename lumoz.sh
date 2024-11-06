#!/bin/bash

# 현재 작업 디렉토리 표시
echo "현재 작업 디렉토리: $(pwd)"
echo "홈 디렉토리: $HOME"

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

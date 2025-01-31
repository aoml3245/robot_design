# 프로젝트 개요
본 프로젝트는 Docker 환경과 Docker Compose를 활용하여 ROS(ROS Noetic, ROS Humble) 환경을 GUI 기반으로 실행할 수 있도록 구성하였습니다.  
OpenManipulator X를 Gazebo 시뮬레이터에서 구동하는 방법은 하단에 안내된 링크와 설정 방법을 참고해주세요.

## 사전 준비 사항
### 1) Docker 설치
- 공식 문서: [Docker 설치 가이드](https://docs.docker.com/engine/install/)
- 운영체제별 설치 방법을 참고하여 Docker를 먼저 설치합니다.

### 2) Docker Compose 설치
- 최신 Docker 설치 환경에서는 `docker compose` 플러그인이 기본 제공되거나 별도로 설치가 가능합니다.
- 설치 여부를 확인한 후, 필요 시 버전에 맞는 설치 방법을 참고하세요.

### 3) GUI 환경 설정
- Docker 컨테이너 내부에서 GUI 프로그램을 사용하려면 **X11 포워딩, VNC, X 서버 설정** 등이 필요할 수 있습니다.
- 호스트 운영체제(Windows, Linux, macOS)별로 설정 방법이 다를 수 있으니 적절히 구성해 주세요.

## ROS 버전
본 프로젝트는 **ROS Noetic** 버전과 **ROS Humble** 버전을 모두 지원합니다.  
Dockerfile을 선택해 사용할 수 있습니다.

## 사용 방법 (예시)
### 1) 프로젝트 클론
```bash
git clone <저장소 주소>
cd <프로젝트 폴더>
```
### 2) Docker Compose 실행
```bash
docker compose up -f <원하는 compose 파일.yml>--build
```

### 3) 컴테이너 확인
```bash
docker compose ls
```
### 3) 컨테이너 진입
```bash
docker compose exec <서비스명> bash
```
### 4) GUI 프로그램 테스트

- 컨테이너 내부에서 `xclock` 등의 간단한 GUI 프로그램을 실행하여 **GUI 포워딩이 정상 동작하는지 확인**하세요.
- 필요시 다운로드 필요합니다.
---

## OpenManipulator X Gazebo 시뮬레이션

OpenManipulator X를 Gazebo에서 구동하는 자세한 방법은 아래 링크를 참고하세요.  
🔗 [OpenManipulator X Gazebo 실행 가이드](https://emanual.robotis.com/docs/en/platform/openmanipulator_x/ros_simulation/#launch-gazebo)

ROS Noetic 또는 ROS Humble 환경에서 `roslaunch`, `ros2 launch` 등을 활용해 Gazebo를 실행하고 매니퓰레이터 동작을 테스트할 수 있습니다.



---

## 주의 사항

- **Docker 컨테이너는 호스트 환경과 격리**되어 있으므로, GUI를 사용하려면 **호스트와 X11 디스플레이를 공유**하거나 **VNC를 설정**해야 합니다.
- `roslaunch`, `rviz`, `gazebo` 등 **GUI 기반 프로그램을 실행할 때 네트워크 설정과 X 서버 권한을 적절히 구성**하세요.

여러 창이 필요한 경우 여러 터미널을 열어 각각 
```  docker compose exec ```명령어 실행 필요합니다

---

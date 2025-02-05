################################################################################
# (A) 패키지로 나눠서 빌드하는 정석 구조 + RealSense 설치 + open_manipulator_motion 의존성
# ------------------------------------------------------------------------------
# 1. open_manipulator_6dof_application 레포지토리를 먼저 전체 다운받는다.
# 2. 그 안에 들어있는 open_manipulator_motion / open_manipulator_6dof_control_gui 폴더만
#    각각 src/ 최상위로 꺼내서, 독립된 catkin 패키지 형태를 만든다.
# 3. RealSense 설치( librealsense , realsense-ros )
# 4. open_manipulator_6dof_control_gui에서 open_manipulator_motion 의존성 자동 추가
# 5. C++11 활성화
# 6. ROS2 관련 의존성(ros2topic, ament_lint_common) 무시
################################################################################
FROM nvidia/opengl:base-ubuntu18.04

# 비대화식 설치 모드 (필요하다면 주석 해제)
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y sudo chrony ntpdate && useradd -m -s /bin/bash dockeruser && \
    echo "dockeruser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dockeruser

RUN sudo ntpdate -q ntp.ubuntu.com

################################################################################
# 1) RealSense 설정: apt key 등록 + 소스 추가
################################################################################
RUN sudo apt update && sudo apt upgrade -y && sudo apt install -y curl apt-transport-https software-properties-common
RUN sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
RUN sudo apt-get update && sudo apt-get upgrade -y

RUN sudo mkdir -p /etc/apt/keyrings
RUN curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null

RUN echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | \
    sudo tee /etc/apt/sources.list.d/librealsense.list
RUN sudo apt-get update

USER root
################################################################################
# 2) ROS 및 빌드에 필요한 패키지 설치
################################################################################
RUN apt update && apt upgrade -y && apt-get install -y \
    ros-kinetic-desktop-full          \
    ros-kinetic-rqt*                  \
    python-rosinstall                 \
    ros-kinetic-ros-controllers       \
    ros-kinetic-gazebo*               \
    ros-kinetic-moveit*               \
    ros-kinetic-industrial-core       \
    ros-kinetic-dynamixel-sdk         \
    ros-kinetic-dynamixel-workbench*  \
    ros-kinetic-robotis-manipulator   \
    ros-kinetic-ar-track-alvar        \
    ros-kinetic-ar-track-alvar-msgs   \
    ros-kinetic-image-proc            \
    ros-kinetic-realsense2-camera     \
    ros-kinetic-realsense2-description\
    librealsense2-dev                 \
    librealsense2-utils               \
    librealsense2-dkms                \
    librealsense2-dbg                 \
    ros-kinetic-rgbd-launch           \
    systemd-coredump                  \
    git                               \
    vim                               \
    cmake                             \
    build-essential                   \
    wget                              \
    libgl1-mesa-glx                   \
    libgl1-mesa-dri                   \
    mesa-utils                        \
    sed                               \
    findutils                         \
    && rm -rf /var/lib/apt/lists/*

################################################################################
# 3) rosdep 초기화
################################################################################
RUN rm -rf /etc/ros/rosdep/sources.list.d/20-default.list
RUN /bin/bash -c 'source /opt/ros/kinetic/setup.bash && rosdep init && rosdep update'

USER dockeruser
WORKDIR /home/dockeruser

################################################################################
# 6) catkin 워크스페이스 생성
################################################################################
RUN mkdir -p /home/dockeruser/colcon_ws/src && chmod 777 /home/dockeruser/colcon_ws/src

RUN cd /home/dockeruser/colcon_ws/src && \
    /bin/bash -c 'source /opt/ros/kinetic/setup.bash && catkin_init_workspace' && \
    cd /home/dockeruser/colcon_ws && \
    /bin/bash -c 'source /opt/ros/kinetic/setup.bash && catkin_make'

################################################################################
# 7) 필요한 리포지토리 clone
#    - open_manipulator_6dof_application에서 open_manipulator_motion / open_manipulator_6dof_control_gui 추출
#    - RealSense: ros1-legacy 브랜치 사용
################################################################################
RUN cd /home/dockeruser/colcon_ws/src && \
    git clone -b kinetic-devel https://github.com/ROBOTIS-GIT/DynamixelSDK.git && \
    git clone -b kinetic-devel https://github.com/ROBOTIS-GIT/open_manipulator.git && \
    git clone -b kinetic-devel https://github.com/ROBOTIS-GIT/dynamixel-workbench.git && \
    git clone -b kinetic-devel https://github.com/ROBOTIS-GIT/dynamixel-workbench-msgs.git && \
    git clone -b kinetic-devel https://github.com/ROBOTIS-GIT/open_manipulator_msgs.git && \
    git clone -b kinetic-devel https://github.com/ROBOTIS-GIT/robotis_manipulator.git && \
    git clone https://github.com/zang09/open_manipulator_friends.git && \
    git clone https://github.com/zang09/open_manipulator_perceptions.git && \
    git clone https://github.com/zang09/open_manipulator_6dof_simulations.git && \
    \
    # (7-1) open_manipulator_6dof_application clone
    git clone https://github.com/zang09/open_manipulator_6dof_application.git && \
    mv open_manipulator_6dof_application/open_manipulator_motion . && \
    mv open_manipulator_6dof_application/open_manipulator_6dof_control_gui . && \
    rm -rf open_manipulator_6dof_application && \
    \
    # (7-2) realsense ROS1 버전 clone
    git clone -b ros1-legacy https://github.com/intel-ros/realsense.git 

################################################################################
# 8) open_manipulator_6dof_control_gui에서 open_manipulator_motion 의존성 추가
#    package.xml / CMakeLists.txt 자동 수정, 중복 삽입 방지
################################################################################
RUN FILE_PKGXML="/home/dockeruser/colcon_ws/src/open_manipulator_6dof_control_gui/package.xml" \
    && FILE_CMAKELISTS="/home/dockeruser/colcon_ws/src/open_manipulator_6dof_control_gui/CMakeLists.txt" \
    \
    ############################################################################
    # [A] package.xml에 <depend>open_manipulator_motion</depend> "최초 한 번만" 삽입
    ############################################################################
    && if ! grep -q '<depend>open_manipulator_motion</depend>' "$FILE_PKGXML"; then \
         sed -i '0,/<\/depend>/ s/<\/depend>/<\/depend>\n  <depend>open_manipulator_motion<\/depend>/' "$FILE_PKGXML"; \
       fi \
    \
    ############################################################################
    # [B] CMakeLists.txt: find_package(catkin REQUIRED COMPONENTS ...)에
    #     open_manipulator_motion 없는 경우만 추가
    ############################################################################
    && if ! grep -q 'find_package(catkin REQUIRED COMPONENTS.*open_manipulator_motion' "$FILE_CMAKELISTS"; then \
         sed -i '/find_package(catkin REQUIRED COMPONENTS/ a \  open_manipulator_motion' "$FILE_CMAKELISTS"; \
       fi \
    \
    ############################################################################
    # [C] CMakeLists.txt: catkin_package(CATKIN_DEPENDS ...)에
    #     open_manipulator_motion 없는 경우만 추가
    ############################################################################
    && if ! grep -q 'CATKIN_DEPENDS.*open_manipulator_motion' "$FILE_CMAKELISTS"; then \
         sed -i '/catkin_package(/,/)/{ /CATKIN_DEPENDS/ s/$/ open_manipulator_motion/ }' "$FILE_CMAKELISTS"; \
       fi


COPY patches/open_manipulator_6dof.gazebo.xacro /home/dockeruser/colcon_ws/src/open_manipulator_friends/open_manipulator_6dof_description/urdf/open_manipulator_6dof.gazebo.xacro


################################################################################
# 9) C++11 활성화: CMakeLists에 add_compile_options(-std=c++11)
#    (GUI 패키지 외에 다른 곳도 필요하다면 별도 처리)
################################################################################
RUN /bin/bash -c 'echo "add_compile_options(-std=c++11)" >> /home/dockeruser/colcon_ws/src/open_manipulator_6dof_control_gui/CMakeLists.txt'

################################################################################
# 10) 의존성 설치 후 catkin_make
#     - skip-keys: ros2topic, ament_lint_common 등 ROS2 의존성 무시
################################################################################
RUN /bin/bash -c 'source /opt/ros/kinetic/setup.bash && \
    cd /home/dockeruser/colcon_ws && \
    rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y --skip-keys="ros2topic ament_lint_common" && \
    catkin_make -j1 -DCMAKE_CXX_STANDARD=11'

ENV CXXFLAGS="-std=c++11"

USER dockeruser

################################################################################
# 11) 환경 설정
################################################################################
RUN echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
RUN echo "source /home/dockeruser/colcon_ws/devel/setup.bash" >> ~/.bashrc

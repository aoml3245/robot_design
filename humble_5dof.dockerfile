
FROM osrf/ros:humble-desktop-full

# 비대화식 설치 모드
ENV DEBIAN_FRONTEND=noninteractive


# install bootstrap tools
RUN apt-get update && sudo apt install -y \
  ros-humble-dynamixel-sdk \
  ros-humble-ros2-control \
  ros-humble-moveit* \
  ros-humble-gazebo-ros2-control \
  ros-humble-ros2-controllers \
  ros-humble-controller-manager \
  ros-humble-position-controllers \
  ros-humble-joint-state-broadcaster \
  ros-humble-joint-trajectory-controller \
  ros-humble-gripper-controllers \
  ros-humble-hardware-interface \
  ros-humble-xacro \ 
  git \
  vim \
  build-essential \
  wget \
  sudo \
  libgl1-mesa-glx \
  libgl1-mesa-dri \
  mesa-utils \ 
  && rm -rf /var/lib/apt/lists/*




# 비루트 사용자 추가 및 sudo 권한 부여
RUN useradd -m dockeruser && echo "dockeruser:dockeruser" | chpasswd && adduser dockeruser sudo


# 비루트 사용자로 전환
USER dockeruser
WORKDIR /home/dockeruser

RUN mkdir -p /home/dockeruser/colcon_ws/src && chmod 777 /home/dockeruser/colcon_ws/src

RUN mkdir -p /home/dockeruser/colcon_ws/src && cd /home/dockeruser/colcon_ws/src && \
git clone -b humble https://github.com/ROBOTIS-GIT/open_manipulator.git && \
git clone -b humble https://github.com/ROBOTIS-GIT/dynamixel_hardware_interface.git && \
git clone -b humble https://github.com/ROBOTIS-GIT/dynamixel_interfaces.git && \ 
    /bin/bash -c 'source /opt/ros/humble/setup.bash && cd /home/dockeruser/colcon_ws && colcon build --symlink-install'




# 환경 설정
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "source /usr/share/gazebo/setup.sh" >> ~/.bashrc
RUN echo "source /home/dockeruser/colcon_ws/install/setup.bash" >> ~/.bashrc
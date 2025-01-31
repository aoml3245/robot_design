FROM osrf/ros:noetic-desktop-full


# 비대화식 설치 모드
ENV DEBIAN_FRONTEND=noninteractive


RUN apt update && apt-get install -y ros-noetic-ros-controllers ros-noetic-gazebo* ros-noetic-moveit* ros-noetic-industrial-core && \
    apt install -y ros-noetic-dynamixel-sdk ros-noetic-dynamixel-workbench* && \
    apt install -y ros-noetic-robotis-manipulator git \
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



# 환경 설정
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
RUN echo "source /home/dockeruser/colcon_ws/devel/setup.bash" >> ~/.bashrc

RUN mkdir -p /home/dockeruser/colcon_ws/src && cd /home/dockeruser/colcon_ws/src && \
    git clone -b noetic https://github.com/ROBOTIS-GIT/open_manipulator.git && \
    git clone -b noetic https://github.com/ROBOTIS-GIT/open_manipulator_msgs.git && \
    git clone -b noetic https://github.com/ROBOTIS-GIT/open_manipulator_simulations.git && \
    git clone -b noetic https://github.com/ROBOTIS-GIT/open_manipulator_dependencies.git && \
    /bin/bash -c 'source /opt/ros/noetic/setup.bash && cd /home/dockeruser/colcon_ws && catkin_make'



# 비루트 사용자로 실행
USER dockeruser
WORKDIR /home/dockeruser


# ROS 환경 설정
SHELL ["/bin/bash", "-c"]
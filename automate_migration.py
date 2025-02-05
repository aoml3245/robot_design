#!/usr/bin/env python3
import os
import re
import sys

def process_text(content):
    original = content

    # 1. CMakeLists.txt: cmake_minimum_required(~~) 를 cmake_minimum_required(VERSION 3.10.2) 로 변경
    content = re.sub(
        r'^\s*cmake_minimum_required\s*\(.*\)',
        'cmake_minimum_required(VERSION 3.10.2)',
        content,
        flags=re.MULTILINE
    )

    # 2. setup.py: from distutils.core import setup 를 from setuptools import setup 로 변경
    content = re.sub(
        r'^\s*#?\s*from\s+distutils\.core\s+import\s+setup',
        'from setuptools import setup',
        content,
        flags=re.MULTILINE
    )

    # 4. 파이썬 파일 내: "import rviz" (주석 여부 상관없이) 를 "from rviz import bindings as rviz" 로 변경
    content = re.sub(
        r'^\s*#?\s*import\s+rviz\s*$',
        'from rviz import bindings as rviz',
        content,
        flags=re.MULTILINE
    )

    # 5. xacro.py 를 xacro 로 변경 (문자열 내 명령어나 스크립트 호출 등)
    content = re.sub(r'\bxacro\.py\b', 'xacro', content)

    return content

def process_file(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    new_content = process_text(content)
    if new_content != content:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Updated {file_path}")

def process_package_xml(file_path):
    """
    package.xml 파일이 package format 3인 경우, 조건부 buildtool_depend를 삽입합니다.
    """
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    original = content

    if '<package format="3">' in content:
        # 조건부 설정이 없을 경우에만 추가
        if 'python-setuptools' not in content:
            insertion = (
                "\n  <buildtool_depend condition=\"$ROS_PYTHON_VERSION == 2\">python-setuptools</buildtool_depend>\n"
                "  <buildtool_depend condition=\"$ROS_PYTHON_VERSION == 3\">python3-setuptools</buildtool_depend>\n"
            )
            # <package format="3"> 태그 바로 뒤에 삽입 (첫 번째 등장 위치)
            content = re.sub(
                r'(<package\s+format="3"\s*>)',
                r'\1' + insertion,
                content,
                count=1
            )

    if content != original:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Updated {file_path}")

def main():
    if len(sys.argv) < 2:
        print("Usage: {} <root_directory>".format(sys.argv[0]))
        sys.exit(1)
    root_dir = sys.argv[1]
    for subdir, dirs, files in os.walk(root_dir):
        for file in files:
            file_path = os.path.join(subdir, file)
            # CMake 파일: 보통 이름이 CMakeLists.txt 인 경우
            if file == "CMakeLists.txt":
                process_file(file_path)
            # setup.py 파일 처리
            elif file == "setup.py":
                process_file(file_path)
            # package.xml 파일 처리
            elif file == "package.xml":
                process_package_xml(file_path)
            # 파이썬 파일 (.py 확장자): rviz import, xacro.py 변경 등
            elif file.endswith(".py"):
                process_file(file_path)
            # 그 외 다른 파일도 필요에 따라 추가할 수 있습니다.
            # 예를 들어, 스크립트 파일 등.
            
if __name__ == "__main__":
    main()

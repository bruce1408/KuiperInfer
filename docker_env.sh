#!/bin/bash

# 判断是否在 Docker 环境中
if [ -f /.dockerenv ]; then
    echo "错误: 当前已经在 Docker 容器内，不能创建新容器。"
    exit 1
fi

usage() {
    echo "Usage: $0 [container_name]"
    echo "如果不提供 container_name，将会提示输入。"
    exit 1
}

# 获取容器名称
if [ $# -ge 1 ]; then
    CONTAINER_NAME="$1"
else
    read -p "请输入 Docker 容器名称: " CONTAINER_NAME
    if [ -z "$CONTAINER_NAME" ]; then
        echo "错误: 未提供容器名称。"
        usage
    fi
fi


# 检查容器是否存在
if [[ $(docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format "{{.Names}}") == "$CONTAINER_NAME" ]]; then
    # 容器存在
    # 检查容器是否在运行
    if [[ $(docker ps --filter "name=^/${CONTAINER_NAME}$" --filter "status=running" -q) ]]; then
        echo "容器 '$CONTAINER_NAME' 已经启动，直接进入容器并安装zsh以激活环境..."
    else
        echo "容器 '$CONTAINER_NAME' 存在但未启动，启动容器..."
        docker start $CONTAINER_NAME
    fi
    # 进入容器并激活 Conda 环境
    # docker exec -it $CONTAINER_NAME 
    docker exec -it $CONTAINER_NAME /bin/zsh

    # 这里不加-c命令切换了，而是直接在docker的zsh中进行配置
else
    echo "容器 '$CONTAINER_NAME' 不存在，创建并启动容器并进入..."
    
    # 这里 -u 还是改回和主机一样的id，这样的话，就可以对文件进行git 修改，但是缺乏root权限，所以需要安装依赖库的话就
    # 需要重新用root权限打开文件     docker exec -u root -it $CONTAINER_NAME /bin/bash
    docker run --name ${CONTAINER_NAME} -it -u $(id -u):$(id -g) \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -v /etc/localtime:/etc/localtime:ro \
        -v ${HOME}:${HOME} \
        -v /opt/qcom:/opt/qcom \
        -v /home/bruce_ultra/Pictures:/home/bruce_ultra/miniconda3 \
        -v ${WORKSPACE}:${WORKSPACE} \
        --gpus all \
        --restart always \
        --shm-size=16G \
        --entrypoint /bin/bash \
        -w ${WORKSPACE} \
        --hostname infer_docker registry.cn-hangzhou.aliyuncs.com/hellofss/kuiperinfer:latest 
    
    echo -e "\
        \n\
        sudo docker exec -it -u root infer_env /bin/bash\n\
        \n\
        容器已经创建完成，请把主机 zsh 和 p10.zsh 文件拷贝到 docker /root 目录下;\n\
        并在 zsh 脚本添加 conda 环境路径，然后重启容器"
fi
#!/bin/zsh

# 定义图片文件后缀（需要转换为 WebP 格式的文件后缀）
image_extensions=(".png" ".jpg" ".jpeg" ".PNG")

# 网站目标目录
WEB_DIR="/www/webRoot/imagehost.mintimate.cn"
# 工作空间临时检录目录
WORK_SPACE_DIR="/home/git/mySpace/imagehost.mintimate.cn"
# 定义需要跳过的文件前缀
skip_prefixes=("emoticon" "emoji")
# Python Fle Path
PYTHON_MAIN="/home/git/PythonTool"
# 定义输出目录
OUTPUT_DIR="/home/git/GitHookLogs"

# 确保输出目录存在
mkdir -p $OUTPUT_DIR
# 检录工作空间到目标目录
git --work-tree=$WORK_SPACE_DIR --git-dir=/home/git/mySource/imageHost.git checkout -f

# 定义一个函数,用于检查文件路径是否以需要跳过的前缀开头
check_skip_prefix() {
    local filepath=$1
    for prefix in "${skip_prefixes[@]}"; do
        if [[ "$filepath" == "$prefix"* ]]; then
            return 0  # 返回 0 表示匹配到了需要跳过的前缀
        fi
    done
    return 1  # 返回 1 表示没有匹配到需要跳过的前缀
}

# 定义一个函数,用于检查文件是否为图片
is_image_file() {
    local filepath=$1
    for ext in "${image_extensions[@]}"; do
        if [[ "$filepath" == *"$ext" ]]; then
            return 0  # 返回 0 表示是图片文件
        fi
    done
    return 1  # 返回 1 表示不是图片文件
}

# 获取当前日期和时间，格式为 YYYYMMDD-HHMMSS
NOW=$(date +"%Y%m%d-%H%M%S")
# 定义输出文件，包含时间戳
OUTPUT_FILE="${OUTPUT_DIR}/${NOW}_Change.log"
OUTPUT_FILE_PY="${OUTPUT_DIR}/PythonProcess.log"

# 读取标准输入（oldrev newrev refname）
while read oldrev newrev refname
do
    # 获取变更的文件列表
    echo "Changes in $refname:" >> $OUTPUT_FILE
    # 使用 git diff-tree 来查看变更
    git diff-tree --no-commit-id --name-status -r $oldrev $newrev | while read status_flag file1 file2
    do
        case $status_flag in
            M|A)
                echo "Modify: $file1" >> $OUTPUT_FILE
                ;;
            D)
                echo "Delete: $file1" >> $OUTPUT_FILE
                ;;
            R)
                echo "MV $file1 To $file2" >> $OUTPUT_FILE
                ;;
        esac
    done
done

# 使用 Python WebP解析脚本
process_file() {
    local filepath=$1
    local action=$2
    local dst=

    # 判断是否存在上级目标目录
    mkdir -p "$(dirname "$WEB_DIR/$filepath")"

    # 检查文件路径是否以需要跳过的前缀开头
    check_skip_prefix "$filepath"
    if [ $? -eq 0 ]; then
        cp "$WORK_SPACE_DIR/$filepath" "$WEB_DIR/$filepath"
        return
    fi

    # 检查文件是否为图片
    is_image_file "$filepath"
    if [ $? -eq 0 ]; then
        # 执行 python 脚本
        nohup $PYTHON_MAIN/bin/python $PYTHON_MAIN/image2WebpForGit.py -w -s "$WORK_SPACE_DIR/$filepath" -t "$WEB_DIR/${filepath%.*}.webp" >> $OUTPUT_FILE_PY 2>&1 &
    else
        # 如果不是图片,执行 cp 命令
        cp "$WORK_SPACE_DIR/$filepath" "$WEB_DIR/$filepath"
    fi
}

# 使用 case 语句处理不同的操作
while read line; do
    case $line in
        Modify*)
            filepath=$(echo $line | awk '{print $2}')
            process_file "$filepath" modify
            ;;
        Delete*)
            filepath=$(echo $line | awk '{print $2}')
            rm -f "$WEB_DIR/$filepath"
            rm -f "$WEB_DIR/${filepath%.*}.webp"
            ;;
        MV*)
            src=$(echo $line | awk '{print $2}')
            dst=$(echo $line | awk '{print $3}')
            rm -f "$WEB_DIR/$src"
            rm -f "$WEB_DIR/${src%.*}.webp"
            process_file "$dst" move
            ;;
    esac
done < $OUTPUT_FILE
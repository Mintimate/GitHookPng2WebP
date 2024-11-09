## Guide

文件结构:
- image2WebpForGit.py: 用于将图片转换为webp格式的脚本，并且支持将图片添加水印。
- post-receive: 用于替换 Git Hook 内的 post-receive 脚本，用于差异化 commit 内容，调用 image2WebpForGit.py 脚本。

## image2WebpForGit.py

需要安装的库：
```bash
pip install pillow
```

使用方法：
1. 将 image2WebpForGit.py 放置在项目根目录下。
2. 终端执行 `python3 -s 「原始文件地址」' -t 「目标文件地址」 image2WebpForGit.py` 即可将项目中的图片转换为 webp 格式。

可选参数：
- -r: 替换原始文件，传入参数，会自动删除原始文件。
- -w: 添加水印，需要传入水印图片地址。

## post-receive
需要将 post-receive 文件放置在项目的 hooks/ 目录下，替换原有的 post-receive 文件。并且确保 post-receive 文件有执行权限。

需要修改文件内部的变量执行为自己的服务器:

```yaml
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
```
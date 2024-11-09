import os
from PIL import Image

# 调用方法进行转码
# 获取脚本所在的目录
script_dir = os.path.dirname(os.path.abspath(__file__))
# 构建水印图片的路径
watermark_image_path = os.path.join(script_dir, 'water', 'WaterNew(Alpha85).png')
# 要转换的图像的文件类型
valid_extensions = ['.png', '.jpeg', '.jpg', '.PNG', '.JPEG', '.JPG', '.webp']


def convert_to_webp(input_path, target_path, watermark_mode):
    """
    将给定文件夹中的所有PNG和JPEG/JPG图像转换为WEBP格式，并将其保存到指定的输出文件夹中。

    参数:
    - input_path (str): 包含要转换的图像的文件夹的路径。
    - output_path (str): 保存转换图像的输出文件夹的路径。
    - copy_others (bool, 可选): 如果为True，则将输入文件夹中的其他非PNG和非JPEG/JPG文件复制到输出文件夹中。默认为False。

    返回:
    None
    """

    wm_img = Image.open(watermark_image_path).convert("RGBA")

    total_saved_percentage = 0  # 总大小缩减百分比

    # 检查文件是否为 PNG 或 JPEG/JPG 图像
    if any(input_path.endswith(ext) for ext in valid_extensions):
        # 计算大小缩减百分比
        with Image.open(input_path) as image:
            original_size = os.path.getsize(input_path)
            # 计算水印的放置位置以底部居中
            bg_width, bg_height = image.size
            wm_width, wm_height = wm_img.size
            position = ((bg_width - wm_width) // 2, bg_height - wm_height - 30)  # 底部居中坐标

            # 创建一个新的透明图层用于合并，以防背景颜色受影响
            image_target = Image.new('RGBA', image.size, (255, 255, 255, 0))  # 完全透明图层
            image_target.paste(image, (0, 0))  # 将背景图片粘贴到透明图层上

            # 粘贴水印到新图层的底部中心位置，透明度已由水印图片自身定义，无需额外调整
            if bg_width > 512 * 1.5 and watermark_mode:
                image_target.paste(wm_img, position, mask=wm_img.split()[3])  # 使用alpha通道作为遮罩确保透明度正确
            image_target.save(target_path, 'webp', quality=80, optimize=True, lossless=False, method=6,
                              save_all=True,
                              progressive=True)
            converted_size = os.path.getsize(target_path)
            saved_percentage = (original_size - converted_size) * 100 / original_size
            total_saved_percentage += saved_percentage

        print(f"将 {input_path} 转换为 {target_path} ({saved_percentage:.2f}% 节省)")


def __get_parser():
    """
    获取参数
    :return:
    """
    import argparse
    parser = argparse.ArgumentParser(description='git image2webp')
    parser.add_argument('-s', '--source', type=str, required=True, help='path source of source image')
    parser.add_argument('-t', '--target', type=str, required=False, default=None, help='path target of source image')
    parser.add_argument('-r', '--replace', action='store_true', required=False, default=False,
                        help='replace source image. if -t is not set, the source image will be replaced')
    parser.add_argument('-w', '--watermark', action='store_true', required=False, default=False, help='add watermark')
    return parser.parse_args()


if __name__ == '__main__':
    args = __get_parser()
    if args.target is not None and not args.target.endswith('.webp'):
        print('Target image must be webp format.')
        exit(1)
    elif args.target is None:
        # 如果目标文件没有设置，则默认为源文件替换为 webp 格式
        args.target = os.path.splitext(args.source)[0] + '.webp'
        print(f'Target image: {args.target}')
    convert_to_webp(args.source, args.target, args.watermark)
    # 替换模式，并且源文件不是 webp 格式
    if args.replace and not args.source.endswith('.webp'):
        os.remove(args.source)
        print(f'Remove source image: {args.source}')

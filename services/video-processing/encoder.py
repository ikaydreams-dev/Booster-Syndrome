import subprocess
import os

class VideoEncoder:
    def __init__(self):
        self.ffmpeg_path = 'ffmpeg'

    def compress_video(self, input_file, output_file, quality='medium'):
        """Compress video file"""
        quality_settings = {
            'low': '28',
            'medium': '23',
            'high': '18'
        }

        crf = quality_settings.get(quality, '23')

        cmd = [
            self.ffmpeg_path,
            '-i', input_file,
            '-c:v', 'libx264',
            '-crf', crf,
            '-c:a', 'aac',
            '-b:a', '128k',
            output_file
        ]

        subprocess.run(cmd, check=True)
        return output_file

    def create_thumbnail(self, video_file, output_file, timestamp='00:00:01'):
        """Extract thumbnail from video"""
        cmd = [
            self.ffmpeg_path,
            '-i', video_file,
            '-ss', timestamp,
            '-vframes', '1',
            output_file
        ]

        subprocess.run(cmd, check=True)
        return output_file

    def convert_format(self, input_file, output_file, format='mp4'):
        """Convert video to different format"""
        cmd = [
            self.ffmpeg_path,
            '-i', input_file,
            output_file
        ]

        subprocess.run(cmd, check=True)
        return output_file

    def get_video_info(self, video_file):
        """Get video metadata"""
        cmd = [
            self.ffmpeg_path,
            '-i', video_file,
            '-hide_banner'
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stderr

import subprocess
import os
from typing import Optional, List

class VideoTranscoder:
    def __init__(self, ffmpeg_path: str = 'ffmpeg'):
        self.ffmpeg_path = ffmpeg_path

    def transcode(
        self,
        input_file: str,
        output_file: str,
        video_codec: str = 'libx264',
        audio_codec: str = 'aac',
        resolution: Optional[str] = None,
        bitrate: Optional[str] = None,
        preset: str = 'medium'
    ) -> bool:
        """Transcode video to different format/quality"""
        cmd = [
            self.ffmpeg_path,
            '-i', input_file,
            '-c:v', video_codec,
            '-c:a', audio_codec,
            '-preset', preset,
        ]

        if resolution:
            cmd.extend(['-s', resolution])

        if bitrate:
            cmd.extend(['-b:v', bitrate])

        cmd.extend(['-y', output_file])

        try:
            subprocess.run(cmd, check=True, capture_output=True)
            return True
        except subprocess.CalledProcessError as e:
            print(f"Transcoding failed: {e.stderr.decode()}")
            return False

    def create_hls_variants(self, input_file: str, output_dir: str) -> bool:
        """Create HLS streaming variants"""
        os.makedirs(output_dir, exist_ok=True)

        variants = [
            {'resolution': '1920x1080', 'bitrate': '5000k', 'name': '1080p'},
            {'resolution': '1280x720', 'bitrate': '2800k', 'name': '720p'},
            {'resolution': '854x480', 'bitrate': '1400k', 'name': '480p'},
            {'resolution': '640x360', 'bitrate': '800k', 'name': '360p'},
        ]

        for variant in variants:
            output_file = os.path.join(output_dir, f"{variant['name']}.m3u8")

            cmd = [
                self.ffmpeg_path,
                '-i', input_file,
                '-c:v', 'libx264',
                '-c:a', 'aac',
                '-s', variant['resolution'],
                '-b:v', variant['bitrate'],
                '-hls_time', '4',
                '-hls_playlist_type', 'vod',
                '-hls_segment_filename', os.path.join(output_dir, f"{variant['name']}_%03d.ts"),
                '-y', output_file
            ]

            try:
                subprocess.run(cmd, check=True, capture_output=True)
            except subprocess.CalledProcessError as e:
                print(f"HLS variant creation failed: {e.stderr.decode()}")
                return False

        return self.create_master_playlist(output_dir, variants)

    def create_master_playlist(self, output_dir: str, variants: List[dict]) -> bool:
        """Create master HLS playlist"""
        master_path = os.path.join(output_dir, 'master.m3u8')

        with open(master_path, 'w') as f:
            f.write('#EXTM3U\n')
            f.write('#EXT-X-VERSION:3\n')

            for variant in variants:
                bandwidth = int(variant['bitrate'].replace('k', '')) * 1000
                resolution = variant['resolution']

                f.write(f'#EXT-X-STREAM-INF:BANDWIDTH={bandwidth},RESOLUTION={resolution}\n')
                f.write(f"{variant['name']}.m3u8\n")

        return True

    def extract_thumbnail(self, input_file: str, output_file: str, timestamp: str = '00:00:01') -> bool:
        """Extract thumbnail from video"""
        cmd = [
            self.ffmpeg_path,
            '-i', input_file,
            '-ss', timestamp,
            '-vframes', '1',
            '-y', output_file
        ]

        try:
            subprocess.run(cmd, check=True, capture_output=True)
            return True
        except subprocess.CalledProcessError:
            return False

    def get_video_info(self, input_file: str) -> dict:
        """Get video metadata"""
        cmd = [
            'ffprobe',
            '-v', 'quiet',
            '-print_format', 'json',
            '-show_format',
            '-show_streams',
            input_file
        ]

        try:
            result = subprocess.run(cmd, check=True, capture_output=True)
            import json
            return json.loads(result.stdout.decode())
        except subprocess.CalledProcessError:
            return {}

    def convert_to_mp4(self, input_file: str, output_file: str) -> bool:
        """Convert video to MP4 format"""
        return self.transcode(
            input_file,
            output_file,
            video_codec='libx264',
            audio_codec='aac',
            preset='fast'
        )

    def compress_video(self, input_file: str, output_file: str, crf: int = 28) -> bool:
        """Compress video using CRF"""
        cmd = [
            self.ffmpeg_path,
            '-i', input_file,
            '-c:v', 'libx264',
            '-crf', str(crf),
            '-c:a', 'aac',
            '-y', output_file
        ]

        try:
            subprocess.run(cmd, check=True, capture_output=True)
            return True
        except subprocess.CalledProcessError:
            return False

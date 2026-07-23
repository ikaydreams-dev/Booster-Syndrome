package backup

import (
	"archive/tar"
	"compress/gzip"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

type BackupService struct {
	backupDir string
}

func NewBackupService(backupDir string) *BackupService {
	return &BackupService{
		backupDir: backupDir,
	}
}

func (bs *BackupService) CreateBackup(sourceDir string, backupName string) (string, error) {
	timestamp := time.Now().Format("20060102_150405")
	backupFileName := fmt.Sprintf("%s_%s.tar.gz", backupName, timestamp)
	backupPath := filepath.Join(bs.backupDir, backupFileName)

	if err := os.MkdirAll(bs.backupDir, 0755); err != nil {
		return "", err
	}

	file, err := os.Create(backupPath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	gw := gzip.NewWriter(file)
	defer gw.Close()

	tw := tar.NewWriter(gw)
	defer tw.Close()

	err = filepath.Walk(sourceDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		header, err := tar.FileInfoHeader(info, info.Name())
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(sourceDir, path)
		if err != nil {
			return err
		}
		header.Name = relPath

		if err := tw.WriteHeader(header); err != nil {
			return err
		}

		if !info.IsDir() {
			file, err := os.Open(path)
			if err != nil {
				return err
			}
			defer file.Close()

			_, err = io.Copy(tw, file)
			return err
		}

		return nil
	})

	if err != nil {
		return "", err
	}

	return backupPath, nil
}

func (bs *BackupService) RestoreBackup(backupPath string, destDir string) error {
	file, err := os.Open(backupPath)
	if err != nil {
		return err
	}
	defer file.Close()

	gr, err := gzip.NewReader(file)
	if err != nil {
		return err
	}
	defer gr.Close()

	tr := tar.NewReader(gr)

	for {
		header, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}

		target := filepath.Join(destDir, header.Name)

		switch header.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(target, 0755); err != nil {
				return err
			}
		case tar.TypeReg:
			dir := filepath.Dir(target)
			if err := os.MkdirAll(dir, 0755); err != nil {
				return err
			}

			outFile, err := os.Create(target)
			if err != nil {
				return err
			}
			defer outFile.Close()

			if _, err := io.Copy(outFile, tr); err != nil {
				return err
			}
		}
	}

	return nil
}

func (bs *BackupService) ListBackups() ([]string, error) {
	files, err := os.ReadDir(bs.backupDir)
	if err != nil {
		return nil, err
	}

	backups := make([]string, 0)
	for _, file := range files {
		if !file.IsDir() && filepath.Ext(file.Name()) == ".gz" {
			backups = append(backups, file.Name())
		}
	}

	return backups, nil
}

func (bs *BackupService) DeleteOldBackups(daysToKeep int) error {
	files, err := os.ReadDir(bs.backupDir)
	if err != nil {
		return err
	}

	cutoffTime := time.Now().AddDate(0, 0, -daysToKeep)

	for _, file := range files {
		info, err := file.Info()
		if err != nil {
			continue
		}

		if info.ModTime().Before(cutoffTime) {
			filePath := filepath.Join(bs.backupDir, file.Name())
			if err := os.Remove(filePath); err != nil {
				return err
			}
		}
	}

	return nil
}

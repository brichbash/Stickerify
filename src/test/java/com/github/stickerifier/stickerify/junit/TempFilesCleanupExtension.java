package com.github.stickerifier.stickerify.junit;

import static org.junit.jupiter.api.Assumptions.abort;

import org.junit.jupiter.api.extension.AfterAllCallback;
import org.junit.jupiter.api.extension.ExtensionContext;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Custom JUnit extension used to clear temp files
 * generated by unit tests during their execution.
 */
public class TempFilesCleanupExtension implements AfterAllCallback {

	@Override
	public void afterAll(ExtensionContext context) throws IOException {
		deleteTempFiles();
	}

	private static void deleteTempFiles() throws IOException {
		try (var files = Files.list(Path.of(System.getProperty("java.io.tmpdir")))) {
			files.filter(Files::isRegularFile)
					.filter(TempFilesCleanupExtension::stickerifyFiles)
					.forEach(TempFilesCleanupExtension::deleteFile);
		}
	}

	private static boolean stickerifyFiles(Path path) {
		var fileName = path.getFileName().toString();

		return fileName.startsWith("Stickerify-") || fileName.startsWith("OriginalFile-");
	}

	private static void deleteFile(Path path) {
		try {
			Files.delete(path);
		} catch (IOException e) {
			abort("The file could not be deleted from the system.");
		}
	}
}

package com.github.stickerifier.stickerify.process;

import com.github.stickerifier.stickerify.telegram.exception.TelegramApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import ws.schild.jave.process.ProcessLocator;

/**
 * Custom locator class to be used by Jave to find the path where Ffmpeg is installed at in the system.
 *
 * @see ProcessLocator
 */
public class PathLocator implements ProcessLocator {

	private static final Logger LOGGER = LoggerFactory.getLogger(PathLocator.class);

	private static final boolean IS_WINDOWS = System.getProperty("os.name").contains("Windows");
	private static final String[] FIND_FFMPEG = { IS_WINDOWS ? "where" : "which", "ffmpeg" };

	public static final PathLocator INSTANCE = new PathLocator(System.getenv("FFMPEG_LOCATION"));

	private String ffmpegLocation;

	private PathLocator(String ffmpegLocation) {
		if (ffmpegLocation == null || ffmpegLocation.isBlank()) {
			try {
				ffmpegLocation = ProcessHelper.getCommandOutput(FIND_FFMPEG).trim();
			} catch (TelegramApiException e) {
				LOGGER.atError().setCause(e).log("Unable to detect Ffmpeg's installation path");
				return;
			}
		}
		this.ffmpegLocation = ffmpegLocation;
		LOGGER.atInfo().log("Ffmpeg is installed at {}", ffmpegLocation);
	}

	@Override
	public String getExecutablePath() {
		return ffmpegLocation;
	}
}

package com.github.stickerifier.stickerify.process;

import ws.schild.jave.process.ProcessLocator;

/**
 * Custom locator class to be used by Jave to find the path where FFmpeg is installed for native compilation.
 *
 * @see ProcessLocator
 */
public class NativeLocator implements ProcessLocator {
	@Override
	public String getExecutablePath() {
		return "/ffmpeg";
	}
}

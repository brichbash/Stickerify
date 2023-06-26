package com.github.stickerifier.stickerify.runner;

import com.github.stickerifier.stickerify.bot.Stickerify;
import com.github.stickerifier.stickerify.process.NativeLocator;

public class Native {
	public static void main(String[] args) {
		new Stickerify(new NativeLocator());
	}
}

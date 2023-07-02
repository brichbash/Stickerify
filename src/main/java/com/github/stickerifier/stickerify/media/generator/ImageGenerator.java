package com.github.stickerifier.stickerify.media.generator;

import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.util.Objects;

public class ImageGenerator {

	private static final Logger LOGGER = LoggerFactory.getLogger(ImageGenerator.class);

	private static final String GENERATE_IMAGE_ENDPOINT = "https://api.replicate.com/v1/predictions";
	private static final String REPLICATE_API_TOKEN = System.getenv("REPLICATE_API_TOKEN");
	private static final MediaType JSON_CONTENT_TYPE = MediaType.get("application/json");
	private static final Gson GSON = new Gson();

	private final OkHttpClient client = new OkHttpClient();

	public File generateImage(final String prompt) {
		var body = buildRequestBody(prompt);

		var request = new Request.Builder().url(GENERATE_IMAGE_ENDPOINT)
				.addHeader("Authorization", REPLICATE_API_TOKEN)
				.post(body)
				.build();

		try (var response = client.newCall(request).execute()) {
			var apiResponse = Objects.requireNonNull(response.body()).string();
			LOGGER.atDebug().log("Received answer from API call:\n{}", apiResponse);

			var generateImageResponse = GSON.fromJson(apiResponse, ReplicateResponse.class);
			var getImageEndpoint = generateImageResponse.link().getImageEndpoint();

			var getImageRequest = new Request.Builder().url(getImageEndpoint)
					.addHeader("Authorization", REPLICATE_API_TOKEN)
					.build();

			// Image generation isn't fast: don't spam the endpoint but retrieve the image after enough time passed
			// TODO add proper waiting time handling -> check if the image is ready, otherwise retry in a few seconds
			Thread.sleep(5_000L);

			try (var getImageResponse = client.newCall(getImageRequest).execute()) {
				var getImageApiResponse = Objects.requireNonNull(getImageResponse.body()).string();
				LOGGER.atDebug().log("Received answer from API call:\n{}", getImageApiResponse);

				var newGetImageResponse = GSON.fromJson(getImageApiResponse, ReplicateResponse.class);
				var fileEndpoint = newGetImageResponse.fileEndpoints()[0];

				// TODO download file
				// TODO convert it
			}
		} catch (IOException | InterruptedException e) {
			throw new RuntimeException(e);
		}

		return null;
	}

	private static RequestBody buildRequestBody(final String prompt) {
		return RequestBody.create("""
				{
					"version": "db21e45d3f7023abc2a46ee38a23973f6dce16bb082a930b0c49861f96d1e5bf",
					"input": {
						"prompt": "%s"
					}
				}
				""".formatted(prompt), JSON_CONTENT_TYPE);
	}

	private record ReplicateResponse(@SerializedName("urls") Link link, @SerializedName("output") String[] fileEndpoints) {
		private record Link(@SerializedName("get") String getImageEndpoint) {}
	}
}

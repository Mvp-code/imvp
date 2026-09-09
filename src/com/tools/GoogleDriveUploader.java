package com.tools;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

/**
 * Uploads files to a shared Google Drive folder using a service account.
 * Config: F:/JavProject/config/google-drive-sa.json
 * Share the target Drive folder with the service account client_email.
 */
public class GoogleDriveUploader {

	private static final String CONFIG_PATH = "F:/JavProject/config/google-drive-sa.json";
	private static final String FOLDER_ID   = "17PQBwesRSotGP5xo433c9h3nJnFBv2V8_Ga5JINlW6dvDWMmFbrpWqKHGgJkdtlQoBOuaN1V";
	private static final String SCOPE       = "https://www.googleapis.com/auth/drive.file";

	public static boolean isConfigured() {
		return new File(CONFIG_PATH).isFile();
	}

	public static String upload(File file, String displayName, String mimeType) {
		try {
			if (!file.isFile() || !isConfigured()) return null;

			JsonObject cfg = JsonParser.parseReader(
					new InputStreamReader(new FileInputStream(CONFIG_PATH), StandardCharsets.UTF_8))
					.getAsJsonObject();
			String clientEmail = cfg.get("client_email").getAsString();
			String privateKey  = cfg.get("private_key").getAsString();

			String token = fetchAccessToken(clientEmail, privateKey);
			if (token == null || token.isEmpty()) return null;

			if (mimeType == null || mimeType.isEmpty()) {
				mimeType = Files.probeContentType(file.toPath());
				if (mimeType == null) mimeType = "application/octet-stream";
			}

			String metadata = "{\"name\":\"" + jsonEscape(displayName)
					+ "\",\"parents\":[\"" + FOLDER_ID + "\"]}";

			String boundary = "mvp_boundary_" + System.currentTimeMillis();
			URL url = new URL("https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,webViewLink");
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("POST");
			conn.setDoOutput(true);
			conn.setRequestProperty("Authorization", "Bearer " + token);
			conn.setRequestProperty("Content-Type", "multipart/related; boundary=" + boundary);

			byte[] metaPart = ("--" + boundary + "\r\n"
					+ "Content-Type: application/json; charset=UTF-8\r\n\r\n"
					+ metadata + "\r\n"
					+ "--" + boundary + "\r\n"
					+ "Content-Type: " + mimeType + "\r\n\r\n").getBytes(StandardCharsets.UTF_8);
			byte[] fileBytes = Files.readAllBytes(file.toPath());
			byte[] endPart = ("\r\n--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8);

			OutputStream out = conn.getOutputStream();
			out.write(metaPart);
			out.write(fileBytes);
			out.write(endPart);
			out.flush();
			out.close();

			int code = conn.getResponseCode();
			BufferedReader br = new BufferedReader(new InputStreamReader(
					code >= 200 && code < 300 ? conn.getInputStream() : conn.getErrorStream(),
					StandardCharsets.UTF_8));
			StringBuilder sb = new StringBuilder();
			String line;
			while ((line = br.readLine()) != null) sb.append(line);
			br.close();

			if (code < 200 || code >= 300) {
				System.out.println("GoogleDriveUploader error " + code + ": " + sb);
				return null;
			}

			JsonObject resp = JsonParser.parseString(sb.toString()).getAsJsonObject();
			if (resp.has("webViewLink")) return resp.get("webViewLink").getAsString();
			if (resp.has("id")) return "https://drive.google.com/file/d/" + resp.get("id").getAsString() + "/view";
			return null;
		} catch (Exception ex) {
			System.out.println("GoogleDriveUploader.upload failed: " + ex.getMessage());
			ex.printStackTrace();
			return null;
		}
	}

	private static String fetchAccessToken(String clientEmail, String privateKeyPem) throws Exception {
		long now = System.currentTimeMillis() / 1000L;
		String header = b64url("{\"alg\":\"RS256\",\"typ\":\"JWT\"}");
		String payload = b64url("{\"iss\":\"" + clientEmail + "\",\"scope\":\"" + SCOPE
				+ "\",\"aud\":\"https://oauth2.googleapis.com/token\",\"exp\":" + (now + 3600)
				+ ",\"iat\":" + now + "}");
		String signInput = header + "." + payload;
		String signature = b64url(signRsa(signInput, privateKeyPem));
		String jwt = signInput + "." + signature;

		String body = "grant_type=" + URLEncoder.encode("urn:ietf:params:oauth:grant-type:jwt-bearer", "UTF-8")
				+ "&assertion=" + URLEncoder.encode(jwt, "UTF-8");

		HttpURLConnection conn = (HttpURLConnection) new URL("https://oauth2.googleapis.com/token").openConnection();
		conn.setRequestMethod("POST");
		conn.setDoOutput(true);
		conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
		conn.getOutputStream().write(body.getBytes(StandardCharsets.UTF_8));

		BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8));
		StringBuilder sb = new StringBuilder();
		String line;
		while ((line = br.readLine()) != null) sb.append(line);
		br.close();

		JsonObject tok = JsonParser.parseString(sb.toString()).getAsJsonObject();
		return tok.has("access_token") ? tok.get("access_token").getAsString() : null;
	}

	private static byte[] signRsa(String input, String privateKeyPem) throws Exception {
		String pem = privateKeyPem.replace("-----BEGIN PRIVATE KEY-----", "")
				.replace("-----END PRIVATE KEY-----", "").replaceAll("\\s", "");
		byte[] keyBytes = Base64.getDecoder().decode(pem);
		PrivateKey key = KeyFactory.getInstance("RSA")
				.generatePrivate(new PKCS8EncodedKeySpec(keyBytes));
		Signature sig = Signature.getInstance("SHA256withRSA");
		sig.initSign(key);
		sig.update(input.getBytes(StandardCharsets.UTF_8));
		return sig.sign();
	}

	private static String b64url(String s) {
		return Base64.getUrlEncoder().withoutPadding()
				.encodeToString(s.getBytes(StandardCharsets.UTF_8));
	}

	private static String b64url(byte[] bytes) {
		return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
	}

	private static String jsonEscape(String s) {
		if (s == null) return "";
		return s.replace("\\", "\\\\").replace("\"", "\\\"");
	}
}

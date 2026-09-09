package com.util;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.GregorianCalendar;

import org.apache.commons.codec.binary.Base64;

public class Authentication {

	public static final String SHA1 = "SHA-1";
	public static final String SHA256 = "SHA-256";

	public static String encodeString(String encString) {
		byte[] encodedBytes = encString.getBytes();
		String encodedString = new String(Base64.encodeBase64(encodedBytes));
		return encodedString;
	}

	public static String decodeString(String encString) {
		byte[] encodedBytes = encString.getBytes();
		String decodedString = new String(Base64.decodeBase64(encodedBytes));
		return decodedString;
	}

	public static String convertToString(byte[] bytes) {
		StringBuffer s = new StringBuffer();
		int length = bytes.length;
		for (int n = 0; n < length; n++) {
			s.append((int) bytes[n]);
			if (n != length - 1) {
				s.append(' ');
			}
		}
		return s.toString();
	}

	public static String convertToHex(byte[] data) {
		StringBuffer buf = new StringBuffer();
		for (int i = 0; i < data.length; i++) {
			int halfbyte = (data[i] >>> 4) & 0x0F;
			int two_halfs = 0;
			do {
				if ((0 <= halfbyte) && (halfbyte <= 9))
					buf.append((char) ('0' + halfbyte));
				else
					buf.append((char) ('a' + (halfbyte - 10)));
				halfbyte = data[i] & 0x0F;
			} while (two_halfs++ < 1);
		}
		return buf.toString();
	}

	public static String getDigestString(String messageString,
			String algorithm) {

		MessageDigest md = null;
		if (algorithm.length() == 0)
			algorithm = SHA1;
		try {
			md = MessageDigest.getInstance(algorithm);
		} catch (NoSuchAlgorithmException e) {
			e.getMessage();
		}

		try {
			md.update(messageString.getBytes("UTF-8"));
		} catch (Exception e) {
			e.getMessage();
		}

		byte raw[] = md.digest();
		String hash = new String(convertToHex(raw));
		return hash;
	}
}
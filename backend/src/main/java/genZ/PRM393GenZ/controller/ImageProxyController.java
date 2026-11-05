package genZ.PRM393GenZ.controller;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;

@RestController
@CrossOrigin(origins = "*")
public class ImageProxyController {

    @GetMapping("/proxy-image")
    public ResponseEntity<byte[]> proxyImage(@RequestParam("url") String targetUrl) {
        if (targetUrl == null || targetUrl.isBlank()) {
            return ResponseEntity.badRequest().build();
        }

        try {
            URI uri = new URI(targetUrl.trim());
            URL url = uri.toURL();
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(10000);
            connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

            int responseCode = connection.getResponseCode();
            if (responseCode != HttpURLConnection.HTTP_OK) {
                return ResponseEntity.status(responseCode).build();
            }

            String contentType = connection.getContentType();
            if (contentType == null || contentType.isBlank()) {
                contentType = MediaType.IMAGE_JPEG_VALUE;
            }

            byte[] imageBytes;
            try (InputStream in = connection.getInputStream()) {
                imageBytes = in.readAllBytes();
            }

            HttpHeaders headers = new HttpHeaders();
            headers.set("Content-Type", contentType);
            headers.set("Cache-Control", "public, max-age=86400");
            headers.set("Access-Control-Allow-Origin", "*");

            return new ResponseEntity<>(imageBytes, headers, HttpStatus.OK);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}

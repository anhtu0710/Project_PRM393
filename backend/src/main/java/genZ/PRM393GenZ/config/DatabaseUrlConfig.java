package genZ.PRM393GenZ.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;
import java.net.URI;

@Configuration
public class DatabaseUrlConfig {

    @Bean
    @Primary
    public DataSource dataSource(DataSourceProperties properties) {
        String url = System.getenv("SPRING_DATASOURCE_URL");
        if (url == null || url.isBlank()) {
            url = System.getenv("DATABASE_URL");
        }
        if (url == null || url.isBlank()) {
            url = properties.getUrl();
        }

        String username = properties.getUsername();
        String password = properties.getPassword();

        if (url != null && (url.startsWith("postgres://") || url.startsWith("postgresql://"))) {
            try {
                // Tách URI postgres://user:password@host:port/dbname của Render thành JDBC URL + Username + Password
                String cleanUriStr = url.startsWith("postgres://")
                        ? "http://" + url.substring("postgres://".length())
                        : "http://" + url.substring("postgresql://".length());
                URI uri = URI.create(cleanUriStr);

                if (uri.getUserInfo() != null && uri.getUserInfo().contains(":")) {
                    String[] userInfo = uri.getUserInfo().split(":", 2);
                    username = userInfo[0];
                    password = userInfo[1];
                }

                int port = uri.getPort() > 0 ? uri.getPort() : 5432;
                String dbPath = uri.getPath(); // e.g. "/dbname"
                url = "jdbc:postgresql://" + uri.getHost() + ":" + port + dbPath;

            } catch (Exception e) {
                if (url.startsWith("postgres://")) {
                    url = "jdbc:postgresql://" + url.substring("postgres://".length());
                } else if (url.startsWith("postgresql://")) {
                    url = "jdbc:postgresql://" + url.substring("postgresql://".length());
                }
            }
        }

        HikariDataSource dataSource = new HikariDataSource();
        dataSource.setJdbcUrl(url);
        if (username != null && !username.isBlank()) {
            dataSource.setUsername(username);
        }
        if (password != null && !password.isBlank()) {
            dataSource.setPassword(password);
        }
        return dataSource;
    }
}

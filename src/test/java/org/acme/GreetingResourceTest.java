package org.acme;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import io.quarkus.test.keycloak.client.KeycloakTestClient;

@QuarkusTest
public class GreetingResourceTest {

    KeycloakTestClient keycloak = new KeycloakTestClient();

    @Test
    public void testHelloEndpoint() {
        given()
          .auth().oauth2(getAccessToken("alice"))
          .when().get("/hello")
          .then()
             .statusCode(200)
             .body(is("Hello from RESTEasy Reactive"));
    }
    protected String getAccessToken(String user) {
        return keycloak.getAccessToken(user);
    }

}